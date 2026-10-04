import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Firebase client configuration for native Push, supplied only through
/// `--dart-define-from-file=config/push.local.json` (gitignored).
/// Empty values keep native Push disabled; the app never ships a default.
class MerchantPushConfig {
  const MerchantPushConfig._();

  static const _apiKey = String.fromEnvironment('SGO_FIREBASE_API_KEY');
  static const _projectId = String.fromEnvironment('SGO_FIREBASE_PROJECT_ID');
  static const _senderId = String.fromEnvironment('SGO_FIREBASE_SENDER_ID');
  static const _iosAppId = String.fromEnvironment('SGO_FIREBASE_IOS_APP_ID');
  static const _androidAppId = String.fromEnvironment(
    'SGO_FIREBASE_ANDROID_APP_ID',
  );
  static const _iosBundleId = String.fromEnvironment(
    'SGO_FIREBASE_IOS_BUNDLE_ID',
    defaultValue: 'com.speedygo.speedygoMerchantApp',
  );

  /// Options for the current platform, or null when not configured.
  static FirebaseOptions? currentPlatformOptions() {
    if (kIsWeb) return null;
    if (_apiKey.isEmpty || _projectId.isEmpty || _senderId.isEmpty) {
      return null;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
        if (_iosAppId.isEmpty) return null;
        return const FirebaseOptions(
          apiKey: _apiKey,
          appId: _iosAppId,
          messagingSenderId: _senderId,
          projectId: _projectId,
          iosBundleId: _iosBundleId,
        );
      case TargetPlatform.android:
        if (_androidAppId.isEmpty) return null;
        return const FirebaseOptions(
          apiKey: _apiKey,
          appId: _androidAppId,
          messagingSenderId: _senderId,
          projectId: _projectId,
        );
      default:
        return null;
    }
  }
}
