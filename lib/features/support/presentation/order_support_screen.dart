import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:speedygo_merchant_app/app/theme/app_theme.dart';
import 'package:speedygo_merchant_app/core/constants/app_strings.dart';
import 'package:speedygo_merchant_app/core/errors/app_exception.dart';
import 'package:speedygo_merchant_app/core/money/money_format.dart';
import 'package:speedygo_merchant_app/core/widgets/merchant_primary_button.dart';
import 'package:speedygo_merchant_app/core/widgets/merchant_ui.dart';
import 'package:speedygo_merchant_app/features/access/application/access_controller.dart';
import 'package:speedygo_merchant_app/features/auth/application/auth_infrastructure.dart';
import 'package:speedygo_merchant_app/features/orders/application/orders_controller.dart';
import 'package:speedygo_merchant_app/features/orders/data/order_models.dart';
import 'package:speedygo_merchant_app/features/orders/presentation/order_public_reference.dart';
import 'package:speedygo_merchant_app/features/orders/presentation/orders_screen.dart';
import 'package:speedygo_merchant_app/features/support/presentation/support_topic_picker.dart';

/// Support tickets are OWNER/MANAGER only (STAFF is forbidden server-side).
bool merchantRoleCanContactSupport(String? role) =>
    role == 'OWNER' || role == 'MANAGER';

const supportBodyMaxLength = 4000;

/// Order-scoped support ticket (`POST /merchant/:merchantId/support`). A
/// server topic and a subject are required; no attachments or drafts.
class OrderSupportScreen extends ConsumerStatefulWidget {
  const OrderSupportScreen({super.key, required this.orderId});

  final String orderId;

  @override
  ConsumerState<OrderSupportScreen> createState() => _OrderSupportScreenState();
}

class _OrderSupportScreenState extends ConsumerState<OrderSupportScreen> {
  final _subject = TextEditingController();
  final _body = TextEditingController();
  String? _topicCode;
  bool _sending = false;
  bool _submitted = false;
  String? _error;
  String? _sentReference;

  @override
  void initState() {
    super.initState();
    _subject.addListener(() => setState(() {}));
    _body.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _subject.dispose();
    _body.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _body.text.trim();
    final merchantId = ref
        .read(accessControllerProvider)
        .membership
        ?.merchantId;
    if (text.isEmpty || merchantId == null || _sending) return;
    final topic = _topicCode;
    final subject = _subject.text.trim();
    if (topic == null || subject.isEmpty) {
      setState(() => _submitted = true);
      return;
    }
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      final reference = await ref
          .read(merchantApiProvider)
          .createSupportTicket(
            merchantId: merchantId,
            subject: subject,
            topicCode: topic,
            body: text,
            orderId: widget.orderId,
          );
      if (!mounted) return;
      setState(() => _sentReference = reference);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(
        () => _error = e.statusCode == 403
            ? AppStrings.supportForbidden
            : AppStrings.supportSendError,
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = AppStrings.supportSendError);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final role = ref.watch(accessControllerProvider).membership?.role;
    final detail = ref.watch(orderDetailControllerProvider(widget.orderId));
    final allowed = merchantRoleCanContactSupport(role);
    final canSend = allowed && _body.text.trim().isNotEmpty && !_sending;

    return MerchantScaffold(
      title: AppStrings.supportReportTitle,
      centerTitle: true,
      headerColor: AppColors.surface,
      headerHeight: 64,
      bottom: _sentReference != null || !allowed
          ? null
          : MerchantStickyBar(
              child: MerchantPrimaryButton(
                key: const Key('support-send'),
                label: AppStrings.supportSend,
                icon: Icons.send,
                leadingIcon: true,
                loading: _sending,
                onPressed: canSend ? _send : null,
              ),
            ),
      body: _sentReference != null
          ? _SentConfirmation(reference: _sentReference!)
          : ListView(
              padding: const EdgeInsets.only(top: 16, bottom: 24),
              children: [
                if (detail.value != null) ...[
                  _OrderContextCard(order: detail.value!.order),
                  const SizedBox(height: 24),
                ],
                if (!allowed)
                  Text(
                    AppStrings.supportForbidden,
                    key: const Key('support-forbidden'),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  )
                else ...[
                  SupportTopicPicker(
                    selectedCode: _topicCode,
                    onSelected: (code) => setState(() => _topicCode = code),
                    errorText: _submitted && _topicCode == null
                        ? AppStrings.supportTopicRequired
                        : null,
                  ),
                  const SizedBox(height: 16),
                  MerchantLabeledField(
                    label: AppStrings.supportSubjectLabel,
                    requiredMark: true,
                    child: TextField(
                      key: const Key('support-subject'),
                      controller: _subject,
                      maxLength: supportSubjectMaxLength,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        hintText: AppStrings.supportSubjectHint,
                        errorText: _submitted && _subject.text.trim().isEmpty
                            ? AppStrings.supportSubjectRequired
                            : null,
                      ),
                    ),
                  ),
                  MerchantLabeledField(
                    label: AppStrings.supportDescriptionLabel,
                    requiredMark: true,
                    child: TextField(
                      key: const Key('support-body'),
                      controller: _body,
                      minLines: 5,
                      maxLines: 8,
                      maxLength: supportBodyMaxLength,
                      decoration: const InputDecoration(
                        hintText: AppStrings.supportDescriptionHint,
                      ),
                    ),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.info_outline,
                        size: 16,
                        color: AppColors.onSurfaceVariant,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          AppStrings.supportSensitiveHint,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      _error!,
                      key: const Key('support-error'),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.error,
                      ),
                    ),
                  ],
                ],
              ],
            ),
    );
  }
}

