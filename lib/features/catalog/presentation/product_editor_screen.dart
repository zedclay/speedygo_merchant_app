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
import 'package:speedygo_merchant_app/core/money/money_format.dart';
import 'package:speedygo_merchant_app/core/widgets/merchant_ui.dart';
import 'package:speedygo_merchant_app/features/access/application/access_controller.dart';
import 'package:speedygo_merchant_app/features/auth/application/auth_infrastructure.dart';
import 'package:speedygo_merchant_app/features/catalog/application/catalog_controller.dart';
import 'package:speedygo_merchant_app/features/catalog/data/catalog_models.dart';
import 'package:speedygo_merchant_app/core/navigation/app_routes.dart';
import 'package:speedygo_merchant_app/features/catalog/presentation/catalog_widgets.dart';
import 'package:speedygo_merchant_app/features/catalog/presentation/product_image_crop_screen.dart';
import 'package:speedygo_merchant_app/features/catalog/presentation/selling_unit_screen.dart';
import 'package:speedygo_merchant_app/features/orders/presentation/prep_time_clock.dart';

class ProductEditorScreen extends ConsumerStatefulWidget {
  const ProductEditorScreen({super.key, this.productId});

  final String? productId;

  bool get isCreate => productId == null || productId!.isEmpty;

  @override
  ConsumerState<ProductEditorScreen> createState() =>
      _ProductEditorScreenState();
}

class _ProductEditorScreenState extends ConsumerState<ProductEditorScreen> {
  final _name = TextEditingController();
  final _description = TextEditingController();
  final _price = TextEditingController();
  final _nameFocus = FocusNode();
  final _priceFocus = FocusNode();
  final _nameFieldKey = GlobalKey();
  final _priceFieldKey = GlobalKey();
  final _categoryFieldKey = GlobalKey();
  String? _categoryId;
  var _available = true;
  var _loading = true;
  var _saving = false;
  var _uploadingImage = false;
  String? _error;
  String? _nameError;
  String? _priceError;
  String? _categoryError;
  Uint8List? _localImageBytes;
  String? _localImageName;
  String? _localImageType;
  String? _productBranchId;
  var _removeRemoteImage = false;
  var _remoteImageFailed = false;
  var _expectRemoteImage = false;
  String? _imageInfo;
  DateTime? _updatedAt;
  List<CatalogOptionGroup>? _groups;
  var _sellingUnit = SellingUnitSelection.none;
  var _sellingUnitTouched = false;

