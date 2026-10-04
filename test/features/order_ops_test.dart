import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speedygo_merchant_app/core/constants/app_strings.dart';
import 'package:speedygo_merchant_app/core/money/money_format.dart';
import 'package:speedygo_merchant_app/core/storage/session_store.dart';
import 'package:speedygo_merchant_app/features/access/application/access_controller.dart';
import 'package:speedygo_merchant_app/features/access/data/models.dart';
import 'package:speedygo_merchant_app/features/auth/application/session_providers.dart';
import 'package:speedygo_merchant_app/features/auth/data/models.dart';
import 'package:speedygo_merchant_app/features/orders/application/orders_controller.dart';
import 'package:speedygo_merchant_app/features/orders/data/order_models.dart';
import 'package:speedygo_merchant_app/features/orders/presentation/order_detail_screen.dart';

import 'phase1_flow_test.dart';

MerchantOrderDetail _detail({
  required String id,
  required String branchId,
  required String status,
  required String fulfillment,
  String? reason,
}) {
  return MerchantOrderDetail(
    id: id,
    publicReference: 'sgo_$id',
    status: status,
    fulfillmentStatus: fulfillment,
    merchantBranchId: branchId,
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
        quantity: 2,
        unitPriceMinor: '600',
        lineTotalMinor: '1200',
        options: [
          MerchantOrderItemOption(
            optionNameSnapshot: 'Grand',
            additionalPriceMinor: '0',
          ),
        ],
      ),
    ],
    deliveryAddress: const MerchantOrderAddress(
      addressText: 'Hydra, Alger',
      latitude: 36.75,
      longitude: 3.05,
    ),
    statusHistory: const [],
    cancellation: reason == null
        ? null
        : MerchantOrderCancellation(
            reason: reason,
            cancelledAt: '2026-01-01T10:05:00Z',
          ),
  );
}

