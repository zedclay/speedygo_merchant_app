import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speedygo_merchant_app/core/constants/app_strings.dart';
import 'package:speedygo_merchant_app/core/errors/app_exception.dart';
import 'package:speedygo_merchant_app/features/access/application/access_controller.dart';
import 'package:speedygo_merchant_app/features/access/data/models.dart';
import 'package:speedygo_merchant_app/features/notifications/domain/incoming_order_alert.dart';
import 'package:speedygo_merchant_app/features/notifications/presentation/incoming_order_alert_overlay.dart';
import 'package:speedygo_merchant_app/features/orders/presentation/order_detail_screen.dart';
import 'package:speedygo_merchant_app/features/orders/presentation/orders_screen.dart';
import 'package:speedygo_merchant_app/features/store/data/store_models.dart';
import 'package:speedygo_merchant_app/features/support/presentation/order_support_screen.dart';

import '../../features/phase1_flow_test.dart';
import 'parity_harness.dart';

String _iso(DateTime t) => t.toUtc().toIso8601String();

final _now = DateTime.now().toUtc();

Map<String, Object?> _financial({required String gross, bool staff = false}) {
  final g = int.parse(gross);
  final commission = g * 700 ~/ 10000;
  return staff
      ? {
          'currency': 'DZD',
          'grossMerchandiseSubtotalMinor': gross,
          'deliveryFeeMinor': '20000',
        }
      : {
          'currency': 'DZD',
          'grossMerchandiseSubtotalMinor': gross,
          'merchantDiscountMinor': '0',
          'merchantCommissionRateBps': 700,
          'merchantCommissionAmountMinor': '$commission',
          'merchantNetAmountMinor': '${g - commission}',
          'deliveryFeeMinor': '20000',
        };
}

Map<String, Object?> _summaryJson(
  String id, {
  required String status,
  required String fulfillment,
  required String customer,
  required String gross,
  required DateTime createdAt,
  DateTime? estimatedReadyAt,
  bool late = false,
}) => {
  'id': id,
  'publicReference': 'sgo_$id',
  'status': status,
  'fulfillmentStatus': fulfillment,
  'merchantBranchId': 'b1',
  'createdAt': _iso(createdAt),
  'confirmedAt': null,
  'customerFullName': customer,
  'payment': {'method': 'COD', 'status': 'PENDING'},
  'financialAccess': 'GRANTED',
  'financial': _financial(gross: gross),
  'preparationMinutes': estimatedReadyAt == null ? null : 25,
  'originalPreparationMinutes': estimatedReadyAt == null ? null : 25,
  'estimatedReadyAt': estimatedReadyAt == null ? null : _iso(estimatedReadyAt),
  'originalEstimatedReadyAt':
      estimatedReadyAt == null ? null : _iso(estimatedReadyAt),
  'preparationEstimateVersion': estimatedReadyAt == null ? 0 : 1,
  'isPreparationLate': late,
};

MerchantOrderSummary _summary(
  String id, {
  required String status,
  required String fulfillment,
  required String customer,
  required String gross,
  required DateTime createdAt,
  DateTime? estimatedReadyAt,
  bool late = false,
}) => MerchantOrderSummary.fromJson(
  _summaryJson(
    id,
    status: status,
    fulfillment: fulfillment,
    customer: customer,
    gross: gross,
    createdAt: createdAt,
    estimatedReadyAt: estimatedReadyAt,
    late: late,
  ),
);

const _items = [
  {
    'id': 'it1',
    'productId': 'p1',
    'productNameSnapshot': 'Couscous royal',
    'quantity': 1,
    'unitPriceMinor': '120000',
    'lineTotalMinor': '120000',
    'options': [
      {'optionNameSnapshot': 'Agneau', 'additionalPriceMinor': '0'},
    ],
  },
  {
    'id': 'it2',
    'productId': 'p2',
    'productNameSnapshot': 'Chorba frik',
    'quantity': 2,
    'unitPriceMinor': '35000',
    'lineTotalMinor': '70000',
    'options': <Object>[],
  },
  {
    'id': 'it3',
    'productId': 'p3',
    'productNameSnapshot': 'Thé à la menthe',
    'quantity': 1,
    'unitPriceMinor': '35000',
    'lineTotalMinor': '35000',
    'options': <Object>[],
  },
];

Map<String, Object?> _event(
  String type,
  String actor,
  String? from,
  String to,
  DateTime at,
) => {
  'eventType': type,
  'actorType': actor,
  'fromStatus': from,
  'toStatus': to,
  'occurredAt': _iso(at),
};

