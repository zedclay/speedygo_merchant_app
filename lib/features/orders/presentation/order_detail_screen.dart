import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:speedygo_merchant_app/app/theme/app_theme.dart';
import 'package:speedygo_merchant_app/core/constants/app_strings.dart';
import 'package:speedygo_merchant_app/core/money/money_format.dart';
import 'package:speedygo_merchant_app/core/navigation/app_routes.dart';
import 'package:speedygo_merchant_app/core/widgets/merchant_primary_button.dart';
import 'package:speedygo_merchant_app/core/widgets/merchant_ui.dart';
import 'package:speedygo_merchant_app/features/access/application/access_controller.dart';
import 'package:speedygo_merchant_app/features/orders/application/orders_controller.dart';
import 'package:speedygo_merchant_app/features/orders/data/order_models.dart';
import 'package:speedygo_merchant_app/features/orders/presentation/mark_ready_confirm_screen.dart';
import 'package:speedygo_merchant_app/features/orders/presentation/orders_screen.dart';
import 'package:speedygo_merchant_app/features/orders/presentation/order_public_reference.dart';
import 'package:speedygo_merchant_app/features/orders/presentation/prep_time_clock.dart';
import 'package:speedygo_merchant_app/features/orders/presentation/preparation_time_widgets.dart';
import 'package:speedygo_merchant_app/features/orders/presentation/delivery_impact_card.dart';
import 'package:speedygo_merchant_app/features/orders/presentation/reject_reason_sheet.dart';
import 'package:speedygo_merchant_app/features/support/presentation/order_support_screen.dart';

class OrderDetailScreen extends ConsumerStatefulWidget {
  const OrderDetailScreen({super.key, required this.orderId});

  final String orderId;

