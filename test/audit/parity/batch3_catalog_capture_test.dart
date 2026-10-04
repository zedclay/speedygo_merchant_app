import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:speedygo_merchant_app/app/theme/app_theme.dart';
import 'package:speedygo_merchant_app/core/constants/app_strings.dart';
import 'package:speedygo_merchant_app/core/errors/app_exception.dart';
import 'package:speedygo_merchant_app/features/access/data/merchant_api.dart';
import 'package:speedygo_merchant_app/features/access/data/models.dart';
import 'package:speedygo_merchant_app/features/catalog/application/catalog_controller.dart';
import 'package:speedygo_merchant_app/features/catalog/data/catalog_models.dart';
import 'package:speedygo_merchant_app/features/catalog/presentation/catalog_screen.dart';
import 'package:speedygo_merchant_app/features/catalog/presentation/catalog_sub_screens.dart';
import 'package:speedygo_merchant_app/features/catalog/presentation/catalog_widgets.dart';
import 'package:speedygo_merchant_app/features/catalog/presentation/category_editor_screen.dart';
import 'package:speedygo_merchant_app/features/catalog/presentation/option_groups_screen.dart';
import 'package:speedygo_merchant_app/features/catalog/presentation/product_detail_screen.dart';
import 'package:speedygo_merchant_app/features/catalog/presentation/product_editor_screen.dart';
import 'package:speedygo_merchant_app/features/catalog/presentation/product_image_crop_screen.dart';
import 'package:speedygo_merchant_app/features/shell/merchant_shell.dart';

import '../../features/phase1_flow_test.dart';
import 'parity_harness.dart';

const _categories = [
  CatalogCategory(
    id: 'c1',
    branchId: 'b1',
    name: 'Plats traditionnels',
    sortOrder: 1,
    active: true,
  ),
  CatalogCategory(
    id: 'c2',
    branchId: 'b1',
    name: 'Soupes',
    sortOrder: 2,
    active: true,
  ),
  CatalogCategory(
    id: 'c3',
    branchId: 'b1',
    name: 'Boissons',
    sortOrder: 3,
    active: true,
  ),
  CatalogCategory(
    id: 'c4',
    branchId: 'b1',
    name: 'Entrées',
    sortOrder: 4,
    active: false,
  ),
];

CatalogProduct _p(
  String id,
  String category,
  String name,
  String price, {
  bool available = true,
  String? description,
}) =>
    CatalogProduct(
      id: id,
      branchId: 'b1',
      categoryId: category,
      name: name,
      description: description,
      priceMinor: price,
      available: available,
      updatedAt: DateTime.utc(2026, 9, 30, 10, 20),
    );

final _products = [
  _p('p1', 'c1', 'Couscous royal', '150000',
      description: 'Agneau, légumes, pois chiches'),
  _p('p2', 'c2', 'Chorba frik', '35000'),
  _p('p3', 'c1', 'Tajine zitoun', '95000', available: false),
  _p('p4', 'c1', 'Pain traditionnel', '5000'),
  _p('p5', 'c3', 'Citronnade maison', '15000'),
];

class _CatalogApi extends FakeMerchantApi {
  _CatalogApi({String role = 'OWNER', List<CatalogProduct>? products})
      : super(
          meHandler: () async => MerchantMe(
            merchantMembershipExists: true,
            memberships: [
              membership(
                role: role,
                branches: [branch('b1', name: 'Dar El Benna')],
              ).parityWith(name: 'Dar El Benna'),
            ],
          ),
          catalogBootstrapHandler: ({required merchantId, required branchId}) async =>
              CatalogBootstrap(
                branchId: branchId,
                stats: const CatalogStats(
                  categoryCount: 4,
                  productCount: 5,
                  availableProductCount: 4,
                ),
                categories: _categories,
              ),
          productsHandler: ({required merchantId, required branchId, categoryId}) async =>
              products ?? _products,
        );

  final List<String> categoryUpdates = [];
  final List<String> availabilityUpdates = [];
  int deleteCalls = 0;
  Object? deleteError;