MerchantOrderDetail _detail(
  String id, {
  required String status,
  required String fulfillment,
  required List<Map<String, Object?>> history,
  DateTime? estimatedReadyAt,
  Map<String, Object?>? cancellation,
  bool staff = false,
  bool late = false,
  int? delayMinutes,
  Map<String, Object?>? deliveryImpact,
  Map<String, Object?>? latestPreparationRevision,
}) {
  final created = _now.subtract(const Duration(minutes: 40));
  return MerchantOrderDetail.fromJson({
    ..._summaryJson(
      id,
      status: status,
      fulfillment: fulfillment,
      customer: 'Sara Belkacem',
      gross: '225000',
      createdAt: created,
      estimatedReadyAt: estimatedReadyAt,
      late: late,
    ),
    'financialAccess': staff ? 'ROLE_RESTRICTED' : 'GRANTED',
    'financial': _financial(gross: '225000', staff: staff),
    'items': _items,
    'deliveryAddress': {
      'addressText': 'Cité 200 logements, Sidi Djillali, Sidi Bel Abbès',
      'latitude': 35.19,
      'longitude': -0.63,
      'instructions': null,
    },
    'statusHistory': history,
    'cancellation': cancellation,
    if (delayMinutes != null) 'delayMinutes': delayMinutes,
    if (deliveryImpact != null) 'deliveryImpact': deliveryImpact,
    if (latestPreparationRevision != null)
      'latestPreparationRevision': latestPreparationRevision,
  });
}

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

MerchantOrderListPage _page(List<MerchantOrderSummary> items, {int? total}) =>
    MerchantOrderListPage(
      items: items,
      total: total ?? items.length,
      limit: 50,
      offset: 0,
    );

FakeMerchantApi _merchant({
  String role = 'OWNER',
  MerchantOrderDetail? detail,
  MerchantDeliverySummary? delivery,
}) {
  final incoming = [
    _summary(
      'a1842',
      status: 'CREATED',
      fulfillment: 'PENDING_ACCEPTANCE',
      customer: 'Sara Belkacem',
      gross: '225000',
      createdAt: _now.subtract(const Duration(minutes: 2)),
    ),
    _summary(
      'a1843',
      status: 'CREATED',
      fulfillment: 'PENDING_ACCEPTANCE',
      customer: 'Karim Haddad',
      gross: '98000',
      createdAt: _now.subtract(const Duration(minutes: 1)),
    ),
  ];
  final preparing = [
    _summary(
      'a1835',
      status: 'ACTIVE',
      fulfillment: 'PREPARING',
      customer: 'Amine Bensaïd',
      gross: '154000',
      createdAt: _now.subtract(const Duration(minutes: 20)),
      estimatedReadyAt: _now.add(const Duration(minutes: 12)),
    ),
    _summary(
      'a1829',
      status: 'ACTIVE',
      fulfillment: 'PREPARING',
      customer: 'Lina Meziane',
      gross: '76000',
      createdAt: _now.subtract(const Duration(minutes: 45)),
      estimatedReadyAt: _now.subtract(const Duration(minutes: 6)),
      late: true,
    ),
  ];
  final ready = [
    _summary(
      'a1820',
      status: 'ACTIVE',
      fulfillment: 'READY',
      customer: 'Mohamed Rezki',
      gross: '140000',
      createdAt: _now.subtract(const Duration(minutes: 35)),
    ),
  ];
  final completed = [
    _summary(
      'a1801',
      status: 'COMPLETED',
      fulfillment: 'READY',
      customer: 'Nadia Ouali',
      gross: '310000',
      createdAt: _now.subtract(const Duration(hours: 1)),
    ),
    _summary(
      'a1760',
      status: 'COMPLETED',
      fulfillment: 'READY',
      customer: 'Yacine Mansouri',
      gross: '185000',
      createdAt: _now.subtract(const Duration(days: 1, hours: 2)),
    ),
  ];
  final cancelled = [
    _summary(
      'a1799',
      status: 'CANCELLED',
      fulfillment: 'PENDING_ACCEPTANCE',
      customer: 'Rania Saadi',
      gross: '64000',
      createdAt: _now.subtract(const Duration(hours: 2)),
    ),
  ];
  return FakeMerchantApi(
    meHandler: () async => MerchantMe(
      merchantMembershipExists: true,
      memberships: [
        membership(
          role: role,
          branches: [branch('b1', name: 'Dar El Benna')],
        ).parityWith(name: 'Dar El Benna'),
      ],
    ),
    availabilityHandler: ({required merchantId, required branchId}) async =>
        _open(branchId),
    ordersHandler:
        ({
          required merchantId,
          branchId,
          orderStatus,
          fulfillmentStatus,
          limit = 50,
          offset = 0,
        }) async {
          final list = switch ((orderStatus, fulfillmentStatus)) {
            ('CREATED', 'PENDING_ACCEPTANCE') => incoming,
            ('ACTIVE', 'PREPARING') => preparing,
            ('ACTIVE', 'READY') => ready,
            ('COMPLETED', _) => completed,
            ('CANCELLED', _) => cancelled,
            (_, 'PENDING_ACCEPTANCE') => incoming,
            (_, 'PREPARING') => preparing,
            (_, 'READY') => ready,
            _ => <MerchantOrderSummary>[],
          };
          return _page(limit == 1 ? list.take(1).toList() : list,
              total: list.length);
        },
    orderDetailHandler: ({required merchantId, required orderId}) async =>
        detail!,
  )
    ..unreadCount = 2
    ..deliveryHandler = ({required orderId}) async => delivery;
}

