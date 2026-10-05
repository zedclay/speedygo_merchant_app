import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speedygo_merchant_app/core/constants/app_strings.dart';
import 'package:speedygo_merchant_app/features/access/data/models.dart';
import 'package:speedygo_merchant_app/features/notifications/application/merchant_push_controller.dart';
import 'package:speedygo_merchant_app/features/notifications/data/push_messaging_gateway.dart';
import 'package:speedygo_merchant_app/features/notifications/presentation/notification_settings_screen.dart';
import 'package:speedygo_merchant_app/features/shell/logout_screen.dart';
import 'package:speedygo_merchant_app/features/shell/profile_settings_screen.dart';
import 'package:speedygo_merchant_app/features/store/application/store_controllers.dart';
import 'package:speedygo_merchant_app/features/store/data/store_models.dart';
import 'package:speedygo_merchant_app/features/store/presentation/notifications_screen.dart';
import 'package:speedygo_merchant_app/features/support/data/support_models.dart';
import 'package:speedygo_merchant_app/features/support/presentation/support_center_screen.dart';
import 'package:speedygo_merchant_app/features/support/presentation/support_ticket_screen.dart';

import '../../features/phase1_flow_test.dart';
import 'parity_harness.dart';

/// Fixed clock: 30 Sep 2026, 13:00 Algiers (12:00 UTC).
final _now = DateTime.utc(2026, 9, 30, 12);

class _StubPush extends MerchantPushController {
  _StubPush(this.initial);
  final MerchantPushState initial;

  @override
  MerchantPushState build() => initial;

  @override
  Future<void> syncRegistration({bool prompt = false}) async {}
}

const _permissions = MethodChannel('flutter.baseflow.com/permissions/methods');
const _granted = 1;

BranchAvailabilityState _availability({required bool open}) =>
    BranchAvailabilityState(
      branchId: 'b1',
      timezone: 'Africa/Algiers',
      availabilityMode: 'FOLLOW_SCHEDULE',
      effectiveMode: 'FOLLOW_SCHEDULE',
      hoursConfigured: true,
      isOpenNow: open,
      acceptingOrders: open,
      temporaryExpired: false,
      outsideWeeklyHours: !open,
      reasonCode: null,
      customerMessage: null,
      closedUntil: null,
      nextOpenAt: null,
      currentClosesAt: null,
      version: null,
      updatedAt: null,
    );

MerchantOrderListPage _page(int total) =>
    MerchantOrderListPage(items: const [], total: total, limit: 50, offset: 0);

SupportTicketSummary _ticket(
  String id,
  String ref,
  SupportTicketStatus status, {
  String? orderId,
  required DateTime updatedAt,
}) => SupportTicketSummary(
  id: id,
  publicReference: ref,
  status: status,
  orderId: orderId,
  createdAt: updatedAt.subtract(const Duration(hours: 3)),
  updatedAt: updatedAt,
);

final _tickets = SupportTicketPage(
  items: [
    _ticket(
      't1',
      'sgt_8f2a41',
      SupportTicketStatus.inProgress,
      orderId: 'o1',
      updatedAt: _now.subtract(const Duration(minutes: 25)),
    ),
    _ticket(
      't2',
      'sgt_5c19e0',
      SupportTicketStatus.open,
      updatedAt: _now.subtract(const Duration(hours: 2)),
    ),
    _ticket(
      't3',
      'sgt_2b7d93',
      SupportTicketStatus.resolved,
      updatedAt: DateTime.utc(2026, 9, 24, 9),
    ),
  ],
  total: 3,
);

