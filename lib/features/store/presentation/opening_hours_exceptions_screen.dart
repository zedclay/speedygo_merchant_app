import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:speedygo_merchant_app/app/theme/app_theme.dart';
import 'package:speedygo_merchant_app/core/constants/app_strings.dart';
import 'package:speedygo_merchant_app/core/errors/app_exception.dart';
import 'package:speedygo_merchant_app/core/widgets/merchant_ui.dart';
import 'package:speedygo_merchant_app/features/access/application/access_controller.dart';
import 'package:speedygo_merchant_app/features/store/application/opening_hours_format.dart';
import 'package:speedygo_merchant_app/features/store/application/store_controllers.dart';
import 'package:speedygo_merchant_app/features/store/data/store_models.dart';

/// Mirrors backend `OPENING_HOURS_EXCEPTION_*` limits.
const _labelMax = 80;
const _messageMax = 500;
const _maxDaysAhead = 365;
const _maxUpcoming = 100;
const _defaultInterval = OpeningInterval(opens: '09:00', closes: '13:00');

class OpeningHoursExceptionsScreen extends ConsumerStatefulWidget {
  const OpeningHoursExceptionsScreen({super.key});

  @override
  ConsumerState<OpeningHoursExceptionsScreen> createState() =>
      _OpeningHoursExceptionsScreenState();
}

