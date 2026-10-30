import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speedygo_merchant_app/core/constants/app_strings.dart';
import 'package:speedygo_merchant_app/core/storage/session_store.dart';
import 'package:speedygo_merchant_app/features/access/application/access_controller.dart';
import 'package:speedygo_merchant_app/features/access/data/geo_models.dart';
import 'package:speedygo_merchant_app/features/access/data/models.dart';
import 'package:speedygo_merchant_app/features/access/presentation/access_screens.dart';
import 'package:speedygo_merchant_app/features/auth/application/session_controller.dart';
import 'package:speedygo_merchant_app/features/auth/application/session_providers.dart';
import 'package:speedygo_merchant_app/features/auth/data/models.dart';
import 'package:speedygo_merchant_app/features/catalog/data/catalog_models.dart';
import 'package:speedygo_merchant_app/features/orders/data/order_models.dart';
import 'package:speedygo_merchant_app/features/orders/presentation/order_detail_screen.dart';
import 'package:speedygo_merchant_app/features/store/application/opening_hours_format.dart';
import 'package:speedygo_merchant_app/l10n/app_localizations.dart';

import 'phase1_flow_test.dart';

const _alger = AlgeriaWilaya(code: '16', nameFr: 'Alger', nameAr: 'الجزائر');
const _oran = AlgeriaWilaya(code: '31', nameFr: 'Oran', nameAr: 'وهران');
const _algerCentre = AlgeriaCommune(
  id: 556,
  wilayaCode: '16',
  nameFr: 'Alger Centre',
  nameAr: 'الجزائر الوسطى',
);
const _oranCommune = AlgeriaCommune(
  id: 1101,
  wilayaCode: '31',
  nameFr: 'Oran',
  nameAr: 'وهران',
);

FakeMerchantApi _geoApi() {
  return FakeMerchantApi(
    meHandler: () async => MerchantMe(
      merchantMembershipExists: true,
      memberships: [membership(branches: const [])],
    ),
  )
    ..wilayaCatalog = const [_alger, _oran]
    ..communesByWilaya = const {
      '16': [_algerCentre],
      '31': [_oranCommune],
    };
}

Future<ProviderContainer> _signedIn(FakeMerchantApi merchant) async {
  final store = MemorySessionStore()
    ..value = const TokenPair(
      accessToken: 'a',
      refreshToken: 'r',
      expiresIn: 900,
      tokenType: 'Bearer',
    );
  final container = testContainer(
    auth: FakeAuthApi(),
    merchant: merchant,
    store: store,
  );
  container.read(tokenCacheProvider).current = store.value;
  await restoreAndResolve(container);
  return container;
}