SupportTicketDetail _detail(SupportTicketStatus status) => SupportTicketDetail(
  summary: _ticket(
    't1',
    'sgt_8f2a41',
    status,
    orderId: 'o1',
    updatedAt: _now.subtract(const Duration(minutes: 25)),
  ),
  createdByAccountId: 'acc-1',
  orderPublicReference: 'sgo_4a7c21',
  messages: [
    SupportMessage(
      id: 'm1',
      authorAccountId: 'acc-1',
      body:
          'Le livreur est arrivé mais la commande a été récupérée '
          'par un autre livreur.',
      createdAt: _now.subtract(const Duration(hours: 3)),
      displayName: null,
    ),
    SupportMessage(
      id: 'm2',
      authorAccountId: 'ops-9',
      body: 'Merci, nous vérifions avec l’équipe de livraison.',
      createdAt: _now.subtract(const Duration(minutes: 25)),
      displayName: 'Support SpeedyGo',
    ),
  ],
);

final _notifications = [
  MerchantNotificationItem(
    id: 'n1',
    type: 'MERCHANT_ORDER_CREATED',
    sourceId: 'o1',
    title: 'Nouvelle commande',
    body: 'Commande sgo_4a7c21 reçue.',
    read: false,
    createdAt: _now.subtract(const Duration(minutes: 2)).toIso8601String(),
  ),
  MerchantNotificationItem(
    id: 'n2',
    type: 'SETTLEMENT_FINALIZED',
    title: 'Relevé finalisé',
    body: 'Votre relevé hebdomadaire est disponible.',
    read: false,
    createdAt: _now.subtract(const Duration(hours: 3)).toIso8601String(),
  ),
  MerchantNotificationItem(
    id: 'n3',
    type: 'MERCHANT_ORDER_CREATED',
    sourceId: 'o0',
    title: 'Nouvelle commande',
    body: 'Commande sgo_19be07 reçue.',
    read: true,
    createdAt: DateTime.utc(2026, 9, 29, 18, 40).toIso8601String(),
  ),
];

FakeMerchantApi _api({
  bool open = true,
  int activeOrders = 3,
  List<MerchantNotificationItem>? notifications,
  SupportTicketPage? tickets,
  SupportTicketStatus ticketStatus = SupportTicketStatus.inProgress,
}) =>
    FakeMerchantApi(
        meHandler: () async => MerchantMe(
          merchantMembershipExists: true,
          memberships: [
            membership(branches: [branch('b1', name: 'Dar El Benna')])
                .parityWith(name: 'Dar El Benna'),
          ],
        ),
        availabilityHandler: ({required merchantId, required branchId}) async =>
            _availability(open: open),
        ordersHandler: ({
          required merchantId,
          branchId,
          orderStatus,
          fulfillmentStatus,
          limit = 50,
          offset = 0,
        }) async => _page(fulfillmentStatus == 'PREPARING' ? activeOrders : 0),
      )
      ..notificationsHandler = (() async => notifications ?? _notifications)
      ..unreadCount = 2
      ..supportListHandler = (({required limit, required offset}) async =>
          tickets ?? _tickets)
      ..supportDetailHandler = ((id) async => _detail(ticketStatus));

const _pushOff = MerchantPushState();

