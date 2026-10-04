import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:image/image.dart' as img;
import 'package:speedygo_merchant_app/app/theme/app_theme.dart';
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

import '../../features/phase1_flow_test.dart';
import '../../helpers/path_provider_fixture.dart';
import 'parity_harness.dart';

/// Before/after captures of the polish pass: snack bar against the in-body
/// sticky bar, the catalogue end above the FAB, and STAFF on the duplicate
/// route. Each capture also writes the measured rectangles; this file records
/// and never asserts, so it can document the state before a fix.
const _phase = String.fromEnvironment('B9_PHASE', defaultValue: 'after');
const _geometryOut =
    '/Users/mac/Downloads/speedygo_project/apps/merchant_app/audit/parity/polish/geometry';

/// Bottom safe area of a notched phone (home indicator).
const _safeBottom = 34.0;

double _heightFor(ParityVariant v) => v.width == parityRefWidth ? 844 : 812;

Uint8List _gradient(int w, int h, List<int> from, List<int> to) {
  final image = img.Image(width: w, height: h);
  for (var y = 0; y < h; y++) {
    final t = y / h;
    img.drawLine(
      image,
      x1: 0,
      y1: y,
      x2: w - 1,
      y2: y,
      color: img.ColorRgb8(
        (from[0] + (to[0] - from[0]) * t).round(),
        (from[1] + (to[1] - from[1]) * t).round(),
        (from[2] + (to[2] - from[2]) * t).round(),
      ),
    );
  }
  return Uint8List.fromList(img.encodePng(image));
}

final Uint8List _productFixture = _gradient(
  480,
  480,
  [214, 160, 90],
  [150, 90, 40],
);

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
      hasImage: true,
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

class _PolishApi extends FakeMerchantApi {
  _PolishApi({String role = 'OWNER'})
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
              imageCopied: true,
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
  }) async => _productFixture;
}

Map<String, double> _rect(WidgetTester tester, Finder finder) {
  final r = tester.getRect(finder.first);
  return {'left': r.left, 'top': r.top, 'right': r.right, 'bottom': r.bottom};
}

Rect? _snackRect(WidgetTester tester) {
  final material = find.descendant(
    of: find.byType(SnackBar),
    matching: find.byType(Material),
  );
  if (material.evaluate().isEmpty) return null;
  return tester.getRect(material.first);
}

void _writeGeometry(String name, Map<String, Object?> data) {
  final file = File('$_geometryOut/$name.json');
  file.parent.createSync(recursive: true);
  file.writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert({'phase': _phase, ...data})}\n',
  );
}

Map<String, Object?> _snackGeometry(
  WidgetTester tester,
  ParityVariant v,
  Finder primary,
) {
  final snack = _snackRect(tester);
  final bar = tester.getRect(find.byType(MerchantStickyBar).last);
  final action = tester.getRect(primary.first);
  return {
    'variant': v.suffix,
    'textScale': v.textScale,
    'surface': {'width': v.width, 'height': _heightFor(v)},
    'safeBottom': _safeBottom,
    'snackBar': snack == null
        ? null
        : {
            'left': snack.left,
            'top': snack.top,
            'right': snack.right,
            'bottom': snack.bottom,
          },
    'stickyBar': {
      'left': bar.left,
      'top': bar.top,
      'right': bar.right,
      'bottom': bar.bottom,
    },
    'primaryAction': {
      'left': action.left,
      'top': action.top,
      'right': action.right,
      'bottom': action.bottom,
    },
    'snackOverlapsStickyBar': snack != null && snack.overlaps(bar),
    'snackOverlapsPrimaryAction': snack != null && snack.overlaps(action),
    'gapAboveStickyBar': snack == null ? null : bar.top - snack.bottom,
  };
}

Future<void> _frames(WidgetTester tester, [int count = 16]) async {
  for (var i = 0; i < count; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

Widget _app(
  ProviderContainer container,
  ParityVariant v,
  GoRouter router,
) {
  final size = Size(v.width, _heightFor(v));
  return MediaQuery(
    data: MediaQueryData(
      size: size,
      textScaler: TextScaler.linear(v.textScale),
      padding: const EdgeInsets.only(bottom: _safeBottom),
      viewPadding: const EdgeInsets.only(bottom: _safeBottom),
    ),
    child: UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(locale: const Locale('fr')),
        builder: (context, nav) =>
            RepaintBoundary(key: parityRootKey, child: nav),
        routerConfig: router,
      ),
    ),
  );
}

Future<void> _pumpRouter(
  WidgetTester tester,
  ProviderContainer container,
  ParityVariant v,
  GoRouter router,
) async {
  final size = Size(v.width, _heightFor(v));
  tester.view.physicalSize = Size(size.width * 2, size.height * 2);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(_app(container, v, router));
  await _frames(tester, 30);
}

GoRouter _router(String initial, {bool pushFromHub = true}) {
  final router = GoRouter(
    initialLocation: pushFromHub ? '/' : initial,
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => const Scaffold(body: SizedBox.shrink()),
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
      GoRoute(
        path: '/hours',
        builder: (_, _) => const OpeningHoursScreen(),
      ),
    ],
  );
  if (pushFromHub) router.push(initial);
  return router;
}

Future<void> _precache(WidgetTester tester) => tester.runAsync(() async {
  await precacheImage(
    MemoryImage(_productFixture),
    tester.element(find.byType(MaterialApp)),
  );
});

