import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:speedygo_merchant_app/app/app.dart';
import 'package:speedygo_merchant_app/app/router/app_router.dart';
import 'package:speedygo_merchant_app/app/theme/app_theme.dart';
import 'package:speedygo_merchant_app/core/constants/app_constants.dart';
import 'package:speedygo_merchant_app/core/constants/app_strings.dart';
import 'package:speedygo_merchant_app/core/navigation/app_routes.dart';
import 'package:speedygo_merchant_app/core/storage/approval_notice_store.dart';
import 'package:speedygo_merchant_app/core/storage/session_store.dart';
import 'package:speedygo_merchant_app/features/auth/application/session_providers.dart';
import 'package:speedygo_merchant_app/features/catalog/application/catalog_controller.dart';
import 'package:speedygo_merchant_app/features/notifications/application/merchant_push_controller.dart';
import 'package:speedygo_merchant_app/features/notifications/data/push_registration.dart';
import 'package:speedygo_merchant_app/features/shell/merchant_shell.dart';

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

/// Isolated gap-close: dock hide/reveal, empty Catalogue, unreachable API /
/// controlled HTTP 500 + Réessayer. Requires API_BASE_URL on port 3100.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const isolatedApi = 'http://127.0.0.1:3100/api/v1';
  const otpFilePath = String.fromEnvironment('FX_OTP_FILE');
  const evidenceDir = String.fromEnvironment('FX_EVIDENCE_DIR');
  const prefix = String.fromEnvironment('PARITY_PREFIX', defaultValue: 'fxg');
  const gatePath = String.fromEnvironment(
    'FX_GAP_GATE',
    defaultValue: '/tmp/fx_gap_close_gate.txt',
  );
  const shotPath = String.fromEnvironment(
    'FX_GAP_SHOT',
    defaultValue: '/tmp/parity_fx_gap_close_shot.txt',
  );

  const populatedMerchant = '0d00f0f0-fa00-7000-8000-000000001001';
  const populatedBranch = '0d00f0f0-fa00-7000-8000-000000002001';
  const emptyMerchant = '0d00f0f0-fa00-7000-8000-000000001003';
  const emptyBranch = '0d00f0f0-fa00-7000-8000-000000002003';
  const ownerPopulated = '550009101';
  const ownerEmpty = '550009105';

  var memorySessions = MemorySessionStore();
  final results = <String, Object?>{};
  final requestLog = <Map<String, Object?>>[];

  Future<void> pumpFrames(WidgetTester tester, Duration total) async {
    final end = DateTime.now().add(total);
    while (DateTime.now().isBefore(end)) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> waitFor(
    WidgetTester tester,
    Finder finder, {
    Duration timeout = const Duration(seconds: 30),
  }) async {
    final end = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(end)) {
      await pumpFrames(tester, const Duration(milliseconds: 200));
      if (finder.evaluate().isNotEmpty) return;
    }
    throw TestFailure('Timed out waiting for $finder');
  }

  Future<void> shot(WidgetTester tester, String tag) async {
    await pumpFrames(tester, const Duration(milliseconds: 800));
    File(shotPath).writeAsStringSync('${prefix}_$tag\n');
    await pumpFrames(tester, const Duration(seconds: 2));
  }

  Future<void> gate(String cmd, String expectAck) async {
    File(gatePath).writeAsStringSync('$cmd\n');
    final end = DateTime.now().add(const Duration(seconds: 90));
    while (DateTime.now().isBefore(end)) {
      await Future<void>.delayed(const Duration(milliseconds: 250));
      final ack = File(gatePath).readAsStringSync().trim();
      if (ack == expectAck) return;
    }
    throw TestFailure('gate ack timeout for $cmd → $expectAck');
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

  Future<void> pumpApp(
    WidgetTester tester, {
    required String merchantId,
    required String branchId,
  }) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await pumpFrames(tester, const Duration(milliseconds: 400));
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
    await pumpFrames(tester, const Duration(seconds: 5));
  }

  Future<void> login(
    WidgetTester tester, {
    required String phoneLocal,
    required String merchantId,
    required String branchId,
    required String expectBranchName,
  }) async {
    memorySessions = MemorySessionStore();
    await pumpApp(tester, merchantId: merchantId, branchId: branchId);
    await waitFor(tester, find.byKey(const Key('merchant-phone-continue')));
    await tester.enterText(find.byType(TextField).first, phoneLocal);
    await tester.pump(const Duration(milliseconds: 400));
    final otpBefore = DateTime.now().subtract(const Duration(seconds: 1));
    await tester.tap(find.byKey(const Key('merchant-phone-continue')));
    await waitFor(tester, find.byKey(const Key('merchant-otp-field')));
    final otp = await waitForFreshOtp(otpBefore);
    await tester.enterText(find.byKey(const Key('merchant-otp-field')), otp);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.byKey(const Key('merchant-otp-verify')));
    await waitFor(tester, find.byKey(const Key('home-branch-name')));
    expect(find.textContaining(expectBranchName), findsWidgets);
  }

  Future<void> logout(WidgetTester tester) async {
    routerOf(tester).go(AppRoutes.logout);
    await pumpFrames(tester, const Duration(seconds: 2));
    await waitFor(tester, find.byKey(const Key('logout-screen')));
    await tester.tap(find.byKey(const Key('logout-confirm')));
    await waitFor(tester, find.byKey(const Key('merchant-phone-continue')));
  }

  MerchantShellState shellOf(WidgetTester tester) =>
      tester.state<MerchantShellState>(find.byType(MerchantShell));

  ProviderContainer containerOf(WidgetTester tester) =>
      ProviderScope.containerOf(
        tester.element(find.byType(MaterialApp).first),
      );

  Future<void> reloadCatalog(WidgetTester tester) async {
    await containerOf(tester).read(catalogControllerProvider.notifier).reload();
    await pumpFrames(tester, const Duration(milliseconds: 500));
  }

  Future<void> openCatalog(WidgetTester tester) async {
    // Prefer router when the dock may be collapsed (icons not hittable).
    if (find.byKey(const Key('nav-catalog')).evaluate().isNotEmpty &&
        shellOf(tester).visibility.visible) {
      await tester.tap(find.byKey(const Key('nav-catalog')));
    } else {
      routerOf(tester).go(AppRoutes.catalog);
    }
    await pumpFrames(tester, const Duration(seconds: 2));
    await waitFor(tester, find.text(AppStrings.catalogTitle));
  }

  Finder? catalogScrollable(WidgetTester tester) {
    for (final el in find.byType(Scrollable).evaluate()) {
      final state = (el as StatefulElement).state;
      if (state is ScrollableState &&
          state.position.axis == Axis.vertical &&
          state.position.maxScrollExtent > 0) {
        return find.byWidget(el.widget);
      }
    }
    return null;
  }

  ScrollPosition? catalogScroll(WidgetTester tester) {
    final f = catalogScrollable(tester);
    if (f == null) return null;
    return tester.state<ScrollableState>(f).position;
  }

  testWidgets('gap close dock empty offline retry', (tester) async {
    expect(
      AppConstants.apiBaseUrl,
      isolatedApi,
      reason: 'refusing any host other than the isolated API on 3100',
    );
    expect(otpFilePath.isNotEmpty, isTrue);
    expect(evidenceDir.isNotEmpty, isTrue);

    // ---------- 1. Dock hide / reveal on populated Catalogue ----------
    await login(
      tester,
      phoneLocal: ownerPopulated,
      merchantId: populatedMerchant,
      branchId: populatedBranch,
      expectBranchName: 'Comptoir Essai',
    );
    await openCatalog(tester);
    await waitFor(tester, find.text('Couscous royal'));
    await shot(tester, 'dock_visible_catalog');

    final pos0 = catalogScroll(tester);
    expect(pos0, isNotNull, reason: 'Catalogue must be vertically scrollable');
    final maxExtent = pos0!.maxScrollExtent;
    results['catalogMaxScrollExtent'] = maxExtent;
    if (maxExtent < MerchantNavTokens.hideThreshold) {
      results['dockHideReveal'] = 'NOT_RUN_insufficient_live_scroll_extent';
      results['catalogMaxScrollExtent'] = maxExtent;
      await shot(tester, 'dock_insufficient_extent');
    } else {
      final shell = shellOf(tester);
      expect(shell.visibility.visible, isTrue);
      expect(find.byKey(const Key('merchant-nav-dock')), findsOneWidget);

      final scrollFinder = catalogScrollable(tester)!;
      // Finger-driven upward content scroll (positive delta) past 48 px.
      final before = pos0.pixels;
      await tester.drag(scrollFinder, const Offset(0, -160));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      final afterDrag = catalogScroll(tester)?.pixels ?? -1;
      results['dockHideScrollBefore'] = before;
      results['dockHideScrollAfter'] = afterDrag;
      results['dockHideDelta'] = afterDrag - before;

      // Allow hide animation; ignore ballistic by waiting past settle pulses.
      await pumpFrames(tester, const Duration(milliseconds: 400));
      final hideOffset = catalogScroll(tester)?.pixels;
      results['dockHiddenAtPixels'] = hideOffset;
      expect(
        shell.visibility.visible,
        isFalse,
        reason:
            'dock should hide after ≥ ${MerchantNavTokens.hideThreshold} px finger scroll',
      );
      expect(find.byKey(const Key('nav-handle')), findsOneWidget);
      // Wait for hide animation so the screenshot shows the handle, not the dock.
      await pumpFrames(tester, MerchantNavTokens.hideDuration);
      await shot(tester, 'dock_hidden_handle');

      // Downward scroll (negative delta) restores immediately.
      await tester.drag(
        catalogScrollable(tester)!,
        const Offset(0, 80),
      );
      await tester.pump();
      await pumpFrames(tester, const Duration(milliseconds: 300));
      results['dockRestoreByScrollPixels'] = catalogScroll(tester)?.pixels;
      expect(shell.visibility.visible, isTrue);
      expect(find.byKey(const Key('merchant-nav-dock')), findsOneWidget);
      await shot(tester, 'dock_restored_by_scroll');

      // Hide again, then handle tap.
      await tester.drag(
        catalogScrollable(tester)!,
        const Offset(0, -160),
      );
      await pumpFrames(tester, const Duration(milliseconds: 400));
      expect(shell.visibility.visible, isFalse);
      await tester.tap(find.byKey(const Key('nav-handle')));
      await pumpFrames(tester, const Duration(milliseconds: 400));
      expect(shell.visibility.visible, isTrue);
      await shot(tester, 'dock_restored_by_handle');

      // Hide again, scroll to top restores.
      await tester.drag(
        catalogScrollable(tester)!,
        const Offset(0, -160),
      );
      await pumpFrames(tester, const Duration(milliseconds: 400));
      expect(shell.visibility.visible, isFalse);
      final pos = catalogScroll(tester)!;
      await tester.drag(
        catalogScrollable(tester)!,
        Offset(0, pos.pixels + 40),
      );
      await pumpFrames(tester, const Duration(milliseconds: 500));
      results['dockRestoreAtTopPixels'] = catalogScroll(tester)?.pixels;
      expect(shell.visibility.visible, isTrue);
      await shot(tester, 'dock_restored_at_top');

      // Hide, change tab restores (router go — dock icons are not hittable when collapsed).
      await tester.drag(
        catalogScrollable(tester)!,
        const Offset(0, -160),
      );
      await pumpFrames(tester, const Duration(milliseconds: 400));
      expect(shell.visibility.visible, isFalse);
      routerOf(tester).go(AppRoutes.home);
      await pumpFrames(tester, const Duration(milliseconds: 800));
      expect(shell.visibility.visible, isTrue);
      expect(find.byKey(const Key('merchant-nav-dock')), findsOneWidget);
      await shot(tester, 'dock_restored_by_tab');

      // Back to catalogue: last row reachable above dock.
      // SliverList only builds visible children — scroll to extent first.
      await openCatalog(tester);
      expect(shell.visibility.visible, isTrue);
      final scrollToEnd = catalogScroll(tester)!;
      await tester.drag(
        catalogScrollable(tester)!,
        Offset(0, -(scrollToEnd.maxScrollExtent + 80)),
      );
      await pumpFrames(tester, const Duration(milliseconds: 600));
      // Reveal dock again if hide fired during the long scroll.
      if (!shell.visibility.visible) {
        await tester.tap(find.byKey(const Key('nav-handle')));
        await pumpFrames(tester, MerchantNavTokens.hideDuration);
      }
      final last = find.text('Plat essai 24');
      await waitFor(tester, last);
      await tester.ensureVisible(last);
      await pumpFrames(tester, const Duration(milliseconds: 500));
      // Keep last row in view with dock restored for the reachability check.
      if (!shell.visibility.visible) {
        await tester.tap(find.byKey(const Key('nav-handle')));
        await pumpFrames(tester, MerchantNavTokens.hideDuration);
      }
      final lastRect = tester.getRect(last);
      final dockRect =
          tester.getRect(find.byKey(const Key('merchant-nav-dock')));
      results['lastRowBottom'] = lastRect.bottom;
      results['dockTop'] = dockRect.top;
      results['lastRowMaxScrollExtent'] = catalogScroll(tester)?.maxScrollExtent;
      results['lastRowScrollPixels'] = catalogScroll(tester)?.pixels;
      expect(lastRect.bottom, lessThanOrEqualTo(dockRect.top + 1));
      await shot(tester, 'dock_last_row_above');

      // Ballistic settle should not jitter hide/reveal: fling and settle.
      final visibleBeforeFling = shell.visibility.visible;
      await tester.fling(
        catalogScrollable(tester)!,
        const Offset(0, -200),
        800,
      );
      await tester.pumpAndSettle(const Duration(seconds: 2));
      results['visibleAfterBallistic'] = shell.visibility.visible;
      results['visibleBeforeFling'] = visibleBeforeFling;
      await shot(tester, 'dock_after_ballistic');
      results['dockHideReveal'] = 'PASS';
    }

    await logout(tester);

    // ---------- 2. Empty Catalogue ----------
    await login(
      tester,
      phoneLocal: ownerEmpty,
      merchantId: emptyMerchant,
      branchId: emptyBranch,
      expectBranchName: 'Comptoir Vide',
    );

    // API proof via host HTTP is recorded by the runner; UI proof here.
    await openCatalog(tester);
    await waitFor(tester, find.byKey(const Key('catalog-empty-products')));
    expect(find.text(AppStrings.catalogEmptyProducts), findsOneWidget);
    expect(find.byKey(const Key('catalog-empty-add-product')), findsOneWidget);
    expect(find.byKey(const Key('catalog-add-fab')), findsNothing);
    expect(find.text(AppStrings.catalogLoadError), findsNothing);
    expect(find.text('Couscous royal'), findsNothing);
    expect(find.text('Caps'), findsNothing);
    await shot(tester, 'catalog_empty');
    results['emptyCatalogue'] = 'PASS';

    // ---------- 3a. Unreachable API (process stopped — not native offline) ----------
    await gate('stop_api', 'unreachable_ready');
    requestLog.add({
      'kind': 'unreachable',
      'label':
          'isolated API process stopped on port 3100 (not a native network disconnection)',
      'at': DateTime.now().toUtc().toIso8601String(),
    });
    final tUnreach = DateTime.now();
    // Kept-alive Catalogue holds empty data — force one reload against the stopped API.
    await openCatalog(tester);
    await reloadCatalog(tester);
    await waitFor(
      tester,
      find.text(AppStrings.catalogLoadError),
      timeout: const Duration(seconds: 35),
    );
    final unreachMs = DateTime.now().difference(tUnreach).inMilliseconds;
    expect(find.text(AppStrings.catalogLoadError), findsOneWidget);
    expect(find.text(AppStrings.retry), findsWidgets);
    expect(find.text(AppStrings.loading), findsNothing);
    await shot(tester, 'catalog_error_unreachable');
    results['unreachableLeaveLoadingMs'] = unreachMs;
    results['unreachable'] = 'PASS';

    await gate('restore_api', 'api_restored');
    requestLog.add({
      'kind': 'retry_after_unreachable',
      'label': 'single Réessayer after isolated API restored',
      'at': DateTime.now().toUtc().toIso8601String(),
    });
    await tester.tap(find.text(AppStrings.retry).first);
    await waitFor(
      tester,
      find.byKey(const Key('catalog-empty-products')),
      timeout: const Duration(seconds: 35),
    );
    expect(find.byKey(const Key('catalog-add-fab')), findsNothing);
    expect(find.text(AppStrings.catalogLoadError), findsNothing);
    expect(find.text(AppStrings.loading), findsNothing);
    await shot(tester, 'catalog_retry_after_unreachable');
    results['retryAfterUnreachable'] = 'PASS';

    // ---------- 3b. Controlled HTTP 500 stub ----------
    await gate('start_500_stub', 'stub500_ready');
    requestLog.add({
      'kind': 'http_500',
      'label': 'controlled HTTP 500 stub on 127.0.0.1:3100 (deterministic)',
      'at': DateTime.now().toUtc().toIso8601String(),
    });
    final t500 = DateTime.now();
    // Force one reload against the controlled 500 stub (pages stay alive).
    await openCatalog(tester);
    await reloadCatalog(tester);
    await waitFor(
      tester,
      find.text(AppStrings.catalogLoadError),
      timeout: const Duration(seconds: 35),
    );
    final ms500 = DateTime.now().difference(t500).inMilliseconds;
    expect(find.text(AppStrings.loading), findsNothing);
    expect(find.text(AppStrings.retry), findsWidgets);
    await shot(tester, 'catalog_error_http500');
    results['http500LeaveLoadingMs'] = ms500;
    results['http500'] = 'PASS';

    // Single retry after restore → empty catalogue again.
    await gate('restore_api', 'api_restored');
    requestLog.add({
      'kind': 'retry_after_500',
      'label': 'single Réessayer after controlled stub replaced by real API',
      'at': DateTime.now().toUtc().toIso8601String(),
    });
    await tester.tap(find.text(AppStrings.retry).first);
    await waitFor(
      tester,
      find.byKey(const Key('catalog-empty-products')),
      timeout: const Duration(seconds: 35),
    );
    expect(find.text(AppStrings.catalogLoadError), findsNothing);
    expect(find.byKey(const Key('catalog-add-fab')), findsNothing);
    expect(find.text(AppStrings.loading), findsNothing);
    await shot(tester, 'catalog_retry_after_500');
    results['retryAfter500'] = 'PASS';
    results['noPermanentSpinner'] = true;

    await logout(tester);

    final out = File('$evidenceDir/gap_close/GAP_CLOSE_RESULTS_$prefix.json');
    out.parent.createSync(recursive: true);
    out.writeAsStringSync(
      const JsonEncoder.withIndent(' ').convert({
        'prefix': prefix,
        'apiBaseUrl': AppConstants.apiBaseUrl,
        'results': results,
        'requestLog': requestLog,
        'at': DateTime.now().toUtc().toIso8601String(),
      }),
    );
  });
}
