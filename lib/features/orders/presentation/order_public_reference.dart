import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:speedygo_merchant_app/app/theme/app_theme.dart';
import 'package:speedygo_merchant_app/core/constants/app_strings.dart';

/// Secondary display of the canonical [publicReference] with ellipsis and
/// an accessible path to view/copy the full original value (never rewritten).
class OrderPublicReferenceLine extends StatelessWidget {
  const OrderPublicReferenceLine({
    super.key,
    required this.reference,
    this.textKey,
    this.maxLines = 1,
    this.emphasized = false,
    this.color,
    this.label,
    this.prefix,
    this.textStyle,
    this.iconSize = 16,
    this.openKey = const Key('order-ref-open'),
  });

  final String reference;
  final Key? textKey;
  final int maxLines;

  /// Reference card style: 12 px bold primary.
  final bool emphasized;

  /// Overrides the text/icon colour (e.g. on a primary identity block).
  final Color? color;

  /// Title of the full-reference sheet and accessible label.
  final String? label;

  /// Shown before the compact reference (e.g. "Référence : ").
  final String? prefix;

  /// Replaces the default text style (colour still follows [color]).
  final TextStyle? textStyle;

  final double iconSize;
  final Key openKey;

  Future<void> _openFull(BuildContext context) async {
    final resolvedLabel = label ?? AppStrings.orderReferenceLabel;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  resolvedLabel,
                  style: Theme.of(ctx).textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                SelectableText(
                  reference,
                  key: const Key('order-ref-full-text'),
                  style: Theme.of(ctx).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  key: const Key('order-ref-copy'),
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: reference));
                    if (ctx.mounted) {
                      Navigator.of(ctx).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(AppStrings.orderReferenceCopied),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.copy_outlined, size: 18),
                  label: Text(AppStrings.orderReferenceCopy),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final display = '${prefix ?? ''}${_compactReference(reference)}';
    final baseStyle =
        textStyle ??
        theme.textTheme.bodySmall?.copyWith(
          fontWeight: emphasized ? FontWeight.w700 : FontWeight.w500,
          fontSize: 12,
        );
    final resolvedLabel = label ?? AppStrings.orderReferenceLabel;
    return Semantics(
      button: true,
      label: '$resolvedLabel: $reference. ${AppStrings.orderReferenceShowFull}',
      child: InkWell(
        key: openKey,
        onTap: () => _openFull(context),
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  display,
                  key: textKey,
                  maxLines: maxLines,
                  overflow: TextOverflow.ellipsis,
                  style: baseStyle?.copyWith(
                    color:
                        color ??
                        textStyle?.color ??
                        (emphasized
                            ? AppColors.primary
                            : AppColors.onSurfaceVariant),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.copy_outlined,
                size: iconSize,
                color:
                    color ?? AppColors.onSurfaceVariant.withValues(alpha: 0.85),
                semanticLabel: AppStrings.orderReferenceCopy,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Compact secondary display of a long public reference; original unchanged.
String _compactReference(String reference) {
  final t = reference.trim();
  if (t.length <= 22) return t;
  return '${t.substring(0, 10)}…${t.substring(t.length - 6)}';
}