MerchantDeliverySummary _delivery(String status) => MerchantDeliverySummary(
  id: 'd1',
  orderId: 'o1',
  publicReference: 'sgd_d1',
  status: status,
  orderStatus: 'ACTIVE',
  fulfillmentStatus: 'READY',
  driverSearchStartedAt: _iso(_now.subtract(const Duration(minutes: 3))),
);

final _t0 = _now.subtract(const Duration(minutes: 40));

final _historyReady = [
  _event('ORDER_CREATED', 'CUSTOMER', null, 'CREATED', _t0),
  _event('MERCHANT_ACCEPTED', 'MERCHANT', 'CREATED', 'CONFIRMED',
      _t0.add(const Duration(minutes: 2))),
  _event('PREPARATION_STARTED', 'MERCHANT', 'CONFIRMED', 'ACTIVE',
      _t0.add(const Duration(minutes: 4))),
  _event('ORDER_READY', 'MERCHANT', 'ACTIVE', 'ACTIVE',
      _t0.add(const Duration(minutes: 30))),
];

MerchantOrderDetail _incomingDetail() => _detail(
  'o1',
  status: 'CREATED',
  fulfillment: 'PENDING_ACCEPTANCE',
  history: [_historyReady.first],
);

/// Accepted, preparation not started yet (24:54 left on the estimate).
MerchantOrderDetail _confirmedDetail() => _detail(
  'o1',
  status: 'CONFIRMED',
  fulfillment: 'ACCEPTED',
  estimatedReadyAt: _now.add(const Duration(minutes: 24, seconds: 54)),
  history: _historyReady.take(2).toList(),
);

MerchantOrderDetail _preparingDetail() => _detail(
  'o1',
  status: 'ACTIVE',
  fulfillment: 'PREPARING',
  estimatedReadyAt: _now.add(const Duration(minutes: 11, seconds: 40)),
  history: _historyReady.take(3).toList(),
);

MerchantOrderDetail _lateDetail() => _detail(
  'o1',
  status: 'ACTIVE',
  fulfillment: 'PREPARING',
  estimatedReadyAt: _now.subtract(const Duration(minutes: 8)),
  late: true,
  delayMinutes: 8,
  deliveryImpact: {
    'state': 'MAY_DELAY_DRIVER_ASSIGNMENT',
    'deliveryStatus': 'SEARCHING_DRIVER',
  },
  latestPreparationRevision: {
    'revisionNumber': 1,
    'addMinutes': 10,
    'reason': 'Forte affluence',
    'createdAt': _iso(_now.subtract(const Duration(minutes: 2))),
  },
  history: _historyReady.take(3).toList(),
);

/// Same lateness as the live Dar El Bahja order (2838 min past the estimate).
MerchantOrderDetail _lateDaysDetail() => _detail(
  'o1',
  status: 'ACTIVE',
  fulfillment: 'PREPARING',
  estimatedReadyAt: _now.subtract(const Duration(minutes: 2838)),
  late: true,
  delayMinutes: 2838,
  deliveryImpact: {
    'state': 'MAY_DELAY_DRIVER_ASSIGNMENT',
    'deliveryStatus': 'SEARCHING_DRIVER',
  },
  history: _historyReady.take(3).toList(),
);

MerchantOrderDetail _readyDetail() => _detail(
  'o1',
  status: 'ACTIVE',
  fulfillment: 'READY',
  history: _historyReady,
);

MerchantOrderDetail _completedDetail() => _detail(
  'o1',
  status: 'COMPLETED',
  fulfillment: 'READY',
  history: [
    ..._historyReady,
    _event('ORDER_COMPLETED', 'SYSTEM', 'ACTIVE', 'COMPLETED',
        _t0.add(const Duration(minutes: 52))),
  ],
);

