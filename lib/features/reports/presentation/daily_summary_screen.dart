import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:speedygo_merchant_app/app/theme/app_theme.dart';
import 'package:speedygo_merchant_app/core/constants/app_strings.dart';
import 'package:speedygo_merchant_app/core/money/money_format.dart';
import 'package:speedygo_merchant_app/core/navigation/app_routes.dart';
import 'package:speedygo_merchant_app/core/widgets/merchant_primary_button.dart';
import 'package:speedygo_merchant_app/core/widgets/merchant_ui.dart';
import 'package:speedygo_merchant_app/features/access/application/access_controller.dart';
import 'package:speedygo_merchant_app/features/reports/application/daily_summary_controller.dart';
import 'package:speedygo_merchant_app/features/reports/data/reports_models.dart';
import 'package:speedygo_merchant_app/features/reports/presentation/report_widgets.dart';

String _moneyOrDash(String? minor) {
  final label = MoneyFormat.dzdOrEmpty(minor);
  return label.isEmpty ? AppStrings.reportsDataUnavailableShort : label;
}

final _frMonths = [
  'janvier',
  'février',
  'mars',
  'avril',
  'mai',
  'juin',
  'juillet',
  'août',
  'septembre',
  'octobre',
  'novembre',
  'décembre',
];

String _dailySummaryDateLabel(String civil, DateTime now) {
  final parts = civil.split('-');
  if (parts.length != 3) return civil;
  final year = int.parse(parts[0]);
  final month = int.parse(parts[1]);
  final day = int.parse(parts[2]);
  final date = DateTime(year, month, day);
  final today = DateTime(now.year, now.month, now.day);
  final monthLabel = month >= 1 && month <= 12 ? _frMonths[month - 1] : '';
  final dayLabel = '$day ${_capitalize(monthLabel)}';
  if (date == today) {
    return AppStrings.reportsDailySummaryTodayDate(dayLabel.toString());
  }
  return dayLabel;
}

String _capitalize(String value) {
  if (value.isEmpty) return value;
  return '${value[0].toUpperCase()}${value.substring(1)}';
}

String _onTimeRateLabel(int? bps) {
  if (bps == null) return AppStrings.reportsDataUnavailableShort;
  return AppStrings.reportsDailySummaryOnTimePercent(MoneyFormat.basisPointsPercent(bps),
  );
}

class DailySummaryScreen extends ConsumerWidget {
  const DailySummaryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final branchName = ref.watch(
      accessControllerProvider.select((a) => a.selectedBranch?.name),
    );
    final async = ref.watch(dailySummaryControllerProvider);
    final date = ref.watch(dailySummaryDateProvider);
    final theme = Theme.of(context);
    Future<void> reload() =>
        ref.read(dailySummaryControllerProvider.notifier).reload();

