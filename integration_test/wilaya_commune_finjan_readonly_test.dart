import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:speedygo_merchant_app/app/app.dart';
import 'package:speedygo_merchant_app/core/constants/app_strings.dart';
import 'package:speedygo_merchant_app/core/widgets/merchant_primary_button.dart';

/// Finjan read-only Wilaya/Commune check on iPhone 17 Pro.
/// Navigates Profil → Adresse, asserts selectors, screenshots, does NOT save.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const phoneLocal = String.fromEnvironment(
    'WILAYA_FINJAN_PHONE',
    defaultValue: '549445167',
  );
  const otpFilePath = String.fromEnvironment(
    'WILAYA_OTP_FILE',
    defaultValue: '/Users/mac/.speedygo/dev/otp-last',
  );
  const shotMarker = '/tmp/wilaya_host_shot.txt';
  final outDir = Directory(
    '/Users/mac/Downloads/speedygo_project/apps/merchant_app/audit/wilaya-commune/live',
  )..createSync(recursive: true);

  final steps = <Map<String, dynamic>>[];

  void record(String id, String status, {String? detail}) {
    steps.add({
      'id': id,
      'status': status,
      'detail': detail,
      'layer': 'live_merchant_ui',
      'fixture': 'Finjan',
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
    throw StateError('OTP not found in $otpFilePath');
  }

  Future<void> reachFinjanHome(WidgetTester tester) async {
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
      await pumpFrames(tester, const Duration(seconds: 3));
      expect(find.byKey(const Key('merchant-otp-field')), findsOneWidget);
      final otp = await waitForFreshOtp(otpBefore);
      await tester.enterText(find.byKey(const Key('merchant-otp-field')), otp);
      await tester.pump(const Duration(milliseconds: 300));
      final verifyBtn = tester.widget<MerchantPrimaryButton>(
        find.byKey(const Key('merchant-otp-verify')),
      );
      expect(verifyBtn.onPressed, isNotNull);
      await tester.tap(find.byKey(const Key('merchant-otp-verify')));
      await pumpFrames(tester, const Duration(seconds: 12));
    }

    expect(find.byKey(const Key('home-branch-name')), findsOneWidget);
    expect(find.textContaining('Finjan'), findsWidgets);
    record('finjan_home', 'PASS');
  }

  testWidgets('finjan readonly address wilaya commune selectors', (tester) async {
    await reachFinjanHome(tester);
    await markShot('finjan-home');

    await tester.tap(find.text(AppStrings.tabProfile));
    await pumpFrames(tester, const Duration(seconds: 3));
    expect(find.text(AppStrings.storeProfileAddress), findsWidgets);
    record('nav_profile', 'PASS');

    await tester.tap(find.text(AppStrings.storeProfileAddress).first);
    await pumpFrames(tester, const Duration(seconds: 5));

    expect(find.byKey(const Key('store-address-screen')), findsOneWidget);
    expect(find.byKey(const Key('store-address-wilaya')), findsOneWidget);
    expect(find.byKey(const Key('store-address-commune')), findsOneWidget);
    // Wilaya/Commune must be interactive selectors, not contract-gap rows.
    // Other gaps (public contact / pickup hints) may still show unavailable copy.
    final wilayaGap = find.descendant(
      of: find.byKey(const Key('store-address-wilaya')),
      matching: find.text(AppStrings.contractFieldUnavailable),
    );
    final communeGap = find.descendant(
      of: find.byKey(const Key('store-address-commune')),
      matching: find.text(AppStrings.contractFieldUnavailable),
    );
    expect(wilayaGap, findsNothing);
    expect(communeGap, findsNothing);
    record('selectors_visible', 'PASS');

    await markShot('finjan-address-form');

    // Explicitly do not tap save.
    expect(find.byKey(const Key('store-address-save')), findsOneWidget);
    record('no_save', 'PASS', detail: 'save control present; not activated');

    File('${outDir.path}/FINJAN_READONLY_PROVENANCE.json').writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert({
        'ok': true,
        'layer': 'live_merchant_ui',
        'bundleId': 'com.speedygo.speedygoMerchantApp',
        'fixture': 'Finjan',
        'savePerformed': false,
        'finjanDataModified': false,
        'customerAppUntouched': true,
        'simulatorUdid': '4A1C3481-8B8E-48BD-983D-03896884EF09',
        'simulator': 'iPhone 17 Pro',
        'entrypoint':
            'integration_test/wilaya_commune_finjan_readonly_test.dart',
        'steps': steps,
        'at': DateTime.now().toUtc().toIso8601String(),
      }),
    );
  });
}
