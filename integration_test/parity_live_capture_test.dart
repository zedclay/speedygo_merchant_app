import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:speedygo_merchant_app/app/app.dart';
import 'package:speedygo_merchant_app/app/router/app_router.dart';
import 'package:speedygo_merchant_app/core/constants/app_strings.dart';
import 'package:speedygo_merchant_app/core/navigation/app_routes.dart';
import 'package:speedygo_merchant_app/core/storage/approval_notice_store.dart';
import 'package:speedygo_merchant_app/core/storage/session_store.dart';
import 'package:speedygo_merchant_app/features/auth/application/session_controller.dart';
import 'package:speedygo_merchant_app/features/auth/application/session_providers.dart';
import 'package:speedygo_merchant_app/features/auth/application/session_state.dart';
import 'package:speedygo_merchant_app/features/notifications/application/merchant_push_controller.dart';
import 'package:speedygo_merchant_app/features/notifications/data/push_registration.dart';

/// Push token record kept in memory so the device Keychain record is never
/// read, rotated or cleared by a dedicated run.
class _MemoryPushRegistration extends MerchantPushRegistration {
  StoredPushToken? _stored;

  @override
  Future<void> storeRegisteredToken({
    required String token,
    required String platform,
    required String? accountId,
  }) async {
    _stored = (token: token, platform: platform, accountId: accountId);
  }

  @override
  Future<StoredPushToken?> loadStoredToken() async => _stored;

  @override
  Future<void> clearStoredToken() async => _stored = null;
}

