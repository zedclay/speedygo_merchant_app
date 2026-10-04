import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:speedygo_merchant_app/features/access/data/models.dart';
import 'package:speedygo_merchant_app/features/catalog/application/catalog_controller.dart';
import 'package:speedygo_merchant_app/features/catalog/data/catalog_models.dart';
import 'package:speedygo_merchant_app/features/catalog/presentation/product_duplicate_screen.dart';
import 'package:speedygo_merchant_app/features/store/data/store_models.dart';
import 'package:speedygo_merchant_app/features/store/presentation/opening_hours_exceptions_screen.dart';
import 'package:speedygo_merchant_app/features/store/presentation/store_cover_screen.dart';

import '../../features/phase1_flow_test.dart';
import '../../helpers/path_provider_fixture.dart';
import 'parity_harness.dart';

/// Synthetic gradient fixture (not reference imagery).
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

/// Synthetic round badge logo (not reference imagery).
final Uint8List _logoFixture = () {
  final image = img.Image(width: 512, height: 512);
  img.fill(image, color: img.ColorRgb8(255, 255, 255));
  img.fillCircle(
    image,
    x: 256,
    y: 256,
    radius: 230,
    color: img.ColorRgb8(0, 35, 111),
  );
  img.fillCircle(
    image,
    x: 256,
    y: 256,
    radius: 150,
    color: img.ColorRgb8(211, 238, 120),
  );
  img.fillCircle(
    image,
    x: 256,
    y: 256,
    radius: 70,
    color: img.ColorRgb8(0, 35, 111),
  );
  return Uint8List.fromList(img.encodePng(image));
}();

final Uint8List _coverFixture = _gradient(960, 540, [180, 120, 70], [100, 80, 130]);
final Uint8List _productFixture = _gradient(800, 800, [214, 160, 90], [150, 90, 40]);

const _category = CatalogCategory(
  id: 'c1',
  branchId: 'b1',
  name: 'Plat Principal',
  sortOrder: 0,
  active: true,
);

const _product = CatalogProduct(
  id: 'p1',
  branchId: 'b1',
  categoryId: 'c1',
  name: 'Couscous Royal',
  description: 'Semoule, légumes, agneau',
  priceMinor: '150000',
  available: true,
  hasImage: true,
);

class _BatchApi extends FakeMerchantApi {
  _BatchApi()
    : super(
        meHandler: () async => MerchantMe(
          merchantMembershipExists: true,
          memberships: [
            membership(
              branches: [branch('b1', name: 'Dar El Benna')],
            ).parityWith(name: 'Dar El Benna'),
          ],
        ),
        catalogBootstrapHandler: ({required merchantId, required branchId}) async =>
            CatalogBootstrap(
              branchId: branchId,
              stats: const CatalogStats(
                categoryCount: 1,
                productCount: 1,
                availableProductCount: 1,
              ),
              categories: const [_category],
            ),
        productsHandler:
            ({required merchantId, required branchId, categoryId}) async => [
              _product,
            ],
      ) {
    openingHoursHandler = ({required merchantId, required branchId}) async =>
        const OpeningHoursSchedule(
          branchId: 'b1',
          timezone: 'Africa/Algiers',
          hoursConfigured: true,
          version: 3,
          days: [
            OpeningDay(
              dayOfWeek: 1,
              intervals: [OpeningInterval(opens: '11:00', closes: '23:00')],
            ),
          ],
        );
    logoBytes = _logoFixture;
  }

  @override
  Future<Uint8List?> fetchBranchCoverBytes({
    required String merchantId,
    required String branchId,
  }) async => _coverFixture;

  @override
  Future<Uint8List?> fetchProductImageBytes({
    required String merchantId,
    required String branchId,
    required String productId,
  }) async => _productFixture;
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 20; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

Future<void> _precache(WidgetTester tester, Type screen, List<Uint8List> all) {
  return tester.runAsync(() async {
    for (final bytes in all) {
      await precacheImage(MemoryImage(bytes), tester.element(find.byType(screen)));
    }
  }).then((_) => _settle(tester));
}

void main() {
  installPathProviderFixture();

  group('batch 8 contract-completion captures', () {
    for (final v in parityVariants) {
      testWidgets('logo and cover ${v.suffix}', (tester) async {
        final container = await parityReady(_BatchApi());
        addTearDown(container.dispose);
        await parityPumpFull(
          tester,
          container: container,
          variant: v,
          child: const StoreCoverScreen(),
          pushed: true,
        );
        await _precache(tester, StoreCoverScreen, [_logoFixture, _coverFixture]);
        expect(find.byKey(const Key('store-logo-image')), findsOneWidget);
        await parityCapture(tester, 'b8_logo_cover_${v.suffix}');
      });

      testWidgets('exceptional hours ${v.suffix}', (tester) async {
        final api = _BatchApi()
          ..hoursExceptions.addAll(const [
            OpeningHoursException(
              date: '2026-10-05',
              closed: true,
              label: 'Aïd el-Fitr',
              customerMessage: null,
              intervals: [],
              version: 1,
              updatedAt: null,
            ),
            OpeningHoursException(
              date: '2026-10-09',
              closed: false,
              label: 'Vendredi Spécial',
              customerMessage: null,
              intervals: [OpeningInterval(opens: '10:00', closes: '15:00')],
              version: 1,
              updatedAt: null,
            ),
          ]);
        final container = await parityReady(api);
        addTearDown(container.dispose);
        await parityPumpFull(
          tester,
          container: container,
          variant: v,
          child: const OpeningHoursExceptionsScreen(),
          pushed: true,
        );
        final state = tester.state(find.byType(OpeningHoursExceptionsScreen));
        (state as dynamic).debugSetDate('2026-11-01');
        (state as dynamic).debugSetIntervals(const [
          OpeningInterval(opens: '09:00', closes: '13:00'),
        ]);
        await tester.pump();
        await tester.enterText(
          find.byKey(const Key('hours-exception-label')),
          'Fête de la Révolution',
        );
        await tester.enterText(
          find.byKey(const Key('hours-exception-message')),
          'Nous serons ouverts uniquement en matinée.',
        );
        FocusManager.instance.primaryFocus?.unfocus();
        await _settle(tester);
        await parityPumpFull(
          tester,
          container: container,
          variant: v,
          child: const OpeningHoursExceptionsScreen(),
          pushed: true,
        );
        expect(
          find.byKey(const Key('hours-exception-card-2026-10-05')),
          findsOneWidget,
        );
        await parityCapture(tester, 'b8_hours_exceptions_${v.suffix}');
      });

      testWidgets('duplicate product ${v.suffix}', (tester) async {
        final container = await parityReady(_BatchApi());
        addTearDown(container.dispose);
        await container.read(catalogControllerProvider.future);
        await parityPumpFull(
          tester,
          container: container,
          variant: v,
          child: const ProductDuplicateScreen(productId: 'p1'),
          pushed: true,
        );
        await _precache(tester, ProductDuplicateScreen, [_productFixture]);
        expect(find.byKey(const Key('duplicate-screen')), findsOneWidget);
        await parityCapture(tester, 'b8_duplicate_${v.suffix}');
      });
    }
  });
}
