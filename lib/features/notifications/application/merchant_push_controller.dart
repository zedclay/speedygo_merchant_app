import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speedygo_merchant_app/core/errors/app_exception.dart';
import 'package:speedygo_merchant_app/features/auth/application/auth_infrastructure.dart';
import 'package:speedygo_merchant_app/features/auth/application/session_controller.dart';
import 'package:speedygo_merchant_app/features/auth/application/session_state.dart';
import 'package:speedygo_merchant_app/features/notifications/application/order_alert_controller.dart';
import 'package:speedygo_merchant_app/features/notifications/data/notification_preferences.dart';
import 'package:speedygo_merchant_app/features/notifications/data/push_messaging_gateway.dart';
import 'package:speedygo_merchant_app/features/notifications/data/push_registration.dart';

/// Overridden in `main()` with the bootstrapped provider gateway.
final pushMessagingGatewayProvider = Provider<PushMessagingGateway>(
  (ref) => const DisabledPushMessagingGateway(),
);

final pushRegistrationStoreProvider = Provider<MerchantPushRegistration>(
  (ref) => MerchantPushRegistration(),
);

final nativePushPreferenceLoaderProvider = Provider<Future<bool> Function()>((
  ref,
) {
  return () async =>
      (await MerchantNotificationPreferences.load()).nativePushEnabled;
});

enum PushRegistrationStatus {
  /// Provider SDK not configured in this build.
  unavailable,
  idle,
  registered,
  permissionDenied,
  disabledByUser,
  tokenUnavailable,
  failed,
}

@immutable
class MerchantPushState {
  const MerchantPushState({
    this.available = false,
    this.authorization = PushAuthorization.notDetermined,
    this.registration = PushRegistrationStatus.unavailable,
    this.pendingOpen,
  });

  final bool available;
  final PushAuthorization authorization;
  final PushRegistrationStatus registration;

  /// Notification tap waiting for auth + navigation readiness.
  final PushOrderHint? pendingOpen;

  MerchantPushState copyWith({
    bool? available,
    PushAuthorization? authorization,
    PushRegistrationStatus? registration,
    PushOrderHint? pendingOpen,
    bool clearPendingOpen = false,
  }) {
    return MerchantPushState(
      available: available ?? this.available,
      authorization: authorization ?? this.authorization,
      registration: registration ?? this.registration,
      pendingOpen: clearPendingOpen ? null : (pendingOpen ?? this.pendingOpen),
    );
  }
}

/// Native Push lifecycle for this install: token registration, refresh,
/// account-change rotation, scoped sign-out deactivation and tap routing.
/// Push payloads are hints only; order state always comes from the server.
class MerchantPushController extends Notifier<MerchantPushState> {
  final List<StreamSubscription<Object?>> _subs = [];
  Future<void>? _syncInFlight;
  bool _syncAgain = false;

  PushMessagingGateway get _gateway => ref.read(pushMessagingGatewayProvider);
  MerchantPushRegistration get _store =>
      ref.read(pushRegistrationStoreProvider);

  @override
  MerchantPushState build() {
    final gateway = ref.read(pushMessagingGatewayProvider);
    ref.onDispose(() {
      for (final s in _subs) {
        s.cancel();
      }
      _subs.clear();
    });
    if (!gateway.isAvailable) {
      return const MerchantPushState();
    }
    // No ref.listen/watch on the session: SessionController reads this
    // provider on logout, and a dependency back onto the session would be a
    // Riverpod cycle. MerchantAlertHost calls [onSessionChanged] instead.
    _subs
      ..add(gateway.onTokenRefresh.listen((t) => unawaited(_onTokenRefresh(t))))
      ..add(gateway.onForegroundHint.listen(_onForegroundHint))
      ..add(gateway.onOpenedHint.listen(_onOpened));
    unawaited(_captureInitialHint());
    if (ref.read(sessionControllerProvider).phase == SessionPhase.ready) {
      Future.microtask(() => syncRegistration(prompt: true));
    }
    return const MerchantPushState(
      available: true,
      registration: PushRegistrationStatus.idle,
    );
  }

  Future<void> _captureInitialHint() async {
    try {
      final hint = await _gateway.takeInitialHint();
      if (hint != null && ref.mounted) _onOpened(hint);
    } catch (e) {
      debugPrint('push initial message unavailable: $e');
    }
  }

  void _onOpened(PushOrderHint hint) {
    state = state.copyWith(pendingOpen: hint);
  }

  void _onForegroundHint(PushOrderHint hint) {
    unawaited(ref.read(orderAlertControllerProvider.notifier).onPushHint(hint));
  }

  /// Registers for the Account whenever a session becomes ready (sign-in,
  /// restore, or a new session generation).
  void onSessionChanged(SessionState? prev, SessionState next) {
    if (next.phase == SessionPhase.ready &&
        (prev?.phase != SessionPhase.ready ||
            prev?.generation != next.generation)) {
      unawaited(syncRegistration(prompt: true));
    }
  }

  /// Returns and clears the pending tap (single consumer: alert host).
  PushOrderHint? takePendingOpen() {
    final hint = state.pendingOpen;
    if (hint != null) state = state.copyWith(clearPendingOpen: true);
    return hint;
  }

