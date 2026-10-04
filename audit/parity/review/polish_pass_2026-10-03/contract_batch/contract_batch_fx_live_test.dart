import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:image/image.dart' as img;
import 'package:integration_test/integration_test.dart';
import 'package:speedygo_merchant_app/features/catalog/presentation/product_editor_screen.dart';
import 'package:speedygo_merchant_app/app/app.dart';
import 'package:speedygo_merchant_app/app/router/app_router.dart';
import 'package:speedygo_merchant_app/core/constants/app_constants.dart';
import 'package:speedygo_merchant_app/core/constants/app_strings.dart';
import 'package:speedygo_merchant_app/core/navigation/app_routes.dart';
import 'package:speedygo_merchant_app/core/storage/approval_notice_store.dart';
import 'package:speedygo_merchant_app/core/storage/session_store.dart';
import 'package:speedygo_merchant_app/features/access/data/merchant_api.dart';
import 'package:speedygo_merchant_app/features/auth/application/auth_infrastructure.dart';
import 'package:speedygo_merchant_app/features/auth/application/session_controller.dart';
import 'package:speedygo_merchant_app/features/auth/application/session_providers.dart';
import 'package:speedygo_merchant_app/features/auth/application/session_state.dart';
import 'package:speedygo_merchant_app/features/notifications/application/merchant_push_controller.dart';
import 'package:speedygo_merchant_app/features/notifications/data/push_registration.dart';
import 'package:speedygo_merchant_app/features/store/application/opening_hours_format.dart';
import 'package:speedygo_merchant_app/features/store/application/store_controllers.dart';
import 'package:speedygo_merchant_app/features/store/data/store_models.dart';
import 'package:speedygo_merchant_app/features/store/presentation/opening_hours_exceptions_screen.dart';
import 'package:speedygo_merchant_app/features/store/presentation/store_cover_screen.dart';

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

