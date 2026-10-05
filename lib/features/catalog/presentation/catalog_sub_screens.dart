import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:speedygo_merchant_app/app/theme/app_theme.dart';
import 'package:speedygo_merchant_app/core/constants/app_strings.dart';
import 'package:speedygo_merchant_app/core/errors/app_exception.dart';
import 'package:speedygo_merchant_app/core/money/money_format.dart';
import 'package:speedygo_merchant_app/core/navigation/app_routes.dart';
import 'package:speedygo_merchant_app/core/widgets/merchant_ui.dart';
import 'package:speedygo_merchant_app/features/access/application/access_controller.dart';
import 'package:speedygo_merchant_app/features/catalog/application/catalog_controller.dart';
import 'package:speedygo_merchant_app/features/catalog/data/catalog_models.dart';
import 'package:speedygo_merchant_app/features/catalog/presentation/catalog_screen.dart';
import 'package:speedygo_merchant_app/features/catalog/presentation/catalog_widgets.dart';
import 'package:speedygo_merchant_app/features/catalog/presentation/merchant_product_thumb.dart';

TextStyle? _primaryTitle(BuildContext context) =>
    Theme.of(context).textTheme.titleLarge
        ?.copyWith(fontWeight: FontWeight.w700, color: AppColors.primary);

TextStyle? _darkTitle(BuildContext context) =>
    Theme.of(context).textTheme.titleLarge
        ?.copyWith(fontWeight: FontWeight.w700, color: AppColors.onSurface);

bool _canManage(WidgetRef ref) => catalogRoleCanManage(
  ref.watch(accessControllerProvider).membership?.role ?? '',
);

/// Resolves the catalogue state for a sub-screen, with loading and error.
Widget _withCatalog(
  WidgetRef ref,
  Widget Function(CatalogState state) builder,
) {
  return ref
      .watch(catalogControllerProvider)
      .when(
        skipLoadingOnReload: true,
        skipLoadingOnRefresh: true,
        loading: () => const LoadingBody(),
        error: (_, _) => ErrorBody(
          message: AppStrings.catalogLoadError,
          onRetry: () => ref.read(catalogControllerProvider.notifier).reload(),
        ),
        data: builder,
      );
}

CatalogProduct? _findProduct(CatalogState state, String id) {
  for (final p in state.products) {
    if (p.id == id) return p;
  }
  return null;
}

String? _categoryName(CatalogState state, String id) {
  for (final c in state.categories) {
    if (c.id == id) return c.name;
  }
  return null;
}

class _InfoNote extends StatelessWidget {
  const _InfoNote({required this.text, this.title});

