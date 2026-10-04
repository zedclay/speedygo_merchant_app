import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:image/image.dart' as img;
import 'package:integration_test/integration_test.dart';
import 'package:speedygo_merchant_app/app/app.dart';
import 'package:speedygo_merchant_app/app/router/app_router.dart';
import 'package:speedygo_merchant_app/core/constants/app_constants.dart';
import 'package:speedygo_merchant_app/core/constants/app_strings.dart';
import 'package:speedygo_merchant_app/core/errors/app_exception.dart';
import 'package:speedygo_merchant_app/core/navigation/app_routes.dart';
import 'package:speedygo_merchant_app/core/storage/approval_notice_store.dart';
import 'package:speedygo_merchant_app/core/storage/session_store.dart';
import 'package:speedygo_merchant_app/core/utils/uuid_v4.dart';
import 'package:speedygo_merchant_app/core/widgets/merchant_ui.dart';
import 'package:speedygo_merchant_app/features/access/data/merchant_api.dart';
import 'package:speedygo_merchant_app/features/auth/application/auth_infrastructure.dart';
import 'package:speedygo_merchant_app/features/auth/application/session_controller.dart';
import 'package:speedygo_merchant_app/features/auth/application/session_providers.dart';
import 'package:speedygo_merchant_app/features/auth/application/session_state.dart';
import 'package:speedygo_merchant_app/features/catalog/presentation/product_editor_screen.dart';
import 'package:speedygo_merchant_app/features/notifications/application/merchant_push_controller.dart';
import 'package:speedygo_merchant_app/features/notifications/data/push_registration.dart';
import 'package:speedygo_merchant_app/features/shell/merchant_shell.dart';
import 'package:speedygo_merchant_app/features/store/application/opening_hours_format.dart';
import 'package:speedygo_merchant_app/features/store/application/store_controllers.dart';
import 'package:speedygo_merchant_app/features/store/data/store_models.dart';
import 'package:speedygo_merchant_app/features/store/presentation/opening_hours_exceptions_screen.dart';

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

