import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:speedygo_merchant_app/app/theme/app_theme.dart';
import 'package:speedygo_merchant_app/core/constants/app_strings.dart';
import 'package:speedygo_merchant_app/core/navigation/app_routes.dart';
import 'package:speedygo_merchant_app/core/widgets/merchant_ui.dart';
import 'package:speedygo_merchant_app/features/reports/application/sales_report_controller.dart';
import 'package:speedygo_merchant_app/features/reports/data/reports_models.dart';

/// Backend limit for `period=CUSTOM` (inclusive days).
const reportsMaxCustomDays = 93;

/// Product id a top-product row may open in the editor, or null when the
/// role cannot edit the catalogue or the product was deleted.
String? topProductEditableId(MerchantTopProduct item, {required bool canEdit}) {
  final id = item.productId;
  if (!canEdit || id == null || id.isEmpty) return null;
  return id;
}

/// Wraps a top-product row in a tap target when [productId] is non-null.
/// Place it inside the row's decorated container so the ink stays visible.
class TopProductLink extends StatelessWidget {
  const TopProductLink({
    super.key,
    required this.productId,
    required this.label,
    required this.child,
  });

  final String? productId;
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final id = productId;
    if (id == null) return child;
    return Semantics(
      button: true,
      label: label,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: () => context.push(AppRoutes.catalogProductEdit(id)),
          child: child,
        ),
      ),
    );
  }
}

/// Trailing chevron shown only on rows that open the editor.
class TopProductChevron extends StatelessWidget {
  const TopProductChevron({super.key});

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.only(left: 4),
    child: Icon(
      Icons.chevron_right,
      size: 20,
      color: AppColors.onSurfaceVariant,
    ),
  );
}

String _two(int v) => v.toString().padLeft(2, '0');

/// `YYYY-MM-DD` civil date for the report API.
String reportCivilDate(DateTime d) =>
    '${d.year}-${_two(d.month)}-${_two(d.day)}';

/// `2031-03-10` → `10/03`.
String reportShortCivilDate(String civil) {
  final parts = civil.split('-');
  if (parts.length != 3) return civil;
  return '${parts[2]}/${parts[1]}';
}

/// Server `asOf` instant → device-local `HH:mm`.
String reportClock(String iso) {
  final dt = DateTime.tryParse(iso)?.toLocal();
  if (dt == null) return '—';
  return '${_two(dt.hour)}:${_two(dt.minute)}';
}

