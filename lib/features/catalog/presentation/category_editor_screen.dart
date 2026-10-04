import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:speedygo_merchant_app/app/theme/app_theme.dart';
import 'package:speedygo_merchant_app/core/constants/app_strings.dart';
import 'package:speedygo_merchant_app/core/widgets/merchant_ui.dart';
import 'package:speedygo_merchant_app/features/access/application/access_controller.dart';
import 'package:speedygo_merchant_app/features/catalog/application/catalog_controller.dart';
import 'package:speedygo_merchant_app/features/catalog/presentation/catalog_widgets.dart';

class CategoryEditorScreen extends ConsumerStatefulWidget {
  const CategoryEditorScreen({super.key, this.categoryId});

  final String? categoryId;

  bool get isCreate => categoryId == null || categoryId!.isEmpty;

  @override
  ConsumerState<CategoryEditorScreen> createState() =>
      _CategoryEditorScreenState();
}

class _CategoryEditorScreenState extends ConsumerState<CategoryEditorScreen> {
  late final TextEditingController _name;
  late bool _active;
  var _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController();
    _active = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.isCreate) return;
      final cats = ref.read(catalogControllerProvider).value?.categories ?? [];
      final match = cats.where((c) => c.id == widget.categoryId).firstOrNull;
      if (match != null) {
        setState(() {
          _name.text = match.name;
          _active = match.active;
        });
      }
    });
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  bool get _canManage {
    final role = ref.read(accessControllerProvider).membership?.role ?? '';
    final upper = role.toUpperCase();
    return upper == 'OWNER' || upper == 'MANAGER';
  }

  InputDecoration _decoration() {
    return InputDecoration(
      filled: true,
      fillColor: AppColors.surfaceContainerLow,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.outlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
    );
  }

  Future<void> _save() async {
    if (!_canManage || _saving) return;
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _error = AppStrings.catalogSaveError);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final notifier = ref.read(catalogControllerProvider.notifier);
      if (widget.isCreate) {
        await notifier.createCategory(name: name, active: _active);
      } else {
        await notifier.updateCategory(
          categoryId: widget.categoryId!,
          name: name,
          active: _active,
        );
      }
      if (!mounted) return;
      context.pop(true);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = AppStrings.catalogSaveError;
      });
    }
  }

  Future<void> _delete() async {
    if (!_canManage || widget.isCreate) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(AppStrings.catalogDeleteCategory),
        content: const Text(AppStrings.catalogDeleteCategoryConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(AppStrings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(AppStrings.catalogDeleteCategory),
          ),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _saving = true);
    try {
      await ref
          .read(catalogControllerProvider.notifier)
          .deleteCategory(widget.categoryId!);
      if (!mounted) return;
      context.pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = catalogErrorMessage(e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final canManage = _canManage;
    return MerchantScaffold(
      title: widget.isCreate
          ? AppStrings.catalogAddCategory
          : AppStrings.catalogEditCategory,
      centerTitle: true,
      headerColor: AppColors.surface,
      titleStyle: Theme.of(context).textTheme.titleLarge
          ?.copyWith(fontWeight: FontWeight.w700, color: AppColors.primary),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              key: const Key('category-editor-screen'),
              padding: const EdgeInsets.only(top: 12, bottom: 96),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (!canManage) ...[
                    Text(
                      AppStrings.catalogStaffReadOnly,
                      style: Theme.of(context).textTheme.bodyMedium
                          ?.copyWith(color: AppColors.onSurfaceVariant),
                    ),
                    const SizedBox(height: 12),
                  ],
                  MerchantEditorSection(
                    title: AppStrings.catalogCategoryDetails,
                    icon: Icons.edit_note,
                    children: [
                      MerchantLabeledField(
                        label: AppStrings.catalogCategoryName,
                        requiredMark: true,
                        child: TextField(
                          key: const Key('category-editor-name'),
                          controller: _name,
                          enabled: canManage && !_saving,
                          decoration: _decoration(),
                        ),
                      ),
                      const MerchantContractGapRow(
                        label: AppStrings.catalogFieldCategoryNameAr,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  MerchantEditorSection(
                    title: AppStrings.catalogCategorySettings,
                    icon: Icons.settings_suggest_outlined,
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(AppStrings.catalogCategoryActive),
                                Text(
                                  AppStrings.catalogCategoryActiveSub,
                                  style: TextStyle(
                                    color: AppColors.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          CatalogSwitch(
                            key: const Key('category-editor-active'),
                            value: _active,
                            onChanged: canManage && !_saving
                                ? (v) => setState(() => _active = v)
                                : null,
                          ),
                        ],
                      ),
                      const MerchantContractGapRow(
                        label: AppStrings.catalogFieldCategoryDesc,
                      ),
                      if (!widget.isCreate && canManage)
                        OutlinedButton(
                          key: const Key('category-editor-delete'),
                          onPressed: _saving ? null : _delete,
                          child: const Text(AppStrings.catalogDeleteCategory),
                        ),
                    ],
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _error!,
                      style: Theme.of(context).textTheme.bodyMedium
                          ?.copyWith(color: AppColors.error),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (canManage)
            MerchantDualStickyBar(
              secondary: OutlinedButton(
                key: const Key('category-editor-cancel'),
                onPressed: _saving ? null : () => context.pop(),
                child: const Text(
                  AppStrings.catalogCategoryCancel,
                  maxLines: 1,
                ),
              ),
              primary: FilledButton.icon(
                key: const Key('category-editor-save'),
                onPressed: _saving ? null : _save,
                icon: const Icon(Icons.save_outlined, size: 18),
                label: Text(
                  _saving ? AppStrings.loading : AppStrings.catalogSaveProduct,
                  maxLines: 2,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
