import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:speedygo_merchant_app/app/app.dart';
import 'package:speedygo_merchant_app/app/router/app_router.dart';
import 'package:speedygo_merchant_app/core/constants/app_strings.dart';
import 'package:speedygo_merchant_app/core/navigation/app_routes.dart';
import 'package:speedygo_merchant_app/core/storage/approval_notice_store.dart';
import 'package:speedygo_merchant_app/core/storage/session_store.dart';
import 'package:speedygo_merchant_app/features/auth/application/session_providers.dart';
import 'package:speedygo_merchant_app/features/auth/application/session_controller.dart';
import 'package:speedygo_merchant_app/features/notifications/application/merchant_push_controller.dart';
import 'package:speedygo_merchant_app/features/notifications/data/push_registration.dart';
import 'package:speedygo_merchant_app/features/orders/application/orders_controller.dart';
import 'package:speedygo_merchant_app/features/reports/application/daily_summary_controller.dart';
import 'package:speedygo_merchant_app/features/reports/presentation/report_widgets.dart';

/// Isolated live captures for Daily Summary + delayed-order delivery impact.
/// Host: audit/parity/isolated/fx_daily_delay_live.sh
class _MemoryPushRegistration extends MerchantPushRegistration {
  StoredPushToken? _stored;

  @override
  Future<void> storeRegisteredToken({
    required String token,
    required String platform,
    required String? accountId,
  }) async {
    _stored = (token: token, platform: platform, accountId: accountId);
  }

  @override
  Future<StoredPushToken?> loadStoredToken() async => _stored;

  @override
  Future<void> clearStoredToken() async => _stored = null;
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const otpFilePath = String.fromEnvironment('FX_OTP_FILE');
  const evidenceDir = String.fromEnvironment('FX_EVIDENCE_DIR');
  const prefix = String.fromEnvironment('PARITY_PREFIX', defaultValue: 'fxdd');
  const lateOrderId = String.fromEnvironment('FX_LATE_ORDER_ID');
  const ownerPhone = String.fromEnvironment(
    'FX_OWNER_PHONE',
    defaultValue: '550009101',
  );
  const staffPhone = String.fromEnvironment(
    'FX_STAFF_PHONE',
    defaultValue: '550009103',
  );
  const shotMarker = '/tmp/parity_fx_isolated_shot.txt';
  const apiBase = String.fromEnvironment('API_BASE_URL');

  final sessions = MemorySessionStore();
  final contexts = MemoryContextStore();
  final launches = MemoryLaunchStore();
  final approvals = MemoryApprovalNoticeStore();
  final pushTokens = _MemoryPushRegistration();
  final checks = <String, Object?>{};

  Future<void> pumpFrames(WidgetTester tester, Duration total) async {
    final end = DateTime.now().add(total);
    while (DateTime.now().isBefore(end)) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> waitFor(
    WidgetTester tester,
    Finder finder, {
    Duration timeout = const Duration(seconds: 45),
  }) async {
    final end = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(end)) {
      await pumpFrames(tester, const Duration(milliseconds: 200));
      if (finder.evaluate().isNotEmpty) return;
    }
    throw TestFailure('Timed out waiting for $finder');
  }

  Future<void> tapVisible(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await pumpFrames(tester, const Duration(milliseconds: 350));
    await tester.tap(finder, warnIfMissed: false);
    await pumpFrames(tester, const Duration(milliseconds: 400));
  }

  Future<void> shot(WidgetTester tester, String tag) async {
    FocusManager.instance.primaryFocus?.unfocus();
    await pumpFrames(tester, const Duration(milliseconds: 1200));
    File(shotMarker).writeAsStringSync('${prefix}_$tag\n');
    await pumpFrames(tester, const Duration(seconds: 2));
  }

  Future<String> waitForFreshOtp(DateTime after) async {
    final file = File(otpFilePath);
    for (var i = 0; i < 80; i++) {
      if (file.existsSync() && !file.lastModifiedSync().isBefore(after)) {
        final otp = file.readAsStringSync().trim();
        if (RegExp(r'^\d{4,8}$').hasMatch(otp)) return otp;
      }
      await Future<void>.delayed(const Duration(milliseconds: 250));
    }
    throw StateError('OTP not found');
  }

