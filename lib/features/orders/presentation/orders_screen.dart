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
import 'package:speedygo_merchant_app/features/orders/presentation/order_quick_actions.dart';
import 'package:speedygo_merchant_app/features/orders/presentation/prep_time_clock.dart';
import 'package:speedygo_merchant_app/features/store/application/store_controllers.dart';

class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(ordersListControllerProvider);
    final access = ref.watch(accessControllerProvider);
    final branch = access.selectedBranch;
    final canMutate = merchantRoleCanMutateOrders(access.membership?.role);
    final isOpenNow = ref
        .watch(branchAvailabilityControllerProvider)
        .value
        ?.isOpenNow;
    final unread = ref.watch(notificationsUnreadCountProvider).value ?? 0;
    final counts = ref.watch(homeOrderCountsProvider).value;
    final selected = async.value?.filter ?? MerchantOrderListFilter.incoming;
    final history = selected.isHistory;
    final theme = Theme.of(context);

    Future<void> reloadAll() async {
      await Future.wait([
        ref.read(ordersListControllerProvider.notifier).reload(),
        ref.read(homeOrderCountsProvider.notifier).reload(),
      ]);
    }

    return MerchantScaffold(
      title: AppStrings.tabOrders,
      headerColor: AppColors.surface,
      headerHeight: 64,
      titleStyle: theme.textTheme.titleLarge?.copyWith(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: AppColors.onSurface,
      ),
      subtitleWidget: branch == null
          ? null
          : _BranchOpenSubtitle(name: branch.name, isOpenNow: isOpenNow),
      actions: [
        MerchantBellButton(
          key: const Key('orders-notifications'),
          unread: unread,
          onPressed: () => context.push(AppRoutes.notifications),
        ),
        const SizedBox(width: 4),
      ],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 12),
          _SegmentBar(
            history: history,
            onActive: () {
              if (!history) return;
              ref
                  .read(ordersListControllerProvider.notifier)
                  .setFilter(MerchantOrderListFilter.incoming);
            },
            onHistory: () {
              if (history) return;
              ref
                  .read(ordersListControllerProvider.notifier)
                  .setFilter(MerchantOrderListFilter.completed);
            },
          ),
          const SizedBox(height: 12),
          if (history)
            _HistoryChips(
              selected: selected,
              onSelected: (filter) => ref
                  .read(ordersListControllerProvider.notifier)
                  .setFilter(filter),
            )
          else
            _StatusTabs(
              selected: selected,
              counts: counts,
              onSelected: (filter) => ref
                  .read(ordersListControllerProvider.notifier)
                  .setFilter(filter),
            ),
          const SizedBox(height: 12),
          Expanded(
            child: async.when(
              loading: () => const LoadingBody(),
              error: (e, _) => ErrorBody(
                message: AppStrings.ordersLoadError,
                onRetry: () =>
                    ref.read(ordersListControllerProvider.notifier).reload(),
              ),
              data: (page) {
                if (page.items.isEmpty) {
                  return RefreshIndicator(
                    onRefresh: reloadAll,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        const SizedBox(height: 48),
                        Icon(
                          history ? Icons.history : Icons.receipt_long_outlined,
                          size: 40,
                          color: AppColors.outline,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _ordersEmptyMessage(page.filter),
                          key: const Key('orders-empty'),
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                final rows = history
                    ? _historyRows(page.items)
                    : [for (final o in page.items) _Row.order(o)];
                return RefreshIndicator(
                  onRefresh: reloadAll,
                  child: NotificationListener<ScrollNotification>(
                    onNotification: (n) {
                      if (n.metrics.pixels >= n.metrics.maxScrollExtent - 120 &&
                          page.hasMore &&
                          !page.loadingMore) {
                        ref
                            .read(ordersListControllerProvider.notifier)
                            .loadMore();
                      }
                      return false;
                    },
                    child: ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.only(bottom: 24),
                      itemCount: rows.length + (page.hasMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index >= rows.length) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        final row = rows[index];
                        if (row.day != null) {
                          return Padding(
                            padding: EdgeInsets.only(
                              top: index == 0 ? 4 : 12,
                              bottom: 8,
                            ),
                            child: Text(
                              row.day!.toUpperCase(),
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: AppColors.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.6,
                              ),
                            ),
                          );
                        }
                        final order = row.order!;
                        void open() =>
                            context.push(AppRoutes.orderDetail(order.id));
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: history
                              ? _HistoryOrderCard(order: order, onTap: open)
                              : _OrderListCard(
                                  key: ValueKey('order-list-card-${order.id}'),
                                  order: order,
                                  onTap: open,
                                  canMutate: canMutate,
                                ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _BranchOpenSubtitle extends StatelessWidget {
  const _BranchOpenSubtitle({required this.name, required this.isOpenNow});

  final String name;
  final bool? isOpenNow;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelMedium?.copyWith(
      color: AppColors.onSurfaceVariant,
      fontWeight: FontWeight.w500,
      fontSize: 12,
    );
    return Row(
      key: const Key('orders-branch-context'),
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(
            isOpenNow == null ? name : '$name • ',
            style: style,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (isOpenNow != null) ...[
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: isOpenNow! ? const Color(0xFFB7D15F) : AppColors.error,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            isOpenNow!
                ? AppStrings.availabilityOpen
                : AppStrings.availabilityClosed,
            style: style,
          ),
        ],
      ],
    );
  }
}

class _SegmentBar extends StatelessWidget {
  const _SegmentBar({
    required this.history,
    required this.onActive,
    required this.onHistory,
  });

  final bool history;
  final VoidCallback onActive;
  final VoidCallback onHistory;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('orders-segment-bar'),
      constraints: const BoxConstraints(minHeight: 36),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: _SegmentButton(
              key: const Key('orders-segment-active'),
              label: AppStrings.orderSegmentActive,
              selected: !history,
              onTap: onActive,
            ),
          ),
          Expanded(
            child: _SegmentButton(
              key: const Key('orders-segment-history'),
              label: AppStrings.orderSegmentHistory,
              selected: history,
              onTap: onHistory,
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
    return Material(
      color: selected ? AppColors.primary : Colors.transparent,
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Center(
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: selected
                    ? AppColors.onPrimary
                    : AppColors.onSurfaceVariant,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Reference status tabs: one `surface-container-high` container with a white
/// selected tab; every tab carries its server `total`.
class _StatusTabs extends StatelessWidget {
  const _StatusTabs({
    required this.selected,
    required this.counts,
    required this.onSelected,
  });

  final MerchantOrderListFilter selected;
  final HomeOrderCounts? counts;
  final ValueChanged<MerchantOrderListFilter> onSelected;

  int? _count(MerchantOrderListFilter f) => switch (f) {
    MerchantOrderListFilter.incoming => counts?.incoming,
    MerchantOrderListFilter.accepted => counts?.accepted,
    MerchantOrderListFilter.preparing => counts?.preparing,
    MerchantOrderListFilter.ready => counts?.ready,
    _ => null,
  };

  @override
  Widget build(BuildContext context) {
    final filters = MerchantOrderListFilterX.activeFilters;
    final scroll = MediaQuery.textScalerOf(context).scale(14) > 15.5;
    final tabs = [
      for (final f in filters)
        _StatusTab(
          key: Key('orders-filter-${f.name}'),
          label: f == MerchantOrderListFilter.preparing && !scroll
              ? AppStrings.homeCountPreparing
              : f.label,
          count: _count(f),
          selected: f == selected,
          onTap: () => onSelected(f),
        ),
    ];
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
      ),
      child: scroll
          ? SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: tabs),
            )
          : Row(children: [for (final t in tabs) Expanded(child: t)]),
    );
  }
}

class _StatusTab extends StatelessWidget {
  const _StatusTab({
    super.key,
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int? count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = count == null ? label : '$label ($count)';
    return Semantics(
      selected: selected,
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          constraints: const BoxConstraints(minHeight: 36),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? AppColors.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: selected
                ? const [
                    BoxShadow(
                      color: Color(0x0D000000),
                      blurRadius: 2,
                      offset: Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Center(
            widthFactor: 1,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                text,
                maxLines: 1,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: selected
                      ? AppColors.primary
                      : AppColors.onSurfaceVariant,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HistoryChips extends StatelessWidget {
  const _HistoryChips({required this.selected, required this.onSelected});

  final MerchantOrderListFilter selected;
  final ValueChanged<MerchantOrderListFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final f in MerchantOrderListFilterX.historyFilters)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Material(
                key: Key('orders-filter-${f.name}'),
                color: f == selected
                    ? AppColors.primary
                    : AppColors.surfaceContainerHighest,
                shape: StadiumBorder(
                  side: f == selected
                      ? BorderSide.none
                      : const BorderSide(color: AppColors.outlineVariant),
                ),
                child: InkWell(
                  customBorder: const StadiumBorder(),
                  onTap: () => onSelected(f),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    child: Text(
                      f.label,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontSize: 12,
                        color: f == selected
                            ? AppColors.onPrimary
                            : AppColors.onSurface,
                        fontWeight: f == selected
                            ? FontWeight.w600
                            : FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Row {
  const _Row.order(this.order) : day = null;
  const _Row.day(this.day) : order = null;
  final MerchantOrderSummary? order;
  final String? day;
}

/// Groups loaded history pages by Branch-local day (Aujourd’hui / Hier /
/// dd/MM/yyyy); purely presentational over `createdAt`.
List<_Row> _historyRows(List<MerchantOrderSummary> items) {
  final today = DateTime.now().toUtc().add(kMerchantBranchUtcOffset);
  final todayKey = DateTime.utc(today.year, today.month, today.day);
  final rows = <_Row>[];
  String? lastLabel;
  for (final o in items) {
    final created = parsePrepInstant(o.createdAt)
        ?.add(kMerchantBranchUtcOffset);
    String label;
    if (created == null) {
      label = AppStrings.orderHistoryEarlier;
    } else {
      final key = DateTime.utc(created.year, created.month, created.day);
      final diff = todayKey.difference(key).inDays;
      label = diff == 0
          ? AppStrings.orderHistoryToday
          : diff == 1
          ? AppStrings.orderHistoryYesterday
          : '${key.day.toString().padLeft(2, '0')}/'
                '${key.month.toString().padLeft(2, '0')}/${key.year}';
    }
    if (label != lastLabel) {
      rows.add(_Row.day(label));
      lastLabel = label;
    }
    rows.add(_Row.order(o));
  }
  return rows;
}

/// Reference, customer name and amount. The amount and payment move to their
/// own row when the name would not fit on one line beside them (large text
/// or long names), so the name keeps the full card width.
class _OrderCardHeader extends StatelessWidget {
  const _OrderCardHeader({
    required this.order,
    required this.merchandise,
    required this.isIncoming,
  });

  final MerchantOrderSummary order;
  final String merchandise;
  final bool isIncoming;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = order.customerFullName?.isNotEmpty == true
        ? order.customerFullName!
        : AppStrings.orderCustomerLabel;
    final nameStyle = theme.textTheme.titleMedium?.copyWith(
      fontSize: 18,
      fontWeight: FontWeight.w700,
    );
    final amountStyle = theme.textTheme.labelLarge?.copyWith(
      color: AppColors.primary,
      fontWeight: FontWeight.w700,
    );
    final paymentStyle = theme.textTheme.labelSmall?.copyWith(
      color: AppColors.outline,
      fontSize: 10,
    );
    final payment = orderPaymentLabel(order.payment.method);
    final reference = OrderPublicReferenceLine(
      reference: order.publicReference,
      textKey: Key('order-card-ref-${order.id}'),
      emphasized: true,
    );
    final amount = merchandise.isEmpty
        ? null
        : Text(
            merchandise,
            key: Key('order-card-gms-${order.id}'),
            style: amountStyle,
          );
    final paymentText = Text(payment, style: paymentStyle);

    return LayoutBuilder(
      builder: (context, constraints) {
        final scaler = MediaQuery.textScalerOf(context);
        final direction = Directionality.of(context);
        double widthOf(String text, TextStyle? style) {
          final painter = TextPainter(
            text: TextSpan(text: text, style: style),
            textDirection: direction,
            textScaler: scaler,
            maxLines: 1,
          )..layout();
          final width = painter.width;
          painter.dispose();
          return width;
        }

        final sideWidth = [
          if (merchandise.isNotEmpty) widthOf(merchandise, amountStyle),
          widthOf(payment, paymentStyle),
        ].reduce((a, b) => a > b ? a : b);
        final nameRoom = constraints.maxWidth - sideWidth - 8;
        final stacked = widthOf(name, nameStyle) > nameRoom;

        final nameText = Text(
          name,
          key: Key('order-card-name-${order.id}'),
          style: nameStyle,
          maxLines: stacked ? 3 : 2,
          overflow: TextOverflow.ellipsis,
        );

        if (stacked) {
          return Column(
            key: Key('order-card-header-stacked-${order.id}'),
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              reference,
              const SizedBox(height: 2),
              nameText,
              const SizedBox(height: 4),
              Wrap(
                spacing: 12,
                runSpacing: 2,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [?amount, paymentText],
              ),
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [reference, const SizedBox(height: 2), nameText],
              ),
            ),
            const SizedBox(width: 8),
            Padding(
              padding: EdgeInsets.only(top: isIncoming ? 20 : 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [?amount, paymentText],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _OrderListCard extends StatelessWidget {
  const _OrderListCard({
    super.key,
    required this.order,
    required this.onTap,
    this.canMutate = false,
  });

  final MerchantOrderSummary order;
  final VoidCallback onTap;
  final bool canMutate;

  @override
  Widget build(BuildContext context) {
    final merchandise = MoneyFormat.dzdOrEmpty(
      order.financial.grossMerchandiseSubtotalMinor,
    );
    final fulfillment = order.fulfillmentStatus;
    final isIncoming = fulfillment == 'PENDING_ACCEPTANCE';
    final canQuickAct = canMutate && isIncoming && order.status == 'CREATED';
    final isPreparing = fulfillment == 'PREPARING' || fulfillment == 'ACCEPTED';
    final isReady = fulfillment == 'READY';
    final radius = BorderRadius.circular(16);
    final borderColor = isIncoming
        ? AppColors.primary.withValues(alpha: 0.2)
        : isReady
        ? AppColors.tertiaryFixed
        : AppColors.outlineVariant;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: merchantCardShadow,
      ),
      child: Material(
        color: isReady ? const Color(0xFFFCFEF4) : AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(color: borderColor, width: isIncoming ? 2 : 1),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: Key('order-card-${order.id}'),
          onTap: onTap,
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _OrderCardHeader(
                      order: order,
                      merchandise: merchandise,
                      isIncoming: isIncoming,
                    ),
                    const SizedBox(height: 12),
                    if (isIncoming)
                      _CardBanner(
                        icon: Icons.notifications_active,
                        text: AppStrings.orderListAcceptNow,
                        background: const Color(0x4DD9E2FF),
                        foreground: const Color(0xFF001946),
                        iconColor: AppColors.primary,
                      )
                    else if (isPreparing)
                      _PrepRow(order: order)
                    else if (isReady)
                      _CardBanner(
                        icon: Icons.inventory_2_outlined,
                        text: AppStrings.orderFulfillmentReady,
                        background: AppColors.tertiaryFixed.withValues(
                          alpha: 0.35,
                        ),
                        foreground: AppColors.onTertiaryFixed,
                        iconColor: AppColors.tertiary,
                      ),
                    if (isIncoming) ...[
                      const SizedBox(height: 12),
                      if (canQuickAct)
                        IncomingOrderQuickActions(order: order)
                      else
                        FilledButton(
                          onPressed: onTap,
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(AppStrings.homeTreatOrder),
                        ),
                    ],
                  ],
                ),
              ),
              if (isIncoming)
                PositionedDirectional(
                  top: 0,
                  end: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadiusDirectional.only(
                        bottomStart: Radius.circular(12),
                      ),
                    ),
                    child: Text(
                      AppStrings.orderFulfillmentIncoming.toUpperCase(),
                      style: const TextStyle(
                        color: AppColors.onPrimary,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CardBanner extends StatelessWidget {
  const _CardBanner({
    required this.icon,
    required this.text,
    required this.background,
    required this.foreground,
    required this.iconColor,
  });

  final IconData icon;
  final String text;
  final Color background;
  final Color foreground;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: iconColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.labelLarge
                  ?.copyWith(color: foreground, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

/// Preparing row: server `estimatedReadyAt` (Branch clock) or the derived
/// late flag. Static text, no client countdown.
class _PrepRow extends StatelessWidget {
  const _PrepRow({required this.order});

  final MerchantOrderSummary order;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ready = order.estimatedReadyAt;
    final late = order.isPreparationLate;
    final String? right = late
        ? AppStrings.orderListLate
        : ready == null
        ? null
        : AppStrings.orderListReadyAt(formatPrepClockIso(ready));
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        border: Border.symmetric(
          horizontal: BorderSide(
            color: AppColors.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.restaurant,
            size: 20,
            color: AppColors.primaryContainer,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              orderFulfillmentLabel(order.fulfillmentStatus),
              style: theme.textTheme.labelLarge?.copyWith(
                color: AppColors.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (right != null)
            Text(
              right,
              key: Key('order-card-prep-${order.id}'),
              style: theme.textTheme.labelLarge?.copyWith(
                color: late ? AppColors.error : AppColors.primary,
                fontWeight: FontWeight.w700,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
        ],
      ),
    );
  }
}

class _HistoryOrderCard extends StatelessWidget {
  const _HistoryOrderCard({required this.order, required this.onTap});

  final MerchantOrderSummary order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cancelled = order.status == 'CANCELLED' || order.status == 'FAILED';
    final merchandise = MoneyFormat.dzdOrEmpty(
      order.financial.grossMerchandiseSubtotalMinor,
    );
    final bar = cancelled ? AppColors.error : const Color(0xFF16A34A);
    final radius = BorderRadius.circular(16);
    return Opacity(
      opacity: cancelled ? 0.75 : 1,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: merchantCardShadow,
        ),
        child: Material(
          color: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: radius,
            side: BorderSide(
              color: AppColors.outlineVariant.withValues(alpha: 0.3),
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            key: Key('order-card-${order.id}'),
            onTap: onTap,
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(width: 4, color: bar),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                OrderPublicReferenceLine(
                                  reference: order.publicReference,
                                  textKey: Key('order-card-ref-${order.id}'),
                                  emphasized: !cancelled,
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.schedule,
                                      size: 16,
                                      color: AppColors.onSurfaceVariant,
                                    ),
                                    const SizedBox(width: 4),
                                    Flexible(
                                      child: Text(
                                        formatPrepClockIso(order.createdAt),
                                        style: theme.textTheme.labelLarge
                                            ?.copyWith(
                                              color: AppColors.onSurfaceVariant,
                                              fontWeight: FontWeight.w500,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                                if (order.customerFullName?.isNotEmpty ==
                                    true) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    order.customerFullName!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              if (merchandise.isNotEmpty)
                                Text(
                                  merchandise,
                                  key: Key('order-card-gms-${order.id}'),
                                  style: theme.textTheme.labelLarge?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: cancelled
                                        ? AppColors.outline
                                        : AppColors.onSurface,
                                    decoration: cancelled
                                        ? TextDecoration.lineThrough
                                        : null,
                                  ),
                                ),
                              const SizedBox(height: 6),
                              StatusBadge(
                                label: orderListStatusLabel(
                                  order.status,
                                  order.fulfillmentStatus,
                                ),
                                tone: cancelled
                                    ? StatusTone.error
                                    : StatusTone.success,
                                icon: cancelled
                                    ? Icons.cancel
                                    : Icons.check_circle,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

String _ordersEmptyMessage(MerchantOrderListFilter filter) {
  switch (filter) {
    case MerchantOrderListFilter.incoming:
      return AppStrings.ordersEmptyIncoming;
    case MerchantOrderListFilter.accepted:
      return AppStrings.ordersEmptyAccepted;
    case MerchantOrderListFilter.preparing:
      return AppStrings.ordersEmptyPreparing;
    case MerchantOrderListFilter.ready:
      return AppStrings.ordersEmptyReady;
    case MerchantOrderListFilter.cancelled:
      return AppStrings.ordersEmptyCancelled;
    case MerchantOrderListFilter.completed:
      return AppStrings.ordersEmptyCompleted;
    case MerchantOrderListFilter.failed:
      return AppStrings.ordersEmptyFailed;
  }
}

String orderFulfillmentLabel(String status) {
  switch (status) {
    case 'PENDING_ACCEPTANCE':
      return AppStrings.orderFulfillmentIncoming;
    case 'ACCEPTED':
      return AppStrings.orderFulfillmentAccepted;
    case 'PREPARING':
      return AppStrings.orderFulfillmentPreparing;
    case 'READY':
      return AppStrings.orderFulfillmentReady;
    default:
      return status;
  }
}

/// Prefer order.status when terminal so cancelled rows are not labeled "Nouvelle".
String orderListStatusLabel(String orderStatus, String fulfillmentStatus) {
  if (orderStatus == 'CANCELLED') return AppStrings.orderStatusCancelled;
  if (orderStatus == 'FAILED') return AppStrings.orderStatusFailed;
  if (orderStatus == 'COMPLETED') return AppStrings.orderStatusCompleted;
  return orderFulfillmentLabel(fulfillmentStatus);
}

String orderStatusLabel(String status) {
  switch (status) {
    case 'CREATED':
      return AppStrings.orderStatusCreated;
    case 'CONFIRMED':
      return AppStrings.orderStatusConfirmed;
    case 'ACTIVE':
      return AppStrings.orderStatusActive;
    case 'COMPLETED':
      return AppStrings.orderStatusCompleted;
    case 'CANCELLED':
      return AppStrings.orderStatusCancelled;
    case 'FAILED':
      return AppStrings.orderStatusFailed;
    default:
      return status;
  }
}

String orderPaymentLabel(String method) {
  switch (method) {
    case 'COD':
      return AppStrings.orderPaymentCod;
    case 'ELECTRONIC':
      return AppStrings.orderPaymentElectronic;
    default:
      return method;
  }
}

StatusTone fulfillmentTone(String fulfillment, String orderStatus) {
  if (orderStatus == 'CANCELLED' || orderStatus == 'FAILED') {
    return StatusTone.error;
  }
  switch (fulfillment) {
    case 'PENDING_ACCEPTANCE':
      return StatusTone.fresh;
    case 'ACCEPTED':
    case 'PREPARING':
      return StatusTone.info;
    case 'READY':
      return StatusTone.success;
    default:
      return StatusTone.info;
  }
}
