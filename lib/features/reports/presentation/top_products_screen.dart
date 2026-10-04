import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:speedygo_merchant_app/app/theme/app_theme.dart';
import 'package:speedygo_merchant_app/core/constants/app_strings.dart';
import 'package:speedygo_merchant_app/core/money/money_format.dart';
import 'package:speedygo_merchant_app/core/navigation/app_routes.dart';
import 'package:speedygo_merchant_app/core/widgets/merchant_ui.dart';
import 'package:speedygo_merchant_app/features/access/application/access_controller.dart';
import 'package:speedygo_merchant_app/features/catalog/presentation/catalog_screen.dart';
import 'package:speedygo_merchant_app/features/reports/application/sales_report_controller.dart';
import 'package:speedygo_merchant_app/features/reports/data/reports_models.dart';
import 'package:speedygo_merchant_app/features/reports/presentation/report_widgets.dart';

/// Full ranking of products sold (historical order items of COMPLETED orders).
class TopProductsScreen extends ConsumerWidget {
  const TopProductsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final branchName = ref.watch(
      accessControllerProvider.select((a) => a.selectedBranch?.name),
    );
    final async = ref.watch(topProductsControllerProvider);
    final sort = ref.watch(topProductsSortProvider);
    final theme = Theme.of(context);
    Future<void> reload() =>
        ref.read(topProductsControllerProvider.notifier).reload();

