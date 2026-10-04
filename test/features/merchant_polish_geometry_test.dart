import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:speedygo_merchant_app/app/theme/app_theme.dart';
import 'package:speedygo_merchant_app/core/constants/app_strings.dart';
import 'package:speedygo_merchant_app/core/widgets/merchant_ui.dart';
import 'package:speedygo_merchant_app/features/access/data/models.dart';
import 'package:speedygo_merchant_app/features/catalog/application/catalog_controller.dart';
import 'package:speedygo_merchant_app/features/catalog/data/catalog_models.dart';
import 'package:speedygo_merchant_app/features/catalog/presentation/catalog_screen.dart';
import 'package:speedygo_merchant_app/features/catalog/presentation/product_duplicate_screen.dart';
import 'package:speedygo_merchant_app/features/catalog/presentation/product_editor_screen.dart';
import 'package:speedygo_merchant_app/features/shell/merchant_shell.dart';
import 'package:speedygo_merchant_app/features/store/data/store_models.dart';
import 'package:speedygo_merchant_app/features/store/presentation/opening_hours_exceptions_screen.dart';
import 'package:speedygo_merchant_app/features/store/presentation/opening_hours_screen.dart';

import '../audit/parity/parity_harness.dart';
import '../helpers/path_provider_fixture.dart';
import 'phase1_flow_test.dart';

const _scales = [1.0, 1.35];
const _phone = Size(390, 844);
const _safeBottom = 34.0;

const _category = CatalogCategory(
  id: 'c1',
  branchId: 'b1',
  name: 'Plat Principal',
  sortOrder: 0,
  active: true,
);

CatalogProduct _product(String id, String name, {bool available = true}) =>
    CatalogProduct(
      id: id,
      branchId: 'b1',
      categoryId: 'c1',
      name: name,
      description: 'Fixture',
      priceMinor: '120000',
      available: available,
    );

final _products = [
  _product('p1', 'Couscous royal'),
  _product('p2', 'Chorba frik'),
  _product('p3', 'Salade méchouia'),
  _product('p4', 'Tajine zitoun'),
  _product('p5', 'Thé à la menthe'),
  _product('p6', 'Jus d’orange pressé'),
  _product('p-copy', 'Copie de Couscous royal', available: false),
];

class _GeometryApi extends FakeMerchantApi {
  _GeometryApi({String role = 'OWNER'})
    : super(
        meHandler: () async => MerchantMe(
          merchantMembershipExists: true,
          memberships: [
            membership(
              branches: [branch('b1', name: 'Dar El Benna')],
              role: role,
            ).parityWith(name: 'Dar El Benna'),
          ],
        ),
        catalogBootstrapHandler: ({required merchantId, required branchId}) async =>
            CatalogBootstrap(
              branchId: branchId,
              stats: CatalogStats(
                categoryCount: 1,
                productCount: _products.length,
                availableProductCount: _products.length - 1,
              ),
              categories: const [_category],
            ),
        productsHandler:
            ({required merchantId, required branchId, categoryId}) async =>
                _products,
      ) {
    openingHoursHandler = ({required merchantId, required branchId}) async =>
        OpeningHoursSchedule(
          branchId: 'b1',
          timezone: 'Africa/Algiers',
          hoursConfigured: true,
          version: 3,
          days: [
            for (var d = 1; d <= 7; d++)
              OpeningDay(
                dayOfWeek: d,
                intervals: const [
                  OpeningInterval(opens: '11:00', closes: '23:00'),
                ],
              ),
          ],
        );
    duplicateHandler =
        ({required merchantId, required productId, required requestId, name}) async =>
            ProductDuplicateResult(
              product: _products.last,
              replayed: false,
              optionGroupCount: 0,
              optionCount: 0,
              imageCopied: false,
            );
  }

  @override
  Future<CatalogProduct> getProduct({
    required String merchantId,
    required String productId,
  }) async => _products.firstWhere((p) => p.id == productId);

  @override
  Future<Uint8List?> fetchProductImageBytes({
    required String merchantId,
    required String branchId,
    required String productId,
  }) async => null;
}

