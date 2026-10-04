import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:speedygo_merchant_app/app/app.dart';
import 'package:speedygo_merchant_app/app/router/app_router.dart';
import 'package:speedygo_merchant_app/core/constants/app_strings.dart';
import 'package:speedygo_merchant_app/core/navigation/app_routes.dart';
import 'package:speedygo_merchant_app/features/access/application/access_controller.dart';
import 'package:speedygo_merchant_app/features/auth/application/session_controller.dart';
import 'package:speedygo_merchant_app/features/notifications/application/merchant_push_controller.dart';
import 'package:speedygo_merchant_app/features/notifications/application/order_alert_controller.dart';
import 'package:speedygo_merchant_app/features/notifications/data/push_messaging_gateway.dart';
import 'package:speedygo_merchant_app/features/notifications/data/push_registration.dart';
import 'package:speedygo_merchant_app/features/orders/presentation/order_detail_screen.dart';

/// Native Push client logic against the live backend with a HARNESS gateway.
///
/// Push hints are injected through the same `PushMessagingGateway` seam the
/// Firebase implementation feeds. No APNs/FCM message, no OS banner and no
/// native tap are involved: this is not native delivery evidence.
///
/// Host protocol (see /tmp/push_harness_host.py):
/// - request: `/tmp/push_harness_req/{seq}.json` `{"op": ..., "arg": ...}`
/// - response: `/tmp/push_harness_resp/{seq}.json`
/// - screenshot marker: /tmp/push_harness_shot.txt
class HarnessPushGateway implements PushMessagingGateway {
  HarnessPushGateway({required this.prefix, this.serial = 1, this.initial});

  final String prefix;
  int serial;
  PushOrderHint? initial;
  PushAuthorization auth = PushAuthorization.authorized;
  int deleteCount = 0;
  final refresh = StreamController<String>.broadcast();
  final foreground = StreamController<PushOrderHint>.broadcast();
  final opened = StreamController<PushOrderHint>.broadcast();

  String get currentToken => '$prefix-$serial';

  @override
  bool get isAvailable => true;
  @override
  String get platform => 'ios';
  @override
  Future<PushAuthorization> authorizationStatus() async => auth;
  @override
  Future<PushAuthorization> requestAuthorization() async => auth;
  @override
  Future<String?> getToken() async => currentToken;
  @override
  Future<void> deleteToken() async {
    deleteCount += 1;
    serial += 1;
  }

