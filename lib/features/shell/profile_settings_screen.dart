import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:speedygo_merchant_app/app/theme/app_theme.dart';
import 'package:speedygo_merchant_app/core/constants/app_strings.dart';
import 'package:speedygo_merchant_app/core/navigation/app_routes.dart';
import 'package:speedygo_merchant_app/core/widgets/merchant_ui.dart';
import 'package:speedygo_merchant_app/features/access/application/access_controller.dart';
import 'package:speedygo_merchant_app/features/auth/application/session_providers.dart';
import 'package:speedygo_merchant_app/features/notifications/application/merchant_push_controller.dart';
import 'package:speedygo_merchant_app/features/notifications/data/push_messaging_gateway.dart';
import 'package:speedygo_merchant_app/features/support/presentation/order_support_screen.dart';
import 'package:speedygo_merchant_app/features/team/data/team_models.dart';

/// Settings hub aligned with `merchant_settings_french`. Only rows with a
/// live destination are listed (no security, exceptional hours, delivery zone,
/// language or legal rows: no screen or contract yet). Team management is
/// OWNER/MANAGER only; received team invitations are open to every role.
class ProfileSettingsScreen extends ConsumerWidget {
  const ProfileSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final access = ref.watch(accessControllerProvider);
    final membership = access.membership;
    final branch = access.selectedBranch;
    final merchantName = membership?.merchantName ?? '';
    final roleLabel = merchantRoleLabel(membership?.role ?? '');
    final multiBranch = (membership?.branches.length ?? 0) > 1;
    final push = ref.watch(merchantPushControllerProvider);
    final notificationsOff =
        push.available && push.authorization == PushAuthorization.denied;
    final canContactSupport = merchantRoleCanContactSupport(membership?.role);

