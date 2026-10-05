import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speedygo_merchant_app/core/constants/app_strings.dart';
import 'package:speedygo_merchant_app/core/storage/session_store.dart';
import 'package:speedygo_merchant_app/features/auth/application/session_providers.dart';
import 'package:speedygo_merchant_app/features/shell/language_settings_screen.dart';
import 'package:speedygo_merchant_app/l10n/app_localizations.dart';

const _out = 'audit/parity/captures/l10n_fr_ar_2026-10-04';
const _rootKey = Key('l10n-capture-root');

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

Future<void> _pump(
  WidgetTester tester, {
  required String locale,
  required Widget home,
  double textScale = 1.0,
}) async {
  tester.view.physicalSize = const Size(390 * 2, 844 * 2);
  tester.view.devicePixelRatio = 2;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        launchStoreProvider.overrideWithValue(
          MemoryLaunchStore(languageSeen: true, locale: locale),
        ),
        sessionStoreProvider.overrideWithValue(MemorySessionStore()),
      ],
      child: MediaQuery(
        data: MediaQueryData(
          size: const Size(390, 844),
          textScaler: TextScaler.linear(textScale),
        ),
        child: MaterialApp(
          locale: Locale(locale),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: Builder(
            builder: (context) {
              AppStrings.bind(AppLocalizations.of(context), locale);
              return RepaintBoundary(key: _rootKey, child: home);
            },
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

class _AddProductCapture extends StatelessWidget {
  const _AddProductCapture();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.catalogAddProduct)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            decoration: InputDecoration(
              labelText: AppStrings.catalogProductName,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            decoration: InputDecoration(
              labelText: AppStrings.catalogProductPrice,
            ),
          ),
          const SizedBox(height: 12),
          Text(AppStrings.catalogSectionAvailability),
          const SizedBox(height: 24),
          SizedBox(
            height: 56,
            child: FilledButton(
              onPressed: () {},
              child: Text(AppStrings.catalogSaveProduct),
            ),
          ),
        ],
      ),
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('capture language settings FR/AR 390x844', (tester) async {
    await _pump(
      tester,
      locale: 'fr',
      home: const LanguageSettingsScreen(),
    );
    await _capture(tester, 'row61_language_settings_fr');
    await _pump(
      tester,
      locale: 'ar',
      home: const LanguageSettingsScreen(),
    );
    await _capture(tester, 'row61_language_settings_ar');
  });

  testWidgets('capture add-product chrome FR/AR + scale 1.3', (tester) async {
    await _pump(tester, locale: 'fr', home: const _AddProductCapture());
    await _capture(tester, 'row45_add_product_fr');
    await _pump(tester, locale: 'ar', home: const _AddProductCapture());
    await _capture(tester, 'row45_add_product_ar');
    await _pump(
      tester,
      locale: 'ar',
      home: const _AddProductCapture(),
      textScale: 1.3,
    );
    await _capture(tester, 'row45_add_product_ar_scale13');
  });
}
