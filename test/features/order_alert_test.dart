import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speedygo_merchant_app/core/storage/session_store.dart';
import 'package:speedygo_merchant_app/features/access/application/access_controller.dart';
import 'package:speedygo_merchant_app/features/access/data/models.dart';
import 'package:speedygo_merchant_app/features/auth/application/auth_infrastructure.dart';
import 'package:speedygo_merchant_app/features/auth/application/session_controller.dart';
import 'package:speedygo_merchant_app/features/auth/application/session_providers.dart';
import 'package:speedygo_merchant_app/features/auth/application/session_state.dart';
import 'package:speedygo_merchant_app/features/notifications/application/order_alert_controller.dart';
import 'package:speedygo_merchant_app/features/notifications/domain/incoming_order_alert.dart';
import 'package:speedygo_merchant_app/features/store/data/store_models.dart';

import 'phase1_flow_test.dart';

class _ReadySession extends SessionController {
  @override
  SessionState build() => const SessionState(
        phase: SessionPhase.ready,
        accountId: 'a-fixture',
      );
}

class _ReadyAccess extends AccessController {
  _ReadyAccess(this.mem, this.branch);
  final MerchantMembership mem;
  final MerchantBranch branch;

  @override
  AccessState build() => AccessState(
        destination: AccessDestination.home,
        membership: mem,
        selectedBranch: branch,
      );
}