    return MerchantScaffold(
      title: AppStrings.reportsDailySummaryTitle,
      subtitle: branchName,
      headerColor: AppColors.surface,
      titleStyle: theme.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
        color: AppColors.onSurface,
      ),
      bodyPadding: EdgeInsets.zero,
      leading: IconButton(
        key: const Key('daily-summary-back'),
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
          key: const Key('daily-summary-refresh'),
          tooltip: AppStrings.refresh,
          onPressed: reload,
          icon: const Icon(Icons.refresh),
        ),
      ],
      body: Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              onRefresh: reload,
              child: async.when(
                loading: () => ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: const [
                    SizedBox(height: 8),
                    ReportLoadingCard(key: Key('daily-summary-loading')),
                  ],
                ),
                error: (_, _) => ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: ReportErrorCard(
                        message: AppStrings.reportsDailySummaryLoadError,
                        retryKey: const Key('daily-summary-retry'),
                        onRetry: reload,
                      ),
                    ),
                  ],
                ),
                data: (summary) {
                  if (summary == null) {
                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(height: 8),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: MerchantCard(
                            child: Text(AppStrings.reportsDataUnavailable),
                          ),
                        ),
                      ],
                    );
                  }
                  return _DailySummaryBody(summary: summary, date: date);
                },
              ),
            ),
          ),
          async.maybeWhen(
            data: (summary) => summary == null
                ? const SizedBox.shrink()
                : MerchantStickyBar(
                    child: MerchantPrimaryButton(
                      key: const Key('daily-summary-view-orders'),
                      label: AppStrings.reportsDailySummaryViewOrders,
                      icon: Icons.list_alt,
                      leadingIcon: true,
                      maxLines: 2,
                      onPressed: () => context.go(AppRoutes.orders),
                    ),
                  ),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

/// Title + date chip: side-by-side when they fit; otherwise title gets the full
/// width and the chip wraps below (no text-scale clamp, no title ellipsis).
class _DailySummaryTitleDateHeader extends StatelessWidget {
  const _DailySummaryTitleDateHeader({
    required this.date,
    required this.onPickDate,
  });

  final String date;
  final VoidCallback onPickDate;

  static const _gap = 8.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final titleStyle = theme.textTheme.headlineMedium?.copyWith(
      fontWeight: FontWeight.w700,
    );
    final chipLabelStyle = theme.textTheme.labelLarge?.copyWith(
      color: AppColors.primary,
      fontWeight: FontWeight.w600,
    );
    final dateLabel = _dailySummaryDateLabel(date, DateTime.now());
    final chip = Material(
      color: AppColors.surfaceContainerLow,
      shape: const StadiumBorder(
        side: BorderSide(color: AppColors.outlineVariant),
      ),
      child: InkWell(
        key: const Key('daily-summary-date-pill'),
        customBorder: const StadiumBorder(),
        onTap: onPickDate,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.calendar_today,
                size: 16,
                color: AppColors.primary,
              ),
              const SizedBox(width: 6),
              Text(dateLabel, style: chipLabelStyle),
            ],
          ),
        ),
      ),
    );

    final title = Text(
      AppStrings.reportsDailySummaryTitle,
      key: const Key('daily-summary-title'),
      style: titleStyle,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final scaler = MediaQuery.textScalerOf(context);
        final direction = Directionality.of(context);
        final titlePainter = TextPainter(
          text: TextSpan(
            text: AppStrings.reportsDailySummaryTitle,
            style: titleStyle,
          ),
          textDirection: direction,
          textScaler: scaler,
          maxLines: 1,
        )..layout();
        final chipPainter = TextPainter(
          text: TextSpan(text: dateLabel, style: chipLabelStyle),
          textDirection: direction,
          textScaler: scaler,
          maxLines: 1,
        )..layout();
        // Icon 16 + gap 6 + horizontal padding 24.
        final chipWidth = chipPainter.width + 16 + 6 + 24;
        final fitsSideBySide =
            titlePainter.width + _gap + chipWidth <= constraints.maxWidth;

        return Wrap(
          key: const Key('daily-summary-title-date'),
          spacing: _gap,
          runSpacing: _gap,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: fitsSideBySide ? null : constraints.maxWidth,
              child: title,
            ),
            chip,
          ],
        );
      },
    );
  }
}

class _DailySummaryBody extends ConsumerWidget {
  const _DailySummaryBody({required this.summary, required this.date});

  final MerchantDailySummary summary;
  final String date;

  Future<void> _pickDate(BuildContext context, WidgetRef ref) async {
    final parts = date.split('-');
    if (parts.length != 3) return;
    final initial = DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isAfter(today) ? today : initial,
      firstDate: DateTime(today.year - 2, today.month, today.day),
      lastDate: today,
      helpText: AppStrings.reportsDailySummaryTitle,
    );
    if (picked == null) return;
    ref.read(dailySummaryDateProvider.notifier).select(reportCivilDate(picked));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scale = MediaQuery.textScalerOf(context).scale(14);
    final stacked = scale > 16;
    final emptyDay = summary.ordersCreatedCount == 0;
    final prepMinutes = summary.averageActualPreparationMinutes;
    final cancelledTotal =
        summary.breakdown.cancelled + summary.breakdown.failed;

