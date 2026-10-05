import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:speedygo_merchant_app/app/theme/app_theme.dart';
import 'package:speedygo_merchant_app/core/constants/app_strings.dart';
import 'package:speedygo_merchant_app/core/constants/merchant_assets.dart';
import 'package:speedygo_merchant_app/core/navigation/app_routes.dart';
import 'package:speedygo_merchant_app/core/widgets/merchant_primary_button.dart';
import 'package:speedygo_merchant_app/core/widgets/searchable_admin_picker.dart';
import 'package:speedygo_merchant_app/features/access/application/access_controller.dart';
import 'package:speedygo_merchant_app/features/access/application/registration_controller.dart';
import 'package:speedygo_merchant_app/features/access/data/evidence_file_picker.dart';
import 'package:speedygo_merchant_app/features/access/data/geo_models.dart';
import 'package:speedygo_merchant_app/features/access/data/models.dart';
import 'package:speedygo_merchant_app/features/access/presentation/evidence_presentation.dart';
import 'package:speedygo_merchant_app/features/access/presentation/location_picker_screen.dart';
import 'package:speedygo_merchant_app/features/access/presentation/verification_review_widgets.dart';
import 'package:speedygo_merchant_app/features/auth/application/auth_infrastructure.dart';
import 'package:speedygo_merchant_app/features/auth/application/session_controller.dart';
import 'package:speedygo_merchant_app/features/orders/presentation/order_public_reference.dart';

class RegistrationHostScreen extends ConsumerStatefulWidget {
  const RegistrationHostScreen({super.key});

  @override
  ConsumerState<RegistrationHostScreen> createState() =>
      _RegistrationHostScreenState();
}

class _RegistrationHostScreenState
    extends ConsumerState<RegistrationHostScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final access = ref.read(accessControllerProvider);
      ref
          .read(registrationControllerProvider.notifier)
          .hydrateFromAccess(access.membership);
    });
  }

  @override
  Widget build(BuildContext context) {
    final reg = ref.watch(registrationControllerProvider);
    return switch (reg.step) {
      RegistrationStep.account => const _AccountStep(),
      RegistrationStep.activity => const _ActivityStep(),
      RegistrationStep.documents => const _DocumentsStep(),
      RegistrationStep.establishment => const _EstablishmentStep(),
      RegistrationStep.review => const _ReviewStep(),
    };
  }
}

enum _RegProgressStyle { percent, labelled }

class _RegScaffold extends StatelessWidget {
  const _RegScaffold({
    required this.section,
    required this.child,
    this.title,
    this.subtitle,
    this.onBack,
    this.appBarTitle,
    this.appBarTitleColor = AppColors.primary,
    this.appBarActions,
    this.progressStyle = _RegProgressStyle.percent,
    this.stepName,
    this.showProgress = true,
  });

  final int section;
  final String? title;
  final Widget? subtitle;
  final Widget child;
  final VoidCallback? onBack;
  final String? appBarTitle;
  final Color appBarTitleColor;
  final List<Widget>? appBarActions;
  final _RegProgressStyle progressStyle;

  /// Right-hand step name of the labelled progress row.
  final String? stepName;
  final bool showProgress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pct = ((section / 4) * 100).round();
    final labelled = progressStyle == _RegProgressStyle.labelled;
    return Scaffold(
      key: const Key('merchant-registration'),
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        toolbarHeight: 56,
        leading: onBack == null
            ? null
            : IconButton(
                key: const Key('merchant-reg-back'),
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back, color: AppColors.primary),
              ),
        title: Text(
          appBarTitle ?? AppStrings.regTitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleLarge?.copyWith(
            color: appBarTitleColor,
            fontWeight: appBarTitleColor == AppColors.primary
                ? FontWeight.w700
                : FontWeight.w600,
          ),
        ),
        actions: appBarActions,
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (showProgress || title != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (showProgress) ...[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            labelled
                                ? '${AppStrings.regStepOf} $section sur 4'
                                      .toUpperCase()
                                : '${AppStrings.regStepOf} $section sur 4',
                            key: const Key('merchant-reg-step-label'),
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: labelled
                                  ? AppColors.primary
                                  : AppColors.onSurfaceVariant,
                              fontSize: 12,
                              letterSpacing: labelled ? 1 : 0.5,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              labelled ? (stepName ?? '') : '$pct%',
                              textAlign: TextAlign.end,
                              style: labelled
                                  ? theme.textTheme.labelLarge?.copyWith(
                                      color: AppColors.onSurfaceVariant,
                                      fontSize: 12,
                                      fontStyle: FontStyle.italic,
                                    )
                                  : theme.textTheme.labelLarge?.copyWith(
                                      color: AppColors.primary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(99),
                        child: LinearProgressIndicator(
                          value: section / 4,
                          minHeight: 8,
                          backgroundColor: labelled
                              ? AppColors.surfaceContainer
                              : AppColors.surfaceContainerHighest,
                          color: labelled
                              ? AppColors.primaryContainer
                              : AppColors.primary,
                        ),
                      ),
                    ],
                    if (title != null) ...[
                      const SizedBox(height: 16),
                      Text(title!, style: theme.textTheme.headlineMedium),
                    ],
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      subtitle!,
                    ],
                  ],
                ),
              ),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}

/// Sticky footer of the registration references: translucent surface, top
/// border, primary CTA.
class _RegStickyBar extends StatelessWidget {
  const _RegStickyBar({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.85),
            border: const Border(
              top: BorderSide(color: AppColors.outlineVariant),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          child: child,
        ),
      ),
    );
  }
}

