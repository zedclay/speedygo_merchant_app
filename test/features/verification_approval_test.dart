import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speedygo_merchant_app/app/router/app_router.dart';
import 'package:speedygo_merchant_app/core/constants/app_strings.dart';
import 'package:speedygo_merchant_app/core/errors/app_exception.dart';
import 'package:speedygo_merchant_app/core/navigation/app_routes.dart';
import 'package:speedygo_merchant_app/core/storage/approval_notice_store.dart';
import 'package:speedygo_merchant_app/core/storage/session_store.dart';
import 'package:speedygo_merchant_app/features/access/application/access_controller.dart';
import 'package:speedygo_merchant_app/features/access/data/models.dart';
import 'package:speedygo_merchant_app/features/auth/application/session_controller.dart';
import 'package:speedygo_merchant_app/features/auth/application/session_providers.dart';
import 'package:speedygo_merchant_app/features/auth/application/session_state.dart';
import 'package:speedygo_merchant_app/features/auth/data/models.dart';
import 'package:speedygo_merchant_app/features/store/presentation/opening_hours_screen.dart';

import 'phase1_flow_test.dart';

const _tokens = TokenPair(
  accessToken: 'a',
  refreshToken: 'r-token-value',
  expiresIn: 900,
  tokenType: 'Bearer',
);

MerchantMe _me(MerchantMembership m) =>
    MerchantMe(merchantMembershipExists: true, memberships: [m]);

MerchantMembership _pending({List<MerchantBranch> branches = const []}) =>
    membership(
      status: 'PENDING_REVIEW',
      approved: false,
      operationalReady: false,
      verificationSubmitted: true,
      branches: branches,
    );

MerchantMembership _rejected() => membership(
  status: 'REJECTED',
  approved: false,
  operationalReady: false,
  verificationSubmitted: true,
  branches: [branch('b1')],
);

MerchantMembership _approved({List<MerchantBranch>? branches}) =>
    membership(branches: branches ?? [branch('b1')]);

class _Server {
  _Server(this.current);
  MerchantMembership current;
  Object? error;

  Future<MerchantMe> me() async {
    final e = error;
    if (e != null) throw e;
    return _me(current);
  }
}

AuthMe _authMe(String accountId) => AuthMe(
  accountId: accountId,
  phone: '+213550000001',
  status: 'ACTIVE',
  hasMerchantMembership: true,
);

class _ThrowingApprovalStore implements ApprovalNoticeStore {
  @override
  Future<ApprovalNoticeState> read(String accountId, String merchantId) =>
      Future.error(StateError('keychain unavailable'));

  @override
  Future<void> markAcknowledged(String accountId, String merchantId) =>
      Future.error(StateError('keychain unavailable'));

  @override
  Future<void> markObservedUnapproved(String accountId, String merchantId) =>
      Future.error(StateError('keychain unavailable'));
}

ProviderContainer _container(
  _Server server,
  ApprovalNoticeStore approvals, {
  String accountId = 'acc-1',
}) {
  final store = MemorySessionStore()..value = _tokens;
  final container = testContainer(
    auth: FakeAuthApi(meHandler: () async => _authMe(accountId)),
    merchant: FakeMerchantApi(meHandler: server.me),
    store: store,
    approvals: approvals,
  );
  container.read(tokenCacheProvider).current = store.value;
  return container;
}

AccessDestination _destination(ProviderContainer c) =>
    c.read(accessControllerProvider).destination;

