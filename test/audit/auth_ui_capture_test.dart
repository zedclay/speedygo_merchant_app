import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speedygo_merchant_app/app/app.dart';
import 'package:speedygo_merchant_app/core/constants/app_strings.dart';
import 'package:speedygo_merchant_app/core/storage/session_store.dart';
import 'package:speedygo_merchant_app/features/access/data/models.dart';
import 'package:speedygo_merchant_app/features/auth/application/session_controller.dart';
import 'package:speedygo_merchant_app/features/auth/application/session_providers.dart';
import 'package:speedygo_merchant_app/features/auth/application/session_state.dart';
import 'package:speedygo_merchant_app/features/auth/data/models.dart';

import '../features/phase1_flow_test.dart';

Future<void> _capture(WidgetTester tester, String name) async {
  await tester.pump();
  final finder = find.byType(RepaintBoundary).first;
  final renderObject = tester.renderObject(finder);
  if (renderObject is! RenderRepaintBoundary) return;
  await tester.runAsync(() async {
    final image = await renderObject.toImage(pixelRatio: 1.5);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File(
      '/Users/mac/Downloads/speedygo_project/apps/merchant_app/audit/phase-1/captures/auth-ui/$name.png',
    );
    file.parent.createSync(recursive: true);
    await file.writeAsBytes(bytes!.buffer.asUint8List());
  });
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 40; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpAt(
    WidgetTester tester, {
    required Size size,
    double textScale = 1,
    required ProviderContainer container,
  }) async {
    tester.view.physicalSize = size * 2;
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(
          size: size,
          textScaler: TextScaler.linear(textScale),
        ),
        child: UncontrolledProviderScope(
          container: container,
          child: const RepaintBoundary(child: SpeedyGoApp()),
        ),
      ),
    );
    await tester.pump();
    await _settle(tester);
  }

  testWidgets('mocked auth captures phone and otp layouts', (tester) async {
    final auth = FakeAuthApi();
    final merchant = FakeMerchantApi();
    final container = testContainer(auth: auth, merchant: merchant);
    addTearDown(container.dispose);

    await pumpAt(tester, size: const Size(375, 667), container: container);
    expect(find.text(AppStrings.phoneTitle), findsOneWidget);
    expect(find.text(AppStrings.phonePrefix), findsOneWidget);
    await _capture(tester, 'phone-se-375x667');

    await tester.enterText(
      find.byKey(const Key('merchant-phone-field')),
      '550000001',
    );
    await tester.pump();
    await tester.showKeyboard(find.byKey(const Key('merchant-phone-field')));
    await tester.pump();
    await _capture(tester, 'phone-keyboard-se-375x667');
    tester.testTextInput.hide();
    await tester.pump();

    await tester.ensureVisible(find.byKey(const Key('merchant-phone-continue')));
    await tester.tap(find.byKey(const Key('merchant-phone-continue')));
    await _settle(tester);
    expect(find.text(AppStrings.otpTitle), findsOneWidget);
    expect(find.text(AppStrings.editNumber), findsOneWidget);
    await _capture(tester, 'otp-se-375x667');

    await pumpAt(tester, size: const Size(402, 874), container: container);
    expect(find.text(AppStrings.otpTitle), findsOneWidget);
    await _capture(tester, 'otp-pro-402x874');

    await pumpAt(
      tester,
      size: const Size(375, 667),
      textScale: 1.3,
      container: container,
    );
    expect(find.text(AppStrings.otpTitle), findsOneWidget);
    await _capture(tester, 'otp-dense-text-1_3');
  });

  testWidgets('mocked verification missing checklist capture', (tester) async {
    final auth = FakeAuthApi();
    final checklist = const [
      MerchantEvidenceItem(
        type: 'BUSINESS_IDENTITY',
        required: true,
        present: false,
        complete: false,
      ),
      MerchantEvidenceItem(
        type: 'BUSINESS_REGISTRATION',
        required: true,
        present: false,
        complete: false,
      ),
      MerchantEvidenceItem(
        type: 'SUPPORTING_DOCUMENT',
        required: false,
        present: false,
        complete: false,
      ),
    ];
    final merchant = FakeMerchantApi(
      meHandler: () async => MerchantMe(
        merchantMembershipExists: true,
        memberships: [
          membership(
            status: 'PENDING_REVIEW',
            approved: false,
            operationalReady: false,
            verificationSubmitted: true,
            branches: [branch('b1')],
            evidenceChecklist: checklist,
          ),
        ],
      ),
    );
    final store = MemorySessionStore()
      ..value = const TokenPair(
        accessToken: 'a',
        refreshToken: 'r-token-value',
        expiresIn: 900,
        tokenType: 'Bearer',
      );
    final container =
        testContainer(auth: auth, merchant: merchant, store: store);
    container.read(tokenCacheProvider).current = store.value;
    addTearDown(container.dispose);

    await pumpAt(tester, size: const Size(375, 667), container: container);
    expect(find.text(AppStrings.verificationPendingTitle), findsOneWidget);
    expect(find.text('Identité de l’activité'), findsOneWidget);
    expect(find.text('Manquant'), findsWidgets);
    expect(find.textContaining('required='), findsNothing);
    expect(find.textContaining('BUSINESS_IDENTITY'), findsNothing);
    await tester.ensureVisible(find.byKey(const Key('merchant-verification-refresh')));
    expect(find.byKey(const Key('merchant-verification-refresh')), findsOneWidget);
    await _capture(tester, 'verification-pending-missing-se');
  });

  testWidgets('change number navigates phone without new login loop',
      (tester) async {
    final auth = FakeAuthApi();
    final container = testContainer(
      auth: auth,
      merchant: FakeMerchantApi(),
    );
    addTearDown(container.dispose);
    await pumpAt(tester, size: const Size(375, 667), container: container);
    await tester.enterText(
      find.byKey(const Key('merchant-phone-field')),
      '550000001',
    );
    await tester.pump();
    await tester.ensureVisible(find.byKey(const Key('merchant-phone-continue')));
    await tester.tap(find.byKey(const Key('merchant-phone-continue')));
    await _settle(tester);
    expect(
      container.read(sessionControllerProvider).phase,
      SessionPhase.awaitingOtp,
    );
    await tester.tap(find.text(AppStrings.editNumber));
    await _settle(tester);
    expect(find.text(AppStrings.phoneTitle), findsOneWidget);
    expect(
      container.read(sessionControllerProvider).phase,
      SessionPhase.awaitingOtp,
    );
  });
}
