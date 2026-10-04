import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
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
import 'package:speedygo_merchant_app/features/notifications/domain/incoming_order_alert.dart';
import 'package:speedygo_merchant_app/features/orders/data/order_models.dart';
import 'package:speedygo_merchant_app/features/orders/presentation/order_detail_screen.dart';
import 'package:speedygo_merchant_app/features/reports/application/reports_controller.dart';
import 'package:speedygo_merchant_app/features/reports/data/reports_models.dart';
import 'package:speedygo_merchant_app/features/reports/presentation/reports_screen.dart';

import 'phase1_flow_test.dart';
import 'sales_report_fixtures.dart';

const _ownerNet = '11,16 DZD';
// Order detail renders the commission as a deduction (Stitch finance reference).
const _ownerCommission = '- 0,84 DZD';
const _gross = '12 DZD';

Map<String, Object?> _orderJson({required bool staff}) => {
  'id': 'o-1',
  'publicReference': 'sgo_o1',
  'status': 'CREATED',
  'fulfillmentStatus': 'PENDING_ACCEPTANCE',
  'merchantBranchId': 'b-1',
  'createdAt': '2026-01-01T10:00:00Z',
  'confirmedAt': null,
  'customerFullName': 'Client Test',
  'payment': {'method': 'COD', 'status': 'PENDING'},
  'financialAccess': staff ? 'ROLE_RESTRICTED' : 'GRANTED',
  'financial': staff
      ? {
          'currency': 'DZD',
          'grossMerchandiseSubtotalMinor': '1200',
          'deliveryFeeMinor': '500',
        }
      : {
          'currency': 'DZD',
          'grossMerchandiseSubtotalMinor': '1200',
          'merchantDiscountMinor': '0',
          'merchantCommissionRateBps': 700,
          'merchantCommissionAmountMinor': '84',
          'merchantNetAmountMinor': '1116',
          'deliveryFeeMinor': '500',
        },
  'preparationMinutes': null,
  'originalPreparationMinutes': null,
  'estimatedReadyAt': null,
  'originalEstimatedReadyAt': null,
  'preparationEstimateVersion': 0,
  'isPreparationLate': false,
  'items': [
    {
      'id': 'i-1',
      'productId': 'p-1',
      'productNameSnapshot': 'Café',
      'quantity': 2,
      'unitPriceMinor': '600',
      'lineTotalMinor': '1200',
      'options': <Object>[],
    },
  ],
  'deliveryAddress': {
    'addressText': 'Hydra, Alger',
    'latitude': 36.75,
    'longitude': 3.05,
    'instructions': null,
  },
  'statusHistory': <Object>[],
  'cancellation': null,
};

MerchantOrderDetail _order({required bool staff}) =>
    MerchantOrderDetail.fromJson(_orderJson(staff: staff));

const _branch = MerchantBranch(
  id: 'b-1',
  name: 'Branche test',
  phone: '0550000000',
  addressText: 'Centre',
  latitude: 36.7,
  longitude: 3.0,
  operationalStatus: 'ACTIVE',
);

