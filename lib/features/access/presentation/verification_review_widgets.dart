import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speedygo_merchant_app/app/theme/app_theme.dart';
import 'package:speedygo_merchant_app/core/constants/app_strings.dart';
import 'package:speedygo_merchant_app/features/access/application/registration_controller.dart';
import 'package:speedygo_merchant_app/features/access/data/models.dart';
import 'package:speedygo_merchant_app/features/access/presentation/evidence_presentation.dart';

/// `dd/MM/yyyy HH:mm` in local time; null when [iso] is missing or invalid.
String? formatDossierDate(String? iso) {
  if (iso == null || iso.isEmpty) return null;
  final parsed = DateTime.tryParse(iso)?.toLocal();
  if (parsed == null) return null;
  String two(int v) => v.toString().padLeft(2, '0');
  return '${two(parsed.day)}/${two(parsed.month)}/${parsed.year} '
      '${two(parsed.hour)}:${two(parsed.minute)}';
}

/// Required consents (terms + dossier accuracy declaration) shown before the
/// dossier is submitted. Versions come from the backend; nothing is hardcoded.
class LegalConsentSection extends ConsumerStatefulWidget {
  const LegalConsentSection({super.key});

  @override
  ConsumerState<LegalConsentSection> createState() =>
      _LegalConsentSectionState();
}

class _LegalConsentSectionState extends ConsumerState<LegalConsentSection> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(registrationControllerProvider.notifier).loadLegal();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reg = ref.watch(registrationControllerProvider);
    final notifier = ref.read(registrationControllerProvider.notifier);
    final legal = reg.legal;

    Widget body;
    if (legal == null) {
      body = reg.legalLoading
          ? Row(
              key: const Key('merchant-legal-loading'),
              children: [
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    AppStrings.legalLoading,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            )
          : _LegalRetry(
              message: AppStrings.legalLoadFailed,
              onRetry: () => notifier.loadLegal(force: true),
            );
    } else if (!legal.isComplete) {
      body = _LegalRetry(
        message: AppStrings.legalIncomplete,
        onRetry: reg.legalLoading
            ? null
            : () => notifier.loadLegal(force: true),
      );
    } else {
      final enabled = !reg.busy;
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ConsentTile(
            tileKey: const Key('merchant-legal-terms'),
            checked: reg.termsAccepted,
            label: AppStrings.legalTermsLabel,
            version: legal.terms!,
            onChanged: enabled ? notifier.setTermsAccepted : null,
          ),
          const SizedBox(height: 8),
          _ConsentTile(
            tileKey: const Key('merchant-legal-declaration'),
            checked: reg.declarationAccepted,
            label: AppStrings.legalDeclarationLabel,
            version: legal.declaration!,
            onChanged: enabled ? notifier.setDeclarationAccepted : null,
          ),
          if (!reg.consentsComplete) ...[
            const SizedBox(height: 8),
            Text(
              AppStrings.legalConsentHint,
              key: const Key('merchant-legal-hint'),
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ],
      );
    }

    return Container(
      key: const Key('merchant-legal-section'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.gavel_outlined, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  AppStrings.legalSectionTitle,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            AppStrings.legalSectionBody,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          body,
        ],
      ),
    );
  }
}

class _LegalRetry extends StatelessWidget {
  const _LegalRetry({required this.message, required this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const Key('merchant-legal-unavailable'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(message, style: const TextStyle(color: AppColors.error)),
        TextButton.icon(
          key: const Key('merchant-legal-retry'),
          onPressed: onRetry,
          icon: const Icon(Icons.refresh, size: 18),
          label: const Text(AppStrings.legalRetry),
        ),
      ],
    );
  }
}

class _ConsentTile extends StatelessWidget {
  const _ConsentTile({
    required this.tileKey,
    required this.checked,
    required this.label,
    required this.version,
    required this.onChanged,
  });

