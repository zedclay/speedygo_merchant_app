import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speedygo_merchant_app/core/storage/session_store.dart';
import 'package:speedygo_merchant_app/features/access/application/access_controller.dart';
import 'package:speedygo_merchant_app/features/access/data/models.dart';
import 'package:speedygo_merchant_app/features/auth/application/session_providers.dart';
import 'package:speedygo_merchant_app/features/auth/data/models.dart';
import 'package:speedygo_merchant_app/features/orders/data/order_models.dart';
import 'package:speedygo_merchant_app/features/orders/presentation/order_detail_screen.dart';

import '../features/phase1_flow_test.dart';

const _out =
    '/Users/mac/Downloads/speedygo_project/apps/merchant_app/audit/phase-2/captures';

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
    final image = await renderObject.toImage(pixelRatio: 1.5);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File('$_out/$name.png');
    file.parent.createSync(recursive: true);
    await file.writeAsBytes(bytes!.buffer.asUint8List());
  });
}

MerchantOrderDetail _detail({
  required String id,
  required String status,
  required String fulfillment,
  String? reason,
}) {
  return MerchantOrderDetail(
    id: id,
    publicReference: 'sgo_$id',
    status: status,
    fulfillmentStatus: fulfillment,
    merchantBranchId: 'b1',
    createdAt: '2026-09-18T12:00:00Z',
    confirmedAt: status == 'CREATED' ? null : '2026-09-18T12:01:00Z',
    customerFullName: 'Client Test',
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
        productNameSnapshot: 'TEST FIXTURE Phase2 Café',
        quantity: 1,
        unitPriceMinor: '1200',
        lineTotalMinor: '1200',
        options: [],
      ),
    ],
    deliveryAddress: const MerchantOrderAddress(
      addressText: 'Hydra TEST FIXTURE',
      latitude: 36.747,
      longitude: 3.034,
    ),
    statusHistory: const [],
    cancellation: reason == null
        ? null
        : MerchantOrderCancellation(
            reason: reason,
            cancelledAt: '2026-09-18T12:05:00Z',
          ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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
          items: [detail],
          limit: limit,
          offset: offset,
          total: 1,
        );
      },
    )..mutableDetail = detail;
    final store = MemorySessionStore()
      ..value = const TokenPair(
        accessToken: 'a',
        refreshToken: 'r',
        expiresIn: 900,
        tokenType: 'Bearer',
      );
    final container =
        testContainer(auth: FakeAuthApi(), merchant: merchant, store: store);
    addTearDown(container.dispose);
    container.read(tokenCacheProvider).current = store.value;
    await restoreAndResolve(container);
    await container
        .read(accessControllerProvider.notifier)
        .selectBranch(branch('b1'));

    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MediaQuery(
          data: MediaQueryData(size: size, textScaler: TextScaler.linear(textScale)),
          child: MaterialApp(
            home: OrderDetailScreen(orderId: detail.id),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('order-detail-ref')), findsOneWidget);
    await _capture(tester, fileStem);
  }

  testWidgets(
    'captures SE incoming / preparing / ready / rejected',
    (tester) async {
    const se = Size(375, 667);
    await pumpDetail(
      tester,
      size: se,
      textScale: 1.0,
      detail: _detail(
        id: 'cap-in',
        status: 'CREATED',
        fulfillment: 'PENDING_ACCEPTANCE',
      ),
      fileStem: 'se-incoming',
    );
    await pumpDetail(
      tester,
      size: se,
      textScale: 1.3,
      detail: _detail(
        id: 'cap-prep',
        status: 'ACTIVE',
        fulfillment: 'PREPARING',
      ),
      fileStem: 'se-preparing-scale13',
    );
    await pumpDetail(
      tester,
      size: se,
      textScale: 1.0,
      detail: _detail(
        id: 'cap-ready',
        status: 'ACTIVE',
        fulfillment: 'READY',
      ),
      fileStem: 'se-ready',
    );
    await pumpDetail(
      tester,
      size: se,
      textScale: 1.0,
      detail: _detail(
        id: 'cap-rej',
        status: 'CANCELLED',
        fulfillment: 'PENDING_ACCEPTANCE',
        reason: 'Rupture de stock',
      ),
      fileStem: 'se-rejected',
    );
  }, tags: ['visual_capture']);

  testWidgets(
    'captures Pro list + incoming '
    '(skipped: superseded by phase2_visual_review_capture_test; historical captures retained)',
    (tester) async {},
    skip: true,
    tags: ['visual_capture'],
  );

}
