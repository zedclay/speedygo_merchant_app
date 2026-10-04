import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:speedygo_merchant_app/app/theme/app_theme.dart';
import 'package:speedygo_merchant_app/core/constants/app_strings.dart';
import 'package:speedygo_merchant_app/core/money/money_format.dart';
import 'package:speedygo_merchant_app/core/navigation/app_routes.dart';
import 'package:speedygo_merchant_app/core/widgets/merchant_ui.dart';
import 'package:speedygo_merchant_app/features/access/application/access_controller.dart';
import 'package:speedygo_merchant_app/features/auth/application/auth_infrastructure.dart';
import 'package:speedygo_merchant_app/features/catalog/application/catalog_controller.dart';
import 'package:speedygo_merchant_app/features/catalog/data/catalog_models.dart';
import 'package:speedygo_merchant_app/features/catalog/presentation/catalog_screen.dart';
import 'package:speedygo_merchant_app/features/catalog/presentation/catalog_widgets.dart';
import 'package:speedygo_merchant_app/features/catalog/presentation/merchant_product_thumb.dart';

/// Read-only product sheet: identity, description, option groups, price and
/// the customer card preview. Editing happens in the product editor.
class ProductDetailScreen extends ConsumerStatefulWidget {
  const ProductDetailScreen({super.key, required this.productId});

  final String productId;

  @override
  ConsumerState<ProductDetailScreen> createState() =>
      _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  List<CatalogOptionGroup>? _groups;
  bool _groupsFailed = false;
  bool _toggling = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(_loadGroups);
  }

  Future<void> _loadGroups() async {
    final merchantId = ref
        .read(accessControllerProvider)
        .membership
        ?.merchantId;
    if (merchantId == null) return;
    setState(() => _groupsFailed = false);
    try {
      final groups = await ref
          .read(merchantApiProvider)
          .listOptionGroups(
            merchantId: merchantId,
            productId: widget.productId,
          );
      if (!mounted) return;
      setState(() => _groups = groups);
    } catch (_) {
      if (!mounted) return;
      setState(() => _groupsFailed = true);
    }
  }

  Future<void> _toggle(CatalogProduct product, bool value) async {
    setState(() => _toggling = true);
    try {
      await ref
          .read(catalogControllerProvider.notifier)
          .toggleAvailability(product.id, value);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(catalogErrorMessage(e))));
    } finally {
      if (mounted) setState(() => _toggling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canManage = catalogRoleCanManage(
      ref.watch(accessControllerProvider).membership?.role ?? '',
    );
    final async = ref.watch(catalogControllerProvider);
    return MerchantScaffold(
      title: AppStrings.catalogProductDetailTitle,
      titleStyle: theme.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
        color: AppColors.primary,
      ),
      headerColor: AppColors.surface,
      bodyPadding: EdgeInsets.zero,
      body: async.when(
        loading: () => const LoadingBody(),
        error: (_, _) => ErrorBody(
          message: AppStrings.catalogLoadError,
          onRetry: () => ref.read(catalogControllerProvider.notifier).reload(),
        ),
        data: (state) {
          CatalogProduct? product;
          for (final p in state.products) {
            if (p.id == widget.productId) product = p;
          }
          if (product == null) {
            return ErrorBody(
              message: AppStrings.catalogLoadError,
              onRetry: () =>
                  ref.read(catalogControllerProvider.notifier).reload(),
            );
          }
          final p = product;
          String? categoryName;
          for (final c in state.categories) {
            if (c.id == p.categoryId) categoryName = c.name;
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: ListView(
                  key: const Key('product-detail-scroll'),
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  children: [
                    _HeaderCard(product: p, categoryName: categoryName),
                    const SizedBox(height: 16),
                    _InfoCard(product: p),
                    const SizedBox(height: 16),
                    _PricingCard(product: p),
                    const SizedBox(height: 16),
                    _ConfigCard(
                      groups: _groups,
                      failed: _groupsFailed,
                      onRetry: _loadGroups,
                    ),
                    const SizedBox(height: 16),
                    _AppearanceCard(product: p),
                  ],
                ),
              ),
              if (canManage)
                MerchantStickyBar(
                  child: _Footer(
                    product: p,
                    busy: _toggling,
                    onToggle: (v) => _toggle(p, v),
                    onEdit: () =>
                        context.push(AppRoutes.catalogProductEdit(p.id)),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child, this.icon, this.title});

  final Widget child;
  final IconData? icon;
  final String? title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: merchantCardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null) ...[
            Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, color: AppColors.primary, size: 22),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    title!,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
          child,
        ],
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.product, this.categoryName});

  final CatalogProduct product;
  final String? categoryName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _Card(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MerchantProductThumb(product: product, size: 96),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  key: const Key('product-detail-name'),
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    CatalogStockPill(available: product.available),
                    if (categoryName != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          categoryName!,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: AppColors.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReadOnlyField extends StatelessWidget {
  const _ReadOnlyField({required this.label, required this.value, this.muted});

  final String label;
  final String value;
  final bool? muted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.outlineVariant),
          ),
          child: Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: muted == true
                  ? AppColors.onSurfaceVariant
                  : AppColors.onSurface,
            ),
          ),
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.product});

  final CatalogProduct product;

  @override
  Widget build(BuildContext context) {
    final description = product.description?.trim() ?? '';
    return _Card(
      icon: Icons.info_outline,
      title: AppStrings.catalogDetailInfo,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ReadOnlyField(
            label: AppStrings.catalogDetailName,
            value: product.name,
          ),
          const SizedBox(height: 16),
          _ReadOnlyField(
            label: AppStrings.catalogProductDescription,
            value: description.isEmpty
                ? AppStrings.catalogDetailNoDescription
                : description,
            muted: description.isEmpty,
          ),
        ],
      ),
    );
  }
}

