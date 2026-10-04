import 'package:speedygo_merchant_app/features/access/data/models.dart';

/// Maps server evidence checklist fields to user-facing copy.
/// Document type codes are SpeedyGo application categories (not statutory names).
class EvidencePresentation {
  const EvidencePresentation._();

  static String documentTitle(String type) {
    switch (type.toUpperCase()) {
      case 'BUSINESS_IDENTITY':
        return 'Identité de l’activité';
      case 'BUSINESS_REGISTRATION':
        return 'Enregistrement de l’activité';
      case 'SUPPORTING_DOCUMENT':
        return 'Document complémentaire';
      default:
        return 'Pièce justificative';
    }
  }

  static String requirementLabel(bool required) =>
      required ? 'Obligatoire' : 'Facultatif';

  /// Document-level labels from contract fields only.
  ///
  /// Backend checklist (read-only):
  /// - `present` = a document row exists for that type
  /// - `status` = that row’s PENDING | SUBMITTED (null when absent)
  /// - `complete` = technical readiness for submit (not admin approval)
  /// - dossier `verificationSubmitted` = required docs are SUBMITTED
  ///
  /// Presence is authoritative over dossier submission: an absent optional
  /// piece stays « Non fourni » even when the dossier is already submitted.
  /// There is no per-document admin-approved flag — never show « Validé ».
  static String itemState(MerchantEvidenceItem item) {
    if (!item.present) {
      return item.required ? 'Manquant' : 'Non fourni';
    }
    final status = (item.status ?? '').toUpperCase();
    if (status == 'SUBMITTED') return 'En examen';
    return 'Ajouté';
  }

  static StatusToneForEvidence toneForItem(MerchantEvidenceItem item) {
    if (!item.present) {
      return item.required
          ? StatusToneForEvidence.warning
          : StatusToneForEvidence.neutral;
    }
    final status = (item.status ?? '').toUpperCase();
    if (status == 'SUBMITTED') return StatusToneForEvidence.info;
    return StatusToneForEvidence.success;
  }

  static String merchantStatusLabel(String? status) {
    switch ((status ?? '').toUpperCase()) {
      case 'PENDING_REVIEW':
        return 'En vérification';
      case 'REJECTED':
        return 'À corriger';
      case 'SUSPENDED':
        return 'Suspendu';
      case 'ACTIVE':
        return 'Approuvé';
      default:
        return 'Statut inconnu';
    }
  }

  /// Uses [verificationSubmitted] (required docs formally SUBMITTED), not
  /// merchant status PENDING_REVIEW alone.
  static String pendingGuidance({
    required bool verificationSubmitted,
    required bool verificationReady,
    required bool hasMissingRequired,
  }) {
    if (verificationSubmitted) {
      return 'Votre dossier a été transmis et est en attente d’examen.';
    }
    if (hasMissingRequired) {
      return 'Votre commerce est enregistré. Des pièces obligatoires manquent encore. '
          'Complétez le dossier puis soumettez-le.';
    }
    if (verificationReady) {
      return 'Les pièces requises sont prêtes. Vous pouvez soumettre le dossier pour examen.';
    }
    return 'Votre commerce est enregistré et en attente de vérification. '
        'Vérifiez que chaque pièce obligatoire est complète avant de soumettre.';
  }
}

enum StatusToneForEvidence { success, warning, info, neutral }