Future<ProviderContainer> _ready(
  FakeMerchantApi api, {
  MerchantPushState push = _pushOff,
}) => parityReady(
  api,
  overrides: [
    storeClockProvider.overrideWithValue(() => _now),
    merchantPushControllerProvider.overrideWith(() => _StubPush(push)),
  ],
);

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_permissions, (call) async {
          if (call.method == 'checkPermissionStatus') return _granted;
          return null;
        });
  });
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_permissions, null);
  });

  group('batch 6 settings captures', () {
    for (final v in parityVariants) {
      testWidgets('settings ${v.suffix}', (tester) async {
        final container = await _ready(_api());
        addTearDown(container.dispose);
        await parityPumpFull(
          tester,
          container: container,
          variant: v,
          child: const ProfileSettingsScreen(),
          pushed: true,
        );
        await parityCapture(tester, 'b6_settings_${v.suffix}');
      });

      testWidgets('logout with warning ${v.suffix}', (tester) async {
        final container = await _ready(_api());
        addTearDown(container.dispose);
        await parityPumpFull(
          tester,
          container: container,
          variant: v,
          child: const LogoutScreen(),
          pushed: true,
        );
        await parityCapture(tester, 'b6_logout_${v.suffix}');
      });

      testWidgets('logout calm ${v.suffix}', (tester) async {
        final container = await _ready(_api(open: false, activeOrders: 0));
        addTearDown(container.dispose);
        await parityPumpFull(
          tester,
          container: container,
          variant: v,
          child: const LogoutScreen(),
          pushed: true,
        );
        await parityCapture(tester, 'b6_logout_calm_${v.suffix}');
      });

      testWidgets('support center ${v.suffix}', (tester) async {
        final container = await _ready(_api());
        addTearDown(container.dispose);
        await parityPumpFull(
          tester,
          container: container,
          variant: v,
          child: const SupportCenterScreen(),
          pushed: true,
        );
        await parityCapture(tester, 'b6_support_${v.suffix}');
      });

      testWidgets('support ticket ${v.suffix}', (tester) async {
        final container = await _ready(_api());
        addTearDown(container.dispose);
        await parityPumpFull(
          tester,
          container: container,
          variant: v,
          child: const SupportTicketScreen(ticketId: 't1'),
          pushed: true,
        );
        await parityCapture(tester, 'b6_support_ticket_${v.suffix}');
      });

      testWidgets('notification center ${v.suffix}', (tester) async {
        final container = await _ready(_api());
        addTearDown(container.dispose);
        await parityPumpFull(
          tester,
          container: container,
          variant: v,
          child: const NotificationsScreen(),
          pushed: true,
        );
        await parityCapture(tester, 'b6_notifications_${v.suffix}');
      });

      testWidgets('notification settings ${v.suffix}', (tester) async {
        final container = await _ready(
          _api(),
          push: const MerchantPushState(
            available: true,
            authorization: PushAuthorization.authorized,
            registration: PushRegistrationStatus.registered,
          ),
        );
        addTearDown(container.dispose);
        await parityPumpFull(
          tester,
          container: container,
          variant: v,
          child: const NotificationSettingsScreen(),
          pushed: true,
        );
        await parityCapture(tester, 'b6_notification_settings_${v.suffix}');
      });
    }
  });

  group('batch 6 behaviour', () {
    Future<ProviderContainer> pump(
      WidgetTester tester,
      Widget child, {
      FakeMerchantApi? api,
    }) async {
      final container = await _ready(api ?? _api());
      addTearDown(container.dispose);
      await parityPumpFull(
        tester,
        container: container,
        variant: parityVariants.first,
        child: child,
        pushed: true,
      );
      return container;
    }

    testWidgets('logout warns only while orders are active or store is open', (
      tester,
    ) async {
      await pump(tester, const LogoutScreen());
      expect(find.byKey(const Key('logout-warning')), findsOneWidget);
      expect(find.byKey(const Key('logout-active-count')), findsOneWidget);
      expect(find.textContaining('3'), findsWidgets);

      await pump(
        tester,
        const LogoutScreen(),
        api: _api(open: false, activeOrders: 0),
      );
      expect(find.byKey(const Key('logout-warning')), findsNothing);
      expect(find.byKey(const Key('logout-confirm')), findsOneWidget);
      expect(find.byKey(const Key('logout-cancel')), findsOneWidget);
    });

    testWidgets('support center splits active and resolved tickets', (
      tester,
    ) async {
      await pump(tester, const SupportCenterScreen());
      expect(find.byKey(const Key('support-ticket-t1')), findsOneWidget);
      expect(find.byKey(const Key('support-ticket-t2')), findsOneWidget);
      expect(find.text('2'), findsWidgets);
      expect(find.byKey(const Key('support-ticket-t3')), findsOneWidget);
      expect(find.text('IN_PROGRESS'), findsNothing);
      expect(find.textContaining('RESOLVED'), findsNothing);
    });

    testWidgets('support center empty state', (tester) async {
      await pump(
        tester,
        const SupportCenterScreen(),
        api: _api(tickets: const SupportTicketPage(items: [], total: 0)),
      );
      expect(find.byKey(const Key('support-empty')), findsOneWidget);
      expect(find.byKey(const Key('support-topics')), findsOneWidget);
    });

    testWidgets('topic tiles sit between active and resolved tickets', (
      tester,
    ) async {
      await pump(tester, const SupportCenterScreen());
      final topics = tester.getRect(find.byKey(const Key('support-topics')));
      expect(
        tester.getRect(find.byKey(const Key('support-ticket-t2'))).bottom,
        lessThan(topics.top),
      );
      expect(
        tester.getRect(find.byKey(const Key('support-ticket-t3'))).top,
        greaterThan(topics.bottom),
      );
      for (final k in const [
        'ORDER_ISSUE',
        'CATALOGUE_TECH',
        'PAYMENT_COD',
        'ACCOUNT_ACCESS',
      ]) {
        expect(find.byKey(Key('support-topic-$k')), findsOneWidget);
      }
    });

    testWidgets('topic tile opens compose with topic preselected', (
      tester,
    ) async {
      final api = _api();
      await pump(tester, const SupportCenterScreen(), api: api);
      await tester.tap(find.byKey(const Key('support-topic-CATALOGUE_TECH')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('support-compose')), findsOneWidget);
      expect(
        find.byKey(const Key('support-topic-choice-CATALOGUE_TECH')),
        findsOneWidget,
      );
      FilledButton send() => tester.widget<FilledButton>(
        find.byKey(const Key('support-compose-send')),
      );
      expect(send().onPressed, isNull);

      await tester.enterText(
        find.byKey(const Key('support-compose-subject')),
        'Prix catalogue',
      );
      await tester.enterText(
        find.byKey(const Key('support-compose-body')),
        'Prix du couscous incorrect',
      );
      await tester.pump();
      expect(send().onPressed, isNotNull);
      await tester.tap(find.byKey(const Key('support-compose-send')));
      await tester.pumpAndSettle();
      expect(api.supportTickets, [
        {
          'body': 'Prix du couscous incorrect',
          'orderId': null,
          'subject': 'Prix catalogue',
          'topicCode': 'CATALOGUE_TECH',
        },
      ]);
    });

    testWidgets('payment topic can be completed with subject and body', (
      tester,
    ) async {
      final api = _api();
      await pump(tester, const SupportCenterScreen(), api: api);
      await tester.tap(find.byKey(const Key('support-topic-PAYMENT_COD')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('support-compose-subject')),
        'Virement',
      );
      await tester.enterText(
        find.byKey(const Key('support-compose-body')),
        'Paiement : virement non reçu',
      );
      await tester.pump();
      await tester.tap(find.byKey(const Key('support-compose-send')));
      await tester.pumpAndSettle();
      expect(api.supportTickets.single['body'], 'Paiement : virement non reçu');
      expect(api.supportTickets.single['orderId'], isNull);
      expect(api.supportTickets.single['topicCode'], 'PAYMENT_COD');
    });

    testWidgets('ticket reply is sent and the field clears', (tester) async {
      final api = _api();
      await pump(tester, const SupportTicketScreen(ticketId: 't1'), api: api);
      await tester.enterText(
        find.byKey(const Key('support-reply-body')),
        'Toujours en attente',
      );
      await tester.pump();
      await tester.tap(find.byKey(const Key('support-reply-send')));
      await tester.pumpAndSettle();
      expect(api.supportReplies, [('t1', 'Toujours en attente')]);
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('support-reply-body')))
            .controller
            ?.text,
        isEmpty,
      );
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('finished ticket has no reply bar', (tester) async {
      await pump(
        tester,
        const SupportTicketScreen(ticketId: 't1'),
        api: _api(ticketStatus: SupportTicketStatus.resolved),
      );
      expect(find.byKey(const Key('support-reply-body')), findsNothing);
      expect(find.byKey(const Key('support-ticket-finished')), findsOneWidget);
    });

    testWidgets('notification center: relative time, unread marks, details', (
      tester,
    ) async {
      await pump(tester, const NotificationsScreen());
      final title = find.descendant(
        of: find.byType(AppBar),
        matching: find.text(AppStrings.notificationsTitle),
      );
      expect(
        tester.renderObject<RenderParagraph>(title).didExceedMaxLines,
        isFalse,
      );
      expect(
        tester.widget<Text>(find.byKey(const Key('notification-time-n1'))).data,
        '2 min',
      );
      expect(
        tester.widget<Text>(find.byKey(const Key('notification-time-n2'))).data,
        '3 h',
      );
      expect(
        tester.widget<Text>(find.byKey(const Key('notification-time-n3'))).data,
        AppStrings.notificationsYesterday,
      );
      expect(find.byKey(const Key('notification-unread-n1')), findsOneWidget);
      expect(find.byKey(const Key('notification-unread-n3')), findsNothing);
      expect(find.byKey(const Key('notification-details-n1')), findsOneWidget);
      expect(find.byKey(const Key('notification-details-n2')), findsNothing);
      expect(
        find.text(AppStrings.notificationsToday.toUpperCase()),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const Key('notif-filter-orders')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('notification-n2')), findsNothing);
      expect(find.byKey(const Key('notification-n1')), findsOneWidget);
    });

    testWidgets('mark-all is disabled when everything is read', (tester) async {
      await pump(
        tester,
        const NotificationsScreen(),
        api: _api(notifications: [_notifications.last]),
      );
      final button = tester.widget<TextButton>(
        find.byKey(const Key('notifications-mark-all')),
      );
      expect(button.onPressed, isNull);
    });

    for (final v in parityVariants) {
      testWidgets('mark-all stays visible and reachable ${v.suffix}', (
        tester,
      ) async {
        final container = await _ready(_api());
        addTearDown(container.dispose);
        await parityPumpFull(
          tester,
          container: container,
          variant: v,
          child: const NotificationsScreen(),
          pushed: true,
        );
        final action = find.byKey(const Key('notifications-mark-all'));
        expect(action, findsOneWidget);
        final rect = tester.getRect(action);
        final width = tester.view.physicalSize.width /
            tester.view.devicePixelRatio;
        expect(rect.right, lessThanOrEqualTo(width));
        expect(rect.width, greaterThanOrEqualTo(kMinInteractiveDimension));
        final label = find.descendant(
          of: action,
          matching: find.text(AppStrings.notificationsMarkAllRead),
        );
        if (label.evaluate().isNotEmpty) {
          expect(
            tester.renderObject<RenderParagraph>(label).didExceedMaxLines,
            isFalse,
          );
        } else {
          expect(
            tester.widget<IconButton>(action).tooltip,
            AppStrings.notificationsMarkAllRead,
          );
        }
        expect(
          tester
              .renderObject<RenderParagraph>(
                find.text(AppStrings.notificationsTitle),
              )
              .didExceedMaxLines,
          isFalse,
        );
      });
    }

    testWidgets('notification settings keeps real preferences only', (
      tester,
    ) async {
      await pump(tester, const NotificationSettingsScreen());
      expect(find.text(AppStrings.notifSettingsTitle), findsOneWidget);
      expect(find.byKey(const Key('notif-critical-warning')), findsOneWidget);
      expect(find.byKey(const Key('notif-pref-foreground')), findsOneWidget);
      expect(find.byKey(const Key('notif-pref-sound')), findsOneWidget);
      expect(find.byKey(const Key('notif-pref-vibration')), findsOneWidget);
      expect(find.byKey(const Key('notif-push-unavailable')), findsOneWidget);
      expect(find.byKey(const Key('notif-settings-save')), findsOneWidget);
      expect(find.byType(Slider), findsNothing);
      expect(find.byType(DropdownButton<String>), findsNothing);
    });
  });
}
