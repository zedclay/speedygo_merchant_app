import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:speedygo_merchant_app/app/theme/app_theme.dart';
import 'package:speedygo_merchant_app/core/constants/app_strings.dart';
import 'package:speedygo_merchant_app/core/money/money_format.dart';
import 'package:speedygo_merchant_app/core/navigation/app_routes.dart';
import 'package:speedygo_merchant_app/core/widgets/merchant_ui.dart';
import 'package:speedygo_merchant_app/features/access/application/access_controller.dart';
import 'package:speedygo_merchant_app/features/orders/application/orders_controller.dart';
import 'package:speedygo_merchant_app/features/orders/data/order_models.dart';
import 'package:speedygo_merchant_app/features/orders/presentation/order_public_reference.dart';
import 'package:speedygo_merchant_app/features/orders/presentation/orders_screen.dart';
import 'package:speedygo_merchant_app/features/reports/application/sales_report_controller.dart';
import 'package:speedygo_merchant_app/features/reports/data/reports_models.dart';
import 'package:speedygo_merchant_app/features/store/application/store_controllers.dart';

/// Client time of the last successful active-orders load. The orders list
/// has no server `asOf`, so this never implies realtime freshness.
class HomeLastSyncController extends Notifier<DateTime?> {
  @override
  DateTime? build() {
    ref.listen(homeActiveOrdersProvider, (_, next) {
      if (next.hasValue && !next.isLoading && !next.hasError) {
        state = DateTime.now();
      }
    });
    final current = ref.read(homeActiveOrdersProvider);
    return current.hasValue && !current.isLoading ? DateTime.now() : null;
  }
}

