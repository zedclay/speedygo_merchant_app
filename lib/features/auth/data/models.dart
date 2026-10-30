import 'package:flutter/foundation.dart';

class SessionParseException implements Exception {
  const SessionParseException();
}

class TokenPair {
  const TokenPair({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
    required this.tokenType,
  });

  final String accessToken;
  final String refreshToken;
  final int expiresIn;
  final String tokenType;

  factory TokenPair.fromJson(Map<String, dynamic> json) {
    final access = json['accessToken']?.toString();
    final refresh = json['refreshToken']?.toString();
    final type = json['tokenType']?.toString() ?? 'Bearer';
    final expires = json['expiresIn'];
    if (access == null ||
        access.isEmpty ||
        refresh == null ||
        refresh.isEmpty) {
      throw const SessionParseException();
    }
    return TokenPair(
      accessToken: access,
      refreshToken: refresh,
      expiresIn: expires is int ? expires : int.tryParse('$expires') ?? 0,
      tokenType: type,
    );
  }

  Map<String, dynamic> toJson() => {
    'accessToken': accessToken,
    'refreshToken': refreshToken,
    'expiresIn': expiresIn,
    'tokenType': tokenType,
  };
}

class OtpRequestBody {
  const OtpRequestBody({required this.identifier});
  final String identifier;

  Map<String, dynamic> toJson() => {
    'channel': 'PHONE',
    'identifier': identifier,
    'purpose': 'AUTHENTICATE',
  };
}

/// Backend `DevicePlatform`: `ios` | `android` | `web`.
String authOtpVerifyPlatform({
  TargetPlatform? platform,
  bool? isWeb,
}) {
  if (isWeb ?? kIsWeb) {
    return 'web';
  }
  switch (platform ?? defaultTargetPlatform) {
    case TargetPlatform.iOS:
      return 'ios';
    case TargetPlatform.android:
      return 'android';
    case TargetPlatform.macOS:
    case TargetPlatform.windows:
    case TargetPlatform.linux:
    case TargetPlatform.fuchsia:
      return 'web';
  }
}

class OtpVerifyBody {
  const OtpVerifyBody({
    required this.identifier,
    required this.code,
    required this.platform,
    this.appVersion = '1.0.0',
  });

  factory OtpVerifyBody.forDevice({
    required String identifier,
    required String code,
    String appVersion = '1.0.0',
  }) {
    return OtpVerifyBody(
      identifier: identifier,
      code: code,
      platform: authOtpVerifyPlatform(),
      appVersion: appVersion,
    );
  }

  final String identifier;
  final String code;
  final String platform;
  final String appVersion;

  Map<String, dynamic> toJson() => {
    'channel': 'PHONE',
    'identifier': identifier,
    'purpose': 'AUTHENTICATE',
    'code': code,
    'platform': platform,
    'appVersion': appVersion,
  };
}

class AuthMe {
  const AuthMe({
    required this.accountId,
    required this.phone,
    required this.status,
    required this.hasMerchantMembership,
  });

  final String accountId;
  final String? phone;
  final String status;
  final bool hasMerchantMembership;

  factory AuthMe.fromJson(Map<String, dynamic> json) {
    final account = json['account'];
    final profiles = json['profiles'];
    if (account is! Map) throw const SessionParseException();
    return AuthMe(
      accountId: account['id']?.toString() ?? '',
      phone: account['phone']?.toString(),
      status: account['status']?.toString() ?? '',
      hasMerchantMembership: profiles is Map
          ? profiles['hasMerchantMembership'] == true
          : false,
    );
  }
}
