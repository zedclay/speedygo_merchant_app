import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:speedygo_merchant_app/app/theme/app_theme.dart';
import 'package:speedygo_merchant_app/core/constants/app_strings.dart';
import 'package:speedygo_merchant_app/core/errors/app_exception.dart';
import 'package:speedygo_merchant_app/core/navigation/app_routes.dart';
import 'package:speedygo_merchant_app/core/widgets/merchant_ui.dart';
import 'package:speedygo_merchant_app/features/access/application/access_controller.dart';
import 'package:speedygo_merchant_app/features/orders/application/orders_controller.dart';
import 'package:speedygo_merchant_app/features/store/application/opening_hours_format.dart';
import 'package:speedygo_merchant_app/features/store/application/store_controllers.dart';
import 'package:speedygo_merchant_app/features/store/data/store_models.dart';

/// Store availability control — segment is Selon les horaires / Fermé.
/// Ouvert/Fermé badge comes only from server [isOpenNow].
class StoreAvailabilityScreen extends ConsumerStatefulWidget {
  const StoreAvailabilityScreen({super.key});

  @override
  ConsumerState<StoreAvailabilityScreen> createState() =>
      _StoreAvailabilityScreenState();
}

enum _DraftSegment { followSchedule, forceClosed }

class _StoreAvailabilityScreenState
    extends ConsumerState<StoreAvailabilityScreen> {
  _DraftSegment? _draft;
  bool _saving = false;
  String? _error;
  String? _serverVersionKey;

  _DraftSegment _segmentFrom(BranchAvailabilityState s) {
    if (s.availabilityMode == 'FORCE_CLOSED') {
      return _DraftSegment.forceClosed;
    }
    if (s.availabilityMode == 'TEMPORARY_CLOSED' && !s.temporaryExpired) {
      return _DraftSegment.forceClosed;
    }
    return _DraftSegment.followSchedule;
  }

  Future<void> _save(BranchAvailabilityState current) async {
    final segment = _draft ?? _segmentFrom(current);
    final mode = segment == _DraftSegment.followSchedule
        ? 'FOLLOW_SCHEDULE'
        : 'FORCE_CLOSED';

    if (mode == 'FOLLOW_SCHEDULE' && current.outsideWeeklyHours) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text(AppStrings.availabilityReopenTitle),
          content: const Text(AppStrings.availabilityReopenOutsideHoursBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text(AppStrings.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text(AppStrings.availabilityConfirmReopen),
            ),
          ],
        ),
      );
      if (ok != true) return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref
          .read(branchAvailabilityControllerProvider.notifier)
          .save(mode: mode);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.availabilitySaved)),
      );
    } catch (e) {
      if (!mounted) return;
      final conflict =
          e is ApiException &&
          (e.code == 'AVAILABILITY_VERSION_CONFLICT' || e.statusCode == 409);
      setState(() {
        _error = conflict
            ? AppStrings.availabilityConflict
            : (e is AppException
                  ? e.message
                  : AppStrings.availabilitySaveError);
      });
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final access = ref.watch(accessControllerProvider);
    final membership = access.membership;
    final branch = access.selectedBranch;
    final canManage = branchRoleCanManage(membership?.role ?? '');
    final async = ref.watch(branchAvailabilityControllerProvider);
    final activeCount = ref.watch(homeOrderCountsProvider).value?.active;
    final schedule = ref.watch(openingHoursControllerProvider).value;
    final now = ref.watch(storeClockProvider)();

    return MerchantScaffold(
      title: AppStrings.availabilityTitle,
      titleStyle: theme.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
        color: AppColors.primary,
      ),
      bodyPadding: EdgeInsets.zero,
      body: async.when(
        loading: () => const LoadingBody(),
        error: (_, _) => ErrorBody(
          message: AppStrings.availabilityLoadError,
          onRetry: () =>
              ref.read(branchAvailabilityControllerProvider.notifier).reload(),
        ),
        data: (state) {
          final versionKey = '${state.version}|${state.updatedAt}';
          if (_serverVersionKey != versionKey) {
            _serverVersionKey = versionKey;
            _draft = _segmentFrom(state);
          }
          final segment = _draft ?? _segmentFrom(state);
          final open = state.isOpenNow;
          final displayName =
              branch?.name ?? membership?.merchantName ?? AppStrings.homeTitle;
          final updatedAt = state.updatedAt == null
              ? null
              : DateTime.tryParse(state.updatedAt!);

          return Column(
            key: const Key('store-availability-screen'),
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  children: [
                    _Header(name: displayName, open: open),
                    const SizedBox(height: 24),
                    _SegmentControl(
                      segment: segment,
                      onFollow: canManage
                          ? () => setState(
                              () => _draft = _DraftSegment.followSchedule,
                            )
                          : null,
                      onClosed: canManage
                          ? () => setState(
                              () => _draft = _DraftSegment.forceClosed,
                            )
                          : null,
                    ),
                    const SizedBox(height: 12),
                    _StatusBanner(isOpenNow: open, segment: segment),
                    if (segment == _DraftSegment.forceClosed &&
                        _segmentFrom(state) != _DraftSegment.forceClosed) ...[
                      const SizedBox(height: 12),
                      _CloseWarning(activeCount: activeCount),
                    ],
                    const SizedBox(height: 24),
                    _ActiveOrdersCard(count: activeCount),
                    const SizedBox(height: 24),
                    _TodayCard(
                      intervals: schedule == null
                          ? null
                          : todayIntervals(schedule, now),
                      loaded: schedule != null,
                      canManage: canManage,
                    ),
                    if (canManage) ...[
                      const SizedBox(height: 16),
                      const _QuickPauseCard(),
                    ],
                    if (!canManage) ...[
                      const SizedBox(height: 16),
                      Text(
                        AppStrings.availabilityStaffReadOnly,
                        key: const Key('availability-readonly'),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _error!,
                        style: const TextStyle(color: AppColors.error),
                      ),
                    ],
                  ],
                ),
              ),
              if (canManage)
                MerchantStickyBar(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: FilledButton.icon(
                          key: const Key('availability-save'),
                          onPressed: _saving ? null : () => _save(state),
                          icon: _saving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.save_outlined),
                          label: Text(
                            _saving
                                ? AppStrings.availabilitySaving
                                : AppStrings.availabilitySave,
                            maxLines: 2,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      if (updatedAt != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            AppStrings.availabilityLastUpdate(updatedAt, now),
                            key: const Key('availability-last-update'),
                            textAlign: TextAlign.center,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.name, required this.open});

  final String name;
  final bool open;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppStrings.availabilityEstablishment.toUpperCase(),
                style: theme.textTheme.labelMedium?.copyWith(
                  color: AppColors.onSurfaceVariant,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                name,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              MerchantStatusPill(
                key: const Key('availability-open-badge'),
                label: open
                    ? AppStrings.availabilityOpen
                    : AppStrings.availabilityClosed,
                tone: open ? StatusTone.success : StatusTone.error,
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: AppColors.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.storefront,
            color: AppColors.onPrimaryContainer,
            size: 32,
          ),
        ),
      ],
    );
  }
}

