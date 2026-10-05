import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:speedygo_merchant_app/app/theme/app_theme.dart';
import 'package:speedygo_merchant_app/core/constants/app_strings.dart';
import 'package:speedygo_merchant_app/core/errors/app_exception.dart';
import 'package:speedygo_merchant_app/core/navigation/app_routes.dart';
import 'package:speedygo_merchant_app/core/widgets/merchant_ui.dart';
import 'package:speedygo_merchant_app/features/access/application/access_controller.dart';
import 'package:speedygo_merchant_app/features/store/application/opening_hours_format.dart';
import 'package:speedygo_merchant_app/features/store/application/store_controllers.dart';
import 'package:speedygo_merchant_app/features/store/data/store_models.dart';

const _fallbackInterval = OpeningInterval(opens: '09:00', closes: '17:00');

class OpeningHoursScreen extends ConsumerStatefulWidget {
  const OpeningHoursScreen({super.key});

  @override
  ConsumerState<OpeningHoursScreen> createState() => _OpeningHoursScreenState();
}

class _OpeningHoursScreenState extends ConsumerState<OpeningHoursScreen> {
  Map<int, List<OpeningInterval>>? _draft;
  int? _draftVersion;

  /// Intervals of days switched off in this session, restored on re-enable.
  final Map<int, List<OpeningInterval>> _remembered = {};
  bool _saving = false;
  String? _error;

  Map<int, List<OpeningInterval>> _fromSchedule(OpeningHoursSchedule s) {
    final byDow = {for (final d in s.days) d.dayOfWeek: d.intervals};
    return {
      for (var dow = 1; dow <= 7; dow++)
        dow: List.unmodifiable(byDow[dow] ?? const <OpeningInterval>[]),
    };
  }

  void _setDay(int dow, List<OpeningInterval> intervals) {
    setState(() {
      _draft = {..._draft!, dow: List.unmodifiable(intervals)};
      _error = null;
    });
  }

  Future<void> _toggle(int dow, bool on) async {
    final current = _draft![dow]!;
    if (!on) {
      if (current.isNotEmpty) _remembered[dow] = current;
      _setDay(dow, const []);
      return;
    }
    final restored = _remembered[dow];
    if (restored != null && restored.isNotEmpty) {
      _setDay(dow, restored);
      return;
    }
    await _edit(dow, seed: const [_fallbackInterval]);
  }

