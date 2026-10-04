import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speedygo_merchant_app/core/errors/app_exception.dart';
import 'package:speedygo_merchant_app/features/access/data/merchant_api.dart';
import 'package:speedygo_merchant_app/features/auth/application/auth_infrastructure.dart';
import 'package:speedygo_merchant_app/features/auth/application/session_controller.dart';
import 'package:speedygo_merchant_app/features/auth/application/session_state.dart';
import 'package:speedygo_merchant_app/features/notifications/application/merchant_push_controller.dart';
import 'package:speedygo_merchant_app/features/notifications/data/push_messaging_gateway.dart';
import 'package:speedygo_merchant_app/features/notifications/data/push_registration.dart';

const _accountA = 'aaaaaaaa-aaaa-7aaa-8aaa-aaaaaaaaaaaa';
const _accountB = 'bbbbbbbb-bbbb-7bbb-8bbb-bbbbbbbbbbbb';
const _order = '01a0d97f-9cbd-7b41-8dbf-ef8238661920';

class _FakeGateway implements PushMessagingGateway {
  PushAuthorization auth = PushAuthorization.authorized;
  PushAuthorization authAfterRequest = PushAuthorization.authorized;
  int requestCount = 0;
  int deleteCount = 0;
  int _serial = 2;
  String token = 'tok-1';
  PushOrderHint? initial;
  final refresh = StreamController<String>.broadcast();
  final foreground = StreamController<PushOrderHint>.broadcast();
  final opened = StreamController<PushOrderHint>.broadcast();

  @override
  bool get isAvailable => true;
  @override
  String get platform => 'ios';
  @override
  Future<PushAuthorization> authorizationStatus() async => auth;
  @override
  Future<PushAuthorization> requestAuthorization() async {
    requestCount++;
    auth = authAfterRequest;
    return auth;
  }

  @override
  Future<String?> getToken() async => token;
  @override
  Future<void> deleteToken() async {
    deleteCount++;
    token = 'tok-${_serial++}';
  }

  @override
  Stream<String> get onTokenRefresh => refresh.stream;
  @override
  Stream<PushOrderHint> get onForegroundHint => foreground.stream;
  @override
  Stream<PushOrderHint> get onOpenedHint => opened.stream;
  @override
  Future<PushOrderHint?> takeInitialHint() async {
    final h = initial;
    initial = null;
    return h;
  }
}

class _MemoryStore extends MerchantPushRegistration {
  StoredPushToken? value;
  @override
  Future<void> storeRegisteredToken({
    required String token,
    required String platform,
    required String? accountId,
  }) async {
    value = (token: token, platform: platform, accountId: accountId);
  }

  @override
  Future<StoredPushToken?> loadStoredToken() async => value;
  @override
  Future<void> clearStoredToken() async => value = null;
}

class _FakeApi implements MerchantClient {
  final registered = <String>[];
  final deactivated = <String>[];
  Set<String> conflictTokens = {};

  @override
  Future<void> registerDeviceToken({
    required String token,
    required String platform,
  }) async {
    if (conflictTokens.contains(token)) {
      throw const ApiException(
        'Push token is registered to another account',
        code: 'NOTIFICATION_INTEGRITY_CONFLICT',
        statusCode: 409,
      );
    }
    registered.add('$platform:$token');
  }

