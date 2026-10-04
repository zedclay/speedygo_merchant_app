import 'package:speedygo_merchant_app/features/orders/data/order_models.dart';

/// One actionable new-order alert (never auto-accept).
class IncomingOrderAlert {
  const IncomingOrderAlert({
    required this.orderId,
    required this.notificationId,
    required this.publicReference,
    required this.customerLabel,
    required this.itemCount,
    required this.merchandiseSubtotalMinor,
    required this.paymentMethod,
    required this.createdAt,
    required this.branchId,
    required this.fulfillmentStatus,
    required this.orderStatus,
    this.items = const [],
  });

  final String orderId;
  final String notificationId;
  final String publicReference;
  final String customerLabel;
  final int itemCount;

  /// Null when the server did not send the snapshot value (never shown as 0).
  final int? merchandiseSubtotalMinor;
  final String paymentMethod;
  final String createdAt;
  final String branchId;
  final String fulfillmentStatus;
  final String orderStatus;
  final List<MerchantOrderItem> items;

  bool get isStillIncoming =>
      fulfillmentStatus == 'PENDING_ACCEPTANCE' &&
      orderStatus.toUpperCase() != 'CANCELLED';

  factory IncomingOrderAlert.fromDetail({
    required MerchantOrderDetail detail,
    required String notificationId,
  }) {
    final grossRaw = detail.financial.grossMerchandiseSubtotalMinor;
    final gross = grossRaw == null ? null : int.tryParse(grossRaw);
    return IncomingOrderAlert(
      orderId: detail.id,
      notificationId: notificationId,
      publicReference: detail.publicReference,
      customerLabel: detail.customerFullName?.trim().isNotEmpty == true
          ? detail.customerFullName!.trim()
          : 'Client',
      itemCount: detail.items.fold<int>(0, (s, i) => s + i.quantity),
      merchandiseSubtotalMinor: gross,
      paymentMethod: detail.payment.method,
      createdAt: detail.createdAt,
      branchId: detail.merchantBranchId,
      fulfillmentStatus: detail.fulfillmentStatus,
      orderStatus: detail.status,
      items: detail.items,
    );
  }
}
