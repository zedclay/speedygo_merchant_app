import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:speedygo_merchant_app/app/app.dart';
import 'package:speedygo_merchant_app/app/router/app_router.dart';
import 'package:speedygo_merchant_app/core/navigation/app_routes.dart';
import 'package:speedygo_merchant_app/core/storage/approval_notice_store.dart';
import 'package:speedygo_merchant_app/core/storage/session_store.dart';
import 'package:speedygo_merchant_app/features/auth/application/session_controller.dart';
import 'package:speedygo_merchant_app/features/auth/application/session_providers.dart';
import 'package:speedygo_merchant_app/features/notifications/application/merchant_push_controller.dart';
import 'package:speedygo_merchant_app/features/notifications/data/push_registration.dart';

/// Isolated live captures for Merchant Team Management (row 64).
/// Host: audit/parity/isolated/fx_team_live.sh
class _MemoryPushRegistration extends MerchantPushRegistration {
  StoredPushToken? _stored;

  @override
  Future<void> storeRegisteredToken({
    required String token,
    required String platform,
    required String? accountId,
  }) async {
    _stored = (token: token, platform: platform, accountId: accountId);
  }

  @override
  Future<StoredPushToken?> loadStoredToken() async => _stored;

  @override
  Future<void> clearStoredToken() async => _stored = null;
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const otpFilePath = String.fromEnvironment('FX_OTP_FILE');
  const evidenceDir = String.fromEnvironment('FX_EVIDENCE_DIR');
  const prefix = String.fromEnvironment('PARITY_PREFIX', defaultValue: 'fxteam');
  const ownerPhone = String.fromEnvironment(
    'FX_OWNER_PHONE',
    defaultValue: '550009101',
  );
  const staffPhone = String.fromEnvironment(
    'FX_STAFF_PHONE',
    defaultValue: '550009103',
  );
  const shotMarker = '/tmp/parity_fx_isolated_shot.txt';
  const apiBase = String.fromEnvironment('API_BASE_URL');

  final sessions = MemorySessionStore();
  final contexts = MemoryContextStore();
  final launches = MemoryLaunchStore();
  final approvals = MemoryApprovalNoticeStore();
  final pushTokens = _MemoryPushRegistration();
  final checks = <String, Object?>{};

  Future<void> pumpFrames(WidgetTester tester, Duration total) async {
    final end = DateTime.now().add(total);
    while (DateTime.now().isBefore(end)) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> waitFor(
    WidgetTester tester,
    Finder finder, {
    Duration timeout = const Duration(seconds: 45),
  }) async {
    final end = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(end)) {
      await pumpFrames(tester, const Duration(milliseconds: 200));
      if (finder.evaluate().isNotEmpty) return;
    }
    throw TestFailure('Timed out waiting for $finder');
  }

  Future<void> tapVisible(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await pumpFrames(tester, const Duration(milliseconds: 350));
    await tester.tap(finder, warnIfMissed: false);
    await pumpFrames(tester, const Duration(milliseconds: 400));
  }

  Future<void> shot(WidgetTester tester, String tag) async {
    FocusManager.instance.primaryFocus?.unfocus();
    await pumpFrames(tester, const Duration(milliseconds: 1200));
    File(shotMarker).writeAsStringSync('${prefix}_$tag\n');
    await pumpFrames(tester, const Duration(seconds: 2));
  }

  Future<String> waitForFreshOtp(DateTime after) async {
    final file = File(otpFilePath);
    for (var i = 0; i < 80; i++) {
      if (file.existsSync() && !file.lastModifiedSync().isBefore(after)) {
        final otp = file.readAsStringSync().trim();
        if (RegExp(r'^\d{4,8}$').hasMatch(otp)) return otp;
      }
      await Future<void>.delayed(const Duration(milliseconds: 250));
    }
    throw StateError('OTP not found');
  }

  Future<void> pumpApp(WidgetTester tester) => tester.pumpWidget(
        ProviderScope(
          key: UniqueKey(),
          overrides: [
            sessionStoreProvider.overrideWithValue(sessions),
            contextStoreProvider.overrideWithValue(contexts),
            launchStoreProvider.overrideWithValue(launches),
            approvalNoticeStoreProvider.overrideWithValue(approvals),
            pushRegistrationStoreProvider.overrideWithValue(pushTokens),
          ],
          child: const SpeedyGoApp(),
        ),
      );

  GoRouter routerOf(WidgetTester tester) => ProviderScope.containerOf(
        tester.element(find.byType(MaterialApp).first),
      ).read(appRouterProvider);

  ProviderContainer containerOf(WidgetTester tester) =>
      ProviderScope.containerOf(tester.element(find.byType(MaterialApp).first));

  Future<void> requestOtpClear(WidgetTester tester) async {
    File(shotMarker).writeAsStringSync('${prefix}_clear_otp\n');
    await pumpFrames(tester, const Duration(seconds: 3));
  }