  @override
  Stream<String> get onTokenRefresh => refresh.stream;
  @override
  Stream<PushOrderHint> get onForegroundHint => foreground.stream;
  @override
  Stream<PushOrderHint> get onOpenedHint => opened.stream;
  @override
  Future<PushOrderHint?> takeInitialHint() async {
    final h = initial;
    initial = null;
    return h;
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const phoneLocal = String.fromEnvironment(
    'ALERT_LIVE_PHONE',
    defaultValue: '550000071',
  );
  const otpFilePath = String.fromEnvironment(
    'ALERT_OTP_FILE',
    defaultValue: '/Users/mac/.speedygo/dev/otp-last',
  );
  const darAccount = '0d00c071-d000-7000-8000-000000000001';
  final outDir = Directory(
    '/Users/mac/Downloads/speedygo_project/apps/merchant_app/audit/phase-5-ui/native-push',
  )..createSync(recursive: true);
  final reqDir = Directory('/tmp/push_harness_req')..createSync();
  final respDir = Directory('/tmp/push_harness_resp')..createSync();
  const shotMarker = '/tmp/push_harness_shot.txt';

  final steps = <Map<String, dynamic>>[];
  var seq = 0;

  void record(String id, bool ok, {Object? detail}) {
    steps.add({
      'id': id,
      'status': ok ? 'PASS' : 'FAIL',
      'detail': detail,
      'layer': 'harness_injected_push_hint',
      'at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  Future<Map<String, dynamic>> host(String op, [Object? arg]) async {
    seq += 1;
    final id = seq.toString().padLeft(3, '0');
    final resp = File('${respDir.path}/$id.json');
    if (resp.existsSync()) resp.deleteSync();
    File('${reqDir.path}/$id.json.tmp')
      ..writeAsStringSync(jsonEncode({'op': op, 'arg': arg}))
      ..renameSync('${reqDir.path}/$id.json');
    for (var i = 0; i < 240; i++) {
      if (resp.existsSync()) {
        return jsonDecode(resp.readAsStringSync()) as Map<String, dynamic>;
      }
      await Future<void>.delayed(const Duration(milliseconds: 250));
    }
    throw StateError('host op $op timed out');
  }

  Future<void> pumpFrames(WidgetTester tester, Duration total) async {
    final end = DateTime.now().add(total);
    while (DateTime.now().isBefore(end)) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> markShot(String tag) async {
    File(shotMarker).writeAsStringSync('$tag\n');
    await Future<void>.delayed(const Duration(seconds: 3));
  }

  Future<bool> pumpUntil(
    WidgetTester tester,
    bool Function() cond, {
    Duration timeout = const Duration(seconds: 20),
  }) async {
    final end = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(end)) {
      if (cond()) return true;
      await tester.pump(const Duration(milliseconds: 200));
    }
    return cond();
  }

  Future<String> waitForFreshOtp(DateTime after) async {
    final file = File(otpFilePath);
    for (var i = 0; i < 60; i++) {
      if (file.existsSync() && !file.lastModifiedSync().isBefore(after)) {
        final otp = file.readAsStringSync().trim();
        if (RegExp(r'^\d{4,8}$').hasMatch(otp)) return otp;
      }
      await Future<void>.delayed(const Duration(milliseconds: 500));
    }
    throw StateError('OTP not refreshed');
  }

  Future<void> pumpApp(WidgetTester tester, HarnessPushGateway gw) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [pushMessagingGatewayProvider.overrideWithValue(gw)],
        child: const SpeedyGoApp(),
      ),
    );
  }

