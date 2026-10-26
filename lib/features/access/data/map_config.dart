import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Map rendering and Places lookup configuration for the Merchant picker.
///
/// Places Autocomplete (New) and Geocoding stay on the Backend
/// (`GOOGLE_MAPS_API_KEY`, never dart-defined). Official policy: Places and
/// Geocoding results shown on a map must be on a Google Map. OSM is an
/// explicit development-only mode (`MAP_DEV_OSM=true`) with Google lookups
/// disabled. Missing Maps SDK keys without that flag is an unavailable state.
enum MapRenderMode { google, osmDev, unavailable }

class MerchantMapConfig {
  const MerchantMapConfig._();

  static const googleMapsIosApiKey = String.fromEnvironment(
    'GOOGLE_MAPS_IOS_API_KEY',
    defaultValue: '',
  );

  static const googleMapsAndroidApiKey = String.fromEnvironment(
    'GOOGLE_MAPS_ANDROID_API_KEY',
    defaultValue: '',
  );

  /// Explicit development fallback. Must not be combined with Places lookups.
  static const osmDevMode = bool.fromEnvironment(
    'MAP_DEV_OSM',
    defaultValue: false,
  );

  static bool get hasNativeMapsSdkKey {
    final ios = googleMapsIosApiKey.trim().isNotEmpty;
    final android = googleMapsAndroidApiKey.trim().isNotEmpty;
    if (kIsWeb) {
      return false;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.android:
        return android;
      default:
        return ios || android;
    }
  }

  static const _defaultOsmTileUrl =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

  static const tileUrlTemplate = String.fromEnvironment(
    'MAP_TILE_URL_TEMPLATE',
    defaultValue: _defaultOsmTileUrl,
  );

  static const osmAttribution = '© OpenStreetMap contributors';

  static const userAgentPackageName = 'com.speedygo.speedygoMerchantApp';

  static const iosBundleId = 'com.speedygo.speedygoMerchantApp';
  static const androidApplicationId = 'com.speedygo.speedygo_merchant_app';

  /// Sidi Bel Abbès centre — camera start only, never auto-saved.
  static const explorationLatitude = 35.1939;
  static const explorationLongitude = -0.6417;
  static const explorationZoom = 13.0;
  static const confirmedZoom = 16.0;

  static String get configurationBlocker {
    final parts = <String>[
      'Places/Geocoding use Backend GOOGLE_MAPS_API_KEY only (never dart-defined).',
      if (!hasNativeMapsSdkKey && !osmDevMode)
        'GOOGLE_MAPS_IOS_API_KEY / GOOGLE_MAPS_ANDROID_API_KEY unset and MAP_DEV_OSM is false — picker is unavailable.',
      if (osmDevMode)
        'MAP_DEV_OSM=true — OSM development map only; Google Places/Geocoding lookups are disabled.',
    ];
    return parts.join(' ');
  }
}

class MapRuntimeConfig {
  const MapRuntimeConfig({
    required this.googleMapsReady,
    required this.osmDevMode,
  });

  final bool googleMapsReady;
  final bool osmDevMode;

  MapRenderMode get mode {
    if (googleMapsReady) {
      return MapRenderMode.google;
    }
    if (osmDevMode) {
      return MapRenderMode.osmDev;
    }
    return MapRenderMode.unavailable;
  }

  bool get placesLookupEnabled => mode == MapRenderMode.google;
}

final mapRuntimeConfigProvider = Provider<MapRuntimeConfig>((ref) {
  return MapRuntimeConfig(
    googleMapsReady: MerchantMapConfig.hasNativeMapsSdkKey,
    osmDevMode: MerchantMapConfig.osmDevMode,
  );
});

/// Widget tests set this so GoogleMap platform views are not created.
final locationMapStubProvider = Provider<bool>((ref) => false);
