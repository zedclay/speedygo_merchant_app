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

/// Isolated Batch 7 visual/live captures against speedygo_parity_fx (:3100).
///
/// Phase `register`: fresh OTP login → registration → documents → review with
/// server legal consent → pending (real reference) → cold relaunch → logout.
/// Phase `rejected` (host rejects with structured APPLICATION + DOCUMENT
/// issues): rejected screen → correction → replace BUSINESS_IDENTITY → review
/// with fresh consent → resubmit → pending attempt 2 → logout.
///
/// Host: `audit/parity/isolated/fx_b7_live.sh`. OTPs never printed.
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

  const phoneLocal = String.fromEnvironment('B7_PHONE');
  const phase = String.fromEnvironment('B7_PHASE');
  const prefix = String.fromEnvironment('PARITY_PREFIX', defaultValue: 'fxb7');
  const merchantName = String.fromEnvironment(
    'B7_MERCHANT_NAME',
    defaultValue: 'Parité B7 Isolé',
  );
  const otpFilePath = String.fromEnvironment('FX_OTP_FILE');
  const evidenceDir = String.fromEnvironment('FX_EVIDENCE_DIR');
  const shotMarker = '/tmp/parity_fx_isolated_shot.txt';
  const appBase = String.fromEnvironment('API_BASE_URL');

  final sessions = MemorySessionStore();
  final contexts = MemoryContextStore();
  final launches = MemoryLaunchStore();
  final approvals = MemoryApprovalNoticeStore();
  final pushTokens = _MemoryPushRegistration();
  final checks = <String, Object?>{};
  var sessionCreated = false;
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
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.ensureVisible(finder);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(finder, warnIfMissed: false);
    await tester.pump(const Duration(milliseconds: 200));
  }

  Future<void> shot(WidgetTester tester, String tag) async {
    FocusManager.instance.primaryFocus?.unfocus();
    await pumpFrames(tester, const Duration(milliseconds: 1500));
    File(shotMarker).writeAsStringSync('${prefix}_$tag\n');
    await pumpFrames(tester, const Duration(seconds: 3));
    steps.add({
      'tag': '${prefix}_$tag',
      'at': DateTime.now().toUtc().toIso8601String(),
    });
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

  Future<void> coldRestart(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 500));
    await pumpApp(tester);
    await pumpFrames(tester, const Duration(seconds: 6));
  }

  Future<void> login(WidgetTester tester) async {
    await pumpApp(tester);
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
    await tester.enterText(
      find.byKey(const Key('merchant-phone-field')),
      phoneLocal,
    );
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

  Future<void> acceptLegalConsents(WidgetTester tester) async {
    // Ensure review step and trigger / wait for legal load.
    final reg = containerOf(tester).read(registrationControllerProvider.notifier);
    expect(
      containerOf(tester).read(registrationControllerProvider).step,
      RegistrationStep.review,
    );
    await reg.loadLegal(force: true);
    await pumpFrames(tester, const Duration(seconds: 2));

    // Scroll the review ListView so the consent block is on-screen.
    for (var i = 0; i < 8; i++) {
      if (find.byKey(const Key('merchant-legal-section')).evaluate().isNotEmpty &&
          find.byKey(const Key('merchant-legal-terms')).evaluate().isNotEmpty) {
        break;
      }
      final scrollables = find.byType(Scrollable);
      if (scrollables.evaluate().isNotEmpty) {
        await tester.drag(scrollables.first, const Offset(0, -280));
        await pumpFrames(tester, const Duration(milliseconds: 400));
      } else {
        await pumpFrames(tester, const Duration(milliseconds: 400));
      }
    }

    if (find.byKey(const Key('merchant-legal-retry')).evaluate().isNotEmpty) {
      await tapVisible(tester, find.byKey(const Key('merchant-legal-retry')));
      await pumpFrames(tester, const Duration(seconds: 2));
    }

    await waitFor(tester, find.byKey(const Key('merchant-legal-section')));
    await waitFor(tester, find.byKey(const Key('merchant-legal-terms')));
    await tapVisible(tester, find.byKey(const Key('merchant-legal-terms')));
    await tapVisible(
      tester,
      find.byKey(const Key('merchant-legal-declaration')),
    );
    expect(
      containerOf(tester).read(registrationControllerProvider).consentsComplete,
      isTrue,
    );
  }

  Future<void> logoutThisSession(WidgetTester tester) async {
    await containerOf(tester).read(sessionControllerProvider.notifier).logout();
    await waitFor(tester, find.byKey(const Key('merchant-phone-field')));
  }

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

  void writeProvenance() {
    final dir = evidenceDir.isEmpty
        ? Directory(
            '/Users/mac/Downloads/speedygo_project/apps/merchant_app/'
            'audit/parity/isolated/evidence',
          )
        : Directory(evidenceDir);
    dir.createSync(recursive: true);
    File('${dir.path}/PROVENANCE_${prefix}_b7_$phase.json').writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert({
        'app': 'merchant',
        'bundleId': 'com.speedygo.speedygoMerchantApp',
        'fixture': merchantName,
        'phase': phase,
        'backend': 'isolated speedygo_parity_fx',
        'apiBase': appBase,
        'sessionRevoked': true,
        'stores':
            'memory only (session, context, launch, approval notice, push token)',
        'checks': checks,
        'steps': steps,
      }),
    );
  }

  Future<void> runRegister(WidgetTester tester) async {
    expect(AcceptanceFixtureEvidenceFilePicker.acceptancePickerEnabled, isTrue);
    await waitFor(tester, find.byKey(const Key('merchant-reg-role-owner')));
    await shot(tester, 'b7_registration');
    await tester.tap(find.byKey(const Key('merchant-reg-role-owner')));
    await pumpFrames(tester, const Duration(milliseconds: 600));
    await tapVisible(tester, find.byKey(const Key('merchant-reg-account-continue')));
    await waitFor(tester, find.byKey(const Key('merchant-reg-name')));
    await tester.enterText(find.byKey(const Key('merchant-reg-name')), merchantName);
    await tester.pump(const Duration(milliseconds: 300));
    await tapVisible(
      tester,
      find.byKey(const Key('merchant-reg-activity-continue')),
    );
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
      '1 Rue de test isolé (adresse fictive)',
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
    final map =
        tester.getCenter(find.byKey(const Key('merchant-location-picker')));
    await tester.dragFrom(map, const Offset(-40, -20));
    await pumpFrames(tester, const Duration(seconds: 2));
    await tapVisible(tester, find.byKey(const Key('merchant-location-confirm')));
    await waitFor(tester, find.byKey(const Key('merchant-reg-location-confirmed')));
    await tapVisible(
      tester,
      find.byKey(const Key('merchant-reg-estab-continue')),
    );
    await waitFor(tester, find.byKey(const Key('merchant-reg-submit')));
    await acceptLegalConsents(tester);
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -400));
    await pumpFrames(tester, const Duration(milliseconds: 800));
    await shot(tester, 'b7_review');

    await tapVisible(tester, find.byKey(const Key('merchant-reg-submit')));
    await waitFor(tester, find.byKey(const Key('merchant-verification-pending')));
    expect(find.textContaining('transmis'), findsOneWidget);
    final membership =
        containerOf(tester).read(accessControllerProvider).membership;
    final reference = membership?.merchantPublicReference.trim() ?? '';
    expect(reference.isNotEmpty, isTrue, reason: 'server dossier reference');
    checks['pendingReference'] = reference;
    checks['attemptNumber'] = membership?.attemptNumber;
    checks['submittedAt'] = membership?.submittedAt;
    checks['legalAcceptance'] = membership?.legalAcceptance != null;
    await shot(tester, 'b7_pending');

    await coldRestart(tester);
    await waitFor(tester, find.byKey(const Key('merchant-verification-pending')));
    final after =
        containerOf(tester).read(accessControllerProvider).membership;
    expect(after?.merchantPublicReference.trim(), reference);
    checks['pendingSurvivesColdRestart'] = true;
    await shot(tester, 'b7_pending_cold');
  }

  Future<void> runRejected(WidgetTester tester) async {
    await waitFor(
      tester,
      find.byKey(const Key('merchant-verification-rejected')),
    );
    expect(find.text(AppStrings.verificationRejectedTitle), findsOneWidget);
    expect(find.textContaining('Complétez le nom commercial'), findsOneWidget);
    expect(find.textContaining('illisible'), findsOneWidget);
    final rejected =
        containerOf(tester).read(accessControllerProvider).membership;
    checks['rejectedReference'] = rejected?.merchantPublicReference;
    checks['unresolvedIssueCount'] = rejected?.unresolvedIssueCount;
    checks['currentIssues'] = rejected?.currentIssues
        .map(
          (i) => {
            'scope': i.scope,
            'code': i.code,
            'messageFr': i.messageFr,
            'documentType': i.documentType,
            'isResolved': i.isResolved,
          },
        )
        .toList();
    await shot(tester, 'b7_rejected');

    await tapVisible(
      tester,
      find.byKey(const Key('merchant-verification-correct')),
    );
    await waitFor(tester, find.byKey(const Key('merchant-registration')));
    containerOf(tester)
        .read(registrationControllerProvider.notifier)
        .goTo(RegistrationStep.review);
    await waitFor(tester, find.byKey(const Key('merchant-reg-correction-intro')));

    await tapVisible(
      tester,
      find.byKey(const Key('merchant-issue-replace-BUSINESS_IDENTITY')),
    );
    await waitFor(
      tester,
      find.byKey(const Key('merchant-reg-doc-pick-BUSINESS_IDENTITY')),
    );
    await tapVisible(
      tester,
      find.byKey(const Key('merchant-reg-doc-pick-BUSINESS_IDENTITY')),
    );
    await pumpFrames(tester, const Duration(seconds: 6));
    await shot(tester, 'b7_documents_correction');
    containerOf(tester)
        .read(registrationControllerProvider.notifier)
        .goTo(RegistrationStep.review);
    await waitFor(tester, find.byKey(const Key('merchant-reg-correction-intro')));

    final afterRebind =
        containerOf(tester).read(registrationControllerProvider).membership;
    final docOpen = afterRebind?.currentIssues
            .where(
              (i) =>
                  i.isDocument &&
                  i.documentType == 'BUSINESS_IDENTITY' &&
                  !i.isResolved,
            )
            .length ??
        -1;
    checks['documentIssueOpenAfterRebind'] = docOpen;
    expect(docOpen, 0, reason: 'DOCUMENT_ILLEGIBLE must clear after rebind');
    checks['applicationIssueStillOpen'] = afterRebind?.currentIssues.any(
          (i) =>
              i.scope.toUpperCase() == 'APPLICATION' && !i.isResolved,
        ) ==
        true;

    await acceptLegalConsents(tester);
    expect(find.text(AppStrings.regCorrectionSubmit), findsOneWidget);
    await shot(tester, 'b7_resubmission');

    await tapVisible(tester, find.byKey(const Key('merchant-reg-submit')));
    await waitFor(tester, find.byKey(const Key('merchant-verification-pending')));
    final resub =
        containerOf(tester).read(accessControllerProvider).membership;
    checks['resubmitAttempt'] = resub?.attemptNumber;
    checks['resubmitLegalAcceptance'] = resub?.legalAcceptance != null;
    expect(resub?.attemptNumber, 2);
    checks['resubmitted'] = true;
    await shot(tester, 'b7_pending_after_resubmit');

    await coldRestart(tester);
    await waitFor(tester, find.byKey(const Key('merchant-verification-pending')));
    checks['resubmitPendingSurvivesColdRestart'] = true;
  }

  Future<void> runPhase(WidgetTester tester) async {
    expect(phoneLocal.length, 9);
    expect(otpFilePath.isNotEmpty, isTrue);
    expect(appBase.contains('3100'), isTrue, reason: 'isolated API only');
    expect(phase, anyOf('register', 'rejected'));

    await login(tester);
    if (phase == 'register') {
      await runRegister(tester);
    } else {
      await runRejected(tester);
    }
    await logoutThisSession(tester);
    File(shotMarker).writeAsStringSync('${prefix}_99_done\n');
    writeProvenance();
  }

  testWidgets('parity fx b7 live captures ($phase)', (tester) async {
    try {
      await runPhase(tester);
    } finally {
      await revokeIfStillSignedIn(tester);
    }
  });
}
