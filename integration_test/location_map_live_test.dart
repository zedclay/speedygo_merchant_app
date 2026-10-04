import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:speedygo_merchant_app/app/theme/app_theme.dart';
import 'package:speedygo_merchant_app/core/constants/app_strings.dart';
import 'package:speedygo_merchant_app/core/widgets/merchant_primary_button.dart';
import 'package:speedygo_merchant_app/features/access/presentation/location_picker_screen.dart';

/// Live-device map verification — isolated harness; does NOT touch Finjan.
///
/// Emits `LIVE_MAP_HOST_SHOT=<tag>` markers so a host script can capture via
/// `xcrun simctl io … screenshot` (IntegrationTest takeScreenshot is solid-blue
/// on this simulator / binding).
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpFrames(WidgetTester tester, Duration total) async {
    final end = DateTime.now().add(total);
    while (DateTime.now().isBefore(end)) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> holdForHostShot(String tag) async {
    // Side channel (line-buffered) — stdout via `tee` can flush too late.
    File('/tmp/live_map_host_shot.txt').writeAsStringSync('$tag\n');
    // ignore: avoid_print
    print('LIVE_MAP_HOST_SHOT=$tag');
    await Future<void>.delayed(const Duration(seconds: 10));
  }

  testWidgets('live map tiles, confirm, cancel preserve prior point',
      (tester) async {
    LocationPickResult? first;
    LocationPickResult? afterCancel;
    LocationPickResult? moved;

    final shotDir = Directory(
      '/Users/mac/Downloads/speedygo_project/apps/merchant_app'
      '/audit/registration-verification/captures/live-map',
    )..createSync(recursive: true);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.light(),
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FilledButton(
                        key: const Key('open-picker-1'),
                        onPressed: () async {
                          first = await Navigator.of(context)
                              .push<LocationPickResult>(
                            MaterialPageRoute(
                              builder: (_) => const LocationPickerScreen(
                                initialLatitude: 36.7538,
                                initialLongitude: 3.0588,
                                branchLabel: 'Live Map Fixture',
                                addressHint: 'Alger test',
                              ),
                            ),
                          );
                        },
                        child: const Text('open1'),
                      ),
                      FilledButton(
                        key: const Key('open-picker-2'),
                        onPressed: () async {
                          afterCancel = await Navigator.of(context)
                              .push<LocationPickResult>(
                            MaterialPageRoute(
                              builder: (_) => LocationPickerScreen(
                                initialLatitude: first?.latitude ?? 36.7538,
                                initialLongitude: first?.longitude ?? 3.0588,
                              ),
                            ),
                          );
                        },
                        child: const Text('open2'),
                      ),
                      FilledButton(
                        key: const Key('open-picker-3'),
                        onPressed: () async {
                          moved = await Navigator.of(context)
                              .push<LocationPickResult>(
                            MaterialPageRoute(
                              builder: (_) => LocationPickerScreen(
                                initialLatitude: first?.latitude ?? 36.7538,
                                initialLongitude: first?.longitude ?? 3.0588,
                              ),
                            ),
                          );
                        },
                        child: const Text('open3'),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
    await pumpFrames(tester, const Duration(milliseconds: 500));

    await tester.tap(find.byKey(const Key('open-picker-1')));
    await pumpFrames(tester, const Duration(seconds: 8));
    expect(find.byKey(const Key('merchant-location-picker')), findsOneWidget);
    expect(find.text(AppStrings.regLocationPickerTitle), findsOneWidget);
    await holdForHostShot('picker-tiles');

    final map =
        tester.getCenter(find.byKey(const Key('merchant-location-picker')));
    await tester.dragFrom(map, const Offset(-80, -40));
    await pumpFrames(tester, const Duration(seconds: 2));
    await holdForHostShot('after-pan');

    final cta = tester.widget<MerchantPrimaryButton>(
      find.byKey(const Key('merchant-location-confirm')),
    );
    expect(cta.onPressed, isNotNull);
    await tester.tap(find.byKey(const Key('merchant-location-confirm')));
    await pumpFrames(tester, const Duration(milliseconds: 800));
    expect(first, isNotNull);
    expect(first!.latitude.isFinite, isTrue);
    expect(first!.longitude.isFinite, isTrue);

    await tester.tap(find.byKey(const Key('open-picker-2')));
    await pumpFrames(tester, const Duration(seconds: 3));
    await tester.tap(find.byKey(const Key('merchant-location-use-gps')));
    await pumpFrames(tester, const Duration(seconds: 5));
    await holdForHostShot('after-gps-tap');
    await tester.tap(find.byKey(const Key('merchant-location-back')));
    await pumpFrames(tester, const Duration(milliseconds: 800));
    expect(afterCancel, isNull);

    await tester.tap(find.byKey(const Key('open-picker-3')));
    await pumpFrames(tester, const Duration(seconds: 3));
    final map2 =
        tester.getCenter(find.byKey(const Key('merchant-location-picker')));
    await tester.dragFrom(map2, const Offset(60, 30));
    await pumpFrames(tester, const Duration(seconds: 2));
    await tester.tap(find.byKey(const Key('merchant-location-confirm')));
    await pumpFrames(tester, const Duration(milliseconds: 800));
    expect(moved, isNotNull);

    final result = {
      'confirmedLat': first!.latitude,
      'confirmedLng': first!.longitude,
      'movedLat': moved!.latitude,
      'movedLng': moved!.longitude,
      'pinMoved': moved!.latitude != first!.latitude ||
          moved!.longitude != first!.longitude,
      'cancelReturnedNull': true,
      'shotDir': shotDir.path,
      'gpsSource': 'simulated via simctl (not physical GNSS)',
      'finjanUntouched': true,
      'mapProvider': 'flutter_map + MAP_TILE_URL_TEMPLATE (Carto Voyager for live run)',
      'screenshotNote':
          'Host simctl screenshots via LIVE_MAP_HOST_SHOT markers; '
          'IntegrationTest takeScreenshot returned solid blue on this sim',
    };
    File('${shotDir.path}/live-map-result.json')
        .writeAsStringSync(const JsonEncoder.withIndent('  ').convert(result));
    // ignore: avoid_print
    print('LIVE_MAP_RESULT=${jsonEncode(result)}');
  });
}
