import 'package:speedygo_merchant_app/core/constants/app_strings.dart';

final publicOrderRefPattern = RegExp(r'sgo_[0-9A-Za-z]+');

String? extractPublicOrderReference(String body) {
  return publicOrderRefPattern.firstMatch(body)?.group(0);
}

enum TextDirectionGuess { ltr, rtl, neutral }

TextDirectionGuess guessTextDirection(String value) {
  for (final rune in value.runes) {
    if (rune >= 0x0600 && rune <= 0x06FF) {
      return TextDirectionGuess.rtl;
    }
    final latin =
        (rune >= 0x41 && rune <= 0x5A) || (rune >= 0x61 && rune <= 0x7A);
    if (latin) {
      return TextDirectionGuess.ltr;
    }
  }
  return TextDirectionGuess.neutral;
}

class NotificationCopy {
  const NotificationCopy({
    required this.title,
    required this.body,
    this.publicReference,
    this.localized = true,
  });

  final String title;
  final String body;
  final String? publicReference;
  final bool localized;
}

/// Render-time localization from `type` + extracted identifiers.
/// Does not rewrite stored Notification rows.
NotificationCopy resolveSystemNotificationCopy({
  required String type,
  required String storedTitle,
  required String storedBody,
}) {
  final ref = extractPublicOrderReference(storedBody);
  switch (type) {
    case 'ORDER_ACCEPTED':
      return NotificationCopy(
        title: AppStrings.notifTitleOrderAccepted,
        body: AppStrings.notifBodyOrderAccepted(ref ?? ''),
        publicReference: ref,
      );
    case 'ORDER_REJECTED':
      return NotificationCopy(
        title: AppStrings.notifTitleOrderRejected,
        body: AppStrings.notifBodyOrderRejected(ref ?? ''),
        publicReference: ref,
      );
    case 'ORDER_CANCELLED':
      return NotificationCopy(
        title: AppStrings.notifTitleOrderCancelled,
        body: AppStrings.notifBodyOrderCancelled(ref ?? ''),
        publicReference: ref,
      );
    case 'ORDER_READY':
      return NotificationCopy(
        title: AppStrings.notifTitleOrderReady,
        body: AppStrings.notifBodyOrderReady(ref ?? ''),
        publicReference: ref,
      );
    case 'DRIVER_ASSIGNED':
      return NotificationCopy(
        title: AppStrings.notifTitleDriverAssigned,
        body: AppStrings.notifBodyDriverAssigned(ref ?? ''),
        publicReference: ref,
      );
    case 'DELIVERY_COMPLETED':
      return NotificationCopy(
        title: AppStrings.notifTitleDeliveryCompleted,
        body: AppStrings.notifBodyDeliveryCompleted(ref ?? ''),
        publicReference: ref,
      );
    case 'PAYMENT_SUCCEEDED':
      return NotificationCopy(
        title: AppStrings.notifTitlePaymentSucceeded,
        body: AppStrings.notifBodyPaymentSucceeded(ref ?? ''),
        publicReference: ref,
      );
    case 'REFUND_REFUNDED':
      return NotificationCopy(
        title: AppStrings.notifTitleRefundRefunded,
        body: AppStrings.notifBodyRefundRefunded(ref ?? ''),
        publicReference: ref,
      );
    case 'MATCH_OFFER':
      return NotificationCopy(
        title: AppStrings.notifTitleMatchOffer,
        body: AppStrings.notifBodyMatchOffer,
      );
    case 'SETTLEMENT_FINALIZED':
      return NotificationCopy(
        title: AppStrings.notifTitleSettlementFinalized,
        body: AppStrings.notifBodySettlementFinalized,
      );
    case 'DRIVER_EARNING_CREATED':
      return NotificationCopy(
        title: AppStrings.notifTitleDriverEarningCreated,
        body: AppStrings.notifBodyDriverEarningCreated,
      );
    case 'MERCHANT_ORDER_CREATED':
      return NotificationCopy(
        title: AppStrings.notifTitleMerchantOrderCreated,
        body: AppStrings.notifBodyMerchantOrderCreated(ref ?? ''),
        publicReference: ref,
      );
    default:
      return NotificationCopy(
        title: storedTitle,
        body: storedBody,
        publicReference: ref,
        localized: false,
      );
  }
}
