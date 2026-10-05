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
import 'package:speedygo_merchant_app/features/auth/application/session_providers.dart';
import 'package:speedygo_merchant_app/features/auth/data/models.dart';
import 'package:speedygo_merchant_app/features/catalog/data/catalog_models.dart';
import 'package:speedygo_merchant_app/features/catalog/presentation/catalog_screen.dart';
import 'package:speedygo_merchant_app/features/orders/data/order_models.dart';
import 'package:speedygo_merchant_app/features/orders/presentation/orders_screen.dart';
import 'package:speedygo_merchant_app/features/reports/data/reports_models.dart';
import 'package:speedygo_merchant_app/features/reports/presentation/reports_screen.dart';
import 'package:speedygo_merchant_app/features/shell/home_dashboard_screen.dart';
import 'package:speedygo_merchant_app/features/shell/store_profile_screen.dart';
import 'package:speedygo_merchant_app/features/store/data/store_models.dart';

import '../features/phase1_flow_test.dart';

const _out =
    '/Users/mac/Downloads/speedygo_project/apps/merchant_app/audit/phase-5-ui/mocked';

const _captureRootKey = Key('capture-root');

Future<void> _capture(WidgetTester tester, String name) async {
  await tester.pump();
  final finder = find.byKey(_captureRootKey);
  if (finder.evaluate().isEmpty) {
    Directory(_out).createSync(recursive: true);
    File('$_out/$name.txt').writeAsStringSync('capture-skipped-no-root');
    return;
  }
  final renderObject = tester.renderObject(finder);
  if (renderObject is! RenderRepaintBoundary) {
    Directory(_out).createSync(recursive: true);
    File('$_out/$name.txt').writeAsStringSync('capture-skipped');
    return;
  }
  await tester.runAsync(() async {
    final image = await renderObject.toImage(pixelRatio: 2);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File('$_out/$name.png');
    file.parent.createSync(recursive: true);
    await file.writeAsBytes(bytes!.buffer.asUint8List());
  });
}

Widget _shell(int index, Widget child) {
  return ColoredBox(
    color: AppColors.background,
    child: Scaffold(
      backgroundColor: AppColors.background,
      body: child,
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border(
            top: BorderSide(
              color: AppColors.outlineVariant.withValues(alpha: 0.55),
            ),
          ),
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: AppColors.surface,
          elevation: 0,
          currentIndex: index,
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
      ),
    ),
  );
}

MerchantOrderSummary _summary({
  required String id,
  required String fulfillment,
  String status = 'ACTIVE',
  String? customer,
}) {
  return MerchantOrderSummary(
    id: id,
    publicReference: 'sgo_$id',
    status: status,
    fulfillmentStatus: fulfillment,
    merchantBranchId: 'b1',
    createdAt: '2026-09-19T10:00:00Z',
    confirmedAt: null,
    customerFullName: customer ?? 'Sara Belkacem',
    financial: const MerchantOrderFinancial(
      currency: 'DZD',
      grossMerchandiseSubtotalMinor: '150000',
      merchantDiscountMinor: '0',
      merchantCommissionRateBps: 700,
      merchantCommissionAmountMinor: '10500',
      merchantNetAmountMinor: '139500',
      deliveryFeeMinor: '20000',
    ),
    payment: const MerchantOrderPayment(method: 'COD', status: 'PENDING'),
  );
}