class _PricingCard extends StatelessWidget {
  const _PricingCard({required this.product});

  final CatalogProduct product;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _Card(
      icon: Icons.storefront_outlined,
      title: AppStrings.catalogDetailPricing,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppStrings.catalogDetailPrice,
              style: theme.textTheme.labelMedium?.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              product.priceWithUnitLabel,
              key: const Key('product-detail-price'),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConfigCard extends StatelessWidget {
  const _ConfigCard({
    required this.groups,
    required this.failed,
    required this.onRetry,
  });

  final List<CatalogOptionGroup>? groups;
  final bool failed;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Widget content;
    if (failed) {
      content = Row(
        children: [
          Expanded(
            child: Text(
              AppStrings.catalogGroupsLoadError,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.error,
              ),
            ),
          ),
          TextButton(
            key: const Key('product-detail-groups-retry'),
            onPressed: onRetry,
            child: const Text(AppStrings.retry),
          ),
        ],
      );
    } else if (groups == null) {
      content = const Center(
        child: Padding(
          padding: EdgeInsets.all(8),
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    } else if (groups!.isEmpty) {
      content = Text(
        AppStrings.catalogDetailNoOptions,
        key: const Key('product-detail-no-groups'),
        style: theme.textTheme.bodyMedium?.copyWith(
          color: AppColors.onSurfaceVariant,
        ),
      );
    } else {
      final ordered = [
        ...groups!.where((g) => g.required),
        ...groups!.where((g) => !g.required),
      ];
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < ordered.length; i++) ...[
            if (i > 0) const SizedBox(height: 20),
            _GroupBlock(group: ordered[i]),
          ],
        ],
      );
    }
    return _Card(
      icon: Icons.tune,
      title: AppStrings.catalogSectionConfig,
      child: content,
    );
  }
}

class _GroupBlock extends StatelessWidget {
  const _GroupBlock({required this.group});

  final CatalogOptionGroup group;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final g = group;
    final rule = g.required
        ? AppStrings.catalogRequiredSummary(
            g.maxSelections <= 1
                ? AppStrings.catalogSingleChoice
                : AppStrings.catalogChoiceRange(
                    g.minSelections,
                    g.maxSelections,
                  ),
          )
        : AppStrings.catalogOptionalSummary(g.maxSelections);
    return Column(
      key: Key('product-detail-group-${g.id}'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.end,
          spacing: 8,
          runSpacing: 2,
          children: [
            Text(
              g.name,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              rule,
              style: theme.textTheme.labelMedium?.copyWith(
                color: g.required
                    ? AppColors.primary
                    : AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (g.options.isEmpty)
          Text(
            AppStrings.catalogOptionsEmpty,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
        for (final o in g.options) ...[
          Container(
            key: Key('product-detail-option-${o.id}'),
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.outlineVariant),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    o.name,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: o.available
                          ? AppColors.onSurface
                          : AppColors.onSurfaceVariant,
                      decoration: o.available
                          ? null
                          : TextDecoration.lineThrough,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '+${MoneyFormat.dzdOrEmpty(o.additionalPriceMinor)}',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _AppearanceCard extends StatelessWidget {
  const _AppearanceCard({required this.product});

  final CatalogProduct product;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final description = product.description?.trim() ?? '';
    return Container(
      key: const Key('product-detail-appearance'),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 36, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  AppStrings.catalogDetailAppearance,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 256),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.outlineVariant.withValues(
                            alpha: 0.3,
                          ),
                        ),
                        boxShadow: merchantCardShadow,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          MerchantProductThumb(
                            product: product,
                            size: 128,
                            width: double.infinity,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            product.name,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (description.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                          ],
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  MoneyFormat.dzdOrEmpty(product.priceMinor),
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.1,
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.add,
                                  size: 18,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.only(bottomLeft: Radius.circular(8)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.visibility_outlined,
                    size: 14,
                    color: AppColors.onPrimary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    AppStrings.catalogCustomerPreview,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: AppColors.onPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({
    required this.product,
    required this.busy,
    required this.onToggle,
    required this.onEdit,
  });

  final CatalogProduct product;
  final bool busy;
  final ValueChanged<bool> onToggle;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final stacked = MediaQuery.textScalerOf(context).scale(1) >= 1.25;
    final toggle = Row(
      mainAxisSize: stacked ? MainAxisSize.max : MainAxisSize.min,
      children: [
        CatalogSwitch(
          key: const Key('product-detail-available'),
          value: product.available,
          onChanged: busy ? null : onToggle,
          semanticLabel: AppStrings.catalogDetailAvailable,
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            AppStrings.catalogDetailAvailable,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
    final edit = FilledButton.icon(
      key: const Key('product-detail-edit'),
      onPressed: onEdit,
      icon: const Icon(Icons.edit, size: 20),
      label: const Text(
        AppStrings.catalogEditProduct,
        maxLines: 2,
        textAlign: TextAlign.center,
      ),
    );
    if (stacked) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [toggle, const SizedBox(height: 12), edit],
      );
    }
    return Row(
      children: [
        Expanded(flex: 5, child: toggle),
        const SizedBox(width: 12),
        Expanded(flex: 6, child: edit),
      ],
    );
  }
}
