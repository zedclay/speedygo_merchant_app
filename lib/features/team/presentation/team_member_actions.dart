import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speedygo_merchant_app/app/theme/app_theme.dart';
import 'package:speedygo_merchant_app/core/constants/app_strings.dart';
import 'package:speedygo_merchant_app/core/widgets/merchant_primary_button.dart';
import 'package:speedygo_merchant_app/features/team/application/team_controller.dart';
import 'package:speedygo_merchant_app/features/team/data/team_models.dart';
import 'package:speedygo_merchant_app/features/team/presentation/team_invite_sheet.dart';

void _toast(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

String _memberLabel(TeamMember member) => member.phone == null
    ? AppStrings.teamPhoneUnavailable
    : formatTeamPhone(member.phone);

/// Confirms, then revokes a MANAGER/STAFF membership. A stale version is
/// reported and the roster is re-read by the controller.
Future<void> confirmRevokeMember(
  BuildContext context,
  WidgetRef ref,
  TeamMember member,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialog) => AlertDialog(
      key: const Key('team-revoke-dialog'),
      title: Text(AppStrings.teamRevokeTitle),
      content: Text(AppStrings.teamRevokeBody(_memberLabel(member))),
      actions: [
        TextButton(
          key: const Key('team-revoke-keep'),
          onPressed: () => Navigator.of(dialog).pop(false),
          child: Text(AppStrings.teamKeep),
        ),
        TextButton(
          key: const Key('team-revoke-confirm'),
          style: TextButton.styleFrom(foregroundColor: AppColors.error),
          onPressed: () => Navigator.of(dialog).pop(true),
          child: Text(AppStrings.teamRevoke),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return;
  try {
    await ref.read(teamControllerProvider.notifier).revoke(member);
    if (context.mounted) _toast(context, AppStrings.teamRevoked);
  } catch (e) {
    if (context.mounted) _toast(context, teamErrorMessage(e));
  }
}

/// Role change MANAGER <-> STAFF (OWNER is never assignable).
Future<void> showChangeRoleSheet(
  BuildContext context,
  WidgetRef ref,
  TeamMember member,
) async {
  final changed = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: AppColors.surface,
    builder: (_) => _ChangeRoleSheet(member: member),
  );
  if (changed == true && context.mounted) {
    _toast(context, AppStrings.teamRoleUpdated);
  }
}

class _ChangeRoleSheet extends ConsumerStatefulWidget {
  const _ChangeRoleSheet({required this.member});

  final TeamMember member;

  @override
  ConsumerState<_ChangeRoleSheet> createState() => _ChangeRoleSheetState();
}

class _ChangeRoleSheetState extends ConsumerState<_ChangeRoleSheet> {
  late String _role = widget.member.role;
  bool _busy = false;
  String? _error;

  Future<void> _save() async {
    if (_busy || _role == widget.member.role) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(teamControllerProvider.notifier)
          .changeRole(widget.member, _role);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = teamErrorMessage(e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        0,
        16,
        16 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            key: const Key('team-role-sheet'),
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                AppStrings.teamRoleSheetTitle,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _memberLabel(widget.member),
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                AppStrings.teamRoleSheetHint,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              for (final role in teamAssignableRoles) ...[
                TeamRoleOption(
                  key: Key('team-role-option-$role'),
                  role: role,
                  selected: _role == role,
                  onTap: _busy ? null : () => setState(() => _role = role),
                ),
                const SizedBox(height: 8),
              ],
              if (_error != null) ...[
                const SizedBox(height: 4),
                Text(
                  _error!,
                  key: const Key('team-role-error'),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.error,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              MerchantPrimaryButton(
                key: const Key('team-role-save'),
                label: AppStrings.teamRoleSave,
                loading: _busy,
                onPressed: _role == widget.member.role ? null : _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Confirms, then cancels a pending invitation.
Future<void> confirmCancelInvitation(
  BuildContext context,
  WidgetRef ref,
  TeamInvitation invitation,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialog) => AlertDialog(
      key: const Key('team-cancel-invite-dialog'),
      title: Text(AppStrings.teamCancelInviteTitle),
      content: Text(
        AppStrings.teamCancelInviteBody(formatTeamPhone(invitation.phone)),
      ),
      actions: [
        TextButton(
          key: const Key('team-cancel-invite-keep'),
          onPressed: () => Navigator.of(dialog).pop(false),
          child: Text(AppStrings.teamKeep),
        ),
        TextButton(
          key: const Key('team-cancel-invite-confirm'),
          style: TextButton.styleFrom(foregroundColor: AppColors.error),
          onPressed: () => Navigator.of(dialog).pop(true),
          child: Text(AppStrings.teamCancelInviteConfirm),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return;
  try {
    await ref
        .read(teamControllerProvider.notifier)
        .cancelInvitation(invitation);
    if (context.mounted) _toast(context, AppStrings.teamInviteCancelled);
  } catch (e) {
    if (context.mounted) _toast(context, teamErrorMessage(e));
  }
}

/// Issues a new accept code (the previous one stops working) and shows it. No
/// message is delivered to the invitee.
Future<void> regenerateInvitationCode(
  BuildContext context,
  WidgetRef ref,
  TeamInvitation invitation,
) async {
  try {
    final issued = await ref
        .read(teamControllerProvider.notifier)
        .regenerateCode(invitation);
    if (!context.mounted) return;
    await showTeamAcceptCodeSheet(
      context,
      phone: invitation.phone,
      code: issued.acceptCode,
      expiresAt: issued.invitation.expiresAt,
      regenerated: true,
    );
  } catch (e) {
    if (context.mounted) _toast(context, teamErrorMessage(e));
  }
}
