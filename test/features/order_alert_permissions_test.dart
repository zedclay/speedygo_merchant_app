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
import 'package:speedygo_merchant_app/features/notifications/application/merchant_push_controller.dart';
import 'package:speedygo_merchant_app/features/notifications/application/order_alert_controller.dart';
import 'package:speedygo_merchant_app/features/notifications/domain/incoming_order_alert.dart';
import 'package:speedygo_merchant_app/features/notifications/presentation/incoming_order_alert_overlay.dart';
import 'package:speedygo_merchant_app/features/notifications/presentation/merchant_alert_host.dart';
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

const _pendingAlert = IncomingOrderAlert(
  orderId: 'o-1',
  notificationId: 'n-1',
  publicReference: 'sgo_o1',
  customerLabel: 'Client Test',
  itemCount: 2,
  merchandiseSubtotalMinor: 1200,
  paymentMethod: 'COD',
  createdAt: '2026-01-01T10:00:00.000+01:00',
  branchId: 'b-1',
  fulfillmentStatus: 'PENDING_ACCEPTANCE',
  orderStatus: 'CREATED',
);

final _refuse = find.byKey(const Key('incoming-alert-refuse'));
final _details = find.byKey(const Key('incoming-alert-details'));
final _alert = find.byKey(const Key('incoming-order-alert'));

MerchantMembership _member(String role) =>
    membership(role: role, branches: [_branch]);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('workflow permission mirrors backend ORDER_WORKFLOW_MUTATE', () {
    expect(merchantRoleCanMutateOrders('OWNER'), isTrue);
    expect(merchantRoleCanMutateOrders('MANAGER'), isTrue);
    expect(merchantRoleCanMutateOrders('STAFF'), isFalse);
    expect(merchantRoleCanMutateOrders(null), isFalse);
    expect(merchantRoleCanMutateOrders('AUDITOR'), isFalse);
  });

  group('incoming order alert actions', () {
    testWidgets('overlay without a refuse callback renders no refuse action', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: IncomingOrderAlertOverlay(
            alert: _pendingAlert,
            onViewDetails: () {},
            onRefuse: null,
            onDismiss: () {},
          ),
        ),
      );
      expect(_refuse, findsNothing);
      expect(find.text(AppStrings.alertRefuse), findsNothing);
      expect(_details, findsOneWidget);
    });

    testWidgets('STAFF sees the alert and view action, never refuse', (
      tester,
    ) async {
      final h = _HostHarness(role: 'STAFF');
      await h.pump(tester);
      expect(_alert, findsOneWidget);
      expect(_refuse, findsNothing);
      expect(find.text(AppStrings.alertRefuse), findsNothing);
      expect(_details, findsOneWidget);
      expect(_enabled(tester, _details), isTrue);
    });

    for (final role in ['OWNER', 'MANAGER']) {
      testWidgets('$role keeps refuse and view actions', (tester) async {
        final h = _HostHarness(role: role);
        await h.pump(tester);
        expect(_refuse, findsOneWidget);
        expect(_enabled(tester, _refuse), isTrue);
        expect(_details, findsOneWidget);
      });
    }

    testWidgets('role change updates an already-open alert', (tester) async {
      final h = _HostHarness(role: 'OWNER');
      await h.pump(tester);
      expect(_refuse, findsOneWidget);

      h.access.switchTo(_member('STAFF'));
      await tester.pump();
      expect(_alert, findsOneWidget);
      expect(_refuse, findsNothing);
      expect(_details, findsOneWidget);

      h.access.switchTo(_member('MANAGER'));
      await tester.pump();
      expect(_refuse, findsOneWidget);
    });

    testWidgets('sign-out clears an already-open alert', (tester) async {
      final h = _HostHarness(role: 'OWNER');
      await h.pump(tester);
      expect(_alert, findsOneWidget);

      h.session.signOut();
      await tester.pump();
      expect(_alert, findsNothing);
      expect(_refuse, findsNothing);
    });

    testWidgets('account switch clears the previous account alert', (
      tester,
    ) async {
      final h = _HostHarness(role: 'OWNER');
      await h.pump(tester);
      expect(_alert, findsOneWidget);

      h.session.switchAccount('a-staff');
      h.access.switchTo(_member('STAFF'));
      await tester.pump();
      expect(_alert, findsNothing);
      expect(_refuse, findsNothing);
    });

    testWidgets('above the navigator (app builder) the alert builds and '
        'dismisses', (tester) async {
      final h = _HostHarness(role: 'OWNER', inAppBuilder: true);
      await h.pump(tester);
      expect(tester.takeException(), isNull);
      expect(_alert, findsOneWidget);
      final dismiss = find.byKey(const Key('incoming-alert-dismiss'));
      expect(
        find.descendant(of: dismiss, matching: find.byType(Tooltip)),
        findsOneWidget,
      );

      await tester.tap(dismiss);
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(_alert, findsNothing);
      expect(find.text('shell'), findsOneWidget);
    });
  });

  group('order detail preparation-estimate action', () {
    for (final (role, visible) in [
      ('OWNER', true),
      ('MANAGER', true),
      ('STAFF', false),
    ]) {
      testWidgets('$role ${visible ? 'can' : 'cannot'} open update-prep', (
        tester,
      ) async {
        await _pumpPreparingDetail(tester, role);
        expect(
          find.byKey(const Key('prep-countdown-banner')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('prep-update-open')),
          visible ? findsOneWidget : findsNothing,
        );
        expect(find.byKey(const Key('order-start-prep')), findsNothing);
        expect(
          find.byKey(const Key('order-mark-ready')),
          visible ? findsOneWidget : findsNothing,
        );
        await tester.pumpWidget(const SizedBox.shrink());
      });
    }
  });
}

