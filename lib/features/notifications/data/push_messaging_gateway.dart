import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:speedygo_merchant_app/features/notifications/data/push_config.dart';

final _uuid = RegExp(
  r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
);

/// Routing hint from a native Push payload. Never trusted for order state:
/// the app always re-fetches the order before showing actions.
@immutable
class PushOrderHint {
  const PushOrderHint({
    required this.orderId,
    this.merchantId,
    this.branchId,
    this.notificationId,
  });

  final String orderId;
  final String? merchantId;
  final String? branchId;
  final String? notificationId;

  static PushOrderHint? fromData(Map<String, dynamic> data) {
    if (data['type'] != 'MERCHANT_ORDER_CREATED') return null;
    final orderId = data['orderId'];
    if (orderId is! String || !_uuid.hasMatch(orderId)) return null;
    String? uuidOrNull(Object? v) =>
        v is String && _uuid.hasMatch(v) ? v : null;
    return PushOrderHint(
      orderId: orderId.toLowerCase(),
      merchantId: uuidOrNull(data['merchantId']),
      branchId: uuidOrNull(data['branchId']),
      notificationId: uuidOrNull(data['notificationId']),
    );
  }
}

enum PushAuthorization { authorized, provisional, denied, notDetermined }

extension PushAuthorizationX on PushAuthorization {
  bool get allowsDisplay =>
      this == PushAuthorization.authorized ||
      this == PushAuthorization.provisional;
}

/// Provider-neutral seam over the native Push SDK (testable with fakes).
abstract class PushMessagingGateway {
  /// True once the provider SDK initialized with real configuration.
  bool get isAvailable;

  /// Provider platform label sent to `PUT /notifications/device-tokens`.
  String get platform;

  Future<PushAuthorization> authorizationStatus();
  Future<PushAuthorization> requestAuthorization();
  Future<String?> getToken();

  /// Invalidates this install's token at the provider (logout/account change).
  Future<void> deleteToken();

  Stream<String> get onTokenRefresh;
  Stream<PushOrderHint> get onForegroundHint;
  Stream<PushOrderHint> get onOpenedHint;

  /// Tap that cold-launched the app, consumed once.
  Future<PushOrderHint?> takeInitialHint();
}

class DisabledPushMessagingGateway implements PushMessagingGateway {
  const DisabledPushMessagingGateway();

  @override
  bool get isAvailable => false;
  @override
  String get platform =>
      defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android';
  @override
  Future<PushAuthorization> authorizationStatus() async =>
      PushAuthorization.notDetermined;
  @override
  Future<PushAuthorization> requestAuthorization() async =>
      PushAuthorization.notDetermined;
  @override
  Future<String?> getToken() async => null;
  @override
  Future<void> deleteToken() async {}
  @override
  Stream<String> get onTokenRefresh => const Stream.empty();
  @override
  Stream<PushOrderHint> get onForegroundHint => const Stream.empty();
  @override
  Stream<PushOrderHint> get onOpenedHint => const Stream.empty();
  @override
  Future<PushOrderHint?> takeInitialHint() async => null;
}

class FirebasePushMessagingGateway implements PushMessagingGateway {
  FirebasePushMessagingGateway._();

  static PushMessagingGateway? _instance;

  /// Initializes Firebase when configured; otherwise returns a disabled
  /// gateway. Must run before `runApp` so a cold-launch tap is captured.
  static Future<PushMessagingGateway> bootstrap() async {
    final existing = _instance;
    if (existing != null) return existing;
    final options = MerchantPushConfig.currentPlatformOptions();
    if (options == null) {
      return _instance = const DisabledPushMessagingGateway();
    }
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(options: options);
      }
      // Foreground: no OS banner; the in-app alert is the only surface.
      await FirebaseMessaging.instance
          .setForegroundNotificationPresentationOptions(
            alert: false,
            badge: false,
            sound: false,
          );
      return _instance = FirebasePushMessagingGateway._();
    } catch (e) {
      debugPrint('native push disabled: Firebase init failed ($e)');
      return _instance = const DisabledPushMessagingGateway();
    }
  }

  FirebaseMessaging get _fm => FirebaseMessaging.instance;
  bool _initialTaken = false;

  @override
  bool get isAvailable => true;

  @override
  String get platform =>
      defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android';

  static PushAuthorization _map(AuthorizationStatus s) => switch (s) {
    AuthorizationStatus.authorized => PushAuthorization.authorized,
    AuthorizationStatus.provisional => PushAuthorization.provisional,
    AuthorizationStatus.denied ||
    AuthorizationStatus.deniedPermanently => PushAuthorization.denied,
    AuthorizationStatus.notDetermined => PushAuthorization.notDetermined,
  };

  @override
  Future<PushAuthorization> authorizationStatus() async =>
      _map((await _fm.getNotificationSettings()).authorizationStatus);

  @override
  Future<PushAuthorization> requestAuthorization() async =>
      _map((await _fm.requestPermission()).authorizationStatus);

  @override
  Future<String?> getToken() async {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      // FCM needs the APNs token first; it can lag behind launch.
      for (var i = 0; i < 5; i++) {
        if (await _fm.getAPNSToken() != null) break;
        await Future<void>.delayed(const Duration(seconds: 1));
      }
      if (await _fm.getAPNSToken() == null) return null;
    }
    return _fm.getToken();
  }

  @override
  Future<void> deleteToken() => _fm.deleteToken();

  @override
  Stream<String> get onTokenRefresh => _fm.onTokenRefresh;

  @override
  Stream<PushOrderHint> get onForegroundHint => FirebaseMessaging.onMessage
      .map((m) => PushOrderHint.fromData(m.data))
      .where((h) => h != null)
      .cast<PushOrderHint>();

  @override
  Stream<PushOrderHint> get onOpenedHint => FirebaseMessaging.onMessageOpenedApp
      .map((m) => PushOrderHint.fromData(m.data))
      .where((h) => h != null)
      .cast<PushOrderHint>();

  @override
  Future<PushOrderHint?> takeInitialHint() async {
    if (_initialTaken) return null;
    _initialTaken = true;
    final m = await _fm.getInitialMessage();
    return m == null ? null : PushOrderHint.fromData(m.data);
  }
}
