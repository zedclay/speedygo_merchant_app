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

/// Tracked fixture writes for the Merchant parity pass (dev backend only).
///
/// 1. List-card accept / reject (D-B2) on two CREATED COD orders created for
///    this run on Dar El Bahja (`FX_ACCEPT_ORDER_ID`, `FX_REJECT_ORDER_ID`).
///    The icon-only reject is checked and opened through its accessibility
///    label and tap action.
/// 2. Branch-name persistence (D-D1) on the Atelier Sucré branch: rename,
///    reopen in a fresh app instance, then restore the original name.
///
/// One dedicated OTP session with every app store in memory (Keychain never
/// read or written); it is revoked at the end, also on failure. Screenshots
/// are taken by the host watcher from [shotMarker].
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const phoneLocal = '550000071';
  const otpFilePath = '/Users/mac/.speedygo/dev/otp-last';
  const prefix = String.fromEnvironment('PARITY_PREFIX', defaultValue: 'fx');
  const acceptId = String.fromEnvironment('FX_ACCEPT_ORDER_ID');
  const rejectId = String.fromEnvironment('FX_REJECT_ORDER_ID');
  const ordersMerchant = '0d00c071-d000-7000-8000-000000010001';
  const ordersBranch = '0d00c071-d000-7000-8000-000000011001';
  const renameMerchant = '0d00c071-d000-7000-8000-000000010010';
  const renameBranch = '0d00c071-d000-7000-8000-000000011010';
  const renamed = 'Atelier Sucré TEST FIXTURE P5';
  const shotMarker = '/tmp/parity_live_shot.txt';
  final outDir = Directory(
    '/Users/mac/Downloads/speedygo_project/apps/merchant_app/audit/parity/live',
  );

  final memorySessions = MemorySessionStore();
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
    throw StateError('OTP not found');
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

  /// A new app instance on [merchantId]/[branchId]; only the in-memory
  /// session survives from the previous instance.
  Future<void> pumpApp(
    WidgetTester tester,
    String merchantId,
    String branchId,
  ) async {
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

  Future<void> login(WidgetTester tester) async {
    await pumpApp(tester, ordersMerchant, ordersBranch);
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
    expect(find.textContaining('Dar El Bahja'), findsWidgets);
  }

  Future<void> revokeDedicatedSession(WidgetTester tester) async {
    if (!sessionCreated) return;
    final app = find.byType(MaterialApp);
    if (app.evaluate().isEmpty) {
      await pumpApp(tester, ordersMerchant, ordersBranch);
    }
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

  /// New orders raise the full-screen alert above the navigator; close each
  /// one with its dismiss button, as a merchant would.
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
      if (dismissed == 0) await shot(tester, 'fx_alert');
      await tester.tap(dismiss);
      dismissed++;
    }
    expect(alert, findsNothing);
    results['alertsDismissed'] = dismissed;
  }

  Future<void> listCardActions(WidgetTester tester) async {
    routerOf(tester).go(AppRoutes.orders);
    final acceptButton = find.byKey(const Key('order-card-accept-$acceptId'));
    final rejectButton = find.byKey(const Key('order-card-reject-$rejectId'));
    await waitFor(tester, acceptButton);
    await waitFor(tester, rejectButton);
    await dismissAlerts(tester);
    await tester.ensureVisible(find.byKey(const Key('order-card-$acceptId')));
    await pumpFrames(tester, const Duration(milliseconds: 500));
    results['acceptHeaderStacked'] = find
        .byKey(const Key('order-card-header-stacked-$acceptId'))
        .evaluate()
        .isNotEmpty;
    await shot(tester, 'fx_incoming');

    await tester.tap(acceptButton);
    await waitFor(tester, find.byKey(const Key('accept-prep-sheet')));
    await shot(tester, 'fx_accept_sheet');
    final confirm = find.byKey(const Key('accept-prep-confirm'));
    await tester.ensureVisible(confirm);
    await pumpFrames(tester, const Duration(milliseconds: 400));
    await tester.tap(confirm);
    await waitFor(tester, find.text(AppStrings.orderQuickAccepted));
    await waitGone(tester, acceptButton);
    results['acceptSnack'] = AppStrings.orderQuickAccepted;
    await shot(tester, 'fx_after_accept');

    final semantics = tester.ensureSemantics();
    try {
      await tester.ensureVisible(rejectButton);
      await pumpFrames(tester, const Duration(milliseconds: 500));
      // iOS exposes no separate focus action (host tests also assert it).
      expect(
        tester.getSemantics(rejectButton),
        matchesSemantics(
          label: AppStrings.orderRejectTitle,
          isButton: true,
          hasTapAction: true,
          isEnabled: true,
          hasEnabledState: true,
          isFocusable: true,
        ),
      );
      results['rejectSemanticsLabel'] = AppStrings.orderRejectTitle;
      final labelled = find.semantics.byLabel(AppStrings.orderRejectTitle);
      expect(labelled, findsOne);
      tester.semantics.tap(labelled);
      results['rejectOpenedBy'] = 'semantics tap action';
    } finally {
      semantics.dispose();
    }
    await waitFor(tester, find.byKey(const Key('order-reject-reason')));
    await tester.enterText(
      find.byKey(const Key('order-reject-reason')),
      'TEST FIXTURE parity pass 5 — rupture',
    );
    await tester.pump(const Duration(milliseconds: 400));
    await shot(tester, 'fx_reject_sheet');
    await tester.tap(find.byKey(const Key('order-reject-confirm')));
    await waitFor(tester, find.text(AppStrings.orderQuickRejected));
    await waitGone(tester, rejectButton);
    results['rejectSnack'] = AppStrings.orderQuickRejected;
    await shot(tester, 'fx_after_reject');
  }

  Future<void> branchRename(WidgetTester tester) async {
    final field = find.byKey(const Key('store-general-branch-name'));
    String fieldText() => tester.widget<TextField>(field).controller!.text;

    await pumpApp(tester, renameMerchant, renameBranch);
    await waitFor(tester, find.byKey(const Key('home-branch-name')));
    await push(tester, AppRoutes.storeGeneral);
    await waitFor(tester, field);
    final original = fieldText();
    expect(original, 'Atelier Sucré');
    results['branchOriginal'] = original;

    await tester.enterText(field, renamed);
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.byKey(const Key('store-general-save')));
    await waitFor(tester, find.text(AppStrings.storeGeneralSaved));
    await waitGone(tester, field);
    results['branchRenamedTo'] = renamed;
    results['screenClosedAfterSave'] = true;
    await shot(tester, 'fx_branch_saved');

    await pumpApp(tester, renameMerchant, renameBranch);
    await waitFor(tester, find.byKey(const Key('home-branch-name')));
    expect(find.textContaining(renamed), findsWidgets);
    await push(tester, AppRoutes.storeGeneral);
    await waitFor(tester, field);
    expect(fieldText(), renamed);
    results['branchAfterFreshInstance'] = fieldText();
    await shot(tester, 'fx_branch_reopened');

    await tester.enterText(field, original);
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.byKey(const Key('store-general-save')));
    await waitFor(tester, find.text(AppStrings.storeGeneralSaved));
    await waitGone(tester, field);
    routerOf(tester).go(AppRoutes.home);
    await waitFor(tester, find.byKey(const Key('home-branch-name')));
    await pumpFrames(tester, const Duration(seconds: 2));
    expect(find.textContaining(renamed), findsNothing);
    expect(find.textContaining(original), findsWidgets);
    results['branchRestoredTo'] = original;
  }

  testWidgets('parity fixture writes: list-card accept/reject, branch name', (
    tester,
  ) async {
    expect(acceptId, isNotEmpty);
    expect(rejectId, isNotEmpty);
    try {
      await login(tester);
      await listCardActions(tester);
      await branchRename(tester);

      await push(tester, AppRoutes.logout);
      await waitFor(tester, find.byKey(const Key('logout-screen')));
      await tester.tap(find.byKey(const Key('logout-confirm')));
      await waitFor(tester, find.byKey(const Key('merchant-phone-continue')));
      results['sessionRevokedByLogout'] = true;
    } finally {
      await revokeDedicatedSession(tester);
      File(shotMarker).writeAsStringSync('${prefix}_99_done\n');
      File('${outDir.path}/PROVENANCE_FIXTURE_$prefix.json').writeAsStringSync(
        const JsonEncoder.withIndent('  ').convert({
          'app': 'merchant',
          'backend': 'local dev',
          'prefix': prefix,
          'session':
              'dedicated OTP session, app stores in memory (Keychain untouched)',
          'acceptOrderId': acceptId,
          'rejectOrderId': rejectId,
          'renameBranchId': renameBranch,
          'results': results,
          'steps': steps,
        }),
      );
    }
  });
}