/// Tinted section block with a primary icon header (registration reference).
class _RegSection extends StatelessWidget {
  const _RegSection({
    required this.icon,
    required this.title,
    required this.child,
  });

  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _AccountStep extends ConsumerWidget {
  const _AccountStep();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final reg = ref.watch(registrationControllerProvider);
    final phone =
        ref.watch(sessionControllerProvider).verifiedPhone ??
        ref.watch(sessionControllerProvider).pendingPhone ??
        '—';
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: AppColors.onSurfaceVariant,
    );
    final roleHint = switch (reg.intent) {
      RegistrationIntent.owner => AppStrings.regOwnerHint,
      RegistrationIntent.operatorJoinUnsupported => AppStrings.regOperatorHint,
      _ => null,
    };
    return _RegScaffold(
      section: 1,
      appBarTitleColor: AppColors.onSurface,
      progressStyle: _RegProgressStyle.labelled,
      stepName: AppStrings.regAccountTitle,
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
              children: [
                _RegSection(
                  icon: Icons.badge_outlined,
                  title: AppStrings.regRoleLabel,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _RoleCard(
                              key: const Key('merchant-reg-role-owner'),
                              selected: reg.intent == RegistrationIntent.owner,
                              title: AppStrings.regOwner,
                              icon: Icons.account_balance,
                              onTap: () => ref
                                  .read(registrationControllerProvider.notifier)
                                  .setIntent(RegistrationIntent.owner),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _RoleCard(
                              key: const Key('merchant-reg-role-operator'),
                              selected:
                                  reg.intent ==
                                  RegistrationIntent.operatorJoinUnsupported,
                              title: AppStrings.regOperator,
                              icon: Icons.engineering_outlined,
                              onTap: () => ref
                                  .read(registrationControllerProvider.notifier)
                                  .setIntent(
                                    RegistrationIntent.operatorJoinUnsupported,
                                  ),
                            ),
                          ),
                        ],
                      ),
                      if (roleHint != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          roleHint,
                          key: const Key('merchant-reg-role-hint'),
                          style: muted,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                _RegSection(
                  icon: Icons.contact_phone_outlined,
                  title: AppStrings.regContactTitle,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        AppStrings.regBranchPhoneLabel,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Opacity(
                        opacity: 0.8,
                        child: Container(
                          height: 48,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.outlineVariant),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.lock_outline,
                                color: AppColors.onSurfaceVariant,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  phone,
                                  key: const Key('merchant-reg-verified-phone'),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodyLarge,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        AppStrings.regVerifiedPhoneHint,
                        style: muted?.copyWith(fontSize: 11),
                      ),
                      const SizedBox(height: 16),
                      Text(AppStrings.regEmailUnsupported, style: muted),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.info_outline,
                      size: 20,
                      color: AppColors.onSurfaceVariant,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        AppStrings.regConsentUnsupported,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
                if (reg.errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    reg.errorMessage!,
                    key: const Key('merchant-reg-error'),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
              ],
            ),
          ),
          _RegStickyBar(
            child: reg.intent == RegistrationIntent.operatorJoinUnsupported
                ? MerchantPrimaryButton(
                    key: const Key('merchant-reg-open-invitations'),
                    label: AppStrings.regOperatorOpenInvitations,
                    icon: Icons.mark_email_unread_outlined,
                    leadingIcon: true,
                    maxLines: 2,
                    onPressed: () =>
                        context.push(AppRoutes.accessTeamInvitations),
                  )
                : MerchantPrimaryButton(
                    key: const Key('merchant-reg-account-continue'),
                    label: AppStrings.regAccountContinue,
                    icon: Icons.arrow_forward,
                    onPressed: () => ref
                        .read(registrationControllerProvider.notifier)
                        .continueFromAccount(),
                  ),
          ),
        ],
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    super.key,
    required this.selected,
    required this.title,
    required this.icon,
    required this.onTap,
  });

  final bool selected;
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(12);
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected
            ? AppColors.primaryContainer.withValues(alpha: 0.1)
            : AppColors.surfaceContainerLowest,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(
            color: selected ? AppColors.primary : AppColors.outlineVariant,
            width: 2,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          customBorder: RoundedRectangleBorder(borderRadius: radius),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 96),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    color: selected
                        ? AppColors.primary
                        : AppColors.onSurfaceVariant,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: selected
                          ? AppColors.primary
                          : AppColors.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ActivityStep extends ConsumerStatefulWidget {
  const _ActivityStep();

  @override
  ConsumerState<_ActivityStep> createState() => _ActivityStepState();
}

class _ActivityStepState extends ConsumerState<_ActivityStep> {
  late final TextEditingController _name;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(
      text: ref.read(registrationControllerProvider).merchantNameDraft,
    );
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reg = ref.watch(registrationControllerProvider);
    return _RegScaffold(
      section: 2,
      title: AppStrings.regActivityTitle,
      onBack: () => ref
          .read(registrationControllerProvider.notifier)
          .goTo(RegistrationStep.account),
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(AppStrings.regActivityBody),
                const SizedBox(height: 16),
                TextField(
                  key: const Key('merchant-reg-name'),
                  controller: _name,
                  onChanged: (v) => ref
                      .read(registrationControllerProvider.notifier)
                      .updateMerchantNameDraft(v),
                  decoration: InputDecoration(
                    labelText: AppStrings.merchantNameLabel,
                    hintText: AppStrings.merchantNameHint,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  AppStrings.regLegalIdUnsupported,
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(color: AppColors.onSurfaceVariant),
                ),
                if (reg.errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    reg.errorMessage!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: MerchantPrimaryButton(
              key: const Key('merchant-reg-activity-continue'),
              label: AppStrings.regContinue,
              loading: reg.busy,
              onPressed: () => ref
                  .read(registrationControllerProvider.notifier)
                  .saveActivityAndContinue(),
            ),
          ),
        ],
      ),
    );
  }
}

