import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speedygo_merchant_app/core/constants/app_strings.dart';
import 'package:speedygo_merchant_app/core/errors/app_exception.dart';
import 'package:speedygo_merchant_app/features/access/data/merchant_api.dart';
import 'package:speedygo_merchant_app/features/auth/application/auth_infrastructure.dart';
import 'package:speedygo_merchant_app/features/auth/application/session_controller.dart';
import 'package:speedygo_merchant_app/features/auth/application/session_state.dart';
import 'package:speedygo_merchant_app/features/store/application/notification_copy.dart';
import 'package:speedygo_merchant_app/features/store/application/notification_navigation.dart';
import 'package:speedygo_merchant_app/features/store/application/store_controllers.dart';
import 'package:speedygo_merchant_app/features/store/data/store_models.dart';
import 'package:speedygo_merchant_app/features/store/presentation/notifications_screen.dart';
import 'package:speedygo_merchant_app/l10n/app_localizations.dart';

MerchantNotificationItem item({
  String id = 'n1',
  String type = 'MERCHANT_ORDER_CREATED',
  String? sourceId = '11111111-1111-4111-8111-111111111111',
  bool read = false,
  String title = 'Title',
  String body = 'Body sgo_fixture',
  String createdAt = '2026-10-23T10:00:00.000Z',
}) {
  return MerchantNotificationItem(
    id: id,
    type: type,
    sourceId: sourceId,
    title: title,
    body: body,
    read: read,
    createdAt: createdAt,
  );
}

class FakeInboxApi implements MerchantClient {
  FakeInboxApi({List<MerchantNotificationItem>? seed})
    : items = List.of(seed ?? const []);

  List<MerchantNotificationItem> items;
  int unreadOverride = -1;
  int listCalls = 0;
  int markReadCalls = 0;
  int markAllCalls = 0;
  Object? listError;
  Object? Function(int offset)? listErrorForOffset;
  Object? markReadError;
  Object? markAllError;
  Object? unreadError;
  bool overlapOnLoadMore = false;
  Duration Function(int callCount)? listDelayForCall;

  int get unread =>
      unreadOverride >= 0 ? unreadOverride : items.where((n) => !n.read).length;

  @override
  Future<List<MerchantNotificationItem>> listNotifications({
    int limit = 50,
    int offset = 0,
  }) async {
    return (await listNotificationsPage(limit: limit, offset: offset)).items;
  }

  @override
  Future<MerchantNotificationPage> listNotificationsPage({
    int limit = 50,
    int offset = 0,
  }) async {
    listCalls += 1;
    final delay = listDelayForCall?.call(listCalls);
    if (delay != null && delay > Duration.zero) {
      await Future<void>.delayed(delay);
    }
    if (listError != null) throw listError!;
    final offsetError = listErrorForOffset?.call(offset);
    if (offsetError != null) throw offsetError;
    final snapshot = List.of(items);
    final slice = overlapOnLoadMore && offset > 0
        ? snapshot.take(limit).toList()
        : snapshot.skip(offset).take(limit).toList();
    return MerchantNotificationPage(
      items: slice,
      total: snapshot.length,
      unreadCount: unread,
    );
  }

  @override
  Future<int> notificationsUnreadCount() async {
    if (unreadError != null) throw unreadError!;
    return unread;
  }

  @override
  Future<void> markNotificationRead(String notificationId) async {
    markReadCalls += 1;
    if (markReadError != null) throw markReadError!;
    items = [
      for (final n in items)
        n.id == notificationId ? n.copyWith(read: true) : n,
    ];
  }

