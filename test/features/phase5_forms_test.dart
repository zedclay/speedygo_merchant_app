import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:speedygo_merchant_app/app/theme/app_theme.dart';
import 'package:speedygo_merchant_app/core/constants/app_strings.dart';
import 'package:speedygo_merchant_app/core/storage/session_store.dart';
import 'package:speedygo_merchant_app/features/access/application/access_controller.dart';
import 'package:speedygo_merchant_app/features/access/data/evidence_file_picker.dart';
import 'package:speedygo_merchant_app/features/access/data/merchant_api.dart';
import 'package:speedygo_merchant_app/features/access/data/models.dart';
import 'package:speedygo_merchant_app/features/auth/application/auth_infrastructure.dart';
import 'package:speedygo_merchant_app/features/auth/application/session_controller.dart';
import 'package:speedygo_merchant_app/features/auth/application/session_providers.dart';
import 'package:speedygo_merchant_app/features/auth/application/session_state.dart';
import 'package:speedygo_merchant_app/features/catalog/application/catalog_controller.dart';
import 'package:speedygo_merchant_app/features/catalog/data/catalog_models.dart';
import 'package:speedygo_merchant_app/features/catalog/presentation/catalog_screen.dart';
import 'package:speedygo_merchant_app/features/catalog/presentation/category_editor_screen.dart';
import 'package:speedygo_merchant_app/features/catalog/presentation/product_editor_screen.dart';
import 'package:speedygo_merchant_app/features/store/presentation/store_address_screen.dart';
import 'package:speedygo_merchant_app/features/store/presentation/store_cover_screen.dart';

import '../helpers/path_provider_fixture.dart';
import 'phase1_flow_test.dart';

