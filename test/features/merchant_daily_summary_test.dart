import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:speedygo_merchant_app/app/theme/app_theme.dart';
import 'package:speedygo_merchant_app/core/constants/app_strings.dart';
import 'package:speedygo_merchant_app/core/errors/app_exception.dart';
import 'package:speedygo_merchant_app/core/navigation/app_routes.dart';
import 'package:speedygo_merchant_app/core/widgets/merchant_ui.dart';
import 'package:speedygo_merchant_app/features/access/application/access_controller.dart';
import 'package:speedygo_merchant_app/features/auth/application/auth_infrastructure.dart';
import 'package:speedygo_merchant_app/features/orders/data/order_models.dart';
import 'package:speedygo_merchant_app/features/orders/presentation/delivery_impact_card.dart';
import 'package:speedygo_merchant_app/features/reports/application/daily_summary_controller.dart';
import 'package:speedygo_merchant_app/features/reports/data/reports_models.dart';
import 'package:speedygo_merchant_app/features/reports/presentation/daily_summary_screen.dart';
import 'package:speedygo_merchant_app/features/auth/application/session_controller.dart';
import 'package:speedygo_merchant_app/features/auth/application/session_providers.dart';
import 'package:speedygo_merchant_app/features/auth/application/session_state.dart';
import 'package:speedygo_merchant_app/features/reports/application/reports_controller.dart';
import 'package:speedygo_merchant_app/features/reports/presentation/reports_screen.dart';
import 'package:speedygo_merchant_app/core/storage/session_store.dart';
import 'package:speedygo_merchant_app/features/access/data/models.dart';

