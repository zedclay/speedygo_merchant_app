import 'dart:async';

import 'package:flutter/material.dart';
import 'package:speedygo_merchant_app/app/theme/app_theme.dart';
import 'package:speedygo_merchant_app/core/constants/app_strings.dart';
import 'package:speedygo_merchant_app/core/widgets/merchant_ui.dart';
import 'package:speedygo_merchant_app/features/orders/presentation/order_public_reference.dart';
import 'package:speedygo_merchant_app/features/orders/presentation/prep_time_clock.dart';

const prepMinutePresets = <int>[15, 20, 25, 30, 45];

const prepCustomMinMinutes = 5;
const prepCustomMaxMinutes = 120;
const prepAddCustomMax = 60;

/// Bottom sheet: select preparation minutes then confirm accept.
/// [initialMinutes] restores a previous choice (e.g. after a failed accept).
Future<int?> showAcceptPreparationSheet(
  BuildContext context, {
  required String publicReference,
  required int itemCount,
  String? customerName,
  String? merchandise,
  String? address,
  String? branchName,
  int? initialMinutes,
}) {
  return showModalBottomSheet<int>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppColors.background,
    builder: (ctx) => _AcceptPrepSheet(
      publicReference: publicReference,
      itemCount: itemCount,
      customerName: customerName,
      merchandise: merchandise,
      address: address,
      branchName: branchName,
      initialMinutes: initialMinutes,
    ),
  );
}

class _AcceptPrepSheet extends StatefulWidget {
  const _AcceptPrepSheet({
    required this.publicReference,
    required this.itemCount,
    this.customerName,
    this.merchandise,
    this.address,
    this.branchName,
    this.initialMinutes,
  });

  final String publicReference;
  final int itemCount;
  final String? customerName;
  final String? merchandise;
  final String? address;
  final String? branchName;
  final int? initialMinutes;

  @override
  State<_AcceptPrepSheet> createState() => _AcceptPrepSheetState();
}

