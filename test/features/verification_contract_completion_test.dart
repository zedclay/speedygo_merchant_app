import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speedygo_merchant_app/app/app.dart';
import 'package:speedygo_merchant_app/core/constants/app_strings.dart';
import 'package:speedygo_merchant_app/core/errors/app_exception.dart';
import 'package:speedygo_merchant_app/features/access/application/registration_controller.dart';
import 'package:speedygo_merchant_app/features/access/data/models.dart';
import 'package:speedygo_merchant_app/features/access/presentation/verification_review_widgets.dart';

import 'phase1_flow_test.dart';
import 'registration_flow_test.dart' show authedContainer, settle;

const _readyDocs = [
  MerchantEvidenceItem(
    type: 'BUSINESS_IDENTITY',
    required: true,
    present: true,
    complete: true,
    status: 'SUBMITTED',
  ),
  MerchantEvidenceItem(
    type: 'BUSINESS_REGISTRATION',
    required: true,
    present: true,
    complete: true,
    status: 'SUBMITTED',
  ),
];

const _applicationIssue = VerificationIssue(
  scope: 'APPLICATION',
  code: 'MERCHANT_NAME_MISMATCH',
  messageFr: 'Le nom du commerce ne correspond pas au registre.',
);

const _documentIssue = VerificationIssue(
  scope: 'DOCUMENT',
  code: 'DOCUMENT_ILLEGIBLE',
  messageFr: 'Le document est illisible.',
  documentType: 'BUSINESS_IDENTITY',
);

LegalCurrent _legal({String terms = 'terms-v3', String declaration = 'decl-v2'}) =>
    LegalCurrent(
      versions: [
        LegalVersion(
          kind: LegalKind.merchantTerms,
          version: terms,
          contentUrl: 'https://speedygo.example/terms',
        ),
        LegalVersion(
          kind: LegalKind.dossierAccuracyDeclaration,
          version: declaration,
        ),
      ],
    );

MerchantMembership _readyToSubmit() => membership(
  status: 'PENDING_REVIEW',
  approved: false,
  operationalReady: false,
  verificationReady: true,
  verificationSubmitted: false,
  branches: [branch('b1')],
  evidenceChecklist: _readyDocs,
);

MerchantMembership _rejected({
  List<VerificationIssue> issues = const [_applicationIssue, _documentIssue],
}) => membership(
  status: 'REJECTED',
  approved: false,
  operationalReady: false,
  verificationReady: true,
  verificationSubmitted: true,
  branches: [branch('b1')],
  evidenceChecklist: _readyDocs,
  attemptNumber: 2,
  submittedAt: '2026-10-01T09:30:00Z',
  reviewedAt: '2026-10-02T14:05:00Z',
  currentIssues: issues,
);

FakeMerchantApi _serverWith(MerchantMembership m) => FakeMerchantApi(
  meHandler: () async =>
      MerchantMe(merchantMembershipExists: true, memberships: [m]),
)..legalCurrentHandler = () async => _legal();

Future<void> _pumpApp(WidgetTester tester, ProviderContainer container) async {
  tester.view.physicalSize = const Size(800, 3200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const SpeedyGoApp(),
    ),
  );
  await settle(tester);
}

bool _submitEnabled(WidgetTester tester) {
  final button = tester.widget<FilledButton>(
    find.descendant(
      of: find.byKey(const Key('merchant-reg-submit')),
      matching: find.byType(FilledButton),
    ),
  );
  return button.onPressed != null;
}

Future<void> _tap(WidgetTester tester, Key key) async {
  await tester.ensureVisible(find.byKey(key));
  await tester.tap(find.byKey(key));
  await settle(tester, n: 10);
}

