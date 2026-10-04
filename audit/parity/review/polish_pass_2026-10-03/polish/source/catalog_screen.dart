import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:speedygo_merchant_app/app/theme/app_theme.dart';
import 'package:speedygo_merchant_app/core/constants/app_strings.dart';
import 'package:speedygo_merchant_app/core/money/money_format.dart';
import 'package:speedygo_merchant_app/core/navigation/app_routes.dart';
import 'package:speedygo_merchant_app/core/widgets/merchant_ui.dart';
import 'package:speedygo_merchant_app/features/access/application/access_controller.dart';
import 'package:speedygo_merchant_app/features/catalog/application/catalog_controller.dart';
import 'package:speedygo_merchant_app/features/catalog/data/catalog_models.dart';
import 'package:speedygo_merchant_app/features/catalog/presentation/catalog_widgets.dart';
import 'package:speedygo_merchant_app/features/catalog/presentation/merchant_product_thumb.dart';
import 'package:speedygo_merchant_app/features/store/application/store_controllers.dart';

bool catalogRoleCanManage(String role) {
  final r = role.toUpperCase();
  return r == 'OWNER' || r == 'MANAGER';
}

/// Space kept between the last row and the add button when fully scrolled.
const double _catalogEndGap = 24;

/// Bottom padding that lets the last row scroll fully above an end-floating
/// button of [fabHeight] (0 without one) and the bottom safe area. The bottom
/// navigation belongs to the shell's Scaffold, so this body already ends
/// above it.
double catalogListEndPadding(BuildContext context, double fabHeight) {
  final safeBottom = MediaQuery.paddingOf(context).bottom;
  if (fabHeight <= 0) return _catalogEndGap + safeBottom;
  return fabHeight + kFloatingActionButtonMargin + safeBottom + _catalogEndGap;
}

class CatalogScreen extends ConsumerStatefulWidget {
  const CatalogScreen({super.key});

  static void _add(BuildContext context, WidgetRef ref) {
    final current = ref.read(catalogControllerProvider).value;
    if (current?.tab == CatalogTab.categories) {
      context.push(AppRoutes.catalogCategoryNew);
      return;
    }
    if (current == null || current.categories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.catalogNeedCategory)),
      );
      context.push(AppRoutes.catalogCategoryNew);
      return;
    }
    context.push(AppRoutes.catalogProductNew);
  }

  @override
  ConsumerState<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends ConsumerState<CatalogScreen> {
  /// Measured height of the add button; the M3 extended size until laid out.
  final _fabHeight = ValueNotifier<double>(56);

  @override
  void dispose() {
    _fabHeight.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final async = ref.watch(catalogControllerProvider);
    final canManage = catalogRoleCanManage(
      ref.watch(accessControllerProvider).membership?.role ?? '',
    );
    final unread = ref.watch(notificationsUnreadCountProvider).value ?? 0;
    final state = async.asData?.value;
    final onCategories = state?.tab == CatalogTab.categories;
    final listEmpty = state != null &&
        (onCategories ? state.categories.isEmpty : state.products.isEmpty);
    final showFab = canManage && state != null && !listEmpty;

    return MerchantScaffold(
      title: AppStrings.catalogTitle,
      centerTitle: true,
      headerColor: AppColors.surface,
      headerHeight: 56,
      titleStyle: theme.textTheme.titleLarge?.copyWith(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: AppColors.primary,
      ),
      actions: [
        if (canManage && state != null && onCategories &&
            state.categories.length > 1)
          TextButton(
            key: const Key('catalog-reorder'),
            onPressed: () => context.push(AppRoutes.catalogReorder),
            child: const Text(AppStrings.catalogReorder),
          ),
        if (canManage && state != null && !onCategories &&
            state.products.isNotEmpty)
          IconButton(
            key: const Key('catalog-bulk-open'),
            tooltip: AppStrings.catalogBulkTooltip,
            color: AppColors.primary,
            onPressed: () => context.push(AppRoutes.catalogBulkAvailability),
            icon: const Icon(Icons.checklist),
          ),
        MerchantBellButton(
          key: const Key('catalog-notifications'),
          unread: unread,
          onPressed: () => context.push(AppRoutes.notifications),
        ),
        const SizedBox(width: 4),
      ],
      floatingActionButton: showFab
          ? MerchantSizeReporter(
              onSize: (size) => _fabHeight.value = size.height,
              child: FloatingActionButton.extended(
                key: const Key('catalog-add-fab'),
                shape: const StadiumBorder(),
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
                onPressed: () => CatalogScreen._add(context, ref),
                icon: const Icon(Icons.add),
                label: Text(
                  onCategories
                      ? AppStrings.catalogAddCategory
                      : AppStrings.catalogAddProduct,
                ),
              ),
            )
          : null,
      body: async.when(
        loading: () => const LoadingBody(),
        error: (_, _) => ErrorBody(
          message: AppStrings.catalogLoadError,
          onRetry: () => ref.read(catalogControllerProvider.notifier).reload(),
        ),
        data: (state) => _CatalogBody(
          state: state,
          canManage: canManage,
          fabHeight: _fabHeight,
          hasFab: showFab,
        ),
      ),
    );
  }
}