class _SegmentControl extends StatelessWidget {
  const _SegmentControl({
    required this.segment,
    required this.onFollow,
    required this.onClosed,
  });

  final _DraftSegment segment;
  final VoidCallback? onFollow;
  final VoidCallback? onClosed;

  @override
  Widget build(BuildContext context) {
    final follow = segment == _DraftSegment.followSchedule;
    return Container(
      key: const Key('availability-segment'),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          Expanded(
            child: _SegBtn(
              key: const Key('availability-seg-follow'),
              label: AppStrings.availabilityFollowSchedule.toUpperCase(),
              selected: follow,
              selectedColor: AppColors.tertiaryFixed,
              selectedFg: AppColors.onTertiaryFixed,
              onTap: onFollow,
            ),
          ),
          Expanded(
            child: _SegBtn(
              key: const Key('availability-seg-closed'),
              label: AppStrings.availabilityForceClosed.toUpperCase(),
              selected: !follow,
              selectedColor: AppColors.error,
              selectedFg: Colors.white,
              onTap: onClosed,
            ),
          ),
        ],
      ),
    );
  }
}

class _SegBtn extends StatelessWidget {
  const _SegBtn({
    super.key,
    required this.label,
    required this.selected,
    required this.selectedColor,
    required this.selectedFg,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color selectedColor;
  final Color selectedFg;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? selectedColor : Colors.transparent,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: selected ? selectedFg : AppColors.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.isOpenNow, required this.segment});