  @override
  Future<int> markAllNotificationsRead() async {
    markAllCalls += 1;
    if (markAllError != null) throw markAllError!;
    items = [for (final n in items) n.copyWith(read: true)];
    unreadOverride = 0;
    return items.length;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Session extends SessionController {
  _Session(this.initial);
  final SessionState initial;
  @override
  SessionState build() => initial;
  void switchAccount(String accountId) {
    state = SessionState(
      phase: SessionPhase.ready,
      accountId: accountId,
      generation: state.generation + 1,
    );
  }
}

void _bind(String code) {
  AppStrings.bind(lookupAppLocalizations(Locale(code)), code);
}

ProviderContainer inboxContainer(
  FakeInboxApi api, {
  String accountId = 'acc-a',
  int generation = 1,
}) {
  return ProviderContainer(
    overrides: [
      merchantApiProvider.overrideWithValue(api),
      sessionControllerProvider.overrideWith(
        () => _Session(
          SessionState(
            phase: SessionPhase.ready,
            accountId: accountId,
            generation: generation,
          ),
        ),
      ),
      storeClockProvider.overrideWithValue(
        () => DateTime.utc(2026, 10, 23, 12),
      ),
    ],
  );
}

Future<NotificationInboxState> settleInbox(ProviderContainer container) async {
  container.listen(notificationsControllerProvider, (_, _) {});
  container.listen(notificationsUnreadCountProvider, (_, _) {});
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
  return container.read(notificationsControllerProvider);
}

Widget inboxApp({
  required FakeInboxApi api,
  String locale = 'fr',
  String accountId = 'acc-ui',
}) {
  _bind(locale);
  final rtl = locale == 'ar';
  return ProviderScope(
    overrides: [
      merchantApiProvider.overrideWithValue(api),
      sessionControllerProvider.overrideWith(
        () => _Session(
          SessionState(
            phase: SessionPhase.ready,
            accountId: accountId,
            generation: 1,
          ),
        ),
      ),
      storeClockProvider.overrideWithValue(
        () => DateTime.utc(2026, 10, 23, 12),
      ),
    ],
    child: MaterialApp(
      locale: Locale(locale),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: MediaQuery(
        data: const MediaQueryData(size: Size(390, 844)),
        child: Directionality(
          textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
          child: const NotificationsScreen(),
        ),
      ),
    ),
  );
}

void main() {
  setUp(() => _bind('fr'));
  tearDown(() => _bind('fr'));

  test('system copy localizes merchant order and keeps public refs', () {
    _bind('fr');
    final fr = resolveSystemNotificationCopy(
      type: 'MERCHANT_ORDER_CREATED',
      storedTitle: 'New order',
      storedBody: 'Commande sgo_fixture reçue.',
    );
    expect(fr.localized, isTrue);
    expect(fr.title, 'Nouvelle commande');
    expect(fr.body, contains('sgo_fixture'));
    _bind('ar');
    final ar = resolveSystemNotificationCopy(
      type: 'MERCHANT_ORDER_CREATED',
      storedTitle: 'New order',
      storedBody: 'Commande sgo_fixture reçue.',
    );
    expect(ar.title, 'طلب جديد');
    expect(ar.body, contains('sgo_fixture'));
  });

  test('unknown types keep stored copy; cancel stays generic', () {
    _bind('fr');
    final unknown = resolveSystemNotificationCopy(
      type: 'ADMIN_SUPPORT_TICKET',
      storedTitle: 'Ticket Dar El Bahja',
      storedBody: 'Ada — 650,00 DZD',
    );
    expect(unknown.localized, isFalse);
    expect(unknown.body, contains('650,00 DZD'));
    final cancelled = resolveSystemNotificationCopy(
      type: 'ORDER_CANCELLED',
      storedTitle: 'Order cancelled',
      storedBody:
          'Your order sgo_fixture was cancelled. A refund has been requested.',
    );
    expect(cancelled.body, isNot(contains('refund')));
  });

  test('malformed merchant source ids are rejected', () {
    expect(isPlausibleSourceId('o1'), isFalse);
    expect(
      isPlausibleSourceId('11111111-1111-4111-8111-111111111111'),
      isTrue,
    );
  });

  test('pagination appends without inventing unread from page alone', () async {
    final seed = [
      for (var i = 0; i < 25; i++) item(id: 'n$i', read: i.isEven),
    ];
    final api = FakeInboxApi(seed: seed);
    final container = inboxContainer(api);
    addTearDown(container.dispose);
    var state = await settleInbox(container);
    expect(state.items.length, 20);
    expect(state.unreadCount, 12);
    await container.read(notificationsControllerProvider.notifier).loadMore();
    state = container.read(notificationsControllerProvider);
    expect(state.items.length, 25);
    expect(state.unreadCount, 12);
  });

  test('load-more overlapping ids are deduplicated', () async {
    final seed = [for (var i = 0; i < 25; i++) item(id: 'n$i')];
    final api = FakeInboxApi(seed: seed)..overlapOnLoadMore = true;
    final container = inboxContainer(api);
    addTearDown(container.dispose);
    await settleInbox(container);
    await container.read(notificationsControllerProvider.notifier).loadMore();
    final state = container.read(notificationsControllerProvider);
    expect(state.items.map((e) => e.id).toSet().length, state.items.length);
  });

  test('certain mark-read failure rolls back unread', () async {
    final api = FakeInboxApi(seed: [item(id: 'n1')])
      ..markReadError = const ApiException(
        'not found',
        code: 'NOTIFICATION_NOT_FOUND',
        statusCode: 404,
      );
    final container = inboxContainer(api);
    addTearDown(container.dispose);
    await settleInbox(container);
    await container.read(notificationsControllerProvider.notifier).markRead('n1');
    final state = container.read(notificationsControllerProvider);
    expect(state.items.first.read, isFalse);
    expect(state.unreadCount, 1);
    expect(container.read(notificationsUnreadCountProvider), 1);
  });

  test('unread count failure does not invent zero', () async {
    final api = FakeInboxApi(seed: [item(id: 'n1'), item(id: 'n2')]);
    final container = inboxContainer(api);
    addTearDown(container.dispose);
    await settleInbox(container);
    expect(container.read(notificationsUnreadCountProvider), 2);
    api.unreadError = const ApiException('down', code: 'NETWORK');
    await container.read(notificationsUnreadCountProvider.notifier).refresh();
    expect(container.read(notificationsUnreadCountProvider), 2);
  });

  test('session change rejects a stale list response', () async {
    final api = FakeInboxApi(seed: [item(id: 'old')])
      ..listDelayForCall = (call) =>
          call == 1
          ? const Duration(milliseconds: 80)
          : const Duration(milliseconds: 5);
    final container = inboxContainer(api, accountId: 'acc-old');
    addTearDown(container.dispose);
    container.listen(notificationsControllerProvider, (_, _) {});
    await Future<void>.delayed(Duration.zero);
    (container.read(sessionControllerProvider.notifier) as _Session)
        .switchAccount('acc-new');
    api.items = [item(id: 'new')];
    await Future<void>.delayed(const Duration(milliseconds: 120));
    final ids = container
        .read(notificationsControllerProvider)
        .items
        .map((e) => e.id)
        .toList();
    expect(ids, isNot(contains('old')));
  });

  testWidgets('empty inbox FR', (tester) async {
    await tester.pumpWidget(inboxApp(api: FakeInboxApi(), locale: 'fr'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('notifications-empty')), findsOneWidget);
  });

  testWidgets('populated inbox AR keeps mixed Latin', (tester) async {
    await tester.pumpWidget(
      inboxApp(
        api: FakeInboxApi(
          seed: [
            item(id: 'n1', read: false),
            item(
              id: 'n2',
              type: 'ADMIN_SUPPORT_TICKET',
              title: 'Ticket Dar El Bahja',
              body: 'Ada — 650,00 DZD',
              read: true,
            ),
          ],
        ),
        locale: 'ar',
      ),
    );
    await tester.pump();
    await tester.pump();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('notification-n1')), findsOneWidget);
    expect(find.text(AppStrings.notifTitleMerchantOrderCreated), findsOneWidget);
    expect(find.textContaining('sgo_fixture'), findsWidgets);
    expect(find.textContaining('Dar El Bahja'), findsOneWidget);
    expect(find.textContaining('650,00 DZD'), findsOneWidget);
    expect(
      Directionality.of(tester.element(find.byType(NotificationsScreen))),
      TextDirection.rtl,
    );
  });

  test('load-more failure keeps loaded rows and sets pagination error',
      () async {
    final seed = [for (var i = 0; i < 25; i++) item(id: 'n$i')];
    final api = FakeInboxApi(seed: seed)
      ..listErrorForOffset = (offset) {
        if (offset > 0) {
          return const ApiException('down', code: 'NETWORK');
        }
        return null;
      };
    final container = inboxContainer(api);
    addTearDown(container.dispose);
    await settleInbox(container);
    await container.read(notificationsControllerProvider.notifier).loadMore();
    final state = container.read(notificationsControllerProvider);
    expect(state.items.length, 20);
    expect(state.loadMoreError, isNotNull);
  });
}
