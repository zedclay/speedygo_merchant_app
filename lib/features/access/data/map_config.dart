/// Map / geocoding configuration for Merchant location picker.
///
/// ## Declared SpeedyGo provider
/// Backend `.env.example` includes `GOOGLE_MAPS_API_KEY=` (empty). Neither
/// Merchant nor Customer wires the Google Maps mobile SDK today. No Merchant
/// geocoding/Places API exists — address search is therefore omitted.
///
/// ## What this build uses
/// Interactive map: [flutter_map] + raster tiles.
/// - Override tiles (recommended for production):
///   `--dart-define=MAP_TILE_URL_TEMPLATE=https://…/{z}/{x}/{y}.png`
/// - Default local/dev template points at OpenStreetMap public tiles with
///   attribution + package User-Agent. OSMF tile policy may **not** permit
///   production app traffic — treat default as a **configuration blocker**
///   until a licensed tile endpoint or Google Maps SDK key is provisioned.
///
/// Address search is proxied by Backend `GET /geo/places/*` and fail-closed
/// when `GOOGLE_MAPS_API_KEY` is empty (503 GEO_GEOCODING_NOT_CONFIGURED).
/// GPS (“Utiliser ma position”) is always a suggestion; never auto-confirms.
class MerchantMapConfig {
  const MerchantMapConfig._();

  static const googleMapsApiKey = String.fromEnvironment(
    'GOOGLE_MAPS_API_KEY',
    defaultValue: '',
  );

  static bool get hasGoogleMapsKey => googleMapsApiKey.trim().isNotEmpty;

  static const _defaultOsmTileUrl =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

  static const tileUrlTemplate = String.fromEnvironment(
    'MAP_TILE_URL_TEMPLATE',
    defaultValue: _defaultOsmTileUrl,
  );

  static bool get usingDefaultOsmTiles => tileUrlTemplate == _defaultOsmTileUrl;

  static const osmAttribution = '© OpenStreetMap contributors';

  static const userAgentPackageName = 'com.speedygo.speedygo_merchant_app';

  /// Sidi Bel Abbès camera start — never auto-saved.
  static const explorationLatitude = 35.1939;
  static const explorationLongitude = -0.6417;
  static const explorationZoom = 13.0;
  static const confirmedZoom = 16.0;

  static bool get addressSearchSupported => true;

  static String get configurationBlocker {
    final parts = <String>[
      if (!hasGoogleMapsKey)
        'GOOGLE_MAPS_API_KEY is empty (backend .env / --dart-define). '
            'Google Maps SDK is not integrated in Merchant.',
      if (usingDefaultOsmTiles)
        'MAP_TILE_URL_TEMPLATE unset — default OpenStreetMap public tiles '
            'are for limited/dev use only (OSMF tile policy). Provision a '
            'licensed tile URL or Google Maps SDK before production.',
      'Live Places/Geocoding requires Backend GOOGLE_MAPS_API_KEY. Empty key is fail-closed (503).',
    ];
    return parts.join(' ');
  }
}
