import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speedygo_merchant_app/app/theme/app_theme.dart';
import 'package:speedygo_merchant_app/core/constants/app_strings.dart';
import 'package:speedygo_merchant_app/core/widgets/merchant_ui.dart';
import 'package:speedygo_merchant_app/features/auth/application/session_controller.dart';

/// In-app language selector (parity row 61 / D-G3).
///
/// Applies immediately on confirmation via [SessionController.setLocale]
/// without logging out. Selection is persisted across restarts.
class LanguageSettingsScreen extends ConsumerStatefulWidget {
  const LanguageSettingsScreen({super.key});

  @override
  ConsumerState<LanguageSettingsScreen> createState() =>
      _LanguageSettingsScreenState();
}

class _LanguageSettingsScreenState
    extends ConsumerState<LanguageSettingsScreen> {
  String? _pending;

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionControllerProvider);
    final current = session.locale == 'ar' ? 'ar' : 'fr';
    final selected = _pending ?? current;
    final dirty = selected != current;
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return MerchantScaffold(
      title: AppStrings.languageSettingsTitle,
      centerTitle: true,
      body: ListView(
        key: const Key('language-settings-screen'),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
        children: [
          Text(
            AppStrings.languageSettingsSubtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),
          _LanguageCard(
            key: const Key('language-option-fr'),
            title: AppStrings.languageOptionFrench,
            selected: selected == 'fr',
            onTap: session.busy
                ? null
                : () => setState(() => _pending = 'fr'),
          ),
          const SizedBox(height: 12),
          _LanguageCard(
            key: const Key('language-option-ar'),
            title: AppStrings.languageOptionArabic,
            selected: selected == 'ar',
            onTap: session.busy
                ? null
                : () => setState(() => _pending = 'ar'),
          ),
          const SizedBox(height: 20),
          Text(
            AppStrings.languagePreviewNote,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
          if (session.errorMessage != null) ...[
            const SizedBox(height: 16),
            Text(
              session.errorMessage!,
              key: const Key('language-settings-error'),
              style: TextStyle(color: theme.colorScheme.error),
            ),
          ],
        ],
      ),
      bottom: Material(
        elevation: 6,
        color: theme.colorScheme.surface,
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              12,
              16,
              12 + bottomInset.clamp(0, 24),
            ),
            child: SizedBox(
              height: 56,
              child: FilledButton(
                key: const Key('language-apply'),
                onPressed: !dirty || session.busy
                    ? null
                    : () async {
                        await ref
                            .read(sessionControllerProvider.notifier)
                            .setLocale(selected);
                        if (!mounted) return;
                        setState(() => _pending = null);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(AppStrings.languageApplied)),
                        );
                      },
                child: session.busy
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(AppStrings.languageApply),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LanguageCard extends StatelessWidget {
  const _LanguageCard({
    super.key,
    required this.title,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: AppColors.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 64),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Icon(
                  selected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  color: selected ? AppColors.primary : AppColors.onSurfaceVariant,
                  size: 28,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
