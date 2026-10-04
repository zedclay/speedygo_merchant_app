import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:speedygo_merchant_app/app/theme/app_theme.dart';
import 'package:speedygo_merchant_app/core/constants/app_strings.dart';
import 'package:speedygo_merchant_app/core/navigation/app_routes.dart';
import 'package:speedygo_merchant_app/core/widgets/merchant_ui.dart';
import 'package:speedygo_merchant_app/features/notifications/application/order_alert_controller.dart';
import 'package:speedygo_merchant_app/features/orders/presentation/order_public_reference.dart';
import 'package:speedygo_merchant_app/features/store/application/opening_hours_format.dart';
import 'package:speedygo_merchant_app/features/store/application/store_controllers.dart';
import 'package:speedygo_merchant_app/features/store/data/store_models.dart';

enum _NotifFilter { all, orders }

final _orderRefInBody = RegExp(r'sgo_[0-9a-fA-F]+');

/// Whether the text "Tout marquer comme lu" fits beside the full title at
/// the current width and text scale; otherwise the icon action is used.
bool _markAllTextFits(BuildContext context, ThemeData theme) {
  final scaler = MediaQuery.textScalerOf(context);
  final direction = Directionality.of(context);
  double widthOf(String text, TextStyle? style) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: direction,
      textScaler: scaler,
      maxLines: 1,
    )..layout();
    final width = painter.width;
    painter.dispose();
    return width;
  }

  final title = widthOf(
    AppStrings.notificationsTitle,
    theme.textTheme.titleLarge?.copyWith(
      fontSize: 20,
      fontWeight: FontWeight.w600,
    ),
  );
  final label = widthOf(
    AppStrings.notificationsMarkAllRead,
    theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
  );
  // Back button, title, toolbar spacing, button padding and end inset.
  final needed = kToolbarHeight + title + 16 + label + 16 + 8;
  return needed <= MediaQuery.sizeOf(context).width;
}

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  _NotifFilter _filter = _NotifFilter.all;

  Future<void> _refresh() async {
    ref.read(orderAlertControllerProvider.notifier).reconcile(reason: 'manual');
    await ref.read(notificationsControllerProvider.notifier).reload();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final async = ref.watch(notificationsControllerProvider);
    final now = ref.watch(storeClockProvider)();
    final hasUnread = async.value?.any((n) => !n.read) ?? false;
    final stacked = !_markAllTextFits(context, theme);
    final VoidCallback? markAll = hasUnread
        ? () => ref.read(notificationsControllerProvider.notifier).markAllRead()
        : null;

    return MerchantScaffold(
      title: AppStrings.notificationsTitle,
      headerColor: AppColors.surface,
      headerHeight: 56,
      titleSpacing: 0,
      titleStyle: theme.textTheme.titleLarge?.copyWith(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppColors.onSurface,
      ),
      actions: [
        if (stacked)
          IconButton(
            key: const Key('notifications-mark-all'),
            tooltip: AppStrings.notificationsMarkAllRead,
            color: AppColors.primary,
            onPressed: markAll,
            icon: const Icon(Icons.done_all),
          )
        else
          TextButton(
            key: const Key('notifications-mark-all'),
            onPressed: markAll,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              textStyle: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            child: const Text(AppStrings.notificationsMarkAllRead),
          ),
        const SizedBox(width: 8),
      ],
      body: async.when(
        loading: () => const LoadingBody(),
        error: (_, _) => ErrorBody(
          message: AppStrings.notificationsLoadError,
          onRetry: () =>
              ref.read(notificationsControllerProvider.notifier).reload(),
        ),
        data: (items) {
          final filtered = items.where((n) {
            if (_filter == _NotifFilter.orders) {
              return n.type == 'MERCHANT_ORDER_CREATED';
            }
            return true;
          }).toList();
          final groups = _groupByDay(filtered, now);
          return Column(
            children: [
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Row(
                    children: [
                      _FilterPill(
                        key: const Key('notif-filter-all'),
                        label: AppStrings.notificationsFilterAll,
                        selected: _filter == _NotifFilter.all,
                        onTap: () => setState(() => _filter = _NotifFilter.all),
                      ),
                      const SizedBox(width: 8),
                      _FilterPill(
                        key: const Key('notif-filter-orders'),
                        label: AppStrings.notificationsFilterOrders,
                        selected: _filter == _NotifFilter.orders,
                        onTap: () =>
                            setState(() => _filter = _NotifFilter.orders),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _refresh,
                  child: filtered.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: const [
                            SizedBox(height: 48),
                            Text(
                              AppStrings.notificationsEmpty,
                              key: Key('notifications-empty'),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        )
                      : ListView.builder(
                          key: const Key('notifications-screen'),
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.only(bottom: 24),
                          itemCount: groups.length,
                          itemBuilder: (context, index) {
                            final group = groups[index];
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (index > 0) const SizedBox(height: 16),
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: Text(
                                    group.label.toUpperCase(),
                                    style: theme.textTheme.labelLarge?.copyWith(
                                      color: AppColors.outline,
                                      letterSpacing: 0.8,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                for (final n in group.items)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: _NotificationTile(
                                      item: n,
                                      now: now,
                                      onOpen: () => _openItem(n),
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _openItem(MerchantNotificationItem item) async {
    if (!item.read) {
      await ref
          .read(notificationsControllerProvider.notifier)
          .markRead(item.id);
    }
    final orderId = item.sourceId;
    if (item.type == 'MERCHANT_ORDER_CREATED' &&
        orderId != null &&
        orderId.isNotEmpty) {
      ref.read(orderAlertControllerProvider.notifier).markOrderHandled(orderId);
      if (!mounted) return;
      context.push(AppRoutes.orderDetail(orderId));
    }
  }
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? AppColors.primary : AppColors.surfaceContainerHigh,
        shape: const StadiumBorder(),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: selected
                    ? AppColors.onPrimary
                    : AppColors.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.item,
    required this.now,
    required this.onOpen,
  });

  final MerchantNotificationItem item;
  final DateTime now;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isOrder = item.type == 'MERCHANT_ORDER_CREATED';
    final (IconData icon, Color bg, Color fg) = switch (item.type) {
      'MERCHANT_ORDER_CREATED' => (
        Icons.shopping_basket_outlined,
        AppColors.primaryFixed,
        AppColors.primary,
      ),
      'SETTLEMENT_FINALIZED' => (
        Icons.account_balance_wallet_outlined,
        AppColors.secondaryContainer,
        AppColors.onSecondaryContainer,
      ),
      _ => (
        Icons.notifications_outlined,
        AppColors.surfaceContainerHigh,
        AppColors.onSurfaceVariant,
      ),
    };
    final publicRef = _extractPublicReference(item.body);
    final bodyWithoutRef = publicRef == null
        ? item.body
        : item.body
              .replaceFirst(publicRef, '')
              .replaceAll(RegExp(r'\s{2,}'), ' ')
              .trim();
    final time = _relativeTime(item.createdAt, now);
    final radius = BorderRadius.circular(12);
    return DecoratedBox(
      key: Key('notification-${item.id}'),
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: merchantCardShadow,
      ),
      child: Material(
        color: AppColors.surfaceContainerLowest,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onOpen,
          child: Container(
            decoration: item.read
                ? null
                : const BoxDecoration(
                    border: Border(
                      left: BorderSide(color: AppColors.primary, width: 4),
                    ),
                  ),
            padding: EdgeInsets.fromLTRB(item.read ? 16 : 12, 16, 16, 16),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: bg,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: fg),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  item.title,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              if (time.isNotEmpty) ...[
                                const SizedBox(width: 8),
                                Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: Text(
                                    time,
                                    key: Key('notification-time-${item.id}'),
                                    style: theme.textTheme.labelMedium
                                        ?.copyWith(color: AppColors.outline),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          if (bodyWithoutRef.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              bodyWithoutRef,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                          ],
                          if (publicRef != null) ...[
                            const SizedBox(height: 4),
                            OrderPublicReferenceLine(reference: publicRef),
                          ],
                          if (isOrder) ...[
                            const SizedBox(height: 12),
                            SizedBox(
                              height: 40,
                              child: FilledButton(
                                key: Key('notification-details-${item.id}'),
                                onPressed: onOpen,
                                style: FilledButton.styleFrom(
                                  backgroundColor:
                                      AppColors.surfaceContainerHigh,
                                  foregroundColor: AppColors.onSurface,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text(
                                  AppStrings.notificationsOpenDetails,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                if (!item.read)
                  Positioned(
                    top: -8,
                    right: -8,
                    child: Container(
                      key: Key('notification-unread-${item.id}'),
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
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

String? _extractPublicReference(String body) {
  final m = _orderRefInBody.firstMatch(body);
  return m?.group(0);
}

class _DayGroup {
  const _DayGroup({required this.label, required this.items});
  final String label;
  final List<MerchantNotificationItem> items;
}

String _two(int v) => v.toString().padLeft(2, '0');

List<_DayGroup> _groupByDay(
  List<MerchantNotificationItem> items,
  DateTime now,
) {
  final map = <String, List<MerchantNotificationItem>>{};
  final order = <String>[];
  final local = branchLocalNow(now);
  final today = DateTime.utc(local.year, local.month, local.day);
  final yesterday = today.subtract(const Duration(days: 1));

  for (final item in items) {
    final parsed = DateTime.tryParse(item.createdAt);
    final dt = parsed == null ? null : branchLocalNow(parsed);
    final day = dt == null ? null : DateTime.utc(dt.year, dt.month, dt.day);
    final key = day == null
        ? '—'
        : day == today
        ? AppStrings.notificationsToday
        : day == yesterday
        ? AppStrings.notificationsYesterday
        : '${_two(day.day)}/${_two(day.month)}/${day.year}';
    if (!map.containsKey(key)) {
      map[key] = [];
      order.add(key);
    }
    map[key]!.add(item);
  }

  return [for (final key in order) _DayGroup(label: key, items: map[key]!)];
}

/// "5 min", "2 h", "Hier", or `dd/MM` in Branch time.
String _relativeTime(String iso, DateTime now) {
  final at = DateTime.tryParse(iso);
  if (at == null) return '';
  final diff = now.toUtc().difference(at.toUtc());
  if (diff.inMinutes < 1) return AppStrings.notificationsJustNow;
  if (diff.inMinutes < 60) return '${diff.inMinutes} min';
  final local = branchLocalNow(at);
  final today = branchLocalNow(now);
  final sameDay =
      local.year == today.year &&
      local.month == today.month &&
      local.day == today.day;
  if (sameDay) return '${diff.inHours} h';
  final yesterday = DateTime.utc(
    today.year,
    today.month,
    today.day,
  ).subtract(const Duration(days: 1));
  if (DateTime.utc(local.year, local.month, local.day) == yesterday) {
    return AppStrings.notificationsYesterday;
  }
  return '${_two(local.day)}/${_two(local.month)}';
}
