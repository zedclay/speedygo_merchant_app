import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speedygo_merchant_app/core/constants/app_strings.dart';
import 'package:speedygo_merchant_app/core/constants/merchant_assets.dart';
import 'package:speedygo_merchant_app/features/access/application/access_controller.dart';
import 'package:speedygo_merchant_app/features/access/application/registration_controller.dart';
import 'package:speedygo_merchant_app/features/access/data/models.dart';
import 'package:speedygo_merchant_app/features/access/presentation/access_screens.dart';
import 'package:speedygo_merchant_app/features/access/presentation/registration_screens.dart';
import 'package:speedygo_merchant_app/features/auth/application/session_providers.dart';
import 'package:speedygo_merchant_app/features/auth/data/models.dart';
import 'package:speedygo_merchant_app/core/storage/approval_notice_store.dart';
import 'package:speedygo_merchant_app/core/storage/session_store.dart';
import 'package:speedygo_merchant_app/core/widgets/merchant_primary_button.dart';

import '../../features/phase1_flow_test.dart';
import 'parity_harness.dart';

/// Real format: `sgm_` + 32 hex characters (compact on screen, full on demand).
const _reference = 'sgm_01a0f3306fa976c4a954d2a26f7a7137';
const _referenceCompact = 'sgm_01a0f3…7a7137';

const _benna = MerchantBranch(
  id: 'b1',
  name: 'Dar El Benna',
  phone: '0550123456',
  addressText: '12 Rue Didouche Mourad',
  latitude: 36.7732,
  longitude: 3.0588,
  operationalStatus: 'ACTIVE',
  wilayaCode: '16',
  communeId: 556,
  wilayaNameFr: 'Alger',
  communeNameFr: 'Alger Centre',
);

const _identity = MerchantEvidenceItem(
  type: 'BUSINESS_IDENTITY',
  required: true,
  present: true,
  complete: true,
  status: 'PENDING',
);
const _registration = MerchantEvidenceItem(
  type: 'BUSINESS_REGISTRATION',
  required: true,
  present: true,
  complete: true,
  status: 'PENDING',
);
const _registrationMissing = MerchantEvidenceItem(
  type: 'BUSINESS_REGISTRATION',
  required: true,
  present: false,
  complete: false,
);
const _supportingAbsent = MerchantEvidenceItem(
  type: 'SUPPORTING_DOCUMENT',
  required: false,
  present: false,
  complete: false,
);

MerchantMembership _member({
  required String status,
  required List<MerchantEvidenceItem> evidence,
  bool submitted = false,
  bool ready = false,
  String role = 'OWNER',
}) => MerchantMembership(
  merchantId: 'm-b7',
  role: role,
  profileComplete: true,
  hasBranch: true,
  branchReady: true,
  approved: false,
  operationalReady: false,
  verificationReady: ready,
  verificationSubmitted: submitted,
  verificationAttentionRequired: false,
  merchantName: 'Dar El Benna',
  merchantStatus: status,
  merchantPublicReference: _reference,
  verifiedAt: null,
  branches: const [_benna],
  evidenceChecklist: evidence,
);

final _draft = _member(
  status: 'PENDING_REVIEW',
  evidence: const [_identity, _registrationMissing, _supportingAbsent],
);
final _complete = _member(
  status: 'PENDING_REVIEW',
  ready: true,
  evidence: const [_identity, _registration, _supportingAbsent],
);
final _pending = _member(
  status: 'PENDING_REVIEW',
  submitted: true,
  ready: true,
  evidence: const [
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
    _supportingAbsent,
  ],
);
MerchantMembership _rejected({String role = 'OWNER', bool ready = false}) =>
    _member(
      status: 'REJECTED',
      role: role,
      ready: ready,
      evidence: ready
          ? const [_identity, _registration, _supportingAbsent]
          : const [_identity, _registrationMissing, _supportingAbsent],
    );