/// Live parity captures (Batches 1–6) for the Dar El Bahja synthetic Merchant
/// on the dev backend. Read-only: screens are opened, nothing is saved.
///
/// `PARITY_SESSION=dedicated` (default): OTP login with every app store held
/// in memory (session, selected merchant/branch, launch flags, approval
/// notice, push token), so the device Keychain is never read or written.
/// The session created by the run is revoked at the end, also on failure.
/// `PARITY_SESSION=restored`: uses the session already stored on the device
/// (must be Dar El Bahja); the logout screen is shown but never confirmed.
///
/// Screenshots are taken by the host watcher (`audit/parity/live/run_parity_live.sh`)
/// reading [shotMarker]; this test never captures or prints tokens / OTPs.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const phoneLocal = '550000071';
  const otpFilePath = String.fromEnvironment(
    'PARITY_OTP_FILE',
    defaultValue: '/Users/mac/.speedygo/dev/otp-last',
  );
  const prefix = String.fromEnvironment('PARITY_PREFIX', defaultValue: 'live');
  const orderId = String.fromEnvironment('PARITY_ORDER_ID');
  const productId = String.fromEnvironment('PARITY_PRODUCT_ID');
  const categoryId = String.fromEnvironment('PARITY_CATEGORY_ID');
  const sessionMode = String.fromEnvironment(
    'PARITY_SESSION',
    defaultValue: 'dedicated',
  );
  const restoredSession = sessionMode == 'restored';
  const merchantId = String.fromEnvironment(
    'PARITY_MERCHANT_ID',
    defaultValue: '0d00c071-d000-7000-8000-000000010001',
  );
  const branchId = String.fromEnvironment(
    'PARITY_BRANCH_ID',
    defaultValue: '0d00c071-d000-7000-8000-000000011001',
  );
  final memorySessions = MemorySessionStore();
  var sessionCreated = false;
  // Comma-separated tags to capture (empty = all). The walk is unchanged.
  final onlyTags = const String.fromEnvironment('PARITY_ONLY')
      .split(',')
      .map((t) => t.trim())
      .where((t) => t.isNotEmpty)
      .toSet();
  const shotMarker = '/tmp/parity_live_shot.txt';
  final outDir = Directory(
    '/Users/mac/Downloads/speedygo_project/apps/merchant_app/audit/parity/live',
  )..createSync(recursive: true);

  final steps = <Map<String, Object?>>[];

  Future<void> pumpFrames(WidgetTester tester, Duration total) async {
    final end = DateTime.now().add(total);
    while (DateTime.now().isBefore(end)) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> waitFor(
    WidgetTester tester,
    Finder finder, {
    Duration timeout = const Duration(seconds: 25),
  }) async {
    final end = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(end)) {
      await pumpFrames(tester, const Duration(milliseconds: 200));
      if (finder.evaluate().isNotEmpty) return;
    }
    throw TestFailure('Timed out waiting for $finder');
  }

  Future<void> shot(WidgetTester tester, String tag) async {
    if (onlyTags.isNotEmpty && !onlyTags.contains(tag)) return;
    await pumpFrames(tester, const Duration(milliseconds: 1500));
    File(shotMarker).writeAsStringSync('${prefix}_$tag\n');
    await pumpFrames(tester, const Duration(seconds: 3));
    steps.add({'tag': '${prefix}_$tag', 'at': DateTime.now().toUtc().toIso8601String()});
  }

  Future<String> waitForFreshOtp(DateTime after) async {
    final file = File(otpFilePath);
    for (var i = 0; i < 80; i++) {
      if (file.existsSync() && !file.lastModifiedSync().isBefore(after)) {
        final otp = file.readAsStringSync().trim();
        if (RegExp(r'^\d{4,8}$').hasMatch(otp)) return otp;
      }
      await Future<void>.delayed(const Duration(milliseconds: 250));
    }
    throw StateError('OTP not found');
  }

  GoRouter routerOf(WidgetTester tester) => ProviderScope.containerOf(
    tester.element(find.byType(MaterialApp).first),
  ).read(appRouterProvider);

  Future<void> goTab(WidgetTester tester, String path) async {
    routerOf(tester).go(path);
    await pumpFrames(tester, const Duration(seconds: 3));
  }

  /// Opens [path] pushed above the home tab, as the app does from a tile.
  Future<void> pushFromHome(WidgetTester tester, String path) async {
    routerOf(tester).go(AppRoutes.home);
    await pumpFrames(tester, const Duration(milliseconds: 800));
    routerOf(tester).push(path);
    await pumpFrames(tester, const Duration(seconds: 3));
  }

  /// Lazy lists only learn their full extent as they build, so jump until
  /// the extent stops growing.
  Future<void> scrollToEnd(WidgetTester tester) async {
    for (var pass = 0; pass < 5; pass++) {
      var moved = false;
      for (final element in find.byType(Scrollable).evaluate()) {
        final state = (element as StatefulElement).state as ScrollableState;
        final position = state.position;
        if (position.axis == Axis.vertical &&
            position.maxScrollExtent > 0 &&
            position.pixels < position.maxScrollExtent) {
          position.jumpTo(position.maxScrollExtent);
          moved = true;
        }
      }
      await pumpFrames(tester, const Duration(milliseconds: 600));
      if (!moved) break;
    }
  }

  void expectMerchantIdentity() {
    // Merchant shell identity (never the Customer app).
    expect(find.text(AppStrings.tabCatalog), findsOneWidget);
    expect(find.text(AppStrings.tabReports), findsOneWidget);
    expect(find.text('Recherche'), findsNothing);
    expect(find.textContaining('Dar El Bahja'), findsWidgets);
    expect(find.textContaining('Finjan'), findsNothing);
  }

  Future<void> reachHome(WidgetTester tester) async {
    if (restoredSession) {
      await tester.pumpWidget(const ProviderScope(child: SpeedyGoApp()));
    } else {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sessionStoreProvider.overrideWithValue(memorySessions),
            contextStoreProvider.overrideWithValue(
              MemoryContextStore()
                ..merchantId = merchantId
                ..branchId = branchId,
            ),
            launchStoreProvider.overrideWithValue(
              MemoryLaunchStore(languageSeen: true, onboardingSeen: true),
            ),
            approvalNoticeStoreProvider.overrideWithValue(
              MemoryApprovalNoticeStore(),
            ),
            pushRegistrationStoreProvider.overrideWithValue(
              _MemoryPushRegistration(),
            ),
          ],
          child: const SpeedyGoApp(),
        ),
      );
    }
    await pumpFrames(tester, const Duration(seconds: 6));

    if (find.byKey(const Key('merchant-language')).evaluate().isNotEmpty) {
      await tester.tap(find.text('Français'));
      await pumpFrames(tester, const Duration(seconds: 2));
    }
    if (find.text(AppStrings.onboardingSkip).evaluate().isNotEmpty) {
      await tester.tap(find.text(AppStrings.onboardingSkip));
      await pumpFrames(tester, const Duration(seconds: 2));
    }
    if (find.text(AppStrings.onboardingStart).evaluate().isNotEmpty) {
      await tester.tap(find.text(AppStrings.onboardingStart));
      await pumpFrames(tester, const Duration(seconds: 2));
    }
    if (restoredSession) {
      await waitFor(tester, find.byKey(const Key('home-branch-name')))
          .catchError((Object _) {
            throw TestFailure('no restored Merchant session on this device');
          });
      expectMerchantIdentity();
      return;
    }
    // Dedicated session only: a restored session belongs to someone else and
    // must be neither used nor revoked by this run.
    await waitFor(tester, find.byKey(const Key('merchant-phone-continue')))
        .catchError((Object _) {
          throw TestFailure('existing session restored; refusing to use it');
        });
    await tester.enterText(find.byType(TextField).first, phoneLocal);
    await tester.pump(const Duration(milliseconds: 400));
    final otpBefore = DateTime.now().subtract(const Duration(seconds: 1));
    await tester.tap(find.byKey(const Key('merchant-phone-continue')));
    await waitFor(tester, find.byKey(const Key('merchant-otp-field')));
    final otp = await waitForFreshOtp(otpBefore);
    await tester.enterText(find.byKey(const Key('merchant-otp-field')), otp);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.byKey(const Key('merchant-otp-verify')));
    sessionCreated = true;
    await waitFor(tester, find.byKey(const Key('home-branch-name')));
    expectMerchantIdentity();
  }

  /// Revokes the dedicated session if the walk stopped before the logout
  /// screen confirmed it. Never runs for a restored session.
  Future<void> revokeDedicatedSession(WidgetTester tester) async {
    if (restoredSession || !sessionCreated) return;
    final app = find.byType(MaterialApp);
    if (app.evaluate().isEmpty) return;
    final container = ProviderScope.containerOf(tester.element(app.first));
    if (container.read(sessionControllerProvider).phase ==
        SessionPhase.signedOut) {
      return;
    }
    await container.read(sessionControllerProvider.notifier).logout();
    await pumpFrames(tester, const Duration(seconds: 2));
  }

  Future<void> walk(WidgetTester tester) async {
    await reachHome(tester);

    // B1 · shell and dashboard
    await shot(tester, 'b1_home');
    await scrollToEnd(tester);
    await shot(tester, 'b1_home_end');

    // B2 · orders
    await goTab(tester, AppRoutes.orders);
    await shot(tester, 'b2_orders');
    if (orderId.isNotEmpty) {
      await pushFromHome(tester, '/app/orders/$orderId');
      await shot(tester, 'b2_order_detail');
      await scrollToEnd(tester);
      await shot(tester, 'b2_order_detail_end');

      // Update-time sheet: opened and a reason chip selected (local state
      // only), then dismissed. The confirm button is never tapped.
      final open = find.byKey(const Key('prep-update-open'));
      if (open.evaluate().isNotEmpty) {
        await tester.ensureVisible(open.first);
        await pumpFrames(tester, const Duration(milliseconds: 500));
        await tester.tap(open.first);
        final sheet = find.byKey(const Key('update-prep-sheet'));
        await waitFor(tester, sheet);
        await shot(tester, 'b2_update_sheet');
        final busy = find.byKey(const Key('prep-reason-busy'));
        if (busy.evaluate().isNotEmpty) {
          await tester.ensureVisible(busy);
          await pumpFrames(tester, const Duration(milliseconds: 400));
          await tester.tap(busy);
          await pumpFrames(tester, const Duration(milliseconds: 600));
          final confirm = find.byKey(const Key('prep-update-confirm'));
          await tester.ensureVisible(confirm);
          await shot(tester, 'b2_update_sheet_reason');
        }
        Navigator.of(tester.element(sheet)).pop();
        await pumpFrames(tester, const Duration(seconds: 1));
        expect(sheet, findsNothing);
      }
    }

    // B3 · catalogue
    await goTab(tester, AppRoutes.catalog);
    await shot(tester, 'b3_catalog');
    if (categoryId.isNotEmpty) {
      await pushFromHome(tester, '/app/catalog/category/$categoryId');
      await shot(tester, 'b3_category');
      await scrollToEnd(tester);
      await shot(tester, 'b3_category_end');
    }
    if (productId.isNotEmpty) {
      await pushFromHome(tester, '/app/catalog/products/$productId');
      await shot(tester, 'b3_product');
      await pushFromHome(tester, '/app/catalog/products/$productId/variants');
      await shot(tester, 'b3_variants');
      await pushFromHome(tester, '/app/catalog/products/$productId/extras');
      await shot(tester, 'b3_extras');
      await pushFromHome(
        tester,
        '/app/catalog/products/$productId/availability',
      );
      await shot(tester, 'b3_product_availability');
    }
    await pushFromHome(tester, AppRoutes.catalogReorder);
    await shot(tester, 'b3_reorder');
    await pushFromHome(tester, AppRoutes.catalogBulkAvailability);
    await shot(tester, 'b3_bulk_availability');

    // B4 · store
    await goTab(tester, AppRoutes.profile);
    await shot(tester, 'b4_profile');
    await pushFromHome(tester, AppRoutes.storeGeneral);
    await waitFor(tester, find.byKey(const Key('store-general-screen')));
    await shot(tester, 'b4_general');
    await pushFromHome(tester, AppRoutes.openingHours);
    await shot(tester, 'b4_hours');
    await pushFromHome(tester, AppRoutes.storeAvailability);
    await shot(tester, 'b4_availability');
    await pushFromHome(tester, AppRoutes.temporaryClosure);
    await shot(tester, 'b4_temporary');
    await pushFromHome(tester, AppRoutes.storeCover);
    await shot(tester, 'b4_cover');
    await pushFromHome(tester, AppRoutes.storeAddress);
    await shot(tester, 'b4_address');

    // B5 · reports
    await goTab(tester, AppRoutes.reports);
    await shot(tester, 'b5_overview');
    await pushFromHome(tester, AppRoutes.reportsTopProducts);
    await shot(tester, 'b5_top_products');

    // B6 · settings, notifications, support
    await pushFromHome(tester, AppRoutes.settings);
    await shot(tester, 'b6_settings');
    await pushFromHome(tester, AppRoutes.notifications);
    await shot(tester, 'b6_notifications');
    await pushFromHome(tester, AppRoutes.notificationSettings);
    await shot(tester, 'b6_notification_settings');
    await pushFromHome(tester, AppRoutes.support);
    await shot(tester, 'b6_support');
    await pushFromHome(tester, AppRoutes.logout);
    await waitFor(tester, find.byKey(const Key('logout-screen')));
    await shot(tester, 'b6_logout');

    if (restoredSession) {
      // The restored session is preserved: leave the logout screen unconfirmed.
      expect(find.byKey(const Key('logout-confirm')), findsOneWidget);
      routerOf(tester).go(AppRoutes.home);
      await pumpFrames(tester, const Duration(seconds: 2));
      expect(find.byKey(const Key('home-branch-name')), findsOneWidget);
    } else {
      // Revoke the session created by this run.
      await tester.tap(find.byKey(const Key('logout-confirm')));
      await waitFor(tester, find.byKey(const Key('merchant-phone-continue')));
    }
    File(shotMarker).writeAsStringSync('${prefix}_99_done\n');

    File('${outDir.path}/PROVENANCE_$prefix.json').writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert({
        'app': 'merchant',
        'bundleId': 'com.speedygo.speedygoMerchantApp',
        'merchant': 'Dar El Bahja (synthetic, OWNER)',
        'backend': 'local dev',
        'prefix': prefix,
        'session': restoredSession
            ? 'restored device session (preserved, not revoked)'
            : 'dedicated OTP session, app stores in memory (Keychain untouched)',
        'sessionRevoked': !restoredSession,
        'steps': steps,
      }),
    );
  }

  testWidgets('parity live captures batches 1–6', (tester) async {
    try {
      await walk(tester);
    } finally {
      await revokeDedicatedSession(tester);
    }
  });
}
