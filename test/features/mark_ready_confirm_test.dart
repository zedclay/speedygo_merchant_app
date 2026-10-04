import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
import 'package:speedygo_merchant_app/features/orders/presentation/order_detail_screen.dart';

import 'phase1_flow_test.dart';

const _branch = MerchantBranch(
  id: 'b-1',
  name: 'Branche test',
  phone: '0550000000',
  addressText: 'Centre',
  latitude: 36.7,
  longitude: 3.0,
  operationalStatus: 'ACTIVE',
);

MerchantOrderDetail _preparing() {
  final readyAt = DateTime.now().toUtc().add(const Duration(minutes: 20));
  return MerchantOrderDetail.fromJson({
    'id': 'o-1',
    'publicReference': 'sgo_01a0e8dc8a8f',
    'status': 'ACTIVE',
    'fulfillmentStatus': 'PREPARING',
    'merchantBranchId': 'b-1',
    'createdAt': '2026-01-01T10:00:00Z',
    'confirmedAt': '2026-01-01T10:01:00Z',
    'customerFullName': 'Client Test',
    'payment': {'method': 'COD', 'status': 'PENDING'},
    'financialAccess': 'GRANTED',
    'financial': {
      'currency': 'DZD',
      'grossMerchandiseSubtotalMinor': '330000',
      'deliveryFeeMinor': '50000',
    },
    'preparationMinutes': 20,
    'originalPreparationMinutes': 20,
    'estimatedReadyAt': readyAt.toIso8601String(),
    'originalEstimatedReadyAt': readyAt.toIso8601String(),
    'preparationEstimateVersion': 1,
    'isPreparationLate': false,
    'items': [
      {
        'id': 'i-1',
        'productId': 'p-1',
        'productNameSnapshot': 'Couscous royal',
        'quantity': 1,
        'unitPriceMinor': '180000',
        'lineTotalMinor': '200000',
        'options': [
          {'optionNameSnapshot': 'Grande', 'additionalPriceMinor': '20000'},
        ],
      },
      {
        'id': 'i-2',
        'productId': 'p-2',
        'productNameSnapshot': 'Pain maison',
        'quantity': 2,
        'unitPriceMinor': '65000',
        'lineTotalMinor': '130000',
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
  });
}

class _Session extends SessionController {
  @override
  SessionState build() =>
      const SessionState(phase: SessionPhase.ready, accountId: 'a-owner');
}

class _Access extends AccessController {
  @override
  AccessState build() => AccessState(
        destination: AccessDestination.home,
        membership: membership(role: 'OWNER', branches: [_branch]),
        selectedBranch: _branch,
      );
}

Future<FakeMerchantApi> _pump(
  WidgetTester tester, {
  Size size = const Size(390, 844),
  double textScale = 1.0,
}) async {
  tester.view.physicalSize = size * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final api = FakeMerchantApi(
    orderDetailHandler: ({required merchantId, required orderId}) async =>
        _preparing(),
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        merchantApiProvider.overrideWithValue(api),
        sessionStoreProvider.overrideWithValue(MemorySessionStore()),
        contextStoreProvider.overrideWithValue(MemoryContextStore()),
        sessionControllerProvider.overrideWith(_Session.new),
        accessControllerProvider.overrideWith(_Access.new),
      ],
      child: MaterialApp(
        theme: AppTheme.light(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
          ),
          child: child!,
        ),
        home: const OrderDetailScreen(orderId: 'o-1'),
      ),
    ),
  );
  await _settle(tester);
  return api;
}

Future<void> _settle(WidgetTester tester) async {
  // The preparation countdown ticks, so settle by bounded pumps.
  for (var i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _openConfirm(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('order-mark-ready')));
  await _settle(tester);
  await tester.pump(const Duration(milliseconds: 400));
  await _settle(tester);
}

void main() {
  testWidgets('mark ready opens the packing list without mutating', (
    tester,
  ) async {
    final api = await _pump(tester);
    await _openConfirm(tester);

    expect(
      find.byKey(const Key('order-mark-ready-confirm-screen')),
      findsOneWidget,
    );
    expect(find.text('#sgo_01a0e8dc8a8f'), findsOneWidget);
    expect(find.text(AppStrings.orderFulfillmentPreparing), findsOneWidget);
    expect(find.text(AppStrings.markReadyPackingTitle), findsOneWidget);
    expect(find.text('3 articles'), findsOneWidget);
    expect(find.text('1× Couscous royal'), findsOneWidget);
    expect(find.text('· Grande'), findsOneWidget);
    expect(find.text('2× Pain maison'), findsOneWidget);
    // Only the order's own items; no invented rows, note or gating ticks.
    expect(find.textContaining('Couverts'), findsNothing);
    expect(find.textContaining('Note'), findsNothing);
    expect(find.byType(Checkbox), findsNothing);
    final confirm = tester.widget<ButtonStyleButton>(
      find.descendant(
        of: find.byKey(const Key('order-mark-ready-confirm')),
        matching: find.byWidgetPredicate((w) => w is ButtonStyleButton),
      ),
    );
    expect(confirm.onPressed, isNotNull);
    expect(api.mutationCalls, isEmpty);
  });

  testWidgets('Retour returns to the detail without marking ready', (
    tester,
  ) async {
    final api = await _pump(tester);
    await _openConfirm(tester);
    await tester.tap(find.byKey(const Key('order-mark-ready-back')));
    await _settle(tester);
    await tester.pump(const Duration(milliseconds: 400));

    expect(
      find.byKey(const Key('order-mark-ready-confirm-screen')),
      findsNothing,
    );
    expect(find.byKey(const Key('order-mark-ready')), findsOneWidget);
    expect(api.mutationCalls, isEmpty);
  });

  testWidgets('confirming marks the order ready once', (tester) async {
    final api = await _pump(tester);
    await _openConfirm(tester);
    await tester.tap(find.byKey(const Key('order-mark-ready-confirm')));
    await _settle(tester);
    await tester.pump(const Duration(milliseconds: 400));
    await _settle(tester);

    expect(api.mutationCalls, ['ready:o-1']);
    expect(
      find.byKey(const Key('order-mark-ready-confirm-screen')),
      findsNothing,
    );
    expect(find.byKey(const Key('order-mark-ready')), findsNothing);
  });

  testWidgets('375 pt at text 1.35: no overflow, both actions reachable', (
    tester,
  ) async {
    await _pump(tester, size: const Size(375, 667), textScale: 1.35);
    await _openConfirm(tester);

    expect(tester.takeException(), isNull);
    final packing = tester.getRect(
      find.byKey(const Key('order-mark-ready-packing')),
    );
    expect(packing.height, greaterThan(100));
    expect(find.text('2× Pain maison'), findsOneWidget);
    for (final key in ['order-mark-ready-confirm', 'order-mark-ready-back']) {
      final rect = tester.getRect(find.byKey(Key(key)));
      expect(rect.left, greaterThanOrEqualTo(0));
      expect(rect.right, lessThanOrEqualTo(375));
      expect(rect.bottom, lessThanOrEqualTo(667));
    }
    expect(find.text(AppStrings.markReadyConfirm), findsOneWidget);
  });
}
