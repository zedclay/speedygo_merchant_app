import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderParagraph;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:speedygo_merchant_app/app/theme/app_theme.dart';
import 'package:speedygo_merchant_app/core/constants/app_strings.dart';
import 'package:speedygo_merchant_app/core/money/money_format.dart';
import 'package:speedygo_merchant_app/core/navigation/app_routes.dart';
import 'package:speedygo_merchant_app/core/storage/session_store.dart';
import 'package:speedygo_merchant_app/features/access/application/access_controller.dart';
import 'package:speedygo_merchant_app/features/access/data/models.dart';
import 'package:speedygo_merchant_app/features/auth/application/auth_infrastructure.dart';
import 'package:speedygo_merchant_app/features/auth/application/session_controller.dart';
import 'package:speedygo_merchant_app/features/auth/application/session_providers.dart';
import 'package:speedygo_merchant_app/features/auth/application/session_state.dart';
import 'package:speedygo_merchant_app/features/reports/application/reports_controller.dart';
import 'package:speedygo_merchant_app/features/reports/application/sales_report_controller.dart';
import 'package:speedygo_merchant_app/features/reports/data/reports_models.dart';
import 'package:speedygo_merchant_app/features/reports/presentation/reports_screen.dart';
import 'package:speedygo_merchant_app/features/reports/presentation/top_products_screen.dart';