class _DocumentsStep extends ConsumerWidget {
  const _DocumentsStep();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reg = ref.watch(registrationControllerProvider);
    final checklist = reg.membership?.evidenceChecklist ?? const [];
    final types = checklist.isNotEmpty
        ? checklist
        : const [
            MerchantEvidenceItem(
              type: 'BUSINESS_IDENTITY',
              required: true,
              present: false,
              complete: false,
            ),
            MerchantEvidenceItem(
              type: 'BUSINESS_REGISTRATION',
              required: true,
              present: false,
              complete: false,
            ),
            MerchantEvidenceItem(
              type: 'SUPPORTING_DOCUMENT',
              required: false,
              present: false,
              complete: false,
            ),
          ];
    final merchantName = reg.membership?.merchantName.trim() ?? '';

    return _RegScaffold(
      section: 3,
      title: AppStrings.regDocsTitle,
      appBarTitle: AppStrings.regDocsAppBar,
      appBarActions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          // The brand asset is white/lime artwork; it needs a dark tile.
          child: Container(
            width: 40,
            height: 24,
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Image.asset(
              MerchantAssets.logo,
              key: const Key('merchant-reg-docs-logo'),
              fit: BoxFit.contain,
            ),
          ),
        ),
      ],
      subtitle: merchantName.isEmpty
          ? null
          : Text.rich(
              TextSpan(
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(color: AppColors.onSurfaceVariant),
                children: [
                  const TextSpan(text: 'Établissement : '),
                  TextSpan(
                    text: merchantName,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
      onBack: () => ref
          .read(registrationControllerProvider.notifier)
          .goTo(RegistrationStep.activity),
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ...types.map((item) {
                    final local = reg.localEvidence[item.type];
                    final issues = (reg.membership?.currentIssues ?? const [])
                        .where(
                          (i) =>
                              i.isDocument &&
                              !i.isResolved &&
                              i.documentType == item.type,
                        )
                        .map((i) => i.messageFr.trim())
                        .where((m) => m.isNotEmpty)
                        .toList();
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _DocumentCard(
                        item: item,
                        local: local,
                        issueMessages: issues,
                        busy: reg.busy,
                        onPick: () => _pickAndUpload(ref, item.type),
                      ),
                    );
                  }),
                  const SizedBox(height: 12),
                  const _DocsTipsCard(),
                  const SizedBox(height: 16),
                  Text(
                    AppStrings.regDocsFormats,
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: AppColors.onSurfaceVariant),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    key: const Key('merchant-reg-docs-privacy'),
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.security,
                        size: 20,
                        color: AppColors.outline,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          AppStrings.regDocsPrivacy,
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(
                                color: AppColors.onSurfaceVariant,
                                height: 1.5,
                              ),
                        ),
                      ),
                    ],
                  ),
                  if (reg.errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      reg.errorMessage!,
                      key: const Key('merchant-reg-docs-error'),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          _RegStickyBar(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                MerchantPrimaryButton(
                  key: const Key('merchant-reg-docs-continue'),
                  label: AppStrings.regDocsContinueFinal,
                  loading: reg.busy,
                  onPressed: () => ref
                      .read(registrationControllerProvider.notifier)
                      .continueFromDocuments(),
                ),
                const SizedBox(height: 8),
                Text(
                  AppStrings.regDocsRequired,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: AppColors.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickAndUpload(WidgetRef ref, String type) async {
    final notifier = ref.read(registrationControllerProvider.notifier);
    try {
      final picked = await ref.read(evidenceFilePickerProvider).pickEvidence();
      if (picked == null) return;
      final name = picked.filename;
      final lower = name.toLowerCase();
      final contentType = lower.endsWith('.pdf')
          ? 'application/pdf'
          : lower.endsWith('.png')
          ? 'image/png'
          : 'image/jpeg';
      await notifier.uploadAndBindEvidence(
        type: type,
        filename: name,
        contentType: contentType,
        bytes: picked.bytes,
      );
    } on MissingPluginException {
      notifier.reportUiError(AppStrings.regPickerUnavailable);
    } on PlatformException catch (e) {
      notifier.reportUiError(
        e.message?.isNotEmpty == true
            ? e.message!
            : AppStrings.regPickerUnavailable,
      );
    } catch (_) {
      notifier.reportUiError(AppStrings.networkError);
    }
  }
}

class _DocumentCard extends StatelessWidget {
  const _DocumentCard({
    required this.item,
    required this.local,
    required this.busy,
    required this.onPick,
    this.issueMessages = const [],
  });

  final MerchantEvidenceItem item;
  final LocalEvidenceDraft? local;
  final bool busy;

  /// Unresolved rejection messages for this document type.
  final List<String> issueMessages;
  final VoidCallback onPick;

  IconData _typeIcon() {
    switch (item.type.toUpperCase()) {
      case 'BUSINESS_IDENTITY':
        return Icons.badge_outlined;
      case 'BUSINESS_REGISTRATION':
        return Icons.receipt_long_outlined;
      default:
        return Icons.description_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = EvidencePresentation.itemState(item);
    final attached = item.present || (local != null && local!.error == null);
    final highlight = !item.present && item.required;
    final filename = local?.filename;
    final stackAction = MediaQuery.textScalerOf(context).scale(1) >= 1.2;
    final Widget action = attached
        ? IconButton(
            key: Key('merchant-reg-doc-pick-${item.type}'),
            onPressed: busy ? null : onPick,
            tooltip: AppStrings.regReplaceDocument,
            icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
          )
        : FilledButton.icon(
            key: Key('merchant-reg-doc-pick-${item.type}'),
            onPressed: busy ? null : onPick,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.onPrimary,
              elevation: 2,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              minimumSize: const Size(0, 40),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: const StadiumBorder(),
            ),
            icon: const Icon(Icons.add, size: 18),
            label: Text(
              AppStrings.regPickDocument,
              style: Theme.of(context).textTheme.labelLarge
                  ?.copyWith(color: AppColors.onPrimary),
            ),
          );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: highlight
              ? AppColors.primaryContainer
              : AppColors.outlineVariant,
          width: highlight ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.onSurface.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: highlight
                    ? AppColors.primaryFixed
                    : AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.outlineVariant),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(_typeIcon(), color: AppColors.primary, size: 28),
                  if (attached)
                    const Positioned(
                      right: 2,
                      bottom: 2,
                      child: Icon(
                        Icons.check_circle,
                        size: 18,
                        color: AppColors.tertiary,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    EvidencePresentation.documentTitle(item.type),
                    style: Theme.of(context).textTheme.titleMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    EvidencePresentation.requirementLabel(item.required),
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: AppColors.onSurfaceVariant),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        !item.present
                            ? (item.required
                                  ? Icons.upload_file_outlined
                                  : Icons.remove_circle_outline)
                            : Icons.verified_outlined,
                        size: 14,
                        color: !item.present
                            ? (item.required
                                  ? AppColors.primary
                                  : AppColors.onSurfaceVariant)
                            : AppColors.tertiary,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          state,
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(
                                fontSize: 12,
                                color: !item.present
                                    ? (item.required
                                          ? AppColors.primary
                                          : AppColors.onSurfaceVariant)
                                    : state == 'En examen'
                                    ? AppColors.primary
                                    : AppColors.tertiary,
                              ),
                        ),
                      ),
                    ],
                  ),
                  if (filename != null && filename.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Tooltip(
                      message: filename,
                      child: Text(
                        filename,
                        key: Key('merchant-reg-doc-file-${item.type}'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall
                            ?.copyWith(color: AppColors.onSurfaceVariant),
                      ),
                    ),
                  ],
                  for (var i = 0; i < issueMessages.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Row(
                        key: Key('merchant-reg-doc-issue-${item.type}-$i'),
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 2),
                            child: Icon(
                              Icons.error_outline,
                              size: 14,
                              color: AppColors.error,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              issueMessages[i],
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: AppColors.error),
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (local?.uploading == true)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: LinearProgressIndicator(minHeight: 3),
                    ),
                  if (local?.error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        local!.error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  if (stackAction) ...[
                    const SizedBox(height: 8),
                    Align(alignment: Alignment.centerLeft, child: action),
                  ],
                ],
              ),
            ),
            if (!stackAction) ...[const SizedBox(width: 8), action],
          ],
        ),
      ),
    );
  }
}