MerchantOrderListPage _page(List<MerchantOrderSummary> items) {
  return MerchantOrderListPage(
    items: items,
    total: items.length,
    limit: 50,
    offset: 0,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<ProviderContainer> ready(FakeMerchantApi merchant) async {
    final store = MemorySessionStore()
      ..value = const TokenPair(
        accessToken: 'a',
        refreshToken: 'r',
        expiresIn: 900,
        tokenType: 'Bearer',
      );
    final container =
        testContainer(auth: FakeAuthApi(), merchant: merchant, store: store);
    container.read(tokenCacheProvider).current = store.value;
    await restoreAndResolve(container);
    await container
        .read(accessControllerProvider.notifier)
        .selectBranch(branch('b1', name: 'Finjan Café'));
    return container;
  }

  Future<void> pumpTab(
    WidgetTester tester, {
    required ProviderContainer container,
    required Size size,
    required int index,
    required Widget child,
    double textScale = 1,
  }) async {
    tester.view.physicalSize = Size(size.width * 2, size.height * 2);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(
          size: size,
          padding: EdgeInsets.zero,
          viewPadding: EdgeInsets.zero,
          viewInsets: EdgeInsets.zero,
          textScaler: TextScaler.linear(textScale),
        ),
        child: UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.light(locale: const Locale('fr')),
            home: SizedBox(
              width: size.width,
              height: size.height,
              child: RepaintBoundary(
                key: _captureRootKey,
                child: _shell(index, child),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  FakeMerchantApi emptyOrdersMerchant({bool? openNow = true}) {
    return FakeMerchantApi(
      availabilityHandler: ({required merchantId, required branchId}) async {
        if (openNow == null) throw Exception('availability unavailable');
        return _availability(branchId, openNow: openNow);
      },
      meHandler: () async => MerchantMe(
        merchantMembershipExists: true,
        memberships: [
          membership(
            branches: [branch('b1', name: 'Finjan Café')],
            status: 'ACTIVE',
            approved: true,
            operationalReady: true,
          ).copyWithName('Finjan'),
        ],
      ),
      ordersHandler: ({
        required merchantId,
        branchId,
        orderStatus,
        fulfillmentStatus,
        limit = 50,
        offset = 0,
      }) async =>
          _page(const []),
    );
  }

  group('phase-3 five-tab captures', () {
    for (final size in [
      (const Size(375, 667), 'se'),
      (const Size(402, 874), 'pro'),
    ]) {
      testWidgets('home empty ${size.$2}', (tester) async {
        final merchant = emptyOrdersMerchant();
        final container = await ready(merchant);
        addTearDown(container.dispose);

        await pumpTab(
          tester,
          container: container,
          size: size.$1,
          index: 0,
          child: const HomeScreen(),
        );
        // `Ouvert` exists only inside the availability badge; the operational
        // pill is shown only when the Branch is not ACTIVE (parity D-A2).
        expect(find.text('Actif'), findsNothing);
        expect(find.textContaining('Ouvert'), findsOneWidget);
        expect(
          find.descendant(
            of: find.byKey(const Key('home-open-badge')),
            matching: find.text(AppStrings.availabilityOpen),
          ),
          findsOneWidget,
        );
        expect(find.text(AppStrings.homeActiveOrdersEmpty), findsOneWidget);
        await _capture(tester, 'home_empty_${size.$2}');
      });

      testWidgets('home populated ${size.$2}', (tester) async {
        final incoming = _summary(
          id: 'i1',
          fulfillment: 'PENDING_ACCEPTANCE',
          status: 'CREATED',
        );
        final preparing = _summary(
          id: 'p1',
          fulfillment: 'PREPARING',
          customer: 'Mohamed Rezki',
        );
        final merchant = FakeMerchantApi(
          meHandler: () async => MerchantMe(
            merchantMembershipExists: true,
            memberships: [
              membership(
                branches: [branch('b1', name: 'Finjan Café')],
                status: 'ACTIVE',
                approved: true,
                operationalReady: true,
              ).copyWithName('Finjan'),
            ],
          ),
          ordersHandler: ({
            required merchantId,
            branchId,
            orderStatus,
            fulfillmentStatus,
            limit = 50,
            offset = 0,
          }) async {
            if (orderStatus == 'CREATED' &&
                fulfillmentStatus == 'PENDING_ACCEPTANCE') {
              return _page([incoming]);
            }
            if (orderStatus == 'ACTIVE' && fulfillmentStatus == 'PREPARING') {
              return _page([preparing]);
            }
            if (orderStatus == 'ACTIVE' && fulfillmentStatus == 'READY') {
              return _page(const []);
            }
            return _page(const []);
          },
        );
        final container = await ready(merchant);
        addTearDown(container.dispose);

        await pumpTab(
          tester,
          container: container,
          size: size.$1,
          index: 0,
          child: const HomeScreen(),
        );
        expect(find.textContaining('Finjan'), findsWidgets);
        expect(find.byKey(const Key('home-order-card-i1')), findsOneWidget);
        await _capture(tester, 'home_populated_${size.$2}');
      });

      testWidgets('orders empty incoming ${size.$2}', (tester) async {
        final merchant = emptyOrdersMerchant();
        final container = await ready(merchant);
        addTearDown(container.dispose);

        await pumpTab(
          tester,
          container: container,
          size: size.$1,
          index: 1,
          child: const OrdersScreen(),
        );
        expect(find.text(AppStrings.ordersEmptyIncoming), findsOneWidget);
        await _capture(tester, 'orders_empty_incoming_${size.$2}');
      });

      testWidgets('catalog empty ${size.$2}', (tester) async {
        final merchant = emptyOrdersMerchant();
        final container = await ready(merchant);
        addTearDown(container.dispose);

        await pumpTab(
          tester,
          container: container,
          size: size.$1,
          index: 2,
          child: const CatalogScreen(),
        );
        expect(find.text(AppStrings.catalogEmptyProducts), findsOneWidget);
        await _capture(tester, 'catalog_empty_${size.$2}');
      });

      testWidgets('catalog populated ${size.$2}', (tester) async {
        final merchant = FakeMerchantApi(
          meHandler: () async => MerchantMe(
            merchantMembershipExists: true,
            memberships: [
              membership(
                branches: [branch('b1', name: 'Finjan Café')],
                status: 'ACTIVE',
                approved: true,
                operationalReady: true,
              ).copyWithName('Finjan'),
            ],
          ),
          catalogBootstrapHandler: ({
            required merchantId,
            required branchId,
          }) async =>
              CatalogBootstrap(
                branchId: branchId,
                stats: const CatalogStats(
                  categoryCount: 1,
                  productCount: 1,
                  availableProductCount: 1,
                ),
                categories: const [
                  CatalogCategory(
                    id: 'c1',
                    branchId: 'b1',
                    name: 'Plats',
                    sortOrder: 0,
                    active: true,
                  ),
                ],
              ),
          productsHandler: ({
            required merchantId,
            required branchId,
            categoryId,
          }) async =>
              const [
                CatalogProduct(
                  id: 'p1',
                  branchId: 'b1',
                  categoryId: 'c1',
                  name: 'Couscous Royal',
                  description: null,
                  priceMinor: '150000',
                  available: true,
                ),
              ],
        );
        final container = await ready(merchant);
        addTearDown(container.dispose);

        await pumpTab(
          tester,
          container: container,
          size: size.$1,
          index: 2,
          child: const CatalogScreen(),
        );
        expect(find.text('Couscous Royal'), findsOneWidget);
        await _capture(tester, 'catalog_populated_${size.$2}');
      });

      testWidgets('reports ${size.$2}', (tester) async {
        final merchant = FakeMerchantApi(
          meHandler: () async => MerchantMe(
            merchantMembershipExists: true,
            memberships: [
              membership(
                branches: [branch('b1', name: 'Finjan Café')],
                status: 'ACTIVE',
                approved: true,
                operationalReady: true,
              ).copyWithName('Finjan'),
            ],
          ),
          ratingsHandler: ({required merchantId}) async => MerchantRatingSummary(
            merchantId: merchantId,
            count: 0,
            average: null,
          ),
          settlementsHandler: ({required merchantId}) async => const [],
        );
        final container = await ready(merchant);
        addTearDown(container.dispose);

        await pumpTab(
          tester,
          container: container,
          size: size.$1,
          index: 3,
          child: const ReportsScreen(),
        );
        expect(find.byKey(const Key('reports-finance-section')), findsOneWidget);
        expect(find.text(AppStrings.reportsMerchantNet), findsOneWidget);
        await _capture(tester, 'reports_${size.$2}');
      });

      testWidgets('profile ${size.$2}', (tester) async {
        final merchant = emptyOrdersMerchant();
        final container = await ready(merchant);
        addTearDown(container.dispose);

        await pumpTab(
          tester,
          container: container,
          size: size.$1,
          index: 4,
          child: const StoreProfileScreen(),
        );
        expect(find.byKey(const Key('store-profile-screen')), findsOneWidget);
        expect(find.textContaining('Finjan'), findsWidgets);
        await _capture(tester, 'profile_${size.$2}');
      });
    }

    testWidgets('text scale 1.3 home empty', (tester) async {
      final merchant = emptyOrdersMerchant();
      final container = await ready(merchant);
      addTearDown(container.dispose);

      await pumpTab(
        tester,
        container: container,
        size: const Size(375, 667),
        index: 0,
        child: const HomeScreen(),
        textScale: 1.3,
      );
      await _capture(tester, 'home_empty_se_text1_3');
    });

    testWidgets('text scale 1.3 catalog empty', (tester) async {
      final merchant = emptyOrdersMerchant();
      final container = await ready(merchant);
      addTearDown(container.dispose);

      await pumpTab(
        tester,
        container: container,
        size: const Size(375, 667),
        index: 2,
        child: const CatalogScreen(),
        textScale: 1.3,
      );
      await _capture(tester, 'catalog_empty_se_text1_3');
    });

    testWidgets('text scale 1.3 profile', (tester) async {
      final merchant = emptyOrdersMerchant();
      final container = await ready(merchant);
      addTearDown(container.dispose);

      await pumpTab(
        tester,
        container: container,
        size: const Size(375, 667),
        index: 4,
        child: const StoreProfileScreen(),
        textScale: 1.3,
      );
      await _capture(tester, 'profile_se_text1_3');
    });

    testWidgets('home closed branch shows Fermé, never Ouvert', (tester) async {
      final merchant = emptyOrdersMerchant(openNow: false);
      final container = await ready(merchant);
      addTearDown(container.dispose);

      await pumpTab(
        tester,
        container: container,
        size: const Size(375, 667),
        index: 0,
        child: const HomeScreen(),
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('home-open-badge')),
          matching: find.text(AppStrings.availabilityClosed),
        ),
        findsOneWidget,
      );
      expect(find.textContaining('Ouvert'), findsNothing);
      expect(find.text('Actif'), findsNothing);
    });

    testWidgets('home without availability invents no open state',
        (tester) async {
      final merchant = emptyOrdersMerchant(openNow: null);
      final container = await ready(merchant);
      addTearDown(container.dispose);

      await pumpTab(
        tester,
        container: container,
        size: const Size(375, 667),
        index: 0,
        child: const HomeScreen(),
      );
      expect(find.byKey(const Key('home-open-badge')), findsNothing);
      expect(find.textContaining('Ouvert'), findsNothing);
      expect(find.text('Actif'), findsNothing);
      // Cancels Riverpod's automatic retry of the failed load before timer checks.
      container.dispose();
    });
  });
}

BranchAvailabilityState _availability(String branchId, {required bool openNow}) {
  return BranchAvailabilityState(
    branchId: branchId,
    timezone: 'Africa/Algiers',
    availabilityMode: 'FOLLOW_SCHEDULE',
    effectiveMode: 'FOLLOW_SCHEDULE',
    hoursConfigured: true,
    isOpenNow: openNow,
    acceptingOrders: openNow,
    temporaryExpired: false,
    outsideWeeklyHours: !openNow,
    reasonCode: null,
    customerMessage: null,
    closedUntil: null,
    nextOpenAt: null,
    currentClosesAt: null,
    version: null,
    updatedAt: null,
  );
}
