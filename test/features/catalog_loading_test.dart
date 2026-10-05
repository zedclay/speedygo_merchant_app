import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speedygo_merchant_app/app/theme/app_theme.dart';
import 'package:speedygo_merchant_app/core/constants/app_strings.dart';
import 'package:speedygo_merchant_app/core/errors/app_exception.dart';
import 'package:speedygo_merchant_app/core/storage/session_store.dart';
import 'package:speedygo_merchant_app/features/access/application/access_controller.dart';
import 'package:speedygo_merchant_app/features/access/data/models.dart';
import 'package:speedygo_merchant_app/features/auth/application/auth_infrastructure.dart';
import 'package:speedygo_merchant_app/features/auth/application/session_controller.dart';
import 'package:speedygo_merchant_app/features/auth/application/session_providers.dart';
import 'package:speedygo_merchant_app/features/auth/application/session_state.dart';
import 'package:speedygo_merchant_app/features/catalog/application/catalog_controller.dart';
import 'package:speedygo_merchant_app/features/catalog/data/catalog_models.dart';
import 'package:speedygo_merchant_app/features/catalog/presentation/catalog_screen.dart';

import 'phase1_flow_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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
  const bootstrap = CatalogBootstrap(
    branchId: 'b-1',
    stats: CatalogStats(
      categoryCount: 1,
      productCount: 1,
      availableProductCount: 1,
    ),
    categories: [category],
  );
  const emptyBootstrap = CatalogBootstrap(
    branchId: 'b-1',
    stats: CatalogStats(
      categoryCount: 0,
      productCount: 0,
      availableProductCount: 0,
    ),
    categories: [],
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

  ProviderContainer containerFor(
    FakeMerchantApi merchant, {
    SessionController Function()? session,
    AccessController Function()? access,
  }) {
    return ProviderContainer(
      overrides: [
        merchantApiProvider.overrideWithValue(merchant),
        sessionStoreProvider.overrideWithValue(MemorySessionStore()),
        contextStoreProvider.overrideWithValue(MemoryContextStore()),
        sessionControllerProvider.overrideWith(
          session ?? _ReadySession.new,
        ),
        accessControllerProvider.overrideWith(
          access ?? () => _ReadyAccess(mem, branchOne),
        ),
      ],
    );
  }

  Future<void> pumpCatalog(
    WidgetTester tester,
    ProviderContainer container,
  ) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.light(locale: const Locale('fr')),
          home: const CatalogScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
  }

  testWidgets('populated response shows products, not Chargement', (
    tester,
  ) async {
    final merchant = FakeMerchantApi(
      catalogBootstrapHandler: ({
        required merchantId,
        required branchId,
      }) async =>
          bootstrap,
      productsHandler: ({
        required merchantId,
        required branchId,
        String? categoryId,
      }) async =>
          const [product],
    );
    final container = containerFor(merchant);
    addTearDown(container.dispose);
    await pumpCatalog(tester, container);
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.loading), findsNothing);
    expect(find.text('Thé à la menthe'), findsOneWidget);
    expect(find.byKey(const Key('catalog-product-p-1')), findsOneWidget);
  });

  testWidgets('valid empty response shows truthful empty state', (
    tester,
  ) async {
    final merchant = FakeMerchantApi(
      catalogBootstrapHandler: ({
        required merchantId,
        required branchId,
      }) async =>
          emptyBootstrap,
      productsHandler: ({
        required merchantId,
        required branchId,
        String? categoryId,
      }) async =>
          const [],
    );
    final container = containerFor(merchant);
    addTearDown(container.dispose);
    await pumpCatalog(tester, container);
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.loading), findsNothing);
    expect(find.text(AppStrings.catalogEmptyProducts), findsOneWidget);
    expect(find.byKey(const Key('catalog-empty-products')), findsOneWidget);
    expect(find.byKey(const Key('catalog-product-p-1')), findsNothing);
  });

  testWidgets('timeout becomes retryable error, not Chargement', (
    tester,
  ) async {
    final merchant = FakeMerchantApi(
      catalogBootstrapHandler: ({
        required merchantId,
        required branchId,
      }) =>
          Completer<CatalogBootstrap>().future,
    );
    final container = containerFor(merchant);
    addTearDown(container.dispose);
    await pumpCatalog(tester, container);
    expect(find.text(AppStrings.loading), findsOneWidget);

    await tester.pump(kCatalogLoadTimeout + const Duration(milliseconds: 50));

    expect(find.text(AppStrings.loading), findsNothing);
    expect(find.text(AppStrings.catalogLoadError), findsOneWidget);
    expect(find.text(AppStrings.retry), findsOneWidget);
  });

  testWidgets('offline/network failure becomes retryable error', (
    tester,
  ) async {
    final merchant = FakeMerchantApi(
      catalogBootstrapHandler: ({
        required merchantId,
        required branchId,
      }) async {
        throw NetworkException(
          AppStrings.networkError,
          code: 'NETWORK',
        );
      },
    );
    final container = containerFor(merchant);
    addTearDown(container.dispose);
    await pumpCatalog(tester, container);
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.loading), findsNothing);
    expect(find.text(AppStrings.catalogLoadError), findsOneWidget);
    expect(find.text(AppStrings.retry), findsOneWidget);
  });

  testWidgets('backend 500 becomes retryable error', (tester) async {
    final merchant = FakeMerchantApi(
      catalogBootstrapHandler: ({
        required merchantId,
        required branchId,
      }) async {
        throw const ApiException(
          'broken',
          code: 'INTERNAL',
          statusCode: 500,
        );
      },
    );
    final container = containerFor(merchant);
    addTearDown(container.dispose);
    await pumpCatalog(tester, container);
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.loading), findsNothing);
    expect(find.text(AppStrings.catalogLoadError), findsOneWidget);
    expect(find.text(AppStrings.retry), findsOneWidget);
  });

  test('authentication failure invalidates the session', () async {
    final session = _TrackingSession();
    final merchant = FakeMerchantApi(
      catalogBootstrapHandler: ({
        required merchantId,
        required branchId,
      }) async {
        throw const ApiException(
          'expired',
          code: 'AUTH_INVALID_TOKEN',
          statusCode: 401,
        );
      },
    );
    final container = containerFor(
      merchant,
      session: () => session,
    );
    addTearDown(container.dispose);

    try {
      await container.read(catalogControllerProvider.future);
      fail('expected AUTH_INVALID_TOKEN');
    } on ApiException catch (e) {
      expect(e.code, 'AUTH_INVALID_TOKEN');
    }
    expect(session.invalidations, 1);
    expect(
      container.read(sessionControllerProvider).phase,
      SessionPhase.signedOut,
    );
    expect(container.read(catalogControllerProvider).hasError, isTrue);
  });

  testWidgets('retry reruns the request and can recover', (tester) async {
    var calls = 0;
    final merchant = FakeMerchantApi(
      catalogBootstrapHandler: ({
        required merchantId,
        required branchId,
      }) async =>
          bootstrap,
      productsHandler: ({
        required merchantId,
        required branchId,
        String? categoryId,
      }) async {
        calls += 1;
        if (calls == 1) {
          throw NetworkException(
            AppStrings.networkError,
            code: 'NETWORK',
          );
        }
        return const [product];
      },
    );
    final container = containerFor(merchant);
    addTearDown(container.dispose);
    await pumpCatalog(tester, container);
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.catalogLoadError), findsOneWidget);
    expect(calls, 1);

    await tester.tap(find.text(AppStrings.retry));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(calls, 2);
    expect(find.text(AppStrings.catalogLoadError), findsNothing);
    expect(find.text('Thé à la menthe'), findsOneWidget);
  });

  testWidgets('leaving and reopening Catalogue keeps data, not Chargement', (
    tester,
  ) async {
    final merchant = FakeMerchantApi(
      catalogBootstrapHandler: ({
        required merchantId,
        required branchId,
      }) async =>
          bootstrap,
      productsHandler: ({
        required merchantId,
        required branchId,
        String? categoryId,
      }) async =>
          const [product],
    );
    final container = containerFor(merchant);
    addTearDown(container.dispose);

    await pumpCatalog(tester, container);
    await tester.pumpAndSettle();
    expect(find.text('Thé à la menthe'), findsOneWidget);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: SizedBox.shrink()),
      ),
    );
    await tester.pump();
    expect(container.read(catalogControllerProvider).hasValue, isTrue);
    expect(container.read(catalogControllerProvider).isLoading, isFalse);

    await pumpCatalog(tester, container);
    await tester.pump();

    expect(find.text(AppStrings.loading), findsNothing);
    expect(find.text('Thé à la menthe'), findsOneWidget);
  });

  test('provider dispose during an in-flight request does not hang', () async {
    final started = Completer<void>();
    final hold = Completer<CatalogBootstrap>();
    final merchant = FakeMerchantApi(
      catalogBootstrapHandler: ({
        required merchantId,
        required branchId,
      }) {
        if (!started.isCompleted) started.complete();
        return hold.future;
      },
    );
    final container = containerFor(merchant);
    container.read(catalogControllerProvider);
    await started.future;
    expect(container.read(catalogControllerProvider).isLoading, isTrue);

    container.dispose();
  });

  test('access busy/generation pulses do not restart Catalogue', () async {
    var loads = 0;
    final access = _MutableAccess(mem, branchOne);
    final merchant = FakeMerchantApi(
      catalogBootstrapHandler: ({
        required merchantId,
        required branchId,
      }) async {
        loads += 1;
        return bootstrap;
      },
      productsHandler: ({
        required merchantId,
        required branchId,
        String? categoryId,
      }) async =>
          const [product],
    );
    final container = containerFor(
      merchant,
      access: () => access,
    );
    addTearDown(container.dispose);

    await container.read(catalogControllerProvider.future);
    expect(loads, 1);

    access.pulse();
    await Future<void>.delayed(Duration.zero);
    expect(loads, 1);
    expect(container.read(catalogControllerProvider).hasValue, isTrue);
  });
}

class _ReadySession extends SessionController {
  @override
  SessionState build() => const SessionState(
        phase: SessionPhase.ready,
        accountId: 'a-1',
      );
}

class _TrackingSession extends SessionController {
  var invalidations = 0;

  @override
  SessionState build() => const SessionState(
        phase: SessionPhase.ready,
        accountId: 'a-1',
      );

  @override
  Future<void> invalidateLocalSession() async {
    invalidations += 1;
    state = const SessionState(phase: SessionPhase.signedOut);
  }
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

class _MutableAccess extends AccessController {
  _MutableAccess(this.mem, this.branch);
  final MerchantMembership mem;
  final MerchantBranch branch;

  @override
  AccessState build() => AccessState(
        destination: AccessDestination.home,
        membership: mem,
        selectedBranch: branch,
      );

  void pulse() {
    state = AccessState(
      destination: AccessDestination.home,
      membership: mem,
      selectedBranch: branch,
      busy: true,
      requestGeneration: state.requestGeneration + 1,
    );
  }
}