MerchantOrderDetail _cancelledDetail() => _detail(
  'o1',
  status: 'CANCELLED',
  fulfillment: 'PENDING_ACCEPTANCE',
  history: [
    _historyReady.first,
    _event('CUSTOMER_CANCELLED', 'CUSTOMER', 'CREATED', 'CANCELLED',
        _t0.add(const Duration(minutes: 5))),
  ],
  cancellation: {
    'reason': "Temps d'attente trop long",
    'cancelledAt': _iso(_t0.add(const Duration(minutes: 5))),
  },
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('parity batch 2 — orders (mocked)', () {
    for (final v in parityVariants) {
      testWidgets('orders active incoming ${v.suffix}', (tester) async {
        final container = await parityReady(_merchant());
        addTearDown(container.dispose);
        await parityPumpFull(
          tester,
          container: container,
          variant: v,
          tabIndex: 1,
          child: const OrdersScreen(),
        );
        await parityCapture(tester, 'b2_orders_active_incoming_${v.suffix}');
        expect(find.byKey(const Key('order-card-a1842')), findsOneWidget);
        expect(find.byKey(const Key('orders-branch-context')), findsOneWidget);
      });

      testWidgets('orders active preparing ${v.suffix}', (tester) async {
        final container = await parityReady(_merchant());
        addTearDown(container.dispose);
        await parityPump(
          tester,
          container: container,
          variant: v,
          height: 844,
          tabIndex: 1,
          child: const OrdersScreen(),
        );
        await tester.ensureVisible(
          find.byKey(const Key('orders-filter-preparing')),
        );
        await tester.pump();
        await tester.tap(find.byKey(const Key('orders-filter-preparing')));
        await parityPumpFull(
          tester,
          container: container,
          variant: v,
          tabIndex: 1,
          child: const OrdersScreen(),
        );
        await parityCapture(tester, 'b2_orders_active_preparing_${v.suffix}');
        expect(find.byKey(const Key('order-card-a1835')), findsOneWidget);
      });

      testWidgets('orders history ${v.suffix}', (tester) async {
        final container = await parityReady(_merchant());
        addTearDown(container.dispose);
        await parityPump(
          tester,
          container: container,
          variant: v,
          height: 844,
          tabIndex: 1,
          child: const OrdersScreen(),
        );
        await tester.tap(find.byKey(const Key('orders-segment-history')));
        await parityPumpFull(
          tester,
          container: container,
          variant: v,
          tabIndex: 1,
          child: const OrdersScreen(),
        );
        await parityCapture(tester, 'b2_orders_history_${v.suffix}');
      });

      final details = <String, (MerchantOrderDetail Function(), String?)>{
        'incoming': (_incomingDetail, null),
        'confirmed': (_confirmedDetail, null),
        'preparing': (_preparingDetail, null),
        'preparing_late': (_lateDetail, null),
        'preparing_late_days': (_lateDaysDetail, null),
        'ready_searching': (_readyDetail, 'SEARCHING_DRIVER'),
        'ready_at_pickup': (_readyDetail, 'AT_PICKUP'),
        'ready_to_pickup': (_readyDetail, 'TO_PICKUP'),
        'completed': (_completedDetail, 'DELIVERED'),
        'cancelled': (_cancelledDetail, null),
      };
      for (final entry in details.entries) {
        testWidgets('detail ${entry.key} ${v.suffix}', (tester) async {
          final (build, deliveryStatus) = entry.value;
          final container = await parityReady(
            _merchant(
              detail: build(),
              delivery: deliveryStatus == null ? null : _delivery(deliveryStatus),
            ),
          );
          addTearDown(container.dispose);
          await parityPumpFull(
            tester,
            container: container,
            variant: v,
            child: const OrderDetailScreen(orderId: 'o1'),
            pushed: true,
          );
          await parityCapture(tester, 'b2_detail_${entry.key}_${v.suffix}');
          expect(find.byKey(const Key('order-detail-ref')), findsOneWidget);
          if (entry.key == 'preparing_late_days') {
            expect(find.textContaining('1 j 23 h de retard'), findsOneWidget);
            expect(find.textContaining('2838'), findsNothing);
            expect(find.textContaining('Heure prévue : le '), findsOneWidget);
            expect(find.textContaining('Prête'), findsNothing);
          }
          if (entry.key.startsWith('preparing_late')) {
            final banner = tester.getTopLeft(
              find.byKey(const Key('prep-countdown-banner')),
            );
            final identity = tester.getTopLeft(
              find.byKey(const Key('order-identity-block')),
            );
            expect(banner.dy, lessThan(identity.dy));
            expect(
              tester.getSize(find.byKey(const Key('order-identity-block'))).height,
              lessThan(170),
            );
          }
          if (entry.key == 'confirmed') {
            expect(find.byKey(const Key('order-start-prep')), findsOneWidget);
            expect(find.byKey(const Key('order-mark-ready')), findsNothing);
          }
          if (entry.key == 'ready_to_pickup') {
            expect(find.text('TO_PICKUP'), findsNothing);
            expect(find.textContaining('Livreur en route'), findsWidgets);
          }
        });
      }

      testWidgets('mark ready confirmation ${v.suffix}', (tester) async {
        final container =
            await parityReady(_merchant(detail: _preparingDetail()));
        addTearDown(container.dispose);
        await parityPump(
          tester,
          container: container,
          variant: v,
          height: 844,
          includeOverlays: true,
          pushed: true,
          child: const OrderDetailScreen(orderId: 'o1'),
        );
        await tester.tap(find.byKey(const Key('order-mark-ready')));
        await tester.pumpAndSettle();
        await parityCapture(tester, 'b2_mark_ready_confirm_${v.suffix}');
        expect(
          find.byKey(const Key('order-mark-ready-confirm-screen')),
          findsOneWidget,
        );
        expect(find.byType(Checkbox), findsNothing);
        expect(tester.takeException(), isNull);
      });

      testWidgets('accept sheet ${v.suffix}', (tester) async {
        final container =
            await parityReady(_merchant(detail: _incomingDetail()));
        addTearDown(container.dispose);
        await parityPump(
          tester,
          container: container,
          variant: v,
          height: 844,
          includeOverlays: true,
          pushed: true,
          child: const OrderDetailScreen(orderId: 'o1'),
        );
        await tester.tap(find.byKey(const Key('order-accept')));
        await tester.pumpAndSettle();
        await parityCapture(tester, 'b2_accept_sheet_${v.suffix}');
        expect(find.byKey(const Key('accept-prep-sheet')), findsOneWidget);
        expect(find.textContaining('Recommandé'), findsNothing);
      });

      testWidgets('update prep sheet ${v.suffix}', (tester) async {
        final container =
            await parityReady(_merchant(detail: _preparingDetail()));
        addTearDown(container.dispose);
        await parityPump(
          tester,
          container: container,
          variant: v,
          height: 844,
          includeOverlays: true,
          pushed: true,
          child: const OrderDetailScreen(orderId: 'o1'),
        );
        await tester.tap(find.byKey(const Key('prep-update-open')));
        await tester.pumpAndSettle();
        await parityCapture(tester, 'b2_update_sheet_${v.suffix}');
        expect(find.byKey(const Key('prep-update-preview')), findsOneWidget);

        await tester.ensureVisible(find.byKey(const Key('prep-reason-busy')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('prep-reason-busy')));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.byKey(const Key('prep-update-reason')));
        await tester.pumpAndSettle();
        final field = tester.getRect(find.byKey(const Key('prep-update-reason')));
        final confirm =
            tester.getRect(find.byKey(const Key('prep-update-confirm')));
        expect(field.bottom, lessThanOrEqualTo(confirm.top));
        expect(
          tester
              .widget<TextField>(find.byKey(const Key('prep-update-reason')))
              .controller!
              .text,
          AppStrings.prepReasonBusy,
        );
        await parityCapture(tester, 'b2_update_sheet_reason_${v.suffix}');
      });

      testWidgets('update prep sheet previous day ${v.suffix}', (tester) async {
        final container =
            await parityReady(_merchant(detail: _lateDaysDetail()));
        addTearDown(container.dispose);
        await parityPump(
          tester,
          container: container,
          variant: v,
          height: 844,
          includeOverlays: true,
          pushed: true,
          child: const OrderDetailScreen(orderId: 'o1'),
        );
        await tester.tap(find.byKey(const Key('prep-update-open')));
        await tester.pumpAndSettle();
        await parityCapture(tester, 'b2_update_sheet_days_${v.suffix}');
        final current = tester
            .widget<Text>(find.byKey(const Key('prep-update-current-ready')))
            .data!;
        expect(current, startsWith('le '));
        expect(find.byKey(const Key('prep-preview-from-day')), findsOneWidget);
        expect(find.byKey(const Key('prep-preview-to-day')), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('incoming alert ${v.suffix}', (tester) async {
        final container = await parityReady(_merchant());
        addTearDown(container.dispose);
        final alert = IncomingOrderAlert.fromDetail(
          detail: _incomingDetail(),
          notificationId: 'n1',
        );
        await parityPump(
          tester,
          container: container,
          variant: v,
          height: v.textScale > 1 ? 1000 : 844,
          child: IncomingOrderAlertOverlay(
            alert: alert,
            onViewDetails: () {},
            onRefuse: () {},
            onDismiss: () {},
          ),
        );
        await parityCapture(tester, 'b2_incoming_alert_${v.suffix}');
        expect(find.text('Total de la commande'), findsNothing);
        expect(find.text('Sous-total marchandises'), findsOneWidget);
      });

      testWidgets('support form ${v.suffix}', (tester) async {
        final container = await parityReady(
          _merchant(detail: _completedDetail()),
        );
        addTearDown(container.dispose);
        await parityPumpFull(
          tester,
          container: container,
          variant: v,
          child: const OrderSupportScreen(orderId: 'o1'),
          pushed: true,
        );
        await parityCapture(tester, 'b2_support_form_${v.suffix}');
        expect(find.byKey(const Key('support-body')), findsOneWidget);
      });
    }
  });

  group('orders behaviour', () {
    testWidgets('accept sheet custom time is bounded 5–120', (tester) async {
      final merchant = _merchant(detail: _incomingDetail());
      final container = await parityReady(merchant);
      addTearDown(container.dispose);
      await parityPump(
        tester,
        container: container,
        variant: parityVariants.first,
        height: 900,
        child: const OrderDetailScreen(orderId: 'o1'),
      );
      await tester.tap(find.byKey(const Key('order-accept')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('prep-minutes-custom-open')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('prep-minutes-custom')), '150');
      await tester.pump();
      expect(
        tester.widget<FilledButton>(find.byKey(const Key('accept-prep-confirm'))).onPressed,
        isNull,
      );
      await tester.enterText(find.byKey(const Key('prep-minutes-custom')), '35');
      await tester.pump();
      expect(
        tester.widget<FilledButton>(find.byKey(const Key('accept-prep-confirm'))).onPressed,
        isNotNull,
      );
    });

    testWidgets('timeline shows French labels, newest first', (tester) async {
      final container = await parityReady(
        _merchant(detail: _completedDetail(), delivery: _delivery('DELIVERED')),
      );
      addTearDown(container.dispose);
      await parityPumpFull(
        tester,
        container: container,
        variant: parityVariants.first,
        child: const OrderDetailScreen(orderId: 'o1'),
      );
      final timeline = find.byKey(const Key('order-timeline'));
      expect(timeline, findsOneWidget);
      expect(
        find.descendant(of: timeline, matching: find.textContaining('_')),
        findsNothing,
      );
      final completedY = tester.getTopLeft(
        find.descendant(of: timeline, matching: find.text('Terminée')),
      ).dy;
      final createdY = tester.getTopLeft(
        find.descendant(of: timeline, matching: find.text('Commande reçue')),
      ).dy;
      expect(completedY, lessThan(createdY));
    });

    testWidgets('AT_PICKUP reads as driver at the store', (tester) async {
      final container = await parityReady(
        _merchant(detail: _readyDetail(), delivery: _delivery('AT_PICKUP')),
      );
      addTearDown(container.dispose);
      await parityPumpFull(
        tester,
        container: container,
        variant: parityVariants.first,
        child: const OrderDetailScreen(orderId: 'o1'),
      );
      expect(find.text('AT_PICKUP'), findsNothing);
      expect(find.textContaining('Livreur arrivé au commerce'), findsWidgets);
    });

    testWidgets('cancelled order names the customer as actor', (tester) async {
      final container =
          await parityReady(_merchant(detail: _cancelledDetail()));
      addTearDown(container.dispose);
      await parityPumpFull(
        tester,
        container: container,
        variant: parityVariants.first,
        child: const OrderDetailScreen(orderId: 'o1'),
      );
      expect(
        tester.widget<Text>(find.byKey(const Key('order-cancellation-actor'))).data,
        'Annulée par le client',
      );
      expect(find.byKey(const Key('order-cancellation-reason')), findsOneWidget);
    });

    testWidgets('STAFF has no support entry on the detail', (tester) async {
      final container = await parityReady(
        _merchant(role: 'STAFF', detail: _readyDetail()),
      );
      addTearDown(container.dispose);
      await parityPumpFull(
        tester,
        container: container,
        variant: parityVariants.first,
        child: const OrderDetailScreen(orderId: 'o1'),
      );
      expect(find.byKey(const Key('order-support')), findsNothing);
    });

    testWidgets('OWNER support entry is shown on a ready order', (tester) async {
      final container = await parityReady(_merchant(detail: _readyDetail()));
      addTearDown(container.dispose);
      await parityPumpFull(
        tester,
        container: container,
        variant: parityVariants.first,
        child: const OrderDetailScreen(orderId: 'o1'),
      );
      expect(find.byKey(const Key('order-support')), findsOneWidget);
    });

    testWidgets('support form sends body with orderId and shows the ticket ref',
        (tester) async {
      final merchant = _merchant(detail: _completedDetail())
        ..supportTicketHandler = ({required body, orderId}) async => 'sgt_42ab';
      final container = await parityReady(merchant);
      addTearDown(container.dispose);
      await parityPump(
        tester,
        container: container,
        variant: parityVariants.first,
        height: 844,
        child: const OrderSupportScreen(orderId: 'o1'),
      );
      await tester.tap(find.byKey(const Key('support-send')));
      await tester.pump();
      expect(merchant.supportTickets, isEmpty);

      await tester.tap(find.byKey(const Key('support-topic-choice-ORDER_ISSUE')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('support-subject')),
        'Livraison incomplète',
      );
      await tester.enterText(
        find.byKey(const Key('support-body')),
        'Le livreur est reparti sans la boisson.',
      );
      await tester.pump();
      await tester.tap(find.byKey(const Key('support-send')));
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      expect(merchant.supportTickets, [
        {
          'body': 'Le livreur est reparti sans la boisson.',
          'orderId': 'o1',
          'subject': 'Livraison incomplète',
          'topicCode': 'ORDER_ISSUE',
        },
      ]);
      expect(find.byKey(const Key('support-sent')), findsOneWidget);
      expect(find.textContaining('sgt_42ab'), findsOneWidget);
    });

    testWidgets('support form maps 403 to a permission message', (tester) async {
      final merchant = _merchant(detail: _completedDetail())
        ..supportTicketHandler = ({required body, orderId}) async =>
            throw const ApiException('Forbidden', statusCode: 403);
      final container = await parityReady(merchant);
      addTearDown(container.dispose);
      await parityPump(
        tester,
        container: container,
        variant: parityVariants.first,
        height: 844,
        child: const OrderSupportScreen(orderId: 'o1'),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('support-topic-choice-ORDER_ISSUE')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('support-subject')),
        'Test',
      );
      await tester.enterText(find.byKey(const Key('support-body')), 'Test');
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('support-send')));
      await tester.tap(find.byKey(const Key('support-send')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('support-error')), findsOneWidget);
      expect(find.text(AppStrings.supportForbidden), findsOneWidget);
      expect(find.byKey(const Key('support-sent')), findsNothing);
    });
  });

  group('incoming list-card actions (D-B2)', () {
    MerchantOrderDetail incoming(String id) => _detail(
          id,
          status: 'CREATED',
          fulfillment: 'PENDING_ACCEPTANCE',
          history: [_historyReady.first],
        );

    ({FakeMerchantApi api, List<String> detailReads}) setup({
      String role = 'OWNER',
      MerchantOrderDetail Function(String id)? detailFor,
    }) {
      final reads = <String>[];
      final api = _merchant(role: role)
        ..orderDetailHandler = ({required merchantId, required orderId}) async {
          reads.add(orderId);
          return (detailFor ?? incoming)(orderId);
        };
      return (api: api, detailReads: reads);
    }

    Future<ProviderContainer> pumpList(
      WidgetTester tester,
      FakeMerchantApi api, {
      ParityVariant? variant,
    }) async {
      final container = await parityReady(api);
      addTearDown(container.dispose);
      await parityPump(
        tester,
        container: container,
        variant: variant ?? parityVariants.first,
        height: 1400,
        tabIndex: 1,
        includeOverlays: true,
        child: const OrdersScreen(),
      );
      return container;
    }

    bool minuteSelected(WidgetTester tester, int m) =>
        (tester.widget(find.byKey(Key('prep-minutes-$m'))) as dynamic).selected
            as bool;

    for (final role in const ['OWNER', 'MANAGER']) {
      testWidgets('$role sees accept and reject on incoming cards', (
        tester,
      ) async {
        await pumpList(tester, setup(role: role).api);
        expect(find.byKey(const Key('order-card-accept-a1842')), findsOneWidget);
        expect(find.byKey(const Key('order-card-reject-a1842')), findsOneWidget);
        expect(find.text(AppStrings.homeTreatOrder), findsNothing);
      });
    }

    for (final v in parityVariants) {
      testWidgets('card header gives the name room ${v.suffix}', (
        tester,
      ) async {
        await pumpList(tester, setup().api, variant: v);
        final stacked = find.byKey(const Key('order-card-header-stacked-a1842'));
        final name = tester.getRect(find.byKey(const Key('order-card-name-a1842')));
        final amount =
            tester.getRect(find.byKey(const Key('order-card-gms-a1842')));
        final card = tester.getRect(find.byKey(const Key('order-card-a1842')));
        final lineHeight = MediaQuery.textScalerOf(
              tester.element(find.byKey(const Key('order-card-name-a1842'))),
            ).scale(18) *
            1.6;
        expect(name.height, lessThan(lineHeight), reason: 'name on one line');
        if (v.textScale > 1.2) {
          expect(stacked, findsOneWidget);
          expect(amount.top, greaterThanOrEqualTo(name.bottom));
          expect(name.width, greaterThan((card.width - 32) * 0.4));
        } else {
          expect(stacked, findsNothing);
          expect(amount.left, greaterThanOrEqualTo(name.right));
        }
      });
    }

    testWidgets('icon-only reject is labelled and opens the reason flow', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pumpList(tester, setup().api);
      final reject = find.byKey(const Key('order-card-reject-a1842'));
      expect(
        tester.getSemantics(reject),
        matchesSemantics(
          label: AppStrings.orderRejectTitle,
          isButton: true,
          hasTapAction: true,
          isEnabled: true,
          hasEnabledState: true,
          isFocusable: true,
          hasFocusAction: true,
        ),
      );
      tester.semantics
          .tap(find.semantics.byLabel(AppStrings.orderRejectTitle).first);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('order-reject-reason')), findsOneWidget);
      expect(find.byKey(const Key('order-reject-confirm')), findsOneWidget);
      handle.dispose();
    });

    testWidgets('STAFF keeps "Traiter" and gets no inline actions', (
      tester,
    ) async {
      await pumpList(tester, setup(role: 'STAFF').api);
      expect(find.byKey(const Key('order-card-accept-a1842')), findsNothing);
      expect(find.byKey(const Key('order-card-reject-a1842')), findsNothing);
      expect(find.text(AppStrings.homeTreatOrder), findsNWidgets(2));
    });

    testWidgets('accept rechecks the order, then submits once', (
      tester,
    ) async {
      final s = setup();
      await pumpList(tester, s.api);
      await tester.tap(find.byKey(const Key('order-card-accept-a1842')));
      await tester.tap(
        find.byKey(const Key('order-card-accept-a1842')),
        warnIfMissed: false,
      );
      await tester.pumpAndSettle();
      expect(s.detailReads, ['a1842']);
      expect(find.byKey(const Key('accept-prep-sheet')), findsOneWidget);
      await tester.tap(find.byKey(const Key('prep-minutes-30')));
      await tester.pump();
      await tester.ensureVisible(find.byKey(const Key('accept-prep-confirm')));
      await tester.tap(find.byKey(const Key('accept-prep-confirm')));
      await tester.pumpAndSettle();
      expect(s.api.mutationCalls, ['accept:a1842:30']);
      expect(s.api.acceptCalls, 1);
      expect(find.text(AppStrings.orderQuickAccepted), findsOneWidget);
    });

    testWidgets('order already handled elsewhere: no sheet, no mutation', (
      tester,
    ) async {
      final s = setup(
        detailFor: (id) => _detail(
          id,
          status: 'CONFIRMED',
          fulfillment: 'ACCEPTED',
          history: _historyReady.take(2).toList(),
        ),
      );
      await pumpList(tester, s.api);
      await tester.tap(find.byKey(const Key('order-card-accept-a1842')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('accept-prep-sheet')), findsNothing);
      expect(s.api.mutationCalls, isEmpty);
      expect(find.text(AppStrings.orderQuickAlreadyHandled), findsOneWidget);

      await tester.tap(find.byKey(const Key('order-card-reject-a1843')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('order-reject-reason')), findsNothing);
      expect(s.api.mutationCalls, isEmpty);
    });

    testWidgets('failed accept keeps the chosen preparation time', (
      tester,
    ) async {
      final s = setup();
      s.api.acceptThrowsConflict = true;
      await pumpList(tester, s.api);
      await tester.tap(find.byKey(const Key('order-card-accept-a1842')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('prep-minutes-45')));
      await tester.pump();
      await tester.ensureVisible(find.byKey(const Key('accept-prep-confirm')));
      await tester.tap(find.byKey(const Key('accept-prep-confirm')));
      await tester.pumpAndSettle();
      expect(s.api.mutationCalls, ['accept:a1842:45']);
      expect(find.text(AppStrings.orderQuickAccepted), findsNothing);

      s.api.acceptThrowsConflict = false;
      await tester.tap(find.byKey(const Key('order-card-accept-a1842')));
      await tester.pumpAndSettle();
      expect(minuteSelected(tester, 45), isTrue);
      expect(minuteSelected(tester, 25), isFalse);
    });

    testWidgets('reject requires a reason and keeps it after dismissal', (
      tester,
    ) async {
      final s = setup();
      await pumpList(tester, s.api);
      await tester.tap(find.byKey(const Key('order-card-reject-a1842')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('order-reject-confirm')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('order-reject-reason')), findsOneWidget);
      expect(s.api.mutationCalls, isEmpty);

      await tester.enterText(
        find.byKey(const Key('order-reject-reason')),
        'Rupture de semoule',
      );
      await tester.tap(find.text(AppStrings.back));
      await tester.pumpAndSettle();
      expect(s.api.mutationCalls, isEmpty);

      await tester.tap(find.byKey(const Key('order-card-reject-a1842')));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('order-reject-reason')))
            .controller!
            .text,
        'Rupture de semoule',
      );
      await tester.tap(find.byKey(const Key('order-reject-confirm')));
      await tester.pumpAndSettle();
      expect(s.api.mutationCalls, ['reject:a1842:OTHER:Rupture de semoule']);
      expect(find.text(AppStrings.orderQuickRejected), findsOneWidget);
    });

    testWidgets('inline actions disappear when the role is downgraded', (
      tester,
    ) async {
      final s = setup();
      final container = await pumpList(tester, s.api);
      expect(find.byKey(const Key('order-card-accept-a1842')), findsOneWidget);
      s.api.meHandler = () async => MerchantMe(
            merchantMembershipExists: true,
            memberships: [
              membership(
                role: 'STAFF',
                branches: [branch('b1', name: 'Dar El Benna')],
              ).parityWith(name: 'Dar El Benna'),
            ],
          );
      await container.read(accessControllerProvider.notifier).refreshInPlace();
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('order-card-accept-a1842')), findsNothing);
      expect(find.text(AppStrings.homeTreatOrder), findsNWidgets(2));
    });
  });
}