  final Key tileKey;
  final bool checked;
  final String label;
  final LegalVersion version;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final url = version.contentUrl;
    final showUrl = url != null && RegExp(r'^https?://').hasMatch(url);
    return Material(
      color: checked
          ? AppColors.primaryContainer.withValues(alpha: 0.08)
          : AppColors.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: checked ? AppColors.primary : AppColors.outlineVariant,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: CheckboxListTile(
        key: tileKey,
        value: checked,
        onChanged: onChanged == null ? null : (v) => onChanged!(v == true),
        controlAffinity: ListTileControlAffinity.leading,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(label, style: theme.textTheme.bodyMedium),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppStrings.legalVersionTag(version.version),
              style: theme.textTheme.labelMedium?.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
            if (showUrl)
              Text(
                '${AppStrings.legalContentLink} : $url',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppColors.outline,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Structured rejection issues: APPLICATION issues first, then DOCUMENT
/// issues pointing at the document type to re-upload.
class VerificationIssuesList extends StatelessWidget {
  const VerificationIssuesList({
    super.key,
    required this.issues,
    this.onReplaceDocument,
  });

  final List<VerificationIssue> issues;

  /// When set, document issues get a shortcut to the upload step.
  final ValueChanged<String>? onReplaceDocument;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final application = issues.where((i) => !i.isDocument).toList();
    final documents = issues.where((i) => i.isDocument).toList();
    final remaining = issues.where((i) => !i.isResolved).length;

    return Container(
      key: const Key('merchant-issues-list'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.errorContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.error_outline, color: AppColors.error, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  AppStrings.issuesTitle,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            AppStrings.issuesRemaining(remaining),
            key: const Key('merchant-issues-count'),
            style: theme.textTheme.labelLarge?.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
          if (application.isNotEmpty) ...[
            const SizedBox(height: 16),
            const _GroupTitle(
              key: Key('merchant-issues-application-title'),
              text: AppStrings.issuesApplicationTitle,
            ),
            for (var i = 0; i < application.length; i++)
              _IssueRow(
                key: Key('merchant-issue-application-$i'),
                issue: application[i],
              ),
          ],
          if (documents.isNotEmpty) ...[
            const SizedBox(height: 16),
            const _GroupTitle(
              key: Key('merchant-issues-document-title'),
              text: AppStrings.issuesDocumentTitle,
            ),
            for (var i = 0; i < documents.length; i++)
              _IssueRow(
                key: Key('merchant-issue-document-$i'),
                issue: documents[i],
                onReplaceDocument: documents[i].isResolved
                    ? null
                    : onReplaceDocument,
              ),
          ],
        ],
      ),
    );
  }
}

class _GroupTitle extends StatelessWidget {
  const _GroupTitle({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        text.toUpperCase(),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: AppColors.outline,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

class _IssueRow extends StatelessWidget {
  const _IssueRow({super.key, required this.issue, this.onReplaceDocument});

  final VerificationIssue issue;
  final ValueChanged<String>? onReplaceDocument;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final type = issue.documentType;
    final message = issue.messageFr.trim().isEmpty
        ? AppStrings.regRejectionNoReason
        : issue.messageFr.trim();
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(
              issue.isResolved ? Icons.check_circle : Icons.circle,
              size: issue.isResolved ? 16 : 8,
              color: issue.isResolved ? AppColors.tertiary : AppColors.error,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.onSurface,
                    decoration: issue.isResolved
                        ? TextDecoration.lineThrough
                        : null,
                  ),
                ),
                if (issue.isDocument && type != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    AppStrings.issuesDocumentConcerned(
                      EvidencePresentation.documentTitle(type),
                    ),
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: AppColors.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (onReplaceDocument != null)
                    TextButton.icon(
                      key: Key('merchant-issue-replace-$type'),
                      onPressed: () => onReplaceDocument!(type),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 36),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        alignment: Alignment.centerLeft,
                      ),
                      icon: const Icon(Icons.upload_file_outlined, size: 18),
                      label: const Text(AppStrings.issuesReplaceDocument),
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

/// Read-only dossier timeline: attempt, submission, review and the consent
/// recorded with the latest submission. Only server-provided values.
class VerificationDossierInfo extends StatelessWidget {
  const VerificationDossierInfo({super.key, required this.membership});

  final MerchantMembership membership;

  static bool hasData(MerchantMembership m) =>
      m.attemptNumber != null ||
      formatDossierDate(m.submittedAt) != null ||
      formatDossierDate(m.reviewedAt) != null ||
      m.legalAcceptance != null;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final m = membership;
    final submitted = formatDossierDate(m.submittedAt);
    final reviewed = formatDossierDate(m.reviewedAt);
    final acceptance = m.legalAcceptance;
    final acceptedAt = formatDossierDate(acceptance?.acceptedAt);

    Widget row(Key key, String label, String value) => Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        key: key,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            flex: 6,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    return Container(
      key: const Key('merchant-dossier-info'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            AppStrings.regCorrectionDetails,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          if (m.attemptNumber != null)
            row(
              const Key('merchant-dossier-attempt'),
              AppStrings.dossierAttemptLabel,
              '${m.attemptNumber}',
            ),
          if (submitted != null)
            row(
              const Key('merchant-dossier-submitted-at'),
              AppStrings.dossierSubmittedAtLabel,
              submitted,
            ),
          if (reviewed != null)
            row(
              const Key('merchant-dossier-reviewed-at'),
              AppStrings.dossierReviewedAtLabel,
              reviewed,
            ),
          if (acceptance != null)
            row(
              const Key('merchant-dossier-consent'),
              AppStrings.dossierConsentLabel,
              [
                AppStrings.dossierConsentVersions(
                  acceptance.termsVersion,
                  acceptance.declarationVersion,
                ),
                ?acceptedAt,
              ].join('\n'),
            ),
        ],
      ),
    );
  }
}