Future<ProviderContainer> _readyContainer(FakeMerchantApi merchant) async {
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
  await container
      .read(accessControllerProvider.notifier)
      .selectBranch(branch('b1'));
  return container;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('merchantActionsFor', () {
    test('maps CREATED+PENDING to accept/reject for OWNER', () {
      expect(
        merchantActionsFor(
          orderStatus: 'CREATED',
          fulfillmentStatus: 'PENDING_ACCEPTANCE',
          role: 'OWNER',
        ),
        [MerchantOrderAction.accept, MerchantOrderAction.reject],
      );
    });

    test('STAFF cannot mutate', () {
      expect(
        merchantActionsFor(
          orderStatus: 'CREATED',
          fulfillmentStatus: 'PENDING_ACCEPTANCE',
          role: 'STAFF',
        ),
        isEmpty,
      );
    });

    test('reject is not offered after acceptance', () {
      expect(
        merchantActionsFor(
          orderStatus: 'CONFIRMED',
          fulfillmentStatus: 'ACCEPTED',
          role: 'OWNER',
        ),
        [MerchantOrderAction.startPreparation],
      );
      expect(
        merchantActionsFor(
          orderStatus: 'ACTIVE',
          fulfillmentStatus: 'PREPARING',
          role: 'MANAGER',
        ),
        [MerchantOrderAction.markReady],
      );
      expect(
        merchantActionsFor(
          orderStatus: 'ACTIVE',
          fulfillmentStatus: 'READY',
          role: 'OWNER',
        ),
        isEmpty,
      );
      expect(
        merchantActionsFor(
          orderStatus: 'CANCELLED',
          fulfillmentStatus: 'PENDING_ACCEPTANCE',
          role: 'OWNER',
        ),
        isEmpty,
      );
    });
  });

  group('MoneyFormat', () {
    test('formats centimes without float', () {
      expect(MoneyFormat.dzd('1200'), '12 DZD');
      expect(MoneyFormat.dzd('220000'), '2 200 DZD');
      expect(MoneyFormat.dzd('0'), '0 DZD');
    });

    test('keeps centimes for fractional amounts', () {
      expect(MoneyFormat.dzd('220050'), '2 200,50 DZD');
      expect(MoneyFormat.dzd('220005'), '2 200,05 DZD');
      expect(MoneyFormat.dzd('1'), '0,01 DZD');
      expect(MoneyFormat.dzd('99'), '0,99 DZD');
      expect(
        MoneyFormat.dzd('100000000000000000001'),
        '1 000 000 000 000 000 000,01 DZD',
      );
      expect(MoneyFormat.dzdSigned('-250001'), '- 2 500,01 DZD');
      expect(MoneyFormat.dzdDeduction('296150'), '- 2 961,50 DZD');
      expect(MoneyFormat.dzdOrEmpty('5050'), '50,50 DZD');
    });
  });

  group('OrdersListController', () {
    test('home counts use list.total not page length', () async {
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
          final total = switch (fulfillmentStatus) {
            'PENDING_ACCEPTANCE' => 7,
            'PREPARING' => 2,
            'READY' => 1,
            _ => 0,
          };
          return MerchantOrderListPage(
            items: const [],
            limit: limit,
            offset: offset,
            total: total,
          );
        },
      );
      final container = await _readyContainer(merchant);
      addTearDown(container.dispose);

      final counts = await container.read(homeOrderCountsProvider.future);
      expect(counts.incoming, 7);
      expect(counts.preparing, 2);
      expect(counts.ready, 1);
    });
  });

  group('OrderDetailController mutations', () {
    test('accept with preparationMinutes persists estimate fields', () async {
      final detail = _detail(
        id: 'o-prep',
        branchId: 'b1',
        status: 'CREATED',
        fulfillment: 'PENDING_ACCEPTANCE',
      );
      final merchant = FakeMerchantApi(
        meHandler: () async => MerchantMe(
          merchantMembershipExists: true,
          memberships: [
            membership(branches: [branch('b1')]),
          ],
        ),
      )..mutableDetail = detail;
      final container = await _readyContainer(merchant);
      addTearDown(container.dispose);

      await container.read(orderDetailControllerProvider('o-prep').future);
      await container
          .read(orderDetailControllerProvider('o-prep').notifier)
          .accept(preparationMinutes: 25);
      final state =
          container.read(orderDetailControllerProvider('o-prep')).value!;
      expect(state.order.fulfillmentStatus, 'ACCEPTED');
      expect(state.order.preparationMinutes, 25);
      expect(state.order.originalPreparationMinutes, 25);
      expect(state.order.estimatedReadyAt, isNotNull);
      expect(state.order.originalEstimatedReadyAt, state.order.estimatedReadyAt);
      expect(state.order.preparationEstimateVersion, 1);
      expect(merchant.mutationCalls.last, 'accept:o-prep:25');
    });

    test('updatePreparationEstimate bumps version and readyAt', () async {
      final readyAt = DateTime.now()
          .toUtc()
          .add(const Duration(minutes: 20))
          .toIso8601String();
      final detail = MerchantOrderDetail(
        id: 'o-upd',
        publicReference: 'sgo_o-upd',
        status: 'CONFIRMED',
        fulfillmentStatus: 'ACCEPTED',
        merchantBranchId: 'b1',
        createdAt: '2026-01-01T10:00:00Z',
        confirmedAt: '2026-01-01T10:01:00Z',
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
        preparationMinutes: 25,
        originalPreparationMinutes: 25,
        estimatedReadyAt: readyAt,
        originalEstimatedReadyAt: readyAt,
        preparationEstimateVersion: 1,
        items: const [],
        deliveryAddress: const MerchantOrderAddress(
          addressText: 'Hydra, Alger',
          latitude: 36.75,
          longitude: 3.05,
        ),
        statusHistory: const [],
      );
      final merchant = FakeMerchantApi(
        meHandler: () async => MerchantMe(
          merchantMembershipExists: true,
          memberships: [
            membership(branches: [branch('b1')]),
          ],
        ),
      )..mutableDetail = detail;
      final container = await _readyContainer(merchant);
      addTearDown(container.dispose);

      await container.read(orderDetailControllerProvider('o-upd').future);
      await container
          .read(orderDetailControllerProvider('o-upd').notifier)
          .updatePreparationEstimate(addMinutes: 10, reason: 'affluence');
      final state =
          container.read(orderDetailControllerProvider('o-upd')).value!;
      expect(state.order.preparationMinutes, 25);
      expect(state.order.preparationEstimateVersion, 2);
      expect(state.order.originalEstimatedReadyAt, readyAt);
      expect(state.order.estimatedReadyAt, isNot(readyAt));
      expect(
        merchant.mutationCalls.last,
        'prep-estimate:o-upd:10:1',
      );
    });

    test('stale preparationEstimateVersion rejects without overwrite', () async {
      final readyAt = DateTime.now()
          .toUtc()
          .add(const Duration(minutes: 20))
          .toIso8601String();
      final detail = MerchantOrderDetail(
        id: 'o-stale',
        publicReference: 'sgo_o-stale',
        status: 'ACTIVE',
        fulfillmentStatus: 'PREPARING',
        merchantBranchId: 'b1',
        createdAt: '2026-01-01T10:00:00Z',
        confirmedAt: '2026-01-01T10:01:00Z',
        preparationMinutes: 25,
        originalPreparationMinutes: 25,
        estimatedReadyAt: readyAt,
        originalEstimatedReadyAt: readyAt,
        preparationEstimateVersion: 2,
        items: const [],
        deliveryAddress: const MerchantOrderAddress(
          addressText: 'Hydra',
          latitude: 36.75,
          longitude: 3.05,
        ),
        statusHistory: const [],
        payment: const MerchantOrderPayment(method: 'COD', status: 'PENDING'),
        financial: const MerchantOrderFinancial(
          currency: 'DZD',
          grossMerchandiseSubtotalMinor: '100',
          merchantDiscountMinor: '0',
          merchantCommissionRateBps: 700,
          merchantCommissionAmountMinor: '7',
          merchantNetAmountMinor: '93',
          deliveryFeeMinor: '0',
        ),
      );
      final merchant = FakeMerchantApi(
        meHandler: () async => MerchantMe(
          merchantMembershipExists: true,
          memberships: [
            membership(branches: [branch('b1')]),
          ],
        ),
      )..mutableDetail = detail;
      // Simulate concurrent bump before our call uses version from loaded state.
      merchant.mutableDetail = MerchantOrderDetail(
        id: detail.id,
        publicReference: detail.publicReference,
        status: detail.status,
        fulfillmentStatus: detail.fulfillmentStatus,
        merchantBranchId: detail.merchantBranchId,
        createdAt: detail.createdAt,
        confirmedAt: detail.confirmedAt,
        preparationMinutes: 35,
        originalPreparationMinutes: 25,
        estimatedReadyAt: DateTime.parse(readyAt)
            .add(const Duration(minutes: 10))
            .toUtc()
            .toIso8601String(),
        originalEstimatedReadyAt: readyAt,
        preparationEstimateVersion: 3,
        items: detail.items,
        deliveryAddress: detail.deliveryAddress,
        statusHistory: detail.statusHistory,
        payment: detail.payment,
        financial: detail.financial,
      );
      final container = await _readyContainer(merchant);
      addTearDown(container.dispose);

      // Load with version 3 already on server, but force controller to think v=2
      // by patching state after fetch — use accept path via custom: call update
      // while mutableDetail has higher version than state's version by reloading
      // then manually invoking API with stale expected via controller after
      // we set mutable back... Simpler: load first, then bump mutable, then update.
      await container.read(orderDetailControllerProvider('o-stale').future);
      // Reset controller state to stale version 2 while server is at 3.
      final loaded =
          container.read(orderDetailControllerProvider('o-stale')).value!;
      // Server already at 3 from mutableDetail; reload gave us 3.
      // Force conflict by calling API with expected 2 via Fake after setting version.
      expect(loaded.order.preparationEstimateVersion, 3);
      // Call update with controller which sends current.version (3) — instead
      // bump server to 4 after load then update with 3.
      merchant.mutableDetail = MerchantOrderDetail(
        id: detail.id,
        publicReference: detail.publicReference,
        status: detail.status,
        fulfillmentStatus: detail.fulfillmentStatus,
        merchantBranchId: detail.merchantBranchId,
        createdAt: detail.createdAt,
        confirmedAt: detail.confirmedAt,
        preparationMinutes: 45,
        originalPreparationMinutes: 25,
        estimatedReadyAt: DateTime.parse(readyAt)
            .add(const Duration(minutes: 20))
            .toUtc()
            .toIso8601String(),
        originalEstimatedReadyAt: readyAt,
        preparationEstimateVersion: 4,
        items: detail.items,
        deliveryAddress: detail.deliveryAddress,
        statusHistory: detail.statusHistory,
        payment: detail.payment,
        financial: detail.financial,
      );
      await container
          .read(orderDetailControllerProvider('o-stale').notifier)
          .updatePreparationEstimate(addMinutes: 5);
      final state =
          container.read(orderDetailControllerProvider('o-stale')).value!;
      expect(state.actionError, isNotNull);
      expect(state.order.preparationEstimateVersion, 4);
      expect(state.order.preparationMinutes, 45);
    });

    test('accept reconciles and blocks double in-flight', () async {
      final detail = _detail(
        id: 'o1',
        branchId: 'b1',
        status: 'CREATED',
        fulfillment: 'PENDING_ACCEPTANCE',
      );
      final merchant = FakeMerchantApi(
        meHandler: () async => MerchantMe(
          merchantMembershipExists: true,
          memberships: [
            membership(branches: [branch('b1')]),
          ],
        ),
      )..mutableDetail = detail;
      final container = await _readyContainer(merchant);
      addTearDown(container.dispose);

      await container.read(orderDetailControllerProvider('o1').future);
      final notifier =
          container.read(orderDetailControllerProvider('o1').notifier);
      await Future.wait([notifier.accept(), notifier.accept()]);
      expect(merchant.acceptCalls, 1);
      final state = container.read(orderDetailControllerProvider('o1')).value!;
      expect(state.order.fulfillmentStatus, 'ACCEPTED');
      expect(state.order.status, 'CONFIRMED');
    });

    test('network uncertainty re-reads before exposing retry', () async {
      final detail = _detail(
        id: 'o2',
        branchId: 'b1',
        status: 'CREATED',
        fulfillment: 'PENDING_ACCEPTANCE',
      );
      final merchant = FakeMerchantApi(
        meHandler: () async => MerchantMe(
          merchantMembershipExists: true,
          memberships: [
            membership(branches: [branch('b1')]),
          ],
        ),
      )
        ..mutableDetail = detail
        ..acceptThrowsNetwork = true;
      final container = await _readyContainer(merchant);
      addTearDown(container.dispose);

      await container.read(orderDetailControllerProvider('o2').future);
      await container.read(orderDetailControllerProvider('o2').notifier).accept();
      final state = container.read(orderDetailControllerProvider('o2')).value!;
      expect(state.order.fulfillmentStatus, 'PENDING_ACCEPTANCE');
      expect(state.actionError, isNotNull);
      expect(state.mutating, isFalse);
    });

    test('foreign branch detail is not exposed', () async {
      final merchant = FakeMerchantApi(
        meHandler: () async => MerchantMe(
          merchantMembershipExists: true,
          memberships: [
            membership(branches: [branch('b1')]),
          ],
        ),
        orderDetailHandler: ({required merchantId, required orderId}) async {
          return _detail(
            id: orderId,
            branchId: 'other-branch',
            status: 'CREATED',
            fulfillment: 'PENDING_ACCEPTANCE',
          );
        },
      );
      final container = await _readyContainer(merchant);
      addTearDown(container.dispose);

      final sub = container.listen(
        orderDetailControllerProvider('foreign'),
        (_, _) {},
        fireImmediately: true,
      );
      addTearDown(sub.close);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      for (var i = 0; i < 20; i++) {
        final async = container.read(orderDetailControllerProvider('foreign'));
        if (async.hasError) break;
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }
      final async = container.read(orderDetailControllerProvider('foreign'));
      expect(async.hasError, isTrue);
      expect(
        async.error.toString().contains('MERCHANT_ORDER_NOT_FOUND') ||
            async.error.toString().contains('Commande introuvable'),
        isTrue,
      );
    });
  });

  group('Order detail widgets', () {
    testWidgets('incoming shows accept/reject; rejected shows reason', (
      tester,
    ) async {
      final incoming = _detail(
        id: 'o-in',
        branchId: 'b1',
        status: 'CREATED',
        fulfillment: 'PENDING_ACCEPTANCE',
      );
      final merchant = FakeMerchantApi(
        meHandler: () async => MerchantMe(
          merchantMembershipExists: true,
          memberships: [
            membership(branches: [branch('b1')]),
          ],
        ),
      )..mutableDetail = incoming;
      final container = await _readyContainer(merchant);
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: OrderDetailScreen(orderId: 'o-in'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('order-accept')), findsOneWidget);
      expect(find.byKey(const Key('order-reject')), findsOneWidget);
      expect(find.text('Café'), findsOneWidget);
      expect(find.byKey(const Key('order-detail-ref')), findsOneWidget);

      await container
          .read(orderDetailControllerProvider('o-in').notifier)
          .reject('Rupture de stock');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      final after =
          container.read(orderDetailControllerProvider('o-in')).value!;
      expect(after.order.status, 'CANCELLED');
      expect(after.order.cancellation?.reason, 'Rupture de stock');
      expect(
        find.byKey(
          const Key('order-cancellation-reason'),
          skipOffstage: false,
        ),
        findsOneWidget,
      );
      expect(find.byKey(const Key('order-accept')), findsNothing);
    });

    testWidgets('ready state has no mark-ready; waiting copy shown', (
      tester,
    ) async {
      final ready = _detail(
        id: 'o-ready',
        branchId: 'b1',
        status: 'ACTIVE',
        fulfillment: 'READY',
      );
      final merchant = FakeMerchantApi(
        meHandler: () async => MerchantMe(
          merchantMembershipExists: true,
          memberships: [
            membership(branches: [branch('b1')]),
          ],
        ),
      )..mutableDetail = ready;
      final container = await _readyContainer(merchant);
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: OrderDetailScreen(orderId: 'o-ready'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('order-mark-ready')), findsNothing);
      expect(find.text(AppStrings.orderReadyBanner), findsWidgets);
      expect(find.byKey(const Key('order-ready-waiting')), findsOneWidget);
      expect(
        find.textContaining('livraison', findRichText: true),
        findsWidgets,
      );
    });
  });
}
