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
import 'package:speedygo_merchant_app/features/reports/application/reports_controller.dart';
import 'package:speedygo_merchant_app/features/reports/application/sales_report_controller.dart';
import 'package:speedygo_merchant_app/features/reports/data/reports_models.dart';
import 'package:speedygo_merchant_app/features/reports/presentation/report_widgets.dart';
import 'package:speedygo_merchant_app/features/store/application/store_controllers.dart';

Future<void> _reloadAll(WidgetRef ref) => Future.wait([
  ref.read(salesReportControllerProvider.notifier).reload(),
  ref.read(reportsControllerProvider.notifier).reload(),
]);

String _moneyOrDash(String? minor) {
  final label = MoneyFormat.dzdOrEmpty(minor);
  return label.isEmpty ? AppStrings.reportsDataUnavailableShort : label;
}

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(notificationsUnreadCountProvider).value ?? 0;
    return MerchantScaffold(
      title: AppStrings.reportsTitle,
      headerColor: AppColors.surface,
      headerHeight: 56,
      titleStyle: Theme.of(context).textTheme.titleLarge
          ?.copyWith(fontWeight: FontWeight.w700, color: AppColors.primary),
      leading: Padding(
        padding: const EdgeInsets.only(left: 16),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Container(
            key: const Key('reports-store-avatar'),
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: AppColors.surfaceVariant,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.storefront_outlined,
              size: 20,
              color: AppColors.primary,
            ),
          ),
        ),
      ),
      actions: [
        IconButton(
          key: const Key('reports-refresh'),
          tooltip: AppStrings.refresh,
          onPressed: () => _reloadAll(ref),
          icon: const Icon(Icons.refresh, color: AppColors.onSurfaceVariant),
        ),
        MerchantBellButton(
          key: const Key('reports-notifications'),
          unread: unread,
          onPressed: () => context.push(AppRoutes.notifications),
        ),
        const SizedBox(width: 4),
      ],
      body: const _ReportsBody(),
    );
  }
}

