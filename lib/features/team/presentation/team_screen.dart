import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speedygo_merchant_app/app/theme/app_theme.dart';
import 'package:speedygo_merchant_app/core/constants/app_strings.dart';
import 'package:speedygo_merchant_app/core/widgets/merchant_ui.dart';
import 'package:speedygo_merchant_app/features/access/application/access_controller.dart';
import 'package:speedygo_merchant_app/features/team/application/team_controller.dart';
import 'package:speedygo_merchant_app/features/team/data/team_models.dart';
import 'package:speedygo_merchant_app/features/team/presentation/team_invite_sheet.dart';
import 'package:speedygo_merchant_app/features/team/presentation/team_member_actions.dart';

/// Gap kept between the last roster card and the invite FAB when fully scrolled.
const double _teamEndGap = 24;

/// Bottom padding so the last card clears an end-floating button of
/// [fabHeight] (0 without one) plus the Scaffold FAB margin and safe area.
@visibleForTesting
double teamListEndPadding(BuildContext context, double fabHeight) {
  final safeBottom = MediaQuery.paddingOf(context).bottom;
  if (fabHeight <= 0) return _teamEndGap + safeBottom;
  return fabHeight + kFloatingActionButtonMargin + safeBottom + _teamEndGap;
}

bool _stackedLayout(BuildContext context) =>
    MediaQuery.textScalerOf(context).scale(1) >= 1.25;

/// `staff_and_account_access_french`. Members are known by phone only; there
/// is no presence or last-activity data. Only the OWNER (`canManage`) can
/// invite, re-role, revoke, cancel or regenerate codes.
class TeamScreen extends ConsumerStatefulWidget {
  const TeamScreen({super.key});

  @override
  ConsumerState<TeamScreen> createState() => _TeamScreenState();
}

class _TeamScreenState extends ConsumerState<TeamScreen> {
  /// Measured height of the extended invite FAB; M3 default until laid out.
  final _fabHeight = ValueNotifier<double>(56);

  @override
  void dispose() {
    _fabHeight.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final membership = ref.watch(accessControllerProvider).membership;
    final allowed = merchantRoleCanReadTeam(membership?.role);
    final async = ref.watch(teamControllerProvider);
    final team = async.value;
    final forbidden =
        !allowed || (async.hasError && teamIsForbidden(async.error!));
    final canManage = !forbidden && (team?.canManage ?? false);

    return MerchantScaffold(
      title: AppStrings.teamTitle,
      centerTitle: true,
      headerColor: AppColors.background,
      titleStyle: theme.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
        color: AppColors.primary,
      ),
      floatingActionButton: canManage
          ? MerchantSizeReporter(
              onSize: (size) => _fabHeight.value = size.height,
              child: FloatingActionButton.extended(
                key: const Key('team-invite-fab'),
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
                onPressed: () => showTeamInviteSheet(context),
                icon: const Icon(Icons.person_add),
                label: Text(AppStrings.teamInviteMember),
              ),
            )
          : null,
      body: forbidden
          ? const _ForbiddenState()
          : async.when(
              loading: () => const LoadingBody(),
              error: (_, _) => _ErrorState(
                onRetry: () =>
                    ref.read(teamControllerProvider.notifier).reload(),
              ),
              data: (value) => value == null
                  ? _ErrorState(
                      onRetry: () =>
                          ref.read(teamControllerProvider.notifier).reload(),
                    )
                  : _TeamRoster(
                      team: value,
                      merchantName: membership?.merchantName ?? '',
                      canManage: canManage,
                      fabHeight: _fabHeight,
                    ),
            ),
    );
  }
}

class _ForbiddenState extends StatelessWidget {
  const _ForbiddenState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          key: const Key('team-forbidden'),
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_outline, size: 40, color: AppColors.outline),
            const SizedBox(height: 12),
            Text(
              AppStrings.teamForbiddenTitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              AppStrings.teamForbiddenBody,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          key: const Key('team-error'),
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              AppStrings.teamLoadError,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            FilledButton(
              key: const Key('team-retry'),
              onPressed: onRetry,
              child: Text(AppStrings.retry),
            ),
          ],
        ),
      ),
    );
  }
}

