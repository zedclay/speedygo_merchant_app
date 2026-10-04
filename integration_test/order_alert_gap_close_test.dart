import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:speedygo_merchant_app/app/app.dart';
import 'package:speedygo_merchant_app/app/router/app_router.dart';
import 'package:speedygo_merchant_app/core/constants/app_strings.dart';
import 'package:speedygo_merchant_app/core/navigation/app_routes.dart';
import 'package:speedygo_merchant_app/features/notifications/application/order_alert_controller.dart';

/// Gap-close: offline→reconnect, resume, multi-order, inbox/prefs shots.
///
/// Host protocol (files under /tmp):
/// - ALERT_OFFLINE_GATE file present ⇒ merchant API path treated offline
/// - /tmp/alert_gap_order_ids.txt — newline-separated PENDING order ids created
///   while "offline" (or for multi-order), then gate removed for reconnect
///
/// Dart-defines:
/// - ALERT_LIVE_PHONE
/// - ALERT_OFFLINE_GATE (path)
/// - ALERT_GAP_MODE = reconnect | resume_stale | multi | shots
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const phoneLocal = String.fromEnvironment(
    'ALERT_LIVE_PHONE',
    defaultValue: '550000071',
  );
  const offlineGate = String.fromEnvironment(
    kAlertOfflineGateEnv,
    defaultValue: '/tmp/sg_merchant_offline',
  );
  const mode = String.fromEnvironment(
    'ALERT_GAP_MODE',
    defaultValue: 'reconnect',
  );
  const otpFilePath = String.fromEnvironment(
    'ALERT_OTP_FILE',
    defaultValue: '/Users/mac/.speedygo/dev/otp-last',
  );
  const shotMarker = '/tmp/alert_host_shot.txt';
  const orderIdsFile = '/tmp/alert_gap_order_ids.txt';
  final outDir = Directory(
    '/Users/mac/Downloads/speedygo_project/apps/merchant_app/audit/phase-5-ui/order-alerts-live',
  )..createSync(recursive: true);

  final steps = <Map<String, dynamic>>[];

  void record(String id, String status, {String? detail}) {
    steps.add({
      'id': id,
      'status': status,
      'detail': detail,
      'mode': mode,
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
      // Verify is enabled only after the rebuild that follows onChanged.
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.byKey(const Key('merchant-otp-verify')));
      await pumpFrames(tester, const Duration(seconds: 10));
    }
    expect(find.textContaining('Dar El Bahja'), findsWidgets);
  }

  ProviderContainer containerOf(WidgetTester tester) {
    return ProviderScope.containerOf(
      tester.element(find.byType(MaterialApp).first),
    );
  }

  Future<bool> waitForAlert(WidgetTester tester, ProviderContainer c) async {
    for (var i = 0; i < 30; i++) {
      if (find.byKey(const Key('incoming-order-alert')).evaluate().isNotEmpty) {
        return true;
      }
      await c.read(orderAlertControllerProvider.notifier).reconcile(
            reason: mode == 'reconnect' ? 'reconnect' : 'poll',
          );
      await pumpFrames(tester, const Duration(seconds: 1));
    }
    return false;
  }

  void writeProvenance({String? error}) {
    File('${outDir.path}/ORDER_ALERT_GAP_PROVENANCE.json').writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert({
        'fixture': 'Dar El Bahja',
        'phone': '+213$phoneLocal',
        'mode': mode,
        'pollIntervalSeconds': kMerchantOrderAlertPollInterval.inSeconds,
        'harnessResult': error == null ? 'PASS' : 'FAIL',
        'error': error,
        'steps': steps,
        'nativePush': 'NOT_EXERCISED (DisabledPushMessagingGateway; no Firebase options in this build)',
        'nativePushRequirement':
            'FCM adapter + firebase_messaging client are implemented; delivery still needs '
            'FCM credentials (backend) and Firebase options (config/push.local.json). '
            'See docs/architecture/NATIVE_PUSH_SETUP.md and audit/phase-5-ui/native-push/NATIVE_PUSH_REPORT.md. '
            'Foreground poll evidence here is independent of Push.',
        'offlineSimulation': mode == 'reconnect'
            ? 'harness_injected_file_gate (ALERT_OFFLINE_GATE) — not a native device-network disconnect'
            : null,
      }),
    );
  }

  testWidgets('order-alert gap mode=$mode', (tester) async {
    try {
      await reachHome(tester);
      record('home_loaded', 'PASS');
      final c = containerOf(tester);

      if (mode == 'shots') {
        // Clear any leftover foreground alert so inbox/prefs are visible.
        final alerts = c.read(orderAlertControllerProvider.notifier);
        final active = c.read(orderAlertControllerProvider).activeAlert;
        if (active != null) {
          alerts.markOrderHandled(active.orderId, promoteNext: false);
        }
        alerts.dismissActive();
        await pumpFrames(tester, const Duration(seconds: 1));

        Future<void> capturePair(String suffix) async {
          c.read(appRouterProvider).go(AppRoutes.notifications);
          await pumpFrames(tester, const Duration(seconds: 3));
          expect(find.text(AppStrings.notificationsTitle), findsWidgets);
          expect(
            find.byKey(const Key('incoming-order-alert')),
            findsNothing,
          );
          await markShot('alert-inbox$suffix');
          record('inbox_shot$suffix', 'PASS');

          c.read(appRouterProvider).push(AppRoutes.notificationSettings);
          await pumpFrames(tester, const Duration(seconds: 3));
          expect(
            find.byKey(const Key('notification-settings-screen')),
            findsOneWidget,
          );
          final unavailable = find.text(
            AppStrings.notifSettingsPushUnavailable,
          );
          if (unavailable.evaluate().isEmpty) {
            await tester.dragUntilVisible(
              unavailable,
              find.byKey(const Key('notification-settings-screen')),
              const Offset(0, -80),
            );
            await pumpFrames(tester, const Duration(milliseconds: 500));
          }
          expect(unavailable, findsWidgets);
          expect(find.textContaining('écran de verrouillage'), findsNothing);
          await markShot('alert-preferences$suffix');
          record('preferences_shot$suffix', 'PASS');
        }

        await capturePair('');
        tester.platformDispatcher.textScaleFactorTestValue = 1.35;
        addTearDown(() {
          tester.platformDispatcher.clearTextScaleFactorTestValue();
        });
        await pumpFrames(tester, const Duration(seconds: 1));
        await capturePair('-a11y');
        writeProvenance();
        return;
      }

      if (mode == 'reconnect') {
        // Reset alert session so leftover PENDING orders from fixtures do not
        // keep an overlay open through the offline window.
        final alerts = c.read(orderAlertControllerProvider.notifier);
        alerts.stop();
        File(offlineGate).writeAsStringSync('1');
        record('offline_gate_on', 'PASS');
        await alerts.start();
        await pumpFrames(tester, const Duration(seconds: 2));
        await alerts.reconcile(reason: 'poll');
        await pumpFrames(tester, const Duration(seconds: 1));
        expect(
          find.byKey(const Key('incoming-order-alert')),
          findsNothing,
          reason: 'no alert while offline',
        );
        record('offline_no_alert', 'PASS');

        // Host creates order(s) while gate is on; wait for ids file.
        List<String> ids = const [];
        for (var i = 0; i < 90; i++) {
          final f = File(orderIdsFile);
          if (f.existsSync()) {
            ids = f
                .readAsStringSync()
                .split('\n')
                .map((e) => e.trim())
                .where((e) => e.isNotEmpty)
                .toList();
            if (ids.isNotEmpty) break;
          }
          await Future<void>.delayed(const Duration(milliseconds: 500));
        }
        expect(ids, isNotEmpty, reason: 'host must write order ids while offline');
        record('orders_created_while_offline', 'PASS', detail: ids.join(','));

        // Still offline — reconcile must not surface.
        await c
            .read(orderAlertControllerProvider.notifier)
            .reconcile(reason: 'poll');
        await pumpFrames(tester, const Duration(seconds: 1));
        expect(find.byKey(const Key('incoming-order-alert')), findsNothing);
        record('still_offline_no_alert', 'PASS');

        // Reconnect.
        if (File(offlineGate).existsSync()) {
          File(offlineGate).deleteSync();
        }
        record('offline_gate_off', 'PASS');
        await c
            .read(orderAlertControllerProvider.notifier)
            .reconcile(reason: 'reconnect');
        await pumpFrames(tester, const Duration(seconds: 2));
        final seen = await waitForAlert(tester, c);
        expect(seen, isTrue);
        expect(find.byKey(const Key('incoming-order-alert')), findsOneWidget);
        final active =
            c.read(orderAlertControllerProvider).activeAlert;
        expect(active, isNotNull);
        expect(
          ids.contains(active!.orderId),
          isTrue,
          reason: 'alert must be the order created while offline',
        );
        record('reconnect_one_alert', 'PASS', detail: active.orderId);
        await markShot('alert-incoming');

        await tester.tap(find.byKey(const Key('incoming-alert-details')));
        await pumpFrames(tester, const Duration(seconds: 8));
        var dismissed = false;
        for (var i = 0; i < 20; i++) {
          if (find.byKey(const Key('incoming-order-alert')).evaluate().isEmpty) {
            dismissed = true;
            break;
          }
          await pumpFrames(tester, const Duration(milliseconds: 500));
        }
        expect(dismissed, isTrue);
        record('reconnect_tap_opens', 'PASS');
        await markShot('alert-opened-order');
        writeProvenance();
        return;
      }

      if (mode == 'multi') {
        List<String> ids = const [];
        for (var i = 0; i < 60; i++) {
          final f = File(orderIdsFile);
          if (f.existsSync()) {
            ids = f
                .readAsStringSync()
                .split('\n')
                .map((e) => e.trim())
                .where((e) => e.isNotEmpty)
                .toList();
            if (ids.length >= 2) break;
          }
          await Future<void>.delayed(const Duration(milliseconds: 500));
        }
        expect(ids.length, greaterThanOrEqualTo(2));
        await c
            .read(orderAlertControllerProvider.notifier)
            .reconcile(reason: 'poll');
        await pumpFrames(tester, const Duration(seconds: 2));
        final seen = await waitForAlert(tester, c);
        expect(seen, isTrue);
        final queued =
            c.read(orderAlertControllerProvider.notifier).queuedAlertCount;
        expect(
          queued + 1,
          greaterThanOrEqualTo(2),
          reason: 'active + queue must cover burst orders',
        );
        record('multi_order_queued', 'PASS', detail: 'queued=$queued ids=${ids.length}');
        await markShot('alert-incoming');
        writeProvenance();
        return;
      }

      if (mode == 'resume_stale') {
        // Expect host to have accepted/rejected the order listed in ids file
        // after alert was shown once — we show, then host mutates, then resume.
        final seen = await waitForAlert(tester, c);
        expect(seen, isTrue);
        record('alert_before_stale', 'PASS');
        await markShot('alert-incoming');

        // Signal host we are ready for stale mutation.
        File('/tmp/alert_gap_ready_for_stale.txt').writeAsStringSync('1');
        // Wait for host to clear ready flag after mutation.
        for (var i = 0; i < 60; i++) {
          if (!File('/tmp/alert_gap_ready_for_stale.txt').existsSync()) break;
          await Future<void>.delayed(const Duration(milliseconds: 500));
        }
        record('host_mutated_order', 'PASS');

        // Simulate return from background.
        c.read(orderAlertControllerProvider.notifier).onLifecycle(
              AppLifecycleState.paused,
            );
        await pumpFrames(tester, const Duration(milliseconds: 500));
        c.read(orderAlertControllerProvider.notifier).onLifecycle(
              AppLifecycleState.resumed,
            );
        await pumpFrames(tester, const Duration(seconds: 3));
        await c
            .read(orderAlertControllerProvider.notifier)
            .reconcile(reason: 'resume');
        await pumpFrames(tester, const Duration(seconds: 2));

        final alert = c.read(orderAlertControllerProvider).activeAlert;
        final staleIds = File(orderIdsFile).existsSync()
            ? File(orderIdsFile)
                .readAsStringSync()
                .split('\n')
                .map((e) => e.trim())
                .where((e) => e.isNotEmpty)
                .toSet()
            : <String>{};
        if (alert != null) {
          expect(
            alert.isStillIncoming,
            isTrue,
            reason: 'if an alert remains it must still be pending',
          );
          expect(
            staleIds.contains(alert.orderId),
            isFalse,
            reason: 'accepted/handled order must not remain as new-order alert',
          );
          record(
            'resume_alert_still_pending',
            'PASS',
            detail: 'otherPending=${alert.orderId}',
          );
        } else {
          record('resume_stale_dismissed', 'PASS');
        }
        // Must not show accept CTA for a non-pending order as "new".
        writeProvenance();
        return;
      }

      fail('Unknown ALERT_GAP_MODE=$mode');
    } catch (e, st) {
      record('fatal', 'FAIL', detail: '$e\n$st');
      writeProvenance(error: e.toString());
      rethrow;
    }
  });
}
