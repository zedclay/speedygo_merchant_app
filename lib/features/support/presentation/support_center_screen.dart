import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:speedygo_merchant_app/app/theme/app_theme.dart';
import 'package:speedygo_merchant_app/core/constants/app_strings.dart';
import 'package:speedygo_merchant_app/core/errors/app_exception.dart';
import 'package:speedygo_merchant_app/core/navigation/app_routes.dart';
import 'package:speedygo_merchant_app/core/widgets/merchant_ui.dart';
import 'package:speedygo_merchant_app/features/access/application/access_controller.dart';
import 'package:speedygo_merchant_app/features/auth/application/auth_infrastructure.dart';
import 'package:speedygo_merchant_app/features/store/application/store_controllers.dart';
import 'package:speedygo_merchant_app/features/support/application/support_controllers.dart';
import 'package:speedygo_merchant_app/features/support/data/support_models.dart';
import 'package:speedygo_merchant_app/features/support/presentation/order_support_screen.dart';
import 'package:speedygo_merchant_app/features/support/presentation/support_topic_picker.dart';

/// Merchant support centre (`merchant_support_french`). Topic tiles and FAQ
/// articles come from the server; a ticket needs a topic, a subject and a
/// message. Creating tickets is OWNER/MANAGER only.
class SupportCenterScreen extends ConsumerWidget {
  const SupportCenterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final merchantName =
        ref.watch(accessControllerProvider).membership?.merchantName ?? '';
    final async = ref.watch(supportTicketsProvider);
    final canContact = merchantRoleCanContactSupport(
      ref.watch(accessControllerProvider).membership?.role,
    );
    final now = ref.watch(storeClockProvider)();