  Future<void> _edit(int dow, {List<OpeningInterval>? seed}) async {
    final result = await showModalBottomSheet<List<OpeningInterval>>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: AppColors.surface,
      builder: (_) => _DayEditorSheet(
        dayLabel: openingHoursDayLabels[dow]!,
        initial: seed ?? _draft![dow]!,
      ),
    );
    if (result == null || !mounted) return;
    if (result.isEmpty && _draft![dow]!.isNotEmpty) {
      _remembered[dow] = _draft![dow]!;
    }
    _setDay(dow, result);
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    final days = [
      for (var dow = 1; dow <= 7; dow++)
        OpeningDay(dayOfWeek: dow, intervals: _draft![dow]!),
    ];
    try {
      await ref.read(openingHoursControllerProvider.notifier).save(days);
      if (!mounted) return;
      setState(() => _draft = null);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.openingHoursSaved)),
      );
    } catch (e) {
      if (!mounted) return;
      final code = e is ApiException ? e.code : null;
      final conflict =
          code == 'OPENING_HOURS_VERSION_CONFLICT' ||
          (e is ApiException && e.statusCode == 409);
      setState(() {
        if (conflict) _draft = null;
        _error = conflict
            ? AppStrings.openingHoursConflict
            : code == 'OPENING_HOURS_INVALID'
            ? AppStrings.openingHoursInvalid
            : AppStrings.openingHoursSaveError;
      });
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(openingHoursControllerProvider);
    final access = ref.watch(accessControllerProvider);
    final canManage = branchRoleCanManage(access.membership?.role ?? '');
    final availability = ref.watch(branchAvailabilityControllerProvider).value;
    final openNow = availability?.isOpenNow;
    final todayException = availability?.hoursException;

    return MerchantScaffold(
      title: AppStrings.openingHoursTitle,
      titleStyle: Theme.of(context).textTheme.titleLarge
          ?.copyWith(color: AppColors.onSurface, fontWeight: FontWeight.w600),
      bodyPadding: EdgeInsets.zero,
      body: async.when(
        loading: () => const LoadingBody(),
        error: (_, _) => ErrorBody(
          message: AppStrings.openingHoursLoadError,
          onRetry: () =>
              ref.read(openingHoursControllerProvider.notifier).reload(),
        ),
        data: (schedule) {
          if (_draft == null || _draftVersion != schedule.version) {
            _draft = _fromSchedule(schedule);
            _draftVersion = schedule.version;
          }
          final draft = _draft!;
          return Column(
            key: const Key('opening-hours-screen'),
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  children: [
                    _StatusCard(
                      branchName:
                          access.selectedBranch?.name ??
                          access.membership?.merchantName ??
                          '',
                      configured: schedule.hoursConfigured,
                      openNow: openNow,
                    ),
                    const SizedBox(height: 24),
                    _WeekCard(
                      draft: draft,
                      canManage: canManage,
                      onToggle: _saving ? null : _toggle,
                      onEdit: _saving ? null : (dow) => _edit(dow),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _error!,
                        key: const Key('opening-hours-error'),
                        style: const TextStyle(color: AppColors.error),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Container(
                      decoration: _cardDecoration(),
                      clipBehavior: Clip.antiAlias,
                      child: MerchantNavRow(
                        key: const Key('opening-hours-exceptions-link'),
                        icon: Icons.event_note_outlined,
                        title: AppStrings.hoursExceptionsTitle,
                        subtitle: todayException == null
                            ? AppStrings.hoursExceptionsNavSub
                            : AppStrings.hoursExceptionsToday(todayException.label.toString(), ),
                        onTap: _saving
                            ? null
                            : () => context.push(
                                AppRoutes.openingHoursExceptions,
                              ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (!canManage) ...[
                      _Note(
                        key: Key('opening-hours-readonly'),
                        icon: Icons.lock_outline,
                        text: AppStrings.openingHoursStaffReadOnly,
                      ),
                      const SizedBox(height: 12),
                    ],
                    _Note(
                      icon: Icons.info_outline,
                      text: AppStrings.openingHoursInfo,
                    ),
                  ],
                ),
              ),
              if (canManage)
                MerchantStickyBar(
                  child: SizedBox(
                    height: 52,
                    child: FilledButton(
                      key: const Key('opening-hours-save'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primaryContainer,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _saving ? null : _save,
                      child: Text(
                        _saving
                            ? AppStrings.loading
                            : AppStrings.openingHoursSave,
                        maxLines: 2,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

BoxDecoration _cardDecoration() => BoxDecoration(
  color: AppColors.surfaceContainerLowest,
  borderRadius: BorderRadius.circular(12),
  border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.3)),
  boxShadow: merchantCardShadow,
);

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.branchName,
    required this.configured,
    required this.openNow,
  });

  final String branchName;
  final bool configured;
  final bool? openNow;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final stacked = MediaQuery.textScalerOf(context).scale(1) >= 1.25;
    final names = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          branchName,
          key: const Key('opening-hours-branch'),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          configured
              ? AppStrings.openingHoursUsual
              : AppStrings.openingHoursNotConfigured,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
      ],
    );
    final pill = openNow == null ? null : _OpenPill(open: openNow!);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: stacked || pill == null
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                names,
                if (pill != null) ...[const SizedBox(height: 8), pill],
              ],
            )
          : Row(
              children: [
                Expanded(child: names),
                const SizedBox(width: 8),
                pill,
              ],
            ),
    );
  }
}

class _OpenPill extends StatelessWidget {
  const _OpenPill({required this.open});

  final bool open;

  @override
  Widget build(BuildContext context) {
    final fg = open ? AppColors.tertiaryContainer : AppColors.error;
    return Container(
      key: const Key('opening-hours-open-pill'),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: open
            ? AppColors.tertiaryFixedDim.withValues(alpha: 0.2)
            : AppColors.errorContainer,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: open ? AppColors.tertiaryFixedDim : AppColors.error,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: fg, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            open
                ? AppStrings.openingHoursOpenNow
                : AppStrings.openingHoursClosedNow,
            style: Theme.of(context).textTheme.labelMedium
                ?.copyWith(color: fg, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _WeekCard extends StatelessWidget {
  const _WeekCard({
    required this.draft,
    required this.canManage,
    required this.onToggle,
    required this.onEdit,
  });

  final Map<int, List<OpeningInterval>> draft;
  final bool canManage;
  final Future<void> Function(int dow, bool on)? onToggle;
  final void Function(int dow)? onEdit;

  @override
  Widget build(BuildContext context) {
    final divider = Divider(
      height: 1,
      thickness: 1,
      color: AppColors.outlineVariant.withValues(alpha: 0.3),
    );
    return Container(
      decoration: _cardDecoration(),
      clipBehavior: Clip.antiAlias,
      child: Material(
        type: MaterialType.transparency,
        child: Column(
          children: [
            for (final dow in openingHoursDisplayOrder) ...[
              if (dow != openingHoursDisplayOrder.first) divider,
              _DayRow(
                dow: dow,
                intervals: draft[dow]!,
                canManage: canManage,
                onToggle: onToggle,
                onEdit: onEdit,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DayRow extends StatelessWidget {
  const _DayRow({
    required this.dow,
    required this.intervals,
    required this.canManage,
    required this.onToggle,
    required this.onEdit,
  });

  final int dow;
  final List<OpeningInterval> intervals;
  final bool canManage;
  final Future<void> Function(int dow, bool on)? onToggle;
  final void Function(int dow)? onEdit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final stacked = MediaQuery.textScalerOf(context).scale(1) >= 1.25;
    final open = intervals.isNotEmpty;
    final day = Text(
      openingHoursDayLabels[dow]!,
      style: theme.textTheme.bodyLarge?.copyWith(
        color: AppColors.onSurface,
        fontWeight: FontWeight.w400,
      ),
    );
    final hours = Text(
      open
          ? (stacked
                ? intervals.map(formatInterval).join('\n')
                : formatIntervalsUnbroken(intervals))
          : AppStrings.openingHoursClosed,
      key: Key('opening-hours-day-$dow'),
      textAlign: stacked ? TextAlign.start : TextAlign.center,
      style: theme.textTheme.bodyMedium?.copyWith(
        color: AppColors.onSurfaceVariant,
      ),
    );
    final controls = canManage
        ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _HoursSwitch(
                key: Key('opening-hours-switch-$dow'),
                value: open,
                onChanged: onToggle == null ? null : (v) => onToggle!(dow, v),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right,
                size: 20,
                color: AppColors.onSurfaceVariant,
              ),
            ],
          )
        : null;
    final content = stacked
        ? Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [day, const SizedBox(height: 2), hours],
                ),
              ),
              ?controls,
            ],
          )
        : Row(
            children: [
              SizedBox(width: 96, child: day),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: hours,
                ),
              ),
              ?controls,
            ],
          );
    return InkWell(
      key: Key('opening-hours-row-$dow'),
      onTap: canManage && onEdit != null ? () => onEdit!(dow) : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: content,
      ),
    );
  }
}

class _HoursSwitch extends StatelessWidget {
  const _HoursSwitch({super.key, required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      height: 24,
      child: FittedBox(
        fit: BoxFit.contain,
        child: Switch(
          value: value,
          onChanged: onChanged,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          trackOutlineColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected)
                ? Colors.transparent
                : AppColors.outlineVariant,
          ),
          trackColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected)
                ? AppColors.primaryContainer
                : AppColors.surfaceContainer,
          ),
          thumbColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected)
                ? AppColors.onPrimary
                : AppColors.outline,
          ),
          thumbIcon: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected)
                ? const Icon(
                    Icons.check,
                    size: 16,
                    color: AppColors.primaryContainer,
                  )
                : null,
          ),
        ),
      ),
    );
  }
}

