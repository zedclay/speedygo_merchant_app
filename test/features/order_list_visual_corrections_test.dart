import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speedygo_merchant_app/app/theme/app_theme.dart';
import 'package:speedygo_merchant_app/core/constants/app_strings.dart';
import 'package:speedygo_merchant_app/core/storage/session_store.dart';
import 'package:speedygo_merchant_app/features/access/application/access_controller.dart';
import 'package:speedygo_merchant_app/features/access/data/models.dart';
import 'package:speedygo_merchant_app/features/auth/application/session_providers.dart';
import 'package:speedygo_merchant_app/features/auth/data/models.dart';
import 'package:speedygo_merchant_app/features/orders/application/orders_controller.dart';
import 'package:speedygo_merchant_app/features/orders/data/order_models.dart';
import 'package:speedygo_merchant_app/features/orders/presentation/order_detail_screen.dart';
import 'package:speedygo_merchant_app/features/orders/presentation/orders_screen.dart';

import 'phase1_flow_test.dart';

/// Five-tab chrome without GoRouter (MerchantShell requires GoRouterState).
class _OrdersShellHarness extends StatelessWidget {
  const _OrdersShellHarness({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: 1,
        selectedFontSize: 11,
        unselectedFontSize: 10,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined, key: Key('nav-home')),
            label: AppStrings.tabHome,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long, key: Key('nav-orders')),
            label: AppStrings.tabOrders,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2_outlined, key: Key('nav-catalog')),
            label: AppStrings.tabCatalog,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_outlined, key: Key('nav-reports')),
            label: AppStrings.tabReports,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline, key: Key('nav-profile')),
            label: AppStrings.tabProfile,
          ),
        ],
      ),
    );
  }
}

