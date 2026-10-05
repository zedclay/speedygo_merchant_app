import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speedygo_merchant_app/app/theme/app_theme.dart';
import 'package:speedygo_merchant_app/core/constants/app_strings.dart';
import 'package:speedygo_merchant_app/core/widgets/merchant_ui.dart';
import 'package:speedygo_merchant_app/features/access/application/access_controller.dart';
import 'package:speedygo_merchant_app/features/auth/application/auth_infrastructure.dart';
import 'package:speedygo_merchant_app/features/auth/application/session_controller.dart';
import 'package:speedygo_merchant_app/features/orders/presentation/order_public_reference.dart';
import 'package:speedygo_merchant_app/features/support/application/support_controllers.dart';
import 'package:speedygo_merchant_app/features/support/data/support_models.dart';
import 'package:speedygo_merchant_app/features/support/presentation/order_support_screen.dart';
import 'package:speedygo_merchant_app/features/support/presentation/support_center_screen.dart';

/// Ticket thread with reply. No Stitch reference exists for this state; it
/// uses the support-centre tokens.
class SupportTicketScreen extends ConsumerStatefulWidget {
  const SupportTicketScreen({super.key, required this.ticketId});

  final String ticketId;

  @override
  ConsumerState<SupportTicketScreen> createState() =>
      _SupportTicketScreenState();
}

class _SupportTicketScreenState extends ConsumerState<SupportTicketScreen> {
  final _reply = TextEditingController();
  bool _sending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _reply.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _reply.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _reply.text.trim();
    final merchantId = ref
        .read(accessControllerProvider)
        .membership
        ?.merchantId;
    if (text.isEmpty || merchantId == null || _sending) return;
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await ref
          .read(merchantApiProvider)
          .replySupportTicket(
            merchantId: merchantId,
            ticketId: widget.ticketId,
            body: text,
          );
      if (!mounted) return;
      _reply.clear();
      ref.invalidate(supportTicketProvider(widget.ticketId));
      ref.invalidate(supportTicketsProvider);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = AppStrings.supportReplyError);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final async = ref.watch(supportTicketProvider(widget.ticketId));
    final accountId = ref.watch(
      sessionControllerProvider.select((s) => s.accountId),
    );
    final detail = async.value;

    return MerchantScaffold(
      title: AppStrings.supportTicketTitle,
      subtitle: detail?.summary.publicReference,
      headerColor: AppColors.surface,
      titleStyle: theme.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
        color: AppColors.onSurface,
      ),
      bodyPadding: EdgeInsets.zero,
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Padding(
          padding: const EdgeInsets.all(16),
          child: MerchantCard(
            key: const Key('support-ticket-error'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(AppStrings.supportTicketLoadError),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton(
                    key: const Key('support-ticket-retry'),
                    onPressed: () =>
                        ref.invalidate(supportTicketProvider(widget.ticketId)),
                    child: Text(AppStrings.retry),
                  ),
                ),
              ],
            ),
          ),
        ),
        data: (d) => Column(
          key: const Key('support-ticket'),
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Row(
                    children: [
                      SupportStatusChip(status: d.summary.status),
                      if (d.summary.createdAt != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          AppStrings.supportDate(d.summary.createdAt!),
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (d.orderPublicReference != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      AppStrings.supportLinkedOrder,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    OrderPublicReferenceLine(
                      reference: d.orderPublicReference!,
                    ),
                  ],
                  const SizedBox(height: 16),
                  if (d.messages.isEmpty)
                    Text(
                      AppStrings.supportNoMessages,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    )
                  else
                    for (final m in d.messages) ...[
                      _MessageBubble(
                        message: m,
                        mine: m.authorAccountId == accountId,
                      ),
                      const SizedBox(height: 12),
                    ],
                ],
              ),
            ),
            if (d.summary.status.isFinished)
              Container(
                key: const Key('support-ticket-finished'),
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                color: AppColors.surfaceContainerLow,
                child: SafeArea(
                  top: false,
                  child: Text(
                    AppStrings.supportTicketFinished,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ),
              )
            else
              MerchantStickyBar(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_error != null) ...[
                      Text(
                        _error!,
                        key: const Key('support-reply-error'),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.error,
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: TextField(
                            key: const Key('support-reply-body'),
                            controller: _reply,
                            minLines: 1,
                            maxLines: 4,
                            maxLength: supportBodyMaxLength,
                            buildCounter: (
                              _, {
                              required currentLength,
                              required isFocused,
                              maxLength,
                            }) => null,
                            decoration: InputDecoration(
                              hintText: AppStrings.supportReplyHint,
                              isDense: true,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filled(
                          key: const Key('support-reply-send'),
                          tooltip: AppStrings.supportReplySend,
                          onPressed: _reply.text.trim().isEmpty || _sending
                              ? null
                              : _send,
                          icon: const Icon(Icons.send),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message, required this.mine});

  final SupportMessage message;
  final bool mine;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final author = mine
        ? AppStrings.supportYou
        : (message.displayName ?? AppStrings.supportTeam);
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.8,
        ),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: mine
                ? AppColors.primaryContainer
                : AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(12),
            border: mine ? null : Border.all(color: AppColors.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                author,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: mine
                      ? AppColors.onPrimaryContainer
                      : AppColors.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                message.body,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: mine ? AppColors.onPrimary : AppColors.onSurface,
                ),
              ),
              if (message.createdAt != null) ...[
                const SizedBox(height: 4),
                Text(
                  AppStrings.supportDate(message.createdAt!),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: mine
                        ? AppColors.onPrimaryContainer
                        : AppColors.outline,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
