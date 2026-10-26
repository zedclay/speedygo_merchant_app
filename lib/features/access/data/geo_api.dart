import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speedygo_merchant_app/core/constants/app_constants.dart';
import 'package:speedygo_merchant_app/core/errors/app_exception.dart';
import 'package:speedygo_merchant_app/core/network/api_error_parser.dart';
import 'package:speedygo_merchant_app/features/auth/application/auth_infrastructure.dart';

class PlaceSuggestion {
  const PlaceSuggestion({required this.placeId, required this.text});

  final String placeId;
  final String text;
}

class PlaceDetails {
  const PlaceDetails({
    required this.placeId,
    required this.latitude,
    required this.longitude,
    this.formattedAddress,
  });

  final String placeId;
  final double latitude;
  final double longitude;
  final String? formattedAddress;
}

class GeocodingNotConfiguredException extends ApiException {
  const GeocodingNotConfiguredException()
    : super(
        'Address search is not configured',
        code: 'GEO_GEOCODING_NOT_CONFIGURED',
      );
}

class MerchantGeoClient {
  MerchantGeoClient(this._dio);

  final Dio _dio;

  Future<List<PlaceSuggestion>> autocomplete({
    required String q,
    String language = 'fr',
    String? sessionToken,
  }) async {
    try {
      final token = sessionToken?.trim();
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.geoPlacesAutocomplete,
        queryParameters: {
          'q': q,
          'language': language,
          if (token != null && token.isNotEmpty) 'sessionToken': token,
        },
      );
      final raw = response.data?['suggestions'];
      if (raw is! List) return const [];
      return raw
          .whereType<Map>()
          .map(
            (row) => PlaceSuggestion(
              placeId: row['placeId']?.toString() ?? '',
              text: row['text']?.toString() ?? '',
            ),
          )
          .where((row) => row.placeId.isNotEmpty && row.text.isNotEmpty)
          .toList();
    } on DioException catch (error) {
      final parsed = mapDioError(error);
      if (parsed.code == 'GEO_GEOCODING_NOT_CONFIGURED') {
        throw const GeocodingNotConfiguredException();
      }
      throw parsed;
    }
  }

  Future<PlaceDetails> placeDetails({
    required String placeId,
    String language = 'fr',
    String? sessionToken,
  }) async {
    try {
      final token = sessionToken?.trim();
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.geoPlacesDetails,
        queryParameters: {
          'placeId': placeId,
          'language': language,
          if (token != null && token.isNotEmpty) 'sessionToken': token,
        },
      );
      final data = response.data;
      final lat = (data?['latitude'] as num?)?.toDouble();
      final lng = (data?['longitude'] as num?)?.toDouble();
      if (lat == null || lng == null) {
        throw const ApiException(
          'Place details did not include a usable point',
          code: 'GEO_LOCATION_INVALID',
        );
      }
      final formatted = data?['formattedAddress']?.toString().trim();
      return PlaceDetails(
        placeId: data?['placeId']?.toString() ?? placeId,
        latitude: lat,
        longitude: lng,
        formattedAddress: (formatted == null || formatted.isEmpty)
            ? null
            : formatted,
      );
    } on DioException catch (error) {
      final parsed = mapDioError(error);
      if (parsed.code == 'GEO_GEOCODING_NOT_CONFIGURED') {
        throw const GeocodingNotConfiguredException();
      }
      throw parsed;
    }
  }
}

final merchantGeoClientProvider = Provider<MerchantGeoClient>((ref) {
  return MerchantGeoClient(ref.watch(authInfrastructureProvider).dio);
});
