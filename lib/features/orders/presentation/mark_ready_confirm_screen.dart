import 'package:flutter/material.dart';
import 'package:speedygo_merchant_app/app/theme/app_theme.dart';
import 'package:speedygo_merchant_app/core/constants/app_strings.dart';
import 'package:speedygo_merchant_app/core/widgets/merchant_primary_button.dart';
import 'package:speedygo_merchant_app/core/widgets/merchant_ui.dart';
import 'package:speedygo_merchant_app/features/orders/data/order_models.dart';

/// Opens the mark-ready confirmation; true when the merchant confirms.
Future<bool> confirmMarkReady(
  BuildContext context,
  MerchantOrderDetail order,
) async {
  final confirmed = await Navigator.of(context).push<bool>(
    MaterialPageRoute(builder: (_) => MarkReadyConfirmScreen(order: order)),
  );
  return confirmed ?? false;
}

/// Packing list before marking an order ready. The list is informational:
/// it shows only the order's own items and never gates the confirmation.
class MarkReadyConfirmScreen extends StatelessWidget {
  const MarkReadyConfirmScreen({super.key, required this.order});

  final MerchantOrderDetail order;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final count = order.items.fold<int>(0, (sum, i) => sum + i.quantity);
    return MerchantScaffold(
      key: const Key('order-mark-ready-confirm-screen'),
      title: '#${order.publicReference}',
      headerDivider: true,
      actions: const [
        Padding(
          padding: EdgeInsets.only(right: 12),
          child: Center(child: _PreparingChip()),
        ),
      ],
      body: ListView(
        padding: const EdgeInsets.only(top: 16, bottom: 24),
        children: [
          MerchantCard(
            key: const Key('order-mark-ready-packing'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 12,
                  runSpacing: 4,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.checklist, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            AppStrings.markReadyPackingTitle,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      AppStrings.prepItemCount('${count}'),
                      key: const Key('order-mark-ready-count'),
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: AppColors.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  AppStrings.markReadyPackingHint,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                for (var i = 0; i < order.items.length; i++) ...[
                  if (i > 0)
                    Divider(
                      height: 1,
                      color: AppColors.outlineVariant.withValues(alpha: 0.3),
                    ),
                  _PackingRow(item: order.items[i]),
                ],
              ],
            ),
          ),
        ],
      ),
      bottom: MerchantStickyBar(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            MerchantPrimaryButton(
              key: const Key('order-mark-ready-confirm'),
              label: AppStrings.markReadyConfirm,
              onPressed: () => Navigator.of(context).pop(true),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              key: const Key('order-mark-ready-back'),
              onPressed: () => Navigator.of(context).pop(false),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              child: Text(AppStrings.back),
            ),
          ],
        ),
      ),
    );
  }
}

class _PackingRow extends StatelessWidget {
  const _PackingRow({required this.item});

  final MerchantOrderItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      key: Key('order-mark-ready-item-${item.id}'),
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${item.quantity}× ${item.productNameSnapshot}',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          for (final opt in item.options)
            Text(
              '· ${opt.optionNameSnapshot}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }
}

class _PreparingChip extends StatelessWidget {
  const _PreparingChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.tertiaryContainer.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.tertiaryFixed),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.soup_kitchen_outlined,
            size: 16,
            color: AppColors.tertiaryContainer,
          ),
          const SizedBox(width: 4),
          Text(
            AppStrings.orderFulfillmentPreparing,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: AppColors.tertiaryContainer,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
