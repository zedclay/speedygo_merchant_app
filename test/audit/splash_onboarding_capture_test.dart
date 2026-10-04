import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speedygo_merchant_app/app/app.dart';
import 'package:speedygo_merchant_app/core/constants/app_strings.dart';
import 'package:speedygo_merchant_app/core/constants/merchant_assets.dart';

import '../features/phase1_flow_test.dart';
import '../features/startup_flow_test.dart';

Future<void> _settle(WidgetTester tester, {int frames = 40}) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

Future<void> _precacheOnboarding(WidgetTester tester) async {
  final context = tester.element(find.byType(MaterialApp));
  await tester.runAsync(() async {
    await Future.wait([
      precacheImage(const AssetImage(MerchantAssets.onboardingReceive), context),
      precacheImage(const AssetImage(MerchantAssets.onboardingPrepare), context),
      precacheImage(
        const AssetImage(MerchantAssets.onboardingBusiness),
        context,
      ),
    ]);
  });
  await tester.pump();
}

Future<void> _capture(WidgetTester tester, String name) async {
  await tester.pump();
  final finder = find.byKey(const Key('merchant-capture-root'));
  final renderObject = tester.renderObject(finder);
  if (renderObject is! RenderRepaintBoundary) return;
  await tester.runAsync(() async {
    final image = await renderObject.toImage(pixelRatio: 1.5);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File(
      'audit/phase-1/captures/splash-onboarding/$name.png',
    );
    file.parent.createSync(recursive: true);
    await file.writeAsBytes(bytes!.buffer.asUint8List());
  });
}

ProviderContainer _container(ControllableLaunchStore launch, Duration splashMin) {
  return testContainer(
    auth: FakeAuthApi(),
    merchant: FakeMerchantApi(),
    launch: launch,
    splashMin: splashMin,
  );
}

Future<void> _pumpApp(
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
        child: const RepaintBoundary(
          key: Key('merchant-capture-root'),
          child: SpeedyGoApp(),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('capture splash 375x667', (tester) async {
    const hold = Duration(days: 365);
    final container = _container(
      ControllableLaunchStore(languageSeen: true, onboardingSeen: false),
      hold,
    );
    addTearDown(container.dispose);
    await _pumpApp(tester, size: const Size(375, 667), container: container);
    expect(find.byKey(const Key('merchant-splash')), findsOneWidget);
    expect(find.text(AppStrings.splashTagline), findsOneWidget);
    await _capture(tester, 'splash-375x667');
    await tester.pump(hold);
  });

  testWidgets('capture splash 402x874', (tester) async {
    const hold = Duration(days: 365);
    final container = _container(
      ControllableLaunchStore(languageSeen: true, onboardingSeen: false),
      hold,
    );
    addTearDown(container.dispose);
    await _pumpApp(tester, size: const Size(402, 874), container: container);
    expect(find.byKey(const Key('merchant-splash')), findsOneWidget);
    expect(find.text(AppStrings.splashTagline), findsOneWidget);
    expect(find.byKey(const Key('merchant-onboarding')), findsNothing);
    await _capture(tester, 'splash-402x874');
    await tester.pump(hold);
  });

  testWidgets('capture onboarding pages and text scale', (tester) async {
    Future<ProviderContainer> openOnboarding(Size size, {double scale = 1}) async {
      final container = _container(
        ControllableLaunchStore(languageSeen: true, onboardingSeen: false),
        Duration.zero,
      );
      addTearDown(container.dispose);
      await _pumpApp(
        tester,
        size: size,
        textScale: scale,
        container: container,
      );
      await _settle(tester);
      expect(find.byKey(const Key('merchant-onboarding')), findsOneWidget);
      await _precacheOnboarding(tester);
      return container;
    }

    await openOnboarding(const Size(375, 667));
    expect(find.text(AppStrings.onboardingPage1Title), findsOneWidget);
    expect(find.text(AppStrings.onboardingNext), findsOneWidget);
    await _capture(tester, 'onboarding-1-375x667');

    await openOnboarding(const Size(402, 874));
    expect(find.text(AppStrings.onboardingPage1Title), findsOneWidget);
    await _capture(tester, 'onboarding-1-402x874');

    await openOnboarding(const Size(375, 667));
    await tester.tap(find.byKey(const Key('merchant-onboarding-primary')));
    await _settle(tester);
    expect(find.text(AppStrings.onboardingPage2Title), findsOneWidget);
    await _capture(tester, 'onboarding-2-375x667');

    await tester.tap(find.byKey(const Key('merchant-onboarding-primary')));
    await _settle(tester);
    expect(find.text(AppStrings.onboardingPage3Title), findsOneWidget);
    expect(find.text(AppStrings.onboardingStart), findsOneWidget);
    await _capture(tester, 'onboarding-3-375x667');

    await openOnboarding(const Size(402, 874));
    final pageView = tester.widget<PageView>(
      find.byKey(const Key('merchant-onboarding-pager')),
    );
    pageView.controller!.jumpToPage(2);
    await _settle(tester);
    expect(find.text(AppStrings.onboardingPage3Title), findsOneWidget);
    await _capture(tester, 'onboarding-3-402x874');

    await openOnboarding(const Size(375, 667), scale: 1.3);
    expect(find.text(AppStrings.onboardingPage1Title), findsOneWidget);
    expect(tester.takeException(), isNull);
    await _capture(tester, 'onboarding-1-text-1_3-375x667');
    await tester.tap(find.byKey(const Key('merchant-onboarding-primary')));
    await _settle(tester);
    await _capture(tester, 'onboarding-2-text-1_3-375x667');
    await tester.tap(find.byKey(const Key('merchant-onboarding-primary')));
    await _settle(tester);
    expect(find.text(AppStrings.onboardingStart), findsOneWidget);
    await _capture(tester, 'onboarding-3-text-1_3-375x667');
    expect(
      find.image(const AssetImage(MerchantAssets.onboardingBusiness)),
      findsOneWidget,
    );
  });
}
