import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:speedygo_merchant_app/app/app.dart';
import 'package:speedygo_merchant_app/app/router/app_router.dart';
import 'package:speedygo_merchant_app/core/navigation/app_routes.dart';
import 'package:speedygo_merchant_app/core/storage/approval_notice_store.dart';
import 'package:speedygo_merchant_app/core/storage/session_store.dart';
import 'package:speedygo_merchant_app/features/auth/application/session_providers.dart';
import 'package:speedygo_merchant_app/features/notifications/application/merchant_push_controller.dart';
import 'package:speedygo_merchant_app/features/notifications/data/push_registration.dart';

/// Isolated live end-viewport capture for team roster FAB clearance.
/// Host: audit/parity/isolated/fx_team_end_live.sh
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

  testWidgets('fx team end live capture', (tester) async {
    expect(otpFilePath.isNotEmpty, isTrue);
    expect(apiBase.contains('3100'), isTrue);
    Directory(evidenceDir).createSync(recursive: true);

    File(shotMarker).writeAsStringSync('${prefix}_clear_otp\n');
    await pumpFrames(tester, const Duration(seconds: 3));

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
      ownerPhone,
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
    checks['ownerLogin'] = true;

    final router = ProviderScope.containerOf(
      tester.element(find.byType(MaterialApp).first),
    ).read(appRouterProvider);
    router.push(AppRoutes.team);
    await pumpFrames(tester, const Duration(seconds: 3));
    await waitFor(tester, find.byKey(const Key('team-screen')));
    await pumpFrames(tester, const Duration(seconds: 1));

    final scrollable = find.descendant(
      of: find.byKey(const Key('team-screen')),
      matching: find.byType(Scrollable),
    );
    final position = tester.state<ScrollableState>(scrollable).position;
    for (var i = 0; i < 8; i++) {
      position.jumpTo(position.maxScrollExtent);
      await pumpFrames(tester, const Duration(milliseconds: 400));
      if (position.pixels >= position.maxScrollExtent) break;
    }
    await waitFor(tester, find.byKey(const Key('team-roles-summary')));
    await shot(tester, 'team_end');
    checks['teamEnd'] = true;

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