    return MerchantScaffold(
      title: AppStrings.supportCenterTitle,
      subtitle: merchantName.toUpperCase(),
      headerColor: AppColors.surface,
      titleStyle: theme.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
        color: AppColors.onSurface,
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(supportTicketsProvider.future),
        child: ListView(
          key: const Key('support-center'),
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(vertical: 24),
          children: [
            if (canContact)
              SizedBox(
                height: 56,
                child: FilledButton.icon(
                  key: const Key('support-new-ticket'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primaryContainer,
                    foregroundColor: AppColors.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    textStyle: theme.textTheme.titleMedium?.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  onPressed: () => _compose(context, ref),
                  icon: const Icon(Icons.add_circle),
                  label: const Text(AppStrings.supportNewTicket),
                ),
              ),
            if (canContact) const SizedBox(height: 24),
            ...async.when(
              loading: () => const [
                Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(),
                  ),
                ),
              ],
              error: (_, _) => [
                MerchantCard(
                  key: const Key('support-load-error'),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.supportLoadError,
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: FilledButton(
                          key: const Key('support-retry'),
                          onPressed: () =>
                              ref.invalidate(supportTicketsProvider),
                          child: const Text(AppStrings.retry),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              data: (page) =>
                  _ticketSections(context, ref, page, now, canContact),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _ticketSections(
    BuildContext context,
    WidgetRef ref,
    SupportTicketPage? page,
    DateTime now,
    bool canContact,
  ) {
    final theme = Theme.of(context);
    final items = page?.items ?? const <SupportTicketSummary>[];
    final topics = [
      if (canContact) ...[
        _SupportTopics(
          onPick: (code) =>
              showSupportCompose(context, ref, initialTopicCode: code),
        ),
        const SizedBox(height: 24),
      ],
      const _SupportFaq(),
      const SizedBox(height: 24),
    ];
    if (items.isEmpty) {
      return [
        Text(
          AppStrings.supportNoTickets,
          key: const Key('support-empty'),
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 24),
        ...topics,
      ];
    }
    final active = [
      for (final t in items)
        if (!t.status.isFinished) t,
    ];
    final finished = [
      for (final t in items)
        if (t.status.isFinished) t,
    ];
    return [
      if (active.isNotEmpty) ...[
        _SectionHeader(
          title: AppStrings.supportActiveTickets,
          count: active.length,
        ),
        const SizedBox(height: 12),
        for (final t in active) ...[
          _ActiveTicketCard(ticket: t, now: now),
          const SizedBox(height: 12),
        ],
        const SizedBox(height: 12),
      ],
      ...topics,
      if (finished.isNotEmpty) ...[
        const _SectionHeader(title: AppStrings.supportResolvedTickets),
        const SizedBox(height: 12),
        _ResolvedList(tickets: finished),
      ],
      if (page != null && page.total > items.length) ...[
        const SizedBox(height: 16),
        Text(
          AppStrings.supportShowingLatest(items.length, page.total),
          key: const Key('support-partial'),
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
      ],
    ];
  }

  Future<void> _compose(BuildContext context, WidgetRef ref) =>
      showSupportCompose(context, ref);
}

/// Opens the new-ticket sheet; on success refreshes the ticket list and
/// confirms with the public ticket reference.
/// [initialTopicCode] preselects a server topic (topic tiles).
Future<void> showSupportCompose(
  BuildContext context,
  WidgetRef ref, {
  String? initialTopicCode,
}) async {
  final reference = await showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: AppColors.surface,
    builder: (_) => _ComposeSheet(initialTopicCode: initialTopicCode),
  );
  if (reference == null || !context.mounted) return;
  ref.invalidate(supportTicketsProvider);
  ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(AppStrings.supportCreated(reference))));
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.count});

  final String title;
  final int? count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Flexible(
          child: Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        if (count != null) ...[
          const SizedBox(width: 8),
          Container(
            key: const Key('support-active-count'),
            constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
            padding: const EdgeInsets.symmetric(horizontal: 6),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.primaryContainer,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '$count',
              style: theme.textTheme.labelSmall?.copyWith(
                color: AppColors.onPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _ActiveTicketCard extends StatelessWidget {
  const _ActiveTicketCard({required this.ticket, required this.now});

  final SupportTicketSummary ticket;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final updated = ticket.updatedAt;
    return Material(
      color: AppColors.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: AppColors.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: Key('support-ticket-${ticket.id}'),
        onTap: () => context.push(AppRoutes.supportTicket(ticket.id)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  ticket.orderId != null
                      ? Icons.shopping_bag_outlined
                      : Icons.support_agent,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ticket.displayTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        SupportStatusChip(status: ticket.status),
                        if (updated != null)
                          Text(
                            '• ${AppStrings.supportUpdated(updated, now)}',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: AppColors.onSurfaceVariant,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, color: AppColors.outline),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResolvedList extends StatelessWidget {
  const _ResolvedList({required this.tickets});

  final List<SupportTicketSummary> tickets;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < tickets.length; i++) ...[
            if (i > 0) const Divider(height: 1),
            Opacity(
              opacity: 0.75,
              child: InkWell(
                key: Key('support-ticket-${tickets[i].id}'),
                onTap: () =>
                    context.push(AppRoutes.supportTicket(tickets[i].id)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.check_circle_outline,
                          color: AppColors.outline,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tickets[i].displayTitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text: AppStrings.supportStatus(
                                      tickets[i].status.name,
                                    ).toUpperCase(),
                                    style: const TextStyle(
                                      color: Color(0xFF07883B),
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  if (tickets[i].updatedAt != null)
                                    TextSpan(
                                      text:
                                          ' • ${AppStrings.supportDate(tickets[i].updatedAt!)}',
                                    ),
                                ],
                              ),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: AppColors.outline,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: AppColors.outline),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class SupportStatusChip extends StatelessWidget {
  const SupportStatusChip({super.key, required this.status});

  final SupportTicketStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.secondaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        AppStrings.supportStatus(status.name).toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: AppColors.onSecondaryContainer,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

IconData _topicIcon(String code) {
  final c = code.toUpperCase();
  if (c.contains('ORDER') || c.contains('DELIVER')) {
    return Icons.local_shipping_outlined;
  }
  if (c.contains('CATALOG') || c.contains('PRODUCT')) {
    return Icons.inventory_2_outlined;
  }
  if (c.contains('PAYMENT') || c.contains('BILLING') || c.contains('PAYOUT')) {
    return Icons.payments_outlined;
  }
  if (c.contains('PROFILE') || c.contains('ACCOUNT') || c.contains('VERIF')) {
    return Icons.verified_user_outlined;
  }
  return Icons.help_outline;
}

class _SupportTopics extends ConsumerWidget {
  const _SupportTopics({required this.onPick});

  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final topics = ref.watch(supportTopicsProvider);
    return Column(
      key: const Key('support-topics'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.supportTopicsTitle,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          AppStrings.supportTopicsHint,
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        ...topics.when(
          loading: () => const [
            Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            ),
          ],
          error: (_, _) => [
            Row(
              children: [
                Expanded(
                  child: Text(
                    AppStrings.supportTopicsLoadError,
                    key: const Key('support-topics-error'),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.error,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => ref.invalidate(supportTopicsProvider),
                  child: const Text(AppStrings.retry),
                ),
              ],
            ),
          ],
          data: (items) => items.isEmpty
              ? [
                  Text(
                    AppStrings.supportTopicsEmpty,
                    key: const Key('support-topics-empty'),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ]
              : [
                  for (var i = 0; i < items.length; i += 2) ...[
                    if (i > 0) const SizedBox(height: 12),
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (var j = i; j < i + 2; j++) ...[
                            if (j > i) const SizedBox(width: 12),
                            Expanded(
                              child: j < items.length
                                  ? _TopicTile(
                                      key: Key(
                                        'support-topic-${items[j].code}',
                                      ),
                                      icon: _topicIcon(items[j].code),
                                      label: items[j].labelFr,
                                      onTap: () => onPick(items[j].code),
                                    )
                                  : const SizedBox.shrink(),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ],
        ),
      ],
    );
  }
}

class _SupportFaq extends ConsumerWidget {
  const _SupportFaq();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final faq = ref.watch(supportFaqProvider);
    return Column(
      key: const Key('support-faq'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.supportFaqTitle,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        ...faq.when(
          loading: () => const [
            Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            ),
          ],
          error: (_, _) => [
            Row(
              children: [
                Expanded(
                  child: Text(
                    AppStrings.supportFaqLoadError,
                    key: const Key('support-faq-error'),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.error,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => ref.invalidate(supportFaqProvider),
                  child: const Text(AppStrings.retry),
                ),
              ],
            ),
          ],
          data: (items) => items.isEmpty
              ? [
                  Text(
                    AppStrings.supportFaqEmpty,
                    key: const Key('support-faq-empty'),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ]
              : [
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.outlineVariant),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        for (var i = 0; i < items.length; i++) ...[
                          if (i > 0) const Divider(height: 1),
                          Theme(
                            data: theme.copyWith(
                              dividerColor: Colors.transparent,
                            ),
                            child: ExpansionTile(
                              key: Key('support-faq-${items[i].slug}'),
                              title: Text(
                                items[i].titleFr,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              expandedCrossAxisAlignment:
                                  CrossAxisAlignment.start,
                              childrenPadding: const EdgeInsets.fromLTRB(
                                16,
                                0,
                                16,
                                16,
                              ),
                              children: [
                                Text(
                                  items[i].bodyFr,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: AppColors.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
        ),
      ],
    );
  }
}

class _TopicTile extends StatelessWidget {
  const _TopicTile({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      button: true,
      child: Material(
        color: AppColors.surfaceContainerLowest,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: AppColors.outlineVariant),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primaryFixed.withValues(alpha: 0.4),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 22, color: AppColors.onSurface),
                ),
                const SizedBox(height: 12),
                Text(
                  label,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ComposeSheet extends ConsumerStatefulWidget {
  const _ComposeSheet({this.initialTopicCode});

  final String? initialTopicCode;

  @override
  ConsumerState<_ComposeSheet> createState() => _ComposeSheetState();
}

class _ComposeSheetState extends ConsumerState<_ComposeSheet> {
  final _subject = TextEditingController();
  final _body = TextEditingController();
  String? _topicCode;
  bool _sending = false;
  bool _submitted = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _topicCode = widget.initialTopicCode;
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
    final merchantId = ref
        .read(accessControllerProvider)
        .membership
        ?.merchantId;
    if (_body.text.trim().isEmpty || merchantId == null || _sending) return;
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
            body: _body.text.trim(),
          );
      if (!mounted) return;
      Navigator.of(context).pop(reference);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _sending = false;
        _error = e.statusCode == 403
            ? AppStrings.supportForbidden
            : AppStrings.supportSendError;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _sending = false;
        _error = AppStrings.supportSendError;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        0,
        16,
        16 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            key: const Key('support-compose'),
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                AppStrings.supportComposeTitle,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                AppStrings.supportComposeHint,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              SupportTopicPicker(
                selectedCode: _topicCode,
                onSelected: (code) => setState(() => _topicCode = code),
                errorText: _submitted && _topicCode == null
                    ? AppStrings.supportTopicRequired
                    : null,
              ),
              const SizedBox(height: 16),
              TextField(
                key: const Key('support-compose-subject'),
                controller: _subject,
                maxLength: supportSubjectMaxLength,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: '${AppStrings.supportSubjectLabel} *',
                  hintText: AppStrings.supportSubjectHint,
                  errorText: _submitted && _subject.text.trim().isEmpty
                      ? AppStrings.supportSubjectRequired
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                key: const Key('support-compose-body'),
                controller: _body,
                minLines: 4,
                maxLines: 8,
                maxLength: supportBodyMaxLength,
                decoration: InputDecoration(
                  hintText: AppStrings.supportDescriptionLabel,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(
                  _error!,
                  key: const Key('support-compose-error'),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.error,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              SizedBox(
                height: 48,
                child: FilledButton(
                  key: const Key('support-compose-send'),
                  onPressed: _body.text.trim().isEmpty || _sending
                      ? null
                      : _send,
                  child: Text(_sending ? '…' : AppStrings.supportSend),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
