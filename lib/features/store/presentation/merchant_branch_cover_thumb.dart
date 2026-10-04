import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speedygo_merchant_app/app/theme/app_theme.dart';
import 'package:speedygo_merchant_app/core/media/merchant_media_epoch.dart';
import 'package:speedygo_merchant_app/features/access/application/access_controller.dart';
import 'package:speedygo_merchant_app/features/auth/application/auth_infrastructure.dart';

enum MerchantBranchMediaKind { cover, logo }

/// Profile / storefront thumb for the bound branch cover (Merchant JWT).
class MerchantBranchCoverThumb extends ConsumerStatefulWidget {
  const MerchantBranchCoverThumb({
    super.key,
    this.size = 64,
    this.width,
    this.height,
    this.borderRadius = 12,
    this.framed = true,
    this.placeholder,
    this.kind = MerchantBranchMediaKind.cover,
  });

  final double size;
  final double? width;
  final double? height;
  final double borderRadius;

  /// White tile with outline and shadow; off for full-bleed heroes.
  final bool framed;

  /// Shown when no media is bound (defaults to a storefront icon).
  final Widget? placeholder;

  /// Which bound branch media to stream.
  final MerchantBranchMediaKind kind;

  @override
  ConsumerState<MerchantBranchCoverThumb> createState() =>
      _MerchantBranchCoverThumbState();
}

class _MerchantBranchCoverThumbState
    extends ConsumerState<MerchantBranchCoverThumb> {
  Uint8List? _bytes;
  var _loading = false;
  var _failed = false;
  String? _branchId;
  int? _loadedEpoch;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load(force: true));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final branchId = ref.read(accessControllerProvider).selectedBranch?.id;
    if (branchId != _branchId) {
      _branchId = branchId;
      _bytes = null;
      _failed = false;
      _loadedEpoch = null;
      _load(force: true);
    }
  }

  Future<void> _load({bool force = false}) async {
    final epoch = ref.read(merchantMediaEpochProvider);
    if (!force && _loadedEpoch == epoch && !_loading) return;
    final access = ref.read(accessControllerProvider);
    final membership = access.membership;
    final branch = access.selectedBranch;
    if (membership == null || branch == null) return;
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      final api = ref.read(merchantApiProvider);
      final bytes = widget.kind == MerchantBranchMediaKind.logo
          ? await api.fetchBranchLogoBytes(
              merchantId: membership.merchantId,
              branchId: branch.id,
            )
          : await api.fetchBranchCoverBytes(
              merchantId: membership.merchantId,
              branchId: branch.id,
            );
      if (!mounted) return;
      setState(() {
        _bytes = bytes;
        _loading = false;
        _failed = false;
        _loadedEpoch = epoch;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _bytes = null;
        _loading = false;
        _failed = true;
        _loadedEpoch = epoch;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<int>(merchantMediaEpochProvider, (prev, next) {
      if (prev != next) {
        _load(force: true);
      }
    });
    final width = widget.width ?? widget.size;
    final height = widget.height ?? widget.size;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: widget.framed
            ? AppColors.surface
            : AppColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(widget.borderRadius),
        border: widget.framed
            ? Border.all(color: AppColors.outlineVariant)
            : null,
        boxShadow: widget.framed
            ? [
                BoxShadow(
                  color: AppColors.onSurface.withValues(alpha: 0.06),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      clipBehavior: Clip.antiAlias,
      child: _bytes != null
          ? Image.memory(
              _bytes!,
              key: ValueKey<int>(_bytes!.length ^ (_loadedEpoch ?? 0)),
              fit: BoxFit.cover,
              width: width,
              height: height,
              gaplessPlayback: true,
            )
          : _loading
          ? const Center(
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          : _failed
          ? InkWell(
              onTap: () => _load(force: true),
              child: const Icon(
                Icons.refresh,
                color: AppColors.onSurfaceVariant,
                size: 24,
              ),
            )
          : widget.placeholder ??
                const Icon(
                  Icons.storefront,
                  color: AppColors.primary,
                  size: 30,
                ),
    );
  }
}

/// Bound branch logo (Merchant JWT); falls back to [placeholder] when none.
class MerchantBranchLogoThumb extends StatelessWidget {
  const MerchantBranchLogoThumb({
    super.key,
    this.size = 64,
    this.borderRadius = 8,
    this.placeholder,
  });

  final double size;
  final double borderRadius;
  final Widget? placeholder;

  @override
  Widget build(BuildContext context) {
    return MerchantBranchCoverThumb(
      size: size,
      borderRadius: borderRadius,
      placeholder: placeholder,
      kind: MerchantBranchMediaKind.logo,
    );
  }
}
