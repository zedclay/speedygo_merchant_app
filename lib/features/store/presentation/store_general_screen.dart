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

/// Backend `UpdateMerchantBranchDto.name` limit.
const storeBranchNameMaxLength = 255;

final _emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

/// "Informations générales" (`store_information_french`): OWNER/MANAGER edit
/// the branch name, Arabic name, description and public e-mail through the
/// branch PATCH; the verified merchant name is read-only. Empty fields are
/// sent as `null`. A failed save keeps every draft value on screen.
class StoreGeneralScreen extends ConsumerStatefulWidget {
  const StoreGeneralScreen({super.key});

  @override
  ConsumerState<StoreGeneralScreen> createState() => _StoreGeneralScreenState();
}

class _StoreGeneralScreenState extends ConsumerState<StoreGeneralScreen> {
  late final TextEditingController _name;
  late final TextEditingController _nameAr;
  late final TextEditingController _description;
  late final TextEditingController _email;
  late final String _initialName;
  late final String _initialNameAr;
  late final String _initialDescription;
  late final String _initialEmail;
  bool _saving = false;
  String? _error;
  String? _emailError;

  @override
  void initState() {
    super.initState();
    final branch = ref.read(accessControllerProvider).selectedBranch;
    _initialName = branch?.name ?? '';
    _initialNameAr = branch?.nameAr ?? '';
    _initialDescription = branch?.description ?? '';
    _initialEmail = branch?.publicEmail ?? '';
    TextEditingController field(String text) =>
        TextEditingController(text: text)..addListener(
          () => setState(() {
            _error = null;
            _emailError = null;
          }),
        );
    _name = field(_initialName);
    _nameAr = field(_initialNameAr);
    _description = field(_initialDescription);
    _email = field(_initialEmail);
  }

  @override
  void dispose() {
    _name.dispose();
    _nameAr.dispose();
    _description.dispose();
    _email.dispose();
    super.dispose();
  }

  bool get _canManage {
    final role = ref
        .read(accessControllerProvider)
        .membership
        ?.role
        .toUpperCase();
    return role == 'OWNER' || role == 'MANAGER';
  }

  bool get _nameChanged => _name.text.trim() != _initialName.trim();

  /// Changed optional public fields; a cleared field maps to `null`.
  Map<String, String?> get _publicChanges {
    String? orNull(TextEditingController c) {
      final v = c.text.trim();
      return v.isEmpty ? null : v;
    }

    return {
      if (_nameAr.text.trim() != _initialNameAr.trim())
        'nameAr': orNull(_nameAr),
      if (_description.text.trim() != _initialDescription.trim())
        'description': orNull(_description),
      if (_email.text.trim() != _initialEmail.trim())
        'publicEmail': orNull(_email),
    };
  }

  bool get _changed => _nameChanged || _publicChanges.isNotEmpty;