MerchantMembership _member(String role) =>
    membership(role: role, branches: [_branch]);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('order financial model', () {
    test('GRANTED keeps every snapshot value', () {
      final order = _order(staff: false);
      expect(order.financialAccess, MerchantFinancialAccess.granted);
      expect(order.financeRestricted, isFalse);
      expect(order.financial.merchantNetAmountMinor, '1116');
      expect(order.financial.merchantCommissionAmountMinor, '84');
      expect(order.financial.merchantCommissionRateBps, 700);
      expect(order.financial.merchantDiscountMinor, '0');
    });

    test('ROLE_RESTRICTED parses missing values as null, never zero', () {
      final order = _order(staff: true);
      expect(order.financialAccess, MerchantFinancialAccess.restricted);
      expect(order.financeRestricted, isTrue);
      expect(order.financial.merchantNetAmountMinor, isNull);
      expect(order.financial.merchantCommissionAmountMinor, isNull);
      expect(order.financial.merchantCommissionRateBps, isNull);
      expect(order.financial.merchantDiscountMinor, isNull);
      expect(order.financial.grossMerchandiseSubtotalMinor, '1200');
      expect(order.financial.deliveryFeeMinor, '500');
      expect(order.items.single.lineTotalMinor, '1200');
    });

    test('ROLE_RESTRICTED drops finance keys even if a server sends them', () {
      final json = _orderJson(staff: false)
        ..['financialAccess'] = 'ROLE_RESTRICTED';
      final order = MerchantOrderDetail.fromJson(json);
      expect(order.financial.merchantNetAmountMinor, isNull);
      expect(order.financial.merchantCommissionRateBps, isNull);
      expect(order.financial.grossMerchandiseSubtotalMinor, '1200');
    });

    test('absent financial block stays null instead of zero', () {
      final json = _orderJson(staff: false)..remove('financial');
      final order = MerchantOrderSummary.fromJson(json);
      expect(order.financial.grossMerchandiseSubtotalMinor, isNull);
      expect(order.financial.merchantNetAmountMinor, isNull);
      expect(order.financial.deliveryFeeMinor, isNull);
    });

    test('list pages carry per-item access', () {
      final page = MerchantOrderListPage.fromJson({
        'items': [_orderJson(staff: true)],
        'limit': 20,
        'offset': 0,
        'total': 1,
      });
      expect(page.items.single.financeRestricted, isTrue);
      expect(page.items.single.financial.merchantNetAmountMinor, isNull);
    });

    test('incoming alert keeps a missing subtotal as null', () {
      final json = _orderJson(staff: true);
      (json['financial'] as Map).remove('grossMerchandiseSubtotalMinor');
      final alert = IncomingOrderAlert.fromDetail(
        detail: MerchantOrderDetail.fromJson(json),
        notificationId: 'n-1',
      );
      expect(alert.merchandiseSubtotalMinor, isNull);
    });

    test('restricted sales summary never exposes finance values', () {
      final json = populatedSummaryJson()..['financeAccess'] = 'ROLE_RESTRICTED';
      final summary = MerchantSalesSummary.fromJson(json);
      expect(summary.financeGranted, isFalse);
      expect(summary.finance, isNull);
      expect(summary.grossMerchandiseMinor, '4230000');
    });
  });

  group('order detail presentation', () {
    testWidgets('OWNER sees commission and merchant net', (tester) async {
      final harness = _Harness(role: 'OWNER');
      await harness.pumpOrder(tester);
      expect(find.text(_gross), findsWidgets);
      expect(find.text(_ownerNet), findsOneWidget);
      expect(find.text(_ownerCommission), findsOneWidget);
      expect(find.byKey(const Key('order-finance-restricted')), findsNothing);
      expect(find.byKey(const Key('order-accept')), findsOneWidget);
    });

    testWidgets('STAFF sees sales and items, no finance and no zeros', (
      tester,
    ) async {
      final harness = _Harness(role: 'STAFF');
      await harness.pumpOrder(tester);
      expect(find.text(_gross), findsWidgets);
      expect(find.text('Café'), findsOneWidget);
      expect(find.byKey(const Key('order-finance-restricted')), findsOneWidget);
      expect(find.text(AppStrings.orderFinanceNet), findsNothing);
      expect(find.textContaining('Commission SpeedyGo'), findsNothing);
      expect(find.text(AppStrings.orderFinanceDiscount), findsNothing);
      expect(find.text('0 DZD'), findsNothing);
      expect(find.text(_ownerNet), findsNothing);
      // Existing STAFF behaviour: read-only, no workflow actions offered.
      expect(find.byKey(const Key('order-accept')), findsNothing);
      expect(find.byKey(const Key('order-reject')), findsNothing);
    });

    testWidgets('owner finance is not shown after switching to STAFF role', (
      tester,
    ) async {
      final harness = _Harness(role: 'OWNER');
      await harness.pumpOrder(tester);
      expect(find.text(_ownerNet), findsOneWidget);

      harness.gateStaff();
      harness.access.switchTo(_member('STAFF'));
      await tester.pump();
      expect(find.text(_ownerNet), findsNothing);
      expect(find.text(_ownerCommission), findsNothing);

      harness.releaseStaff();
      await tester.pumpAndSettle();
      expect(find.text(_ownerNet), findsNothing);
      expect(find.byKey(const Key('order-finance-restricted')), findsOneWidget);
      expect(harness.orderRoles, ['OWNER', 'STAFF']);
    });

    testWidgets('owner finance is not shown after switching account', (
      tester,
    ) async {
      final harness = _Harness(role: 'OWNER');
      await harness.pumpOrder(tester);
      expect(find.text(_ownerNet), findsOneWidget);

      harness.gateStaff();
      harness.role = 'STAFF';
      harness.session.switchAccount('a-staff');
      harness.access.switchTo(_member('STAFF'));
      await tester.pump();
      expect(find.text(_ownerNet), findsNothing);

      harness.releaseStaff();
      await tester.pumpAndSettle();
      expect(find.text(_ownerNet), findsNothing);
      expect(find.byKey(const Key('order-finance-restricted')), findsOneWidget);
    });
  });

  group('reports cache', () {
    testWidgets('owner commission/net are not shown after switching to STAFF', (
      tester,
    ) async {
      final harness = _Harness(role: 'OWNER');
      await harness.pumpReports(tester);
      expect(find.text('39 339 DZD'), findsOneWidget);
      expect(find.text('Commission SpeedyGo (7%)'), findsOneWidget);

      harness.gateStaff();
      harness.access.switchTo(_member('STAFF'));
      await tester.pump();
      expect(find.text('39 339 DZD'), findsNothing);
      expect(find.text('Commission SpeedyGo (7%)'), findsNothing);

      harness.releaseStaff();
      await tester.pumpAndSettle();
      expect(find.text('39 339 DZD'), findsNothing);
      expect(find.text(AppStrings.reportsFinanceRestricted), findsOneWidget);
      expect(find.text('42 300 DZD'), findsOneWidget);
      expect(harness.summaryRoles, ['OWNER', 'STAFF']);
    });
  });
}

