import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:speedygo_merchant_app/app/theme/app_theme.dart';
import 'package:speedygo_merchant_app/core/constants/app_strings.dart';
import 'package:speedygo_merchant_app/core/errors/app_exception.dart';
import 'package:speedygo_merchant_app/core/money/money_format.dart';
import 'package:speedygo_merchant_app/core/navigation/app_routes.dart';
import 'package:speedygo_merchant_app/core/utils/uuid_v4.dart';
import 'package:speedygo_merchant_app/core/widgets/merchant_ui.dart';
import 'package:speedygo_merchant_app/features/access/application/access_controller.dart';
import 'package:speedygo_merchant_app/features/auth/application/auth_infrastructure.dart';
import 'package:speedygo_merchant_app/features/catalog/application/catalog_controller.dart';
import 'package:speedygo_merchant_app/features/catalog/data/catalog_models.dart';
import 'package:speedygo_merchant_app/features/catalog/presentation/catalog_screen.dart';
import 'package:speedygo_merchant_app/features/catalog/presentation/merchant_product_thumb.dart';

/// Mirrors backend `CATALOG_NAME_MAX_LENGTH`.
const _nameMax = 255;

class ProductDuplicateScreen extends ConsumerStatefulWidget {
  const ProductDuplicateScreen({super.key, required this.productId});

  final String productId;

  @override
  ConsumerState<ProductDuplicateScreen> createState() =>
      _ProductDuplicateScreenState();
}

