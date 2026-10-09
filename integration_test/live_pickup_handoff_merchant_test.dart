import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:speedygo_merchant_app/app/app.dart';
import 'package:speedygo_merchant_app/app/router/app_router.dart';
import 'package:speedygo_merchant_app/core/constants/app_constants.dart';
import 'package:speedygo_merchant_app/core/constants/app_strings.dart';
import 'package:speedygo_merchant_app/core/navigation/app_routes.dart';
import 'package:speedygo_merchant_app/core/storage/approval_notice_store.dart';
import 'package:speedygo_merchant_app/core/storage/session_store.dart';
import 'package:speedygo_merchant_app/features/auth/application/session_providers.dart';
import 'package:speedygo_merchant_app/features/notifications/application/merchant_push_controller.dart';
import 'package:speedygo_merchant_app/features/notifications/data/push_registration.dart';

/// Live Merchant pickup-handoff UI against isolated API :3100.
///
/// Phase: `code` shows PENDING code; `recheck` expects CONSUMED confirmation.
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

  const isolatedApi = 'http://127.0.0.1:3100/api/v1';
  const otpFilePath = String.fromEnvironment('FX_OTP_FILE');
  const evidenceDir = String.fromEnvironment('FX_EVIDENCE_DIR');
  const prefix = String.fromEnvironment(
    'PARITY_PREFIX',
    defaultValue: 'fxlive',
  );
  const phase = String.fromEnvironment(
    'LIVE_HANDOFF_PHASE',
    defaultValue: 'code',
  );
  const orderId = String.fromEnvironment('FX_ORDER_ID');
  const secretsPath = String.fromEnvironment('FX_SECRETS_PATH');
  const owner = '550009101';
  const merchantId = '0d00f0f0-fa00-7000-8000-000000001001';
  const branchId = '0d00f0f0-fa00-7000-8000-000000002001';
  const shotMarker = '/tmp/parity_fx_isolated_shot.txt';

  var memorySessions = MemorySessionStore();

  Future<void> pumpFrames(WidgetTester tester, Duration total) async {
    final end = DateTime.now().add(total);
    while (DateTime.now().isBefore(end)) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> waitFor(
    WidgetTester tester,
    Finder finder, {
    Duration timeout = const Duration(seconds: 35),
  }) async {
    final end = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(end)) {
      await pumpFrames(tester, const Duration(milliseconds: 200));
      if (finder.evaluate().isNotEmpty) return;
    }
    throw TestFailure('Timed out waiting for $finder');
  }

  Future<void> shot(WidgetTester tester, String tag) async {
    await pumpFrames(tester, const Duration(milliseconds: 1200));
    File(shotMarker).writeAsStringSync('${prefix}_$tag\n');
    await pumpFrames(tester, const Duration(seconds: 3));
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
    throw StateError('isolated OTP not found');
  }

  GoRouter routerOf(WidgetTester tester) => ProviderScope.containerOf(
    tester.element(find.byType(MaterialApp).first),
  ).read(appRouterProvider);

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await pumpFrames(tester, const Duration(milliseconds: 400));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionStoreProvider.overrideWithValue(memorySessions),
          contextStoreProvider.overrideWithValue(
            MemoryContextStore()
              ..merchantId = merchantId
              ..branchId = branchId,
          ),
          launchStoreProvider.overrideWithValue(
            MemoryLaunchStore(languageSeen: true, onboardingSeen: true),
          ),
          approvalNoticeStoreProvider.overrideWithValue(
            MemoryApprovalNoticeStore(),
          ),
          pushRegistrationStoreProvider.overrideWithValue(
            _MemoryPushRegistration(),
          ),
        ],
        child: const SpeedyGoApp(),
      ),
    );
    await pumpFrames(tester, const Duration(seconds: 6));
  }

  Future<void> login(WidgetTester tester) async {
    memorySessions = MemorySessionStore();
    await pumpApp(tester);
    await waitFor(tester, find.byKey(const Key('merchant-phone-continue')));
    File(shotMarker).writeAsStringSync('${prefix}_clear_otp\n');
    await pumpFrames(tester, const Duration(milliseconds: 800));
    await tester.enterText(find.byType(TextField).first, owner);
    await tester.pump(const Duration(milliseconds: 400));
    final otpBefore = DateTime.now().subtract(const Duration(seconds: 1));
    await tester.tap(find.byKey(const Key('merchant-phone-continue')));
    await waitFor(tester, find.byKey(const Key('merchant-otp-field')));
    final otp = await waitForFreshOtp(otpBefore);
    await tester.enterText(find.byKey(const Key('merchant-otp-field')), otp);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.byKey(const Key('merchant-otp-verify')));
    await waitFor(tester, find.byKey(const Key('home-branch-name')));
  }

  testWidgets('live merchant pickup handoff $phase', (tester) async {
    expect(AppConstants.apiBaseUrl, isolatedApi);
    expect(otpFilePath.isNotEmpty, isTrue);
    expect(orderId.isNotEmpty, isTrue);
    expect(secretsPath.isNotEmpty, isTrue);
    expect(evidenceDir.isNotEmpty, isTrue);

    await login(tester);
    routerOf(tester).go(AppRoutes.orderDetail(orderId));
    await pumpFrames(tester, const Duration(seconds: 5));
    await waitFor(tester, find.byKey(const Key('order-detail')));

    if (phase == 'recheck') {
      // Post-pickup contract: handoff chrome is AT_PICKUP-only; after confirm
      // Merchant shows assigned-driver deliveryStatus PICKED_UP ("Récupérée").
      await waitFor(
        tester,
        find.byKey(const Key('order-assigned-driver')),
        timeout: const Duration(seconds: 45),
      );
      await waitFor(
        tester,
        find.text(AppStrings.deliveryPickedUp),
        timeout: const Duration(seconds: 45),
      );
      expect(find.byKey(const Key('pickup-handoff-code')), findsNothing);
      await tester.ensureVisible(find.byKey(const Key('order-assigned-driver')));
      await shot(tester, 'merchant_post_confirm');
    } else {
      await waitFor(
        tester,
        find.byKey(const Key('pickup-handoff-code')),
        timeout: const Duration(seconds: 45),
      );
      final secrets =
          jsonDecode(File(secretsPath).readAsStringSync())
              as Map<String, dynamic>;
      final expected = (secrets['pickupCode'] ?? '').toString();
      expect(expected.length, 4);
      final shown = tester
          .widget<Text>(find.byKey(const Key('pickup-handoff-code')))
          .data!
          .replaceAll(RegExp(r'\s+'), '');
      expect(shown, expected);
      await tester.ensureVisible(find.byKey(const Key('pickup-handoff-code')));
      await shot(tester, 'merchant_pickup_code');
    }

    File(shotMarker).writeAsStringSync('${prefix}_99_done\n');
    await pumpFrames(tester, const Duration(seconds: 2));
  });
}