  final String text;
  final String? title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border: const Border(
          left: BorderSide(color: AppColors.primary, width: 4),
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title != null) ...[
                  Text(
                    title!,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
                Text(
                  text,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Selectable radio card (availability state, delete choice).
class _RadioCard extends StatelessWidget {
  const _RadioCard({
    super.key,
    required this.selected,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.icon,
    this.iconColor = AppColors.primary,
    this.tag,
  });

  final bool selected;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final IconData? icon;
  final Color iconColor;
  final String? tag;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      selected: selected,
      inMutuallyExclusiveGroup: true,
      button: true,
      child: Material(
        color: selected ? AppColors.surfaceContainer : AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: selected ? AppColors.primary : AppColors.outlineVariant,
            width: selected ? 2 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  selected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: selected ? AppColors.primary : AppColors.outline,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          if (icon != null) Icon(icon, color: iconColor),
                          Text(
                            title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (tag != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.tertiaryContainer,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                tag!,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: AppColors.tertiaryFixed,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Recherche et filtres
// ---------------------------------------------------------------------------

class ProductFiltersScreen extends ConsumerStatefulWidget {
  const ProductFiltersScreen({super.key});

  @override
  ConsumerState<ProductFiltersScreen> createState() =>
      _ProductFiltersScreenState();
}

class _ProductFiltersScreenState extends ConsumerState<ProductFiltersScreen> {
  final _query = TextEditingController();
  String? _categoryId;
  ProductStockFilter _stock = ProductStockFilter.all;
  bool _missingImage = false;
  bool _seeded = false;

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  void _seed(CatalogState state) {
    if (_seeded) return;
    _seeded = true;
    _query.text = state.searchQuery;
    _categoryId = state.selectedCategoryId;
    _stock = state.stockFilter;
    _missingImage = state.missingImageOnly;
  }

  ProductFilter get _filter => (
    query: _query.text,
    categoryId: _categoryId,
    stock: _stock,
    missingImage: _missingImage,
  );

  void _reset() => setState(() {
    _query.clear();
    _categoryId = null;
    _stock = ProductStockFilter.all;
    _missingImage = false;
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return MerchantScaffold(
      title: AppStrings.catalogFiltersTitle,
      bodyPadding: EdgeInsets.zero,
      titleStyle: _darkTitle(context),
      headerColor: AppColors.surface,
      actions: [
        TextButton(
          key: const Key('filters-reset'),
          onPressed: _reset,
          child: Text(AppStrings.catalogFiltersReset),
        ),
      ],
      body: _withCatalog(ref, (state) {
        _seed(state);
        final results = filterProducts(state.products, _filter);
        Widget section(String title, List<Widget> chips) => Padding(
          padding: const EdgeInsets.only(top: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(spacing: 8, runSpacing: 8, children: chips),
            ],
          ),
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                children: [
                  CatalogSearchField(
                    key: const Key('filters-query'),
                    controller: _query,
                    hint: AppStrings.catalogSearchHint,
                    onChanged: (_) => setState(() {}),
                  ),
                  section(AppStrings.catalogFiltersCategories, [
                    for (final c in state.categories)
                      CatalogPillChip(
                        key: Key('filters-category-${c.id}'),
                        label: c.name,
                        selected: _categoryId == c.id,
                        selectedColor: AppColors.primary,
                        onTap: () => setState(
                          () => _categoryId = _categoryId == c.id ? null : c.id,
                        ),
                      ),
                  ]),
                  section(AppStrings.catalogFiltersStatus, [
                    CatalogPillChip(
                      key: const Key('filters-in-stock'),
                      label: AppStrings.catalogInStock,
                      icon: Icons.check_circle_outline,
                      selected: _stock == ProductStockFilter.inStock,
                      selectedColor: AppColors.tertiaryFixed,
                      selectedForeground: AppColors.onTertiaryFixed,
                      onTap: () => setState(
                        () => _stock = _stock == ProductStockFilter.inStock
                            ? ProductStockFilter.all
                            : ProductStockFilter.inStock,
                      ),
                    ),
                    CatalogPillChip(
                      key: const Key('filters-out-of-stock'),
                      label: AppStrings.catalogFiltersOutOfStock,
                      icon: Icons.highlight_off,
                      selected: _stock == ProductStockFilter.outOfStock,
                      selectedColor: AppColors.errorContainer,
                      selectedForeground: AppColors.onErrorContainer,
                      onTap: () => setState(
                        () => _stock = _stock == ProductStockFilter.outOfStock
                            ? ProductStockFilter.all
                            : ProductStockFilter.outOfStock,
                      ),
                    ),
                  ]),
                  section(AppStrings.catalogFiltersQuality, [
                    CatalogPillChip(
                      key: const Key('filters-missing-image'),
                      label: AppStrings.catalogFiltersMissingImage,
                      icon: Icons.hide_image_outlined,
                      selected: _missingImage,
                      selectedColor: AppColors.primary,
                      onTap: () =>
                          setState(() => _missingImage = !_missingImage),
                    ),
                  ]),
                  const SizedBox(height: 24),
                  const Divider(height: 1),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          AppStrings.catalogFiltersPreview,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Text(
                        AppStrings.catalogProductsCount('${results.length}'),
                        key: const Key('filters-count'),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  for (final p in results.take(3)) ...[
                    _PreviewRow(product: p),
                    const SizedBox(height: 8),
                  ],
                ],
              ),
            ),
            MerchantStickyBar(
              child: SizedBox(
                height: 52,
                child: FilledButton(
                  key: const Key('filters-apply'),
                  onPressed: () {
                    ref
                        .read(catalogControllerProvider.notifier)
                        .applyFilter(_filter);
                    context.pop();
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(AppStrings.catalogFiltersApply),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.onPrimary.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text('${results.length}'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}

class _PreviewRow extends StatelessWidget {
  const _PreviewRow({required this.product});

  final CatalogProduct product;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return MerchantCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          MerchantProductThumb(product: product, size: 48),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  MoneyFormat.dzdOrEmpty(product.priceMinor),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          CatalogStockPill(available: product.available),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Réorganiser les catégories
// ---------------------------------------------------------------------------

class ReorderCategoriesScreen extends ConsumerStatefulWidget {
  const ReorderCategoriesScreen({super.key});

  @override
  ConsumerState<ReorderCategoriesScreen> createState() =>
      _ReorderCategoriesScreenState();
}

class _ReorderCategoriesScreenState
    extends ConsumerState<ReorderCategoriesScreen> {
  List<CatalogCategory>? _order;
  List<CatalogCategory> _initial = const [];
  bool _saving = false;
  String? _error;

  bool get _dirty {
    final order = _order;
    if (order == null) return false;
    for (var i = 0; i < order.length; i++) {
      if (order[i].id != _initial[i].id) return true;
    }
    return false;
  }

  Future<void> _save() async {
    final order = _order;
    if (order == null) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final failed = await ref
        .read(catalogControllerProvider.notifier)
        .reorderCategories([for (final c in order) c.id]);
    if (!mounted) return;
    if (failed.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.catalogReorderSaved)),
      );
      context.pop();
      return;
    }
    setState(() {
      _saving = false;
      _error = AppStrings.catalogReorderPartial;
      _order = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canManage = _canManage(ref);
    return MerchantScaffold(
      title: AppStrings.catalogReorderTitle,
      bodyPadding: EdgeInsets.zero,
      titleStyle: _darkTitle(context),
      headerColor: AppColors.surface,
      body: _withCatalog(ref, (state) {
        if (_order == null) {
          _initial = List.of(state.categories);
          _order = List.of(state.categories);
        }
        final order = _order!;
        if (!canManage) {
          return Center(child: Text(AppStrings.catalogStaffReadOnly));
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              color: AppColors.surfaceContainerLow,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.catalogCategoriesCount(order.length),
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    AppStrings.catalogReorderHint,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: CatalogErrorBanner(message: _error!),
              ),
            Expanded(
              child: ReorderableListView.builder(
                key: const Key('reorder-list'),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                buildDefaultDragHandles: false,
                itemCount: order.length,
                onReorderItem: (from, to) => setState(() {
                  final item = order.removeAt(from);
                  order.insert(to, item);
                }),
                itemBuilder: (context, i) {
                  final c = order[i];
                  return Padding(
                    key: ValueKey(c.id),
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _ReorderRow(index: i, category: c),
                  );
                },
              ),
            ),
            MerchantDualStickyBar(
              secondary: OutlinedButton(
                key: const Key('reorder-reset'),
                onPressed: _saving || !_dirty
                    ? null
                    : () => setState(() => _order = List.of(_initial)),
                child: Text(AppStrings.catalogFiltersReset, maxLines: 1),
              ),
              primary: FilledButton(
                key: const Key('reorder-save'),
                onPressed: _saving || !_dirty ? null : _save,
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.onPrimary,
                        ),
                      )
                    : Text(
                        AppStrings.catalogReorderSave,
                        maxLines: 2,
                        textAlign: TextAlign.center,
                      ),
              ),
            ),
          ],
        );
      }),
    );
  }
}

class _ReorderRow extends StatelessWidget {
  const _ReorderRow({required this.index, required this.category});

  final int index;
  final CatalogCategory category;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = !category.active;
    return Material(
      key: Key('reorder-row-${category.id}'),
      color: muted ? AppColors.surfaceContainerLow : AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: muted ? AppColors.surfaceVariant : AppColors.outlineVariant,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 8, 16),
        child: Row(
          children: [
            SizedBox(
              width: 32,
              child: Text(
                '${index + 1}',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: AppColors.outline,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: muted ? AppColors.outline : AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  CatalogVisibilityTag(visible: category.active),
                ],
              ),
            ),
            ReorderableDragStartListener(
              index: index,
              child: const Padding(
                padding: EdgeInsets.all(12),
                child: Icon(Icons.drag_handle, color: AppColors.outline),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Disponibilité groupée
// ---------------------------------------------------------------------------

class BulkAvailabilityScreen extends ConsumerStatefulWidget {
  const BulkAvailabilityScreen({super.key});

  @override
  ConsumerState<BulkAvailabilityScreen> createState() =>
      _BulkAvailabilityScreenState();
}

class _BulkAvailabilityScreenState
    extends ConsumerState<BulkAvailabilityScreen> {
  final Set<String> _selected = {};
  bool _available = true;
  bool _saving = false;

  Future<void> _apply() async {
    setState(() => _saving = true);
    final ids = List.of(_selected);
    final failed = await ref
        .read(catalogControllerProvider.notifier)
        .setAvailabilityBulk(ids, _available);
    if (!mounted) return;
    final done = ids.length - failed.length;
    setState(() {
      _saving = false;
      _selected
        ..clear()
        ..addAll(failed);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          failed.isEmpty
              ? AppStrings.catalogBulkDone(done.toString())
              : '${AppStrings.catalogBulkDone(done.toString())} '
                    '${AppStrings.catalogBulkFailed('${failed.length}')}',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canManage = _canManage(ref);
    return MerchantScaffold(
      title: AppStrings.catalogBulkTitle,
      bodyPadding: EdgeInsets.zero,
      centerTitle: true,
      titleStyle: _primaryTitle(context),
      headerColor: AppColors.surface,
      leading: IconButton(
        key: const Key('bulk-close'),
        tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
        color: AppColors.primary,
        icon: const Icon(Icons.close),
        onPressed: () => context.pop(),
      ),
      body: _withCatalog(ref, (state) {
        if (!canManage) {
          return Center(child: Text(AppStrings.catalogStaffReadOnly));
        }
        final groups = <(String, List<CatalogProduct>)>[
          for (final c in state.categories)
            (
              c.name,
              state.products.where((p) => p.categoryId == c.id).toList(),
            ),
        ].where((g) => g.$2.isNotEmpty).toList();
        final known = {for (final c in state.categories) c.id};
        final orphans = state.products
            .where((p) => !known.contains(p.categoryId))
            .toList();
        if (orphans.isNotEmpty) {
          groups.add((AppStrings.catalogUncategorized, orphans));
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                children: [
                  _InfoNote(text: AppStrings.catalogBulkNote),
                  const SizedBox(height: 16),
                  MerchantCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            Text(
                              AppStrings.catalogBulkSelection,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                AppStrings.catalogBulkSelected(
                                  _selected.length,
                                ),
                                key: const Key('bulk-selected-count'),
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: AppColors.onPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          AppStrings.catalogBulkNewStatus,
                          style: theme.textTheme.labelLarge,
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<bool>(
                          key: const Key('bulk-status'),
                          initialValue: _available,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: AppColors.surfaceContainerLow,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                color: AppColors.outlineVariant,
                              ),
                            ),
                          ),
                          items: [
                            DropdownMenuItem(
                              value: true,
                              child: Text(AppStrings.catalogAvailableOption),
                            ),
                            DropdownMenuItem(
                              value: false,
                              child: Text(AppStrings.catalogFiltersOutOfStock),
                            ),
                          ],
                          onChanged: (v) =>
                              setState(() => _available = v ?? true),
                        ),
                      ],
                    ),
                  ),
                  for (final (name, products) in groups) ...[
                    const SizedBox(height: 24),
                    _BulkGroupHeader(
                      name: name,
                      allSelected: products.every(
                        (p) => _selected.contains(p.id),
                      ),
                      onToggle: (all) => setState(() {
                        for (final p in products) {
                          all ? _selected.add(p.id) : _selected.remove(p.id);
                        }
                      }),
                    ),
                    const SizedBox(height: 8),
                    for (final p in products) ...[
                      _BulkRow(
                        product: p,
                        selected: _selected.contains(p.id),
                        onChanged: (v) => setState(
                          () =>
                              v ? _selected.add(p.id) : _selected.remove(p.id),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ],
                ],
              ),
            ),
            MerchantStickyBar(
              child: Row(
                children: [
                  CatalogSquareButton(
                    key: const Key('bulk-clear'),
                    icon: Icons.deselect,
                    tooltip: AppStrings.catalogBulkClear,
                    onPressed: () => setState(_selected.clear),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: FilledButton.icon(
                        key: const Key('bulk-apply'),
                        onPressed: _saving || _selected.isEmpty ? null : _apply,
                        icon: const Icon(Icons.published_with_changes),
                        label: Text(AppStrings.catalogBulkApply),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }
}

class _BulkGroupHeader extends StatelessWidget {
  const _BulkGroupHeader({
    required this.name,
    required this.allSelected,
    required this.onToggle,
  });

  final String name;
  final bool allSelected;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.only(bottom: 4),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.outlineVariant)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              name,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          InkWell(
            onTap: () => onToggle(!allSelected),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  AppStrings.catalogBulkSelectAll,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                Checkbox(
                  value: allSelected,
                  onChanged: (v) => onToggle(v ?? false),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BulkRow extends StatelessWidget {
  const _BulkRow({
    required this.product,
    required this.selected,
    required this.onChanged,
  });

  final CatalogProduct product;
  final bool selected;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final available = product.available;
    final stacked = MediaQuery.textScalerOf(context).scale(1) >= 1.25;
    final price = Text(
      MoneyFormat.dzdOrEmpty(product.priceMinor),
      style: theme.textTheme.titleSmall?.copyWith(
        color: AppColors.primary,
        fontWeight: FontWeight.w700,
      ),
    );
    return Material(
      key: Key('bulk-row-${product.id}'),
      color: selected ? AppColors.surfaceContainerLow : AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: selected ? AppColors.primary : AppColors.outlineVariant,
        ),
      ),
      child: InkWell(
        onTap: () => onChanged(!selected),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 8, 12, 8),
          child: Row(
            children: [
              Checkbox(
                key: Key('bulk-check-${product.id}'),
                value: selected,
                onChanged: (v) => onChanged(v ?? false),
              ),
              MerchantProductThumb(product: product, size: 48),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Row(
                      children: [
                        Icon(
                          Icons.circle,
                          size: 8,
                          color: available
                              ? AppColors.tertiaryContainer
                              : AppColors.error,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            available
                                ? AppStrings.catalogAvailableOption
                                : AppStrings.catalogFiltersOutOfStock,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: available
                                  ? AppColors.tertiary
                                  : AppColors.error,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (stacked) ...[const SizedBox(height: 2), price],
                  ],
                ),
              ),
              if (!stacked) ...[const SizedBox(width: 8), price],
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Détails de la catégorie
// ---------------------------------------------------------------------------

class CategoryDetailScreen extends ConsumerWidget {
  const CategoryDetailScreen({super.key, required this.categoryId});

  final String categoryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final canManage = _canManage(ref);
    final state = ref.watch(catalogControllerProvider).value;
    CatalogCategory? category;
    for (final c in state?.categories ?? const <CatalogCategory>[]) {
      if (c.id == categoryId) category = c;
    }
    return MerchantScaffold(
      title: AppStrings.catalogCategoryDetailTitle,
      centerTitle: true,
      titleStyle: _primaryTitle(context),
      headerColor: AppColors.surface,
      actions: [
        if (canManage && category != null)
          IconButton(
            key: const Key('category-detail-edit'),
            tooltip: AppStrings.catalogEditCategory,
            icon: const Icon(Icons.edit_outlined),
            onPressed: () =>
                context.push(AppRoutes.catalogCategoryEdit(categoryId)),
          ),
      ],
      floatingActionButton: canManage && category != null
          ? FloatingActionButton.extended(
              key: const Key('category-detail-add-product'),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              extendedPadding: const EdgeInsets.symmetric(horizontal: 24),
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.onPrimary,
              onPressed: () => context.push(AppRoutes.catalogProductNew),
              icon: const Icon(Icons.add),
              label: Text(AppStrings.catalogAddProduct),
            )
          : null,
      body: _withCatalog(ref, (state) {
        final c = category;
        if (c == null) {
          return ErrorBody(
            message: AppStrings.catalogLoadError,
            onRetry: () =>
                ref.read(catalogControllerProvider.notifier).reload(),
          );
        }
        final products = state.products
            .where((p) => p.categoryId == c.id)
            .toList();
        return ListView(
          key: const Key('category-detail'),
          padding: EdgeInsets.only(
            top: 24,
            bottom: 96 + MediaQuery.paddingOf(context).bottom,
          ),
          children: [
            Text(
              c.name,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            MerchantCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          AppStrings.catalogCategoryDetails,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Text(
                        c.active
                            ? AppStrings.catalogVisible
                            : AppStrings.catalogHidden,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: c.active
                              ? AppColors.tertiaryContainer
                              : AppColors.outline,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (canManage)
                        CatalogSwitch(
                          key: const Key('category-detail-visible'),
                          tone: CatalogSwitchTone.olive,
                          value: c.active,
                          semanticLabel: c.name,
                          onChanged: (v) async {
                            try {
                              await ref
                                  .read(catalogControllerProvider.notifier)
                                  .setCategoryVisibility(c.id, v);
                            } catch (_) {
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    AppStrings.catalogVisibilityError,
                                  ),
                                ),
                              );
                            }
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppStrings.catalogArticles(products.length),
                    key: const Key('category-detail-count'),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(
                        Icons.format_list_numbered,
                        size: 20,
                        color: AppColors.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        AppStrings.catalogDisplayOrder(c.sortOrder.toString()),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              AppStrings.catalogCategoryProducts,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            if (products.isEmpty)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  AppStrings.catalogCategoryEmpty,
                  textAlign: TextAlign.center,
                ),
              ),
            for (final p in products) ...[
              _CategoryProductRow(product: p, canManage: canManage),
              const SizedBox(height: 12),
            ],
          ],
        );
      }),
    );
  }
}

class _CategoryProductRow extends ConsumerWidget {
  const _CategoryProductRow({required this.product, required this.canManage});

  final CatalogProduct product;
  final bool canManage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final available = product.available;
    return Material(
      key: Key('category-product-${product.id}'),
      color: available ? AppColors.surface : AppColors.background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.surfaceVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: canManage
            ? () => context.push(AppRoutes.catalogProductEdit(product.id))
            : null,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: available
                            ? AppColors.onSurface
                            : AppColors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      MoneyFormat.dzdOrEmpty(product.priceMinor),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: available
                            ? AppColors.primary
                            : AppColors.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  CatalogStockPill(available: available),
                  if (canManage)
                    CatalogSwitch(
                      key: Key('category-product-available-${product.id}'),
                      tone: CatalogSwitchTone.olive,
                      value: available,
                      semanticLabel: product.name,
                      onChanged: (v) async {
                        try {
                          await ref
                              .read(catalogControllerProvider.notifier)
                              .toggleAvailability(product.id, v);
                        } catch (_) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                AppStrings.catalogAvailabilityError,
                              ),
                            ),
                          );
                        }
                      },
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Disponibilité du produit
// ---------------------------------------------------------------------------

class _ProductSummaryCard extends StatelessWidget {
  const _ProductSummaryCard({
    required this.product,
    this.overline,
    this.caption,
  });

  final CatalogProduct product;
  final String? overline;
  final String? caption;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceVariant),
      ),
      child: Row(
        children: [
          MerchantProductThumb(product: product, size: 72),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (overline != null)
                  Text(
                    overline!,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                Text(
                  product.name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (caption != null)
                  Text(
                    caption!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                const SizedBox(height: 4),
                Text(
                  MoneyFormat.dzdOrEmpty(product.priceMinor),
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ProductAvailabilityScreen extends ConsumerStatefulWidget {
  const ProductAvailabilityScreen({super.key, required this.productId});

  final String productId;

  @override
  ConsumerState<ProductAvailabilityScreen> createState() =>
      _ProductAvailabilityScreenState();
}

class _ProductAvailabilityScreenState
    extends ConsumerState<ProductAvailabilityScreen> {
  bool? _choice;
  bool _saving = false;
  String? _error;

  Future<void> _save(CatalogProduct product) async {
    final choice = _choice;
    if (choice == null || choice == product.available) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref
          .read(catalogControllerProvider.notifier)
          .toggleAvailability(product.id, choice);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.catalogAvailabilitySaved)),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = catalogErrorMessage(e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canManage = _canManage(ref);
    return MerchantScaffold(
      title: AppStrings.catalogAvailabilityTitle,
      bodyPadding: EdgeInsets.zero,
      centerTitle: true,
      titleStyle: _primaryTitle(context),
      headerColor: AppColors.surface,
      body: _withCatalog(ref, (state) {
        final product = _findProduct(state, widget.productId);
        if (product == null) {
          return ErrorBody(
            message: AppStrings.catalogLoadError,
            onRetry: () =>
                ref.read(catalogControllerProvider.notifier).reload(),
          );
        }
        final choice = _choice ?? product.available;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                children: [
                  _ProductSummaryCard(
                    product: product,
                    caption: _categoryName(state, product.categoryId),
                  ),
                  const SizedBox(height: 24),
                  _InfoNote(text: AppStrings.catalogAvailabilityNote),
                  const SizedBox(height: 24),
                  Text(
                    AppStrings.catalogAvailabilityState,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _RadioCard(
                    key: const Key('availability-available'),
                    selected: choice,
                    title: AppStrings.catalogAvailableOption,
                    subtitle: AppStrings.catalogAvailableOptionSub,
                    onTap: canManage
                        ? () => setState(() => _choice = true)
                        : null,
                  ),
                  const SizedBox(height: 12),
                  _RadioCard(
                    key: const Key('availability-out-of-stock'),
                    selected: !choice,
                    title: AppStrings.catalogFiltersOutOfStock,
                    subtitle: AppStrings.catalogOutOfStockOptionSub,
                    onTap: canManage
                        ? () => setState(() => _choice = false)
                        : null,
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    CatalogErrorBanner(message: _error!),
                  ],
                  if (!canManage) ...[
                    const SizedBox(height: 16),
                    Text(AppStrings.catalogStaffReadOnly),
                  ],
                ],
              ),
            ),
            if (canManage)
              MerchantStickyBar(
                child: SizedBox(
                  height: 52,
                  child: FilledButton.icon(
                    key: const Key('availability-save'),
                    style: FilledButton.styleFrom(shape: const StadiumBorder()),
                    onPressed: _saving || choice == product.available
                        ? null
                        : () => _save(product),
                    icon: const Icon(Icons.save_outlined),
                    label: Text(AppStrings.catalogAvailabilitySave),
                  ),
                ),
              ),
          ],
        );
      }),
    );
  }
}

// ---------------------------------------------------------------------------
// Supprimer le produit
// ---------------------------------------------------------------------------

class ProductDeleteScreen extends ConsumerStatefulWidget {
  const ProductDeleteScreen({super.key, required this.productId});

  final String productId;

  @override
  ConsumerState<ProductDeleteScreen> createState() =>
      _ProductDeleteScreenState();
}

enum _DeleteChoice { hide, delete }

class _ProductDeleteScreenState extends ConsumerState<ProductDeleteScreen> {
  _DeleteChoice? _choice;
  bool _saving = false;
  String? _error;

  Future<void> _confirm(CatalogProduct product, _DeleteChoice choice) async {
    setState(() {
      _saving = true;
      _error = null;
    });
    final controller = ref.read(catalogControllerProvider.notifier);
    try {
      if (choice == _DeleteChoice.hide) {
        await controller.toggleAvailability(product.id, false);
      } else {
        await controller.deleteProduct(product.id);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            choice == _DeleteChoice.hide
                ? AppStrings.catalogMarkedOutOfStock
                : AppStrings.catalogDeleted,
          ),
        ),
      );
      context.go(AppRoutes.catalog);
    } catch (e) {
      if (!mounted) return;
      final inUse = e is ApiException && e.code == 'CATALOG_PRODUCT_IN_USE';
      setState(() {
        _saving = false;
        _error = catalogErrorMessage(e);
        if (inUse && product.available) _choice = _DeleteChoice.hide;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final canManage = _canManage(ref);
    final branch = ref.watch(accessControllerProvider).selectedBranch?.name;
    return MerchantScaffold(
      title: AppStrings.catalogDeleteTitle,
      bodyPadding: EdgeInsets.zero,
      titleStyle: _darkTitle(context),
      headerColor: AppColors.surface,
      body: _withCatalog(ref, (state) {
        final product = _findProduct(state, widget.productId);
        if (product == null) {
          return ErrorBody(
            message: AppStrings.catalogLoadError,
            onRetry: () =>
                ref.read(catalogControllerProvider.notifier).reload(),
          );
        }
        if (!canManage) {
          return Center(child: Text(AppStrings.catalogStaffReadOnly));
        }
        final choice =
            _choice ??
            (product.available ? _DeleteChoice.hide : _DeleteChoice.delete);
        final isDelete = choice == _DeleteChoice.delete;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                children: [
                  _ProductSummaryCard(product: product, overline: branch),
                  const SizedBox(height: 24),
                  _InfoNote(
                    title: AppStrings.catalogDeleteWarningTitle,
                    text: AppStrings.catalogDeleteWarningBody,
                  ),
                  const SizedBox(height: 24),
                  if (product.available) ...[
                    _RadioCard(
                      key: const Key('delete-choice-hide'),
                      selected: !isDelete,
                      icon: Icons.inventory_2_outlined,
                      title: AppStrings.catalogDeleteHideOption,
                      subtitle: AppStrings.catalogDeleteHideOptionSub,
                      tag: AppStrings.catalogDeleteRecommended,
                      onTap: () => setState(() => _choice = _DeleteChoice.hide),
                    ),
                    const SizedBox(height: 12),
                  ],
                  _RadioCard(
                    key: const Key('delete-choice-delete'),
                    selected: isDelete,
                    icon: Icons.delete_forever_outlined,
                    iconColor: AppColors.error,
                    title: AppStrings.catalogDeleteHardOption,
                    subtitle: AppStrings.catalogDeleteHardOptionSub,
                    onTap: () => setState(() => _choice = _DeleteChoice.delete),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    CatalogErrorBanner(
                      key: const Key('delete-error'),
                      message: _error!,
                    ),
                  ],
                ],
              ),
            ),
            MerchantStickyBar(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    height: 52,
                    child: FilledButton(
                      key: const Key('delete-confirm'),
                      style: FilledButton.styleFrom(
                        shape: const StadiumBorder(),
                        backgroundColor: isDelete
                            ? AppColors.error
                            : AppColors.primary,
                      ),
                      onPressed: _saving
                          ? null
                          : () => _confirm(product, choice),
                      child: Text(
                        isDelete
                            ? AppStrings.catalogDeleteHardConfirm
                            : AppStrings.catalogDeleteHideOption,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 52,
                    child: OutlinedButton(
                      key: const Key('delete-cancel'),
                      style: OutlinedButton.styleFrom(
                        shape: const StadiumBorder(),
                      ),
                      onPressed: _saving ? null : () => context.pop(),
                      child: Text(AppStrings.cancel),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }
}
