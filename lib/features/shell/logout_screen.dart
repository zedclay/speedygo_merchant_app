import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:speedygo_merchant_app/app/theme/app_theme.dart';
import 'package:speedygo_merchant_app/core/constants/app_strings.dart';
import 'package:speedygo_merchant_app/core/widgets/merchant_ui.dart';
import 'package:speedygo_merchant_app/features/access/application/access_controller.dart';
import 'package:speedygo_merchant_app/features/auth/application/session_controller.dart';
import 'package:speedygo_merchant_app/features/orders/application/orders_controller.dart';
import 'package:speedygo_merchant_app/features/shell/profile_settings_screen.dart';
import 'package:speedygo_merchant_app/features/store/application/store_controllers.dart';

/// Sign-out confirmation (`merchant_logout_french`). The operational warning
/// only appears when the live order count or availability calls for it.
class LogoutScreen extends ConsumerStatefulWidget {
  const LogoutScreen({super.key});

  @override
  ConsumerState<LogoutScreen> createState() => _LogoutScreenState();
}

class _LogoutScreenState extends ConsumerState<LogoutScreen> {
  bool _busy = false;

  Future<void> _logout() async {
    setState(() => _busy = true);
    await ref.read(sessionControllerProvider.notifier).logout();
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final access = ref.watch(accessControllerProvider);
    final merchantName = access.membership?.merchantName ?? '';
    final branchName = access.selectedBranch?.name;
    final active = ref.watch(homeOrderCountsProvider).value?.active;
    final storeOpen = ref
        .watch(branchAvailabilityControllerProvider)
        .value
        ?.isOpenNow;
    final hasActive = (active ?? 0) > 0;
    final showWarning = hasActive || storeOpen == true;

    return MerchantScaffold(
      title: AppStrings.logoutConfirmTitle,
      titleStyle: theme.textTheme.headlineSmall?.copyWith(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: AppColors.primary,
      ),
      bodyPadding: EdgeInsets.zero,
      body: Column(
        key: const Key('logout-screen'),
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
              children: [
                _AccountCard(
                  merchantName: merchantName,
                  branchName: branchName,
                ),
                if (showWarning) ...[
                  const SizedBox(height: 24),
                  _OperationsWarning(activeCount: active, storeOpen: storeOpen),
                ],
                const SizedBox(height: 24),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: AppColors.onSurfaceVariant,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        AppStrings.logoutDataPreserved,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    height: 52,
                    child: FilledButton.icon(
                      key: const Key('logout-confirm'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.error,
                        foregroundColor: AppColors.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        textStyle: theme.textTheme.labelLarge?.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      onPressed: _busy ? null : _logout,
                      icon: const Icon(Icons.logout),
                      label: const Text(AppStrings.logout),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 48,
                    child: OutlinedButton(
                      key: const Key('logout-cancel'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        backgroundColor: AppColors.surfaceContainerLowest,
                        side: const BorderSide(color: AppColors.primary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        textStyle: theme.textTheme.labelLarge?.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      onPressed: _busy ? null : () => context.pop(),
                      child: const Text(AppStrings.logoutCancel),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountCard extends StatelessWidget {
  const _AccountCard({required this.merchantName, required this.branchName});

  final String merchantName;
  final String? branchName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final stacked = MediaQuery.textScalerOf(context).scale(1) >= 1.25;
    const chip = _ConnectedChip();
    return MerchantCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.primaryContainer,
            child: Text(
              merchantInitials(merchantName),
              style: theme.textTheme.titleLarge?.copyWith(
                color: AppColors.onPrimaryContainer,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  merchantName,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (branchName != null && branchName != merchantName) ...[
                  const SizedBox(height: 2),
                  Text(
                    branchName!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (stacked) ...[const SizedBox(height: 8), chip],
              ],
            ),
          ),
          if (!stacked) ...[const SizedBox(width: 8), chip],
        ],
      ),
    );
  }
}

class _ConnectedChip extends StatelessWidget {
  const _ConnectedChip();

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF16A34A);
    return Container(
      key: const Key('logout-connected'),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.tertiaryFixedDim.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: AppColors.tertiaryFixed.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: green,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            AppStrings.logoutConnected,
            style: Theme.of(context).textTheme.labelMedium
                ?.copyWith(color: green, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _OperationsWarning extends StatelessWidget {
  const _OperationsWarning({
    required this.activeCount,
    required this.storeOpen,
  });

  final int? activeCount;
  final bool? storeOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasActive = (activeCount ?? 0) > 0;
    Widget line(String label, String value, Color color, Key key) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
          const SizedBox(width: 8),
          Text(
            value,
            key: key,
            style: theme.textTheme.labelLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
    return Container(
      key: const Key('logout-warning'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.errorContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.errorContainer),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_rounded, color: AppColors.error),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  AppStrings.logoutWarningTitle,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  AppStrings.logoutWarningBody(
                    hasActiveOrders: hasActive,
                    storeOpen: storeOpen == true,
                  ),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.outlineVariant),
                  ),
                  child: Column(
                    children: [
                      if (activeCount != null)
                        line(
                          AppStrings.logoutActiveOrders,
                          '$activeCount',
                          hasActive ? AppColors.error : AppColors.onSurface,
                          const Key('logout-active-count'),
                        ),
                      if (activeCount != null && storeOpen != null)
                        const Divider(height: 1),
                      if (storeOpen != null)
                        line(
                          AppStrings.logoutStoreState,
                          storeOpen!
                              ? AppStrings.logoutStoreOpen
                              : AppStrings.logoutStoreClosed,
                          AppColors.primary,
                          const Key('logout-store-state'),
                        ),
                    ],
                  ),
                ),
                if (hasActive) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      AppStrings.logoutHandoverAdvice,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: AppColors.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
