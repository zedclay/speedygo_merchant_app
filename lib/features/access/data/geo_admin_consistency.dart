import 'package:latlong2/latlong.dart';
import 'package:speedygo_merchant_app/features/access/data/map_config.dart';

/// Administrative wilaya envelopes are **not** delivery coverage.
/// Coverage stays polygonal [DeliveryZone] `ST_Covers` on the confirmed pin.
/// Changing wilaya must never rewrite the confirmed point (no city-centre snap).
class GeoAdminConsistency {
  const GeoAdminConsistency._();

  /// Coarse envelopes used only to surface catalogue vs pin mismatch.
  /// Unknown codes return null (no guess, no rewrite).
  static ({double minLat, double maxLat, double minLng, double maxLng})?
  envelopeFor(String? wilayaCode) {
    return switch (wilayaCode) {
      '16' => (minLat: 36.55, maxLat: 36.95, minLng: 2.70, maxLng: 3.50),
      '22' => (minLat: 34.70, maxLat: 35.50, minLng: -1.05, maxLng: -0.20),
      '31' => (minLat: 35.40, maxLat: 36.05, minLng: -1.10, maxLng: -0.30),
      _ => null,
    };
  }

  static LatLng cameraForWilaya(String? wilayaCode) {
    return switch (wilayaCode) {
      '16' => const LatLng(36.7538, 3.0588),
      '31' => const LatLng(35.6971, -0.6337),
      '22' => const LatLng(
        MerchantMapConfig.explorationLatitude,
        MerchantMapConfig.explorationLongitude,
      ),
      _ => const LatLng(
        MerchantMapConfig.explorationLatitude,
        MerchantMapConfig.explorationLongitude,
      ),
    };
  }

  static bool pinMatchesWilaya({
    required String? wilayaCode,
    required double? latitude,
    required double? longitude,
  }) {
    if (wilayaCode == null ||
        wilayaCode.isEmpty ||
        latitude == null ||
        longitude == null) {
      return true;
    }
    if (!latitude.isFinite || !longitude.isFinite) {
      return true;
    }
    final box = envelopeFor(wilayaCode);
    if (box == null) {
      return true;
    }
    return latitude >= box.minLat &&
        latitude <= box.maxLat &&
        longitude >= box.minLng &&
        longitude <= box.maxLng;
  }
}