  Future<void> pumpApp(WidgetTester tester) => tester.pumpWidget(
        ProviderScope(
          key: UniqueKey(),
          overrides: [
            sessionStoreProvider.overrideWithValue(sessions),
            contextStoreProvider.overrideWithValue(contexts),
            launchStoreProvider.overrideWithValue(launches),
            approvalNoticeStoreProvider.overrideWithValue(approvals),
            pushRegistrationStoreProvider.overrideWithValue(pushTokens),
          ],
          child: const SpeedyGoApp(),
        ),
      );

  Future<void> login(WidgetTester tester, String phoneLocal) async {
    await pumpApp(tester);
    final end = DateTime.now().add(const Duration(seconds: 90));
    while (find.byKey(const Key('merchant-phone-field')).evaluate().isEmpty) {
      if (DateTime.now().isAfter(end)) {
        throw TestFailure('phone login not reached');
      }
      if (find.byKey(const Key('merchant-language-fr')).evaluate().isNotEmpty) {
        final scrollables = find.byType(Scrollable);
        if (scrollables.evaluate().isNotEmpty) {
          await tester.drag(scrollables.first, const Offset(0, -240));
          await pumpFrames(tester, const Duration(milliseconds: 400));
        }
        await tapVisible(tester, find.byKey(const Key('merchant-language-fr')));
      } else if (find
          .byKey(const Key('merchant-onboarding-skip'))
          .evaluate()
          .isNotEmpty) {
        await tapVisible(
          tester,
          find.byKey(const Key('merchant-onboarding-skip')),
        );
      }
      await pumpFrames(tester, const Duration(milliseconds: 500));
    }
    await tester.enterText(
      find.byKey(const Key('merchant-phone-field')),
      phoneLocal,
    );
    await tester.pump(const Duration(milliseconds: 400));
    final otpBefore = DateTime.now().subtract(const Duration(seconds: 1));
    await tapVisible(tester, find.byKey(const Key('merchant-phone-continue')));
    await waitFor(tester, find.byKey(const Key('merchant-otp-field')));
    final otp = await waitForFreshOtp(otpBefore);
    await tester.enterText(find.byKey(const Key('merchant-otp-field')), otp);
    await tester.pump(const Duration(milliseconds: 300));
    await tapVisible(tester, find.byKey(const Key('merchant-otp-verify')));
    await pumpFrames(tester, const Duration(seconds: 5));
    await waitFor(tester, find.byKey(const Key('home-branch-name')));
  }

  GoRouter routerOf(WidgetTester tester) => ProviderScope.containerOf(
        tester.element(find.byType(MaterialApp).first),
      ).read(appRouterProvider);

  ProviderContainer containerOf(WidgetTester tester) =>
      ProviderScope.containerOf(tester.element(find.byType(MaterialApp).first));

  Future<void> requestOtpClear(WidgetTester tester) async {
    // Host watcher (fx_daily_delay_live.sh) clears Redis index 9 OTP keys.
    File(shotMarker).writeAsStringSync('${prefix}_clear_otp\n');
    await pumpFrames(tester, const Duration(seconds: 3));
  }

