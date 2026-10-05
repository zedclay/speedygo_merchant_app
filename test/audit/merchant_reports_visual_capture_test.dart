import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speedygo_merchant_app/app/theme/app_theme.dart';
import 'package:speedygo_merchant_app/core/constants/app_strings.dart';
import 'package:speedygo_merchant_app/core/storage/session_store.dart';
import 'package:speedygo_merchant_app/features/access/application/access_controller.dart';
import 'package:speedygo_merchant_app/features/access/data/models.dart';
import 'package:speedygo_merchant_app/features/auth/application/auth_infrastructure.dart';
import 'package:speedygo_merchant_app/features/auth/application/session_controller.dart';
import 'package:speedygo_merchant_app/features/auth/application/session_providers.dart';
import 'package:speedygo_merchant_app/features/auth/application/session_state.dart';
import 'package:speedygo_merchant_app/features/reports/application/reports_controller.dart';
import 'package:speedygo_merchant_app/features/reports/data/reports_models.dart';
import 'package:speedygo_merchant_app/features/reports/presentation/reports_screen.dart';
import 'package:speedygo_merchant_app/features/reports/presentation/top_products_screen.dart';

import '../features/phase1_flow_test.dart';
import '../features/sales_report_fixtures.dart';

/// Mocked (contract-shaped fixture) captures for Merchant sales reports.
const _out =
    '/Users/mac/Downloads/speedygo_project/apps/merchant_app/audit/phase-5-ui/reports';
const _root = Key('reports-capture-root');

Future<void> _capture(WidgetTester tester, String name) async {
  await tester.pump();
  final render = tester.renderObject(find.byKey(_root));
  if (render is! RenderRepaintBoundary) {
    throw StateError('capture root is not a RepaintBoundary');
  }
  await tester.runAsync(() async {
    final image = await render.toImage(pixelRatio: 2);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File('$_out/$name.png');
    file.parent.createSync(recursive: true);
    await file.writeAsBytes(bytes!.buffer.asUint8List());
  });
}

Widget _bottomNav(Widget child) {
  return Scaffold(
    backgroundColor: AppColors.background,
    body: child,
    bottomNavigationBar: BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      backgroundColor: AppColors.surface,
      elevation: 0,
      currentIndex: 3,
      selectedFontSize: 11,
      unselectedFontSize: 10,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.onSurfaceVariant,
      items: [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          label: AppStrings.tabHome,
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.receipt_long),
          label: AppStrings.tabOrders,
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.inventory_2_outlined),
          label: AppStrings.tabCatalog,
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.bar_chart_outlined),
          label: AppStrings.tabReports,
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          label: AppStrings.tabProfile,
        ),
      ],
    ),
  );
}

const _branch = MerchantBranch(
  id: 'b-1',
  name: 'Finjan Café',
  phone: '0550000000',
  addressText: 'Centre',
  latitude: 36.7,
  longitude: 3.0,
  operationalStatus: 'ACTIVE',
);

