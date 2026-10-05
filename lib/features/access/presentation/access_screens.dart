import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:speedygo_merchant_app/app/theme/app_theme.dart';
import 'package:speedygo_merchant_app/core/constants/app_strings.dart';
import 'package:speedygo_merchant_app/core/navigation/app_routes.dart';
import 'package:speedygo_merchant_app/core/widgets/merchant_ui.dart';
import 'package:speedygo_merchant_app/features/access/application/access_controller.dart';
import 'package:speedygo_merchant_app/features/access/data/models.dart';
import 'package:speedygo_merchant_app/features/access/presentation/evidence_presentation.dart';
import 'package:speedygo_merchant_app/features/access/presentation/verification_review_widgets.dart';
import 'package:speedygo_merchant_app/features/auth/application/session_controller.dart';
import 'package:speedygo_merchant_app/features/orders/presentation/order_public_reference.dart';
import 'package:speedygo_merchant_app/features/shell/profile_settings_screen.dart'
    show merchantRoleLabel;
import 'package:speedygo_merchant_app/features/support/presentation/order_support_screen.dart';
import 'package:speedygo_merchant_app/features/support/presentation/support_center_screen.dart';

class NoMembershipScreen extends ConsumerStatefulWidget {
  const NoMembershipScreen({super.key});

  @override
  ConsumerState<NoMembershipScreen> createState() => _NoMembershipScreenState();
}

class _NoMembershipScreenState extends ConsumerState<NoMembershipScreen> {
  final _name = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final access = ref.watch(accessControllerProvider);
    return MerchantScaffold(
      title: AppStrings.noMembershipTitle,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 12),
          Text(AppStrings.noMembershipBody),
          const SizedBox(height: 24),
          Text(
            AppStrings.merchantNameLabel,
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 8),
          TextField(
            key: const Key('merchant-create-name'),
            controller: _name,
            decoration: InputDecoration(
              hintText: AppStrings.merchantNameHint,
            ),
          ),
          if (access.errorMessage != null) ...[
            const SizedBox(height: 12),
            Text(
              access.errorMessage!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const Spacer(),
          FilledButton(
            key: const Key('merchant-create-submit'),
            onPressed: access.busy
                ? null
                : () => ref
                      .read(accessControllerProvider.notifier)
                      .createMerchantProfile(_name.text),
            child: Text(AppStrings.createMerchant),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            key: const Key('merchant-no-membership-invitations'),
            onPressed: () => context.push(AppRoutes.accessTeamInvitations),
            child: Text(AppStrings.noMembershipInvitationsCta),
          ),
          TextButton(
            onPressed: () =>
                ref.read(sessionControllerProvider.notifier).logout(),
            child: Text(AppStrings.logout),
          ),
        ],
      ),
    );
  }
}