import 'phase1_flow_test.dart';
import 'sales_report_fixtures.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('money helpers', () {
    test('signed and deduction formatting use integer minor units', () {
      expect(MoneyFormat.dzdSigned('-250000'), '- 2 500 DZD');
      expect(MoneyFormat.dzdSigned('0'), '0 DZD');
      expect(MoneyFormat.dzdSigned('-0'), '0 DZD');
      expect(MoneyFormat.dzdSigned('1200'), '12 DZD');
      expect(MoneyFormat.dzdSigned('abc'), '');
      expect(MoneyFormat.dzdSigned(null), '');
      expect(MoneyFormat.dzdDeduction('296100'), '- 2 961 DZD');
      expect(MoneyFormat.dzdDeduction('0'), '0 DZD');
      expect(MoneyFormat.dzdDeduction(null), '');
    });

    test('basis points render without float math', () {
      expect(MoneyFormat.basisPointsPercent(700), '7%');
      expect(MoneyFormat.basisPointsPercent(750), '7,5%');
      expect(MoneyFormat.basisPointsPercent(725), '7,25%');
      expect(MoneyFormat.basisPointsPercent(5), '0,05%');
      expect(MoneyFormat.basisPointsPercent(1000), '10%');
    });
  });

  group('models', () {
    test('period query only sends from/to for CUSTOM', () {
      expect(ReportPeriodSelection.today.toQuery(), {'period': 'TODAY'});
      expect(
        const ReportPeriodSelection(
          ReportPeriod.thisWeek,
          from: '2031-03-01',
        ).toQuery(),
        {'period': 'THIS_WEEK'},
      );
      expect(
        const ReportPeriodSelection(
          ReportPeriod.custom,
          from: '2031-03-01',
          to: '2031-03-10',
        ).toQuery(),
        {'period': 'CUSTOM', 'from': '2031-03-01', 'to': '2031-03-10'},
      );
    });

    test('zero activity parses as zero; missing snapshot parses as null', () {
      final zero = MerchantSalesSummary.fromJson(zeroSummaryJson());
      expect(zero.dataComplete, isTrue);
      expect(zero.grossMerchandiseMinor, '0');
      expect(zero.averageBasketMinor, isNull);
      expect(zero.finance!.commissionMinor, '0');

      final missing = MerchantSalesSummary.fromJson(missingSnapshotJson());
      expect(missing.dataComplete, isFalse);
      expect(missing.grossMerchandiseMinor, isNull);
      expect(missing.finance!.commissionMinor, isNull);
      expect(missing.finance!.merchantNetMinor, isNull);
      expect(
        missing.buckets.every((b) => b.grossMerchandiseMinor == null),
        isTrue,
      );
    });

    test('trend buckets keep server order', () {
      final s = MerchantSalesSummary.fromJson(populatedSummaryJson());
      expect(s.hourly, isTrue);
      expect(s.buckets.first.localStart, '2031-03-15T00:00');
      expect(s.buckets.last.localStart, '2031-03-15T11:00');
    });
  });

  group('reports overview', () {
    testWidgets(
      'populated owner view shows snapshot finance, KPIs, trend and top 3',
      (tester) async {
        final calls = <ReportPeriodSelection>[];
        final branchIds = <String?>[];
        final merchant = FakeMerchantApi(
          salesSummaryHandler:
              ({required merchantId, required period, branchId}) async {
                calls.add(period);
                branchIds.add(branchId);
                return MerchantSalesSummary.fromJson(populatedSummaryJson());
              },
          topProductsHandler:
              ({
                required merchantId,
                required period,
                branchId,
                required sort,
                required limit,
              }) async {
                expect(limit, 3);
                return MerchantTopProducts.fromJson(populatedTopJson(limit: 3));
              },
        );
        await _pumpReports(tester, merchant);

        expect(find.text('42 300 DZD'), findsOneWidget);
        expect(find.text('Commission SpeedyGo (7%)'), findsOneWidget);
        expect(find.text('- 2 961 DZD'), findsOneWidget);
        expect(find.text('39 339 DZD'), findsOneWidget);
        expect(
          find.descendant(
            of: find.byKey(const Key('reports-metric-orders')),
            matching: find.text('18'),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: find.byKey(const Key('reports-metric-basket')),
            matching: find.text('2 350 DZD'),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: find.byKey(const Key('reports-metric-cancellations')),
            matching: find.text('2'),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: find.byKey(const Key('reports-metric-prep')),
            matching: find.text(AppStrings.reportsPrepTimeNotTracked),
          ),
          findsOneWidget,
        );
        // No fabricated growth percentage anywhere.
        expect(find.textContaining('+'), findsNothing);
        expect(find.textContaining('vs Hier'), findsNothing);
        expect(
          find.byKey(const Key('reports-finance-restricted')),
          findsNothing,
        );
        expect(find.byKey(const Key('reports-finance-missing')), findsNothing);
        expect(find.byKey(const Key('reports-refunds')), findsNothing);

        await tester.scrollUntilVisible(
          find.byKey(const Key('reports-top-product-3')),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        expect(find.byKey(const Key('reports-trend-chart')), findsOneWidget);
        expect(
          tester
              .widget<Text>(find.byKey(const Key('reports-trend-label-first')))
              .data,
          '00h',
        );
        expect(
          tester
              .widget<Text>(find.byKey(const Key('reports-trend-label-last')))
              .data,
          '11h',
        );
        expect(find.byKey(const Key('reports-trend-bar-11')), findsOneWidget);
        expect(find.text('Couscous Royal'), findsOneWidget);
        expect(find.text('8 commandes'), findsOneWidget);
        expect(find.text('24 000 DZD'), findsOneWidget);
        expect(find.text('Boisson Sélecto'), findsOneWidget);
        expect(
          find.byKey(const Key('reports-top-products-see-all')),
          findsOneWidget,
        );

        expect(calls, [ReportPeriodSelection.today]);
        expect(branchIds, ['b-1']);
      },
    );

    testWidgets('period chips reload for the selected period and branch', (
      tester,
    ) async {
      final calls = <ReportPeriodSelection>[];
      final merchant = FakeMerchantApi(
        salesSummaryHandler:
            ({required merchantId, required period, branchId}) async {
              calls.add(period);
              return MerchantSalesSummary.fromJson(
                populatedSummaryJson(period: period.period.apiValue),
              );
            },
      );
      await _pumpReports(tester, merchant);
      await tester.tap(find.byKey(const Key('reports-period-YESTERDAY')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('reports-period-THIS_MONTH')));
      await tester.pumpAndSettle();
      expect(calls.map((c) => c.period), [
        ReportPeriod.today,
        ReportPeriod.yesterday,
        ReportPeriod.thisMonth,
      ]);
      Color chipColor(String period) => tester
          .widget<Material>(
            find
                .ancestor(
                  of: find.byKey(Key('reports-period-$period')),
                  matching: find.byType(Material),
                )
                .first,
          )
          .color!;
      expect(chipColor('THIS_MONTH'), AppColors.primary);
      expect(chipColor('TODAY'), isNot(AppColors.primary));
      expect(chipColor('YESTERDAY'), isNot(AppColors.primary));
    });

    testWidgets('zero activity shows zeros, never "unavailable"', (
      tester,
    ) async {
      final merchant = FakeMerchantApi(
        salesSummaryHandler: ({
          required merchantId,
          required period,
          branchId,
        }) async => MerchantSalesSummary.fromJson(zeroSummaryJson()),
      );
      await _pumpReports(tester, merchant);

      expect(
        find.descendant(
          of: find.byKey(const Key('reports-gross')),
          matching: find.text('0 DZD'),
        ),
        findsOneWidget,
      );
      expect(
        tester.widget<Text>(find.byKey(const Key('reports-net'))).data,
        '0 DZD',
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('reports-metric-orders')),
          matching: find.text('0'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('reports-metric-basket')),
          matching: find.text(AppStrings.reportsDataUnavailableShort),
        ),
        findsOneWidget,
      );
      expect(find.byKey(const Key('reports-finance-missing')), findsNothing);
      await tester.scrollUntilVisible(
        find.byKey(const Key('reports-top-products-empty')),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.byKey(const Key('reports-trend-empty')), findsOneWidget);
      expect(find.byKey(const Key('reports-trend-chart')), findsNothing);
      expect(
        find.byKey(const Key('reports-top-products-see-all')),
        findsNothing,
      );
    });

    testWidgets('missing financial snapshot withholds money instead of zero', (
      tester,
    ) async {
      final merchant = FakeMerchantApi(
        salesSummaryHandler: ({
          required merchantId,
          required period,
          branchId,
        }) async => MerchantSalesSummary.fromJson(missingSnapshotJson()),
      );
      await _pumpReports(tester, merchant);

      expect(
        find.descendant(
          of: find.byKey(const Key('reports-gross')),
          matching: find.text(AppStrings.reportsDataUnavailableShort),
        ),
        findsOneWidget,
      );
      expect(
        tester.widget<Text>(find.byKey(const Key('reports-net'))).data,
        AppStrings.reportsDataUnavailableShort,
      );
      expect(find.text('0 DZD'), findsNothing);
      expect(find.byKey(const Key('reports-finance-missing')), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const Key('reports-metric-orders')),
          matching: find.text('3'),
        ),
        findsOneWidget,
      );
      await tester.scrollUntilVisible(
        find.byKey(const Key('reports-trend-unavailable')),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.byKey(const Key('reports-trend-chart')), findsNothing);
    });

    testWidgets('STAFF sees sales but not commission or net', (tester) async {
      final merchant = FakeMerchantApi(
        salesSummaryHandler:
            ({required merchantId, required period, branchId}) async =>
                MerchantSalesSummary.fromJson(
                  populatedSummaryJson(staff: true),
                ),
      );
      await _pumpReports(tester, merchant);

      expect(find.text('42 300 DZD'), findsOneWidget);
      expect(find.text(AppStrings.reportsCommission), findsOneWidget);
      expect(find.text('- 2 961 DZD'), findsNothing);
      expect(
        tester.widget<Text>(find.byKey(const Key('reports-net'))).data,
        AppStrings.reportsDataUnavailableShort,
      );
      expect(
        find.byKey(const Key('reports-finance-restricted')),
        findsOneWidget,
      );
    });

    testWidgets('refund adjustments are shown separately and signed', (
      tester,
    ) async {
      final merchant = FakeMerchantApi(
        salesSummaryHandler:
            ({required merchantId, required period, branchId}) async =>
                MerchantSalesSummary.fromJson(
                  populatedSummaryJson(
                    refundsCompleted: 2,
                    adjustments: '-250000',
                    discount: '50000',
                    rate: null,
                  ),
                ),
      );
      await _pumpReports(tester, merchant);

      expect(find.byKey(const Key('reports-refunds')), findsOneWidget);
      expect(find.text('- 2 500 DZD'), findsOneWidget);
      expect(find.text(AppStrings.reportsRefundsNote), findsOneWidget);
      // Sales stay the snapshot figure; refunds never reduce them.
      expect(find.text('42 300 DZD'), findsOneWidget);
      expect(
        find.byKey(const Key('reports-merchant-discount')),
        findsOneWidget,
      );
      expect(find.text('- 500 DZD'), findsOneWidget);
      // Mixed historical rates → no single percentage, explicit copy instead.
      expect(find.text(AppStrings.reportsCommissionMixedRates), findsOneWidget);
      expect(find.textContaining('%'), findsNothing);
    });

    testWidgets('commission label never claims a rate it does not have', (
      tester,
    ) async {
      MerchantSalesSummary? next;
      final merchant = FakeMerchantApi(
        salesSummaryHandler: ({
          required merchantId,
          required period,
          branchId,
        }) async => next!,
      );

      Future<String> labelFor(Map<String, dynamic> json) async {
        next = MerchantSalesSummary.fromJson(json);
        await tester.pumpWidget(const SizedBox());
        await _pumpReports(tester, merchant);
        final label = find.descendant(
          of: find.byKey(const Key('reports-commission')),
          matching: find.textContaining('Commission'),
        );
        return tester.widget<Text>(label).data!;
      }

      expect(
        await labelFor(populatedSummaryJson(rate: 750)),
        'Commission SpeedyGo (7,5%)',
      );
      expect(
        await labelFor(populatedSummaryJson(rate: null)),
        AppStrings.reportsCommissionMixedRates,
      );
      // No orders: there is no rate to describe.
      expect(await labelFor(zeroSummaryJson()), AppStrings.reportsCommission);
      // Missing snapshot: rate unknown, amounts withheld.
      expect(
        await labelFor(missingSnapshotJson()),
        AppStrings.reportsCommission,
      );
      // STAFF: finance withheld, so no rate either.
      expect(
        await labelFor(populatedSummaryJson(staff: true)),
        AppStrings.reportsCommission,
      );
    });

    testWidgets(
      'small screen at text 1.35: titles fit and refresh stays reachable',
      (tester) async {
        tester.view.physicalSize = const Size(375 * 3, 667 * 3);
        tester.view.devicePixelRatio = 3;
        tester.platformDispatcher.textScaleFactorTestValue = 1.35;
        addTearDown(tester.view.reset);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

        var summaryCalls = 0;
        var topCalls = 0;
        final merchant = FakeMerchantApi(
          salesSummaryHandler:
              ({required merchantId, required period, branchId}) async {
                summaryCalls++;
                return MerchantSalesSummary.fromJson(populatedSummaryJson());
              },
          topProductsHandler:
              ({
                required merchantId,
                required period,
                branchId,
                required sort,
                required limit,
              }) async {
                topCalls++;
                return MerchantTopProducts.fromJson(
                  populatedTopJson(limit: limit),
                );
              },
        );
        await _pumpRouter(tester, merchant);

        void expectTitleFits(String title) {
          final paragraph = tester.renderObject<RenderParagraph>(
            find.descendant(
              of: find.byType(AppBar),
              matching: find.text(title),
            ),
          );
          expect(paragraph.didExceedMaxLines, isFalse, reason: title);
        }

        void expectOnScreen(Finder finder) {
          expect(finder.hitTestable(), findsOneWidget);
          final rect = tester.getRect(finder);
          expect(rect.left >= 0 && rect.right <= 375, isTrue);
          expect(rect.width >= 40 && rect.height >= 40, isTrue);
        }

        expectTitleFits(AppStrings.reportsTitle);
        expectOnScreen(find.byKey(const Key('reports-refresh')));
        final beforeRefresh = summaryCalls;
        await tester.tap(find.byKey(const Key('reports-refresh')));
        await tester.pumpAndSettle();
        expect(summaryCalls, beforeRefresh + 1);

        await _openTopProducts(tester);
        expectTitleFits(AppStrings.reportsTopProductsScreenTitle);
        expectOnScreen(find.byKey(const Key('top-products-back')));
        expectOnScreen(find.byKey(const Key('top-products-refresh')));
        final beforeTopRefresh = topCalls;
        await tester.tap(find.byKey(const Key('top-products-refresh')));
        await tester.pumpAndSettle();
        expect(topCalls, beforeTopRefresh + 1);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'overview → top products → sort → back → reopen keeps period and sort',
      (tester) async {
        final summaryPeriods = <ReportPeriodSelection>[];
        final topRequests = <(ReportPeriodSelection, TopProductSort, int)>[];
        final merchant = FakeMerchantApi(
          salesSummaryHandler:
              ({required merchantId, required period, branchId}) async {
                summaryPeriods.add(period);
                return MerchantSalesSummary.fromJson(
                  populatedSummaryJson(period: period.period.apiValue),
                );
              },
          topProductsHandler:
              ({
                required merchantId,
                required period,
                branchId,
                required sort,
                required limit,
              }) async {
                topRequests.add((period, sort, limit));
                return MerchantTopProducts.fromJson(
                  populatedTopJson(limit: limit, sort: sort.apiValue),
                );
              },
        );
        await _pumpRouter(tester, merchant);
        final container = ProviderScope.containerOf(
          tester.element(find.byType(ReportsScreen)),
        );
        const custom = ReportPeriodSelection(
          ReportPeriod.custom,
          from: '2031-03-01',
          to: '2031-03-10',
        );
        container.read(reportPeriodProvider.notifier).select(custom);
        await tester.pumpAndSettle();
        expect(summaryPeriods.last, custom);

        await _openTopProducts(tester);
        expect(find.byKey(const Key('top-products-screen')), findsOneWidget);
        expect(topRequests.last, (custom, TopProductSort.orders, 20));
        // The custom range chip is selected and scrolled into view.
        expect(find.text('01/03 – 10/03'), findsOneWidget);
        expect(_chipColor(tester, 'CUSTOM'), AppColors.primary);
        expect(
          find.byKey(const Key('reports-period-CUSTOM')).hitTestable(),
          findsOneWidget,
        );

        await tester.tap(find.byKey(const Key('top-products-sort-revenue')));
        await tester.pumpAndSettle();
        expect(topRequests.last, (custom, TopProductSort.revenue, 20));

        await tester.tap(find.byKey(const Key('top-products-back')));
        await tester.pumpAndSettle();
        expect(find.byType(TopProductsScreen), findsNothing);
        expect(find.byKey(const Key('reports-screen')), findsOneWidget);
        expect(container.read(reportPeriodProvider), custom);
        expect(summaryPeriods.toSet(), {ReportPeriodSelection.today, custom});

        // Changing the period on the detail screen is shared with the overview.
        await _openTopProducts(tester);
        expect(topRequests.last, (custom, TopProductSort.revenue, 20));
        await tester.tap(find.byKey(const Key('reports-period-YESTERDAY')));
        await tester.pumpAndSettle();
        const yesterday = ReportPeriodSelection(ReportPeriod.yesterday);
        expect(topRequests.last, (yesterday, TopProductSort.revenue, 20));
        await tester.tap(find.byKey(const Key('top-products-back')));
        await tester.pumpAndSettle();
        expect(summaryPeriods.last, yesterday);
        expect(_chipColor(tester, 'YESTERDAY'), AppColors.primary);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('top products opened directly still offers a working back', (
      tester,
    ) async {
      final merchant = FakeMerchantApi(
        salesSummaryHandler: ({
          required merchantId,
          required period,
          branchId,
        }) async => MerchantSalesSummary.fromJson(populatedSummaryJson()),
      );
      await _pumpRouter(
        tester,
        merchant,
        initialLocation: AppRoutes.reportsTopProducts,
      );
      expect(find.byType(TopProductsScreen), findsOneWidget);
      expect(find.byKey(const Key('top-products-back')), findsOneWidget);
      await tester.tap(find.byKey(const Key('top-products-back')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('reports-screen')), findsOneWidget);
    });

    testWidgets('loading then error shows retry without automatic retries', (
      tester,
    ) async {
      var calls = 0;
      final gate = Completer<void>();
      final merchant = FakeMerchantApi(
        salesSummaryHandler:
            ({required merchantId, required period, branchId}) async {
              calls++;
              if (calls == 1) {
                await gate.future;
                throw Exception('network');
              }
              return MerchantSalesSummary.fromJson(populatedSummaryJson());
            },
      );
      await _pumpReports(tester, merchant, settle: false);
      expect(find.byKey(const Key('reports-sales-loading')), findsOneWidget);

      gate.complete();
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('reports-sales-retry')), findsOneWidget);
      expect(find.text(AppStrings.reportsSalesLoadError), findsOneWidget);

      await tester.pump(const Duration(seconds: 10));
      expect(calls, 1);

      await tester.tap(find.byKey(const Key('reports-sales-retry')));
      await tester.pumpAndSettle();
      expect(calls, 2);
      expect(find.text('42 300 DZD'), findsOneWidget);
    });

    testWidgets('"Voir tout" opens the full ranking', (tester) async {
      final merchant = FakeMerchantApi(
        salesSummaryHandler: ({
          required merchantId,
          required period,
          branchId,
        }) async => MerchantSalesSummary.fromJson(populatedSummaryJson()),
        topProductsHandler:
            ({
              required merchantId,
              required period,
              branchId,
              required sort,
              required limit,
            }) async =>
                MerchantTopProducts.fromJson(populatedTopJson(limit: limit)),
      );
      await _pumpRouter(tester, merchant);
      await _openTopProducts(tester);
      expect(find.byKey(const Key('top-products-screen')), findsOneWidget);
      expect(find.text('Total : 4 articles'), findsOneWidget);
      expect(find.byKey(const Key('top-products-back')), findsOneWidget);
    });
  });

  group('top products screen', () {
    testWidgets('ranks by orders, toggles to revenue, flags deleted products', (
      tester,
    ) async {
      final sorts = <TopProductSort>[];
      final merchant = FakeMerchantApi(
        topProductsHandler:
            ({
              required merchantId,
              required period,
              branchId,
              required sort,
              required limit,
            }) async {
              sorts.add(sort);
              expect(limit, 20);
              return MerchantTopProducts.fromJson(
                populatedTopJson(limit: limit, sort: sort.apiValue),
              );
            },
      );
      await _pumpTop(tester, merchant);

      expect(find.text('Total : 4 articles'), findsOneWidget);
      expect(find.byKey(const Key('top-product-1')), findsOneWidget);
      expect(find.text('8 commandes • 12 unités'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.byKey(const Key('top-products-synced')),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text(AppStrings.reportsDeletedProduct), findsOneWidget);
      expect(find.byKey(const Key('top-products-synced')), findsOneWidget);
      await tester.scrollUntilVisible(
        find.byKey(const Key('top-products-sort')),
        -200,
        scrollable: find.byType(Scrollable).first,
      );

      await tester.tap(find.byKey(const Key('top-products-sort-revenue')));
      await tester.pumpAndSettle();
      expect(sorts, [TopProductSort.orders, TopProductSort.revenue]);
    });

    testWidgets('empty period shows zero total and empty state', (
      tester,
    ) async {
      final merchant = FakeMerchantApi();
      await _pumpTop(tester, merchant);
      expect(find.text('Total : 0 articles'), findsOneWidget);
      expect(find.byKey(const Key('top-products-empty')), findsOneWidget);
    });

    testWidgets('error offers retry', (tester) async {
      var calls = 0;
      final merchant = FakeMerchantApi(
        topProductsHandler:
            ({
              required merchantId,
              required period,
              branchId,
              required sort,
              required limit,
            }) async {
              calls++;
              if (calls == 1) throw Exception('boom');
              return MerchantTopProducts.fromJson(
                populatedTopJson(limit: limit),
              );
            },
      );
      await _pumpTop(tester, merchant);
      expect(find.byKey(const Key('top-products-retry')), findsOneWidget);
      await tester.tap(find.byKey(const Key('top-products-retry')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('top-product-1')), findsOneWidget);
    });
  });

  group('top-product navigation by role', () {
    FakeMerchantApi api() => FakeMerchantApi(
          salesSummaryHandler: ({
            required merchantId,
            required period,
            branchId,
          }) async => MerchantSalesSummary.fromJson(populatedSummaryJson()),
          topProductsHandler: ({
            required merchantId,
            required period,
            branchId,
            required sort,
            required limit,
          }) async =>
              MerchantTopProducts.fromJson(populatedTopJson(limit: limit)),
        );

    Future<void> scrollToKey(WidgetTester tester, Key key) async {
      await tester.scrollUntilVisible(
        find.byKey(key),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
    }

    for (final role in const ['OWNER', 'MANAGER']) {
      testWidgets('$role opens the editor from the overview and the list', (
        tester,
      ) async {
        await _pumpRouter(tester, api(), role: role);
        await scrollToKey(tester, const Key('reports-top-product-1'));
        expect(
          find.byKey(const Key('reports-top-product-chevron-1')),
          findsOneWidget,
        );
        await tester.tap(find.byKey(const Key('reports-top-product-1')));
        await tester.pumpAndSettle();
        expect(find.text('editor:p-1'), findsOneWidget);

        await _pumpRouter(
          tester,
          api(),
          role: role,
          initialLocation: AppRoutes.reportsTopProducts,
        );
        await scrollToKey(tester, const Key('top-product-2'));
        expect(find.byKey(const Key('top-product-chevron-2')), findsOneWidget);
        await tester.tap(find.byKey(const Key('top-product-2')));
        await tester.pumpAndSettle();
        expect(find.text('editor:p-2'), findsOneWidget);
      });
    }

    testWidgets('STAFF gets no chevron and no navigation', (tester) async {
      await _pumpRouter(tester, api(), role: 'STAFF');
      await scrollToKey(tester, const Key('reports-top-product-1'));
      expect(
        find.byKey(const Key('reports-top-product-chevron-1')),
        findsNothing,
      );
      await tester.tap(find.byKey(const Key('reports-top-product-1')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('product-editor-stub')), findsNothing);
      expect(find.byKey(const Key('reports-screen')), findsOneWidget);

      await _pumpRouter(
        tester,
        api(),
        role: 'STAFF',
        initialLocation: AppRoutes.reportsTopProducts,
      );
      await scrollToKey(tester, const Key('top-product-1'));
      expect(find.byIcon(Icons.chevron_right), findsNothing);
      await tester.tap(find.byKey(const Key('top-product-1')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('product-editor-stub')), findsNothing);
      expect(find.byType(TopProductsScreen), findsOneWidget);
    });

    testWidgets('deleted product stays non-interactive for OWNER', (
      tester,
    ) async {
      await _pumpRouter(
        tester,
        api(),
        initialLocation: AppRoutes.reportsTopProducts,
      );
      await scrollToKey(tester, const Key('top-product-4'));
      expect(
        find.descendant(
          of: find.byKey(const Key('top-product-4')),
          matching: find.text(AppStrings.reportsDeletedProduct),
        ),
        findsOneWidget,
      );
      expect(find.byKey(const Key('top-product-chevron-4')), findsNothing);
      await tester.tap(find.byKey(const Key('top-product-4')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('product-editor-stub')), findsNothing);
    });
  });
}

const _branch = MerchantBranch(
  id: 'b-1',
  name: 'Finjan',
  phone: '0550000000',
  addressText: 'Centre',
  latitude: 36.7,
  longitude: 3.0,
  operationalStatus: 'ACTIVE',
);

List<Override> _overrides(FakeMerchantApi merchant, {String role = 'OWNER'}) {
  final mem = membership(
    role: role,
    branches: [_branch],
  ).copyWithName('Finjan');
  return [
    merchantApiProvider.overrideWithValue(merchant),
    sessionStoreProvider.overrideWithValue(MemorySessionStore()),
    contextStoreProvider.overrideWithValue(MemoryContextStore()),
    sessionControllerProvider.overrideWith(() => _ReadySession()),
    accessControllerProvider.overrideWith(() => _ReadyAccess(mem, _branch)),
    reportsControllerProvider.overrideWith(() => _SeedReports()),
  ];
}

Future<void> _pumpReports(
  WidgetTester tester,
  FakeMerchantApi merchant, {
  bool settle = true,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: _overrides(merchant),
      child: MaterialApp(theme: AppTheme.light(), home: const ReportsScreen()),
    ),
  );
  await tester.pump();
  if (settle) await tester.pumpAndSettle();
}