  final bool isOpenNow;
  final _DraftSegment segment;

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color border;
    final Color titleFg;
    final Color bodyFg;
    final IconData icon;
    final String title;
    final String body;
    if (segment == _DraftSegment.forceClosed) {
      bg = AppColors.errorContainer;
      border = AppColors.error.withValues(alpha: 0.25);
      titleFg = AppColors.onErrorContainer;
      bodyFg = AppColors.onErrorContainer;
      icon = Icons.cancel_outlined;
      title = AppStrings.availabilityBannerClosedTitle;
      body = AppStrings.availabilityBannerClosedBody;
    } else if (isOpenNow) {
      bg = AppColors.tertiaryFixed.withValues(alpha: 0.3);
      border = AppColors.tertiaryFixedDim;
      titleFg = AppColors.tertiary;
      bodyFg = const Color(0xFF3D4C00);
      icon = Icons.check_circle_outline;
      title = AppStrings.availabilityBannerOpenTitle;
      body = AppStrings.availabilityBannerOpenBody;
    } else {
      bg = AppColors.warningWash;
      border = AppColors.warning.withValues(alpha: 0.3);
      titleFg = AppColors.warning;
      bodyFg = AppColors.warning;
      icon = Icons.schedule;
      title = AppStrings.availabilityBannerScheduleClosedTitle;
      body = AppStrings.availabilityBannerScheduleClosedBody;
    }
    return Container(
      key: const Key('availability-banner'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: titleFg),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(color: titleFg, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  body,
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(color: bodyFg),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CloseWarning extends StatelessWidget {
  const _CloseWarning({required this.activeCount});

  final int? activeCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      key: const Key('availability-close-warning'),
      decoration: BoxDecoration(
        color: AppColors.errorContainer.withValues(alpha: 0.2),
        borderRadius: const BorderRadius.horizontal(right: Radius.circular(12)),
        border: const Border(
          left: BorderSide(color: AppColors.error, width: 4),
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded, color: AppColors.error),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.availabilityCloseWarningTitle.toUpperCase(),
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: AppColors.error,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  AppStrings.availabilityCloseWarningBody(activeCount),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.onErrorContainer,
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

class _ActiveOrdersCard extends StatelessWidget {
  const _ActiveOrdersCard({required this.count});

  final int? count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.3),
        ),
        boxShadow: merchantCardShadow,
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: Color(0xFFDDE1FF),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.list_alt, color: Color(0xFF2D3F93)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              count == null
                  ? AppStrings.availabilityActiveOrdersUnknown
                  : AppStrings.availabilityActiveOrders(count!),
              key: const Key('availability-active-orders'),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: AppColors.surfaceContainerHigh,
            shape: const CircleBorder(),
            child: IconButton(
              key: const Key('availability-open-orders'),
              onPressed: () => context.go(AppRoutes.orders),
              icon: const Icon(Icons.chevron_right, color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}

class _TodayCard extends StatelessWidget {
  const _TodayCard({
    required this.intervals,
    required this.loaded,
    required this.canManage,
  });

  /// Null when hours are not configured (or not loaded yet).
  final List<OpeningInterval>? intervals;
  final bool loaded;
  final bool canManage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final big = theme.textTheme.headlineSmall?.copyWith(
      color: AppColors.primary,
      fontWeight: FontWeight.w700,
    );
    final Widget hours;
    if (!loaded) {
      hours = Text('—', style: big);
    } else if (intervals == null) {
      hours = Text(
        AppStrings.openingHoursEmpty,
        style: theme.textTheme.titleMedium?.copyWith(color: AppColors.primary),
      );
    } else if (intervals!.isEmpty) {
      hours = Text(AppStrings.availabilityClosedToday, style: big);
    } else {
      hours = Text(
        intervals!.map((i) => '${i.opens} - ${i.closes}').join('\n'),
        style: big,
      );
    }
    return Container(
      key: const Key('availability-today'),
      constraints: const BoxConstraints(minHeight: 120),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardLabel(
            icon: Icons.schedule,
            text: AppStrings.availabilityToday,
          ),
          const SizedBox(height: 8),
          hours,
          if (canManage) ...[
            const SizedBox(height: 8),
            InkWell(
              key: const Key('availability-modify-hours'),
              onTap: () => context.push(AppRoutes.openingHours),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      AppStrings.availabilityModifyHours,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.edit, size: 16, color: AppColors.primary),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _QuickPauseCard extends StatelessWidget {
  const _QuickPauseCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Widget pause(String label, int minutes) => Expanded(
      child: OutlinedButton(
        key: Key('availability-pause-$minutes'),
        style: OutlinedButton.styleFrom(
          backgroundColor: AppColors.surfaceContainerLowest,
          foregroundColor: AppColors.onSurface,
          side: const BorderSide(color: AppColors.outlineVariant),
          minimumSize: const Size(0, 40),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        onPressed: () => context.push(
          AppRoutes.temporaryClosure,
          extra: {'presetMinutes': minutes},
        ),
        child: Text(label, textAlign: TextAlign.center),
      ),
    );
    return Container(
      key: const Key('availability-quick-pause'),
      constraints: const BoxConstraints(minHeight: 120),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardLabel(
            icon: Icons.pause_circle_outline,
            text: AppStrings.availabilityQuickPause,
          ),
          const SizedBox(height: 8),
          Text(
            AppStrings.availabilityQuickPauseHint,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              pause(AppStrings.availabilityPause30, 30),
              const SizedBox(width: 8),
              pause(AppStrings.availabilityPause60, 60),
            ],
          ),
        ],
      ),
    );
  }
}

class _CardLabel extends StatelessWidget {
  const _CardLabel({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.onSurfaceVariant),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text.toUpperCase(),
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: AppColors.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
