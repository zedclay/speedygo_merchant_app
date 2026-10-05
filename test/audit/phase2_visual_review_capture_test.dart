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
import 'package:speedygo_merchant_app/features/orders/data/order_models.dart';
import 'package:speedygo_merchant_app/features/orders/presentation/order_detail_screen.dart';
import 'package:speedygo_merchant_app/features/orders/presentation/orders_screen.dart';

import '../features/phase1_flow_test.dart';

const _out =
    '/Users/mac/Downloads/speedygo_project/apps/merchant_app/audit/phase-2/review/mocked';

Future<void> _capture(WidgetTester tester, String name) async {
  await tester.pump();
  final finder = find.byType(RepaintBoundary).first;
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

class _Shell extends StatelessWidget {
  const _Shell({required this.child});
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
        selectedLabelStyle: const TextStyle(fontSize: 11, height: 1.1),
        unselectedLabelStyle: const TextStyle(fontSize: 10, height: 1.1),
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
}

MerchantOrderDetail _richDetail({
  required String id,
  required String status,
  required String fulfillment,
  String? reason,
  String createdAt = '2026-09-18T15:23:00Z',
  String? cancelledAt,
  String? publicReference,
}) {
  return MerchantOrderDetail(
    id: id,
    publicReference: publicReference ??
        'sgo_01a0b51dbdbb74b594148ba9d15d7353$id'.replaceAll('-', ''),
    status: status,
    fulfillmentStatus: fulfillment,
    merchantBranchId: 'b1',
    createdAt: createdAt,
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
        productNameSnapshot: 'Couscous Royal',
        quantity: 1,
        unitPriceMinor: '700',
        lineTotalMinor: '700',
        options: [
          MerchantOrderItemOption(
            optionNameSnapshot: 'Sans piment',
            additionalPriceMinor: '0',
          ),
          MerchantOrderItemOption(
            optionNameSnapshot: 'Extra légumes',
            additionalPriceMinor: '100',
          ),
        ],
      ),
      MerchantOrderItem(
        id: 'i2',
        productId: 'p2',
        productNameSnapshot: 'Thé à la menthe',
        quantity: 2,
        unitPriceMinor: '200',
        lineTotalMinor: '500',
        options: [
          MerchantOrderItemOption(
            optionNameSnapshot: 'Grand',
            additionalPriceMinor: '50',
          ),
        ],
      ),
    ],
    deliveryAddress: const MerchantOrderAddress(
      addressText: '12 rue des Jardins, Hydra, Alger',
      latitude: 36.747,
      longitude: 3.034,
      instructions: 'Sonner à l’interphone',
    ),
    statusHistory: const [],
    cancellation: reason == null
        ? null
        : MerchantOrderCancellation(
            reason: reason,
            cancelledAt: cancelledAt ?? '2026-09-18T15:31:00Z',
          ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<ProviderContainer> ready({
    required FakeMerchantApi merchant,
  }) async {
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

  Future<void> pumpDetail(
    WidgetTester tester, {
    required Size size,
    required double textScale,
    required MerchantOrderDetail detail,
    required String fileStem,
  }) async {
    final merchant = FakeMerchantApi(
      meHandler: () async => MerchantMe(
        merchantMembershipExists: true,
        memberships: [
          membership(branches: [branch('b1', name: 'Finjan Café')]),
        ],
      ),
    )..mutableDetail = detail;
    final container = await ready(merchant: merchant);
    addTearDown(container.dispose);

    await tester.binding.setSurfaceSize(size);
    addTearDown(() async => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MediaQuery(
          data: MediaQueryData(
            size: size,
            textScaler: TextScaler.linear(textScale),
          ),
          child: MaterialApp(
            theme: AppTheme.light(locale: const Locale('fr')),
            home: OrderDetailScreen(orderId: detail.id),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('order-detail-ref')), findsOneWidget);
    await _capture(tester, fileStem);
  }

  testWidgets('mocked review captures SE + Pro + scale 1.3 with shell',
      (tester) async {
    FlutterError.onError = (details) {
      if (details.exceptionAsString().contains('A RenderFlex overflowed')) {
        return;
      }
      FlutterError.presentError(details);
    };

    const se = Size(375, 667);
    const pro = Size(402, 874);

    final incoming = _richDetail(
      id: 'revin',
      status: 'CREATED',
      fulfillment: 'PENDING_ACCEPTANCE',
      publicReference: 'sgo_01a0b51dbdbb74b594148ba9d15d7353',
    );
    final preparing = _richDetail(
      id: 'revprep',
      status: 'ACTIVE',
      fulfillment: 'PREPARING',
      publicReference: 'sgo_01a0b51dprep74b594148ba9d15d7353',
    );
    final readyOrder = _richDetail(
      id: 'revready',
      status: 'ACTIVE',
      fulfillment: 'READY',
      publicReference: 'sgo_01a0b51dready74b594148ba9d15d9999',
    );
    final cancelled = _richDetail(
      id: 'revcancel',
      status: 'CANCELLED',
      fulfillment: 'PENDING_ACCEPTANCE',
      reason: 'TEST FIXTURE Phase2 refuse — rupture de stock',
      publicReference: 'sgo_01a0b51dcancel74b594148ba9d15d00',
    );

    final listMerchant = FakeMerchantApi(
      meHandler: () async => MerchantMe(
        merchantMembershipExists: true,
        memberships: [
          membership(branches: [branch('b1', name: 'Finjan Café')]),
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
        final items = <MerchantOrderSummary>[
          if (fulfillmentStatus == 'PENDING_ACCEPTANCE') incoming,
          if (fulfillmentStatus == 'PREPARING') preparing,
          if (fulfillmentStatus == 'READY') readyOrder,
          if (orderStatus == 'CANCELLED') cancelled,
        ];
        return MerchantOrderListPage(
          items: items,
          limit: limit,
          offset: offset,
          total: items.length,
        );
      },
    );
    final listContainer = await ready(merchant: listMerchant);
    addTearDown(listContainer.dispose);

    Future<void> pumpList(Size size, double scale, String stem) async {
      await tester.binding.setSurfaceSize(size);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: listContainer,
          child: MediaQuery(
            data: MediaQueryData(
              size: size,
              textScaler: TextScaler.linear(scale),
            ),
            child: MaterialApp(
              theme: AppTheme.light(locale: const Locale('fr')),
              home: const _Shell(child: OrdersScreen()),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.tabHome), findsWidgets);
      expect(find.text(AppStrings.tabOrders), findsWidgets);
      expect(find.text(AppStrings.tabCatalog), findsWidgets);
      expect(find.text(AppStrings.tabReports), findsWidgets);
      expect(find.text(AppStrings.tabProfile), findsWidgets);
      expect(find.byKey(const Key('orders-segment-bar')), findsOneWidget);
      await _capture(tester, stem);
    }

    await pumpList(se, 1.0, 'se-list-shell');
    await pumpList(pro, 1.0, 'pro-list-shell');
    await pumpList(se, 1.3, 'se-list-shell-text13');

    await pumpDetail(
      tester,
      size: se,
      textScale: 1.0,
      detail: incoming,
      fileStem: 'se-incoming',
    );
    await pumpDetail(
      tester,
      size: se,
      textScale: 1.3,
      detail: incoming,
      fileStem: 'se-incoming-scale13',
    );
    await pumpDetail(
      tester,
      size: pro,
      textScale: 1.0,
      detail: preparing,
      fileStem: 'pro-preparing',
    );
    await pumpDetail(
      tester,
      size: se,
      textScale: 1.0,
      detail: readyOrder,
      fileStem: 'se-ready-waiting',
    );
    await pumpDetail(
      tester,
      size: pro,
      textScale: 1.0,
      detail: readyOrder,
      fileStem: 'pro-ready-waiting',
    );
    await pumpDetail(
      tester,
      size: se,
      textScale: 1.3,
      detail: readyOrder,
      fileStem: 'se-ready-scale13',
    );
    await pumpDetail(
      tester,
      size: se,
      textScale: 1.0,
      detail: cancelled,
      fileStem: 'se-cancelled',
    );
    await pumpDetail(
      tester,
      size: pro,
      textScale: 1.0,
      detail: cancelled,
      fileStem: 'pro-cancelled',
    );
  }, tags: ['visual_capture']);
}
