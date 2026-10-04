import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:speedygo_merchant_app/app/app.dart';
import 'package:speedygo_merchant_app/core/constants/app_strings.dart';
import 'package:speedygo_merchant_app/core/storage/approval_notice_store.dart';
import 'package:speedygo_merchant_app/core/storage/session_store.dart';
import 'package:speedygo_merchant_app/features/access/application/access_controller.dart';
import 'package:speedygo_merchant_app/features/access/application/registration_controller.dart';
import 'package:speedygo_merchant_app/features/access/data/evidence_file_picker.dart';
import 'package:speedygo_merchant_app/features/auth/application/session_controller.dart';
import 'package:speedygo_merchant_app/features/auth/application/session_providers.dart';
import 'package:speedygo_merchant_app/features/auth/application/session_state.dart';
import 'package:speedygo_merchant_app/features/notifications/application/merchant_push_controller.dart';
import 'package:speedygo_merchant_app/features/notifications/data/push_registration.dart';

/// Push token record kept in memory so the device Keychain record (which may
/// belong to another Account's session) is never read, rotated or cleared.
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

/// Live Batch 7 captures on an isolated fixture account (dev backend).
///
/// Phase `register`: OTP login with a fresh fixture phone, real registration
/// through the UI (acceptance evidence picker), submit, pending, logout.
/// Phase `rejected` (after the host rejects the dossier through the admin
/// API): login, rejected screen, correction-mode review, logout.
/// Phase `approval` (D-G2): login on a pending or rejected dossier (a rejected
/// one is resubmitted through the correction flow), signal the host, which
/// approves it through the admin API; then refresh → approval screen, cold
/// restart (notice persists), acknowledgement → server routing, cold restart
/// (notice gone), logout. All stores are shared across the in-process cold
/// restarts and never leave memory.
///
/// Session, selected-merchant and push-token state live in memory only: a
/// session already stored in the device Keychain is never read, used or
/// cleared. Each phase revokes only the session it created. Screenshots are taken by
/// `audit/parity/live/run_parity_b7_live.sh`; OTPs are never printed.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const phoneLocal = String.fromEnvironment('B7_PHONE');
  const phase = String.fromEnvironment('B7_PHASE');
  const prefix = String.fromEnvironment('PARITY_PREFIX', defaultValue: 'live');
  const merchantName = String.fromEnvironment(
    'B7_MERCHANT_NAME',
    defaultValue: 'Fixture Parité B7',
  );
  const otpFilePath = '/Users/mac/.speedygo/dev/otp-last';
  const shotMarker = '/tmp/parity_live_shot.txt';
  const signalFile = '/tmp/parity_b7_signal.txt';
  // Comma-separated tags to capture (empty = all; "none" = no screenshots).
  final onlyTags = const String.fromEnvironment('B7_ONLY')
      .split(',')
      .map((t) => t.trim())
      .where((t) => t.isNotEmpty)
      .toSet();
  final sessions = MemorySessionStore();
  final contexts = MemoryContextStore();
  final launches = MemoryLaunchStore();
  final approvals = MemoryApprovalNoticeStore();
  final pushTokens = _MemoryPushRegistration();
  final checks = <String, Object?>{};
  var sessionCreated = false;
  final outDir = Directory(
    '/Users/mac/Downloads/speedygo_project/apps/merchant_app/audit/parity/live',
  )..createSync(recursive: true);
  final steps = <Map<String, Object?>>[];

  Future<void> pumpFrames(WidgetTester tester, Duration total) async {
    final end = DateTime.now().add(total);
    while (DateTime.now().isBefore(end)) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> waitFor(
    WidgetTester tester,
    Finder finder, {
    Duration timeout = const Duration(seconds: 30),
  }) async {
    final end = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(end)) {
      await pumpFrames(tester, const Duration(milliseconds: 200));
      if (finder.evaluate().isNotEmpty) return;
    }
    throw TestFailure('Timed out waiting for $finder');
  }

  Future<void> tapVisible(WidgetTester tester, Finder finder) async {
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.ensureVisible(finder);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(finder, warnIfMissed: false);
    await tester.pump(const Duration(milliseconds: 200));
  }

  Future<void> shot(WidgetTester tester, String tag) async {
    if (onlyTags.isNotEmpty && !onlyTags.contains(tag)) return;
    FocusManager.instance.primaryFocus?.unfocus();
    await pumpFrames(tester, const Duration(milliseconds: 1500));
    File(shotMarker).writeAsStringSync('${prefix}_$tag\n');
    await pumpFrames(tester, const Duration(seconds: 3));
    steps.add({'tag': '${prefix}_$tag', 'at': DateTime.now().toUtc().toIso8601String()});
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

  ProviderContainer containerOf(WidgetTester tester) =>
      ProviderScope.containerOf(tester.element(find.byType(MaterialApp).first));

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

  /// Cold start inside the same process: a new app instance over the same
  /// (in-memory) stores, as after the app is killed and reopened.
  Future<void> coldRestart(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 500));
    await pumpApp(tester);
    await pumpFrames(tester, const Duration(seconds: 6));
  }

  Future<void> login(WidgetTester tester) async {
    await pumpApp(tester);
    // Dedicated session only (never reuse a restored one): walk the first-run
    // screens as they appear, and stop if an authenticated screen shows up.
    final restoredMarkers = [
      find.byKey(const Key('home-branch-name')),
      find.byKey(const Key('merchant-registration')),
      find.byKey(const Key('merchant-verification-pending')),
      find.byKey(const Key('merchant-verification-rejected')),
    ];
    final end = DateTime.now().add(const Duration(seconds: 60));
    while (find.byKey(const Key('merchant-phone-field')).evaluate().isEmpty) {
      if (restoredMarkers.any((f) => f.evaluate().isNotEmpty)) {
        await shot(tester, 'b7_guard_restored');
        throw TestFailure('existing session restored; refusing to use it');
      }
      if (DateTime.now().isAfter(end)) {
        await shot(tester, 'b7_guard_timeout');
        throw TestFailure('phone login screen not reached');
      }
      if (find.byKey(const Key('merchant-language-fr')).evaluate().isNotEmpty) {
        await tester.tap(find.byKey(const Key('merchant-language-fr')));
      } else if (find
          .byKey(const Key('merchant-onboarding-skip'))
          .evaluate()
          .isNotEmpty) {
        await tester.tap(find.byKey(const Key('merchant-onboarding-skip')));
      }
      await pumpFrames(tester, const Duration(milliseconds: 500));
    }
    await tester.enterText(find.byKey(const Key('merchant-phone-field')), phoneLocal);
    await tester.pump(const Duration(milliseconds: 400));
    final otpBefore = DateTime.now().subtract(const Duration(seconds: 1));
    await tester.tap(find.byKey(const Key('merchant-phone-continue')));
    await waitFor(tester, find.byKey(const Key('merchant-otp-field')));
    final otp = await waitForFreshOtp(otpBefore);
    await tester.enterText(find.byKey(const Key('merchant-otp-field')), otp);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.byKey(const Key('merchant-otp-verify')));
    sessionCreated = true;
    await pumpFrames(tester, const Duration(seconds: 4));
  }

  Future<void> pickFromSheet(
    WidgetTester tester,
    Key field,
    String query,
    String tile,
  ) async {
    await tapVisible(tester, find.byKey(field));
    await pumpFrames(tester, const Duration(seconds: 3));
    await tester.enterText(find.byType(TextField).last, query);
    await pumpFrames(tester, const Duration(seconds: 1));
    final item = find.widgetWithText(ListTile, tile);
    await waitFor(tester, item);
    await tester.ensureVisible(item.first);
    await tester.tap(item.first);
    await pumpFrames(tester, const Duration(seconds: 3));
  }

  Future<void> logoutThisSession(WidgetTester tester) async {
    await containerOf(tester).read(sessionControllerProvider.notifier).logout();
    await waitFor(tester, find.byKey(const Key('merchant-phone-field')));
  }

  /// Revokes the session this run created if the phase stopped early.
  Future<void> revokeIfStillSignedIn(WidgetTester tester) async {
    if (!sessionCreated) return;
    final app = find.byType(MaterialApp);
    if (app.evaluate().isEmpty) {
      await pumpApp(tester);
      await pumpFrames(tester, const Duration(seconds: 4));
    }
    final container = containerOf(tester);
    if (container.read(sessionControllerProvider).phase ==
        SessionPhase.signedOut) {
      return;
    }
    await container.read(sessionControllerProvider.notifier).logout();
    await pumpFrames(tester, const Duration(seconds: 2));
  }

  Future<void> waitForSignal(String value, Duration timeout) async {
    final file = File(signalFile);
    final end = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(end)) {
      if (file.existsSync() && file.readAsStringSync().trim() == value) return;
      await Future<void>.delayed(const Duration(milliseconds: 500));
    }
    throw TestFailure('host signal "$value" not received');
  }

  AccessDestination destinationOf(WidgetTester tester) =>
      containerOf(tester).read(accessControllerProvider).destination;

  ApprovalNoticeState onlyNoticeState() {
    expect(approvals.values.length, 1);
    return approvals.values.values.single;
  }

  Future<void> approvalPhase(WidgetTester tester) async {
    final pending = find.byKey(const Key('merchant-verification-pending'));
    final rejected = find.byKey(const Key('merchant-verification-rejected'));
    final approved = find.byKey(const Key('merchant-verification-approved'));
    await waitFor(tester, find.byWidgetPredicate(
      (w) => w.key == const Key('merchant-verification-pending') ||
          w.key == const Key('merchant-verification-rejected'),
    ));
    if (rejected.evaluate().isNotEmpty) {
      checks['start'] = 'REJECTED';
      await shot(tester, 'b7_rejected');
      expect(onlyNoticeState(), ApprovalNoticeState.observedUnapproved);
      await tapVisible(tester, find.byKey(const Key('merchant-verification-correct')));
      await waitFor(tester, find.byKey(const Key('merchant-registration')));
      containerOf(tester)
          .read(registrationControllerProvider.notifier)
          .goTo(RegistrationStep.review);
      await waitFor(tester, find.byKey(const Key('merchant-reg-correction-intro')));
      await shot(tester, 'b7_resubmission');
      await tapVisible(tester, find.byKey(const Key('merchant-reg-submit')));
      await waitFor(tester, pending);
      checks['resubmitted'] = true;
    } else {
      checks['start'] = 'PENDING_REVIEW';
    }
    await shot(tester, 'b7_pending');
    expect(onlyNoticeState(), ApprovalNoticeState.observedUnapproved);
    checks['observedBeforeApproval'] = true;

    File(signalFile).writeAsStringSync('awaiting_approval\n');
    await waitForSignal('approved', const Duration(minutes: 3));
    await tapVisible(tester, find.byKey(const Key('merchant-verification-refresh')));
    await waitFor(tester, approved);
    expect(find.text(AppStrings.approvedTitle), findsOneWidget);
    expect(find.byKey(const Key('merchant-approved-badge')), findsOneWidget);
    expect(
      tester.widget<Text>(find.byKey(const Key('merchant-approved-name'))).data,
      merchantName,
    );
    expect(destinationOf(tester), AccessDestination.verificationApproved);
    await shot(tester, 'b7_approved');

    await coldRestart(tester);
    await waitFor(tester, approved);
    expect(onlyNoticeState(), ApprovalNoticeState.observedUnapproved);
    checks['noticeSurvivesColdRestart'] = true;

    await tapVisible(tester, find.byKey(const Key('merchant-approved-continue')));
    final end = DateTime.now().add(const Duration(seconds: 30));
    while (approved.evaluate().isNotEmpty && DateTime.now().isBefore(end)) {
      await pumpFrames(tester, const Duration(milliseconds: 300));
    }
    await pumpFrames(tester, const Duration(seconds: 3));
    expect(approved, findsNothing);
    expect(onlyNoticeState(), ApprovalNoticeState.acknowledged);
    final next = destinationOf(tester);
    expect(
      next,
      anyOf(
        AccessDestination.home,
        AccessDestination.selectBranch,
        AccessDestination.needBranch,
      ),
    );
    checks['afterAcknowledgement'] = next.name;
    await shot(tester, 'b7_approved_next');

    await coldRestart(tester);
    expect(approved, findsNothing);
    expect(destinationOf(tester), next);
    checks['noNoticeAfterAcknowledgedRestart'] = true;
  }

  void writeProvenance() {
    File('${outDir.path}/PROVENANCE_${prefix}_b7_$phase.json').writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert({
        'app': 'merchant',
        'bundleId': 'com.speedygo.speedygoMerchantApp',
        'fixture': merchantName,
        'phase': phase,
        'backend': 'local dev',
        'sessionRevoked': true,
        'stores': 'memory only (session, context, launch, approval notice, push token)',
        'checks': checks,
        'steps': steps,
      }),
    );
  }

  Future<void> runPhase(WidgetTester tester) async {
    expect(phoneLocal.length, 9);
    expect(phase, anyOf('register', 'rejected', 'approval'));

    await login(tester);

    if (phase == 'approval') {
      await approvalPhase(tester);
    } else if (phase == 'register') {
      expect(AcceptanceFixtureEvidenceFilePicker.acceptancePickerEnabled, isTrue);
      await waitFor(tester, find.byKey(const Key('merchant-reg-role-owner')));
      await shot(tester, 'b7_registration');
      await tester.tap(find.byKey(const Key('merchant-reg-role-owner')));
      await pumpFrames(tester, const Duration(milliseconds: 600));
      await tapVisible(tester, find.byKey(const Key('merchant-reg-account-continue')));
      await waitFor(tester, find.byKey(const Key('merchant-reg-name')));
      await tester.enterText(find.byKey(const Key('merchant-reg-name')), merchantName);
      await tester.pump(const Duration(milliseconds: 300));
      await tapVisible(tester, find.byKey(const Key('merchant-reg-activity-continue')));
      await waitFor(
        tester,
        find.byKey(const Key('merchant-reg-doc-pick-BUSINESS_IDENTITY')),
      );
      await tapVisible(
        tester,
        find.byKey(const Key('merchant-reg-doc-pick-BUSINESS_IDENTITY')),
      );
      await pumpFrames(tester, const Duration(seconds: 5));
      await tester.drag(find.byType(Scrollable).first, const Offset(0, 600));
      await shot(tester, 'b7_documents');
      await tapVisible(
        tester,
        find.byKey(const Key('merchant-reg-doc-pick-BUSINESS_REGISTRATION')),
      );
      await pumpFrames(tester, const Duration(seconds: 5));
      await tapVisible(tester, find.byKey(const Key('merchant-reg-docs-continue')));
      await waitFor(tester, find.byKey(const Key('merchant-reg-branch-name')));

      await tester.enterText(
        find.byKey(const Key('merchant-reg-branch-name')),
        merchantName,
      );
      await tester.enterText(
        find.byKey(const Key('merchant-reg-branch-phone')),
        '0559900093',
      );
      await tester.enterText(
        find.byKey(const Key('merchant-reg-branch-address')),
        '1 Rue de test (adresse fictive)',
      );
      await pickFromSheet(
        tester,
        const Key('merchant-reg-wilaya'),
        'Alger',
        '16 — Alger',
      );
      await pickFromSheet(
        tester,
        const Key('merchant-reg-commune'),
        'Centre',
        'Alger Centre',
      );
      await tapVisible(tester, find.byKey(const Key('merchant-reg-choose-on-map')));
      await waitFor(tester, find.byKey(const Key('merchant-location-picker')));
      await pumpFrames(tester, const Duration(seconds: 2));
      // The exploration default is not confirmable until the map is panned.
      final map =
          tester.getCenter(find.byKey(const Key('merchant-location-picker')));
      await tester.dragFrom(map, const Offset(-40, -20));
      await pumpFrames(tester, const Duration(seconds: 2));
      await tapVisible(tester, find.byKey(const Key('merchant-location-confirm')));
      await waitFor(tester, find.byKey(const Key('merchant-reg-location-confirmed')));
      await tapVisible(tester, find.byKey(const Key('merchant-reg-estab-continue')));
      await waitFor(tester, find.byKey(const Key('merchant-reg-submit')));
      await shot(tester, 'b7_review');

      await tapVisible(tester, find.byKey(const Key('merchant-reg-submit')));
      await waitFor(tester, find.byKey(const Key('merchant-verification-pending')));
      expect(find.textContaining('transmis'), findsOneWidget);
      await shot(tester, 'b7_pending');
    } else {
      await waitFor(tester, find.byKey(const Key('merchant-verification-rejected')));
      expect(find.text(AppStrings.verificationRejectedTitle), findsOneWidget);
      await shot(tester, 'b7_rejected');
      await tapVisible(tester, find.byKey(const Key('merchant-verification-correct')));
      await waitFor(tester, find.byKey(const Key('merchant-registration')));
      containerOf(tester)
          .read(registrationControllerProvider.notifier)
          .goTo(RegistrationStep.review);
      await waitFor(tester, find.byKey(const Key('merchant-reg-correction-intro')));
      expect(find.text(AppStrings.regCorrectionSubmit), findsOneWidget);
      await shot(tester, 'b7_resubmission');
    }

    await logoutThisSession(tester);
    File(shotMarker).writeAsStringSync('${prefix}_99_done\n');
    writeProvenance();
  }

  testWidgets('parity live captures batch 7 ($phase)', (tester) async {
    try {
      await runPhase(tester);
    } finally {
      await revokeIfStillSignedIn(tester);
    }
  });
}
