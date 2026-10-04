import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:speedygo_merchant_app/app/app.dart';
import 'package:speedygo_merchant_app/core/widgets/merchant_primary_button.dart';
import 'package:speedygo_merchant_app/features/access/data/evidence_file_picker.dart';

/// Live registration lifecycle through Merchant UI gestures.
///
/// Requires host-provided dart-defines:
/// - ACCEPTANCE_EVIDENCE_PICKER=1
/// - ACCEPTANCE_PHONE (9 local digits, no country code)
/// - ACCEPTANCE_OTP
/// - ACCEPTANCE_MERCHANT_NAME
///
/// Isolated SE simulator only — does not clear Finjan Keychain on 17 Pro.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const phoneLocal = String.fromEnvironment('ACCEPTANCE_PHONE');
  const merchantName = String.fromEnvironment(
    'ACCEPTANCE_MERCHANT_NAME',
    defaultValue: 'TEST FIXTURE — Lifecycle Acceptance Shop',
  );
  const otpFilePath = String.fromEnvironment(
    'ACCEPTANCE_OTP_FILE',
    defaultValue: '/Users/mac/.speedygo/dev/otp-last',
  );

  final auditDir = Directory(
    '/Users/mac/Downloads/speedygo_project/apps/merchant_app'
    '/audit/registration-lifecycle-acceptance',
  )..createSync(recursive: true);
  Directory('${auditDir.path}/screenshots').createSync(recursive: true);
  final steps = <Map<String, dynamic>>[];

  Future<void> pumpFrames(WidgetTester tester, Duration total) async {
    final end = DateTime.now().add(total);
    while (DateTime.now().isBefore(end)) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> tapVisible(WidgetTester tester, Finder finder) async {
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.ensureVisible(finder);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(finder, warnIfMissed: false);
    // If the first tap missed (keyboard / sticky chrome), scroll then retry.
    await tester.pump(const Duration(milliseconds: 200));
  }

  Future<void> openMapPicker(WidgetTester tester) async {
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump(const Duration(milliseconds: 500));
    final choose = find.byKey(const Key('merchant-reg-choose-on-map'));
    final edit = find.byKey(const Key('merchant-reg-location-edit'));
    final opener = choose.evaluate().isNotEmpty ? choose : edit;
    expect(opener, findsOneWidget);
    final formScroll = find.descendant(
      of: find.byKey(const Key('merchant-registration')),
      matching: find.byType(SingleChildScrollView),
    );
    if (formScroll.evaluate().isNotEmpty) {
      await tester.drag(formScroll.last, const Offset(0, -420));
      await tester.pump(const Duration(milliseconds: 400));
    }
    await tester.ensureVisible(opener);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(opener, warnIfMissed: false);
    await pumpFrames(tester, const Duration(seconds: 3));
    if (find.byKey(const Key('merchant-location-picker')).evaluate().isEmpty) {
      if (choose.evaluate().isNotEmpty) {
        final btn = tester.widget<OutlinedButton>(choose);
        expect(btn.onPressed, isNotNull);
        btn.onPressed!();
      } else {
        await tester.tap(edit);
      }
      await pumpFrames(tester, const Duration(seconds: 5));
    }
    expect(find.byKey(const Key('merchant-location-picker')), findsOneWidget);
  }

  Future<void> hostShot(String tag) async {
    File('/tmp/lifecycle_host_shot.txt').writeAsStringSync('$tag\n');
    // ignore: avoid_print
    print('LIFECYCLE_HOST_SHOT=$tag');
    await Future<void>.delayed(const Duration(seconds: 6));
  }

  void record(String id, String status, {String? detail, String? layer}) {
    steps.add({
      'id': id,
      'status': status,
      'detail': detail,
      'layer': layer ?? 'live_merchant_ui',
      'at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  testWidgets('registration draft submit pending (live API)', (tester) async {
    expect(
      AcceptanceFixtureEvidenceFilePicker.acceptancePickerEnabled,
      isTrue,
      reason: 'ACCEPTANCE_EVIDENCE_PICKER=1 required',
    );
    expect(phoneLocal.length, 9);

    Future<String> waitForFreshOtp(DateTime after) async {
      final file = File(otpFilePath);
      for (var i = 0; i < 40; i++) {
        if (file.existsSync()) {
          final stamp = file.lastModifiedSync();
          if (stamp.isAfter(after)) {
            final code = file.readAsStringSync().trim();
            if (code.length >= 4) return code;
          }
        }
        await Future<void>.delayed(const Duration(milliseconds: 250));
      }
      throw TestFailure('OTP file not updated at $otpFilePath');
    }

    await tester.pumpWidget(
      const ProviderScope(child: SpeedyGoApp()),
    );
    await pumpFrames(tester, const Duration(seconds: 3));

    // Language (first run) or later screens if already seen on this sim.
    for (var i = 0; i < 80; i++) {
      if (find.byKey(const Key('merchant-language')).evaluate().isNotEmpty) {
        await tester.tap(find.byKey(const Key('merchant-language-fr')));
        await pumpFrames(tester, const Duration(seconds: 2));
        break;
      }
      if (find.byKey(const Key('merchant-onboarding')).evaluate().isNotEmpty) {
        break;
      }
      if (find.byKey(const Key('merchant-phone-field')).evaluate().isNotEmpty) {
        break;
      }
      if (find.byKey(const Key('merchant-registration')).evaluate().isNotEmpty) {
        // ignore: avoid_print
        print('LIFECYCLE_SESSION_RESUMED_REGISTRATION');
        break;
      }
      await tester.pump(const Duration(milliseconds: 200));
    }
    if (find.byKey(const Key('merchant-onboarding')).evaluate().isNotEmpty) {
      await tester.tap(find.byKey(const Key('merchant-onboarding-skip')));
      await pumpFrames(tester, const Duration(seconds: 2));
    }

    // Wait for phone — fail clearly if a restored session skipped auth.
    for (var i = 0; i < 60; i++) {
      if (find.byKey(const Key('merchant-phone-field')).evaluate().isNotEmpty) {
        break;
      }
      if (find.byKey(const Key('merchant-registration')).evaluate().isNotEmpty) {
        break;
      }
      await tester.pump(const Duration(milliseconds: 200));
    }
    if (find.byKey(const Key('merchant-phone-field')).evaluate().isEmpty) {
      // ignore: avoid_print
      print(
        'LIFECYCLE_NO_PHONE '
        'reg=${find.byKey(const Key('merchant-registration')).evaluate().isNotEmpty} '
        'otp=${find.byKey(const Key('merchant-otp-field')).evaluate().isNotEmpty} '
        'splash=${find.byKey(const Key('merchant-splash')).evaluate().isNotEmpty}',
      );
    }
    expect(
      find.byKey(const Key('merchant-phone-field')),
      findsOneWidget,
      reason: 'Expected signed-out phone screen (clear SE keychain if resumed)',
    );
    await tester.enterText(
      find.byKey(const Key('merchant-phone-field')),
      phoneLocal,
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    final otpBefore = File(otpFilePath).existsSync()
        ? File(otpFilePath).lastModifiedSync()
        : DateTime.fromMillisecondsSinceEpoch(0);
    final continueBtn = tester.widget<MerchantPrimaryButton>(
      find.byKey(const Key('merchant-phone-continue')),
    );
    expect(
      continueBtn.onPressed,
      isNotNull,
      reason: 'phone continue disabled (invalid/cooldown)',
    );
    await tester.tap(find.byKey(const Key('merchant-phone-continue')));
    await pumpFrames(tester, const Duration(seconds: 2));

    // Wait for OTP screen (app requests OTP; host capture file updates).
    for (var i = 0; i < 40; i++) {
      if (find.byKey(const Key('merchant-otp-field')).evaluate().isNotEmpty) {
        break;
      }
      await tester.pump(const Duration(milliseconds: 250));
    }
    if (find.byKey(const Key('merchant-otp-field')).evaluate().isEmpty) {
      // ignore: avoid_print
      print('LIFECYCLE_PHONE_STUCK');
    }
    expect(find.byKey(const Key('merchant-otp-field')), findsOneWidget);
    final otp = await waitForFreshOtp(otpBefore);
    await tester.enterText(find.byKey(const Key('merchant-otp-field')), otp);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    final verifyBtn = tester.widget<MerchantPrimaryButton>(
      find.byKey(const Key('merchant-otp-verify')),
    );
    expect(
      verifyBtn.onPressed,
      isNotNull,
      reason: 'OTP verify disabled (code length / busy)',
    );
    await tester.tap(find.byKey(const Key('merchant-otp-verify')));
    // Access resolve: OTP verify → me → registration (or loading/error).
    for (var i = 0; i < 80; i++) {
      if (find.byKey(const Key('merchant-registration')).evaluate().isNotEmpty) {
        break;
      }
      if (find.byKey(const Key('merchant-access-error')).evaluate().isNotEmpty) {
        // ignore: avoid_print
        print('LIFECYCLE_ACCESS_ERROR');
        break;
      }
      await tester.pump(const Duration(milliseconds: 250));
    }
    if (find.byKey(const Key('merchant-registration')).evaluate().isEmpty) {
      // ignore: avoid_print
      print(
        'LIFECYCLE_POST_OTP_KEYS='
        '${tester.allWidgets.whereType<KeyedSubtree>().map((w) => w.key).whereType<Key>().take(40).toList()}',
      );
    }
    expect(find.byKey(const Key('merchant-registration')), findsOneWidget);
    record('auth_otp', 'PASS');

    // Fresh accounts start at account; resumed drafts may already be later.
    if (find.byKey(const Key('merchant-reg-role-owner')).evaluate().isNotEmpty) {
      await tester.tap(find.byKey(const Key('merchant-reg-role-owner')));
      await pumpFrames(tester, const Duration(milliseconds: 500));
      await tester.tap(find.byKey(const Key('merchant-reg-account-continue')));
      await pumpFrames(tester, const Duration(seconds: 2));
    }

    if (find.byKey(const Key('merchant-reg-name')).evaluate().isNotEmpty) {
      await tester.enterText(
        find.byKey(const Key('merchant-reg-name')),
        merchantName,
      );
      await tester.tap(find.byKey(const Key('merchant-reg-activity-continue')));
      await pumpFrames(tester, const Duration(seconds: 5));
      record('registration_activity', 'PASS');
    }

    if (find
        .byKey(const Key('merchant-reg-doc-pick-BUSINESS_IDENTITY'))
        .evaluate()
        .isNotEmpty) {
      await tapVisible(
        tester,
        find.byKey(const Key('merchant-reg-doc-pick-BUSINESS_IDENTITY')),
      );
      await pumpFrames(tester, const Duration(seconds: 4));
      await tapVisible(
        tester,
        find.byKey(const Key('merchant-reg-doc-pick-BUSINESS_REGISTRATION')),
      );
      await pumpFrames(tester, const Duration(seconds: 4));
      await tapVisible(
        tester,
        find.byKey(const Key('merchant-reg-docs-continue')),
      );
      await pumpFrames(tester, const Duration(seconds: 3));
      record('registration_documents', 'PASS', detail: 'optional left absent');
    }

    // Establishment + map (SE viewport — dismiss keyboard, scroll CTA)
    expect(find.byKey(const Key('merchant-reg-branch-name')), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('merchant-reg-branch-name')),
      'TEST FIXTURE Branch Alger',
    );
    await tester.enterText(
      find.byKey(const Key('merchant-reg-branch-phone')),
      '0559901101',
    );
    await tester.enterText(
      find.byKey(const Key('merchant-reg-branch-address')),
      'TEST FIXTURE address — not a real business address',
    );
    await openMapPicker(tester);
    final map =
        tester.getCenter(find.byKey(const Key('merchant-location-picker')));
    await tester.dragFrom(map, const Offset(-40, -20));
    await pumpFrames(tester, const Duration(seconds: 2));
    await tapVisible(
      tester,
      find.byKey(const Key('merchant-location-confirm')),
    );
    await pumpFrames(tester, const Duration(seconds: 3));
    expect(find.byKey(const Key('merchant-reg-location-confirmed')), findsOneWidget);

    // Back preserves data: open map again and cancel
    await openMapPicker(tester);
    await tapVisible(tester, find.byKey(const Key('merchant-location-back')));
    await pumpFrames(tester, const Duration(seconds: 2));
    expect(find.text('TEST FIXTURE Branch Alger'), findsWidgets);
    expect(find.byKey(const Key('merchant-reg-location-confirmed')), findsOneWidget);
    record('registration_establishment_map', 'PASS');

    await tapVisible(
      tester,
      find.byKey(const Key('merchant-reg-estab-continue')),
    );
    await pumpFrames(tester, const Duration(seconds: 5));

    // Review screenshot + submit
    await hostShot('review');
    expect(find.byKey(const Key('merchant-reg-submit')), findsOneWidget);
    await tapVisible(tester, find.byKey(const Key('merchant-reg-submit')));
    await pumpFrames(tester, const Duration(seconds: 6));
    record('submission', 'PASS');

    // Pending
    expect(
      find.byKey(const Key('merchant-verification-pending')),
      findsOneWidget,
    );
    expect(find.textContaining('transmis'), findsOneWidget);
    await tester.ensureVisible(find.text('Non fourni'));
    await pumpFrames(tester, const Duration(seconds: 1));
    expect(find.text('Non fourni'), findsOneWidget);
    expect(find.text('Facultatif'), findsOneWidget);
    await hostShot('pending');
    record('pending_optional_absent', 'PASS');

    // Pending merchants must not land on Home
    expect(find.byKey(const Key('home-branch-name')), findsNothing);
    record('pending_blocks_home', 'PASS');

    File('${auditDir.path}/step_results_partial.json').writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert({
        'phoneLocal': phoneLocal,
        'merchantName': merchantName,
        'steps': steps,
        'note': 'Admin reject/approve NOT RUN in this widget — see host report',
      }),
    );
    // ignore: avoid_print
    print('LIFECYCLE_STEPS=${jsonEncode(steps)}');
  });
}