class _DocsTipsCard extends StatelessWidget {
  const _DocsTipsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.tips_and_updates_outlined,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  AppStrings.regDocsTipsTitle,
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _tipRow(context, Icons.wb_sunny_outlined, AppStrings.regDocsTipLight),
          const SizedBox(height: 12),
          _tipRow(
            context,
            Icons.center_focus_strong_outlined,
            AppStrings.regDocsTipFrame,
          ),
          const SizedBox(height: 12),
          _tipRow(context, Icons.flash_off, AppStrings.regDocsTipFlash),
        ],
      ),
    );
  }

  Widget _tipRow(BuildContext context, IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(icon, size: 20, color: AppColors.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(color: AppColors.onSurfaceVariant),
          ),
        ),
      ],
    );
  }
}

class _EstablishmentStep extends ConsumerStatefulWidget {
  const _EstablishmentStep();

  @override
  ConsumerState<_EstablishmentStep> createState() => _EstablishmentStepState();
}

class _EstablishmentStepState extends ConsumerState<_EstablishmentStep> {
  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _address;

  @override
  void initState() {
    super.initState();
    final reg = ref.read(registrationControllerProvider);
    _name = TextEditingController(text: reg.branchNameDraft);
    _phone = TextEditingController(text: reg.branchPhoneDraft);
    _address = TextEditingController(text: reg.branchAddressDraft);
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _address.dispose();
    super.dispose();
  }

  void _sync() {
    ref
        .read(registrationControllerProvider.notifier)
        .updateBranchDraft(
          name: _name.text,
          phone: _phone.text,
          address: _address.text,
        );
    setState(() {});
  }

