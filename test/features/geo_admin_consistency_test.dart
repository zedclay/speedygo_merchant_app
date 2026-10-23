import 'package:flutter_test/flutter_test.dart';
import 'package:speedygo_merchant_app/features/access/data/geo_admin_consistency.dart';
import 'package:speedygo_merchant_app/features/access/data/models.dart';

void main() {
  test('SBA pin matches wilaya 22 and not Oran or Algiers', () {
    expect(
      GeoAdminConsistency.pinMatchesWilaya(
        wilayaCode: '22',
        latitude: 35.1939,
        longitude: -0.6417,
      ),
      isTrue,
    );
    expect(
      GeoAdminConsistency.pinMatchesWilaya(
        wilayaCode: '31',
        latitude: 35.1939,
        longitude: -0.6417,
      ),
      isFalse,
    );
    expect(
      GeoAdminConsistency.pinMatchesWilaya(
        wilayaCode: '16',
        latitude: 35.1939,
        longitude: -0.6417,
      ),
      isFalse,
    );
  });

  test('Algiers pin mismatches SBA and Oran catalogues', () {
    expect(
      GeoAdminConsistency.pinMatchesWilaya(
        wilayaCode: '22',
        latitude: 36.7538,
        longitude: 3.0588,
      ),
      isFalse,
    );
    expect(
      GeoAdminConsistency.pinMatchesWilaya(
        wilayaCode: '31',
        latitude: 36.7538,
        longitude: 3.0588,
      ),
      isFalse,
    );
    expect(
      GeoAdminConsistency.pinMatchesWilaya(
        wilayaCode: '16',
        latitude: 36.7538,
        longitude: 3.0588,
      ),
      isTrue,
    );
  });

  test('changing wilaya does not invent a replacement point', () {
    const lat = 36.7538;
    const lng = 3.0588;
    expect(
      GeoAdminConsistency.cameraForWilaya('22').latitude,
      isNot(closeTo(lat, 0.01)),
    );
    expect(
      GeoAdminConsistency.pinMatchesWilaya(
        wilayaCode: '22',
        latitude: lat,
        longitude: lng,
      ),
      isFalse,
    );
  });

  test('branch JSON accepts Numeric coordinates as strings', () {
    final branch = MerchantBranch.fromJson({
      'id': '0d00c071-d000-7000-8000-000000011001',
      'name': 'Dar El Bahja',
      'phone': '+213550000071',
      'addressText': 'SBA',
      'latitude': '35.193900',
      'longitude': '-0.641700',
      'operationalStatus': 'ACTIVE',
      'wilayaCode': '22',
      'communeId': 824,
    });
    expect(branch.latitude, closeTo(35.1939, 0.000001));
    expect(branch.longitude, closeTo(-0.6417, 0.000001));
    expect(branch.wilayaCode, '22');
    expect(branch.communeId, 824);
  });
}