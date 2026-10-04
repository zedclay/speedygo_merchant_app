import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:speedygo_merchant_app/app/app.dart';
import 'package:speedygo_merchant_app/app/router/app_router.dart';
import 'package:speedygo_merchant_app/core/constants/app_constants.dart';
import 'package:speedygo_merchant_app/core/constants/app_strings.dart';
import 'package:speedygo_merchant_app/core/navigation/app_routes.dart';
import 'package:speedygo_merchant_app/core/storage/approval_notice_store.dart';
import 'package:speedygo_merchant_app/core/storage/session_store.dart';
import 'package:speedygo_merchant_app/features/auth/application/session_controller.dart';
import 'package:speedygo_merchant_app/features/auth/application/session_providers.dart';
import 'package:speedygo_merchant_app/features/auth/application/session_state.dart';
import 'package:speedygo_merchant_app/features/notifications/application/merchant_push_controller.dart';
import 'package:speedygo_merchant_app/features/notifications/data/push_registration.dart';

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

/// Merchant write flows against the disposable environment only
/// (`speedygo_parity_fx` behind the API on 127.0.0.1:3100).
///
/// 1. OWNER: list-card accept / reject on two orders placed through the real
///    checkout for this run; branch-name save → fresh app instance → restore;
///    populated Reports and Top produits; Top produits and overview rows open
///    the product editor.
/// 2. MANAGER: a Top produits row opens the product editor.
/// 3. STAFF: Top produits rows have no chevron and no tap target; tapping a
///    row leaves the screen in place.
///
/// Refuses to run unless the app was built with API_BASE_URL on port 3100.
/// One memory-only OTP session per role (Keychain never read or written),
/// each ended by the app's logout; sessions live only in the disposable
/// database. Screenshots are taken by the host watcher from [shotMarker].
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const isolatedApi = 'http://127.0.0.1:3100/api/v1';
  const otpFilePath = String.fromEnvironment('FX_OTP_FILE');
  const evidenceDir = String.fromEnvironment('FX_EVIDENCE_DIR');
  const prefix = String.fromEnvironment('PARITY_PREFIX', defaultValue: 'fxi');
  const acceptId = String.fromEnvironment('FX_ACCEPT_ORDER_ID');
  const rejectId = String.fromEnvironment('FX_REJECT_ORDER_ID');
  const merchantId = '0d00f0f0-fa00-7000-8000-000000001001';
  const branchId = '0d00f0f0-fa00-7000-8000-000000002001';
  const branchName = 'Comptoir Essai';
  const renamed = 'Comptoir Essai TEST FX';
  const topProductName = 'Couscous royal';
  const owner = '550009101';
  const manager = '550009102';
  const staff = '550009103';
  const shotMarker = '/tmp/parity_fx_isolated_shot.txt';

  var memorySessions = MemorySessionStore();
  var sessionCreated = false;
  final steps = <Map<String, Object?>>[];
  final results = <String, Object?>{};

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

  Future<void> waitGone(WidgetTester tester, Finder finder) async {
    final end = DateTime.now().add(const Duration(seconds: 25));
    while (DateTime.now().isBefore(end)) {
      await pumpFrames(tester, const Duration(milliseconds: 200));
      if (finder.evaluate().isEmpty) return;
    }
    throw TestFailure('Still present: $finder');
  }

  Future<void> shot(WidgetTester tester, String tag) async {
    await pumpFrames(tester, const Duration(milliseconds: 1200));
    File(shotMarker).writeAsStringSync('${prefix}_$tag\n');
    await pumpFrames(tester, const Duration(seconds: 3));
    steps.add({
      'tag': '${prefix}_$tag',
      'at': DateTime.now().toUtc().toIso8601String(),
    });
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
    throw StateError('isolated OTP not found');
  }

  GoRouter routerOf(WidgetTester tester) => ProviderScope.containerOf(
    tester.element(find.byType(MaterialApp).first),
  ).read(appRouterProvider);

  Future<void> push(WidgetTester tester, String path) async {
    routerOf(tester).go(AppRoutes.home);
    await pumpFrames(tester, const Duration(milliseconds: 800));
    routerOf(tester).push(path);
    await pumpFrames(tester, const Duration(seconds: 3));
  }

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await pumpFrames(tester, const Duration(milliseconds: 500));
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
    await pumpFrames(tester, const Duration(seconds: 6));
  }

  Future<void> login(WidgetTester tester, String phoneLocal) async {
    memorySessions = MemorySessionStore();
    await pumpApp(tester);
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
    expect(find.textContaining(branchName), findsWidgets);
  }

  Future<void> logout(WidgetTester tester, String role) async {
    await push(tester, AppRoutes.logout);
    await waitFor(tester, find.byKey(const Key('logout-screen')));
    await tester.tap(find.byKey(const Key('logout-confirm')));
    await waitFor(tester, find.byKey(const Key('merchant-phone-continue')));
    sessionCreated = false;
    results['logout_$role'] = true;
  }

  Future<void> revokeDedicatedSession(WidgetTester tester) async {
    if (!sessionCreated) return;
    if (find.byType(MaterialApp).evaluate().isEmpty) await pumpApp(tester);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(MaterialApp).first),
    );
    if (container.read(sessionControllerProvider).phase ==
        SessionPhase.signedOut) {
      return;
    }
    await container.read(sessionControllerProvider.notifier).logout();
    await pumpFrames(tester, const Duration(seconds: 2));
  }

  Future<void> dismissAlerts(WidgetTester tester) async {
    final alert = find.byKey(const Key('incoming-order-alert'));
    final dismiss = find.byKey(const Key('incoming-alert-dismiss'));
    var dismissed = 0;
    await waitFor(
      tester,
      alert,
      timeout: const Duration(seconds: 15),
    ).catchError((Object _) {});
    for (var i = 0; i < 6; i++) {
      await pumpFrames(tester, const Duration(seconds: 2));
      if (alert.evaluate().isEmpty) break;
      expect(tester.takeException(), isNull);
      if (dismissed == 0) await shot(tester, 'alert');
      await tester.tap(dismiss);
      dismissed++;
    }
    expect(alert, findsNothing);
    results['alertsDismissed'] = dismissed;
  }

  Future<void> acceptReject(WidgetTester tester) async {
    routerOf(tester).go(AppRoutes.orders);
    final acceptButton = find.byKey(const Key('order-card-accept-$acceptId'));
    final rejectButton = find.byKey(const Key('order-card-reject-$rejectId'));
    await waitFor(tester, acceptButton);
    await waitFor(tester, rejectButton);
    await dismissAlerts(tester);
    await tester.ensureVisible(find.byKey(const Key('order-card-$acceptId')));
    await pumpFrames(tester, const Duration(milliseconds: 500));
    await shot(tester, 'incoming');

    await tester.tap(acceptButton);
    await waitFor(tester, find.byKey(const Key('accept-prep-sheet')));
    await shot(tester, 'accept_sheet');
    final confirm = find.byKey(const Key('accept-prep-confirm'));
    await tester.ensureVisible(confirm);
    await pumpFrames(tester, const Duration(milliseconds: 400));
    await tester.tap(confirm);
    await waitFor(tester, find.text(AppStrings.orderQuickAccepted));
    await waitGone(tester, acceptButton);
    results['accepted'] = acceptId;
    await shot(tester, 'after_accept');

    await tester.ensureVisible(rejectButton);
    await pumpFrames(tester, const Duration(milliseconds: 500));
    await tester.tap(rejectButton);
    await waitFor(tester, find.byKey(const Key('order-reject-reason')));
    await tester.enterText(
      find.byKey(const Key('order-reject-reason')),
      'TEST FIXTURE isolée — rupture',
    );
    await tester.pump(const Duration(milliseconds: 400));
    await shot(tester, 'reject_sheet');
    await tester.tap(find.byKey(const Key('order-reject-confirm')));
    await waitFor(tester, find.text(AppStrings.orderQuickRejected));
    await waitGone(tester, rejectButton);
    results['rejected'] = rejectId;
    await shot(tester, 'after_reject');
  }

  Future<void> branchRename(WidgetTester tester) async {
    final field = find.byKey(const Key('store-general-branch-name'));
    String fieldText() => tester.widget<TextField>(field).controller!.text;

    await push(tester, AppRoutes.storeGeneral);
    await waitFor(tester, field);
    expect(fieldText(), branchName);
    await tester.enterText(field, renamed);
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.byKey(const Key('store-general-save')));
    await waitFor(tester, find.text(AppStrings.storeGeneralSaved));
    await waitGone(tester, field);
    await shot(tester, 'branch_saved');

    await pumpApp(tester);
    await waitFor(tester, find.byKey(const Key('home-branch-name')));
    expect(find.textContaining(renamed), findsWidgets);
    await push(tester, AppRoutes.storeGeneral);
    await waitFor(tester, field);
    expect(fieldText(), renamed);
    results['branchAfterFreshInstance'] = fieldText();
    await shot(tester, 'branch_reopened');

    await tester.enterText(field, branchName);
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.byKey(const Key('store-general-save')));
    await waitFor(tester, find.text(AppStrings.storeGeneralSaved));
    await waitGone(tester, field);
    routerOf(tester).go(AppRoutes.home);
    await waitFor(tester, find.byKey(const Key('home-branch-name')));
    await pumpFrames(tester, const Duration(seconds: 2));
    expect(find.textContaining(renamed), findsNothing);
    results['branchRestoredTo'] = branchName;
  }

  Future<void> expectEditorOpened(WidgetTester tester, String role) async {
    await waitFor(tester, find.byKey(const Key('product-editor-screen')));
    await waitFor(
      tester,
      find.descendant(
        of: find.byKey(const Key('product-editor-name')),
        matching: find.text(topProductName),
      ),
    );
  }

  Future<void> closeEditor(WidgetTester tester) async {
    routerOf(tester).pop();
    await waitGone(tester, find.byKey(const Key('product-editor-screen')));
  }

  Future<void> scrollReportsTo(WidgetTester tester, Finder target) async {
    await tester.scrollUntilVisible(
      target,
      300,
      scrollable: find
          .descendant(
            of: find.byKey(const Key('reports-screen')),
            matching: find.byType(Scrollable),
          )
          .first,
      maxScrolls: 40,
    );
    await pumpFrames(tester, const Duration(milliseconds: 600));
  }

  Future<void> reportsOwner(WidgetTester tester) async {
    routerOf(tester).go(AppRoutes.reports);
    final firstRow = find.byKey(const Key('reports-top-product-1'));
    await waitFor(tester, find.byKey(const Key('reports-metric-orders')));
    expect(find.byKey(const Key('reports-gross')), findsOneWidget);
    await shot(tester, 'reports');
    await scrollReportsTo(tester, firstRow);
    expect(
      find.descendant(of: firstRow, matching: find.text(topProductName)),
      findsOneWidget,
    );
    expect(find.byKey(const Key('reports-top-products-empty')), findsNothing);
    expect(
      find.byKey(const Key('reports-top-product-chevron-1')),
      findsOneWidget,
    );
    await shot(tester, 'reports_top_section');
    await tester.tap(firstRow);
    await expectEditorOpened(tester, 'OWNER');
    results['ownerOverviewRowOpensEditor'] = true;
    await closeEditor(tester);
  }

  Future<void> topProducts(
    WidgetTester tester,
    String role, {
    required bool canEdit,
  }) async {
    await push(tester, AppRoutes.reportsTopProducts);
    final firstRow = find.byKey(const Key('top-product-1'));
    await waitFor(tester, firstRow);
    expect(
      find.descendant(of: firstRow, matching: find.text(topProductName)),
      findsOneWidget,
    );
    expect(find.byKey(const Key('top-products-empty')), findsNothing);
    final rows = find.byWidgetPredicate(
      (w) =>
          w.key is ValueKey<String> &&
          RegExp(r'^top-product-\d+$').hasMatch((w.key! as ValueKey<String>).value),
    );
    final chevrons = find.byWidgetPredicate(
      (w) =>
          w.key is ValueKey<String> &&
          (w.key! as ValueKey<String>).value.startsWith('top-product-chevron-'),
    );
    results['topRows_$role'] = rows.evaluate().length;
    results['topChevrons_$role'] = chevrons.evaluate().length;
    final tag = 'top_products_${role.toLowerCase()}';
    await shot(tester, tag);
    if (canEdit) {
      expect(chevrons, findsWidgets);
      await tester.tap(firstRow);
      await expectEditorOpened(tester, role);
      await shot(tester, 'editor_${role.toLowerCase()}');
      results['topRowOpensEditor_$role'] = true;
      await closeEditor(tester);
    } else {
      expect(rows, findsWidgets);
      expect(chevrons, findsNothing);
      await tester.tap(firstRow);
      await pumpFrames(tester, const Duration(seconds: 2));
      expect(find.byKey(const Key('product-editor-screen')), findsNothing);
      expect(find.byKey(const Key('top-products-screen')), findsOneWidget);
      results['topRowOpensEditor_$role'] = false;
    }
  }

  Future<void> staffOverview(WidgetTester tester) async {
    routerOf(tester).go(AppRoutes.reports);
    final firstRow = find.byKey(const Key('reports-top-product-1'));
    await waitFor(tester, find.byKey(const Key('reports-metric-orders')));
    await scrollReportsTo(tester, firstRow);
    expect(find.byKey(const Key('reports-top-product-chevron-1')), findsNothing);
    await tester.tap(firstRow);
    await pumpFrames(tester, const Duration(seconds: 2));
    expect(find.byKey(const Key('product-editor-screen')), findsNothing);
    results['staffOverviewRowOpensEditor'] = false;
    await shot(tester, 'reports_staff');
  }

  testWidgets('isolated fixture writes and role navigation', (tester) async {
    expect(
      AppConstants.apiBaseUrl,
      isolatedApi,
      reason: 'refusing to run outside the isolated API',
    );
    expect(otpFilePath, endsWith('/.speedygo/parity_fx/otp/otp-last'));
    expect(evidenceDir, isNotEmpty);
    expect(acceptId, isNotEmpty);
    expect(rejectId, isNotEmpty);
    var role = 'OWNER';
    try {
      await login(tester, owner);
      await acceptReject(tester);
      await branchRename(tester);
      await reportsOwner(tester);
      await topProducts(tester, 'OWNER', canEdit: true);
      await logout(tester, 'OWNER');

      role = 'MANAGER';
      await login(tester, manager);
      await topProducts(tester, 'MANAGER', canEdit: true);
      await logout(tester, 'MANAGER');

      role = 'STAFF';
      await login(tester, staff);
      await topProducts(tester, 'STAFF', canEdit: false);
      await staffOverview(tester);
      await logout(tester, 'STAFF');
    } catch (e) {
      results['failedRole'] = role;
      rethrow;
    } finally {
      await revokeDedicatedSession(tester);
      File(shotMarker).writeAsStringSync('${prefix}_99_done\n');
      File('$evidenceDir/PROVENANCE_$prefix.json').writeAsStringSync(
        const JsonEncoder.withIndent('  ').convert({
          'app': 'merchant',
          'backend': 'isolated (speedygo_parity_fx via 127.0.0.1:3100)',
          'apiBaseUrl': AppConstants.apiBaseUrl,
          'prefix': prefix,
          'session':
              'one OTP session per role, app stores in memory (Keychain untouched)',
          'acceptOrderId': acceptId,
          'rejectOrderId': rejectId,
          'branchId': branchId,
          'results': results,
          'steps': steps,
        }),
      );
    }
  });
}