final homeLastSyncProvider =
    NotifierProvider<HomeLastSyncController, DateTime?>(
      HomeLastSyncController.new,
    );

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final access = ref.watch(accessControllerProvider);
    final membership = access.membership;
    final branch = access.selectedBranch;
    final counts = ref.watch(homeOrderCountsProvider);
    final activeOrders = ref.watch(homeActiveOrdersProvider);
    final todaySales = ref.watch(todaySalesSummaryProvider);
    final lastSync = ref.watch(homeLastSyncProvider);
    final unread = ref.watch(notificationsUnreadCountProvider).value ?? 0;
    final title =
        branch?.name ?? membership?.merchantName ?? AppStrings.homeTitle;
    // Reference shows the availability pill only; the operational pill appears
    // when the Branch is not ACTIVE so restrictions stay visible (D-A2).
    final operational =
        branch == null || branch.operationalStatus.toUpperCase() == 'ACTIVE'
        ? null
        : _operationalLabel(branch.operationalStatus);
    final availability = ref.watch(branchAvailabilityControllerProvider);
    final isOpenNow = availability.value?.isOpenNow;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Material(
              color: AppColors.background,
              elevation: 1,
              shadowColor: const Color(0x14000000),
              child: SizedBox(
                height: MerchantLayout.headerHeight,
                child: Padding(
                  padding: const EdgeInsets.only(left: 16, right: 4),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.speed,
                        color: AppColors.primary,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          title,
                          key: const Key('home-branch-name'),
                          style: theme.textTheme.headlineMedium?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                            height: 1.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isOpenNow != null) ...[
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () =>
                              context.push(AppRoutes.storeAvailability),
                          child: MerchantStatusPill(
                            key: const Key('home-open-badge'),
                            label: isOpenNow
                                ? AppStrings.availabilityOpen
                                : AppStrings.availabilityClosed,
                            tone: isOpenNow
                                ? StatusTone.success
                                : StatusTone.error,
                          ),
                        ),
                      ],
                      if (operational != null) ...[
                        const SizedBox(width: 6),
                        MerchantStatusPill(
                          key: const Key('home-operational-badge'),
                          label: operational,
                          tone: StatusTone.warning,
                        ),
                      ],
                      MerchantBellButton(
                        key: const Key('home-notifications'),
                        unread: unread,
                        onPressed: () => context.push(AppRoutes.notifications),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(todaySalesSummaryProvider);
                  await Future.wait([
                    ref.read(homeOrderCountsProvider.notifier).reload(),
                    ref.read(homeActiveOrdersProvider.notifier).reload(),
                    ref
                        .read(branchAvailabilityControllerProvider.notifier)
                        .reload(),
                  ]);
                },
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    if (membership?.verificationAttentionRequired == true) ...[
                      const _VerificationBanner(),
                      const SizedBox(height: 24),
                    ],
                    _KpiStrip(summary: todaySales),
                    const SizedBox(height: 24),
                    counts.when(
                      loading: () => const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      error: (_, _) => ErrorBody(
                        message: AppStrings.ordersLoadError,
                        onRetry: () =>
                            ref.read(homeOrderCountsProvider.notifier).reload(),
                      ),
                      data: (c) => _ShortcutTiles(
                        incoming: c.incoming,
                        preparing: c.preparing,
                        ready: c.ready,
                        onIncoming: () => _goOrders(
                          context,
                          ref,
                          MerchantOrderListFilter.incoming,
                        ),
                        onPreparing: () => _goOrders(
                          context,
                          ref,
                          MerchantOrderListFilter.preparing,
                        ),
                        onReady: () => _goOrders(
                          context,
                          ref,
                          MerchantOrderListFilter.ready,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Text(
                            AppStrings.homeActiveOrdersTitle,
                            style: theme.textTheme.titleLarge,
                          ),
                        ),
                        if (lastSync != null) ...[
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              AppStrings.homeLastSync(_hhmm(lastSync)),
                              key: const Key('home-last-sync'),
                              textAlign: TextAlign.end,
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: AppColors.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 12),
                    activeOrders.when(
                      loading: () => const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      error: (_, _) => ErrorBody(
                        message: AppStrings.ordersLoadError,
                        onRetry: () => ref
                            .read(homeActiveOrdersProvider.notifier)
                            .reload(),
                      ),
                      data: (orders) {
                        if (orders.isEmpty) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            child: Text(
                              AppStrings.homeActiveOrdersEmpty,
                              key: const Key('home-active-orders-empty'),
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                          );
                        }
                        return Column(
                          children: [
                            for (final order in orders) ...[
                              _HomeActiveOrderCard(
                                order: order,
                                onTap: () => context.push(
                                  AppRoutes.orderDetail(order.id),
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _goOrders(
    BuildContext context,
    WidgetRef ref,
    MerchantOrderListFilter filter,
  ) async {
    await ref.read(ordersListControllerProvider.notifier).setFilter(filter);
    if (context.mounted) {
      context.go(AppRoutes.orders);
    }
  }
}

String _hhmm(DateTime t) =>
    '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

/// Attention banner only: there is no verification destination route
/// (parity decision D-A4), so it has no tap target and no chevron.
class _VerificationBanner extends StatelessWidget {
  const _VerificationBanner();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      key: const Key('home-verification-banner'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: AppColors.onPrimaryContainer),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.homeVerificationTitle,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: AppColors.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  AppStrings.homeVerificationBody,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.onPrimaryContainer.withValues(alpha: 0.9),
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

/// Today's KPIs from `GET /reports/sales?period=TODAY`. "Temps moyen" has no
/// contract and is omitted; missing values render "—", never zero.
class _KpiStrip extends StatelessWidget {
  const _KpiStrip({required this.summary});

  final AsyncValue<MerchantSalesSummary?> summary;

  @override
  Widget build(BuildContext context) {
    final data = summary.value;
    final gross = data?.grossMerchandiseMinor;
    String salesValue = AppStrings.homeKpiUnavailable;
    String? salesUnit;
    if (gross != null && MoneyFormat.isMinorString(gross)) {
      final formatted = MoneyFormat.dzd(gross);
      salesValue = formatted.substring(0, formatted.length - 4);
      salesUnit = AppStrings.homeKpiCurrency;
    }
    final orders = data == null ? null : '${data.completedOrderCount}';
    return Row(
      key: const Key('home-kpi-strip'),
      children: [
        Expanded(
          child: _KpiCard(
            keyName: 'home-kpi-sales',
            label: AppStrings.homeKpiSales,
            value: salesValue,
            unit: salesUnit,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _KpiCard(
            keyName: 'home-kpi-orders',
            label: AppStrings.homeKpiOrders,
            value: orders ?? AppStrings.homeKpiUnavailable,
            unit: orders == null ? null : AppStrings.homeKpiOrdersUnit,
          ),
        ),
      ],
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.keyName,
    required this.label,
    required this.value,
    this.unit,
  });

  final String keyName;
  final String label;
  final String value;
  final String? unit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      key: Key(keyName),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.3),
        ),
        boxShadow: merchantCardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: AppColors.onSurfaceVariant,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Text.rich(
              TextSpan(
                text: value,
                style: theme.textTheme.titleLarge?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
                children: [
                  if (unit != null)
                    TextSpan(
                      text: ' $unit',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppColors.primary,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _ShortcutTiles extends StatelessWidget {
  const _ShortcutTiles({
    required this.incoming,
    required this.preparing,
    required this.ready,
    required this.onIncoming,
    required this.onPreparing,
    required this.onReady,
  });

  final int incoming;
  final int preparing;
  final int ready;
  final VoidCallback onIncoming;
  final VoidCallback onPreparing;
  final VoidCallback onReady;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow =
            MediaQuery.textScalerOf(context).scale(14) > 16 ||
            constraints.maxWidth < 340;
        final tiles = [
          _ShortcutTile(
            keyName: 'home-count-incoming',
            value: '$incoming',
            label: AppStrings.homeCountIncoming,
            emphasized: true,
            onTap: onIncoming,
          ),
          _ShortcutTile(
            keyName: 'home-count-preparing',
            value: '$preparing',
            label: AppStrings.homeCountPreparing,
            onTap: onPreparing,
          ),
          _ShortcutTile(
            keyName: 'home-count-ready',
            value: '$ready',
            label: AppStrings.homeCountReady,
            onTap: onReady,
          ),
          const _ShortcutTile(
            keyName: 'home-count-courier',
            value: AppStrings.homeCountCourierUnavailable,
            label: AppStrings.homeCountCourier,
            onTap: null,
          ),
        ];
        if (narrow) {
          return Column(
            children: [
              Row(
                children: [
                  Expanded(child: tiles[0]),
                  const SizedBox(width: 8),
                  Expanded(child: tiles[1]),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: tiles[2]),
                  const SizedBox(width: 8),
                  Expanded(child: tiles[3]),
                ],
              ),
            ],
          );
        }
        return Row(
          children: [
            for (var i = 0; i < tiles.length; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              Expanded(child: tiles[i]),
            ],
          ],
        );
      },
    );
  }
}

class _ShortcutTile extends StatelessWidget {
  const _ShortcutTile({
    required this.keyName,
    required this.value,
    required this.label,
    required this.onTap,
    this.emphasized = false,
  });

  final String keyName;
  final String value;
  final String label;
  final VoidCallback? onTap;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final bg = emphasized ? AppColors.primary : AppColors.surfaceContainerHigh;
    final fg = emphasized ? AppColors.onPrimary : AppColors.onSurfaceVariant;
    final radius = BorderRadius.circular(12);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: emphasized
            ? const [
                BoxShadow(
                  color: Color(0x1A000000),
                  blurRadius: 6,
                  offset: Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Material(
        key: Key(keyName),
        color: bg,
        borderRadius: radius,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: radius,
              border: emphasized
                  ? null
                  : Border.all(
                      color: AppColors.outlineVariant.withValues(alpha: 0.3),
                    ),
            ),
            child: Column(
              children: [
                Text(
                  value,
                  style: Theme.of(context).textTheme.headlineMedium
                      ?.copyWith(color: fg, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: fg,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  softWrap: true,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeActiveOrderCard extends StatelessWidget {
  const _HomeActiveOrderCard({required this.order, required this.onTap});

  final MerchantOrderSummary order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final merchandise = MoneyFormat.dzdOrEmpty(
      order.financial.grossMerchandiseSubtotalMinor,
    );
    final statusLabel = orderListStatusLabel(
      order.status,
      order.fulfillmentStatus,
    );
    final isIncoming = order.fulfillmentStatus == 'PENDING_ACCEPTANCE';
    final isReady = order.fulfillmentStatus == 'READY';
    final radius = BorderRadius.circular(12);
    final ink = isReady ? AppColors.onSurfaceVariant : AppColors.onSurface;

    final content = Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        OrderPublicReferenceLine(
                          reference: order.publicReference,
                          textKey: Key('home-order-ref-${order.id}'),
                        ),
                        StatusBadge(
                          label: statusLabel,
                          tone: isReady
                              ? StatusTone.neutral
                              : fulfillmentTone(
                                  order.fulfillmentStatus,
                                  order.status,
                                ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      order.customerFullName?.isNotEmpty == true
                          ? order.customerFullName!
                          : AppStrings.orderCustomerLabel,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: ink,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (merchandise.isNotEmpty) ...[
                const SizedBox(width: 8),
                Text(
                  merchandise,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: ink,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              key: Key('home-order-cta-${order.id}'),
              onPressed: onTap,
              style: FilledButton.styleFrom(
                minimumSize: Size.fromHeight(isIncoming ? 48 : 40),
                backgroundColor: isIncoming
                    ? AppColors.primary
                    : AppColors.surfaceContainerHigh,
                foregroundColor: isIncoming
                    ? AppColors.onPrimary
                    : AppColors.onSurfaceVariant,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                textStyle: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: Text(
                isIncoming
                    ? AppStrings.homeTreatOrder
                    : AppStrings.homeOpenOrder,
              ),
            ),
          ),
        ],
      ),
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: isIncoming
            ? const [
                BoxShadow(
                  color: Color(0x0D000000),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ]
            : merchantCardShadow,
      ),
      child: Material(
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(
            color: isIncoming
                ? AppColors.outlineVariant
                : AppColors.outlineVariant.withValues(alpha: 0.6),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: Key('home-order-card-${order.id}'),
          onTap: onTap,
          child: isIncoming
              ? IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(width: 6, color: AppColors.primary),
                      Expanded(child: content),
                    ],
                  ),
                )
              : content,
        ),
      ),
    );
  }
}

String _operationalLabel(String status) {
  switch (status.toUpperCase()) {
    case 'ACTIVE':
      return AppStrings.operationalActive;
    case 'INACTIVE':
      return AppStrings.operationalInactive;
    case 'SUSPENDED':
      return AppStrings.operationalSuspended;
    default:
      return status;
  }
}
