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

class OtpVerifyBody {
  const OtpVerifyBody({
    required this.identifier,
    required this.code,
    this.platform = 'ios',
    this.appVersion = '1.0.0',
  });

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
