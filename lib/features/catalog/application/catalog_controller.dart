import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speedygo_merchant_app/core/constants/app_strings.dart';
import 'package:speedygo_merchant_app/core/errors/app_exception.dart';
import 'package:speedygo_merchant_app/core/media/merchant_media_epoch.dart';
import 'package:speedygo_merchant_app/features/access/application/access_controller.dart';
import 'package:speedygo_merchant_app/features/auth/application/auth_infrastructure.dart';
import 'package:speedygo_merchant_app/features/auth/application/session_controller.dart';
import 'package:speedygo_merchant_app/features/catalog/data/catalog_models.dart';

/// Caps a hung interceptor / Keychain read so Catalogue cannot stay on
/// "Chargement…" after Dio's own timeouts would already have fired.
const kCatalogLoadTimeout = Duration(seconds: 25);

enum CatalogTab { products, categories }

/// Stock filter over the boolean `available` flag (no temporary states).
enum ProductStockFilter { all, inStock, outOfStock }

/// Product filter values shared by the list and the filters screen.
typedef ProductFilter = ({
  String query,
  String? categoryId,
  ProductStockFilter stock,
  bool missingImage,
});

List<CatalogProduct> filterProducts(
  List<CatalogProduct> products,
  ProductFilter f,
) {
  final q = f.query.trim().toLowerCase();
  return products.where((p) {
    if (f.categoryId != null &&
        f.categoryId!.isNotEmpty &&
        p.categoryId != f.categoryId) {
      return false;
    }
    if (f.stock == ProductStockFilter.inStock && !p.available) return false;
    if (f.stock == ProductStockFilter.outOfStock && p.available) return false;
    if (f.missingImage && p.hasImage) return false;
    if (q.isEmpty) return true;
    final name = p.name.toLowerCase();
    final desc = (p.description ?? '').toLowerCase();
    return name.contains(q) || desc.contains(q);
  }).toList();
}

class CatalogState {
  const CatalogState({
    required this.categories,
    required this.products,
    required this.selectedCategoryId,
    required this.searchQuery,
    required this.tab,
    this.stockFilter = ProductStockFilter.all,
    this.missingImageOnly = false,
    this.categoryQuery = '',
  });

  final List<CatalogCategory> categories;
  final List<CatalogProduct> products;
  final String? selectedCategoryId;
  final String searchQuery;
  final CatalogTab tab;
  final ProductStockFilter stockFilter;
  final bool missingImageOnly;
  final String categoryQuery;

  ProductFilter get filter => (
    query: searchQuery,
    categoryId: selectedCategoryId,
    stock: stockFilter,
    missingImage: missingImageOnly,
  );

  /// Filters beyond search and category chips are active.
  bool get hasExtraFilters =>
      stockFilter != ProductStockFilter.all || missingImageOnly;

  List<CatalogProduct> get visibleProducts => filterProducts(products, filter);

  List<CatalogCategory> get visibleCategories {
    final q = categoryQuery.trim().toLowerCase();
    if (q.isEmpty) return categories;
    return categories.where((c) => c.name.toLowerCase().contains(q)).toList();
  }

  /// Product count per category, from the fully paginated product list.
  int productCountFor(String categoryId) =>
      products.where((p) => p.categoryId == categoryId).length;

  CatalogState copyWith({
    List<CatalogCategory>? categories,
    List<CatalogProduct>? products,
    String? selectedCategoryId,
    bool clearCategory = false,
    String? searchQuery,
    CatalogTab? tab,
    ProductStockFilter? stockFilter,
    bool? missingImageOnly,
    String? categoryQuery,
  }) {
    return CatalogState(
      categories: categories ?? this.categories,
      products: products ?? this.products,
      selectedCategoryId: clearCategory
          ? null
          : (selectedCategoryId ?? this.selectedCategoryId),
      searchQuery: searchQuery ?? this.searchQuery,
      tab: tab ?? this.tab,
      stockFilter: stockFilter ?? this.stockFilter,
      missingImageOnly: missingImageOnly ?? this.missingImageOnly,
      categoryQuery: categoryQuery ?? this.categoryQuery,
    );
  }
}

class CatalogController extends AsyncNotifier<CatalogState> {
  int _generation = 0;

  @override
  Future<CatalogState> build() async {
    final merchantId = ref.watch(
      accessControllerProvider.select((s) => s.membership?.merchantId),
    );
    final branchId = ref.watch(
      accessControllerProvider.select((s) => s.selectedBranch?.id),
    );
    _generation += 1;
    return _load(
      merchantId: merchantId,
      branchId: branchId,
      selectedCategoryId: null,
      searchQuery: '',
      tab: CatalogTab.products,
    );
  }

  Future<void> setCategory(String? categoryId) async {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(
      current.copyWith(
        selectedCategoryId: categoryId,
        clearCategory: categoryId == null || categoryId.isEmpty,
      ),
    );
  }

