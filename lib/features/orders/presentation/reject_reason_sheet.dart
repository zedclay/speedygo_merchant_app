import 'package:flutter/material.dart';
import 'package:speedygo_merchant_app/app/theme/app_theme.dart';
import 'package:speedygo_merchant_app/core/constants/app_strings.dart';
import 'package:speedygo_merchant_app/core/widgets/merchant_primary_button.dart';
import 'package:speedygo_merchant_app/features/orders/data/order_models.dart';

typedef RejectReasonResult = ({String reason, String? reasonCode});

/// Default free-text details when a structured tile is selected.
String rejectReasonDefaultDetails(MerchantRejectReasonCode code) {
  switch (code) {
    case MerchantRejectReasonCode.productUnavailable:
      return AppStrings.rejectReasonProductUnavailable;
    case MerchantRejectReasonCode.tooBusy:
      return AppStrings.rejectReasonTooBusy;
    case MerchantRejectReasonCode.closingSoon:
      return AppStrings.rejectReasonClosingSoon;
    case MerchantRejectReasonCode.other:
      return '';
  }
}

/// Rejection reason sheet shared by the order detail and the list card.
Future<RejectReasonResult?> showRejectReasonSheet(
  BuildContext context, {
  required TextEditingController controller,
  MerchantRejectReasonCode? initialCode,
}) {
  return showModalBottomSheet<RejectReasonResult>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => _RejectReasonSheet(
      controller: controller,
      initialCode: initialCode,
    ),
  );
}

class _RejectReasonSheet extends StatefulWidget {
  const _RejectReasonSheet({
    required this.controller,
    this.initialCode,
  });

  final TextEditingController controller;
  final MerchantRejectReasonCode? initialCode;

  @override
  State<_RejectReasonSheet> createState() => _RejectReasonSheetState();
}

class _RejectReasonSheetState extends State<_RejectReasonSheet> {
  MerchantRejectReasonCode? _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialCode ?? _codeFromText(widget.controller.text);
  }

  MerchantRejectReasonCode? _codeFromText(String text) {
    final trimmed = text.trim();
    for (final code in MerchantRejectReasonCode.values) {
      if (trimmed == rejectReasonDefaultDetails(code)) return code;
    }
    if (trimmed.isEmpty) return null;
    return MerchantRejectReasonCode.other;
  }

  void _pickCode(MerchantRejectReasonCode? code) {
    setState(() {
      _selected = code;
      if (code == null || code == MerchantRejectReasonCode.other) {
        if (code == MerchantRejectReasonCode.other) {
          widget.controller.clear();
        }
      } else {
        widget.controller.text = rejectReasonDefaultDetails(code);
      }
    });
  }

  void _confirm() {
    final text = widget.controller.text.trim();
    if (text.isEmpty) return;
    final code = _selected == MerchantRejectReasonCode.other ? 'OTHER' : _selected?.apiValue;
    Navigator.of(context).pop((reason: text, reasonCode: code));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            AppStrings.orderRejectTitle,
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            AppStrings.rejectReasonTilesHint,
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          _RejectReasonTiles(
            selected: _selected,
            onPick: _pickCode,
          ),
          const SizedBox(height: 12),
          TextField(
            key: const Key('order-reject-reason'),
            controller: widget.controller,
            maxLength: 255,
            maxLines: 3,
            onChanged: (_) => setState(() {
              if (_selected != MerchantRejectReasonCode.other) {
                _selected = _codeFromText(widget.controller.text);
              }
            }),
            decoration: const InputDecoration(
              labelText: AppStrings.orderRejectReasonLabel,
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          MerchantPrimaryButton(
            key: const Key('order-reject-confirm'),
            label: AppStrings.orderRejectConfirm,
            onPressed: _confirm,
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(AppStrings.back),
          ),
        ],
      ),
    );
  }
}

class _RejectReasonTiles extends StatelessWidget {
  const _RejectReasonTiles({required this.selected, required this.onPick});

  final MerchantRejectReasonCode? selected;
  final ValueChanged<MerchantRejectReasonCode?> onPick;

  @override
  Widget build(BuildContext context) {
    Widget tile({
      required Key key,
      required IconData icon,
      required String label,
      required MerchantRejectReasonCode? code,
    }) {
      final isSelected = selected == code;
      final color = isSelected ? AppColors.primary : AppColors.onSurface;
      return Semantics(
        button: true,
        selected: isSelected,
        child: Material(
          color: isSelected
              ? AppColors.primaryFixed.withValues(alpha: 0.2)
              : AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(
              color: isSelected ? AppColors.primary : AppColors.outlineVariant,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => onPick(code),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 22, color: color),
                  const SizedBox(height: 6),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: tile(
                  key: const Key('reject-reason-product-unavailable'),
                  icon: Icons.inventory_2_outlined,
                  label: AppStrings.rejectReasonProductUnavailable,
                  code: MerchantRejectReasonCode.productUnavailable,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: tile(
                  key: const Key('reject-reason-too-busy'),
                  icon: Icons.groups_outlined,
                  label: AppStrings.rejectReasonTooBusy,
                  code: MerchantRejectReasonCode.tooBusy,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: tile(
                  key: const Key('reject-reason-closing-soon'),
                  icon: Icons.schedule_outlined,
                  label: AppStrings.rejectReasonClosingSoon,
                  code: MerchantRejectReasonCode.closingSoon,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: tile(
                  key: const Key('reject-reason-other'),
                  icon: Icons.more_horiz,
                  label: AppStrings.rejectReasonOther,
                  code: MerchantRejectReasonCode.other,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
