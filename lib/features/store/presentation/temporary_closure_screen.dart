import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:speedygo_merchant_app/app/theme/app_theme.dart';
import 'package:speedygo_merchant_app/core/constants/app_strings.dart';
import 'package:speedygo_merchant_app/core/errors/app_exception.dart';
import 'package:speedygo_merchant_app/core/widgets/merchant_ui.dart';
import 'package:speedygo_merchant_app/features/access/application/access_controller.dart';
import 'package:speedygo_merchant_app/features/orders/application/orders_controller.dart';
import 'package:speedygo_merchant_app/features/store/application/opening_hours_format.dart';
import 'package:speedygo_merchant_app/features/store/application/store_controllers.dart';

/// Temporary / indefinite closure form (French ref).
class TemporaryClosureScreen extends ConsumerStatefulWidget {
  const TemporaryClosureScreen({super.key, this.presetMinutes});

  final int? presetMinutes;

  @override
  ConsumerState<TemporaryClosureScreen> createState() =>
      _TemporaryClosureScreenState();
}

enum _ReopenKind { minutes30, minutes60, custom, indefinite }

class _TemporaryClosureScreenState
    extends ConsumerState<TemporaryClosureScreen> {
  String? _reasonCode = 'PEAK_KITCHEN';
  late _ReopenKind _kind;
  DateTime? _customUntilUtc;
  final _messageCtrl = TextEditingController();
  bool _saving = false;
  String? _error;

  static List<(String, String, IconData)> get _reasons => [
        (
          'PEAK_KITCHEN',
          AppStrings.availabilityReasonPeak,
          Icons.restaurant_outlined,
        ),
        (
          'TECHNICAL',
          AppStrings.availabilityReasonTechnical,
          Icons.engineering_outlined,
        ),
        (
          'OUT_OF_STOCK',
          AppStrings.availabilityReasonStock,
          Icons.inventory_2_outlined,
        ),
        (
          'LUNCH_BREAK',
          AppStrings.availabilityReasonLunch,
          Icons.timer_outlined,
        ),
      ];

  @override
  void initState() {
    super.initState();
    _kind = widget.presetMinutes == 60
        ? _ReopenKind.minutes60
        : _ReopenKind.minutes30;
  }

  @override
  void dispose() {
    _messageCtrl.dispose();
    super.dispose();
  }

  DateTime _now() => ref.read(storeClockProvider)().toUtc();

  String _atLabel(DateTime utc) {
    final local = utc.add(branchUtcOffset);
    final today = branchLocalNow(_now());
    final sameDay =
        local.year == today.year &&
        local.month == today.month &&
        local.day == today.day;
    return AppStrings.temporaryClosureAt(
      today: sameDay,
      hhmm: formatHhMm(local.hour * 60 + local.minute),
    );
  }

  Future<void> _pickCustom() async {
    final previous = _kind;
    final seed = (_customUntilUtc ?? _now().add(const Duration(hours: 1))).add(
      branchUtcOffset,
    );
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: seed.hour, minute: seed.minute),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (!mounted) return;
    if (picked == null) {
      setState(() {
        if (_customUntilUtc == null) {
          _kind = previous == _ReopenKind.custom
              ? _ReopenKind.minutes30
              : previous;
        }
      });
      return;
    }
    setState(() {
      _customUntilUtc = _nextOccurrenceUtc(picked);
      _kind = _ReopenKind.custom;
      _error = null;
    });
  }

  /// Next branch-local occurrence of [time] after now, as UTC.
  DateTime _nextOccurrenceUtc(TimeOfDay time) {
    final now = _now();
    final local = branchLocalNow(now);
    var until = DateTime.utc(
      local.year,
      local.month,
      local.day,
      time.hour,
      time.minute,
    ).subtract(branchUtcOffset);
    if (!until.isAfter(now)) until = until.add(const Duration(days: 1));
    return until;
  }

  DateTime? _closedUntil() {
    final now = _now();
    return switch (_kind) {
      _ReopenKind.minutes30 => now.add(const Duration(minutes: 30)),
      _ReopenKind.minutes60 => now.add(const Duration(hours: 1)),
      _ReopenKind.custom => _customUntilUtc,
      _ReopenKind.indefinite => null,
    };
  }

  Future<void> _confirm() async {
    final message = _messageCtrl.text.trim().isEmpty
        ? null
        : _messageCtrl.text.trim();
    DateTime? until;
    if (_kind != _ReopenKind.indefinite) {
      until = _closedUntil();
      if (until == null || !until.isAfter(_now())) {
        setState(() => _error = AppStrings.temporaryClosurePastTime);
        return;
      }
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final notifier = ref.read(branchAvailabilityControllerProvider.notifier);
      if (until == null) {
        await notifier.save(
          mode: 'FORCE_CLOSED',
          reasonCode: _reasonCode,
          customerMessage: message,
        );
      } else {
        await notifier.save(
          mode: 'TEMPORARY_CLOSED',
          reasonCode: _reasonCode,
          customerMessage: message,
          closedUntil: until.toIso8601String(),
        );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.availabilityClosureSaved)),
      );
      context.pop();
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
    final canManage = branchRoleCanManage(access.membership?.role ?? '');
    final activeCount = ref.watch(homeOrderCountsProvider).value?.active;
    final availability = ref.watch(branchAvailabilityControllerProvider);
    final availabilityReady = availability.hasValue && !availability.isLoading;

    return MerchantScaffold(
      title: AppStrings.temporaryClosureTitle,
      subtitle: access.selectedBranch?.name,
      titleStyle: theme.textTheme.titleLarge?.copyWith(
        color: AppColors.primary,
        fontWeight: FontWeight.w600,
      ),
      bodyPadding: EdgeInsets.zero,
      body: !canManage
          ? Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                key: const Key('temporary-closure-readonly'),
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.lock_outline,
                    color: AppColors.onSurfaceVariant,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      AppStrings.temporaryClosureStaffReadOnly,
                      style: theme.textTheme.bodyLarge,
                    ),
                  ),
                ],
              ),
            )
          : Column(
              key: const Key('temporary-closure-screen'),
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    children: [
                      _ImpactCard(activeCount: activeCount),
                      const SizedBox(height: 24),
                      _SectionTitle(AppStrings.temporaryClosureReason),
                      const SizedBox(height: 12),
                      for (final r in _reasons) ...[
                        _ReasonTile(
                          code: r.$1,
                          label: r.$2,
                          icon: r.$3,
                          selected: _reasonCode == r.$1,
                          onTap: () => setState(() => _reasonCode = r.$1),
                        ),
                        const SizedBox(height: 12),
                      ],
                      const SizedBox(height: 12),
                      _SectionTitle(AppStrings.temporaryClosureReopen),
                      const SizedBox(height: 12),
                      _ReopenField(
                        kind: _kind,
                        customLabel: _customUntilUtc == null
                            ? AppStrings.temporaryClosurePickTime
                            : _atLabel(_customUntilUtc!),
                        onChanged: (v) {
                          if (v == _ReopenKind.custom) {
                            _pickCustom();
                            return;
                          }
                          setState(() {
                            _kind = v;
                            _error = null;
                          });
                        },
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: _SectionTitle(
                              AppStrings.temporaryClosureMessage,
                            ),
                          ),
                          Text(
                            AppStrings.temporaryClosureOptional.toUpperCase(),
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        key: const Key('temporary-closure-message'),
                        controller: _messageCtrl,
                        maxLines: 3,
                        maxLength: 500,
                        decoration: InputDecoration(
                          hintText: AppStrings.temporaryClosureMessageHint,
                          filled: true,
                          fillColor: AppColors.surfaceContainerLowest,
                          contentPadding: const EdgeInsets.all(16),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppColors.outlineVariant,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppColors.outlineVariant,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const _VisibilityCard(),
                      if (availability.hasError && !availability.isLoading) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                AppStrings.availabilityLoadError,
                                style: TextStyle(color: AppColors.error),
                              ),
                            ),
                            TextButton(
                              key: const Key('temporary-closure-retry'),
                              onPressed: () => ref
                                  .read(
                                    branchAvailabilityControllerProvider
                                        .notifier,
                                  )
                                  .reload(),
                              child: Text(AppStrings.retry),
                            ),
                          ],
                        ),
                      ],
                      if (_error != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          _error!,
                          key: const Key('temporary-closure-error'),
                          style: const TextStyle(color: AppColors.error),
                        ),
                      ],
                    ],
                  ),
                ),
                MerchantStickyBar(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.info_outline,
                            size: 18,
                            color: AppColors.onSurfaceVariant,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              AppStrings.temporaryClosureManualReopenHint,
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: FilledButton(
                          key: const Key('temporary-closure-confirm'),
                          style: FilledButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: _saving || !availabilityReady
                              ? null
                              : _confirm,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Flexible(
                                child: Text(
                                  _saving
                                      ? AppStrings.availabilitySaving
                                      : AppStrings.temporaryClosureConfirm,
                                  maxLines: 2,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              const SizedBox(width: 8),
                              _saving
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.lock_clock, size: 20),
                            ],
                          ),
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

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.titleMedium
          ?.copyWith(fontWeight: FontWeight.w600),
    );
  }
}

