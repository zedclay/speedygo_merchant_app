import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:speedygo_merchant_app/app/theme/app_theme.dart';
import 'package:speedygo_merchant_app/core/constants/app_strings.dart';
import 'package:speedygo_merchant_app/core/storage/session_store.dart';
import 'package:speedygo_merchant_app/features/access/application/access_controller.dart';
import 'package:speedygo_merchant_app/features/access/data/models.dart';
import 'package:speedygo_merchant_app/features/auth/application/auth_infrastructure.dart';
import 'package:speedygo_merchant_app/features/auth/application/session_controller.dart';
import 'package:speedygo_merchant_app/features/auth/application/session_providers.dart';
import 'package:speedygo_merchant_app/features/auth/application/session_state.dart';
import 'package:speedygo_merchant_app/features/catalog/application/catalog_controller.dart';
import 'package:speedygo_merchant_app/features/catalog/data/catalog_models.dart';
import 'package:speedygo_merchant_app/features/catalog/presentation/category_editor_screen.dart';
import 'package:speedygo_merchant_app/features/catalog/presentation/product_editor_screen.dart';
import 'package:speedygo_merchant_app/features/store/presentation/store_address_screen.dart';
import 'package:speedygo_merchant_app/features/store/presentation/store_cover_screen.dart';

import '../features/phase1_flow_test.dart';
import '../helpers/path_provider_fixture.dart';

const _out =
    '/Users/mac/Downloads/speedygo_project/apps/merchant_app/audit/phase-5-ui/mocked/editors';

const _captureRootKey = Key('capture-root');

/// Simulated SE/Pro safe-area insets (not a native keyboard).
const _seSafe = EdgeInsets.fromLTRB(0, 44, 0, 34);
const _proSafe = EdgeInsets.fromLTRB(0, 59, 0, 34);

