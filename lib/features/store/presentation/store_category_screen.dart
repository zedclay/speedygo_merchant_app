import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:speedygo_merchant_app/app/theme/app_theme.dart';
import 'package:speedygo_merchant_app/core/constants/app_strings.dart';
import 'package:speedygo_merchant_app/core/errors/app_exception.dart';
import 'package:speedygo_merchant_app/core/widgets/merchant_ui.dart';
import 'package:speedygo_merchant_app/features/access/application/access_controller.dart';
import 'package:speedygo_merchant_app/features/auth/application/auth_infrastructure.dart';
import 'package:speedygo_merchant_app/features/store/application/store_controllers.dart';
import 'package:speedygo_merchant_app/features/store/data/classification_models.dart';

/// "Catégorie de l'établissement" (`store_category_selection_french`):
/// single-select (0..1) among server-managed commerce verticals. OWNER and
/// MANAGER save with PUT, or clear with DELETE; STAFF sees it read-only.
class StoreCategoryScreen extends ConsumerStatefulWidget {
  const StoreCategoryScreen({super.key});

  @override
  ConsumerState<StoreCategoryScreen> createState() =>
      _StoreCategoryScreenState();
}

class _StoreCategoryScreenState extends ConsumerState<StoreCategoryScreen> {
  final _search = TextEditingController();
  String? _draftId;
  bool _touched = false;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _search.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  bool get _canManage {
    final role = ref.read(accessControllerProvider).membership?.role ?? '';
    return role == 'OWNER' || role == 'MANAGER';
  }

  void _pick(CommerceVertical vertical) {
    if (!_canManage || _saving) return;
    setState(() {
      _touched = true;
      _draftId = vertical.id;
      _error = null;
    });
  }

  String _messageFor(Object e) {
    if (e is ApiException) {
      return switch (e.statusCode) {
        403 => AppStrings.storeCategoryForbidden,
        409 => AppStrings.storeCategoryRestricted,
        _ => AppStrings.storeCategorySaveError,
      };
    }
    return AppStrings.storeCategorySaveError;
  }

  Future<void> _run({
    required Future<void> Function(String merchantId, String branchId) action,
    required String savedMessage,
  }) async {
    if (!_canManage || _saving) return;
    final access = ref.read(accessControllerProvider);
    final membership = access.membership;
    final branch = access.selectedBranch;
    if (membership == null || branch == null) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await action(membership.merchantId, branch.id);
      ref.invalidate(branchClassificationProvider);
      if (!mounted) return;
      final messenger = ScaffoldMessenger.maybeOf(context);
      context.pop(true);
      messenger?.showSnackBar(SnackBar(content: Text(savedMessage)));
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = _messageFor(e);
      });
    }
  }

  Future<void> _save(String verticalId) => _run(
    savedMessage: AppStrings.storeCategorySaved,
    action: (merchantId, branchId) => ref
        .read(merchantApiProvider)
        .putBranchClassification(
          merchantId: merchantId,
          branchId: branchId,
          verticalId: verticalId,
        ),
  );

  Future<void> _clear() => _run(
    savedMessage: AppStrings.storeCategoryCleared,
    action: (merchantId, branchId) => ref
        .read(merchantApiProvider)
        .deleteBranchClassification(merchantId: merchantId, branchId: branchId),
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canManage = _canManage;
    final verticals = ref.watch(commerceVerticalsProvider);
    final current =
        ref.watch(branchClassificationProvider).value ??
        ref.watch(accessControllerProvider).selectedBranch?.classification;
    final selectedId = _touched ? _draftId : current?.verticalId;
    final dirty =
        _touched && _draftId != null && _draftId != current?.verticalId;

    return MerchantScaffold(
      title: AppStrings.storeCategoryTitle,
      titleStyle: theme.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
        color: AppColors.primary,
      ),
      bodyPadding: EdgeInsets.zero,
      body: Column(
        children: [
          Expanded(
            child: ListView(
              key: const Key('store-category-screen'),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              children: [
                if (!canManage) ...[
                  Text(
                    AppStrings.storeCategoryReadOnly,
                    key: const Key('store-category-read-only'),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                Text(
                  AppStrings.storeCategorySubtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  key: const Key('store-category-search'),
                  controller: _search,
                  textInputAction: TextInputAction.search,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: AppStrings.storeCategorySearch,
                  ),
                ),
                const SizedBox(height: 12),
                _InfoBanner(theme: theme),
                const SizedBox(height: 16),
                ...verticals.when(
                  loading: () => const [
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  ],
                  error: (_, _) => [
                    _Message(
                      key: const Key('store-category-load-error'),
                      text: AppStrings.storeCategoryLoadError,
                      actionLabel: AppStrings.retry,
                      onAction: () => ref.invalidate(commerceVerticalsProvider),
                    ),
                  ],
                  data: (items) => _tiles(items, selectedId, canManage),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    key: const Key('store-category-error'),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.error,
                    ),
                  ),
                ],
                if (canManage && current != null) ...[
                  const SizedBox(height: 16),
                  TextButton(
                    key: const Key('store-category-clear'),
                    onPressed: _saving ? null : _clear,
                    child: const Text(AppStrings.storeCategoryClear),
                  ),
                ],
              ],
            ),
          ),
          if (canManage)
            MerchantStickyBar(
              child: SizedBox(
                height: 48,
                child: FilledButton(
                  key: const Key('store-category-save'),
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  onPressed: dirty && !_saving ? () => _save(_draftId!) : null,
                  child: _saving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text(AppStrings.storeCategorySave),
                ),
              ),
            ),
        ],
      ),
    );
  }

  List<Widget> _tiles(
    List<CommerceVertical> items,
    String? selectedId,
    bool canManage,
  ) {
    if (items.isEmpty) {
      return const [
        _Message(
          key: Key('store-category-empty'),
          text: AppStrings.storeCategoryEmpty,
        ),
      ];
    }
    final query = _search.text.trim().toLowerCase();
    final shown = query.isEmpty
        ? items
        : items.where((v) => v.name.toLowerCase().contains(query)).toList();
    if (shown.isEmpty) {
      return const [
        _Message(
          key: Key('store-category-no-match'),
          text: AppStrings.storeCategoryNoMatch,
        ),
      ];
    }
    return [
      for (final vertical in shown)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _VerticalTile(
            tileKey: Key('store-category-${vertical.slug}'),
            vertical: vertical,
            selected: vertical.id == selectedId,
            enabled: canManage && !_saving,
            onTap: () => _pick(vertical),
          ),
        ),
    ];
  }
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primaryFixed.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: AppColors.primary, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              AppStrings.storeCategoryInfo,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({
    super.key,
    required this.text,
    this.actionLabel,
    this.onAction,
  });

  final String text;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Text(
            text,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(color: AppColors.onSurfaceVariant),
          ),
          if (actionLabel != null)
            TextButton(onPressed: onAction, child: Text(actionLabel!)),
        ],
      ),
    );
  }
}

class _VerticalTile extends StatelessWidget {
  const _VerticalTile({
    required this.tileKey,
    required this.vertical,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final Key tileKey;
  final CommerceVertical vertical;
  final bool selected;
  final bool enabled;
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
          onTap: enabled ? onTap : null,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 56),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      vertical.name,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: selected
                            ? AppColors.primary
                            : AppColors.onSurface,
                      ),
                    ),
                  ),
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