    return ListView(
      key: const Key('daily-summary-screen'),
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        _DailySummaryTitleDateHeader(
          date: date,
          onPickDate: () => _pickDate(context, ref),
        ),
        const SizedBox(height: 16),
        if (emptyDay)
          MerchantCard(
            key: const Key('daily-summary-empty'),
            child: Text(
              AppStrings.reportsDailySummaryEmpty,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
          )
        else ...[
          _KpiGrid(
            stacked: stacked,
            summary: summary,
            prepMinutes: prepMinutes,
          ),
          const SizedBox(height: 12),
          _BreakdownCard(
            completed: summary.breakdown.completed,
            inProgress: summary.breakdown.inProgress,
            cancelled: cancelledTotal,
            total: summary.ordersCreatedCount,
          ),
          const SizedBox(height: 12),
          _PrepEfficiencyCard(
            averageMinutes: prepMinutes,
            onTimeRateBps: summary.onTimePreparationRateBps,
          ),
          if (summary.cancellationReasons.isNotEmpty) ...[
            const SizedBox(height: 12),
            _CancellationReasonsCard(reasons: summary.cancellationReasons),
          ],
        ],
        if (!summary.dataComplete) ...[
          const SizedBox(height: 12),
          Text(
            AppStrings.reportsFinanceMissingSnapshot,
            key: const Key('daily-summary-missing-snapshot'),
            style: theme.textTheme.bodySmall?.copyWith(color: AppColors.error),
          ),
        ],
        const SizedBox(height: 8),
        _LastUpdatedBanner(asOf: summary.asOf),
      ],
    );
  }
}

class _KpiGrid extends StatelessWidget {
  const _KpiGrid({
    required this.stacked,
    required this.summary,
    required this.prepMinutes,
  });

  final bool stacked;
  final MerchantDailySummary summary;
  final int? prepMinutes;

