import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:speedygo_merchant_app/app/app.dart';
import 'package:speedygo_merchant_app/core/constants/app_strings.dart';

/// Live five-tab capture helper for Finjan session (Pro simulator).
/// Screenshots are written by a host watcher reading `/tmp/phase3_host_shot.txt`.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const phoneLocal = String.fromEnvironment(
    'PHASE3_PHONE',
    defaultValue: '559907701',
  );
  const otpFilePath = String.fromEnvironment(
    'PHASE3_OTP_FILE',
    defaultValue: '/Users/mac/.speedygo/dev/otp-last',
  );
  const shotMarker = '/tmp/phase3_host_shot.txt';

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
    for (var i = 0; i < 50; i++) {
      if (file.existsSync() && !file.lastModifiedSync().isBefore(after)) {
        final otp = file.readAsStringSync().trim();
        if (otp.length >= 4) return otp;
      }
      await Future<void>.delayed(const Duration(milliseconds: 250));
    }
    throw StateError('OTP not found in $otpFilePath');
  }

  Future<void> reachHome(WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: SpeedyGoApp()));
    await pumpFrames(tester, const Duration(seconds: 6));

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
      final phoneField = find.byType(TextField).first;
      await tester.enterText(phoneField, phoneLocal);
      await tester.pump(const Duration(milliseconds: 400));
      final otpBefore = DateTime.now().subtract(const Duration(seconds: 1));
      await tester.tap(find.byKey(const Key('merchant-phone-continue')));
      await pumpFrames(tester, const Duration(seconds: 3));
      expect(find.byKey(const Key('merchant-otp-field')), findsOneWidget);
      final otp = await waitForFreshOtp(otpBefore);
      await tester.enterText(find.byKey(const Key('merchant-otp-field')), otp);
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.byKey(const Key('merchant-otp-verify')));
      await pumpFrames(tester, const Duration(seconds: 10));
    }

    expect(find.byKey(const Key('home-branch-name')), findsOneWidget);
    // Identity: Merchant shell tabs only (never Customer Recherche/Alertes).
    expect(find.text(AppStrings.tabCatalog), findsOneWidget);
    expect(find.text(AppStrings.tabReports), findsOneWidget);
    expect(find.text('Recherche'), findsNothing);
    expect(find.text('Alertes'), findsNothing);
  }

  testWidgets('phase-3 live five tabs capture', (tester) async {
    await reachHome(tester);
    expect(find.textContaining('Finjan'), findsWidgets);
    expect(find.textContaining('Ouvert'), findsNothing);
    await markShot('live-home-pro');

    await tester.tap(find.byKey(const Key('nav-orders')));
    await pumpFrames(tester, const Duration(seconds: 3));
    await markShot('live-orders-pro');

    await tester.tap(find.text(AppStrings.tabCatalog));
    await pumpFrames(tester, const Duration(seconds: 3));
    expect(find.byKey(const Key('catalog-screen')), findsOneWidget);
    await markShot('live-catalog-pro');

    await tester.tap(find.text(AppStrings.tabReports));
    await pumpFrames(tester, const Duration(seconds: 3));
    expect(find.byKey(const Key('reports-screen')), findsOneWidget);
    await markShot('live-reports-pro');

    await tester.tap(find.text(AppStrings.tabProfile));
    await pumpFrames(tester, const Duration(seconds: 3));
    expect(find.byKey(const Key('store-profile-screen')), findsOneWidget);
    await markShot('live-profile-pro');

    File(
      '/Users/mac/Downloads/speedygo_project/apps/merchant_app/audit/phase-3-tabs/live-verified/PROVENANCE.json',
    ).writeAsStringSync(
      '{\n'
      '  "ok": true,\n'
      '  "app": "merchant",\n'
      '  "bundleId": "com.speedygo.speedygoMerchantApp",\n'
      '  "displayName": "Speedygo Merchant App",\n'
      '  "package": "speedygo_merchant_app",\n'
      '  "simulatorUdid": "4A1C3481-8B8E-48BD-983D-03896884EF09",\n'
      '  "simulator": "iPhone 17 Pro",\n'
      '  "workingDirectory": "apps/merchant_app",\n'
      '  "entrypoint": "lib/main.dart",\n'
      '  "tabs": ["Accueil","Commandes","Catalogue","Rapports","Profil"],\n'
      '  "at": "${DateTime.now().toUtc().toIso8601String()}"\n'
      '}\n',
    );
    File(
      '/Users/mac/Downloads/speedygo_project/apps/merchant_app/audit/phase-3-tabs/LIVE_CAPTURE_STEPS.json',
    )
      ..parent.createSync(recursive: true)
      ..writeAsStringSync(
        '{"ok":true,"tabs":["home","orders","catalog","reports","profile"],'
        '"bundleId":"com.speedygo.speedygoMerchantApp",'
        '"at":"${DateTime.now().toUtc().toIso8601String()}"}',
      );
  });
}