class _CatalogBody extends ConsumerStatefulWidget {
  const _CatalogBody({
    required this.state,
    required this.canManage,
    required this.fabHeight,
    required this.hasFab,
  });

  final CatalogState state;
  final bool canManage;
  final ValueListenable<double> fabHeight;
  final bool hasFab;

  @override
  ConsumerState<_CatalogBody> createState() => _CatalogBodyState();
}

class _CatalogBodyState extends ConsumerState<_CatalogBody> {
  late final TextEditingController _searchController;
  late final TextEditingController _categorySearch;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.state.searchQuery);
    _categorySearch = TextEditingController(text: widget.state.categoryQuery);
  }

  @override
  void didUpdateWidget(covariant _CatalogBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.state.searchQuery != _searchController.text &&
        widget.state.searchQuery != oldWidget.state.searchQuery) {
      _searchController.text = widget.state.searchQuery;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _categorySearch.dispose();
    super.dispose();
  }

  CatalogController get _controller =>
      ref.read(catalogControllerProvider.notifier);

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final isProducts = state.tab == CatalogTab.products;

    // Only the app bar stays pinned (as in the reference); tabs, search and
    // chips scroll with the list so large text keeps the list reachable. The
    // header is always the first sliver of the same scroll view, so typing a
    // search that empties the list never rebuilds the field.
    final header = Column(
      key: const Key('catalog-header'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 16),
        _SegmentedTab(
          productsSelected: isProducts,
          onProducts: () => _controller.setTab(CatalogTab.products),
          onCategories: () => _controller.setTab(CatalogTab.categories),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: isProducts
                  ? CatalogSearchField(
                      key: const Key('catalog-search'),
                      controller: _searchController,
                      hint: AppStrings.catalogSearchHint,
                      onChanged: _controller.setSearch,
                    )
                  : CatalogSearchField(
                      key: const Key('catalog-category-search'),
                      controller: _categorySearch,
                      hint: AppStrings.catalogCategorySearchHint,
                      onChanged: _controller.setCategorySearch,
                    ),
            ),
            if (isProducts) ...[
              const SizedBox(width: 8),
              CatalogSquareButton(
                key: const Key('catalog-filter-open'),
                icon: Icons.filter_list,
                tooltip: AppStrings.catalogFilterTooltip,
                badge: state.hasExtraFilters,
                onPressed: () => context.push(AppRoutes.catalogFilters),
              ),
            ],
          ],
        ),
        if (isProducts) ...[
          const SizedBox(height: 16),
          _CategoryChips(
            categories: state.categories,
            selectedId: state.selectedCategoryId,
            onSelected: _controller.setCategory,
          ),
        ],
        const SizedBox(height: 16),
      ],
    );
    return RefreshIndicator(
      key: const Key('catalog-screen'),
      onRefresh: _controller.reload,
      child: ValueListenableBuilder<double>(
        valueListenable: widget.fabHeight,
        builder: (context, fabHeight, _) {
          final endPadding = catalogListEndPadding(
            context,
            widget.hasFab ? fabHeight : 0,
          );
          return CustomScrollView(
            key: const Key('catalog-scroll'),
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(child: header),
              if (isProducts)
                ..._productSlivers(state, widget.canManage, endPadding)
              else
                ..._categorySlivers(
                  context,
                  state,
                  widget.canManage,
                  endPadding,
                ),
            ],
          );
        },
      ),
    );
  }
}

