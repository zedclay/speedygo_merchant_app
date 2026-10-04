import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:speedygo_merchant_app/app/theme/app_theme.dart';
import 'package:speedygo_merchant_app/core/constants/app_strings.dart';
import 'package:speedygo_merchant_app/core/errors/app_exception.dart';
import 'package:speedygo_merchant_app/core/storage/session_store.dart';
import 'package:speedygo_merchant_app/core/utils/uuid_v4.dart';
import 'package:speedygo_merchant_app/features/access/application/access_controller.dart';
import 'package:speedygo_merchant_app/features/access/data/evidence_file_picker.dart';
import 'package:speedygo_merchant_app/features/access/data/merchant_api.dart';
import 'package:speedygo_merchant_app/features/access/data/models.dart';
import 'package:speedygo_merchant_app/features/auth/application/auth_infrastructure.dart';
import 'package:speedygo_merchant_app/features/auth/application/session_controller.dart';
import 'package:speedygo_merchant_app/features/auth/application/session_providers.dart';
import 'package:speedygo_merchant_app/features/auth/application/session_state.dart';
import 'package:speedygo_merchant_app/features/catalog/data/catalog_models.dart';
import 'package:speedygo_merchant_app/features/catalog/presentation/product_duplicate_screen.dart';
import 'package:speedygo_merchant_app/features/store/application/opening_hours_format.dart';
import 'package:speedygo_merchant_app/features/store/data/store_models.dart';
import 'package:speedygo_merchant_app/features/store/presentation/merchant_branch_cover_thumb.dart';
import 'package:speedygo_merchant_app/features/store/presentation/opening_hours_exceptions_screen.dart';
import 'package:speedygo_merchant_app/features/store/presentation/store_cover_screen.dart';

import '../helpers/path_provider_fixture.dart';
import 'phase1_flow_test.dart';

final _png = AcceptanceFixtureEvidenceFilePicker.fixturePngBytes;