  String? get _resolvedBranchId {
    final selected = ref.read(accessControllerProvider).selectedBranch?.id;
    if (selected != null && selected.isNotEmpty) return selected;
    final fromProduct = _productBranchId;
    if (fromProduct != null && fromProduct.isNotEmpty) return fromProduct;
    return null;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _price.dispose();
    _nameFocus.dispose();
    _priceFocus.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    if (widget.isCreate) {
      for (var i = 0; i < 40; i++) {
        final catalog = ref.read(catalogControllerProvider).value;
        if (catalog != null) {
          if (!mounted) return;
          setState(() {
            _categoryId = catalog.categories
                .where((c) => c.active)
                .map((c) => c.id)
                .firstOrNull;
            _loading = false;
          });
          return;
        }
        await Future<void>.delayed(const Duration(milliseconds: 25));
      }
      if (!mounted) return;
      setState(() => _loading = false);
      return;
    }
    try {
      final access = ref.read(accessControllerProvider);
      final membership = access.membership;
      if (membership == null) {
        setState(() {
          _error = AppStrings.catalogLoadError;
          _loading = false;
        });
        return;
      }
      final product = await ref
          .read(merchantApiProvider)
          .getProduct(
            merchantId: membership.merchantId,
            productId: widget.productId!,
          );
      final branchId =
          access.selectedBranch?.id ??
          (product.branchId.isNotEmpty ? product.branchId : null);
      Uint8List? remoteBytes;
      var remoteFailed = false;
      final expectRemote = product.hasImage;
      if (expectRemote) {
        if (branchId == null || branchId.isEmpty) {
          remoteFailed = true;
        } else {
          try {
            remoteBytes = await ref
                .read(merchantApiProvider)
                .fetchProductImageBytes(
                  merchantId: membership.merchantId,
                  branchId: branchId,
                  productId: product.id,
                );
            if (remoteBytes == null || remoteBytes.isEmpty) {
              remoteFailed = true;
            }
          } catch (_) {
            remoteFailed = true;
          }
        }
      }
      if (!mounted) return;
      setState(() {
        _name.text = product.name;
        _description.text = product.description ?? '';
        _price.text = MoneyFormat.minorToMajorInput(product.priceMinor);
        _categoryId = product.categoryId;
        _available = product.available;
        _updatedAt = product.updatedAt;
        _productBranchId = product.branchId;
        _sellingUnit = product.sellingUnit;
        _expectRemoteImage = expectRemote;
        _remoteImageFailed = remoteFailed;
        if (remoteBytes != null && remoteBytes.isNotEmpty) {
          _localImageBytes = remoteBytes;
          _localImageName = 'product.png';
          _localImageType = 'image/png';
          _remoteImageFailed = false;
        }
        _loading = false;
      });
      _loadGroups();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = AppStrings.catalogLoadError;
        _loading = false;
      });
    }
  }

  Future<void> _loadGroups() async {
    final membership = ref.read(accessControllerProvider).membership;
    if (membership == null || widget.isCreate) return;
    try {
      final groups = await ref
          .read(merchantApiProvider)
          .listOptionGroups(
            merchantId: membership.merchantId,
            productId: widget.productId!,
          );
      if (mounted) setState(() => _groups = groups);
    } catch (_) {
      if (mounted) setState(() => _groups = null);
    }
  }

  Future<void> _openGroups(bool required) async {
    final id = widget.productId!;
    await context.push(
      required
          ? AppRoutes.catalogProductVariants(id)
          : AppRoutes.catalogProductExtras(id),
    );
    await _loadGroups();
  }

  Future<void> _openSellingUnit() async {
    final chosen = await Navigator.of(context).push<SellingUnitSelection>(
      MaterialPageRoute(
        builder: (_) => SellingUnitScreen(
          initial: _sellingUnit,
          priceMinor: MoneyFormat.majorInputToMinor(_price.text),
          readOnly: !_canManage,
        ),
      ),
    );
    if (chosen == null || !mounted) return;
    setState(() {
      _sellingUnit = chosen;
      _sellingUnitTouched = true;
    });
  }

  String? get _updatedLabel {
    final at = _updatedAt;
    if (at == null) return null;
    final local = at.toUtc().add(kMerchantBranchUtcOffset);
    String two(int v) => v.toString().padLeft(2, '0');
    return '${AppStrings.catalogLastUpdated} : ${two(local.day)}/'
        '${two(local.month)}/${local.year} à ${two(local.hour)}:'
        '${two(local.minute)}';
  }

  bool get _canManage {
    final role = ref.read(accessControllerProvider).membership?.role ?? '';
    final upper = role.toUpperCase();
    return upper == 'OWNER' || upper == 'MANAGER';
  }

  Future<void> _pickImage() async {
    final picked = await pickMerchantImage(context);
    if (picked == null || !mounted) return;
    final result = await Navigator.of(context).push<ProductImageCropResult>(
      MaterialPageRoute(
        builder: (_) => ProductImageCropScreen(
          bytes: picked.bytes,
          productName: _name.text.trim(),
        ),
      ),
    );
    if (result == null || !mounted) return;
    final cropped = result.image;
    if (result.remove || cropped == null) {
      setState(() {
        _localImageBytes = null;
        _localImageName = null;
        _localImageType = null;
        if (!widget.isCreate && _expectRemoteImage) _removeRemoteImage = true;
      });
      return;
    }
    setState(() {
      _localImageBytes = cropped.bytes;
      _localImageName = cropped.filename;
      _localImageType = cropped.contentType;
      _removeRemoteImage = false;
      _remoteImageFailed = false;
      _imageInfo = null;
    });
  }

  Future<void> _retryRemoteImage() async {
    if (widget.isCreate || widget.productId == null) return;
    final access = ref.read(accessControllerProvider);
    final membership = access.membership;
    final branchId = _resolvedBranchId;
    if (membership == null || branchId == null) return;
    setState(() {
      _loading = true;
      _remoteImageFailed = false;
    });
    try {
      final bytes = await ref
          .read(merchantApiProvider)
          .fetchProductImageBytes(
            merchantId: membership.merchantId,
            branchId: branchId,
            productId: widget.productId!,
          );
      if (!mounted) return;
      setState(() {
        if (bytes != null && bytes.isNotEmpty) {
          _localImageBytes = bytes;
          _localImageName = 'product.png';
          _localImageType = 'image/png';
          _remoteImageFailed = false;
        } else {
          _remoteImageFailed = _expectRemoteImage;
        }
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _remoteImageFailed = true;
        _loading = false;
      });
    }
  }

  @visibleForTesting
  void debugSetLocalImage({
    required Uint8List bytes,
    String name = 'product.jpg',
    String contentType = 'image/jpeg',
  }) {
    setState(() {
      _localImageBytes = bytes;
      _localImageName = name;
      _localImageType = contentType;
      _removeRemoteImage = false;
      _imageInfo = null;
    });
  }

  /// Integration-test diagnostics (remote hydrate).
  int? get debugLocalImageByteLength => _localImageBytes?.length;
  bool get debugRemoteImageFailed => _remoteImageFailed;
  bool get debugExpectRemoteImage => _expectRemoteImage;

  Future<void> _save() async {
    if (!_canManage || _saving) return;
    if (!_validateFields()) return;
    final name = _name.text.trim();
    final categoryId = _categoryId!;
    final priceMinor = MoneyFormat.majorInputToMinor(_price.text)!;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final notifier = ref.read(catalogControllerProvider.notifier);
      late CatalogProduct product;
      if (widget.isCreate) {
        product = await notifier.createProduct(
          categoryId: categoryId,
          name: name,
          description: _description.text.trim().isEmpty
              ? null
              : _description.text.trim(),
          priceMinor: priceMinor,
          available: _available,
          sellingUnit: _sellingUnit.isNone ? null : _sellingUnit,
        );
      } else {
        product = await notifier.updateProduct(
          productId: widget.productId!,
          categoryId: categoryId,
          name: name,
          description: _description.text.trim(),
          priceMinor: priceMinor,
          available: _available,
          sellingUnit: _sellingUnitTouched ? _sellingUnit : null,
        );
      }
      await _syncImage(product);
      if (!mounted) return;
      if (_error == AppStrings.catalogImageBindPartial ||
          _error == AppStrings.catalogImageUploadError) {
        setState(() => _saving = false);
        return;
      }
      if (_imageInfo != null) {
        setState(() => _saving = false);
        return;
      }
      context.pop(true);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = AppStrings.catalogSaveRetryHint;
      });
    }
  }

  bool _validateFields() {
    final name = _name.text.trim();
    final categoryId = _categoryId;
    final priceMinor = MoneyFormat.majorInputToMinor(_price.text);
    String? nameError;
    String? priceError;
    String? categoryError;
    if (name.isEmpty) {
      nameError = AppStrings.catalogFieldRequired;
    }
    if (categoryId == null || categoryId.isEmpty) {
      categoryError = AppStrings.catalogCategoryRequired;
    }
    if (priceMinor == null) {
      priceError = AppStrings.catalogPriceInvalid;
    }
    setState(() {
      _nameError = nameError;
      _priceError = priceError;
      _categoryError = categoryError;
      _error = null;
    });
    if (nameError == null && priceError == null && categoryError == null) {
      return true;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (nameError != null) {
        _scrollTo(_nameFieldKey);
        _nameFocus.requestFocus();
      } else if (categoryError != null) {
        _scrollTo(_categoryFieldKey);
      } else if (priceError != null) {
        _scrollTo(_priceFieldKey);
        _priceFocus.requestFocus();
      }
    });
    return false;
  }

  void _scrollTo(GlobalKey key) {
    final ctx = key.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 280),
      alignment: 0.15,
      curve: Curves.easeOut,
    );
  }

  void _showLocalPreview(List<CatalogCategory> categories) {
    final categoryName = categories
        .where((c) => c.id == _categoryId)
        .map((c) => c.name)
        .firstOrNull;
    final priceMinor = MoneyFormat.majorInputToMinor(_price.text);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  AppStrings.catalogPreviewTitle,
                  key: const Key('product-preview-sheet'),
                  style: Theme.of(ctx).textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 16),
                if (_localImageBytes != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.memory(
                      key: const Key('product-preview-image'),
                      _localImageBytes!,
                      height: 140,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                Text(
                  key: const Key('product-preview-name'),
                  _name.text.trim().isEmpty ? '—' : _name.text.trim(),
                  style: Theme.of(ctx).textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                if (_description.text.trim().isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    key: const Key('product-preview-description'),
                    _description.text.trim(),
                  ),
                ],
                const SizedBox(height: 10),
                Text(
                  categoryName == null || categoryName.isEmpty
                      ? AppStrings.catalogCategoryRequired
                      : categoryName,
                  style: Theme.of(ctx).textTheme.bodyMedium
                      ?.copyWith(color: AppColors.onSurfaceVariant),
                ),
                const SizedBox(height: 6),
                Text(
                  key: const Key('product-preview-price'),
                  priceMinor == null
                      ? AppStrings.catalogPriceInvalid
                      : MoneyFormat.dzd(priceMinor.toString()),
                  style: Theme.of(ctx).textTheme.titleMedium,
                ),
                const SizedBox(height: 6),
                Text(
                  _available
                      ? AppStrings.catalogProductAvailable
                      : AppStrings.catalogOutOfStockNow,
                ),
                const SizedBox(height: 20),
                FilledButton(
                  key: const Key('product-preview-close'),
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Fermer'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _syncImage(CatalogProduct product) async {
    final access = ref.read(accessControllerProvider);
    final membership = access.membership;
    final branchId =
        access.selectedBranch?.id ??
        (product.branchId.isNotEmpty ? product.branchId : _productBranchId);
    if (membership == null || branchId == null || branchId.isEmpty) {
      if (_localImageBytes != null || _removeRemoteImage) {
        if (mounted) {
          setState(() => _error = AppStrings.catalogImageUploadError);
        }
      }
      return;
    }
    final api = ref.read(merchantApiProvider);
    if (_removeRemoteImage && !widget.isCreate) {
      try {
        await api.deleteProductImage(
          merchantId: membership.merchantId,
          branchId: branchId,
          productId: product.id,
        );
        bumpMerchantMediaEpoch(ref);
        if (mounted) {
          setState(() {
            _imageInfo = null;
            _expectRemoteImage = false;
          });
        }
      } catch (_) {
        if (mounted) {
          setState(() => _error = AppStrings.catalogImageBindPartial);
        }
        return;
      }
    }
    final bytes = _localImageBytes;
    if (bytes == null || bytes.isEmpty) return;
    setState(() => _uploadingImage = true);
    String? uploadReference;
    try {
      final uploaded = await api.uploadProductImageContent(
        merchantId: membership.merchantId,
        branchId: branchId,
        productId: product.id,
        filename: _localImageName ?? 'product.png',
        contentType: _localImageType ?? 'image/png',
        bytes: bytes,
      );
      uploadReference = uploaded.uploadReference;
    } catch (e) {
      if (mounted) {
        setState(() {
          _uploadingImage = false;
          _error = e is AppException
              ? e.message
              : AppStrings.catalogImageUploadError;
        });
      }
      return;
    }
    try {
      await api.bindProductImage(
        merchantId: membership.merchantId,
        branchId: branchId,
        productId: product.id,
        uploadReference: uploadReference,
      );
      bumpMerchantMediaEpoch(ref);
      if (mounted) {
        setState(() {
          _error = null;
          _imageInfo = null;
          _uploadingImage = false;
          _expectRemoteImage = true;
          _remoteImageFailed = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = AppStrings.catalogImageBindPartial;
          _uploadingImage = false;
        });
      }
    }
  }

  Future<void> _delete() async {
    if (!_canManage || widget.isCreate) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppStrings.catalogDeleteProduct),
        content: Text(AppStrings.catalogDeleteConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(AppStrings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(AppStrings.catalogDeleteProduct),
          ),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _saving = true);
    try {
      await ref
          .read(catalogControllerProvider.notifier)
          .deleteProduct(widget.productId!);
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

  InputDecoration _fieldDecoration({String? suffix, String? errorText}) {
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
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error, width: 2),
      ),
      suffixText: suffix,
      errorText: errorText,
    );
  }

  @override
  Widget build(BuildContext context) {
    final catalog = ref.watch(catalogControllerProvider).value;
    final categories = catalog?.categories ?? const <CatalogCategory>[];
    final canManage = _canManage;
    final isCreate = widget.isCreate;

    return MerchantScaffold(
      title: isCreate
          ? AppStrings.catalogAddProduct
          : AppStrings.catalogEditProduct,
      subtitle: isCreate ? null : _updatedLabel,
      centerTitle: isCreate,
      headerColor: AppColors.surface,
      titleStyle: Theme.of(context).textTheme.titleLarge
          ?.copyWith(fontWeight: FontWeight.w700, color: AppColors.primary),
      body: _loading
          ? const LoadingBody()
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    key: const Key('product-editor-screen'),
                    padding: const EdgeInsets.only(top: 8, bottom: 96),
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
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
                        if (_error != null) ...[
                          Text(
                            key: const Key('product-editor-error'),
                            _error!,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: AppColors.error),
                          ),
                          const SizedBox(height: 12),
                        ],
                        if (!isCreate) ...[
                          _StatusBanner(online: _available),
                          const SizedBox(height: 12),
                          _AvailabilityCard(
                            available: _available,
                            onChanged: canManage && !_saving
                                ? (v) => setState(() => _available = v)
                                : null,
                          ),
                          const SizedBox(height: 12),
                          MerchantEditorSection(
                            title: AppStrings.catalogSectionImage,
                            icon: Icons.image_outlined,
                            children: [
                              _ProductImageBlock(
                                bytes: _localImageBytes,
                                isCreate: false,
                                canManage: canManage,
                                remoteFailed:
                                    _remoteImageFailed &&
                                    _localImageBytes == null,
                                onRetryRemote: _retryRemoteImage,
                                onPick: canManage ? _pickImage : null,
                                onClearLocal:
                                    canManage && _localImageBytes != null
                                    ? () => setState(() {
                                        _localImageBytes = null;
                                        _localImageName = null;
                                        _localImageType = null;
                                      })
                                    : null,
                                onMarkRemoveRemote: canManage
                                    ? () => setState(() {
                                        _removeRemoteImage = true;
                                        _localImageBytes = null;
                                      })
                                    : null,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                        ],
                        MerchantEditorSection(
                          title: isCreate
                              ? AppStrings.catalogSectionInfo
                              : AppStrings.catalogSectionGeneral,
                          icon: Icons.info_outline,
                          children: [
                            KeyedSubtree(
                              key: _nameFieldKey,
                              child: MerchantLabeledField(
                                label: AppStrings.catalogProductName,
                                requiredMark: true,
                                child: TextField(
                                  key: const Key('product-editor-name'),
                                  focusNode: _nameFocus,
                                  controller: _name,
                                  enabled: canManage && !_saving,
                                  textInputAction: TextInputAction.next,
                                  onChanged: (_) {
                                    if (_nameError != null) {
                                      setState(() => _nameError = null);
                                    }
                                  },
                                  decoration: _fieldDecoration(
                                    errorText: _nameError,
                                  ),
                                ),
                              ),
                            ),
                            MerchantContractGapRow(
                              label: AppStrings.catalogFieldNameAr,
                            ),
                            MerchantLabeledField(
                              label: AppStrings.catalogProductDescription,
                              child: TextField(
                                key: const Key('product-editor-description'),
                                controller: _description,
                                enabled: canManage && !_saving,
                                maxLines: 3,
                                decoration: _fieldDecoration(),
                              ),
                            ),
                            MerchantContractGapRow(
                              label: AppStrings.catalogFieldDescAr,
                            ),
                            if (isCreate)
                              KeyedSubtree(
                                key: _categoryFieldKey,
                                child: MerchantLabeledField(
                                  label: AppStrings.catalogProductCategory,
                                  requiredMark: true,
                                  child: DropdownButtonFormField<String>(
                                    key: const Key('product-editor-category'),
                                    // ignore: deprecated_member_use
                                    value:
                                        categories.any(
                                          (c) => c.id == _categoryId,
                                        )
                                        ? _categoryId
                                        : null,
                                    decoration: _fieldDecoration(
                                      errorText: _categoryError,
                                    ),
                                    items: [
                                      for (final c in categories)
                                        DropdownMenuItem(
                                          value: c.id,
                                          child: Text(c.name),
                                        ),
                                    ],
                                    onChanged: canManage && !_saving
                                        ? (v) => setState(() {
                                            _categoryId = v;
                                            _categoryError = null;
                                          })
                                        : null,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        if (isCreate) ...[
                          const SizedBox(height: 12),
                          MerchantEditorSection(
                            title: AppStrings.catalogSectionMedia,
                            icon: Icons.image_outlined,
                            children: [
                              _ProductImageBlock(
                                bytes: _localImageBytes,
                                isCreate: true,
                                canManage: canManage,
                                onPick: canManage ? _pickImage : null,
                                onClearLocal:
                                    canManage && _localImageBytes != null
                                    ? () => setState(() {
                                        _localImageBytes = null;
                                        _localImageName = null;
                                        _localImageType = null;
                                      })
                                    : null,
                                onMarkRemoveRemote: null,
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 12),
                        MerchantEditorSection(
                          title: isCreate
                              ? AppStrings.catalogSectionPrice
                              : AppStrings.catalogSectionPriceDetails,
                          icon: Icons.payments_outlined,
                          children: [
                            if (!isCreate)
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.errorContainer.withValues(
                                    alpha: 0.45,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(
                                      Icons.warning_rounded,
                                      size: 20,
                                      color: AppColors.error,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        AppStrings.catalogPriceWarning,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: AppColors.onErrorContainer,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            KeyedSubtree(
                              key: _priceFieldKey,
                              child: MerchantLabeledField(
                                label: AppStrings.catalogProductPrice,
                                requiredMark: true,
                                child: TextField(
                                  key: const Key('product-editor-price'),
                                  focusNode: _priceFocus,
                                  controller: _price,
                                  enabled: canManage && !_saving,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                  onChanged: (_) {
                                    if (_priceError != null) {
                                      setState(() => _priceError = null);
                                    }
                                  },
                                  decoration: _fieldDecoration(
                                    suffix: AppStrings.catalogCurrencySuffix,
                                    errorText: _priceError,
                                  ),
                                ),
                              ),
                            ),
                            MerchantContractGapRow(
                              label: AppStrings.catalogFieldPrepTime,
                            ),
                            _ConfigRow(
                              key: const Key('product-editor-selling-unit'),
                              label: AppStrings.catalogFieldSaleUnit,
                              detail:
                                  _sellingUnit.displayLabel ??
                                  AppStrings.sellingUnitNotSet,
                              onTap: _openSellingUnit,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        MerchantEditorSection(
                          key: const Key('product-editor-config-section'),
                          title: AppStrings.catalogSectionConfig,
                          icon: Icons.settings_outlined,
                          children: [
                            if (isCreate)
                              Text(
                                AppStrings.catalogSaveFirstForOptions,
                                key: const Key('product-editor-options-hint'),
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: AppColors.onSurfaceVariant,
                                    ),
                              )
                            else ...[
                              _ConfigRow(
                                key: const Key('product-editor-variants'),
                                label: AppStrings.catalogFieldVariants,
                                detail: _groups == null
                                    ? null
                                    : AppStrings.catalogGroupsCount(_groups!
                                            .where((g) => g.required)
                                            .length,
                                      ),
                                onTap: () => _openGroups(true),
                              ),
                              _ConfigRow(
                                key: const Key('product-editor-extras'),
                                label: AppStrings.catalogFieldExtras,
                                detail: _groups == null
                                    ? null
                                    : AppStrings.catalogGroupsCount(_groups!
                                            .where((g) => !g.required)
                                            .length,
                                      ),
                                onTap: () => _openGroups(false),
                              ),
                            ],
                            if (isCreate)
                              SwitchListTile(
                                key: const Key('product-editor-available'),
                                contentPadding: EdgeInsets.zero,
                                title: Text(
                                  AppStrings.catalogProductAvailable,
                                ),
                                subtitle: Text(
                                  AppStrings.catalogProductAvailableSub,
                                ),
                                value: _available,
                                onChanged: canManage && !_saving
                                    ? (v) => setState(() => _available = v)
                                    : null,
                              ),
                            if (!isCreate && canManage)
                              OutlinedButton(
                                key: const Key('product-editor-delete'),
                                onPressed: _saving ? null : _delete,
                                child: Text(
                                  AppStrings.catalogDeleteProduct,
                                ),
                              ),
                          ],
                        ),
                        if (_imageInfo != null && _error == null) ...[
                          const SizedBox(height: 12),
                          Text(
                            key: const Key('product-editor-image-info'),
                            _imageInfo!,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: AppColors.onSurfaceVariant),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                if (canManage)
                  MerchantDualStickyBar(
                    secondary: OutlinedButton(
                      key: const Key('product-editor-preview'),
                      onPressed: (_saving || _uploadingImage)
                          ? null
                          : () => _showLocalPreview(categories),
                      child: Text(
                        AppStrings.catalogPreview,
                        maxLines: 1,
                        softWrap: false,
                      ),
                    ),
                    primary: FilledButton.icon(
                      key: const Key('product-editor-save'),
                      onPressed: (_saving || _uploadingImage) ? null : _save,
                      icon: const Icon(Icons.save_outlined, size: 18),
                      label: Text(
                        _saving || _uploadingImage
                            ? AppStrings.loading
                            : (isCreate
                                  ? AppStrings.catalogSaveProduct
                                  : AppStrings.catalogSaveProductEdits),
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

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.online});

  final bool online;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: online ? AppColors.primaryContainer : AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: online ? AppColors.onPrimaryContainer : AppColors.primary,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              online
                  ? AppStrings.catalogOnlineBanner
                  : AppStrings.catalogOfflineBanner,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: online
                    ? AppColors.onPrimaryContainer
                    : AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AvailabilityCard extends StatelessWidget {
  const _AvailabilityCard({required this.available, required this.onChanged});

  final bool available;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return MerchantCard(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      child: Row(
        children: [
          Icon(
            available ? Icons.check_circle : Icons.cancel_outlined,
            color: available ? AppColors.tertiaryContainer : AppColors.outline,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.catalogSectionAvailability,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  available
                      ? AppStrings.catalogInStockNow
                      : AppStrings.catalogOutOfStockNow,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          CatalogSwitch(
            key: const Key('product-editor-available'),
            value: available,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _ConfigRow extends StatelessWidget {
  const _ConfigRow({
    super.key,
    required this.label,
    required this.onTap,
    this.detail,
  });

  final String label;
  final String? detail;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: theme.textTheme.bodyLarge),
                  if (detail != null)
                    Text(
                      detail!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

class _ProductImageBlock extends StatelessWidget {
  const _ProductImageBlock({
    required this.bytes,
    required this.isCreate,
    required this.canManage,
    this.remoteFailed = false,
    this.onRetryRemote,
    this.onPick,
    this.onClearLocal,
    this.onMarkRemoveRemote,
  });

  final Uint8List? bytes;
  final bool isCreate;
  final bool canManage;
  final bool remoteFailed;
  final VoidCallback? onRetryRemote;
  final VoidCallback? onPick;
  final VoidCallback? onClearLocal;
  final VoidCallback? onMarkRemoveRemote;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (remoteFailed && bytes == null) ...[
          Container(
            key: const Key('product-editor-remote-error'),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(
                  AppStrings.catalogImageRemoteUnavailable,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                if (onRetryRemote != null) ...[
                  const SizedBox(height: 8),
                  TextButton.icon(
                    key: const Key('product-editor-remote-retry'),
                    onPressed: onRetryRemote,
                    icon: const Icon(Icons.refresh),
                    label: Text(AppStrings.retry),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
        if (isCreate && bytes == null && onPick != null)
          InkWell(
            key: const Key('product-editor-pick-image'),
            onTap: onPick,
            borderRadius: BorderRadius.circular(12),
            child: CustomPaint(
              painter: _DashedBorderPainter(
                color: AppColors.primaryContainer.withValues(alpha: 0.55),
              ),
              child: SizedBox(
                height: 120,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_a_photo_outlined,
                      color: AppColors.primaryContainer,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppStrings.catalogImageAdd,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: AppColors.primaryContainer,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      AppStrings.catalogImageHint,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        if (bytes != null) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: AspectRatio(
              aspectRatio: 4 / 3,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.memory(
                    bytes!,
                    key: Key('product-editor-image-${bytes!.length}'),
                    fit: BoxFit.cover,
                    gaplessPlayback: true,
                    errorBuilder: (_, _, _) => const ColoredBox(
                      color: AppColors.surfaceContainerLow,
                      child: Center(
                        child: Icon(
                          Icons.broken_image_outlined,
                          size: 40,
                          color: AppColors.outline,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 8,
                    bottom: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        AppStrings.catalogImagePrimary,
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  if (onClearLocal != null || onMarkRemoveRemote != null)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Material(
                        color: AppColors.error,
                        shape: const CircleBorder(),
                        child: IconButton(
                          key: const Key('product-editor-clear-image'),
                          icon: const Icon(Icons.delete_outline, size: 18),
                          color: Colors.white,
                          onPressed: onClearLocal ?? onMarkRemoveRemote,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ] else if (!isCreate)
          AspectRatio(
            aspectRatio: 4 / 3,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Icon(
                  Icons.image_outlined,
                  size: 40,
                  color: AppColors.outline,
                ),
              ),
            ),
          ),
        if (!isCreate) ...[
          const SizedBox(height: 8),
          Text(
            AppStrings.catalogImageHint,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
          if (canManage && onPick != null) ...[
            const SizedBox(height: 8),
            OutlinedButton.icon(
              key: const Key('product-editor-pick-image'),
              onPressed: onPick,
              icon: const Icon(Icons.add_photo_alternate_outlined),
              label: Text(AppStrings.catalogImageChangePhoto),
            ),
          ],
        ],
      ],
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  _DashedBorderPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    const dash = 6.0;
    const gap = 4.0;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(12)),
      );
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = distance + dash;
        canvas.drawPath(
          metric.extractPath(distance, next.clamp(0, metric.length)),
          paint,
        );
        distance = next + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color;
}