import 'daily_summary_fixtures.dart';
import 'phase1_flow_test.dart';
import 'sales_report_fixtures.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('models', () {
    test('parses populated daily summary without coercing null money to zero', () {
      final summary = MerchantDailySummary.fromJson(
        populatedDailySummaryJson(missingMoney: true),
      );
      expect(summary.dataComplete, isFalse);
      expect(summary.grossMerchandiseMinor, isNull);
      expect(summary.averageActualPreparationMinutes, 23);
      expect(summary.onTimePreparationRateBps, 8333);
    });
  });

  group('daily summary screen', () {
    testWidgets('empty day shows empty state and orders CTA', (tester) async {
      final merchant = FakeMerchantApi(
        dailySummaryHandler:
            ({required merchantId, date, branchId}) async =>
                MerchantDailySummary.fromJson(emptyDailySummaryJson()),
      );
      await _pumpDailySummary(tester, merchant);

      expect(find.byKey(const Key('daily-summary-empty')), findsOneWidget);
      expect(find.text(AppStrings.reportsDailySummaryEmpty), findsOneWidget);
      expect(find.byKey(const Key('daily-summary-view-orders')), findsOneWidget);
    });

    testWidgets('populated view shows KPIs, breakdown and prep efficiency',
        (tester) async {
      final merchant = FakeMerchantApi(
        dailySummaryHandler:
            ({required merchantId, date, branchId}) async =>
                MerchantDailySummary.fromJson(populatedDailySummaryJson()),
      );
      await _pumpDailySummary(tester, merchant);

      expect(find.text('42 300 DZD'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const Key('daily-summary-kpi-orders')),
          matching: find.text('18'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('daily-summary-kpi-prep')),
          matching: find.text('23 min'),
        ),
        findsOneWidget,
      );
      expect(find.byKey(const Key('daily-summary-breakdown')), findsOneWidget);
      expect(find.textContaining('Livrées'), findsOneWidget);
      expect(find.textContaining('15'), findsWidgets);
      await tester.scrollUntilVisible(
        find.byKey(const Key('daily-summary-prep-efficiency')),
        200,
        scrollable: find
            .descendant(
              of: find.byKey(const Key('daily-summary-screen')),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      expect(find.byKey(const Key('daily-summary-prep-efficiency')), findsOneWidget);
      expect(find.text('83,33% à l’heure'), findsOneWidget);
      expect(
        find.byKey(const Key('daily-summary-cancel-reason-PRODUCT_UNAVAILABLE')),
        findsOneWidget,
      );
      expect(find.text('Indisponibilité produit'), findsOneWidget);
    });

    testWidgets('missing snapshot shows dash for sales not zero', (tester) async {
      final merchant = FakeMerchantApi(
        dailySummaryHandler:
            ({required merchantId, date, branchId}) async =>
                MerchantDailySummary.fromJson(
                  populatedDailySummaryJson(missingMoney: true),
                ),
      );
      await _pumpDailySummary(tester, merchant);

      expect(
        find.descendant(
          of: find.byKey(const Key('daily-summary-kpi-sales')),
          matching: find.text(AppStrings.reportsDataUnavailableShort),
        ),
        findsOneWidget,
      );
      expect(find.text('0 DZD'), findsNothing);
      await tester.scrollUntilVisible(
        find.byKey(const Key('daily-summary-missing-snapshot')),
        200,
        scrollable: find
            .descendant(
              of: find.byKey(const Key('daily-summary-screen')),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      expect(find.byKey(const Key('daily-summary-missing-snapshot')), findsOneWidget);
    });

    testWidgets('large text scale stacks KPI grid', (tester) async {
      final merchant = FakeMerchantApi(
        dailySummaryHandler:
            ({required merchantId, date, branchId}) async =>
                MerchantDailySummary.fromJson(populatedDailySummaryJson()),
      );
      await _pumpDailySummary(tester, merchant, textScale: 1.35);

      expect(find.byKey(const Key('daily-summary-kpi-sales')), findsOneWidget);
      expect(find.byKey(const Key('daily-summary-kpi-orders')), findsOneWidget);
    });

    testWidgets('reports shortcut navigates when TODAY is selected', (tester) async {
      final merchant = FakeMerchantApi(
        salesSummaryHandler:
            ({required merchantId, required period, branchId}) async =>
                MerchantSalesSummary.fromJson(populatedSummaryJson()),
        topProductsHandler:
            ({
              required merchantId,
              required period,
              branchId,
              required sort,
              required limit,
            }) async =>
                MerchantTopProducts.fromJson(populatedTopJson(limit: 3)),
        dailySummaryHandler:
            ({required merchantId, date, branchId}) async =>
                MerchantDailySummary.fromJson(populatedDailySummaryJson()),
      );
      await _pumpReportsRouter(tester, merchant);
      expect(find.byKey(const Key('reports-daily-summary-shortcut')), findsOneWidget);
      await tester.tap(find.byKey(const Key('reports-daily-summary-shortcut')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('daily-summary-screen')), findsOneWidget);
    });

    testWidgets('STAFF restricted finance shows dash not zero', (tester) async {
      final json = populatedDailySummaryJson();
      json['financeAccess'] = 'ROLE_RESTRICTED';
      json['grossMerchandiseMinor'] = null;
      json['averageBasketMinor'] = null;
      final merchant = FakeMerchantApi(
        dailySummaryHandler:
            ({required merchantId, date, branchId}) async =>
                MerchantDailySummary.fromJson(json),
      );
      await _pumpDailySummary(tester, merchant);
      expect(
        find.descendant(
          of: find.byKey(const Key('daily-summary-kpi-sales')),
          matching: find.text(AppStrings.reportsDataUnavailableShort),
        ),
        findsOneWidget,
      );
      expect(find.text('0 DZD'), findsNothing);
      expect(find.text('42 300 DZD'), findsNothing);
    });

    testWidgets('error state exposes retry', (tester) async {
      var calls = 0;
      final merchant = FakeMerchantApi(
        dailySummaryHandler: ({required merchantId, date, branchId}) async {
          calls += 1;
          if (calls == 1) {
            throw const ApiException('boom', statusCode: 500, code: 'INTERNAL');
          }
          return MerchantDailySummary.fromJson(populatedDailySummaryJson());
        },
      );
      await _pumpDailySummary(tester, merchant);
      expect(find.byKey(const Key('daily-summary-retry')), findsOneWidget);
      await tester.tap(find.byKey(const Key('daily-summary-retry')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('daily-summary-kpi-orders')), findsOneWidget);
      expect(calls, 2);
    });
  });

  group('daily summary geometry at 1.35', () {
    const phone = Size(375, 844);

    testWidgets('title and date never overlap; title keeps full width', (
      tester,
    ) async {
      final merchant = FakeMerchantApi(
        dailySummaryHandler:
            ({required merchantId, date, branchId}) async =>
                MerchantDailySummary.fromJson(populatedDailySummaryJson()),
      );
      await _pumpDailySummary(
        tester,
        merchant,
        textScale: 1.35,
        surface: phone,
      );

      final title = tester.getRect(find.byKey(const Key('daily-summary-title')));
      final date = tester.getRect(
        find.byKey(const Key('daily-summary-date-pill')),
      );
      final overlap = title.overlaps(date);
      expect(overlap, isFalse, reason: 'title=$title date=$date');
      // When stacked, title uses the content width (not a narrow side column).
      expect(title.width, greaterThan(phone.width * 0.7));
      // Not fragmented into a single-word column beside the chip.
      expect(title.width, greaterThan(date.width));
    });

    testWidgets('complete CTA label visible without ellipsis', (tester) async {
      final merchant = FakeMerchantApi(
        dailySummaryHandler:
            ({required merchantId, date, branchId}) async =>
                MerchantDailySummary.fromJson(populatedDailySummaryJson()),
      );
      await _pumpDailySummary(
        tester,
        merchant,
        textScale: 1.35,
        surface: phone,
      );

      final cta = find.byKey(const Key('daily-summary-view-orders'));
      expect(cta, findsOneWidget);
      expect(
        find.descendant(
          of: cta,
          matching: find.text(AppStrings.reportsDailySummaryViewOrders),
        ),
        findsOneWidget,
      );
      final label = tester.widget<Text>(
        find.descendant(
          of: cta,
          matching: find.text(AppStrings.reportsDailySummaryViewOrders),
        ),
      );
      expect(label.maxLines, 2);
      expect(label.overflow, isNot(TextOverflow.ellipsis));
      final ctaRect = tester.getRect(cta);
      expect(ctaRect.height, greaterThanOrEqualTo(56));
    });

    testWidgets('last content card fully reachable above sticky CTA', (
      tester,
    ) async {
      final merchant = FakeMerchantApi(
        dailySummaryHandler:
            ({required merchantId, date, branchId}) async =>
                MerchantDailySummary.fromJson(populatedDailySummaryJson()),
      );
      await _pumpDailySummary(
        tester,
        merchant,
        textScale: 1.35,
        surface: phone,
      );

      final scrollable = find.descendant(
        of: find.byKey(const Key('daily-summary-screen')),
        matching: find.byType(Scrollable),
      );
      final position = tester.state<ScrollableState>(scrollable).position;
      expect(position.maxScrollExtent, greaterThan(0));
      position.jumpTo(position.maxScrollExtent);
      await tester.pumpAndSettle();

      final last = tester.getRect(
        find.byKey(const Key('daily-summary-last-updated')),
      );
      final sticky = tester.getRect(find.byType(MerchantStickyBar));
      expect(
        last.bottom,
        lessThanOrEqualTo(sticky.top + 0.5),
        reason: 'last=$last sticky=$sticky',
      );
      expect(
        find.text(AppStrings.reportsDailySummaryViewOrders),
        findsOneWidget,
      );
    });
  });

  group('delivery impact card', () {
    testWidgets('shows French copy for each visible state', (tester) async {
      for (final state in [
        MerchantDeliveryImpactState.mayDelayDriverAssignment,
        MerchantDeliveryImpactState.mayDelayPickup,
        MerchantDeliveryImpactState.driverWaiting,
        MerchantDeliveryImpactState.deliveryTimingUnavailable,
      ]) {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light(),
            home: Scaffold(
              body: DeliveryImpactCard(
                deliveryImpact: MerchantDeliveryImpact(
                  state: state,
                  deliveryStatus: 'SEARCHING_DRIVER',
                ),
                latestRevisionReason: 'Forte affluence',
              ),
            ),
          ),
        );
        expect(
          find.byKey(Key('delivery-impact-${state.apiValue}')),
          findsOneWidget,
        );
        expect(find.textContaining('livraison'), findsWidgets);
        expect(find.textContaining('Forte affluence'), findsOneWidget);
        await tester.pumpWidget(const SizedBox.shrink());
      }
    });

    testWidgets('hides card for resolved and not applicable', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: const Scaffold(
            body: DeliveryImpactCard(
              deliveryImpact: MerchantDeliveryImpact(
                state: MerchantDeliveryImpactState.resolved,
              ),
            ),
          ),
        ),
      );
      expect(find.byKey(const Key('delivery-impact-RESOLVED')), findsNothing);
    });
  });
}

