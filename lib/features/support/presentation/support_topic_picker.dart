import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speedygo_merchant_app/app/theme/app_theme.dart';
import 'package:speedygo_merchant_app/core/constants/app_strings.dart';
import 'package:speedygo_merchant_app/features/support/application/support_controllers.dart';

/// Client-side bound for the ticket subject line.
const supportSubjectMaxLength = 120;

/// Single-choice topic chips fed by the server topic list. Selection is a
/// topic code; the parent keeps it and requires it before sending.
class SupportTopicPicker extends ConsumerWidget {
  const SupportTopicPicker({
    super.key,
    required this.selectedCode,
    required this.onSelected,
    this.errorText,
  });

  final String? selectedCode;
  final ValueChanged<String> onSelected;
  final String? errorText;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final topics = ref.watch(supportTopicsProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${AppStrings.supportTopicLabel} *',
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        topics.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
          error: (_, _) => Row(
            children: [
              Expanded(
                child: Text(
                  AppStrings.supportTopicsLoadError,
                  key: const Key('support-topics-error'),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.error,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => ref.invalidate(supportTopicsProvider),
                child: Text(AppStrings.retry),
              ),
            ],
          ),
          data: (items) => items.isEmpty
              ? Text(
                  AppStrings.supportTopicsEmpty,
                  key: const Key('support-topics-empty'),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                )
              : Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final topic in items)
                      ChoiceChip(
                        key: Key('support-topic-choice-${topic.code}'),
                        label: Text(topic.labelFr),
                        selected: topic.code == selectedCode,
                        onSelected: (_) => onSelected(topic.code),
                      ),
                  ],
                ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 4),
          Text(
            errorText!,
            key: const Key('support-topic-required'),
            style: theme.textTheme.bodySmall?.copyWith(color: AppColors.error),
          ),
        ],
      ],
    );
  }
}
