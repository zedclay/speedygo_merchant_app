import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:speedygo_merchant_app/app/app.dart';
import 'package:speedygo_merchant_app/core/constants/app_strings.dart';
import 'package:speedygo_merchant_app/core/widgets/merchant_primary_button.dart';

/// Post-rejection state verification — opens an already-cancelled order.
/// Does NOT re-run reject. Label: "Post-rejection state verified through live UI."
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const phoneLocal = String.fromEnvironment(
    'PHASE2_PHONE',
    defaultValue: '559907701',
  );
  const rejectId = String.fromEnvironment(
    'PHASE2_REJECT_ORDER_ID',
    defaultValue: '01a0b51d-bf20-785a-abcb-a3b7cd7381b5',
  );
  const expectedReason = String.fromEnvironment(
    'PHASE2_REJECT_REASON',
    defaultValue: 'TEST FIXTURE Phase2 refuse — rupture',
  );
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
      'layer': 'live_merchant_ui_post_rejection',
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

    var loggedIn = false;
    for (var attempt = 0; attempt < 80; attempt++) {
      await tester.pump(const Duration(milliseconds: 250));

      if (find.byKey(const Key('home-branch-name')).evaluate().isNotEmpty) {
        loggedIn = true;
        break;
      }

      if (find.byKey(const Key('merchant-language-fr')).evaluate().isNotEmpty) {
        await tester.tap(find.byKey(const Key('merchant-language-fr')));
        await pumpFrames(tester, const Duration(seconds: 3));
        continue;
      }

      if (find.byKey(const Key('merchant-onboarding-skip')).evaluate().isNotEmpty) {
        await tester.tap(find.byKey(const Key('merchant-onboarding-skip')));
        await pumpFrames(tester, const Duration(seconds: 3));
        continue;
      }

      if (find.byKey(const Key('merchant-onboarding-existing')).evaluate().isNotEmpty) {
        await tester.tap(find.byKey(const Key('merchant-onboarding-existing')));
        await pumpFrames(tester, const Duration(seconds: 2));
        continue;
      }

      if (find.byKey(const Key('merchant-phone-continue')).evaluate().isNotEmpty) {
        await tester.enterText(
          find.byKey(const Key('merchant-phone-field')),
          phoneLocal,
        );
        await tester.pump(const Duration(milliseconds: 500));
        final otpBefore = DateTime.now().subtract(const Duration(seconds: 1));
        await tester.tap(find.byKey(const Key('merchant-phone-continue')));
        // Wait for OTP screen (or surface error if rate-limited).
        var otpReady = false;
        for (var w = 0; w < 40; w++) {
          await tester.pump(const Duration(milliseconds: 250));
          if (find.byKey(const Key('merchant-otp-field')).evaluate().isNotEmpty) {
            otpReady = true;
            break;
          }
        }
        if (!otpReady) {
          fail(
            'OTP screen not shown after phone continue — likely OTP cooldown. '
            'Ensure host script clears auth:otp:* after API pre-check.',
          );
        }
        final otp = await waitForFreshOtp(otpBefore);
        await tester.enterText(find.byKey(const Key('merchant-otp-field')), otp);
        await tester.pump(const Duration(milliseconds: 300));
        final verifyBtn = tester.widget<MerchantPrimaryButton>(
          find.byKey(const Key('merchant-otp-verify')),
        );
        expect(verifyBtn.onPressed, isNotNull);
        await tester.tap(find.byKey(const Key('merchant-otp-verify')));
        await pumpFrames(tester, const Duration(seconds: 12));
        continue;
      }

      // Branch picker (multi-branch) — select first if present.
      if (find.textContaining('Succursale').evaluate().isNotEmpty ||
          find.byType(ListTile).evaluate().isNotEmpty) {
        final tiles = find.byType(ListTile);
        if (tiles.evaluate().isNotEmpty) {
          await tester.tap(tiles.first);
          await pumpFrames(tester, const Duration(seconds: 3));
        }
      }
    }

    expect(loggedIn, isTrue, reason: 'synthetic merchant never reached home');
    expect(find.byKey(const Key('home-branch-name')), findsOneWidget);
    record('login_home', 'PASS');
  }

  Future<void> openOrdersTab(WidgetTester tester) async {
    if (find.byKey(const Key('nav-orders')).evaluate().isNotEmpty) {
      await tester.tap(find.byKey(const Key('nav-orders')));
    } else if (find.byKey(const Key('nav-orders-active')).evaluate().isNotEmpty) {
      await tester.tap(find.byKey(const Key('nav-orders-active')));
    } else if (find.byKey(const Key('home-count-incoming')).evaluate().isNotEmpty) {
      await tester.tap(find.byKey(const Key('home-count-incoming')));
    } else {
      await tester.tap(find.text(AppStrings.tabOrders).last);
    }
    await pumpFrames(tester, const Duration(seconds: 3));

    for (var i = 0; i < 40; i++) {
      if (find.byKey(const Key('orders-segment-bar')).evaluate().isNotEmpty) {
        return;
      }
      if (find.byKey(const Key('orders-refresh')).evaluate().isNotEmpty) {
        return;
      }
      await tester.pump(const Duration(milliseconds: 200));
    }
    fail('Orders screen not reached after nav tap');
  }

  testWidgets('post-rejection state verified through live UI', (tester) async {
    expect(rejectId.isNotEmpty, isTrue);
    await reachHome(tester);

    await openOrdersTab(tester);
    expect(find.byKey(const Key('orders-segment-bar')), findsOneWidget);

    // Historique → Annulées (cancelled chip only visible in history segment).
    await tester.tap(find.byKey(const Key('orders-segment-history')));
    await pumpFrames(tester, const Duration(seconds: 2));
    final cancelledChip = find.byKey(const Key('orders-filter-cancelled'));
    expect(cancelledChip, findsOneWidget);
    await tester.ensureVisible(cancelledChip);
    await tester.tap(cancelledChip);
    await pumpFrames(tester, const Duration(seconds: 4));
    record('filter_cancelled', 'PASS');

    final card = find.byKey(const Key('order-card-$rejectId'));
    expect(card, findsOneWidget);
    File('/tmp/phase2_post_reject_shot.txt').writeAsStringSync('list-cancelled\n');
    await Future<void>.delayed(const Duration(seconds: 4));

    await tester.tap(card);
    await pumpFrames(tester, const Duration(seconds: 5));

    // Server-backed cancelled presentation.
    expect(find.byKey(const Key('order-detail-ref')), findsOneWidget);
    expect(find.byKey(const Key('order-cancellation-reason')), findsOneWidget);
    expect(find.textContaining(expectedReason), findsWidgets);
    expect(find.text(AppStrings.orderStatusCancelled), findsWidgets);

    // No mutation CTAs.
    expect(find.byKey(const Key('order-accept')), findsNothing);
    expect(find.byKey(const Key('order-reject')), findsNothing);
    expect(find.byKey(const Key('order-start-prep')), findsNothing);
    expect(find.byKey(const Key('order-mark-ready')), findsNothing);
    record('cancelled_detail', 'PASS', detail: expectedReason);

    File('/tmp/phase2_post_reject_shot.txt').writeAsStringSync('post-rejected-detail\n');
    await Future<void>.delayed(const Duration(seconds: 5));

    // Back to cancelled list filter.
    await tester.tap(find.byKey(const Key('order-detail-back')));
    await pumpFrames(tester, const Duration(seconds: 3));
    expect(find.byKey(const Key('orders-filter-cancelled')), findsOneWidget);
    // Filter selection should still be cancelled (provider state preserved).
    expect(find.byKey(const Key('order-card-$rejectId')), findsOneWidget);
    File('/tmp/phase2_post_reject_shot.txt').writeAsStringSync('list-cancelled-after-back\n');
    await Future<void>.delayed(const Duration(seconds: 4));
    record('back_to_cancelled_list', 'PASS');

    File('${auditDir.path}/fixtures/live_post_rejection_steps.json')
        .writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert({
        'label': 'Post-rejection state verified through live UI.',
        'note':
            'Does not recover the missed screenshot of the original rejection tap.',
        'rejectOrderId': rejectId,
        'expectedReason': expectedReason,
        'steps': steps,
      }),
    );
  });
}
