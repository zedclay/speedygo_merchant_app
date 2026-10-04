import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speedygo_merchant_app/core/constants/app_constants.dart';
import 'package:speedygo_merchant_app/core/network/api_client.dart';
import 'package:speedygo_merchant_app/core/network/api_config.dart';
import 'package:speedygo_merchant_app/core/network/token_refresher.dart';
import 'package:speedygo_merchant_app/features/access/data/merchant_api.dart';
import 'package:speedygo_merchant_app/features/auth/application/session_providers.dart';
import 'package:speedygo_merchant_app/features/auth/data/auth_api.dart';

class AuthInfrastructure {
  AuthInfrastructure({
    required this.authApi,
    required this.merchantApi,
    required this.refresher,
    required this.config,
    required this.dio,
  });

  final AuthApi authApi;
  final MerchantApi merchantApi;
  final TokenRefresher refresher;
  final ApiConfig config;
  final Dio dio;
}

final apiConfigProvider = Provider<ApiConfig>((ref) {
  return const ApiConfig(apiBaseUrl: AppConstants.apiBaseUrl);
});

final authInfrastructureProvider = Provider<AuthInfrastructure>((ref) {
  final config = ref.watch(apiConfigProvider);
  final store = ref.watch(sessionStoreProvider);
  final cache = ref.watch(tokenCacheProvider);
  final epoch = ref.watch(sessionEpochProvider);
  final refreshDio = createRefreshClient(config: config);
  final refreshApi = AuthApi(dio: refreshDio, refreshDio: refreshDio);
  final refresher = TokenRefresher(
    authApi: refreshApi,
    store: store,
    cache: cache,
    currentGeneration: () => epoch.value,
  );
  final dio = createApiClient(
    config: config,
    readSession: () async => cache.current ?? await store.read(),
    refresher: refresher,
    onSessionInvalid: () async {
      cache.current = null;
      await store.clear();
      epoch.value += 1;
      await cache.onAuthFailure?.call();
    },
  );
  return AuthInfrastructure(
    authApi: AuthApi(dio: dio, refreshDio: refreshDio),
    merchantApi: MerchantApi(dio),
    refresher: refresher,
    config: config,
    dio: dio,
  );
});

final authApiProvider = Provider<AuthClient>((ref) {
  return ref.watch(authInfrastructureProvider).authApi;
});

final merchantApiProvider = Provider<MerchantClient>((ref) {
  return ref.watch(authInfrastructureProvider).merchantApi;
});
