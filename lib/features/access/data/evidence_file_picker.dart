import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Result of an evidence file selection (UI or test fixture).
class EvidencePickedFile {
  const EvidencePickedFile({required this.filename, required this.bytes});

  final String filename;
  final Uint8List bytes;
}

/// Abstraction over [FilePicker] so integration/acceptance tests can inject
/// labeled fixture documents without native pickers.
abstract class EvidenceFilePicker {
  Future<EvidencePickedFile?> pickEvidence();
}

class PlatformEvidenceFilePicker implements EvidenceFilePicker {
  @override
  Future<EvidencePickedFile?> pickEvidence() async {
    final files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'png', 'jpg', 'jpeg'],
    );
    if (files.isEmpty) return null;
    final file = files.first;
    final bytes = await file.readAsBytes();
    return EvidencePickedFile(filename: file.name, bytes: bytes);
  }
}

/// When `--dart-define=ACCEPTANCE_EVIDENCE_PICKER=true`, returns a harmless PNG
/// labeled for SpeedyGo registration lifecycle acceptance.
class AcceptanceFixtureEvidenceFilePicker implements EvidenceFilePicker {
  const AcceptanceFixtureEvidenceFilePicker();

  static const acceptancePickerEnabled = bool.fromEnvironment(
    'ACCEPTANCE_EVIDENCE_PICKER',
    defaultValue: false,
  );

  /// Minimal valid 1×1 PNG (not a real business document).
  static final Uint8List fixturePngBytes = Uint8List.fromList(<int>[
    0x89,
    0x50,
    0x4E,
    0x47,
    0x0D,
    0x0A,
    0x1A,
    0x0A,
    0x00,
    0x00,
    0x00,
    0x0D,
    0x49,
    0x48,
    0x44,
    0x52,
    0x00,
    0x00,
    0x00,
    0x01,
    0x00,
    0x00,
    0x00,
    0x01,
    0x08,
    0x02,
    0x00,
    0x00,
    0x00,
    0x90,
    0x77,
    0x53,
    0xDE,
    0x00,
    0x00,
    0x00,
    0x0C,
    0x49,
    0x44,
    0x41,
    0x54,
    0x08,
    0xD7,
    0x63,
    0xF8,
    0xCF,
    0xC0,
    0x00,
    0x00,
    0x00,
    0x03,
    0x00,
    0x01,
    0x00,
    0x05,
    0xFE,
    0xD4,
    0xEF,
    0x00,
    0x00,
    0x00,
    0x00,
    0x49,
    0x45,
    0x4E,
    0x44,
    0xAE,
    0x42,
    0x60,
    0x82,
  ]);

  @override
  Future<EvidencePickedFile?> pickEvidence() async {
    return EvidencePickedFile(
      filename: 'TEST_FIXTURE_NOT_A_REAL_BUSINESS_DOCUMENT.png',
      bytes: fixturePngBytes,
    );
  }
}

final evidenceFilePickerProvider = Provider<EvidenceFilePicker>((ref) {
  if (AcceptanceFixtureEvidenceFilePicker.acceptancePickerEnabled) {
    return const AcceptanceFixtureEvidenceFilePicker();
  }
  return PlatformEvidenceFilePicker();
});