/// Session with a token and a resolved membership (or none), without
/// selecting a branch: registration and verification sit before the shell.
Future<ProviderContainer> _ready(
  MerchantMembership? member, {
  ApprovalNoticeStore? approvals,
}) async {
  final store = MemorySessionStore()
    ..value = const TokenPair(
      accessToken: 'a',
      refreshToken: 'r',
      expiresIn: 900,
      tokenType: 'Bearer',
    );
  final container = testContainer(
    auth: FakeAuthApi(),
    merchant: FakeMerchantApi(
      meHandler: () async => MerchantMe(
        merchantMembershipExists: member != null,
        memberships: [?member],
      ),
    ),
    store: store,
    approvals: approvals,
  );
  container.read(tokenCacheProvider).current = store.value;
  await restoreAndResolve(container);
  return container;
}

MerchantMembership _approvedMember({bool withBranch = true}) =>
    MerchantMembership(
      merchantId: 'm-b7',
      role: 'OWNER',
      profileComplete: true,
      hasBranch: withBranch,
      branchReady: withBranch,
      approved: true,
      operationalReady: false,
      verificationReady: true,
      verificationSubmitted: true,
      verificationAttentionRequired: false,
      merchantName: 'Dar El Benna',
      merchantStatus: 'ACTIVE',
      merchantPublicReference: _reference,
      verifiedAt: '2026-09-30T08:00:00Z',
      branches: withBranch ? const [_benna] : const [],
      evidenceChecklist: const [],
    );

/// Approved on the server after this installation saw the dossier pending.
Future<ProviderContainer> _approvedReady({bool withBranch = true}) async {
  final approvals = MemoryApprovalNoticeStore();
  await approvals.markObservedUnapproved('acc-1', 'm-b7');
  final container = await _ready(
    _approvedMember(withBranch: withBranch),
    approvals: approvals,
  );
  expect(
    container.read(accessControllerProvider).destination,
    AccessDestination.verificationApproved,
  );
  return container;
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 20; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

Future<void> _unmount(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(seconds: 1));
}