class _AcceptPrepSheetState extends State<_AcceptPrepSheet> {
  int _selected = 25;
  bool _custom = false;
  final _customController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final initial = widget.initialMinutes;
    if (initial == null) return;
    if (prepMinutePresets.contains(initial)) {
      _selected = initial;
    } else if (initial >= prepCustomMinMinutes &&
        initial <= prepCustomMaxMinutes) {
      _custom = true;
      _customController.text = '$initial';
    }
  }

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  int? get _customValue {
    final v = int.tryParse(_customController.text.trim());
    if (v == null || v < prepCustomMinMinutes || v > prepCustomMaxMinutes) {
      return null;
    }
    return v;
  }

  int? get _value => _custom ? _customValue : _selected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = widget.customerName;
    final branch = widget.branchName;
    final stacked = MediaQuery.textScalerOf(context).scale(1) >= 1.25;
    final amount = widget.merchandise == null
        ? null
        : Text(
            widget.merchandise!,
            style: theme.textTheme.titleLarge?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          );
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        key: const Key('accept-prep-sheet'),
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SheetHeader(
            title: AppStrings.prepAcceptTitle,
            subtitle: widget.publicReference,
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (branch != null && branch.isNotEmpty) ...[
                    _BranchBlock(name: branch),
                    const SizedBox(height: 16),
                  ],
                  if (name != null || widget.merchandise != null) ...[
                    MerchantCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: AppColors.secondaryContainer,
                                child: Text(
                                  (name == null || name.isEmpty)
                                      ? '?'
                                      : name.characters.first.toUpperCase(),
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: AppColors.onSecondaryContainer,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (name != null)
                                      Text(
                                        name,
                                        style: theme.textTheme.titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                    Text(
                                      AppStrings.prepItemCount(widget.itemCount.toString(), ),
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                            color: AppColors.onSurfaceVariant,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              if (amount != null && !stacked) ...[
                                const SizedBox(width: 8),
                                amount,
                              ],
                            ],
                          ),
                          if (amount != null && stacked) ...[
                            const SizedBox(height: 8),
                            amount,
                          ],
                          if (widget.address != null &&
                              widget.address!.isNotEmpty) ...[
                            Divider(
                              height: 24,
                              color: AppColors.outlineVariant.withValues(
                                alpha: 0.5,
                              ),
                            ),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.location_on_outlined,
                                  size: 20,
                                  color: AppColors.onSurfaceVariant,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    widget.address!,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: AppColors.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                  Text(
                    AppStrings.prepEstimatedTitle,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppStrings.prepSelectHint(widget.itemCount),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final half = (constraints.maxWidth - 12) / 2;
                      return Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          for (final m in prepMinutePresets)
                            SizedBox(
                              width: m == prepMinutePresets.last
                                  ? constraints.maxWidth
                                  : half,
                              child: _MinuteTile(
                                key: Key('prep-minutes-$m'),
                                value: '$m',
                                caption: AppStrings.prepMinutesCaption,
                                selected: !_custom && _selected == m,
                                onTap: () => setState(() {
                                  _custom = false;
                                  _selected = m;
                                }),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _CustomEntry(
                    key: const Key('prep-minutes-custom-open'),
                    label: AppStrings.prepCustomTime,
                    icon: Icons.more_time,
                    open: _custom,
                    onTap: () => setState(() => _custom = !_custom),
                  ),
                  if (_custom) ...[
                    const SizedBox(height: 12),
                    TextField(
                      key: const Key('prep-minutes-custom'),
                      controller: _customController,
                      autofocus: true,
                      keyboardType: TextInputType.number,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        suffixText: 'min',
                        helperText: AppStrings.prepCustomRange(prepCustomMinMinutes.toString(), prepCustomMaxMinutes.toString(), ),
                        errorText:
                            _customController.text.isNotEmpty &&
                                _customValue == null
                            ? AppStrings.prepCustomRange(prepCustomMinMinutes.toString(), prepCustomMaxMinutes.toString(), )
                            : null,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          _SheetFooter(
            children: [
              SizedBox(
                height: 52,
                child: FilledButton.icon(
                  key: const Key('accept-prep-confirm'),
                  onPressed: _value == null
                      ? null
                      : () => Navigator.pop(context, _value),
                  icon: const Icon(Icons.check_circle),
                  label: Text(AppStrings.prepConfirmAccept),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 48,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(AppStrings.cancel),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Update prep estimate sheet (+5/+10/+15/+20 or custom + optional reason).
Future<({int addMinutes, String? reason})?> showUpdatePreparationSheet(
  BuildContext context, {
  required String? estimatedReadyAt,
  required String? originalEstimatedReadyAt,
  String? publicReference,
  String? customerName,
  bool isLate = false,
  DateTime Function() now = DateTime.now,
}) {
  return showModalBottomSheet<({int addMinutes, String? reason})>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppColors.background,
    builder: (ctx) => _UpdatePrepSheet(
      estimatedReadyAt: estimatedReadyAt,
      originalEstimatedReadyAt: originalEstimatedReadyAt,
      publicReference: publicReference,
      customerName: customerName,
      isLate: isLate,
      now: now,
    ),
  );
}

class _UpdatePrepSheet extends StatefulWidget {
  const _UpdatePrepSheet({
    required this.estimatedReadyAt,
    required this.originalEstimatedReadyAt,
    this.publicReference,
    this.customerName,
    this.isLate = false,
    this.now = DateTime.now,
  });

  final String? estimatedReadyAt;
  final String? originalEstimatedReadyAt;
  final String? publicReference;
  final String? customerName;
  final bool isLate;
  final DateTime Function() now;

  @override
  State<_UpdatePrepSheet> createState() => _UpdatePrepSheetState();
}

class _UpdatePrepSheetState extends State<_UpdatePrepSheet> {
  int _add = 10;
  bool _custom = false;
  final _customController = TextEditingController();
  final _reason = TextEditingController();
  final _reasonFocus = FocusNode();

  @override
  void dispose() {
    _customController.dispose();
    _reason.dispose();
    _reasonFocus.dispose();
    super.dispose();
  }

  void _pickReason(String? label) {
    setState(() {
      if (label == null) {
        if (prepReasonPresets.contains(_reason.text.trim())) _reason.clear();
        _reasonFocus.requestFocus();
      } else {
        _reason.value = TextEditingValue(
          text: label,
          selection: TextSelection.collapsed(offset: label.length),
        );
      }
    });
  }

  int? get _customValue {
    final v = int.tryParse(_customController.text.trim());
    if (v == null || v < 1 || v > prepAddCustomMax) return null;
    return v;
  }

  int? get _value => _custom ? _customValue : _add;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final add = _value;
    final now = widget.now();
    final preview = prepEstimatePreview(
      estimatedReadyAt: widget.estimatedReadyAt,
      addMinutes: add ?? 0,
      now: now,
    );
    final originalDay = formatPrepOtherDayIso(
      widget.originalEstimatedReadyAt,
      now,
    );
    final originalClock = formatPrepClockIso(widget.originalEstimatedReadyAt);
    final label = theme.textTheme.labelMedium?.copyWith(
      color: AppColors.onSurfaceVariant,
      letterSpacing: 0.5,
    );
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        key: const Key('update-prep-sheet'),
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SheetHeader(
            title: AppStrings.prepUpdateTitle,
            closeLeading: true,
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (widget.publicReference != null) ...[
                    Align(
                      alignment: Alignment.centerLeft,
                      child: OrderPublicReferenceLine(
                        reference: widget.publicReference!,
                        prefix: '${AppStrings.alertOrderLabel.toUpperCase()} ',
                        textStyle: label,
                        textKey: const Key('prep-update-reference'),
                        openKey: const Key('prep-update-reference-open'),
                      ),
                    ),
                    if (widget.customerName != null)
                      Row(
                        children: [
                          const Icon(
                            Icons.person,
                            size: 20,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              widget.customerName!,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 16),
                  ],
                  MerchantCard(
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: const BoxDecoration(
                            color: AppColors.secondaryContainer,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.schedule,
                            size: 20,
                            color: AppColors.onSecondaryContainer,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppStrings.prepCurrentReady,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: AppColors.onSurfaceVariant,
                                ),
                              ),
                              Text(
                                preview.fromDay == null
                                    ? preview.from
                                    : AppStrings.prepClockOnDay(preview.fromDay!, preview.from.toString(), ),
                                key: const Key('prep-update-current-ready'),
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              if (widget.originalEstimatedReadyAt != null &&
                                  widget.originalEstimatedReadyAt !=
                                      widget.estimatedReadyAt)
                                Text(
                                  AppStrings.prepOriginalReady(
                                    originalDay == null
                                        ? originalClock
                                        : AppStrings.prepClockOnDay(
                                            originalDay,
                                            originalClock,
                                          ),
                                  ),
                                  style: label,
                                ),
                            ],
                          ),
                        ),
                        StatusBadge(
                          label: widget.isLate
                              ? AppStrings.orderListLate
                              : AppStrings.prepInProgress,
                          tone: widget.isLate
                              ? StatusTone.error
                              : StatusTone.neutral,
                          icon: widget.isLate
                              ? Icons.timer_off_outlined
                              : Icons.hourglass_top,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    AppStrings.prepAddTime,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      for (final m in const [5, 10, 15, 20]) ...[
                        if (m != 5) const SizedBox(width: 8),
                        Expanded(
                          child: _MinuteTile(
                            key: Key('prep-add-$m'),
                            value: '+$m',
                            selected: !_custom && _add == m,
                            compact: true,
                            onTap: () => setState(() {
                              _custom = false;
                              _add = m;
                            }),
                          ),
                        ),
                      ],
                    ],
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      key: const Key('prep-add-custom-open'),
                      onPressed: () => setState(() => _custom = !_custom),
                      icon: const Icon(Icons.edit, size: 18),
                      label: Text(AppStrings.prepCustomEntry),
                    ),
                  ),
                  if (_custom) ...[
                    TextField(
                      key: const Key('prep-add-custom'),
                      controller: _customController,
                      autofocus: true,
                      keyboardType: TextInputType.number,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        prefixText: '+ ',
                        suffixText: 'min',
                        helperText: AppStrings.prepCustomRange('1', prepAddCustomMax.toString(), ),
                        errorText:
                            _customController.text.isNotEmpty &&
                                _customValue == null
                            ? AppStrings.prepCustomRange('1', prepAddCustomMax.toString())
                            : null,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  const SizedBox(height: 8),
                  if (add != null)
                    _ComparisonCard(
                      key: const Key('prep-update-preview'),
                      from: preview.from,
                      to: preview.to,
                      fromDay: preview.fromDay,
                      toDay: preview.toDay,
                      add: add,
                    ),
                  const SizedBox(height: 20),
                  Text(
                    AppStrings.prepReasonOptional,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppStrings.prepReasonShortcutsHint,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _ReasonTiles(
                    selected: _reason.text.trim(),
                    onPick: _pickReason,
                  ),
                  const SizedBox(height: 12),
                  MerchantLabeledField(
                    label: AppStrings.prepReasonFieldLabel,
                    child: TextField(
                      key: const Key('prep-update-reason'),
                      controller: _reason,
                      focusNode: _reasonFocus,
                      onChanged: (_) => setState(() {}),
                      maxLength: 255,
                      minLines: 3,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: AppStrings.prepReasonHint,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          _SheetFooter(
            children: [
              _UpdateFooterRow(
                stacked: MediaQuery.textScalerOf(context).scale(1) >= 1.25,
                cancel: SizedBox(
                  height: 48,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(AppStrings.cancel),
                  ),
                ),
                confirm: SizedBox(
                  height: 48,
                  child: FilledButton.icon(
                    key: const Key('prep-update-confirm'),
                    onPressed: add == null
                        ? null
                        : () => Navigator.pop(context, (
                            addMinutes: add,
                            reason: _reason.text.trim().isEmpty
                                ? null
                                : _reason.text.trim(),
                          )),
                    icon: const Icon(Icons.update),
                    label: Text(AppStrings.prepUpdateConfirm),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Text shortcuts for the free-text revision reason. They only fill the
/// editable field; the API stores free text, not a reason category.
List<String> get prepReasonPresets => [
  AppStrings.prepReasonBusy,
  AppStrings.prepReasonLongPrep,
  AppStrings.prepReasonMissingIngredient,
];

class _ReasonTiles extends StatelessWidget {
  const _ReasonTiles({required this.selected, required this.onPick});

  final String selected;
  final ValueChanged<String?> onPick;

  @override
  Widget build(BuildContext context) {
    final other = selected.isNotEmpty && !prepReasonPresets.contains(selected);
    final tiles = <Widget>[
      _ReasonTile(
        key: const Key('prep-reason-busy'),
        icon: Icons.groups_outlined,
        label: AppStrings.prepReasonBusy,
        selected: selected == AppStrings.prepReasonBusy,
        onTap: () => onPick(AppStrings.prepReasonBusy),
      ),
      _ReasonTile(
        key: const Key('prep-reason-long'),
        icon: Icons.soup_kitchen_outlined,
        label: AppStrings.prepReasonLongPrep,
        selected: selected == AppStrings.prepReasonLongPrep,
        onTap: () => onPick(AppStrings.prepReasonLongPrep),
      ),
      _ReasonTile(
        key: const Key('prep-reason-ingredient'),
        icon: Icons.inventory_2_outlined,
        label: AppStrings.prepReasonMissingIngredient,
        selected: selected == AppStrings.prepReasonMissingIngredient,
        onTap: () => onPick(AppStrings.prepReasonMissingIngredient),
      ),
      _ReasonTile(
        key: const Key('prep-reason-other'),
        icon: Icons.more_horiz,
        label: AppStrings.prepReasonOther,
        selected: other,
        onTap: () => onPick(null),
      ),
    ];
    return Column(
      children: [
        for (var i = 0; i < tiles.length; i += 2) ...[
          if (i > 0) const SizedBox(height: 8),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: tiles[i]),
                const SizedBox(width: 8),
                Expanded(child: tiles[i + 1]),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _ReasonTile extends StatelessWidget {
  const _ReasonTile({
    super.key,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = selected ? AppColors.primary : AppColors.onSurface;
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected
            ? AppColors.primaryFixed.withValues(alpha: 0.2)
            : AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: selected ? AppColors.primary : AppColors.outlineVariant,
            width: selected ? 2 : 1,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 22, color: color),
                const SizedBox(height: 6),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: color,
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

class _SheetHeader extends StatelessWidget {
  const _SheetHeader({
    required this.title,
    this.subtitle,
    this.closeLeading = false,
  });

  final String title;
  final String? subtitle;
  final bool closeLeading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppColors.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
        child: Row(
          children: [
            IconButton(
              tooltip: AppStrings.cancel,
              onPressed: () => Navigator.pop(context),
              icon: Icon(
                closeLeading ? Icons.close : Icons.arrow_back,
                color: AppColors.primary,
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: closeLeading
                    ? CrossAxisAlignment.center
                    : CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    textAlign: closeLeading
                        ? TextAlign.center
                        : TextAlign.start,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: closeLeading
                          ? AppColors.onSurface
                          : AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
            if (closeLeading) const SizedBox(width: 48),
          ],
        ),
      ),
    );
  }
}

class _BranchBlock extends StatelessWidget {
  const _BranchBlock({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.primary,
            child: Text(
              name.characters.first.toUpperCase(),
              style: theme.textTheme.titleMedium?.copyWith(
                color: AppColors.onPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.prepBranchLabel.toUpperCase(),
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: AppColors.onSurfaceVariant,
                    letterSpacing: 0.6,
                  ),
                ),
                Text(
                  name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
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

class _UpdateFooterRow extends StatelessWidget {
  const _UpdateFooterRow({
    required this.stacked,
    required this.cancel,
    required this.confirm,
  });

  final bool stacked;
  final Widget cancel;
  final Widget confirm;

  @override
  Widget build(BuildContext context) {
    if (stacked) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [confirm, const SizedBox(height: 8), cancel],
      );
    }
    return Row(
      children: [
        Expanded(child: cancel),
        const SizedBox(width: 12),
        Expanded(flex: 2, child: confirm),
      ],
    );
  }
}

class _SheetFooter extends StatelessWidget {
  const _SheetFooter({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(
            color: AppColors.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        ),
      ),
    );
  }
}

class _MinuteTile extends StatelessWidget {
  const _MinuteTile({
    super.key,
    required this.value,
    required this.selected,
    required this.onTap,
    this.caption,
    this.compact = false,
  });

  final String value;
  final String? caption;
  final bool selected;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fg = selected ? AppColors.onPrimary : AppColors.onSurface;
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected
            ? (compact ? AppColors.primaryContainer : AppColors.primary)
            : AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(compact ? 8 : 12),
          side: BorderSide(
            color: selected ? Colors.transparent : AppColors.outlineVariant,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: compact ? 48 : 72),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    value,
                    style:
                        (compact
                                ? theme.textTheme.titleMedium
                                : theme.textTheme.headlineSmall)
                            ?.copyWith(color: fg, fontWeight: FontWeight.w700),
                  ),
                  if (caption != null)
                    Text(
                      caption!,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: selected
                            ? AppColors.onPrimary
                            : AppColors.onSurfaceVariant,
                        letterSpacing: 0.6,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CustomEntry extends StatelessWidget {
  const _CustomEntry({
    super.key,
    required this.label,
    required this.icon,
    required this.open,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool open;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: open ? AppColors.surfaceContainerLow : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.outline),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(
              open ? Icons.expand_less : Icons.chevron_right,
              color: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }
}

class _ComparisonCard extends StatelessWidget {
  const _ComparisonCard({
    super.key,
    required this.from,
    required this.to,
    required this.add,
    this.fromDay,
    this.toDay,
  });

  final String from;
  final String to;
  final int add;

  /// Branch-local `dd/MM` when the estimate is on another day than today.
  final String? fromDay;
  final String? toDay;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final caption = theme.textTheme.labelMedium?.copyWith(
      color: AppColors.onSurfaceVariant,
    );
    return Semantics(
      container: true,
      label: AppStrings.prepNewEstimate(AppStrings.prepSpokenClock(from, fromDay),
        AppStrings.prepSpokenClock(to, toDay),
        add,
      ),
      excludeSemantics: true,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceContainer,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppColors.outlineVariant.withValues(alpha: 0.6),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 64),
                    child: Text(
                      AppStrings.prepNewShort,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(AppStrings.prepCurrentShort, style: caption),
                            Text(
                              from,
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: AppColors.onSurfaceVariant,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                            if (fromDay != null)
                              Text(
                                AppStrings.prepOnDay(fromDay!),
                                key: const Key('prep-preview-from-day'),
                                style: caption,
                              ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward, color: AppColors.outline),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              AppStrings.prepNewShort,
                              style: caption?.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              to,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (toDay != null)
                              Text(
                                AppStrings.prepOnDay(toDay!),
                                key: const Key('prep-preview-to-day'),
                                style: caption?.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(8),
                  ),
                ),
                child: Text(
                  '+$add min',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: AppColors.onPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PreparationCountdownBanner extends StatefulWidget {
  const PreparationCountdownBanner({
    super.key,
    required this.estimatedReadyAt,
    required this.originalEstimatedReadyAt,
    required this.isPreparationLate,
    this.delayMinutes,
    this.onUpdate,
  });

  final String? estimatedReadyAt;
  final String? originalEstimatedReadyAt;
  final bool isPreparationLate;

  /// Server-authoritative delay when late; falls back to local clock.
  final int? delayMinutes;
  final VoidCallback? onUpdate;

  @override
  State<PreparationCountdownBanner> createState() =>
      _PreparationCountdownBannerState();
}

class _PreparationCountdownBannerState
    extends State<PreparationCountdownBanner> {
  Timer? _timer;
  Duration _remaining = Duration.zero;
  Duration _lateBy = Duration.zero;

  @override
  void initState() {
    super.initState();
    _tick();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  @override
  void didUpdateWidget(covariant PreparationCountdownBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.estimatedReadyAt != widget.estimatedReadyAt) {
      _tick();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _tick() {
    final ready = parsePrepInstant(widget.estimatedReadyAt);
    if (ready == null) {
      setState(() {
        _remaining = Duration.zero;
        _lateBy = Duration.zero;
      });
      return;
    }
    final now = DateTime.now().toUtc();
    setState(() {
      if (now.isAfter(ready)) {
        _remaining = Duration.zero;
        _lateBy = now.difference(ready);
      } else {
        _remaining = ready.difference(now);
        _lateBy = Duration.zero;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.estimatedReadyAt == null) {
      return const SizedBox.shrink();
    }
    final theme = Theme.of(context);
    final late = widget.isPreparationLate || _lateBy > Duration.zero;
    final revisedClock = formatPrepClockIso(widget.estimatedReadyAt);
    final revisedDay = formatPrepOtherDayIso(
      widget.estimatedReadyAt,
      DateTime.now(),
    );
    final originalClock = widget.originalEstimatedReadyAt == null
        ? null
        : formatPrepClockIso(widget.originalEstimatedReadyAt);
    final caption = theme.textTheme.labelMedium?.copyWith(
      fontWeight: FontWeight.w700,
      letterSpacing: 0.6,
      color: late ? AppColors.error : AppColors.onSurfaceVariant,
    );
    return Container(
      key: const Key('prep-countdown-banner'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: late
            ? AppColors.errorContainer.withValues(alpha: 0.3)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: late
              ? AppColors.error
              : AppColors.outlineVariant.withValues(alpha: 0.3),
        ),
        boxShadow: merchantCardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (late) ...[
            const Icon(Icons.timer_off, color: AppColors.error, size: 32),
            const SizedBox(height: 8),
            Text(
              AppStrings.prepLateBy(widget.delayMinutes ?? _lateBy.inMinutes),
              key: const Key('prep-delay-minutes'),
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.onSurface,
              ),
            ),
          ] else ...[
            Text(
              AppStrings.prepRemainingTitle,
              textAlign: TextAlign.center,
              style: caption,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _TimeBox(
                    value: _remaining.inMinutes.toString().padLeft(2, '0'),
                    caption: AppStrings.prepMinutesCaption,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _TimeBox(
                    value: _remaining.inSeconds
                        .remainder(60)
                        .toString()
                        .padLeft(2, '0'),
                    caption: AppStrings.prepSecondsCaption,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Text(
            revisedDay == null
                ? AppStrings.prepScheduledAtLocal(revisedClock)
                : AppStrings.prepScheduledOnLocal(revisedDay, revisedClock),
            key: const Key('prep-revised-ready'),
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontStyle: FontStyle.italic,
              color: AppColors.onSurfaceVariant,
            ),
          ),
          if (originalClock != null && originalClock != revisedClock) ...[
            const SizedBox(height: 2),
            Text(
              AppStrings.prepOriginalReadyLabel(originalClock.toString()),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
          if (late) ...[
            const SizedBox(height: 8),
            Text(
              AppStrings.prepLateHint,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.onErrorContainer,
              ),
            ),
          ],
          if (widget.onUpdate != null) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              key: const Key('prep-update-open'),
              onPressed: widget.onUpdate,
              icon: const Icon(Icons.schedule, size: 20),
              label: Text(AppStrings.prepUpdateAction),
            ),
          ],
        ],
      ),
    );
  }
}

class _TimeBox extends StatelessWidget {
  const _TimeBox({required this.value, required this.caption});

  final String value;
  final String caption;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Container(
          constraints: const BoxConstraints(minHeight: 64),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.outlineVariant.withValues(alpha: 0.3),
            ),
          ),
          child: Text(
            value,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontSize: 30,
              fontWeight: FontWeight.w700,
              color: AppColors.onSurface,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          caption,
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
            color: AppColors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