void main() {
  installPathProviderFixture();

  group('batch 9 polish captures ($_phase)', () {
    for (final v in parityVariants) {
      testWidgets('snack bar on exceptional-hours save ${v.suffix}', (
        tester,
      ) async {
        final container = await parityReady(_PolishApi());
        addTearDown(container.dispose);
        await _pumpRouter(tester, container, v, _router('/hours/exceptions'));
        final state = tester.state(find.byType(OpeningHoursExceptionsScreen));
        (state as dynamic).debugSetDate('2026-11-01');
        await tester.pump();
        final closed = find.byKey(const Key('hours-exception-status-closed'));
        await tester.ensureVisible(closed);
        await tester.tap(closed);
        await tester.pump();
        await tester.enterText(
          find.byKey(const Key('hours-exception-label')),
          'Fête de la Révolution',
        );
        FocusManager.instance.primaryFocus?.unfocus();
        await _frames(tester, 8);
        await tester.tap(find.byKey(const Key('hours-exception-save')));
        await _frames(tester);
        final name = 'b9_snack_hours_${_phase}_${v.suffix}';
        _writeGeometry(
          name,
          _snackGeometry(
            tester,
            v,
            find.byKey(const Key('hours-exception-save')),
          ),
        );
        await parityCapture(tester, name);
      });

      testWidgets('snack bar on the duplicate editor ${v.suffix}', (
        tester,
      ) async {
        final container = await parityReady(_PolishApi());
        addTearDown(container.dispose);
        await container.read(catalogControllerProvider.future);
        await _pumpRouter(
          tester,
          container,
          v,
          _router('/app/catalog/products/p1/duplicate'),
        );
        await tester.tap(find.byKey(const Key('duplicate-create')));
        await _frames(tester, 30);
        await _precache(tester);
        await _frames(tester, 6);
        final name = 'b9_snack_duplicate_editor_${_phase}_${v.suffix}';
        _writeGeometry(
          name,
          _snackGeometry(
            tester,
            v,
            find.byKey(const Key('product-editor-save')),
          ),
        );
        await parityCapture(tester, name);
      });

      testWidgets('snack bar on weekly hours save ${v.suffix}', (
        tester,
      ) async {
        final container = await parityReady(_PolishApi());
        addTearDown(container.dispose);
        await _pumpRouter(tester, container, v, _router('/hours'));
        await tester.tap(find.byKey(const Key('opening-hours-switch-1')));
        await _frames(tester, 4);
        await tester.tap(find.byKey(const Key('opening-hours-save')));
        await _frames(tester);
        final name = 'b9_snack_weekly_hours_${_phase}_${v.suffix}';
        _writeGeometry(
          name,
          _snackGeometry(
            tester,
            v,
            find.byKey(const Key('opening-hours-save')),
          ),
        );
        await parityCapture(tester, name);
      });

      testWidgets('catalogue end above the FAB ${v.suffix}', (tester) async {
        final container = await parityReady(_PolishApi());
        addTearDown(container.dispose);
        await _pumpRouter(
          tester,
          container,
          v,
          _router('/app/catalog', pushFromHub: false),
        );
        await _precache(tester);
        final scroll = tester.state<ScrollableState>(
          find
              .descendant(
                of: find.byKey(const Key('catalog-scroll')),
                matching: find.byType(Scrollable),
              )
              .first,
        );
        // Lazy slivers refine the extent as rows build; jump until it settles.
        for (var i = 0; i < 10; i++) {
          final max = scroll.position.maxScrollExtent;
          scroll.position.jumpTo(max);
          await _frames(tester, 4);
          if (scroll.position.maxScrollExtent == max) break;
        }
        await _frames(tester, 6);
        final last = find.byKey(const Key('catalog-product-p-copy'));
        final card = tester.getRect(last);
        final fab = tester.getRect(find.byKey(const Key('catalog-add-fab')));
        final nav = tester.getRect(find.byType(MerchantBottomNav));
        final name = 'b9_catalog_end_${_phase}_${v.suffix}';
        _writeGeometry(name, {
          'variant': v.suffix,
          'textScale': v.textScale,
          'surface': {'width': v.width, 'height': _heightFor(v)},
          'safeBottom': _safeBottom,
          'lastCard': _rect(tester, last),
          'fab': _rect(tester, find.byKey(const Key('catalog-add-fab'))),
          'bottomNav': _rect(tester, find.byType(MerchantBottomNav)),
          'lastCardOverlapsFab': card.overlaps(fab),
          'gapAboveFab': fab.top - card.bottom,
          'gapAboveNav': nav.top - card.bottom,
          'gapAboveSafeArea': _heightFor(v) - _safeBottom - card.bottom,
        });
        await parityCapture(tester, name);
      });

      testWidgets('STAFF on the direct duplicate route ${v.suffix}', (
        tester,
      ) async {
        final container = await parityReady(_PolishApi(role: 'STAFF'));
        addTearDown(container.dispose);
        await _pumpRouter(
          tester,
          container,
          v,
          _router('/app/catalog/products/p1/duplicate', pushFromHub: false),
        );
        final name = 'b9_staff_duplicate_${_phase}_${v.suffix}';
        _writeGeometry(name, {
          'variant': v.suffix,
          'textScale': v.textScale,
          'appBar': find.byType(AppBar).evaluate().isNotEmpty,
          'backButton':
              find.byKey(const Key('duplicate-close')).evaluate().isNotEmpty ||
              find.byKey(const Key('merchant-back')).evaluate().isNotEmpty ||
              find
                  .byKey(const Key('duplicate-forbidden-back'))
                  .evaluate()
                  .isNotEmpty,
          'catalogFallback': find
              .byKey(const Key('duplicate-forbidden-catalog'))
              .evaluate()
              .isNotEmpty,
          'duplicateFormShown':
              find.byKey(const Key('duplicate-name')).evaluate().isNotEmpty,
          'createActionShown':
              find.byKey(const Key('duplicate-create')).evaluate().isNotEmpty,
        });
        await parityCapture(tester, name);
      });
    }
  });
}
