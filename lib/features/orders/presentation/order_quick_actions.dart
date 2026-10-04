import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speedygo_merchant_app/app/theme/app_theme.dart';
import 'package:speedygo_merchant_app/core/constants/app_strings.dart';
import 'package:speedygo_merchant_app/core/money/money_format.dart';
import 'package:speedygo_merchant_app/features/access/application/access_controller.dart';
import 'package:speedygo_merchant_app/features/orders/application/orders_controller.dart';
import 'package:speedygo_merchant_app/features/orders/data/order_models.dart';
import 'package:speedygo_merchant_app/features/orders/presentation/preparation_time_widgets.dart';
import 'package:speedygo_merchant_app/features/orders/presentation/reject_reason_sheet.dart';

/// Accept / reject on an incoming list card (decision D-B2). Shown only to
/// roles that may mutate orders. Each action re-reads the order and the role
/// before opening the existing sheets, and submits through the order detail
/// controller (single in-flight mutation, server reconciliation on error).
class IncomingOrderQuickActions extends ConsumerStatefulWidget {
  const IncomingOrderQuickActions({super.key, required this.order});

  final MerchantOrderSummary order;

  @override
  ConsumerState<IncomingOrderQuickActions> createState() =>
      _IncomingOrderQuickActionsState();
}

/// Unsent inputs per order, kept across list rebuilds and failed attempts.
class OrderQuickDrafts {
  final minutes = <String, int>{};
  final reasons = <String, TextEditingController>{};

  TextEditingController reasonFor(String orderId) =>
      reasons.putIfAbsent(orderId, TextEditingController.new);

  void clear(String orderId) {
    minutes.remove(orderId);
    reasons.remove(orderId)?.dispose();
  }
}

final orderQuickDraftsProvider = Provider<OrderQuickDrafts>((ref) {
  final drafts = OrderQuickDrafts();
  ref.onDispose(() {
    for (final c in drafts.reasons.values) {
      c.dispose();
    }
  });
  return drafts;
});

class _IncomingOrderQuickActionsState
    extends ConsumerState<IncomingOrderQuickActions> {
  bool _busy = false;
  bool _loading = false;

  /// Spinner only while talking to the server, not while a sheet is open.
  Future<T> _withSpinner<T>(Future<T> Function() call) async {
    if (mounted) setState(() => _loading = true);
    try {
      return await call();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String get _orderId => widget.order.id;

  /// Fresh detail when the order is still awaiting acceptance and the role
  /// may act; otherwise reports why and returns null.
  Future<MerchantOrderDetail?> _recheck(
    ScaffoldMessengerState? messenger,
  ) async {
    final role = ref.read(accessControllerProvider).membership?.role;
    if (!merchantRoleCanMutateOrders(role)) {
      messenger?.showSnackBar(
        const SnackBar(content: Text(AppStrings.orderQuickNotAllowed)),
      );
      return null;
    }
    final provider = orderDetailControllerProvider(_orderId);
    await _withSpinner(() async {
      if (ref.exists(provider)) {
        await ref.read(provider.notifier).reload();
      } else {
        try {
          await ref.read(provider.future);
        } catch (_) {}
      }
    });
    if (!mounted) return null;
    final fresh = ref.read(provider);
    final detail = fresh.value?.order;
    if (detail == null) {
      messenger?.showSnackBar(
        const SnackBar(content: Text(AppStrings.orderQuickCheckFailed)),
      );
      return null;
    }
    final stillIncoming =
        detail.status == 'CREATED' &&
        detail.fulfillmentStatus == 'PENDING_ACCEPTANCE';
    final roleNow = ref.read(accessControllerProvider).membership?.role;
    if (!merchantRoleCanMutateOrders(roleNow)) {
      messenger?.showSnackBar(
        const SnackBar(content: Text(AppStrings.orderQuickNotAllowed)),
      );
      return null;
    }
    if (!stillIncoming) {
      ref.invalidate(ordersListControllerProvider);
      messenger?.showSnackBar(
        const SnackBar(content: Text(AppStrings.orderQuickAlreadyHandled)),
      );
      return null;
    }
    return detail;
  }

  /// Runs [action] once at a time for this card.
  Future<void> _guarded(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _reportResult(ScaffoldMessengerState? messenger, String success) {
    final state = ref.read(orderDetailControllerProvider(_orderId)).value;
    final error = state?.actionError;
    final order = state?.order;
    final handled =
        order != null &&
        !(order.status == 'CREATED' &&
            order.fulfillmentStatus == 'PENDING_ACCEPTANCE');
    if (error == null && handled) {
      ref.read(orderQuickDraftsProvider).clear(_orderId);
      messenger?.showSnackBar(SnackBar(content: Text(success)));
    } else if (error != null) {
      messenger?.showSnackBar(SnackBar(content: Text(error)));
    }
    ref.invalidate(ordersListControllerProvider);
  }

  Future<void> _accept() => _guarded(() async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    final detail = await _recheck(messenger);
    if (detail == null || !mounted) return;
    final drafts = ref.read(orderQuickDraftsProvider);
    final minutes = await showAcceptPreparationSheet(
      context,
      publicReference: detail.publicReference,
      itemCount: detail.items.fold<int>(0, (sum, i) => sum + i.quantity),
      customerName: detail.customerFullName,
      merchandise: _nonEmpty(
        MoneyFormat.dzdOrEmpty(detail.financial.grossMerchandiseSubtotalMinor),
      ),
      address: detail.deliveryAddress.addressText,
      branchName: ref.read(accessControllerProvider).selectedBranch?.name,
      initialMinutes: drafts.minutes[_orderId],
    );
    if (minutes == null || !mounted) return;
    drafts.minutes[_orderId] = minutes;
    await _withSpinner(
      () => ref
          .read(orderDetailControllerProvider(_orderId).notifier)
          .accept(preparationMinutes: minutes),
    );
    if (!mounted) return;
    _reportResult(messenger, AppStrings.orderQuickAccepted);
  });

  Future<void> _reject() => _guarded(() async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    final detail = await _recheck(messenger);
    if (detail == null || !mounted) return;
    final controller = ref.read(orderQuickDraftsProvider).reasonFor(_orderId);
    final result = await showRejectReasonSheet(context, controller: controller);
    if (result == null || result.reason.isEmpty || !mounted) return;
    await _withSpinner(
      () => ref
          .read(orderDetailControllerProvider(_orderId).notifier)
          .reject(result.reason, reasonCode: result.reasonCode),
    );
    if (!mounted) return;
    _reportResult(messenger, AppStrings.orderQuickRejected);
  });

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    );
    return Row(
      children: [
        Expanded(
          child: FilledButton(
            key: Key('order-card-accept-${widget.order.id}'),
            onPressed: _busy ? null : _accept,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              shape: shape,
            ),
            child: _loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(AppStrings.orderAccept),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 48,
          height: 48,
          child: Tooltip(
            message: AppStrings.orderRejectTitle,
            excludeFromSemantics: true,
            child: OutlinedButton(
              key: Key('order-card-reject-${widget.order.id}'),
              onPressed: _busy ? null : _reject,
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.zero,
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error),
                shape: shape,
              ),
              child: const Icon(
                Icons.close,
                semanticLabel: AppStrings.orderRejectTitle,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

String? _nonEmpty(String value) => value.isEmpty ? null : value;