  @override
  Future<void> deactivateDeviceToken({required String token}) async {
    deactivated.add(token);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeSession extends SessionController {
  @override
  SessionState build() => const SessionState(phase: SessionPhase.signedOut);

  void signIn(String accountId, {int generation = 1}) {
    state = SessionState(
      phase: SessionPhase.ready,
      accountId: accountId,
      generation: generation,
    );
  }

  void signOut() {
    state = SessionState(
      phase: SessionPhase.signedOut,
      generation: state.generation + 1,
    );
  }

  /// Same read SessionController.logout/invalidateLocalSession performs.
  Future<void> signOutLikeLogout() async {
    await ref
        .read(merchantPushControllerProvider.notifier)
        .deactivateForSignOut(callServer: true);
    signOut();
  }
}

class _Harness {
  _Harness({bool nativeEnabled = true}) : _nativeEnabled = nativeEnabled {
    container = ProviderContainer(
      overrides: [
        pushMessagingGatewayProvider.overrideWithValue(gateway),
        pushRegistrationStoreProvider.overrideWithValue(store),
        merchantApiProvider.overrideWithValue(api),
        sessionControllerProvider.overrideWith(_FakeSession.new),
        nativePushPreferenceLoaderProvider
            .overrideWithValue(() async => _nativeEnabled),
      ],
    );
    container.listen(merchantPushControllerProvider, (_, _) {});
    // Mirrors MerchantAlertHost, which forwards session transitions.
    container.listen(
      sessionControllerProvider,
      (prev, next) => container
          .read(merchantPushControllerProvider.notifier)
          .onSessionChanged(prev, next),
    );
  }

  final gateway = _FakeGateway();
  final store = _MemoryStore();
  final api = _FakeApi();
  bool _nativeEnabled;
  late final ProviderContainer container;

  set nativeEnabled(bool v) => _nativeEnabled = v;
  _FakeSession get session =>
      container.read(sessionControllerProvider.notifier) as _FakeSession;
  MerchantPushController get push =>
      container.read(merchantPushControllerProvider.notifier);
  MerchantPushState get state => container.read(merchantPushControllerProvider);

  Future<void> settle() async {
    for (var i = 0; i < 10; i++) {
      await Future<void>.delayed(Duration.zero);
    }
  }
}

void main() {
  group('PushOrderHint.fromData', () {
    test('accepts merchant new-order payload and normalizes ids', () {
      final hint = PushOrderHint.fromData({
        'type': 'MERCHANT_ORDER_CREATED',
        'orderId': _order.toUpperCase(),
        'merchantId': _accountA,
        'notificationId': 'not-a-uuid',
      });
      expect(hint?.orderId, _order);
      expect(hint?.merchantId, _accountA);
      expect(hint?.notificationId, isNull);
    });

    test('rejects other types and malformed order ids', () {
      expect(
        PushOrderHint.fromData({'type': 'ORDER_READY', 'orderId': _order}),
        isNull,
      );
      expect(
        PushOrderHint.fromData({
          'type': 'MERCHANT_ORDER_CREATED',
          'orderId': '../../admin',
        }),
        isNull,
      );
    });
  });

  test('registers the token for the signed-in account after permission prompt',
      () async {
    final h = _Harness();
    h.gateway.auth = PushAuthorization.notDetermined;
    h.session.signIn(_accountA);
    await h.settle();

    expect(h.gateway.requestCount, 1);
    expect(h.api.registered, ['ios:tok-1']);
    expect(h.store.value?.accountId, _accountA);
    expect(h.state.registration, PushRegistrationStatus.registered);
  });

  test('permission denied: no registration and stored token is deactivated',
      () async {
    final h = _Harness();
    h.store.value = (token: 'old', platform: 'ios', accountId: _accountA);
    h.gateway.auth = PushAuthorization.denied;
    h.session.signIn(_accountA);
    await h.settle();

    expect(h.api.registered, isEmpty);
    expect(h.api.deactivated, ['old']);
    expect(h.store.value, isNull);
    expect(h.state.registration, PushRegistrationStatus.permissionDenied);
  });

  test('user opt-out deactivates this install token only', () async {
    final h = _Harness(nativeEnabled: false);
    h.store.value = (token: 'mine', platform: 'ios', accountId: _accountA);
    h.session.signIn(_accountA);
    await h.settle();
    expect(h.api.deactivated, ['mine']);
    expect(h.api.registered, isEmpty);
    expect(h.state.registration, PushRegistrationStatus.disabledByUser);

    h.nativeEnabled = true;
    await h.push.syncRegistration();
    expect(h.api.registered, ['ios:tok-1']);
  });

  test('account change on the same install rotates the provider token',
      () async {
    final h = _Harness();
    h.store.value = (token: 'tok-A', platform: 'ios', accountId: _accountA);
    h.session.signIn(_accountB);
    await h.settle();

    expect(h.gateway.deleteCount, 1);
    expect(h.api.registered, ['ios:tok-2']);
    expect(h.api.deactivated, isEmpty,
        reason: 'B must not DELETE a token owned by A');
    expect(h.store.value?.accountId, _accountB);
  });

  test('token refresh deactivates the old token and registers the new one',
      () async {
    final h = _Harness();
    h.session.signIn(_accountA);
    await h.settle();
    expect(h.api.registered, ['ios:tok-1']);

    h.gateway.token = 'tok-refreshed';
    h.gateway.refresh.add('tok-refreshed');
    await h.settle();

    expect(h.api.deactivated, ['tok-1']);
    expect(h.api.registered.last, 'ios:tok-refreshed');
    expect(h.store.value?.token, 'tok-refreshed');
  });

  test('409 (token still active for another account) rotates once and retries',
      () async {
    final h = _Harness();
    h.api.conflictTokens = {'tok-1'};
    h.session.signIn(_accountA);
    await h.settle();

    expect(h.gateway.deleteCount, 1);
    expect(h.api.registered, ['ios:tok-2']);
    expect(h.state.registration, PushRegistrationStatus.registered);
  });

  test('logout deactivates exactly the stored token then deletes it at provider',
      () async {
    final h = _Harness();
    h.session.signIn(_accountA);
    await h.settle();

    await h.push.deactivateForSignOut(callServer: true);
    expect(h.api.deactivated, ['tok-1']);
    expect(h.store.value, isNull);
    expect(h.gateway.deleteCount, 1);
  });

  test('session controller can read the push controller (no provider cycle)',
      () async {
    final h = _Harness();
    h.session.signIn(_accountA);
    await h.settle();
    expect(h.api.registered, ['ios:tok-1']);

    await h.session.signOutLikeLogout();
    expect(h.api.deactivated, ['tok-1']);
    expect(h.store.value, isNull);
  });

  test('expired session: no server call, provider token still invalidated',
      () async {
    final h = _Harness();
    h.session.signIn(_accountA);
    await h.settle();

    await h.push.deactivateForSignOut(callServer: false);
    expect(h.api.deactivated, isEmpty);
    expect(h.store.value, isNull);
    expect(h.gateway.deleteCount, 1);
  });

  test('cold-launch tap is held as pendingOpen until consumed once', () async {
    final h = _Harness();
    h.gateway.initial = const PushOrderHint(orderId: _order);
    // Rebuild so build() captures the initial message.
    h.container.invalidate(merchantPushControllerProvider);
    h.container.read(merchantPushControllerProvider);
    await h.settle();

    expect(h.state.pendingOpen?.orderId, _order);
    expect(h.push.takePendingOpen()?.orderId, _order);
    expect(h.push.takePendingOpen(), isNull);
    expect(h.state.pendingOpen, isNull);
  });

  test('background tap (onMessageOpenedApp) sets pendingOpen', () async {
    final h = _Harness();
    h.gateway.opened.add(const PushOrderHint(orderId: _order));
    await h.settle();
    expect(h.state.pendingOpen?.orderId, _order);
  });

  test('no registration while signed out; re-registers on next sign-in',
      () async {
    final h = _Harness();
    await h.push.syncRegistration();
    expect(h.api.registered, isEmpty);

    h.session.signIn(_accountA);
    await h.settle();
    h.session.signOut();
    await h.push.deactivateForSignOut(callServer: true);
    h.session.signIn(_accountA, generation: 3);
    await h.settle();
    expect(h.api.registered, ['ios:tok-1', 'ios:tok-2']);
  });
}