class _SegmentedTab extends StatelessWidget {
  const _SegmentedTab({
    required this.productsSelected,
    required this.onProducts,
    required this.onCategories,
  });

  final bool productsSelected;
  final VoidCallback onProducts;
  final VoidCallback onCategories;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: _SegmentButton(
              key: const Key('catalog-tab-products'),
              label: AppStrings.catalogTabProducts,
              selected: productsSelected,
              onTap: onProducts,
            ),
          ),
          Expanded(
            child: _SegmentButton(
              key: const Key('catalog-tab-categories'),
              label: AppStrings.catalogTabCategories,
              selected: !productsSelected,
              onTap: onCategories,
            ),
          ),
        ],
      ),
    );
  }
}

class _SegmentButton extends StatelessWidget {
  const _SegmentButton({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? AppColors.surface : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        elevation: selected ? 1 : 0,
        shadowColor: AppColors.onSurface.withValues(alpha: 0.08),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: selected
                        ? AppColors.onSurface
                        : AppColors.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryChips extends StatelessWidget {
  const _CategoryChips({
    required this.categories,
    required this.selectedId,
    required this.onSelected,
  });

  final List<CatalogCategory> categories;
  final String? selectedId;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    final allSelected = selectedId == null || selectedId!.isEmpty;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          CatalogPillChip(
            key: const Key('catalog-chip-all'),
            label: AppStrings.catalogAllCategories,
            selected: allSelected,
            onTap: () => onSelected(null),
          ),
          for (final c in categories) ...[
            const SizedBox(width: 8),
            CatalogPillChip(
              key: Key('catalog-chip-${c.id}'),
              label: c.name,
              selected: selectedId == c.id,
              onTap: () => onSelected(c.id),
            ),
          ],
        ],
      ),
    );
  }
}

List<Widget> _productSlivers(
  CatalogState state,
  bool canManage,
  double endPadding,
) {
  final products = state.visibleProducts;
  if (state.products.isEmpty) {
    return [
      SliverToBoxAdapter(
        child: Column(
          children: [
            const SizedBox(height: 64),
            const Center(
              child: Text(
                AppStrings.catalogEmptyProducts,
                key: Key('catalog-empty-products'),
                textAlign: TextAlign.center,
              ),
            ),
            if (canManage) ...[
              const SizedBox(height: 16),
              Center(
                child: Consumer(
                  builder: (context, ref, _) => FilledButton.icon(
                    key: const Key('catalog-empty-add-product'),
                    onPressed: () => CatalogScreen._add(context, ref),
                    icon: const Icon(Icons.add),
                    label: const Text(AppStrings.catalogAddProduct),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    ];
  }
  if (products.isEmpty) {
    return const [
      SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.only(top: 48),
          child: Center(
            child: Text(
              AppStrings.catalogNoResults,
              key: Key('catalog-no-results'),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    ];
  }
  return [
    SliverPadding(
      padding: EdgeInsets.only(bottom: endPadding),
      sliver: SliverList.separated(
        itemCount: products.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) =>
            CatalogProductCard(product: products[index], canManage: canManage),
      ),
    ),
  ];
}

/// Product row shared by the list and category detail.
class CatalogProductCard extends ConsumerWidget {
  const CatalogProductCard({
    super.key,
    required this.product,
    required this.canManage,
    this.showThumb = true,
    this.showMenu = true,
  });

  final CatalogProduct product;
  final bool canManage;
  final bool showThumb;
  final bool showMenu;

  Future<void> _toggle(BuildContext context, WidgetRef ref, bool value) async {
    try {
      await ref
          .read(catalogControllerProvider.notifier)
          .toggleAvailability(product.id, value);
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.catalogAvailabilityError)),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final price = MoneyFormat.dzdOrEmpty(product.priceMinor);
    final available = product.available;
    final stacked = MediaQuery.textScalerOf(context).scale(1) >= 1.25;
    final statusLabel = Text(
      available ? AppStrings.catalogInStock : AppStrings.catalogOutOfStock,
      style: theme.textTheme.labelMedium?.copyWith(
        color: available ? AppColors.tertiaryContainer : AppColors.outline,
        fontWeight: FontWeight.w600,
      ),
    );
    final control = canManage
        ? Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              statusLabel,
              CatalogSwitch(
                key: Key('catalog-product-available-${product.id}'),
                value: available,
                semanticLabel: product.name,
                onChanged: (v) => _toggle(context, ref, v),
              ),
            ],
          )
        : statusLabel;
    final menu = canManage && showMenu
        ? _ProductMenu(product: product)
        : const SizedBox.shrink();

    final info = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          product.name,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: available ? AppColors.onSurface : AppColors.onSurfaceVariant,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        if (price.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            price,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: available
                  ? AppColors.primary
                  : AppColors.primary.withValues(alpha: 0.6),
            ),
          ),
        ],
      ],
    );

    return Material(
      key: Key('catalog-product-${product.id}'),
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.surfaceVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push(AppRoutes.catalogProductDetails(product.id)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 4, 12),
          child: stacked
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (showThumb) ...[
                          MerchantProductThumb(product: product, size: 64),
                          const SizedBox(width: 12),
                        ],
                        Expanded(child: info),
                        menu,
                      ],
                    ),
                    const SizedBox(height: 8),
                    Align(alignment: Alignment.centerRight, child: control),
                  ],
                )
              : Row(
                  children: [
                    if (showThumb) ...[
                      MerchantProductThumb(product: product, size: 64),
                      const SizedBox(width: 16),
                    ],
                    Expanded(child: info),
                    const SizedBox(width: 8),
                    control,
                    menu,
                  ],
                ),
        ),
      ),
    );
  }
}

