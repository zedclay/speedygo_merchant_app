import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speedygo_merchant_app/app/theme/app_theme.dart';
import 'package:speedygo_merchant_app/core/storage/session_store.dart';
import 'package:speedygo_merchant_app/features/access/application/access_controller.dart';
import 'package:speedygo_merchant_app/features/access/data/models.dart';
import 'package:speedygo_merchant_app/features/auth/application/auth_infrastructure.dart';
import 'package:speedygo_merchant_app/features/auth/application/session_controller.dart';
import 'package:speedygo_merchant_app/features/auth/application/session_providers.dart';
import 'package:speedygo_merchant_app/features/auth/application/session_state.dart';
import 'package:speedygo_merchant_app/features/catalog/data/catalog_models.dart';
import 'package:speedygo_merchant_app/features/catalog/presentation/catalog_screen.dart';

import '../../features/phase1_flow_test.dart';

const _out =
    '/Users/mac/Downloads/speedygo_project/apps/merchant_app/audit/parity/catalog_loading/mocked';

const _rootKey = Key('capture-root');
const _phone = Size(390, 844);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Catalogue recovery captures at 1.0 and 1.35', (tester) async {
    const category = CatalogCategory(
      id: 'c-1',
      branchId: 'b-1',
      name: 'Boissons',
      sortOrder: 1,
      active: true,
    );
    const product = CatalogProduct(
      id: 'p-1',
      branchId: 'b-1',
      categoryId: 'c-1',
      name: 'Thé à la menthe',
      description: 'Fixture',
      priceMinor: '15000',
      available: true,
    );
    final merchant = FakeMerchantApi(
      catalogBootstrapHandler: ({
        required merchantId,
        required branchId,
      }) async =>
          const CatalogBootstrap(
            branchId: 'b-1',
            stats: CatalogStats(
              categoryCount: 1,
              productCount: 1,
              availableProductCount: 1,
            ),
            categories: [category],
          ),
      productsHandler: ({
        required merchantId,
        required branchId,
        String? categoryId,
      }) async =>
          const [product],
    );
    final branchOne = MerchantBranch(
      id: 'b-1',
      name: 'Fixture Branch',
      phone: '0550000001',
      addressText: 'Alger',
      latitude: 36.7,
      longitude: 3.0,
      operationalStatus: 'ACTIVE',
    );
    final mem = membership(branches: [branchOne]).copyWithName('Fixture Café');
    final container = ProviderContainer(
      overrides: [
        merchantApiProvider.overrideWithValue(merchant),
        sessionStoreProvider.overrideWithValue(MemorySessionStore()),
        contextStoreProvider.overrideWithValue(MemoryContextStore()),
        sessionControllerProvider.overrideWith(_ReadySession.new),
        accessControllerProvider.overrideWith(
          () => _ReadyAccess(mem, branchOne),
        ),
      ],
    );
    addTearDown(container.dispose);

    for (final scale in const [1.0, 1.35]) {
      await _pumpCatalog(tester, container, scale);
      await tester.pumpAndSettle();
      expect(find.text('Thé à la menthe'), findsOneWidget);
      await _capture(tester, 'catalog_recovery_t${scale.toStringAsFixed(2)}');
    }
  });
}

Future<void> _pumpCatalog(
  WidgetTester tester,
  ProviderContainer container,
  double textScale,
) async {
  tester.view.physicalSize = Size(_phone.width * 2, _phone.height * 2);
  tester.view.devicePixelRatio = 2;
  tester.view.padding = const FakeViewPadding(bottom: 34);
  tester.view.viewPadding = const FakeViewPadding(bottom: 34);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPadding);
  addTearDown(tester.view.resetViewPadding);
  await tester.binding.setSurfaceSize(_phone);
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MediaQuery(
        data: MediaQueryData(
          size: _phone,
          textScaler: TextScaler.linear(textScale),
          padding: const EdgeInsets.only(bottom: 34),
        ),
        child: MaterialApp(
          theme: AppTheme.light(locale: const Locale('fr')),
          home: const RepaintBoundary(
            key: _rootKey,
            child: CatalogScreen(),
          ),
        ),
      ),
    ),
  );
}

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

class _ReadySession extends SessionController {
  @override
  SessionState build() => const SessionState(
        phase: SessionPhase.ready,
        accountId: 'a-1',
      );
}

class _ReadyAccess extends AccessController {
  _ReadyAccess(this.mem, this.branch);
  final MerchantMembership mem;
  final MerchantBranch branch;

  @override
  AccessState build() => AccessState(
        destination: AccessDestination.home,
        membership: mem,
        selectedBranch: branch,
      );
}
