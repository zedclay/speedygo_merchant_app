import 'package:flutter/material.dart';
import 'package:speedygo_merchant_app/app/theme/app_theme.dart';
import 'package:speedygo_merchant_app/core/constants/app_strings.dart';
import 'package:speedygo_merchant_app/core/errors/app_exception.dart';

/// Colour set of [CatalogSwitch]; each follows its own Stitch reference.
enum CatalogSwitchTone {
  /// Product list and editors: lime track, primary check thumb.
  lime,

  /// Category detail (`d_tails_de_la_cat_gorie_standardis`): `#516400`
  /// track, as rendered in its PNG, with the same primary check thumb.
  olive,
}

/// Reference toggle: coloured track when on (see [CatalogSwitchTone]), pale
/// track with a white thumb when off.
class CatalogSwitch extends StatelessWidget {
  const CatalogSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.semanticLabel,
    this.tone = CatalogSwitchTone.lime,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;
  final String? semanticLabel;
  final CatalogSwitchTone tone;

  @override
  Widget build(BuildContext context) {
    final sw = Switch(
      value: value,
      onChanged: onChanged,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      trackOutlineColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected)
            ? Colors.transparent
            : AppColors.outlineVariant,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected)
            ? (tone == CatalogSwitchTone.olive
                  ? AppColors.tertiaryContainer
                  : AppColors.tertiaryFixed)
            : AppColors.surfaceContainer,
      ),
      thumbColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected)
            ? AppColors.primaryContainer
            : AppColors.surface,
      ),
      thumbIcon: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected)
            ? const Icon(Icons.check, size: 16, color: AppColors.onPrimary)
            : null,
      ),
    );
    return Semantics(
      label: semanticLabel,
      child: Transform.scale(scale: 0.85, child: sw),
    );
  }
}

/// Full-pill filter chip without a check mark.
class CatalogPillChip extends StatelessWidget {
  const CatalogPillChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    this.selectedColor = AppColors.primaryContainer,
    this.selectedForeground = AppColors.onPrimary,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;
  final Color selectedColor;
  final Color selectedForeground;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? selectedForeground : AppColors.onSurface;
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? selectedColor : AppColors.surface,
        shape: StadiumBorder(
          side: BorderSide(
            color: selected ? Colors.transparent : AppColors.outlineVariant,
          ),
        ),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 40),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 18, color: fg),
                    const SizedBox(width: 6),
                  ],
                  Flexible(
                    child: Text(
                      label,
                      style: Theme.of(context).textTheme.labelLarge
                          ?.copyWith(color: fg, fontWeight: FontWeight.w600),
                    ),
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

/// 48 px search field with the reference outline.
class CatalogSearchField extends StatelessWidget {
  const CatalogSearchField({
    super.key,
    required this.controller,
    required this.hint,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: AppColors.outlineVariant),
    );
    return TextField(
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.outline),
        prefixIcon: const Icon(Icons.search, color: AppColors.outline),
        filled: true,
        fillColor: AppColors.surface,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        border: border,
        enabledBorder: border,
        focusedBorder: border.copyWith(
          borderSide: const BorderSide(color: AppColors.primary),
        ),
      ),
    );
  }
}

/// Square 48 px outlined icon button (filter trigger), with an optional dot.
class CatalogSquareButton extends StatelessWidget {
  const CatalogSquareButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.badge = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final bool badge;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: AppColors.outlineVariant),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onPressed,
          child: SizedBox(
            width: 48,
            height: 48,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(icon, color: AppColors.onSurface),
                if (badge)
                  const Positioned(
                    top: 10,
                    right: 10,
                    child: CircleAvatar(
                      radius: 4,
                      backgroundColor: AppColors.primary,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// "En stock" / "Rupture" pill with icon (category detail, filters preview).
class CatalogStockPill extends StatelessWidget {
  const CatalogStockPill({super.key, required this.available});

  final bool available;

  @override
  Widget build(BuildContext context) {
    final bg = available
        ? AppColors.tertiaryFixed.withValues(alpha: 0.35)
        : AppColors.errorContainer;
    final fg = available ? AppColors.tertiaryContainer : AppColors.error;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: fg.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            available ? Icons.check_circle_outline : Icons.highlight_off,
            size: 14,
            color: fg,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              available
                  ? AppStrings.catalogInStock
                  : AppStrings.catalogOutOfStock,
              style: Theme.of(context).textTheme.labelMedium
                  ?.copyWith(color: fg, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

/// "Visible" / "Masqué" tag with an eye icon.
class CatalogVisibilityTag extends StatelessWidget {
  const CatalogVisibilityTag({super.key, required this.visible});

  final bool visible;

  @override
  Widget build(BuildContext context) {
    final fg = visible ? AppColors.onTertiaryFixed : AppColors.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: visible ? AppColors.tertiaryFixed : AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: visible
              ? AppColors.tertiaryContainer.withValues(alpha: 0.3)
              : AppColors.outlineVariant,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            visible ? Icons.visibility : Icons.visibility_off_outlined,
            size: 14,
            color: fg,
          ),
          const SizedBox(width: 4),
          Text(
            visible ? AppStrings.catalogVisible : AppStrings.catalogHidden,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(color: fg),
          ),
        ],
      ),
    );
  }
}

/// Maps catalogue write failures to user copy.
String catalogErrorMessage(Object error) {
  if (error is ApiException) {
    switch (error.code) {
      case 'CATALOG_CATEGORY_IN_USE':
        return AppStrings.catalogCategoryInUse;
      case 'CATALOG_PRODUCT_IN_USE':
        return AppStrings.catalogProductInUse;
      case 'MERCHANT_ROLE_FORBIDDEN':
        return AppStrings.catalogStaffReadOnly;
    }
  }
  return AppStrings.catalogSaveError;
}

/// Inline error line for catalogue sub-screens.
class CatalogErrorBanner extends StatelessWidget {
  const CatalogErrorBanner({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, color: AppColors.onErrorContainer),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: AppColors.onErrorContainer),
            ),
          ),
        ],
      ),
    );
  }
}
