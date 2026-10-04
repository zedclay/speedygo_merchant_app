import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:speedygo_merchant_app/features/auth/data/models.dart';

/// Merchant-only session keys — never shared with Customer storage.
abstract class SessionStore {
  Future<TokenPair?> read();
  Future<void> write(TokenPair pair);
  Future<void> clear();
  Future<bool> isRefreshPending();
  Future<void> markRefreshPending();
  Future<void> clearRefreshPending();
}

class SecureSessionStore implements SessionStore {
  SecureSessionStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const _key = 'speedygo.merchant.session.v1';
  static const _pendingKey = 'speedygo.merchant.refresh-pending.v1';

  final FlutterSecureStorage _storage;

  @override
  Future<TokenPair?> read() async {
    final raw = await _storage.read(key: _key);
    if (raw == null || raw.isEmpty) return null;
    try {
      final map = jsonDecode(raw);
      if (map is! Map<String, dynamic>) {
        await clear();
        return null;
      }
      return TokenPair.fromJson(map);
    } on FormatException {
      await clear();
      return null;
    } on SessionParseException {
      await clear();
      return null;
    }
  }

  @override
  Future<void> write(TokenPair pair) {
    return _storage.write(key: _key, value: jsonEncode(pair.toJson()));
  }

  @override
  Future<void> clear() async {
    await _storage.delete(key: _key);
    await _storage.delete(key: _pendingKey);
  }

  @override
  Future<bool> isRefreshPending() async {
    return await _storage.read(key: _pendingKey) == '1';
  }

  @override
  Future<void> markRefreshPending() {
    return _storage.write(key: _pendingKey, value: '1');
  }

  @override
  Future<void> clearRefreshPending() {
    return _storage.delete(key: _pendingKey);
  }
}

class MemorySessionStore implements SessionStore {
  TokenPair? value;
  bool refreshPending = false;

  @override
  Future<TokenPair?> read() async => value;

  @override
  Future<void> write(TokenPair pair) async {
    value = pair;
    refreshPending = false;
  }

  @override
  Future<void> clear() async {
    value = null;
    refreshPending = false;
  }

  @override
  Future<bool> isRefreshPending() async => refreshPending;

  @override
  Future<void> markRefreshPending() async {
    refreshPending = true;
  }

  @override
  Future<void> clearRefreshPending() async {
    refreshPending = false;
  }
}

abstract class ContextStore {
  Future<String?> readMerchantId();
  Future<void> writeMerchantId(String merchantId);
  Future<String?> readBranchId();
  Future<void> writeBranchId(String branchId);
  Future<void> clear();
}

class SecureContextStore implements ContextStore {
  SecureContextStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const _merchantKey = 'speedygo.merchant.selected-merchant.v1';
  static const _branchKey = 'speedygo.merchant.selected-branch.v1';
  final FlutterSecureStorage _storage;

  @override
  Future<String?> readMerchantId() => _storage.read(key: _merchantKey);

  @override
  Future<void> writeMerchantId(String merchantId) {
    return _storage.write(key: _merchantKey, value: merchantId);
  }

  @override
  Future<String?> readBranchId() => _storage.read(key: _branchKey);

  @override
  Future<void> writeBranchId(String branchId) {
    return _storage.write(key: _branchKey, value: branchId);
  }

  @override
  Future<void> clear() async {
    await _storage.delete(key: _merchantKey);
    await _storage.delete(key: _branchKey);
  }
}

class MemoryContextStore implements ContextStore {
  String? merchantId;
  String? branchId;

  @override
  Future<String?> readMerchantId() async => merchantId;

  @override
  Future<void> writeMerchantId(String id) async => merchantId = id;

  @override
  Future<String?> readBranchId() async => branchId;

  @override
  Future<void> writeBranchId(String id) async => branchId = id;

  @override
  Future<void> clear() async {
    merchantId = null;
    branchId = null;
  }
}

abstract class LaunchStore {
  Future<bool> readLanguageSeen();
  Future<void> markLanguageSeen();
  Future<String> readLocale();
  Future<void> writeLocale(String locale);
  Future<bool> readOnboardingSeen();
  Future<void> markOnboardingSeen();
}

class SecureLaunchStore implements LaunchStore {
  SecureLaunchStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const _languageKey = 'speedygo.merchant.language.v1';
  static const _localeKey = 'speedygo.merchant.locale.v1';

  /// Versioned intro completion — separate from languageSeen and auth tokens.
  static const _onboardingKey = 'speedygo.merchant.onboarding.v1';
  final FlutterSecureStorage _storage;

  @override
  Future<bool> readLanguageSeen() async =>
      await _storage.read(key: _languageKey) == '1';

  @override
  Future<void> markLanguageSeen() =>
      _storage.write(key: _languageKey, value: '1');

  @override
  Future<String> readLocale() async =>
      await _storage.read(key: _localeKey) ?? 'fr';

  @override
  Future<void> writeLocale(String locale) =>
      _storage.write(key: _localeKey, value: locale);

  @override
  Future<bool> readOnboardingSeen() async =>
      await _storage.read(key: _onboardingKey) == '1';

  @override
  Future<void> markOnboardingSeen() =>
      _storage.write(key: _onboardingKey, value: '1');
}

class MemoryLaunchStore implements LaunchStore {
  MemoryLaunchStore({
    this.languageSeen = false,
    this.locale = 'fr',
    this.onboardingSeen = false,
  });
  bool languageSeen;
  String locale;
  bool onboardingSeen;

  @override
  Future<bool> readLanguageSeen() async => languageSeen;

  @override
  Future<void> markLanguageSeen() async => languageSeen = true;

  @override
  Future<String> readLocale() async => locale;

  @override
  Future<void> writeLocale(String value) async => locale = value;

  @override
  Future<bool> readOnboardingSeen() async => onboardingSeen;

  @override
  Future<void> markOnboardingSeen() async => onboardingSeen = true;
}