/// Pumps the wizard and moves to [step] once hydration has run.
Future<void> _pumpStep(
  WidgetTester tester,
  ProviderContainer container,
  ParityVariant variant,
  RegistrationStep step,
) async {
  await parityPump(
    tester,
    container: container,
    variant: variant,
    height: 844,
    child: const RegistrationHostScreen(),
  );
  container.read(registrationControllerProvider.notifier).goTo(step);
  await _settle(tester);
  await parityPumpFull(
    tester,
    container: container,
    variant: variant,
    child: const RegistrationHostScreen(),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('batch 7 mocked captures', () {
    for (final v in parityVariants) {
      testWidgets('account ${v.suffix}', (tester) async {
        final container = await _ready(null);
        addTearDown(container.dispose);
        await _pumpStep(tester, container, v, RegistrationStep.account);
        expect(tester.takeException(), isNull);
        await parityCapture(tester, 'b7_registration_${v.suffix}');
        await _unmount(tester);
      });

      testWidgets('documents ${v.suffix}', (tester) async {
        final container = await _ready(_draft);
        addTearDown(container.dispose);
        await _pumpStep(tester, container, v, RegistrationStep.documents);
        final logo = find.byKey(const Key('merchant-reg-docs-logo'));
        await tester.runAsync(
          () => precacheImage(
            const AssetImage(MerchantAssets.logo),
            tester.element(logo),
          ),
        );
        await tester.pump();
        expect(tester.takeException(), isNull);
        await parityCapture(tester, 'b7_documents_${v.suffix}');
        await _unmount(tester);
      });

      testWidgets('review ${v.suffix}', (tester) async {
        final container = await _ready(_complete);
        addTearDown(container.dispose);
        await _pumpStep(tester, container, v, RegistrationStep.review);
        expect(tester.takeException(), isNull);
        await parityCapture(tester, 'b7_review_${v.suffix}');
        await _unmount(tester);
      });

      testWidgets('pending ${v.suffix}', (tester) async {
        final container = await _ready(_pending);
        addTearDown(container.dispose);
        await parityPumpFull(
          tester,
          container: container,
          variant: v,
          child: const VerificationScreen(
            kind: AccessDestination.verificationPending,
          ),
        );
        expect(tester.takeException(), isNull);
        await parityCapture(tester, 'b7_pending_${v.suffix}');
        await _unmount(tester);
      });

      testWidgets('rejected ${v.suffix}', (tester) async {
        final container = await _ready(_rejected());
        addTearDown(container.dispose);
        await parityPumpFull(
          tester,
          container: container,
          variant: v,
          child: const VerificationScreen(
            kind: AccessDestination.verificationRejected,
          ),
        );
        expect(tester.takeException(), isNull);
        expect(
          tester
              .renderObject<RenderParagraph>(find.text(AppStrings.brandName))
              .didExceedMaxLines,
          isFalse,
        );
        await parityCapture(tester, 'b7_rejected_${v.suffix}');
        await _unmount(tester);
      });

      testWidgets('resubmission ${v.suffix}', (tester) async {
        final container = await _ready(_rejected(ready: true));
        addTearDown(container.dispose);
        await _pumpStep(tester, container, v, RegistrationStep.review);
        expect(tester.takeException(), isNull);
        await parityCapture(tester, 'b7_resubmission_${v.suffix}');
        await _unmount(tester);
      });

      for (final withBranch in const [true, false]) {
        final name = withBranch ? 'b7_approved' : 'b7_approved_need_branch';
        testWidgets('$name ${v.suffix}', (tester) async {
          final container = await _approvedReady(withBranch: withBranch);
          addTearDown(container.dispose);
          await parityPumpFull(
            tester,
            container: container,
            variant: v,
            child: const VerificationApprovedScreen(),
          );
          expect(tester.takeException(), isNull);
          await parityCapture(tester, '${name}_${v.suffix}');
          await _unmount(tester);
        });
      }

      final viewport = v.textScale > 1 ? 667.0 : 844.0;
      final footerCases = <String,
          (Future<ProviderContainer> Function(), Widget, Key, Key)>{
        'b7_pending': (
          () => _ready(_pending),
          const VerificationScreen(
            kind: AccessDestination.verificationPending,
          ),
          const Key('merchant-verification-guidance-box'),
          const Key('merchant-verification-refresh'),
        ),
        'b7_approved': (
          () => _approvedReady(),
          const VerificationApprovedScreen(),
          const Key('merchant-approved-note'),
          const Key('merchant-approved-continue'),
        ),
      };
      for (final entry in footerCases.entries) {
        final (ready, screen, lastKey, footerKey) = entry.value;
        testWidgets('${entry.key} viewport top and end ${v.suffix}', (
          tester,
        ) async {
          final container = await ready();
          addTearDown(container.dispose);
          await parityPump(
            tester,
            container: container,
            variant: v,
            height: viewport,
            bottomInset: 34,
            child: screen,
          );
          expect(tester.takeException(), isNull);
          await parityCapture(tester, '${entry.key}_top_${v.suffix}');
          final position = tester
              .stateList<ScrollableState>(find.byType(Scrollable))
              .map((s) => s.position)
              .firstWhere((p) => p.axis == Axis.vertical);
          if (v.textScale > 1) {
            expect(position.maxScrollExtent, greaterThan(0));
          }
          position.jumpTo(position.maxScrollExtent);
          await tester.pumpAndSettle();
          final last = tester.getRect(find.byKey(lastKey));
          final footer = tester.getRect(find.byKey(footerKey));
          expect(last.bottom, lessThanOrEqualTo(footer.top));
          expect(footer.bottom, lessThanOrEqualTo(viewport - 34));
          final button = find.descendant(
            of: find.byKey(footerKey),
            matching: find.byWidgetPredicate((w) => w is ButtonStyleButton),
            matchRoot: true,
          );
          final buttonRect = tester.getRect(button.first);
          for (final label in tester.widgetList<Text>(
            find.descendant(of: button.first, matching: find.byType(Text)),
          )) {
            final text = tester.getRect(find.byWidget(label));
            expect(text.top - buttonRect.top, greaterThanOrEqualTo(8));
            expect(buttonRect.bottom - text.bottom, greaterThanOrEqualTo(8));
            expect(text.left, greaterThanOrEqualTo(buttonRect.left));
            expect(text.right, lessThanOrEqualTo(buttonRect.right));
          }
          final hit = tester.hitTestOnBinding(last.center);
          expect(
            hit.path.any(
              (e) =>
                  e.target is RenderBox &&
                  tester.renderObject(find.byKey(lastKey)) == e.target,
            ),
            isTrue,
          );
          await parityCapture(tester, '${entry.key}_end_${v.suffix}');
          await _unmount(tester);
        });
      }
    }
  });

  group('batch 7 behaviour', () {
    const w390 = (width: 390.0, textScale: 1.0, suffix: 'w390');

    testWidgets('account shows the role cards and the locked phone', (
      tester,
    ) async {
      final container = await _ready(null);
      addTearDown(container.dispose);
      await _pumpStep(tester, container, w390, RegistrationStep.account);
      expect(find.byKey(const Key('merchant-reg-step-label')), findsOneWidget);
      expect(find.byKey(const Key('merchant-reg-role-owner')), findsOneWidget);
      expect(find.byKey(const Key('merchant-reg-role-operator')), findsOneWidget);
      expect(find.byKey(const Key('merchant-reg-verified-phone')), findsOneWidget);
      expect(find.text(AppStrings.regAccountTitle), findsOneWidget);
      await _unmount(tester);
    });

    testWidgets('documents keep real states, tips and privacy note', (
      tester,
    ) async {
      final container = await _ready(_draft);
      addTearDown(container.dispose);
      await _pumpStep(tester, container, w390, RegistrationStep.documents);
      expect(find.text('Ajouté'), findsWidgets);
      expect(find.text('Manquant'), findsWidgets);
      expect(find.text('Validé'), findsNothing);
      expect(find.byKey(const Key('merchant-reg-docs-privacy')), findsOneWidget);
      expect(
        find.byKey(const Key('merchant-reg-doc-pick-BUSINESS_REGISTRATION')),
        findsOneWidget,
      );
      await _unmount(tester);
    });

    testWidgets('first submission review keeps the regular copy', (
      tester,
    ) async {
      final container = await _ready(_complete);
      addTearDown(container.dispose);
      await _pumpStep(tester, container, w390, RegistrationStep.review);
      expect(find.text(AppStrings.regReviewTitle), findsOneWidget);
      expect(find.text(AppStrings.regSubmit), findsOneWidget);
      expect(find.byKey(const Key('merchant-reg-review-info')), findsOneWidget);
      expect(
        find.byKey(const Key('merchant-reg-correction-intro')),
        findsNothing,
      );
      MerchantPrimaryButton submit() => tester.widget<MerchantPrimaryButton>(
        find.byKey(const Key('merchant-reg-submit')),
      );
      // Submission also requires the legal consents (rows 71/72).
      expect(submit().onPressed, isNull);
      container.read(registrationControllerProvider.notifier)
        ..setTermsAccepted(true)
        ..setDeclarationAccepted(true);
      await _settle(tester);
      expect(submit().onPressed, isNotNull);
      await _unmount(tester);
    });

    testWidgets('rejected dossier reviews in correction mode', (tester) async {
      final container = await _ready(_rejected(ready: true));
      addTearDown(container.dispose);
      await _pumpStep(tester, container, w390, RegistrationStep.review);
      expect(find.text(AppStrings.regCorrectionTitle), findsOneWidget);
      expect(find.text(AppStrings.regCorrectionSubmit), findsOneWidget);
      expect(find.text(AppStrings.regSubmit), findsNothing);
      expect(
        find.byKey(const Key('merchant-reg-correction-intro')),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('merchant-reg-correction-summary')),
          matching: find.textContaining(_referenceCompact),
        ),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel(RegExp(RegExp.escape(_reference))),
        findsOneWidget,
      );
      await _unmount(tester);
    });

    testWidgets('pending shows real states only and no invented metadata', (
      tester,
    ) async {
      final container = await _ready(_pending);
      addTearDown(container.dispose);
      await parityPumpFull(
        tester,
        container: container,
        variant: w390,
        child: const VerificationScreen(
          kind: AccessDestination.verificationPending,
        ),
      );
      expect(find.text(AppStrings.verificationTimelineTitle), findsOneWidget);
      expect(find.textContaining('transmis'), findsOneWidget);
      expect(find.text('Non fourni'), findsOneWidget);
      expect(find.text('Validé'), findsNothing);
      expect(find.textContaining('Prioritaire'), findsNothing);
      expect(find.textContaining('SMS'), findsNothing);
      expect(find.textContaining('Soumis le'), findsNothing);
      expect(find.textContaining(_referenceCompact), findsOneWidget);
      expect(
        find.bySemanticsLabel(RegExp(RegExp.escape(_reference))),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('merchant-verification-support')),
        findsOneWidget,
      );
      await _unmount(tester);
    });

    testWidgets('pending support opens compose; hidden for staff', (
      tester,
    ) async {
      var container = await _ready(_pending);
      addTearDown(container.dispose);
      await parityPump(
        tester,
        container: container,
        variant: w390,
        height: 1400,
        includeOverlays: true,
        child: const VerificationScreen(
          kind: AccessDestination.verificationPending,
        ),
      );
      await tester.tap(find.byKey(const Key('merchant-verification-support')));
      await _settle(tester);
      expect(find.byType(BottomSheet), findsOneWidget);
      await _unmount(tester);

      container = await _ready(
        _member(
          status: 'PENDING_REVIEW',
          submitted: true,
          role: 'STAFF',
          evidence: _pending.evidenceChecklist,
        ),
      );
      addTearDown(container.dispose);
      await parityPump(
        tester,
        container: container,
        variant: w390,
        height: 1400,
        child: const VerificationScreen(
          kind: AccessDestination.verificationPending,
        ),
      );
      expect(
        find.byKey(const Key('merchant-verification-support')),
        findsNothing,
      );
      await _unmount(tester);
    });

    testWidgets('rejected screen corrects via the existing flow', (
      tester,
    ) async {
      final container = await _ready(_rejected());
      addTearDown(container.dispose);
      await parityPumpFull(
        tester,
        container: container,
        variant: w390,
        child: const VerificationScreen(
          kind: AccessDestination.verificationRejected,
        ),
      );
      expect(find.text(AppStrings.verificationRejectedTitle), findsOneWidget);
      expect(find.textContaining('Erreur'), findsNothing);
      expect(find.text(AppStrings.regRejectionNoReason), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const Key('merchant-verification-reference')),
          matching: find.text(_referenceCompact),
        ),
        findsOneWidget,
      );
      await tester.tap(
        find.byKey(const Key('merchant-verification-reference-open')),
      );
      await _settle(tester);
      expect(find.text(AppStrings.verificationReferenceFull), findsOneWidget);
      expect(
        tester
            .widget<SelectableText>(find.byKey(const Key('order-ref-full-text')))
            .data,
        _reference,
      );
      await tester.tapAt(const Offset(10, 10));
      await _settle(tester);
      expect(find.byKey(const Key('merchant-verification-refresh')), findsOneWidget);
      expect(find.byKey(const Key('merchant-verification-logout')), findsOneWidget);
      expect(
        container.read(accessControllerProvider).destination,
        AccessDestination.verificationRejected,
      );
      await tester.tap(find.byKey(const Key('merchant-verification-correct')));
      await tester.pump();
      expect(
        container.read(accessControllerProvider).destination,
        AccessDestination.registration,
      );
      await _unmount(tester);
    });

    testWidgets('pending title fits at 1.35 on 375', (tester) async {
      final container = await _ready(_pending);
      addTearDown(container.dispose);
      await parityPumpFull(
        tester,
        container: container,
        variant: parityVariants.last,
        child: const VerificationScreen(
          kind: AccessDestination.verificationPending,
        ),
      );
      final title = tester.renderObject<RenderParagraph>(
        find.text(AppStrings.appName),
      );
      expect(title.didExceedMaxLines, isFalse);
      await _unmount(tester);
    });
  });
}
