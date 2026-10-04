import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speedygo_merchant_app/app/app.dart';
import 'package:speedygo_merchant_app/core/storage/session_store.dart';
import 'package:speedygo_merchant_app/features/access/data/models.dart';
import 'package:speedygo_merchant_app/features/auth/application/session_providers.dart';
import 'package:speedygo_merchant_app/features/auth/data/models.dart';

import '../features/phase1_flow_test.dart';
import '../features/startup_flow_test.dart';

/// Captures verification-pending bottom edge after sticky-bar shadow fix.
const _out =
    '/Users/mac/Downloads/speedygo_project/apps/merchant_app/audit/registration-verification/captures';

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 40; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

Future<void> _capture(WidgetTester tester, String name) async {
  await tester.pump();
  final finder = find.byKey(const Key('merchant-capture-root'));
  final renderObject = tester.renderObject(finder);
  if (renderObject is! RenderRepaintBoundary) return;
  await tester.runAsync(() async {
    final image = await renderObject.toImage(pixelRatio: 2);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File('$_out/$name.png');
    file.parent.createSync(recursive: true);
    await file.writeAsBytes(bytes!.buffer.asUint8List());
  });
}

MerchantMembership _submittedPending() {
  return membership(
    status: 'PENDING_REVIEW',
    approved: false,
    verificationSubmitted: true,
    branches: [branch('b1')],
    evidenceChecklist: const [
      MerchantEvidenceItem(
        type: 'BUSINESS_IDENTITY',
        required: true,
        present: true,
        complete: true,
        status: 'SUBMITTED',
      ),
      MerchantEvidenceItem(
        type: 'BUSINESS_REGISTRATION',
        required: true,
        present: true,
        complete: true,
        status: 'SUBMITTED',
      ),
      MerchantEvidenceItem(
        type: 'SUPPORTING_DOCUMENT',
        required: false,
        present: false,
        complete: false,
      ),
    ],
  ).copyWithName('Pending Shop');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpPending(
    WidgetTester tester, {
    required Size size,
    double textScale = 1,
    double bottomInset = 34,
  }) async {
    tester.view.physicalSize = Size(size.width * 2, size.height * 2);
    tester.view.devicePixelRatio = 2;
    tester.view.padding = FakeViewPadding(
      top: 47 * 2,
      bottom: bottomInset * 2,
    );
    tester.view.viewPadding = FakeViewPadding(
      top: 47 * 2,
      bottom: bottomInset * 2,
    );
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPadding);
    addTearDown(tester.view.resetViewPadding);

    final store = MemorySessionStore()
      ..value = const TokenPair(
        accessToken: 'a',
        refreshToken: 'r-token-value',
        expiresIn: 900,
        tokenType: 'Bearer',
      );
    final container = testContainer(
      auth: FakeAuthApi(),
      merchant: FakeMerchantApi(
        meHandler: () async => MerchantMe(
          merchantMembershipExists: true,
          memberships: [_submittedPending()],
        ),
      ),
      store: store,
      launch: ControllableLaunchStore(languageSeen: true, onboardingSeen: true),
    );
    container.read(tokenCacheProvider).current = store.value;
    addTearDown(container.dispose);

    await tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(
          size: size,
          textScaler: TextScaler.linear(textScale),
          padding: EdgeInsets.only(top: 47, bottom: bottomInset),
          viewPadding: EdgeInsets.only(top: 47, bottom: bottomInset),
        ),
        child: UncontrolledProviderScope(
          container: container,
          child: const RepaintBoundary(
            key: Key('merchant-capture-root'),
            child: SpeedyGoApp(),
          ),
        ),
      ),
    );
    await _settle(tester);
    expect(find.byKey(const Key('merchant-verification-pending')), findsOneWidget);
    expect(find.byKey(const Key('merchant-verification-refresh')), findsOneWidget);
    expect(find.byKey(const Key('merchant-verification-logout')), findsOneWidget);
  }

  testWidgets('verification-pending bottom edge after shadow fix', (tester) async {
    // SE — scroll to end so sticky bar + full bottom edge are in frame.
    await pumpPending(tester, size: const Size(375, 667));
    await tester.drag(
      find.byType(SingleChildScrollView).first,
      const Offset(0, -800),
    );
    await _settle(tester);
    await _capture(tester, 'verification-pending-bottom-se');

    // SE text scale 1.3
    await pumpPending(
      tester,
      size: const Size(375, 667),
      textScale: 1.3,
    );
    await tester.drag(
      find.byType(SingleChildScrollView).first,
      const Offset(0, -900),
    );
    await _settle(tester);
    await _capture(tester, 'verification-pending-bottom-se-scale13');

    // Pro
    await pumpPending(tester, size: const Size(402, 874));
    await tester.drag(
      find.byType(SingleChildScrollView).first,
      const Offset(0, -1000),
    );
    await _settle(tester);
    await _capture(tester, 'verification-pending-bottom-pro');

    // Assert no elevated Material remains in the sticky actions.
    final materials = tester.widgetList<Material>(find.byType(Material));
    for (final m in materials) {
      // Sticky bar must not use elevation; button Materials may still elevate lightly.
      if (m.color == const Color(0xFFFFFFFF) && m.elevation >= 8) {
        fail('Found elevated surface Material (elevation ${m.elevation})');
      }
    }
  });
}
