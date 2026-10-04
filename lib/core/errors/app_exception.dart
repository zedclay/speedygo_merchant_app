sealed class AppException implements Exception {
  const AppException(
    this.message, {
    this.code,
    this.statusCode,
    this.retryAfterSeconds,
  });

  final String message;
  final String? code;
  final int? statusCode;
  final int? retryAfterSeconds;

  @override
  String toString() => message;
}

class NetworkException extends AppException {
  const NetworkException(
    super.message, {
    super.code,
    super.statusCode,
    super.retryAfterSeconds,
  });
}

class ApiException extends AppException {
  const ApiException(
    super.message, {
    super.code,
    super.statusCode,
    super.retryAfterSeconds,
  });

  bool get isAuthFailure =>
      code == 'AUTH_INVALID_TOKEN' ||
      code == 'AUTH_SESSION_REVOKED' ||
      code == 'AUTH_SESSION_EXPIRED';

  bool get isAccountBlocked =>
      code == 'AUTH_ACCOUNT_SUSPENDED' || code == 'AUTH_ACCOUNT_DISABLED';
}

class RefreshAmbiguousException extends AppException {
  const RefreshAmbiguousException()
    : super(
        'Reconnectez-vous pour continuer. L’ancienne session n’est plus utilisable ici.',
        code: 'AUTH_REFRESH_AMBIGUOUS',
      );
}

class UnexpectedException extends AppException {
  const UnexpectedException(super.message, {super.code, super.statusCode});
}