Future<void> _frames(WidgetTester tester, [int count = 16]) async {
  for (var i = 0; i < count; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

MediaQueryData _media(
  double scale, {
  Size size = _phone,
  double safeBottom = _safeBottom,
  double keyboard = 0,
}) => MediaQueryData(
  size: size,
  textScaler: TextScaler.linear(scale),
  viewPadding: EdgeInsets.only(bottom: safeBottom),
  padding: EdgeInsets.only(
    bottom: (safeBottom - keyboard).clamp(0, safeBottom).toDouble(),
  ),
  viewInsets: EdgeInsets.only(bottom: keyboard),
);

void _surface(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Rect _snackRect(WidgetTester tester) => tester.getRect(
  find
      .descendant(of: find.byType(SnackBar), matching: find.byType(Material))
      .first,
);

/// The snack bar must sit wholly above the sticky bar and its primary action.
void _expectSnackClear(WidgetTester tester, Finder primary) {
  final snack = _snackRect(tester);
  final bar = tester.getRect(find.byType(MerchantStickyBar).last);
  final action = tester.getRect(primary);
  expect(snack.bottom, lessThanOrEqualTo(bar.top), reason: 'snack $snack bar $bar');
  expect(snack.overlaps(action), isFalse, reason: 'snack $snack action $action');
  expect(action.bottom, lessThanOrEqualTo(bar.bottom));
}

GoRouter _router(String initial, {bool pushFromHub = true}) {
  final router = GoRouter(
    initialLocation: pushFromHub ? '/' : initial,
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) =>
            const Scaffold(body: Text('hub', key: Key('test-hub'))),
      ),
      GoRoute(
        path: '/app/catalog',
        builder: (_, _) => Scaffold(
          body: const CatalogScreen(),
          bottomNavigationBar: MerchantBottomNav(
            currentIndex: 2,
            onSelect: (_) {},
          ),
        ),
      ),
      GoRoute(
        path: '/app/catalog/products/:productId/duplicate',
        builder: (_, state) => ProductDuplicateScreen(
          productId: state.pathParameters['productId']!,
        ),
      ),
      GoRoute(
        path: '/app/catalog/products/:productId',
        builder: (_, state) =>
            ProductEditorScreen(productId: state.pathParameters['productId']),
      ),
      GoRoute(
        path: '/hours/exceptions',
        builder: (_, _) => const OpeningHoursExceptionsScreen(),
      ),
      GoRoute(path: '/hours', builder: (_, _) => const OpeningHoursScreen()),
    ],
  );
  if (pushFromHub) router.push(initial);
  return router;
}

Future<void> _pumpRouter(
  WidgetTester tester,
  ProviderContainer container,
  GoRouter router,
  MediaQueryData media, {
  ThemeData? theme,
}) async {
  _surface(tester, media.size);
  await tester.pumpWidget(
    MediaQuery(
      data: media,
      child: UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          theme: theme ?? AppTheme.light(locale: const Locale('fr')),
          routerConfig: router,
        ),
      ),
    ),
  );
  await _frames(tester, 30);
}

Future<void> _scrollCatalogToEnd(WidgetTester tester) async {
  final scroll = tester.state<ScrollableState>(
    find
        .descendant(
          of: find.byKey(const Key('catalog-scroll')),
          matching: find.byType(Scrollable),
        )
        .first,
  );
  for (var i = 0; i < 10; i++) {
    final max = scroll.position.maxScrollExtent;
    scroll.position.jumpTo(max);
    await _frames(tester, 4);
    if (scroll.position.maxScrollExtent == max) break;
  }
}

