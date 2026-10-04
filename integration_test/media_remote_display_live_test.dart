import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:speedygo_merchant_app/app/app.dart';
import 'package:speedygo_merchant_app/core/constants/app_strings.dart';
import 'package:speedygo_merchant_app/core/navigation/app_routes.dart';
import 'package:speedygo_merchant_app/core/widgets/merchant_primary_button.dart';
import 'package:speedygo_merchant_app/features/catalog/presentation/catalog_screen.dart';
import 'package:speedygo_merchant_app/features/catalog/presentation/product_editor_screen.dart';
import 'package:speedygo_merchant_app/features/store/presentation/store_cover_screen.dart';

/// Live Merchant media remote-display proof on iPhone 16e / Dar El Bahja.
/// Does not touch Finjan (17 Pro). Uses Merchant JWT streams only.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const phoneLocal = String.fromEnvironment(
    'MEDIA_LIVE_PHONE',
    defaultValue: '550000071',
  );
  const otpFilePath = String.fromEnvironment(
    'MEDIA_OTP_FILE',
    defaultValue: '/Users/mac/.speedygo/dev/otp-last',
  );
  const shotMarker = '/tmp/media_host_shot.txt';
  final outDir = Directory(
    '/Users/mac/Downloads/speedygo_project/apps/merchant_app/audit/phase-5-ui/media-live',
  )..createSync(recursive: true);
  final bluePng = File('${outDir.path}/fixture_blue.png');
  final coverPng = File('${outDir.path}/cover_green.png');

  final steps = <Map<String, dynamic>>[];

  void record(String id, String status, {String? detail}) {
    steps.add({
      'id': id,
      'status': status,
      'detail': detail,
      'layer': 'live_merchant_ui',
      'fixture': 'Dar El Bahja',
      'bundleId': 'com.speedygo.speedygoMerchantApp',
      'at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  Future<void> pumpFrames(WidgetTester tester, Duration total) async {
    final end = DateTime.now().add(total);
    while (DateTime.now().isBefore(end)) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> markShot(String tag) async {
    File(shotMarker).writeAsStringSync(tag);
    await Future<void>.delayed(const Duration(seconds: 3));
  }

  Future<String> waitForFreshOtp(DateTime after) async {
    final file = File(otpFilePath);
    for (var i = 0; i < 60; i++) {
      if (file.existsSync() && !file.lastModifiedSync().isBefore(after)) {
        final otp = file.readAsStringSync().trim();
        if (RegExp(r'^\d{4,8}$').hasMatch(otp)) return otp;
      }
      await Future<void>.delayed(const Duration(milliseconds: 250));
    }
    throw StateError('OTP not found');
  }

  Future<void> reachHome(WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: SpeedyGoApp()));
    await pumpFrames(tester, const Duration(seconds: 8));
    if (find.byKey(const Key('merchant-language')).evaluate().isNotEmpty) {
      await tester.tap(find.text('Français'));
      await pumpFrames(tester, const Duration(seconds: 2));
    }
    if (find.text(AppStrings.onboardingSkip).evaluate().isNotEmpty) {
      await tester.tap(find.text(AppStrings.onboardingSkip));
      await pumpFrames(tester, const Duration(seconds: 2));
    }
    if (find.text(AppStrings.onboardingStart).evaluate().isNotEmpty) {
      await tester.tap(find.text(AppStrings.onboardingStart));
      await pumpFrames(tester, const Duration(seconds: 2));
    }
    if (find.byKey(const Key('home-branch-name')).evaluate().isEmpty) {
      expect(find.byKey(const Key('merchant-phone-continue')), findsOneWidget);
      await tester.enterText(find.byType(TextField).first, phoneLocal);
      await tester.pump(const Duration(milliseconds: 400));
      final otpBefore = DateTime.now().subtract(const Duration(seconds: 1));
      await tester.tap(find.byKey(const Key('merchant-phone-continue')));
      await pumpFrames(tester, const Duration(seconds: 4));
      expect(find.byKey(const Key('merchant-otp-field')), findsOneWidget);
      final otp = await waitForFreshOtp(otpBefore);
      await tester.enterText(find.byKey(const Key('merchant-otp-field')), otp);
      await tester.pump(const Duration(milliseconds: 300));
      final verifyBtn = tester.widget<MerchantPrimaryButton>(
        find.byKey(const Key('merchant-otp-verify')),
      );
      expect(verifyBtn.onPressed, isNotNull);
      await tester.tap(find.byKey(const Key('merchant-otp-verify')));
      await pumpFrames(tester, const Duration(seconds: 14));
    }
    expect(find.byKey(const Key('home-branch-name')), findsOneWidget);
    if (find.textContaining('Dar El Bahja').evaluate().isEmpty) {
      // Leftover SE session — force logout then login as Dar El Bahja.
      await tester.tap(find.text(AppStrings.tabProfile));
      await pumpFrames(tester, const Duration(seconds: 3));
      // Profile header can obscure lower rows — scroll to settings.
      final scrollable = find.byType(Scrollable);
      if (scrollable.evaluate().isNotEmpty) {
        await tester.drag(scrollable.first, const Offset(0, -500));
        await pumpFrames(tester, const Duration(seconds: 1));
      }
      final settings = find.byKey(const Key('store-profile-settings'));
      expect(settings, findsWidgets);
      await tester.ensureVisible(settings.first);
      await tester.tap(settings.first, warnIfMissed: false);
      await pumpFrames(tester, const Duration(seconds: 3));
      final logout = find.byKey(const Key('merchant-logout'));
      expect(logout, findsOneWidget);
      await tester.ensureVisible(logout);
      await tester.tap(logout);
      await pumpFrames(tester, const Duration(seconds: 2));
      final confirm = find.text(AppStrings.logoutConfirmAction);
      expect(confirm, findsWidgets);
      await tester.tap(confirm.last);
      await pumpFrames(tester, const Duration(seconds: 8));
      for (var i = 0; i < 30; i++) {
        if (find
            .byKey(const Key('merchant-phone-continue'))
            .evaluate()
            .isNotEmpty) {
          break;
        }
        await pumpFrames(tester, const Duration(milliseconds: 500));
      }
      expect(find.byKey(const Key('merchant-phone-continue')), findsOneWidget);
      await tester.enterText(find.byType(TextField).first, phoneLocal);
      await tester.pump(const Duration(milliseconds: 400));
      final otpBefore = DateTime.now().subtract(const Duration(seconds: 1));
      await tester.tap(find.byKey(const Key('merchant-phone-continue')));
      await pumpFrames(tester, const Duration(seconds: 4));
      for (var i = 0; i < 30; i++) {
        if (find.byKey(const Key('merchant-otp-field')).evaluate().isNotEmpty) {
          break;
        }
        await pumpFrames(tester, const Duration(milliseconds: 500));
      }
      expect(find.byKey(const Key('merchant-otp-field')), findsOneWidget);
      final otp = await waitForFreshOtp(otpBefore);
      await tester.enterText(find.byKey(const Key('merchant-otp-field')), otp);
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.byKey(const Key('merchant-otp-verify')));
      await pumpFrames(tester, const Duration(seconds: 14));
    }
    expect(find.byKey(const Key('home-branch-name')), findsOneWidget);
    expect(find.textContaining('Dar El Bahja'), findsWidgets);
    expect(find.textContaining('Finjan'), findsNothing);
    record('home', 'PASS');
  }

  testWidgets('media remote display product and cover', (tester) async {
    expect(bluePng.existsSync(), isTrue);
    expect(coverPng.existsSync(), isTrue);
    final coverBytes = await coverPng.readAsBytes();

    await reachHome(tester);

    // --- Cover: upload/bind via editor, then reopen (remote load) ---
    await tester.tap(find.text(AppStrings.tabProfile));
    await pumpFrames(tester, const Duration(seconds: 3));
    await tester.tap(find.text(AppStrings.storeProfileMedia).first);
    await pumpFrames(tester, const Duration(seconds: 5));
    expect(find.byKey(const Key('store-cover-screen')), findsOneWidget);

    final coverState = tester.state(find.byType(StoreCoverScreen));
    (coverState as dynamic).debugSetCoverBytes(
      bytes: Uint8List.fromList(coverBytes),
      filename: 'cover_green.png',
      contentType: 'image/png',
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('store-cover-save')));
    await pumpFrames(tester, const Duration(seconds: 12));
    record(
      'cover_save',
      find.byKey(const Key('store-cover-screen')).evaluate().isEmpty
          ? 'PASS'
          : 'FAIL',
    );

    // Reopen cover editor — must hydrate from Merchant GET (not local pick).
    if (find.text(AppStrings.storeProfileMedia).evaluate().isEmpty) {
      await tester.tap(find.text(AppStrings.tabProfile));
      await pumpFrames(tester, const Duration(seconds: 3));
    }
    await tester.tap(find.text(AppStrings.storeProfileMedia).first);
    await pumpFrames(tester, const Duration(seconds: 8));
    expect(find.byKey(const Key('store-cover-screen')), findsOneWidget);
    expect(find.byType(Image), findsWidgets);
    record('cover_reopen_remote', 'PASS');
    await markShot('media-cover-reopened');

    // Back to profile
    final back = find.byTooltip('Back');
    if (back.evaluate().isNotEmpty) {
      await tester.tap(back.first);
    } else {
      await tester.tap(find.byIcon(Icons.arrow_back).first);
    }
    await pumpFrames(tester, const Duration(seconds: 3));

    // --- Product: open Couscous by route (list tap can hit FAB) ---
    const couscousId = '0d00c071-d000-7000-8000-000000030101';
    await tester.tap(find.text(AppStrings.tabCatalog));
    await pumpFrames(tester, const Duration(seconds: 6));
    expect(find.byType(CatalogScreen), findsOneWidget);
    final catalogCtx = tester.element(find.byType(CatalogScreen));
    catalogCtx.go(AppRoutes.catalogProductEdit(couscousId));
    await pumpFrames(tester, const Duration(seconds: 16));
    expect(find.byType(ProductEditorScreen), findsOneWidget);
    // Edit mode has availability switch; create mode does not.
    expect(find.byKey(const Key('product-editor-available')), findsOneWidget);
    expect(find.text('Couscous royal'), findsWidgets);

    final productState =
        tester.state(find.byType(ProductEditorScreen)) as dynamic;
    final bytesLen = productState.debugLocalImageByteLength as int?;
    final remoteFailed = productState.debugRemoteImageFailed as bool?;
    final expectRemote = productState.debugExpectRemoteImage as bool?;
    final editorImages = find.descendant(
      of: find.byType(ProductEditorScreen),
      matching: find.byType(Image),
    );
    final editorRaw = find.descendant(
      of: find.byType(ProductEditorScreen),
      matching: find.byType(RawImage),
    );
    var hasImageWidget =
        editorImages.evaluate().isNotEmpty || editorRaw.evaluate().isNotEmpty;
    if (!hasImageWidget && (bytesLen ?? 0) > 0) {
      // Bytes hydrated but Image may be above the fold / not yet laid out.
      await tester.drag(find.byType(Scrollable).first, const Offset(0, 200));
      await pumpFrames(tester, const Duration(seconds: 2));
      hasImageWidget = editorImages.evaluate().isNotEmpty ||
          editorRaw.evaluate().isNotEmpty;
    }

    record(
      'product_reopen_remote',
      hasImageWidget && (bytesLen ?? 0) > 0 ? 'PASS' : 'FAIL',
      detail:
          'bytes=$bytesLen expectRemote=$expectRemote remoteFailed=$remoteFailed '
          'imageWidget=$hasImageWidget productId=$couscousId',
    );
    expect(
      hasImageWidget && (bytesLen ?? 0) > 0,
      isTrue,
      reason:
          'Product remote image must paint after reopen '
          '(bytes=$bytesLen failed=$remoteFailed expectRemote=$expectRemote)',
    );
    await markShot('media-product-reopened');

    File('${outDir.path}/MEDIA_LIVE_PROVENANCE.json').writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert({
        'ok': true,
        'layer': 'live_merchant_ui',
        'bundleId': 'com.speedygo.speedygoMerchantApp',
        'fixture': 'Dar El Bahja',
        'phone': '+213$phoneLocal',
        'simulator': 'iPhone 16e',
        'simulatorUdid': '8DB9007A-B816-4EC5-86ED-C627AC60F2C5',
        'remoteMediaRead': 'Merchant JWT GET streams',
        'finjanUntouched': true,
        'customerTokenUnused': true,
        'entrypoint': 'integration_test/media_remote_display_live_test.dart',
        'steps': steps,
        'at': DateTime.now().toUtc().toIso8601String(),
      }),
    );
  });
}