/// Fake backend that answers with the projection for the current role, and
/// can hold the STAFF response to observe the in-between frames.
class _Harness {
  _Harness({required this.role})
    : access = _SwitchableAccess(_member(role), _branch),
      session = _SwitchableSession();

  String role;
  final _SwitchableAccess access;
  final _SwitchableSession session;
  final orderRoles = <String>[];
  final summaryRoles = <String>[];
  Completer<void>? _staffGate;

  void gateStaff() => _staffGate = Completer<void>();
  void releaseStaff() => _staffGate?.complete();

  String get _currentRole => access.state.membership?.role ?? role;

  Future<void> _waitIfStaff(String current) async {
    if (current == 'STAFF' && _staffGate != null) await _staffGate!.future;
  }

  late final FakeMerchantApi api = FakeMerchantApi(
    orderDetailHandler: ({required merchantId, required orderId}) async {
      final current = _currentRole;
      orderRoles.add(current);
      await _waitIfStaff(current);
      return _order(staff: current == 'STAFF');
    },
    salesSummaryHandler: ({required merchantId, required period, branchId}) async {
      final current = _currentRole;
      summaryRoles.add(current);
      await _waitIfStaff(current);
      return MerchantSalesSummary.fromJson(
        populatedSummaryJson(staff: current == 'STAFF'),
      );
    },
    topProductsHandler:
        ({
          required merchantId,
          required period,
          branchId,
          required sort,
          required limit,
        }) async => MerchantTopProducts.fromJson(populatedTopJson(limit: limit)),
  );

  List<Override> get _overrides => [
    merchantApiProvider.overrideWithValue(api),
    sessionStoreProvider.overrideWithValue(MemorySessionStore()),
    contextStoreProvider.overrideWithValue(MemoryContextStore()),
    sessionControllerProvider.overrideWith(() => session),
    accessControllerProvider.overrideWith(() => access),
    reportsControllerProvider.overrideWith(() => _SeedReports()),
  ];

  Future<void> pumpOrder(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: _overrides,
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const OrderDetailScreen(orderId: 'o-1'),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> pumpReports(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: _overrides,
        child: MaterialApp(theme: AppTheme.light(), home: const ReportsScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }
}

class _SwitchableSession extends SessionController {
  @override
  SessionState build() =>
      const SessionState(phase: SessionPhase.ready, accountId: 'a-owner');

  void switchAccount(String accountId) =>
      state = SessionState(phase: SessionPhase.ready, accountId: accountId);
}

class _SwitchableAccess extends AccessController {
  _SwitchableAccess(this.initial, this.branch);
  final MerchantMembership initial;
  final MerchantBranch branch;

  @override
  AccessState build() => AccessState(
    destination: AccessDestination.home,
    membership: initial,
    selectedBranch: branch,
  );

  void switchTo(MerchantMembership membership) => state = AccessState(
    destination: AccessDestination.home,
    membership: membership,
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