void main() {
  installPathProviderFixture();

  group('snack bar clears the in-body sticky bar', () {
    for (final scale in _scales) {
      testWidgets('exceptional-hours save at $scale', (tester) async {
        final container = await parityReady(_GeometryApi());
        addTearDown(container.dispose);
        await _pumpRouter(
          tester,
          container,
          _router('/hours/exceptions'),
          _media(scale),
        );
        final state = tester.state(find.byType(OpeningHoursExceptionsScreen));
        (state as dynamic).debugSetDate('2026-11-01');
        await tester.pump();
        final closed = find.byKey(const Key('hours-exception-status-closed'));
        await tester.ensureVisible(closed);
        await tester.tap(closed);
        await tester.pump();
        await tester.enterText(
          find.byKey(const Key('hours-exception-label')),
          'Fête',
        );
        FocusManager.instance.primaryFocus?.unfocus();
        await _frames(tester, 8);
        await tester.tap(find.byKey(const Key('hours-exception-save')));
        await _frames(tester);
        expect(find.text(AppStrings.hoursExceptionsSaved), findsOneWidget);
        _expectSnackClear(
          tester,
          find.byKey(const Key('hours-exception-save')),
        );
      });

      testWidgets('duplicate success on the copy editor at $scale', (
        tester,
      ) async {
        final container = await parityReady(_GeometryApi());
        addTearDown(container.dispose);
        await container.read(catalogControllerProvider.future);
        await _pumpRouter(
          tester,
          container,
          _router('/app/catalog/products/p1/duplicate'),
          _media(scale),
        );
        await tester.tap(find.byKey(const Key('duplicate-create')));
        await _frames(tester, 30);
        expect(find.byKey(const Key('product-editor-screen')), findsOneWidget);
        expect(find.text(AppStrings.duplicateCreated), findsOneWidget);
        _expectSnackClear(tester, find.byKey(const Key('product-editor-save')));
      });

      testWidgets('weekly hours save at $scale', (tester) async {
        final container = await parityReady(_GeometryApi());
        addTearDown(container.dispose);
        await _pumpRouter(tester, container, _router('/hours'), _media(scale));
        await tester.tap(find.byKey(const Key('opening-hours-switch-1')));
        await _frames(tester, 4);
        await tester.tap(find.byKey(const Key('opening-hours-save')));
        await _frames(tester);
        expect(find.text(AppStrings.openingHoursSaved), findsOneWidget);
        _expectSnackClear(tester, find.byKey(const Key('opening-hours-save')));
      });
    }

    Future<void> pumpGeneric(
      WidgetTester tester,
      MediaQueryData media, {
      required bool sticky,
      bool dual = false,
    }) async {
      _surface(tester, media.size);
      await tester.pumpWidget(
        MediaQuery(
          data: media,
          child: MaterialApp(
            theme: AppTheme.light(locale: const Locale('fr')),
            home: MerchantScaffold(
              title: 'Formulaire',
              bodyPadding: EdgeInsets.zero,
              body: Builder(
                builder: (context) => Column(
                  children: [
                    Expanded(
                      child: Center(
                        child: TextButton(
                          key: const Key('show-snack'),
                          onPressed: () =>
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text('Enregistré.'),
                                  action: SnackBarAction(
                                    label: 'Annuler',
                                    onPressed: () {},
                                  ),
                                ),
                              ),
                          child: const Text('show'),
                        ),
                      ),
                    ),
                    if (sticky && dual)
                      MerchantDualStickyBar(
                        secondary: OutlinedButton(
                          onPressed: () {},
                          child: const Text('Aperçu'),
                        ),
                        primary: FilledButton(
                          key: const Key('primary'),
                          onPressed: () {},
                          child: const Text('Enregistrer les modifications'),
                        ),
                      )
                    else if (sticky)
                      MerchantStickyBar(
                        child: FilledButton(
                          key: const Key('primary'),
                          onPressed: () {},
                          child: const Text('Enregistrer'),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await _frames(tester, 4);
      await tester.tap(find.byKey(const Key('show-snack')));
      await _frames(tester);
    }

    for (final scale in _scales) {
      for (final safe in [0.0, _safeBottom]) {
        for (final keyboard in [0.0, 320.0]) {
          for (final dual in [false, true]) {
            testWidgets(
              'scale $scale safe $safe keyboard $keyboard dual $dual',
              (tester) async {
                await pumpGeneric(
                  tester,
                  _media(scale, safeBottom: safe, keyboard: keyboard),
                  sticky: true,
                  dual: dual,
                );
                _expectSnackClear(tester, find.byKey(const Key('primary')));
                final snack = _snackRect(tester);
                if (keyboard > 0) {
                  expect(
                    snack.bottom,
                    lessThanOrEqualTo(_phone.height - keyboard),
                  );
                }
                // Message, action and duration are the caller's.
                expect(find.text('Enregistré.'), findsOneWidget);
                expect(find.text('Annuler'), findsOneWidget);
                expect(
                  tester.widget<SnackBar>(find.byType(SnackBar)).duration,
                  const Duration(milliseconds: 4000),
                );
              },
            );
          }
        }
      }
    }

    testWidgets('without a sticky bar the snack bar keeps its position', (
      tester,
    ) async {
      await pumpGeneric(tester, _media(1.0), sticky: false);
      final snack = _snackRect(tester);
      expect(snack.left, 0);
      expect(snack.right, _phone.width);
      final scope = tester.state(find.byType(MerchantSnackBarScope));
      expect((scope as dynamic).lift, 0);
    });
  });

  group('catalogue end clears the add button', () {
    void expectClear(WidgetTester tester, {required double screenBottom}) {
      final card = tester.getRect(find.byKey(const Key('catalog-product-p-copy')));
      final fab = tester.getRect(find.byKey(const Key('catalog-add-fab')));
      expect(card.overlaps(fab), isFalse, reason: 'card $card fab $fab');
      expect(fab.top - card.bottom, greaterThanOrEqualTo(16));
      expect(card.bottom, lessThanOrEqualTo(screenBottom));
      final nav = find.byType(MerchantBottomNav);
      if (nav.evaluate().isNotEmpty) {
        expect(card.bottom, lessThanOrEqualTo(tester.getRect(nav).top));
      }
    }

    for (final scale in _scales) {
      testWidgets('inside the shell at $scale', (tester) async {
        final container = await parityReady(_GeometryApi());
        addTearDown(container.dispose);
        await _pumpRouter(
          tester,
          container,
          _router('/app/catalog', pushFromHub: false),
          _media(scale),
        );
        await _scrollCatalogToEnd(tester);
        expectClear(tester, screenBottom: _phone.height - _safeBottom);
        expect(
          tester.getRect(find.byKey(const Key('catalog-add-fab'))).bottom,
          lessThanOrEqualTo(tester.getRect(find.byType(MerchantBottomNav)).top),
        );
      });

      testWidgets('without the shell, above the safe area at $scale', (
        tester,
      ) async {
        final container = await parityReady(_GeometryApi());
        addTearDown(container.dispose);
        final router = GoRouter(
          routes: [GoRoute(path: '/', builder: (_, _) => const CatalogScreen())],
        );
        await _pumpRouter(tester, container, router, _media(scale));
        await _scrollCatalogToEnd(tester);
        expectClear(tester, screenBottom: _phone.height - _safeBottom);
      });

      testWidgets('a taller add button at $scale', (tester) async {
        final container = await parityReady(_GeometryApi());
        addTearDown(container.dispose);
        final base = AppTheme.light(locale: const Locale('fr'));
        await _pumpRouter(
          tester,
          container,
          _router('/app/catalog', pushFromHub: false),
          _media(scale),
          theme: base.copyWith(
            floatingActionButtonTheme: base.floatingActionButtonTheme.copyWith(
              extendedSizeConstraints: const BoxConstraints.tightFor(
                height: 88,
              ),
            ),
          ),
        );
        await _scrollCatalogToEnd(tester);
        expect(
          tester.getSize(find.byKey(const Key('catalog-add-fab'))).height,
          88,
        );
        expectClear(tester, screenBottom: _phone.height - _safeBottom);
      });
    }
  });

  group('STAFF on the duplicate route', () {
    void expectForbidden() {
      expect(find.byKey(const Key('duplicate-forbidden')), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.text(AppStrings.duplicateTitle), findsOneWidget);
      expect(find.byKey(const Key('duplicate-forbidden-back')), findsOneWidget);
      expect(find.text(AppStrings.duplicateBackToCatalog), findsOneWidget);
      expect(find.byKey(const Key('duplicate-name')), findsNothing);
      expect(find.byKey(const Key('duplicate-create')), findsNothing);
      expect(find.byKey(const Key('duplicate-source')), findsNothing);
    }

    for (final scale in _scales) {
      testWidgets('reached directly: back goes to the catalogue at $scale', (
        tester,
      ) async {
        final api = _GeometryApi(role: 'STAFF');
        final container = await parityReady(api);
        addTearDown(container.dispose);
        await _pumpRouter(
          tester,
          container,
          _router('/app/catalog/products/p1/duplicate', pushFromHub: false),
          _media(scale),
        );
        expectForbidden();
        await tester.tap(find.byKey(const Key('duplicate-forbidden-back')));
        await _frames(tester, 20);
        expect(find.byType(CatalogScreen), findsOneWidget);
        expect(api.duplicateRequestIds, isEmpty);
      });

      testWidgets('“Retour au catalogue” opens the catalogue at $scale', (
        tester,
      ) async {
        final api = _GeometryApi(role: 'STAFF');
        final container = await parityReady(api);
        addTearDown(container.dispose);
        await _pumpRouter(
          tester,
          container,
          _router('/app/catalog/products/p1/duplicate'),
          _media(scale),
        );
        expectForbidden();
        await tester.tap(find.byKey(const Key('duplicate-forbidden-catalog')));
        await _frames(tester, 20);
        expect(find.byType(CatalogScreen), findsOneWidget);
        expect(api.duplicateRequestIds, isEmpty);
      });
    }

    testWidgets('pushed over another screen: back pops', (tester) async {
      final container = await parityReady(_GeometryApi(role: 'STAFF'));
      addTearDown(container.dispose);
      final router = _router('/', pushFromHub: false);
      await _pumpRouter(tester, container, router, _media(1.0));
      router.push('/app/catalog/products/p1/duplicate');
      await _frames(tester, 20);
      expect(find.byKey(const Key('duplicate-forbidden')), findsOneWidget);
      await tester.tap(find.byKey(const Key('duplicate-forbidden-back')));
      await _frames(tester, 20);
      expect(find.byKey(const Key('test-hub')), findsOneWidget);
    });

    testWidgets('OWNER reached directly: close falls back to the catalogue', (
      tester,
    ) async {
      final container = await parityReady(_GeometryApi());
      addTearDown(container.dispose);
      await container.read(catalogControllerProvider.future);
      await _pumpRouter(
        tester,
        container,
        _router('/app/catalog/products/p1/duplicate', pushFromHub: false),
        _media(1.0),
      );
      expect(find.byKey(const Key('duplicate-screen')), findsOneWidget);
      await tester.tap(find.byKey(const Key('duplicate-close')));
      await _frames(tester, 20);
      expect(find.byType(CatalogScreen), findsOneWidget);
    });
  });
}
