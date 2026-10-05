import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:speedygo_merchant_app/app/theme/app_theme.dart';
import 'package:speedygo_merchant_app/core/constants/app_strings.dart';
import 'package:speedygo_merchant_app/core/navigation/app_routes.dart';
import 'package:speedygo_merchant_app/core/widgets/merchant_primary_button.dart';
import 'package:speedygo_merchant_app/core/widgets/merchant_ui.dart';
import 'package:speedygo_merchant_app/features/access/application/access_controller.dart';
import 'package:speedygo_merchant_app/features/team/application/team_controller.dart';
import 'package:speedygo_merchant_app/features/team/data/team_models.dart';
import 'package:speedygo_merchant_app/features/team/presentation/team_invite_sheet.dart';

/// Invitations addressed to the signed-in phone. Accepting needs the one-time
/// code the owner shared manually; nothing is delivered by SpeedyGo.
class MyInvitationsScreen extends ConsumerWidget {
  const MyInvitationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final async = ref.watch(myTeamInvitationsControllerProvider);
    return MerchantScaffold(
      title: AppStrings.teamInvitationsTitle,
      centerTitle: true,
      headerColor: AppColors.background,
      titleStyle: theme.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
        color: AppColors.primary,
      ),
      body: async.when(
        loading: () => const LoadingBody(),
        error: (_, _) => Center(
          child: Column(
            key: const Key('my-invitations-error'),
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                AppStrings.teamInvitationsLoadError,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              FilledButton(
                key: const Key('my-invitations-retry'),
                onPressed: () => ref
                    .read(myTeamInvitationsControllerProvider.notifier)
                    .reload(),
                child: Text(AppStrings.retry),
              ),
            ],
          ),
        ),
        data: (invitations) => RefreshIndicator(
          onRefresh: () =>
              ref.read(myTeamInvitationsControllerProvider.notifier).reload(),
          child: ListView(
            key: const Key('my-invitations-screen'),
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.only(
              top: 16,
              bottom: 24 + MediaQuery.paddingOf(context).bottom,
            ),
            children: [
              Text(
                AppStrings.teamInvitationsHint,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              if (invitations.isEmpty)
                Text(
                  AppStrings.teamInvitationsEmpty,
                  key: const Key('my-invitations-empty'),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                )
              else
                for (final invitation in invitations) ...[
                  _MyInvitationCard(invitation: invitation),
                  const SizedBox(height: 12),
                ],
            ],
          ),
        ),
      ),
    );
  }
}

class _MyInvitationCard extends ConsumerWidget {
  const _MyInvitationCard({required this.invitation});

  final MyTeamInvitation invitation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final expiresAt = invitation.expiresAt;
    return MerchantCard(
      key: Key('my-invitation-${invitation.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            invitation.merchantName,
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
          if (expiresAt != null) ...[
            const SizedBox(height: 2),
            Text(
              AppStrings.teamExpiresOn(formatTeamDate(expiresAt)),
              style: theme.textTheme.labelMedium?.copyWith(
                color: AppColors.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          const SizedBox(height: 12),
          MerchantPrimaryButton(
            key: Key('my-invitation-accept-${invitation.id}'),
            label: AppStrings.teamAccept,
            icon: Icons.check,
            leadingIcon: true,
            onPressed: () => _openAccept(context, ref),
          ),
        ],
      ),
    );
  }

  Future<void> _openAccept(BuildContext context, WidgetRef ref) async {
    final accepted = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: AppColors.surface,
      builder: (_) => _AcceptSheet(invitation: invitation),
    );
    if (accepted == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.teamAccepted(invitation.merchantName.toString())),
        ),
      );
      // Re-resolve merchant access so a new membership can enter the shell
      // (including invitees who previously had no MerchantMember).
      await ref.read(accessControllerProvider.notifier).resolve();
      if (!context.mounted) return;
      final router = GoRouter.maybeOf(context);
      if (router == null) return;
      final destination = ref.read(accessControllerProvider).destination;
      if (destination == AccessDestination.home ||
          destination == AccessDestination.selectBranch ||
          destination == AccessDestination.needBranch) {
        router.go(
          destination == AccessDestination.home
              ? AppRoutes.home
              : destination == AccessDestination.selectBranch
                  ? AppRoutes.selectBranch
                  : AppRoutes.needBranch,
        );
      }
    }
  }
}

class _AcceptSheet extends ConsumerStatefulWidget {
  const _AcceptSheet({required this.invitation});

  final MyTeamInvitation invitation;

  @override
  ConsumerState<_AcceptSheet> createState() => _AcceptSheetState();
}

class _AcceptSheetState extends ConsumerState<_AcceptSheet> {
  final _code = TextEditingController();
  bool _submitted = false;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _code.addListener(() {
      if (_error != null || _submitted) setState(() => _error = null);
    });
  }

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  String get _trimmed => _code.text.trim();

  bool get _valid =>
      _trimmed.length == teamAcceptCodeLength &&
      RegExp(r'^[0-9a-fA-F]+$').hasMatch(_trimmed);

  Future<void> _submit() async {
    if (_busy) return;
    if (!_valid) {
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
      await ref
          .read(myTeamInvitationsControllerProvider.notifier)
          .accept(widget.invitation, _trimmed);
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
            key: const Key('my-invitation-sheet'),
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                AppStrings.teamAcceptTitle,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.invitation.merchantName,
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              TextField(
                key: const Key('my-invitation-code'),
                controller: _code,
                enabled: !_busy,
                autocorrect: false,
                enableSuggestions: false,
                minLines: 2,
                maxLines: 3,
                textInputAction: TextInputAction.done,
                style: const TextStyle(fontFamily: 'monospace'),
                decoration: InputDecoration(
                  labelText: AppStrings.teamAcceptCodeLabel,
                  errorText: _submitted && !_valid
                      ? AppStrings.teamAcceptCodeInvalid
                      : null,
                  errorMaxLines: 3,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(
                  _error!,
                  key: const Key('my-invitation-error'),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.error,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              MerchantPrimaryButton(
                key: const Key('my-invitation-code-submit'),
                label: AppStrings.teamAcceptConfirm,
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