bool _enabled(WidgetTester tester, Finder finder) {
  return tester.widget<ButtonStyleButton>(finder).onPressed != null;
}

Future<void> _pumpPreparingDetail(WidgetTester tester, String role) async {
  final readyAt = DateTime.now().toUtc().add(const Duration(minutes: 20));
  final api = FakeMerchantApi(
    orderDetailHandler: ({required merchantId, required orderId}) async =>
        MerchantOrderDetail.fromJson({
          'id': 'o-1',
          'publicReference': 'sgo_o1',
          'status': 'ACTIVE',
          'fulfillmentStatus': 'PREPARING',
          'merchantBranchId': 'b-1',
          'createdAt': '2026-01-01T10:00:00Z',
          'confirmedAt': '2026-01-01T10:01:00Z',
          'customerFullName': 'Client Test',
          'payment': {'method': 'COD', 'status': 'PENDING'},
          'financialAccess': role == 'STAFF' ? 'ROLE_RESTRICTED' : 'GRANTED',
          'financial': {
            'currency': 'DZD',
            'grossMerchandiseSubtotalMinor': '1200',
            'deliveryFeeMinor': '500',
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
        }),
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        merchantApiProvider.overrideWithValue(api),
        sessionStoreProvider.overrideWithValue(MemorySessionStore()),
        contextStoreProvider.overrideWithValue(MemoryContextStore()),
        sessionControllerProvider.overrideWith(_SwitchableSession.new),
        accessControllerProvider.overrideWith(
          () => _SwitchableAccess(_member(role)),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.light(),
        home: const OrderDetailScreen(orderId: 'o-1'),
      ),
    ),
  );
  // The countdown banner ticks, so settle by bounded pumps.
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Real [MerchantAlertHost] and real [OrderAlertController] session/branch
/// listeners, with one alert already open and network polling disabled.
/// [inAppBuilder] mounts the host in `MaterialApp.builder`, above the
/// navigator and its overlay, as `SpeedyGoApp` does.
class _HostHarness {
  _HostHarness({required String role, this.inAppBuilder = false})
    : access = _SwitchableAccess(_member(role)),
      session = _SwitchableSession();

  final _SwitchableAccess access;
  final _SwitchableSession session;
  final bool inAppBuilder;

  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          merchantApiProvider.overrideWithValue(FakeMerchantApi()),
          sessionStoreProvider.overrideWithValue(MemorySessionStore()),
          contextStoreProvider.overrideWithValue(MemoryContextStore()),
          sessionControllerProvider.overrideWith(() => session),
          accessControllerProvider.overrideWith(() => access),
          merchantPushControllerProvider.overrideWith(_IdlePush.new),
          orderAlertControllerProvider.overrideWith(_OpenAlert.new),
        ],
        child: inAppBuilder
            ? MaterialApp(
                theme: AppTheme.light(),
                builder: (context, child) =>
                    MerchantAlertHost(child: child ?? const SizedBox.shrink()),
                home: const Scaffold(body: Text('shell')),
              )
            : MaterialApp(
                theme: AppTheme.light(),
                home: const MerchantAlertHost(
                  child: Scaffold(body: Text('shell')),
                ),
              ),
      ),
    );
    await tester.pump();
  }
}

class _OpenAlert extends OrderAlertController {
  @override
  OrderAlertState build() {
    super.build();
    return const OrderAlertState(activeAlert: _pendingAlert);
  }

  @override
  Future<void> start() async {}
}

class _IdlePush extends MerchantPushController {
  @override
  MerchantPushState build() => const MerchantPushState();

  @override
  void onSessionChanged(SessionState? prev, SessionState next) {}

  @override
  Future<void> syncRegistration({bool prompt = false}) async {}
}

class _SwitchableSession extends SessionController {
  @override
  SessionState build() =>
      const SessionState(phase: SessionPhase.ready, accountId: 'a-owner');

  void switchAccount(String accountId) =>
      state = SessionState(phase: SessionPhase.ready, accountId: accountId);

  void signOut() => state = const SessionState(phase: SessionPhase.signedOut);
}

class _SwitchableAccess extends AccessController {
  _SwitchableAccess(this.initial);
  final MerchantMembership initial;

  @override
  AccessState build() => AccessState(
    destination: AccessDestination.home,
    membership: initial,
    selectedBranch: _branch,
  );

  void switchTo(MerchantMembership membership) => state = AccessState(
    destination: AccessDestination.home,
    membership: membership,
    selectedBranch: _branch,
  );
}