  Future<void> reachHome(WidgetTester tester) async {
    await pumpFrames(tester, const Duration(seconds: 8));
    if (find.byKey(const Key('merchant-language')).evaluate().isNotEmpty) {
      await tester.tap(find.text('Français'));
      await pumpFrames(tester, const Duration(seconds: 2));
    }
    for (final label in [AppStrings.onboardingSkip, AppStrings.onboardingStart]) {
      if (find.text(label).evaluate().isNotEmpty) {
        await tester.tap(find.text(label));
        await pumpFrames(tester, const Duration(seconds: 2));
      }
    }
    if (find.byKey(const Key('home-branch-name')).evaluate().isEmpty) {
      expect(find.byKey(const Key('merchant-phone-continue')), findsOneWidget);
      await tester.enterText(find.byType(TextField).first, phoneLocal);
      await tester.pump(const Duration(milliseconds: 400));
      final otpBefore = DateTime.now().subtract(const Duration(seconds: 1));
      await tester.tap(find.byKey(const Key('merchant-phone-continue')));
      await pumpFrames(tester, const Duration(seconds: 4));
      expect(find.byKey(const Key('merchant-otp-field')), findsOneWidget);
      final otp = await waitForFreshOtp(otpBefore);
      await tester.enterText(find.byKey(const Key('merchant-otp-field')), otp);
      // Verify is enabled only after the rebuild that follows onChanged.
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.byKey(const Key('merchant-otp-verify')));
      await pumpFrames(tester, const Duration(seconds: 10));
    }
    if (find.textContaining('Dar El Bahja').evaluate().isEmpty) {
      final texts = find
          .byType(Text)
          .evaluate()
          .map((e) => (e.widget as Text).data)
          .whereType<String>()
          .take(20)
          .toList();
      final s = ProviderScope.containerOf(
        tester.element(find.byType(MaterialApp).first),
      ).read(sessionControllerProvider);
      fail(
        'home not reached; visible: $texts; session phase=${s.phase} '
        'busy=${s.busy} pendingPhone=${s.pendingPhone != null} '
        'error=${s.errorMessage} gen=${s.generation}',
      );
    }
  }

  ProviderContainer containerOf(WidgetTester tester) =>
      ProviderScope.containerOf(tester.element(find.byType(MaterialApp).first));

  // go_router's currentConfiguration.uri does not include imperative pushes,
  // so detail visibility is asserted on the mounted screen instead.
  bool detailOpen(String orderId) => find
      .byWidgetPredicate((w) => w is OrderDetailScreen && w.orderId == orderId)
      .evaluate()
      .isNotEmpty;
  bool anyDetailOpen() => find.byType(OrderDetailScreen).evaluate().isNotEmpty;

  Future<void> backHome(WidgetTester tester, ProviderContainer c) async {
    ScaffoldMessenger.maybeOf(
      tester.element(find.byType(Scaffold).first),
    )?.clearSnackBars();
    c.read(appRouterProvider).go(AppRoutes.home);
    await pumpFrames(tester, const Duration(seconds: 2));
    expect(anyDetailOpen(), isFalse, reason: 'back on home before next step');
  }

  void clearAlerts(ProviderContainer c) {
    final alerts = c.read(orderAlertControllerProvider.notifier);
    final active = c.read(orderAlertControllerProvider).activeAlert;
    if (active != null) alerts.markOrderHandled(active.orderId, promoteNext: false);
    alerts.dismissActive();
  }

  void writeProvenance({String? error, String? tokenPrefix}) {
    File('${outDir.path}/NATIVE_PUSH_SIM_HARNESS_PROVENANCE.json')
        .writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert({
        'fixture': 'Dar El Bahja',
        'device': 'iPhone 16e simulator (isolated; Finjan simulator untouched)',
        'layer': 'harness_injected_push_hint',
        'nativeDelivery': 'NOT_EXERCISED — no APNs/FCM message, no OS banner, no native tap',
        'backend': 'live local backend (PUSH_PROVIDER=disabled); device-token API is real',
        'tokenPrefix': tokenPrefix,
        'harnessResult':
            error == null && steps.every((s) => s['status'] == 'PASS')
                ? 'PASS'
                : 'FAIL',
        'error': error,
        'steps': steps,
      }),
    );
  }

  testWidgets('native push client logic (harness gateway, live backend)',
      (tester) async {
    final prefix = 'sim-harness-${DateTime.now().millisecondsSinceEpoch}';
    final orders = <String>[];
    try {
      await host('reset_tokens');
      // Leftover harness orders would queue ahead of this run's alerts.
      await host('reject_pending');
      final gw = HarnessPushGateway(prefix: prefix);
      await pumpApp(tester, gw);
      await reachHome(tester);
      var c = containerOf(tester);
      final access = c.read(accessControllerProvider);
      final merchantId = access.membership!.merchantId;
      final branchId = access.selectedBranch!.id;
      PushOrderHint hint(String orderId, {String? merchant}) => PushOrderHint(
            orderId: orderId,
            merchantId: merchant ?? merchantId,
            branchId: branchId,
          );

      // 1. Registration after session ready.
      final registered = await pumpUntil(
        tester,
        () =>
            c.read(merchantPushControllerProvider).registration ==
            PushRegistrationStatus.registered,
      );
      final row1 = await host('token', gw.currentToken);
      record(
        'token_registered_after_session_ready',
        registered &&
            row1['accountId'] == darAccount &&
            row1['active'] == true,
        detail: {'token': gw.currentToken, 'server': row1},
      );

      // 2. Foreground: push hint + poll for the same order → one alert.
      clearAlerts(c);
      await pumpFrames(tester, const Duration(seconds: 1));
      final oid = (await host('create'))['orderId'] as String;
      orders.add(oid);
      var appearances = 0;
      String? lastAlert;
      final sub = c.listen(orderAlertControllerProvider, (_, next) {
        final id = next.activeAlert?.orderId;
        if (id == oid && lastAlert != oid) appearances += 1;
        lastAlert = id;
      });
      gw.foreground.add(hint(oid));
      unawaited(
        c.read(orderAlertControllerProvider.notifier).reconcile(reason: 'poll'),
      );
      final shown = await pumpUntil(
        tester,
        () =>
            c.read(orderAlertControllerProvider).activeAlert?.orderId == oid &&
            find.byKey(const Key('incoming-order-alert')).evaluate().isNotEmpty,
      );
      gw.foreground.add(hint(oid));
      // Covers at least one 8s poll tick plus the duplicate hint.
      await pumpFrames(tester, const Duration(seconds: 10));
      sub.close();
      if (shown) await markShot('push-harness-foreground-alert');
      record(
        'foreground_push_and_poll_deduped',
        shown && appearances == 1,
        detail: {'orderId': oid, 'alertAppearances': appearances},
      );

      // 3. Tap on a still-pending order → detail with actions.
      clearAlerts(c);
      await pumpFrames(tester, const Duration(seconds: 1));
      gw.opened.add(hint(oid));
      final opened = await pumpUntil(
        tester,
        () =>
            detailOpen(oid) &&
            find.byKey(const Key('order-accept')).evaluate().isNotEmpty,
      );
      if (opened) await markShot('push-harness-tap-open');
      record(
        'tap_opens_correct_pending_order',
        opened,
        detail: {'orderId': oid, 'detailOpen': detailOpen(oid)},
      );
      await backHome(tester, c);

      // 4. Tap after the order was accepted elsewhere → stale, no actions.
      final accepted = await host('accept', oid);
      gw.opened.add(hint(oid));
      final staleSnack = await pumpUntil(
        tester,
        () => find.text(AppStrings.notificationsOrderStale).evaluate().isNotEmpty,
      );
      final loaded = await pumpUntil(
        tester,
        () =>
            detailOpen(oid) &&
            find.byKey(const Key('order-detail-ref')).evaluate().isNotEmpty,
      );
      await pumpFrames(tester, const Duration(seconds: 1));
      final noAccept = find.byKey(const Key('order-accept')).evaluate().isEmpty;
      final incomingLabel =
          find.text(AppStrings.orderIncomingBanner).evaluate().isNotEmpty;
      if (staleSnack) await markShot('push-harness-tap-stale');
      record(
        'tap_on_handled_order_not_shown_as_awaiting',
        staleSnack && loaded && noAccept && !incomingLabel,
        detail: {
          'orderId': oid,
          'hostAccept': accepted['status'],
          'detailOpen': detailOpen(oid),
          'acceptButtonVisible': !noAccept,
          'incomingLabelVisible': incomingLabel,
        },
      );
      await backHome(tester, c);

      // 5. Inaccessible: unknown order and foreign merchant → no navigation.
      const unknown = '01a0ffff-ffff-7fff-8fff-ffffffffffff';
      gw.opened.add(hint(unknown));
      final unknownSnack = await pumpUntil(
        tester,
        () => find.text(AppStrings.pushOrderInaccessible).evaluate().isNotEmpty,
      );
      await pumpFrames(tester, const Duration(seconds: 1));
      final stayed1 = !anyDetailOpen();
      if (unknownSnack) await markShot('push-harness-tap-inaccessible');
      await backHome(tester, c);
      gw.opened.add(
        hint(oid, merchant: '0d00c099-d000-7000-8000-000000010001'),
      );
      final foreignSnack = await pumpUntil(
        tester,
        () => find.text(AppStrings.pushOrderInaccessible).evaluate().isNotEmpty,
      );
      await pumpFrames(tester, const Duration(seconds: 1));
      final stayed2 = !anyDetailOpen();
      record(
        'tap_on_inaccessible_order_does_not_navigate',
        unknownSnack && stayed1 && foreignSnack && stayed2,
        detail: {'unknownOrder': unknown, 'foreignMerchantHint': true},
      );
      await backHome(tester, c);

      // 6. Token refresh → old deactivated, new active.
      final oldToken = gw.currentToken;
      gw.serial += 1;
      gw.refresh.add(gw.currentToken);
      final store = MerchantPushRegistration();
      await pumpFrames(tester, const Duration(seconds: 4));
      final stored = await store.loadStoredToken();
      final oldRow = await host('token', oldToken);
      final newRow = await host('token', gw.currentToken);
      record(
        'token_refresh_rotates_server_row',
        stored?.token == gw.currentToken &&
            oldRow['active'] == false &&
            newRow['active'] == true &&
            newRow['accountId'] == darAccount,
        detail: {'old': oldRow, 'new': newRow},
      );

      // 7. Permission denied (harness-simulated OS state) → token deactivated.
      gw.auth = PushAuthorization.denied;
      await c.read(merchantPushControllerProvider.notifier).syncRegistration();
      await pumpFrames(tester, const Duration(seconds: 1));
      final deniedState = c.read(merchantPushControllerProvider).registration;
      final deniedRow = await host('token', gw.currentToken);
      c.read(appRouterProvider).push(AppRoutes.notificationSettings);
      await pumpFrames(tester, const Duration(seconds: 3));
      final deniedCopy =
          find.text(AppStrings.notifSettingsOsDeniedPush).evaluate().isNotEmpty;
      await markShot('push-harness-permission-denied');
      record(
        'permission_denied_deactivates_token',
        deniedState == PushRegistrationStatus.permissionDenied &&
            deniedRow['active'] == false &&
            deniedCopy,
        detail: {'server': deniedRow, 'settingsCopy': deniedCopy},
      );
      gw.auth = PushAuthorization.authorized;
      await c.read(merchantPushControllerProvider.notifier).syncRegistration();
      await pumpFrames(tester, const Duration(seconds: 2));
      final reRow = await host('token', gw.currentToken);
      record(
        'permission_regranted_reregisters',
        c.read(merchantPushControllerProvider).registration ==
                PushRegistrationStatus.registered &&
            reRow['active'] == true,
        detail: {'server': reRow},
      );
      await backHome(tester, c);

      // 8. Cold start from a tap: consumed only after restore + access ready.
      clearAlerts(c);
      final oid2 = (await host('create'))['orderId'] as String;
      orders.add(oid2);
      final gw2 = HarnessPushGateway(
        prefix: prefix,
        serial: gw.serial,
        initial: hint(oid2),
      );
      await tester.pumpWidget(const SizedBox.shrink());
      await pumpFrames(tester, const Duration(seconds: 1));
      await pumpApp(tester, gw2);
      // (session phase, access destination, pendingOpen held, detail open)
      final statesSeen = <String>[];
      var openedBeforeReady = false;
      final coldOpened = await pumpUntil(
        tester,
        () {
          if (find.byType(MaterialApp).evaluate().isEmpty) return false;
          final cc = containerOf(tester);
          final phase = cc.read(sessionControllerProvider).phase.name;
          final dest = cc.read(accessControllerProvider).destination.name;
          final held =
              cc.read(merchantPushControllerProvider).pendingOpen != null;
          final open = detailOpen(oid2);
          if (open && (phase != 'ready' || dest != 'home')) {
            openedBeforeReady = true;
          }
          final s = '$phase/$dest/held=$held/detail=$open';
          if (statesSeen.isEmpty || statesSeen.last != s) statesSeen.add(s);
          return open &&
              find.byKey(const Key('order-accept')).evaluate().isNotEmpty;
        },
        timeout: const Duration(seconds: 30),
      );
      c = containerOf(tester);
      if (coldOpened) await markShot('push-harness-cold-start-open');
      record(
        'cold_start_tap_opens_after_auth_and_navigation_ready',
        coldOpened &&
            !openedBeforeReady &&
            c.read(merchantPushControllerProvider).pendingOpen == null,
        detail: {'orderId': oid2, 'statesSeen': statesSeen},
      );

      // 9. Scoped logout → this install's token deactivated + rotated.
      final beforeLogout = gw2.currentToken;
      await c.read(sessionControllerProvider.notifier).logout();
      await pumpFrames(tester, const Duration(seconds: 3));
      final logoutRow = await host('token', beforeLogout);
      record(
        'logout_deactivates_install_token',
        logoutRow['active'] == false &&
            gw2.deleteCount >= 1 &&
            await store.loadStoredToken() == null,
        detail: {'server': logoutRow, 'providerDeleteCalls': gw2.deleteCount},
      );
      writeProvenance(tokenPrefix: prefix);
    } catch (e) {
      writeProvenance(error: e.toString(), tokenPrefix: prefix);
      rethrow;
    } finally {
      for (final o in orders) {
        await host('cleanup', o);
      }
      await host('done');
    }
    expect(steps.every((s) => s['status'] == 'PASS'), isTrue,
        reason: const JsonEncoder.withIndent(' ').convert(steps));
  });
}
