import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speedygo_merchant_app/app/theme/app_theme.dart';
import 'package:speedygo_merchant_app/core/constants/app_strings.dart';
import 'package:speedygo_merchant_app/core/widgets/merchant_primary_button.dart';
import 'package:speedygo_merchant_app/features/team/application/team_controller.dart';
import 'package:speedygo_merchant_app/features/team/data/team_models.dart';

String teamRoleLabel(String role) => switch (role) {
  teamRoleOwner => AppStrings.teamRoleOwner,
  teamRoleManager => AppStrings.teamRoleManager,
  teamRoleStaff => AppStrings.teamRoleStaff,
  _ => role,
};

String teamRoleHint(String role) => switch (role) {
  teamRoleManager => AppStrings.teamRoleManagerHint,
  teamRoleStaff => AppStrings.teamRoleStaffHint,
  _ => '',
};

/// Single-choice role tile (MANAGER / STAFF) used by the invite and the
/// change-role sheets.
class TeamRoleOption extends StatelessWidget {
  const TeamRoleOption({
    super.key,
    required this.role,
    required this.selected,
    required this.onTap,
  });

  final String role;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      inMutuallyExclusiveGroup: true,
      selected: selected,
      button: true,
      child: Material(
        color: selected ? AppColors.primaryFixed : AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: selected ? AppColors.primary : AppColors.outlineVariant,
            width: selected ? 1.5 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  selected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: selected ? AppColors.primary : AppColors.outline,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        teamRoleLabel(role),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        teamRoleHint(role),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
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

/// Opens the invite sheet. On success the one-time accept code sheet follows;
/// the roster is already refreshed by the controller.
Future<void> showTeamInviteSheet(BuildContext context) async {
  final issued = await showModalBottomSheet<(TeamInvitationIssued, String)>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: AppColors.surface,
    builder: (_) => const _InviteSheet(),
  );
  if (issued == null || !context.mounted) return;
  await showTeamAcceptCodeSheet(
    context,
    phone: issued.$2,
    code: issued.$1.acceptCode,
    expiresAt: issued.$1.invitation.expiresAt,
  );
}

class _InviteSheet extends ConsumerStatefulWidget {
  const _InviteSheet();

  @override
  ConsumerState<_InviteSheet> createState() => _InviteSheetState();
}

class _InviteSheetState extends ConsumerState<_InviteSheet> {
  final _phone = TextEditingController();
  String _role = teamRoleStaff;
  bool _submitted = false;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _phone.addListener(() {
      if (_error != null || _submitted) setState(() => _error = null);
    });
  }

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;
    final e164 = normalizeTeamPhone(_phone.text);
    if (e164 == null) {
      setState(() {
        _submitted = true;
        _error = null;
      });
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final issued = await ref
          .read(teamControllerProvider.notifier)
          .createInvitation(phone: e164, role: _role);
      if (!mounted) return;
      Navigator.of(context).pop((issued, e164));
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
    final phoneInvalid = _submitted && normalizeTeamPhone(_phone.text) == null;
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
            key: const Key('team-invite-sheet'),
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                AppStrings.teamInviteTitle,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                AppStrings.teamInviteHint,
                key: const Key('team-invite-hint'),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                key: const Key('team-invite-phone'),
                controller: _phone,
                enabled: !_busy,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.done,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9 +]')),
                  LengthLimitingTextInputFormatter(20),
                ],
                onSubmitted: (_) => _submit(),
                decoration: InputDecoration(
                  labelText: AppStrings.teamInvitePhoneLabel,
                  hintText: AppStrings.teamInvitePhoneHint,
                  helperText: AppStrings.teamInvitePhoneHelper,
                  helperMaxLines: 3,
                  prefixText: '${AppStrings.phonePrefix}  ',
                  errorText: phoneInvalid
                      ? AppStrings.teamInvitePhoneInvalid
                      : null,
                  errorMaxLines: 3,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                AppStrings.teamInviteRoleLabel,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              for (final role in teamAssignableRoles) ...[
                TeamRoleOption(
                  key: Key('team-invite-role-$role'),
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
                  key: const Key('team-invite-error'),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.error,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              MerchantPrimaryButton(
                key: const Key('team-invite-submit'),
                label: AppStrings.teamInviteCreate,
                icon: Icons.person_add,
                leadingIcon: true,
                loading: _busy,
                maxLines: 2,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shows the one-time accept code. The sheet cannot be dismissed by a swipe or
/// a tap outside: the code is never shown again, and SpeedyGo sends nothing,
/// so the owner must copy it and pass it on.
Future<void> showTeamAcceptCodeSheet(
  BuildContext context, {
  required String phone,
  required String code,
  DateTime? expiresAt,
  bool regenerated = false,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    isDismissible: false,
    enableDrag: false,
    backgroundColor: AppColors.surface,
    builder: (_) => _AcceptCodeSheet(
      phone: phone,
      code: code,
      expiresAt: expiresAt,
      regenerated: regenerated,
    ),
  );
}

class _AcceptCodeSheet extends StatelessWidget {
  const _AcceptCodeSheet({
    required this.phone,
    required this.code,
    required this.expiresAt,
    required this.regenerated,
  });

  final String phone;
  final String code;
  final DateTime? expiresAt;
  final bool regenerated;

  Future<void> _copy(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: code));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(AppStrings.teamCodeCopied)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
        child: Column(
          key: const Key('team-accept-code-sheet'),
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.vpn_key_outlined, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    regenerated
                        ? AppStrings.teamCodeRegeneratedTitle
                        : AppStrings.teamCodeTitle,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              AppStrings.teamCodeInstruction(formatTeamPhone(phone)),
              key: const Key('team-accept-code-instruction'),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
            if (regenerated) ...[
              const SizedBox(height: 8),
              Text(
                AppStrings.teamCodeRegeneratedNote,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.outlineVariant),
              ),
              child: SelectableText(
                code,
                key: const Key('team-accept-code'),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
            ),
            if (expiresAt != null) ...[
              const SizedBox(height: 8),
              Text(
                AppStrings.teamExpiresOn(formatTeamDate(expiresAt!)),
                key: const Key('team-accept-code-expiry'),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 16),
            OutlinedButton.icon(
              key: const Key('team-accept-code-copy'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
              onPressed: () => _copy(context),
              icon: const Icon(Icons.copy),
              label: Text(
                AppStrings.teamCodeCopy,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 8),
            MerchantPrimaryButton(
              key: const Key('team-accept-code-done'),
              label: AppStrings.teamCodeDone,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}
