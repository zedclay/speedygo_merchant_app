import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speedygo_merchant_app/app/app.dart';
import 'package:speedygo_merchant_app/core/constants/app_strings.dart';
import 'package:speedygo_merchant_app/core/storage/session_store.dart';
import 'package:speedygo_merchant_app/features/access/application/access_controller.dart';
import 'package:speedygo_merchant_app/features/access/data/models.dart';
import 'package:speedygo_merchant_app/features/auth/application/session_controller.dart';
import 'package:speedygo_merchant_app/features/auth/application/session_providers.dart';
import 'package:speedygo_merchant_app/features/auth/application/session_state.dart';
import 'package:speedygo_merchant_app/features/auth/data/models.dart';

import 'phase1_flow_test.dart';

class ControllableLaunchStore implements LaunchStore {
  ControllableLaunchStore({
    this.languageSeen = false,
    this.locale = 'fr',
    this.onboardingSeen = false,
    this.failWrites = false,
    this.failOnboardingWrites = false,
    this.failReads = false,
  });

  bool languageSeen;
  String locale;
  bool onboardingSeen;
  bool failWrites;
  bool failOnboardingWrites;
  bool failReads;
  int writeLocaleCalls = 0;
  int markSeenCalls = 0;
  int markOnboardingCalls = 0;

  @override
  Future<bool> readLanguageSeen() async {
    if (failReads) throw StateError('launch-read-failed');
    return languageSeen;
  }

  @override
  Future<void> markLanguageSeen() async {
    markSeenCalls += 1;
    if (failWrites) throw StateError('launch-write-failed');
    languageSeen = true;
  }

  @override
  Future<String> readLocale() async {
    if (failReads) throw StateError('launch-read-failed');
    return locale;
  }

  @override
  Future<void> writeLocale(String value) async {
    writeLocaleCalls += 1;
    if (failWrites) throw StateError('launch-write-failed');
    locale = value;
  }

  @override
  Future<bool> readOnboardingSeen() async {
    if (failReads) throw StateError('launch-read-failed');
    return onboardingSeen;
  }

  @override
  Future<void> markOnboardingSeen() async {
    markOnboardingCalls += 1;
    if (failOnboardingWrites || failWrites) {
      throw StateError('onboarding-write-failed');
    }
    onboardingSeen = true;
  }
}

class DelayingLaunchStore implements LaunchStore {
  DelayingLaunchStore(this.inner, {required this.onRead});

  final LaunchStore inner;
  final Future<void> Function() onRead;

  @override
  Future<bool> readLanguageSeen() async {
    await onRead();
    return inner.readLanguageSeen();
  }

  @override
  Future<void> markLanguageSeen() => inner.markLanguageSeen();

  @override
  Future<String> readLocale() => inner.readLocale();

  @override
  Future<void> writeLocale(String locale) => inner.writeLocale(locale);

  @override
  Future<bool> readOnboardingSeen() => inner.readOnboardingSeen();

  @override
  Future<void> markOnboardingSeen() => inner.markOnboardingSeen();
}

Future<void> pumpStartup(
  WidgetTester tester,
  ProviderContainer container, {
  int frames = 40,
}) async {
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const SpeedyGoApp(),
    ),
  );
  await tester.pump();
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

