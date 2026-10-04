import 'package:flutter/material.dart';
import 'package:speedygo_merchant_app/app/theme/app_theme.dart';

/// Merchant-local primary CTA (Customer [SgPrimaryButton] visual parity).
class MerchantPrimaryButton extends StatelessWidget {
  const MerchantPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.icon,
    this.leadingIcon = false,
    this.maxLines = 1,
  });

  final int maxLines;

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData? icon;

  /// Stitch task CTAs put the icon before the label; auth flows keep it after.
  final bool leadingIcon;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(56),
        padding: EdgeInsets.symmetric(
          horizontal: 16,
          vertical: maxLines > 1 ? 14 : 16,
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.4),
        elevation: 4,
        shadowColor: const Color(0x330A4096),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(
          fontFamily: AppTheme.latinFont,
          fontSize: 16,
          fontWeight: FontWeight.w700,
          height: 1.25,
        ),
      ),
      onPressed: loading ? null : onPressed,
      child: loading
          ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                color: AppColors.onPrimary,
              ),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null && leadingIcon) ...[
                  Icon(icon, size: 20, color: AppColors.onPrimary),
                  const SizedBox(width: 8),
                ],
                Flexible(
                  child: Text(
                    label,
                    maxLines: maxLines,
                    softWrap: true,
                    overflow: maxLines > 1
                        ? TextOverflow.visible
                        : TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: AppTheme.latinFont,
                      color: AppColors.onPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      height: 1.25,
                    ),
                  ),
                ),
                if (icon != null && !leadingIcon) ...[
                  const SizedBox(width: 8),
                  Icon(icon, size: 20, color: AppColors.onPrimary),
                ],
              ],
            ),
    );
  }
}
