import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:speedygo_merchant_app/app/app.dart';
import 'package:speedygo_merchant_app/core/constants/app_strings.dart';
import 'package:speedygo_merchant_app/core/storage/session_store.dart';

import '../test/features/phase1_flow_test.dart';
import '../test/features/startup_flow_test.dart';

/// Isolated first-run language flow on device. Does not touch Keychain session.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('live isolated: Français advances off language', (tester) async {
    final launch = ControllableLaunchStore(languageSeen: false);
    final container = testContainer(
      auth: FakeAuthApi(),
      merchant: FakeMerchantApi(),
      launch: launch,
      store: MemorySessionStore(),
      splashMin: const Duration(milliseconds: 300),
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

    await tester.pump(const Duration(milliseconds: 350));
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(find.byKey(const Key('merchant-language')), findsOneWidget);

    await tester.tap(find.byKey(const Key('merchant-language-fr')));
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    expect(launch.languageSeen, isTrue);
    expect(find.byKey(const Key('merchant-onboarding')), findsOneWidget);
    expect(find.text(AppStrings.onboardingPage1Title), findsOneWidget);
  });
}