class _OrderContextCard extends StatelessWidget {
  const _OrderContextCard({required this.order});

  final MerchantOrderDetail order;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final caption = theme.textTheme.labelMedium?.copyWith(
      color: AppColors.outline,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.5,
    );
    final merchandise = MoneyFormat.dzdOrEmpty(
      order.financial.grossMerchandiseSubtotalMinor,
    );
    return MerchantCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(AppStrings.supportOrderLabel, style: caption),
                      const SizedBox(height: 2),
                      OrderPublicReferenceLine(
                        reference: order.publicReference,
                        emphasized: true,
                      ),
                    ],
                  ),
                ),
                StatusBadge(
                  label: orderListStatusLabel(
                    order.status,
                    order.fulfillmentStatus,
                  ),
                  tone: fulfillmentTone(order.fulfillmentStatus, order.status),
                  pill: true,
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(AppStrings.supportCustomerLabel, style: caption),
                      const SizedBox(height: 2),
                      Text(
                        order.customerFullName?.isNotEmpty == true
                            ? order.customerFullName!
                            : AppStrings.orderCustomerLabel,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                if (merchandise.isNotEmpty)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppStrings.supportMerchandiseLabel,
                          style: caption,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          merchandise,
                          style: theme.textTheme.bodyMedium?.copyWith(
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
      ),
    );
  }
}

class _SentConfirmation extends StatelessWidget {
  const _SentConfirmation({required this.reference});

  final String reference;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      key: const Key('support-sent'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              color: AppColors.tertiaryFixed,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check, size: 36, color: AppColors.tertiary),
          ),
          const SizedBox(height: 16),
          Text(
            AppStrings.supportSentTitle,
            style: theme.textTheme.headlineMedium?.copyWith(
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            reference.isEmpty
                ? AppStrings.supportSentBodyNoRef
                : AppStrings.supportSentBody(reference),
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          OutlinedButton(
            key: const Key('support-back'),
            onPressed: () {
              if (context.canPop()) context.pop();
            },
            child: const Text(AppStrings.supportBackToOrder),
          ),
        ],
      ),
    );
  }
}
