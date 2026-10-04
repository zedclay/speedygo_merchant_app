import 'package:flutter/material.dart';
import 'package:speedygo_merchant_app/app/theme/app_theme.dart';
import 'package:speedygo_merchant_app/core/constants/app_strings.dart';
import 'package:speedygo_merchant_app/core/money/money_format.dart';
import 'package:speedygo_merchant_app/features/notifications/domain/incoming_order_alert.dart';
import 'package:speedygo_merchant_app/features/orders/presentation/order_public_reference.dart';
import 'package:speedygo_merchant_app/features/orders/presentation/prep_time_clock.dart';

/// Full-screen incoming order alert (MerchantScreens reference).
/// No invented accept-expiry countdown — shows received clock only.
class IncomingOrderAlertOverlay extends StatelessWidget {
  const IncomingOrderAlertOverlay({
    super.key,
    required this.alert,
    required this.onViewDetails,
    required this.onRefuse,
    required this.onDismiss,
  });

  final IncomingOrderAlert alert;
  final VoidCallback onViewDetails;

  /// Null when the member lacks the reject permission: the action is not shown.
  final VoidCallback? onRefuse;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final received = formatPrepClockIso(alert.createdAt);
    final paymentLabel = _paymentLabel(alert.paymentMethod);
    final stillIncoming = alert.isStillIncoming;
    final label = theme.textTheme.labelMedium?.copyWith(
      color: AppColors.onSurfaceVariant,
    );

    return Material(
      key: const Key('incoming-order-alert'),
      color: AppColors.background,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _AlertHeader(onDismiss: onDismiss),
          Expanded(
            child: Transform.translate(
              offset: const Offset(0, -16),
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (!stillIncoming) ...[
                        const MerchantStatusBanner(
                          message: AppStrings.notificationsOrderStale,
                        ),
                        const SizedBox(height: 16),
                      ],
                      _BentoCard(
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: const BoxDecoration(
                                color: AppColors.secondaryContainer,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.person,
                                color: AppColors.onSecondaryContainer,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    AppStrings.orderCustomerLabel,
                                    style: label,
                                  ),
                                  Text(
                                    alert.customerLabel,
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                            if (alert.publicReference.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              Flexible(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      AppStrings.alertOrderLabel,
                                      style: label,
                                    ),
                                    OrderPublicReferenceLine(
                                      reference: alert.publicReference,
                                      emphasized: true,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: _FactTile(
                                icon: Icons.schedule,
                                label: AppStrings.alertReceivedAt,
                                value: received,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _FactTile(
                                icon: Icons.payments,
                                label: AppStrings.alertPayment,
                                value: paymentLabel,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      CustomPaint(
                        painter: _DashedBorderPainter(
                          color: AppColors.outlineVariant,
                          radius: 16,
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.restaurant_menu,
                                    color: AppColors.primary,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      alert.itemCount <= 1
                                          ? '1 article'
                                          : '${alert.itemCount} ${AppStrings.alertItems}',
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              for (final item in alert.items.take(6))
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          '${item.quantity}x ${item.productNameSnapshot}',
                                          style: theme.textTheme.bodyMedium
                                              ?.copyWith(
                                                color:
                                                    AppColors.onSurfaceVariant,
                                              ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        MoneyFormat.dzd(item.lineTotalMinor),
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                              color: AppColors.onSurfaceVariant,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              Divider(
                                height: 20,
                                color: AppColors.outlineVariant.withValues(
                                  alpha: 0.6,
                                ),
                              ),
                              Wrap(
                                alignment: WrapAlignment.spaceBetween,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                spacing: 12,
                                children: [
                                  Text(
                                    AppStrings.alertOrderTotal,
                                    style: theme.textTheme.labelLarge,
                                  ),
                                  Text(
                                    alert.merchandiseSubtotalMinor == null
                                        ? AppStrings.valueUnavailable
                                        : MoneyFormat.dzd(
                                            '${alert.merchandiseSubtotalMinor}',
                                          ),
                                    style: theme.textTheme.headlineSmall
                                        ?.copyWith(
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.w700,
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
              ),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border(
                top: BorderSide(
                  color: AppColors.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0F000000),
                  blurRadius: 30,
                  offset: Offset(0, -8),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      height: 56,
                      child: FilledButton.icon(
                        key: const Key('incoming-alert-details'),
                        onPressed: onViewDetails,
                        icon: const Icon(Icons.visibility),
                        label: const Text(AppStrings.alertViewDetails),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    if (onRefuse != null) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 56,
                        child: OutlinedButton.icon(
                          key: const Key('incoming-alert-refuse'),
                          onPressed: stillIncoming ? onRefuse : null,
                          icon: const Icon(Icons.cancel_outlined),
                          label: const Text(AppStrings.alertRefuse),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.error,
                            side: const BorderSide(color: AppColors.error),
                            backgroundColor: AppColors.surface,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _paymentLabel(String method) {
    final m = method.toUpperCase();
    if (m.contains('COD') || m.contains('CASH')) {
      return 'À la livraison';
    }
    if (m.isEmpty) return '—';
    return method;
  }
}

class _AlertHeader extends StatelessWidget {
  const _AlertHeader({required this.onDismiss});

  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    Widget ring(double size) => Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.onPrimary.withValues(alpha: 0.1),
          width: 24,
        ),
      ),
    );
    return ClipRect(
      child: ColoredBox(
        color: AppColors.primary,
        child: Stack(
          children: [
            Positioned(top: -60, right: -60, child: ring(200)),
            Positioned(bottom: -40, left: -50, child: ring(140)),
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 24, 8, 40),
                child: Row(
                  children: [
                    const SizedBox(width: 48),
                    Expanded(
                      child: Text(
                        AppStrings.alertNewOrder,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: AppColors.tertiaryFixed,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                    IconButton(
                      key: const Key('incoming-alert-dismiss'),
                      onPressed: onDismiss,
                      tooltip: AppStrings.alertDismiss,
                      icon: const Icon(Icons.close, color: AppColors.onPrimary),
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

class _BentoCard extends StatelessWidget {
  const _BentoCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariant),
        boxShadow: const [
          BoxShadow(
            color: Color(0x140A4096),
            blurRadius: 20,
            spreadRadius: -4,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _FactTile extends StatelessWidget {
  const _FactTile({
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
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 128),
      child: _BentoCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: AppColors.primary),
            const SizedBox(height: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                Text(
                  value,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius)),
      );
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(metric.extractPath(distance, distance + 6), paint);
        distance += 10;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.radius != radius;
}

class MerchantStatusBanner extends StatelessWidget {
  const MerchantStatusBanner({super.key, required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.warningWash,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        message,
        style: Theme.of(context).textTheme.bodyMedium
            ?.copyWith(color: AppColors.warning, fontWeight: FontWeight.w600),
      ),
    );
  }
}
