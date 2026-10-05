import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:speedygo_merchant_app/app/theme/app_theme.dart';
import 'package:speedygo_merchant_app/core/constants/app_strings.dart';
import 'package:speedygo_merchant_app/core/errors/app_exception.dart';
import 'package:speedygo_merchant_app/core/media/merchant_image_picker.dart';
import 'package:speedygo_merchant_app/core/media/merchant_media_epoch.dart';
import 'package:speedygo_merchant_app/core/widgets/merchant_ui.dart';
import 'package:speedygo_merchant_app/features/access/application/access_controller.dart';
import 'package:speedygo_merchant_app/features/auth/application/auth_infrastructure.dart';

class StoreCoverScreen extends ConsumerStatefulWidget {
  const StoreCoverScreen({super.key});

  @override
  ConsumerState<StoreCoverScreen> createState() => _StoreCoverScreenState();
}

class _StoreCoverScreenState extends ConsumerState<StoreCoverScreen> {
  Uint8List? _bytes;
  String? _filename;
  String? _contentType;
  var _saving = false;
  var _removing = false;
  var _loadingRemote = true;
  var _remoteFailed = false;
  var _remoteIsLocalPick = false;
  var _hasRemote = false;
  String? _error;
  String? _info;

  Uint8List? _logoBytes;
  String? _logoFilename;
  String? _logoContentType;
  var _logoPending = false;
  var _hasRemoteLogo = false;
  var _loadingLogo = true;
  var _logoFailed = false;
  var _removingLogo = false;