class _OpeningHoursExceptionsScreenState
    extends ConsumerState<OpeningHoursExceptionsScreen> {
  final _labelCtl = TextEditingController();
  final _messageCtl = TextEditingController();
  String? _date;
  String? _editingDate;
  var _closed = false;
  List<OpeningInterval> _intervals = const [_defaultInterval];
  var _saving = false;
  String? _deletingDate;
  String? _error;

  @override
  void dispose() {
    _labelCtl.dispose();
    _messageCtl.dispose();
    super.dispose();
  }

  bool get _dirty =>
      _date != null ||
      _editingDate != null ||
      _closed ||
      _labelCtl.text.isNotEmpty ||
      _messageCtl.text.isNotEmpty ||
      _intervals.length != 1 ||
      _intervals.first.opens != _defaultInterval.opens ||
      _intervals.first.closes != _defaultInterval.closes;

  void _resetForm() {
    setState(() {
      _date = null;
      _editingDate = null;
      _closed = false;
      _intervals = const [_defaultInterval];
      _labelCtl.clear();
      _messageCtl.clear();
      _error = null;
    });
  }

  void _editExisting(OpeningHoursException item) {
    setState(() {
      _date = item.date;
      _editingDate = item.date;
      _closed = item.closed;
      _intervals = item.closed || item.intervals.isEmpty
          ? const [_defaultInterval]
          : List.unmodifiable(item.intervals);
      _labelCtl.text = item.label;
      _messageCtl.text = item.customerMessage ?? '';
      _error = null;
    });
  }

  @visibleForTesting
  void debugSetDate(String date) => setState(() {
    _date = date;
    _error = null;
  });

  @visibleForTesting
  void debugSetIntervals(List<OpeningInterval> intervals) => setState(() {
    _intervals = List.unmodifiable(intervals);
    _error = null;
  });

  String _today(OpeningHoursExceptionList list) {
    if (parseCivilDate(list.today) != null) return list.today;
    return civilDateKey(branchLocalNow(ref.read(storeClockProvider)()));
  }

  Future<void> _pickDate(OpeningHoursExceptionList list) async {
    final today = parseCivilDate(_today(list))!;
    final first = DateTime(today.year, today.month, today.day);
    final last = first.add(const Duration(days: _maxDaysAhead));
    final current = _date == null ? null : parseCivilDate(_date!);
    var initial = current == null
        ? first
        : DateTime(current.year, current.month, current.day);
    if (initial.isBefore(first) || initial.isAfter(last)) initial = first;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: last,
    );
    if (picked == null || !mounted) return;
    setState(() {
      _date = civilDateKey(DateTime.utc(picked.year, picked.month, picked.day));
      _error = null;
    });
  }

  String? _validate(OpeningHoursExceptionList list) {
    final date = _date;
    if (date == null) return AppStrings.hoursExceptionsDateRequired;
    if (_labelCtl.text.trim().isEmpty) {
      return AppStrings.hoursExceptionsLabelRequired;
    }
    if (list.byDate(date) == null && list.items.length >= _maxUpcoming) {
      return AppStrings.hoursExceptionsTooMany;
    }
    if (_closed) return null;
    return switch (validateExceptionIntervals(_intervals)) {
      null => null,
      ExceptionIntervalIssue.empty =>
        AppStrings.hoursExceptionsIntervalsRequired,
      ExceptionIntervalIssue.tooMany => AppStrings.openingHoursIssueTooMany,
      ExceptionIntervalIssue.overlap => AppStrings.openingHoursIssueOverlap,
      ExceptionIntervalIssue.overnight ||
      ExceptionIntervalIssue.zeroLength ||
      ExceptionIntervalIssue.invalid => AppStrings.hoursExceptionsSameDay,
    };
  }

  Future<void> _save(OpeningHoursExceptionList list) async {
    if (_saving) return;
    final issue = _validate(list);
    if (issue != null) {
      setState(() => _error = issue);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final message = _messageCtl.text.trim();
    try {
      await ref
          .read(openingHoursExceptionsControllerProvider.notifier)
          .save(
            date: _date!,
            closed: _closed,
            intervals: _intervals,
            label: _labelCtl.text.trim(),
            customerMessage: message.isEmpty ? null : message,
          );
      if (!mounted) return;
      _resetForm();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.hoursExceptionsSaved)),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = _saveErrorMessage(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _saveErrorMessage(Object e) {
    if (e is! ApiException) return AppStrings.hoursExceptionsSaveError;
    return switch (e.code) {
      'OPENING_HOURS_EXCEPTION_VERSION_CONFLICT' ||
      'OPENING_HOURS_EXCEPTION_NOT_FOUND' => AppStrings.hoursExceptionsConflict,
      'OPENING_HOURS_EXCEPTION_WEEKLY_REQUIRED' =>
        AppStrings.hoursExceptionsWeeklyRequired,
      'OPENING_HOURS_EXCEPTION_INVALID' ||
      'VALIDATION_ERROR' => AppStrings.hoursExceptionsInvalid,
      _ when e.statusCode == 403 => AppStrings.hoursExceptionsStaffReadOnly,
      _ => AppStrings.hoursExceptionsSaveError,
    };
  }

  Future<void> _delete(OpeningHoursException item) async {
    if (_deletingDate != null || _saving) return;
    final label = formatCivilDateFr(item.date);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        key: const Key('hours-exception-delete-dialog'),
        title: const Text(AppStrings.hoursExceptionsDeleteTitle),
        content: Text(AppStrings.hoursExceptionsDeleteBody(label)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(AppStrings.hoursExceptionsCancel),
          ),
          TextButton(
            key: const Key('hours-exception-delete-confirm'),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(AppStrings.hoursExceptionsDeleteConfirm),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() {
      _deletingDate = item.date;
      _error = null;
    });
    try {
      await ref
          .read(openingHoursExceptionsControllerProvider.notifier)
          .delete(item.date);
      if (!mounted) return;
      if (_editingDate == item.date) _resetForm();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.hoursExceptionsDeleted)),
      );
    } catch (e) {
      if (!mounted) return;
      final stale =
          e is ApiException &&
          (e.code == 'OPENING_HOURS_EXCEPTION_VERSION_CONFLICT' ||
              e.code == 'OPENING_HOURS_EXCEPTION_NOT_FOUND');
      setState(() {
        _error = stale
            ? AppStrings.hoursExceptionsConflict
            : AppStrings.hoursExceptionsDeleteError;
      });
    } finally {
      if (mounted) setState(() => _deletingDate = null);
    }
  }

  void _cancel() {
    if (_dirty) {
      _resetForm();
    } else {
      context.pop();
    }
  }

  void _showHelp() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        key: const Key('hours-exception-help-dialog'),
        title: const Text(AppStrings.hoursExceptionsHelpTitle),
        content: const Text(AppStrings.hoursExceptionsHelpBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(AppStrings.hoursExceptionsHelpOk),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(openingHoursExceptionsControllerProvider);
    final access = ref.watch(accessControllerProvider);
    final canManage = branchRoleCanManage(access.membership?.role ?? '');
    final weeklyConfigured = ref
        .watch(openingHoursControllerProvider)
        .value
        ?.hoursConfigured;
    final theme = Theme.of(context);
    final stacked = MediaQuery.textScalerOf(context).scale(1) >= 1.25;

    return MerchantScaffold(
      title: AppStrings.hoursExceptionsTitle,
      titleStyle: theme.textTheme.titleLarge?.copyWith(
        color: AppColors.primary,
        fontWeight: FontWeight.w600,
      ),
      actions: [
        IconButton(
          key: const Key('hours-exception-help'),
          tooltip: AppStrings.hoursExceptionsHelpTitle,
          onPressed: _showHelp,
          icon: const Icon(Icons.help_outline),
        ),
      ],
      bodyPadding: EdgeInsets.zero,
      body: async.when(
        loading: () => const LoadingBody(),
        error: (_, _) => ErrorBody(
          message: AppStrings.hoursExceptionsLoadError,
          onRetry: () => ref
              .read(openingHoursExceptionsControllerProvider.notifier)
              .reload(),
        ),
        data: (list) {
          final busy = _saving || _deletingDate != null;
          return Column(
            key: const Key('hours-exceptions-screen'),
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  children: [
                    const _InfoBanner(text: AppStrings.hoursExceptionsBanner),
                    const SizedBox(height: 24),
                    Text(
                      AppStrings.hoursExceptionsUpcoming,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (list.items.isEmpty)
                      Text(
                        AppStrings.hoursExceptionsEmpty,
                        key: const Key('hours-exceptions-empty'),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    for (final item in list.items) ...[
                      _ExceptionCard(
                        item: item,
                        selected: item.date == _editingDate,
                        deleting: item.date == _deletingDate,
                        onTap: canManage && !busy
                            ? () => _editExisting(item)
                            : null,
                        onDelete: canManage && !busy
                            ? () => _delete(item)
                            : null,
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (_error != null && !canManage) ...[
                      Text(
                        _error!,
                        key: const Key('hours-exception-error'),
                        style: const TextStyle(color: AppColors.error),
                      ),
                      const SizedBox(height: 12),
                    ],
                    const SizedBox(height: 12),
                    if (canManage) ...[
                      const Divider(
                        color: AppColors.outlineVariant,
                        indent: 8,
                        endIndent: 8,
                      ),
                      const SizedBox(height: 12),
                      if (weeklyConfigured == false) ...[
                        const _Note(
                          key: Key('hours-exception-weekly-required'),
                          icon: Icons.warning_amber_outlined,
                          text: AppStrings.hoursExceptionsWeeklyRequired,
                        ),
                        const SizedBox(height: 12),
                      ],
                      _buildForm(context, list, busy),
                    ] else
                      const _Note(
                        key: Key('hours-exception-readonly'),
                        icon: Icons.lock_outline,
                        text: AppStrings.hoursExceptionsStaffReadOnly,
                      ),
                  ],
                ),
              ),
              if (canManage)
                MerchantStickyBar(
                  child: Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 52,
                          child: OutlinedButton(
                            key: const Key('hours-exception-cancel'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.onSurface,
                              side: const BorderSide(color: AppColors.outline),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: busy ? null : _cancel,
                            child: const Text(
                              AppStrings.hoursExceptionsCancel,
                              maxLines: 2,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: stacked ? 1 : 2,
                        child: SizedBox(
                          height: 52,
                          child: FilledButton(
                            key: const Key('hours-exception-save'),
                            style: FilledButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: busy || weeklyConfigured == false
                                ? null
                                : () => _save(list),
                            child: Text(
                              _saving
                                  ? AppStrings.loading
                                  : AppStrings.hoursExceptionsSave,
                              maxLines: 2,
                              textAlign: TextAlign.center,
                            ),
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

  Widget _buildForm(
    BuildContext context,
    OpeningHoursExceptionList list,
    bool busy,
  ) {
    final theme = Theme.of(context);
    final labelStyle = theme.textTheme.labelLarge?.copyWith(
      color: AppColors.onSurface,
      fontWeight: FontWeight.w600,
    );
    final taken =
        _date != null && _date != _editingDate && list.byDate(_date!) != null;
    return Container(
      key: const Key('hours-exception-form'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.add_circle, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _editingDate == null
                      ? AppStrings.hoursExceptionsAdd
                      : AppStrings.hoursExceptionsEdit,
                  key: const Key('hours-exception-form-title'),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(AppStrings.hoursExceptionsDate, style: labelStyle),
          const SizedBox(height: 4),
          InkWell(
            key: const Key('hours-exception-date'),
            borderRadius: BorderRadius.circular(8),
            onTap: busy || _editingDate != null ? null : () => _pickDate(list),
            child: InputDecorator(
              decoration: _fieldDecoration(
                prefixIcon: const Icon(Icons.calendar_month),
              ),
              child: Text(
                _date == null
                    ? AppStrings.hoursExceptionsDateHint
                    : formatCivilDateFr(_date!),
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: _date == null
                      ? AppColors.onSurfaceVariant
                      : AppColors.onSurface,
                ),
              ),
            ),
          ),
          if (taken) ...[
            const SizedBox(height: 4),
            Row(
              key: const Key('hours-exception-date-taken'),
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.warning, size: 14, color: AppColors.error),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    AppStrings.hoursExceptionsDateTaken,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.error,
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          Text(AppStrings.hoursExceptionsStatus, style: labelStyle),
          const SizedBox(height: 8),
          _StatusToggle(
            closed: _closed,
            onChanged: busy
                ? null
                : (closed) => setState(() {
                    _closed = closed;
                    _error = null;
                  }),
          ),
          if (!_closed) ...[
            const SizedBox(height: 16),
            Text(AppStrings.hoursExceptionsHours, style: labelStyle),
            const SizedBox(height: 4),
            for (var i = 0; i < _intervals.length; i++) ...[
              Row(
                children: [
                  Expanded(
                    child: _TimeField(
                      key: Key('hours-exception-opens-$i'),
                      value: _intervals[i].opens,
                      onChanged: busy
                          ? null
                          : (v) => setState(() {
                              _intervals = List.of(_intervals)
                                ..[i] = OpeningInterval(
                                  opens: v,
                                  closes: _intervals[i].closes,
                                );
                              _error = null;
                            }),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      AppStrings.hoursExceptionsTo,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ),
                  Expanded(
                    child: _TimeField(
                      key: Key('hours-exception-closes-$i'),
                      value: _intervals[i].closes,
                      onChanged: busy
                          ? null
                          : (v) => setState(() {
                              _intervals = List.of(_intervals)
                                ..[i] = OpeningInterval(
                                  opens: _intervals[i].opens,
                                  closes: v,
                                );
                              _error = null;
                            }),
                    ),
                  ),
                  if (_intervals.length > 1)
                    IconButton(
                      key: Key('hours-exception-remove-$i'),
                      tooltip: AppStrings.openingHoursRemoveRange,
                      onPressed: busy
                          ? null
                          : () => setState(() {
                              _intervals = List.of(_intervals)..removeAt(i);
                              _error = null;
                            }),
                      icon: const Icon(
                        Icons.delete_outline,
                        color: AppColors.error,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            Text(
              AppStrings.hoursExceptionsSameDay,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
            if (_intervals.length < openingHoursMaxIntervalsPerDay)
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: TextButton.icon(
                  key: const Key('hours-exception-add-range'),
                  onPressed: busy
                      ? null
                      : () => setState(() {
                          final last = parseHhMm(_intervals.last.closes) ?? 0;
                          final start = last == 0 ? 18 * 60 : last + 60;
                          final opens = start.clamp(0, 22 * 60);
                          _intervals = [
                            ..._intervals,
                            OpeningInterval(
                              opens: formatHhMm(opens),
                              closes: formatHhMm(opens + 60),
                            ),
                          ];
                          _error = null;
                        }),
                  icon: const Icon(Icons.add),
                  label: const Text(AppStrings.openingHoursAddRange),
                ),
              ),
          ],
          const SizedBox(height: 16),
          Text(AppStrings.hoursExceptionsLabel, style: labelStyle),
          const SizedBox(height: 4),
          TextField(
            key: const Key('hours-exception-label'),
            controller: _labelCtl,
            enabled: !busy,
            maxLength: _labelMax,
            textCapitalization: TextCapitalization.sentences,
            decoration: _fieldDecoration(
              hintText: AppStrings.hoursExceptionsLabelHint,
            ),
            onChanged: (_) => setState(() => _error = null),
          ),
          const SizedBox(height: 8),
          Text(AppStrings.hoursExceptionsMessage, style: labelStyle),
          const SizedBox(height: 4),
          TextField(
            key: const Key('hours-exception-message'),
            controller: _messageCtl,
            enabled: !busy,
            maxLength: _messageMax,
            minLines: 2,
            maxLines: 4,
            textCapitalization: TextCapitalization.sentences,
            decoration: _fieldDecoration(
              helperText: AppStrings.hoursExceptionsMessageHint,
              helperMaxLines: 5,
            ),
            onChanged: (_) => setState(() => _error = null),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              key: const Key('hours-exception-error'),
              style: const TextStyle(color: AppColors.error),
            ),
          ],
        ],
      ),
    );
  }
}

InputDecoration _fieldDecoration({
  Widget? prefixIcon,
  String? hintText,
  String? helperText,
  int? helperMaxLines,
}) {
  final border = OutlineInputBorder(
    borderRadius: BorderRadius.circular(8),
    borderSide: const BorderSide(color: AppColors.outlineVariant),
  );
  return InputDecoration(
    filled: true,
    fillColor: AppColors.surface,
    prefixIcon: prefixIcon,
    hintText: hintText,
    helperText: helperText,
    helperMaxLines: helperMaxLines,
    border: border,
    enabledBorder: border,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
  );
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('hours-exceptions-banner'),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.primaryFixed,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info, color: AppColors.onPrimaryFixed, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: AppColors.onPrimaryFixed),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExceptionCard extends StatelessWidget {
  const _ExceptionCard({
    required this.item,
    required this.selected,
    required this.deleting,
    required this.onTap,
    required this.onDelete,
  });

  final OpeningHoursException item;
  final bool selected;
  final bool deleting;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = item.closed ? AppColors.error : AppColors.tertiaryFixedDim;
    final hours = item.closed
        ? null
        : item.intervals.map((i) => '${i.opens} - ${i.closes}').join(', ');
    return Material(
      key: Key('hours-exception-card-${item.date}'),
      color: AppColors.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.outlineVariant,
              width: selected ? 2 : 1,
            ),
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(width: 4, color: accent),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 4, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              item.label,
                              style: theme.textTheme.labelLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            _StatusPill(closed: item.closed),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.calendar_today,
                                  size: 16,
                                  color: AppColors.onSurfaceVariant,
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    formatCivilDateFr(item.date),
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: AppColors.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (hours != null) ...[
                              const Text(
                                '•',
                                style: TextStyle(
                                  color: AppColors.outlineVariant,
                                ),
                              ),
                              Text(
                                hours,
                                key: Key('hours-exception-hours-${item.date}'),
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: AppColors.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                if (onDelete != null || deleting)
                  Center(
                    child: deleting
                        ? const Padding(
                            padding: EdgeInsets.all(14),
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : IconButton(
                            key: Key('hours-exception-delete-${item.date}'),
                            tooltip: AppStrings.hoursExceptionsDeleteConfirm,
                            onPressed: onDelete,
                            icon: const Icon(
                              Icons.delete_outline,
                              color: AppColors.outline,
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

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.closed});

  final bool closed;

  @override
  Widget build(BuildContext context) {
    final fg = closed
        ? AppColors.onErrorContainer
        : AppColors.onTertiaryFixedVariant;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: closed ? AppColors.errorContainer : AppColors.tertiaryFixed,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(closed ? Icons.event_busy : Icons.schedule, size: 14, color: fg),
          const SizedBox(width: 4),
          Text(
            closed
                ? AppStrings.hoursExceptionsClosed
                : AppStrings.hoursExceptionsOpen,
            style: Theme.of(context).textTheme.labelMedium
                ?.copyWith(color: fg, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _StatusToggle extends StatelessWidget {
  const _StatusToggle({required this.closed, required this.onChanged});

  final bool closed;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: _StatusOption(
              key: const Key('hours-exception-status-open'),
              selected: !closed,
              icon: Icons.check_circle,
              label: AppStrings.hoursExceptionsOpen,
              selectedColor: AppColors.primary,
              onTap: onChanged == null ? null : () => onChanged!(false),
            ),
          ),
          Expanded(
            child: _StatusOption(
              key: const Key('hours-exception-status-closed'),
              selected: closed,
              icon: Icons.cancel,
              label: AppStrings.hoursExceptionsClosed,
              selectedColor: AppColors.error,
              onTap: onChanged == null ? null : () => onChanged!(true),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusOption extends StatelessWidget {
  const _StatusOption({
    super.key,
    required this.selected,
    required this.icon,
    required this.label,
    required this.selectedColor,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final String label;
  final Color selectedColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? selectedColor : AppColors.onSurfaceVariant;
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? AppColors.surface : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 18, color: fg),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.labelLarge
                        ?.copyWith(color: fg, fontWeight: FontWeight.w600),
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

class _TimeField extends StatelessWidget {
  const _TimeField({super.key, required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onChanged == null
          ? null
          : () async {
              final minute = parseHhMm(value) ?? 9 * 60;
              final picked = await showTimePicker(
                context: context,
                initialTime: TimeOfDay(hour: minute ~/ 60, minute: minute % 60),
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(context)
                      .copyWith(alwaysUse24HourFormat: true),
                  child: child!,
                ),
              );
              if (picked != null) {
                onChanged!(formatHhMm(picked.hour * 60 + picked.minute));
              }
            },
      child: InputDecorator(
        decoration: _fieldDecoration(),
        child: Text(value, style: Theme.of(context).textTheme.titleMedium),
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColors.onSurfaceVariant),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(color: AppColors.onSurfaceVariant, height: 1.25),
          ),
        ),
      ],
    );
  }
}