  Future<void> login(WidgetTester tester, String phoneLocal) async {
    await pumpApp(tester);
    final end = DateTime.now().add(const Duration(seconds: 90));
    while (find.byKey(const Key('merchant-phone-field')).evaluate().isEmpty) {
      if (DateTime.now().isAfter(end)) {
        throw TestFailure('phone login not reached');
      }
      if (find.byKey(const Key('merchant-language-fr')).evaluate().isNotEmpty) {
        final scrollables = find.byType(Scrollable);
        if (scrollables.evaluate().isNotEmpty) {
          await tester.drag(scrollables.first, const Offset(0, -240));
          await pumpFrames(tester, const Duration(milliseconds: 400));
        }
        await tapVisible(tester, find.byKey(const Key('merchant-language-fr')));
      } else if (find
          .byKey(const Key('merchant-onboarding-skip'))
          .evaluate()
          .isNotEmpty) {
        await tapVisible(
          tester,
          find.byKey(const Key('merchant-onboarding-skip')),
        );
      }
      await pumpFrames(tester, const Duration(milliseconds: 500));
    }
    await tester.enterText(
      find.byKey(const Key('merchant-phone-field')),
      phoneLocal,
    );
    await tester.pump(const Duration(milliseconds: 400));
    final otpBefore = DateTime.now().subtract(const Duration(seconds: 1));
    await tapVisible(tester, find.byKey(const Key('merchant-phone-continue')));
    await waitFor(tester, find.byKey(const Key('merchant-otp-field')));
    final otp = await waitForFreshOtp(otpBefore);
    await tester.enterText(find.byKey(const Key('merchant-otp-field')), otp);
    await tester.pump(const Duration(milliseconds: 300));
    await tapVisible(tester, find.byKey(const Key('merchant-otp-verify')));
    await pumpFrames(tester, const Duration(seconds: 5));
    await waitFor(tester, find.byKey(const Key('home-branch-name')));
  }

  Future<void> logout(WidgetTester tester) async {
    await containerOf(tester).read(sessionControllerProvider.notifier).logout();
    await pumpFrames(tester, const Duration(seconds: 2));
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 300));
    await requestOtpClear(tester);
  }

  Future<void> openTeam(WidgetTester tester) async {
    final router = routerOf(tester);
    router.push(AppRoutes.team);
    await pumpFrames(tester, const Duration(seconds: 3));
    await waitFor(tester, find.byKey(const Key('team-screen')));
  }

  testWidgets('fx team live captures', (tester) async {
    expect(otpFilePath.isNotEmpty, isTrue);
    expect(apiBase.contains('3100'), isTrue);
    Directory(evidenceDir).createSync(recursive: true);

    await requestOtpClear(tester);
    await login(tester, ownerPhone);
    checks['ownerLogin'] = true;

    // Settings entry point (Gestion de l’équipe).
    routerOf(tester).push(AppRoutes.settings);
    await pumpFrames(tester, const Duration(seconds: 2));
    await waitFor(tester, find.byKey(const Key('settings-team')));
    await shot(tester, 'settings_owner');
    await tapVisible(tester, find.byKey(const Key('settings-team')));
    await waitFor(tester, find.byKey(const Key('team-screen')));
    await shot(tester, 'team_top');
    checks['teamTop'] = true;

    final scrollables = find.byType(Scrollable);
    if (scrollables.evaluate().isNotEmpty) {
      await tester.drag(scrollables.first, const Offset(0, -700));
      await pumpFrames(tester, const Duration(milliseconds: 800));
    }
    await shot(tester, 'team_end');
    checks['teamEnd'] = true;

    await tapVisible(tester, find.byKey(const Key('team-invite-fab')));
    await waitFor(tester, find.byKey(const Key('team-invite-sheet')));
    await shot(tester, 'team_invite_sheet');
    checks['inviteSheet'] = true;
    Navigator.of(
      tester.element(find.byKey(const Key('team-invite-sheet'))),
    ).pop();
    await pumpFrames(tester, const Duration(milliseconds: 600));

    // Cold relaunch: new app instance with persisted session.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 300));
    await pumpApp(tester);
    await pumpFrames(tester, const Duration(seconds: 5));
    await waitFor(tester, find.byKey(const Key('home-branch-name')));
    await openTeam(tester);
    await shot(tester, 'team_cold');
    checks['teamCold'] = true;

    await logout(tester);
    await login(tester, staffPhone);
    routerOf(tester).push(AppRoutes.settings);
    await pumpFrames(tester, const Duration(seconds: 2));
    checks['staffNoTeamRow'] =
        find.byKey(const Key('settings-team')).evaluate().isEmpty;
    await shot(tester, 'settings_staff');
    routerOf(tester).push(AppRoutes.team);
    await pumpFrames(tester, const Duration(seconds: 3));
    await waitFor(tester, find.byKey(const Key('team-forbidden')));
    await shot(tester, 'team_staff_denied');
    checks['staffDenied'] = true;

    File(shotMarker).writeAsStringSync('${prefix}_99_done\n');
    await pumpFrames(tester, const Duration(seconds: 2));

    File('$evidenceDir/CHECKS_$prefix.json').writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert({
        'prefix': prefix,
        'apiBase': apiBase,
        'checks': checks,
        'backend': 'isolated speedygo_parity_fx',
        'at': DateTime.now().toUtc().toIso8601String(),
      }),
    );
  });
}
