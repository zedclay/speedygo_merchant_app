import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:speedygo_merchant_app/app/app.dart';
import 'package:speedygo_merchant_app/core/constants/app_strings.dart';
import 'package:speedygo_merchant_app/core/widgets/merchant_primary_button.dart';
import 'package:speedygo_merchant_app/features/access/data/evidence_file_picker.dart';

/// Continues registration acceptance after Admin reject (API-only).
/// Fixture phone: ACCEPTANCE_PHONE (9 local digits). Does not recreate merchant.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const phoneLocal = String.fromEnvironment('ACCEPTANCE_PHONE');
  const otpFilePath = String.fromEnvironment(
    'ACCEPTANCE_OTP_FILE',
    defaultValue: '/Users/mac/.speedygo/dev/otp-last',
  );
  const approveMarker = String.fromEnvironment(
    'ACCEPTANCE_APPROVE_MARKER',
    defaultValue: '/tmp/lifecycle_approve_done.txt',
  );

  final auditDir = Directory(
    '/Users/mac/Downloads/speedygo_project/apps/merchant_app'
    '/audit/registration-lifecycle-acceptance',
  )..createSync(recursive: true);
  final shotDir = Directory('${auditDir.path}/screenshots')
    ..createSync(recursive: true);
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
    await tester.pump(const Duration(milliseconds: 200));
    await tester.tap(finder, warnIfMissed: false);
    await tester.pump(const Duration(milliseconds: 200));
  }

  Future<void> hostShot(String tag) async {
    File('/tmp/lifecycle_host_shot.txt').writeAsStringSync('$tag\n');
    // ignore: avoid_print
    print('LIFECYCLE_HOST_SHOT=$tag');
    await Future<void>.delayed(const Duration(seconds: 5));
  }

  void record(String id, String status, {String? detail}) {
    steps.add({
      'id': id,
      'status': status,
      'detail': detail,
      'layer': 'live_merchant_ui',
      'at': DateTime.now().toUtc().toIso8601String(),
    });
  }

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

  testWidgets('correction resubmit approve relaunch (live API)', (tester) async {
    expect(
      AcceptanceFixtureEvidenceFilePicker.acceptancePickerEnabled,
      isTrue,
    );
    expect(phoneLocal.length, 9);
    File(approveMarker).writeAsStringSync('');

    await tester.pumpWidget(const ProviderScope(child: SpeedyGoApp()));
    await pumpFrames(tester, const Duration(seconds: 3));

    for (var i = 0; i < 80; i++) {
      if (find.byKey(const Key('merchant-language')).evaluate().isNotEmpty) {
        await tester.tap(find.byKey(const Key('merchant-language-fr')));
        await pumpFrames(tester, const Duration(seconds: 2));
        break;
      }
      if (find.byKey(const Key('merchant-onboarding')).evaluate().isNotEmpty ||
          find.byKey(const Key('merchant-phone-field')).evaluate().isNotEmpty) {
        break;
      }
      await tester.pump(const Duration(milliseconds: 200));
    }
    if (find.byKey(const Key('merchant-onboarding')).evaluate().isNotEmpty) {
      await tester.tap(find.byKey(const Key('merchant-onboarding-skip')));
      await pumpFrames(tester, const Duration(seconds: 2));
    }
    for (var i = 0; i < 60; i++) {
      if (find.byKey(const Key('merchant-phone-field')).evaluate().isNotEmpty) {
        break;
      }
      await tester.pump(const Duration(milliseconds: 200));
    }
    expect(find.byKey(const Key('merchant-phone-field')), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('merchant-phone-field')),
      phoneLocal,
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    final otpBefore = File(otpFilePath).existsSync()
        ? File(otpFilePath).lastModifiedSync()
        : DateTime.fromMillisecondsSinceEpoch(0);
    expect(
      tester
          .widget<MerchantPrimaryButton>(
            find.byKey(const Key('merchant-phone-continue')),
          )
          .onPressed,
      isNotNull,
    );
    await tester.tap(find.byKey(const Key('merchant-phone-continue')));
    await pumpFrames(tester, const Duration(seconds: 2));

    for (var i = 0; i < 40; i++) {
      if (find.byKey(const Key('merchant-otp-field')).evaluate().isNotEmpty) {
        break;
      }
      await tester.pump(const Duration(milliseconds: 250));
    }
    expect(find.byKey(const Key('merchant-otp-field')), findsOneWidget);
    final otp = await waitForFreshOtp(otpBefore);
    await tester.enterText(find.byKey(const Key('merchant-otp-field')), otp);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(
      tester
          .widget<MerchantPrimaryButton>(
            find.byKey(const Key('merchant-otp-verify')),
          )
          .onPressed,
      isNotNull,
    );
    await tester.tap(find.byKey(const Key('merchant-otp-verify')));

    for (var i = 0; i < 80; i++) {
      if (find.text(AppStrings.verificationRejectedTitle).evaluate().isNotEmpty) {
        break;
      }
      await tester.pump(const Duration(milliseconds: 250));
    }
    expect(find.text(AppStrings.verificationRejectedTitle), findsOneWidget);
    expect(find.text(AppStrings.verificationRejectedBody), findsOneWidget);
    // v1.0: no Admin rejection reason — must not invent one.
    expect(find.textContaining('motif'), findsNothing);
    expect(find.textContaining('raison admin'), findsNothing);
    await hostShot('rejected');
    record(
      'rejected_ui_generic_guidance',
      'PASS',
      detail: 'Generic correction body; no persisted rejection reason (contract)',
    );

    await tapVisible(
      tester,
      find.byKey(const Key('merchant-verification-correct')),
    );
    await pumpFrames(tester, const Duration(seconds: 3));
    expect(find.byKey(const Key('merchant-registration')), findsOneWidget);

    // After reject, docs stay present (PENDING/"Ajouté") so resume may land on review.
    if (find
        .byKey(const Key('merchant-reg-doc-pick-BUSINESS_IDENTITY'))
        .evaluate()
        .isEmpty) {
      final edits = find.widgetWithText(TextButton, AppStrings.regEdit);
      expect(edits, findsWidgets);
      // Review blocks: activity (0), documents (1), establishment (2).
      await tester.tap(edits.at(1));
      await pumpFrames(tester, const Duration(seconds: 2));
    }

    for (var i = 0; i < 40; i++) {
      if (find
          .byKey(const Key('merchant-reg-doc-pick-BUSINESS_IDENTITY'))
          .evaluate()
          .isNotEmpty) {
        break;
      }
      await tester.pump(const Duration(milliseconds: 200));
    }
    expect(
      find.byKey(const Key('merchant-reg-doc-pick-BUSINESS_IDENTITY')),
      findsOneWidget,
    );
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
    await pumpFrames(tester, const Duration(seconds: 4));
    record(
      'correction_documents',
      'PASS',
      detail: 'Re-attached required evidence after REJECTED',
    );

    for (var i = 0; i < 40; i++) {
      if (find.byKey(const Key('merchant-reg-estab-continue')).evaluate().isNotEmpty ||
          find.byKey(const Key('merchant-reg-submit')).evaluate().isNotEmpty) {
        break;
      }
      await tester.pump(const Duration(milliseconds: 200));
    }
    if (find.byKey(const Key('merchant-reg-branch-name')).evaluate().isNotEmpty) {
      await tester.enterText(
        find.byKey(const Key('merchant-reg-branch-name')),
        'TEST FIXTURE Branch Alger (corrected)',
      );
      await tester.pump();
    }
    if (find.byKey(const Key('merchant-reg-estab-continue')).evaluate().isNotEmpty) {
      await tapVisible(
        tester,
        find.byKey(const Key('merchant-reg-estab-continue')),
      );
      await pumpFrames(tester, const Duration(seconds: 6));
    }

    for (var i = 0; i < 40; i++) {
      if (find.byKey(const Key('merchant-reg-submit')).evaluate().isNotEmpty) {
        break;
      }
      await tester.pump(const Duration(milliseconds: 250));
    }
    expect(find.byKey(const Key('merchant-reg-submit')), findsOneWidget);
    await hostShot('resubmit-review');
    await tapVisible(tester, find.byKey(const Key('merchant-reg-submit')));
    await pumpFrames(tester, const Duration(seconds: 8));
    expect(
      find.byKey(const Key('merchant-verification-pending')),
      findsOneWidget,
    );
    record('resubmit_pending', 'PASS');
    await hostShot('resubmit-pending');

    // Signal host to approve (API-only).
    File('/tmp/lifecycle_ready_for_approve.txt').writeAsStringSync('1\n');
    // ignore: avoid_print
    print('LIFECYCLE_READY_FOR_APPROVE=1');

    for (var i = 0; i < 120; i++) {
      if (File(approveMarker).existsSync() &&
          File(approveMarker).readAsStringSync().trim() == '1') {
        break;
      }
      await Future<void>.delayed(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(
      File(approveMarker).readAsStringSync().trim(),
      '1',
      reason: 'host did not signal approve',
    );

    await tapVisible(
      tester,
      find.byKey(const Key('merchant-verification-refresh')),
    );
    await pumpFrames(tester, const Duration(seconds: 8));

    // Approved + existing active branch → Home (operational enough for shell).
    for (var i = 0; i < 60; i++) {
      if (find.byKey(const Key('home-branch-name')).evaluate().isNotEmpty) {
        break;
      }
      await tester.pump(const Duration(milliseconds: 250));
    }
    expect(find.byKey(const Key('home-branch-name')), findsOneWidget);
    record('post_approve_home', 'PASS', detail: 'Refresh after Admin approve');
    await hostShot('approved-home');

    // Cold relaunch restoration: new root with persisted session (no keychain wipe).
    await tester.pumpWidget(const ProviderScope(child: SpeedyGoApp()));
    await pumpFrames(tester, const Duration(seconds: 8));
    for (var i = 0; i < 80; i++) {
      if (find.byKey(const Key('home-branch-name')).evaluate().isNotEmpty) {
        break;
      }
      if (find.byKey(const Key('merchant-phone-field')).evaluate().isNotEmpty) {
        break;
      }
      await tester.pump(const Duration(milliseconds: 200));
    }
    expect(find.byKey(const Key('home-branch-name')), findsOneWidget);
    expect(find.byKey(const Key('merchant-phone-field')), findsNothing);
    record('cold_relaunch_home', 'PASS');
    await hostShot('cold-relaunch-home');

    File('${auditDir.path}/step_results_correction.json').writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert({
        'phoneLocal': phoneLocal,
        'steps': steps,
        'notes': [
          'Admin reject/approve are API-only (host).',
          'v1.0 has no persisted rejection reason — generic guidance only.',
          'Approval ≠ catalog/order ops readiness (Phase 2 paused).',
        ],
      }),
    );
    // ignore: avoid_print
    print('LIFECYCLE_CORRECTION_STEPS=${jsonEncode(steps)}');
    // ignore: unused_local_variable
    final _ = shotDir;
  });
}
