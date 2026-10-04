import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speedygo_merchant_app/app/router/app_router.dart';
import 'package:speedygo_merchant_app/core/navigation/app_routes.dart';
import 'package:speedygo_merchant_app/core/storage/session_store.dart';
import 'package:speedygo_merchant_app/features/access/data/models.dart';
import 'package:speedygo_merchant_app/features/auth/application/session_providers.dart';
import 'package:speedygo_merchant_app/features/auth/data/models.dart';
import 'package:speedygo_merchant_app/features/catalog/data/catalog_models.dart';
import 'package:speedygo_merchant_app/features/store/data/classification_models.dart';
import 'package:speedygo_merchant_app/features/support/data/support_models.dart';

import 'phase1_flow_test.dart';

void main() {
  group('selling unit', () {
    test('display label prefers server labelFr then allowlist', () {
      expect(sellingUnitDisplayLabel(null, null), isNull);
      expect(sellingUnitDisplayLabel('PLAT', null), 'Plat');
      expect(sellingUnitDisplayLabel('CUSTOM', '  Cornet  '), 'Cornet');
      expect(sellingUnitDisplayLabel('CUSTOM', null), isNull);
      expect(sellingUnitDisplayLabel('KG', null), isNull);
    });

    test('CUSTOM selection requires a non-empty labelFr for display', () {
      expect(
        const SellingUnitSelection(code: 'CUSTOM', labelFr: null).displayLabel,
        isNull,
      );
      expect(
        const SellingUnitSelection(
          code: 'CUSTOM',
          labelFr: 'Cornet',
        ).displayLabel,
        'Cornet',
      );
      expect(
        const SellingUnitSelection(code: 'PLAT').displayLabel,
        'Plat',
      );
    });
  });

  group('store category', () {
    testWidgets('single-select save assigns one vertical', (tester) async {
      final merchant = FakeMerchantApi(
        meHandler: () async => MerchantMe(
          merchantMembershipExists: true,
          memberships: [
            membership(branches: [branch('b1', name: 'Comptoir')]),
          ],
        ),
      );
      final store = MemorySessionStore()
        ..value = const TokenPair(
          accessToken: 'a',
          refreshToken: 'r-token-value',
          expiresIn: 900,
          tokenType: 'Bearer',
        );
      final container = testContainer(
        auth: FakeAuthApi(),
        merchant: merchant,
        store: store,
      );
      addTearDown(container.dispose);
      container.read(tokenCacheProvider).current = store.value;

      await pumpApp(tester, container);
      container.read(appRouterProvider).push(AppRoutes.storeCategory);
      for (var i = 0; i < 40; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      expect(find.byKey(const Key('store-category-screen')), findsOneWidget);
      expect(find.text('Restaurant'), findsWidgets);
      await tester.tap(find.text('Restaurant').first);
      await tester.pump();
      await tester.tap(find.byKey(const Key('store-category-save')));
      for (var i = 0; i < 40; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      expect(merchant.classificationPuts, ['v-restaurant']);
      expect(merchant.branchClassification?.slug, 'restaurant');
    });
  });

  group('support models', () {
    test('displayTitle prefers subject over publicReference', () {
      const withSubject = SupportTicketSummary(
        id: '1',
        publicReference: 'sgt_abc',
        status: SupportTicketStatus.open,
        orderId: null,
        createdAt: null,
        updatedAt: null,
        subject: 'Paiement COD',
        topicCode: 'PAYMENT_COD',
      );
      const legacy = SupportTicketSummary(
        id: '2',
        publicReference: 'sgt_legacy',
        status: SupportTicketStatus.open,
        orderId: null,
        createdAt: null,
        updatedAt: null,
      );
      expect(withSubject.displayTitle, 'Paiement COD');
      expect(legacy.displayTitle, 'sgt_legacy');
    });

    test('FAQ version parses as opaque string', () {
      final article = SupportFaqArticle.fromJson({
        'slug': 'hours',
        'titleFr': 'Horaires',
        'bodyFr': 'Une date à la fois.',
        'version': '2026-10-03',
      });
      expect(article.version, '2026-10-03');
    });
  });

  group('branch classification parse', () {
    test('accepts bare and wrapped payloads', () {
      final bare = BranchClassification.tryParse({
        'verticalId': 'v1',
        'slug': 'restaurant',
        'name': 'Restaurant',
        'iconKey': 'restaurant',
      });
      final wrapped = BranchClassification.tryParse({
        'classification': {
          'verticalId': 'v1',
          'slug': 'restaurant',
          'name': 'Restaurant',
          'iconKey': 'restaurant',
        },
      });
      expect(bare?.verticalId, 'v1');
      expect(wrapped?.verticalId, 'v1');
      expect(BranchClassification.tryParse(null), isNull);
    });
  });
}
