import 'package:dio/dio.dart';
import 'package:speedygo_merchant_app/core/constants/app_strings.dart';
import 'package:speedygo_merchant_app/core/errors/app_exception.dart';

AppException mapDioError(Object error) {
  if (error is AppException) return error;
  if (error is DioException) {
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.connectionError) {
      return NetworkException(AppStrings.networkError, code: 'NETWORK');
    }
    final data = error.response?.data;
    String? code;
    String? message;
    int? retryAfter;
    if (data is Map) {
      final err = data['error'];
      if (err is Map) {
        code = err['code']?.toString();
        message = err['message']?.toString();
      }
      final ra = data['retryAfterSeconds'] ?? data['retryAfter'];
      if (ra is int) retryAfter = ra;
      if (ra is String) retryAfter = int.tryParse(ra);
    }
    final header = error.response?.headers.value('retry-after');
    if (retryAfter == null && header != null) {
      retryAfter = int.tryParse(header);
    }
    return ApiException(
      message?.isNotEmpty == true ? message! : AppStrings.errorForCode(code),
      code: code,
      statusCode: error.response?.statusCode,
      retryAfterSeconds: retryAfter,
    );
  }
  return UnexpectedException(error.toString());
}
