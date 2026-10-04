import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speedygo_merchant_app/core/constants/app_strings.dart';
import 'package:speedygo_merchant_app/features/access/data/models.dart';
import 'package:speedygo_merchant_app/features/reports/data/reports_models.dart';
import 'package:speedygo_merchant_app/features/reports/presentation/daily_summary_screen.dart';
import 'package:speedygo_merchant_app/features/reports/presentation/reports_screen.dart';
import 'package:speedygo_merchant_app/features/reports/presentation/top_products_screen.dart';

import '../../features/daily_summary_fixtures.dart';
import '../../features/phase1_flow_test.dart';
import '../../features/sales_report_fixtures.dart';
import 'parity_harness.dart';

FakeMerchantApi _reportsApi() => FakeMerchantApi(
      meHandler: () async => MerchantMe(
        merchantMembershipExists: true,
        memberships: [
          membership(branches: [branch('b1', name: 'Dar El Benna')]),
        ],
      ),
      salesSummaryHandler:
          ({required merchantId, required period, branchId}) async =>
              MerchantSalesSummary.fromJson(
                populatedSummaryJson(period: period.period.apiValue),
              ),
      topProductsHandler: ({
        required merchantId,
        required period,
        branchId,
        required sort,
        required limit,
      }) async =>
          MerchantTopProducts.fromJson(
            populatedTopJson(limit: limit, sort: sort.apiValue),
          ),
      dailySummaryHandler:
          ({required merchantId, date, branchId}) async =>
              MerchantDailySummary.fromJson(populatedDailySummaryJson()),
      ratingsHandler: ({required merchantId}) async =>
          MerchantRatingSummary(merchantId: merchantId, count: 37, average: 4.6),
      settlementsHandler: ({required merchantId}) async => [
        MerchantSettlementSummary(
          settlementId: 's-2',
          merchantId: merchantId,
          periodStart: '2031-03-01T00:00:00.000Z',
          periodEnd: '2031-03-08T00:00:00.000Z',
          status: 'FINALIZED',
          currency: 'DZD',
          grossSalesMinor: '1250000',
          commissionMinor: '87500',
          netPayableMinor: '1162500',
        ),
        MerchantSettlementSummary(
          settlementId: 's-3',
          merchantId: merchantId,
          periodStart: '2031-03-08T00:00:00.000Z',
          periodEnd: '2031-03-15T00:00:00.000Z',
          status: 'DRAFT',
          currency: 'DZD',
          grossSalesMinor: '980000',
          commissionMinor: '68600',
          netPayableMinor: '911400',
        ),
      ],
    );

void main() {
  group('batch 5 reports captures', () {
    for (final v in parityVariants) {
      testWidgets('overview ${v.suffix}', (tester) async {
        final container = await parityReady(_reportsApi());
        addTearDown(container.dispose);
        await parityPumpFull(
          tester,
          container: container,
          variant: v,
          tabIndex: 3,
          child: const ReportsScreen(),
        );
        await parityCapture(tester, 'b5_overview_${v.suffix}');
      });

      testWidgets('top products ${v.suffix}', (tester) async {
        final container = await parityReady(_reportsApi());
        addTearDown(container.dispose);
        await parityPumpFull(
          tester,
          container: container,
          variant: v,
          child: const TopProductsScreen(),
          pushed: true,
        );
        await parityCapture(tester, 'b5_top_products_${v.suffix}');
      });

      testWidgets('daily summary top ${v.suffix}', (tester) async {
        final container = await parityReady(_reportsApi());
        addTearDown(container.dispose);
        await parityPump(
          tester,
          container: container,
          variant: v,
          height: 844,
          child: const DailySummaryScreen(),
          pushed: true,
        );
        await parityCapture(tester, 'b5_daily_summary_${v.suffix}');
      });

      testWidgets('daily summary end ${v.suffix}', (tester) async {
        final container = await parityReady(_reportsApi());
        addTearDown(container.dispose);
        await parityPump(
          tester,
          container: container,
          variant: v,
          height: 844,
          child: const DailySummaryScreen(),
          pushed: true,
        );
        final scrollable = find.descendant(
          of: find.byKey(const Key('daily-summary-screen')),
          matching: find.byType(Scrollable),
        );
        final position = tester.state<ScrollableState>(scrollable).position;
        position.jumpTo(position.maxScrollExtent);
        await tester.pumpAndSettle();
        await parityCapture(tester, 'b5_daily_summary_end_${v.suffix}');
      });
    }
  });

  group('reports parity behaviour', () {
    testWidgets('KPI cards follow the reference order', (tester) async {
      final container = await parityReady(_reportsApi());
      addTearDown(container.dispose);
      await parityPumpFull(
        tester,
        container: container,
        variant: parityVariants.first,
        tabIndex: 3,
        child: const ReportsScreen(),
      );
      final keys = [
        'reports-metric-orders',
        'reports-metric-prep',
        'reports-metric-cancellations',
        'reports-metric-basket',
      ];
      final origins = [
        for (final k in keys) tester.getTopLeft(find.byKey(Key(k))),
      ];
      expect(origins[0].dy, origins[1].dy);
      expect(origins[0].dx, lessThan(origins[1].dx));
      expect(origins[2].dy, greaterThan(origins[0].dy));
      expect(origins[2].dy, origins[3].dy);
      expect(origins[2].dx, lessThan(origins[3].dx));
      expect(find.byKey(const Key('reports-notifications')), findsOneWidget);
      expect(find.byKey(const Key('reports-refresh')), findsOneWidget);
    });

    testWidgets('settlement statuses are shown in French, never raw enums', (
      tester,
    ) async {
      final container = await parityReady(_reportsApi());
      addTearDown(container.dispose);
      await parityPumpFull(
        tester,
        container: container,
        variant: parityVariants.first,
        tabIndex: 3,
        child: const ReportsScreen(),
      );
      expect(find.text('Finalisé'), findsOneWidget);
      expect(find.text('Brouillon'), findsOneWidget);
      expect(find.text('FINALIZED'), findsNothing);
      expect(find.text('DRAFT'), findsNothing);
      expect(AppStrings.reportsSettlementStatus('PAID'), 'Statut inconnu');
    });

    testWidgets('top products: ribbon on rank 1 only, sort toggle switches', (
      tester,
    ) async {
      final sorts = <TopProductSort>[];
      final api = _reportsApi();
      final base = api.topProductsHandler!;
      api.topProductsHandler = ({
        required merchantId,
        required period,
        branchId,
        required sort,
        required limit,
      }) {
        sorts.add(sort);
        return base(
          merchantId: merchantId,
          period: period,
          branchId: branchId,
          sort: sort,
          limit: limit,
        );
      };
      final container = await parityReady(api);
      addTearDown(container.dispose);
      await parityPumpFull(
        tester,
        container: container,
        variant: parityVariants.first,
        child: const TopProductsScreen(),
        pushed: true,
      );
      expect(find.byKey(const Key('top-product-ribbon')), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const Key('top-product-1')),
          matching: find.byKey(const Key('top-product-ribbon')),
        ),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const Key('top-products-sort-revenue')));
      await tester.pumpAndSettle();
      expect(sorts.last, TopProductSort.revenue);
      await tester.tap(find.byKey(const Key('top-products-sort-orders')));
      await tester.pumpAndSettle();
      expect(sorts.last, TopProductSort.orders);
    });
  });
}