  Future<void> _openLocationPicker() async {
    final reg = ref.read(registrationControllerProvider);
    final confirmed = reg.hasValidConfirmedLocation;
    final result = await Navigator.of(context).push<LocationPickResult>(
      MaterialPageRoute(
        builder: (_) => LocationPickerScreen(
          initialLatitude: confirmed
              ? double.tryParse(reg.branchLatDraft)
              : null,
          initialLongitude: confirmed
              ? double.tryParse(reg.branchLngDraft)
              : null,
          branchLabel: _name.text.trim().isEmpty ? null : _name.text.trim(),
          addressHint: _address.text.trim().isEmpty
              ? null
              : _address.text.trim(),
        ),
      ),
    );
    if (!mounted || result == null) return;
    ref
        .read(registrationControllerProvider.notifier)
        .confirmLocationDraft(
          latitude: result.latitude,
          longitude: result.longitude,
        );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final reg = ref.watch(registrationControllerProvider);
    final commerceName = reg.membership?.merchantName.trim() ?? '';

    return _RegScaffold(
      section: 4,
      title: AppStrings.regEstablishmentTitle,
      subtitle: Text(
        AppStrings.regEstablishmentBody,
        style: Theme.of(context).textTheme.bodyMedium
            ?.copyWith(color: AppColors.onSurfaceVariant),
      ),
      onBack: () => ref
          .read(registrationControllerProvider.notifier)
          .goTo(RegistrationStep.documents),
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _EstabSection(
                    icon: Icons.storefront,
                    title: AppStrings.regIdentitySection,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (commerceName.isNotEmpty) ...[
                          Text(
                            AppStrings.regCommerceContext,
                            style: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(color: AppColors.onSurfaceVariant),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            commerceName,
                            key: const Key('merchant-reg-commerce-context'),
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 16),
                        ],
                        Text(
                          AppStrings.regBranchNameFrLabel,
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(color: AppColors.onSurfaceVariant),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          key: const Key('merchant-reg-branch-name'),
                          controller: _name,
                          onChanged: (_) => _sync(),
                          decoration: const InputDecoration(
                            hintText: 'Ex. Dar El Benna — centre-ville',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _EstabSection(
                    icon: Icons.contact_phone_outlined,
                    title: AppStrings.regContactSection,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          AppStrings.regBranchPhoneLabel,
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(color: AppColors.onSurfaceVariant),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          key: const Key('merchant-reg-branch-phone'),
                          controller: _phone,
                          onChanged: (_) => _sync(),
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            prefixText: '+213  ',
                            hintText: '555 12 34 56',
                            helperText: AppStrings.regBranchPhoneHint,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  KeyedSubtree(
                    key: const Key('merchant-reg-category-readonly'),
                    child: _EstabSection(
                      icon: Icons.category_outlined,
                      title: AppStrings.regCategorySection,
                      child: Text(
                        AppStrings.regCategoryReadonly,
                        style: Theme.of(context).textTheme.bodyMedium
                            ?.copyWith(color: AppColors.onSurfaceVariant),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  KeyedSubtree(
                    key: const Key('merchant-reg-location'),
                    child: _EstabSection(
                      icon: Icons.location_on_outlined,
                      title: AppStrings.regAddressSection,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            AppStrings.regAddressGuidance,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: AppColors.onSurfaceVariant),
                          ),
                          const SizedBox(height: 12),
                          _RegAdminLocationFields(
                            wilayaLabel:
                                reg.branchWilayaLabelDraft == null ||
                                    reg.branchWilayaCodeDraft == null
                                ? null
                                : '${reg.branchWilayaCodeDraft} — ${reg.branchWilayaLabelDraft}',
                            communeLabel: reg.branchCommuneLabelDraft,
                            wilayaSelected: reg.branchWilayaCodeDraft != null,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            AppStrings.regAddressExactLabel,
                            style: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(color: AppColors.onSurfaceVariant),
                          ),
                          const SizedBox(height: 6),
                          TextField(
                            key: const Key('merchant-reg-branch-address'),
                            controller: _address,
                            onChanged: (_) => _sync(),
                            maxLines: 2,
                            decoration: const InputDecoration(
                              hintText: 'Numéro et nom de rue',
                              suffixIcon: Icon(
                                Icons.location_on,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            AppStrings.regPickupPlace,
                            style: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(color: AppColors.onSurfaceVariant),
                          ),
                          const SizedBox(height: 8),
                          if (reg.hasValidConfirmedLocation)
                            _ConfirmedLocationCard(
                              branchLabel: _name.text.trim().isEmpty
                                  ? (commerceName.isEmpty ? '—' : commerceName)
                                  : _name.text.trim(),
                              addressLabel: _address.text.trim().isEmpty
                                  ? '—'
                                  : _address.text.trim(),
                              latitude: double.parse(reg.branchLatDraft.trim()),
                              longitude: double.parse(
                                reg.branchLngDraft.trim(),
                              ),
                              onEdit: _openLocationPicker,
                            )
                          else
                            OutlinedButton.icon(
                              key: const Key('merchant-reg-choose-on-map'),
                              onPressed: _openLocationPicker,
                              icon: const Icon(Icons.map_outlined),
                              label: Text(AppStrings.regChooseOnMap),
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size.fromHeight(52),
                                foregroundColor: AppColors.primary,
                                side: const BorderSide(
                                  color: AppColors.primaryContainer,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    key: const Key('merchant-reg-preview'),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD9E2FF).withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.12),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppStrings.regPreviewLabel.toUpperCase(),
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(
                                color: AppColors.primary,
                                fontSize: 12,
                                letterSpacing: 0.8,
                              ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.outlineVariant),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _name.text.trim().isEmpty
                                    ? '—'
                                    : _name.text.trim(),
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              if (commerceName.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  commerceName,
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: AppColors.onSurfaceVariant,
                                      ),
                                ),
                              ],
                              const SizedBox(height: 6),
                              Text(
                                _address.text.trim().isEmpty
                                    ? '—'
                                    : _address.text.trim(),
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: AppColors.onSurfaceVariant,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _phone.text.trim().isEmpty
                                    ? '—'
                                    : '+213 ${_phone.text.trim()}',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              if (reg.hasValidConfirmedLocation) ...[
                                const SizedBox(height: 4),
                                Text(
                                  '${AppStrings.regPickupPlace} : '
                                  '${double.parse(reg.branchLatDraft).toStringAsFixed(5)}, '
                                  '${double.parse(reg.branchLngDraft).toStringAsFixed(5)}',
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: AppColors.onSurfaceVariant,
                                      ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (reg.errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      reg.errorMessage!,
                      key: const Key('merchant-reg-estab-error'),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                  const SizedBox(height: 72),
                ],
              ),
            ),
          ),
          Material(
            color: AppColors.surface,
            elevation: 8,
            shadowColor: AppColors.onSurface.withValues(alpha: 0.12),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: MerchantPrimaryButton(
                key: const Key('merchant-reg-estab-continue'),
                label: AppStrings.regContinue,
                loading: reg.busy,
                onPressed: () => ref
                    .read(registrationControllerProvider.notifier)
                    .saveEstablishmentAndContinue(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfirmedLocationCard extends StatelessWidget {
  const _ConfirmedLocationCard({
    required this.branchLabel,
    required this.addressLabel,
    required this.latitude,
    required this.longitude,
    required this.onEdit,
  });

  final String branchLabel;
  final String addressLabel;
  final double latitude;
  final double longitude;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      key: const Key('merchant-reg-location-confirmed'),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 120,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F3FF),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
              border: Border(
                bottom: BorderSide(
                  color: AppColors.outlineVariant.withValues(alpha: 0.6),
                ),
              ),
            ),
            child: Stack(
              children: [
                const Center(
                  child: Icon(
                    Icons.location_on,
                    color: AppColors.primary,
                    size: 40,
                  ),
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.successWash,
                      borderRadius: BorderRadius.circular(99),
                      border: Border.all(color: AppColors.successOnLight),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.check_circle,
                          size: 16,
                          color: Color(0xFF171E00),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          AppStrings.regLocationConfirmed,
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(
                                fontSize: 12,
                                color: const Color(0xFF171E00),
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        branchLabel,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        addressLabel,
                        style: Theme.of(context).textTheme.bodyMedium
                            ?.copyWith(color: AppColors.onSurfaceVariant),
                      ),
                      Text(
                        '${latitude.toStringAsFixed(5)}, ${longitude.toStringAsFixed(5)}',
                        key: const Key('merchant-reg-confirmed-coords'),
                        style: Theme.of(context).textTheme.bodySmall
                            ?.copyWith(color: AppColors.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                TextButton.icon(
                  key: const Key('merchant-reg-location-edit'),
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_location_alt_outlined, size: 18),
                  label: Text(AppStrings.regLocationEdit),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EstabSection extends StatelessWidget {
  const _EstabSection({
    required this.icon,
    required this.title,
    required this.child,
  });

  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: AppColors.onSurface.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(icon, color: AppColors.primary, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

class _ReviewStep extends ConsumerWidget {
  const _ReviewStep();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final reg = ref.watch(registrationControllerProvider);
    final session = ref.watch(sessionControllerProvider);
    final m = reg.membership;
    final branch = m?.branches.isNotEmpty == true ? m!.branches.first : null;
    final checklist = m?.evidenceChecklist ?? const <MerchantEvidenceItem>[];
    final missing = <String>[];
    if (m == null || m.merchantName.isEmpty) {
      missing.add('Nom du commerce');
    }
    for (final e in checklist) {
      if (e.required && !e.complete) {
        missing.add(EvidencePresentation.documentTitle(e.type));
      }
    }
    if (branch == null) missing.add('Établissement');
    final notifier = ref.read(registrationControllerProvider.notifier);
    final phone = session.verifiedPhone ?? session.pendingPhone;
    final located =
        branch != null && (branch.latitude != 0 || branch.longitude != 0);
    final place = [
      branch?.communeNameFr,
      branch?.wilayaNameFr,
    ].whereType<String>().where((v) => v.trim().isNotEmpty).join(', ');
    final correcting = m?.merchantStatus.toUpperCase() == 'REJECTED';
    final reference = m?.merchantPublicReference.trim() ?? '';
    final issues = m?.unresolvedIssues ?? const <VerificationIssue>[];

    return _RegScaffold(
      section: 4,
      showProgress: false,
      appBarTitle: correcting
          ? AppStrings.regCorrectionTitle
          : AppStrings.regReviewTitle,
      onBack: () => notifier.goTo(RegistrationStep.establishment),
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                if (correcting)
                  Column(
                    key: const Key('merchant-reg-correction-intro'),
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.info_outline,
                            size: 20,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            AppStrings.regCorrectionActionRequired,
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        AppStrings.regCorrectionIntro(m?.merchantName.trim().ifEmpty('—') ?? '—',
                        ),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.onSurface,
                        ),
                      ),
                    ],
                  )
                else
                  Container(
                    key: const Key('merchant-reg-review-info'),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.primaryContainer.withValues(
                          alpha: 0.2,
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
                            AppStrings.regReviewBody,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (correcting && issues.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  VerificationIssuesList(
                    issues: issues,
                    onReplaceDocument: (_) =>
                        notifier.goTo(RegistrationStep.documents),
                  ),
                ],
                const SizedBox(height: 24),
                _ReviewSection(
                  key: const Key('merchant-reg-review-commerce'),
                  title: AppStrings.regActivityTitle,
                  onEdit: () => notifier.goTo(RegistrationStep.activity),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _ReviewField(
                        label: AppStrings.merchantNameLabel,
                        value: m?.merchantName.isNotEmpty == true
                            ? m!.merchantName
                            : '—',
                      ),
                      if (phone != null) ...[
                        const Divider(height: 24),
                        _ReviewField(
                          label: AppStrings.regVerifiedPhone,
                          value: phone,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                _ReviewSection(
                  key: const Key('merchant-reg-review-docs'),
                  title: AppStrings.regReviewDocsTitle,
                  onEdit: () => notifier.goTo(RegistrationStep.documents),
                  plain: true,
                  child: _ReviewDocsGrid(items: checklist),
                ),
                const SizedBox(height: 24),
                _ReviewSection(
                  key: const Key('merchant-reg-review-branch'),
                  title: AppStrings.regReviewBranchTitle,
                  onEdit: () => notifier.goTo(RegistrationStep.establishment),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _ReviewField(
                        label: AppStrings.branchNameLabel,
                        value: branch?.name.isNotEmpty == true
                            ? branch!.name
                            : '—',
                      ),
                      const SizedBox(height: 16),
                      _ReviewField(
                        label: AppStrings.regBranchPhoneLabel,
                        value: branch?.phone.isNotEmpty == true
                            ? branch!.phone
                            : '—',
                      ),
                      const SizedBox(height: 16),
                      _ReviewField(
                        label: AppStrings.regReviewLocation,
                        value: [
                          if (branch?.addressText.isNotEmpty == true)
                            branch!.addressText,
                          if (place.isNotEmpty) place,
                        ].join('\n').ifEmpty('—'),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        key: const Key('merchant-reg-review-position'),
                        children: [
                          Icon(
                            located
                                ? Icons.check_circle
                                : Icons.location_off_outlined,
                            size: 18,
                            color: located
                                ? AppColors.primary
                                : AppColors.onSurfaceVariant,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              located
                                  ? AppStrings.regLocationConfirmed
                                  : AppStrings.regLocationRequired,
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: located
                                    ? AppColors.primary
                                    : AppColors.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (missing.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Container(
                    key: const Key('merchant-reg-review-missing'),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.errorContainer.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.error_outline,
                              color: AppColors.error,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                AppStrings.regMissingSteps,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        for (final item in missing)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              '• $item',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
                if (correcting) ...[
                  const SizedBox(height: 24),
                  Container(
                    key: const Key('merchant-reg-correction-summary'),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primaryFixed.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.storefront_outlined,
                            size: 20,
                            color: AppColors.onPrimary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppStrings.regCorrectionDetails,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: AppColors.onSurface,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                '${AppStrings.merchantNameLabel} : '
                                '${m?.merchantName.trim().ifEmpty('—') ?? '—'}',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: AppColors.onSurfaceVariant,
                                ),
                              ),
                              if (reference.isNotEmpty)
                                OrderPublicReferenceLine(
                                  reference: reference,
                                  label: AppStrings.verificationReferenceFull,
                                  prefix:
                                      '${AppStrings.verificationReferenceLabel} : ',
                                  openKey: const Key(
                                    'merchant-reg-correction-reference-open',
                                  ),
                                  maxLines: 2,
                                  textStyle: theme.textTheme.bodyMedium
                                      ?.copyWith(
                                        color: AppColors.onSurfaceVariant,
                                      ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                const LegalConsentSection(),
                if (reg.errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    reg.errorMessage!,
                    key: const Key('merchant-reg-review-error'),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
              ],
            ),
          ),
          _RegStickyBar(
            child: MerchantPrimaryButton(
              key: const Key('merchant-reg-submit'),
              label: correcting
                  ? AppStrings.regCorrectionSubmit
                  : AppStrings.regSubmit,
              maxLines: 2,
              icon: Icons.send_outlined,
              leadingIcon: true,
              loading: reg.busy,
              onPressed:
                  missing.isNotEmpty ||
                      m?.verificationReady != true ||
                      !reg.consentsComplete
                  ? null
                  : () => notifier.submitForReview(),
            ),
          ),
        ],
      ),
    );
  }
}

extension on String {
  String ifEmpty(String fallback) => isEmpty ? fallback : this;
}

class _ReviewSection extends StatelessWidget {
  const _ReviewSection({
    super.key,
    required this.title,
    required this.onEdit,
    required this.child,
    this.plain = false,
  });

  final String title;
  final VoidCallback onEdit;
  final Widget child;

  /// Renders [child] without the white card (document grid has its own).
  final bool plain;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            TextButton.icon(
              onPressed: onEdit,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                textStyle: theme.textTheme.labelLarge,
              ),
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: Text(AppStrings.regEdit),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (plain)
          child
        else
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            child: child,
          ),
      ],
    );
  }
}

class _ReviewField extends StatelessWidget {
  const _ReviewField({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: theme.textTheme.labelMedium?.copyWith(
            color: AppColors.outline,
            letterSpacing: 0.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _ReviewDocsGrid extends StatelessWidget {
  const _ReviewDocsGrid({required this.items});

  final List<MerchantEvidenceItem> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final stacked = MediaQuery.textScalerOf(context).scale(1) >= 1.25;
    final cards = [
      for (final e in items)
        Container(
          key: Key('merchant-reg-review-doc-${e.type}'),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                EvidencePresentation.documentTitle(e.type).toUpperCase(),
                style: theme.textTheme.labelMedium?.copyWith(
                  color: AppColors.outline,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 12),
              _ReviewDocChip(item: e),
            ],
          ),
        ),
    ];
    if (cards.isEmpty) return const SizedBox.shrink();
    if (stacked) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < cards.length; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            cards[i],
          ],
        ],
      );
    }
    final rows = <Widget>[];
    for (var i = 0; i < cards.length; i += 2) {
      rows.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: cards[i]),
              const SizedBox(width: 12),
              Expanded(
                child: i + 1 < cards.length
                    ? cards[i + 1]
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < rows.length; i++) ...[
          if (i > 0) const SizedBox(height: 12),
          rows[i],
        ],
      ],
    );
  }
}

class _ReviewDocChip extends StatelessWidget {
  const _ReviewDocChip({required this.item});

  final MerchantEvidenceItem item;

  @override
  Widget build(BuildContext context) {
    final state = EvidencePresentation.itemState(item);
    final missingRequired = item.required && !item.present;
    final (IconData icon, Color bg, Color fg) = item.present
        ? (
            Icons.check_circle,
            AppColors.primaryContainer.withValues(alpha: 0.1),
            AppColors.primary,
          )
        : missingRequired
        ? (Icons.error_outline, AppColors.errorContainer, AppColors.error)
        : (
            Icons.remove_circle_outline,
            AppColors.surfaceContainerHigh,
            AppColors.onSurfaceVariant,
          );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: fg),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              state,
              style: Theme.of(context).textTheme.labelMedium
                  ?.copyWith(color: fg, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _RegAdminLocationFields extends ConsumerStatefulWidget {
  const _RegAdminLocationFields({
    required this.wilayaLabel,
    required this.communeLabel,
    required this.wilayaSelected,
  });

  final String? wilayaLabel;
  final String? communeLabel;
  final bool wilayaSelected;

  @override
  ConsumerState<_RegAdminLocationFields> createState() =>
      _RegAdminLocationFieldsState();
}

class _RegAdminLocationFieldsState
    extends ConsumerState<_RegAdminLocationFields> {
  List<AlgeriaWilaya> _wilayas = const [];
  List<AlgeriaCommune> _communes = const [];
  var _wilayasLoading = false;
  var _communesLoading = false;
  String? _error;
  int _communesRequestId = 0;
  String? _loadedWilayaCode;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _ensureWilayas());
  }

  Future<void> _ensureWilayas() async {
    if (_wilayas.isNotEmpty || _wilayasLoading) return;
    setState(() {
      _wilayasLoading = true;
      _error = null;
    });
    try {
      final list = await ref.read(merchantApiProvider).listWilayas();
      if (!mounted) return;
      setState(() {
        _wilayas = list;
        _wilayasLoading = false;
      });
      final code = ref
          .read(registrationControllerProvider)
          .branchWilayaCodeDraft;
      if (code != null && code.isNotEmpty) {
        await _ensureCommunes(code);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _wilayasLoading = false;
        _error = AppStrings.adminLocationLoadError;
      });
    }
  }

  Future<void> _ensureCommunes(String wilayaCode) async {
    if (_loadedWilayaCode == wilayaCode && _communes.isNotEmpty) return;
    final requestId = ++_communesRequestId;
    setState(() {
      _communesLoading = true;
      _error = null;
      _communes = const [];
    });
    try {
      final list = await ref
          .read(merchantApiProvider)
          .listCommunes(wilayaCode: wilayaCode);
      if (!mounted || requestId != _communesRequestId) return;
      setState(() {
        _communes = list;
        _communesLoading = false;
        _loadedWilayaCode = wilayaCode;
      });
    } catch (_) {
      if (!mounted || requestId != _communesRequestId) return;
      setState(() {
        _communesLoading = false;
        _error = AppStrings.adminLocationLoadError;
      });
    }
  }

  Future<void> _pickWilaya() async {
    await _ensureWilayas();
    if (!mounted || _wilayas.isEmpty) return;
    final picked = await showSearchableAdminPicker<AlgeriaWilaya>(
      context: context,
      title: AppStrings.storeAddressWilaya,
      options: _wilayas,
      labelOf: (w) => w.displayLabel,
      searchTextOf: (w) => '${w.code} ${w.nameFr} ${w.nameAr}',
    );
    if (!mounted || picked == null) return;
    ref
        .read(registrationControllerProvider.notifier)
        .setWilayaDraft(code: picked.code, label: picked.nameFr);
    setState(() {
      _communes = const [];
      _loadedWilayaCode = null;
    });
    await _ensureCommunes(picked.code);
  }

  Future<void> _pickCommune() async {
    final code = ref.read(registrationControllerProvider).branchWilayaCodeDraft;
    if (code == null || code.isEmpty) {
      setState(() => _error = AppStrings.adminLocationWilayaRequired);
      return;
    }
    await _ensureCommunes(code);
    if (!mounted || _communes.isEmpty) return;
    final picked = await showSearchableAdminPicker<AlgeriaCommune>(
      context: context,
      title: AppStrings.storeAddressCommune,
      options: _communes,
      labelOf: (c) => c.displayLabel,
      searchTextOf: (c) => '${c.nameFr} ${c.nameAr} ${c.aliasesFr.join(' ')}',
    );
    if (!mounted || picked == null) return;
    ref
        .read(registrationControllerProvider.notifier)
        .setCommuneDraft(id: picked.id, label: picked.nameFr);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _error!,
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: AppColors.error),
                  ),
                ),
                TextButton(
                  onPressed: _wilayasLoading ? null : _ensureWilayas,
                  child: Text(AppStrings.adminLocationRetry),
                ),
              ],
            ),
          ),
        AdminLocationSelectField(
          key: const Key('merchant-reg-wilaya'),
          label: AppStrings.storeAddressWilaya,
          valueText: widget.wilayaLabel,
          enabled: !_wilayasLoading,
          onTap: _pickWilaya,
          hint: _wilayasLoading
              ? AppStrings.loading
              : AppStrings.adminLocationChoose,
        ),
        const SizedBox(height: 12),
        AdminLocationSelectField(
          key: const Key('merchant-reg-commune'),
          label: AppStrings.storeAddressCommune,
          valueText: widget.communeLabel,
          enabled: widget.wilayaSelected && !_communesLoading,
          onTap: _pickCommune,
          hint: !widget.wilayaSelected
              ? AppStrings.adminLocationWilayaRequired
              : (_communesLoading
                    ? AppStrings.loading
                    : AppStrings.adminLocationChoose),
        ),
      ],
    );
  }
}