class _DailySummaryShortcut extends ConsumerWidget {
  const _DailySummaryShortcut();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final period = ref.watch(reportPeriodProvider);
    if (period.period != ReportPeriod.today) {
      return const SizedBox.shrink();
    }
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: MerchantCard(
        padding: EdgeInsets.zero,
        child: InkWell(
          key: const Key('reports-daily-summary-shortcut'),
          borderRadius: BorderRadius.circular(12),
          onTap: () => context.push(AppRoutes.reportsDailySummary),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                const Icon(
                  Icons.summarize_outlined,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    AppStrings.reportsDailySummaryShortcut,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  color: AppColors.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ReportsBody extends ConsumerWidget {
  const _ReportsBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sales = ref.watch(salesReportControllerProvider);
    final extras = ref.watch(reportsControllerProvider);
    return RefreshIndicator(
      onRefresh: () => _reloadAll(ref),
      child: ListView(
        key: const Key('reports-screen'),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 8),
          const ReportPeriodChips(),
          const _DailySummaryShortcut(),
          const SizedBox(height: 16),
          ...sales.when(
            loading: () => const [
              ReportLoadingCard(key: Key('reports-sales-loading')),
            ],
            error: (_, _) => [
              ReportErrorCard(
                message: AppStrings.reportsSalesLoadError,
                retryKey: const Key('reports-sales-retry'),
                onRetry: () =>
                    ref.read(salesReportControllerProvider.notifier).reload(),
              ),
            ],
            data: (state) => state == null
                ? [
                    MerchantCard(
                      child: Text(AppStrings.reportsDataUnavailable),
                    ),
                  ]
                : [
                    _FinanceSection(summary: state.summary),
                    const SizedBox(height: 12),
                    _OpsMetrics(summary: state.summary),
                    const SizedBox(height: 12),
                    _LastUpdatedBanner(asOf: state.summary.asOf),
                    const SizedBox(height: 12),
                    _TrendSection(summary: state.summary),
                    const SizedBox(height: 16),
                    _TopProductsSection(
                      top: state.topProducts,
                      canEdit: catalogRoleCanManage(
                        ref.watch(accessControllerProvider).membership?.role ??
                            '',
                      ),
                    ),
                  ],
          ),
          const SizedBox(height: 12),
          ...extras.when(
            loading: () => const [
              ReportLoadingCard(key: Key('reports-extras-loading')),
            ],
            error: (_, _) => [
              ReportErrorCard(
                message: AppStrings.reportsLoadError,
                retryKey: const Key('reports-extras-retry'),
                onRetry: () =>
                    ref.read(reportsControllerProvider.notifier).reload(),
              ),
            ],
            data: (state) => [
              _RatingsCard(ratings: state.ratings),
              const SizedBox(height: 12),
              _SettlementsSection(
                settlements: state.settlements,
                forbidden: state.settlementsForbidden,
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _FinanceSection extends StatelessWidget {
  const _FinanceSection({required this.summary});

  final MerchantSalesSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final finance = summary.finance;
    final granted = summary.financeGranted && finance != null;
    final rate = finance?.uniformCommissionRateBps;
    final String commissionLabel;
    if (granted && rate != null) {
      commissionLabel = AppStrings.reportsCommissionWithRate(MoneyFormat.basisPointsPercent(rate),
      );
    } else if (granted &&
        summary.dataComplete &&
        summary.completedOrderCount > 0) {
      commissionLabel = AppStrings.reportsCommissionMixedRates;
    } else {
      commissionLabel = AppStrings.reportsCommission;
    }
    final discount = finance?.merchantDiscountMinor;
    final showDiscount = granted && discount != null && discount != '0';
    final showRefunds =
        granted &&
        (finance.refundsCompletedCount > 0 ||
            finance.recordedRefundAdjustmentsMinor != '0');

    String deduction(String? minor) {
      final label = MoneyFormat.dzdDeduction(minor);
      return label.isEmpty ? AppStrings.reportsDataUnavailableShort : label;
    }

    return MerchantCard(
      key: const Key('reports-finance-section'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  AppStrings.reportsFinanceTitle.toUpperCase(),
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: AppColors.onSurfaceVariant,
                    letterSpacing: 0.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Icon(
                Icons.payments_outlined,
                size: 20,
                color: AppColors.outline,
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 10),
          _FinanceRow(
            key: const Key('reports-gross'),
            label: AppStrings.reportsGrossSales,
            value: _moneyOrDash(summary.grossMerchandiseMinor),
          ),
          if (showDiscount) ...[
            const SizedBox(height: 8),
            _FinanceRow(
              key: const Key('reports-merchant-discount'),
              label: AppStrings.reportsMerchantDiscount,
              value: deduction(discount),
              valueColor: AppColors.error,
            ),
          ],
          const SizedBox(height: 8),
          _FinanceRow(
            key: const Key('reports-commission'),
            label: commissionLabel,
            value: granted
                ? deduction(finance.commissionMinor)
                : AppStrings.reportsDataUnavailableShort,
            valueColor:
                granted &&
                    finance.commissionMinor != null &&
                    finance.commissionMinor != '0'
                ? AppColors.error
                : null,
          ),
          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 10),
          _NetRow(
            label: Text(
              AppStrings.reportsMerchantNet,
              style: theme.textTheme.labelLarge?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
            value: Text(
              granted
                  ? _moneyOrDash(finance.merchantNetMinor)
                  : AppStrings.reportsDataUnavailableShort,
              key: const Key('reports-net'),
              style: theme.textTheme.titleLarge?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (showRefunds) ...[
            const SizedBox(height: 12),
            Container(
              key: const Key('reports-refunds'),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _FinanceRow(
                    label: AppStrings.reportsRefundsCompleted,
                    value: '${finance.refundsCompletedCount}',
                    compact: true,
                  ),
                  const SizedBox(height: 4),
                  _FinanceRow(
                    label: AppStrings.reportsRefundAdjustments,
                    value: MoneyFormat.dzdSigned(
                      finance.recordedRefundAdjustmentsMinor,
                    ),
                    compact: true,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    AppStrings.reportsRefundsNote,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (!summary.financeGranted) ...[
            const SizedBox(height: 8),
            Text(
              AppStrings.reportsFinanceRestricted,
              key: const Key('reports-finance-restricted'),
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
          if (!summary.dataComplete) ...[
            const SizedBox(height: 8),
            Text(
              AppStrings.reportsFinanceMissingSnapshot,
              key: const Key('reports-finance-missing'),
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.error,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Net line: side by side, stacked (label above value) under large text so
/// the label never breaks mid-word next to a wide amount.
class _NetRow extends StatelessWidget {
  const _NetRow({required this.label, required this.value});

  final Widget label;
  final Widget value;

  @override
  Widget build(BuildContext context) {
    final stacked = MediaQuery.textScalerOf(context).scale(14) > 16;
    if (stacked) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          label,
          const SizedBox(height: 4),
          Align(alignment: Alignment.centerRight, child: value),
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: label),
        const SizedBox(width: 8),
        value,
      ],
    );
  }
}

class _FinanceRow extends StatelessWidget {
  const _FinanceRow({
    super.key,
    required this.label,
    required this.value,
    this.valueColor,
    this.compact = false,
  });

  final String label;
  final String value;
  final Color? valueColor;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style:
                (compact
                        ? theme.textTheme.bodySmall
                        : theme.textTheme.bodyMedium)
                    ?.copyWith(color: AppColors.onSurfaceVariant),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style:
              (compact
                      ? theme.textTheme.labelLarge
                      : theme.textTheme.titleMedium)
                  ?.copyWith(color: valueColor),
        ),
      ],
    );
  }
}

class _OpsMetrics extends StatelessWidget {
  const _OpsMetrics({required this.summary});

  final MerchantSalesSummary summary;

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.textScalerOf(context).scale(14);
    final stacked = scale > 16;
    final cards = [
      _OpsMetricCard(
        key: const Key('reports-metric-orders'),
        title: AppStrings.reportsOrdersMetric,
        icon: Icons.receipt_long_outlined,
        value: '${summary.completedOrderCount}',
      ),
      _OpsMetricCard(
        key: Key('reports-metric-prep'),
        title: AppStrings.reportsPrepTimeMetric,
        icon: Icons.timer_outlined,
        value: AppStrings.reportsDataUnavailableShort,
        caption: AppStrings.reportsPrepTimeNotTracked,
      ),
      _OpsMetricCard(
        key: const Key('reports-metric-cancellations'),
        title: AppStrings.reportsCancellationsMetric,
        icon: Icons.cancel_outlined,
        value: '${summary.cancelledOrderCount}',
        valueColor: summary.cancelledOrderCount > 0 ? AppColors.error : null,
      ),
      _OpsMetricCard(
        key: const Key('reports-metric-basket'),
        title: AppStrings.reportsAverageBasketMetric,
        icon: Icons.shopping_basket_outlined,
        value: _moneyOrDash(summary.averageBasketMinor),
      ),
    ];

    if (stacked) {
      return Column(
        children: [
          for (final card in cards) ...[card, const SizedBox(height: 12)],
        ],
      );
    }
    return Column(
      children: [
        for (var i = 0; i < cards.length; i += 2) ...[
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: cards[i]),
                const SizedBox(width: 12),
                Expanded(child: cards[i + 1]),
              ],
            ),
          ),
          if (i + 2 < cards.length) const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _OpsMetricCard extends StatelessWidget {
  const _OpsMetricCard({
    super.key,
    required this.title,
    required this.icon,
    required this.value,
    this.valueColor,
    this.caption,
  });

  final String title;
  final IconData icon;
  final String value;
  final Color? valueColor;
  final String? caption;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return MerchantCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  title.toUpperCase(),
                  maxLines: 2,
                  softWrap: true,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: AppColors.onSurfaceVariant,
                    letterSpacing: 0,
                    fontWeight: FontWeight.w600,
                    height: 1.15,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Icon(icon, size: 20, color: AppColors.onSurfaceVariant),
            ],
          ),
          const SizedBox(height: 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: valueColor ?? AppColors.onSurface,
              ),
            ),
          ),
          if (caption != null) ...[
            const SizedBox(height: 2),
            Text(
              caption!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _LastUpdatedBanner extends StatelessWidget {
  const _LastUpdatedBanner({required this.asOf});

  final String asOf;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      key: const Key('reports-last-updated'),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.update, size: 16, color: AppColors.onSurfaceVariant),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              AppStrings.reportsLastUpdated(reportClock(asOf)),
              textAlign: TextAlign.center,
              style: theme.textTheme.labelMedium?.copyWith(
                color: AppColors.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrendSection extends StatelessWidget {
  const _TrendSection({required this.summary});

  final MerchantSalesSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final buckets = summary.buckets;
    final hasSales = buckets.any(
      (b) => b.grossMerchandiseMinor != null && b.grossMerchandiseMinor != '0',
    );
    Widget placeholder(Key key, String text) => Container(
      key: key,
      height: 96,
      width: double.infinity,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: AppColors.onSurfaceVariant,
        ),
      ),
    );

    return MerchantCard(
      key: const Key('reports-trend-section'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.reportsTrendTitle,
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          if (!summary.dataComplete)
            placeholder(
              const Key('reports-trend-unavailable'),
              AppStrings.reportsDataUnavailable,
            )
          else if (!hasSales)
            placeholder(
              const Key('reports-trend-empty'),
              AppStrings.reportsTrendEmpty,
            )
          else
            _TrendBars(
              buckets: buckets,
              hourly: summary.hourly,
              totalOrders: summary.completedOrderCount,
              totalGross: summary.grossMerchandiseMinor ?? '0',
            ),
        ],
      ),
    );
  }
}

class _TrendBars extends StatelessWidget {
  const _TrendBars({
    required this.buckets,
    required this.hourly,
    required this.totalOrders,
    required this.totalGross,
  });

  final List<MerchantSalesTrendBucket> buckets;
  final bool hourly;
  final int totalOrders;
  final String totalGross;

  String _label(MerchantSalesTrendBucket b) {
    if (hourly && b.localStart.length >= 13) {
      return '${b.localStart.substring(11, 13)}h';
    }
    return reportShortCivilDate(b.localStart);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final values = [
      for (final b in buckets)
        BigInt.tryParse(b.grossMerchandiseMinor ?? '0') ?? BigInt.zero,
    ];
    final peak = values.fold<BigInt>(BigInt.zero, (m, v) => v > m ? v : m);
    // Bar geometry only (pixels); money stays integer for display.
    double factor(BigInt v) {
      if (peak == BigInt.zero || v == BigInt.zero) return 0;
      final perMille = (v * BigInt.from(1000) ~/ peak).toInt();
      return perMille < 30 ? 0.03 : perMille / 1000;
    }

    final gap = buckets.length > 31 ? 0.5 : 2.0;
    final labelStyle = theme.textTheme.labelSmall?.copyWith(
      color: AppColors.onSurfaceVariant,
    );
    final middle = buckets.length ~/ 2;

    return Semantics(
      label: AppStrings.reportsTrendSemantics(totalOrders.toString(), MoneyFormat.dzdOrEmpty(totalGross),
      ),
      child: ExcludeSemantics(
        child: Column(
          key: const Key('reports-trend-chart'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 120,
              padding: const EdgeInsets.only(top: 8),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (var i = 0; i < buckets.length; i++)
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: gap),
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: FractionallySizedBox(
                            key: Key('reports-trend-bar-$i'),
                            heightFactor: factor(values[i]),
                            widthFactor: 1,
                            child: const DecoratedBox(
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(3),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Text(
                  _label(buckets.first),
                  key: const Key('reports-trend-label-first'),
                  style: labelStyle,
                ),
                const Spacer(),
                if (buckets.length > 2) ...[
                  Text(_label(buckets[middle]), style: labelStyle),
                  const Spacer(),
                ],
                if (buckets.length > 1)
                  Text(
                    _label(buckets.last),
                    key: const Key('reports-trend-label-last'),
                    style: labelStyle,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TopProductsSection extends StatelessWidget {
  const _TopProductsSection({required this.top, required this.canEdit});

  final MerchantTopProducts top;
  final bool canEdit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      key: const Key('reports-top-products-section'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                AppStrings.reportsTopProductsTitle,
                style: theme.textTheme.titleMedium,
              ),
            ),
            if (top.distinctProductCount > 0)
              TextButton(
                key: const Key('reports-top-products-see-all'),
                onPressed: () => context.push(AppRoutes.reportsTopProducts),
                child: Text(AppStrings.reportsSeeAll),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (top.items.isEmpty)
          MerchantCard(
            key: const Key('reports-top-products-empty'),
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
              padding: const EdgeInsets.only(bottom: 8),
              child: _topProductRow(theme, item),
            ),
      ],
    );
  }

  Widget _topProductRow(ThemeData theme, MerchantTopProduct item) {
    final editableId = topProductEditableId(item, canEdit: canEdit);
    return Container(
      key: Key('reports-top-product-${item.rank}'),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: TopProductLink(
        productId: editableId,
        label: item.name,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ReportRankBadge(rank: item.rank),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      AppStrings.reportsOrderCount('${item.orderCount}'),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                MoneyFormat.dzdOrEmpty(item.revenueMinor),
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (editableId != null)
                TopProductChevron(
                  key: Key('reports-top-product-chevron-${item.rank}'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RatingsCard extends StatelessWidget {
  const _RatingsCard({required this.ratings});

  final MerchantRatingSummary? ratings;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (ratings == null) {
      return MerchantCard(
        child: Text(
          AppStrings.reportsRatingsUnavailable,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
      );
    }
    return MerchantCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  AppStrings.reportsRatingsTitle.toUpperCase(),
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: AppColors.onSurfaceVariant,
                    letterSpacing: 0.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Icon(
                Icons.star_outline,
                size: 20,
                color: AppColors.outline,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                ratings!.average?.toStringAsFixed(1) ?? '—',
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '${ratings!.count} ${AppStrings.reportsRatingsCount}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          if (ratings!.count == 0) ...[
            const SizedBox(height: 8),
            Text(
              AppStrings.reportsRatingsEmpty,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SettlementsSection extends StatelessWidget {
  const _SettlementsSection({
    required this.settlements,
    required this.forbidden,
  });

  final List<MerchantSettlementSummary> settlements;
  final bool forbidden;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return MerchantCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.reportsSettlementsTitle.toUpperCase(),
            style: theme.textTheme.labelMedium?.copyWith(
              color: AppColors.onSurfaceVariant,
              letterSpacing: 0.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          if (forbidden)
            Text(
              AppStrings.reportsSettlementsForbidden,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            )
          else if (settlements.isEmpty)
            Text(
              AppStrings.reportsSettlementsEmpty,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            )
          else
            ...settlements.map((s) => _SettlementTile(settlement: s)),
        ],
      ),
    );
  }
}

class _SettlementTile extends StatelessWidget {
  const _SettlementTile({required this.settlement});

  final MerchantSettlementSummary settlement;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final net = MoneyFormat.dzdOrEmpty(settlement.netPayableMinor);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_shortDate(settlement.periodStart)} → ${_shortDate(settlement.periodEnd)}',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 2),
                Text(
                  AppStrings.reportsSettlementStatus(settlement.status.toString()),
                  key: const Key('reports-settlement-status'),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (net.isNotEmpty)
            Text(
              net,
              style: theme.textTheme.titleMedium?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
        ],
      ),
    );
  }

  String _shortDate(String iso) {
    final dt = DateTime.tryParse(iso)?.toLocal();
    if (dt == null) return iso;
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }
}
