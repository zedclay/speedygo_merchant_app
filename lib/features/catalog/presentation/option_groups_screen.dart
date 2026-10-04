import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speedygo_merchant_app/app/theme/app_theme.dart';
import 'package:speedygo_merchant_app/core/constants/app_strings.dart';
import 'package:speedygo_merchant_app/core/errors/app_exception.dart';
import 'package:speedygo_merchant_app/core/money/money_format.dart';
import 'package:speedygo_merchant_app/core/widgets/merchant_ui.dart';
import 'package:speedygo_merchant_app/features/access/application/access_controller.dart';
import 'package:speedygo_merchant_app/features/auth/application/auth_infrastructure.dart';
import 'package:speedygo_merchant_app/features/catalog/application/catalog_controller.dart';
import 'package:speedygo_merchant_app/features/catalog/data/catalog_models.dart';
import 'package:speedygo_merchant_app/features/catalog/presentation/catalog_screen.dart';
import 'package:speedygo_merchant_app/features/catalog/presentation/catalog_widgets.dart';

/// Option groups of one product, split by kind: `required` groups are the
/// "Variantes obligatoires", optional ones the "Suppléments optionnels".
/// Every change is saved immediately through the per-entity API.
class OptionGroupsScreen extends ConsumerStatefulWidget {
  const OptionGroupsScreen({
    super.key,
    required this.productId,
    required this.required,
  });

  final String productId;
  final bool required;

  @override
  ConsumerState<OptionGroupsScreen> createState() => _OptionGroupsScreenState();
}

class _OptionGroupsScreenState extends ConsumerState<OptionGroupsScreen> {
  List<CatalogOptionGroup>? _groups;
  bool _loadFailed = false;

