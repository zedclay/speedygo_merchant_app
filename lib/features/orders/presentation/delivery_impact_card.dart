import 'package:flutter/material.dart';
import 'package:speedygo_merchant_app/app/theme/app_theme.dart';
import 'package:speedygo_merchant_app/core/constants/app_strings.dart';
import 'package:speedygo_merchant_app/core/widgets/merchant_ui.dart';
import 'package:speedygo_merchant_app/features/orders/data/order_models.dart';

String deliveryImpactMessage(MerchantDeliveryImpactState state) {
  switch (state) {
    case MerchantDeliveryImpactState.mayDelayDriverAssignment:
      return AppStrings.deliveryImpactMayDelayDriverAssignment;
    case MerchantDeliveryImpactState.mayDelayPickup:
      return AppStrings.deliveryImpactMayDelayPickup;
    case MerchantDeliveryImpactState.driverWaiting:
      return AppStrings.deliveryImpactDriverWaiting;
    case MerchantDeliveryImpactState.deliveryTimingUnavailable:
      return AppStrings.deliveryImpactTimingUnavailable;
    case MerchantDeliveryImpactState.notApplicable:
    case MerchantDeliveryImpactState.resolved:
      return '';
  }
}

/// Truthful delivery-impact copy when preparation is late (no invented ETA).
class DeliveryImpactCard extends StatelessWidget {
  const DeliveryImpactCard({
    super.key,
    required this.deliveryImpact,
    this.latestRevisionReason,
  });

  final MerchantDeliveryImpact deliveryImpact;
  final String? latestRevisionReason;

  @override
  Widget build(BuildContext context) {
    if (!deliveryImpact.state.showOnLateCard) {
      return const SizedBox.shrink();
    }
    final theme = Theme.of(context);
    final message = deliveryImpactMessage(deliveryImpact.state);
    return MerchantCard(
      key: const Key('delivery-impact-card'),
      child: Column(
        key: Key('delivery-impact-${deliveryImpact.state.apiValue}'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.deliveryImpactTitle,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.local_shipping_outlined,
                size: 20,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  message,
                  key: const Key('delivery-impact-message'),
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            ],
          ),
          if (latestRevisionReason != null &&
              latestRevisionReason!.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              AppStrings.deliveryImpactLatestRevision(latestRevisionReason!),
              key: const Key('delivery-impact-revision-reason'),
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