/// Mirrors the app router: Reports inside the shell navigator, top products
/// pushed on the root navigator.
Future<void> _pumpRouter(
  WidgetTester tester,
  FakeMerchantApi merchant, {
  String initialLocation = AppRoutes.reports,
  String role = 'OWNER',
}) async {
  final rootKey = GlobalKey<NavigatorState>();
  final router = GoRouter(
    navigatorKey: rootKey,
    initialLocation: initialLocation,
    routes: [
      ShellRoute(
        builder: (_, _, child) => child,
        routes: [
          GoRoute(
            path: AppRoutes.reports,
            builder: (_, _) => const ReportsScreen(),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.reportsTopProducts,
        parentNavigatorKey: rootKey,
        builder: (_, _) => const TopProductsScreen(),
      ),
      GoRoute(
        path: AppRoutes.catalogProductEdit(':id'),
        parentNavigatorKey: rootKey,
        builder: (_, state) => Scaffold(
          body: Text(
            'editor:${state.pathParameters['id']}',
            key: const Key('product-editor-stub'),
          ),
        ),
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: _overrides(merchant, role: role),
      child: MaterialApp.router(theme: AppTheme.light(), routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _openTopProducts(WidgetTester tester) async {
  await tester.scrollUntilVisible(
    find.byKey(const Key('reports-top-products-see-all')),
    200,
    scrollable: find
        .descendant(
          of: find.byKey(const Key('reports-screen')),
          matching: find.byType(Scrollable),
        )
        .first,
  );
  await tester.ensureVisible(
    find.byKey(const Key('reports-top-products-see-all')),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('reports-top-products-see-all')));
  await tester.pumpAndSettle();
}

Color _chipColor(WidgetTester tester, String period) => tester
    .widget<Material>(
      find
          .ancestor(
            of: find.byKey(Key('reports-period-$period')),
            matching: find.byType(Material),
          )
          .first,
    )
    .color!;

Future<void> _pumpTop(WidgetTester tester, FakeMerchantApi merchant) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: _overrides(merchant),
      child: MaterialApp(
        theme: AppTheme.light(),
        home: const TopProductsScreen(),
      ),
    ),
  );
  await tester.pump();
  await tester.pumpAndSettle();
}

class _ReadySession extends SessionController {
  @override
  SessionState build() =>
      const SessionState(phase: SessionPhase.ready, accountId: 'a-1');
}

class _ReadyAccess extends AccessController {
  _ReadyAccess(this.mem, this.branch);
  final MerchantMembership mem;
  final MerchantBranch branch;

  @override
  AccessState build() => AccessState(
    destination: AccessDestination.home,
    membership: mem,
    selectedBranch: branch,
  );
}

class _SeedReports extends ReportsController {
  @override
  Future<ReportsState> build() async => const ReportsState(
    ratings: MerchantRatingSummary(merchantId: 'm-1', count: 0, average: null),
    settlements: [],
    settlementsForbidden: false,
  );
}