Future<void> _pump(
  WidgetTester tester, {
  required FakeMerchantApi merchant,
  required Size size,
  required Widget child,
  double textScale = 1,
  bool withNav = true,
}) async {
  tester.view.physicalSize = Size(size.width * 2, size.height * 2);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final mem = membership(branches: [_branch]).copyWithName('Finjan');
  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(
        size: size,
        textScaler: TextScaler.linear(textScale),
      ),
      child: ProviderScope(
        overrides: [
          merchantApiProvider.overrideWithValue(merchant),
          sessionStoreProvider.overrideWithValue(MemorySessionStore()),
          contextStoreProvider.overrideWithValue(MemoryContextStore()),
          sessionControllerProvider.overrideWith(() => _ReadySession()),
          accessControllerProvider.overrideWith(
            () => _ReadyAccess(mem, _branch),
          ),
          reportsControllerProvider.overrideWith(() => _SeedReports()),
        ],
        child: MaterialApp(
          theme: AppTheme.light(locale: const Locale('fr')),
          home: SizedBox(
            width: size.width,
            height: size.height,
            child: RepaintBoundary(
              key: _root,
              child: withNav ? _bottomNav(child) : child,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pumpAndSettle();
}

Future<void> _scrollTo(WidgetTester tester, Key key) async {
  await tester.scrollUntilVisible(
    find.byKey(key),
    150,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
}

FakeMerchantApi _populated({bool staff = false}) => FakeMerchantApi(
  salesSummaryHandler: ({
    required merchantId,
    required period,
    branchId,
  }) async => MerchantSalesSummary.fromJson(populatedSummaryJson(staff: staff)),
  topProductsHandler:
      ({
        required merchantId,
        required period,
        branchId,
        required sort,
        required limit,
      }) async => MerchantTopProducts.fromJson(
        populatedTopJson(limit: limit, sort: sort.apiValue),
      ),
);

FakeMerchantApi _empty() => FakeMerchantApi(
  salesSummaryHandler: ({
    required merchantId,
    required period,
    branchId,
  }) async => MerchantSalesSummary.fromJson(zeroSummaryJson()),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const sizes = [(Size(375, 667), 'se'), (Size(402, 874), 'pro')];
  const scales = [(1.0, ''), (1.35, '_text135')];

  group('merchant reports captures', () {
    for (final (size, device) in sizes) {
      for (final (scale, suffix) in scales) {
        testWidgets('overview populated $device$suffix', (tester) async {
          await _pump(
            tester,
            merchant: _populated(),
            size: size,
            textScale: scale,
            child: const ReportsScreen(),
          );
          expect(find.text('Commission SpeedyGo (7%)'), findsOneWidget);
          await _capture(tester, 'overview_populated_$device${suffix}_1_top');
          await _scrollTo(tester, const Key('reports-trend-section'));
          await _capture(tester, 'overview_populated_$device${suffix}_2_trend');
          await _scrollTo(tester, const Key('reports-top-product-3'));
          await _capture(
            tester,
            'overview_populated_$device${suffix}_3_top_products',
          );
        });

        testWidgets('overview empty $device$suffix', (tester) async {
          await _pump(
            tester,
            merchant: _empty(),
            size: size,
            textScale: scale,
            child: const ReportsScreen(),
          );
          await _capture(tester, 'overview_empty_$device${suffix}_1_top');
          await _scrollTo(tester, const Key('reports-top-products-empty'));
          await _capture(
            tester,
            'overview_empty_$device${suffix}_2_trend_products',
          );
        });

        testWidgets('top products populated $device$suffix', (tester) async {
          await _pump(
            tester,
            merchant: _populated(),
            size: size,
            textScale: scale,
            withNav: false,
            child: const TopProductsScreen(),
          );
          expect(find.text('Total : 4 articles'), findsOneWidget);
          await _capture(tester, 'top_products_populated_$device$suffix');
        });

        testWidgets('top products empty $device$suffix', (tester) async {
          await _pump(
            tester,
            merchant: _empty(),
            size: size,
            textScale: scale,
            withNav: false,
            child: const TopProductsScreen(),
          );
          expect(find.text('Total : 0 articles'), findsOneWidget);
          await _capture(tester, 'top_products_empty_$device$suffix');
        });
      }
    }

    testWidgets('overview missing snapshot se', (tester) async {
      await _pump(
        tester,
        merchant: FakeMerchantApi(
          salesSummaryHandler: ({
            required merchantId,
            required period,
            branchId,
          }) async => MerchantSalesSummary.fromJson(missingSnapshotJson()),
        ),
        size: const Size(375, 667),
        child: const ReportsScreen(),
      );
      await _capture(tester, 'overview_missing_snapshot_se_1_top');
      await _scrollTo(tester, const Key('reports-trend-unavailable'));
      await _capture(tester, 'overview_missing_snapshot_se_2_trend');
    });

    testWidgets('overview staff restricted se', (tester) async {
      await _pump(
        tester,
        merchant: _populated(staff: true),
        size: const Size(375, 667),
        child: const ReportsScreen(),
      );
      await _capture(tester, 'overview_staff_restricted_se');
    });

    testWidgets('overview error se', (tester) async {
      await _pump(
        tester,
        merchant: FakeMerchantApi(
          salesSummaryHandler: ({
            required merchantId,
            required period,
            branchId,
          }) async => throw Exception('network'),
        ),
        size: const Size(375, 667),
        child: const ReportsScreen(),
      );
      expect(find.byKey(const Key('reports-sales-retry')), findsOneWidget);
      await _capture(tester, 'overview_error_se');
    });
  });
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
