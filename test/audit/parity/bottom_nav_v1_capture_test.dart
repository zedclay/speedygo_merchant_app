import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:speedygo_merchant_app/app/theme/app_theme.dart';
import 'package:speedygo_merchant_app/core/constants/app_strings.dart';
import 'package:speedygo_merchant_app/features/shell/merchant_shell.dart';

const _out =
    '/Users/mac/Downloads/speedygo_project/apps/merchant_app/audit/parity/bottom_nav/mocked';

const _rootKey = Key('capture-root');
const _phone = Size(390, 844);
const _small = Size(375, 667);

Future<void> _capture(WidgetTester tester, String name) async {
  await tester.pump();
  final renderObject = tester.renderObject(find.byKey(_rootKey));
  if (renderObject is! RenderRepaintBoundary) {
    fail('capture root is not a RepaintBoundary');
  }
  await tester.runAsync(() async {
    final image = await renderObject.toImage(pixelRatio: 2);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File('$_out/$name.png');
    file.parent.createSync(recursive: true);
    await file.writeAsBytes(bytes!.buffer.asUint8List());
  });
}

Widget _page(String name) {
  return Scaffold(
    backgroundColor: AppColors.background,
    body: ListView(
      children: [
        const SizedBox(height: 12),
        Text(name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
        for (var i = 0; i < 18; i++)
          ListTile(title: Text('$name item ${i + 1}')),
      ],
    ),
  );
}

Future<void> _pump(
  WidgetTester tester, {
  required Size size,
  required double textScale,
  required int index,
  bool hidden = false,
}) async {
  tester.view.physicalSize = Size(size.width * 2, size.height * 2);
  tester.view.devicePixelRatio = 2;
  tester.view.padding = const FakeViewPadding(bottom: 68);
  tester.view.viewPadding = const FakeViewPadding(bottom: 68);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPadding);
  addTearDown(tester.view.resetViewPadding);
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));

  final visibility = MerchantNavVisibilityController();
  if (hidden) {
    visibility.applyPrimaryVerticalScroll(
      pixels: 80,
      minScrollExtent: 0,
      delta: 80,
    );
  }
  final pages = [
    _page('Accueil'),
    _page('Commandes'),
    _page('Catalogue'),
    _page('Rapports'),
    _page('Profil'),
  ];
  final router = GoRouter(
    initialLocation: MerchantShell.tabRoutes[index],
    routes: [
      ShellRoute(
        builder: (context, state, child) => MerchantShell(
          debugPages: pages,
          debugVisibility: visibility,
          child: child,
        ),
        routes: [
          for (final path in MerchantShell.tabRoutes)
            GoRoute(path: path, builder: (_, _) => const SizedBox.shrink()),
        ],
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      child: MediaQuery(
        data: MediaQueryData(
          size: size,
          textScaler: TextScaler.linear(textScale),
          padding: const EdgeInsets.only(bottom: 34),
          viewPadding: const EdgeInsets.only(bottom: 34),
        ),
        child: MaterialApp.router(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(locale: const Locale('fr')),
          builder: (context, child) => RepaintBoundary(
            key: _rootKey,
            child: child ?? const SizedBox.shrink(),
          ),
          routerConfig: router,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('mocked Concept V1 dock at 1.0 and 1.35', (tester) async {
    const variants = <({Size size, double scale, String suffix})>[
      (size: _phone, scale: 1.0, suffix: 'w390'),
      (size: _small, scale: 1.35, suffix: 'w375_t135'),
    ];
    const names = [
      'accueil',
      'commandes',
      'catalogue',
      'rapports',
      'profil',
    ];
    for (final variant in variants) {
      for (var i = 0; i < names.length; i++) {
        await _pump(
          tester,
          size: variant.size,
          textScale: variant.scale,
          index: i,
        );
        await _capture(tester, 'nav_${names[i]}_${variant.suffix}');
      }
      await _pump(
        tester,
        size: variant.size,
        textScale: variant.scale,
        index: 0,
        hidden: true,
      );
      await _capture(tester, 'nav_hidden_${variant.suffix}');
    }
    expect(Directory(_out).listSync().length, greaterThanOrEqualTo(12));
  });

  testWidgets('standalone dock chrome at 1.0 and 1.35', (tester) async {
    for (final scale in [1.0, 1.35]) {
      final size = scale == 1.0 ? _phone : _small;
      tester.view.physicalSize = Size(size.width * 2, size.height * 2);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MediaQuery(
          data: MediaQueryData(
            size: size,
            textScaler: TextScaler.linear(scale),
            padding: const EdgeInsets.only(bottom: 34),
            viewPadding: const EdgeInsets.only(bottom: 34),
          ),
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(locale: const Locale('fr')),
            home: ColoredBox(
              color: AppColors.background,
              child: RepaintBoundary(
                key: _rootKey,
                child: Scaffold(
                  backgroundColor: Colors.transparent,
                  body: const SizedBox.expand(),
                  bottomNavigationBar: MerchantBottomNav(
                    currentIndex: 2,
                    onSelect: (_) {},
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.text(AppStrings.tabCatalog), findsOneWidget);
      await _capture(
        tester,
        scale == 1.0 ? 'nav_dock_only_w390' : 'nav_dock_only_w375_t135',
      );
    }
  });
}