  Future<void> setSearch(String query) async {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(current.copyWith(searchQuery: query));
  }

  void applyFilter(ProductFilter f) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(
      current.copyWith(
        searchQuery: f.query,
        selectedCategoryId: f.categoryId,
        clearCategory: f.categoryId == null || f.categoryId!.isEmpty,
        stockFilter: f.stock,
        missingImageOnly: f.missingImage,
      ),
    );
  }

  void setCategorySearch(String query) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(current.copyWith(categoryQuery: query));
  }

  /// Optimistic category visibility (`active`) toggle.
  Future<void> setCategoryVisibility(String categoryId, bool active) async {
    final current = state.value;
    final membership = ref.read(accessControllerProvider).membership;
    if (current == null || membership == null) return;
    final previous = current.categories;
    state = AsyncData(
      current.copyWith(
        categories: [
          for (final c in previous)
            c.id == categoryId ? c.copyWith(active: active) : c,
        ],
      ),
    );
    try {
      final updated = await ref
          .read(merchantApiProvider)
          .updateCategory(
            merchantId: membership.merchantId,
            categoryId: categoryId,
            active: active,
          );
      final latest = state.value ?? current;
      state = AsyncData(
        latest.copyWith(
          categories: [
            for (final c in latest.categories) c.id == categoryId ? updated : c,
          ],
        ),
      );
    } catch (_) {
      final latest = state.value ?? current;
      state = AsyncData(latest.copyWith(categories: previous));
      rethrow;
    }
  }

  /// Saves a new display order with one `PATCH sortOrder` per moved category
  /// (there is no batch endpoint). Returns the ids that failed to save.
  Future<List<String>> reorderCategories(List<String> orderedIds) async {
    final current = state.value;
    final membership = ref.read(accessControllerProvider).membership;
    if (current == null || membership == null) return orderedIds;
    final byId = {for (final c in current.categories) c.id: c};
    final failed = <String>[];
    for (var i = 0; i < orderedIds.length; i++) {
      final category = byId[orderedIds[i]];
      final order = i + 1;
      if (category == null || category.sortOrder == order) continue;
      try {
        await ref
            .read(merchantApiProvider)
            .updateCategory(
              merchantId: membership.merchantId,
              categoryId: category.id,
              sortOrder: order,
            );
      } catch (_) {
        failed.add(category.id);
      }
    }
    await reload();
    return failed;
  }

  /// Sets `available` on each product in turn. Returns the ids that failed.
  Future<List<String>> setAvailabilityBulk(
    Iterable<String> productIds,
    bool available,
  ) async {
    final failed = <String>[];
    for (final id in productIds) {
      try {
        await toggleAvailability(id, available);
      } catch (_) {
        failed.add(id);
      }
    }
    return failed;
  }

  Future<void> setTab(CatalogTab tab) async {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(current.copyWith(tab: tab));
  }

  Future<void> reload() async {
    final current = state.value;
    ref.read(merchantMediaEpochProvider.notifier).bump();
    final token = ++_generation;
    final access = ref.read(accessControllerProvider);
    final result = await AsyncValue.guard(() async {
      final next = await _load(
        merchantId: access.membership?.merchantId,
        branchId: access.selectedBranch?.id,
        selectedCategoryId: current?.selectedCategoryId,
        searchQuery: current?.searchQuery ?? '',
        tab: current?.tab ?? CatalogTab.products,
      );
      return next.copyWith(
        stockFilter: current?.stockFilter,
        missingImageOnly: current?.missingImageOnly,
        categoryQuery: current?.categoryQuery,
      );
    });
    if (token != _generation) return;
    state = result;
  }

  Future<void> toggleAvailability(String productId, bool available) async {
    final current = state.value;
    if (current == null) return;
    final access = ref.read(accessControllerProvider);
    final membership = access.membership;
    if (membership == null) return;

    final previous = current.products;
    final optimistic = previous
        .map((p) => p.id == productId ? p.copyWith(available: available) : p)
        .toList();
    state = AsyncData(current.copyWith(products: optimistic));

    try {
      final updated = await ref
          .read(merchantApiProvider)
          .updateProductAvailability(
            merchantId: membership.merchantId,
            productId: productId,
            available: available,
          );
      final latest = state.value ?? current;
      state = AsyncData(
        latest.copyWith(
          products: latest.products
              .map((p) => p.id == productId ? updated : p)
              .toList(),
        ),
      );
    } catch (e) {
      final latest = state.value ?? current;
      state = AsyncData(latest.copyWith(products: previous));
      rethrow;
    }
  }

  Future<CatalogProduct> createProduct({
    required String categoryId,
    required String name,
    String? description,
    required int priceMinor,
    required bool available,
    SellingUnitSelection? sellingUnit,
  }) async {
    final access = ref.read(accessControllerProvider);
    final membership = access.membership;
    final branch = access.selectedBranch;
    if (membership == null || branch == null) {
      throw StateError('missing branch');
    }
    final created = await ref
        .read(merchantApiProvider)
        .createProduct(
          merchantId: membership.merchantId,
          branchId: branch.id,
          categoryId: categoryId,
          name: name,
          description: description,
          priceMinor: priceMinor,
          available: available,
          sellingUnit: sellingUnit,
        );
    await reload();
    return created;
  }

  Future<CatalogProduct> updateProduct({
    required String productId,
    String? categoryId,
    String? name,
    String? description,
    int? priceMinor,
    bool? available,
    SellingUnitSelection? sellingUnit,
  }) async {
    final access = ref.read(accessControllerProvider);
    final membership = access.membership;
    if (membership == null) throw StateError('missing membership');
    final updated = await ref
        .read(merchantApiProvider)
        .updateProduct(
          merchantId: membership.merchantId,
          productId: productId,
          categoryId: categoryId,
          name: name,
          description: description,
          priceMinor: priceMinor,
          available: available,
          sellingUnit: sellingUnit,
        );
    await reload();
    return updated;
  }

  Future<void> deleteProduct(String productId) async {
    final access = ref.read(accessControllerProvider);
    final membership = access.membership;
    if (membership == null) return;
    await ref
        .read(merchantApiProvider)
        .deleteProduct(merchantId: membership.merchantId, productId: productId);
    await reload();
  }

  Future<CatalogCategory> createCategory({
    required String name,
    bool active = true,
  }) async {
    final access = ref.read(accessControllerProvider);
    final membership = access.membership;
    final branch = access.selectedBranch;
    if (membership == null || branch == null) {
      throw StateError('missing branch');
    }
    final created = await ref
        .read(merchantApiProvider)
        .createCategory(
          merchantId: membership.merchantId,
          branchId: branch.id,
          name: name,
          active: active,
        );
    await reload();
    return created;
  }

  Future<CatalogCategory> updateCategory({
    required String categoryId,
    String? name,
    bool? active,
  }) async {
    final access = ref.read(accessControllerProvider);
    final membership = access.membership;
    if (membership == null) throw StateError('missing membership');
    final updated = await ref
        .read(merchantApiProvider)
        .updateCategory(
          merchantId: membership.merchantId,
          categoryId: categoryId,
          name: name,
          active: active,
        );
    await reload();
    return updated;
  }

  Future<void> deleteCategory(String categoryId) async {
    final access = ref.read(accessControllerProvider);
    final membership = access.membership;
    if (membership == null) return;
    await ref
        .read(merchantApiProvider)
        .deleteCategory(
          merchantId: membership.merchantId,
          categoryId: categoryId,
        );
    await reload();
  }

  Future<CatalogState> _load({
    required String? merchantId,
    required String? branchId,
    required String? selectedCategoryId,
    required String searchQuery,
    required CatalogTab tab,
  }) async {
    try {
      return await _fetch(
        merchantId: merchantId,
        branchId: branchId,
        selectedCategoryId: selectedCategoryId,
        searchQuery: searchQuery,
        tab: tab,
      ).timeout(kCatalogLoadTimeout);
    } on TimeoutException {
      throw const NetworkException(
        AppStrings.catalogLoadError,
        code: 'CATALOG_TIMEOUT',
      );
    } on ApiException catch (e) {
      if (e.isAuthFailure) {
        await ref
            .read(sessionControllerProvider.notifier)
            .invalidateLocalSession();
      }
      rethrow;
    }
  }

  Future<CatalogState> _fetch({
    required String? merchantId,
    required String? branchId,
    required String? selectedCategoryId,
    required String searchQuery,
    required CatalogTab tab,
  }) async {
    if (merchantId == null ||
        merchantId.isEmpty ||
        branchId == null ||
        branchId.isEmpty) {
      throw const NetworkException(
        AppStrings.catalogLoadError,
        code: 'CATALOG_NO_BRANCH',
      );
    }

    final api = ref.read(merchantApiProvider);
    final bootstrap = await api.getCatalogBootstrap(
      merchantId: merchantId,
      branchId: branchId,
    );
    final products = await api.listProducts(
      merchantId: merchantId,
      branchId: branchId,
    );
    return CatalogState(
      categories: bootstrap.categories,
      products: products,
      selectedCategoryId: selectedCategoryId,
      searchQuery: searchQuery,
      tab: tab,
    );
  }
}

/// Catalogue failures stay on the explicit "Réessayer" path. Riverpod's
/// default retry would flip the tab back to "Chargement…" forever.
Duration? _noAutomaticRetry(int _, Object _) => null;

final catalogControllerProvider =
    AsyncNotifierProvider<CatalogController, CatalogState>(
      CatalogController.new,
      retry: _noAutomaticRetry,
    );
