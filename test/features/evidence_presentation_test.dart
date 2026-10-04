import 'package:flutter_test/flutter_test.dart';
import 'package:speedygo_merchant_app/features/access/data/models.dart';
import 'package:speedygo_merchant_app/features/access/presentation/evidence_presentation.dart';

void main() {
  test('document titles avoid raw enum codes', () {
    expect(
      EvidencePresentation.documentTitle('BUSINESS_IDENTITY'),
      'Identité de l’activité',
    );
    expect(
      EvidencePresentation.documentTitle('BUSINESS_REGISTRATION'),
      'Enregistrement de l’activité',
    );
    expect(
      EvidencePresentation.documentTitle('SUPPORTING_DOCUMENT'),
      'Document complémentaire',
    );
  });

  test('item states never treat complete/present as administrative Validé', () {
    expect(
      EvidencePresentation.itemState(
        const MerchantEvidenceItem(
          type: 'BUSINESS_IDENTITY',
          required: true,
          present: false,
          complete: false,
        ),
      ),
      'Manquant',
    );
    expect(
      EvidencePresentation.itemState(
        const MerchantEvidenceItem(
          type: 'BUSINESS_IDENTITY',
          required: true,
          present: true,
          complete: false,
          status: 'PENDING',
        ),
      ),
      'Ajouté',
    );
    expect(
      EvidencePresentation.itemState(
        const MerchantEvidenceItem(
          type: 'BUSINESS_IDENTITY',
          required: true,
          present: true,
          complete: true,
          status: 'PENDING',
        ),
      ),
      'Ajouté',
      reason: 'complete=true is technical readiness, not admin approval',
    );
    expect(
      EvidencePresentation.itemState(
        const MerchantEvidenceItem(
          type: 'BUSINESS_IDENTITY',
          required: true,
          present: true,
          complete: true,
          status: 'SUBMITTED',
        ),
      ),
      'En examen',
    );
    expect(
      EvidencePresentation.itemState(
        const MerchantEvidenceItem(
          type: 'BUSINESS_IDENTITY',
          required: true,
          present: true,
          complete: true,
          status: 'SUBMITTED',
        ),
      ),
      isNot('Validé'),
    );
  });

  test(
    'submitted dossier does not mark absent optional as En examen',
    () {
      // Mirrors GET /merchant/me checklist when required docs are SUBMITTED
      // and SUPPORTING_DOCUMENT has no row (present=false, status=null).
      const optionalAbsent = MerchantEvidenceItem(
        type: 'SUPPORTING_DOCUMENT',
        required: false,
        present: false,
        complete: false,
        status: null,
      );
      expect(EvidencePresentation.itemState(optionalAbsent), 'Non fourni');
      expect(
        EvidencePresentation.requirementLabel(optionalAbsent.required),
        'Facultatif',
      );
      expect(EvidencePresentation.itemState(optionalAbsent), isNot('En examen'));
      expect(EvidencePresentation.itemState(optionalAbsent), isNot('Manquant'));

      // Even if a buggy client passed SUBMITTED without present, presence wins.
      expect(
        EvidencePresentation.itemState(
          const MerchantEvidenceItem(
            type: 'SUPPORTING_DOCUMENT',
            required: false,
            present: false,
            complete: false,
            status: 'SUBMITTED',
          ),
        ),
        'Non fourni',
      );

      expect(
        EvidencePresentation.itemState(
          const MerchantEvidenceItem(
            type: 'BUSINESS_IDENTITY',
            required: true,
            present: true,
            complete: true,
            status: 'SUBMITTED',
          ),
        ),
        'En examen',
      );
    },
  );

  test('pending guidance uses verificationSubmitted not PENDING_REVIEW alone',
      () {
    final pendingOnly = EvidencePresentation.pendingGuidance(
      verificationSubmitted: false,
      verificationReady: false,
      hasMissingRequired: false,
    );
    expect(pendingOnly.toLowerCase().contains('transmis'), isFalse);

    final missing = EvidencePresentation.pendingGuidance(
      verificationSubmitted: false,
      verificationReady: false,
      hasMissingRequired: true,
    );
    expect(missing.contains('manquent'), isTrue);
    expect(missing.toLowerCase().contains('transmis'), isFalse);

    final submitted = EvidencePresentation.pendingGuidance(
      verificationSubmitted: true,
      verificationReady: true,
      hasMissingRequired: false,
    );
    expect(submitted.contains('transmis'), isTrue);
  });

  test('merchant status labels are human-readable', () {
    expect(
      EvidencePresentation.merchantStatusLabel('PENDING_REVIEW'),
      'En vérification',
    );
    expect(EvidencePresentation.merchantStatusLabel('REJECTED'), 'À corriger');
  });
}