class _TeamRoster extends ConsumerWidget {
  const _TeamRoster({
    required this.team,
    required this.merchantName,
    required this.canManage,
    required this.fabHeight,
  });

  final MerchantTeam team;
  final String merchantName;
  final bool canManage;
  final ValueListenable<double> fabHeight;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final invitations = team.outstandingInvitations;
    return RefreshIndicator(
      onRefresh: () => ref.read(teamControllerProvider.notifier).reload(),
      child: ValueListenableBuilder<double>(
        valueListenable: fabHeight,
        builder: (context, measuredFabHeight, _) {
          final endPadding = teamListEndPadding(
            context,
            canManage ? measuredFabHeight : 0,
          );
          return ListView(
            key: const Key('team-screen'),
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.only(top: 16, bottom: endPadding),
            children: [
              _StoreContextCard(merchantName: merchantName),
              const SizedBox(height: 24),
              Text(
                AppStrings.teamActiveMembers,
                key: const Key('team-members-title'),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              if (team.members.isEmpty)
                Text(
                  AppStrings.teamEmptyMembers,
                  key: const Key('team-members-empty'),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                )
              else
                for (final member in team.members) ...[
                  _MemberCard(member: member, canManage: canManage),
                  const SizedBox(height: 12),
                ],
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(
                    Icons.mail_outline,
                    size: 20,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      AppStrings.teamPendingInvitations,
                      key: const Key('team-invites-title'),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (invitations.isEmpty)
                Text(
                  AppStrings.teamEmptyInvitations,
                  key: const Key('team-invites-empty'),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                )
              else
                for (final invitation in invitations) ...[
                  _InvitationCard(invitation: invitation, canManage: canManage),
                  const SizedBox(height: 12),
                ],
              const SizedBox(height: 12),
              const _RolesSummary(),
            ],
          );
        },
      ),
    );
  }
}

class _StoreContextCard extends StatelessWidget {
  const _StoreContextCard({required this.merchantName});