class SelectBranchScreen extends ConsumerWidget {
  const SelectBranchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final access = ref.watch(accessControllerProvider);
    final membership = access.membership;
    final branches = membership == null
        ? const <MerchantBranch>[]
        : (membership.activeBranches.isNotEmpty
              ? membership.activeBranches
              : membership.branches);
    return MerchantScaffold(
      title: AppStrings.selectBranchTitle,
      body: ListView(
        children: [
          const SizedBox(height: 12),
          Text(AppStrings.selectBranchSubtitle),
          const SizedBox(height: 16),
          ...branches.map(
            (branch) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: MerchantCard(
                child: ListTile(
                  key: Key('branch-${branch.id}'),
                  title: Text(branch.name),
                  subtitle: Text(branch.addressText),
                  trailing: StatusBadge(
                    label: branch.operationalStatus,
                    tone: branch.operationalStatus.toUpperCase() == 'ACTIVE'
                        ? StatusTone.success
                        : StatusTone.warning,
                  ),
                  onTap: () => ref
                      .read(accessControllerProvider.notifier)
                      .selectBranch(branch),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class NeedBranchScreen extends ConsumerStatefulWidget {
  const NeedBranchScreen({super.key});

  @override
  ConsumerState<NeedBranchScreen> createState() => _NeedBranchScreenState();
}

class _NeedBranchScreenState extends ConsumerState<NeedBranchScreen> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  final _lat = TextEditingController(text: '36.7538');
  final _lng = TextEditingController(text: '3.0588');

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _address.dispose();
    _lat.dispose();
    _lng.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final access = ref.watch(accessControllerProvider);
    return MerchantScaffold(
      title: AppStrings.needBranchTitle,
      body: ListView(
        children: [
          const SizedBox(height: 12),
          Text(AppStrings.needBranchBody),
          const SizedBox(height: 16),
          TextField(
            key: const Key('branch-name'),
            controller: _name,
            decoration: InputDecoration(
              labelText: AppStrings.branchNameLabel,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            key: const Key('branch-phone'),
            controller: _phone,
            decoration: InputDecoration(
              labelText: AppStrings.branchPhoneLabel,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            key: const Key('branch-address'),
            controller: _address,
            decoration: InputDecoration(
              labelText: AppStrings.branchAddressLabel,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _lat,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: AppStrings.branchLatLabel,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _lng,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: AppStrings.branchLngLabel,
            ),
          ),
          if (access.errorMessage != null) ...[
            const SizedBox(height: 12),
            Text(
              access.errorMessage!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: 24),
          FilledButton(
            key: const Key('branch-create-submit'),
            onPressed: access.busy
                ? null
                : () => ref
                      .read(accessControllerProvider.notifier)
                      .createBranch(
                        name: _name.text,
                        phone: _phone.text,
                        addressText: _address.text,
                        latitude: double.tryParse(_lat.text) ?? 0,
                        longitude: double.tryParse(_lng.text) ?? 0,
                        // Legacy need-branch form: Alger Centre catalogue pair.
                        // Prefer registration / store-address screens for full selectors.
                        wilayaCode: '16',
                        communeId: 556,
                      ),
            child: Text(AppStrings.addBranch),
          ),
        ],
      ),
    );
  }
}

class VerificationScreen extends ConsumerWidget {
  const VerificationScreen({super.key, required this.kind});

  final AccessDestination kind;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return switch (kind) {
      AccessDestination.verificationPending => const _PendingVerificationBody(),
      AccessDestination.verificationRejected =>
        const _RejectedVerificationBody(),
      _ => _LegacyVerificationBody(kind: kind),
    };
  }
}

class _VerificationHeader extends StatelessWidget {
  const _VerificationHeader({this.title, this.trailing});

  final String? title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final resolvedTitle = title ?? AppStrings.appName;
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 56,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Icon(Icons.speed, color: AppColors.primary, size: 28),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    resolvedTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
                ?trailing,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Real checklist row: document category, requirement and contract state.
class _EvidenceRow extends StatelessWidget {
  const _EvidenceRow({required this.item, this.accent = false});

  final MerchantEvidenceItem item;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final state = EvidencePresentation.itemState(item);
    final tone = switch (state) {
      'Ajouté' || 'Fourni' => StatusTone.success,
      'En examen' || 'Non fourni' => StatusTone.info,
      _ => StatusTone.warning,
    };
    final accentColor = switch (state) {
      'Manquant' => AppColors.error,
      'Non fourni' => AppColors.outlineVariant,
      _ => AppColors.tertiaryFixedDim,
    };
    final (icon, iconColor) = switch (state) {
      'Manquant' => (Icons.description_outlined, AppColors.error),
      'Non fourni' => (Icons.remove_circle_outline, AppColors.outline),
      _ => (Icons.check_circle_outline, AppColors.tertiary),
    };
    final text = Theme.of(context).textTheme;
    final stackBadge = MediaQuery.textScalerOf(context).scale(1) >= 1.2;
    final badge = StatusBadge(label: state, tone: tone);
    final row = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 22, color: iconColor),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                EvidencePresentation.documentTitle(item.type),
                style: text.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 2),
              Text(
                EvidencePresentation.requirementLabel(item.required),
                style: text.bodySmall?.copyWith(color: AppColors.outline),
              ),
              if (stackBadge) ...[const SizedBox(height: 6), badge],
            ],
          ),
        ),
        if (!stackBadge) ...[const SizedBox(width: 8), badge],
      ],
    );
    if (!accent) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: row,
      );
    }
    return Container(
      key: Key('merchant-verification-item-${item.type}'),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.4),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 4, color: accentColor),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                child: row,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VerificationCard extends StatelessWidget {
  const _VerificationCard({required this.child, this.cardKey});

  final Widget child;
  final Key? cardKey;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: cardKey,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.2),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _PendingVerificationBody extends ConsumerWidget {
  const _PendingVerificationBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final access = ref.watch(accessControllerProvider);
    final membership = access.membership;
    final checklist = membership?.evidenceChecklist ?? const [];
    final submitted = membership?.verificationSubmitted == true;
    final hasMissingRequired = checklist.any(
      (item) => item.required && !item.complete,
    );
    final guidance = EvidencePresentation.pendingGuidance(
      verificationSubmitted: submitted,
      verificationReady: membership?.verificationReady == true,
      hasMissingRequired: hasMissingRequired,
    );
    final reference = membership?.merchantPublicReference.trim() ?? '';
    final canContactSupport = merchantRoleCanContactSupport(membership?.role);
    final text = Theme.of(context).textTheme;

    return Scaffold(
      key: const Key('merchant-verification-pending'),
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _VerificationHeader(),
          Expanded(
            child: Stack(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 8),
                      Center(
                        child: Container(
                          width: 160,
                          height: 160,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primaryFixed.withValues(
                              alpha: 0.3,
                            ),
                            gradient: LinearGradient(
                              begin: Alignment.bottomLeft,
                              end: Alignment.topRight,
                              colors: [
                                Color.alphaBlend(
                                  AppColors.primary.withValues(alpha: 0.05),
                                  AppColors.primaryFixed.withValues(alpha: 0.3),
                                ),
                                AppColors.primaryFixed.withValues(alpha: 0.3),
                              ],
                            ),
                          ),
                          child: const Icon(
                            Icons.hourglass_empty,
                            size: 80,
                            color: AppColors.primaryContainer,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        membership?.merchantName ?? '—',
                        key: const Key('merchant-verification-identity'),
                        textAlign: TextAlign.center,
                        style: text.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 24),
                      _VerificationCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.schedule,
                                  size: 22,
                                  color: AppColors.primaryContainer,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    AppStrings.verificationPendingTitle,
                                    style: text.titleMedium?.copyWith(
                                      color: AppColors.primaryContainer,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (reference.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              OrderPublicReferenceLine(
                                reference: reference,
                                label: AppStrings.verificationReferenceFull,
                                prefix:
                                    '${AppStrings.verificationReferenceLabel} : ',
                                textKey: const Key(
                                  'merchant-verification-reference',
                                ),
                                openKey: const Key(
                                  'merchant-verification-reference-open',
                                ),
                                maxLines: 2,
                                textStyle: text.labelLarge?.copyWith(
                                  color: AppColors.outline,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (submitted) ...[
                        const SizedBox(height: 16),
                        _VerificationCard(
                          cardKey: const Key('merchant-verification-timeline'),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppStrings.verificationTimelineTitle,
                                style: text.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 16),
                              _ProgressRow(
                                done: true,
                                active: false,
                                title: AppStrings.verificationSubmittedStep,
                                subtitle: null,
                              ),
                              _ProgressRow(
                                done: false,
                                active: true,
                                title: AppStrings.verificationReviewStep,
                                subtitle: AppStrings.verificationReviewStepBody,
                              ),
                              _ProgressRow(
                                done: false,
                                active: false,
                                title: AppStrings.verificationFinalStep,
                                subtitle: AppStrings.verificationFinalStepBody,
                                isLast: true,
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (membership != null &&
                          VerificationDossierInfo.hasData(membership)) ...[
                        const SizedBox(height: 16),
                        VerificationDossierInfo(membership: membership),
                      ],
                      const SizedBox(height: 16),
                      _VerificationCard(
                        cardKey: const Key('merchant-verification-checklist'),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppStrings.verificationDossierProgress,
                              style: text.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            for (var i = 0; i < checklist.length; i++) ...[
                              if (i > 0)
                                Divider(
                                  height: 1,
                                  color: AppColors.outlineVariant.withValues(
                                    alpha: 0.3,
                                  ),
                                ),
                              _EvidenceRow(item: checklist[i]),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        key: const Key('merchant-verification-guidance-box'),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.primaryFixed.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: const Border(
                            left: BorderSide(
                              color: AppColors.primary,
                              width: 4,
                            ),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.info_outline,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                guidance,
                                key: const Key(
                                  'merchant-verification-guidance',
                                ),
                                style: text.bodyMedium?.copyWith(
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (access.errorMessage != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          access.errorMessage!,
                          style: const TextStyle(color: AppColors.error),
                        ),
                      ],
                    ],
                  ),
                ),
                const Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: 24,
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0x00F9F9FF), AppColors.background],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Flat footer: no Material elevation (avoids a grey shadow strip).
          ColoredBox(
            color: AppColors.background,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (membership?.verificationReady == true && !submitted)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: FilledButton(
                          style: _verificationPrimaryStyle,
                          onPressed: () => ref
                              .read(accessControllerProvider.notifier)
                              .openRegistrationCorrections(),
                          child: Text(AppStrings.submitVerification),
                        ),
                      ),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x330A4096),
                            blurRadius: 12,
                            offset: Offset(0, 6),
                          ),
                        ],
                      ),
                      child: FilledButton.icon(
                        key: const Key('merchant-verification-refresh'),
                        style: _verificationPrimaryStyle,
                        onPressed: access.busy
                            ? null
                            : () => ref
                                  .read(accessControllerProvider.notifier)
                                  .refreshInPlace(),
                        icon: access.busy
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.refresh),
                        label: Text(AppStrings.refreshStatus),
                      ),
                    ),
                    if (canContactSupport) ...[
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        key: const Key('merchant-verification-support'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.primary),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          textStyle: text.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        onPressed: () => showSupportCompose(context, ref),
                        icon: const Icon(Icons.contact_support_outlined),
                        label: Text(AppStrings.supportContact),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Center(
                      child: TextButton.icon(
                        key: const Key('merchant-verification-logout'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.outlineVariant,
                        ),
                        onPressed: () => ref
                            .read(sessionControllerProvider.notifier)
                            .logout(),
                        icon: const Icon(Icons.logout, size: 18),
                        label: Text(AppStrings.logout),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

final ButtonStyle _verificationPrimaryStyle = FilledButton.styleFrom(
  minimumSize: const Size.fromHeight(56),
  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
  backgroundColor: AppColors.primary,
  foregroundColor: AppColors.onPrimary,
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  textStyle: const TextStyle(
    fontFamily: AppTheme.latinFont,
    fontSize: 16,
    fontWeight: FontWeight.w600,
  ),
);

class _ProgressRow extends StatelessWidget {
  const _ProgressRow({
    required this.done,
    required this.active,
    required this.title,
    required this.subtitle,
    this.isLast = false,
  });

  final bool done;
  final bool active;
  final String title;
  final String? subtitle;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final Color circleColor;
    final Widget icon;
    if (done) {
      circleColor = AppColors.primary;
      icon = const Icon(Icons.check, size: 16, color: AppColors.onPrimary);
    } else if (active) {
      circleColor = AppColors.tertiaryFixed;
      icon = const Icon(Icons.sync, size: 16, color: AppColors.onTertiaryFixed);
    } else {
      circleColor = AppColors.surfaceContainerHigh;
      icon = const Icon(
        Icons.more_horiz,
        size: 16,
        color: AppColors.outlineVariant,
      );
    }
    final waiting = !done && !active;
    final text = Theme.of(context).textTheme;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 24,
            child: Column(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: circleColor,
                    shape: BoxShape.circle,
                    border: active
                        ? Border.all(
                            color: AppColors.tertiaryFixedDim,
                            width: 2,
                          )
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: icon,
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: AppColors.outlineVariant.withValues(alpha: 0.5),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: text.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: waiting
                          ? AppColors.outlineVariant
                          : AppColors.onSurface,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: text.labelMedium?.copyWith(
                        color: active
                            ? AppColors.tertiary
                            : waiting
                            ? AppColors.outlineVariant
                            : AppColors.outline,
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

class _RejectedVerificationBody extends ConsumerWidget {
  const _RejectedVerificationBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final access = ref.watch(accessControllerProvider);
    final membership = access.membership;
    final checklist = membership?.evidenceChecklist ?? const [];
    final reference = membership?.merchantPublicReference.trim() ?? '';
    final merchantName = membership?.merchantName.trim() ?? '';
    final canContactSupport = merchantRoleCanContactSupport(membership?.role);
    final issues = membership?.unresolvedIssues ?? const <VerificationIssue>[];
    final text = Theme.of(context).textTheme;

    return Scaffold(
      key: const Key('merchant-verification-rejected'),
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _VerificationHeader(
            title: AppStrings.brandName,
            trailing: IconButton(
              key: const Key('merchant-verification-refresh'),
              tooltip: AppStrings.refreshStatus,
              color: AppColors.primary,
              onPressed: access.busy
                  ? null
                  : () => ref
                        .read(accessControllerProvider.notifier)
                        .refreshInPlace(),
              icon: access.busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: const BoxDecoration(
                        color: AppColors.errorContainer,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.assignment_late_outlined,
                        size: 40,
                        color: AppColors.error,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    AppStrings.verificationRejectedTitle,
                    textAlign: TextAlign.center,
                    style: text.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurface,
                    ),
                  ),
                  if (merchantName.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      AppStrings.verificationRejectedGreeting(merchantName.toString()),
                      key: const Key('merchant-verification-greeting'),
                      textAlign: TextAlign.center,
                      style: text.bodyMedium?.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                  if (reference.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Center(
                      child: Container(
                        key: const Key('merchant-verification-reference'),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Text(
                              AppStrings.verificationRequestIdLabel,
                              style: text.labelSmall?.copyWith(
                                color: AppColors.onSurfaceVariant,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(height: 4),
                            OrderPublicReferenceLine(
                              reference: reference,
                              label: AppStrings.verificationReferenceFull,
                              openKey: const Key(
                                'merchant-verification-reference-open',
                              ),
                              color: AppColors.primary,
                              iconSize: 18,
                              textStyle: text.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  if (issues.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    VerificationIssuesList(issues: issues),
                  ],
                  if (membership != null &&
                      VerificationDossierInfo.hasData(membership)) ...[
                    const SizedBox(height: 16),
                    VerificationDossierInfo(membership: membership),
                  ],
                  const SizedBox(height: 24),
                  Text(
                    AppStrings.checklistTitle.toUpperCase(),
                    style: text.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurface,
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  for (final item in checklist)
                    _EvidenceRow(item: item, accent: true),
                  const SizedBox(height: 4),
                  Container(
                    key: const Key('merchant-verification-guidance'),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                issues.isNotEmpty
                                    ? AppStrings.issuesFixHint
                                    : AppStrings.regRejectionNoReason,
                                style: text.bodyMedium?.copyWith(
                                  color: AppColors.onSurfaceVariant,
                                ),
                              ),
                              if (membership?.verificationAttentionRequired ==
                                  true) ...[
                                const SizedBox(height: 8),
                                Text(
                                  AppStrings.attentionRequired,
                                  style: text.bodyMedium?.copyWith(
                                    color: AppColors.onSurfaceVariant,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (access.errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      access.errorMessage!,
                      style: const TextStyle(color: AppColors.error),
                    ),
                  ],
                  if (canContactSupport) ...[
                    const SizedBox(height: 24),
                    Text(
                      AppStrings.verificationNeedHelp,
                      textAlign: TextAlign.center,
                      style: text.bodyMedium?.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    Center(
                      child: TextButton.icon(
                        key: const Key('merchant-verification-support'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          textStyle: text.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                        onPressed: () => showSupportCompose(context, ref),
                        icon: const Icon(Icons.support_agent, size: 20),
                        label: Text(AppStrings.supportContact),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.surface.withValues(alpha: 0.95),
              border: Border(
                top: BorderSide(
                  color: AppColors.outlineVariant.withValues(alpha: 0.3),
                ),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    FilledButton.icon(
                      key: const Key('merchant-verification-correct'),
                      style: _verificationPrimaryStyle,
                      onPressed: () => ref
                          .read(accessControllerProvider.notifier)
                          .openRegistrationCorrections(),
                      icon: const Icon(Icons.send_outlined),
                      label: Text(
                        AppStrings.verificationCorrectAndSubmit,
                      ),
                    ),
                    Center(
                      child: TextButton.icon(
                        key: const Key('merchant-verification-logout'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.error,
                        ),
                        onPressed: () => ref
                            .read(sessionControllerProvider.notifier)
                            .logout(),
                        icon: const Icon(Icons.logout, size: 18),
                        label: Text(AppStrings.logout),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LegacyVerificationBody extends ConsumerWidget {
  const _LegacyVerificationBody({required this.kind});

  final AccessDestination kind;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final access = ref.watch(accessControllerProvider);
    final membership = access.membership;
    final checklist = membership?.evidenceChecklist ?? const [];
    final hasMissingRequired = checklist.any(
      (item) => item.required && !item.complete,
    );
    final (title, defaultBody, tone) = switch (kind) {
      AccessDestination.verificationRejected => (
        AppStrings.verificationRejectedTitle,
        AppStrings.verificationRejectedBody,
        StatusTone.error,
      ),
      AccessDestination.verificationSuspended => (
        AppStrings.suspendedTitle,
        AppStrings.suspendedBody,
        StatusTone.error,
      ),
      _ => (
        AppStrings.verificationPendingTitle,
        EvidencePresentation.pendingGuidance(
          verificationSubmitted: membership?.verificationSubmitted == true,
          verificationReady: membership?.verificationReady == true,
          hasMissingRequired: hasMissingRequired,
        ),
        StatusTone.warning,
      ),
    };
    final statusLabel = EvidencePresentation.merchantStatusLabel(
      membership?.merchantStatus,
    );
    return MerchantScaffold(
      title: title,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ListView(
              children: [
                const SizedBox(height: 12),
                MerchantCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        membership?.merchantName ?? '',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      StatusBadge(label: statusLabel, tone: tone),
                      const SizedBox(height: 12),
                      Text(defaultBody),
                      if (membership?.verificationAttentionRequired ==
                          true) ...[
                        const SizedBox(height: 12),
                        Text(AppStrings.attentionRequired),
                      ],
                      if (kind == AccessDestination.verificationRejected) ...[
                        const SizedBox(height: 12),
                        Text(AppStrings.regRejectionNoReason),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  AppStrings.checklistTitle,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                ...checklist.map((item) {
                  final state = EvidencePresentation.itemState(item);
                  final itemTone = switch (state) {
                    'Ajouté' || 'Fourni' => StatusTone.success,
                    'En examen' => StatusTone.info,
                    'Non fourni' => StatusTone.info,
                    _ => StatusTone.warning,
                  };
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: MerchantCard(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  EvidencePresentation.documentTitle(item.type),
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  EvidencePresentation.requirementLabel(
                                    item.required,
                                  ),
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        color: AppColors.onSurfaceVariant,
                                      ),
                                ),
                              ],
                            ),
                          ),
                          StatusBadge(label: state, tone: itemTone),
                        ],
                      ),
                    ),
                  );
                }),
                if (access.errorMessage != null)
                  Text(
                    access.errorMessage!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
              ],
            ),
          ),
          if (kind == AccessDestination.verificationRejected)
            FilledButton(
              key: const Key('merchant-verification-correct'),
              onPressed: () => ref
                  .read(accessControllerProvider.notifier)
                  .openRegistrationCorrections(),
              child: Text(AppStrings.regEdit),
            ),
          const SizedBox(height: 8),
          OutlinedButton(
            key: const Key('merchant-verification-refresh'),
            onPressed: access.busy
                ? null
                : () => ref
                      .read(accessControllerProvider.notifier)
                      .refreshInPlace(),
            child: access.busy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(AppStrings.refreshStatus),
          ),
          TextButton(
            onPressed: () =>
                ref.read(sessionControllerProvider.notifier).logout(),
            child: Text(AppStrings.logout),
          ),
        ],
      ),
    );
  }
}

/// One-time notice after a server-confirmed approval of a merchant this
/// installation previously saw pending/rejected (see [AccessController]).
class VerificationApprovedScreen extends ConsumerWidget {
  const VerificationApprovedScreen({super.key});

  Future<void> _continue(
    BuildContext context,
    WidgetRef ref, {
    String? target,
  }) async {
    final router = GoRouter.of(context);
    final ready = await ref
        .read(accessControllerProvider.notifier)
        .acknowledgeApproval();
    if (!ready || target == null) return;
    if (target == AppRoutes.catalog) {
      router.go(target);
      return;
    }
    router.go(AppRoutes.home);
    router.push(target);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final access = ref.watch(accessControllerProvider);
    final membership = access.membership;
    final text = Theme.of(context).textTheme;
    final needsBranch = membership == null || membershipNeedsBranch(membership);
    final reference = membership?.merchantPublicReference.trim() ?? '';
    final busy = access.busy;

    Widget step({
      required Key key,
      required IconData icon,
      required String title,
      required String body,
      required String target,
    }) {
      final enabled = !needsBranch && !busy;
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Material(
          color: AppColors.surfaceContainerLowest,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppColors.outlineVariant),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            key: key,
            onTap: enabled
                ? () => _continue(context, ref, target: target)
                : null,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      icon,
                      color: enabled ? AppColors.primary : AppColors.outline,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: text.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: enabled
                                ? AppColors.onSurface
                                : AppColors.outline,
                          ),
                        ),
                        Text(
                          needsBranch
                              ? AppStrings.approvedNeedBranchHint
                              : body,
                          style: text.bodyMedium?.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (enabled)
                    const Icon(Icons.chevron_right, color: AppColors.outline),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      key: const Key('merchant-verification-approved'),
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _VerificationHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 32, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 96,
                      height: 96,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.tertiaryFixed,
                        boxShadow: [
                          BoxShadow(color: Color(0x66BBD562), blurRadius: 24),
                        ],
                      ),
                      child: const Icon(
                        Icons.check_circle,
                        size: 48,
                        color: AppColors.tertiary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    AppStrings.approvedTitle,
                    textAlign: TextAlign.center,
                    style: text.headlineLarge?.copyWith(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.6,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppStrings.approvedSubtitle,
                    textAlign: TextAlign.center,
                    style: text.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    AppStrings.approvedBody,
                    textAlign: TextAlign.center,
                    style: text.bodyMedium?.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    key: const Key('merchant-approved-summary'),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.outlineVariant),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x0A000000),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.start,
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  AppStrings.approvedReferenceLabel,
                                  style: text.labelMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 1,
                                    color: AppColors.onSurfaceVariant,
                                  ),
                                ),
                                Text(
                                  membership?.merchantName ?? '—',
                                  key: const Key('merchant-approved-name'),
                                  style: text.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary,
                                  ),
                                ),
                                if (reference.isNotEmpty)
                                  OrderPublicReferenceLine(
                                    reference: reference,
                                    label: AppStrings.approvedReferenceFull,
                                    prefix: '#',
                                    textKey: const Key(
                                      'merchant-approved-reference',
                                    ),
                                    openKey: const Key(
                                      'merchant-approved-reference-open',
                                    ),
                                    textStyle: text.labelMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.outline,
                                    ),
                                  ),
                              ],
                            ),
                            Container(
                              key: const Key('merchant-approved-badge'),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.tertiaryContainer,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.verified,
                                    size: 14,
                                    color: _onTertiaryContainer,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    AppStrings.approvedBadge,
                                    style: text.labelMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: _onTertiaryContainer,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (membership != null &&
                            membership.role.isNotEmpty) ...[
                          const Divider(
                            height: 24,
                            color: AppColors.outlineVariant,
                          ),
                          Row(
                            children: [
                              const Icon(
                                Icons.person_outline,
                                size: 20,
                                color: AppColors.onSurfaceVariant,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  merchantRoleLabel(membership.role),
                                  key: const Key('merchant-approved-role'),
                                  style: text.bodyMedium?.copyWith(
                                    color: AppColors.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (membership != null &&
                      VerificationDossierInfo.hasData(membership)) ...[
                    const SizedBox(height: 16),
                    VerificationDossierInfo(membership: membership),
                  ],
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      AppStrings.approvedStepsTitle,
                      style: text.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  step(
                    key: const Key('merchant-approved-hours'),
                    icon: Icons.schedule,
                    title: AppStrings.approvedHoursTitle,
                    body: AppStrings.approvedHoursBody,
                    target: AppRoutes.openingHours,
                  ),
                  step(
                    key: const Key('merchant-approved-catalog'),
                    icon: Icons.inventory_2_outlined,
                    title: AppStrings.approvedCatalogTitle,
                    body: AppStrings.approvedCatalogBody,
                    target: AppRoutes.catalog,
                  ),
                  step(
                    key: const Key('merchant-approved-alerts'),
                    icon: Icons.notifications_active_outlined,
                    title: AppStrings.approvedAlertsTitle,
                    body: AppStrings.approvedAlertsBody,
                    target: AppRoutes.notificationSettings,
                  ),
                  const SizedBox(height: 16),
                  Container(
                    key: const Key('merchant-approved-note'),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.outlineVariant),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            AppStrings.approvedNotOpenNote,
                            style: text.bodyMedium?.copyWith(
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (access.errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      access.errorMessage!,
                      style: const TextStyle(color: AppColors.error),
                    ),
                  ],
                ],
              ),
            ),
          ),
          DecoratedBox(
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(top: BorderSide(color: AppColors.outlineVariant)),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: FilledButton(
                  key: const Key('merchant-approved-continue'),
                  style: _verificationPrimaryStyle.copyWith(
                    minimumSize: const WidgetStatePropertyAll(
                      Size.fromHeight(52),
                    ),
                  ),
                  onPressed: busy ? null : () => _continue(context, ref),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          needsBranch
                              ? AppStrings.addBranch
                              : AppStrings.approvedContinue,
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

const _onTertiaryContainer = Color(0xFFC7E16D);

class PermissionDeniedScreen extends ConsumerWidget {
  const PermissionDeniedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MerchantScaffold(
      title: AppStrings.accessRestrictedTitle,
      body: Column(
        children: [
          const SizedBox(height: 24),
          Text(AppStrings.accessRestrictedBody),
          const Spacer(),
          FilledButton(
            onPressed: () =>
                ref.read(sessionControllerProvider.notifier).logout(),
            child: Text(AppStrings.logout),
          ),
        ],
      ),
    );
  }
}

class AccessErrorScreen extends ConsumerWidget {
  const AccessErrorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final access = ref.watch(accessControllerProvider);
    return MerchantScaffold(
      title: AppStrings.appName,
      body: ErrorBody(
        message: access.errorMessage ?? AppStrings.networkError,
        onRetry: () => ref.read(accessControllerProvider.notifier).resolve(),
      ),
    );
  }
}

class AccessLoadingScreen extends StatelessWidget {
  const AccessLoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MerchantScaffold(
      title: AppStrings.appName,
      body: LoadingBody(),
    );
  }
}