  Future<void> logout(WidgetTester tester) async {
    await containerOf(tester).read(sessionControllerProvider.notifier).logout();
    await pumpFrames(tester, const Duration(seconds: 2));
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 300));
    await requestOtpClear(tester);
  }

  testWidgets('daily summary + delayed order live captures', (tester) async {
    expect(otpFilePath.isNotEmpty, isTrue);
    expect(apiBase.contains('3100'), isTrue);
    expect(lateOrderId.isNotEmpty, isTrue, reason: 'FX_LATE_ORDER_ID required');

    await login(tester, ownerPhone);
    final router = routerOf(tester);
    final container = containerOf(tester);

    router.go(AppRoutes.reportsDailySummary);
    await pumpFrames(tester, const Duration(seconds: 4));
    await waitFor(tester, find.byKey(const Key('daily-summary-screen')));
    checks['dailySummaryLoaded'] = true;
    await shot(tester, 'daily_summary');

    final scrollables = find.byType(Scrollable);
    if (scrollables.evaluate().isNotEmpty) {
      await tester.drag(scrollables.first, const Offset(0, -480));
      await pumpFrames(tester, const Duration(milliseconds: 800));
      await shot(tester, 'daily_summary_end');
    }

    // Empty day via civil date with no fixture orders.
    container.read(dailySummaryDateProvider.notifier).select('2020-01-15');
    await pumpFrames(tester, const Duration(seconds: 3));
    await waitFor(tester, find.byKey(const Key('daily-summary-empty')));
    checks['dailySummaryEmpty'] = true;
    await shot(tester, 'daily_summary_empty');
    container
        .read(dailySummaryDateProvider.notifier)
        .select(reportCivilDate(DateTime.now()));
    await pumpFrames(tester, const Duration(seconds: 3));
    await waitFor(tester, find.byKey(const Key('daily-summary-screen')));

    router.go(AppRoutes.orderDetail(lateOrderId));
    await pumpFrames(tester, const Duration(seconds: 5));
    await waitFor(tester, find.byKey(const Key('order-detail')));
    await container
        .read(orderDetailControllerProvider(lateOrderId).notifier)
        .reload();
    await pumpFrames(tester, const Duration(seconds: 3));
    checks['delayedOrderLoaded'] = true;
    await shot(tester, 'delayed_order_before');

    final impact = find.byKey(const Key('delivery-impact-card'));
    if (impact.evaluate().isNotEmpty) {
      checks['deliveryImpactVisible'] = true;
      await tester.ensureVisible(impact);
      await pumpFrames(tester, const Duration(milliseconds: 600));
      await shot(tester, 'delayed_order_impact');
    } else {
      checks['deliveryImpactVisible'] = false;
    }

    // Open update sheet (before confirm) then apply +10 with a reason.
    if (find.byKey(const Key('prep-update-open')).evaluate().isNotEmpty) {
      await tapVisible(tester, find.byKey(const Key('prep-update-open')));
      await pumpFrames(tester, const Duration(seconds: 2));
      await waitFor(tester, find.byKey(const Key('update-prep-sheet')));
      await shot(tester, 'delayed_order_update_sheet');
      if (find.byKey(const Key('prep-add-10')).evaluate().isNotEmpty) {
        await tapVisible(tester, find.byKey(const Key('prep-add-10')));
      }
      if (find.byKey(const Key('prep-reason-busy')).evaluate().isNotEmpty) {
        await tapVisible(tester, find.byKey(const Key('prep-reason-busy')));
        await shot(tester, 'delayed_order_update_reason');
      }
      await tapVisible(tester, find.byKey(const Key('prep-update-confirm')));
      await pumpFrames(tester, const Duration(seconds: 4));
      checks['prepEstimateUpdated'] = true;
      await shot(tester, 'delayed_order_after');
    } else {
      checks['prepEstimateUpdated'] = false;
    }

    // Cold relaunch → daily summary still loads with persisted session.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 400));
    await pumpApp(tester);
    await pumpFrames(tester, const Duration(seconds: 5));
    routerOf(tester).go(AppRoutes.reportsDailySummary);
    await pumpFrames(tester, const Duration(seconds: 4));
    await waitFor(tester, find.byKey(const Key('daily-summary-screen')));
    checks['dailySummaryCold'] = true;
    await shot(tester, 'daily_summary_cold');

    await logout(tester);

    // STAFF: operational metrics only; sales must stay "—".
    await login(tester, staffPhone);
    routerOf(tester).go(AppRoutes.reportsDailySummary);
    await pumpFrames(tester, const Duration(seconds: 4));
    await waitFor(tester, find.byKey(const Key('daily-summary-screen')));
    final staffSales = find.descendant(
      of: find.byKey(const Key('daily-summary-kpi-sales')),
      matching: find.text(AppStrings.reportsDataUnavailableShort),
    );
    checks['staffSalesRestricted'] = staffSales.evaluate().isNotEmpty;
    await shot(tester, 'daily_summary_staff');

    await logout(tester);

    File(shotMarker).writeAsStringSync('${prefix}_99_done\n');
    if (evidenceDir.isNotEmpty) {
      File('$evidenceDir/PROVENANCE_$prefix.json').writeAsStringSync(
        const JsonEncoder.withIndent('  ').convert({
          'app': 'merchant',
          'backend': 'isolated speedygo_parity_fx',
          'apiBase': apiBase,
          'lateOrderId': lateOrderId,
          'checks': checks,
        }),
      );
    }
  });
}
