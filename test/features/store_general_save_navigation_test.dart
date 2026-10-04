import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speedygo_merchant_app/app/router/app_router.dart';
import 'package:speedygo_merchant_app/core/constants/app_strings.dart';
import 'package:speedygo_merchant_app/core/navigation/app_routes.dart';
import 'package:speedygo_merchant_app/core/storage/session_store.dart';
import 'package:speedygo_merchant_app/features/access/data/models.dart';
import 'package:speedygo_merchant_app/features/auth/application/session_providers.dart';
import 'package:speedygo_merchant_app/features/auth/data/models.dart';

import 'phase1_flow_test.dart';

/// Saving the branch name refreshes access state, which refreshes the
/// router. The saved screen must stay closed rather than be rebuilt from the
/// route information reported before the pop.
void main() {
  testWidgets('saving the branch name returns to the previous screen', (
    tester,
  ) async {
    var meCalls = 0;
    var name = 'Branch b1';
    final merchant = FakeMerchantApi(
      meHandler: () async {
        meCalls++;
        return MerchantMe(
          merchantMembershipExists: true,
          memberships: [
            membership(branches: [branch('b1', name: name)]),
          ],
        );
      },
    );
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
    );
    addTearDown(container.dispose);
    container.read(tokenCacheProvider).current = store.value;

    await pumpApp(tester, container);
    expect(find.byKey(const Key('home-branch-name')), findsOneWidget);

    container.read(appRouterProvider).push(AppRoutes.storeGeneral);
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    final field = find.byKey(const Key('store-general-branch-name'));
    expect(field, findsOneWidget);

    name = 'Branch renamed';
    await tester.enterText(field, name);
    await tester.pump();
    final callsBeforeSave = meCalls;
    await tester.tap(find.byKey(const Key('store-general-save')));
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    expect(meCalls, greaterThan(callsBeforeSave));
    expect(find.text(AppStrings.storeGeneralSaved), findsOneWidget);
    expect(field, findsNothing);
    expect(find.byKey(const Key('store-general-screen')), findsNothing);
    expect(
      container
          .read(appRouterProvider)
          .routerDelegate
          .currentConfiguration
          .uri
          .path,
      AppRoutes.home,
    );
    expect(find.byKey(const Key('home-branch-name')), findsOneWidget);
    expect(find.textContaining('Branch renamed'), findsWidgets);
  });
}