class _ImpactCard extends StatelessWidget {
  const _ImpactCard({required this.activeCount});

  final int? activeCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final body = theme.textTheme.bodyMedium?.copyWith(
      color: AppColors.onErrorContainer,
    );
    final count = activeCount;
    return Container(
      key: const Key('temporary-closure-impact'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.errorContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.1)),
        boxShadow: merchantCardShadow,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning, color: AppColors.error),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.temporaryClosureActionRequired,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: AppColors.onErrorContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text.rich(
                  TextSpan(
                    style: body,
                    children: [
                      TextSpan(
                        text: AppStrings.temporaryClosureImpactLead,
                      ),
                      if (count == null)
                        TextSpan(
                          text: AppStrings.temporaryClosureImpactUnknown,
                        )
                      else if (count == 0)
                        TextSpan(
                          text: AppStrings.temporaryClosureImpactNone,
                        )
                      else ...[
                        TextSpan(
                          text: AppStrings.temporaryClosureImpactCount(count),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        TextSpan(
                          text: AppStrings.temporaryClosureImpactTail(count),
                        ),
                      ],
                    ],
                  ),
                  key: const Key('temporary-closure-impact-text'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReopenField extends StatelessWidget {
  const _ReopenField({
    required this.kind,
    required this.customLabel,
    required this.onChanged,
  });

  final _ReopenKind kind;
  final String customLabel;
  final ValueChanged<_ReopenKind> onChanged;

  @override
  Widget build(BuildContext context) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.outlineVariant),
    );
    return KeyedSubtree(
      key: ValueKey('$kind|$customLabel'),
      child: _dropdown(context, border),
    );
  }

  Widget _dropdown(BuildContext context, InputBorder border) {
    return DropdownButtonFormField<_ReopenKind>(
      key: const Key('temporary-closure-preset'),
      initialValue: kind,
      isExpanded: true,
      style: Theme.of(context).textTheme.bodyMedium
          ?.copyWith(color: AppColors.onSurface),
      icon: const Icon(Icons.expand_more, color: AppColors.onSurfaceVariant),
      decoration: InputDecoration(
        prefixIcon: const Icon(
          Icons.schedule,
          color: AppColors.onSurfaceVariant,
        ),
        filled: true,
        fillColor: AppColors.surfaceContainerLowest,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: border,
        enabledBorder: border,
      ),
      items: [
        DropdownMenuItem(
          value: _ReopenKind.minutes30,
          child: Text(AppStrings.temporaryClosure30m),
        ),
        DropdownMenuItem(
          value: _ReopenKind.minutes60,
          child: Text(AppStrings.temporaryClosure1h),
        ),
        DropdownMenuItem(
          key: const Key('temporary-closure-custom'),
          value: _ReopenKind.custom,
          child: Text(customLabel, overflow: TextOverflow.ellipsis),
        ),
        DropdownMenuItem(
          value: _ReopenKind.indefinite,
          child: Text(AppStrings.temporaryClosureIndefinite),
        ),
      ],
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }
}

class _VisibilityCard extends StatelessWidget {
  const _VisibilityCard();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      key: const Key('temporary-closure-visibility'),
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/temporary_closure_kitchen.jpg',
              fit: BoxFit.cover,
              excludeFromSemantics: true,
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.6),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Container(
            constraints: const BoxConstraints(minHeight: 160),
            width: double.infinity,
            alignment: Alignment.bottomLeft,
            padding: const EdgeInsets.fromLTRB(16, 48, 16, 16),
            child: Text(
              AppStrings.temporaryClosureImageImpact,
              style: Theme.of(context).textTheme.labelLarge
                  ?.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReasonTile extends StatelessWidget {
  const _ReasonTile({
    required this.code,
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String code;
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? AppColors.surfaceContainer
          : AppColors.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: selected ? AppColors.primary : AppColors.outlineVariant,
        ),
      ),
      child: InkWell(
        key: Key('temporary-closure-reason-$code'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                icon,
                color: selected
                    ? AppColors.primary
                    : AppColors.onSurfaceVariant,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(color: AppColors.onSurface),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
