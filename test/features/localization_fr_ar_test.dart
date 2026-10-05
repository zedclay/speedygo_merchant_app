import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speedygo_merchant_app/core/constants/app_strings.dart';
import 'package:speedygo_merchant_app/core/locale/locale_support.dart';
import 'package:speedygo_merchant_app/core/storage/session_store.dart';
import 'package:speedygo_merchant_app/features/auth/application/session_controller.dart';
import 'package:speedygo_merchant_app/features/auth/application/session_providers.dart';
// sessionStoreProvider + launchStoreProvider live in session_providers.dart
import 'package:speedygo_merchant_app/features/shell/language_settings_screen.dart';
import 'package:speedygo_merchant_app/l10n/app_localizations.dart';

void _bind(String code) {
  AppStrings.bind(lookupAppLocalizations(Locale(code)), code);
}

Widget _app(Widget home, {String locale = 'fr'}) {
  _bind(locale);
  return ProviderScope(
    overrides: [
      launchStoreProvider.overrideWithValue(
        MemoryLaunchStore(languageSeen: true, locale: locale),
      ),
      sessionStoreProvider.overrideWithValue(MemorySessionStore()),
    ],
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
          return home;
        },
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('resolveInitialLanguageCode prefers stored then supported system', () {
    expect(resolveInitialLanguageCode(stored: 'ar'), 'ar');
    expect(resolveInitialLanguageCode(stored: 'fr'), 'fr');
    expect(
      resolveInitialLanguageCode(
        stored: null,
        platform: const Locale('ar', 'DZ'),
      ),
      'ar',
    );
    expect(
      resolveInitialLanguageCode(
        stored: null,
        platform: const Locale('en', 'US'),
      ),
      'fr',
    );
  });

  test('ARB key parity and catalog add-product strings differ by locale', () {
    _bind('fr');
    expect(AppStrings.catalogAddProduct, 'Ajouter un produit');
    expect(AppStrings.tabHome, 'Accueil');
    _bind('ar');
    expect(AppStrings.catalogAddProduct, isNot('Ajouter un produit'));
    expect(AppStrings.catalogAddProduct, isNotEmpty);
    expect(AppStrings.tabHome, isNot('Accueil'));
    expect(RegExp(r'[\u0600-\u06FF]').hasMatch(AppStrings.tabHome), isTrue);
  });

  testWidgets('language settings switches locale immediately and persists', (
    tester,
  ) async {
    final launch = MemoryLaunchStore(languageSeen: true, locale: 'fr');
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          launchStoreProvider.overrideWithValue(launch),
          sessionStoreProvider.overrideWithValue(MemorySessionStore()),
        ],
        child: MaterialApp(
          locale: const Locale('fr'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: Builder(
            builder: (context) {
              AppStrings.bind(AppLocalizations.of(context), 'fr');
              return const LanguageSettingsScreen();
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('language-settings-screen')), findsOneWidget);
    expect(find.byKey(const Key('language-option-ar')), findsOneWidget);

    await tester.tap(find.byKey(const Key('language-option-ar')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('language-apply')));
    await tester.pumpAndSettle();

    expect(launch.locale, 'ar');
    final container = ProviderScope.containerOf(
      tester.element(find.byKey(const Key('language-settings-screen'))),
    );
    expect(container.read(sessionControllerProvider).locale, 'ar');
  });

  testWidgets('Arabic add-product chrome at 390x844 text scale 1.3 RTL', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(
          size: Size(390, 844),
          textScaler: TextScaler.linear(1.3),
        ),
        child: _app(const _AddProductChrome(), locale: 'ar'),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(AppStrings.isArabic, isTrue);
    expect(find.text(AppStrings.catalogAddProduct), findsOneWidget);
    final dir = tester.widget<Directionality>(
      find.byType(Directionality).first,
    );
    expect(dir.textDirection, TextDirection.rtl);
  });

  testWidgets('French add-product chrome stays LTR French', (tester) async {
    await tester.pumpWidget(
      _app(const _AddProductChrome(), locale: 'fr'),
    );
    await tester.pumpAndSettle();
    expect(AppStrings.catalogAddProduct, 'Ajouter un produit');
    expect(AppStrings.isArabic, isFalse);
    final dir = tester.widget<Directionality>(
      find.byType(Directionality).first,
    );
    expect(dir.textDirection, TextDirection.ltr);
  });
}

class _AddProductChrome extends StatelessWidget {
  const _AddProductChrome();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.catalogAddProduct)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(AppStrings.catalogProductName),
          Text(AppStrings.catalogProductPrice),
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
