import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:speedygo_merchant_app/app/app.dart';
import 'package:speedygo_merchant_app/core/constants/app_strings.dart';
import 'package:speedygo_merchant_app/features/notifications/application/order_alert_controller.dart';

/// Live new-order alert on Dar El Bahja (foreground poll path).
///
/// Dart-defines:
/// - ALERT_ORDER_ID — PENDING_ACCEPTANCE order already created for this branch
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const phoneLocal = String.fromEnvironment(
    'ALERT_LIVE_PHONE',
    defaultValue: '550000071',
  );
  const orderId = String.fromEnvironment('ALERT_ORDER_ID');
  const otpFilePath = String.fromEnvironment(
    'ALERT_OTP_FILE',
    defaultValue: '/Users/mac/.speedygo/dev/otp-last',
  );
  const shotMarker = '/tmp/alert_host_shot.txt';
  final outDir = Directory(
    '/Users/mac/Downloads/speedygo_project/apps/merchant_app/audit/phase-5-ui/order-alerts-live',
  )..createSync(recursive: true);

  final steps = <Map<String, dynamic>>[];

  void record(String id, String status, {String? detail}) {
    steps.add({
      'id': id,
      'status': status,
      'detail': detail,
      'layer': 'automated_integration',
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
    File(shotMarker).writeAsStringSync('$tag\n');
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
      await tester.tap(find.byKey(const Key('merchant-otp-verify')));
      await pumpFrames(tester, const Duration(seconds: 10));
    }
    expect(find.textContaining('Dar El Bahja'), findsWidgets);
  }

  void writeProvenance({String? error}) {
    File('${outDir.path}/ORDER_ALERT_LIVE_PROVENANCE.json').writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert({
        'fixture': 'Dar El Bahja',
        'phone': '+213$phoneLocal',
        'orderId': orderId,
        'pollIntervalSeconds': kMerchantOrderAlertPollInterval.inSeconds,
        'harnessResult': error == null ? 'PASS' : 'FAIL',
        'error': error,
        'steps': steps,
        'nativePush': 'BLOCKED',
        'nativePushRequirement':
            'APNs/FCM credentials + provider adapter; DeviceToken APIs ready but Push stays SKIPPED_NOT_CONFIGURED',
      }),
    );
  }

  testWidgets('foreground new-order alert + dedupe + open', (tester) async {
    expect(orderId.isNotEmpty, isTrue, reason: 'ALERT_ORDER_ID required');
    try {
      await reachHome(tester);
      record('home_loaded', 'PASS');

      // Force reconcile (also covered by 8s poller).
      final container = ProviderScope.containerOf(
        tester.element(find.byType(MaterialApp).first),
      );
      await container
          .read(orderAlertControllerProvider.notifier)
          .reconcile(reason: 'start');
      await pumpFrames(tester, const Duration(seconds: 4));

      // Wait up to ~20s for alert (poll + reconcile).
      var seen = false;
      for (var i = 0; i < 25; i++) {
        if (find.byKey(const Key('incoming-order-alert')).evaluate().isNotEmpty) {
          seen = true;
          break;
        }
        await container
            .read(orderAlertControllerProvider.notifier)
            .reconcile(reason: 'poll');
        await pumpFrames(tester, const Duration(seconds: 1));
      }
      expect(seen, isTrue, reason: 'incoming alert must appear for order');
      record('foreground_alert', 'PASS');
      await markShot('alert-incoming');

      // Duplicate reconcile must not stack a second overlay.
      await container
          .read(orderAlertControllerProvider.notifier)
          .reconcile(reason: 'poll');
      await pumpFrames(tester, const Duration(seconds: 2));
      expect(find.byKey(const Key('incoming-order-alert')), findsOneWidget);
      record('dedupe_single_alert', 'PASS');

      await tester.tap(find.byKey(const Key('incoming-alert-details')));
      await pumpFrames(tester, const Duration(seconds: 8));
      // Overlay must dismiss after tap (dedupe marks order handled).
      var dismissed = false;
      for (var i = 0; i < 20; i++) {
        if (find.byKey(const Key('incoming-order-alert')).evaluate().isEmpty) {
          dismissed = true;
          break;
        }
        await pumpFrames(tester, const Duration(milliseconds: 500));
      }
      expect(dismissed, isTrue, reason: 'alert dismisses after open');
      record('alert_tap_opens_order', 'PASS');
      await markShot('alert-opened-order');

      // Second reconcile after open: no re-alert for same order.
      await container
          .read(orderAlertControllerProvider.notifier)
          .reconcile(reason: 'poll');
      await pumpFrames(tester, const Duration(seconds: 2));
      expect(find.byKey(const Key('incoming-order-alert')), findsNothing);
      record('no_repeat_after_open', 'PASS');

      writeProvenance();
    } catch (e, st) {
      record('fatal', 'FAIL', detail: '$e\n$st');
      writeProvenance(error: e.toString());
      rethrow;
    }
  });
}