// 1x1 PNG
final fixturePng = AcceptanceFixtureEvidenceFilePicker.fixturePngBytes;

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

  MerchantMembership mem({String role = 'OWNER', MerchantBranch? forBranch}) =>
      membership(branches: [forBranch ?? branch], role: role)
          .copyWithName('Fixture Café');

  ProviderContainer containerFor(
    FakeMerchantApi merchant, {
    String role = 'OWNER',
    MerchantBranch? withBranch,
  }) {
    final selected = withBranch ?? branch;
    return ProviderContainer(
      overrides: [
        merchantApiProvider.overrideWithValue(merchant),
        sessionStoreProvider.overrideWithValue(MemorySessionStore()),
        contextStoreProvider.overrideWithValue(MemoryContextStore()),
        sessionControllerProvider.overrideWith(() => _ReadySession()),
        accessControllerProvider.overrideWith(
          () => _ReadyAccess(mem(role: role, forBranch: selected), selected),
        ),
      ],
    );
  }

  Future<void> pumpRouted(
    WidgetTester tester, {
    required ProviderContainer container,
    required String path,
    required Widget Function(GoRouterState) builder,
  }) async {
    final router = GoRouter(
      initialLocation: path,
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const Scaffold(
            body: Text('hub', key: Key('test-hub')),
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
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          theme: AppTheme.light(locale: const Locale('fr')),
          routerConfig: router,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));
  }

  Future<void> pumpBare(
    WidgetTester tester, {
    required ProviderContainer container,
    required Widget child,
  }) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.light(locale: const Locale('fr')),
          home: child,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));
  }

  group('product editor', () {
    testWidgets('create validates empty name and stays on form', (tester) async {
      final merchant = _CatalogFixtureApi();
      final container = containerFor(merchant);
      addTearDown(container.dispose);
      await container.read(catalogControllerProvider.future);

      await pumpBare(
        tester,
        container: container,
        child: const ProductEditorScreen(),
      );

      await tester.ensureVisible(find.byKey(const Key('product-editor-save')));
      await tester.tap(find.byKey(const Key('product-editor-save')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text(AppStrings.catalogFieldRequired), findsOneWidget);
      expect(find.text(AppStrings.catalogSaveError), findsNothing);
      expect(find.byKey(const Key('product-editor-screen')), findsOneWidget);
      expect(merchant.createProductCalls, 0);
    });

    testWidgets('create save failure keeps form and shows error', (tester) async {
      final merchant = _CatalogFixtureApi(failCreateProduct: true);
      final container = containerFor(merchant);
      addTearDown(container.dispose);
      await container.read(catalogControllerProvider.future);

      await pumpBare(
        tester,
        container: container,
        child: const ProductEditorScreen(),
      );

      await tester.enterText(
        find.byKey(const Key('product-editor-name')),
        'Thé à la menthe',
      );
      await tester.enterText(
        find.byKey(const Key('product-editor-price')),
        '15,00',
      );
      await tester.tap(find.byKey(const Key('product-editor-save')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byKey(const Key('product-editor-error')), findsOneWidget);
      expect(find.text(AppStrings.catalogSaveRetryHint), findsOneWidget);
      expect(find.byKey(const Key('product-editor-screen')), findsOneWidget);
      expect(find.text('Thé à la menthe'), findsOneWidget);
    });

    testWidgets('local draft preview shows fields and does not save', (tester) async {
      final merchant = _CatalogFixtureApi();
      final container = containerFor(merchant);
      addTearDown(container.dispose);
      await container.read(catalogControllerProvider.future);

      await pumpBare(
        tester,
        container: container,
        child: const ProductEditorScreen(),
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
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byKey(const Key('product-preview-sheet')), findsOneWidget);
      expect(find.byKey(const Key('product-preview-name')), findsOneWidget);
      expect(find.text('Salade César'), findsWidgets);
      expect(
        find.byKey(const Key('product-preview-description')),
        findsOneWidget,
      );
      expect(find.text('Poulet, parmesan, croûtons'), findsWidgets);
      expect(find.byKey(const Key('product-preview-price')), findsOneWidget);
      expect(find.textContaining('12,50'), findsWidgets);
      expect(find.byKey(const Key('product-preview-image')), findsOneWidget);
      expect(merchant.createProductCalls, 0);

      await tester.tap(find.byKey(const Key('product-preview-close')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byKey(const Key('product-preview-sheet')), findsNothing);
      expect(find.byKey(const Key('product-editor-screen')), findsOneWidget);
      final nameField = tester.widget<TextField>(
        find.byKey(const Key('product-editor-name')),
      );
      final descField = tester.widget<TextField>(
        find.byKey(const Key('product-editor-description')),
      );
      final priceField = tester.widget<TextField>(
        find.byKey(const Key('product-editor-price')),
      );
      expect(nameField.controller?.text, 'Salade César');
      expect(descField.controller?.text, 'Poulet, parmesan, croûtons');
      expect(priceField.controller?.text, '12,50');
      expect(merchant.createProductCalls, 0);
    });

    testWidgets('edit reopen loads existing product fields', (tester) async {
      final merchant = _CatalogFixtureApi();
      final container = containerFor(merchant);
      addTearDown(container.dispose);
      await container.read(catalogControllerProvider.future);

      await pumpBare(
        tester,
        container: container,
        child: const ProductEditorScreen(productId: 'p-1'),
      );

      expect(find.byKey(const Key('product-editor-name')), findsOneWidget);
      final nameField = tester.widget<TextField>(find.byKey(const Key('product-editor-name')));
      expect(nameField.controller?.text, 'Couscous Royal');
      expect(find.byKey(const Key('product-editor-delete')), findsOneWidget);
    });

    testWidgets('delete confirms then calls API and pops', (tester) async {
      final merchant = _CatalogFixtureApi();
      final container = containerFor(merchant);
      addTearDown(container.dispose);
      await container.read(catalogControllerProvider.future);

      await pumpRouted(
        tester,
        container: container,
        path: '/product',
        builder: (_) => const ProductEditorScreen(productId: 'p-1'),
      );

      await tester.ensureVisible(find.byKey(const Key('product-editor-delete')));
      await tester.tap(find.byKey(const Key('product-editor-delete')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text(AppStrings.catalogDeleteConfirm), findsOneWidget);
      await tester.tap(
        find.widgetWithText(FilledButton, AppStrings.catalogDeleteProduct).last,
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(merchant.deleteProductCalls, 1);
      expect(find.byKey(const Key('test-hub')), findsOneWidget);
    });

    testWidgets('image bind failure keeps form with partial message', (tester) async {
      final merchant = _CatalogFixtureApi(failBindImage: true);
      final container = containerFor(merchant);
      addTearDown(container.dispose);
      await container.read(catalogControllerProvider.future);

      await pumpBare(
        tester,
        container: container,
        child: const ProductEditorScreen(),
      );

      await tester.enterText(
        find.byKey(const Key('product-editor-name')),
        'Jus',
      );
      await tester.enterText(
        find.byKey(const Key('product-editor-price')),
        '8',
      );

      final state = tester.state(find.byType(ProductEditorScreen));
      (state as dynamic).debugSetLocalImage(
        bytes: fixturePng,
      );
      await tester.pump();

      await tester.tap(find.byKey(const Key('product-editor-save')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(merchant.createProductCalls, 1);
      expect(merchant.uploadImageCalls, 1);
      expect(merchant.bindImageCalls, 1);
      expect(find.text(AppStrings.catalogImageBindPartial), findsOneWidget);
      expect(find.byKey(const Key('product-editor-screen')), findsOneWidget);
      expect(find.text('Jus'), findsOneWidget);
    });

    testWidgets('image upload failure keeps form; bind not attempted', (tester) async {
      final merchant = _CatalogFixtureApi(failUploadImage: true);
      final container = containerFor(merchant);
      addTearDown(container.dispose);
      await container.read(catalogControllerProvider.future);

      await pumpBare(
        tester,
        container: container,
        child: const ProductEditorScreen(),
      );

      await tester.enterText(
        find.byKey(const Key('product-editor-name')),
        'Jus',
      );
      await tester.enterText(
        find.byKey(const Key('product-editor-price')),
        '8',
      );
      final state = tester.state(find.byType(ProductEditorScreen));
      (state as dynamic).debugSetLocalImage(
        bytes: fixturePng,
      );
      await tester.pump();

      await tester.tap(find.byKey(const Key('product-editor-save')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(merchant.createProductCalls, 1);
      expect(merchant.uploadImageCalls, 1);
      expect(merchant.bindImageCalls, 0);
      expect(find.text(AppStrings.catalogImageUploadError), findsOneWidget);
      expect(find.byKey(const Key('product-editor-screen')), findsOneWidget);
    });

    testWidgets(
        'successful bind keeps local preview and does not claim remote gap', (tester) async {
      final merchant = _CatalogFixtureApi();
      final container = containerFor(merchant);
      addTearDown(container.dispose);
      await container.read(catalogControllerProvider.future);

      await pumpRouted(
        tester,
        container: container,
        path: '/product',
        builder: (_) => const ProductEditorScreen(),
      );

      await tester.enterText(
        find.byKey(const Key('product-editor-name')),
        'Jus',
      );
      await tester.enterText(
        find.byKey(const Key('product-editor-price')),
        '8',
      );
      final state = tester.state(find.byType(ProductEditorScreen));
      (state as dynamic).debugSetLocalImage(
        bytes: fixturePng,
      );
      await tester.pump();

      await tester.tap(find.byKey(const Key('product-editor-save')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(merchant.bindImageCalls, 1);
      expect(
        find.text(AppStrings.catalogImageRemoteUnavailable),
        findsNothing,
      );
      expect(find.byKey(const Key('product-editor-screen')), findsOneWidget);
      expect(find.text('Jus'), findsWidgets);
    });

    testWidgets('STAFF role is read-only without save bar', (tester) async {
      final merchant = _CatalogFixtureApi();
      final container = containerFor(merchant, role: 'STAFF');
      addTearDown(container.dispose);
      await container.read(catalogControllerProvider.future);

      await pumpBare(
        tester,
        container: container,
        child: const ProductEditorScreen(productId: 'p-1'),
      );

      expect(find.text(AppStrings.catalogStaffReadOnly), findsOneWidget);
      expect(find.byKey(const Key('product-editor-save')), findsNothing);
      expect(find.byKey(const Key('product-editor-delete')), findsNothing);
    });

    testWidgets('MANAGER can save product', (tester) async {
      final merchant = _CatalogFixtureApi();
      final container = containerFor(merchant, role: 'MANAGER');
      addTearDown(container.dispose);
      await container.read(catalogControllerProvider.future);

      await pumpRouted(
        tester,
        container: container,
        path: '/product',
        builder: (_) => const ProductEditorScreen(),
      );

      await tester.enterText(
        find.byKey(const Key('product-editor-name')),
        'Manager Plat',
      );
      await tester.enterText(
        find.byKey(const Key('product-editor-price')),
        '20',
      );
      await tester.tap(find.byKey(const Key('product-editor-save')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(merchant.createProductCalls, 1);
      expect(find.byKey(const Key('test-hub')), findsOneWidget);
    });
  });

  group('category editor', () {
    testWidgets('create and delete confirmation', (tester) async {
      final merchant = _CatalogFixtureApi();
      final container = containerFor(merchant);
      addTearDown(container.dispose);
      await container.read(catalogControllerProvider.future);

      await pumpRouted(
        tester,
        container: container,
        path: '/category',
        builder: (_) => const CategoryEditorScreen(),
      );
      await tester.enterText(
        find.byKey(const Key('category-editor-name')),
        'Boissons',
      );
      await tester.tap(find.byKey(const Key('category-editor-save')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(merchant.createCategoryCalls, 1);
      expect(find.byKey(const Key('test-hub')), findsOneWidget);

      await pumpRouted(
        tester,
        container: container,
        path: '/category',
        builder: (_) => const CategoryEditorScreen(categoryId: 'c-1'),
      );
      await tester.ensureVisible(find.byKey(const Key('category-editor-delete')));
      await tester.tap(find.byKey(const Key('category-editor-delete')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text(AppStrings.catalogDeleteCategoryConfirm), findsOneWidget);
      await tester.tap(
        find.widgetWithText(FilledButton, AppStrings.catalogDeleteCategory),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(merchant.deleteCategoryCalls, 1);
    });
  });

  group('cover and address', () {
    testWidgets('cover bind failure keeps form', (tester) async {
      final merchant = _CatalogFixtureApi(failBindCover: true);
      final container = containerFor(merchant);
      addTearDown(container.dispose);

      await pumpBare(
        tester,
        container: container,
        child: const StoreCoverScreen(),
      );

      final state = tester.state(find.byType(StoreCoverScreen));
      (state as dynamic).debugSetCoverBytes(
        bytes: fixturePng,
      );
      await tester.pump();

      await tester.tap(find.byKey(const Key('store-cover-save')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text(AppStrings.storeCoverBindPartial), findsOneWidget);
      expect(find.byKey(const Key('store-cover-screen')), findsOneWidget);
      expect(merchant.bindCoverCalls, 1);
    });

    testWidgets('cover upload then bind succeeds without claiming remote read',
        (tester) async {
      final merchant = _CatalogFixtureApi();
      final container = containerFor(merchant);
      addTearDown(container.dispose);

      await pumpRouted(
        tester,
        container: container,
        path: '/cover',
        builder: (_) => const StoreCoverScreen(),
      );

      final state = tester.state(find.byType(StoreCoverScreen));
      (state as dynamic).debugSetCoverBytes(
        bytes: fixturePng,
      );
      await tester.pump();
      await tester.tap(find.byKey(const Key('store-cover-save')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(merchant.uploadCoverCalls, 1);
      expect(merchant.bindCoverCalls, 1);
      expect(find.byKey(const Key('test-hub')), findsOneWidget);
    });

    testWidgets('address save requires map confirm; reopen shows saved values',
        (tester) async {
      final merchant = _CatalogFixtureApi();
      final container = containerFor(merchant);
      addTearDown(container.dispose);

      await pumpRouted(
        tester,
        container: container,
        path: '/address',
        builder: (_) => const StoreAddressScreen(),
      );

      expect(find.text('12 Rue Test'), findsOneWidget);

      final state = tester.state(find.byType(StoreAddressScreen));
      (state as dynamic).debugSetMapConfirmation(confirmed: false);
      await tester.pump();

      await tester.tap(find.byKey(const Key('store-address-save')));
      await tester.pump();
      expect(find.text(AppStrings.storeAddressSaveError), findsOneWidget);
      expect(merchant.updateBranchCalls, 0);

      (state as dynamic).debugSetMapConfirmation(
        confirmed: true,
        latitude: 36.76,
        longitude: 3.06,
      );
      await tester.enterText(
        find.byKey(const Key('store-address-phone')),
        '0550111222',
      );
      await tester.enterText(
        find.byKey(const Key('store-address-text')),
        '99 Avenue Fixture',
      );
      await tester.pump();
      await tester.tap(find.byKey(const Key('store-address-save')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(merchant.updateBranchCalls, 1);
      expect(merchant.lastAddress, '99 Avenue Fixture');
      // Legacy branch (no Wilaya/Commune): unrelated update, pair omitted.
      expect(merchant.lastWilayaCode, isNull);
      expect(merchant.lastCommuneId, isNull);
      expect(find.byKey(const Key('test-hub')), findsOneWidget);
    });

    testWidgets('branch with a stored pair re-sends the restored pair',
        (tester) async {
      final merchant = _CatalogFixtureApi();
      final container = containerFor(
        merchant,
        withBranch: const MerchantBranch(
          id: 'b-1',
          name: 'Fixture Café',
          phone: '0550000000',
          addressText: '12 Rue Test',
          latitude: 36.75,
          longitude: 3.05,
          operationalStatus: 'ACTIVE',
          wilayaCode: '16',
          communeId: 556,
        ),
      );
      addTearDown(container.dispose);

      await pumpRouted(
        tester,
        container: container,
        path: '/address',
        builder: (_) => const StoreAddressScreen(),
      );
      expect(find.textContaining('Alger Centre'), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('store-address-phone')),
        '0550111222',
      );
      await tester.pump();
      await tester.tap(find.byKey(const Key('store-address-save')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(merchant.updateBranchCalls, 1);
      expect(merchant.lastWilayaCode, '16');
      expect(merchant.lastCommuneId, 556);
    });

    testWidgets('Wilaya without Commune is rejected (pair rule)',
        (tester) async {
      final merchant = _CatalogFixtureApi();
      final container = containerFor(
        merchant,
        withBranch: const MerchantBranch(
          id: 'b-1',
          name: 'Fixture Café',
          phone: '0550000000',
          addressText: '12 Rue Test',
          latitude: 36.75,
          longitude: 3.05,
          operationalStatus: 'ACTIVE',
          wilayaCode: '16',
          // Not in the Wilaya's catalogue: Wilaya restores, Commune does not.
          communeId: 999999,
        ),
      );
      addTearDown(container.dispose);

      await pumpRouted(
        tester,
        container: container,
        path: '/address',
        builder: (_) => const StoreAddressScreen(),
      );
      await tester.tap(find.byKey(const Key('store-address-save')));
      await tester.pump();
      expect(find.text(AppStrings.adminLocationPairRequired), findsOneWidget);
      expect(merchant.updateBranchCalls, 0);
    });

    testWidgets('unauthorized STAFF cannot save cover or address', (tester) async {
      final merchant = _CatalogFixtureApi();
      final container = containerFor(merchant, role: 'STAFF');
      addTearDown(container.dispose);

      await pumpBare(
        tester,
        container: container,
        child: const StoreCoverScreen(),
      );
      expect(find.byKey(const Key('store-cover-save')), findsNothing);
      expect(find.byKey(const Key('store-cover-pick')), findsNothing);

      await pumpBare(
        tester,
        container: container,
        child: const StoreAddressScreen(),
      );
      expect(find.byKey(const Key('store-address-save')), findsNothing);
    });
  });

  group('catalog empty/fab', () {
    testWidgets('empty catalogue shows CTA and hides FAB', (tester) async {
      final merchant = _CatalogFixtureApi(emptyProducts: true);
      final container = containerFor(merchant);
      addTearDown(container.dispose);

      await pumpBare(
        tester,
        container: container,
        child: const CatalogScreen(),
      );

      expect(find.byKey(const Key('catalog-empty-add-product')), findsOneWidget);
      expect(find.byKey(const Key('catalog-add-fab')), findsNothing);
    });

    testWidgets('populated catalogue shows compact FAB and product row',
        (tester) async {
      final merchant = _CatalogFixtureApi();
      final container = containerFor(merchant);
      addTearDown(container.dispose);

      await pumpBare(
        tester,
        container: container,
        child: const CatalogScreen(),
      );

      expect(find.byKey(const Key('catalog-add-fab')), findsOneWidget);
      expect(find.byKey(const Key('catalog-product-p-1')), findsOneWidget);
      expect(
        find.byKey(const Key('catalog-product-available-p-1')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('catalog-product-menu-p-1')), findsOneWidget);
    });
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

  @override
  Future<void> selectBranch(MerchantBranch next) async {}

  @override
  Future<void> refreshInPlace() async {}
}

class _CatalogFixtureApi extends FakeMerchantApi {
  _CatalogFixtureApi({
    this.failCreateProduct = false,
    this.failUploadImage = false,
    this.failBindImage = false,
    this.failBindCover = false,
    this.emptyProducts = false,
  });

  final bool failCreateProduct;
  final bool failUploadImage;
  final bool failBindImage;
  final bool failBindCover;
  final bool emptyProducts;

  int createProductCalls = 0;
  int deleteProductCalls = 0;
  int createCategoryCalls = 0;
  int deleteCategoryCalls = 0;
  int uploadImageCalls = 0;
  int bindImageCalls = 0;
  int uploadCoverCalls = 0;
  int bindCoverCalls = 0;
  int updateBranchCalls = 0;
  String? lastAddress;
  String? lastWilayaCode;
  int? lastCommuneId;

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
      CatalogBootstrap(
        branchId: branchId,
        stats: CatalogStats(
          categoryCount: 1,
          productCount: emptyProducts ? 0 : 1,
          availableProductCount: emptyProducts ? 0 : 1,
        ),
        categories: const [_category],
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
      emptyProducts ? const [] : const [_product];

  @override
  Future<CatalogProduct> getProduct({
    required String merchantId,
    required String productId,
  }) async =>
      _product;

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
    createProductCalls += 1;
    if (failCreateProduct) throw Exception('create failed');
    return CatalogProduct(
      id: 'p-new',
      branchId: branchId,
      categoryId: categoryId,
      name: name,
      description: description,
      priceMinor: '$priceMinor',
      available: available,
      sellingUnitCode: sellingUnit?.code,
      sellingUnitLabelFr: sellingUnit?.labelFr,
    );
  }

  @override
  Future<void> deleteProduct({
    required String merchantId,
    required String productId,
  }) async {
    deleteProductCalls += 1;
  }

  @override
  Future<CatalogCategory> createCategory({
    required String merchantId,
    required String branchId,
    required String name,
    int? sortOrder,
    bool active = true,
  }) async {
    createCategoryCalls += 1;
    return CatalogCategory(
      id: 'c-new',
      branchId: branchId,
      name: name,
      sortOrder: sortOrder ?? 0,
      active: active,
    );
  }

  @override
  Future<void> deleteCategory({
    required String merchantId,
    required String categoryId,
  }) async {
    deleteCategoryCalls += 1;
  }

  @override
  Future<EvidenceUploadResult> uploadProductImageContent({
    required String merchantId,
    required String branchId,
    required String productId,
    required String filename,
    required String contentType,
    required Uint8List bytes,
  }) async {
    uploadImageCalls += 1;
    if (failUploadImage) throw Exception('upload failed');
    return super.uploadProductImageContent(
      merchantId: merchantId,
      branchId: branchId,
      productId: productId,
      filename: filename,
      contentType: contentType,
      bytes: bytes,
    );
  }

  @override
  Future<MediaBindResult> bindProductImage({
    required String merchantId,
    required String branchId,
    required String productId,
    required String uploadReference,
  }) async {
    bindImageCalls += 1;
    if (failBindImage) throw Exception('bind failed');
    return super.bindProductImage(
      merchantId: merchantId,
      branchId: branchId,
      productId: productId,
      uploadReference: uploadReference,
    );
  }

  @override
  Future<EvidenceUploadResult> uploadBranchCoverContent({
    required String merchantId,
    required String branchId,
    required String filename,
    required String contentType,
    required Uint8List bytes,
  }) async {
    uploadCoverCalls += 1;
    return super.uploadBranchCoverContent(
      merchantId: merchantId,
      branchId: branchId,
      filename: filename,
      contentType: contentType,
      bytes: bytes,
    );
  }

  @override
  Future<MediaBindResult> bindBranchCover({
    required String merchantId,
    required String branchId,
    required String uploadReference,
  }) async {
    bindCoverCalls += 1;
    if (failBindCover) throw Exception('cover bind failed');
    return super.bindBranchCover(
      merchantId: merchantId,
      branchId: branchId,
      uploadReference: uploadReference,
    );
  }

  @override
  Future<MerchantBranch> updateBranch({
    required String merchantId,
    required String branchId,
    String? name,
    String? phone,
    String? addressText,
    double? latitude,
    double? longitude,
    String? wilayaCode,
    int? communeId,
    Map<String, String?>? publicInfo,
  }) async {
    updateBranchCalls += 1;
    lastAddress = addressText;
    lastWilayaCode = wilayaCode;
    lastCommuneId = communeId;
    return MerchantBranch(
      id: branchId,
      name: name ?? 'Fixture Café',
      phone: phone ?? '0550000000',
      addressText: addressText ?? '12 Rue Test',
      latitude: latitude ?? 36.75,
      longitude: longitude ?? 3.05,
      operationalStatus: 'ACTIVE',
      wilayaCode: wilayaCode,
      communeId: communeId,
      description: publicInfo?['description'],
      nameAr: publicInfo?['nameAr'],
      publicEmail: publicInfo?['publicEmail'],
    );
  }
}