  final String merchantName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return MerchantCard(
      key: const Key('team-store-card'),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: AppColors.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.storefront,
              size: 24,
              color: AppColors.onPrimaryContainer,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  merchantName,
                  key: const Key('team-store-name'),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  AppStrings.teamStoreContext,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OwnerBadge extends StatelessWidget {
  const _OwnerBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.shield_outlined, size: 14, color: AppColors.primary),
          const SizedBox(width: 4),
          Text(
            AppStrings.teamOwnerBadge,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

ButtonStyle _actionStyle({Color? color}) => TextButton.styleFrom(
  foregroundColor: color ?? AppColors.primary,
  minimumSize: const Size(48, 48),
  padding: const EdgeInsets.symmetric(horizontal: 8),
  tapTargetSize: MaterialTapTargetSize.padded,
);

class _MemberCard extends ConsumerWidget {
  const _MemberCard({required this.member, required this.canManage});

  final TeamMember member;
  final bool canManage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final stacked = _stackedLayout(context);
    final showActions = canManage && member.isMutable && !member.isSelf;
    final badge = member.isOwner
        ? _OwnerBadge(key: Key('team-owner-badge-${member.id}'))
        : null;
    return MerchantCard(
      key: Key('team-member-${member.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: AppColors.surfaceVariant,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person_outline,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      member.phone == null
                          ? AppStrings.teamPhoneUnavailable
                          : formatTeamPhone(member.phone),
                      key: Key('team-member-phone-${member.id}'),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          teamRoleLabel(member.role),
                          key: Key('team-member-role-label-${member.id}'),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                        if (member.isSelf)
                          StatusBadge(
                            key: Key('team-member-self-${member.id}'),
                            label: AppStrings.teamSelfBadge,
                            tone: StatusTone.info,
                          ),
                      ],
                    ),
                    if (badge != null && stacked) ...[
                      const SizedBox(height: 8),
                      badge,
                    ],
                  ],
                ),
              ),
              if (badge != null && !stacked) ...[
                const SizedBox(width: 8),
                badge,
              ],
            ],
          ),
          if (showActions) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.only(top: 4),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: AppColors.outlineVariant.withValues(alpha: 0.3),
                  ),
                ),
              ),
              child: Wrap(
                alignment: WrapAlignment.end,
                spacing: 8,
                runSpacing: 0,
                children: [
                  TextButton.icon(
                    key: Key('team-member-role-${member.id}'),
                    style: _actionStyle(),
                    onPressed: () => showChangeRoleSheet(context, ref, member),
                    icon: const Icon(Icons.swap_horiz, size: 16),
                    label: Text(AppStrings.teamChangeRole),
                  ),
                  TextButton.icon(
                    key: Key('team-member-revoke-${member.id}'),
                    style: _actionStyle(color: AppColors.error),
                    onPressed: () => confirmRevokeMember(context, ref, member),
                    icon: const Icon(Icons.person_remove_outlined, size: 16),
                    label: Text(AppStrings.teamRevoke),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _InvitationCard extends ConsumerWidget {
  const _InvitationCard({required this.invitation, required this.canManage});

  final TeamInvitation invitation;
  final bool canManage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final expiresAt = invitation.expiresAt;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(MerchantLayout.radiusCard),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: MerchantCard(
        key: Key('team-invite-${invitation.id}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              formatTeamPhone(invitation.phone),
              key: Key('team-invite-phone-${invitation.id}'),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              AppStrings.teamRoleLine(teamRoleLabel(invitation.role)),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (expiresAt != null)
                  Text(
                    AppStrings.teamExpiresOn(formatTeamDate(expiresAt)),
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: AppColors.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                if (invitation.isExpired)
                  StatusBadge(
                    key: Key('team-invite-expired-${invitation.id}'),
                    label: AppStrings.teamInvitationExpired,
                    tone: StatusTone.warning,
                  ),
              ],
            ),
            if (canManage) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.only(top: 8),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: AppColors.outlineVariant.withValues(alpha: 0.2),
                    ),
                  ),
                ),
                child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    TextButton(
                      key: Key('team-invite-regenerate-${invitation.id}'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        backgroundColor: AppColors.surfaceContainerHigh,
                        minimumSize: const Size(48, 48),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        shape: const StadiumBorder(),
                      ),
                      onPressed: () =>
                          regenerateInvitationCode(context, ref, invitation),
                      child: Text(AppStrings.teamRegenerateCode),
                    ),
                    TextButton(
                      key: Key('team-invite-cancel-${invitation.id}'),
                      style: _actionStyle(color: AppColors.error),
                      onPressed: () =>
                          confirmCancelInvitation(context, ref, invitation),
                      child: Text(AppStrings.teamCancelInvitation),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Capability summary derived from the permission matrix of
/// `MERCHANT_TEAM_MANAGEMENT.md` (not Stitch's Opérateur / catalogue split).
class _RolesSummary extends StatelessWidget {
  const _RolesSummary();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      key: const Key('team-roles-summary'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline, color: AppColors.secondary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  AppStrings.teamRolesSummary,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _SummaryLine(
            roleKey: teamRoleOwner,
            role: AppStrings.teamRoleOwner,
            text: AppStrings.teamSummaryOwner,
          ),
          const SizedBox(height: 12),
          _SummaryLine(
            roleKey: teamRoleManager,
            role: AppStrings.teamRoleManager,
            text: AppStrings.teamSummaryManager,
          ),
          const SizedBox(height: 12),
          _SummaryLine(
            roleKey: teamRoleStaff,
            role: AppStrings.teamRoleStaff,
            text: AppStrings.teamSummaryStaff,
          ),
          const SizedBox(height: 12),
          _SummaryLine(
            roleKey: 'SCOPE',
            icon: Icons.storefront_outlined,
            text: AppStrings.teamSummaryScope,
          ),
        ],
      ),
    );
  }
}

class _SummaryLine extends StatelessWidget {
  const _SummaryLine({
    required this.roleKey,
    required this.text,
    this.role,
    this.icon = Icons.check_circle_outline,
  });

  final String roleKey;
  final String? role;
  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      key: Key('team-role-summary-$roleKey'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(icon, size: 20, color: AppColors.secondary),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text.rich(
            TextSpan(
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.onSurface,
              ),
              children: [
                if (role != null)
                  TextSpan(
                    text: '$role : ',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                TextSpan(text: text),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