    return MerchantScaffold(
      title: AppStrings.reportsTopProductsScreenTitle,
      subtitle: branchName,
      headerColor: AppColors.surface,
      titleStyle: theme.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
        color: AppColors.onSurface,
      ),
      bodyPadding: EdgeInsets.zero,
      leading: IconButton(
        key: const Key('top-products-back'),
        tooltip: MaterialLocalizations.of(context).backButtonTooltip,
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go(AppRoutes.reports);
          }
        },
      ),
      actions: [
        IconButton(
          key: const Key('top-products-refresh'),
          tooltip: AppStrings.refresh,
          onPressed: reload,
          icon: const Icon(Icons.refresh),
        ),
      ],
      body: RefreshIndicator(
        onRefresh: reload,
        child: ListView(
          key: const Key('top-products-screen'),
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            ColoredBox(
              color: AppColors.surface,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const ReportPeriodChips(),
                    const SizedBox(height: 12),
                    _SortToggle(
                      sort: sort,
                      onChanged: (value) => ref
                          .read(topProductsSortProvider.notifier)
                          .select(value),
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 1),
            const SizedBox(height: 16),
            ...async
                .when(
                  loading: () => const [
                    ReportLoadingCard(key: Key('top-products-loading')),
                  ],
                  error: (_, _) => [
                    ReportErrorCard(
                      message: AppStrings.reportsTopProductsLoadError,
                      retryKey: const Key('top-products-retry'),
                      onRetry: reload,
                    ),
                  ],
                  data: (top) {
                    if (top == null) {
                      return const [
                        MerchantCard(
                          child: Text(AppStrings.reportsDataUnavailable),
                        ),
                      ];
                    }
                    return [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              AppStrings.reportsTopSales,
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                          ),
                          Text(
                            AppStrings.reportsTotalArticles(
                              top.distinctProductCount,
                            ),
                            key: const Key('top-products-total'),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (top.items.isEmpty)
                        MerchantCard(
                          key: const Key('top-products-empty'),
                          child: SizedBox(
                            width: double.infinity,
                            child: Text(
                              AppStrings.reportsTopProductsEmpty,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                          ),
                        )
                      else
                        for (final item in top.items)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _RankedProductCard(
                              item: item,
                              sort: top.sort,
                              editableId: topProductEditableId(
                                item,
                                canEdit: catalogRoleCanManage(
                                  ref
                                          .watch(accessControllerProvider)
                                          .membership
                                          ?.role ??
                                      '',
                                ),
                              ),
                            ),
                          ),
                      const SizedBox(height: 8),
                      Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.sync,
                              size: 16,
                              color: AppColors.onSurfaceVariant,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              AppStrings.reportsSyncedAt(reportClock(top.asOf)),
                              key: const Key('top-products-synced'),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ];
                  },
                )
                .map(
                  (w) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: w,
                  ),
                ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _SortToggle extends StatelessWidget {
  const _SortToggle({required this.sort, required this.onChanged});

  final TopProductSort sort;
  final ValueChanged<TopProductSort> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Widget segment(TopProductSort value, String label, Key labelKey) {
      final selected = sort == value;
      return Expanded(
        child: Semantics(
          button: true,
          selected: selected,
          child: Material(
            color: selected
                ? AppColors.surfaceContainerHighest
                : Colors.transparent,
            elevation: selected ? 1 : 0,
            shadowColor: Colors.black.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(6),
            child: InkWell(
              borderRadius: BorderRadius.circular(6),
              onTap: selected ? null : () => onChanged(value),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Text(
                  label,
                  key: labelKey,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: selected ? AppColors.primary : AppColors.outline,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      key: const Key('top-products-sort'),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          segment(
            TopProductSort.orders,
            AppStrings.reportsSortOrders,
            const Key('top-products-sort-orders'),
          ),
          segment(
            TopProductSort.revenue,
            AppStrings.reportsSortRevenue,
            const Key('top-products-sort-revenue'),
          ),
        ],
      ),
    );
  }
}

class _RankedProductCard extends StatelessWidget {
  const _RankedProductCard({
    required this.item,
    required this.sort,
    required this.editableId,
  });

  final MerchantTopProduct item;
  final TopProductSort sort;
  final String? editableId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final byRevenue = sort == TopProductSort.revenue;
    final first = item.rank == 1;
    final ordersStyle = theme.textTheme.bodyMedium?.copyWith(
      color: byRevenue ? AppColors.onSurfaceVariant : AppColors.onSurface,
      fontWeight: byRevenue ? FontWeight.w400 : FontWeight.w600,
    );
    final revenue = MoneyFormat.dzdOrEmpty(item.revenueMinor);
    final revenueStyle = theme.textTheme.titleSmall?.copyWith(
      color: AppColors.primary,
      fontWeight: FontWeight.w700,
    );
    final counts =
        '${AppStrings.reportsOrderCount(item.orderCount)} • '
        '${AppStrings.reportsUnitCount(item.quantity)}';
    final name = Text(
      item.name,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: theme.textTheme.titleMedium?.copyWith(
        fontWeight: first ? FontWeight.w700 : FontWeight.w600,
      ),
    );
    final deleted = item.productId == null
        ? Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              AppStrings.reportsDeletedProduct,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),
          )
        : null;

    Widget iconLine(IconData icon, Color color, Widget text) => Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 6),
        Expanded(child: text),
      ],
    );

    final Widget content;
    if (first) {
      content = Padding(
        padding: const EdgeInsets.fromLTRB(12, 36, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            name,
            ?deleted,
            const SizedBox(height: 6),
            iconLine(
              Icons.shopping_bag_outlined,
              AppColors.primary,
              Text(counts, style: ordersStyle),
            ),
            const SizedBox(height: 4),
            iconLine(
              Icons.payments_outlined,
              AppColors.tertiary,
              Text(revenue, style: revenueStyle),
            ),
          ],
        ),
      );
    } else {
      content = Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 56,
              height: 56,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.surfaceContainer,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.outlineVariant),
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  '${item.rank}',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: AppColors.primaryContainer,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  name,
                  ?deleted,
                  const SizedBox(height: 4),
                  Text(counts, style: ordersStyle),
                  const SizedBox(height: 2),
                  Text(revenue, style: revenueStyle),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final body = editableId == null
        ? content
        : Row(
            children: [
              Expanded(child: content),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: TopProductChevron(
                  key: Key('top-product-chevron-${item.rank}'),
                ),
              ),
            ],
          );
    return Container(
      key: Key('top-product-${item.rank}'),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: TopProductLink(
        productId: editableId,
        label: item.name,
        child: first
            ? Stack(
                children: [
                  body,
                  Positioned(
                    top: 0,
                    left: 0,
                    child: Container(
                      key: const Key('top-product-ribbon'),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.only(
                          bottomRight: Radius.circular(8),
                        ),
                      ),
                      child: Text(
                        AppStrings.reportsRankFirst,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: AppColors.onPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              )
            : body,
      ),
    );
  }
}