class _ProductDuplicateScreenState
    extends ConsumerState<ProductDuplicateScreen> {
  /// One id per duplication attempt; retries reuse it so the server returns
  /// the same copy instead of creating another.
  final String _requestId = uuidV4();
  final _nameCtl = TextEditingController();
  var _seeded = false;
  var _running = false;
  String? _error;

  @override
  void dispose() {
    _nameCtl.dispose();
    super.dispose();
  }

  void _seedName(CatalogProduct product) {
    if (_seeded) return;
    _seeded = true;
    final name = AppStrings.duplicateDefaultName(product.name);
    _nameCtl.text = name.characters.take(_nameMax).toString();
  }

  Future<void> _create() async {
    if (_running) return;
    final name = _nameCtl.text.trim();
    if (name.isEmpty) {
      setState(() => _error = AppStrings.duplicateNameRequired);
      return;
    }
    if (name.characters.length > _nameMax) {
      setState(() => _error = AppStrings.duplicateNameTooLong);
      return;
    }
    final membership = ref.read(accessControllerProvider).membership;
    if (membership == null) return;
    setState(() {
      _running = true;
      _error = null;
    });
    final ProductDuplicateResult result;
    try {
      result = await ref
          .read(merchantApiProvider)
          .duplicateProduct(
            merchantId: membership.merchantId,
            productId: widget.productId,
            requestId: _requestId,
            name: name,
          );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _running = false;
        _error = _errorMessage(e);
      });
      return;
    }
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    await ref.read(catalogControllerProvider.notifier).reload();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          result.replayed
              ? AppStrings.duplicateReplayed
              : AppStrings.duplicateCreated,
        ),
      ),
    );
    router.pushReplacement(AppRoutes.catalogProductEdit(result.product.id));
  }

  String _errorMessage(Object e) {
    if (e is NetworkException) return AppStrings.duplicateNetworkError;
    if (e is! ApiException) return AppStrings.duplicateError;
    return switch (e.code) {
      'CATALOG_DUPLICATE_REQUEST_CONFLICT' => AppStrings.duplicateConflict,
      'CATALOG_PRODUCT_NOT_FOUND' => AppStrings.duplicateNotFound,
      'MERCHANT_ROLE_FORBIDDEN' => AppStrings.catalogStaffReadOnly,
      _ when e.statusCode == 404 => AppStrings.duplicateNotFound,
      _ when e.statusCode == 403 => AppStrings.catalogStaffReadOnly,
      _ => AppStrings.duplicateError,
    };
  }

  /// Leaves the screen; reached directly (no route below), goes to the
  /// catalogue instead.
  void _leave() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.catalog);
    }
  }

  @override
  Widget build(BuildContext context) {
    final membership = ref.watch(accessControllerProvider).membership;
    final theme = Theme.of(context);
    final titleStyle = theme.textTheme.titleLarge?.copyWith(
      color: AppColors.primary,
      fontWeight: FontWeight.w700,
    );
    if (membership == null) {
      return MerchantScaffold(
        title: AppStrings.duplicateTitle,
        centerTitle: true,
        titleStyle: titleStyle,
        body: const LoadingBody(),
      );
    }
    if (!catalogRoleCanManage(membership.role)) {
      return _ForbiddenScaffold(titleStyle: titleStyle, onLeave: _leave);
    }
    final async = ref.watch(catalogControllerProvider);
    final stacked = MediaQuery.textScalerOf(context).scale(1) >= 1.25;

    return MerchantScaffold(
      title: AppStrings.duplicateTitle,
      centerTitle: true,
      titleStyle: titleStyle,
      leading: IconButton(
        key: const Key('duplicate-close'),
        tooltip: AppStrings.duplicateCancel,
        onPressed: _running ? null : _leave,
        icon: const Icon(Icons.close, color: AppColors.onSurfaceVariant),
      ),
      bodyPadding: EdgeInsets.zero,
      body: async.when(
        loading: () => const LoadingBody(),
        error: (_, _) => ErrorBody(
          message: AppStrings.catalogLoadError,
          onRetry: () => ref.read(catalogControllerProvider.notifier).reload(),
        ),
        data: (state) {
          CatalogProduct? product;
          for (final p in state.products) {
            if (p.id == widget.productId) product = p;
          }
          if (product == null) {
            return const Center(
              key: Key('duplicate-not-found'),
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  AppStrings.duplicateNotFound,
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          _seedName(product);
          String? categoryName;
          for (final c in state.categories) {
            if (c.id == product.categoryId) categoryName = c.name;
          }
          return Column(
            key: const Key('duplicate-screen'),
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
                  children: [
                    _SourceCard(product: product, categoryName: categoryName),
                    const SizedBox(height: 24),
                    _NameField(
                      controller: _nameCtl,
                      enabled: !_running,
                      onChanged: () => setState(() => _error = null),
                    ),
                    const SizedBox(height: 24),
                    const Divider(
                      color: AppColors.outlineVariant,
                      indent: 48,
                      endIndent: 48,
                    ),
                    const SizedBox(height: 24),
                    _CopiedChecklist(product: product),
                    const SizedBox(height: 24),
                    const _NotCopiedBanner(),
                    const SizedBox(height: 12),
                    const _UnavailableBanner(),
                    if (_error != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        _error!,
                        key: const Key('duplicate-error'),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.error,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              MerchantStickyBar(
                child: Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 52,
                        child: OutlinedButton(
                          key: const Key('duplicate-cancel'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: const BorderSide(color: AppColors.primary),
                            shape: const StadiumBorder(),
                          ),
                          onPressed: _running ? null : _leave,
                          child: const Text(
                            AppStrings.duplicateCancel,
                            maxLines: 2,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: stacked ? 1 : 2,
                      child: SizedBox(
                        height: 52,
                        child: FilledButton.icon(
                          key: const Key('duplicate-create'),
                          style: FilledButton.styleFrom(
                            shape: const StadiumBorder(),
                          ),
                          onPressed: _running ? null : _create,
                          icon: _running
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.onPrimary,
                                  ),
                                )
                              : const Icon(Icons.content_copy, size: 20),
                          label: Text(
                            _running
                                ? AppStrings.duplicateCreating
                                : AppStrings.duplicateCreate,
                            maxLines: 2,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// STAFF (or any role without catalogue management) reaching the route: no
/// form, no create action, nothing read from the product. The server refuses
/// the duplicate request for these roles as well.
class _ForbiddenScaffold extends StatelessWidget {
  const _ForbiddenScaffold({required this.titleStyle, required this.onLeave});

  final TextStyle? titleStyle;
  final VoidCallback onLeave;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return MerchantScaffold(
      title: AppStrings.duplicateTitle,
      centerTitle: true,
      titleStyle: titleStyle,
      leading: IconButton(
        key: const Key('duplicate-forbidden-back'),
        tooltip: MaterialLocalizations.of(context).backButtonTooltip,
        onPressed: onLeave,
        icon: const Icon(Icons.arrow_back),
      ),
      body: Center(
        key: const Key('duplicate-forbidden'),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Center(child: MerchantIconCircle(icon: Icons.lock_outline)),
              const SizedBox(height: 20),
              Text(
                AppStrings.duplicateForbiddenTitle,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                AppStrings.catalogStaffReadOnly,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: FilledButton.icon(
                  key: const Key('duplicate-forbidden-catalog'),
                  style: FilledButton.styleFrom(
                    shape: const StadiumBorder(),
                    minimumSize: const Size(0, 48),
                  ),
                  onPressed: () => context.go(AppRoutes.catalog),
                  icon: const Icon(Icons.inventory_2_outlined, size: 20),
                  label: const Text(
                    AppStrings.duplicateBackToCatalog,
                    textAlign: TextAlign.center,
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

class _SourceCard extends StatelessWidget {
  const _SourceCard({required this.product, required this.categoryName});

  final CatalogProduct product;
  final String? categoryName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final price = MoneyFormat.dzdOrEmpty(product.priceMinor);
    return Container(
      key: const Key('duplicate-source'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outlineVariant),
        boxShadow: merchantCardShadow,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MerchantProductThumb(product: product, size: 80),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.duplicateSource.toUpperCase(),
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: AppColors.onSurfaceVariant,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  product.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  spacing: 12,
                  runSpacing: 4,
                  children: [
                    if (categoryName != null)
                      Text(
                        categoryName!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    if (price.isNotEmpty)
                      Text(
                        price,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NameField extends StatelessWidget {
  const _NameField({
    required this.controller,
    required this.enabled,
    required this.onChanged,
  });

  final TextEditingController controller;
  final bool enabled;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: AppColors.outline),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Icon(Icons.edit, size: 20, color: AppColors.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                AppStrings.duplicateNewName,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          AppStrings.duplicateNewNameHint,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: controller,
          builder: (context, value, _) => TextField(
            key: const Key('duplicate-name'),
            controller: controller,
            enabled: enabled,
            maxLength: _nameMax,
            textCapitalization: TextCapitalization.sentences,
            onChanged: (_) => onChanged(),
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.surfaceContainerLowest,
              hintText: AppStrings.duplicateNamePlaceholder,
              counterText: '',
              border: border,
              enabledBorder: border,
              suffixIcon: value.text.isEmpty
                  ? null
                  : IconButton(
                      key: const Key('duplicate-name-clear'),
                      tooltip: AppStrings.duplicateClearName,
                      onPressed: enabled
                          ? () {
                              controller.clear();
                              onChanged();
                            }
                          : null,
                      icon: const Icon(
                        Icons.cancel,
                        size: 20,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CopiedChecklist extends StatelessWidget {
  const _CopiedChecklist({required this.product});

  final CatalogProduct product;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final price = MoneyFormat.dzdOrEmpty(product.priceMinor);
    Widget row(String label, {bool copied = true, Key? key}) => Padding(
      key: key,
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(
            copied ? Icons.check_circle : Icons.remove_circle_outline,
            size: 20,
            color: copied ? AppColors.primary : AppColors.outline,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: copied
                    ? AppColors.onSurface
                    : AppColors.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          AppStrings.duplicateCopied,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          key: const Key('duplicate-checklist'),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.surfaceContainer),
          ),
          child: Column(
            children: [
              row(
                product.hasImage
                    ? AppStrings.duplicateImage
                    : AppStrings.duplicateNoImage,
                copied: product.hasImage,
                key: const Key('duplicate-copied-image'),
              ),
              row(
                AppStrings.duplicatePrice(price),
                key: const Key('duplicate-copied-price'),
              ),
              row(
                AppStrings.duplicateOptions,
                key: const Key('duplicate-copied-options'),
              ),
              row(
                AppStrings.duplicateSaleUnits,
                copied: false,
                key: const Key('duplicate-copied-units'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _NotCopiedBanner extends StatelessWidget {
  const _NotCopiedBanner();

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodyMedium
        ?.copyWith(color: AppColors.onSurface);
    return Container(
      key: const Key('duplicate-not-copied'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.errorContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.errorContainer),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: AppColors.error),
          const SizedBox(width: 12),
          Expanded(
            child: Text.rich(
              TextSpan(
                style: style,
                children: const [
                  TextSpan(text: AppStrings.duplicateNotCopiedLead),
                  TextSpan(
                    text: AppStrings.duplicateNotCopiedStrong,
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  TextSpan(text: AppStrings.duplicateNotCopiedTail),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UnavailableBanner extends StatelessWidget {
  const _UnavailableBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('duplicate-unavailable-info'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceContainer),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: AppColors.onSurfaceVariant),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              AppStrings.duplicateUnavailableInfo,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: AppColors.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}