void main() {
  test('notification item parses type and sourceId from API fields', () {
    final item = MerchantNotificationItem.fromJson({
      'id': 'n1',
      'title': 'Nouvelle commande',
      'body': 'Une nouvelle commande sgo_x nécessite votre attention.',
      'read': false,
      'createdAt': '2026-09-25T04:00:00.000Z',
      'type': 'MERCHANT_ORDER_CREATED',
      'sourceId': '01a0d695-92e0-7c55-8569-e0e5cdc856d2',
    });
    expect(item.type, 'MERCHANT_ORDER_CREATED');
    expect(item.sourceId, '01a0d695-92e0-7c55-8569-e0e5cdc856d2');
  });

  test('notification item parses category when sourceId omitted', () {
    final item = MerchantNotificationItem.fromJson({
      'id': 'n2',
      'title': 'Nouvelle commande',
      'body': 'x',
      'read': false,
      'createdAt': '2026-09-25T04:00:00.000Z',
      'category': 'MERCHANT_ORDER_CREATED:abc-order-id',
    });
    expect(item.type, 'MERCHANT_ORDER_CREATED');
    expect(item.sourceId, 'abc-order-id');
  });

  test('incoming alert stillIncoming requires PENDING_ACCEPTANCE', () {
    const alert = IncomingOrderAlert(
      orderId: 'o1',
      notificationId: 'n1',
      publicReference: 'sgo_1',
      customerLabel: 'Client',
      itemCount: 1,
      merchandiseSubtotalMinor: 45000,
      paymentMethod: 'COD',
      createdAt: '2026-09-25T04:00:00.000+01:00',
      branchId: 'b1',
      fulfillmentStatus: 'ACCEPTED',
      orderStatus: 'CONFIRMED',
    );
    expect(alert.isStillIncoming, isFalse);
  });

  test('pending acceptance is still incoming', () {
    const pending = IncomingOrderAlert(
      orderId: 'o2',
      notificationId: 'n2',
      publicReference: 'sgo_2',
      customerLabel: 'Client',
      itemCount: 1,
      merchandiseSubtotalMinor: 100,
      paymentMethod: 'COD',
      createdAt: '2026-09-25T04:00:00.000+01:00',
      branchId: 'b1',
      fulfillmentStatus: 'PENDING_ACCEPTANCE',
      orderStatus: 'CREATED',
    );
    expect(pending.isStillIncoming, isTrue);
  });

  test('poll interval is documented 8 seconds', () {
    expect(kMerchantOrderAlertPollInterval, const Duration(seconds: 8));
  });

  test('offline gate env name is stable for harness', () {
    expect(kAlertOfflineGateEnv, 'ALERT_OFFLINE_GATE');
  });

  testWidgets(
      'unreadable local preferences do not disable the new-order poll',
      (tester) async {
    const prefsChannel = MethodChannel('plugins.flutter.io/shared_preferences');
    SharedPreferences.resetStatic();
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(prefsChannel, (call) async {
      throw PlatformException(code: 'storage', message: 'unreadable');
    });
    addTearDown(() => messenger.setMockMethodCallHandler(prefsChannel, null));
    const branch = MerchantBranch(
      id: 'b-1',
      name: 'Fixture Café',
      phone: '0550000000',
      addressText: '12 Rue Test',
      latitude: 36.75,
      longitude: 3.05,
      operationalStatus: 'ACTIVE',
    );
    var polls = 0;
    final api = FakeMerchantApi()
      ..notificationsHandler = () async {
        polls++;
        return const [];
      };
    final container = ProviderContainer(
      overrides: [
        merchantApiProvider.overrideWithValue(api),
        sessionStoreProvider.overrideWithValue(MemorySessionStore()),
        contextStoreProvider.overrideWithValue(MemoryContextStore()),
        sessionControllerProvider.overrideWith(_ReadySession.new),
        accessControllerProvider.overrideWith(
          () => _ReadyAccess(membership(branches: [branch]), branch),
        ),
      ],
    );

    await container.read(orderAlertControllerProvider.notifier).start();
    expect(polls, 1);

    await tester.pump(kMerchantOrderAlertPollInterval);
    await tester.pump();
    expect(polls, 2);

    container.dispose();
  });

  group('start() interrupted while preferences load', () {
    const prefsChannel = MethodChannel('plugins.flutter.io/shared_preferences');
    const branch = MerchantBranch(
      id: 'b-1',
      name: 'Fixture Café',
      phone: '0550000000',
      addressText: '12 Rue Test',
      latitude: 36.75,
      longitude: 3.05,
      operationalStatus: 'ACTIVE',
    );

    ({ProviderContainer container, Completer<void> prefsGate, int Function() polls})
        harness() {
      SharedPreferences.resetStatic();
      final gate = Completer<void>();
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(prefsChannel, (call) async {
        await gate.future;
        return <String, Object>{};
      });
      addTearDown(() => messenger.setMockMethodCallHandler(prefsChannel, null));
      var polls = 0;
      final api = FakeMerchantApi()
        ..notificationsHandler = () async {
          polls++;
          return const [];
        };
      final container = ProviderContainer(
        overrides: [
          merchantApiProvider.overrideWithValue(api),
          sessionStoreProvider.overrideWithValue(MemorySessionStore()),
          contextStoreProvider.overrideWithValue(MemoryContextStore()),
          sessionControllerProvider.overrideWith(_ReadySession.new),
          accessControllerProvider.overrideWith(
            () => _ReadyAccess(membership(branches: [branch]), branch),
          ),
        ],
      );
      return (container: container, prefsGate: gate, polls: () => polls);
    }

    testWidgets('disposal leaves no poll timer and no use of a disposed ref',
        (tester) async {
      final h = harness();
      final pending =
          h.container.read(orderAlertControllerProvider.notifier).start();
      await tester.pump();
      h.container.dispose();
      h.prefsGate.complete();
      await pending;
      await tester.pump(kMerchantOrderAlertPollInterval * 2);
      expect(h.polls(), 0);
      expect(tester.takeException(), isNull);
    });

    testWidgets('stop() (logout) prevents the poll from starting',
        (tester) async {
      final h = harness();
      final alerts = h.container.read(orderAlertControllerProvider.notifier);
      final pending = alerts.start();
      await tester.pump();
      alerts.stop();
      h.prefsGate.complete();
      await pending;
      await tester.pump(kMerchantOrderAlertPollInterval * 2);
      expect(h.polls(), 0);
      h.container.dispose();
    });
  });
}
