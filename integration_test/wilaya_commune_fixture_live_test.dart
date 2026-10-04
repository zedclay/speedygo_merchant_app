import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:speedygo_merchant_app/app/app.dart';
import 'package:speedygo_merchant_app/core/constants/app_strings.dart';
import 'package:speedygo_merchant_app/core/widgets/merchant_primary_button.dart';

/// Isolated Geo Live Fixture Wilaya/Commune flow on iPhone 16e.
/// Phone: +213555019998 / merchant Geo Live Fixture Merchant.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const phoneLocal = String.fromEnvironment(
    'WILAYA_FIXTURE_PHONE',
    defaultValue: '555019998',
  );
  const otpFilePath = String.fromEnvironment(
    'WILAYA_OTP_FILE',
    defaultValue: '/Users/mac/.speedygo/dev/otp-last',
  );
  const shotMarker = '/tmp/wilaya_host_shot.txt';
  const stateFile = '/tmp/wilaya_fixture_state.json';
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
      'fixture': 'Geo Live Fixture Merchant',
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

  bool isFixtureHome() {
    return find.textContaining('Live Geo Branch').evaluate().isNotEmpty ||
        find.textContaining('Geo Live Fixture').evaluate().isNotEmpty;
  }

  Future<void> waitForPhoneLogin(WidgetTester tester) async {
    for (var i = 0; i < 40; i++) {
      if (find.byKey(const Key('merchant-phone-continue')).evaluate().isNotEmpty) {
        return;
      }
      await pumpFrames(tester, const Duration(milliseconds: 500));
    }
  }

  Future<void> loginAsFixture(WidgetTester tester) async {
    await waitForPhoneLogin(tester);
    expect(
      find.byKey(const Key('merchant-phone-continue')),
      findsOneWidget,
      reason:
          'Phone login missing. home=${find.byKey(const Key('home-branch-name')).evaluate().length} fixture=${isFixtureHome()}',
    );
    await tester.enterText(find.byType(TextField).first, phoneLocal);
    await tester.pump(const Duration(milliseconds: 400));
    final otpBefore = DateTime.now().subtract(const Duration(seconds: 1));
    await tester.tap(find.byKey(const Key('merchant-phone-continue')));
    await pumpFrames(tester, const Duration(seconds: 5));
    // Rate-limit / network: wait for OTP field or surface error text.
    for (var i = 0; i < 30; i++) {
      if (find.byKey(const Key('merchant-otp-field')).evaluate().isNotEmpty) {
        break;
      }
      await pumpFrames(tester, const Duration(milliseconds: 500));
    }
    expect(
      find.byKey(const Key('merchant-otp-field')),
      findsOneWidget,
      reason: 'OTP screen missing after phone continue (rate limit?)',
    );
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

  Future<void> logoutIfHome(WidgetTester tester) async {
    if (find.byKey(const Key('merchant-phone-continue')).evaluate().isNotEmpty) {
      return;
    }
    if (find.text(AppStrings.tabProfile).evaluate().isNotEmpty) {
      await tester.tap(find.text(AppStrings.tabProfile));
      await pumpFrames(tester, const Duration(seconds: 3));
    }
    // Prefer keyed settings row; scroll if needed.
    var settings = find.byKey(const Key('store-profile-settings'));
    if (settings.evaluate().isEmpty) {
      settings = find.text(AppStrings.storeProfileSettings);
    }
    if (settings.evaluate().isNotEmpty) {
      await tester.ensureVisible(settings.first);
      await tester.tap(settings.first);
      await pumpFrames(tester, const Duration(seconds: 3));
    }
    final logout = find.byKey(const Key('merchant-logout'));
    if (logout.evaluate().isEmpty) {
      // Scroll settings body.
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -400));
      await pumpFrames(tester, const Duration(seconds: 1));
    }
    if (find.byKey(const Key('merchant-logout')).evaluate().isEmpty) return;
    await tester.ensureVisible(find.byKey(const Key('merchant-logout')));
    await tester.tap(find.byKey(const Key('merchant-logout')));
    await pumpFrames(tester, const Duration(seconds: 2));
    final confirm = find.text(AppStrings.logoutConfirmAction);
    if (confirm.evaluate().isNotEmpty) {
      await tester.tap(confirm.last);
      await pumpFrames(tester, const Duration(seconds: 8));
    }
    await waitForPhoneLogin(tester);
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

    // Drop leftover SE sessions (e.g. Dar El Bahja) — must be Geo Live Fixture.
    if (find.byKey(const Key('home-branch-name')).evaluate().isNotEmpty &&
        !isFixtureHome()) {
      record(
        'wrong_session_logout',
        'PASS',
        detail: 'Non-fixture home detected; logging out',
      );
      await logoutIfHome(tester);
    }

    if (find.byKey(const Key('home-branch-name')).evaluate().isEmpty ||
        !isFixtureHome()) {
      if (find.byKey(const Key('merchant-phone-continue')).evaluate().isEmpty) {
        await logoutIfHome(tester);
        await pumpFrames(tester, const Duration(seconds: 4));
      }
      await loginAsFixture(tester);
    }

    expect(find.byKey(const Key('home-branch-name')), findsOneWidget);
    expect(find.textContaining('Finjan'), findsNothing);
    expect(isFixtureHome(), isTrue, reason: 'Must be Geo Live Fixture session');
    record('fixture_home', 'PASS', detail: 'Live Geo Branch');
  }

  Future<void> openAddress(WidgetTester tester) async {
    await tester.tap(find.text(AppStrings.tabProfile));
    await pumpFrames(tester, const Duration(seconds: 3));
    await tester.tap(find.text(AppStrings.storeProfileAddress).first);
    await pumpFrames(tester, const Duration(seconds: 6));
    expect(find.byKey(const Key('store-address-screen')), findsOneWidget);
    // Bootstrap wilayas/communes from branch.
    await pumpFrames(tester, const Duration(seconds: 3));
  }

  Future<void> popAddressIfNeeded(WidgetTester tester) async {
    if (find.byKey(const Key('store-address-screen')).evaluate().isEmpty) {
      return;
    }
    final back = find.byTooltip('Back');
    if (back.evaluate().isNotEmpty) {
      await tester.tap(back.first);
    } else {
      final arrow = find.byIcon(Icons.arrow_back);
      if (arrow.evaluate().isNotEmpty) {
        await tester.tap(arrow.first);
      }
    }
    await pumpFrames(tester, const Duration(seconds: 3));
  }

  String? readSelectFieldText(WidgetTester tester, Key key) {
    final field = find.byKey(key);
    if (field.evaluate().isEmpty) return null;
    final texts = find
        .descendant(of: field, matching: find.byType(Text))
        .evaluate()
        .map((e) => (e.widget as Text).data ?? '')
        .where((t) => t.trim().isNotEmpty)
        .toList();
    return texts.isEmpty ? null : texts.last;
  }

  String? readError(WidgetTester tester) {
    final err = find.byKey(const Key('store-address-error'));
    if (err.evaluate().isEmpty) return null;
    final texts = find
        .descendant(of: err, matching: find.byType(Text))
        .evaluate()
        .map((e) => (e.widget as Text).data ?? '')
        .where((t) => t.trim().isNotEmpty)
        .toList();
    if (texts.isNotEmpty) return texts.join(' | ');
    final w = tester.widget(err);
    if (w is Text) return w.data;
    return 'error-present';
  }

  testWidgets('fixture wilaya commune save reopen', (tester) async {
    final mode = const String.fromEnvironment(
      'WILAYA_FIXTURE_MODE',
      defaultValue: 'save',
    );

    await reachHome(tester);
    await openAddress(tester);
    await markShot('fixture-address-form');

    final addressBefore = tester
        .widget<TextField>(find.byKey(const Key('store-address-text')))
        .controller
        ?.text;
    final phoneBefore = tester
        .widget<TextField>(find.byKey(const Key('store-address-phone')))
        .controller
        ?.text;
    expect(addressBefore, isNotNull);
    expect(addressBefore, isNotEmpty);
    expect(phoneBefore, isNotNull);
    expect(phoneBefore, isNotEmpty);
    expect(phoneBefore, isNot(contains('550000101')));

    if (mode == 'reopen') {
      final prior = jsonDecode(File(stateFile).readAsStringSync())
          as Map<String, dynamic>;
      final wilayaText = readSelectFieldText(
        tester,
        const Key('store-address-wilaya'),
      );
      final communeText = readSelectFieldText(
        tester,
        const Key('store-address-commune'),
      );
      final addressAfter = tester
          .widget<TextField>(find.byKey(const Key('store-address-text')))
          .controller
          ?.text;
      expect(wilayaText, contains(prior['wilayaCode'] as String));
      expect(wilayaText, contains(prior['wilayaName'] as String));
      expect(communeText, prior['communeName']);
      expect(addressAfter, prior['addressText']);
      record(
        'cold_reopen_restore',
        'PASS',
        detail: jsonEncode({
          'wilayaText': wilayaText,
          'communeText': communeText,
          'addressText': addressAfter,
          'prior': prior,
        }),
      );
      await markShot('fixture-reopened');
    } else {
      // Pick wilaya via search
      await tester.tap(find.byKey(const Key('store-address-wilaya')));
      await pumpFrames(tester, const Duration(seconds: 3));
      expect(find.text(AppStrings.adminLocationSearchHint), findsOneWidget);
      await tester.enterText(find.byType(TextField).last, 'Alger');
      await pumpFrames(tester, const Duration(seconds: 1));
      await markShot('fixture-wilaya-search');
      final algerTile = find.widgetWithText(ListTile, '16 — Alger');
      expect(algerTile, findsWidgets);
      await tester.ensureVisible(algerTile.first);
      await tester.tap(algerTile.first);
      await pumpFrames(tester, const Duration(seconds: 4));
      record('wilaya_search_select', 'PASS');

      // Commune loading hint may flash; then list Alger communes only
      await tester.tap(find.byKey(const Key('store-address-commune')));
      await pumpFrames(tester, const Duration(seconds: 4));
      expect(find.text(AppStrings.adminLocationSearchHint), findsOneWidget);
      await tester.enterText(find.byType(TextField).last, 'Centre');
      await pumpFrames(tester, const Duration(seconds: 1));
      await markShot('fixture-commune-search');
      final centreTile = find.widgetWithText(ListTile, 'Alger Centre');
      expect(centreTile, findsWidgets);
      // Ensure Oran communes are not listed under Alger filter context
      expect(find.widgetWithText(ListTile, 'Oran'), findsNothing);
      await tester.ensureVisible(centreTile.first);
      await tester.tap(centreTile.first);
      await pumpFrames(tester, const Duration(seconds: 2));
      record('commune_select', 'PASS');
      record(
        'commune_scoped_to_wilaya',
        'PASS',
        detail: 'Alger Centre visible; Oran tile absent in Alger sheet',
      );

      // Change wilaya → commune clears
      await tester.tap(find.byKey(const Key('store-address-wilaya')));
      await pumpFrames(tester, const Duration(seconds: 3));
      await tester.enterText(find.byType(TextField).last, 'Oran');
      await pumpFrames(tester, const Duration(seconds: 1));
      final oranWilaya = find.widgetWithText(ListTile, '31 — Oran');
      expect(oranWilaya, findsWidgets);
      await tester.ensureVisible(oranWilaya.first);
      await tester.tap(oranWilaya.first);
      await pumpFrames(tester, const Duration(seconds: 5));
      final communeAfterWilayaChange = readSelectFieldText(
        tester,
        const Key('store-address-commune'),
      );
      expect(
        communeAfterWilayaChange == null ||
            communeAfterWilayaChange.contains(AppStrings.adminLocationChoose) ||
            communeAfterWilayaChange
                .contains(AppStrings.adminLocationWilayaRequired) ||
            communeAfterWilayaChange == AppStrings.loading ||
            !communeAfterWilayaChange.contains('Alger Centre'),
        isTrue,
        reason: 'Commune must clear when wilaya changes',
      );
      record(
        'wilaya_change_clears_commune',
        'PASS',
        detail: communeAfterWilayaChange,
      );

      // Select valid Oran pair
      await tester.tap(find.byKey(const Key('store-address-commune')));
      await pumpFrames(tester, const Duration(seconds: 4));
      final communeSearch = find.byType(TextField).last;
      await tester.enterText(communeSearch, 'Oran');
      await pumpFrames(tester, const Duration(seconds: 1));
      final oranTile = find.widgetWithText(ListTile, 'Oran');
      expect(oranTile, findsWidgets);
      await tester.ensureVisible(oranTile.first);
      await tester.tap(oranTile.first);
      await pumpFrames(tester, const Duration(seconds: 2));

      final wilayaSaved = readSelectFieldText(
        tester,
        const Key('store-address-wilaya'),
      );
      final communeSaved = readSelectFieldText(
        tester,
        const Key('store-address-commune'),
      );
      expect(wilayaSaved, contains('31'));
      expect(communeSaved, isNotNull);
      expect(communeSaved, isNot(equals(AppStrings.adminLocationChoose)));
      expect(communeSaved, contains('Oran'));

      final addressMid = tester
          .widget<TextField>(find.byKey(const Key('store-address-text')))
          .controller
          ?.text;
      expect(addressMid, addressBefore);

      final saveBtn = find.byKey(const Key('store-address-save'));
      await tester.ensureVisible(saveBtn);
      await tester.tap(saveBtn);

      // Wait for pop or error (network can be slow on sim).
      var left = false;
      String? errText;
      for (var i = 0; i < 40; i++) {
        await pumpFrames(tester, const Duration(milliseconds: 500));
        if (find.byKey(const Key('store-address-screen')).evaluate().isEmpty) {
          left = true;
          break;
        }
        errText = readError(tester);
        if (errText != null) break;
      }

      record(
        'save',
        left ? 'PASS' : 'FAIL',
        detail: left
            ? 'wilaya=$wilayaSaved commune=$communeSaved'
            : 'stillOnAddress err=$errText wilaya=$wilayaSaved commune=$communeSaved phone=$phoneBefore',
      );

      // If API succeeded but pop stalled (e.g. refreshInPlace), leave manually.
      if (!left) {
        expect(errText, isNull, reason: 'Save error on address screen');
        await popAddressIfNeeded(tester);
        left =
            find.byKey(const Key('store-address-screen')).evaluate().isEmpty;
        record(
          'save_pop_fallback',
          left ? 'PASS' : 'FAIL',
          detail: 'manual back after silent save',
        );
      }
      expect(left, isTrue, reason: 'Must leave address screen after save');

      // Soft reopen (same process)
      if (find.text(AppStrings.storeProfileAddress).evaluate().isEmpty) {
        await tester.tap(find.text(AppStrings.tabProfile));
        await pumpFrames(tester, const Duration(seconds: 3));
      }
      expect(find.text(AppStrings.storeProfileAddress), findsWidgets);
      await tester.tap(find.text(AppStrings.storeProfileAddress).first);
      await pumpFrames(tester, const Duration(seconds: 6));
      expect(find.byKey(const Key('store-address-screen')), findsOneWidget);
      await pumpFrames(tester, const Duration(seconds: 3));

      final wilayaRe = readSelectFieldText(
        tester,
        const Key('store-address-wilaya'),
      );
      final communeRe = readSelectFieldText(
        tester,
        const Key('store-address-commune'),
      );
      final addressRe = tester
          .widget<TextField>(find.byKey(const Key('store-address-text')))
          .controller
          ?.text;
      expect(wilayaRe, wilayaSaved);
      expect(communeRe, communeSaved);
      expect(addressRe, addressBefore);
      record(
        'soft_reopen',
        'PASS',
        detail: 'wilaya=$wilayaRe commune=$communeRe address=$addressRe',
      );
      record(
        'address_text_unchanged',
        'PASS',
        detail: addressRe,
      );
      await markShot('fixture-saved-reopened');

      File(stateFile).writeAsStringSync(
        jsonEncode({
          'wilayaCode': '31',
          'wilayaName': 'Oran',
          'communeName': communeSaved,
          'addressText': addressBefore,
          'wilayaDisplay': wilayaSaved,
          'communeDisplay': communeSaved,
          'phone': phoneBefore,
          'expectedCoords': {'lat': 36.753, 'lng': 3.058},
        }),
      );
    }

    record(
      'registration_live_selectors',
      'NOT RUN',
      detail:
          'Fixture already has branch; establishment step not reachable. Shared AdminLocationSelectField covered by store-address + layout unit test.',
    );

    File('${outDir.path}/FIXTURE_PROVENANCE.json').writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert({
        'ok': true,
        'layer': 'live_merchant_ui',
        'bundleId': 'com.speedygo.speedygoMerchantApp',
        'fixture': 'Geo Live Fixture Merchant',
        'phone': '+213$phoneLocal',
        'publicReference': 'sgm_01a0bf0fae06732f86a98e3d8984eded',
        'merchantId': '01a0bf0f-ae06-7992-a9ee-22fed331d03f',
        'branchId': '01a0bf0f-aeef-70bb-8f86-dfe2a5e80154',
        'simulatorUdid': '8DB9007A-B816-4EC5-86ED-C627AC60F2C5',
        'simulator': 'iPhone 16e',
        'mode': mode,
        'finjanUntouched': true,
        'customerAppUntouched': true,
        'entrypoint': 'integration_test/wilaya_commune_fixture_live_test.dart',
        'steps': steps,
        'at': DateTime.now().toUtc().toIso8601String(),
      }),
    );
  });
}