class _Note extends StatelessWidget {
  const _Note({super.key, required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(
              icon,
              size: 20,
              color: AppColors.onSurfaceVariant.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.onSurfaceVariant.withValues(alpha: 0.8),
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DayEditorSheet extends StatefulWidget {
  const _DayEditorSheet({required this.dayLabel, required this.initial});

  final String dayLabel;
  final List<OpeningInterval> initial;

  @override
  State<_DayEditorSheet> createState() => _DayEditorSheetState();
}

class _DayEditorSheetState extends State<_DayEditorSheet> {
  late List<OpeningInterval> _intervals = List.of(widget.initial);
  String? _issue;

  void _add() {
    if (_intervals.length >= openingHoursMaxIntervalsPerDay) return;
    final last = _intervals.isEmpty ? null : parseHhMm(_intervals.last.closes);
    final start = last == null ? 9 * 60 : (last + 60) % (24 * 60);
    setState(() {
      _intervals = [
        ..._intervals,
        OpeningInterval(
          opens: formatHhMm(start),
          closes: formatHhMm((start + 120) % (24 * 60)),
        ),
      ];
      _issue = null;
    });
  }

  void _apply() {
    final issue = validateDayIntervals(_intervals);
    if (issue != null) {
      setState(() {
        _issue = switch (issue) {
          OpeningDayIssue.overlap => AppStrings.openingHoursIssueOverlap,
          OpeningDayIssue.zeroLength => AppStrings.openingHoursIssueZero,
          OpeningDayIssue.tooMany => AppStrings.openingHoursIssueTooMany,
          OpeningDayIssue.invalid => AppStrings.openingHoursInvalid,
        };
      });
      return;
    }
    Navigator.of(context).pop(List<OpeningInterval>.unmodifiable(_intervals));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      key: const Key('day-editor-sheet'),
      padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + bottom),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.dayLabel,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                AppStrings.openingHoursEditorHint,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              if (_intervals.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    AppStrings.openingHoursDayClosedHint,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ),
              for (var i = 0; i < _intervals.length; i++) ...[
                _IntervalRow(
                  index: i,
                  interval: _intervals[i],
                  onChanged: (next) => setState(() {
                    _intervals = List.of(_intervals)..[i] = next;
                    _issue = null;
                  }),
                  onRemove: () => setState(() {
                    _intervals = List.of(_intervals)..removeAt(i);
                    _issue = null;
                  }),
                ),
                const SizedBox(height: 12),
              ],
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: TextButton.icon(
                  key: const Key('day-editor-add'),
                  onPressed: _intervals.length >= openingHoursMaxIntervalsPerDay
                      ? null
                      : _add,
                  icon: const Icon(Icons.add),
                  label: Text(AppStrings.openingHoursAddRange),
                ),
              ),
              if (_issue != null) ...[
                const SizedBox(height: 8),
                Text(
                  _issue!,
                  key: const Key('day-editor-error'),
                  style: const TextStyle(color: AppColors.error),
                ),
              ],
              const SizedBox(height: 16),
              SizedBox(
                height: 52,
                child: FilledButton(
                  key: const Key('day-editor-apply'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primaryContainer,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _apply,
                  child: Text(AppStrings.openingHoursApply),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IntervalRow extends StatelessWidget {
  const _IntervalRow({
    required this.index,
    required this.interval,
    required this.onChanged,
    required this.onRemove,
  });

  final int index;
  final OpeningInterval interval;
  final ValueChanged<OpeningInterval> onChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final o = parseHhMm(interval.opens);
    final c = parseHhMm(interval.closes);
    final allDay = o == 0 && c == 0;
    final nextDay = !allDay && o != null && c != null && c < o;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _TimeField(
                key: Key('day-editor-opens-$index'),
                label: AppStrings.openingHoursOpens,
                value: interval.opens,
                onChanged: (v) => onChanged(
                  OpeningInterval(opens: v, closes: interval.closes),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _TimeField(
                key: Key('day-editor-closes-$index'),
                label: AppStrings.openingHoursCloses,
                value: interval.closes,
                onChanged: (v) => onChanged(
                  OpeningInterval(opens: interval.opens, closes: v),
                ),
              ),
            ),
            IconButton(
              key: Key('day-editor-remove-$index'),
              tooltip: AppStrings.openingHoursRemoveRange,
              onPressed: onRemove,
              icon: const Icon(Icons.delete_outline, color: AppColors.error),
            ),
          ],
        ),
        if (nextDay || allDay)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 4),
            child: Text(
              allDay
                  ? AppStrings.openingHoursAllDay
                  : AppStrings.openingHoursNextDay,
              style: Theme.of(context).textTheme.labelMedium
                  ?.copyWith(color: AppColors.onSurfaceVariant),
            ),
          ),
      ],
    );
  }
}

class _TimeField extends StatelessWidget {
  const _TimeField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () async {
        final minute = parseHhMm(value) ?? 9 * 60;
        final picked = await showTimePicker(
          context: context,
          initialTime: TimeOfDay(hour: minute ~/ 60, minute: minute % 60),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
            child: child!,
          ),
        );
        if (picked != null) {
          onChanged(formatHhMm(picked.hour * 60 + picked.minute));
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(labelText: label),
        child: Text(value, style: Theme.of(context).textTheme.titleMedium),
      ),
    );
  }
}
