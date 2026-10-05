import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speedygo_merchant_app/app/theme/app_theme.dart';
import 'package:speedygo_merchant_app/core/constants/app_strings.dart';
import 'package:speedygo_merchant_app/core/money/money_format.dart';
import 'package:speedygo_merchant_app/core/storage/session_store.dart';
import 'package:speedygo_merchant_app/features/access/application/access_controller.dart';
import 'package:speedygo_merchant_app/features/access/data/models.dart';
import 'package:speedygo_merchant_app/features/auth/application/auth_infrastructure.dart';
import 'package:speedygo_merchant_app/features/auth/application/session_controller.dart';
import 'package:speedygo_merchant_app/features/auth/application/session_providers.dart';
import 'package:speedygo_merchant_app/features/auth/application/session_state.dart';
import 'package:speedygo_merchant_app/features/catalog/application/catalog_controller.dart';
import 'package:speedygo_merchant_app/features/catalog/data/catalog_models.dart';
import 'package:speedygo_merchant_app/features/reports/application/reports_controller.dart';
import 'package:speedygo_merchant_app/features/reports/data/reports_models.dart';
import 'package:speedygo_merchant_app/features/reports/presentation/reports_screen.dart';

import 'phase1_flow_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('majorInputToMinor parses DZD without float math', () {
    expect(MoneyFormat.majorInputToMinor('12'), 1200);
    expect(MoneyFormat.majorInputToMinor('12,5'), 1250);
    expect(MoneyFormat.majorInputToMinor('12.50'), 1250);
    expect(MoneyFormat.majorInputToMinor(''), isNull);
    expect(MoneyFormat.minorToMajorInput('1250'), '12,50');
  });

  test('catalog controller createProduct hits API', () async {
    var createdName = '';
    final merchant = _TrackingMerchant(
      onCreate: (name) => createdName = name,
    );
    final branch = MerchantBranch(
      id: 'b-1',
      name: 'Finjan',
      phone: '0550000000',
      addressText: 'Centre',
      latitude: 36.7,
      longitude: 3.0,
      operationalStatus: 'ACTIVE',
    );
    final mem = membership(branches: [branch]).copyWithName('Finjan');
    final container = ProviderContainer(
      overrides: [
        merchantApiProvider.overrideWithValue(merchant),
        sessionStoreProvider.overrideWithValue(MemorySessionStore()),
        contextStoreProvider.overrideWithValue(MemoryContextStore()),
        sessionControllerProvider.overrideWith(() => _ReadySession()),
        accessControllerProvider.overrideWith(() => _ReadyAccess(mem, branch)),
      ],
    );
    addTearDown(container.dispose);
    await container.read(catalogControllerProvider.future);
    final created = await container.read(catalogControllerProvider.notifier).createProduct(
          categoryId: 'c-1',
          name: 'Thé',
          priceMinor: 15000,
          available: true,
        );
    expect(created.name, 'Thé');
    expect(createdName, 'Thé');
    expect(created.priceMinor, '15000');
  });

  testWidgets('reports shows finance rows without technical copy', (tester) async {
    final merchant = FakeMerchantApi();
    final branch = MerchantBranch(
      id: 'b-1',
      name: 'Finjan',
      phone: '0550000000',
      addressText: 'Centre',
      latitude: 36.7,
      longitude: 3.0,
      operationalStatus: 'ACTIVE',
    );
    final mem = membership(branches: [branch]).copyWithName('Finjan');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          merchantApiProvider.overrideWithValue(merchant),
          sessionStoreProvider.overrideWithValue(MemorySessionStore()),
          contextStoreProvider.overrideWithValue(MemoryContextStore()),
          sessionControllerProvider.overrideWith(() => _ReadySession()),
          accessControllerProvider.overrideWith(() => _ReadyAccess(mem, branch)),
          reportsControllerProvider.overrideWith(() => _SeedReports()),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const ReportsScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();

    expect(find.text('Ventes brutes'), findsOneWidget);
    expect(find.text('Net commerçant'), findsOneWidget);
    // The period filter is live (backend sales contract), not a placeholder.
    expect(find.text('Filtre de période indisponible.'), findsNothing);
    expect(find.text(AppStrings.reportsPeriodToday), findsOneWidget);
    expect(find.textContaining('ne sont pas exposés'), findsNothing);
    expect(find.textContaining('contrat de rapport'), findsNothing);
  });
}

class _TrackingMerchant extends FakeMerchantApi {
  _TrackingMerchant({required this.onCreate});
  final void Function(String name) onCreate;

  @override
  Future<CatalogBootstrap> getCatalogBootstrap({
    required String merchantId,
    required String branchId,
  }) async =>
      const CatalogBootstrap(
        branchId: 'b-1',
        stats: CatalogStats(
          categoryCount: 1,
          productCount: 0,
          availableProductCount: 0,
        ),
        categories: [
          CatalogCategory(
            id: 'c-1',
            branchId: 'b-1',
            name: 'Boissons',
            sortOrder: 0,
            active: true,
          ),
        ],
      );

  @override
  Future<CatalogProduct> createProduct({
    required String merchantId,
    required String branchId,
    required String categoryId,
    required String name,
    String? description,
    required int priceMinor,
    bool available = true,
    SellingUnitSelection? sellingUnit,
  }) async {
    onCreate(name);
    return CatalogProduct(
      id: 'p-new',
      branchId: branchId,
      categoryId: categoryId,
      name: name,
      description: description,
      priceMinor: '$priceMinor',
      available: available,
      sellingUnitCode: sellingUnit?.code,
      sellingUnitLabelFr: sellingUnit?.labelFr,
    );
  }
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

class _SeedReports extends ReportsController {
  @override
  Future<ReportsState> build() async {
    return const ReportsState(
      ratings: MerchantRatingSummary(
        merchantId: 'm-1',
        count: 0,
        average: null,
      ),
      settlements: [],
      settlementsForbidden: false,
    );
  }
}