/// Contract-completion batch (logo, exceptional hours, duplication) against
/// the disposable environment only (`speedygo_parity_fx` on 127.0.0.1:3100).
///
/// OWNER: logo empty → save → profile header → fresh app instance → replace
/// (bytes compared by SHA-256, no stale image) → remove → fallback;
/// exceptional date create → fresh instance → edit with a concurrent server
/// change (409, draft kept) → delete; a closed exception for today flips the
/// Merchant effective state, deleting it restores weekly hours; duplicate
/// Couscous royal through the menu (double tap) → editor of the copy.
/// MANAGER: logo controls, exception editor, duplicate Poulet rôti.
/// STAFF: logo and exceptions read-only, no product menu, duplicate refused.
///
/// One memory-only OTP session per role (Keychain never read or written),
/// each ended by the app's logout. Screenshots by the host watcher.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const isolatedApi = 'http://127.0.0.1:3100/api/v1';
  const otpFilePath = String.fromEnvironment('FX_OTP_FILE');
  const evidenceDir = String.fromEnvironment('FX_EVIDENCE_DIR');
  const prefix = String.fromEnvironment('PARITY_PREFIX', defaultValue: 'fxc');
  const merchantId = '0d00f0f0-fa00-7000-8000-000000001001';
  const branchId = '0d00f0f0-fa00-7000-8000-000000002001';
  const couscousId = '0d00f0f0-fa00-7000-8000-000000007001';
  const pouletId = '0d00f0f0-fa00-7000-8000-000000007002';
  const branchName = 'Comptoir Essai';
  const owner = '550009101';
  const manager = '550009102';
  const staff = '550009103';
  const shotMarker = '/tmp/parity_fx_isolated_shot.txt';

  var memorySessions = MemorySessionStore();
  var sessionCreated = false;
  final steps = <Map<String, Object?>>[];
  final results = <String, Object?>{};

  Uint8List logo(List<int> outer, List<int> inner) {
    final image = img.Image(width: 256, height: 256);
    img.fill(image, color: img.ColorRgb8(255, 255, 255));
    img.fillCircle(
      image,
      x: 128,
      y: 128,
      radius: 120,
      color: img.ColorRgb8(outer[0], outer[1], outer[2]),
    );
    img.fillCircle(
      image,
      x: 128,
      y: 128,
      radius: 70,
      color: img.ColorRgb8(inner[0], inner[1], inner[2]),
    );
    return Uint8List.fromList(img.encodeJpg(image, quality: 90));
  }

  final logoA = logo([0, 35, 111], [211, 238, 120]);
  final logoB = logo([180, 30, 40], [255, 236, 200]);
  /// Length plus FNV-1a 32 fingerprint; equality checks compare full bytes.
  String sha(Uint8List? bytes) {
    if (bytes == null) return 'none';
    var hash = 0x811c9dc5;
    for (final b in bytes) {
      hash = ((hash ^ b) * 0x01000193) & 0xffffffff;
    }
    return '${bytes.length}:${hash.toRadixString(16).padLeft(8, '0')}';
  }

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

  /// Waits for [finder], scrolling the visible vertical list when the target
  /// sits outside the lazily built region (large text scales).
  Future<void> reveal(WidgetTester tester, Finder finder) async {
    final end = DateTime.now().add(const Duration(seconds: 25));
    var towardTop = true;
    while (DateTime.now().isBefore(end)) {
      await pumpFrames(tester, const Duration(milliseconds: 200));
      if (finder.evaluate().isNotEmpty) {
        await tester.ensureVisible(finder.first);
        await pumpFrames(tester, const Duration(milliseconds: 300));
        return;
      }
      final lists = find
          .byWidgetPredicate(
            (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
          )
          .hitTestable();
      if (lists.evaluate().isEmpty) continue;
      final position = tester.state<ScrollableState>(lists.first).position;
      final target = towardTop
          ? math.max(position.minScrollExtent, position.pixels - 400)
          : math.min(position.maxScrollExtent, position.pixels + 400);
      if (target == position.pixels) {
        towardTop = !towardTop;
      } else {
        position.jumpTo(target);
      }
    }
    throw TestFailure('Timed out revealing $finder');
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

  ProviderContainer containerOf(WidgetTester tester) =>
      ProviderScope.containerOf(tester.element(find.byType(MaterialApp).first));

  GoRouter routerOf(WidgetTester tester) =>
      containerOf(tester).read(appRouterProvider);

  MerchantClient apiOf(WidgetTester tester) =>
      containerOf(tester).read(merchantApiProvider);

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
    final container = containerOf(tester);
    if (container.read(sessionControllerProvider).phase ==
        SessionPhase.signedOut) {
      return;
    }
    await container.read(sessionControllerProvider.notifier).logout();
    await pumpFrames(tester, const Duration(seconds: 2));
  }

  Future<Uint8List?> serverLogo(WidgetTester tester) => apiOf(
    tester,
  ).fetchBranchLogoBytes(merchantId: merchantId, branchId: branchId);

  Future<void> tapVisible(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await pumpFrames(tester, const Duration(milliseconds: 400));
    await tester.tap(finder);
  }

  Future<void> saveLogo(WidgetTester tester, Uint8List bytes) async {
    final state = tester.state(find.byType(StoreCoverScreen));
    (state as dynamic).debugSetLogoBytes(bytes: bytes);
    await tester.pump();
    await waitFor(tester, find.byKey(const Key('store-logo-pending')));
    await tapVisible(tester, find.byKey(const Key('store-cover-save')));
    await waitGone(tester, find.byKey(const Key('store-cover-screen')));
  }

  Future<void> ownerLogo(WidgetTester tester) async {
    await push(tester, AppRoutes.storeCover);
    await waitFor(tester, find.byKey(const Key('store-cover-screen')));
    await waitFor(tester, find.byKey(const Key('store-logo-empty')));
    results['logoInitiallyEmpty'] = sha(await serverLogo(tester)) == 'none';
    await shot(tester, 'logo_empty');

    await saveLogo(tester, logoA);
    final saved = await serverLogo(tester);
    results['logoSavedMatchesA'] = listEquals(saved, logoA);
    expect(listEquals(saved, logoA), isTrue);

    routerOf(tester).go(AppRoutes.profile);
    await waitFor(
      tester,
      find.descendant(
        of: find.byKey(const Key('store-profile-logo')),
        matching: find.byType(Image),
      ),
    );
    await shot(tester, 'profile_logo');

    await pumpApp(tester);
    await waitFor(tester, find.byKey(const Key('home-branch-name')));
    await push(tester, AppRoutes.storeCover);
    await waitFor(tester, find.byKey(const Key('store-logo-image')));
    results['logoAfterFreshInstance'] = sha(await serverLogo(tester));
    await shot(tester, 'logo_reopened');

    await saveLogo(tester, logoB);
    final replaced = await serverLogo(tester);
    results['logoReplacedMatchesB'] = listEquals(replaced, logoB);
    results['logoReplacedDiffersFromA'] = !listEquals(replaced, logoA);
    expect(listEquals(replaced, logoB), isTrue);
    await push(tester, AppRoutes.storeCover);
    await waitFor(tester, find.byKey(const Key('store-logo-image')));
    final shown = tester.widget<Image>(find.byKey(const Key('store-logo-image')));
    final shownBytes = (shown.image as MemoryImage).bytes;
    results['logoDisplayedIsB'] = listEquals(shownBytes, logoB);
    expect(listEquals(shownBytes, logoB), isTrue);
    await shot(tester, 'logo_replaced');

    await tapVisible(tester, find.byKey(const Key('store-logo-remove')));
    await waitFor(tester, find.text(AppStrings.storeLogoRemoved));
    await waitFor(tester, find.byKey(const Key('store-logo-empty')));
    results['logoAfterRemove'] = sha(await serverLogo(tester));
    expect(results['logoAfterRemove'], 'none');
    await shot(tester, 'logo_removed');
    routerOf(tester).go(AppRoutes.profile);
    await pumpFrames(tester, const Duration(seconds: 2));
    expect(
      find.descendant(
        of: find.byKey(const Key('store-profile-logo')),
        matching: find.byType(Image),
      ),
      findsNothing,
    );
    await shot(tester, 'profile_logo_fallback');
  }

  String serverToday(WidgetTester tester) =>
      containerOf(tester).read(openingHoursExceptionsControllerProvider).value!.today;

  String plusDays(String date, int days) =>
      civilDateKey(parseCivilDate(date)!.add(Duration(days: days)));

  Future<void> fillException(
    WidgetTester tester, {
    String? date,
    required bool closed,
    required String label,
    List<OpeningInterval>? intervals,
  }) async {
    final state = tester.state(find.byType(OpeningHoursExceptionsScreen));
    if (date != null) (state as dynamic).debugSetDate(date);
    await tester.pump();
    await tapVisible(
      tester,
      find.byKey(
        Key('hours-exception-status-${closed ? 'closed' : 'open'}'),
      ),
    );
    await tester.pump();
    if (!closed && intervals != null) {
      (state as dynamic).debugSetIntervals(intervals);
      await tester.pump();
    }
    final labelField = find.byKey(const Key('hours-exception-label'));
    final entered = find.descendant(of: labelField, matching: find.text(label));
    // Focus restored after a dialog can keep a stale text-input connection, so
    // drop focus and tap the field to open a fresh one before typing.
    for (var attempt = 0; attempt < 3; attempt++) {
      FocusManager.instance.primaryFocus?.unfocus();
      await pumpFrames(tester, const Duration(milliseconds: 300));
      await tester.ensureVisible(labelField);
      await pumpFrames(tester, const Duration(milliseconds: 300));
      await tester.tap(labelField);
      await pumpFrames(tester, const Duration(milliseconds: 400));
      await tester.enterText(labelField, label);
      await pumpFrames(tester, const Duration(milliseconds: 300));
      if (entered.evaluate().isNotEmpty) break;
    }
    expect(entered, findsOneWidget);
    FocusManager.instance.primaryFocus?.unfocus();
    await pumpFrames(tester, const Duration(milliseconds: 400));
  }

  Future<void> ownerExceptions(WidgetTester tester) async {
    await push(tester, AppRoutes.openingHoursExceptions);
    await waitFor(tester, find.byKey(const Key('hours-exceptions-screen')));
    await waitFor(tester, find.byKey(const Key('hours-exceptions-empty')));
    final today = serverToday(tester);
    final future = plusDays(today, 3);
    results['serverToday'] = today;
    await shot(tester, 'hours_exceptions_empty');

    await fillException(
      tester,
      date: future,
      closed: true,
      label: 'TEST FX Inventaire',
    );
    await shot(tester, 'hours_exception_form');
    await tester.tap(find.byKey(const Key('hours-exception-save')));
    await waitFor(tester, find.text(AppStrings.hoursExceptionsSaved));
    await reveal(tester, find.byKey(Key('hours-exception-card-$future')));
    await shot(tester, 'hours_exception_saved');

    await pumpApp(tester);
    await waitFor(tester, find.byKey(const Key('home-branch-name')));
    await push(tester, AppRoutes.openingHoursExceptions);
    await waitFor(tester, find.byKey(Key('hours-exception-card-$future')));
    results['exceptionAfterFreshInstance'] = future;
    await shot(tester, 'hours_exception_reopened');

    await tapVisible(tester, find.byKey(Key('hours-exception-card-$future')));
    await waitFor(tester, find.text(AppStrings.hoursExceptionsEdit));
    final current = containerOf(tester)
        .read(openingHoursExceptionsControllerProvider)
        .value!
        .byDate(future)!;
    await apiOf(tester).putOpeningHoursException(
      merchantId: merchantId,
      branchId: branchId,
      date: future,
      expectedVersion: current.version,
      closed: true,
      intervals: const [],
      label: 'TEST FX Changé ailleurs',
    );
    await fillException(
      tester,
      closed: false,
      label: 'TEST FX Horaires réduits',
      intervals: const [OpeningInterval(opens: '10:00', closes: '14:00')],
    );
    await tester.tap(find.byKey(const Key('hours-exception-save')));
    await waitFor(tester, find.text(AppStrings.hoursExceptionsConflict));
    expect(find.text('TEST FX Horaires réduits'), findsOneWidget);
    await reveal(tester, find.text('TEST FX Changé ailleurs'));
    results['conflictKeptDraft'] = true;
    await shot(tester, 'hours_exception_conflict');

    await tester.tap(find.byKey(const Key('hours-exception-save')));
    await waitFor(tester, find.text(AppStrings.hoursExceptionsSaved));
    await reveal(tester, find.byKey(Key('hours-exception-hours-$future')));
    results['retryAfterConflictSaved'] = true;
    await shot(tester, 'hours_exception_open_interval');

    await tapVisible(tester, find.byKey(Key('hours-exception-delete-$future')));
    await waitFor(tester, find.byKey(const Key('hours-exception-delete-dialog')));
    await tester.tap(find.byKey(const Key('hours-exception-delete-confirm')));
    await waitFor(tester, find.text(AppStrings.hoursExceptionsDeleted));
    await waitGone(tester, find.byKey(Key('hours-exception-card-$future')));
    expect(
      containerOf(tester)
          .read(openingHoursExceptionsControllerProvider)
          .value!
          .byDate(future),
      isNull,
    );
    await shot(tester, 'hours_exception_deleted');

    // A closed exception for today overrides the weekly 24h schedule.
    await fillException(
      tester,
      date: today,
      closed: true,
      label: 'TEST FX Fermé aujourd’hui',
    );
    // The previous snackbar overlays the in-body sticky footer until it hides.
    await waitGone(tester, find.byType(SnackBar));
    await tester.tap(find.byKey(const Key('hours-exception-save')));
    await waitFor(tester, find.text(AppStrings.hoursExceptionsSaved));
    await push(tester, AppRoutes.openingHours);
    await waitFor(tester, find.byKey(const Key('opening-hours-open-pill')));
    await reveal(
      tester,
      find.text(AppStrings.hoursExceptionsToday('TEST FX Fermé aujourd’hui')),
    );
    final closedState = await apiOf(
      tester,
    ).getAvailability(merchantId: merchantId, branchId: branchId);
    results['todayClosedIsOpenNow'] = closedState.isOpenNow;
    results['todayClosedAccepting'] = closedState.acceptingOrders;
    expect(closedState.isOpenNow, isFalse);
    await reveal(tester, find.text(AppStrings.openingHoursClosedNow));
    expect(find.text(AppStrings.openingHoursClosedNow), findsOneWidget);
    await shot(tester, 'hours_today_closed');

    await push(tester, AppRoutes.openingHoursExceptions);
    await reveal(tester, find.byKey(Key('hours-exception-delete-$today')));
    await tapVisible(tester, find.byKey(Key('hours-exception-delete-$today')));
    await waitFor(tester, find.byKey(const Key('hours-exception-delete-dialog')));
    await tester.tap(find.byKey(const Key('hours-exception-delete-confirm')));
    await waitFor(tester, find.text(AppStrings.hoursExceptionsDeleted));
    await push(tester, AppRoutes.openingHours);
    await waitFor(tester, find.text(AppStrings.openingHoursOpenNow));
    final openState = await apiOf(
      tester,
    ).getAvailability(merchantId: merchantId, branchId: branchId);
    results['weeklyFallbackIsOpenNow'] = openState.isOpenNow;
    expect(openState.isOpenNow, isTrue);
    await shot(tester, 'hours_weekly_fallback');
  }

  Future<String> duplicateThroughMenu(
    WidgetTester tester,
    String sourceId,
    String tag, {
    bool doubleTap = false,
  }) async {
    routerOf(tester).go(AppRoutes.catalog);
    final menu = find.byKey(Key('catalog-product-menu-$sourceId'));
    await waitFor(tester, menu);
    await tapVisible(tester, menu);
    await waitFor(tester, find.byKey(const Key('catalog-menu-duplicate')));
    await shot(tester, '${tag}_menu');
    await tester.tap(find.byKey(const Key('catalog-menu-duplicate')));
    await waitFor(tester, find.byKey(const Key('duplicate-screen')));
    await shot(tester, '${tag}_screen');
    final create = find.byKey(const Key('duplicate-create'));
    // Both taps land before any rebuild, so the second one exercises the
    // in-flight guard rather than racing the server response.
    final center = tester.getCenter(create);
    await tester.tapAt(center);
    if (doubleTap) await tester.tapAt(center);
    await waitFor(tester, find.byKey(const Key('product-editor-screen')));
    final copyId = tester
        .widget<ProductEditorScreen>(find.byType(ProductEditorScreen).last)
        .productId!;
    expect(copyId, isNot(sourceId));
    await shot(tester, '${tag}_editor');
    return copyId;
  }

  Future<void> ownerDuplicate(WidgetTester tester) async {
    final api = apiOf(tester);
    final source = await api.getProduct(
      merchantId: merchantId,
      productId: couscousId,
    );
    final copyId = await duplicateThroughMenu(
      tester,
      couscousId,
      'duplicate_owner',
      doubleTap: true,
    );
    final copy = await api.getProduct(merchantId: merchantId, productId: copyId);
    final products = await api.listProducts(
      merchantId: merchantId,
      branchId: branchId,
    );
    final copies = products
        .where((p) => p.name == 'Copie de ${source.name}')
        .length;
    final sourceAfter = await api.getProduct(
      merchantId: merchantId,
      productId: couscousId,
    );
    results['ownerCopyId'] = copyId;
    results['ownerCopyAvailable'] = copy.available;
    results['ownerCopyName'] = copy.name;
    results['ownerCopyHasImage'] = copy.hasImage;
    results['ownerCopiesAfterDoubleTap'] = copies;
    results['sourceUnchanged'] =
        sourceAfter.name == source.name &&
        sourceAfter.available == source.available &&
        sourceAfter.priceMinor == source.priceMinor;
    expect(copy.available, isFalse);
    expect(copies, 1);
    expect(results['sourceUnchanged'], isTrue);
    routerOf(tester).go(AppRoutes.catalog);
    await reveal(tester, find.byKey(Key('catalog-product-$copyId')));
    await shot(tester, 'catalog_with_copy');
  }

  Future<void> managerFlow(WidgetTester tester) async {
    await push(tester, AppRoutes.storeCover);
    await waitFor(tester, find.byKey(const Key('store-logo-pick')));
    results['managerLogoControls'] = true;
    await shot(tester, 'manager_logo');
    await push(tester, AppRoutes.openingHoursExceptions);
    await reveal(tester, find.byKey(const Key('hours-exception-form')));
    results['managerExceptionEditor'] = true;
    final copyId = await duplicateThroughMenu(
      tester,
      pouletId,
      'duplicate_manager',
    );
    final copy = await apiOf(
      tester,
    ).getProduct(merchantId: merchantId, productId: copyId);
    results['managerCopyAvailable'] = copy.available;
    expect(copy.available, isFalse);
  }

  Future<void> staffFlow(WidgetTester tester) async {
    await push(tester, AppRoutes.storeCover);
    await waitFor(tester, find.byKey(const Key('store-cover-screen')));
    await pumpFrames(tester, const Duration(seconds: 2));
    expect(find.byKey(const Key('store-logo-pick')), findsNothing);
    expect(find.byKey(const Key('store-logo-remove')), findsNothing);
    results['staffLogoReadOnly'] = true;
    await shot(tester, 'staff_logo');

    await push(tester, AppRoutes.openingHoursExceptions);
    await waitFor(tester, find.byKey(const Key('hours-exception-readonly')));
    expect(find.byKey(const Key('hours-exception-form')), findsNothing);
    results['staffExceptionsReadOnly'] = true;
    await shot(tester, 'staff_hours_exceptions');

    routerOf(tester).go(AppRoutes.catalog);
    await waitFor(tester, find.byKey(const Key('catalog-product-$couscousId')));
    expect(find.byKey(const Key('catalog-product-menu-$couscousId')), findsNothing);
    results['staffNoProductMenu'] = true;
    await shot(tester, 'staff_catalog');

    await push(tester, AppRoutes.catalogProductDuplicate(couscousId));
    await waitFor(tester, find.byKey(const Key('duplicate-forbidden')));
    results['staffDuplicateRefused'] = true;
    await shot(tester, 'staff_duplicate');
  }

  testWidgets('contract batch: logo, exceptional hours, duplication', (
    tester,
  ) async {
    expect(
      AppConstants.apiBaseUrl,
      isolatedApi,
      reason: 'refusing to run outside the isolated API',
    );
    expect(otpFilePath, endsWith('/.speedygo/parity_fx/otp/otp-last'));
    expect(evidenceDir, isNotEmpty);
    var role = 'OWNER';
    try {
      await login(tester, owner);
      await ownerLogo(tester);
      await ownerExceptions(tester);
      await ownerDuplicate(tester);
      await logout(tester, 'OWNER');

      role = 'MANAGER';
      await login(tester, manager);
      await managerFlow(tester);
      await logout(tester, 'MANAGER');

      role = 'STAFF';
      await login(tester, staff);
      await staffFlow(tester);
      await logout(tester, 'STAFF');
    } catch (e) {
      results['failedRole'] = role;
      results['failure'] = e.toString().split('\n').first;
      final error = find.descendant(
        of: find.byKey(const Key('hours-exception-error')),
        matching: find.byType(Text),
      );
      results['failureInlineError'] = error.evaluate().isEmpty
          ? null
          : tester.widget<Text>(error.first).data;
      final save = find.byKey(const Key('hours-exception-save'));
      results['failureSaveEnabled'] = save.evaluate().isEmpty
          ? null
          : tester.widget<ButtonStyleButton>(save).onPressed != null;
      try {
        await shot(tester, 'failure_state');
      } catch (_) {}
      rethrow;
    } finally {
      await revokeDedicatedSession(tester);
      File(shotMarker).writeAsStringSync('${prefix}_99_done\n');
      File('$evidenceDir/PROVENANCE_$prefix.json').writeAsStringSync(
        const JsonEncoder.withIndent('  ').convert({
          'app': 'merchant',
          'test': 'contract_batch_fx_live_test',
          'backend': 'isolated (speedygo_parity_fx via 127.0.0.1:3100)',
          'apiBaseUrl': AppConstants.apiBaseUrl,
          'prefix': prefix,
          'session':
              'one OTP session per role, app stores in memory (Keychain untouched)',
          'branchId': branchId,
          'logoFixtures': {'A': sha(logoA), 'B': sha(logoB)},
          'results': results,
          'steps': steps,
        }),
      );
    }
  });
}
