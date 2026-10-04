import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:permission_handler/permission_handler.dart';

typedef StoredPushToken = ({String token, String platform, String? accountId});

/// Device-local record of the token this install registered, and for which
/// Account, so logout/account change can deactivate exactly that token.
class MerchantPushRegistration {
  MerchantPushRegistration({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;
  static const _tokenKey = 'merchant_device_push_token';
  static const _platformKey = 'merchant_device_push_platform';
  static const _accountKey = 'merchant_device_push_account';

  /// OS notification permission (used when native Push is unavailable).
  Future<PermissionStatus> requestOsPermission() {
    return Permission.notification.request();
  }

  Future<PermissionStatus> osPermissionStatus() {
    return Permission.notification.status;
  }

  Future<void> storeRegisteredToken({
    required String token,
    required String platform,
    required String? accountId,
  }) async {
    await _storage.write(key: _tokenKey, value: token);
    await _storage.write(key: _platformKey, value: platform);
    if (accountId == null) {
      await _storage.delete(key: _accountKey);
    } else {
      await _storage.write(key: _accountKey, value: accountId);
    }
  }

  Future<StoredPushToken?> loadStoredToken() async {
    final token = await _storage.read(key: _tokenKey);
    final platform = await _storage.read(key: _platformKey);
    if (token == null ||
        token.isEmpty ||
        platform == null ||
        platform.isEmpty) {
      return null;
    }
    final accountId = await _storage.read(key: _accountKey);
    return (token: token, platform: platform, accountId: accountId);
  }

  Future<void> clearStoredToken() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _platformKey);
    await _storage.delete(key: _accountKey);
  }
}
