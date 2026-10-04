import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speedygo_merchant_app/app/theme/app_theme.dart';
import 'package:speedygo_merchant_app/core/media/merchant_media_epoch.dart';
import 'package:speedygo_merchant_app/features/access/application/access_controller.dart';
import 'package:speedygo_merchant_app/features/auth/application/auth_infrastructure.dart';
import 'package:speedygo_merchant_app/features/catalog/data/catalog_models.dart';

/// Loads a bound product photograph with Merchant JWT (not Customer routes).
class MerchantProductThumb extends ConsumerStatefulWidget {
  const MerchantProductThumb({
    super.key,
    required this.product,
    this.size = 52,
    this.width,
  });

  final CatalogProduct product;

  /// Height, and width unless [width] is set.
  final double size;
  final double? width;

  @override
  ConsumerState<MerchantProductThumb> createState() =>
      _MerchantProductThumbState();
}

class _MerchantProductThumbState extends ConsumerState<MerchantProductThumb> {
  Uint8List? _bytes;
  var _loading = false;
  var _failed = false;
  int? _loadedEpoch;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void didUpdateWidget(covariant MerchantProductThumb oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.product.id != widget.product.id ||
        oldWidget.product.hasImage != widget.product.hasImage) {
      _bytes = null;
      _failed = false;
      _loadedEpoch = null;
      _load();
    }
  }

  Future<void> _load({bool force = false}) async {
    if (!mounted) return;
    final epoch = ref.read(merchantMediaEpochProvider);
    if (!force && _loadedEpoch == epoch && (_bytes != null || _failed)) {
      return;
    }
    if (!widget.product.hasImage) {
      if (mounted) {
        setState(() {
          _bytes = null;
          _loading = false;
          _failed = false;
          _loadedEpoch = epoch;
        });
      }
      return;
    }
    final access = ref.read(accessControllerProvider);
    final membership = access.membership;
    final branchId =
        access.selectedBranch?.id ??
        (widget.product.branchId.isNotEmpty ? widget.product.branchId : null);
    if (membership == null || branchId == null) return;
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      final bytes = await ref
          .read(merchantApiProvider)
          .fetchProductImageBytes(
            merchantId: membership.merchantId,
            branchId: branchId,
            productId: widget.product.id,
          );
      if (!mounted) return;
      setState(() {
        _bytes = bytes;
        _loading = false;
        _failed = bytes == null || bytes.isEmpty;
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
    final available = widget.product.available;
    return Container(
      width: widget.width ?? widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(MerchantLayout.radiusLg),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.6),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: _bytes != null
          ? Image.memory(
              _bytes!,
              key: ValueKey<int>(_bytes!.length ^ (_loadedEpoch ?? 0)),
              fit: BoxFit.cover,
              width: widget.width ?? widget.size,
              height: widget.size,
              gaplessPlayback: true,
            )
          : _loading
          ? const Center(
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          : _failed
          ? InkWell(
              onTap: () => _load(force: true),
              child: const Icon(
                Icons.refresh,
                size: 20,
                color: AppColors.onSurfaceVariant,
              ),
            )
          : Icon(
              Icons.inventory_2_outlined,
              size: 22,
              color: available ? AppColors.onSurfaceVariant : AppColors.outline,
            ),
    );
  }
}