  String? get _merchantId =>
      ref.read(accessControllerProvider).membership?.merchantId;

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  Future<void> _load() async {
    final merchantId = _merchantId;
    if (merchantId == null) return;
    setState(() => _loadFailed = false);
    try {
      final groups = await ref
          .read(merchantApiProvider)
          .listOptionGroups(
            merchantId: merchantId,
            productId: widget.productId,
          );
      if (!mounted) return;
      setState(() => _groups = groups);
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadFailed = true);
    }
  }

  Future<void> _run(Future<void> Function(String merchantId) action) async {
    final merchantId = _merchantId;
    if (merchantId == null) return;
    try {
      await action(merchantId);
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(_optionErrorMessage(e))));
    }
  }

  Future<void> _editGroup([CatalogOptionGroup? group]) async {
    final result = await showModalBottomSheet<_GroupDraft>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.surface,
      builder: (_) => _GroupSheet(required: widget.required, group: group),
    );
    if (result == null) return;
    final api = ref.read(merchantApiProvider);
    if (result.delete && group != null) {
      await _run(
        (m) => api.deleteOptionGroup(
          merchantId: m,
          productId: widget.productId,
          groupId: group.id,
        ),
      );
      return;
    }
    final min = widget.required ? 1 : 0;
    if (group == null) {
      await _run(
        (m) => api.createOptionGroup(
          merchantId: m,
          productId: widget.productId,
          name: result.name,
          required: widget.required,
          minSelections: min,
          maxSelections: result.maxSelections,
        ),
      );
    } else {
      await _run(
        (m) => api.updateOptionGroup(
          merchantId: m,
          productId: widget.productId,
          groupId: group.id,
          name: result.name,
          maxSelections: result.maxSelections,
        ),
      );
    }
  }

  Future<void> _editOption(
    CatalogOptionGroup group, [
    CatalogOption? option,
  ]) async {
    final result = await showModalBottomSheet<_OptionDraft>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.surface,
      builder: (_) => _OptionSheet(option: option),
    );
    if (result == null) return;
    final api = ref.read(merchantApiProvider);
    if (result.delete && option != null) {
      await _deleteOption(group, option);
      return;
    }
    if (option == null) {
      await _run(
        (m) => api.createOption(
          merchantId: m,
          productId: widget.productId,
          groupId: group.id,
          name: result.name,
          additionalPriceMinor: result.priceMinor,
          available: result.available,
        ),
      );
    } else {
      await _run(
        (m) => api.updateOption(
          merchantId: m,
          productId: widget.productId,
          groupId: group.id,
          optionId: option.id,
          name: result.name,
          additionalPriceMinor: result.priceMinor,
          available: result.available,
        ),
      );
    }
  }

  Future<void> _deleteOption(CatalogOptionGroup group, CatalogOption option) =>
      _run(
        (m) => ref
            .read(merchantApiProvider)
            .deleteOption(
              merchantId: m,
              productId: widget.productId,
              groupId: group.id,
              optionId: option.id,
            ),
      );

  Future<void> _setOptionAvailable(
    CatalogOptionGroup group,
    CatalogOption option,
    bool available,
  ) => _run(
    (m) => ref
        .read(merchantApiProvider)
        .updateOption(
          merchantId: m,
          productId: widget.productId,
          groupId: group.id,
          optionId: option.id,
          available: available,
        ),
  );

  void _preview(CatalogProduct? product, List<CatalogOptionGroup> groups) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.surface,
      builder: (_) => _CustomerPreview(product: product, groups: groups),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canManage = catalogRoleCanManage(
      ref.watch(accessControllerProvider).membership?.role ?? '',
    );
    final catalog = ref.watch(catalogControllerProvider).value;
    CatalogProduct? product;
    for (final p in catalog?.products ?? const <CatalogProduct>[]) {
      if (p.id == widget.productId) product = p;
    }
    final title = widget.required
        ? AppStrings.catalogVariantsTitle
        : AppStrings.catalogExtrasTitle;
    final all = _groups;
    final groups =
        all?.where((g) => g.required == widget.required).toList() ?? const [];

    Widget body;
    if (_loadFailed) {
      body = ErrorBody(
        message: AppStrings.catalogGroupsLoadError,
        onRetry: _load,
      );
    } else if (all == null) {
      body = const LoadingBody();
    } else {
      body = ListView(
        key: Key(widget.required ? 'variants-list' : 'extras-list'),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          if (product != null)
            Text(
              product.name.toUpperCase(),
              style: theme.textTheme.labelLarge?.copyWith(
                color: AppColors.onSurfaceVariant,
                letterSpacing: 0.6,
              ),
            ),
          Text(
            widget.required
                ? AppStrings.catalogVariantsSubtitle
                : AppStrings.catalogExtrasSubtitle,
            style: theme.textTheme.bodyMedium,
          ),
          if (widget.required) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainer,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.surfaceVariant),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline, color: AppColors.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      AppStrings.catalogVariantsInfo,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          for (final g in groups) ...[
            const SizedBox(height: 20),
            _GroupCard(
              group: g,
              canManage: canManage,
              onEdit: () => _editGroup(g),
              onAddOption: () => _editOption(g),
              onEditOption: (o) => _editOption(g, o),
              onDeleteOption: (o) => _deleteOption(g, o),
              onToggleOption: (o, v) => _setOptionAvailable(g, o, v),
            ),
          ],
          if (canManage) ...[
            const SizedBox(height: 20),
            _DashedAction(
              key: const Key('option-group-add'),
              icon: Icons.add_circle_outline,
              label: widget.required
                  ? AppStrings.catalogAddVariantGroup
                  : AppStrings.catalogAddExtrasGroup,
              filled: !widget.required,
              onTap: () => _editGroup(),
            ),
          ],
        ],
      );
    }

    return MerchantScaffold(
      title: title,
      centerTitle: true,
      bodyPadding: EdgeInsets.zero,
      headerColor: AppColors.surface,
      titleStyle: theme.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
        color: AppColors.primary,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: body),
          if (all != null && groups.isNotEmpty)
            MerchantStickyBar(
              child: SizedBox(
                height: 48,
                child: OutlinedButton.icon(
                  key: const Key('option-groups-preview'),
                  onPressed: () => _preview(product, groups),
                  icon: const Icon(Icons.preview_outlined),
                  label: const Text(AppStrings.catalogCustomerPreview),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

String _optionErrorMessage(Object error) {
  if (error is ApiException && error.code == 'CATALOG_OPTION_GROUP_INVALID') {
    return AppStrings.catalogGroupInvalid;
  }
  return catalogErrorMessage(error);
}

class _GroupCard extends StatelessWidget {
  const _GroupCard({
    required this.group,
    required this.canManage,
    required this.onEdit,
    required this.onAddOption,
    required this.onEditOption,
    required this.onDeleteOption,
    required this.onToggleOption,
  });

  final CatalogOptionGroup group;
  final bool canManage;
  final VoidCallback onEdit;
  final VoidCallback onAddOption;
  final ValueChanged<CatalogOption> onEditOption;
  final ValueChanged<CatalogOption> onDeleteOption;
  final void Function(CatalogOption, bool) onToggleOption;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rule = group.required
        ? (group.maxSelections <= 1
              ? AppStrings.catalogSingleChoice
              : AppStrings.catalogChoiceRange(
                  group.minSelections,
                  group.maxSelections,
                ))
        : AppStrings.catalogMaxSelections(group.maxSelections);
    return Container(
      key: Key('option-group-${group.id}'),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outlineVariant),
        boxShadow: merchantCardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 4, 12),
            decoration: BoxDecoration(
              color: group.required
                  ? AppColors.surfaceContainerLow
                  : AppColors.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
              border: const Border(
                bottom: BorderSide(color: AppColors.outlineVariant),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        group.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        rule,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (group.required)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.tertiaryFixed,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      AppStrings.catalogRequiredTag.toUpperCase(),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppColors.onTertiaryFixed,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                if (canManage)
                  IconButton(
                    key: Key('option-group-edit-${group.id}'),
                    tooltip: AppStrings.catalogEditGroup,
                    color: AppColors.primary,
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: onEdit,
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (group.options.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      AppStrings.catalogOptionsEmpty,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ),
                for (final o in group.options) ...[
                  group.required
                      ? _VariantRow(
                          option: o,
                          canManage: canManage,
                          onTap: () => onEditOption(o),
                          onDelete: () => onDeleteOption(o),
                        )
                      : _ExtraRow(
                          option: o,
                          canManage: canManage,
                          onTap: () => onEditOption(o),
                          onDelete: () => onDeleteOption(o),
                          onToggle: (v) => onToggleOption(o, v),
                        ),
                  const SizedBox(height: 8),
                ],
                if (canManage)
                  group.required
                      ? Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            key: Key('option-add-${group.id}'),
                            onPressed: onAddOption,
                            icon: const Icon(Icons.add),
                            label: const Text(AppStrings.catalogAddChoice),
                          ),
                        )
                      : _DashedAction(
                          key: Key('option-add-${group.id}'),
                          icon: Icons.add,
                          label: AppStrings.catalogAddOption,
                          onTap: onAddOption,
                          compact: true,
                        ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PriceChip extends StatelessWidget {
  const _PriceChip({required this.minor});

  final String minor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '+${MoneyFormat.dzdOrEmpty(minor)}',
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: AppColors.onSurfaceVariant,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _VariantRow extends StatelessWidget {
  const _VariantRow({
    required this.option,
    required this.canManage,
    required this.onTap,
    required this.onDelete,
  });

  final CatalogOption option;
  final bool canManage;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      key: Key('option-${option.id}'),
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: AppColors.outlineVariant),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: canManage ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
          child: Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      option.name,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: option.available
                            ? AppColors.onSurface
                            : AppColors.outline,
                        decoration: option.available
                            ? null
                            : TextDecoration.lineThrough,
                      ),
                    ),
                    _PriceChip(minor: option.additionalPriceMinor),
                  ],
                ),
              ),
              if (canManage)
                IconButton(
                  key: Key('option-delete-${option.id}'),
                  tooltip: AppStrings.catalogOptionDelete,
                  color: AppColors.onSurfaceVariant,
                  icon: const Icon(Icons.close),
                  onPressed: onDelete,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExtraRow extends StatelessWidget {
  const _ExtraRow({
    required this.option,
    required this.canManage,
    required this.onTap,
    required this.onDelete,
    required this.onToggle,
  });

  final CatalogOption option;
  final bool canManage;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      key: Key('option-${option.id}'),
      padding: const EdgeInsets.only(bottom: 8),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.outlineVariant)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  option.name,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (canManage)
                Switch(
                  key: Key('option-available-${option.id}'),
                  value: option.available,
                  onChanged: onToggle,
                )
              else
                Text(
                  option.available
                      ? AppStrings.catalogInStock
                      : AppStrings.catalogOutOfStock,
                ),
            ],
          ),
          Text(
            AppStrings.catalogOptionPrice,
            style: theme.textTheme.labelMedium?.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: canManage ? onTap : null,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.outlineVariant),
                    ),
                    child: Text(
                      MoneyFormat.dzdOrEmpty(option.additionalPriceMinor),
                      textAlign: TextAlign.end,
                      style: theme.textTheme.bodyLarge,
                    ),
                  ),
                ),
              ),
              if (canManage)
                IconButton(
                  key: Key('option-delete-${option.id}'),
                  tooltip: AppStrings.catalogOptionDelete,
                  color: AppColors.error,
                  icon: const Icon(Icons.delete_outline),
                  onPressed: onDelete,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DashedAction extends StatelessWidget {
  const _DashedAction({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.filled = false,
    this.compact = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool filled;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final color = filled ? AppColors.primary : AppColors.onSurfaceVariant;
    return Material(
      color: filled ? AppColors.surfaceContainerLow : Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(compact ? 8 : 12),
        side: BorderSide(
          color: filled ? AppColors.primary : AppColors.outline,
          width: filled ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(compact ? 8 : 12),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(
            vertical: compact ? 10 : 16,
            horizontal: 16,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: filled || compact ? AppColors.primary : color),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: filled || compact ? AppColors.primary : color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

typedef _GroupDraft = ({String name, int maxSelections, bool delete});

class _GroupSheet extends StatefulWidget {
  const _GroupSheet({required this.required, this.group});

  final bool required;
  final CatalogOptionGroup? group;

  @override
  State<_GroupSheet> createState() => _GroupSheetState();
}

class _GroupSheetState extends State<_GroupSheet> {
  late final TextEditingController _name = TextEditingController(
    text: widget.group?.name ?? '',
  );
  late int _max = widget.group?.maxSelections ?? (widget.required ? 1 : 3);

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _confirmDelete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(AppStrings.catalogGroupDelete),
        content: const Text(AppStrings.catalogGroupDeleteConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(AppStrings.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(AppStrings.catalogGroupDelete),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      Navigator.pop(context, (name: '', maxSelections: 0, delete: true));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final valid = _name.text.trim().isNotEmpty && _max >= 1;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: Column(
          key: const Key('option-group-sheet'),
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.group?.name ?? AppStrings.catalogNewGroup,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontStyle: widget.group == null ? FontStyle.italic : null,
                    ),
                  ),
                ),
                if (widget.group != null)
                  IconButton(
                    key: const Key('option-group-delete'),
                    tooltip: AppStrings.catalogGroupDelete,
                    color: AppColors.onSurfaceVariant,
                    icon: const Icon(Icons.delete_outline),
                    onPressed: _confirmDelete,
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              AppStrings.catalogGroupName,
              style: theme.textTheme.labelLarge,
            ),
            const SizedBox(height: 6),
            TextField(
              key: const Key('option-group-name'),
              controller: _name,
              maxLength: 120,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: AppStrings.catalogGroupNameHint,
                counterText: '',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.required
                            ? AppStrings.catalogGroupRequiredSwitch
                            : AppStrings.catalogMaxSelectionsLabel,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        widget.required
                            ? (_max <= 1
                                  ? AppStrings.catalogGroupRequiredSub
                                  : AppStrings.catalogChoiceRange(1, _max))
                            : AppStrings.catalogMaxSelections(_max),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton.outlined(
                  key: const Key('option-group-max-minus'),
                  tooltip: '−',
                  onPressed: _max > 1 ? () => setState(() => _max--) : null,
                  icon: const Icon(Icons.remove),
                ),
                SizedBox(
                  width: 40,
                  child: Text(
                    '$_max',
                    key: const Key('option-group-max'),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                IconButton.outlined(
                  key: const Key('option-group-max-plus'),
                  tooltip: '+',
                  onPressed: _max < 20 ? () => setState(() => _max++) : null,
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 48,
              child: FilledButton(
                key: const Key('option-group-save'),
                onPressed: valid
                    ? () => Navigator.pop(context, (
                        name: _name.text.trim(),
                        maxSelections: _max,
                        delete: false,
                      ))
                    : null,
                child: const Text(AppStrings.catalogGroupSave),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

typedef _OptionDraft = ({
  String name,
  int priceMinor,
  bool available,
  bool delete,
});

class _OptionSheet extends StatefulWidget {
  const _OptionSheet({this.option});

  final CatalogOption? option;

  @override
  State<_OptionSheet> createState() => _OptionSheetState();
}

class _OptionSheetState extends State<_OptionSheet> {
  late final TextEditingController _name = TextEditingController(
    text: widget.option?.name ?? '',
  );
  late final TextEditingController _price = TextEditingController(
    text: widget.option == null
        ? '0'
        : MoneyFormat.minorToMajorInput(widget.option!.additionalPriceMinor),
  );
  late bool _available = widget.option?.available ?? true;

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final price = MoneyFormat.majorInputToMinor(_price.text);
    final valid = _name.text.trim().isNotEmpty && price != null;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          key: const Key('option-sheet'),
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              AppStrings.catalogOptionName,
              style: theme.textTheme.labelLarge,
            ),
            const SizedBox(height: 6),
            TextField(
              key: const Key('option-name'),
              controller: _name,
              maxLength: 120,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                counterText: '',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              AppStrings.catalogOptionPrice,
              style: theme.textTheme.labelLarge,
            ),
            const SizedBox(height: 6),
            TextField(
              key: const Key('option-price'),
              controller: _price,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ],
              textAlign: TextAlign.end,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                suffixText: AppStrings.catalogCurrencySuffix,
                errorText: price == null
                    ? AppStrings.catalogPriceInvalid
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            SwitchListTile(
              key: const Key('option-available'),
              contentPadding: EdgeInsets.zero,
              title: const Text(AppStrings.catalogOptionAvailable),
              value: _available,
              onChanged: (v) => setState(() => _available = v),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                if (widget.option != null) ...[
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: OutlinedButton(
                        key: const Key('option-sheet-delete'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                        ),
                        onPressed: () => Navigator.pop(context, (
                          name: '',
                          priceMinor: 0,
                          available: false,
                          delete: true,
                        )),
                        child: const Text(AppStrings.catalogOptionDelete),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: FilledButton(
                      key: const Key('option-save'),
                      onPressed: valid
                          ? () => Navigator.pop(context, (
                              name: _name.text.trim(),
                              priceMinor: price,
                              available: _available,
                              delete: false,
                            ))
                          : null,
                      child: const Text(AppStrings.catalogSaveProduct),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Read-only sketch of how the groups read for the customer.
class _CustomerPreview extends StatelessWidget {
  const _CustomerPreview({required this.product, required this.groups});

  final CatalogProduct? product;
  final List<CatalogOptionGroup> groups;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        key: const Key('option-groups-preview-sheet'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            AppStrings.catalogCustomerPreview,
            style: theme.textTheme.labelLarge?.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
          if (product != null) ...[
            const SizedBox(height: 8),
            Text(
              product!.name,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              MoneyFormat.dzdOrEmpty(product!.priceMinor),
              style: theme.textTheme.titleMedium?.copyWith(
                color: AppColors.primary,
              ),
            ),
          ],
          for (final g in groups) ...[
            const SizedBox(height: 16),
            Text(
              g.name,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              g.required
                  ? (g.maxSelections <= 1
                        ? AppStrings.catalogSingleChoice
                        : AppStrings.catalogChoiceRange(
                            g.minSelections,
                            g.maxSelections,
                          ))
                  : AppStrings.catalogMaxSelections(g.maxSelections),
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
            for (final o in g.options.where((o) => o.available))
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  g.maxSelections <= 1
                      ? Icons.radio_button_unchecked
                      : Icons.check_box_outline_blank,
                  color: AppColors.outline,
                ),
                title: Text(o.name),
                trailing: Text(
                  '+${MoneyFormat.dzdOrEmpty(o.additionalPriceMinor)}',
                ),
              ),
          ],
        ],
      ),
    );
  }
}