class _ProductMenu extends StatelessWidget {
  const _ProductMenu({required this.product});

  final CatalogProduct product;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    PopupMenuItem<String> item(
      String value,
      IconData icon,
      String label, {
      Color color = AppColors.onSurface,
      Color iconColor = AppColors.primary,
    }) =>
        PopupMenuItem<String>(
          key: Key('catalog-menu-$value'),
          value: value,
          child: Row(
            children: [
              Icon(icon, color: iconColor),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.bodyLarge?.copyWith(color: color),
                ),
              ),
            ],
          ),
        );
    return PopupMenuButton<String>(
      key: Key('catalog-product-menu-${product.id}'),
      icon: const Icon(Icons.more_vert, color: AppColors.onSurfaceVariant),
      color: AppColors.surface,
      elevation: 3,
      constraints: const BoxConstraints(minWidth: 220, maxWidth: 280),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.outlineVariant),
      ),
      onSelected: (value) {
        switch (value) {
          case 'edit':
            context.push(AppRoutes.catalogProductEdit(product.id));
          case 'availability':
            context.push(AppRoutes.catalogProductAvailability(product.id));
          case 'duplicate':
            context.push(AppRoutes.catalogProductDuplicate(product.id));
          case 'delete':
            context.push(AppRoutes.catalogProductDelete(product.id));
        }
      },
      itemBuilder: (_) => [
        item('edit', Icons.edit_outlined, AppStrings.catalogEditProduct),
        item(
          'availability',
          Icons.event_available_outlined,
          AppStrings.catalogMenuAvailability,
        ),
        item(
          'duplicate',
          Icons.content_copy_outlined,
          AppStrings.catalogMenuDuplicate,
        ),
        const PopupMenuDivider(),
        item(
          'delete',
          Icons.delete_outline,
          AppStrings.catalogMenuDelete,
          iconColor: AppColors.error,
        ),
      ],
    );
  }
}

