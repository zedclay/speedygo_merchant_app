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
import 'package:speedygo_merchant_app/features/auth/application/session_providers.dart';
import 'package:speedygo_merchant_app/features/auth/data/models.dart';

import '../features/phase1_flow_test.dart';

Future<void> _capture(WidgetTester tester, String name) async {
  await tester.pump();
  final finder = find.byType(RepaintBoundary).first;
  final renderObject = tester.renderObject(finder);
  if (renderObject is! RenderRepaintBoundary) {
    final dir = Directory(
      '/Users/mac/Downloads/speedygo_project/apps/merchant_app/audit/phase-1/captures',
    );
    dir.createSync(recursive: true);
    File('${dir.path}/$name.txt')
        .writeAsStringSync('capture-skipped: no RenderRepaintBoundary');
    return;
  }
  await tester.runAsync(() async {
    final image = await renderObject.toImage(pixelRatio: 1.5);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File(
      '/Users/mac/Downloads/speedygo_project/apps/merchant_app/audit/phase-1/captures/$name.png',
    );
    file.parent.createSync(recursive: true);
    await file.writeAsBytes(bytes!.buffer.asUint8List());
  });
}

Future<void> _settleBriefly(WidgetTester tester) async {
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
    await _settleBriefly(tester);
  }

  testWidgets('mocked captures: phone and otp SE', (tester) async {
    final auth = FakeAuthApi();
    final merchant = FakeMerchantApi();
    final container = testContainer(auth: auth, merchant: merchant);
    addTearDown(container.dispose);

    await pumpAt(tester, size: const Size(375, 667), container: container);
    expect(find.text(AppStrings.phoneTitle), findsOneWidget);
    await _capture(tester, 'phone-se-375x667');

    await tester.enterText(
      find.byKey(const Key('merchant-phone-field')),
      '550000001',
    );
    await tester.showKeyboard(find.byKey(const Key('merchant-phone-field')));
    await tester.pump();
    await _capture(tester, 'phone-keyboard-se-375x667');
    tester.testTextInput.hide();
    await tester.pump();

    await tester.tap(find.byKey(const Key('merchant-phone-continue')));
    await _settleBriefly(tester);
    expect(find.text(AppStrings.otpTitle), findsOneWidget);
    await _capture(tester, 'otp-se-375x667');
  });

  testWidgets('mocked captures: home Pro and dense text', (tester) async {
    final auth = FakeAuthApi();
    final merchant = FakeMerchantApi(
      meHandler: () async => MerchantMe(
        merchantMembershipExists: true,
        memberships: [
          membership(branches: [branch('b1')]),
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

    await pumpAt(tester, size: const Size(402, 874), container: container);
    expect(find.byKey(const Key('home-branch-name')), findsOneWidget);
    await _capture(tester, 'home-pro-402x874');

    await pumpAt(
      tester,
      size: const Size(375, 667),
      textScale: 1.3,
      container: container,
    );
    expect(find.byKey(const Key('home-branch-name')), findsOneWidget);
    await _capture(tester, 'home-dense-se-text-1_3');
    // Stops the signed-in session's order-alert poll before timer checks.
    container.dispose();
  });
}