/// Period chips (Aujourd’hui / Hier / Cette semaine / Ce mois / Personnalisé)
/// bound to [reportPeriodProvider].
class ReportPeriodChips extends ConsumerWidget {
  const ReportPeriodChips({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selection = ref.watch(reportPeriodProvider);
    final notifier = ref.read(reportPeriodProvider.notifier);
    final customLabel =
        selection.period == ReportPeriod.custom &&
            selection.from != null &&
            selection.to != null
        ? (selection.from == selection.to
              ? reportShortCivilDate(selection.from!)
              : '${reportShortCivilDate(selection.from!)} – ${reportShortCivilDate(selection.to!)}')
        : AppStrings.reportsPeriodCustom;

    Widget chip(ReportPeriod period, String label, VoidCallback onTap) {
      final selected = selection.period == period;
      return _RevealWhenSelected(
        selected: selected,
        child: Padding(
          padding: const EdgeInsets.only(right: 8),
          child: Semantics(
            button: true,
            selected: selected,
            child: Material(
              color: selected ? AppColors.primary : AppColors.surfaceContainer,
              shape: StadiumBorder(
                side: BorderSide(
                  color: selected
                      ? AppColors.primary
                      : AppColors.outlineVariant,
                ),
              ),
              child: InkWell(
                key: Key('reports-period-${period.apiValue}'),
                customBorder: const StadiumBorder(),
                onTap: onTap,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: selected
                          ? AppColors.onPrimary
                          : AppColors.onSurfaceVariant,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Semantics(
      label: AppStrings.reportsPeriodSelectorLabel,
      container: true,
      child: SingleChildScrollView(
        key: const Key('reports-period-chips'),
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final (period, label) in [
              (ReportPeriod.today, AppStrings.reportsPeriodToday),
              (ReportPeriod.yesterday, AppStrings.reportsPeriodYesterday),
              (ReportPeriod.thisWeek, AppStrings.reportsPeriodWeek),
              (ReportPeriod.thisMonth, AppStrings.reportsPeriodMonth),
            ])
              chip(
                period,
                label,
                () => notifier.select(ReportPeriodSelection(period)),
              ),
            chip(
              ReportPeriod.custom,
              customLabel,
              () => _pickCustomRange(context, notifier, selection),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickCustomRange(
    BuildContext context,
    ReportPeriodController notifier,
    ReportPeriodSelection current,
  ) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    DateTimeRange? initial;
    if (current.period == ReportPeriod.custom &&
        current.from != null &&
        current.to != null) {
      final from = DateTime.tryParse(current.from!);
      final to = DateTime.tryParse(current.to!);
      if (from != null && to != null && !to.isAfter(today)) {
        initial = DateTimeRange(start: from, end: to);
      }
    }
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(today.year - 2, today.month, today.day),
      lastDate: today,
      initialDateRange: initial,
      helpText: AppStrings.reportsPeriodCustom,
    );
    if (picked == null) return;
    final start = DateTime(
      picked.start.year,
      picked.start.month,
      picked.start.day,
    );
    final end = DateTime(picked.end.year, picked.end.month, picked.end.day);
    final days =
        DateTime.utc(
          end.year,
          end.month,
          end.day,
        ).difference(DateTime.utc(start.year, start.month, start.day)).inDays +
        1;
    if (days > reportsMaxCustomDays) {
      if (context.mounted) {
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          SnackBar(content: Text(AppStrings.reportsCustomRangeTooLong)),
        );
      }
      return;
    }
    notifier.select(
      ReportPeriodSelection(
        ReportPeriod.custom,
        from: reportCivilDate(start),
        to: reportCivilDate(end),
      ),
    );
  }
}

/// Scrolls the selected chip into the horizontal strip's viewport, so a
/// custom range stays visible when another report screen opens with it.
class _RevealWhenSelected extends StatefulWidget {
  const _RevealWhenSelected({required this.selected, required this.child});

  final bool selected;
  final Widget child;

  @override
  State<_RevealWhenSelected> createState() => _RevealWhenSelectedState();
}

class _RevealWhenSelectedState extends State<_RevealWhenSelected> {
  @override
  void initState() {
    super.initState();
    if (widget.selected) _reveal();
  }

  @override
  void didUpdateWidget(_RevealWhenSelected oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selected && !oldWidget.selected) _reveal();
  }

  void _reveal() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Scrollable.ensureVisible(
        context,
        alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
      );
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Rank square; the first rank is filled (reference “1” badge).
class ReportRankBadge extends StatelessWidget {
  const ReportRankBadge({super.key, required this.rank});

  final int rank;

  @override
  Widget build(BuildContext context) {
    final first = rank == 1;
    return Container(
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: first
            ? AppColors.primaryContainer
            : AppColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '$rank',
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: first
              ? AppColors.onPrimaryContainer
              : AppColors.onSurfaceVariant,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// Inline error card with an explicit retry action.
class ReportErrorCard extends StatelessWidget {
  const ReportErrorCard({
    super.key,
    required this.message,
    required this.onRetry,
    required this.retryKey,
  });

  final String message;
  final VoidCallback onRetry;
  final Key retryKey;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return MerchantCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.error_outline, color: AppColors.error),
              const SizedBox(width: 8),
              Expanded(child: Text(message, style: theme.textTheme.bodyMedium)),
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              key: retryKey,
              onPressed: onRetry,
              child: Text(AppStrings.retry),
            ),
          ),
        ],
      ),
    );
  }
}

class ReportLoadingCard extends StatelessWidget {
  const ReportLoadingCard({super.key});

  @override
  Widget build(BuildContext context) {
    return const MerchantCard(
      child: SizedBox(
        height: 120,
        child: Center(child: CircularProgressIndicator()),
      ),
    );
  }
}
