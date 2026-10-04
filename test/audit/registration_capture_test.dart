import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speedygo_merchant_app/app/app.dart';
import 'package:speedygo_merchant_app/core/constants/app_strings.dart';
import 'package:speedygo_merchant_app/core/storage/session_store.dart';
import 'package:speedygo_merchant_app/features/access/application/registration_controller.dart';
import 'package:speedygo_merchant_app/features/access/data/models.dart';
import 'package:speedygo_merchant_app/features/access/presentation/evidence_presentation.dart';
import 'package:speedygo_merchant_app/features/auth/application/session_providers.dart';
import 'package:speedygo_merchant_app/features/auth/data/models.dart';

import '../features/phase1_flow_test.dart';
import '../features/startup_flow_test.dart';

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 40; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

Future<void> _capture(WidgetTester tester, String name) async {
  await tester.pump();
  final finder = find.byKey(const Key('merchant-capture-root'));
  final renderObject = tester.renderObject(finder);
  if (renderObject is! RenderRepaintBoundary) return;
  await tester.runAsync(() async {
    final image = await renderObject.toImage(pixelRatio: 1.5);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File('audit/registration-verification/captures/$name.png');
    file.parent.createSync(recursive: true);
    await file.writeAsBytes(bytes!.buffer.asUint8List());
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // One app instance at a time: the previous container is disposed once its
  // tree is replaced, so its session timers (order-alert poll) stop with it.
  ProviderContainer? live;

  Future<ProviderContainer> pumpReg(
    WidgetTester tester, {
    required Size size,
    double textScale = 1,
    required FakeMerchantApi merchant,
  }) async {
    tester.view.physicalSize = size * 2;
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final store = MemorySessionStore()
      ..value = const TokenPair(
        accessToken: 'a',
        refreshToken: 'r-token-value',
        expiresIn: 900,
        tokenType: 'Bearer',
      );
    final container = testContainer(
      auth: FakeAuthApi(),
      merchant: merchant,
      store: store,
      launch: ControllableLaunchStore(languageSeen: true, onboardingSeen: true),
    );
    container.read(tokenCacheProvider).current = store.value;
    addTearDown(container.dispose);
    await tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(
          size: size,
          textScaler: TextScaler.linear(textScale),
        ),
        child: UncontrolledProviderScope(
          container: container,
          child: const RepaintBoundary(
            key: Key('merchant-capture-root'),
            child: SpeedyGoApp(),
          ),
        ),
      ),
    );
    live?.dispose();
    live = container;
    await _settle(tester);
    return container;
  }

  testWidgets('registration and verification mocked captures', (tester) async {
    final incomplete = membership(
      status: 'PENDING_REVIEW',
      approved: false,
      verificationSubmitted: false,
      merchantId: 'm-cap',
      evidenceChecklist: const [
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
      ],
      branches: [branch('b1')],
    ).copyWithName('Capture Shop');

    // Account (new user)
    var container = await pumpReg(
      tester,
      size: const Size(375, 667),
      merchant: FakeMerchantApi(),
    );
    expect(find.text(AppStrings.regAccountTitle), findsOneWidget);
    await _capture(tester, 'reg-account-375x667');

    await pumpReg(
      tester,
      size: const Size(402, 874),
      merchant: FakeMerchantApi(),
    );
    await _capture(tester, 'reg-account-402x874');

    // Activity / documents / establishment / review via incomplete membership
    container = await pumpReg(
      tester,
      size: const Size(375, 667),
      merchant: FakeMerchantApi(
        meHandler: () async => MerchantMe(
          merchantMembershipExists: true,
          memberships: [incomplete],
        ),
      ),
    );
    final reg = container.read(registrationControllerProvider.notifier);
    reg.hydrateFromAccess(incomplete);
    reg.goTo(RegistrationStep.activity);
    await _settle(tester);
    expect(find.text(AppStrings.regActivityTitle), findsOneWidget);
    await _capture(tester, 'reg-activity-375x667');

    reg.goTo(RegistrationStep.documents);
    await _settle(tester);
    expect(find.text(AppStrings.regDocsTitle), findsOneWidget);
    await _capture(tester, 'reg-documents-375x667');

    container = await pumpReg(
      tester,
      size: const Size(402, 874),
      merchant: FakeMerchantApi(
        meHandler: () async => MerchantMe(
          merchantMembershipExists: true,
          memberships: [incomplete],
        ),
      ),
    );
    container.read(registrationControllerProvider.notifier)
      ..hydrateFromAccess(incomplete)
      ..goTo(RegistrationStep.documents);
    await _settle(tester);
    await _capture(tester, 'reg-documents-402x874');

    container = await pumpReg(
      tester,
      size: const Size(375, 667),
      merchant: FakeMerchantApi(
        meHandler: () async => MerchantMe(
          merchantMembershipExists: true,
          memberships: [incomplete],
        ),
      ),
    );
    final regEstab = container.read(registrationControllerProvider.notifier);
    regEstab.hydrateFromAccess(incomplete);
    regEstab.goTo(RegistrationStep.establishment);
    await _settle(tester);
    expect(find.text(AppStrings.regEstablishmentTitle), findsOneWidget);
    expect(find.byKey(const Key('merchant-reg-category-readonly')), findsOneWidget);
    expect(find.byKey(const Key('merchant-reg-location')), findsOneWidget);
    expect(find.byKey(const Key('merchant-reg-commerce-context')), findsOneWidget);
    expect(find.text(AppStrings.regCategoryReadonly), findsOneWidget);
    // Fixture branch has saved coords → confirmed summary (not lat/lng fields).
    expect(find.byKey(const Key('merchant-reg-location-confirmed')), findsOneWidget);
    expect(find.text(AppStrings.regLocationConfirmed), findsOneWidget);
    expect(find.byKey(const Key('merchant-reg-branch-lat')), findsNothing);
    await _capture(tester, 'reg-establishment-375x667');
    await tester.ensureVisible(find.byKey(const Key('merchant-reg-location-confirmed')));
    await _settle(tester);
    await _capture(tester, 'reg-location-confirmed-375x667');
    await _capture(tester, 'reg-establishment-location-summary-375x667');

    // Unlocated branch → Choisir sur la carte
    final unlocated = membership(
      status: 'PENDING_REVIEW',
      approved: false,
      verificationSubmitted: false,
      merchantId: 'm-cap-unloc',
      evidenceChecklist: incomplete.evidenceChecklist,
      branches: [
        MerchantBranch(
          id: 'b-unloc',
          name: '',
          phone: '0550000001',
          addressText: '',
          latitude: 0,
          longitude: 0,
          operationalStatus: 'ACTIVE',
        ),
      ],
    ).copyWithName('Capture Shop');
    container = await pumpReg(
      tester,
      size: const Size(375, 667),
      merchant: FakeMerchantApi(
        meHandler: () async => MerchantMe(
          merchantMembershipExists: true,
          memberships: [unlocated],
        ),
      ),
    );
    container.read(registrationControllerProvider.notifier)
      ..hydrateFromAccess(unlocated)
      ..goTo(RegistrationStep.establishment);
    await _settle(tester);
    expect(find.byKey(const Key('merchant-reg-choose-on-map')), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('merchant-reg-choose-on-map')));
    await _settle(tester);
    await _capture(tester, 'reg-location-choose-375x667');

    await tester.tap(find.byKey(const Key('merchant-reg-choose-on-map')));
    await _settle(tester);
    expect(find.byKey(const Key('merchant-location-picker')), findsOneWidget);
    expect(find.text(AppStrings.regLocationPickerTitle), findsOneWidget);
    await _capture(tester, 'reg-location-picker-375x667');
    await tester.tap(find.byKey(const Key('merchant-location-back')));
    await _settle(tester);
    expect(find.byKey(const Key('merchant-reg-choose-on-map')), findsOneWidget);

    container = await pumpReg(
      tester,
      size: const Size(402, 874),
      merchant: FakeMerchantApi(
        meHandler: () async => MerchantMe(
          merchantMembershipExists: true,
          memberships: [incomplete],
        ),
      ),
    );
    container.read(registrationControllerProvider.notifier)
      ..hydrateFromAccess(incomplete)
      ..goTo(RegistrationStep.establishment);
    await _settle(tester);
    await _capture(tester, 'reg-establishment-402x874');

    // Documents with attached + missing states
    final withDocs = incomplete.copyWithEvidence(const [
      MerchantEvidenceItem(
        type: 'BUSINESS_IDENTITY',
        required: true,
        present: true,
        complete: true,
        status: 'PENDING',
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
    ]);
    container = await pumpReg(
      tester,
      size: const Size(375, 667),
      merchant: FakeMerchantApi(
        meHandler: () async => MerchantMe(
          merchantMembershipExists: true,
          memberships: [withDocs],
        ),
      ),
    );
    container.read(registrationControllerProvider.notifier)
      ..hydrateFromAccess(withDocs)
      ..goTo(RegistrationStep.documents);
    await _settle(tester);
    expect(find.text('Ajouté'), findsWidgets);
    expect(find.text('Manquant'), findsWidgets);
    expect(find.text('Validé'), findsNothing);
    await _capture(tester, 'reg-documents-mixed-375x667');

    // Review from incomplete membership (fresh pump)
    container = await pumpReg(
      tester,
      size: const Size(375, 667),
      merchant: FakeMerchantApi(
        meHandler: () async => MerchantMe(
          merchantMembershipExists: true,
          memberships: [incomplete],
        ),
      ),
    );
    container.read(registrationControllerProvider.notifier)
      ..hydrateFromAccess(incomplete)
      ..goTo(RegistrationStep.review);
    await _settle(tester);
    expect(find.text(AppStrings.regReviewTitle), findsOneWidget);
    await _capture(tester, 'reg-review-375x667');

    // Dense text
    container = await pumpReg(
      tester,
      size: const Size(375, 667),
      textScale: 1.3,
      merchant: FakeMerchantApi(
        meHandler: () async => MerchantMe(
          merchantMembershipExists: true,
          memberships: [incomplete],
        ),
      ),
    );
    container.read(registrationControllerProvider.notifier)
      ..hydrateFromAccess(incomplete)
      ..goTo(RegistrationStep.establishment);
    await _settle(tester);
    expect(tester.takeException(), isNull);
    await _capture(tester, 'reg-establishment-text-1_3-375x667');

    // Pending submitted — optional SUPPORTING absent must show Non fourni
    final submitted = membership(
      status: 'PENDING_REVIEW',
      approved: false,
      verificationSubmitted: true,
      branches: [branch('b1')],
      evidenceChecklist: const [
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
        MerchantEvidenceItem(
          type: 'SUPPORTING_DOCUMENT',
          required: false,
          present: false,
          complete: false,
        ),
      ],
    ).copyWithName('Pending Shop');
    await pumpReg(
      tester,
      size: const Size(375, 667),
      merchant: FakeMerchantApi(
        meHandler: () async => MerchantMe(
          merchantMembershipExists: true,
          memberships: [submitted],
        ),
      ),
    );
    expect(find.byKey(const Key('merchant-verification-pending')), findsOneWidget);
    expect(find.text(AppStrings.verificationPendingTitle), findsWidgets);
    expect(find.textContaining('transmis'), findsOneWidget);
    expect(find.text('En examen'), findsWidgets);
    expect(find.text('Non fourni'), findsOneWidget);
    expect(find.text('Facultatif'), findsOneWidget);
    expect(find.text('Validé'), findsNothing);
    await _capture(tester, 'verification-pending-375x667');
    await tester.ensureVisible(find.text('Non fourni'));
    await _settle(tester);
    await _capture(tester, 'verification-pending-optional-absent-375x667');

    await pumpReg(
      tester,
      size: const Size(402, 874),
      merchant: FakeMerchantApi(
        meHandler: () async => MerchantMe(
          merchantMembershipExists: true,
          memberships: [submitted],
        ),
      ),
    );
    expect(find.byKey(const Key('merchant-verification-pending')), findsOneWidget);
    await _capture(tester, 'verification-pending-402x874');

    // PENDING_REVIEW without formal submission must not claim "transmis"
    final pendingIncomplete = membership(
      status: 'PENDING_REVIEW',
      approved: false,
      verificationSubmitted: false,
      branches: [branch('b1')],
      evidenceChecklist: const [
        MerchantEvidenceItem(
          type: 'BUSINESS_IDENTITY',
          required: true,
          present: false,
          complete: false,
        ),
      ],
    ).copyWithName('Incomplete Pending');
    await pumpReg(
      tester,
      size: const Size(375, 667),
      merchant: FakeMerchantApi(
        meHandler: () async => MerchantMe(
          merchantMembershipExists: true,
          memberships: [pendingIncomplete],
        ),
      ),
    );
    // Incomplete may route to registration — only assert guidance helper.
    expect(
      EvidencePresentation.pendingGuidance(
        verificationSubmitted: false,
        verificationReady: false,
        hasMissingRequired: true,
      ).toLowerCase().contains('transmis'),
      isFalse,
    );

    // Rejected
    final rejected = membership(
      status: 'REJECTED',
      approved: false,
      verificationSubmitted: false,
      branches: [branch('b1')],
    ).copyWithName('Rejected Shop');
    await pumpReg(
      tester,
      size: const Size(375, 667),
      merchant: FakeMerchantApi(
        meHandler: () async => MerchantMe(
          merchantMembershipExists: true,
          memberships: [rejected],
        ),
      ),
    );
    expect(find.text(AppStrings.verificationRejectedTitle), findsOneWidget);
    await _capture(tester, 'verification-rejected-375x667');
    await _capture(tester, 'verification-resubmission-entry-375x667');

    // Approved path lands home when ACTIVE
    final approved = membership(
      status: 'ACTIVE',
      approved: true,
      branches: [branch('b1')],
    ).copyWithName('Approved Shop');
    await pumpReg(
      tester,
      size: const Size(375, 667),
      merchant: FakeMerchantApi(
        meHandler: () async => MerchantMe(
          merchantMembershipExists: true,
          memberships: [approved],
        ),
      ),
    );
    expect(find.text(AppStrings.homeTitle), findsWidgets);
    await _capture(tester, 'verification-approved-home-375x667');
    live?.dispose();
    live = null;
  });
}
