import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speedygo_merchant_app/features/access/data/evidence_file_picker.dart';

void main() {
  test('acceptance fixture picker returns labeled PNG bytes', () async {
    final picker = const AcceptanceFixtureEvidenceFilePicker();
    final file = await picker.pickEvidence();
    expect(file, isNotNull);
    expect(
      file!.filename,
      'TEST_FIXTURE_NOT_A_REAL_BUSINESS_DOCUMENT.png',
    );
    expect(file.bytes.length, greaterThan(20));
    expect(file.bytes[0], 0x89);
    expect(file.bytes[1], 0x50); // P
  });

  test('provider defaults to platform picker without dart-define', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    expect(
      container.read(evidenceFilePickerProvider),
      isA<PlatformEvidenceFilePicker>(),
    );
  });
}