  bool get _canManage {
    final role = ref.read(accessControllerProvider).membership?.role ?? '';
    final upper = role.toUpperCase();
    return upper == 'OWNER' || upper == 'MANAGER';
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadRemoteCover();
      _loadRemoteLogo();
    });
  }

  Future<void> _loadRemoteLogo() async {
    final access = ref.read(accessControllerProvider);
    final membership = access.membership;
    final branch = access.selectedBranch;
    if (membership == null || branch == null) {
      if (mounted) setState(() => _loadingLogo = false);
      return;
    }
    setState(() {
      _loadingLogo = true;
      _logoFailed = false;
    });
    try {
      final bytes = await ref
          .read(merchantApiProvider)
          .fetchBranchLogoBytes(
            merchantId: membership.merchantId,
            branchId: branch.id,
          );
      if (!mounted) return;
      setState(() {
        _hasRemoteLogo = bytes != null && bytes.isNotEmpty;
        if (!_logoPending) {
          _logoBytes = _hasRemoteLogo ? bytes : null;
        }
        _loadingLogo = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadingLogo = false;
        _logoFailed = true;
      });
    }
  }

  Future<void> _pickLogo() async {
    final picked = await pickMerchantImage(
      context,
      constraints: MerchantImageConstraints.logo,
    );
    if (picked == null || !mounted) return;
    setState(() {
      _logoBytes = picked.bytes;
      _logoFilename = picked.filename;
      _logoContentType = picked.contentType;
      _logoPending = true;
      _logoFailed = false;
      _error = null;
      _info = null;
    });
  }

  @visibleForTesting
  void debugSetLogoBytes({
    required Uint8List bytes,
    String filename = 'logo.jpg',
    String contentType = 'image/jpeg',
  }) {
    setState(() {
      _logoBytes = bytes;
      _logoFilename = filename;
      _logoContentType = contentType;
      _logoPending = true;
      _error = null;
      _info = null;
    });
  }

  Future<void> _removeLogo() async {
    if (!_canManage || _removingLogo || _saving) return;
    if (_logoPending) {
      setState(() {
        _logoPending = false;
        _logoBytes = null;
        _error = null;
      });
      await _loadRemoteLogo();
      return;
    }
    final access = ref.read(accessControllerProvider);
    final membership = access.membership;
    final branch = access.selectedBranch;
    if (membership == null || branch == null) return;
    setState(() {
      _removingLogo = true;
      _error = null;
    });
    try {
      await ref
          .read(merchantApiProvider)
          .deleteBranchLogo(
            merchantId: membership.merchantId,
            branchId: branch.id,
          );
      bumpMerchantMediaEpoch(ref);
      if (!mounted) return;
      setState(() {
        _logoBytes = null;
        _hasRemoteLogo = false;
        _removingLogo = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.storeLogoRemoved)),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _removingLogo = false;
        _error = AppStrings.storeLogoRemoveError;
      });
    }
  }

  /// Uploads and binds the pending logo; returns false (with [_error] set)
  /// when either step fails.
  Future<bool> _saveLogo(String merchantId, String branchId) async {
    final bytes = _logoBytes;
    if (!_logoPending || bytes == null) return true;
    final api = ref.read(merchantApiProvider);
    String uploadReference;
    try {
      final uploaded = await api.uploadBranchLogoContent(
        merchantId: merchantId,
        branchId: branchId,
        filename: _logoFilename ?? 'logo.jpg',
        contentType: _logoContentType ?? 'image/jpeg',
        bytes: bytes,
      );
      uploadReference = uploaded.uploadReference;
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e is AppException
              ? e.message
              : AppStrings.storeLogoUploadError;
        });
      }
      return false;
    }
    try {
      await api.bindBranchLogo(
        merchantId: merchantId,
        branchId: branchId,
        uploadReference: uploadReference,
      );
    } catch (_) {
      if (mounted) setState(() => _error = AppStrings.storeLogoBindPartial);
      return false;
    }
    bumpMerchantMediaEpoch(ref);
    if (mounted) {
      setState(() {
        _logoPending = false;
        _hasRemoteLogo = true;
      });
    }
    return true;
  }

  Future<void> _loadRemoteCover() async {
    final access = ref.read(accessControllerProvider);
    final membership = access.membership;
    final branch = access.selectedBranch;
    if (membership == null || branch == null) {
      if (mounted) {
        setState(() {
          _loadingRemote = false;
          _remoteFailed = false;
        });
      }
      return;
    }
    setState(() {
      _loadingRemote = true;
      _remoteFailed = false;
    });
    try {
      final bytes = await ref
          .read(merchantApiProvider)
          .fetchBranchCoverBytes(
            merchantId: membership.merchantId,
            branchId: branch.id,
          );
      if (!mounted) return;
      setState(() {
        if (bytes != null && bytes.isNotEmpty) {
          _bytes = bytes;
          _filename = 'cover.jpg';
          _contentType = 'image/jpeg';
          _remoteIsLocalPick = false;
          _hasRemote = true;
        } else {
          _hasRemote = false;
          // Missing cover → empty fallback (not a display failure).
          if (!_remoteIsLocalPick) {
            _bytes = null;
          }
        }
        _loadingRemote = false;
        _remoteFailed = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadingRemote = false;
        _remoteFailed = true;
      });
    }
  }

  Future<void> _pick() async {
    final picked = await pickMerchantImage(context);
    if (picked == null || !mounted) return;
    setState(() {
      _bytes = picked.bytes;
      _filename = picked.filename;
      _contentType = picked.contentType;
      _remoteIsLocalPick = true;
      _remoteFailed = false;
      _error = null;
      _info = null;
    });
  }

  @visibleForTesting
  void debugSetCoverBytes({
    required Uint8List bytes,
    String filename = 'cover.jpg',
    String contentType = 'image/jpeg',
  }) {
    setState(() {
      _bytes = bytes;
      _filename = filename;
      _contentType = contentType;
      _remoteIsLocalPick = true;
      _error = null;
      _info = null;
    });
  }

  bool get _coverPending => _bytes != null && _remoteIsLocalPick;

  Future<void> _save() async {
    if (!_canManage || _saving) return;
    if (!_coverPending && !_logoPending) return;
    final access = ref.read(accessControllerProvider);
    final membership = access.membership;
    final branch = access.selectedBranch;
    if (membership == null || branch == null) return;
    setState(() {
      _saving = true;
      _error = null;
      _info = null;
    });
    final logoWasPending = _logoPending;
    if (!await _saveLogo(membership.merchantId, branch.id)) {
      if (mounted) setState(() => _saving = false);
      return;
    }
    if (!mounted) return;
    final bytes = _bytes;
    if (!_coverPending || bytes == null) {
      context.pop(true);
      return;
    }
    final api = ref.read(merchantApiProvider);
    String? uploadReference;
    try {
      final uploaded = await api.uploadBranchCoverContent(
        merchantId: membership.merchantId,
        branchId: branch.id,
        filename: _filename ?? 'cover.jpg',
        contentType: _contentType ?? 'image/jpeg',
        bytes: bytes,
      );
      uploadReference = uploaded.uploadReference;
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = logoWasPending
            ? AppStrings.storeMediaPartialSaved
            : e is AppException
            ? e.message
            : AppStrings.storeCoverUploadError;
      });
      return;
    }
    try {
      await api.bindBranchCover(
        merchantId: membership.merchantId,
        branchId: branch.id,
        uploadReference: uploadReference,
      );
      bumpMerchantMediaEpoch(ref);
      if (!mounted) return;
      context.pop(true);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = logoWasPending
            ? AppStrings.storeMediaPartialSaved
            : AppStrings.storeCoverBindPartial;
      });
    }
  }

  Future<void> _remove() async {
    if (!_canManage || _removing) return;
    final access = ref.read(accessControllerProvider);
    final membership = access.membership;
    final branch = access.selectedBranch;
    if (membership == null || branch == null) return;
    setState(() {
      _removing = true;
      _error = null;
    });
    try {
      await ref
          .read(merchantApiProvider)
          .deleteBranchCover(
            merchantId: membership.merchantId,
            branchId: branch.id,
          );
      bumpMerchantMediaEpoch(ref);
      if (!mounted) return;
      setState(() {
        _bytes = null;
        _remoteIsLocalPick = false;
        _hasRemote = false;
        _removing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.storeCoverRemove)),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _removing = false;
        _error = AppStrings.storeCoverUploadError;
      });
    }
  }

  Widget _logoActions(bool stacked) {
    final pick = FilledButton.icon(
      key: const Key('store-logo-pick'),
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      onPressed: _saving || _removingLogo ? null : _pickLogo,
      icon: const Icon(Icons.edit, size: 18),
      label: Text(
        _logoBytes == null ? AppStrings.storeLogoAdd : AppStrings.storeLogoEdit,
      ),
    );
    final remove = OutlinedButton.icon(
      key: const Key('store-logo-remove'),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.error,
        side: const BorderSide(color: AppColors.error),
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      onPressed: _saving || _removingLogo || (!_hasRemoteLogo && !_logoPending)
          ? null
          : _removeLogo,
      icon: const Icon(Icons.delete_outline, size: 18),
      label: Text(
        _removingLogo ? AppStrings.loading : AppStrings.storeLogoRemove,
      ),
    );
    if (stacked) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [pick, const SizedBox(height: 8), remove],
      );
    }
    return Row(
      children: [
        Expanded(child: pick),
        const SizedBox(width: 12),
        Expanded(child: remove),
      ],
    );
  }

  Widget _logoPreview(ThemeData theme) {
    final Widget child;
    if (_logoBytes != null) {
      child = Image.memory(
        _logoBytes!,
        key: const Key('store-logo-image'),
        fit: BoxFit.cover,
        gaplessPlayback: true,
      );
    } else if (_loadingLogo) {
      child = const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    } else if (_logoFailed) {
      child = IconButton(
        key: const Key('store-logo-remote-retry'),
        onPressed: _loadRemoteLogo,
        icon: const Icon(Icons.refresh, color: AppColors.onSurfaceVariant),
        tooltip: AppStrings.retry,
      );
    } else {
      child = Column(
        key: const Key('store-logo-empty'),
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.storefront, color: AppColors.outline, size: 36),
          const SizedBox(height: 4),
          Text(
            AppStrings.storeLogoEmpty,
            style: theme.textTheme.labelSmall?.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
      );
    }
    return Container(
      width: 128,
      height: 128,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.surfaceContainer,
      ),
      foregroundDecoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final canManage = _canManage;
    final theme = Theme.of(context);
    final stacked = MediaQuery.textScalerOf(context).scale(1) >= 1.25;
    final branch = ref.watch(accessControllerProvider).selectedBranch;
    return MerchantScaffold(
      title: AppStrings.storeCoverTitle,
      centerTitle: true,
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              key: const Key('store-cover-screen'),
              padding: const EdgeInsets.only(top: 12, bottom: 96),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  MerchantCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          AppStrings.storeLogoSection,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          AppStrings.storeLogoSectionHint,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                        if (canManage) ...[
                          const SizedBox(height: 12),
                          _logoActions(stacked),
                        ],
                        const SizedBox(height: 16),
                        Center(child: _logoPreview(theme)),
                        if (_logoPending) ...[
                          const SizedBox(height: 8),
                          Text(
                            key: const Key('store-logo-pending'),
                            AppStrings.storeLogoPending,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ] else if (_logoFailed) ...[
                          const SizedBox(height: 8),
                          Text(
                            key: const Key('store-logo-remote-error'),
                            AppStrings.storeLogoRemoteUnavailable,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  MerchantCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          AppStrings.storeCoverSection,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          AppStrings.storeCoverSectionHint,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 12),
                        AspectRatio(
                          aspectRatio: 16 / 9,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              DecoratedBox(
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceContainerHigh,
                                  borderRadius: BorderRadius.circular(12),
                                  gradient: _bytes == null
                                      ? const LinearGradient(
                                          colors: [
                                            AppColors.surfaceContainerHigh,
                                            AppColors.surfaceDim,
                                          ],
                                        )
                                      : null,
                                ),
                                child: _loadingRemote
                                    ? const Center(
                                        child: SizedBox(
                                          width: 28,
                                          height: 28,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        ),
                                      )
                                    : _bytes != null
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.memory(
                                          _bytes!,
                                          fit: BoxFit.cover,
                                          gaplessPlayback: true,
                                        ),
                                      )
                                    : _remoteFailed
                                    ? Center(
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                              Icons.broken_image_outlined,
                                              size: 40,
                                              color: AppColors.outline,
                                            ),
                                            const SizedBox(height: 8),
                                            TextButton.icon(
                                              key: const Key(
                                                'store-cover-remote-retry',
                                              ),
                                              onPressed: _loadRemoteCover,
                                              icon: const Icon(Icons.refresh),
                                              label: Text(
                                                AppStrings.retry,
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                    : const Center(
                                        child: Icon(
                                          Icons.image_outlined,
                                          size: 48,
                                          color: AppColors.outline,
                                        ),
                                      ),
                              ),
                              if (canManage)
                                Positioned(
                                  right: 10,
                                  bottom: 10,
                                  child: Material(
                                    color: AppColors.surface,
                                    borderRadius: BorderRadius.circular(20),
                                    child: InkWell(
                                      key: const Key('store-cover-pick'),
                                      onTap: _saving ? null : _pick,
                                      borderRadius: BorderRadius.circular(20),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 8,
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                              Icons.swap_horiz,
                                              size: 18,
                                              color: AppColors.primaryContainer,
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              _bytes == null
                                                  ? AppStrings.storeCoverPick
                                                  : AppStrings
                                                        .storeCoverReplace,
                                              style: theme.textTheme.labelLarge
                                                  ?.copyWith(
                                                    color: AppColors
                                                        .primaryContainer,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if (canManage && _hasRemote) ...[
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            key: const Key('store-cover-remove'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.error,
                              side: const BorderSide(color: AppColors.error),
                              minimumSize: const Size.fromHeight(44),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: _removing || _saving ? null : _remove,
                            icon: const Icon(Icons.delete_outline, size: 20),
                            label: Text(
                              _removing
                                  ? AppStrings.loading
                                  : AppStrings.storeCoverRemove,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  MerchantCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.visibility_outlined,
                              color: AppColors.primaryContainer,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              AppStrings.storeCustomerPreviewTitle,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          AppStrings.storeCustomerPreviewHint,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 12),
                        AspectRatio(
                          aspectRatio: 16 / 9,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: AppColors.surfaceContainerHigh,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Stack(
                              children: [
                                if (_bytes != null)
                                  Positioned.fill(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.memory(
                                        _bytes!,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                Positioned(
                                  left: 12,
                                  bottom: 12,
                                  child: CircleAvatar(
                                    key: const Key('store-preview-avatar'),
                                    radius: 22,
                                    backgroundColor: AppColors.surface,
                                    foregroundImage: _logoBytes != null
                                        ? MemoryImage(_logoBytes!)
                                        : null,
                                    child: Text(
                                      (branch?.name.isNotEmpty ?? false)
                                          ? branch!.name.characters.first
                                                .toUpperCase()
                                          : 'S',
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          branch?.name ?? AppStrings.storeProfileTitle,
                          style: theme.textTheme.titleMedium,
                        ),
                      ],
                    ),
                  ),
                  if (_remoteFailed && _bytes == null) ...[
                    const SizedBox(height: 12),
                    Text(
                      key: const Key('store-cover-remote-error'),
                      AppStrings.storeCoverRemoteUnavailable,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      key: const Key('store-cover-error'),
                      _error!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.error,
                      ),
                    ),
                  ],
                  if (_info != null && _error == null) ...[
                    const SizedBox(height: 12),
                    Text(
                      key: const Key('store-cover-info'),
                      _info!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.onSurfaceVariant,
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
                height: 52,
                child: FilledButton(
                  key: const Key('store-cover-save'),
                  onPressed: _saving || (!_coverPending && !_logoPending)
                      ? null
                      : _save,
                  child: Text(
                    _saving ? AppStrings.loading : AppStrings.storeCoverSave,
                    maxLines: 2,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