  Future<void> _save() async {
    if (!_canManage || _saving || !_changed) return;
    final access = ref.read(accessControllerProvider);
    final membership = access.membership;
    final branch = access.selectedBranch;
    if (membership == null || branch == null) return;
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _error = AppStrings.storeGeneralNameRequired);
      return;
    }
    final email = _email.text.trim();
    if (email.isNotEmpty && !_emailPattern.hasMatch(email)) {
      setState(() => _emailError = AppStrings.storeGeneralEmailInvalid);
      return;
    }
    final publicChanges = _publicChanges;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final updated = await ref
          .read(merchantApiProvider)
          .updateBranch(
            merchantId: membership.merchantId,
            branchId: branch.id,
            name: _nameChanged ? name : null,
            publicInfo: publicChanges.isEmpty ? null : publicChanges,
          );
      final notifier = ref.read(accessControllerProvider.notifier);
      if (!mounted) return;
      final messenger = ScaffoldMessenger.maybeOf(context);
      context.pop(true);
      messenger?.showSnackBar(
        const SnackBar(content: Text(AppStrings.storeGeneralSaved)),
      );
      // Access changes refresh the router from its last reported location;
      // until the pop is reported at the end of the frame, that location
      // still contains this screen and would rebuild it.
      await WidgetsBinding.instance.endOfFrame;
      await notifier.selectBranch(updated);
      try {
        await notifier.refreshInPlace();
      } catch (_) {}
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = switch (e.statusCode) {
          403 => AppStrings.storeGeneralForbidden,
          409 => AppStrings.storeGeneralRestricted,
          _ => AppStrings.storeGeneralSaveError,
        };
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = AppStrings.storeGeneralSaveError;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final access = ref.watch(accessControllerProvider);
    final merchantName = access.membership?.merchantName ?? '';
    final canManage = _canManage;
    final outline = OutlineInputBorder(
      borderRadius: BorderRadius.circular(4),
      borderSide: const BorderSide(color: AppColors.outlineVariant),
    );
    return MerchantScaffold(
      title: AppStrings.storeGeneralTitle,
      titleStyle: theme.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
        color: AppColors.primary,
      ),
      bodyPadding: EdgeInsets.zero,
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              key: const Key('store-general-screen'),
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (!canManage) ...[
                    Text(
                      AppStrings.storeGeneralReadOnly,
                      key: const Key('store-general-read-only'),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  MerchantCard(
                    child: MerchantLabeledField(
                      label: AppStrings.storeGeneralBranchName,
                      helper: AppStrings.storeGeneralBranchNameHint,
                      child: TextField(
                        key: const Key('store-general-branch-name'),
                        controller: _name,
                        enabled: canManage && !_saving,
                        maxLength: storeBranchNameMaxLength,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          border: outline,
                          enabledBorder: outline,
                          filled: true,
                          fillColor: AppColors.surfaceContainerLowest,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  MerchantCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        MerchantLabeledField(
                          label: AppStrings.storeGeneralNameAr,
                          helper: AppStrings.storeGeneralNameArHint,
                          child: TextField(
                            key: const Key('store-general-name-ar'),
                            controller: _nameAr,
                            enabled: canManage && !_saving,
                            maxLength: storeBranchNameMaxLength,
                            textDirection: TextDirection.rtl,
                            textInputAction: TextInputAction.next,
                            decoration: InputDecoration(
                              border: outline,
                              enabledBorder: outline,
                              filled: true,
                              fillColor: AppColors.surfaceContainerLowest,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        MerchantLabeledField(
                          label: AppStrings.storeGeneralDescription,
                          helper: AppStrings.storeGeneralDescriptionHint,
                          child: TextField(
                            key: const Key('store-general-description'),
                            controller: _description,
                            enabled: canManage && !_saving,
                            minLines: 3,
                            maxLines: 6,
                            textInputAction: TextInputAction.newline,
                            decoration: InputDecoration(
                              border: outline,
                              enabledBorder: outline,
                              filled: true,
                              fillColor: AppColors.surfaceContainerLowest,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        MerchantLabeledField(
                          label: AppStrings.storeGeneralPublicEmail,
                          helper: AppStrings.storeGeneralPublicEmailHint,
                          child: TextField(
                            key: const Key('store-general-public-email'),
                            controller: _email,
                            enabled: canManage && !_saving,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => _save(),
                            decoration: InputDecoration(
                              border: outline,
                              enabledBorder: outline,
                              filled: true,
                              fillColor: AppColors.surfaceContainerLowest,
                              errorText: _emailError,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  MerchantCard(
                    key: const Key('store-general-merchant'),
                    child: MerchantLabeledField(
                      label: AppStrings.storeGeneralMerchantName,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  merchantName.isEmpty ? '—' : merchantName,
                                  key: const Key('store-general-merchant-name'),
                                  style: theme.textTheme.titleMedium,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  AppStrings.storeGeneralMerchantLocked,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: AppColors.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.lock_outline,
                            key: Key('store-general-merchant-lock'),
                            size: 20,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    AppStrings.storeGeneralPhoneElsewhere,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _CustomerPreview(
                    name: _name.text.trim(),
                    nameAr: _nameAr.text.trim(),
                    description: _description.text.trim(),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _error!,
                      key: const Key('store-general-error'),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.error,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (canManage)
            MerchantStickyBar(
              child: SizedBox(
                height: 48,
                child: FilledButton(
                  key: const Key('store-general-save'),
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  onPressed: _changed && !_saving ? _save : null,
                  child: _saving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text(AppStrings.storeGeneralSave),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Light preview built only from fields the server returns: the draft names
/// and description, the category when set, and the effective open state.
class _CustomerPreview extends ConsumerWidget {
  const _CustomerPreview({
    required this.name,
    required this.nameAr,
    required this.description,
  });

  final String name;
  final String nameAr;
  final String description;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final open = ref.watch(branchAvailabilityControllerProvider).value;
    final category = ref.watch(branchClassificationProvider).value;
    return MerchantCard(
      key: const Key('store-general-preview'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.storeGeneralPreviewTitle.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              color: AppColors.onSurfaceVariant,
              letterSpacing: 0.8,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            name.isEmpty ? '—' : name,
            key: const Key('store-general-preview-name'),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          if (nameAr.isNotEmpty)
            Text(
              nameAr,
              textDirection: TextDirection.rtl,
              style: theme.textTheme.bodyMedium,
            ),
          if (category != null && category.name.isNotEmpty)
            Text(
              category.name,
              key: const Key('store-general-preview-category'),
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
          if (open != null) ...[
            const SizedBox(height: 8),
            StatusBadge(
              key: const Key('store-general-preview-open'),
              label: open.isOpenNow
                  ? AppStrings.storeGeneralPreviewOpen
                  : AppStrings.storeGeneralPreviewClosed,
              tone: open.isOpenNow ? StatusTone.success : StatusTone.neutral,
            ),
          ],
          if (description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              description,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ],
      ),
    );
  }
}
