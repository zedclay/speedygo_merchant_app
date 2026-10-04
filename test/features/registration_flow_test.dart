import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speedygo_merchant_app/app/app.dart';
import 'package:speedygo_merchant_app/core/constants/app_strings.dart';
import 'package:speedygo_merchant_app/core/storage/session_store.dart';
import 'package:speedygo_merchant_app/features/access/application/access_controller.dart';
import 'package:speedygo_merchant_app/features/access/application/registration_controller.dart';
import 'package:speedygo_merchant_app/features/access/data/models.dart';
import 'package:speedygo_merchant_app/features/auth/application/session_controller.dart';
import 'package:speedygo_merchant_app/features/auth/application/session_providers.dart';
import 'package:speedygo_merchant_app/features/auth/data/models.dart';

import 'phase1_flow_test.dart';
import 'startup_flow_test.dart';

Future<void> settle(WidgetTester tester, {int n = 40}) async {
  for (var i = 0; i < n; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

ProviderContainer authedContainer(FakeMerchantApi merchant) {
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
  return container;
}

void main() {
  testWidgets('new user reaches registration account step', (tester) async {
    final container = authedContainer(FakeMerchantApi());
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const SpeedyGoApp(),
      ),
    );
    await settle(tester);
    expect(find.byKey(const Key('merchant-registration')), findsOneWidget);
    expect(find.text(AppStrings.regAccountTitle), findsOneWidget);
  });

  test('operator intent does not create merchant', () async {
    final merchant = FakeMerchantApi();
    final container = authedContainer(merchant);
    addTearDown(container.dispose);
    await container.read(sessionControllerProvider.notifier).restore();
    await container.read(accessControllerProvider.notifier).resolve();
    final reg = container.read(registrationControllerProvider.notifier);
    reg.setIntent(RegistrationIntent.operatorJoinUnsupported);
    await reg.continueFromAccount();
    expect(
      container.read(registrationControllerProvider).errorMessage,
      AppStrings.regOperatorUnsupported,
    );
    expect(merchant.lastCreatedName, isNull);
    expect(
      container.read(registrationControllerProvider).step,
      RegistrationStep.account,
    );
  });

  test('existing membership reconcile skips create', () async {
    final existing = membership(
      status: 'PENDING_REVIEW',
      approved: false,
      merchantId: 'm-existing',
    ).copyWithName('Existant');
    var createCalls = 0;
    final merchant = _CountingMerchantApi(
      onCreate: () async {
        createCalls += 1;
        return existing;
      },
      meHandler: () async => MerchantMe(
        merchantMembershipExists: true,
        memberships: [existing],
      ),
    );
    final container = authedContainer(merchant);
    addTearDown(container.dispose);
    await container.read(sessionControllerProvider.notifier).restore();
    await container.read(accessControllerProvider.notifier).resolve();
    expect(
      container.read(accessControllerProvider).destination,
      AccessDestination.registration,
    );
    final reg = container.read(registrationControllerProvider.notifier);
    reg.hydrateFromAccess(existing);
    reg.updateMerchantNameDraft('Existant');
    await reg.saveActivityAndContinue();
    expect(createCalls, 0);
    expect(
      container.read(registrationControllerProvider).membership?.merchantId,
      'm-existing',
    );
  });

  testWidgets('resume prefills merchant name without overwrite', (tester) async {
    final created = membership(
      status: 'PENDING_REVIEW',
      approved: false,
      operationalReady: false,
      verificationSubmitted: false,
      merchantId: 'm-1',
      evidenceChecklist: const [
        MerchantEvidenceItem(
          type: 'BUSINESS_IDENTITY',
          required: true,
          present: false,
          complete: false,
        ),
      ],
    ).copyWithName('Finjan');
    final merchant = FakeMerchantApi(
      meHandler: () async => MerchantMe(
        merchantMembershipExists: true,
        memberships: [created],
      ),
    );
    final container = authedContainer(merchant);
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const SpeedyGoApp(),
      ),
    );
    await settle(tester);
    expect(
      container.read(registrationControllerProvider).merchantNameDraft,
      'Finjan',
    );
    expect(
      container.read(registrationControllerProvider).hasServerMerchant,
      isTrue,
    );
  });

  test('upload and bind updates checklist', () async {
    final base = membership(
      status: 'PENDING_REVIEW',
      approved: false,
      merchantId: 'm-1',
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
    ).copyWithName('Doc Shop');
    final merchant = FakeMerchantApi(
      meHandler: () async => MerchantMe(
        merchantMembershipExists: true,
        memberships: [base],
      ),
    );
    final container = authedContainer(merchant);
    addTearDown(container.dispose);
    await container.read(sessionControllerProvider.notifier).restore();
    await container.read(accessControllerProvider.notifier).resolve();
    final reg = container.read(registrationControllerProvider.notifier);
    reg.hydrateFromAccess(base);
    await reg.uploadAndBindEvidence(
      type: 'BUSINESS_IDENTITY',
      filename: 'id.pdf',
      contentType: 'application/pdf',
      bytes: Uint8List.fromList(List.filled(100, 1)),
    );
    final item = container
        .read(registrationControllerProvider)
        .membership!
        .evidenceChecklist
        .firstWhere((e) => e.type == 'BUSINESS_IDENTITY');
    expect(item.complete, isTrue);
  });

  testWidgets('phone auth regression after registration wiring', (tester) async {
    final container = testContainer(
      auth: FakeAuthApi(),
      merchant: FakeMerchantApi(),
      launch: ControllableLaunchStore(
        languageSeen: true,
        onboardingSeen: true,
      ),
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const SpeedyGoApp(),
      ),
    );
    await settle(tester);
    expect(find.text(AppStrings.phoneTitle), findsOneWidget);
  });
}

class _CountingMerchantApi extends FakeMerchantApi {
  _CountingMerchantApi({
    required this.onCreate,
    super.meHandler,
  });

  final Future<MerchantMembership> Function() onCreate;

  @override
  Future<MerchantMembership> createProfile({required String name}) => onCreate();
}