MerchantOrderDetail _order({required MerchantOrderAddress address}) {
  return MerchantOrderDetail(
    id: 'o-addr',
    publicReference: 'sgo_o-addr',
    status: 'CONFIRMED',
    fulfillmentStatus: 'ACCEPTED',
    merchantBranchId: 'b1',
    createdAt: '2026-01-01T10:00:00Z',
    customerFullName: 'Client Test',
    payment: const MerchantOrderPayment(method: 'COD', status: 'PENDING'),
    financial: const MerchantOrderFinancial(
      currency: 'DZD',
      grossMerchandiseSubtotalMinor: '1200',
      merchantDiscountMinor: '0',
      merchantCommissionRateBps: 700,
      merchantCommissionAmountMinor: '84',
      merchantNetAmountMinor: '1116',
      deliveryFeeMinor: '500',
    ),
    items: const [
      MerchantOrderItem(
        id: 'item-1',
        productId: 'p-1',
        productNameSnapshot: 'Café',
        quantity: 1,
        unitPriceMinor: '1200',
        lineTotalMinor: '1200',
        options: [],
      ),
    ],
    deliveryAddress: address,
    statusHistory: const [],
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('D2 first-branch geography', () {
    Future<void> pumpNeedBranch(
      WidgetTester tester,
      ProviderContainer container,
    ) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: NeedBranchScreen()),
        ),
      );
      await tester.pump();
      await tester.pumpAndSettle();
    }

    Future<void> fillIdentity(WidgetTester tester) async {
      await tester.enterText(find.byKey(const Key('branch-name')), 'Oran Café');
      await tester.enterText(
        find.byKey(const Key('branch-phone')),
        '0550111222',
      );
      await tester.enterText(
        find.byKey(const Key('branch-address')),
        'Rue Oran',
      );
    }

    testWidgets('submits selected Oran geography, never Sidi Bel Abbès', (
      tester,
    ) async {
      final merchant = _geoApi();
      final container = await _signedIn(merchant);
      addTearDown(container.dispose);
      expect(
        container.read(accessControllerProvider).destination,
        AccessDestination.needBranch,
      );

      await pumpNeedBranch(tester, container);
      await fillIdentity(tester);
      tester
          .state<NeedBranchScreenState>(find.byType(NeedBranchScreen))
          .debugConfirmPoint(latitude: 35.697, longitude: -0.633);
      await tester.pump();

      await tester.tap(find.byKey(const Key('need-branch-wilaya')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('31 — Oran'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('need-branch-commune')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Oran'));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.byKey(const Key('branch-create-submit')));
      await tester.tap(find.byKey(const Key('branch-create-submit')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(merchant.createdBranches, hasLength(1));
      final payload = merchant.createdBranches.single;
      expect(payload['wilayaCode'], '31');
      expect(payload['communeId'], 1101);
      expect(payload['wilayaCode'], isNot('22'));
      expect(payload['communeId'], isNot(824));
      expect(payload['latitude'], 35.697);
      expect(payload['longitude'], -0.633);
    });

    testWidgets('incomplete geography never falls back to 22/824', (
      tester,
    ) async {
      final merchant = _geoApi();
      final container = await _signedIn(merchant);
      addTearDown(container.dispose);
      await pumpNeedBranch(tester, container);
      await fillIdentity(tester);
      tester
          .state<NeedBranchScreenState>(find.byType(NeedBranchScreen))
          .debugConfirmPoint(latitude: 35.697, longitude: -0.633);
      await tester.pump();

      await tester.ensureVisible(find.byKey(const Key('branch-create-submit')));
      await tester.tap(find.byKey(const Key('branch-create-submit')));
      await tester.pump();

      expect(merchant.createdBranches, isEmpty);
      expect(find.byKey(const Key('need-branch-geo-error')), findsOneWidget);
      expect(find.text(AppStrings.adminLocationPairRequired), findsOneWidget);
    });

    testWidgets('changing wilaya clears an incompatible commune', (
      tester,
    ) async {
      final merchant = _geoApi();
      final container = await _signedIn(merchant);
      addTearDown(container.dispose);
      await pumpNeedBranch(tester, container);
      await fillIdentity(tester);
      tester
          .state<NeedBranchScreenState>(find.byType(NeedBranchScreen))
          .debugConfirmPoint(latitude: 35.697, longitude: -0.633);
      await tester.pump();

      await tester.tap(find.byKey(const Key('need-branch-wilaya')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('31 — Oran'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('need-branch-commune')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Oran'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('need-branch-wilaya')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('16 — Alger'));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.byKey(const Key('branch-create-submit')));
      await tester.tap(find.byKey(const Key('branch-create-submit')));
      await tester.pump();

      expect(merchant.createdBranches, isEmpty);
      expect(find.text(AppStrings.adminLocationPairRequired), findsOneWidget);
    });
  });

  group('D3 delivery-address snapshot', () {
    test('parses structured fields and trims blanks', () {
      final addr = MerchantOrderAddress.fromJson({
        'addressText': 'Rue Didouche',
        'latitude': 36.75,
        'longitude': 3.05,
        'building': '  A  ',
        'floor': '',
        'entrance': '  ',
        'landmark': null,
        'instructions': ' Sonner ',
        'phone': '+213555000000',
        'customerPayableMinor': '1500',
      });
      expect(addr.addressText, 'Rue Didouche');
      expect(addr.building, 'A');
      expect(addr.floor, isNull);
      expect(addr.entrance, isNull);
      expect(addr.landmark, isNull);
      expect(addr.instructions, 'Sonner');
      expect(addr.hasVisibleContent, isTrue);
    });

    test('MerchantOrderDetail keeps snapshot fields from merchant GET', () {
      final detail = MerchantOrderDetail.fromJson({
        'id': 'o1',
        'publicReference': 'sgo_o1',
        'status': 'CONFIRMED',
        'fulfillmentStatus': 'ACCEPTED',
        'merchantBranchId': 'b1',
        'createdAt': '2026-01-01T10:00:00Z',
        'items': const [],
        'statusHistory': const [],
        'deliveryAddress': {
          'addressText': 'Rue X',
          'latitude': 36.7,
          'longitude': 3.0,
          'building': 'Immeuble 12',
          'floor': '3',
          'entrance': 'B',
          'landmark': 'Mosquée',
          'instructions': 'Code 12',
        },
      });
      expect(detail.deliveryAddress.building, 'Immeuble 12');
      expect(detail.deliveryAddress.floor, '3');
      expect(detail.deliveryAddress.entrance, 'B');
      expect(detail.deliveryAddress.landmark, 'Mosquée');
      expect(detail.deliveryAddress.instructions, 'Code 12');
    });

    testWidgets('shows structured lines and ignores extra private fields', (
      tester,
    ) async {
      final detail = _order(
        address: const MerchantOrderAddress(
          addressText: 'Rue Didouche',
          latitude: 36.75,
          longitude: 3.05,
          building: 'A',
          floor: '3',
          entrance: 'B',
          landmark: 'Mosquée',
          instructions: 'Sonner',
        ),
      );
      final merchant = FakeMerchantApi(
        meHandler: () async => MerchantMe(
          merchantMembershipExists: true,
          memberships: [
            membership(branches: [branch('b1')]),
          ],
        ),
      )..mutableDetail = detail;
      final container = await _signedIn(merchant);
      addTearDown(container.dispose);
      await container
          .read(accessControllerProvider.notifier)
          .selectBranch(branch('b1'));

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: OrderDetailScreen(orderId: 'o-addr')),
        ),
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.byKey(const Key('order-address-street')));
      expect(find.text('Rue Didouche'), findsOneWidget);
      expect(find.byKey(const Key('order-address-building')), findsOneWidget);
      expect(find.byKey(const Key('order-address-floor')), findsOneWidget);
      expect(find.byKey(const Key('order-address-entrance')), findsOneWidget);
      expect(find.byKey(const Key('order-address-landmark')), findsOneWidget);
      expect(find.text('Sonner'), findsOneWidget);
      expect(find.textContaining('+213'), findsNothing);
      expect(find.textContaining('customerPayable'), findsNothing);
    });

    testWidgets('structured-only address still renders', (tester) async {
      final detail = _order(
        address: const MerchantOrderAddress(
          addressText: '   ',
          latitude: 36.75,
          longitude: 3.05,
          building: 'Tour B',
        ),
      );
      final merchant = FakeMerchantApi(
        meHandler: () async => MerchantMe(
          merchantMembershipExists: true,
          memberships: [
            membership(branches: [branch('b1')]),
          ],
        ),
      )..mutableDetail = detail;
      final container = await _signedIn(merchant);
      addTearDown(container.dispose);
      await container
          .read(accessControllerProvider.notifier)
          .selectBranch(branch('b1'));

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: OrderDetailScreen(orderId: 'o-addr')),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('order-address-building')), findsOneWidget);
      expect(find.byKey(const Key('order-address-street')), findsNothing);
    });
  });

  group('D4 OTP platform', () {
    test('maps ios, android, and desktop/web to Backend DevicePlatform', () {
      expect(
        authOtpVerifyPlatform(platform: TargetPlatform.iOS, isWeb: false),
        'ios',
      );
      expect(
        authOtpVerifyPlatform(platform: TargetPlatform.android, isWeb: false),
        'android',
      );
      expect(
        authOtpVerifyPlatform(platform: TargetPlatform.macOS, isWeb: false),
        'web',
      );
      expect(
        authOtpVerifyPlatform(platform: TargetPlatform.windows, isWeb: false),
        'web',
      );
      expect(
        authOtpVerifyPlatform(platform: TargetPlatform.iOS, isWeb: true),
        'web',
      );
    });

    test('serialized verify body uses an accepted platform and MERCHANT is unchanged',
        () async {
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      debugDefaultTargetPlatformOverride = TargetPlatform.android;

      OtpVerifyBody? captured;
      final auth = FakeAuthApi(
        verifyOtpHandler: (body) async {
          captured = body;
          return const TokenPair(
            accessToken: 'access',
            refreshToken: 'refresh-token-value',
            expiresIn: 900,
            tokenType: 'Bearer',
          );
        },
      );
      final container = testContainer(
        auth: auth,
        merchant: FakeMerchantApi(),
      );
      addTearDown(container.dispose);

      await container
          .read(sessionControllerProvider.notifier)
          .requestOtp('0550000001');
      await container
          .read(sessionControllerProvider.notifier)
          .verifyOtp('123456');

      expect(captured, isNotNull);
      final json = captured!.toJson();
      expect(json['platform'], 'android');
      expect(json['code'], '123456');
      expect(json['identifier'], '0550000001');
      expect(json['channel'], 'PHONE');
      expect(json['purpose'], 'AUTHENTICATE');
      expect(json['platform'], isNot('ios'));
    });

    test('desktop serialize as web', () {
      final body = OtpVerifyBody(
        identifier: '0550000001',
        code: '654321',
        platform: authOtpVerifyPlatform(
          platform: TargetPlatform.linux,
          isWeb: false,
        ),
      );
      expect(body.toJson()['platform'], 'web');
      expect(body.toJson()['code'], '654321');
    });
  });

  group('D5 weekday and selling-unit localization', () {
    test('FR/AR weekday and allowlist labels switch; codes stay stored', () {
      AppStrings.bind(lookupAppLocalizations(const Locale('fr')), 'fr');
      expect(SellingUnit.plat.code, 'PLAT');
      expect(SellingUnit.plat.labelFr, 'Plat');
      expect(openingHoursDayLabel(4), 'Jeudi');
      expect(sellingUnitDisplayLabel('PLAT', null), 'Plat');
      expect(formatCivilDateFr('2026-12-31'), 'Jeudi 31 Décembre 2026');

      AppStrings.bind(lookupAppLocalizations(const Locale('ar')), 'ar');
      expect(openingHoursDayLabel(4), 'الخميس');
      expect(SellingUnit.plat.localizedLabel, 'طبق');
      expect(sellingUnitDisplayLabel('PLAT', null), 'طبق');
      expect(SellingUnit.plat.code, 'PLAT');
      expect(sellingUnitDisplayLabel('CUSTOM', 'Cornet'), 'Cornet');
      expect(formatCivilDateFr('2026-12-31'), 'الخميس 31 Décembre 2026');

      AppStrings.bind(lookupAppLocalizations(const Locale('fr')), 'fr');
      expect(openingHoursDayLabel(4), 'Jeudi');
      expect(sellingUnitDisplayLabel('PLAT', null), 'Plat');
    });
  });
}