List<Widget> _categorySlivers(
  BuildContext context,
  CatalogState state,
  bool canManage,
  double endPadding,
) {
  if (state.categories.isEmpty) {
    return [
      SliverToBoxAdapter(
        child: Column(
          children: [
            const SizedBox(height: 64),
            const Center(
              child: Text(
                AppStrings.catalogEmptyCategories,
                key: Key('catalog-empty-categories'),
                textAlign: TextAlign.center,
              ),
            ),
            if (canManage) ...[
              const SizedBox(height: 16),
              Center(
                child: FilledButton.icon(
                  key: const Key('catalog-empty-add-category'),
                  onPressed: () => context.push(AppRoutes.catalogCategoryNew),
                  icon: const Icon(Icons.add),
                  label: const Text(AppStrings.catalogAddCategory),
                ),
              ),
            ],
          ],
        ),
      ),
    ];
  }
  final categories = state.visibleCategories;
  if (categories.isEmpty) {
    return const [
      SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.only(top: 48),
          child: Center(
            child: Text(
              AppStrings.catalogNoCategoryResults,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    ];
  }
  return [
    SliverPadding(
      padding: EdgeInsets.only(bottom: endPadding),
      sliver: SliverList.separated(
        itemCount: categories.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final category = categories[index];
          return _CategoryCard(
            category: category,
            count: state.productCountFor(category.id),
            canManage: canManage,
          );
        },
      ),
    ),
  ];
}

class _CategoryCard extends ConsumerWidget {
  const _CategoryCard({
    required this.category,
    required this.count,
    required this.canManage,
  });

  final CatalogCategory category;
  final int count;
  final bool canManage;

  Future<void> _setVisible(
    BuildContext context,
    WidgetRef ref,
    bool value,
  ) async {
    try {
      await ref
          .read(catalogControllerProvider.notifier)
          .setCategoryVisibility(category.id, value);
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.catalogVisibilityError)),
      );
    }
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(AppStrings.catalogDeleteCategory),
        content: const Text(AppStrings.catalogDeleteCategoryConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(AppStrings.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(AppStrings.catalogDeleteCategory),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref
          .read(catalogControllerProvider.notifier)
          .deleteCategory(category.id);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(catalogErrorMessage(e))),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final visible = category.active;
    final muted = !visible;
    return Material(
      key: Key('catalog-category-${category.id}'),
      color: muted ? AppColors.surfaceContainerLow : AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: AppColors.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push(AppRoutes.catalogCategoryDetail(category.id)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 4, 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: muted
                            ? AppColors.onSurfaceVariant
                            : AppColors.onSurface,
                        decoration: muted ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.inventory_2_outlined,
                              size: 16,
                              color: AppColors.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              AppStrings.catalogArticles(count),
                              key: Key('catalog-category-count-${category.id}'),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                        if (muted) const CatalogVisibilityTag(visible: false),
                      ],
                    ),
                  ],
                ),
              ),
              if (canManage) ...[
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CatalogSwitch(
                      key: Key('catalog-category-visible-${category.id}'),
                      value: visible,
                      semanticLabel: category.name,
                      onChanged: (v) => _setVisible(context, ref, v),
                    ),
                    Text(
                      visible
                          ? AppStrings.catalogVisible
                          : AppStrings.catalogHidden,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: visible
                            ? AppColors.tertiaryContainer
                            : AppColors.outline,
                      ),
                    ),
                  ],
                ),
                PopupMenuButton<String>(
                  key: Key('catalog-category-menu-${category.id}'),
                  icon: const Icon(
                    Icons.more_vert,
                    color: AppColors.onSurfaceVariant,
                  ),
                  color: AppColors.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: AppColors.outlineVariant),
                  ),
                  onSelected: (value) {
                    switch (value) {
                      case 'view':
                        context.push(
                          AppRoutes.catalogCategoryDetail(category.id),
                        );
                      case 'edit':
                        context.push(AppRoutes.catalogCategoryEdit(category.id));
                      case 'delete':
                        _delete(context, ref);
                    }
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'view',
                      child: ListTile(
                        leading: Icon(
                          Icons.visibility_outlined,
                          color: AppColors.primary,
                        ),
                        title: Text(AppStrings.catalogMenuViewCategory),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'edit',
                      child: ListTile(
                        leading: Icon(
                          Icons.edit_outlined,
                          color: AppColors.primary,
                        ),
                        title: Text(AppStrings.catalogEditCategory),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const PopupMenuDivider(),
                    PopupMenuItem(
                      key: Key('catalog-category-delete-${category.id}'),
                      value: 'delete',
                      child: const ListTile(
                        leading: Icon(
                          Icons.delete_outline,
                          color: AppColors.error,
                        ),
                        title: Text(AppStrings.catalogDeleteCategory),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
              ] else
                const Padding(
                  padding: EdgeInsets.only(right: 12),
                  child: Icon(Icons.chevron_right, color: AppColors.outline),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