    return MerchantScaffold(
      title: AppStrings.profileSettingsTitle,
      centerTitle: true,
      titleStyle: theme.textTheme.headlineSmall?.copyWith(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: AppColors.primary,
      ),
      body: ListView(
        key: const Key('profile-screen'),
        padding: const EdgeInsets.symmetric(vertical: 24),
        children: [
          _SettingsCard(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: AppColors.primaryContainer,
                    child: Text(
                      merchantInitials(merchantName),
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: AppColors.onPrimaryContainer,
                        fontWeight: FontWeight.w700,
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
                          key: const Key('settings-merchant-name'),
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (branch != null) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.storefront_outlined,
                                size: 16,
                                color: AppColors.onSurfaceVariant,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  branch.name,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: AppColors.onSurfaceVariant,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 4),
                        Text(
                          roleLabel,
                          key: const Key('settings-role'),
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          _SettingsGroup(
            title: AppStrings.profileSectionAccount,
            rows: [
              _SettingsRow(
                key: const Key('settings-profile'),
                icon: Icons.person_outline,
                label: AppStrings.settingsProfileRow,
                onTap: () => context.go(AppRoutes.profile),
              ),
              if (merchantRoleCanReadTeam(membership?.role))
                _SettingsRow(
                  key: const Key('settings-team'),
                  icon: Icons.group_outlined,
                  label: AppStrings.settingsTeamRow,
                  onTap: () => context.push(AppRoutes.team),
                ),
              _SettingsRow(
                key: const Key('settings-team-invitations'),
                icon: Icons.mark_email_unread_outlined,
                label: AppStrings.settingsTeamInvitationsRow,
                onTap: () => context.push(AppRoutes.teamInvitations),
              ),
              if (branch != null)
                _SettingsRow(
                  key: const Key('settings-branch-status'),
                  icon: Icons.verified_outlined,
                  label: AppStrings.profileBranchStatus,
                  trailing: StatusBadge(
                    label: merchantOperationalLabel(branch.operationalStatus),
                    tone: branch.operationalStatus.toUpperCase() == 'ACTIVE'
                        ? StatusTone.success
                        : StatusTone.warning,
                  ),
                ),
              if (multiBranch)
                _SettingsRow(
                  key: const Key('settings-switch-branch'),
                  icon: Icons.swap_horiz,
                  label: AppStrings.switchBranch,
                  onTap: () async {
                    await ref.read(contextStoreProvider).clear();
                    if (membership != null) {
                      await ref
                          .read(contextStoreProvider)
                          .writeMerchantId(membership.merchantId);
                    }
                    await ref.read(accessControllerProvider.notifier).resolve();
                  },
                ),
            ],
          ),
          const SizedBox(height: 24),
          _SettingsGroup(
            title: AppStrings.profileSectionOps,
            rows: [
              _SettingsRow(
                key: const Key('settings-hours'),
                icon: Icons.schedule,
                label: AppStrings.storeProfileHours,
                onTap: () => context.push(AppRoutes.openingHours),
              ),
              _SettingsRow(
                key: const Key('settings-availability'),
                icon: Icons.toggle_on_outlined,
                label: AppStrings.storeProfileAvailability,
                onTap: () => context.push(AppRoutes.storeAvailability),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _SettingsGroup(
            title: AppStrings.profileSectionPrefs,
            rows: [
              _SettingsRow(
                key: const Key('settings-notifications'),
                icon: Icons.notifications_outlined,
                label: AppStrings.notificationsTitle,
                trailing: notificationsOff
                    ? const StatusBadge(
                        key: Key('settings-notifications-off'),
                        label: AppStrings.settingsNotificationsOff,
                        tone: StatusTone.error,
                      )
                    : null,
                onTap: () => context.push(AppRoutes.notificationSettings),
              ),
            ],
          ),
          if (canContactSupport) ...[
            const SizedBox(height: 24),
            _SettingsGroup(
              title: AppStrings.settingsSupportSection,
              rows: [
                _SettingsRow(
                  key: const Key('settings-help-center'),
                  icon: Icons.help_outline,
                  label: AppStrings.settingsHelpCenter,
                  onTap: () => context.push(AppRoutes.support),
                ),
              ],
            ),
          ],
          const SizedBox(height: 32),
          SizedBox(
            height: 48,
            child: OutlinedButton.icon(
              key: const Key('merchant-logout'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                backgroundColor: AppColors.surfaceContainerLowest,
                side: const BorderSide(color: AppColors.error),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                textStyle: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              onPressed: () => context.push(AppRoutes.logout),
              icon: const Icon(Icons.logout),
              label: const Text(AppStrings.logoutConfirmTitle),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            offset: Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Material(type: MaterialType.transparency, child: child),
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.title, required this.rows});

  final String title;
  final List<Widget> rows;

  @override
  Widget build(BuildContext context) {
    return _SettingsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              title.toUpperCase(),
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: AppColors.primary,
                letterSpacing: 0.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0)
              Divider(
                height: 1,
                indent: 16,
                endIndent: 16,
                color: AppColors.outlineVariant.withValues(alpha: 0.3),
              ),
            rows[i],
          ],
        ],
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    super.key,
    required this.icon,
    required this.label,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: AppColors.outline),
            const SizedBox(width: 16),
            Expanded(
              child: Text(label, style: Theme.of(context).textTheme.bodyLarge),
            ),
            if (trailing != null) ...[const SizedBox(width: 8), trailing!],
            if (onTap != null) ...[
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, color: AppColors.outlineVariant),
            ],
          ],
        ),
      ),
    );
  }
}

String merchantInitials(String name) {
  final parts = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((p) => p.isNotEmpty)
      .toList();
  if (parts.isEmpty) return '?';
  if (parts.length == 1) {
    final s = parts[0];
    return s.substring(0, s.length >= 2 ? 2 : 1).toUpperCase();
  }
  return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
}

String merchantRoleLabel(String role) {
  switch (role.toUpperCase()) {
    case 'OWNER':
      return AppStrings.profileRoleOwner;
    case 'MANAGER':
      return AppStrings.profileRoleManager;
    case 'STAFF':
      return AppStrings.profileRoleStaff;
    default:
      return role;
  }
}

String merchantOperationalLabel(String status) {
  switch (status.toUpperCase()) {
    case 'ACTIVE':
      return AppStrings.operationalActive;
    case 'INACTIVE':
      return AppStrings.operationalInactive;
    case 'SUSPENDED':
      return AppStrings.operationalSuspended;
    default:
      return status;
  }
}
