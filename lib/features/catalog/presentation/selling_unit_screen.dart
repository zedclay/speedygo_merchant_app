import 'package:flutter/material.dart';
import 'package:speedygo_merchant_app/app/theme/app_theme.dart';
import 'package:speedygo_merchant_app/core/constants/app_strings.dart';
import 'package:speedygo_merchant_app/core/money/money_format.dart';
import 'package:speedygo_merchant_app/core/widgets/merchant_ui.dart';
import 'package:speedygo_merchant_app/features/catalog/data/catalog_models.dart';

const _commonUnits = [
  SellingUnit.plat,
  SellingUnit.piece,
  SellingUnit.portion,
  SellingUnit.boite,
];
const _packagingUnits = [SellingUnit.pack, SellingUnit.plateau];

/// "Unités de vente" (`selling_units_french`): single choice among the
/// allowlisted units, or a custom French label. Pops with the chosen
/// [SellingUnitSelection]; weight units are not offered (integer quantities).
class SellingUnitScreen extends StatefulWidget {
  const SellingUnitScreen({
    super.key,
    required this.initial,
    required this.priceMinor,
    required this.readOnly,
  });

  final SellingUnitSelection initial;

  /// Current price field value in minor units; `null` while it is invalid.
  final int? priceMinor;
  final bool readOnly;

  @override
  State<SellingUnitScreen> createState() => _SellingUnitScreenState();
}

class _SellingUnitScreenState extends State<SellingUnitScreen> {
  late final TextEditingController _custom;
  SellingUnit? _unit;

  @override
  void initState() {
    super.initState();
    _unit = SellingUnit.fromCode(widget.initial.code);
    _custom = TextEditingController(
      text: _unit == SellingUnit.custom ? widget.initial.labelFr ?? '' : '',
    )..addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _custom.dispose();
    super.dispose();
  }

  String get _customLabel => _custom.text.trim();

  bool get _canApply =>
      !widget.readOnly &&
      (_unit != SellingUnit.custom || _customLabel.isNotEmpty);

  SellingUnitSelection get _selection {
    final unit = _unit;
    if (unit == null) return SellingUnitSelection.none;
    return SellingUnitSelection(
      code: unit.code,
      labelFr: unit == SellingUnit.custom ? _customLabel : null,
    );
  }

  void _pick(SellingUnit? unit) {
    if (widget.readOnly) return;
    setState(() => _unit = unit);
  }

  String get _previewUnit {
    final label = _selection.displayLabel;
    if (_unit == SellingUnit.custom && label == null) {
      return AppStrings.sellingUnitCustomName;
    }
    return label ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final price = widget.priceMinor == null
        ? AppStrings.sellingUnitPreviewNoPrice
        : MoneyFormat.dzd(widget.priceMinor.toString());
    return MerchantScaffold(
      title: AppStrings.sellingUnitTitle,
      titleStyle: theme.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
        color: AppColors.primary,
      ),
      bodyPadding: EdgeInsets.zero,
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              key: const Key('selling-unit-screen'),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (widget.readOnly) ...[
                    Text(
                      AppStrings.sellingUnitReadOnly,
                      key: const Key('selling-unit-read-only'),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  _Callout(theme: theme),
                  const SizedBox(height: 16),
                  _Preview(price: price, unit: _previewUnit),
                  const SizedBox(height: 24),
                  _Group(
                    title: AppStrings.sellingUnitCommon,
                    units: _commonUnits,
                    selected: _unit,
                    onPick: _pick,
                  ),
                  const Divider(height: 32),
                  _Group(
                    title: AppStrings.sellingUnitPackaging,
                    units: _packagingUnits,
                    selected: _unit,
                    onPick: _pick,
                  ),
                  const Divider(height: 32),
                  _UnitTile(
                    tileKey: const Key('selling-unit-CUSTOM'),
                    label: SellingUnit.custom.labelFr,
                    selected: _unit == SellingUnit.custom,
                    onTap: () => _pick(SellingUnit.custom),
                  ),
                  if (_unit == SellingUnit.custom) ...[
                    const SizedBox(height: 12),
                    MerchantLabeledField(
                      label: AppStrings.sellingUnitCustomName,
                      requiredMark: true,
                      child: TextField(
                        key: const Key('selling-unit-custom-field'),
                        controller: _custom,
                        enabled: !widget.readOnly,
                        maxLength: AppStrings.sellingUnitCustomMaxLength,
                        textInputAction: TextInputAction.done,
                        decoration: const InputDecoration(
                          hintText: AppStrings.sellingUnitCustomHint,
                        ),
                      ),
                    ),
                  ],
                  const Divider(height: 32),
                  _UnitTile(
                    tileKey: const Key('selling-unit-none'),
                    label: AppStrings.sellingUnitNone,
                    caption: AppStrings.sellingUnitNoneSub,
                    selected: _unit == null,
                    onTap: () => _pick(null),
                  ),
                ],
              ),
            ),
          ),
          if (!widget.readOnly)
            MerchantStickyBar(
              child: SizedBox(
                height: 48,
                child: FilledButton.icon(
                  key: const Key('selling-unit-apply'),
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  onPressed: _canApply
                      ? () => Navigator.of(context).pop(_selection)
                      : null,
                  icon: const Icon(Icons.check, size: 18),
                  iconAlignment: IconAlignment.end,
                  label: const Text(AppStrings.sellingUnitApply),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Callout extends StatelessWidget {
  const _Callout({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryFixed.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.sellingUnitCalloutTitle,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  AppStrings.sellingUnitCalloutBody,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.onSurfaceVariant,
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

class _Preview extends StatelessWidget {
  const _Preview({required this.price, required this.unit});

  final String price;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return MerchantCard(
      child: Column(
        children: [
          Text(
            AppStrings.sellingUnitPreviewLabel.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              color: AppColors.onSurfaceVariant,
              letterSpacing: 0.8,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            unit.isEmpty ? price : '$price / $unit',
            key: const Key('selling-unit-preview'),
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _Group extends StatelessWidget {
  const _Group({
    required this.title,
    required this.units,
    required this.selected,
    required this.onPick,
  });

  final String title;
  final List<SellingUnit> units;
  final SellingUnit? selected;
  final ValueChanged<SellingUnit?> onPick;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            const gap = 12.0;
            final width = (constraints.maxWidth - gap) / 2;
            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                for (final unit in units)
                  SizedBox(
                    width: width,
                    child: _UnitTile(
                      tileKey: Key('selling-unit-${unit.code}'),
                      label: unit.labelFr,
                      selected: selected == unit,
                      onTap: () => onPick(unit),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _UnitTile extends StatelessWidget {
  const _UnitTile({
    required this.tileKey,
    required this.label,
    required this.selected,
    required this.onTap,
    this.caption,
  });

  final Key tileKey;
  final String label;
  final String? caption;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      key: tileKey,
      button: true,
      inMutuallyExclusiveGroup: true,
      selected: selected,
      child: Material(
        color: selected
            ? AppColors.primaryFixed.withValues(alpha: 0.35)
            : AppColors.surfaceContainerLowest,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: selected ? AppColors.primary : AppColors.outlineVariant,
            width: selected ? 2 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 56),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: selected
                                ? AppColors.primary
                                : AppColors.onSurface,
                          ),
                        ),
                        if (caption != null)
                          Text(
                            caption!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    selected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    size: 20,
                    color: selected ? AppColors.primary : AppColors.outline,
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