void main() {
  group('models', () {
    test('membership parses submission, consent and issues', () {
      final m = MerchantMembership.fromJson({
        'merchantId': 'm-1',
        'role': 'OWNER',
        'merchant': {'name': 'Finjan', 'status': 'REJECTED'},
        'submittedAt': '2026-10-01T09:30:00Z',
        'reviewedAt': '2026-10-02T14:05:00Z',
        'attemptNumber': 2,
        'legalAcceptance': {
          'termsVersion': 'terms-v3',
          'declarationVersion': 'decl-v2',
          'acceptedAt': '2026-10-01T09:29:00Z',
        },
        'currentIssues': [
          {
            'scope': 'DOCUMENT',
            'code': 'DOCUMENT_ILLEGIBLE',
            'messageFr': 'Le document est illisible.',
            'documentType': 'BUSINESS_IDENTITY',
          },
          {
            'scope': 'APPLICATION',
            'code': 'X',
            'messageFr': 'Déjà corrigé.',
            'resolvedAt': '2026-10-03T08:00:00Z',
          },
        ],
        'unresolvedIssueCount': 1,
      });
      expect(m.attemptNumber, 2);
      expect(m.legalAcceptance?.termsVersion, 'terms-v3');
      expect(m.legalAcceptance?.declarationVersion, 'decl-v2');
      expect(m.currentIssues, hasLength(2));
      expect(m.currentIssues.first.isDocument, isTrue);
      expect(m.currentIssues.first.documentType, 'BUSINESS_IDENTITY');
      expect(m.unresolvedIssues, hasLength(1));
      expect(m.unresolvedIssueCount, 1);
    });

    test('legacy membership without new fields parses to empty values', () {
      final m = MerchantMembership.fromJson({
        'merchantId': 'm-1',
        'role': 'MANAGER',
        'merchant': {'name': 'Finjan', 'status': 'ACTIVE'},
        'legalAcceptance': null,
      });
      expect(m.submittedAt, isNull);
      expect(m.attemptNumber, isNull);
      expect(m.legalAcceptance, isNull);
      expect(m.currentIssues, isEmpty);
      expect(m.unresolvedIssueCount, 0);
    });

    test('legal current exposes both kinds and builds acceptances', () {
      final legal = LegalCurrent.fromJson({
        'versions': [
          {
            'kind': 'MERCHANT_TERMS',
            'version': 'terms-v3',
            'contentUrl': 'https://x/terms',
            'contentSha256': 'abc',
            'effectiveFrom': '2026-10-01T00:00:00Z',
          },
          {'kind': 'DOSSIER_ACCURACY_DECLARATION', 'version': 'decl-v2'},
        ],
      });
      expect(legal.isComplete, isTrue);
      expect(legal.terms!.toAcceptance().toJson(), {
        'kind': 'MERCHANT_TERMS',
        'version': 'terms-v3',
      });
      expect(
        const LegalCurrent(
          versions: [LegalVersion(kind: 'MERCHANT_TERMS', version: 'v1')],
        ).isComplete,
        isFalse,
      );
    });
  });

  group('consent gating', () {
    testWidgets('submit stays disabled until both consents are ticked', (
      tester,
    ) async {
      final merchant = _serverWith(_readyToSubmit());
      final container = authedContainer(merchant);
      addTearDown(container.dispose);
      await _pumpApp(tester, container);

      expect(find.byKey(const Key('merchant-legal-section')), findsOneWidget);
      expect(find.text(AppStrings.legalVersionTag('terms-v3')), findsOneWidget);
      expect(find.text(AppStrings.legalVersionTag('decl-v2')), findsOneWidget);
      expect(_submitEnabled(tester), isFalse);

      await _tap(tester, const Key('merchant-legal-terms'));
      expect(_submitEnabled(tester), isFalse);

      await _tap(tester, const Key('merchant-legal-declaration'));
      expect(_submitEnabled(tester), isTrue);

      await _tap(tester, const Key('merchant-legal-terms'));
      expect(_submitEnabled(tester), isFalse);
    });

    testWidgets('submit sends the exact versions returned by the API', (
      tester,
    ) async {
      final merchant = _serverWith(_readyToSubmit());
      final container = authedContainer(merchant);
      addTearDown(container.dispose);
      await _pumpApp(tester, container);

      await _tap(tester, const Key('merchant-legal-terms'));
      await _tap(tester, const Key('merchant-legal-declaration'));
      await _tap(tester, const Key('merchant-reg-submit'));

      expect(merchant.submittedAcceptances, hasLength(1));
      final sent = {
        for (final a in merchant.submittedAcceptances.single) a.kind: a.version,
      };
      expect(sent, {
        LegalKind.merchantTerms: 'terms-v3',
        LegalKind.dossierAccuracyDeclaration: 'decl-v2',
      });
    });

    testWidgets('legal load failure shows retry and keeps submit disabled', (
      tester,
    ) async {
      final merchant = _serverWith(_readyToSubmit());
      var fail = true;
      merchant.legalCurrentHandler = () async {
        if (fail) throw const ApiException('boom', code: 'NETWORK');
        return _legal();
      };
      final container = authedContainer(merchant);
      addTearDown(container.dispose);
      await _pumpApp(tester, container);

      expect(find.byKey(const Key('merchant-legal-unavailable')), findsOneWidget);
      expect(find.text(AppStrings.legalLoadFailed), findsOneWidget);
      expect(_submitEnabled(tester), isFalse);

      fail = false;
      await _tap(tester, const Key('merchant-legal-retry'));
      expect(find.byKey(const Key('merchant-legal-terms')), findsOneWidget);
    });

    test('submit without consent never calls the API', () async {
      final merchant = _serverWith(_readyToSubmit());
      final container = authedContainer(merchant);
      addTearDown(container.dispose);
      await restoreAndResolve(container);
      final reg = container.read(registrationControllerProvider.notifier)
        ..hydrateFromAccess(_readyToSubmit());
      await reg.loadLegal();
      reg.setTermsAccepted(true);

      await reg.submitForReview();

      expect(merchant.submittedAcceptances, isEmpty);
      expect(
        container.read(registrationControllerProvider).errorMessage,
        AppStrings.legalConsentRequired,
      );
    });
  });

  group('outdated legal version', () {
    test('reloads versions, clears consent and accepts the new version', () async {
      var published = 'v1';
      final merchant = _serverWith(_readyToSubmit());
      merchant.legalCurrentHandler = () async =>
          _legal(terms: 'terms-$published', declaration: 'decl-$published');
      merchant.submitVerificationHandler = (id, acceptances) async {
        if (acceptances.any((a) => !a.version.endsWith(published))) {
          throw const ApiException(
            'outdated',
            code: 'LEGAL_VERSION_OUTDATED',
            statusCode: 400,
          );
        }
      };
      final container = authedContainer(merchant);
      addTearDown(container.dispose);
      await restoreAndResolve(container);
      final reg = container.read(registrationControllerProvider.notifier)
        ..hydrateFromAccess(_readyToSubmit());

      await reg.loadLegal();
      reg
        ..setTermsAccepted(true)
        ..setDeclarationAccepted(true);
      expect(container.read(registrationControllerProvider).consentsComplete,
          isTrue);

      published = 'v2';
      await reg.submitForReview();

      var state = container.read(registrationControllerProvider);
      expect(merchant.legalCurrentCalls, 2);
      expect(state.legal!.terms!.version, 'terms-v2');
      expect(state.termsAccepted, isFalse);
      expect(state.declarationAccepted, isFalse);
      expect(state.consentsComplete, isFalse);
      expect(state.errorMessage, AppStrings.legalVersionOutdated);
      expect(state.busy, isFalse);

      reg
        ..setTermsAccepted(true)
        ..setDeclarationAccepted(true);
      await reg.submitForReview();

      state = container.read(registrationControllerProvider);
      expect(merchant.submittedAcceptances, hasLength(2));
      expect(
        merchant.submittedAcceptances.last.map((a) => a.version).toSet(),
        {'terms-v2', 'decl-v2'},
      );
      expect(state.termsAccepted, isFalse);
    });
  });

  group('rejection', () {
    testWidgets('rejected screen groups application and document issues', (
      tester,
    ) async {
      final container = authedContainer(_serverWith(_rejected()));
      addTearDown(container.dispose);
      await _pumpApp(tester, container);

      expect(find.byKey(const Key('merchant-verification-rejected')),
          findsOneWidget);
      expect(find.byKey(const Key('merchant-issues-list')), findsOneWidget);
      expect(find.text(AppStrings.issuesRemaining(2)), findsOneWidget);
      expect(
        find.byKey(const Key('merchant-issues-application-title')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('merchant-issues-document-title')),
        findsOneWidget,
      );
      expect(find.text(_applicationIssue.messageFr), findsOneWidget);
      expect(find.text(_documentIssue.messageFr), findsOneWidget);
      expect(
        find.text(AppStrings.issuesDocumentConcerned('Identité de l’activité')),
        findsOneWidget,
      );
      expect(find.text(AppStrings.issuesFixHint), findsOneWidget);
      expect(find.text(AppStrings.regRejectionNoReason), findsNothing);
      expect(find.byKey(const Key('merchant-dossier-attempt')), findsOneWidget);
      expect(find.byKey(const Key('merchant-dossier-submitted-at')),
          findsOneWidget);
    });

    testWidgets('rejection without structured issues keeps generic guidance', (
      tester,
    ) async {
      final container = authedContainer(
        _serverWith(_rejected(issues: const [])),
      );
      addTearDown(container.dispose);
      await _pumpApp(tester, container);

      expect(find.byKey(const Key('merchant-issues-list')), findsNothing);
      expect(find.text(AppStrings.regRejectionNoReason), findsOneWidget);
    });

    testWidgets('document issue leads to the document step and resubmission',
        (tester) async {
      final merchant = _serverWith(_rejected());
      final container = authedContainer(merchant);
      addTearDown(container.dispose);
      await _pumpApp(tester, container);

      await _tap(tester, const Key('merchant-verification-correct'));
      await settle(tester);
      expect(find.byKey(const Key('merchant-registration')), findsOneWidget);
      expect(find.byKey(const Key('merchant-issues-list')), findsOneWidget);
      expect(_submitEnabled(tester), isFalse);

      await _tap(tester, const Key('merchant-issue-replace-BUSINESS_IDENTITY'));
      expect(
        find.byKey(const Key('merchant-reg-doc-issue-BUSINESS_IDENTITY-0')),
        findsOneWidget,
      );
      expect(find.text(_documentIssue.messageFr), findsOneWidget);
      expect(
        find.byKey(const Key('merchant-reg-doc-pick-BUSINESS_IDENTITY')),
        findsOneWidget,
      );
    });

    testWidgets('resubmitting a rejected dossier needs a fresh consent', (
      tester,
    ) async {
      final merchant = _serverWith(_rejected(issues: const [_applicationIssue]));
      final container = authedContainer(merchant);
      addTearDown(container.dispose);
      await _pumpApp(tester, container);

      await _tap(tester, const Key('merchant-verification-correct'));
      expect(_submitEnabled(tester), isFalse);

      await _tap(tester, const Key('merchant-legal-terms'));
      await _tap(tester, const Key('merchant-legal-declaration'));
      expect(_submitEnabled(tester), isTrue);
      await _tap(tester, const Key('merchant-reg-submit'));

      expect(merchant.submittedAcceptances, hasLength(1));
      expect(
        merchant.submittedAcceptances.single.map((a) => a.version).toSet(),
        {'terms-v3', 'decl-v2'},
      );
    });
  });

  group('status visibility', () {
    testWidgets('pending screen shows attempt and submission time', (
      tester,
    ) async {
      final pending = membership(
        status: 'PENDING_REVIEW',
        approved: false,
        operationalReady: false,
        verificationReady: true,
        verificationSubmitted: true,
        branches: [branch('b1')],
        evidenceChecklist: _readyDocs,
        attemptNumber: 3,
        submittedAt: '2026-10-01T09:30:00Z',
        legalAcceptance: const MerchantLegalAcceptanceRecord(
          termsVersion: 'terms-v3',
          declarationVersion: 'decl-v2',
          acceptedAt: '2026-10-01T09:29:00Z',
        ),
      );
      final container = authedContainer(_serverWith(pending));
      addTearDown(container.dispose);
      await _pumpApp(tester, container);

      expect(find.byKey(const Key('merchant-verification-pending')),
          findsOneWidget);
      expect(find.byKey(const Key('merchant-dossier-info')), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const Key('merchant-dossier-attempt')),
          matching: find.text('3'),
        ),
        findsOneWidget,
      );
      expect(find.byKey(const Key('merchant-dossier-submitted-at')),
          findsOneWidget);
      expect(
        find.textContaining(
          AppStrings.dossierConsentVersions('terms-v3', 'decl-v2'),
        ),
        findsOneWidget,
      );
      expect(find.byKey(const Key('merchant-dossier-reviewed-at')), findsNothing);
    });

    test('dossier info is hidden for legacy merchants', () {
      expect(VerificationDossierInfo.hasData(membership()), isFalse);
    });
  });
}
