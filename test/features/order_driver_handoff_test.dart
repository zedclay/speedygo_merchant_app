import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speedygo_merchant_app/core/constants/app_strings.dart';
import 'package:speedygo_merchant_app/core/storage/session_store.dart';
import 'package:speedygo_merchant_app/features/access/application/access_controller.dart';
import 'package:speedygo_merchant_app/features/access/data/models.dart';
import 'package:speedygo_merchant_app/features/auth/application/session_providers.dart';
import 'package:speedygo_merchant_app/features/auth/data/models.dart';
import 'package:speedygo_merchant_app/features/orders/application/orders_controller.dart';
import 'package:speedygo_merchant_app/features/orders/data/order_models.dart';
import 'package:speedygo_merchant_app/features/orders/presentation/order_detail_screen.dart';

import 'phase1_flow_test.dart';

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
        options: const [],
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

AssignedDriverSummary _driver({
  bool callAllowed = false,
  String? contactPhone,
  String? estimatedArrivalAt,
  String deliveryStatus = 'TO_PICKUP',
}) {
  return AssignedDriverSummary(
    driverId: 'drv-1',
    assignmentId: 'asg-1',
    assignmentVersion: 1,
    displayName: 'Yacine Mansouri',
    vehicle: const AssignedDriverVehicleSummary(
      type: 'Moto',
      plateNumber: '16-12345',
    ),
    contactPhone: contactPhone,
    callAllowed: callAllowed,
    deliveryStatus: deliveryStatus,
    estimatedArrivalAt: estimatedArrivalAt,
  );
}

MerchantDeliverySummary _delivery({
  required String status,
  AssignedDriverSummary? assignedDriver,
}) {
  return MerchantDeliverySummary(
    id: 'd1',
    orderId: 'o-assigned',
    publicReference: 'sgd_d1',
    status: status,
    orderStatus: 'ACTIVE',
    fulfillmentStatus: 'READY',
    assignedDriverId: assignedDriver?.driverId,
    assignedDriver: assignedDriver,
  );
}

MerchantPickupHandoff _handoff({String status = 'PENDING'}) {
  return MerchantPickupHandoff(
    id: 'h1',
    pickupCode: '4186',
    status: status,
    expiresAt: '2026-01-01T11:00:00Z',
    assignmentId: 'asg-1',
    assignmentVersion: 1,
    version: 1,
    attemptsRemaining: 5,
  );
}

Future<ProviderContainer> _container(FakeMerchantApi merchant) async {
  final store = MemorySessionStore()
    ..value = const TokenPair(
      accessToken: 'a',
      refreshToken: 'r',
      expiresIn: 900,
      tokenType: 'Bearer',
    );
  final container = testContainer(auth: FakeAuthApi(), merchant: merchant, store: store);
  container.read(tokenCacheProvider).current = store.value;
  await restoreAndResolve(container);
  await container.read(accessControllerProvider.notifier).selectBranch(branch('b1'));
  return container;
}