/// Final Merchant polish pass against the disposable environment only
/// (`speedygo_parity_fx` on 127.0.0.1:3100).
///
/// OWNER: a synthetic 480×480 image is bound to Couscous royal; the duplicate
/// screen paints it; the copy's editor paints the copied image, also after a
/// fresh app instance; snack bars clear the in-body sticky bar on the copy
/// editor, the exceptional-hours save and the weekly-hours save (weekly hours
/// restored and verified); the populated catalogue end clears the FAB, the
/// bottom navigation and the safe area.
/// STAFF: the duplicate route reached directly shows the forbidden state with
/// an AppBar, a working back action and the catalogue fallback; the server
/// still refuses the duplication (403).
///
/// One memory-only OTP session per role (Keychain never read or written),
/// each ended by the app's logout. Screenshots by the host watcher.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const isolatedApi = 'http://127.0.0.1:3100/api/v1';
  const otpFilePath = String.fromEnvironment('FX_OTP_FILE');
  const evidenceDir = String.fromEnvironment('FX_EVIDENCE_DIR');
  const prefix = String.fromEnvironment('PARITY_PREFIX', defaultValue: 'fxp');
  const merchantId = '0d00f0f0-fa00-7000-8000-000000001001';
  const branchId = '0d00f0f0-fa00-7000-8000-000000002001';
  const couscousId = '0d00f0f0-fa00-7000-8000-000000007001';
  const branchName = 'Comptoir Essai';
  const owner = '550009101';
  const staff = '550009103';
  const shotMarker = '/tmp/parity_fx_isolated_shot.txt';

  var memorySessions = MemorySessionStore();
  var sessionCreated = false;
  final steps = <Map<String, Object?>>[];
  final results = <String, Object?>{};

  Uint8List syntheticImage() {
    final image = img.Image(width: 480, height: 480);
    for (var y = 0; y < 480; y++) {
      for (var x = 0; x < 480; x++) {
        image.setPixelRgb(x, y, 200 - y ~/ 4, 120 + x ~/ 8, 60 + (x + y) ~/ 12);
      }
    }
    img.fillCircle(
      image,
      x: 240,
      y: 240,
      radius: 120,
      color: img.ColorRgb8(255, 236, 200),
    );
    return Uint8List.fromList(img.encodeJpg(image, quality: 88));
  }

  final fixtureImage = syntheticImage();

  /// Length plus FNV-1a 32 fingerprint; equality checks compare full bytes.
  String fp(Uint8List? bytes) {
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

  Future<void> waitGone(WidgetTester tester, Finder finder) async {
    final end = DateTime.now().add(const Duration(seconds: 25));
    while (DateTime.now().isBefore(end)) {
      await pumpFrames(tester, const Duration(milliseconds: 200));
      if (finder.evaluate().isEmpty) return;
    }
    throw TestFailure('Still present: $finder');
  }

  Future<void> shot(WidgetTester tester, String tag) async {
    await pumpFrames(tester, const Duration(milliseconds: 400));
    File(shotMarker).writeAsStringSync('${prefix}_$tag\n');
    await pumpFrames(tester, const Duration(seconds: 2));
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

  Future<void> tapVisible(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await pumpFrames(tester, const Duration(milliseconds: 400));
    await tester.tap(finder);
  }

  double textScale(WidgetTester tester) => MediaQuery.textScalerOf(
    tester.element(find.byType(Scaffold).last),
  ).scale(1);

  double safeBottom(WidgetTester tester) =>
      MediaQuery.paddingOf(tester.element(find.byType(MaterialApp).first))
          .bottom;

  String rect(Rect r) =>
      '${r.left.toStringAsFixed(1)},${r.top.toStringAsFixed(1)},'
      '${r.right.toStringAsFixed(1)},${r.bottom.toStringAsFixed(1)}';

  /// Snack bar vs the in-body sticky bar and its primary action, measured
  /// once the snack bar has finished entering.
  Future<Map<String, Object?>> snackGeometry(
    WidgetTester tester,
    String message,
    Finder primary,
  ) async {
    await waitFor(tester, find.text(message));
    await pumpFrames(tester, const Duration(milliseconds: 700));
    final snack = tester.getRect(
      find
          .descendant(of: find.byType(SnackBar), matching: find.byType(Material))
          .first,
    );
    final bar = tester.getRect(find.byType(MerchantStickyBar).last);
    final action = tester.getRect(primary);
    final screen = tester.view.physicalSize / tester.view.devicePixelRatio;
    final g = {
      'message': message,
      'textScale': textScale(tester),
      'safeBottom': safeBottom(tester),
      'screen': '${screen.width.toStringAsFixed(0)}x${screen.height.toStringAsFixed(0)}',
      'snack': rect(snack),
      'stickyBar': rect(bar),
      'primaryAction': rect(action),
      'gapAboveStickyBar': double.parse((bar.top - snack.bottom).toStringAsFixed(1)),
      'snackOverlapsStickyBar': snack.overlaps(bar),
      'snackOverlapsPrimaryAction': snack.overlaps(action),
    };
    expect(snack.bottom, lessThanOrEqualTo(bar.top), reason: '$g');
    expect(snack.overlaps(action), isFalse, reason: '$g');
    return g;
  }

  final editorImage = find.byWidgetPredicate(
    (w) =>
        w is Image &&
        w.key is ValueKey<String> &&
        (w.key! as ValueKey<String>).value.startsWith('product-editor-image-'),
  );

  /// Bytes of a painted memory image: the decoded frame is on the RawImage.
  Future<Uint8List> paintedBytes(WidgetTester tester, Finder image) async {
    final raw = find.descendant(of: image, matching: find.byType(RawImage));
    final end = DateTime.now().add(const Duration(seconds: 25));
    while (DateTime.now().isBefore(end)) {
      await pumpFrames(tester, const Duration(milliseconds: 200));
      if (raw.evaluate().isNotEmpty &&
          tester.widget<RawImage>(raw.first).image != null) {
        return (tester.widget<Image>(image.first).image as MemoryImage).bytes;
      }
    }
    throw TestFailure('Image never painted: $image');
  }

  Future<void> ownerImageDuplication(WidgetTester tester) async {
    final api = apiOf(tester);
    final before = await api.getProduct(
      merchantId: merchantId,
      productId: couscousId,
    );
    results['sourceHadImageBefore'] = before.hasImage;
    if (!before.hasImage) {
      final upload = await api.uploadProductImageContent(
        merchantId: merchantId,
        branchId: branchId,
        productId: couscousId,
        filename: 'fx_polish_source.jpg',
        contentType: 'image/jpeg',
        bytes: fixtureImage,
      );
      await api.bindProductImage(
        merchantId: merchantId,
        branchId: branchId,
        productId: couscousId,
        uploadReference: upload.uploadReference,
      );
    }
    final sourceBytes = await api.fetchProductImageBytes(
      merchantId: merchantId,
      branchId: branchId,
      productId: couscousId,
    );
    expect(sourceBytes, isNotNull);
    results['fixtureImage'] = fp(fixtureImage);
    results['sourceServedImage'] = fp(sourceBytes);
    results['sourceServedEqualsFixture'] = listEquals(sourceBytes, fixtureImage);

    await push(tester, AppRoutes.catalogProductDuplicate(couscousId));
    await waitFor(tester, find.byKey(const Key('duplicate-screen')));
    final sourceThumb = find.descendant(
      of: find.byKey(const Key('duplicate-source')),
      matching: find.byType(Image),
    );
    await waitFor(tester, sourceThumb);
    final thumbBytes = await paintedBytes(tester, sourceThumb);
    results['duplicateSourceImagePainted'] = fp(thumbBytes);
    results['duplicateSourceImageMatchesServer'] = listEquals(
      thumbBytes,
      sourceBytes,
    );
    expect(listEquals(thumbBytes, sourceBytes), isTrue);
    await shot(tester, '01_duplicate_source_image');

    await tester.tap(find.byKey(const Key('duplicate-create')));
    await waitFor(tester, find.byKey(const Key('product-editor-screen')));
    await waitFor(tester, find.byKey(const Key('product-editor-save')));
    results['snackDuplicateEditor'] = await snackGeometry(
      tester,
      AppStrings.duplicateCreated,
      find.byKey(const Key('product-editor-save')),
    );
    await shot(tester, '02_duplicate_editor_snack');

    final copyId = tester
        .widget<ProductEditorScreen>(find.byType(ProductEditorScreen).last)
        .productId!;
    expect(copyId, isNot(couscousId));
    results['copyId'] = copyId;
    final copy = await api.getProduct(merchantId: merchantId, productId: copyId);
    results['copyHasImage'] = copy.hasImage;
    results['copyAvailable'] = copy.available;
    expect(copy.hasImage, isTrue);
    expect(copy.available, isFalse);
    final copyServed = await api.fetchProductImageBytes(
      merchantId: merchantId,
      branchId: branchId,
      productId: copyId,
    );
    results['copyServedImage'] = fp(copyServed);
    results['copyServedEqualsSource'] = listEquals(copyServed, sourceBytes);
    expect(listEquals(copyServed, sourceBytes), isTrue);

    await waitFor(tester, editorImage);
    final editorBytes = await paintedBytes(tester, editorImage);
    results['copyEditorImagePainted'] = fp(editorBytes);
    results['copyEditorImageMatchesSource'] = listEquals(
      editorBytes,
      sourceBytes,
    );
    expect(listEquals(editorBytes, sourceBytes), isTrue);
    await tester.ensureVisible(editorImage);
    await shot(tester, '03_duplicate_editor_image');

    await pumpApp(tester);
    await waitFor(tester, find.byKey(const Key('home-branch-name')));
    await push(tester, AppRoutes.catalogProductEdit(copyId));
    await waitFor(tester, find.byKey(const Key('product-editor-screen')));
    await waitFor(tester, editorImage);
    final reopened = await paintedBytes(tester, editorImage);
    results['copyEditorImageAfterFreshInstance'] = fp(reopened);
    results['copyEditorImageAfterFreshInstanceMatchesSource'] = listEquals(
      reopened,
      sourceBytes,
    );
    expect(listEquals(reopened, sourceBytes), isTrue);
    await tester.ensureVisible(editorImage);
    await shot(tester, '04_copy_editor_reopened');

    final sourceAfter = await api.fetchProductImageBytes(
      merchantId: merchantId,
      branchId: branchId,
      productId: couscousId,
    );
    results['sourceImageUnchanged'] = listEquals(sourceAfter, sourceBytes);
    expect(listEquals(sourceAfter, sourceBytes), isTrue);
  }

  final productCard = find.byWidgetPredicate(
    (w) =>
        w.key is ValueKey<String> &&
        RegExp(
          r'^catalog-product-[0-9a-f-]{36}$',
        ).hasMatch((w.key! as ValueKey<String>).value),
  );

  Future<void> ownerCatalogueEnd(WidgetTester tester) async {
    routerOf(tester).go(AppRoutes.catalog);
    await waitFor(tester, find.byKey(const Key('catalog-add-fab')));
    await waitFor(tester, productCard);
    final scroll = find
        .descendant(
          of: find.byKey(const Key('catalog-scroll')),
          matching: find.byType(Scrollable),
        )
        .first;
    final position = tester.state<ScrollableState>(scroll).position;
    var extent = -1.0;
    for (var i = 0; i < 20 && extent != position.maxScrollExtent; i++) {
      extent = position.maxScrollExtent;
      position.jumpTo(extent);
      await pumpFrames(tester, const Duration(milliseconds: 400));
    }
    await pumpFrames(tester, const Duration(milliseconds: 600));
    final cards = productCard.evaluate().map((e) {
      final box = e.renderObject! as RenderBox;
      return box.localToGlobal(Offset.zero) & box.size;
    }).toList();
    final last = cards.reduce((a, b) => a.bottom >= b.bottom ? a : b);
    final fab = tester.getRect(find.byKey(const Key('catalog-add-fab')));
    final nav = tester.getRect(find.byType(MerchantBottomNav));
    final screen = tester.view.physicalSize / tester.view.devicePixelRatio;
    final safe = safeBottom(tester);
    final g = {
      'textScale': textScale(tester),
      'safeBottom': safe,
      'productCount': (await apiOf(tester).listProducts(
        merchantId: merchantId,
        branchId: branchId,
      )).length,
      'atScrollEnd': position.pixels == position.maxScrollExtent,
      'lastCard': rect(last),
      'fab': rect(fab),
      'bottomNav': rect(nav),
      'gapAboveFab': double.parse((fab.top - last.bottom).toStringAsFixed(1)),
      'gapAboveNav': double.parse((nav.top - last.bottom).toStringAsFixed(1)),
      'gapAboveSafeArea': double.parse(
        (screen.height - safe - last.bottom).toStringAsFixed(1),
      ),
      'lastCardOverlapsFab': last.overlaps(fab),
    };
    results['catalogEnd'] = g;
    expect(position.pixels, position.maxScrollExtent);
    expect(last.bottom, lessThanOrEqualTo(fab.top), reason: '$g');
    expect(last.bottom, lessThanOrEqualTo(nav.top), reason: '$g');
    expect(last.bottom, lessThanOrEqualTo(screen.height - safe), reason: '$g');
    await shot(tester, '05_catalog_end');
  }

  Future<void> ownerExceptionSnack(WidgetTester tester) async {
    await push(tester, AppRoutes.openingHoursExceptions);
    await waitFor(tester, find.byKey(const Key('hours-exceptions-screen')));
    await waitFor(tester, find.byKey(const Key('hours-exception-form')));
    final today = containerOf(tester)
        .read(openingHoursExceptionsControllerProvider)
        .value!
        .today;
    final date = civilDateKey(
      parseCivilDate(today)!.add(const Duration(days: 9)),
    );
    final state = tester.state(find.byType(OpeningHoursExceptionsScreen));
    (state as dynamic).debugSetDate(date);
    await tester.pump();
    await tapVisible(
      tester,
      find.byKey(const Key('hours-exception-status-closed')),
    );
    final labelField = find.byKey(const Key('hours-exception-label'));
    const label = 'TEST FX Polish';
    final entered = find.descendant(of: labelField, matching: find.text(label));
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
    await pumpFrames(tester, const Duration(milliseconds: 600));
    await tester.tap(find.byKey(const Key('hours-exception-save')));
    results['snackExceptionalHours'] = await snackGeometry(
      tester,
      AppStrings.hoursExceptionsSaved,
      find.byKey(const Key('hours-exception-save')),
    );
    await shot(tester, '06_hours_exception_snack');

    final saved = containerOf(tester)
        .read(openingHoursExceptionsControllerProvider)
        .value!
        .byDate(date)!;
    await apiOf(tester).deleteOpeningHoursException(
      merchantId: merchantId,
      branchId: branchId,
      date: date,
      expectedVersion: saved.version,
    );
    final remaining = await apiOf(tester).listOpeningHoursExceptions(
      merchantId: merchantId,
      branchId: branchId,
    );
    results['exceptionRemoved'] = remaining.byDate(date) == null;
    expect(remaining.byDate(date), isNull);
  }

  String daysKey(OpeningHoursSchedule s) => s.days
      .map(
        (d) =>
            '${d.dayOfWeek}:${d.intervals.map((i) => '${i.opens}-${i.closes}').join('+')}',
      )
      .join('|');

  Future<void> ownerWeeklySnack(WidgetTester tester) async {
    final api = apiOf(tester);
    final original = await api.getOpeningHours(
      merchantId: merchantId,
      branchId: branchId,
    );
    results['weeklyBefore'] = daysKey(original);
    await push(tester, AppRoutes.openingHours);
    await waitFor(tester, find.byKey(const Key('opening-hours-switch-1')));
    await tapVisible(tester, find.byKey(const Key('opening-hours-switch-1')));
    await pumpFrames(tester, const Duration(milliseconds: 500));
    await tester.tap(find.byKey(const Key('opening-hours-save')));
    results['snackWeeklyHours'] = await snackGeometry(
      tester,
      AppStrings.openingHoursSaved,
      find.byKey(const Key('opening-hours-save')),
    );
    await shot(tester, '07_weekly_hours_snack');

    final changed = await api.getOpeningHours(
      merchantId: merchantId,
      branchId: branchId,
    );
    results['weeklyChangedBySave'] = daysKey(changed) != daysKey(original);
    final restored = await api.putOpeningHours(
      merchantId: merchantId,
      branchId: branchId,
      expectedVersion: changed.version ?? 0,
      days: original.days,
    );
    final check = await api.getOpeningHours(
      merchantId: merchantId,
      branchId: branchId,
    );
    results['weeklyAfterSave'] = daysKey(changed);
    results['weeklyAfterRestore'] = daysKey(check);
    results['weeklyRestored'] =
        daysKey(restored) == daysKey(original) &&
        daysKey(check) == daysKey(original);
  }

  Future<void> staffDirectDuplicate(WidgetTester tester) async {
    final forbidden = find.byKey(const Key('duplicate-forbidden'));
    final catalogue = find.byKey(const Key('catalog-scroll'));

    routerOf(tester).go(AppRoutes.catalogProductDuplicate(couscousId));
    await waitFor(tester, forbidden);
    final state = {
      'appBar': find.byType(AppBar).evaluate().isNotEmpty,
      'backAction': find
          .byKey(const Key('duplicate-forbidden-back'))
          .evaluate()
          .isNotEmpty,
      'catalogFallback': find
          .byKey(const Key('duplicate-forbidden-catalog'))
          .evaluate()
          .isNotEmpty,
      'duplicateFormShown':
          find.byKey(const Key('duplicate-name')).evaluate().isNotEmpty ||
          find.byKey(const Key('duplicate-source')).evaluate().isNotEmpty,
      'createActionShown': find
          .byKey(const Key('duplicate-create'))
          .evaluate()
          .isNotEmpty,
      'textScale': textScale(tester),
    };
    results['staffDirectDuplicate'] = state;
    expect(state['appBar'], isTrue);
    expect(state['backAction'], isTrue);
    expect(state['catalogFallback'], isTrue);
    expect(state['duplicateFormShown'], isFalse);
    expect(state['createActionShown'], isFalse);
    await shot(tester, '08_staff_duplicate_forbidden');

    await tester.tap(find.byKey(const Key('duplicate-forbidden-back')));
    await waitGone(tester, forbidden);
    expect(catalogue, findsOneWidget);
    results['staffBackOpensCatalogue'] = true;
    await shot(tester, '09_staff_back_catalogue');

    routerOf(tester).go(AppRoutes.catalogProductDuplicate(couscousId));
    await waitFor(tester, forbidden);
    await tapVisible(
      tester,
      find.byKey(const Key('duplicate-forbidden-catalog')),
    );
    await waitGone(tester, forbidden);
    expect(catalogue, findsOneWidget);
    results['staffFallbackOpensCatalogue'] = true;
    await shot(tester, '10_staff_fallback_catalogue');

    final before = (await apiOf(tester).listProducts(
      merchantId: merchantId,
      branchId: branchId,
    )).length;
    Object? refusal;
    try {
      await apiOf(tester).duplicateProduct(
        merchantId: merchantId,
        productId: couscousId,
        requestId: uuidV4(),
      );
    } catch (e) {
      refusal = e;
    }
    final after = (await apiOf(tester).listProducts(
      merchantId: merchantId,
      branchId: branchId,
    )).length;
    results['staffServerRefusal'] = {
      'status': refusal is ApiException ? refusal.statusCode : null,
      'code': refusal is ApiException ? refusal.code : null,
      'productCountUnchanged': before == after,
    };
    expect(refusal, isA<ApiException>());
    expect((refusal! as ApiException).statusCode, 403);
    expect(before, after);
  }

  testWidgets('polish: image duplication, snack bars, catalogue end, STAFF', (
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
      await ownerImageDuplication(tester);
      await ownerCatalogueEnd(tester);
      await ownerExceptionSnack(tester);
      await ownerWeeklySnack(tester);
      await logout(tester, 'OWNER');

      role = 'STAFF';
      await login(tester, staff);
      await staffDirectDuplicate(tester);
      await logout(tester, 'STAFF');

      // Checked last so the remaining evidence is captured either way.
      expect(
        results['weeklyRestored'],
        isTrue,
        reason:
            'weekly hours after restore: ${results['weeklyAfterRestore']} '
            'expected: ${results['weeklyBefore']}',
      );
    } catch (e) {
      results['failedRole'] = role;
      results['failure'] = e.toString().split('\n').take(3).join(' ');
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
          'test': 'polish_fx_live_test',
          'backend': 'isolated (speedygo_parity_fx via 127.0.0.1:3100)',
          'apiBaseUrl': AppConstants.apiBaseUrl,
          'prefix': prefix,
          'session':
              'one OTP session per role, app stores in memory (Keychain untouched)',
          'branchId': branchId,
          'sourceProductId': couscousId,
          'results': results,
          'steps': steps,
        }),
      );
    }
  });
}
