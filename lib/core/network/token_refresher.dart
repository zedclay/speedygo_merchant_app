import 'package:speedygo_merchant_app/core/errors/app_exception.dart';
import 'package:speedygo_merchant_app/core/storage/session_store.dart';
import 'package:speedygo_merchant_app/features/auth/application/session_providers.dart';
import 'package:speedygo_merchant_app/features/auth/data/auth_api.dart';
import 'package:speedygo_merchant_app/features/auth/data/models.dart';

typedef SessionGeneration = int Function();

/// Single-flight refresh (Merchant-owned store/cache — not Customer keys).
class TokenRefresher {
  TokenRefresher({
    required AuthClient authApi,
    required SessionStore store,
    required TokenCache cache,
    required SessionGeneration currentGeneration,
  }) : _authApi = authApi,
       _store = store,
       _cache = cache,
       _currentGeneration = currentGeneration;

  final AuthClient _authApi;
  final SessionStore _store;
  final TokenCache _cache;
  final SessionGeneration _currentGeneration;

  Future<TokenPair>? _inFlight;
  int _refreshCount = 0;
  int get refreshCount => _refreshCount;

  Future<TokenPair> ensureFresh({String? failedAccessToken}) {
    final cached = _cache.current;
    if (_alreadyRotated(cached, failedAccessToken)) {
      return Future<TokenPair>.value(cached);
    }
    return _inFlight ??= _run();
  }

  Future<TokenPair> _run() async {
    final generation = _currentGeneration();
    try {
      if (await _store.isRefreshPending()) {
        await _dropLocalPair();
        throw const RefreshAmbiguousException();
      }
      final session = _cache.current ?? await _store.read();
      final refreshToken = session?.refreshToken;
      if (refreshToken == null || refreshToken.isEmpty) {
        throw const ApiException(
          'Session remplacée.',
          code: 'AUTH_INVALID_TOKEN',
        );
      }
      await _store.markRefreshPending();
      _refreshCount += 1;
      final pair = await _authApi.refresh(refreshToken);
      if (_currentGeneration() != generation) {
        throw const ApiException(
          'Session remplacée.',
          code: 'AUTH_STALE_REFRESH',
        );
      }
      await _store.write(pair);
      await _store.clearRefreshPending();
      if (_currentGeneration() != generation) {
        throw const ApiException(
          'Session remplacée.',
          code: 'AUTH_STALE_REFRESH',
        );
      }
      _cache.current = pair;
      return pair;
    } on RefreshAmbiguousException {
      await _dropLocalPair();
      rethrow;
    } on ApiException catch (error) {
      if (error.isAuthFailure) {
        await _dropLocalPair();
      } else {
        await _store.clearRefreshPending();
      }
      rethrow;
    } catch (_) {
      await _store.clearRefreshPending();
      rethrow;
    } finally {
      _inFlight = null;
    }
  }

  bool _alreadyRotated(TokenPair? current, String? failedAccessToken) {
    if (current == null ||
        failedAccessToken == null ||
        failedAccessToken.isEmpty) {
      return false;
    }
    return current.accessToken != failedAccessToken;
  }

  Future<void> _dropLocalPair() async {
    _cache.current = null;
    await _store.clear();
  }
}