  @override
  Future<CatalogProduct> getProduct({
    required String merchantId,
    required String productId,
  }) async =>
      _products.firstWhere((p) => p.id == productId);

  @override
  Future<CatalogCategory> updateCategory({
    required String merchantId,
    required String categoryId,
    String? name,
    int? sortOrder,
    bool? active,
  }) async {
    categoryUpdates.add('$categoryId:${sortOrder ?? '-'}:${active ?? '-'}');
    final c = _categories.firstWhere((c) => c.id == categoryId);
    return c.copyWith(name: name, sortOrder: sortOrder, active: active);
  }

  @override
  Future<CatalogProduct> updateProductAvailability({
    required String merchantId,
    required String productId,
    required bool available,
  }) async {
    availabilityUpdates.add('$productId:$available');
    return _products
        .firstWhere((p) => p.id == productId)
        .copyWith(available: available);
  }

  @override
  Future<void> deleteProduct({
    required String merchantId,
    required String productId,
  }) async {
    deleteCalls++;
    final e = deleteError;
    if (e != null) throw e;
  }
}

_CatalogApi _seededApi({String role = 'OWNER'}) {
  final api = _CatalogApi(role: role);
  api.optionGroups['p1'] = [
    const CatalogOptionGroup(
      id: 'g1',
      name: 'Portion',
      required: true,
      minSelections: 1,
      maxSelections: 1,
      options: [
        CatalogOption(
          id: 'o1',
          name: 'Individuelle',
          additionalPriceMinor: '0',
          available: true,
        ),
        CatalogOption(
          id: 'o2',
          name: 'Familiale',
          additionalPriceMinor: '70000',
          available: true,
        ),
      ],
    ),
    const CatalogOptionGroup(
      id: 'g2',
      name: 'Suppléments viande',
      required: false,
      minSelections: 0,
      maxSelections: 3,
      options: [
        CatalogOption(
          id: 'o3',
          name: 'Agneau supplémentaire',
          additionalPriceMinor: '35000',
          available: true,
        ),
        CatalogOption(
          id: 'o4',
          name: 'Poulet supplémentaire',
          additionalPriceMinor: '25000',
          available: false,
        ),
      ],
    ),
  ];
  return api;
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 20; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

class _PagedAdapter implements HttpClientAdapter {
  final List<Map<String, dynamic>> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(Map.of(options.queryParameters));
    final offset = options.queryParameters['offset'] as int;
    final limit = options.queryParameters['limit'] as int;
    const total = 130;
    final count = (total - offset).clamp(0, limit);
    final items = [
      for (var i = 0; i < count; i++)
        {
          'id': 'p${offset + i}',
          'branchId': 'b1',
          'categoryId': 'c1',
          'name': 'P${offset + i}',
          'description': null,
          'priceMinor': '100',
          'available': true,
          'hasImage': false,
          'createdAt': '2026-01-01T00:00:00Z',
          'updatedAt': '2026-01-01T00:00:00Z',
        },
    ];
    return ResponseBody.fromString(
      jsonEncode({
        'items': items,
        'limit': limit,
        'offset': offset,
        'total': total,
      }),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  group('batch 3 catalogue captures', () {
    for (final v in parityVariants) {
      testWidgets('products list ${v.suffix}', (tester) async {
        final container = await parityReady(_seededApi());
        addTearDown(container.dispose);
        await container.read(catalogControllerProvider.future);
        await parityPumpFull(
          tester,
          container: container,
          variant: v,
          tabIndex: 2,
          child: const CatalogScreen(),
        );
        await parityCapture(tester, 'b3_products_${v.suffix}');
        expect(find.byKey(const Key('catalog-product-p1')), findsOneWidget);
      });

      testWidgets('product menu ${v.suffix}', (tester) async {
        final container = await parityReady(_seededApi());
        addTearDown(container.dispose);
        await container.read(catalogControllerProvider.future);
        await parityPump(
          tester,
          container: container,
          variant: v,
          height: 844,
          tabIndex: 2,
          includeOverlays: true,
          child: const CatalogScreen(),
        );
        await tester.tap(find.byKey(const Key('catalog-product-menu-p1')));
        await tester.pumpAndSettle();
        await parityCapture(tester, 'b3_product_menu_${v.suffix}');
      });

      testWidgets('categories list ${v.suffix}', (tester) async {
        final container = await parityReady(_seededApi());
        addTearDown(container.dispose);
        await container.read(catalogControllerProvider.future);
        await container
            .read(catalogControllerProvider.notifier)
            .setTab(CatalogTab.categories);
        await parityPumpFull(
          tester,
          container: container,
          variant: v,
          tabIndex: 2,
          child: const CatalogScreen(),
        );
        await parityCapture(tester, 'b3_categories_${v.suffix}');
      });

      final screens = <String, Widget>{
        'category_detail': const CategoryDetailScreen(categoryId: 'c1'),
        'reorder': const ReorderCategoriesScreen(),
        'filters': const ProductFiltersScreen(),
        'availability': const ProductAvailabilityScreen(productId: 'p1'),
        'bulk': const BulkAvailabilityScreen(),
        'delete': const ProductDeleteScreen(productId: 'p1'),
        'editor_edit': const ProductEditorScreen(productId: 'p1'),
        'editor_new': const ProductEditorScreen(),
        'variants': const OptionGroupsScreen(productId: 'p1', required: true),
        'extras': const OptionGroupsScreen(productId: 'p1', required: false),
        'category_editor': const CategoryEditorScreen(categoryId: 'c1'),
        'product_detail': const ProductDetailScreen(productId: 'p1'),
      };
      for (final entry in screens.entries) {
        testWidgets('${entry.key} ${v.suffix}', (tester) async {
          final container = await parityReady(_seededApi());
          addTearDown(container.dispose);
          await container.read(catalogControllerProvider.future);
          await parityPumpFull(
            tester,
            container: container,
            variant: v,
            child: entry.value,
            pushed: true,
          );
          if (entry.key == 'filters') {
            await tester.tap(find.byKey(const Key('filters-category-c1')));
            await tester.tap(find.byKey(const Key('filters-in-stock')));
            await tester.pump();
          }
          await _settle(tester);
          await parityCapture(tester, 'b3_${entry.key}_${v.suffix}');
        });
      }

      testWidgets('image crop ${v.suffix}', (tester) async {
        final container = await parityReady(_seededApi());
        addTearDown(container.dispose);
        final bytes = _sampleJpeg();
        final screen = ProductImageCropScreen(
          bytes: bytes,
          productName: 'Couscous royal',
        );
        await parityPumpFull(
          tester,
          container: container,
          variant: v,
          child: screen,
          pushed: true,
        );
        await tester.runAsync(() async {
          await precacheImage(
            MemoryImage(bytes),
            tester.element(find.byType(ProductImageCropScreen)),
          );
        });
        await _settle(tester);
        await parityCapture(tester, 'b3_image_crop_${v.suffix}');
      });

      testWidgets('category detail scrolled to end ${v.suffix}', (
        tester,
      ) async {
        final many = [
          ..._products,
          for (var i = 6; i <= 10; i++)
            _p('p$i', 'c1', 'Plat maison numéro $i', '${i}0000'),
        ];
        final container = await parityReady(_CatalogApi(products: many));
        addTearDown(container.dispose);
        await container.read(catalogControllerProvider.future);
        await parityPump(
          tester,
          container: container,
          variant: v,
          height: 667,
          bottomInset: 34,
          child: const CategoryDetailScreen(categoryId: 'c1'),
          pushed: true,
        );
        await _settle(tester);
        final position = tester
            .state<ScrollableState>(
              find.descendant(
                of: find.byKey(const Key('category-detail')),
                matching: find.byType(Scrollable),
              ),
            )
            .position;
        for (var i = 0; i < 5; i++) {
          final max = position.maxScrollExtent;
          position.jumpTo(max);
          await tester.pumpAndSettle();
          if (position.maxScrollExtent == max) break;
        }
        expect(position.pixels, position.maxScrollExtent);
        expect(position.maxScrollExtent, greaterThan(0));
        final last = tester.getRect(
          find.byKey(const Key('category-product-p10')),
        );
        final fab = tester.getRect(
          find.byKey(const Key('category-detail-add-product')),
        );
        expect(last.bottom + 8, lessThanOrEqualTo(fab.top));
        expect(fab.bottom, lessThanOrEqualTo(667 - 34));
        expect(fab.height, greaterThanOrEqualTo(56));
        final fabWidget = tester.widget<FloatingActionButton>(
          find.byKey(const Key('category-detail-add-product')),
        );
        expect(
          fabWidget.shape,
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        );
        expect(fabWidget.backgroundColor, AppColors.primary);
        final switches = tester.widgetList<CatalogSwitch>(
          find.byType(CatalogSwitch),
        );
        expect(switches, isNotEmpty);
        expect(
          switches.every((s) => s.tone == CatalogSwitchTone.olive),
          isTrue,
        );
        final material = tester.widget<Switch>(
          find.descendant(
            of: find.byKey(const Key('category-product-available-p10')),
            matching: find.byType(Switch),
          ),
        );
        expect(
          material.trackColor!.resolve({WidgetState.selected}),
          const Color(0xFF516400),
        );
        expect(
          material.trackColor!.resolve({}),
          AppColors.surfaceContainer,
        );
        await parityCapture(tester, 'b3_category_detail_end_${v.suffix}');
      });

      testWidgets('products tab scrolled to end ${v.suffix}', (tester) async {
        final many = [
          ..._products,
          for (var i = 6; i <= 12; i++)
            _p('p$i', 'c3', 'Boisson maison numéro $i', '${i}000'),
        ];
        final container = await parityReady(_CatalogApi(products: many));
        addTearDown(container.dispose);
        await container.read(catalogControllerProvider.future);
        await parityPump(
          tester,
          container: container,
          variant: v,
          height: 667,
          bottomInset: 34,
          tabIndex: 2,
          child: const CatalogScreen(),
        );
        await _settle(tester);
        final position = tester
            .stateList<ScrollableState>(find.byType(Scrollable))
            .map((s) => s.position)
            .firstWhere(
              (p) => p.axis == Axis.vertical && p.maxScrollExtent > 0,
            );
        // A lazy list refines its extent as rows build; jump until stable.
        for (var i = 0; i < 5; i++) {
          final max = position.maxScrollExtent;
          position.jumpTo(max);
          await tester.pumpAndSettle();
          if (position.maxScrollExtent == max) break;
        }
        expect(position.pixels, position.maxScrollExtent);
        final rows = find.byWidgetPredicate(
          (w) =>
              w.key is ValueKey<String> &&
              RegExp(r'^catalog-product-p\d+$')
                  .hasMatch((w.key! as ValueKey<String>).value),
        );
        expect(rows, findsWidgets);
        final lastBottom = tester
            .widgetList(rows)
            .map((w) => tester.getRect(find.byKey(w.key!)).bottom)
            .reduce((a, b) => a > b ? a : b);
        final fab = tester.getRect(find.byType(FloatingActionButton));
        final nav = tester.getRect(find.byType(MerchantBottomNav));
        expect(lastBottom + 8, lessThanOrEqualTo(fab.top));
        expect(fab.bottom, lessThanOrEqualTo(nav.top));
        // Only the app bar stays pinned: the search scrolled away, so the
        // list gets the space between the app bar and the FAB.
        final appBar = tester.getRect(find.byType(AppBar));
        final search = find.byKey(const Key('catalog-search'));
        expect(
          search.evaluate().isEmpty ||
              tester.getRect(search).bottom <= appBar.bottom,
          isTrue,
        );
        expect(fab.top - appBar.bottom, greaterThan(250));
        await parityCapture(tester, 'b3_products_end_${v.suffix}');
      });
    }

    testWidgets('search with no result keeps the field and its focus', (
      tester,
    ) async {
      final container = await parityReady(_CatalogApi());
      addTearDown(container.dispose);
      await container.read(catalogControllerProvider.future);
      await parityPump(
        tester,
        container: container,
        variant: parityVariants.last,
        height: 667,
        bottomInset: 34,
        tabIndex: 2,
        child: const CatalogScreen(),
      );
      await _settle(tester);
      final field = find.descendant(
        of: find.byKey(const Key('catalog-search')),
        matching: find.byType(EditableText),
      );
      await tester.tap(field);
      await tester.pump();
      final before = tester.state<EditableTextState>(field);
      await tester.enterText(field, 'zzzz introuvable');
      await _settle(tester);
      expect(find.byKey(const Key('catalog-no-results')), findsOneWidget);
      expect(tester.state<EditableTextState>(field), same(before));
      expect(before.widget.focusNode.hasFocus, isTrue);
    });
  });

  group('catalogue behaviour', () {
    test('product list follows pagination beyond the first page', () async {
      final adapter = _PagedAdapter();
      final dio = Dio(BaseOptions(baseUrl: 'http://test'))
        ..httpClientAdapter = adapter;
      final products = await MerchantApi(dio).listProducts(
        merchantId: 'm-1',
        branchId: 'b1',
      );
      expect(products, hasLength(130));
      expect(adapter.requests.map((r) => r['offset']), [0, 100]);
      expect(adapter.requests.every((r) => r['limit'] == 100), isTrue);
    });

    testWidgets('categories show real product counts and hidden state',
        (tester) async {
      final container = await parityReady(_seededApi());
      addTearDown(container.dispose);
      await container.read(catalogControllerProvider.future);
      await container
          .read(catalogControllerProvider.notifier)
          .setTab(CatalogTab.categories);
      await parityPump(
        tester,
        container: container,
        variant: parityVariants.first,
        height: 900,
        child: const CatalogScreen(),
      );
      expect(
        tester
            .widget<Text>(find.byKey(const Key('catalog-category-count-c1')))
            .data,
        '3 articles',
      );
      expect(
        tester
            .widget<Text>(find.byKey(const Key('catalog-category-count-c4')))
            .data,
        '0 article',
      );
      expect(find.text(AppStrings.catalogHidden), findsNWidgets(2));
    });

    testWidgets('product menu duplicate action is backed by the server route', (
      tester,
    ) async {
      final container = await parityReady(_seededApi());
      addTearDown(container.dispose);
      await container.read(catalogControllerProvider.future);
      await parityPump(
        tester,
        container: container,
        variant: parityVariants.first,
        height: 900,
        child: const CatalogScreen(),
      );
      await tester.tap(find.byKey(const Key('catalog-product-menu-p1')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('catalog-menu-edit')), findsOneWidget);
      expect(find.byKey(const Key('catalog-menu-availability')), findsOneWidget);
      expect(find.byKey(const Key('catalog-menu-delete')), findsOneWidget);
      expect(find.byKey(const Key('catalog-menu-duplicate')), findsOneWidget);
      expect(find.text('Dupliquer'), findsOneWidget);
    });

    testWidgets('category visibility toggle patches active', (tester) async {
      final api = _seededApi();
      final container = await parityReady(api);
      addTearDown(container.dispose);
      await container.read(catalogControllerProvider.future);
      await container
          .read(catalogControllerProvider.notifier)
          .setTab(CatalogTab.categories);
      await parityPump(
        tester,
        container: container,
        variant: parityVariants.first,
        height: 900,
        child: const CatalogScreen(),
      );
      await tester.tap(
        find.descendant(
          of: find.byKey(const Key('catalog-category-visible-c2')),
          matching: find.byType(Switch),
        ),
      );
      await _settle(tester);
      expect(api.categoryUpdates, ['c2:-:false']);
      final state = container.read(catalogControllerProvider).value!;
      expect(state.categories.firstWhere((c) => c.id == 'c2').active, isFalse);
    });

    test('reorder patches only moved categories with 1-based order', () async {
      final api = _seededApi();
      final container = await parityReady(api);
      addTearDown(container.dispose);
      await container.read(catalogControllerProvider.future);
      final failed = await container
          .read(catalogControllerProvider.notifier)
          .reorderCategories(['c2', 'c1', 'c3', 'c4']);
      expect(failed, isEmpty);
      expect(api.categoryUpdates, ['c2:1:-', 'c1:2:-']);
    });

    testWidgets('bulk availability updates each selected product',
        (tester) async {
      final api = _seededApi();
      final container = await parityReady(api);
      addTearDown(container.dispose);
      await container.read(catalogControllerProvider.future);
      await parityPump(
        tester,
        container: container,
        variant: parityVariants.first,
        height: 1400,
        child: const BulkAvailabilityScreen(),
      );
      expect(
        tester.widget<FilledButton>(find.byKey(const Key('bulk-apply'))).onPressed,
        isNull,
      );
      await tester.tap(find.byKey(const Key('bulk-row-p1')));
      await tester.tap(find.byKey(const Key('bulk-row-p2')));
      await tester.pump();
      expect(
        tester.widget<Text>(find.byKey(const Key('bulk-selected-count'))).data,
        AppStrings.catalogBulkSelected(2),
      );
      await tester.tap(find.byKey(const Key('bulk-status')));
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppStrings.catalogFiltersOutOfStock).last);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('bulk-apply')));
      await _settle(tester);
      expect(api.availabilityUpdates, ['p1:false', 'p2:false']);
      expect(find.text(AppStrings.catalogBulkDone(2)), findsOneWidget);
    });

    testWidgets('delete refused for historical use explains and offers hide',
        (tester) async {
      final api = _seededApi()
        ..deleteError = const ApiException(
          'in use',
          code: 'CATALOG_PRODUCT_IN_USE',
          statusCode: 409,
        );
      final container = await parityReady(api);
      addTearDown(container.dispose);
      await container.read(catalogControllerProvider.future);
      await parityPump(
        tester,
        container: container,
        variant: parityVariants.first,
        height: 1200,
        child: const ProductDeleteScreen(productId: 'p1'),
      );
      await tester.tap(find.byKey(const Key('delete-choice-delete')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('delete-confirm')));
      await _settle(tester);
      expect(api.deleteCalls, 1);
      expect(find.text(AppStrings.catalogProductInUse), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const Key('delete-confirm')),
          matching: find.text(AppStrings.catalogDeleteHideOption),
        ),
        findsOneWidget,
      );
    });

    testWidgets('variants: create group and priced choice via the API',
        (tester) async {
      final api = _CatalogApi();
      final container = await parityReady(api);
      addTearDown(container.dispose);
      await container.read(catalogControllerProvider.future);
      await parityPump(
        tester,
        container: container,
        variant: parityVariants.first,
        height: 1200,
        child: const OptionGroupsScreen(productId: 'p1', required: true),
      );
      await _settle(tester);
      await tester.tap(find.byKey(const Key('option-group-add')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('option-group-name')), 'Sauce');
      await tester.pump();
      await tester.tap(find.byKey(const Key('option-group-save')));
      await tester.pumpAndSettle();
      expect(api.optionCalls, contains('createGroup:Sauce:true:1:1'));
      expect(find.text('Sauce'), findsOneWidget);

      final groupId = api.optionGroups['p1']!.single.id;
      await tester.tap(find.byKey(Key('option-add-$groupId')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('option-name')), 'Harissa');
      await tester.enterText(find.byKey(const Key('option-price')), '7,50');
      await tester.pump();
      await tester.tap(find.byKey(const Key('option-save')));
      await tester.pumpAndSettle();
      expect(api.optionCalls, contains('createOption:$groupId:Harissa:750'));
      expect(find.text('Harissa'), findsOneWidget);
    });

    testWidgets('STAFF sees read-only catalogue without toggles or menus',
        (tester) async {
      final container = await parityReady(_seededApi(role: 'STAFF'));
      addTearDown(container.dispose);
      await container.read(catalogControllerProvider.future);
      await parityPump(
        tester,
        container: container,
        variant: parityVariants.first,
        height: 900,
        child: const CatalogScreen(),
      );
      expect(find.byType(Switch), findsNothing);
      expect(find.byKey(const Key('catalog-product-menu-p1')), findsNothing);
      expect(find.byKey(const Key('catalog-add-fab')), findsNothing);
      expect(find.byKey(const Key('catalog-bulk-open')), findsNothing);
      expect(find.text(AppStrings.catalogOutOfStock), findsOneWidget);
    });

    testWidgets('filters narrow the list to out-of-stock products',
        (tester) async {
      final container = await parityReady(_seededApi());
      addTearDown(container.dispose);
      await container.read(catalogControllerProvider.future);
      container.read(catalogControllerProvider.notifier).applyFilter((
        query: '',
        categoryId: null,
        stock: ProductStockFilter.outOfStock,
        missingImage: false,
      ));
      await parityPump(
        tester,
        container: container,
        variant: parityVariants.first,
        height: 900,
        child: const CatalogScreen(),
      );
      expect(find.byKey(const Key('catalog-product-p3')), findsOneWidget);
      expect(find.byKey(const Key('catalog-product-p1')), findsNothing);
    });

    testWidgets('product detail shows real groups and toggles availability',
        (tester) async {
      final api = _seededApi();
      final container = await parityReady(api);
      addTearDown(container.dispose);
      await container.read(catalogControllerProvider.future);
      await parityPump(
        tester,
        container: container,
        variant: parityVariants.first,
        height: 1600,
        child: const ProductDetailScreen(productId: 'p1'),
      );
      await _settle(tester);
      expect(find.byKey(const Key('product-detail-group-g1')), findsOneWidget);
      expect(find.byKey(const Key('product-detail-group-g2')), findsOneWidget);
      expect(
        find.text(AppStrings.catalogRequiredSummary(
          AppStrings.catalogSingleChoice,
        )),
        findsOneWidget,
      );
      expect(find.text(AppStrings.catalogOptionalSummary(3)), findsOneWidget);
      expect(find.byKey(const Key('product-detail-option-o2')), findsOneWidget);
      await tester.tap(
        find.descendant(
          of: find.byKey(const Key('product-detail-available')),
          matching: find.byType(Switch),
        ),
      );
      await _settle(tester);
      expect(api.availabilityUpdates, ['p1:false']);
    });

    testWidgets('STAFF product detail is read-only', (tester) async {
      final container = await parityReady(_seededApi(role: 'STAFF'));
      addTearDown(container.dispose);
      await container.read(catalogControllerProvider.future);
      await parityPump(
        tester,
        container: container,
        variant: parityVariants.first,
        height: 1600,
        child: const ProductDetailScreen(productId: 'p1'),
      );
      await _settle(tester);
      expect(find.byKey(const Key('product-detail-name')), findsOneWidget);
      expect(find.byKey(const Key('product-detail-edit')), findsNothing);
      expect(find.byKey(const Key('product-detail-available')), findsNothing);
    });

    test('crop rotates clockwise like the preview before cutting', () {
      final bytes = _sampleJpeg();
      final top = img.decodeJpg(
        cropMerchantImage((
          bytes: bytes,
          quarterTurns: 1,
          x: 0,
          y: 0,
          side: 400,
        )).bytes,
      )!;
      expect(top.width, 400);
      expect(top.height, 400);
      final p = top.getPixel(200, 200);
      expect(p.r, greaterThan(180));
      expect(p.b, lessThan(90));
      final bottom = img.decodeJpg(
        cropMerchantImage((
          bytes: bytes,
          quarterTurns: 1,
          x: 0,
          y: 500,
          side: 400,
        )).bytes,
      )!;
      final q = bottom.getPixel(200, 200);
      expect(q.b, greaterThan(180));
      expect(q.r, lessThan(90));
    });

    group('image crop screen', () {
      Future<List<MerchantCropRequest>> run(
        WidgetTester tester,
        Future<void> Function() interact, {
        void Function(ProductImageCropResult?)? onResult,
      }) async {
        final requests = <MerchantCropRequest>[];
        final container = await parityReady(_seededApi());
        addTearDown(container.dispose);
        final bytes = _sampleJpeg();
        await parityPump(
          tester,
          container: container,
          variant: parityVariants.first,
          height: 1000,
          child: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                key: const Key('open-crop'),
                onPressed: () async {
                  final r = await Navigator.of(context)
                      .push<ProductImageCropResult>(
                    MaterialPageRoute(
                      builder: (_) => ProductImageCropScreen(
                        bytes: bytes,
                        cropper: (req) async {
                          requests.add(req);
                          return cropMerchantImage(req);
                        },
                      ),
                    ),
                  );
                  onResult?.call(r);
                },
                child: const Text('open'),
              ),
            ),
          ),
        );
        await tester.tap(find.byKey(const Key('open-crop')));
        await tester.pumpAndSettle();
        await interact();
        return requests;
      }

      testWidgets('default crop is the framed square of the cover image',
          (tester) async {
        ProductImageCropResult? result;
        final requests = await run(tester, () async {
          await tester.tap(find.byKey(const Key('crop-use')));
          await tester.pumpAndSettle();
        }, onResult: (r) => result = r);
        expect(requests, hasLength(1));
        final r = requests.single;
        expect(r.quarterTurns, 0);
        // 900×700 source in a 390 pt square: 700 px span 390 pt.
        expect(r.side, closeTo(358 * 700 / 390, 0.5));
        expect(r.y, closeTo(16 * 700 / 390, 0.5));
        expect(r.x, closeTo(450 - r.side / 2, 0.5));
        final out = img.decodeJpg(result!.image!.bytes)!;
        expect(out.width, out.height);
        expect(out.width, greaterThanOrEqualTo(400));
      });

      testWidgets('rotate turns the crop a quarter clockwise', (tester) async {
        final requests = await run(tester, () async {
          await tester.tap(find.byKey(const Key('crop-rotate')));
          await tester.pump();
          await tester.tap(find.byKey(const Key('crop-use')));
          await tester.pumpAndSettle();
        });
        final r = requests.single;
        expect(r.quarterTurns, 1);
        expect(r.x, closeTo(16 * 700 / 390, 0.5));
        expect(r.y, closeTo(450 - r.side / 2, 0.5));
      });

      testWidgets('zoom never crops below the 400 px minimum',
          (tester) async {
        final requests = await run(tester, () async {
          await tester.tap(find.byKey(const Key('crop-zoom')));
          await tester.pump();
          await tester.tap(find.byKey(const Key('crop-use')));
          await tester.pumpAndSettle();
        });
        expect(requests.single.side, closeTo(400, 0.5));
      });

      testWidgets('delete asks the editor to remove the image',
          (tester) async {
        ProductImageCropResult? result;
        final requests = await run(tester, () async {
          await tester.tap(find.byKey(const Key('crop-remove')));
          await tester.pumpAndSettle();
        }, onResult: (r) => result = r);
        expect(requests, isEmpty);
        expect(result?.remove, isTrue);
        expect(result?.image, isNull);
      });
    });
  });
}

/// 900×700 JPEG: red left half, blue right half.
Uint8List _sampleJpeg() {
  final image = img.Image(width: 900, height: 700);
  img.fillRect(
    image,
    x1: 0,
    y1: 0,
    x2: 449,
    y2: 699,
    color: img.ColorRgb8(220, 40, 40),
  );
  img.fillRect(
    image,
    x1: 450,
    y1: 0,
    x2: 899,
    y2: 699,
    color: img.ColorRgb8(40, 60, 220),
  );
  return Uint8List.fromList(img.encodeJpg(image, quality: 90));
}
