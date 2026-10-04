import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// flutter_map's built-in tile cache asks path_provider for a cache directory.
/// Widget tests have no platform plugin, so answer every directory query with
/// an isolated temp directory.
void installPathProviderFixture() {
  final dir = Directory.systemTemp.createTempSync('merchant_test_paths_');
  const channel = MethodChannel('plugins.flutter.io/path_provider');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  setUpAll(() {
    messenger.setMockMethodCallHandler(channel, (call) async => dir.path);
  });
  tearDownAll(() {
    messenger.setMockMethodCallHandler(channel, null);
    if (dir.existsSync()) dir.deleteSync(recursive: true);
  });
}