Future<void> settle(WidgetTester tester, {int frames = 30}) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  testWidgets('bootstrap splash renders before resolution', (tester) async {
    final launch = ControllableLaunchStore(languageSeen: false);
    final container = testContainer(
      auth: FakeAuthApi(),
      merchant: FakeMerchantApi(),
      launch: launch,
      splashMin: const Duration(milliseconds: 400),
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const SpeedyGoApp(),
      ),
    );
    await tester.pump();
    expect(find.byKey(const Key('merchant-splash')), findsOneWidget);
    expect(find.byKey(const Key('merchant-splash-logo')), findsOneWidget);
    expect(find.text(AppStrings.splashTagline), findsOneWidget);
    expect(
      container.read(sessionControllerProvider).phase,
      SessionPhase.boot,
    );
    expect(find.byKey(const Key('merchant-language')), findsNothing);

    await tester.pump(const Duration(milliseconds: 450));
    await tester.pump();
    await settle(tester, frames: 20);
    expect(find.byKey(const Key('merchant-splash')), findsNothing);
    expect(find.byKey(const Key('merchant-language')), findsOneWidget);
  });

  testWidgets('no saved language shows language selection', (tester) async {
    final container = testContainer(
      auth: FakeAuthApi(),
      merchant: FakeMerchantApi(),
      launch: ControllableLaunchStore(languageSeen: false),
    );
    addTearDown(container.dispose);
    await pumpStartup(tester, container);
    expect(find.byKey(const Key('merchant-language')), findsOneWidget);
    expect(find.byKey(const Key('merchant-onboarding')), findsNothing);
    expect(find.text(AppStrings.phoneTitle), findsNothing);
  });

  testWidgets('Français tap saves and advances to onboarding', (tester) async {
    final launch = ControllableLaunchStore(languageSeen: false);
    final container = testContainer(
      auth: FakeAuthApi(),
      merchant: FakeMerchantApi(),
      launch: launch,
    );
    addTearDown(container.dispose);
    await pumpStartup(tester, container);

    await tester.tap(find.byKey(const Key('merchant-language-fr')));
    await settle(tester);

    expect(launch.languageSeen, isTrue);
    expect(launch.locale, 'fr');
    expect(launch.writeLocaleCalls, 1);
    expect(launch.markSeenCalls, 1);
    expect(find.byKey(const Key('merchant-onboarding')), findsOneWidget);
    expect(find.text(AppStrings.onboardingPage1Title), findsOneWidget);
    expect(find.byKey(const Key('merchant-language')), findsNothing);
    expect(find.text(AppStrings.phoneTitle), findsNothing);
  });

  testWidgets('Arabic tap saves RTL and advances to onboarding', (tester) async {
    final launch = ControllableLaunchStore(languageSeen: false);
    final container = testContainer(
      auth: FakeAuthApi(),
      merchant: FakeMerchantApi(),
      launch: launch,
    );
    addTearDown(container.dispose);
    await pumpStartup(tester, container);

    await tester.tap(find.byKey(const Key('merchant-language-ar')));
    await settle(tester);

    expect(launch.locale, 'ar');
    expect(launch.languageSeen, isTrue);
    expect(find.byKey(const Key('merchant-onboarding')), findsOneWidget);
    final directionality = tester.widget<Directionality>(
      find.byType(Directionality).first,
    );
    expect(directionality.textDirection, TextDirection.rtl);
  });

  testWidgets('saved language without onboarding shows intro', (tester) async {
    final container = testContainer(
      auth: FakeAuthApi(),
      merchant: FakeMerchantApi(),
      launch: ControllableLaunchStore(languageSeen: true, locale: 'fr'),
    );
    addTearDown(container.dispose);
    await pumpStartup(tester, container);
    expect(find.byKey(const Key('merchant-language')), findsNothing);
    expect(find.byKey(const Key('merchant-onboarding')), findsOneWidget);
    expect(find.text(AppStrings.phoneTitle), findsNothing);
  });

  testWidgets('saved language and onboarding skips to phone', (tester) async {
    final container = testContainer(
      auth: FakeAuthApi(),
      merchant: FakeMerchantApi(),
      launch: ControllableLaunchStore(
        languageSeen: true,
        onboardingSeen: true,
        locale: 'fr',
      ),
    );
    addTearDown(container.dispose);
    await pumpStartup(tester, container);
    expect(find.byKey(const Key('merchant-language')), findsNothing);
    expect(find.byKey(const Key('merchant-onboarding')), findsNothing);
    expect(find.text(AppStrings.phoneTitle), findsOneWidget);
  });

  testWidgets('failed language persistence shows recoverable error',
      (tester) async {
    final launch = ControllableLaunchStore(
      languageSeen: false,
      failWrites: true,
    );
    final container = testContainer(
      auth: FakeAuthApi(),
      merchant: FakeMerchantApi(),
      launch: launch,
    );
    addTearDown(container.dispose);
    await pumpStartup(tester, container);

    await tester.tap(find.byKey(const Key('merchant-language-fr')));
    await settle(tester);

    expect(find.byKey(const Key('merchant-language')), findsOneWidget);
    expect(find.text(AppStrings.languageSaveFailed), findsOneWidget);
    expect(find.byKey(const Key('merchant-onboarding')), findsNothing);
    expect(launch.languageSeen, isFalse);
  });

  testWidgets('bootstrap read failure reaches recoverable restore',
      (tester) async {
    final container = testContainer(
      auth: FakeAuthApi(),
      merchant: FakeMerchantApi(),
      launch: ControllableLaunchStore(failReads: true),
    );
    addTearDown(container.dispose);
    await pumpStartup(tester, container);
    expect(
      container.read(sessionControllerProvider).phase,
      SessionPhase.restoreRetryable,
    );
    expect(find.text(AppStrings.restoreRetry), findsOneWidget);
    expect(find.byKey(const Key('merchant-language')), findsNothing);
  });

  test('duplicate restore does not re-enter while in flight', () async {
    var reads = 0;
    final delaying = DelayingLaunchStore(
      ControllableLaunchStore(languageSeen: true, onboardingSeen: true),
      onRead: () async {
        reads += 1;
        await Future<void>.delayed(const Duration(milliseconds: 100));
      },
    );
    final container = testContainer(
      auth: FakeAuthApi(),
      merchant: FakeMerchantApi(),
      launch: delaying,
    );
    addTearDown(container.dispose);

    final first = container.read(sessionControllerProvider.notifier).restore();
    final second = container.read(sessionControllerProvider.notifier).restore();
    await Future.wait([first, second]);
    expect(reads, 1);
  });

  test('authenticated restore still respects merchant access routing',
      () async {
    final store = MemorySessionStore()
      ..value = const TokenPair(
        accessToken: 'a',
        refreshToken: 'r-token-value',
        expiresIn: 900,
        tokenType: 'Bearer',
      );
    final merchant = FakeMerchantApi(
      meHandler: () async => MerchantMe(
        merchantMembershipExists: true,
        memberships: [
          membership(
            status: 'PENDING_REVIEW',
            approved: false,
            operationalReady: false,
            branches: [branch('b1')],
          ),
        ],
      ),
    );
    final container = testContainer(
      auth: FakeAuthApi(),
      merchant: merchant,
      store: store,
      launch: ControllableLaunchStore(
        languageSeen: true,
        onboardingSeen: false,
      ),
    );
    addTearDown(container.dispose);
    container.read(tokenCacheProvider).current = store.value;
    await container.read(sessionControllerProvider.notifier).restore();
    await container.read(accessControllerProvider.notifier).resolve();
    expect(
      container.read(accessControllerProvider).destination,
      AccessDestination.registration,
    );
    expect(
      container.read(sessionControllerProvider).phase,
      isNot(SessionPhase.ready),
    );
    expect(
      container.read(sessionControllerProvider).onboardingSeen,
      isFalse,
    );
  });
}