  @override
  ConsumerState<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends ConsumerState<OrderDetailScreen> {
  final _rejectController = TextEditingController();

  @override
  void dispose() {
    _rejectController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(orderDetailControllerProvider(widget.orderId));
    final role = ref.watch(accessControllerProvider).membership?.role ?? '';
    final title = async.value == null
        ? AppStrings.orderDetailTitle
        : _detailTitle(async.value!.order);
    final theme = Theme.of(context);
    final titleStyle =
        theme.appBarTheme.titleTextStyle ?? theme.textTheme.titleLarge;
    final titleLines = appBarTitleLines(
      context,
      title,
      titleStyle,
      hasLeading: true,
      actionCount: 1,
    );

    return MerchantSnackBarScope(
      child: Scaffold(
        key: const Key('order-detail'),
        backgroundColor: AppColors.background,
        appBar: AppBar(
          toolbarHeight: titleLines > 1
              ? appBarWrappedHeight(context, titleStyle, lines: titleLines)
              : null,
          title: Text(
            title,
            maxLines: titleLines,
            overflow: TextOverflow.ellipsis,
          ),
          leading: IconButton(
            key: const Key('order-detail-back'),
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/app/orders');
              }
            },
          ),
          actions: [
            IconButton(
              key: const Key('order-detail-refresh'),
              tooltip: AppStrings.refresh,
              onPressed: () => ref
                  .read(orderDetailControllerProvider(widget.orderId).notifier)
                  .reload(),
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        body: async.when(
          loading: () => const LoadingBody(),
          error: (e, _) => ErrorBody(
            message: AppStrings.orderDetailLoadError,
            onRetry: () => ref
                .read(orderDetailControllerProvider(widget.orderId).notifier)
                .reload(),
          ),
          data: (state) {
            final order = state.order;
            final actions = merchantActionsFor(
              orderStatus: order.status,
              fulfillmentStatus: order.fulfillmentStatus,
              role: role,
            );
            final isCancelled = order.status == 'CANCELLED';
            final isPreparing =
                order.fulfillmentStatus == 'ACCEPTED' ||
                order.fulfillmentStatus == 'PREPARING';
            final isReady =
                order.fulfillmentStatus == 'READY' && order.status == 'ACTIVE';
            final isCompleted = order.status == 'COMPLETED';
            final cancelledLayout = isCancelled && order.cancellation != null;
            final isIncoming =
                order.status == 'CREATED' &&
                order.fulfillmentStatus == 'PENDING_ACCEPTANCE';
            final canSupport = merchantRoleCanContactSupport(role);
            final canUpdatePrep =
                isPreparing &&
                !isCancelled &&
                order.estimatedReadyAt != null &&
                merchantRoleCanMutateOrders(role);
            final footerSupport =
                canSupport &&
                ((isPreparing && !isCancelled && actions.isNotEmpty) ||
                    isReady ||
                    isCompleted);
            final timeline = order.statusHistory.isEmpty
                ? null
                : _TimelineCard(events: order.statusHistory);
            final estimate = parsePrepInstant(order.estimatedReadyAt);
            final isLate =
                isPreparing &&
                !isCancelled &&
                estimate != null &&
                (order.isPreparationLate ||
                    estimate.isBefore(DateTime.now().toUtc()));
            final countdown = isPreparing && order.estimatedReadyAt != null
                ? PreparationCountdownBanner(
                    estimatedReadyAt: order.estimatedReadyAt,
                    originalEstimatedReadyAt: order.originalEstimatedReadyAt,
                    isPreparationLate: order.isPreparationLate,
                    delayMinutes: order.delayMinutes,
                  )
                : null;
            final deliveryImpact = isLate && order.deliveryImpact != null
                ? DeliveryImpactCard(
                    deliveryImpact: order.deliveryImpact!,
                    latestRevisionReason:
                        order.latestPreparationRevision?.reason,
                  )
                : null;

            return Column(
              children: [
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () => ref
                        .read(
                          orderDetailControllerProvider(widget.orderId)
                              .notifier,
                        )
                        .reload(),
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      children: [
                        if (state.actionError != null) ...[
                          MerchantCard(
                            child: Text(
                              state.actionError!,
                              key: const Key('order-action-error'),
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: AppColors.error),
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                        if (cancelledLayout) ...[
                          _CancelledHero(order: order),
                          const SizedBox(height: 16),
                          _CancellationCard(
                            cancellation: order.cancellation!,
                            history: order.statusHistory,
                          ),
                          const SizedBox(height: 12),
                          _CancelledSummaryCard(order: order),
                          const SizedBox(height: 16),
                          _CancelledActions(
                            orderId: order.id,
                            canSupport: canSupport,
                            onHistory: () {
                              ref
                                  .read(ordersListControllerProvider.notifier)
                                  .setFilter(MerchantOrderListFilter.cancelled);
                              context.go(AppRoutes.orders);
                            },
                          ),
                        ] else if (isReady) ...[
                          _ReadyStatusSection(
                            delivery: state.delivery,
                            readySince: _readySince(order),
                          ),
                          if (state.delivery?.assignedDriver != null) ...[
                            const SizedBox(height: 12),
                            _AssignedDriverCard(
                              driver: state.delivery!.assignedDriver!,
                            ),
                          ],
                          if (state.delivery?.status == 'AT_PICKUP') ...[
                            const SizedBox(height: 12),
                            _PickupHandoffSection(
                              orderId: order.id,
                              handoff: state.pickupHandoff,
                              loading: state.pickupHandoffLoading,
                              regenerating: state.pickupHandoffRegenerating,
                              error: state.pickupHandoffError,
                              onRetry: () => ref
                                  .read(
                                    orderDetailControllerProvider(widget.orderId)
                                        .notifier,
                                  )
                                  .reloadPickupHandoff(),
                              onRegenerate: () => ref
                                  .read(
                                    orderDetailControllerProvider(widget.orderId)
                                        .notifier,
                                  )
                                  .regeneratePickupHandoff(),
                            ),
                          ],
                          const SizedBox(height: 12),
                          _ReadySummaryCard(order: order),
                        ] else if (isCompleted) ...[
                          _CompletedStatusCard(
                            order: order,
                            delivery: state.delivery,
                          ),
                          if (timeline != null) ...[
                            const SizedBox(height: 12),
                            timeline,
                          ],
                        ] else if (isLate) ...[
                          countdown!,
                          if (deliveryImpact != null) ...[
                            const SizedBox(height: 12),
                            deliveryImpact,
                          ],
                          const SizedBox(height: 12),
                          _IdentityBlock(order: order, compact: true),
                        ] else ...[
                          _IdentityBlock(order: order),
                          if (order.cancellation != null) ...[
                            const SizedBox(height: 12),
                            _CancellationCard(
                              cancellation: order.cancellation!,
                              history: order.statusHistory,
                            ),
                          ],
                        ],
                        if (countdown != null && !isLate) ...[
                          const SizedBox(height: 12),
                          countdown,
                        ],
                        if (!cancelledLayout) ...[
                          const SizedBox(height: 12),
                          _ItemsCard(order: order, emphasizePrep: isPreparing),
                          const SizedBox(height: 12),
                          _AddressCard(order: order),
                        ],
                        const SizedBox(height: 12),
                        _FinanceCard(order: order),
                        if (state.delivery != null && !isReady) ...[
                          const SizedBox(height: 12),
                          _DeliveryCard(delivery: state.delivery!),
                        ],
                        if (timeline != null && !isCompleted) ...[
                          const SizedBox(height: 12),
                          timeline,
                        ],
                        if (canSupport &&
                            !footerSupport &&
                            !cancelledLayout &&
                            !isIncoming) ...[
                          const SizedBox(height: 16),
                          _SupportButton(orderId: order.id),
                        ],
                        SizedBox(height: actions.isEmpty ? 8 : 28),
                      ],
                    ),
                  ),
                ),
                if (isCancelled && actions.isEmpty)
                  MerchantStickyBar(
                    child: FilledButton.icon(
                      key: const Key('order-cancelled-ack'),
                      onPressed: () {
                        if (context.canPop()) {
                          context.pop();
                        } else {
                          context.go(AppRoutes.orders);
                        }
                      },
                      icon: const Icon(Icons.check),
                      label: const Text(AppStrings.orderCancelledAck),
                    ),
                  ),
                if (isCompleted && footerSupport)
                  MerchantStickyBar(
                    child: MerchantPrimaryButton(
                      key: const Key('order-support'),
                      label: AppStrings.supportContact,
                      icon: Icons.support_agent,
                      leadingIcon: true,
                      onPressed: () =>
                          context.push(AppRoutes.orderSupport(order.id)),
                    ),
                  ),
                if (isReady && actions.isEmpty)
                  MerchantStickyBar(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (state.delivery?.assignedDriver?.canCall ==
                            true) ...[
                          MerchantPrimaryButton(
                            key: const Key('order-driver-call'),
                            label: AppStrings.orderDriverCall,
                            icon: Icons.call,
                            leadingIcon: true,
                            onPressed: () => _launchDriverCall(
                              state.delivery!.assignedDriver!.contactPhone!,
                            ),
                          ),
                        ] else ...[
                          MerchantPrimaryButton(
                            key: const Key('order-ready-refresh'),
                            label: AppStrings.refresh,
                            icon: Icons.refresh,
                            leadingIcon: true,
                            onPressed: () => ref
                                .read(
                                  orderDetailControllerProvider(widget.orderId)
                                      .notifier,
                                )
                                .reload(),
                          ),
                        ],
                        if (footerSupport) ...[
                          const SizedBox(height: 8),
                          _SupportButton(orderId: order.id),
                        ],
                      ],
                    ),
                  ),
                if (actions.isNotEmpty)
                  _StickyActions(
                    actions: actions,
                    mutating: state.mutating,
                    onUpdatePrep: canUpdatePrep && !state.mutating
                        ? () => _showUpdatePrepSheet(context, order)
                        : null,
                    showUpdatePrep: canUpdatePrep,
                    supportOrderId: footerSupport ? order.id : null,
                    onAccept: () => _acceptWithPrep(context, order),
                    onReject: () => _showRejectSheet(context),
                    onStartPrep: () => ref
                        .read(
                          orderDetailControllerProvider(widget.orderId)
                              .notifier,
                        )
                        .startPreparation(),
                    onMarkReady: () => _confirmAndMarkReady(context, order),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  String? _readySince(MerchantOrderDetail order) {
    for (final e in order.statusHistory.reversed) {
      if (e.eventType == 'ORDER_READY') return e.occurredAt;
    }
    return null;
  }

  Future<void> _confirmAndMarkReady(
    BuildContext context,
    MerchantOrderDetail order,
  ) async {
    final confirmed = await confirmMarkReady(context, order);
    if (!confirmed || !mounted) return;
    await ref
        .read(orderDetailControllerProvider(widget.orderId).notifier)
        .markReady();
  }

  Future<void> _acceptWithPrep(
    BuildContext context,
    MerchantOrderDetail order,
  ) async {
    final minutes = await showAcceptPreparationSheet(
      context,
      publicReference: order.publicReference,
      itemCount: order.items.fold<int>(0, (sum, i) => sum + i.quantity),
      customerName: order.customerFullName,
      merchandise: MoneyFormat.dzdOrEmpty(
        order.financial.grossMerchandiseSubtotalMinor,
      ).nullIfEmpty,
      address: order.deliveryAddress.addressText,
      branchName: ref.read(accessControllerProvider).selectedBranch?.name,
    );
    if (minutes == null || !mounted) return;
    await ref
        .read(orderDetailControllerProvider(widget.orderId).notifier)
        .accept(preparationMinutes: minutes);
  }

  Future<void> _showUpdatePrepSheet(
    BuildContext context,
    MerchantOrderDetail order,
  ) async {
    final result = await showUpdatePreparationSheet(
      context,
      estimatedReadyAt: order.estimatedReadyAt,
      originalEstimatedReadyAt: order.originalEstimatedReadyAt,
      publicReference: order.publicReference,
      customerName: order.customerFullName,
      isLate: order.isPreparationLate,
    );
    if (result == null || !mounted) return;
    await ref
        .read(orderDetailControllerProvider(widget.orderId).notifier)
        .updatePreparationEstimate(
          addMinutes: result.addMinutes,
          reason: result.reason,
        );
  }

  Future<void> _showRejectSheet(BuildContext context) async {
    final result = await showRejectReasonSheet(
      context,
      controller: _rejectController,
    );
    if (result == null || result.reason.isEmpty || !mounted) return;
    await ref
        .read(orderDetailControllerProvider(widget.orderId).notifier)
        .reject(result.reason, reasonCode: result.reasonCode);
    final state = ref.read(orderDetailControllerProvider(widget.orderId)).value;
    final stillIncoming =
        state != null &&
        state.order.status == 'CREATED' &&
        state.order.fulfillmentStatus == 'PENDING_ACCEPTANCE';
    if (state != null && state.actionError == null && !stillIncoming) {
      _rejectController.clear();
    }
  }
}

String _detailTitle(MerchantOrderDetail order) {
  if (order.status == 'CANCELLED') return AppStrings.orderDetailCancelledTitle;
  if (order.status == 'CREATED' &&
      order.fulfillmentStatus == 'PENDING_ACCEPTANCE') {
    return AppStrings.orderIncomingBanner;
  }
  return AppStrings.orderDetailsTitle;
}

/// Reference identity block (`primary-container`): status chip, customer,
/// reference, received time and payment method.
class _IdentityBlock extends StatelessWidget {
  const _IdentityBlock({required this.order, this.compact = false});
  final MerchantOrderDetail order;

  /// Late preparation (`delayed_order_french`): the delay card leads and the
  /// customer and payment are a secondary, compact card.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final incoming =
        order.fulfillmentStatus == 'PENDING_ACCEPTANCE' &&
        order.status != 'CANCELLED';
    final label = orderListStatusLabel(order.status, order.fulfillmentStatus);
    final customer = order.customerFullName?.isNotEmpty == true
        ? order.customerFullName!
        : AppStrings.orderCustomerLabel;
    if (compact) {
      final muted = theme.textTheme.bodyMedium?.copyWith(
        color: AppColors.onSurfaceVariant,
      );
      return MerchantCard(
        key: const Key('order-identity-block'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: OrderPublicReferenceLine(
                    reference: order.publicReference,
                    textKey: const Key('order-detail-ref'),
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 8),
                StatusBadge(label: label, tone: StatusTone.neutral),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.person_outline,
                  size: 20,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    customer,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${AppStrings.orderReceivedAtLabel} '
              '${formatPrepClockIso(order.createdAt)} · '
              '${orderPaymentLabel(order.payment.method)}',
              key: const Key('order-identity-compact-meta'),
              style: muted,
            ),
          ],
        ),
      );
    }
    return Container(
      key: const Key('order-identity-block'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer,
        borderRadius: BorderRadius.circular(16),
        boxShadow: merchantCardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: OrderPublicReferenceLine(
                  reference: order.publicReference,
                  textKey: const Key('order-detail-ref'),
                  color: AppColors.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: incoming
                      ? AppColors.tertiaryFixed
                      : AppColors.onPrimary.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  label.toUpperCase(),
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: incoming
                        ? AppColors.onTertiaryFixed
                        : AppColors.onPrimary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            order.customerFullName?.isNotEmpty == true
                ? order.customerFullName!
                : AppStrings.orderCustomerLabel,
            style: theme.textTheme.headlineMedium?.copyWith(
              color: AppColors.onPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _IdentityTile(
                  icon: Icons.schedule,
                  label: AppStrings.orderReceivedAtLabel,
                  value: formatPrepClockIso(order.createdAt),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _IdentityTile(
                  icon: Icons.payments_outlined,
                  label: AppStrings.orderPaymentLabel,
                  value: orderPaymentLabel(order.payment.method),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _IdentityTile extends StatelessWidget {
  const _IdentityTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.onPrimary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.onPrimaryContainer),
          const SizedBox(height: 6),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: AppColors.onPrimaryContainer,
            ),
          ),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              color: AppColors.onPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// Cancelled hero: icon circle, "Annulée", compact reference.
class _CancelledHero extends StatelessWidget {
  const _CancelledHero({required this.order});
  final MerchantOrderDetail order;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              color: AppColors.errorContainer,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.cancel, size: 36, color: AppColors.error),
          ),
          const SizedBox(height: 12),
          Text(
            AppStrings.orderStatusCancelled,
            style: theme.textTheme.headlineLarge?.copyWith(
              color: AppColors.error,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            AppStrings.orderCancelledHeroBody,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _CancelledSummaryCard extends StatelessWidget {
  const _CancelledSummaryCard({required this.order});
  final MerchantOrderDetail order;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = order.customerFullName?.isNotEmpty == true
        ? order.customerFullName!
        : AppStrings.orderCustomerLabel;
    final count = order.items.fold<int>(0, (sum, i) => sum + i.quantity);
    final merchandise = MoneyFormat.dzdOrEmpty(
      order.financial.grossMerchandiseSubtotalMinor,
    );
    return MerchantCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.orderSummaryTitle,
            style: theme.textTheme.labelLarge?.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _Initials(name: name),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    OrderPublicReferenceLine(
                      reference: order.publicReference,
                      textKey: const Key('order-detail-ref'),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _SummaryRow(
            label: AppStrings.orderItemsTitle,
            value: _itemsPreview(order, count),
          ),
          if (merchandise.isNotEmpty) ...[
            const SizedBox(height: 8),
            _SummaryRow(
              label: AppStrings.orderFinanceGms,
              value: merchandise,
              emphasize: true,
            ),
          ],
        ],
      ),
    );
  }
}

String _itemsPreview(MerchantOrderDetail order, int count) {
  final names = order.items.map((i) => i.productNameSnapshot).toList();
  if (names.isEmpty) return '$count';
  final shown = names.take(2).join(', ');
  return names.length > 2 ? '$count ($shown…)' : '$count ($shown)';
}

class _CancelledActions extends StatelessWidget {
  const _CancelledActions({
    required this.orderId,
    required this.canSupport,
    required this.onHistory,
  });

  final String orderId;
  final bool canSupport;
  final VoidCallback onHistory;

  @override
  Widget build(BuildContext context) {
    final style = OutlinedButton.styleFrom(
      minimumSize: const Size.fromHeight(48),
      foregroundColor: AppColors.primary,
      side: const BorderSide(color: AppColors.outline),
      padding: const EdgeInsets.symmetric(horizontal: 8),
    );
    final history = OutlinedButton.icon(
      key: const Key('order-cancelled-history'),
      onPressed: onHistory,
      style: style,
      icon: const Icon(Icons.history, size: 20),
      label: const Text(AppStrings.orderViewHistory),
    );
    if (!canSupport) return history;
    final support = OutlinedButton.icon(
      key: const Key('order-support'),
      onPressed: () => context.push(AppRoutes.orderSupport(orderId)),
      style: style,
      icon: const Icon(Icons.support_agent, size: 20),
      label: const Text(AppStrings.supportContact),
    );
    if (MediaQuery.textScalerOf(context).scale(1) >= 1.25) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [support, const SizedBox(height: 8), history],
      );
    }
    return Row(
      children: [
        Expanded(child: support),
        const SizedBox(width: 12),
        Expanded(child: history),
      ],
    );
  }
}

class _CompletedStatusCard extends StatelessWidget {
  const _CompletedStatusCard({required this.order, this.delivery});

  final MerchantOrderDetail order;
  final MerchantDeliverySummary? delivery;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final deliveredAt = delivery?.deliveredAt;
    String? completedAt;
    for (final e in order.statusHistory.reversed) {
      if (e.eventType == 'ORDER_COMPLETED') {
        completedAt = e.occurredAt;
        break;
      }
    }
    final caption = deliveredAt != null
        ? AppStrings.orderDeliveredOn(_formatBranchDateTime(deliveredAt))
        : completedAt != null
        ? AppStrings.orderCompletedOn(_formatBranchDateTime(completedAt))
        : null;
    final delivered = delivery?.status == 'DELIVERED';
    final colors = statusToneColors(StatusTone.success);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(
              '${AppStrings.orderReferenceLabel.toUpperCase()} : ',
              style: theme.textTheme.labelMedium?.copyWith(
                color: AppColors.onSurfaceVariant,
                letterSpacing: 0.5,
              ),
            ),
            Flexible(
              child: OrderPublicReferenceLine(
                reference: order.publicReference,
                textKey: const Key('order-detail-ref'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        MerchantCard(
          key: const Key('order-completed-status'),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.orderCurrentStatus,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (caption != null)
                      Text(
                        caption,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: colors.$1,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: colors.$2.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      size: 16,
                      color: colors.$2,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      delivered
                          ? AppStrings.deliveryDelivered
                          : AppStrings.orderStatusCompleted,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: colors.$2,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

String _formatBranchDateTime(String iso) {
  final dt = parsePrepInstant(iso)?.add(kMerchantBranchUtcOffset);
  if (dt == null) return iso;
  String two(int v) => v.toString().padLeft(2, '0');
  return '${two(dt.day)}/${two(dt.month)}, ${two(dt.hour)}:${two(dt.minute)}';
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  final String label;
  final String value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final labelText = Text(
      label,
      style: theme.textTheme.bodyMedium?.copyWith(
        color: AppColors.onSurfaceVariant,
      ),
    );
    final valueText = Text(
      value,
      textAlign: TextAlign.end,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: emphasize
          ? theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)
          : theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
    );
    final stacked = MediaQuery.textScalerOf(context).scale(1) >= 1.25;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
      ),
      child: stacked
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [labelText, const SizedBox(height: 4), valueText],
            )
          : Row(
              children: [
                Expanded(flex: 2, child: labelText),
                const SizedBox(width: 12),
                Flexible(flex: 3, child: valueText),
              ],
            ),
    );
  }
}

class _Initials extends StatelessWidget {
  const _Initials({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    final initials = parts.take(2).map((p) => p[0].toUpperCase()).join();
    return Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainer,
        shape: BoxShape.circle,
      ),
      child: Text(
        initials,
        style: Theme.of(context).textTheme.labelLarge
            ?.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700),
      ),
    );
  }
}

/// Single ready status block (reference-inspired). Does not invent driver
/// search from delivery presence alone — checks [MerchantDeliverySummary.status].
class _ReadyStatusSection extends StatelessWidget {
  const _ReadyStatusSection({this.delivery, this.readySince});
  final MerchantDeliverySummary? delivery;
  final String? readySince;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = delivery?.status;
    final searching = status == 'SEARCHING_DRIVER';
    final assigned = status == 'DRIVER_ASSIGNED' || status == 'TO_PICKUP';
    final atPickup = status == 'AT_PICKUP';

    final (Key titleKey, String title, IconData icon) = searching
        ? (
            const Key('order-ready-searching'),
            AppStrings.deliverySearching,
            Icons.two_wheeler,
          )
        : assigned
        ? (
            const Key('order-ready-assigned'),
            status == 'TO_PICKUP'
                ? AppStrings.deliveryToPickup
                : AppStrings.orderDriverAssigned,
            Icons.two_wheeler,
          )
        : atPickup
        ? (
            const Key('order-ready-at-pickup'),
            AppStrings.deliveryAtPickup,
            Icons.storefront,
          )
        : (
            const Key('order-ready-waiting'),
            AppStrings.orderReadyWaitingDelivery,
            Icons.hourglass_top,
          );
    final searchStarted = searching ? delivery?.driverSearchStartedAt : null;

    return Column(
      key: const Key('order-ready-status'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.tertiaryFixed,
              borderRadius: BorderRadius.circular(999),
              boxShadow: merchantCardShadow,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.check_circle,
                  size: 20,
                  color: AppColors.onTertiaryFixed,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    AppStrings.orderReadyBanner,
                    key: const Key('order-ready-banner'),
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: AppColors.onTertiaryFixed,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (readySince != null) ...[
          const SizedBox(height: 6),
          Text(
            AppStrings.orderReadySince(formatPrepClockIso(readySince)),
            key: const Key('order-ready-since'),
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
        const SizedBox(height: 16),
        Container(
          constraints: const BoxConstraints(minHeight: 200),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: AppColors.onPrimary, size: 32),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                key: titleKey,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (searchStarted != null) ...[
                const SizedBox(height: 6),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.schedule,
                      size: 16,
                      color: AppColors.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        AppStrings.orderDriverSearchStartedAt(
                          formatPrepClockIso(searchStarted),
                        ),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _ReadySummaryCard extends StatelessWidget {
  const _ReadySummaryCard({required this.order});
  final MerchantOrderDetail order;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = order.customerFullName?.isNotEmpty == true
        ? order.customerFullName!
        : AppStrings.orderCustomerLabel;
    return MerchantCard(
      child: Row(
        children: [
          _Initials(name: name),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                OrderPublicReferenceLine(
                  reference: order.publicReference,
                  textKey: const Key('order-detail-ref'),
                ),
                Text(
                  orderPaymentLabel(order.payment.method),
                  style: theme.textTheme.bodySmall?.copyWith(
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

class _ItemsCard extends StatelessWidget {
  const _ItemsCard({required this.order, this.emphasizePrep = false});
  final MerchantOrderDetail order;
  final bool emphasizePrep;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = emphasizePrep
        ? AppStrings.orderItemsToPrepareTitle
        : AppStrings.orderItemsTitle;
    return MerchantCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.restaurant_menu,
                size: 20,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '$title (${order.items.length})',
                  style: theme.textTheme.titleMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < order.items.length; i++) ...[
            if (i > 0)
              Divider(
                height: 20,
                color: AppColors.outlineVariant.withValues(alpha: 0.4),
              ),
            _ItemRow(item: order.items[i]),
          ],
        ],
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({required this.item});
  final MerchantOrderItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          constraints: const BoxConstraints(minWidth: 32),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.surfaceContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '${item.quantity}×',
            style: theme.textTheme.labelLarge?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.productNameSnapshot, style: theme.textTheme.titleSmall),
              for (final opt in item.options)
                Text(
                  '· ${opt.optionNameSnapshot}'
                  '${MoneyFormat.dzdOrEmpty(opt.additionalPriceMinor).isEmpty ? '' : ' (+${MoneyFormat.dzdOrEmpty(opt.additionalPriceMinor)})'}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          MoneyFormat.dzdOrEmpty(item.lineTotalMinor),
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _AddressCard extends StatelessWidget {
  const _AddressCard({required this.order});
  final MerchantOrderDetail order;

  @override
  Widget build(BuildContext context) {
    final addr = order.deliveryAddress;
    if (addr.addressText.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return MerchantCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const MerchantIconCircle(icon: Icons.location_on_outlined),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.orderDeliveryAddress,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(addr.addressText, style: theme.textTheme.bodyMedium),
                if (addr.instructions != null &&
                    addr.instructions!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    addr.instructions!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FinanceCard extends StatelessWidget {
  const _FinanceCard({required this.order});
  final MerchantOrderDetail order;

  @override
  Widget build(BuildContext context) {
    final f = order.financial;
    final theme = Theme.of(context);
    final cancelled = order.status == 'CANCELLED';
    final commission = MoneyFormat.dzdDeduction(
      f.merchantCommissionAmountMinor,
    );
    return MerchantCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.account_balance_wallet_outlined,
                size: 20,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  AppStrings.orderFinanceTitle,
                  style: theme.textTheme.titleMedium,
                ),
              ),
            ],
          ),
          if (cancelled) ...[
            const SizedBox(height: 8),
            Text(
              AppStrings.orderFinanceNetCancelledNote,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: 12),
          _FinanceRow(
            label: AppStrings.orderFinanceGms,
            value: _moneyOrDash(f.grossMerchandiseSubtotalMinor),
          ),
          if (order.financeRestricted)
            Padding(
              key: const Key('order-finance-restricted'),
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                AppStrings.orderFinanceRestricted,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            )
          else ...[
            if (f.merchantDiscountMinor != null &&
                f.merchantDiscountMinor != '0')
              _FinanceRow(
                label: AppStrings.orderFinanceDiscount,
                value: _moneyOrDash(f.merchantDiscountMinor),
              ),
            _FinanceRow(
              label: f.merchantCommissionRateBps == null
                  ? AppStrings.orderFinanceCommissionUnavailable
                  : AppStrings.orderFinanceCommission(
                      _formatBpsPercent(f.merchantCommissionRateBps!),
                    ),
              value: commission.isEmpty
                  ? AppStrings.valueUnavailable
                  : commission,
              valueColor: commission.isEmpty ? null : AppColors.error,
            ),
            Divider(
              height: 16,
              color: AppColors.outlineVariant.withValues(alpha: 0.5),
            ),
            _FinanceRow(
              label: AppStrings.orderFinanceNet,
              value: _moneyOrDash(f.merchantNetAmountMinor),
              emphasize: true,
            ),
          ],
          const SizedBox(height: 8),
          _FinanceRow(
            label: AppStrings.orderFinanceDeliveryFeeNote,
            value: _moneyOrDash(f.deliveryFeeMinor),
          ),
          Text(
            AppStrings.orderFinanceDeliveryFeeDisclaimer,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.payments_outlined,
                  size: 16,
                  color: AppColors.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    AppStrings.orderPaymentMethod(
                      orderPaymentLabel(order.payment.method),
                    ),
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: AppColors.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
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

class _FinanceRow extends StatelessWidget {
  const _FinanceRow({
    required this.label,
    required this.value,
    this.emphasize = false,
    this.valueColor,
  });

  final String label;
  final String value;
  final bool emphasize;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final style = emphasize
        ? Theme.of(context).textTheme.titleLarge
              ?.copyWith(fontWeight: FontWeight.w700, color: AppColors.primary)
        : Theme.of(context).textTheme.bodyMedium;
    final valueText = Text(value, style: style?.copyWith(color: valueColor));
    if (emphasize && MediaQuery.textScalerOf(context).scale(1) >= 1.25) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(label, style: style),
            Align(alignment: Alignment.centerRight, child: valueText),
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          valueText,
        ],
      ),
    );
  }
}

class _CancellationCard extends StatelessWidget {
  const _CancellationCard({required this.cancellation, required this.history});
  final MerchantOrderCancellation cancellation;
  final List<MerchantOrderStatusEvent> history;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final byCustomer = history.any((e) => e.eventType == 'CUSTOMER_CANCELLED');
    final byMerchant = history.any((e) => e.eventType == 'MERCHANT_REJECTED');
    final actor = byCustomer
        ? AppStrings.orderCancelledByCustomer
        : byMerchant
        ? AppStrings.orderRejectedByMerchant
        : AppStrings.orderStatusCancelled;
    return Container(
      key: const Key('order-cancellation-card'),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.errorContainer.withValues(alpha: 0.6),
        ),
        boxShadow: merchantCardShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 4, color: AppColors.error),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          byCustomer
                              ? Icons.person_remove_outlined
                              : Icons.storefront_outlined,
                          color: AppColors.error,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                actor,
                                key: const Key('order-cancellation-actor'),
                                style: theme.textTheme.labelLarge,
                              ),
                              Text(
                                AppStrings.orderCancelledAt(
                                  _formatIso(cancellation.cancelledAt),
                                ),
                                key: const Key('order-cancellation-at'),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: AppColors.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: AppColors.onSurfaceVariant,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppStrings.orderReasonLabel,
                                style: theme.textTheme.labelLarge,
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.errorContainer.withValues(
                                    alpha: 0.4,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  cancellation.reason,
                                  key: const Key('order-cancellation-reason'),
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: AppColors.error,
                                  ),
                                ),
                              ),
                            ],
                          ),
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
    );
  }
}

class _DeliveryCard extends StatelessWidget {
  const _DeliveryCard({required this.delivery});
  final MerchantDeliverySummary delivery;

  @override
  Widget build(BuildContext context) {
    final driver = delivery.assignedDriver;
    if (driver != null) {
      return _AssignedDriverCard(driver: driver);
    }
    return _DeliveryStatusCard(delivery: delivery);
  }
}

class _DeliveryStatusCard extends StatelessWidget {
  const _DeliveryStatusCard({required this.delivery});
  final MerchantDeliverySummary delivery;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return MerchantCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const MerchantIconCircle(icon: Icons.two_wheeler),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.orderDeliveryStatusTitle,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 6),
                StatusBadge(
                  label: merchantDeliveryStatusLabel(delivery.status),
                  tone:
                      delivery.status == 'FAILED' ||
                          delivery.status == 'CANCELLED'
                      ? StatusTone.error
                      : delivery.status == 'DELIVERED'
                      ? StatusTone.success
                      : StatusTone.info,
                  pill: true,
                ),
                if (delivery.driverSearchStartedAt != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    AppStrings.orderDriverSearchStarted(
                      _formatIso(delivery.driverSearchStartedAt!),
                    ),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
                if (delivery.estimatedArrivalAt != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    AppStrings.orderDriverEtaEstimate(
                      _formatIso(delivery.estimatedArrivalAt!),
                    ),
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AssignedDriverCard extends StatelessWidget {
  const _AssignedDriverCard({required this.driver});
  final AssignedDriverSummary driver;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final vehicleLine = _vehicleLine(driver.vehicle);
    final eta = driver.estimatedArrivalAt;
    final statusLabel = merchantDeliveryStatusLabel(driver.deliveryStatus);
    return MerchantCard(
      key: const Key('order-assigned-driver'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Always stack identity + status so long French labels and text
          // scale 1.35 never overflow a side-by-side Row.
          _AssignedDriverIdentity(
            driver: driver,
            vehicleLine: vehicleLine,
          ),
          const SizedBox(height: 12),
          _AssignedDriverStatusBlock(statusLabel: statusLabel),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.surfaceContainer),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const MerchantIconCircle(icon: Icons.navigation, size: 36),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.orderDriverEtaLabel.toUpperCase(),
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: AppColors.onSurfaceVariant,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (eta != null)
                        Text(
                          AppStrings.orderDriverEtaEstimate(_formatIso(eta)),
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        )
                      else
                        Text(
                          AppStrings.orderDriverEtaUnavailable,
                          key: const Key('order-assigned-driver-eta-unavailable'),
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (!driver.canCall) ...[
            const SizedBox(height: 8),
            Text(
              AppStrings.orderDriverContactUnavailable,
              key: const Key('order-driver-call-unavailable'),
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

class _AssignedDriverIdentity extends StatelessWidget {
  const _AssignedDriverIdentity({
    required this.driver,
    required this.vehicleLine,
  });

  final AssignedDriverSummary driver;
  final String? vehicleLine;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Initials(name: driver.displayName),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                driver.displayName,
                key: const Key('order-assigned-driver-name'),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (vehicleLine != null) ...[
                const SizedBox(height: 4),
                Text(
                  vehicleLine!,
                  key: const Key('order-assigned-driver-vehicle'),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _AssignedDriverStatusBlock extends StatelessWidget {
  const _AssignedDriverStatusBlock({required this.statusLabel});
  final String statusLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.orderDriverStatusLabel,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
        Text(
          statusLabel,
          softWrap: true,
          style: theme.textTheme.titleMedium?.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _PickupHandoffSection extends StatelessWidget {
  const _PickupHandoffSection({
    required this.orderId,
    required this.handoff,
    required this.loading,
    required this.regenerating,
    required this.error,
    required this.onRetry,
    required this.onRegenerate,
  });

  final String orderId;
  final MerchantPickupHandoff? handoff;
  final bool loading;
  final bool regenerating;
  final String? error;
  final VoidCallback onRetry;
  final VoidCallback onRegenerate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (loading && handoff == null && error == null) {
      return MerchantCard(
        key: const Key('pickup-handoff-section'),
        child: Column(
          children: [
            Text(
              AppStrings.pickupHandoffTitle,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            const SizedBox(
              key: Key('pickup-handoff-loading'),
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2.4),
            ),
          ],
        ),
      );
    }
    if (error != null && handoff == null) {
      return MerchantCard(
        key: const Key('pickup-handoff-section'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              AppStrings.pickupHandoffTitle,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              error!,
              key: const Key('pickup-handoff-error'),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              key: const Key('pickup-handoff-retry'),
              onPressed: onRetry,
              child: const Text(AppStrings.pickupHandoffRetry),
            ),
          ],
        ),
      );
    }
    if (handoff == null) return const SizedBox.shrink();

    if (handoff!.isConsumed) {
      return MerchantCard(
        key: const Key('pickup-handoff-section'),
        child: Column(
          children: [
            const Icon(
              Icons.check_circle,
              color: AppColors.tertiary,
              size: 40,
            ),
            const SizedBox(height: 8),
            Text(
              AppStrings.pickupHandoffConfirmed,
              key: const Key('pickup-handoff-confirmed'),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
    }

    return MerchantCard(
      key: const Key('pickup-handoff-section'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_outline, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                AppStrings.pickupHandoffTitle,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 8),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                _spacedPickupCode(handoff!.pickupCode),
                key: const Key('pickup-handoff-code'),
                maxLines: 1,
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 8,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            AppStrings.pickupHandoffInstruction1,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            AppStrings.pickupHandoffInstruction2,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (regenerating)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2.4),
                )
              else
                const Icon(
                  Icons.hourglass_top,
                  size: 20,
                  color: AppColors.primary,
                ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  AppStrings.pickupHandoffWaiting,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              key: const Key('pickup-handoff-regenerate'),
              onPressed: regenerating ? null : onRegenerate,
              icon: const Icon(Icons.refresh),
              label: const Text(AppStrings.pickupHandoffRegenerate),
            ),
          ),
        ],
      ),
    );
  }
}

/// Merchant-facing delivery status labels for every `DeliveryStatus` value.
String merchantDeliveryStatusLabel(String status) {
  switch (status) {
    case 'SEARCHING_DRIVER':
      return AppStrings.deliverySearching;
    case 'DRIVER_ASSIGNED':
      return AppStrings.deliveryAssigned;
    case 'TO_PICKUP':
      return AppStrings.deliveryToPickup;
    case 'AT_PICKUP':
      return AppStrings.deliveryAtPickup;
    case 'PICKED_UP':
      return AppStrings.deliveryPickedUp;
    case 'IN_TRANSIT':
      return AppStrings.deliveryInTransit;
    case 'ARRIVED_CUSTOMER':
      return AppStrings.deliveryArrived;
    case 'DELIVERED':
      return AppStrings.deliveryDelivered;
    case 'FAILED':
      return AppStrings.deliveryFailed;
    case 'CANCELLED':
      return AppStrings.deliveryCancelled;
    default:
      return AppStrings.deliveryUnknown;
  }
}

/// French timeline labels for order status events; unknown codes fall back
/// to the destination status label, never the raw code.
({String title, String caption}) merchantOrderEventLabel(
  MerchantOrderStatusEvent e,
) {
  switch (e.eventType) {
    case 'ORDER_CREATED':
      return (
        title: AppStrings.eventCreated,
        caption: AppStrings.eventCreatedCaption,
      );
    case 'MERCHANT_ACCEPTED':
      return (
        title: AppStrings.eventAccepted,
        caption: AppStrings.eventAcceptedCaption,
      );
    case 'PREPARATION_STARTED':
      return (
        title: AppStrings.eventPrepStarted,
        caption: AppStrings.eventPrepStartedCaption,
      );
    case 'ORDER_READY':
      return (
        title: AppStrings.eventReady,
        caption: AppStrings.eventReadyCaption,
      );
    case 'MERCHANT_REJECTED':
      return (
        title: AppStrings.eventRejected,
        caption: AppStrings.orderRejectedByMerchant,
      );
    case 'CUSTOMER_CANCELLED':
      return (
        title: AppStrings.eventCancelled,
        caption: AppStrings.orderCancelledByCustomer,
      );
    case 'ORDER_COMPLETED':
      return (
        title: AppStrings.eventCompleted,
        caption: AppStrings.eventCompletedCaption,
      );
    default:
      final to = e.toStatus.isEmpty ? '' : orderStatusLabel(e.toStatus);
      return (title: AppStrings.eventStatusUpdate, caption: to);
  }
}

class _TimelineCard extends StatelessWidget {
  const _TimelineCard({required this.events});
  final List<MerchantOrderStatusEvent> events;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ordered = [...events]
      ..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
    return MerchantCard(
      key: const Key('order-timeline'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.schedule, size: 20, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  AppStrings.orderHistoryTitle,
                  style: theme.textTheme.titleMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          for (var i = 0; i < ordered.length; i++)
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: 20,
                    child: Column(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          margin: const EdgeInsets.only(top: 3),
                          decoration: BoxDecoration(
                            color: i == 0
                                ? AppColors.tertiaryContainer
                                : AppColors.outlineVariant,
                            shape: BoxShape.circle,
                          ),
                        ),
                        if (i < ordered.length - 1)
                          Expanded(
                            child: Container(
                              width: 1,
                              color: AppColors.outlineVariant,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        bottom: i < ordered.length - 1 ? 16 : 0,
                      ),
                      child: Builder(
                        builder: (context) {
                          final label = merchantOrderEventLabel(ordered[i]);
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                label.title,
                                style: theme.textTheme.labelLarge,
                              ),
                              if (label.caption.isNotEmpty)
                                Text(
                                  label.caption,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: AppColors.onSurfaceVariant,
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                  Text(
                    formatPrepClockIso(ordered[i].occurredAt),
                    style: theme.textTheme.labelMedium?.copyWith(
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

class _SupportButton extends StatelessWidget {
  const _SupportButton({required this.orderId});
  final String orderId;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      key: const Key('order-support'),
      onPressed: () => context.push(AppRoutes.orderSupport(orderId)),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        foregroundColor: AppColors.primary,
        side: const BorderSide(color: AppColors.primary),
      ),
      icon: const Icon(Icons.support_agent),
      label: const Text(AppStrings.supportContact),
    );
  }
}

class _StickyActions extends StatelessWidget {
  const _StickyActions({
    required this.actions,
    required this.mutating,
    required this.onAccept,
    required this.onReject,
    required this.onStartPrep,
    required this.onMarkReady,
    this.onUpdatePrep,
    this.showUpdatePrep = false,
    this.supportOrderId,
  });

  final List<MerchantOrderAction> actions;
  final bool mutating;
  final VoidCallback? onUpdatePrep;
  final bool showUpdatePrep;
  final String? supportOrderId;
  final VoidCallback onAccept;
  final VoidCallback onReject;
  final VoidCallback onStartPrep;
  final VoidCallback onMarkReady;

  @override
  Widget build(BuildContext context) {
    final hasAccept = actions.contains(MerchantOrderAction.accept);
    final hasReject = actions.contains(MerchantOrderAction.reject);
    final dualIncoming = hasAccept && hasReject;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(
            color: AppColors.outlineVariant.withValues(alpha: 0.45),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            offset: const Offset(0, -2),
            blurRadius: 8,
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showUpdatePrep || supportOrderId != null) ...[
                _SecondaryActionRow(
                  onUpdatePrep: showUpdatePrep ? onUpdatePrep : null,
                  showUpdatePrep: showUpdatePrep,
                  supportOrderId: supportOrderId,
                ),
                const SizedBox(height: 12),
              ],
              if (dualIncoming)
                _IncomingActionRow(
                  mutating: mutating,
                  onAccept: onAccept,
                  onReject: onReject,
                )
              else ...[
                if (hasAccept)
                  MerchantPrimaryButton(
                    key: const Key('order-accept'),
                    label: AppStrings.orderChoosePrepTime,
                    loading: mutating,
                    onPressed: mutating ? null : onAccept,
                  ),
                if (hasReject) ...[
                  if (hasAccept) const SizedBox(height: 8),
                  OutlinedButton(
                    key: const Key('order-reject'),
                    onPressed: mutating ? null : onReject,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                    ),
                    child: const Text(AppStrings.orderReject),
                  ),
                ],
              ],
              if (actions.contains(MerchantOrderAction.startPreparation))
                MerchantPrimaryButton(
                  key: const Key('order-start-prep'),
                  label: AppStrings.orderStartPreparation,
                  loading: mutating,
                  onPressed: mutating ? null : onStartPrep,
                ),
              if (actions.contains(MerchantOrderAction.markReady))
                MerchantPrimaryButton(
                  key: const Key('order-mark-ready'),
                  label: AppStrings.orderMarkReady,
                  icon: Icons.check_circle,
                  leadingIcon: true,
                  loading: mutating,
                  onPressed: mutating ? null : onMarkReady,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SecondaryActionRow extends StatelessWidget {
  const _SecondaryActionRow({
    required this.onUpdatePrep,
    required this.showUpdatePrep,
    required this.supportOrderId,
  });

  final VoidCallback? onUpdatePrep;
  final bool showUpdatePrep;
  final String? supportOrderId;

  @override
  Widget build(BuildContext context) {
    final style = OutlinedButton.styleFrom(
      minimumSize: const Size.fromHeight(48),
      backgroundColor: AppColors.surfaceContainerLow,
      foregroundColor: AppColors.onSurface,
      side: const BorderSide(color: AppColors.outline),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      textStyle: Theme.of(context).textTheme.labelLarge
          ?.copyWith(fontSize: 14, fontWeight: FontWeight.w700),
    );
    final buttons = <Widget>[
      if (showUpdatePrep)
        OutlinedButton.icon(
          key: const Key('prep-update-open'),
          onPressed: onUpdatePrep,
          style: style,
          icon: const Icon(Icons.schedule, size: 20),
          label: const Text(AppStrings.prepUpdateAction),
        ),
      if (supportOrderId != null)
        OutlinedButton.icon(
          key: const Key('order-support'),
          onPressed: () =>
              context.push(AppRoutes.orderSupport(supportOrderId!)),
          style: style,
          icon: const Icon(Icons.help_outline, size: 20),
          label: const Text(AppStrings.supportShort),
        ),
    ];
    if (MediaQuery.textScalerOf(context).scale(1) >= 1.25 ||
        buttons.length == 1) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < buttons.length; i++) ...[
            if (i > 0) const SizedBox(height: 8),
            buttons[i],
          ],
        ],
      );
    }
    return Row(
      children: [
        Expanded(child: buttons[0]),
        const SizedBox(width: 12),
        Expanded(child: buttons[1]),
      ],
    );
  }
}

class _IncomingActionRow extends StatelessWidget {
  const _IncomingActionRow({
    required this.mutating,
    required this.onAccept,
    required this.onReject,
  });

  final bool mutating;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.textScalerOf(context).scale(1);
    // Stack vertically when text is enlarged so labels stay readable.
    if (scale >= 1.25) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MerchantPrimaryButton(
            key: const Key('order-accept'),
            label: AppStrings.orderChoosePrepTime,
            loading: mutating,
            onPressed: mutating ? null : onAccept,
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            key: const Key('order-reject'),
            onPressed: mutating ? null : onReject,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              foregroundColor: AppColors.error,
              side: const BorderSide(color: AppColors.error),
            ),
            child: const Text(AppStrings.orderReject),
          ),
        ],
      );
    }
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            key: const Key('order-reject'),
            onPressed: mutating ? null : onReject,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              foregroundColor: AppColors.error,
              side: const BorderSide(color: AppColors.error),
            ),
            child: const Text(AppStrings.orderReject),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: MerchantPrimaryButton(
            key: const Key('order-accept'),
            label: AppStrings.orderChoosePrepTime,
            loading: mutating,
            onPressed: mutating ? null : onAccept,
          ),
        ),
      ],
    );
  }
}

String _formatIso(String iso) {
  final dt = DateTime.tryParse(iso)?.toLocal();
  if (dt == null) return iso;
  final h = dt.hour.toString().padLeft(2, '0');
  final m = dt.minute.toString().padLeft(2, '0');
  return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} $h:$m';
}

String? _vehicleLine(AssignedDriverVehicleSummary? vehicle) {
  if (vehicle == null) return null;
  final type = vehicle.type.trim();
  final plate = vehicle.plateNumber.trim();
  if (type.isEmpty && plate.isEmpty) return null;
  if (type.isEmpty) return plate;
  if (plate.isEmpty) return type;
  return '$type • $plate';
}

String _spacedPickupCode(String code) {
  final digits = code.trim();
  if (digits.isEmpty) return code;
  return digits.split('').join(' ');
}

Future<void> _launchDriverCall(String phone) async {
  final uri = Uri(scheme: 'tel', path: phone.trim());
  if (!await canLaunchUrl(uri)) return;
  await launchUrl(uri);
}

/// Integer basis points → percent label without float money math.
String _moneyOrDash(String? minor) {
  final formatted = MoneyFormat.dzdOrEmpty(minor);
  return formatted.isEmpty ? AppStrings.valueUnavailable : formatted;
}

String _formatBpsPercent(int bps) {
  final whole = bps ~/ 100;
  final frac = bps % 100;
  if (frac == 0) return '$whole';
  return '$whole,${frac.toString().padLeft(2, '0')}';
}

extension on String {
  String? get nullIfEmpty => isEmpty ? null : this;
}