  /// Visible for tests / harness: inject a tap as the OS plugin would.
  @visibleForTesting
  void debugOpenFromPush(PushOrderHint hint) => _onOpened(hint);

  /// Registers (or deactivates) this install's token for the signed-in
  /// Account according to OS permission and the local opt-in.
  Future<void> syncRegistration({bool prompt = false}) async {
    if (!_gateway.isAvailable) return;
    if (_syncInFlight != null) {
      _syncAgain = true;
      return _syncInFlight;
    }
    final run = _sync(prompt: prompt);
    _syncInFlight = run;
    try {
      await run;
    } finally {
      _syncInFlight = null;
      if (_syncAgain && ref.mounted) {
        _syncAgain = false;
        unawaited(syncRegistration());
      }
    }
  }

  Future<void> _sync({required bool prompt}) async {
    final session = ref.read(sessionControllerProvider);
    final accountId = session.accountId;
    if (session.phase != SessionPhase.ready || accountId == null) return;
    final generation = session.generation;
    bool current() =>
        ref.mounted &&
        ref.read(sessionControllerProvider).generation == generation &&
        ref.read(sessionControllerProvider).phase == SessionPhase.ready;

    try {
      var auth = await _gateway.authorizationStatus();
      if (auth == PushAuthorization.notDetermined && prompt) {
        auth = await _gateway.requestAuthorization();
      }
      if (!current()) return;
      state = state.copyWith(authorization: auth);

      var stored = await _store.loadStoredToken();
      final enabled = await ref.read(nativePushPreferenceLoaderProvider)();
      if (!current()) return;

      if (!auth.allowsDisplay || !enabled) {
        await _deactivateStored(stored, callServer: true);
        state = state.copyWith(
          registration: !enabled
              ? PushRegistrationStatus.disabledByUser
              : PushRegistrationStatus.permissionDenied,
        );
        return;
      }

      if (stored != null &&
          stored.accountId != null &&
          stored.accountId != accountId) {
        // Token was registered by another Account on this install: rotate so
        // the previous Account's token dies at the provider.
        await _store.clearStoredToken();
        await _gateway.deleteToken();
        stored = null;
      }

      var token = await _gateway.getToken();
      if (!current()) return;
      if (token == null) {
        state = state.copyWith(
          registration: PushRegistrationStatus.tokenUnavailable,
        );
        return;
      }

      if (stored != null && stored.token != token) {
        await _deactivateServerToken(stored.token);
      }
      try {
        await ref
            .read(merchantApiProvider)
            .registerDeviceToken(token: token, platform: _gateway.platform);
      } on ApiException catch (e) {
        if (e.statusCode != 409) rethrow;
        // Still active for another Account (e.g. its session expired without
        // logout). Rotate once rather than claiming a live foreign token.
        await _gateway.deleteToken();
        token = await _gateway.getToken();
        if (token == null || !current()) return;
        await ref
            .read(merchantApiProvider)
            .registerDeviceToken(token: token, platform: _gateway.platform);
      }
      if (!current()) return;
      await _store.storeRegisteredToken(
        token: token,
        platform: _gateway.platform,
        accountId: accountId,
      );
      state = state.copyWith(registration: PushRegistrationStatus.registered);
    } catch (e) {
      debugPrint('push registration failed: $e');
      if (ref.mounted) {
        state = state.copyWith(registration: PushRegistrationStatus.failed);
      }
    }
  }

  Future<void> _onTokenRefresh(String token) async {
    final session = ref.read(sessionControllerProvider);
    if (session.phase != SessionPhase.ready) return;
    final stored = await _store.loadStoredToken();
    if (stored?.token == token) return;
    await syncRegistration();
  }

  /// Sign-out: deactivate exactly this install's token for the current
  /// Account (when the server is reachable), then invalidate it at the
  /// provider so a signed-out device stops receiving that Account's pushes.
  Future<void> deactivateForSignOut({required bool callServer}) async {
    try {
      final stored = await _store.loadStoredToken();
      await _deactivateStored(stored, callServer: callServer);
      if (_gateway.isAvailable) {
        await _gateway.deleteToken();
      }
    } catch (e) {
      debugPrint('push sign-out cleanup failed: $e');
    }
    if (ref.mounted) {
      state = state.copyWith(
        registration: _gateway.isAvailable
            ? PushRegistrationStatus.idle
            : PushRegistrationStatus.unavailable,
        clearPendingOpen: callServer,
      );
    }
  }

  Future<void> _deactivateStored(
    StoredPushToken? stored, {
    required bool callServer,
  }) async {
    if (stored == null) return;
    if (callServer) {
      await _deactivateServerToken(stored.token);
    }
    await _store.clearStoredToken();
  }

  Future<void> _deactivateServerToken(String token) async {
    try {
      await ref.read(merchantApiProvider).deactivateDeviceToken(token: token);
    } catch (e) {
      debugPrint('push token deactivate failed: $e');
    }
  }
}

final merchantPushControllerProvider =
    NotifierProvider<MerchantPushController, MerchantPushState>(
      MerchantPushController.new,
    );