Future<void> _capture(WidgetTester tester, String name) async {
  await tester.pump();
  final finder = find.byKey(_captureRootKey);
  expect(finder, findsOneWidget);
  final renderObject = tester.renderObject(finder);
  expect(renderObject, isA<RenderRepaintBoundary>());
  await tester.runAsync(() async {
    final image =
        await (renderObject as RenderRepaintBoundary).toImage(pixelRatio: 2);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File('$_out/$name.png');
    file.parent.createSync(recursive: true);
    await file.writeAsBytes(bytes!.buffer.asUint8List());
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  installPathProviderFixture();

  final branch = MerchantBranch(
    id: 'b-1',
    name: 'Fixture Café',
    phone: '0550000000',
    addressText: '12 Rue Test',
    latitude: 36.75,
    longitude: 3.05,
    operationalStatus: 'ACTIVE',
  );
  final mem =
      membership(branches: [branch], role: 'OWNER').copyWithName('Fixture Café');

  Future<ProviderContainer> ready() async {
    final merchant = _EditorCaptureApi();
    final container = ProviderContainer(
      overrides: [
        merchantApiProvider.overrideWithValue(merchant),
        sessionStoreProvider.overrideWithValue(MemorySessionStore()),
        contextStoreProvider.overrideWithValue(MemoryContextStore()),
        sessionControllerProvider.overrideWith(() => _ReadySession()),
        accessControllerProvider.overrideWith(() => _ReadyAccess(mem, branch)),
      ],
    );
    await container.read(catalogControllerProvider.future);
    return container;
  }

  Future<void> pumpRoutedEditor(
    WidgetTester tester, {
    required ProviderContainer container,
    required Size size,
    required String path,
    required Widget Function(GoRouterState) builder,
    double textScale = 1,
    double keyboardHeight = 0,
    EdgeInsets safe = _seSafe,
  }) async {
    tester.view.physicalSize = Size(size.width * 2, size.height * 2);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final router = GoRouter(
      initialLocation: path,
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const Scaffold(
            body: Center(child: Text('hub', key: Key('test-hub'))),
          ),
          routes: [
            GoRoute(
              path: path.substring(1),
              builder: (_, state) => builder(state),
            ),
          ],
        ),
      ],
    );

    await tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(
          size: size,
          padding: safe,
          viewPadding: safe,
          viewInsets: EdgeInsets.only(bottom: keyboardHeight),
          textScaler: TextScaler.linear(textScale),
        ),
        child: UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            theme: AppTheme.light(locale: const Locale('fr')),
            routerConfig: router,
            builder: (context, child) {
              return ColoredBox(
                color: AppColors.background,
                child: SizedBox(
                  width: size.width,
                  height: size.height,
                  child: RepaintBoundary(
                    key: _captureRootKey,
                    child: child ?? const SizedBox.shrink(),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));
    await tester.pump(const Duration(milliseconds: 120));
  }

  for (final size in [
    (const Size(375, 667), 'se', _seSafe),
    (const Size(402, 874), 'pro', _proSafe),
  ]) {
    testWidgets('product create ${size.$2}', (tester) async {
      final container = await ready();
      addTearDown(container.dispose);
      await pumpRoutedEditor(
        tester,
        container: container,
        size: size.$1,
        safe: size.$3,
        path: '/product-new',
        builder: (_) => const ProductEditorScreen(),
      );
      expect(find.byKey(const Key('merchant-back')), findsOneWidget);
      expect(find.byKey(const Key('product-editor-screen')), findsOneWidget);
      await _capture(tester, 'product_create_${size.$2}');
    });

    testWidgets('product create scrolled ${size.$2}', (tester) async {
      final container = await ready();
      addTearDown(container.dispose);
      await pumpRoutedEditor(
        tester,
        container: container,
        size: size.$1,
        safe: size.$3,
        path: '/product-new',
        builder: (_) => const ProductEditorScreen(),
      );
      await tester.ensureVisible(
        find.byKey(const Key('product-editor-config-section')),
      );
      await tester.pump();
      expect(find.text(AppStrings.catalogSectionConfig), findsOneWidget);
      expect(find.text(AppStrings.catalogProductAvailable), findsOneWidget);
      await _capture(tester, 'product_create_scrolled_${size.$2}');
    });

    testWidgets('product edit ${size.$2}', (tester) async {
      final container = await ready();
      addTearDown(container.dispose);
      await pumpRoutedEditor(
        tester,
        container: container,
        size: size.$1,
        safe: size.$3,
        path: '/product-edit',
        builder: (_) => const ProductEditorScreen(productId: 'p-1'),
      );
      expect(find.text('Couscous Royal'), findsOneWidget);
      await _capture(tester, 'product_edit_${size.$2}');
    });

    testWidgets('product edit keyboard simulated ${size.$2}', (tester) async {
      final container = await ready();
      addTearDown(container.dispose);
      await pumpRoutedEditor(
        tester,
        container: container,
        size: size.$1,
        safe: size.$3,
        keyboardHeight: 280,
        path: '/product-edit',
        builder: (_) => const ProductEditorScreen(productId: 'p-1'),
      );
      await tester.ensureVisible(find.byKey(const Key('product-editor-name')));
      await tester.tap(find.byKey(const Key('product-editor-name')));
      await tester.pump();
      expect(find.byKey(const Key('product-editor-name')), findsOneWidget);
      File('$_out/product_edit_keyboard_${size.$2}.NOTE.txt').writeAsStringSync(
        'Simulated MediaQuery.viewInsets.bottom=280 (not native IME capture).',
      );
      await _capture(tester, 'product_edit_keyboard_${size.$2}');
    });

    testWidgets('category edit ${size.$2}', (tester) async {
      final container = await ready();
      addTearDown(container.dispose);
      await pumpRoutedEditor(
        tester,
        container: container,
        size: size.$1,
        safe: size.$3,
        path: '/category',
        builder: (_) => const CategoryEditorScreen(categoryId: 'c-1'),
      );
      expect(find.text(AppStrings.catalogCategoryDetails), findsOneWidget);
      expect(find.text(AppStrings.catalogCategorySettings), findsOneWidget);
      await _capture(tester, 'category_edit_${size.$2}');
    });

    testWidgets('cover ${size.$2}', (tester) async {
      final container = await ready();
      addTearDown(container.dispose);
      await pumpRoutedEditor(
        tester,
        container: container,
        size: size.$1,
        safe: size.$3,
        path: '/cover',
        builder: (_) => const StoreCoverScreen(),
      );
      expect(find.text(AppStrings.storeLogoSection), findsWidgets);
      expect(find.text(AppStrings.storeCoverSection), findsOneWidget);
      await _capture(tester, 'cover_${size.$2}');
    });

    testWidgets('cover scrolled ${size.$2}', (tester) async {
      final container = await ready();
      addTearDown(container.dispose);
      await pumpRoutedEditor(
        tester,
        container: container,
        size: size.$1,
        safe: size.$3,
        path: '/cover',
        builder: (_) => const StoreCoverScreen(),
      );
      await tester.drag(
        find.byKey(const Key('store-cover-screen')),
        const Offset(0, -400),
      );
      await tester.pump();
      expect(find.text(AppStrings.storeCoverSection), findsWidgets);
      expect(find.text(AppStrings.storeCustomerPreviewTitle), findsOneWidget);
      await _capture(tester, 'cover_scrolled_${size.$2}');
    });

    testWidgets('address ${size.$2}', (tester) async {
      final container = await ready();
      addTearDown(container.dispose);
      await pumpRoutedEditor(
        tester,
        container: container,
        size: size.$1,
        safe: size.$3,
        path: '/address',
        builder: (_) => const StoreAddressScreen(),
      );
      expect(find.text(AppStrings.storeAddressCoordsSection), findsOneWidget);
      expect(find.text(AppStrings.storeAddressSection), findsOneWidget);
      await _capture(tester, 'address_${size.$2}');
    });

    testWidgets('address scrolled ${size.$2}', (tester) async {
      final container = await ready();
      addTearDown(container.dispose);
      await pumpRoutedEditor(
        tester,
        container: container,
        size: size.$1,
        safe: size.$3,
        path: '/address',
        builder: (_) => const StoreAddressScreen(),
      );
      await tester
          .ensureVisible(find.byKey(const Key('store-address-open-map')));
      await tester.pump();
      expect(find.text(AppStrings.storeAddressLocationSummary), findsOneWidget);
      expect(find.byKey(const Key('store-address-open-map')), findsOneWidget);
      await _capture(tester, 'address_scrolled_${size.$2}');
    });

    testWidgets('address keyboard simulated ${size.$2}', (tester) async {
      final container = await ready();
      addTearDown(container.dispose);
      await pumpRoutedEditor(
        tester,
        container: container,
        size: size.$1,
        safe: size.$3,
        keyboardHeight: 280,
        path: '/address',
        builder: (_) => const StoreAddressScreen(),
      );
      await tester.ensureVisible(find.byKey(const Key('store-address-phone')));
      await tester.tap(find.byKey(const Key('store-address-phone')));
      await tester.pump();
      expect(find.byKey(const Key('store-address-phone')), findsOneWidget);
      File('$_out/address_keyboard_${size.$2}.NOTE.txt').writeAsStringSync(
        'Simulated MediaQuery.viewInsets.bottom=280 (not native IME capture).',
      );
      await _capture(tester, 'address_keyboard_${size.$2}');
    });
  }

  testWidgets('product create se text scale 1.3', (tester) async {
    final container = await ready();
    addTearDown(container.dispose);
    await pumpRoutedEditor(
      tester,
      container: container,
      size: const Size(375, 667),
      textScale: 1.3,
      path: '/product-new',
      builder: (_) => const ProductEditorScreen(),
    );
    await _capture(tester, 'product_create_se_text1_3');
  });

  testWidgets('address se text scale 1.3', (tester) async {
    final container = await ready();
    addTearDown(container.dispose);
    await pumpRoutedEditor(
      tester,
      container: container,
      size: const Size(375, 667),
      textScale: 1.3,
      path: '/address',
      builder: (_) => const StoreAddressScreen(),
    );
    await _capture(tester, 'address_se_text1_3');
  });

  testWidgets('product validation se shows field error then capture', (tester) async {
    final container = await ready();
    addTearDown(container.dispose);
    await pumpRoutedEditor(
      tester,
      container: container,
      size: const Size(375, 667),
      path: '/product-new',
      builder: (_) => const ProductEditorScreen(),
    );
    await tester.ensureVisible(find.byKey(const Key('product-editor-save')));
    await tester.tap(find.byKey(const Key('product-editor-save')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text(AppStrings.catalogFieldRequired), findsOneWidget);
    expect(find.text(AppStrings.catalogSaveError), findsNothing);
    await tester.ensureVisible(find.byKey(const Key('product-editor-name')));
    await tester.pump();
    await _capture(tester, 'product_validation_se');
    final create = File('$_out/product_create_se.png').readAsBytesSync();
    final validation =
        File('$_out/product_validation_se.png').readAsBytesSync();
    expect(create, isNot(equals(validation)));
  });

  testWidgets('product save failure se separate from validation', (tester) async {
    final container = await ready();
    addTearDown(container.dispose);
    // Override API to fail create via catalog controller path — use forms fixture style.
    final failing = _FailCreateCaptureApi();
    final store = MemorySessionStore();
    final ctx = MemoryContextStore();
    final mem = membership(
      branches: [
        MerchantBranch(
          id: 'b-1',
          name: 'Fixture Café',
          phone: '0550000000',
          addressText: '12 Rue Test',
          latitude: 36.75,
          longitude: 3.05,
          operationalStatus: 'ACTIVE',
        ),
      ],
      role: 'OWNER',
    ).copyWithName('Fixture Café');
    final failContainer = ProviderContainer(
      overrides: [
        merchantApiProvider.overrideWithValue(failing),
        sessionStoreProvider.overrideWithValue(store),
        contextStoreProvider.overrideWithValue(ctx),
        sessionControllerProvider.overrideWith(() => _ReadySession()),
        accessControllerProvider.overrideWith(
          () => _ReadyAccess(
            mem,
            mem.branches.first,
          ),
        ),
      ],
    );
    addTearDown(failContainer.dispose);
    await failContainer.read(catalogControllerProvider.future);
    await pumpRoutedEditor(
      tester,
      container: failContainer,
      size: const Size(375, 667),
      path: '/product-new',
      builder: (_) => const ProductEditorScreen(),
    );
    await tester.enterText(
      find.byKey(const Key('product-editor-name')),
      'Thé vert',
    );
    await tester.enterText(
      find.byKey(const Key('product-editor-price')),
      '12,00',
    );
    await tester.ensureVisible(find.byKey(const Key('product-editor-save')));
    await tester.tap(find.byKey(const Key('product-editor-save')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text(AppStrings.catalogSaveRetryHint), findsOneWidget);
    expect(find.text(AppStrings.catalogFieldRequired), findsNothing);
    expect(find.text('Thé vert'), findsOneWidget);
    await _capture(tester, 'product_save_failure_se');
  });

  testWidgets('product draft preview se with image then close', (tester) async {
    final container = await ready();
    addTearDown(container.dispose);
    await pumpRoutedEditor(
      tester,
      container: container,
      size: const Size(375, 667),
      path: '/product-new',
      builder: (_) => const ProductEditorScreen(),
    );
    await tester.enterText(
      find.byKey(const Key('product-editor-name')),
      'Salade César',
    );
    await tester.enterText(
      find.byKey(const Key('product-editor-description')),
      'Poulet, parmesan, croûtons',
    );
    await tester.enterText(
      find.byKey(const Key('product-editor-price')),
      '12,50',
    );
    final state = tester.state(find.byType(ProductEditorScreen));
    // 1x1 JPEG
    (state as dynamic).debugSetLocalImage(
      bytes: Uint8List.fromList([
        0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, 0x4A, 0x46, 0x49, 0x46, 0x00, 0x01,
        0x01, 0x00, 0x00, 0x01, 0x00, 0x01, 0x00, 0x00, 0xFF, 0xDB, 0x00, 0x43,
        0x00, 0x08, 0x06, 0x06, 0x07, 0x06, 0x05, 0x08, 0x07, 0x07, 0x07, 0x09,
        0x09, 0x08, 0x0A, 0x0C, 0x14, 0x0D, 0x0C, 0x0B, 0x0B, 0x0C, 0x19, 0x12,
        0x13, 0x0F, 0x14, 0x1D, 0x1A, 0x1F, 0x1E, 0x1D, 0x1A, 0x1C, 0x1C, 0x20,
        0x24, 0x2E, 0x27, 0x20, 0x22, 0x2C, 0x23, 0x1C, 0x1C, 0x28, 0x37, 0x29,
        0x2C, 0x30, 0x31, 0x34, 0x34, 0x34, 0x1F, 0x27, 0x39, 0x3D, 0x38, 0x32,
        0x3C, 0x2E, 0x33, 0x34, 0x32, 0xFF, 0xC0, 0x00, 0x0B, 0x08, 0x00, 0x01,
        0x00, 0x01, 0x01, 0x01, 0x11, 0x00, 0xFF, 0xC4, 0x00, 0x14, 0x00, 0x01,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x08, 0xFF, 0xC4, 0x00, 0x14, 0x10, 0x01, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0xFF, 0xDA, 0x00, 0x08, 0x01, 0x01, 0x00, 0x00, 0x3F, 0x00,
        0x7F, 0xFF, 0xD9,
      ]),
      name: 'preview.jpg',
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('product-editor-preview')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.byKey(const Key('product-preview-sheet')), findsOneWidget);
    expect(find.byKey(const Key('product-preview-name')), findsOneWidget);
    expect(find.byKey(const Key('product-preview-image')), findsOneWidget);
    expect(find.byKey(const Key('product-preview-price')), findsOneWidget);
    await _capture(tester, 'product_preview_se');
    await tester.tap(find.byKey(const Key('product-preview-close')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byKey(const Key('product-preview-sheet')), findsNothing);
    final nameField = tester.widget<TextField>(
      find.byKey(const Key('product-editor-name')),
    );
    expect(nameField.controller?.text, 'Salade César');
  });

  testWidgets('back navigates to hub', (tester) async {
    final container = await ready();
    addTearDown(container.dispose);
    await pumpRoutedEditor(
      tester,
      container: container,
      size: const Size(375, 667),
      path: '/product-new',
      builder: (_) => const ProductEditorScreen(),
    );
    await tester.tap(find.byKey(const Key('merchant-back')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byKey(const Key('test-hub')), findsOneWidget);
  });
}

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

class _EditorCaptureApi extends FakeMerchantApi {
  static const _category = CatalogCategory(
    id: 'c-1',
    branchId: 'b-1',
    name: 'Plats',
    sortOrder: 0,
    active: true,
  );

  static const _product = CatalogProduct(
    id: 'p-1',
    branchId: 'b-1',
    categoryId: 'c-1',
    name: 'Couscous Royal',
    description: 'Fixture',
    priceMinor: '1500',
    available: true,
  );

  @override
  Future<CatalogBootstrap> getCatalogBootstrap({
    required String merchantId,
    required String branchId,
  }) async =>
      const CatalogBootstrap(
        branchId: 'b-1',
        stats: CatalogStats(
          categoryCount: 1,
          productCount: 1,
          availableProductCount: 1,
        ),
        categories: [_category],
      );

  @override
  Future<List<CatalogCategory>> listCategories({
    required String merchantId,
    required String branchId,
  }) async =>
      const [_category];

  @override
  Future<List<CatalogProduct>> listProducts({
    required String merchantId,
    required String branchId,
    String? categoryId,
  }) async =>
      const [_product];

  @override
  Future<CatalogProduct> getProduct({
    required String merchantId,
    required String productId,
  }) async =>
      _product;
}

class _FailCreateCaptureApi extends _EditorCaptureApi {
  @override
  Future<CatalogProduct> createProduct({
    required String merchantId,
    required String branchId,
    required String categoryId,
    required String name,
    String? description,
    required int priceMinor,
    bool available = true,
    SellingUnitSelection? sellingUnit,
  }) async {
    throw Exception('create failed');
  }
}