void main() {
  test('pending then confirmed approval shows the notice once', () async {
    final approvals = MemoryApprovalNoticeStore();
    final server = _Server(_pending(branches: [branch('b1')]));
    final c = _container(server, approvals);
    addTearDown(c.dispose);

    await restoreAndResolve(c);
    expect(_destination(c), AccessDestination.verificationPending);
    expect(
      await approvals.read('acc-1', 'm-1'),
      ApprovalNoticeState.observedUnapproved,
    );

    server.current = _approved();
    await c.read(accessControllerProvider.notifier).refreshInPlace();
    expect(_destination(c), AccessDestination.verificationApproved);
    expect(c.read(sessionControllerProvider).phase, SessionPhase.resolvingAccess);
    expect(
      await approvals.read('acc-1', 'm-1'),
      ApprovalNoticeState.observedUnapproved,
      reason: 'resolving to the notice must not acknowledge it',
    );
  });

  test('rejected then confirmed approval also shows the notice', () async {
    final approvals = MemoryApprovalNoticeStore();
    final server = _Server(_rejected());
    final c = _container(server, approvals);
    addTearDown(c.dispose);

    await restoreAndResolve(c);
    expect(_destination(c), AccessDestination.verificationRejected);
    server.current = _approved();
    await c.read(accessControllerProvider.notifier).resolve();
    expect(_destination(c), AccessDestination.verificationApproved);
  });

  test('approval without a prior local observation goes straight home', () async {
    final approvals = MemoryApprovalNoticeStore();
    final c = _container(_Server(_approved()), approvals);
    addTearDown(c.dispose);

    await restoreAndResolve(c);
    expect(_destination(c), AccessDestination.home);
    expect(await approvals.read('acc-1', 'm-1'), ApprovalNoticeState.none);
  });

  test('a local observation alone never shows congratulations', () async {
    final approvals = MemoryApprovalNoticeStore();
    await approvals.markObservedUnapproved('acc-1', 'm-1');

    final pendingServer = _Server(_pending(branches: [branch('b1')]));
    final c1 = _container(pendingServer, approvals);
    addTearDown(c1.dispose);
    await restoreAndResolve(c1);
    expect(_destination(c1), AccessDestination.verificationPending);

    final suspended = _Server(
      membership(status: 'SUSPENDED', branches: [branch('b1')]),
    );
    final c2 = _container(suspended, approvals);
    addTearDown(c2.dispose);
    await restoreAndResolve(c2);
    expect(_destination(c2), AccessDestination.verificationSuspended);

    final failing = _Server(_approved())
      ..error = const ApiException('down', code: 'SERVICE_UNAVAILABLE');
    final c3 = _container(failing, approvals);
    addTearDown(c3.dispose);
    await restoreAndResolve(c3);
    expect(_destination(c3), AccessDestination.error);
    expect(
      await approvals.read('acc-1', 'm-1'),
      ApprovalNoticeState.observedUnapproved,
    );
  });

  test('cold restart still shows the unacknowledged notice', () async {
    final approvals = MemoryApprovalNoticeStore();
    final server = _Server(_pending(branches: [branch('b1')]));
    final first = _container(server, approvals);
    await restoreAndResolve(first);
    server.current = _approved();
    await first.read(accessControllerProvider.notifier).resolve();
    expect(_destination(first), AccessDestination.verificationApproved);
    first.dispose();

    final second = _container(server, approvals);
    addTearDown(second.dispose);
    await restoreAndResolve(second);
    expect(_destination(second), AccessDestination.verificationApproved);
  });

  test('acknowledgement persists and resumes server routing', () async {
    final approvals = MemoryApprovalNoticeStore();
    final server = _Server(_pending(branches: [branch('b1')]));
    final c = _container(server, approvals);
    addTearDown(c.dispose);
    await restoreAndResolve(c);
    server.current = _approved();
    await c.read(accessControllerProvider.notifier).resolve();

    final ready = await c
        .read(accessControllerProvider.notifier)
        .acknowledgeApproval();
    expect(ready, isTrue);
    expect(_destination(c), AccessDestination.home);
    expect(c.read(sessionControllerProvider).phase, SessionPhase.ready);
    expect(
      await approvals.read('acc-1', 'm-1'),
      ApprovalNoticeState.acknowledged,
    );

    final restarted = _container(server, approvals);
    addTearDown(restarted.dispose);
    await restoreAndResolve(restarted);
    expect(_destination(restarted), AccessDestination.home);
  });

  test('acknowledge is ignored outside the approval destination', () async {
    final approvals = MemoryApprovalNoticeStore();
    final c = _container(_Server(_pending(branches: [branch('b1')])), approvals);
    addTearDown(c.dispose);
    await restoreAndResolve(c);

    final ready = await c
        .read(accessControllerProvider.notifier)
        .acknowledgeApproval();
    expect(ready, isFalse);
    expect(_destination(c), AccessDestination.verificationPending);
    expect(
      await approvals.read('acc-1', 'm-1'),
      ApprovalNoticeState.observedUnapproved,
    );
  });

  test('observations are isolated per account', () async {
    final approvals = MemoryApprovalNoticeStore();
    final server = _Server(_pending(branches: [branch('b1')]));
    final first = _container(server, approvals, accountId: 'acc-1');
    await restoreAndResolve(first);
    first.dispose();

    server.current = _approved();
    final other = _container(server, approvals, accountId: 'acc-2');
    addTearDown(other.dispose);
    await restoreAndResolve(other);
    expect(_destination(other), AccessDestination.home);
    expect(await approvals.read('acc-2', 'm-1'), ApprovalNoticeState.none);
    expect(
      await approvals.read('acc-1', 'm-1'),
      ApprovalNoticeState.observedUnapproved,
    );
  });

  test('need-branch: acknowledgement routes to the branch step', () async {
    final approvals = MemoryApprovalNoticeStore();
    final server = _Server(_pending());
    final c = _container(server, approvals);
    addTearDown(c.dispose);
    await restoreAndResolve(c);
    server.current = _approved(branches: const []);
    await c.read(accessControllerProvider.notifier).resolve();
    expect(_destination(c), AccessDestination.verificationApproved);

    final ready = await c
        .read(accessControllerProvider.notifier)
        .acknowledgeApproval();
    expect(ready, isFalse);
    expect(_destination(c), AccessDestination.needBranch);
  });

  test('storage failure never produces the notice', () async {
    final server = _Server(_pending(branches: [branch('b1')]));
    final c = _container(server, _ThrowingApprovalStore());
    addTearDown(c.dispose);
    await restoreAndResolve(c);
    expect(_destination(c), AccessDestination.verificationPending);
    server.current = _approved();
    await c.read(accessControllerProvider.notifier).resolve();
    expect(_destination(c), AccessDestination.home);
  });

  group('screen', () {
    Future<ProviderContainer> showNotice(
      WidgetTester tester, {
      List<MerchantBranch>? branches,
    }) async {
      final approvals = MemoryApprovalNoticeStore();
      await approvals.markObservedUnapproved('acc-1', 'm-1');
      final c = _container(_Server(_approved(branches: branches)), approvals);
      addTearDown(c.dispose);
      await pumpApp(tester, c);
      expect(
        find.byKey(const Key('merchant-verification-approved')),
        findsOneWidget,
      );
      return c;
    }

    testWidgets('renders real membership data and stays unacknowledged', (
      tester,
    ) async {
      final c = await showNotice(tester);
      expect(find.text(AppStrings.approvedTitle), findsOneWidget);
      expect(find.text('Demo Merchant'), findsOneWidget);
      expect(find.text('#sgm_1'), findsOneWidget);
      expect(find.text(AppStrings.profileRoleOwner), findsOneWidget);
      expect(find.text(AppStrings.approvedContinue), findsOneWidget);
      final approvals =
          c.read(approvalNoticeStoreProvider) as MemoryApprovalNoticeStore;
      expect(
        await approvals.read('acc-1', 'm-1'),
        ApprovalNoticeState.observedUnapproved,
      );
    });

    testWidgets('CTA acknowledges and lands on home', (tester) async {
      final c = await showNotice(tester);
      await tester.tap(find.byKey(const Key('merchant-approved-continue')));
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      expect(c.read(sessionControllerProvider).phase, SessionPhase.ready);
      expect(
        c.read(appRouterProvider).routerDelegate.currentConfiguration.uri.path,
        AppRoutes.home,
      );
    });

    testWidgets('Horaires link acknowledges then opens opening hours', (
      tester,
    ) async {
      final c = await showNotice(tester);
      await tester.ensureVisible(find.byKey(const Key('merchant-approved-hours')));
      await tester.tap(find.byKey(const Key('merchant-approved-hours')));
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      expect(c.read(sessionControllerProvider).phase, SessionPhase.ready);
      expect(find.byType(OpeningHoursScreen), findsOneWidget);
      expect(
        c
            .read(appRouterProvider)
            .routerDelegate
            .currentConfiguration
            .last
            .matchedLocation,
        AppRoutes.openingHours,
      );
    });

    testWidgets('need-branch disables setup links and routes to branch step', (
      tester,
    ) async {
      final c = await showNotice(tester, branches: const []);
      expect(find.text(AppStrings.approvedNeedBranchHint), findsNWidgets(3));
      expect(find.text(AppStrings.addBranch), findsOneWidget);

      await tester.ensureVisible(find.byKey(const Key('merchant-approved-hours')));
      await tester.tap(find.byKey(const Key('merchant-approved-hours')));
      await tester.pump(const Duration(milliseconds: 100));
      expect(_destination(c), AccessDestination.verificationApproved);

      await tester.tap(find.byKey(const Key('merchant-approved-continue')));
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      expect(_destination(c), AccessDestination.needBranch);
      expect(
        c.read(appRouterProvider).routerDelegate.currentConfiguration.uri.path,
        AppRoutes.needBranch,
      );
    });

    testWidgets('fits at text scale 1.35 on a 375 pt screen', (tester) async {
      tester.view.physicalSize = const Size(375 * 3, 812 * 3);
      tester.view.devicePixelRatio = 3;
      tester.platformDispatcher.textScaleFactorTestValue = 1.35;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await showNotice(tester);
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.byKey(const Key('merchant-approved-note')));
      expect(tester.takeException(), isNull);
    });
  });
}
