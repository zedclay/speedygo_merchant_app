import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderParagraph;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:speedygo_merchant_app/app/app.dart';
import 'package:speedygo_merchant_app/core/constants/app_strings.dart';
import 'package:speedygo_merchant_app/core/money/money_format.dart';
import 'package:speedygo_merchant_app/features/reports/application/sales_report_controller.dart';
import 'package:speedygo_merchant_app/features/reports/data/reports_models.dart';

/// Authenticated Reports smoke on the Dar El Bahja synthetic Merchant against
/// the local dev backend, with the controlled fixture from
/// `audit/phase-5-ui/reports-live/seed_reports_live_fixture.sql`.
///
/// Screenshots are taken by a host watcher reading [shotMarker] (simctl).
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const phoneLocal = String.fromEnvironment(
    'REPORTS_LIVE_PHONE',
    defaultValue: '550000071',
  );
  const otpFilePath = String.fromEnvironment(
    'REPORTS_OTP_FILE',
    defaultValue: '/Users/mac/.speedygo/dev/otp-last',
  );
  const prefix = String.fromEnvironment(
    'REPORTS_SHOT_PREFIX',
    defaultValue: 'live',
  );
  const device = String.fromEnvironment('REPORTS_DEVICE', defaultValue: '');
  const shotMarker = '/tmp/reports_live_shot.txt';
  final outDir = Directory(
    '/Users/mac/Downloads/speedygo_project/apps/merchant_app/audit/phase-5-ui/reports-live',
  )..createSync(recursive: true);

  final steps = <Map<String, Object?>>[];
  final observed = <String, Object?>{};

  void record(String id, String status, [Object? detail]) {
    steps.add({
      'id': id,
      'status': status,
      'detail': detail,
      'at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  Future<void> pumpFrames(WidgetTester tester, Duration total) async {
    final end = DateTime.now().add(total);
    while (DateTime.now().isBefore(end)) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> waitFor(
    WidgetTester tester,
    Finder finder, {
    Duration timeout = const Duration(seconds: 20),
  }) async {
    final end = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(end)) {
      await tester.pump(const Duration(milliseconds: 200));
      if (finder.evaluate().isNotEmpty) return;
    }
    throw TestFailure('Timed out waiting for $finder');
  }

  Future<void> markShot(WidgetTester tester, String tag) async {
    await pumpFrames(tester, const Duration(milliseconds: 1200));
    File(shotMarker).writeAsStringSync('${prefix}_$tag\n');
    await pumpFrames(tester, const Duration(seconds: 3));
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
    await pumpFrames(tester, const Duration(seconds: 4));
    final startupEnd = DateTime.now().add(const Duration(seconds: 40));
    while (DateTime.now().isBefore(startupEnd) &&
        find.byKey(const Key('home-branch-name')).evaluate().isEmpty &&
        find.byKey(const Key('merchant-phone-continue')).evaluate().isEmpty &&
        find.byKey(const Key('merchant-language')).evaluate().isEmpty &&
        find.text(AppStrings.onboardingSkip).evaluate().isEmpty &&
        find.text(AppStrings.onboardingStart).evaluate().isEmpty) {
      await tester.pump(const Duration(milliseconds: 250));
    }
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
      await pumpFrames(tester, const Duration(milliseconds: 800));
      await tester.tap(find.byKey(const Key('merchant-otp-verify')));
      await pumpFrames(tester, const Duration(seconds: 8));
      if (find.byKey(const Key('merchant-otp-verify')).evaluate().isNotEmpty &&
          find.byKey(const Key('home-branch-name')).evaluate().isEmpty) {
        await tester.tap(find.byKey(const Key('merchant-otp-verify')));
        await pumpFrames(tester, const Duration(seconds: 8));
      }
      record('login', 'PASS', 'OTP login (dev OTP file)');
    } else {
      record('login', 'PASS', 'existing Dar El Bahja session');
    }
    await waitFor(tester, find.byKey(const Key('home-branch-name')));
    expect(find.textContaining('Dar El Bahja'), findsWidgets);
    expect(find.textContaining('Finjan'), findsNothing);
  }

  ProviderContainer containerOf(WidgetTester tester) =>
      ProviderScope.containerOf(tester.element(find.byType(MaterialApp).first));

  Finder listOf(String key) => find
      .descendant(of: find.byKey(Key(key)), matching: find.byType(Scrollable))
      .first;

  Future<SalesReportState> settledSales(WidgetTester tester) async {
    final c = containerOf(tester);
    final end = DateTime.now().add(const Duration(seconds: 20));
    while (DateTime.now().isBefore(end)) {
      await tester.pump(const Duration(milliseconds: 200));
      final v = c.read(salesReportControllerProvider);
      if (!v.isLoading && v.hasValue && v.value != null) return v.value!;
      if (v.hasError && !v.isLoading) {
        throw TestFailure('sales report error: ${v.error}');
      }
    }
    throw TestFailure('sales report did not settle');
  }

  Future<MerchantTopProducts> settledTop(WidgetTester tester) async {
    final c = containerOf(tester);
    final end = DateTime.now().add(const Duration(seconds: 20));
    while (DateTime.now().isBefore(end)) {
      await tester.pump(const Duration(milliseconds: 200));
      final v = c.read(topProductsControllerProvider);
      if (!v.isLoading && v.hasValue && v.value != null) return v.value!;
      if (v.hasError && !v.isLoading) {
        throw TestFailure('top products error: ${v.error}');
      }
    }
    throw TestFailure('top products did not settle');
  }

  bool titleFits(WidgetTester tester, String title) {
    final paragraph = tester.renderObject<RenderParagraph>(
      find.descendant(of: find.byType(AppBar), matching: find.text(title)),
    );
    return !paragraph.didExceedMaxLines;
  }

  Map<String, Object?> summaryJson(MerchantSalesSummary s) => {
    'period': s.period.period,
    'from': s.period.from,
    'to': s.period.to,
    'completedOrderCount': s.completedOrderCount,
    'grossMerchandiseMinor': s.grossMerchandiseMinor,
    'cancelledOrderCount': s.cancelledOrderCount,
    'financeGranted': s.financeGranted,
    'commissionMinor': s.finance?.commissionMinor,
    'merchantNetMinor': s.finance?.merchantNetMinor,
    'uniformCommissionRateBps': s.finance?.uniformCommissionRateBps,
    'buckets': s.buckets.length,
  };

  List<List<Object?>> topJson(MerchantTopProducts t) => [
    for (final i in t.items)
      [i.rank, i.name, i.orderCount, i.quantity, i.revenueMinor],
  ];

  void writeProvenance({Object? error}) {
    File('${outDir.path}/REPORTS_LIVE_PROVENANCE_$prefix.json')
        .writeAsStringSync(
          const JsonEncoder.withIndent('  ').convert({
            'layer': 'live_authenticated_ui',
            'fixture':
                'Dar El Bahja (+213$phoneLocal), controlled '
                'sgo_rptlive_* orders in speedygo_dev',
            'device': device,
            'backend': 'local dev backend http://127.0.0.1:3000',
            'result': error == null ? 'PASS' : 'FAIL',
            'error': error?.toString(),
            'observed': observed,
            'steps': steps,
          }),
        );
  }

  testWidgets('reports live smoke: overview → period → top → sort → back', (
    tester,
  ) async {
    try {
      await reachHome(tester);
      final view = tester.view;
      observed['logicalSize'] =
          '${(view.physicalSize.width / view.devicePixelRatio).round()}x'
          '${(view.physicalSize.height / view.devicePixelRatio).round()}';
      observed['textScale'] =
          MediaQuery.of(
            tester.element(find.byKey(const Key('home-branch-name'))),
          ).textScaler.scale(10) /
          10;
      record('environment', 'INFO', {
        'size': observed['logicalSize'],
        'textScale': observed['textScale'],
      });

      // 1. Overview, TODAY.
      await tester.tap(find.byKey(const Key('nav-reports')));
      await waitFor(tester, find.byKey(const Key('reports-screen')));
      final today = await settledSales(tester);
      observed['today'] = summaryJson(today.summary);
      observed['todayTop3'] = topJson(today.topProducts);
      expect(today.summary.period.period, 'TODAY');
      expect(today.summary.completedOrderCount, 4);
      expect(today.summary.grossMerchandiseMinor, '570000');
      expect(today.summary.finance!.commissionMinor, '39900');
      expect(today.summary.finance!.merchantNetMinor, '530100');
      expect(today.summary.finance!.uniformCommissionRateBps, 700);
      await waitFor(tester, find.byKey(const Key('reports-gross')));
      expect(find.text(MoneyFormat.dzdOrEmpty('570000')), findsOneWidget);
      expect(find.text('Commission SpeedyGo (7%)'), findsOneWidget);
      expect(find.text(MoneyFormat.dzdDeduction('39900')), findsOneWidget);
      expect(
        tester.widget<Text>(find.byKey(const Key('reports-net'))).data,
        MoneyFormat.dzdOrEmpty('530100'),
      );
      final overviewTitleFits = titleFits(tester, AppStrings.reportsTitle);
      observed['overviewTitleFits'] = overviewTitleFits;
      expect(overviewTitleFits, isTrue);
      expect(
        find.byKey(const Key('reports-refresh')).hitTestable(),
        findsOneWidget,
      );
      record('overview_today', 'PASS', observed['today']);
      await markShot(tester, '01_overview_today');

      await tester.tap(find.byKey(const Key('reports-refresh')));
      await settledSales(tester);
      record('overview_refresh', 'PASS', 'refresh tapped; report reloaded');

      await tester.scrollUntilVisible(
        find.byKey(const Key('reports-trend-chart')),
        250,
        scrollable: listOf('reports-screen'),
      );
      await markShot(tester, '02_overview_today_trend');
      await tester.scrollUntilVisible(
        find.byKey(const Key('reports-top-products-see-all')),
        250,
        scrollable: listOf('reports-screen'),
      );
      expect(find.text('Couscous royal'), findsOneWidget);
      await markShot(tester, '03_overview_today_top');
      await tester.scrollUntilVisible(
        find.byKey(const Key('reports-period-chips')),
        -400,
        scrollable: listOf('reports-screen'),
      );

      // 2. Period change → THIS_WEEK (mixed historical rates).
      await tester.tap(find.byKey(const Key('reports-period-THIS_WEEK')));
      await pumpFrames(tester, const Duration(milliseconds: 300));
      final week = await settledSales(tester);
      observed['week'] = summaryJson(week.summary);
      expect(week.summary.period.period, 'THIS_WEEK');
      expect(week.summary.completedOrderCount, 5);
      expect(week.summary.grossMerchandiseMinor, '655000');
      expect(week.summary.finance!.commissionMinor, '48400');
      expect(week.summary.finance!.merchantNetMinor, '606600');
      expect(week.summary.finance!.uniformCommissionRateBps, isNull);
      await pumpFrames(tester, const Duration(milliseconds: 500));
      expect(find.text(AppStrings.reportsCommissionMixedRates), findsOneWidget);
      expect(find.text(MoneyFormat.dzdDeduction('48400')), findsOneWidget);
      record('period_this_week', 'PASS', observed['week']);
      await markShot(tester, '04_overview_week');

      // 3. Top products (detail route).
      await tester.scrollUntilVisible(
        find.byKey(const Key('reports-top-products-see-all')),
        250,
        scrollable: listOf('reports-screen'),
      );
      await tester.tap(find.byKey(const Key('reports-top-products-see-all')));
      await waitFor(tester, find.byKey(const Key('top-products-screen')));
      final weekByOrders = await settledTop(tester);
      observed['weekByOrders'] = topJson(weekByOrders);
      expect(
        containerOf(tester).read(reportPeriodProvider).period,
        ReportPeriod.thisWeek,
      );
      expect(weekByOrders.sort, TopProductSort.orders);
      expect(weekByOrders.distinctProductCount, 6);
      expect(weekByOrders.items.first.name, 'Couscous royal');
      expect(weekByOrders.items.first.orderCount, 2);
      expect(weekByOrders.items.first.quantity, 3);
      expect(weekByOrders.items.first.revenueMinor, '360000');
      await pumpFrames(tester, const Duration(milliseconds: 500));
      expect(find.text('Total : 6 articles'), findsOneWidget);
      expect(
        find.byKey(const Key('top-products-back')).hitTestable(),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('top-products-refresh')).hitTestable(),
        findsOneWidget,
      );
      final topTitleFits = titleFits(
        tester,
        AppStrings.reportsTopProductsScreenTitle,
      );
      observed['topTitleFits'] = topTitleFits;
      expect(topTitleFits, isTrue);
      expect(
        find.byKey(const Key('reports-period-THIS_WEEK')).hitTestable(),
        findsOneWidget,
      );
      record('top_products_open', 'PASS', observed['weekByOrders']);
      await markShot(tester, '05_top_week_orders');

      // 4. Sort by revenue.
      await tester.tap(find.byKey(const Key('top-products-sort-revenue')));
      await pumpFrames(tester, const Duration(milliseconds: 300));
      final weekByRevenue = await settledTop(tester);
      observed['weekByRevenue'] = topJson(weekByRevenue);
      expect(weekByRevenue.sort, TopProductSort.revenue);
      expect(weekByRevenue.items.map((i) => i.name).toList(), [
        'Couscous royal',
        'Poulet rôti',
        'Couscous légumes',
        'Thé à la menthe',
        'Chorba frik',
        'Jus d’orange pressé',
      ]);
      expect(
        weekByRevenue.items.fold<BigInt>(
          BigInt.zero,
          (sum, i) => sum + BigInt.parse(i.revenueMinor),
        ),
        BigInt.parse(week.summary.grossMerchandiseMinor!),
      );
      record('sort_revenue', 'PASS', observed['weekByRevenue']);
      await markShot(tester, '06_top_week_revenue');

      // 5. Back to the overview; range kept.
      await tester.tap(find.byKey(const Key('top-products-back')));
      await pumpFrames(tester, const Duration(seconds: 1));
      await waitFor(tester, find.byKey(const Key('reports-screen')));
      expect(find.byKey(const Key('top-products-screen')), findsNothing);
      final c = containerOf(tester);
      expect(c.read(reportPeriodProvider).period, ReportPeriod.thisWeek);
      final afterBack = await settledSales(tester);
      expect(afterBack.summary.period.period, 'THIS_WEEK');
      expect(afterBack.summary.grossMerchandiseMinor, '655000');
      await tester.scrollUntilVisible(
        find.byKey(const Key('reports-period-chips')),
        -400,
        scrollable: listOf('reports-screen'),
      );
      record('back_to_overview', 'PASS', 'THIS_WEEK retained');
      await markShot(tester, '07_back_overview_week');

      // 6. Reopen: period and sort retained.
      await tester.scrollUntilVisible(
        find.byKey(const Key('reports-top-products-see-all')),
        250,
        scrollable: listOf('reports-screen'),
      );
      await tester.tap(find.byKey(const Key('reports-top-products-see-all')));
      await waitFor(tester, find.byKey(const Key('top-products-screen')));
      final reopened = await settledTop(tester);
      expect(
        containerOf(tester).read(reportPeriodProvider).period,
        ReportPeriod.thisWeek,
      );
      expect(reopened.distinctProductCount, 6);
      expect(reopened.sort, TopProductSort.revenue);
      expect(reopened.items.first.name, 'Couscous royal');
      record('reopen_top_products', 'PASS', 'THIS_WEEK + REVENUE retained');
      await markShot(tester, '08_reopen_top_revenue');

      await tester.tap(find.byKey(const Key('top-products-back')));
      await pumpFrames(tester, const Duration(seconds: 1));
      await tester.scrollUntilVisible(
        find.byKey(const Key('reports-period-chips')),
        -400,
        scrollable: listOf('reports-screen'),
      );
      await tester.tap(find.byKey(const Key('reports-period-TODAY')));
      await settledSales(tester);
      record('reset_period', 'PASS', 'TODAY');
      await markShot(tester, '99_done');
      writeProvenance();
    } catch (e) {
      writeProvenance(error: e);
      await markShot(tester, '99_done');
      rethrow;
    }
  });
}