  @override
  Widget build(BuildContext context) {
    final cards = [
      _KpiCard(
        key: const Key('daily-summary-kpi-sales'),
        title: AppStrings.reportsDailySummarySalesKpi,
        icon: Icons.payments_outlined,
        value: _moneyOrDash(summary.grossMerchandiseMinor),
        valueColor: AppColors.primary,
        iconBackground: AppColors.primaryContainer.withValues(alpha: 0.2),
        iconColor: AppColors.primary,
      ),
      _KpiCard(
        key: const Key('daily-summary-kpi-orders'),
        title: AppStrings.reportsDailySummaryOrdersKpi,
        icon: Icons.receipt_long_outlined,
        value: '${summary.ordersCreatedCount}',
      ),
      _KpiCard(
        key: const Key('daily-summary-kpi-prep'),
        title: AppStrings.reportsDailySummaryPrepKpi,
        icon: Icons.timer_outlined,
        value: switch (prepMinutes) {
          null => AppStrings.reportsDataUnavailableShort,
          final m => AppStrings.reportsDailySummaryMinutes(m),
        },
      ),
      _KpiCard(
        key: const Key('daily-summary-kpi-cancellations'),
        title: AppStrings.reportsDailySummaryCancellationsKpi,
        icon: Icons.cancel_outlined,
        value: '${summary.cancelledOrderCount}',
        valueColor: summary.cancelledOrderCount > 0 ? AppColors.error : null,
        iconBackground: AppColors.errorContainer.withValues(alpha: 0.3),
        iconColor: AppColors.error,
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

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    super.key,
    required this.title,
    required this.icon,
    required this.value,
    this.valueColor,
    this.iconBackground,
    this.iconColor,
  });

  final String title;
  final IconData icon;
  final String value;
  final Color? valueColor;
  final Color? iconBackground;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return MerchantCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: iconBackground ?? AppColors.surfaceContainerHigh,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 18,
                  color: iconColor ?? AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: valueColor ?? AppColors.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BreakdownCard extends StatelessWidget {
  const _BreakdownCard({
    required this.completed,
    required this.inProgress,
    required this.cancelled,
    required this.total,
  });

  final int completed;
  final int inProgress;
  final int cancelled;
  final int total;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return MerchantCard(
      key: const Key('daily-summary-breakdown'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.reportsDailySummaryBreakdownTitle,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: SizedBox(
              height: 16,
              child: Row(
                children: [
                  if (completed > 0)
                    Expanded(
                      flex: completed,
                      child: const ColoredBox(color: AppColors.tertiary),
                    ),
                  if (inProgress > 0)
                    Expanded(
                      flex: inProgress,
                      child: const ColoredBox(color: AppColors.secondary),
                    ),
                  if (cancelled > 0)
                    Expanded(
                      flex: cancelled,
                      child: const ColoredBox(color: AppColors.error),
                    ),
                  if (completed + inProgress + cancelled == 0)
                    const Expanded(child: ColoredBox(color: AppColors.outlineVariant)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              _LegendDot(
                color: AppColors.tertiary,
                label: AppStrings.reportsDailySummaryDelivered,
                count: completed,
              ),
              _LegendDot(
                color: AppColors.secondary,
                label: AppStrings.reportsDailySummaryInProgress,
                count: inProgress,
              ),
              _LegendDot(
                color: AppColors.error,
                label: AppStrings.reportsDailySummaryCancelled,
                count: cancelled,
                countColor: AppColors.error,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({
    required this.color,
    required this.label,
    required this.count,
    this.countColor,
  });

  final Color color;
  final String label;
  final int count;
  final Color? countColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text.rich(
          TextSpan(
            text: '$label ',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
            children: [
              TextSpan(
                text: '$count',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: countColor ?? AppColors.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PrepEfficiencyCard extends StatelessWidget {
  const _PrepEfficiencyCard({
    required this.averageMinutes,
    required this.onTimeRateBps,
  });

  final int? averageMinutes;
  final int? onTimeRateBps;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scale = MediaQuery.textScalerOf(context).scale(14);
    final stacked = scale > 16;
    final averageValue = averageMinutes == null
        ? AppStrings.reportsDataUnavailableShort
        : AppStrings.reportsDailySummaryMinutes(averageMinutes!);
    final onTimeValue = _onTimeRateLabel(onTimeRateBps);

    Widget column(String label, String value, {Color? color}) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.headlineMedium?.copyWith(
              color: color ?? AppColors.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      );
    }

    return MerchantCard(
      key: const Key('daily-summary-prep-efficiency'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.reportsDailySummaryPrepEfficiencyTitle,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          if (stacked) ...[
            column(
              AppStrings.reportsDailySummaryPrepAverage,
              averageValue,
              color: AppColors.primary,
            ),
            const SizedBox(height: 12),
            column(AppStrings.reportsDailySummaryOnTimeRate, onTimeValue),
          ] else
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: column(
                    AppStrings.reportsDailySummaryPrepAverage,
                    averageValue,
                    color: AppColors.primary,
                  ),
                ),
                Container(
                  width: 1,
                  height: 48,
                  color: AppColors.outlineVariant,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: column(
                    AppStrings.reportsDailySummaryOnTimeRate,
                    onTimeValue,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _CancellationReasonsCard extends StatelessWidget {
  const _CancellationReasonsCard({required this.reasons});

  final List<MerchantDailySummaryCancellationReason> reasons;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return MerchantCard(
      key: const Key('daily-summary-cancellation-reasons'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.reportsDailySummaryCancellationMotifs,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          for (var i = 0; i < reasons.length; i++)
            Padding(
              padding: EdgeInsets.only(
                bottom: i == reasons.length - 1 ? 0 : 8,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      reasons[i].label,
                      key: Key(
                        'daily-summary-cancel-reason-${reasons[i].reasonCode}',
                      ),
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                  Text(
                    '${reasons[i].count}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
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

class _LastUpdatedBanner extends StatelessWidget {
  const _LastUpdatedBanner({required this.asOf});

  final String asOf;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      key: const Key('daily-summary-last-updated'),
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
