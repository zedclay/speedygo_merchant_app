import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speedygo_merchant_app/features/access/data/models.dart';
import 'package:speedygo_merchant_app/features/orders/data/order_models.dart';
import 'package:speedygo_merchant_app/features/reports/data/reports_models.dart';
import 'package:speedygo_merchant_app/features/shell/home_dashboard_screen.dart';
import 'package:speedygo_merchant_app/features/store/data/store_models.dart';

import '../../features/phase1_flow_test.dart';
import 'parity_harness.dart';

MerchantOrderSummary _order(
  String id, {
  required String fulfillment,
  String status = 'ACTIVE',
  required String customer,
  required String minor,
}) {
  return MerchantOrderSummary(
    id: id,
    publicReference: 'sgo_$id',
    status: status,
    fulfillmentStatus: fulfillment,
    merchantBranchId: 'b1',
    createdAt: '2026-09-30T10:00:00Z',
    confirmedAt: null,
    customerFullName: customer,
    financial: MerchantOrderFinancial(
      currency: 'DZD',
      grossMerchandiseSubtotalMinor: minor,
      merchantDiscountMinor: '0',
      merchantCommissionRateBps: 700,
      merchantCommissionAmountMinor: '0',
      merchantNetAmountMinor: minor,
      deliveryFeeMinor: '20000',
    ),
    payment: const MerchantOrderPayment(method: 'COD', status: 'PENDING'),
  );
}

MerchantOrderListPage _page(List<MerchantOrderSummary> items, {int? total}) =>
    MerchantOrderListPage(
      items: items,
      total: total ?? items.length,
      limit: 50,
      offset: 0,
    );

BranchAvailabilityState _open(String branchId) => BranchAvailabilityState(
      branchId: branchId,
      timezone: 'Africa/Algiers',
      availabilityMode: 'FOLLOW_SCHEDULE',
      effectiveMode: 'FOLLOW_SCHEDULE',
      hoursConfigured: true,
      isOpenNow: true,
      acceptingOrders: true,
      temporaryExpired: false,
      outsideWeeklyHours: false,
      reasonCode: null,
      customerMessage: null,
      closedUntil: null,
      nextOpenAt: null,
      currentClosesAt: null,
      version: null,
      updatedAt: null,
    );

FakeMerchantApi _dashboardMerchant({required bool populated}) {
  final incoming = _order(
    'i1',
    fulfillment: 'PENDING_ACCEPTANCE',
    status: 'CREATED',
    customer: 'Sara Belkacem',
    minor: '225000',
  );
  final ready = _order(
    'r1',
    fulfillment: 'READY',
    customer: 'Mohamed Rezki',
    minor: '140000',
  );
  return FakeMerchantApi(
    meHandler: () async => MerchantMe(
      merchantMembershipExists: true,
      memberships: [
        membership(branches: [branch('b1', name: 'Dar El Benna')])
            .parityWith(name: 'Dar El Benna', attention: populated),
      ],
    ),
    availabilityHandler: ({required merchantId, required branchId}) async =>
        _open(branchId),
    salesSummaryHandler: ({required merchantId, required period, branchId}) async =>
        MerchantSalesSummary.fromJson({
      'scope': {'merchantId': merchantId, 'branchId': branchId},
      'period': {'period': period.period.apiValue},
      'asOf': '2026-09-30T12:00:00.000Z',
      'currency': 'DZD',
      'dataStatus': 'COMPLETE',
      'completedOrderCount': populated ? 18 : 0,
      'grossMerchandiseMinor': populated ? '4230000' : '0',
      'averageBasketMinor': null,
      'cancelledOrderCount': 0,
      'financeAccess': 'ROLE_RESTRICTED',
      'finance': null,
      'trend': {'granularity': 'HOUR', 'buckets': <Object>[]},
    }),
    ordersHandler: ({
      required merchantId,
      branchId,
      orderStatus,
      fulfillmentStatus,
      limit = 50,
      offset = 0,
    }) async {
      if (!populated) return _page(const []);
      if (fulfillmentStatus == 'PENDING_ACCEPTANCE') {
        return _page([incoming], total: 2);
      }
      if (fulfillmentStatus == 'PREPARING') return _page(const [], total: 3);
      if (fulfillmentStatus == 'READY') return _page([ready], total: 1);
      return _page(const []);
    },
  )..unreadCount = populated ? 2 : 0;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('parity batch 1 — shell and dashboard (mocked)', () {
    for (final v in parityVariants) {
      testWidgets('dashboard populated ${v.suffix}', (tester) async {
        final container =
            await parityReady(_dashboardMerchant(populated: true));
        addTearDown(container.dispose);
        await parityPump(
          tester,
          container: container,
          variant: v,
          height: v.textScale > 1 ? 1500 : 1091,
          tabIndex: 0,
          child: const HomeScreen(),
        );
        await parityCapture(tester, 'b1_dashboard_populated_${v.suffix}');
        expect(find.byKey(const Key('home-verification-banner')), findsOneWidget);
        expect(find.byKey(const Key('home-kpi-sales')), findsOneWidget);
        expect(find.textContaining('42 300 DZD'), findsOneWidget);
        expect(find.byKey(const Key('bell-unread-dot')), findsOneWidget);
        expect(find.text('Nouveau'), findsOneWidget);
      });

      testWidgets('dashboard empty ${v.suffix}', (tester) async {
        final container =
            await parityReady(_dashboardMerchant(populated: false));
        addTearDown(container.dispose);
        await parityPump(
          tester,
          container: container,
          variant: v,
          height: v.textScale > 1 ? 900 : 844,
          tabIndex: 0,
          child: const HomeScreen(),
        );
        await parityCapture(tester, 'b1_dashboard_empty_${v.suffix}');
        expect(find.byKey(const Key('home-active-orders-empty')), findsOneWidget);
        expect(find.byKey(const Key('bell-unread-dot')), findsNothing);
      });
    }
  });

  group('dashboard behaviour', () {
    testWidgets('non-ACTIVE branch keeps its operational pill', (tester) async {
      final merchant = _dashboardMerchant(populated: false)
        ..meHandler = () async => MerchantMe(
              merchantMembershipExists: true,
              memberships: [
                membership(
                  branches: [branch('b1', name: 'Dar El Benna', status: 'SUSPENDED')],
                ),
              ],
            );
      final container =
          await parityReady(merchant, branchStatus: 'SUSPENDED');
      addTearDown(container.dispose);
      await parityPump(
        tester,
        container: container,
        variant: parityVariants.first,
        height: 844,
        tabIndex: 0,
        child: const HomeScreen(),
      );
      expect(find.byKey(const Key('home-operational-badge')), findsOneWidget);
      expect(find.text('Suspendu'), findsOneWidget);
    });

    testWidgets('KPIs show a dash, never zero, when the summary fails',
        (tester) async {
      final merchant = _dashboardMerchant(populated: false)
        ..salesSummaryHandler = ({
          required merchantId,
          required period,
          branchId,
        }) async =>
            throw Exception('reports unavailable');
      final container = await parityReady(merchant);
      addTearDown(container.dispose);
      await parityPump(
        tester,
        container: container,
        variant: parityVariants.first,
        height: 844,
        tabIndex: 0,
        child: const HomeScreen(),
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('home-kpi-sales')),
          matching: find.textContaining('—'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('home-kpi-orders')),
          matching: find.textContaining('0'),
        ),
        findsNothing,
      );
      container.dispose();
    });
  });
}
