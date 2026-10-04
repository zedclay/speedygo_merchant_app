import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speedygo_merchant_app/app/app.dart';
import 'package:speedygo_merchant_app/app/router/app_router.dart';
import 'package:speedygo_merchant_app/core/constants/app_strings.dart';
import 'package:speedygo_merchant_app/core/constants/merchant_assets.dart';
import 'package:speedygo_merchant_app/core/navigation/app_routes.dart';
import 'package:speedygo_merchant_app/core/storage/session_store.dart';
import 'package:speedygo_merchant_app/features/access/data/models.dart';
import 'package:speedygo_merchant_app/features/auth/application/session_controller.dart';
import 'package:speedygo_merchant_app/features/auth/application/session_state.dart';
import 'package:speedygo_merchant_app/features/auth/data/models.dart';

import 'phase1_flow_test.dart';
import 'startup_flow_test.dart';

Future<void> settle(WidgetTester tester, {int frames = 40}) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

Future<void> pumpOnboarding(
  WidgetTester tester,
  ProviderContainer container,
) async {
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const SpeedyGoApp(),
    ),
  );
  await settle(tester);
}

void main() {
  testWidgets('first launch: language then onboarding then phone via Suivant',
      (tester) async {
    final launch = ControllableLaunchStore(languageSeen: false);
    final container = testContainer(
      auth: FakeAuthApi(),
      merchant: FakeMerchantApi(),
      launch: launch,
    );
    addTearDown(container.dispose);
    await pumpOnboarding(tester, container);

    expect(find.byKey(const Key('merchant-language')), findsOneWidget);
    await tester.tap(find.byKey(const Key('merchant-language-fr')));
    await settle(tester);

    expect(find.byKey(const Key('merchant-onboarding')), findsOneWidget);
    expect(find.text(AppStrings.onboardingPage1Title), findsOneWidget);
    expect(find.image(const AssetImage(MerchantAssets.onboardingReceive)),
        findsOneWidget);

    await tester.tap(find.byKey(const Key('merchant-onboarding-primary')));
    await settle(tester);
    expect(find.text(AppStrings.onboardingPage2Title), findsOneWidget);
    expect(find.text(AppStrings.onboardingNext), findsOneWidget);

    await tester.tap(find.byKey(const Key('merchant-onboarding-primary')));
    await settle(tester);
    expect(find.text(AppStrings.onboardingPage3Title), findsOneWidget);
    expect(find.text(AppStrings.onboardingStart), findsOneWidget);

    await tester.tap(find.byKey(const Key('merchant-onboarding-primary')));
    await settle(tester);

    expect(launch.onboardingSeen, isTrue);
    expect(launch.markOnboardingCalls, 1);
    expect(find.text(AppStrings.phoneTitle), findsOneWidget);
    expect(find.byKey(const Key('merchant-onboarding')), findsNothing);
  });

  testWidgets('swipe advances pages without completing', (tester) async {
    final launch = ControllableLaunchStore(
      languageSeen: true,
      onboardingSeen: false,
    );
    final container = testContainer(
      auth: FakeAuthApi(),
      merchant: FakeMerchantApi(),
      launch: launch,
    );
    addTearDown(container.dispose);
    await pumpOnboarding(tester, container);

    await tester.fling(
      find.byKey(const Key('merchant-onboarding-pager')),
      const Offset(-400, 0),
      1000,
    );
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.onboardingPage2Title), findsOneWidget);
    expect(launch.onboardingSeen, isFalse);
    expect(find.text(AppStrings.phoneTitle), findsNothing);
  });

  testWidgets('Passer completes and opens phone', (tester) async {
    final launch = ControllableLaunchStore(
      languageSeen: true,
      onboardingSeen: false,
    );
    final container = testContainer(
      auth: FakeAuthApi(),
      merchant: FakeMerchantApi(),
      launch: launch,
    );
    addTearDown(container.dispose);
    await pumpOnboarding(tester, container);

    await tester.tap(find.byKey(const Key('merchant-onboarding-skip')));
    await settle(tester);
    expect(launch.onboardingSeen, isTrue);
    expect(find.text(AppStrings.phoneTitle), findsOneWidget);
  });

  testWidgets('J’ai déjà un compte completes and opens phone', (tester) async {
    final launch = ControllableLaunchStore(
      languageSeen: true,
      onboardingSeen: false,
    );
    final container = testContainer(
      auth: FakeAuthApi(),
      merchant: FakeMerchantApi(),
      launch: launch,
    );
    addTearDown(container.dispose);
    await pumpOnboarding(tester, container);

    await tester.tap(find.byKey(const Key('merchant-onboarding-existing')));
    await settle(tester);
    expect(launch.onboardingSeen, isTrue);
    expect(find.text(AppStrings.phoneTitle), findsOneWidget);
  });

  testWidgets('Commencer on page 3 completes', (tester) async {
    final launch = ControllableLaunchStore(
      languageSeen: true,
      onboardingSeen: false,
    );
    final container = testContainer(
      auth: FakeAuthApi(),
      merchant: FakeMerchantApi(),
      launch: launch,
    );
    addTearDown(container.dispose);
    await pumpOnboarding(tester, container);

    final pageView = tester.widget<PageView>(
      find.byKey(const Key('merchant-onboarding-pager')),
    );
    pageView.controller!.jumpToPage(2);
    await settle(tester);
    expect(find.text(AppStrings.onboardingStart), findsOneWidget);

    await tester.tap(find.byKey(const Key('merchant-onboarding-primary')));
    await settle(tester);
    expect(launch.onboardingSeen, isTrue);
    expect(find.text(AppStrings.phoneTitle), findsOneWidget);
  });

  testWidgets('completion persists across relaunch', (tester) async {
    final launch = ControllableLaunchStore(
      languageSeen: true,
      onboardingSeen: false,
    );
    final container = testContainer(
      auth: FakeAuthApi(),
      merchant: FakeMerchantApi(),
      launch: launch,
    );
    addTearDown(container.dispose);
    await pumpOnboarding(tester, container);
    await tester.tap(find.byKey(const Key('merchant-onboarding-skip')));
    await settle(tester);
    expect(launch.onboardingSeen, isTrue);

    final container2 = testContainer(
      auth: FakeAuthApi(),
      merchant: FakeMerchantApi(),
      launch: launch,
    );
    addTearDown(container2.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container2,
        child: const SpeedyGoApp(),
      ),
    );
    await settle(tester);
    expect(find.byKey(const Key('merchant-onboarding')), findsNothing);
    expect(find.text(AppStrings.phoneTitle), findsOneWidget);
  });

  testWidgets('authenticated restore bypasses onboarding', (tester) async {
    final store = MemorySessionStore()
      ..value = const TokenPair(
        accessToken: 'a',
        refreshToken: 'r-token-value',
        expiresIn: 900,
        tokenType: 'Bearer',
      );
    final launch = ControllableLaunchStore(
      languageSeen: true,
      onboardingSeen: false,
    );
    final container = testContainer(
      auth: FakeAuthApi(),
      merchant: FakeMerchantApi(
        meHandler: () async => MerchantMe(
          merchantMembershipExists: true,
          memberships: [
            membership(
              status: 'APPROVED',
              approved: true,
              operationalReady: true,
              branches: [branch('b1')],
            ),
          ],
        ),
      ),
      store: store,
      launch: launch,
      context: MemoryContextStore()..branchId = 'b1',
    );
    addTearDown(container.dispose);
    await pumpOnboarding(tester, container);

    expect(find.byKey(const Key('merchant-onboarding')), findsNothing);
    expect(find.text(AppStrings.phoneTitle), findsNothing);
    expect(
      container.read(sessionControllerProvider).phase,
      isNot(SessionPhase.signedOut),
    );
  });

  testWidgets('duplicate complete taps only persist once', (tester) async {
    final launch = ControllableLaunchStore(
      languageSeen: true,
      onboardingSeen: false,
    );
    final container = testContainer(
      auth: FakeAuthApi(),
      merchant: FakeMerchantApi(),
      launch: launch,
    );
    addTearDown(container.dispose);
    await pumpOnboarding(tester, container);

    await tester.tap(find.byKey(const Key('merchant-onboarding-skip')));
    await tester.tap(find.byKey(const Key('merchant-onboarding-existing')));
    await tester.tap(find.byKey(const Key('merchant-onboarding-primary')));
    await settle(tester);

    expect(launch.markOnboardingCalls, 1);
    expect(find.text(AppStrings.phoneTitle), findsOneWidget);
  });

  testWidgets('persistence failure keeps onboarding with error', (tester) async {
    final launch = ControllableLaunchStore(
      languageSeen: true,
      onboardingSeen: false,
      failOnboardingWrites: true,
    );
    final container = testContainer(
      auth: FakeAuthApi(),
      merchant: FakeMerchantApi(),
      launch: launch,
    );
    addTearDown(container.dispose);
    await pumpOnboarding(tester, container);

    await tester.tap(find.byKey(const Key('merchant-onboarding-skip')));
    await settle(tester);

    expect(launch.onboardingSeen, isFalse);
    expect(find.byKey(const Key('merchant-onboarding')), findsOneWidget);
    expect(find.text(AppStrings.onboardingSaveFailed), findsOneWidget);
    expect(find.text(AppStrings.phoneTitle), findsNothing);
  });

  testWidgets('back from phone does not reopen onboarding', (tester) async {
    final launch = ControllableLaunchStore(
      languageSeen: true,
      onboardingSeen: false,
    );
    final container = testContainer(
      auth: FakeAuthApi(),
      merchant: FakeMerchantApi(),
      launch: launch,
    );
    addTearDown(container.dispose);
    await pumpOnboarding(tester, container);
    await tester.tap(find.byKey(const Key('merchant-onboarding-skip')));
    await settle(tester);
    expect(find.text(AppStrings.phoneTitle), findsOneWidget);

    final router = container.read(appRouterProvider);
    router.go(AppRoutes.onboarding);
    await settle(tester);
    expect(find.byKey(const Key('merchant-onboarding')), findsNothing);
    expect(find.text(AppStrings.phoneTitle), findsOneWidget);
  });

  testWidgets('page 1 render alone does not mark completion', (tester) async {
    final launch = ControllableLaunchStore(
      languageSeen: true,
      onboardingSeen: false,
    );
    final container = testContainer(
      auth: FakeAuthApi(),
      merchant: FakeMerchantApi(),
      launch: launch,
    );
    addTearDown(container.dispose);
    await pumpOnboarding(tester, container);
    expect(find.text(AppStrings.onboardingPage1Title), findsOneWidget);
    expect(launch.onboardingSeen, isFalse);
    expect(launch.markOnboardingCalls, 0);
  });
}
