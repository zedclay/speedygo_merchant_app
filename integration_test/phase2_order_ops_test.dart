import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:speedygo_merchant_app/app/app.dart';
import 'package:speedygo_merchant_app/core/constants/app_strings.dart';
import 'package:speedygo_merchant_app/core/widgets/merchant_primary_button.dart';

/// Live Merchant Phase 2 order mutations via UI taps on SE.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const phoneLocal = String.fromEnvironment(
    'PHASE2_PHONE',
    defaultValue: '559907701',
  );
  const acceptId = String.fromEnvironment('PHASE2_ACCEPT_ORDER_ID');
  const rejectId = String.fromEnvironment('PHASE2_REJECT_ORDER_ID');
  const otpFilePath = String.fromEnvironment(
    'PHASE2_OTP_FILE',
    defaultValue: '/Users/mac/.speedygo/dev/otp-last',
  );

  final auditDir = Directory(
    '/Users/mac/Downloads/speedygo_project/apps/merchant_app/audit/phase-2',
  )..createSync(recursive: true);
  final steps = <Map<String, dynamic>>[];

  void record(String id, String status, {String? detail}) {
    steps.add({
      'id': id,
      'status': status,
      'detail': detail,
      'layer': 'live_merchant_ui',
      'at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  Future<void> pumpFrames(WidgetTester tester, Duration total) async {
    final end = DateTime.now().add(total);
    while (DateTime.now().isBefore(end)) {
      await tester.pump(const Duration(milliseconds: 100));
    }
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
    await pumpFrames(tester, const Duration(seconds: 5));

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
      final verifyBtn = tester.widget<MerchantPrimaryButton>(
        find.byKey(const Key('merchant-otp-verify')),
      );
      expect(verifyBtn.onPressed, isNotNull);
      await tester.tap(find.byKey(const Key('merchant-otp-verify')));
      await pumpFrames(tester, const Duration(seconds: 10));
    }

    expect(find.byKey(const Key('home-branch-name')), findsOneWidget);
    record('login_home', 'PASS');
  }

  testWidgets('phase2 accept path + reject path (live UI)', (tester) async {
    expect(acceptId.isNotEmpty, isTrue);
    expect(rejectId.isNotEmpty, isTrue);

    await reachHome(tester);

    await tester.tap(find.byKey(const Key('nav-orders')));
    await pumpFrames(tester, const Duration(seconds: 5));
    expect(find.byKey(const Key('order-card-$acceptId')), findsOneWidget);
    record('orders_list', 'PASS', detail: 'accept card visible');

    await tester.tap(find.byKey(const Key('order-card-$acceptId')));
    await pumpFrames(tester, const Duration(seconds: 4));
    expect(find.byKey(const Key('order-accept')), findsOneWidget);
    File('/tmp/phase2_host_shot.txt').writeAsStringSync('incoming\n');
    await Future<void>.delayed(const Duration(seconds: 4));
    await tester.tap(find.byKey(const Key('order-accept')));
    await pumpFrames(tester, const Duration(seconds: 5));
    expect(find.byKey(const Key('order-start-prep')), findsOneWidget);
    record('accept', 'PASS');
    await tester.tap(find.byKey(const Key('order-start-prep')));
    await pumpFrames(tester, const Duration(seconds: 5));
    expect(find.byKey(const Key('order-mark-ready')), findsOneWidget);
    File('/tmp/phase2_host_shot.txt').writeAsStringSync('preparing\n');
    await Future<void>.delayed(const Duration(seconds: 4));
    record('start_preparation', 'PASS');
    await tester.tap(find.byKey(const Key('order-mark-ready')));
    await pumpFrames(tester, const Duration(seconds: 2));
    await tester.tap(find.byKey(const Key('order-mark-ready-confirm')));
    await pumpFrames(tester, const Duration(seconds: 5));
    expect(find.byKey(const Key('order-mark-ready')), findsNothing);
    File('/tmp/phase2_host_shot.txt').writeAsStringSync('ready\n');
    await Future<void>.delayed(const Duration(seconds: 4));
    record('mark_ready', 'PASS');

    await tester.tap(find.byKey(const Key('order-detail-back')));
    await pumpFrames(tester, const Duration(seconds: 3));

    await tester.tap(find.byKey(const Key('order-card-$rejectId')));
    await pumpFrames(tester, const Duration(seconds: 4));
    expect(find.byKey(const Key('order-reject')), findsOneWidget);
    await tester.tap(find.byKey(const Key('order-reject')));
    await pumpFrames(tester, const Duration(seconds: 2));
    await tester.enterText(
      find.byKey(const Key('order-reject-reason')),
      'TEST FIXTURE Phase2 refuse — rupture',
    );
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.byKey(const Key('order-reject-confirm')));
    await pumpFrames(tester, const Duration(seconds: 5));
    expect(find.byKey(const Key('order-cancellation-reason')), findsOneWidget);
    File('/tmp/phase2_host_shot.txt').writeAsStringSync('rejected\n');
    await Future<void>.delayed(const Duration(seconds: 4));
    record('reject', 'PASS');

    File('${auditDir.path}/fixtures/live_ui_steps.json').writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert({
        'phone': phoneLocal,
        'acceptOrderId': acceptId,
        'rejectOrderId': rejectId,
        'steps': steps,
      }),
    );
  });
}