Future<void> _pumpDetail(
  WidgetTester tester,
  ProviderContainer container,
  String orderId,
) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(home: OrderDetailScreen(orderId: orderId)),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('assigned driver and pickup handoff', () {
    testWidgets('assigned driver renders name and vehicle', (tester) async {
      final merchant = FakeMerchantApi(
        meHandler: () async => MerchantMe(
          merchantMembershipExists: true,
          memberships: [membership(branches: [branch('b1')])],
        ),
      )
        ..mutableDetail = _readyOrder(id: 'o-assigned')
        ..deliveryHandler = ({required orderId}) async => _delivery(
          status: 'TO_PICKUP',
          assignedDriver: _driver(),
        );
      final container = await _container(merchant);
      addTearDown(container.dispose);

      await _pumpDetail(tester, container, 'o-assigned');

      expect(find.byKey(const Key('order-assigned-driver')), findsOneWidget);
      expect(find.byKey(const Key('order-assigned-driver-name')), findsOneWidget);
      expect(find.text('Yacine Mansouri'), findsOneWidget);
      expect(find.byKey(const Key('order-assigned-driver-vehicle')), findsOneWidget);
      expect(find.text('Moto • 16-12345'), findsOneWidget);
    });

    testWidgets('missing ETA shows unavailable copy', (tester) async {
      final merchant = FakeMerchantApi(
        meHandler: () async => MerchantMe(
          merchantMembershipExists: true,
          memberships: [membership(branches: [branch('b1')])],
        ),
      )
        ..mutableDetail = _readyOrder(id: 'o-assigned')
        ..deliveryHandler = ({required orderId}) async => _delivery(
          status: 'TO_PICKUP',
          assignedDriver: _driver(),
        );
      final container = await _container(merchant);
      addTearDown(container.dispose);

      await _pumpDetail(tester, container, 'o-assigned');

      expect(
        find.byKey(const Key('order-assigned-driver-eta-unavailable')),
        findsOneWidget,
      );
      expect(find.text(AppStrings.orderDriverEtaUnavailable), findsOneWidget);
    });

    testWidgets('call disabled when callAllowed is false', (tester) async {
      final merchant = FakeMerchantApi(
        meHandler: () async => MerchantMe(
          merchantMembershipExists: true,
          memberships: [membership(branches: [branch('b1')])],
        ),
      )
        ..mutableDetail = _readyOrder(id: 'o-assigned')
        ..deliveryHandler = ({required orderId}) async => _delivery(
          status: 'TO_PICKUP',
          assignedDriver: _driver(callAllowed: false),
        );
      final container = await _container(merchant);
      addTearDown(container.dispose);

      await _pumpDetail(tester, container, 'o-assigned');

      expect(find.byKey(const Key('order-driver-call')), findsNothing);
      expect(find.byKey(const Key('order-driver-call-unavailable')), findsOneWidget);
      expect(find.text(AppStrings.orderDriverContactUnavailable), findsOneWidget);
      expect(find.byKey(const Key('order-ready-refresh')), findsOneWidget);
    });

    testWidgets('handoff available and consumed states', (tester) async {
      final merchant = FakeMerchantApi(
        meHandler: () async => MerchantMe(
          merchantMembershipExists: true,
          memberships: [membership(branches: [branch('b1')])],
        ),
      )
        ..mutableDetail = _readyOrder(id: 'o-at-pickup')
        ..deliveryHandler = ({required orderId}) async {
          return _delivery(
            status: 'AT_PICKUP',
            assignedDriver: _driver(deliveryStatus: 'AT_PICKUP'),
          );
        }
        ..pickupHandoffHandler = ({required orderId}) async => _handoff();

      final container = await _container(merchant);
      addTearDown(container.dispose);

      await _pumpDetail(tester, container, 'o-at-pickup');

      final loaded =
          container.read(orderDetailControllerProvider('o-at-pickup')).value!;
      expect(loaded.pickupHandoff?.pickupCode, '4186');
      expect(find.byKey(const Key('pickup-handoff-code')), findsOneWidget);
      expect(find.text('4 1 8 6'), findsOneWidget);
      expect(find.text(AppStrings.pickupHandoffWaiting), findsOneWidget);

      merchant.pickupHandoffHandler = ({required orderId}) async =>
          _handoff(status: 'CONSUMED');
      await container
          .read(orderDetailControllerProvider('o-at-pickup').notifier)
          .reloadPickupHandoff();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byKey(const Key('pickup-handoff-confirmed')), findsOneWidget);
      expect(find.text(AppStrings.pickupHandoffConfirmed), findsOneWidget);
      expect(find.byKey(const Key('pickup-handoff-code')), findsNothing);
    });

    testWidgets('handoff loading state during reload', (tester) async {
      final gate = Completer<void>();
      final merchant = FakeMerchantApi(
        meHandler: () async => MerchantMe(
          merchantMembershipExists: true,
          memberships: [membership(branches: [branch('b1')])],
        ),
      )
        ..mutableDetail = _readyOrder(id: 'o-at-pickup')
        ..deliveryHandler = ({required orderId}) async {
          return _delivery(
            status: 'AT_PICKUP',
            assignedDriver: _driver(deliveryStatus: 'AT_PICKUP'),
          );
        }
        ..pickupHandoffHandler = ({required orderId}) async => _handoff();

      final container = await _container(merchant);
      addTearDown(container.dispose);
      await _pumpDetail(tester, container, 'o-at-pickup');

      merchant.pickupHandoffHandler = ({required orderId}) async {
        await gate.future;
        return _handoff();
      };
      final reload = container
          .read(orderDetailControllerProvider('o-at-pickup').notifier)
          .reloadPickupHandoff();
      await tester.pump();
      expect(find.byKey(const Key('pickup-handoff-loading')), findsOneWidget);
      gate.complete();
      await reload;
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('handoff error shows retry without losing driver card', (
      tester,
    ) async {
      var fail = true;
      final merchant = FakeMerchantApi(
        meHandler: () async => MerchantMe(
          merchantMembershipExists: true,
          memberships: [membership(branches: [branch('b1')])],
        ),
      )
        ..mutableDetail = _readyOrder(id: 'o-at-pickup')
        ..deliveryHandler = ({required orderId}) async {
          return _delivery(
            status: 'AT_PICKUP',
            assignedDriver: _driver(deliveryStatus: 'AT_PICKUP'),
          );
        }
        ..pickupHandoffHandler = ({required orderId}) async {
          if (fail) {
            throw Exception('network');
          }
          return _handoff();
        };

      final container = await _container(merchant);
      addTearDown(container.dispose);

      await _pumpDetail(tester, container, 'o-at-pickup');

      final detailState =
          container.read(orderDetailControllerProvider('o-at-pickup')).value!;
      expect(detailState.delivery?.status, 'AT_PICKUP');
      expect(detailState.pickupHandoff, isNull);
      expect(detailState.pickupHandoffError, AppStrings.pickupHandoffLoadError);
      expect(find.byKey(const Key('order-assigned-driver')), findsOneWidget);
      expect(find.byKey(const Key('pickup-handoff-error')), findsOneWidget);
      expect(find.byKey(const Key('pickup-handoff-retry')), findsOneWidget);

      fail = false;
      await tester.tap(find.byKey(const Key('pickup-handoff-retry')));
      await tester.pump(const Duration(milliseconds: 80));
      await tester.pump();

      expect(find.byKey(const Key('pickup-handoff-code')), findsOneWidget);
      expect(find.byKey(const Key('pickup-handoff-error')), findsNothing);
      expect(find.byKey(const Key('order-assigned-driver')), findsOneWidget);
    });

    testWidgets('unassigned delivery hides driver identity card', (tester) async {
      final merchant = FakeMerchantApi(
        meHandler: () async => MerchantMe(
          merchantMembershipExists: true,
          memberships: [membership(branches: [branch('b1')])],
        ),
      )
        ..mutableDetail = _readyOrder(id: 'o-search')
        ..deliveryHandler = ({required orderId}) async =>
            _delivery(status: 'SEARCHING_DRIVER');
      final container = await _container(merchant);
      addTearDown(container.dispose);

      await _pumpDetail(tester, container, 'o-search');

      expect(find.byKey(const Key('order-assigned-driver')), findsNothing);
      expect(find.byKey(const Key('order-assigned-driver-name')), findsNothing);
      expect(find.byKey(const Key('pickup-handoff-section')), findsNothing);
    });
  });
}