Future<void> _pumpDailySummary(
  WidgetTester tester,
  FakeMerchantApi merchant, {
  double textScale = 1.0,
  Size surface = const Size(390, 844),
}) async {
  tester.view.physicalSize = Size(surface.width * 2, surface.height * 2);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.binding.setSurfaceSize(surface);
  addTearDown(() => tester.binding.setSurfaceSize(null));

  final router = GoRouter(
    initialLocation: AppRoutes.reportsDailySummary,
    routes: [
      GoRoute(
        path: AppRoutes.reportsDailySummary,
        builder: (_, _) => const DailySummaryScreen(),
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: _overrides(merchant),
      child: MediaQuery(
        data: MediaQueryData(
          size: surface,
          textScaler: TextScaler.linear(textScale),
        ),
        child: MaterialApp.router(
          theme: AppTheme.light(),
          routerConfig: router,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
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

List<Override> _overrides(FakeMerchantApi merchant) {
  final mem = membership(role: 'OWNER', branches: [_branch]).copyWithName(
    'Finjan',
  );
  return [
    merchantApiProvider.overrideWithValue(merchant),
    sessionStoreProvider.overrideWithValue(MemorySessionStore()),
    contextStoreProvider.overrideWithValue(MemoryContextStore()),
    sessionControllerProvider.overrideWith(() => _ReadySession()),
    accessControllerProvider.overrideWith(() => _ReadyAccess(mem, _branch)),
    reportsControllerProvider.overrideWith(() => _SeedReports()),
    dailySummaryDateProvider.overrideWith(() => _FixedDate()),
  ];
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

class _FixedDate extends DailySummaryDateController {
  @override
  String build() => '2031-03-15';
}

Future<void> _pumpReportsRouter(
  WidgetTester tester,
  FakeMerchantApi merchant,
) async {
  final rootKey = GlobalKey<NavigatorState>();
  final router = GoRouter(
    navigatorKey: rootKey,
    initialLocation: AppRoutes.reports,
    routes: [
      GoRoute(
        path: AppRoutes.reports,
        builder: (_, _) => const ReportsScreen(),
      ),
      GoRoute(
        path: AppRoutes.reportsDailySummary,
        parentNavigatorKey: rootKey,
        builder: (_, _) => const DailySummaryScreen(),
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: _overrides(merchant),
      child: MaterialApp.router(theme: AppTheme.light(), routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
}
