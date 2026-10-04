import 'package:dio/dio.dart';
import 'package:speedygo_merchant_app/core/constants/app_constants.dart';
import 'package:speedygo_merchant_app/core/errors/app_exception.dart';
import 'package:speedygo_merchant_app/core/network/api_config.dart';
import 'package:speedygo_merchant_app/core/network/token_refresher.dart';
import 'package:speedygo_merchant_app/features/auth/data/models.dart';

typedef AccessTokenReader = Future<TokenPair?> Function();
typedef OnSessionInvalid = Future<void> Function();

Dio createApiClient({
  required ApiConfig config,
  AccessTokenReader? readSession,
  TokenRefresher? refresher,
  OnSessionInvalid? onSessionInvalid,
}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: config.apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 20),
      headers: const {'Accept': 'application/json'},
    ),
  );
  if (readSession != null && refresher != null) {
    dio.interceptors.add(
      AuthInterceptor(
        dio: dio,
        readSession: readSession,
        refresher: refresher,
        onSessionInvalid: onSessionInvalid,
      ),
    );
  }
  return dio;
}

Dio createRefreshClient({required ApiConfig config}) {
  return Dio(
    BaseOptions(
      baseUrl: config.apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      headers: const {'Accept': 'application/json'},
    ),
  );
}

class AuthInterceptor extends QueuedInterceptor {
  AuthInterceptor({
    required Dio dio,
    required this.readSession,
    required this.refresher,
    this.onSessionInvalid,
  }) : _dio = dio;

  final Dio _dio;
  final AccessTokenReader readSession;
  final TokenRefresher refresher;
  final OnSessionInvalid? onSessionInvalid;

  static const _retryExtra = 'speedygo.retry';

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (!_isPublic(options.path)) {
      final session = await readSession();
      final token = session?.accessToken;
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final status = err.response?.statusCode;
    final alreadyRetried = err.requestOptions.extra[_retryExtra] == true;
    if (status != 401 || alreadyRetried || _isPublic(err.requestOptions.path)) {
      handler.next(err);
      return;
    }

    final failedAccess = _accessTokenOf(err.requestOptions);
    final session = await readSession();
    if (session == null || session.refreshToken.isEmpty) {
      handler.next(err);
      return;
    }

    try {
      final TokenPair usable;
      if (failedAccess != null &&
          failedAccess.isNotEmpty &&
          session.accessToken != failedAccess) {
        usable = session;
      } else {
        usable = await refresher.ensureFresh(failedAccessToken: failedAccess);
      }
      final request = err.requestOptions;
      request.headers['Authorization'] = 'Bearer ${usable.accessToken}';
      request.extra[_retryExtra] = true;
      final response = await _dio.fetch<dynamic>(request);
      handler.resolve(response);
    } on RefreshAmbiguousException {
      await onSessionInvalid?.call();
      handler.next(err);
    } on ApiException catch (error) {
      if (error.isAuthFailure || error.code == 'AUTH_STALE_REFRESH') {
        await onSessionInvalid?.call();
      }
      handler.next(err);
    } catch (_) {
      handler.next(err);
    }
  }

  String? _accessTokenOf(RequestOptions options) {
    final raw = options.headers['Authorization']?.toString();
    if (raw == null || !raw.startsWith('Bearer ')) return null;
    return raw.substring(7);
  }

  bool _isPublic(String path) {
    return path.contains(ApiEndpoints.otpRequestPath) ||
        path.contains(ApiEndpoints.otpVerifyPath) ||
        path.contains(ApiEndpoints.refreshPath);
  }
}
