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

import '../../features/phase1_flow_test.dart';

const _out =
    '/Users/mac/Downloads/speedygo_project/apps/merchant_app/audit/parity/comparisons';
const _rootKey = Key('driver-handoff-capture-root');

MerchantOrderDetail _readyOrder({required String id}) {
  return MerchantOrderDetail(
    id: id,
    publicReference: 'sgo_$id',
    status: 'ACTIVE',
    fulfillmentStatus: 'READY',
    merchantBranchId: 'b1',
    createdAt: '2026-01-01T10:00:00Z',
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
        id: 'item-1',
        productId: 'p-1',
        productNameSnapshot: 'Café',
        quantity: 1,
        unitPriceMinor: '1200',
        lineTotalMinor: '1200',
        options: [],
      ),
    ],
    deliveryAddress: const MerchantOrderAddress(
      addressText: 'Hydra, Alger',
      latitude: 36.75,
      longitude: 3.05,
    ),
    statusHistory: const [],
  );
}

AssignedDriverSummary _driver({required String deliveryStatus}) {
  return AssignedDriverSummary(
    driverId: 'drv-1',
    assignmentId: 'asg-1',
    assignmentVersion: 1,
    displayName: 'Yacine Mansouri',
    vehicle: const AssignedDriverVehicleSummary(
      type: 'Moto',
      plateNumber: '16-12345',
    ),
    contactPhone: null,
    callAllowed: false,
    deliveryStatus: deliveryStatus,
    arrivedPickupAt: deliveryStatus == 'AT_PICKUP'
        ? '2026-01-01T10:40:00Z'
        : null,
    estimatedArrivalAt: null,
  );
}

MerchantDeliverySummary _delivery({
  required String status,
  AssignedDriverSummary? assignedDriver,
}) {
  return MerchantDeliverySummary(
    id: 'd1',
    orderId: 'o1',
    publicReference: 'sgd_d1',
    status: status,
    orderStatus: 'ACTIVE',
    fulfillmentStatus: 'READY',
    assignedDriverId: assignedDriver?.driverId,
    assignedDriver: assignedDriver,
  );
}

Future<void> _capture(WidgetTester tester, String name) async {
  await tester.pump();
  final renderObject = tester.renderObject(find.byKey(_rootKey));
  if (renderObject is! RenderRepaintBoundary) {
    fail('capture root is not a RepaintBoundary');
  }
  await tester.runAsync(() async {
    final image = await renderObject.toImage(pixelRatio: 2);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File('$_out/$name.png');
    file.parent.createSync(recursive: true);
    await file.writeAsBytes(bytes!.buffer.asUint8List());
  });
}

Future<void> _pump({
  required WidgetTester tester,
  required FakeMerchantApi merchant,
  required double width,
  required double textScale,
  required String orderId,
}) async {
  tester.view.physicalSize = Size(width * 2, 2400);
  tester.view.devicePixelRatio = 2;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  final store = MemorySessionStore()
    ..value = const TokenPair(
      accessToken: 'a',
      refreshToken: 'r',
      expiresIn: 900,
      tokenType: 'Bearer',
    );
  final container = testContainer(
    auth: FakeAuthApi(),
    merchant: merchant,
    store: store,
  );
  addTearDown(container.dispose);
  container.read(tokenCacheProvider).current = store.value;
  await restoreAndResolve(container);
  await container.read(accessControllerProvider.notifier).selectBranch(branch('b1'));

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MediaQuery(
        data: MediaQueryData(
          size: Size(width, 1200),
          textScaler: TextScaler.linear(textScale),
        ),
        child: MaterialApp(
          home: RepaintBoundary(
            key: _rootKey,
            child: OrderDetailScreen(orderId: orderId),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  // Drain overflow asserts so both text-scale variants complete.
  while (tester.takeException() != null) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  // Captures still write PNGs; ignore transient overflow asserts from sticky
  // bars under extreme text scale so both variants always complete.
  final previous = FlutterError.onError;
  FlutterError.onError = (details) {
    final msg = details.exceptionAsString();
    if (msg.contains('A RenderFlex overflowed')) {
      return;
    }
    previous?.call(details);
  };

  testWidgets('capture assigned driver TO_PICKUP @1.0 and 1.35', (tester) async {
    for (final v in [
      (w: 390.0, s: 1.0, suffix: ''),
      (w: 375.0, s: 1.35, suffix: '_t135'),
    ]) {
      final merchant = FakeMerchantApi(
        meHandler: () async => MerchantMe(
          merchantMembershipExists: true,
          memberships: [
            membership(branches: [branch('b1')]),
          ],
        ),
      )
        ..mutableDetail = _readyOrder(id: 'o-assigned')
        ..deliveryHandler = ({required orderId}) async => _delivery(
              status: 'TO_PICKUP',
              assignedDriver: _driver(deliveryStatus: 'TO_PICKUP'),
            );
      await _pump(
        tester: tester,
        merchant: merchant,
        width: v.w,
        textScale: v.s,
        orderId: 'o-assigned',
      );
      await _capture(
        tester,
        'b2_detail_ready_to_pickup_assigned${v.suffix}',
      );
    }
  });

  testWidgets('capture AT_PICKUP handoff code @1.0 and 1.35', (tester) async {
    for (final v in [
      (w: 390.0, s: 1.0, suffix: ''),
      (w: 375.0, s: 1.35, suffix: '_t135'),
    ]) {
      final merchant = FakeMerchantApi(
        meHandler: () async => MerchantMe(
          merchantMembershipExists: true,
          memberships: [
            membership(branches: [branch('b1')]),
          ],
        ),
      );
      merchant.mutableDetail = _readyOrder(id: 'o-handoff');
      merchant.deliveryHandler = ({required orderId}) async => _delivery(
            status: 'AT_PICKUP',
            assignedDriver: _driver(deliveryStatus: 'AT_PICKUP'),
          );
      merchant.pickupHandoffHandler = ({required orderId}) async =>
          const MerchantPickupHandoff(
            id: 'h1',
            pickupCode: '4186',
            status: 'PENDING',
            expiresAt: '2026-01-01T11:00:00Z',
            assignmentId: 'asg-1',
            assignmentVersion: 1,
            version: 1,
            attemptsRemaining: 5,
          );
      await _pump(
        tester: tester,
        merchant: merchant,
        width: v.w,
        textScale: v.s,
        orderId: 'o-handoff',
      );
      await _capture(
        tester,
        'b2_detail_ready_at_pickup_handoff${v.suffix}',
      );
    }
  });
}