MerchantOrderDetail _detail({
  required String id,
  required String status,
  required String fulfillment,
  required String publicReference,
  String? reason,
  MerchantDeliverySummary? delivery,
}) {
  return MerchantOrderDetail(
    id: id,
    publicReference: publicReference,
    status: status,
    fulfillmentStatus: fulfillment,
    merchantBranchId: 'b1',
    createdAt: '2026-09-18T15:23:00Z',
    confirmedAt: status == 'CREATED' ? null : '2026-09-18T15:24:00Z',
    customerFullName: 'Sara Belkacem',
    payment: const MerchantOrderPayment(method: 'COD', status: 'PENDING'),
    financial: const MerchantOrderFinancial(
      currency: 'DZD',
      grossMerchandiseSubtotalMinor: '1200',
      merchantDiscountMinor: '0',
      merchantCommissionRateBps: 700,
      merchantCommissionAmountMinor: '84',
      merchantNetAmountMinor: '1116',
      deliveryFeeMinor: '500',
    ),
    items: const [
      MerchantOrderItem(
        id: 'i1',
        productId: 'p1',
        productNameSnapshot: 'Couscous',
        quantity: 1,
        unitPriceMinor: '1200',
        lineTotalMinor: '1200',
        options: [],
      ),
    ],
    deliveryAddress: const MerchantOrderAddress(
      addressText: 'Hydra',
      latitude: 36.7,
      longitude: 3.0,
    ),
    statusHistory: const [],
    cancellation: reason == null
        ? null
        : MerchantOrderCancellation(
            reason: reason,
            cancelledAt: '2026-09-18T15:31:00Z',
          ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('En cours / Historique filter mapping is API-backed', () {
    expect(MerchantOrderListFilter.incoming.fulfillmentStatus,
        'PENDING_ACCEPTANCE');
    expect(MerchantOrderListFilter.accepted.fulfillmentStatus, 'ACCEPTED');
    expect(MerchantOrderListFilter.preparing.fulfillmentStatus, 'PREPARING');
    expect(MerchantOrderListFilter.ready.fulfillmentStatus, 'READY');
    expect(MerchantOrderListFilter.incoming.orderStatus, 'CREATED');
    expect(MerchantOrderListFilter.accepted.orderStatus, 'CONFIRMED');
    expect(MerchantOrderListFilter.preparing.orderStatus, 'ACTIVE');
    expect(MerchantOrderListFilter.ready.orderStatus, 'ACTIVE');
    expect(MerchantOrderListFilter.cancelled.orderStatus, 'CANCELLED');
    expect(MerchantOrderListFilter.completed.orderStatus, 'COMPLETED');
    expect(MerchantOrderListFilter.failed.orderStatus, 'FAILED');
    expect(MerchantOrderListFilter.cancelled.fulfillmentStatus, isNull);
    expect(MerchantOrderListFilter.incoming.isHistory, isFalse);
    expect(MerchantOrderListFilter.cancelled.isHistory, isTrue);
    expect(MerchantOrderListFilterX.activeFilters, hasLength(4));
    expect(MerchantOrderListFilterX.historyFilters, hasLength(3));
  });

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

  testWidgets('full reference accessible and copyable (server format)',
      (tester) async {
    const serverRef = 'sgo_01a0b51dbdbb74b594148ba9d15d7353';
    const longRef =
        'sgo_01a0b8f2c3d45e6f7890abcdef1234567890extraLongServerFormatValue';
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          final args = call.arguments as Map<dynamic, dynamic>?;
          copied = args?['text'] as String?;
          return null;
        }
        if (call.method == 'Clipboard.getData') {
          return <String, dynamic>{'text': copied};
        }
        return null;
      },
    );
    addTearDown(() {
      tester.binding.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null);
    });
    final detail = _detail(
      id: 'o1',
      status: 'CREATED',
      fulfillment: 'PENDING_ACCEPTANCE',
      publicReference: longRef,
    );
    final merchant = FakeMerchantApi(
      meHandler: () async => MerchantMe(
        merchantMembershipExists: true,
        memberships: [
          membership(branches: [branch('b1')]),
        ],
      ),
    )..mutableDetail = detail;
    final container = await ready(merchant);
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.light(locale: const Locale('fr')),
          home: const OrderDetailScreen(orderId: 'o1'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('order-detail-ref')), findsOneWidget);
    // Inline display is compact (head…tail); full value is in the sheet.
    final inline =
        tester.widget<Text>(find.byKey(const Key('order-detail-ref'))).data;
    expect(inline, startsWith('sgo_01a0b8'));
    expect(inline, contains('…'));
    expect(inline, isNot(longRef));

    await tester.tap(find.byKey(const Key('order-ref-open')).first);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('order-ref-full-text')), findsOneWidget);
    expect(find.text(longRef), findsWidgets);

    await tester.tap(find.byKey(const Key('order-ref-copy')));
    await tester.pumpAndSettle();
    expect(copied, longRef);
    expect(find.text(AppStrings.orderReferenceCopied), findsOneWidget);

    expect(find.byType(OrderDetailScreen), findsOneWidget);
    expect(serverRef.contains('-'), isFalse);
  });

  testWidgets('ready status appears once; no search without SEARCHING_DRIVER',
      (tester) async {
    final detail = _detail(
      id: 'o-ready',
      status: 'ACTIVE',
      fulfillment: 'READY',
      publicReference: 'sgo_ready_nopunctuation_abcdef',
    );
    final merchant = FakeMerchantApi(
      meHandler: () async => MerchantMe(
        merchantMembershipExists: true,
        memberships: [
          membership(branches: [branch('b1')]),
        ],
      ),
    )..mutableDetail = detail;
    final container = await ready(merchant);
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.light(locale: const Locale('fr')),
          home: const OrderDetailScreen(orderId: 'o-ready'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('order-ready-banner')), findsOneWidget);
    expect(find.text(AppStrings.orderReadyBanner), findsOneWidget);
    expect(find.byKey(const Key('order-ready-waiting')), findsOneWidget);
    expect(find.text(AppStrings.deliverySearching), findsNothing);
    expect(find.byKey(const Key('order-mark-ready')), findsNothing);
  });

  testWidgets('list segments map filters before pagination', (tester) async {
    final calls = <Map<String, String?>>[];
    final merchant = FakeMerchantApi(
      meHandler: () async => MerchantMe(
        merchantMembershipExists: true,
        memberships: [
          membership(branches: [branch('b1')]),
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
        // Tab-count probes (limit 1) are not list queries.
        if (limit == 1) {
          return MerchantOrderListPage(
            items: const [],
            limit: limit,
            offset: offset,
            total: 0,
          );
        }
        calls.add({
          'orderStatus': orderStatus,
          'fulfillmentStatus': fulfillmentStatus,
          'offset': '$offset',
        });
        return MerchantOrderListPage(
          items: const [],
          limit: limit,
          offset: offset,
          total: 0,
        );
      },
    );
    final container = await ready(merchant);
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.light(locale: const Locale('fr')),
          home: const _OrdersShellHarness(child: OrdersScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('nav-home')), findsOneWidget);
    expect(find.byKey(const Key('nav-orders')), findsOneWidget);
    expect(find.byKey(const Key('nav-catalog')), findsOneWidget);
    expect(find.byKey(const Key('nav-reports')), findsOneWidget);
    expect(find.byKey(const Key('nav-profile')), findsOneWidget);
    expect(find.byKey(const Key('orders-segment-active')), findsOneWidget);

    // Default En cours → Nouveaux
    expect(
      calls.last['fulfillmentStatus'],
      'PENDING_ACCEPTANCE',
    );
    expect(calls.last['orderStatus'], 'CREATED');

    await tester.tap(find.byKey(const Key('orders-filter-accepted')));
    await tester.pumpAndSettle();
    expect(calls.last['fulfillmentStatus'], 'ACCEPTED');
    expect(calls.last['orderStatus'], 'CONFIRMED');

    await tester.tap(find.byKey(const Key('orders-segment-history')));
    await tester.pumpAndSettle();
    expect(calls.last['orderStatus'], 'COMPLETED');
    expect(calls.last['fulfillmentStatus'], isNull);
    expect(find.byKey(const Key('orders-filter-cancelled')), findsOneWidget);
    expect(find.byKey(const Key('orders-filter-completed')), findsOneWidget);
    expect(find.byKey(const Key('orders-filter-failed')), findsOneWidget);
    // Active chips hidden in history.
    expect(find.byKey(const Key('orders-filter-incoming')), findsNothing);

    final list = container.read(ordersListControllerProvider).value;
    expect(list?.filter, MerchantOrderListFilter.completed);
  });

  testWidgets('filter retained after detail back', (tester) async {
    final order = _detail(
      id: 'keep-filter',
      status: 'CANCELLED',
      fulfillment: 'PENDING_ACCEPTANCE',
      publicReference: 'sgo_cancelled_plain_ref',
      reason: 'rupture',
    );
    final merchant = FakeMerchantApi(
      meHandler: () async => MerchantMe(
        merchantMembershipExists: true,
        memberships: [
          membership(branches: [branch('b1')]),
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
        return MerchantOrderListPage(
          items: orderStatus == 'CANCELLED' ? [order] : const [],
          limit: limit,
          offset: offset,
          total: orderStatus == 'CANCELLED' ? 1 : 0,
        );
      },
    )..mutableDetail = order;
    final container = await ready(merchant);
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.light(locale: const Locale('fr')),
          home: const OrdersScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('orders-segment-history')));
    await tester.pumpAndSettle();
    // Pick a non-default history chip so retention is observable.
    await tester.tap(find.byKey(const Key('orders-filter-cancelled')));
    await tester.pumpAndSettle();
    expect(
      container.read(ordersListControllerProvider).value?.filter,
      MerchantOrderListFilter.cancelled,
    );

    // Simulate leaving and returning without disposing the list provider.
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.light(locale: const Locale('fr')),
          home: const OrderDetailScreen(orderId: 'keep-filter'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.light(locale: const Locale('fr')),
          home: const OrdersScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      container.read(ordersListControllerProvider).value?.filter,
      MerchantOrderListFilter.cancelled,
    );
    expect(find.byKey(const Key('orders-filter-cancelled')), findsOneWidget);
  });
}