const _weekly = OpeningHoursSchedule(
  branchId: 'b-1',
  timezone: 'Africa/Algiers',
  hoursConfigured: true,
  version: 1,
  days: [
    OpeningDay(
      dayOfWeek: 1,
      intervals: [OpeningInterval(opens: '09:00', closes: '22:00')],
    ),
  ],
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  installPathProviderFixture();

  final branch = MerchantBranch(
    id: 'b-1',
    name: 'Fixture Café',
    phone: '0550000000',
    addressText: '12 Rue Test',
    latitude: 36.75,
    longitude: 3.05,
    operationalStatus: 'ACTIVE',
  );

  ProviderContainer containerFor(FakeMerchantApi api, {String role = 'OWNER'}) {
    final mem = membership(
      branches: [branch],
      role: role,
    ).copyWithName('Fixture Café');
    return ProviderContainer(
      overrides: [
        merchantApiProvider.overrideWithValue(api),
        sessionStoreProvider.overrideWithValue(MemorySessionStore()),
        contextStoreProvider.overrideWithValue(MemoryContextStore()),
        sessionControllerProvider.overrideWith(() => _ReadySession()),
        accessControllerProvider.overrideWith(() => _ReadyAccess(mem, branch)),
      ],
    );
  }

  void tallSurface(WidgetTester tester) {
    tester.view.physicalSize = const Size(1200, 3200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> pumpBare(
    WidgetTester tester,
    ProviderContainer container,
    Widget child,
  ) async {
    tallSurface(tester);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.light(locale: const Locale('fr')),
          home: child,
        ),
      ),
    );
    await settle(tester);
  }

  Future<void> pumpRouter(
    WidgetTester tester,
    ProviderContainer container,
    GoRouter router,
  ) async {
    tallSurface(tester);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          theme: AppTheme.light(locale: const Locale('fr')),
          routerConfig: router,
        ),
      ),
    );
    await settle(tester);
  }

  GoRouter hubRouter(String path, Widget Function(GoRouterState) builder) {
    return GoRouter(
      initialLocation: path,
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) =>
              const Scaffold(body: Text('hub', key: Key('test-hub'))),
          routes: [
            GoRoute(
              path: path.substring(1),
              builder: (_, state) => builder(state),
            ),
          ],
        ),
      ],
    );
  }

  group('store logo', () {
    testWidgets('bound logo renders from server bytes with remove enabled', (
      tester,
    ) async {
      final api = FakeMerchantApi()..logoBytes = _png;
      final container = containerFor(api);
      addTearDown(container.dispose);
      await pumpBare(tester, container, const StoreCoverScreen());

      expect(find.byKey(const Key('store-logo-image')), findsOneWidget);
      expect(find.text(AppStrings.storeLogoEdit), findsOneWidget);
      final remove = tester.widget<ButtonStyleButton>(
        find.byKey(const Key('store-logo-remove')),
      );
      expect(remove.onPressed, isNotNull);
      final avatar = tester.widget<CircleAvatar>(
        find.byKey(const Key('store-preview-avatar')),
      );
      expect(avatar.foregroundImage, isA<MemoryImage>());
    });

    testWidgets('no logo shows fallback and disables remove', (tester) async {
      final api = FakeMerchantApi();
      final container = containerFor(api);
      addTearDown(container.dispose);
      await pumpBare(tester, container, const StoreCoverScreen());

      expect(find.byKey(const Key('store-logo-empty')), findsOneWidget);
      expect(find.text(AppStrings.storeLogoAdd), findsOneWidget);
      final remove = tester.widget<ButtonStyleButton>(
        find.byKey(const Key('store-logo-remove')),
      );
      expect(remove.onPressed, isNull);
      final save = tester.widget<FilledButton>(
        find.byKey(const Key('store-cover-save')),
      );
      expect(save.onPressed, isNull);
    });

    testWidgets('pick then save uploads, binds and pops', (tester) async {
      final api = FakeMerchantApi();
      final container = containerFor(api);
      addTearDown(container.dispose);
      await pumpRouter(
        tester,
        container,
        hubRouter('/cover', (_) => const StoreCoverScreen()),
      );

      final state = tester.state(find.byType(StoreCoverScreen));
      (state as dynamic).debugSetLogoBytes(bytes: _png);
      await tester.pump();
      expect(find.byKey(const Key('store-logo-pending')), findsOneWidget);

      await tester.tap(find.byKey(const Key('store-cover-save')));
      await settle(tester);

      expect(api.logoCalls, ['upload', 'bind']);
      expect(api.logoBytes, _png);
      expect(find.byKey(const Key('test-hub')), findsOneWidget);
    });

    testWidgets('bind failure keeps the pending logo and stays', (
      tester,
    ) async {
      final api = FakeMerchantApi()
        ..logoBindError = const ApiException('boom', statusCode: 500);
      final container = containerFor(api);
      addTearDown(container.dispose);
      await pumpBare(tester, container, const StoreCoverScreen());

      final state = tester.state(find.byType(StoreCoverScreen));
      (state as dynamic).debugSetLogoBytes(bytes: _png);
      await tester.pump();
      await tester.tap(find.byKey(const Key('store-cover-save')));
      await settle(tester);

      expect(find.text(AppStrings.storeLogoBindPartial), findsOneWidget);
      expect(find.byKey(const Key('store-logo-pending')), findsOneWidget);
      expect(api.logoBytes, isNull);
    });

    testWidgets('logo saved but cover upload fails reports partial save', (
      tester,
    ) async {
      final api = _FailingCoverApi();
      final container = containerFor(api);
      addTearDown(container.dispose);
      await pumpBare(tester, container, const StoreCoverScreen());

      final state = tester.state(find.byType(StoreCoverScreen));
      (state as dynamic).debugSetLogoBytes(bytes: _png);
      (state as dynamic).debugSetCoverBytes(bytes: _png);
      await tester.pump();
      await tester.tap(find.byKey(const Key('store-cover-save')));
      await settle(tester);

      expect(api.logoBytes, _png);
      expect(find.text(AppStrings.storeMediaPartialSaved), findsOneWidget);
      expect(find.byKey(const Key('store-logo-pending')), findsNothing);
    });

    testWidgets('remove deletes on the server and restores fallback', (
      tester,
    ) async {
      final api = FakeMerchantApi()..logoBytes = _png;
      final container = containerFor(api);
      addTearDown(container.dispose);
      await pumpBare(tester, container, const StoreCoverScreen());

      await tester.tap(find.byKey(const Key('store-logo-remove')));
      await settle(tester);

      expect(api.logoCalls, ['delete']);
      expect(find.byKey(const Key('store-logo-empty')), findsOneWidget);
      expect(find.text(AppStrings.storeLogoRemoved), findsOneWidget);
    });

    testWidgets('STAFF sees the logo but no mutation controls', (
      tester,
    ) async {
      final api = FakeMerchantApi()..logoBytes = _png;
      final container = containerFor(api, role: 'STAFF');
      addTearDown(container.dispose);
      await pumpBare(tester, container, const StoreCoverScreen());

      expect(find.byKey(const Key('store-logo-image')), findsOneWidget);
      expect(find.byKey(const Key('store-logo-pick')), findsNothing);
      expect(find.byKey(const Key('store-logo-remove')), findsNothing);
      expect(find.byKey(const Key('store-cover-save')), findsNothing);
    });

    testWidgets('logo thumb shows server bytes or the storefront fallback', (
      tester,
    ) async {
      final api = FakeMerchantApi()..logoBytes = _png;
      final container = containerFor(api);
      addTearDown(container.dispose);
      await pumpBare(
        tester,
        container,
        const Scaffold(body: MerchantBranchLogoThumb()),
      );
      expect(find.byType(Image), findsOneWidget);

      api.logoBytes = null;
      final empty = containerFor(api);
      addTearDown(empty.dispose);
      await pumpBare(
        tester,
        empty,
        const Scaffold(body: MerchantBranchLogoThumb(key: Key('second'))),
      );
      expect(find.byType(Image), findsNothing);
      expect(find.byIcon(Icons.storefront), findsOneWidget);
    });
  });

  group('exceptional hours', () {
    FakeMerchantApi hoursApi() =>
        FakeMerchantApi()
          ..openingHoursHandler =
              ({required merchantId, required branchId}) async => _weekly;

    OpeningHoursException exception(
      String date, {
      bool closed = false,
      int version = 1,
      String label = 'Jour férié',
    }) => OpeningHoursException(
      date: date,
      closed: closed,
      label: label,
      customerMessage: null,
      intervals: closed
          ? const []
          : const [OpeningInterval(opens: '10:00', closes: '15:00')],
      version: version,
      updatedAt: null,
    );

    testWidgets('lists upcoming exceptions with status and hours', (
      tester,
    ) async {
      final api = hoursApi()
        ..hoursExceptions.addAll([
          exception('2026-10-05', closed: true, label: 'Aïd'),
          exception('2026-10-09', label: 'Vendredi spécial'),
        ]);
      final container = containerFor(api);
      addTearDown(container.dispose);
      await pumpBare(tester, container, const OpeningHoursExceptionsScreen());

      expect(find.byKey(const Key('hours-exceptions-banner')), findsOneWidget);
      expect(
        find.byKey(const Key('hours-exception-card-2026-10-05')),
        findsOneWidget,
      );
      expect(find.text('Aïd'), findsOneWidget);
      expect(find.text('Lundi 5 Octobre 2026'), findsOneWidget);
      expect(
        find.byKey(const Key('hours-exception-hours-2026-10-09')),
        findsOneWidget,
      );
      expect(find.text('10:00 - 15:00'), findsOneWidget);
    });

    testWidgets('saving a closed date confirms only after the server', (
      tester,
    ) async {
      final api = hoursApi();
      final container = containerFor(api);
      addTearDown(container.dispose);
      await pumpBare(tester, container, const OpeningHoursExceptionsScreen());
      expect(find.byKey(const Key('hours-exceptions-empty')), findsOneWidget);

      final state = tester.state(find.byType(OpeningHoursExceptionsScreen));
      (state as dynamic).debugSetDate('2026-10-05');
      await tester.pump();
      await tester.ensureVisible(
        find.byKey(const Key('hours-exception-status-closed')),
      );
      await tester.tap(find.byKey(const Key('hours-exception-status-closed')));
      await tester.pump();
      expect(find.byKey(const Key('hours-exception-opens-0')), findsNothing);
      await tester.enterText(
        find.byKey(const Key('hours-exception-label')),
        'Fête',
      );
      await tester.tap(find.byKey(const Key('hours-exception-save')));
      await settle(tester);

      expect(api.exceptionCalls, contains('put:2026-10-05:0'));
      expect(api.hoursExceptions.single.closed, isTrue);
      expect(
        find.byKey(const Key('hours-exception-card-2026-10-05')),
        findsOneWidget,
      );
      expect(find.text(AppStrings.hoursExceptionsSaved), findsOneWidget);
    });

    testWidgets('client validation blocks missing date and overnight range', (
      tester,
    ) async {
      final api = hoursApi();
      final container = containerFor(api);
      addTearDown(container.dispose);
      await pumpBare(tester, container, const OpeningHoursExceptionsScreen());

      await tester.tap(find.byKey(const Key('hours-exception-save')));
      await tester.pump();
      expect(find.text(AppStrings.hoursExceptionsDateRequired), findsOneWidget);

      final state = tester.state(find.byType(OpeningHoursExceptionsScreen));
      (state as dynamic).debugSetDate('2026-10-06');
      (state as dynamic).debugSetIntervals(const [
        OpeningInterval(opens: '20:00', closes: '02:00'),
      ]);
      await tester.enterText(
        find.byKey(const Key('hours-exception-label')),
        'Soirée',
      );
      await tester.tap(find.byKey(const Key('hours-exception-save')));
      await tester.pump();
      expect(
        find.byKey(const Key('hours-exception-error')),
        findsOneWidget,
      );
      expect(
        tester
            .widget<Text>(find.byKey(const Key('hours-exception-error')))
            .data,
        AppStrings.hoursExceptionsSameDay,
      );
      expect(api.exceptionCalls.where((c) => c.startsWith('put')), isEmpty);
    });

    testWidgets('version conflict reloads and keeps the draft', (
      tester,
    ) async {
      final api = hoursApi()..hoursExceptions.add(exception('2026-10-07'));
      final container = containerFor(api);
      addTearDown(container.dispose);
      await pumpBare(tester, container, const OpeningHoursExceptionsScreen());

      await tester.tap(find.byKey(const Key('hours-exception-card-2026-10-07')));
      await tester.pump();
      expect(find.text(AppStrings.hoursExceptionsEdit), findsOneWidget);

      api.hoursExceptions[0] = exception(
        '2026-10-07',
        version: 2,
        label: 'Changé ailleurs',
      );
      await tester.enterText(
        find.byKey(const Key('hours-exception-label')),
        'Mon brouillon',
      );
      await tester.tap(find.byKey(const Key('hours-exception-save')));
      await settle(tester);

      expect(api.exceptionCalls, contains('put:2026-10-07:1'));
      expect(api.exceptionCalls.where((c) => c == 'list').length, 2);
      expect(find.text(AppStrings.hoursExceptionsConflict), findsOneWidget);
      expect(find.text('Mon brouillon'), findsOneWidget);
      expect(find.text('Changé ailleurs'), findsOneWidget);
      expect(api.hoursExceptions.single.label, 'Changé ailleurs');
    });

    testWidgets('server failure keeps the draft and adds nothing', (
      tester,
    ) async {
      final api = hoursApi()
        ..putExceptionError = const ApiException('down', statusCode: 500);
      final container = containerFor(api);
      addTearDown(container.dispose);
      await pumpBare(tester, container, const OpeningHoursExceptionsScreen());

      final state = tester.state(find.byType(OpeningHoursExceptionsScreen));
      (state as dynamic).debugSetDate('2026-10-08');
      await tester.enterText(
        find.byKey(const Key('hours-exception-label')),
        'Inventaire',
      );
      await tester.tap(find.byKey(const Key('hours-exception-save')));
      await settle(tester);

      expect(find.text(AppStrings.hoursExceptionsSaveError), findsOneWidget);
      expect(find.text('Inventaire'), findsOneWidget);
      expect(find.byKey(const Key('hours-exceptions-empty')), findsOneWidget);
      expect(find.text(AppStrings.hoursExceptionsSaved), findsNothing);
    });

    testWidgets('delete asks for confirmation and removes the card', (
      tester,
    ) async {
      final api = hoursApi()..hoursExceptions.add(exception('2026-10-07'));
      final container = containerFor(api);
      addTearDown(container.dispose);
      await pumpBare(tester, container, const OpeningHoursExceptionsScreen());

      await tester.tap(
        find.byKey(const Key('hours-exception-delete-2026-10-07')),
      );
      await settle(tester);
      expect(
        find.byKey(const Key('hours-exception-delete-dialog')),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const Key('hours-exception-delete-confirm')));
      await settle(tester);

      expect(api.exceptionCalls, contains('delete:2026-10-07:1'));
      expect(
        find.byKey(const Key('hours-exception-card-2026-10-07')),
        findsNothing,
      );
      expect(find.text(AppStrings.hoursExceptionsDeleted), findsOneWidget);
    });

    testWidgets('STAFF is read-only', (tester) async {
      final api = hoursApi()..hoursExceptions.add(exception('2026-10-07'));
      final container = containerFor(api, role: 'STAFF');
      addTearDown(container.dispose);
      await pumpBare(tester, container, const OpeningHoursExceptionsScreen());

      expect(
        find.byKey(const Key('hours-exception-card-2026-10-07')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('hours-exception-readonly')), findsOneWidget);
      expect(find.byKey(const Key('hours-exception-form')), findsNothing);
      expect(find.byKey(const Key('hours-exception-save')), findsNothing);
      expect(
        find.byKey(const Key('hours-exception-delete-2026-10-07')),
        findsNothing,
      );
    });

    testWidgets('weekly hours not configured disables saving', (
      tester,
    ) async {
      final api = FakeMerchantApi();
      final container = containerFor(api);
      addTearDown(container.dispose);
      await pumpBare(tester, container, const OpeningHoursExceptionsScreen());

      expect(
        find.byKey(const Key('hours-exception-weekly-required')),
        findsOneWidget,
      );
      final save = tester.widget<FilledButton>(
        find.byKey(const Key('hours-exception-save')),
      );
      expect(save.onPressed, isNull);
    });

    test('exception interval rules mirror the backend', () {
      List<OpeningInterval> iv(List<List<String>> spans) => [
        for (final s in spans) OpeningInterval(opens: s[0], closes: s[1]),
      ];
      expect(validateExceptionIntervals(const []), ExceptionIntervalIssue.empty);
      expect(
        validateExceptionIntervals(
          iv([
            ['09:00', '13:00'],
          ]),
        ),
        isNull,
      );
      expect(
        validateExceptionIntervals(
          iv([
            ['18:00', '00:00'],
          ]),
        ),
        isNull,
      );
      expect(
        validateExceptionIntervals(
          iv([
            ['00:00', '00:00'],
          ]),
        ),
        isNull,
      );
      expect(
        validateExceptionIntervals(
          iv([
            ['20:00', '02:00'],
          ]),
        ),
        ExceptionIntervalIssue.overnight,
      );
      expect(
        validateExceptionIntervals(
          iv([
            ['10:00', '10:00'],
          ]),
        ),
        ExceptionIntervalIssue.zeroLength,
      );
      expect(
        validateExceptionIntervals(
          iv([
            ['09:00', '13:00'],
            ['12:00', '15:00'],
          ]),
        ),
        ExceptionIntervalIssue.overlap,
      );
      expect(
        validateExceptionIntervals(
          iv([
            ['09:00', '12:00'],
            ['12:00', '15:00'],
          ]),
        ),
        isNull,
      );
      expect(
        validateExceptionIntervals(
          iv([
            ['08:00', '09:00'],
            ['10:00', '11:00'],
            ['12:00', '13:00'],
            ['14:00', '15:00'],
          ]),
        ),
        ExceptionIntervalIssue.tooMany,
      );
      expect(formatCivilDateFr('2026-12-31'), 'Jeudi 31 Décembre 2026');
      expect(parseCivilDate('2026-02-30'), isNull);
    });
  });

  group('product duplication', () {
    const source = CatalogProduct(
      id: 'p-1',
      branchId: 'b-1',
      categoryId: 'c-1',
      name: 'Couscous royal',
      description: 'Semoule',
      priceMinor: '150000',
      available: true,
      hasImage: true,
    );
    const copy = CatalogProduct(
      id: 'p-copy',
      branchId: 'b-1',
      categoryId: 'c-1',
      name: 'Copie de Couscous royal',
      description: 'Semoule',
      priceMinor: '150000',
      available: false,
      hasImage: true,
    );

    FakeMerchantApi catalogApi() {
      final api = FakeMerchantApi(
        catalogBootstrapHandler: ({required merchantId, required branchId}) async =>
            CatalogBootstrap(
              branchId: branchId,
              stats: const CatalogStats(
                categoryCount: 1,
                productCount: 1,
                availableProductCount: 1,
              ),
              categories: const [
                CatalogCategory(
                  id: 'c-1',
                  branchId: 'b-1',
                  name: 'Plats',
                  sortOrder: 0,
                  active: true,
                ),
              ],
            ),
        productsHandler:
            ({required merchantId, required branchId, categoryId}) async => [
              source,
            ],
      );
      return api;
    }

    GoRouter duplicateRouter() => GoRouter(
      initialLocation: '/app/catalog/products/p-1/duplicate',
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) =>
              const Scaffold(body: Text('hub', key: Key('test-hub'))),
        ),
        GoRoute(
          path: '/app/catalog/products/:productId/duplicate',
          builder: (_, state) => ProductDuplicateScreen(
            productId: state.pathParameters['productId']!,
          ),
        ),
        GoRoute(
          path: '/app/catalog/products/:productId',
          builder: (_, state) => Scaffold(
            body: Text(
              'editor:${state.pathParameters['productId']}',
              key: const Key('test-editor'),
            ),
          ),
        ),
      ],
    );

    testWidgets('prefills the French copy name and the checklist', (
      tester,
    ) async {
      final api = catalogApi();
      final container = containerFor(api);
      addTearDown(container.dispose);
      await pumpRouter(tester, container, duplicateRouter());

      expect(find.byKey(const Key('duplicate-screen')), findsOneWidget);
      final field = tester.widget<TextField>(
        find.byKey(const Key('duplicate-name')),
      );
      expect(field.controller!.text, 'Copie de Couscous royal');
      expect(find.text('Plats'), findsOneWidget);
      expect(find.text(AppStrings.duplicateImage), findsOneWidget);
      expect(find.text(AppStrings.duplicateUnavailableInfo), findsOneWidget);
    });

    testWidgets('creates one copy then opens its editor', (tester) async {
      final api = catalogApi()
        ..duplicateHandler =
            ({
              required merchantId,
              required productId,
              required requestId,
              name,
            }) async => const ProductDuplicateResult(
              product: copy,
              replayed: false,
              optionGroupCount: 2,
              optionCount: 5,
              imageCopied: true,
            );
      final container = containerFor(api);
      addTearDown(container.dispose);
      await pumpRouter(tester, container, duplicateRouter());

      await tester.enterText(
        find.byKey(const Key('duplicate-name')),
        'Couscous du vendredi',
      );
      await tester.tap(find.byKey(const Key('duplicate-create')));
      await settle(tester);

      expect(api.duplicateRequestIds, hasLength(1));
      expect(
        RegExp(
          r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
        ).hasMatch(api.duplicateRequestIds.single),
        isTrue,
      );
      expect(find.text('editor:p-copy'), findsOneWidget);
      expect(find.text(AppStrings.duplicateCreated), findsOneWidget);
    });

    testWidgets('repeated taps while running send a single request', (
      tester,
    ) async {
      final gate = Completer<ProductDuplicateResult>();
      final api = catalogApi()
        ..duplicateHandler =
            ({
              required merchantId,
              required productId,
              required requestId,
              name,
            }) => gate.future;
      final container = containerFor(api);
      addTearDown(container.dispose);
      await pumpRouter(tester, container, duplicateRouter());

      await tester.tap(find.byKey(const Key('duplicate-create')));
      await tester.pump();
      await tester.tap(
        find.byKey(const Key('duplicate-create')),
        warnIfMissed: false,
      );
      await tester.pump();
      expect(api.duplicateRequestIds, hasLength(1));
      expect(find.text(AppStrings.duplicateCreating), findsOneWidget);

      gate.complete(
        const ProductDuplicateResult(
          product: copy,
          replayed: false,
          optionGroupCount: 0,
          optionCount: 0,
          imageCopied: true,
        ),
      );
      await settle(tester);
      expect(find.text('editor:p-copy'), findsOneWidget);
    });

    testWidgets('retry after a network error reuses the request id', (
      tester,
    ) async {
      var attempt = 0;
      final api = catalogApi()
        ..duplicateHandler =
            ({
              required merchantId,
              required productId,
              required requestId,
              name,
            }) async {
              attempt++;
              if (attempt == 1) {
                throw const NetworkException('offline');
              }
              return const ProductDuplicateResult(
                product: copy,
                replayed: true,
                optionGroupCount: 0,
                optionCount: 0,
                imageCopied: true,
              );
            };
      final container = containerFor(api);
      addTearDown(container.dispose);
      await pumpRouter(tester, container, duplicateRouter());

      await tester.tap(find.byKey(const Key('duplicate-create')));
      await settle(tester);
      expect(find.text(AppStrings.duplicateNetworkError), findsOneWidget);
      expect(find.byKey(const Key('duplicate-screen')), findsOneWidget);

      await tester.tap(find.byKey(const Key('duplicate-create')));
      await settle(tester);
      expect(api.duplicateRequestIds, hasLength(2));
      expect(api.duplicateRequestIds.toSet(), hasLength(1));
      expect(find.text('editor:p-copy'), findsOneWidget);
      expect(find.text(AppStrings.duplicateReplayed), findsOneWidget);
    });

    testWidgets('server errors are shown without navigating', (tester) async {
      Object failure = const ApiException(
        'conflict',
        code: 'CATALOG_DUPLICATE_REQUEST_CONFLICT',
        statusCode: 409,
      );
      final api = catalogApi()
        ..duplicateHandler =
            ({
              required merchantId,
              required productId,
              required requestId,
              name,
            }) async => throw failure;
      final container = containerFor(api);
      addTearDown(container.dispose);
      await pumpRouter(tester, container, duplicateRouter());

      await tester.tap(find.byKey(const Key('duplicate-create')));
      await settle(tester);
      expect(find.text(AppStrings.duplicateConflict), findsOneWidget);

      failure = const ApiException(
        'forbidden',
        code: 'MERCHANT_ROLE_FORBIDDEN',
        statusCode: 403,
      );
      await tester.tap(find.byKey(const Key('duplicate-create')));
      await settle(tester);
      expect(find.text(AppStrings.catalogStaffReadOnly), findsOneWidget);

      failure = const ApiException(
        'gone',
        code: 'CATALOG_PRODUCT_NOT_FOUND',
        statusCode: 404,
      );
      await tester.tap(find.byKey(const Key('duplicate-create')));
      await settle(tester);
      expect(find.text(AppStrings.duplicateNotFound), findsOneWidget);
      expect(find.byKey(const Key('test-editor')), findsNothing);
    });

    testWidgets('empty name is rejected before any request', (tester) async {
      final api = catalogApi();
      final container = containerFor(api);
      addTearDown(container.dispose);
      await pumpRouter(tester, container, duplicateRouter());

      await tester.tap(find.byKey(const Key('duplicate-name-clear')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('duplicate-create')));
      await tester.pump();
      expect(find.text(AppStrings.duplicateNameRequired), findsOneWidget);
      expect(api.duplicateRequestIds, isEmpty);
    });

    testWidgets('STAFF cannot duplicate', (tester) async {
      final api = catalogApi();
      final container = containerFor(api, role: 'STAFF');
      addTearDown(container.dispose);
      await pumpRouter(tester, container, duplicateRouter());

      expect(find.byKey(const Key('duplicate-forbidden')), findsOneWidget);
      expect(find.byKey(const Key('duplicate-create')), findsNothing);
    });

    test('uuidV4 yields distinct RFC 4122 v4 ids', () {
      final ids = {for (var i = 0; i < 200; i++) uuidV4()};
      expect(ids, hasLength(200));
      final pattern = RegExp(
        r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
      );
      expect(ids.every(pattern.hasMatch), isTrue);
    });
  });
}

class _FailingCoverApi extends FakeMerchantApi {
  @override
  Future<EvidenceUploadResult> uploadBranchCoverContent({
    required String merchantId,
    required String branchId,
    required String filename,
    required String contentType,
    required Uint8List bytes,
  }) async {
    throw const ApiException('down', statusCode: 500);
  }
}

class _ReadySession extends SessionController {
  @override
  SessionState build() =>
      const SessionState(phase: SessionPhase.ready, accountId: 'a-fixture');
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

  @override
  Future<void> selectBranch(MerchantBranch next) async {}

  @override
  Future<void> refreshInPlace() async {}
}
