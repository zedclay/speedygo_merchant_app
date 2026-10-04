import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:image/image.dart' as img;
import 'package:speedygo_merchant_app/app/theme/app_theme.dart';
import 'package:speedygo_merchant_app/core/constants/app_strings.dart';
import 'package:speedygo_merchant_app/core/errors/app_exception.dart';
import 'package:speedygo_merchant_app/features/access/application/access_controller.dart';
import 'package:speedygo_merchant_app/features/access/data/geo_models.dart';
import 'package:speedygo_merchant_app/features/access/data/models.dart';
import 'package:speedygo_merchant_app/features/access/presentation/location_picker_screen.dart';
import 'package:speedygo_merchant_app/features/shell/store_profile_screen.dart';
import 'package:speedygo_merchant_app/features/store/application/opening_hours_format.dart';
import 'package:speedygo_merchant_app/features/store/application/store_controllers.dart';
import 'package:speedygo_merchant_app/features/store/data/store_models.dart';
import 'package:speedygo_merchant_app/features/store/presentation/opening_hours_screen.dart';
import 'package:speedygo_merchant_app/features/store/presentation/store_address_screen.dart';
import 'package:speedygo_merchant_app/features/store/presentation/store_availability_screen.dart';
import 'package:speedygo_merchant_app/features/store/presentation/store_cover_screen.dart';
import 'package:speedygo_merchant_app/features/store/presentation/store_general_screen.dart';
import 'package:speedygo_merchant_app/features/store/presentation/temporary_closure_screen.dart';

import '../../features/phase1_flow_test.dart';
import '../../helpers/path_provider_fixture.dart';
import 'parity_harness.dart';

const _branch = MerchantBranch(
  id: 'b1',
  name: 'Dar El Benna',
  phone: '0550123456',
  addressText: '12 rue Larbi Ben M’hidi',
  latitude: 35.1899,
  longitude: -0.6308,
  operationalStatus: 'ACTIVE',
  wilayaCode: '22',
  communeId: 2201,
  wilayaNameFr: 'Sidi Bel Abbès',
  communeNameFr: 'Sidi Bel Abbès',
);

/// Wednesday 12:10 in Algiers (UTC+1).
final _now = DateTime.utc(2026, 9, 30, 11, 10);

OpeningDay _day(int dow, List<(String, String)> ranges) => OpeningDay(
      dayOfWeek: dow,
      intervals: [
        for (final r in ranges) OpeningInterval(opens: r.$1, closes: r.$2),
      ],
    );

final _week = [
  _day(1, [('11:00', '23:00')]),
  _day(2, [('11:00', '23:00')]),
  _day(3, [('11:00', '23:00')]),
  _day(4, [('11:00', '23:00')]),
  _day(5, [('11:00', '14:30'), ('18:00', '23:30')]),
  _day(6, [('11:00', '23:30')]),
  _day(7, [('11:00', '23:00')]),
];

typedef AvailabilityPut = ({
  String mode,
  String? reasonCode,
  String? customerMessage,
  String? closedUntil,
});

class StoreApi extends FakeMerchantApi {
  StoreApi({
    String role = 'OWNER',
    this.days,
    this.coverBytes,
    Map<String, int>? orderTotals,
  })  : orderTotals = orderTotals ??
            const {
              'PENDING_ACCEPTANCE': 2,
              'ACCEPTED': 1,
              'PREPARING': 2,
              'READY': 1,
            },
        super(
          meHandler: () async => MerchantMe(
            merchantMembershipExists: true,
            memberships: [
              membership(role: role, branches: const [_branch])
                  .parityWith(name: 'Dar El Benna'),
            ],
          ),
          availabilityHandler: ({required merchantId, required branchId}) async =>
              const BranchAvailabilityState(
                branchId: 'b1',
                timezone: 'Africa/Algiers',
                availabilityMode: 'FOLLOW_SCHEDULE',
                effectiveMode: 'FOLLOW_SCHEDULE',
                hoursConfigured: true,
                isOpenNow: true,
                acceptingOrders: true,
                temporaryExpired: false,
                outsideWeeklyHours: false,
                reasonCode: null,
                customerMessage: null,
                closedUntil: null,
                nextOpenAt: null,
                currentClosesAt: '2026-09-30T22:00:00.000Z',
                version: 3,
                updatedAt: '2026-09-30T11:05:00.000Z',
              ),
        ) {
    openingHoursHandler = ({required merchantId, required branchId}) async {
      hoursLoads++;
      return OpeningHoursSchedule(
        branchId: branchId,
        timezone: 'Africa/Algiers',
        hoursConfigured: true,
        version: 4 + (hoursLoads > 1 && reloadBumpsVersion ? 1 : 0),
        days: days ?? _week,
      );
    };
    ordersHandler = ({
      required merchantId,
      branchId,
      orderStatus,
      fulfillmentStatus,
      limit = 50,
      offset = 0,
    }) async =>
        MerchantOrderListPage(
          items: const [],
          limit: limit,
          offset: offset,
          total: this.orderTotals[fulfillmentStatus] ?? 0,
        );
  }

  final List<OpeningDay>? days;
  final Uint8List? coverBytes;
  final Map<String, int> orderTotals;
  final List<List<OpeningDay>> savedWeeks = [];
  final List<AvailabilityPut> availabilityPuts = [];
  ApiException? hoursError;
  bool reloadBumpsVersion = false;
  int hoursLoads = 0;
  final List<Map<String, Object?>> branchUpdates = [];
  Object? branchError;

  @override
  Future<MerchantBranch> updateBranch({
    required String merchantId,
    required String branchId,
    String? name,
    String? phone,
    String? addressText,
    double? latitude,
    double? longitude,
    String? wilayaCode,
    int? communeId,
  }) async {
    branchUpdates.add({
      'name': name,
      'phone': phone,
      'addressText': addressText,
      'latitude': latitude,
      'longitude': longitude,
      'wilayaCode': wilayaCode,
      'communeId': communeId,
    });
    final error = branchError;
    if (error != null) throw error;
    return MerchantBranch(
      id: branchId,
      name: name ?? _branch.name,
      phone: phone ?? _branch.phone,
      addressText: addressText ?? _branch.addressText,
      latitude: latitude ?? _branch.latitude,
      longitude: longitude ?? _branch.longitude,
      operationalStatus: _branch.operationalStatus,
      wilayaCode: wilayaCode ?? _branch.wilayaCode,
      communeId: communeId ?? _branch.communeId,
    );
  }

  @override
  Future<OpeningHoursSchedule> putOpeningHours({
    required String merchantId,
    required String branchId,
    required int expectedVersion,
    required List<OpeningDay> days,
  }) async {
    savedWeeks.add(days);
    if (hoursError != null) throw hoursError!;
    return super.putOpeningHours(
      merchantId: merchantId,
      branchId: branchId,
      expectedVersion: expectedVersion,
      days: days,
    );
  }

  @override
  Future<BranchAvailabilityState> putAvailability({
    required String merchantId,
    required String branchId,
    required int expectedVersion,
    required String mode,
    String? reasonCode,
    String? customerMessage,
    String? closedUntil,
  }) {
    availabilityPuts.add((
      mode: mode,
      reasonCode: reasonCode,
      customerMessage: customerMessage,
      closedUntil: closedUntil,
    ));
    return super.putAvailability(
      merchantId: merchantId,
      branchId: branchId,
      expectedVersion: expectedVersion,
      mode: mode,
      reasonCode: reasonCode,
      customerMessage: customerMessage,
      closedUntil: closedUntil,
    );
  }

  @override
  Future<Uint8List?> fetchBranchCoverBytes({
    required String merchantId,
    required String branchId,
  }) async =>
      coverBytes;

  @override
  Future<List<AlgeriaWilaya>> listWilayas() async => const [
        AlgeriaWilaya(code: '16', nameFr: 'Alger', nameAr: 'الجزائر'),
        AlgeriaWilaya(code: '22', nameFr: 'Sidi Bel Abbès', nameAr: 'سيدي بلعباس'),
      ];

  @override
  Future<List<AlgeriaCommune>> listCommunes({
    required String wilayaCode,
    String? q,
  }) async {
    if (wilayaCode != '22') {
      return super.listCommunes(wilayaCode: wilayaCode, q: q);
    }
    return const [
      AlgeriaCommune(
        id: 2201,
        wilayaCode: '22',
        nameFr: 'Sidi Bel Abbès',
        nameAr: 'سيدي بلعباس',
      ),
    ];
  }
}

Future<ProviderContainer> storeReady({String role = 'OWNER', StoreApi? api}) async {
  final container = await parityReady(
    api ?? StoreApi(role: role),
    branchName: _branch.name,
    overrides: [storeClockProvider.overrideWithValue(() => _now)],
  );
  await container.read(accessControllerProvider.notifier).selectBranch(_branch);
  return container;
}

/// Synthetic 960×540 cover fixture (not reference imagery).
final Uint8List _coverFixture = () {
  final image = img.Image(width: 960, height: 540);
  for (var y = 0; y < 540; y++) {
    final t = y / 540;
    img.drawLine(
      image,
      x1: 0,
      y1: y,
      x2: 959,
      y2: y,
      color: img.ColorRgb8(
        (180 - 80 * t).round(),
        (120 - 40 * t).round(),
        (70 + 60 * t).round(),
      ),
    );
  }
  img.fillRect(
    image,
    x1: 300,
    y1: 180,
    x2: 660,
    y2: 540,
    color: img.ColorRgb8(60, 40, 30),
  );
  return Uint8List.fromList(img.encodeJpg(image, quality: 85));
}();

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 20; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

/// Real GoRouter so `context.pop()` after a save lands on the hub.
Future<void> _pumpRouted(
  WidgetTester tester, {
  required ProviderContainer container,
  required Widget child,
  double height = 1800,
  double textScale = 1,
}) async {
  final size = Size(390, height);
  tester.view.physicalSize = Size(size.width * 2, size.height * 2);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final router = GoRouter(
    initialLocation: '/screen',
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => const Scaffold(
          body: Text('hub', key: Key('test-hub')),
        ),
        routes: [GoRoute(path: 'screen', builder: (_, _) => child)],
      ),
    ],
  );
  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(
        size: size,
        textScaler: TextScaler.linear(textScale),
      ),
      child: UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          theme: AppTheme.light(locale: const Locale('fr')),
          routerConfig: router,
        ),
      ),
    ),
  );
  await _settle(tester);
}

String _dayText(WidgetTester tester, int dow) =>
    tester
        .widget<Text>(find.byKey(Key('opening-hours-day-$dow')))
        .data!
        .replaceAll('\u2060', '');

void main() {
  installPathProviderFixture();

  group('batch 4 store captures', () {
    for (final v in parityVariants) {
      testWidgets('store profile ${v.suffix}', (tester) async {
        final container =
            await storeReady(api: StoreApi(coverBytes: _coverFixture));
        addTearDown(container.dispose);
        await parityPumpFull(
          tester,
          container: container,
          variant: v,
          tabIndex: 4,
          child: const StoreProfileScreen(),
        );
        await tester.runAsync(() async {
          await precacheImage(
            MemoryImage(_coverFixture),
            tester.element(find.byType(StoreProfileScreen)),
          );
        });
        await _settle(tester);
        expect(
          find.descendant(
            of: find.byKey(const Key('store-profile-hero')),
            matching: find.byType(Image),
          ),
          findsOneWidget,
        );
        expect(find.byKey(const Key('store-profile-status')), findsOneWidget);
        final hero = tester.getRect(find.byKey(const Key('store-profile-hero')));
        final scrim = tester.getRect(
          find.byKey(const Key('store-profile-hero-scrim')),
        );
        expect(scrim.top, hero.top);
        expect(
          scrim.bottom,
          hero.bottom,
          reason: 'the cover gradient must not darken the page below it',
        );
        await parityCapture(tester, 'b4_profile_${v.suffix}');
      });

      final screens = <String, Widget>{
        'hours': const OpeningHoursScreen(),
        'availability': const StoreAvailabilityScreen(),
        'address': const StoreAddressScreen(),
        'general': const StoreGeneralScreen(),
      };
      for (final entry in screens.entries) {
        testWidgets('${entry.key} ${v.suffix}', (tester) async {
          final container = await storeReady();
          addTearDown(container.dispose);
          await parityPumpFull(
            tester,
            container: container,
            variant: v,
            child: entry.value,
            pushed: true,
          );
          await parityCapture(tester, 'b4_${entry.key}_${v.suffix}');
        });
      }

      testWidgets('map location ${v.suffix}', (tester) async {
        final container = await storeReady();
        addTearDown(container.dispose);
        // The map controls use Material elevation, which flutter_test draws
        // as solid outlines unless real shadows are enabled.
        debugDisableShadows = false;
        await parityPump(
          tester,
          container: container,
          variant: v,
          height: 844,
          pushed: true,
          child: LocationPickerScreen(
            initialLatitude: _branch.latitude,
            initialLongitude: _branch.longitude,
            branchLabel: _branch.name,
            addressHint: _branch.addressText,
          ),
        );
        await parityCapture(tester, 'b4_map_${v.suffix}');
        debugDisableShadows = true;
        expect(find.byKey(const Key('merchant-location-picker')), findsOneWidget);
        expect(find.byKey(const Key('merchant-location-cover-thumb')), findsOneWidget);
        expect(find.text(_branch.addressText), findsOneWidget);
        expect(find.textContaining(_branch.latitude.toStringAsFixed(5)), findsNothing);
        expect(tester.takeException(), isNull);
      });

      testWidgets('temporary ${v.suffix}', (tester) async {
        final container = await storeReady();
        addTearDown(container.dispose);
        await parityPumpFull(
          tester,
          container: container,
          variant: v,
          child: const TemporaryClosureScreen(),
          pushed: true,
        );
        await tester.runAsync(() async {
          await precacheImage(
            const AssetImage('assets/images/temporary_closure_kitchen.jpg'),
            tester.element(find.byType(TemporaryClosureScreen)),
          );
        });
        await _settle(tester);
        await parityCapture(tester, 'b4_temporary_${v.suffix}');
      });

      testWidgets('cover ${v.suffix}', (tester) async {
        final container =
            await storeReady(api: StoreApi(coverBytes: _coverFixture));
        addTearDown(container.dispose);
        await parityPumpFull(
          tester,
          container: container,
          variant: v,
          child: const StoreCoverScreen(),
          pushed: true,
        );
        await tester.runAsync(() async {
          await precacheImage(
            MemoryImage(_coverFixture),
            tester.element(find.byType(StoreCoverScreen)),
          );
        });
        await _settle(tester);
        await parityCapture(tester, 'b4_cover_${v.suffix}');
      });
    }
  });

  group('opening hours behaviour', () {
    testWidgets('rows are Monday-first (D-D6) and show every interval',
        (tester) async {
      final container = await storeReady();
      addTearDown(container.dispose);
      await _pumpRouted(
        tester,
        container: container,
        child: const OpeningHoursScreen(),
      );
      final monday = tester.getTopLeft(find.byKey(const Key('opening-hours-row-1')));
      final sunday = tester.getTopLeft(find.byKey(const Key('opening-hours-row-7')));
      expect(monday.dy, lessThan(sunday.dy));
      expect(_dayText(tester, 5), '11:00–14:30 · 18:00–23:30');
      expect(find.text(AppStrings.openingHoursOpenNow), findsOneWidget);
      expect(find.byKey(const Key('opening-hours-branch')), findsOneWidget);
    });

    testWidgets('saving after editing one day keeps split intervals',
        (tester) async {
      final api = StoreApi();
      final container = await storeReady(api: api);
      addTearDown(container.dispose);
      await _pumpRouted(
        tester,
        container: container,
        child: const OpeningHoursScreen(),
      );
      await tester.tap(find.byKey(const Key('opening-hours-switch-1')));
      await tester.pump();
      expect(_dayText(tester, 1), AppStrings.openingHoursClosed);
      await tester.tap(find.byKey(const Key('opening-hours-save')));
      await _settle(tester);

      final saved = api.savedWeeks.single;
      expect(saved.map((d) => d.dayOfWeek), [1, 2, 3, 4, 5, 6, 7]);
      expect(saved[0].intervals, isEmpty);
      expect(
        saved[4].intervals.map(formatInterval),
        ['11:00–14:30', '18:00–23:30'],
      );
      expect(find.text(AppStrings.openingHoursSaved), findsOneWidget);
    });

    testWidgets('switching a day back on restores its intervals',
        (tester) async {
      final container = await storeReady();
      addTearDown(container.dispose);
      await _pumpRouted(
        tester,
        container: container,
        child: const OpeningHoursScreen(),
      );
      await tester.tap(find.byKey(const Key('opening-hours-switch-5')));
      await tester.pump();
      expect(_dayText(tester, 5), AppStrings.openingHoursClosed);
      await tester.tap(find.byKey(const Key('opening-hours-switch-5')));
      await tester.pump();
      expect(_dayText(tester, 5), '11:00–14:30 · 18:00–23:30');
    });

    testWidgets('day editor removes and adds ranges up to three',
        (tester) async {
      final api = StoreApi();
      final container = await storeReady(api: api);
      addTearDown(container.dispose);
      await _pumpRouted(
        tester,
        container: container,
        child: const OpeningHoursScreen(),
      );
      await tester.tap(find.byKey(const Key('opening-hours-row-5')));
      await _settle(tester);
      expect(find.byKey(const Key('day-editor-sheet')), findsOneWidget);
      await tester.tap(find.byKey(const Key('day-editor-remove-1')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('day-editor-apply')));
      await _settle(tester);
      expect(_dayText(tester, 5), '11:00–14:30');

      await tester.tap(find.byKey(const Key('opening-hours-row-6')));
      await _settle(tester);
      await tester.tap(find.byKey(const Key('day-editor-add')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('day-editor-add')));
      await tester.pump();
      final add =
          tester.widget<TextButton>(find.byKey(const Key('day-editor-add')));
      expect(add.onPressed, isNull);
      await tester.tap(find.byKey(const Key('day-editor-apply')));
      await _settle(tester);
      expect(_dayText(tester, 6), '11:00–23:30 · 00:30–02:30 · 03:30–05:30');

      await tester.tap(find.byKey(const Key('opening-hours-save')));
      await _settle(tester);
      final saved = api.savedWeeks.single;
      expect(saved[4].intervals.map(formatInterval), ['11:00–14:30']);
      expect(saved[5].intervals, hasLength(3));
    });

    testWidgets('server rejection keeps the draft and explains',
        (tester) async {
      final api = StoreApi()
        ..hoursError = const ApiException(
          'invalid',
          code: 'OPENING_HOURS_INVALID',
          statusCode: 400,
        );
      final container = await storeReady(api: api);
      addTearDown(container.dispose);
      await _pumpRouted(
        tester,
        container: container,
        child: const OpeningHoursScreen(),
      );
      await tester.tap(find.byKey(const Key('opening-hours-switch-2')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('opening-hours-save')));
      await _settle(tester);
      expect(find.text(AppStrings.openingHoursInvalid), findsOneWidget);
      expect(_dayText(tester, 2), AppStrings.openingHoursClosed);
      expect(find.byKey(const Key('opening-hours-screen')), findsOneWidget);
    });

    testWidgets('version conflict reloads server hours', (tester) async {
      final api = StoreApi()
        ..hoursError = const ApiException(
          'conflict',
          code: 'OPENING_HOURS_VERSION_CONFLICT',
          statusCode: 409,
        )
        ..reloadBumpsVersion = true;
      final container = await storeReady(api: api);
      addTearDown(container.dispose);
      await _pumpRouted(
        tester,
        container: container,
        child: const OpeningHoursScreen(),
      );
      await tester.tap(find.byKey(const Key('opening-hours-switch-2')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('opening-hours-save')));
      await _settle(tester);
      expect(find.text(AppStrings.openingHoursConflict), findsOneWidget);
      expect(_dayText(tester, 2), '11:00–23:00');
      expect(api.hoursLoads, 2);
    });

    testWidgets('STAFF sees hours read-only', (tester) async {
      final container = await storeReady(role: 'STAFF');
      addTearDown(container.dispose);
      await _pumpRouted(
        tester,
        container: container,
        child: const OpeningHoursScreen(),
      );
      expect(_dayText(tester, 5), '11:00–14:30 · 18:00–23:30');
      expect(find.byKey(const Key('opening-hours-save')), findsNothing);
      expect(find.byKey(const Key('opening-hours-switch-1')), findsNothing);
      expect(find.byKey(const Key('opening-hours-readonly')), findsOneWidget);
      await tester.tap(find.byKey(const Key('opening-hours-row-1')));
      await _settle(tester);
      expect(find.byKey(const Key('day-editor-sheet')), findsNothing);
    });
  });

  group('availability behaviour', () {
    testWidgets('shows real today hours, order total and update age',
        (tester) async {
      final container = await storeReady();
      addTearDown(container.dispose);
      await _pumpRouted(
        tester,
        container: container,
        child: const StoreAvailabilityScreen(),
      );
      expect(find.text('11:00 - 23:00'), findsOneWidget);
      expect(find.text('6 commandes en cours'), findsOneWidget);
      expect(
        find.text('Dernière mise à jour : il y a 5 min'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('availability-pause-30')), findsOneWidget);
      expect(find.byKey(const Key('availability-pause-60')), findsOneWidget);
      expect(find.byKey(const Key('availability-close-warning')), findsNothing);

      await tester.tap(find.byKey(const Key('availability-seg-closed')));
      await tester.pump();
      expect(find.byKey(const Key('availability-close-warning')), findsOneWidget);
      expect(find.textContaining('les 6 commandes actives'), findsOneWidget);
    });

    testWidgets('closed today and split days render from schedule',
        (tester) async {
      final days = [
        for (final d in _week)
          d.dayOfWeek == 3
              ? _day(3, [('11:00', '14:30'), ('18:00', '23:30')])
              : d,
      ];
      final container = await storeReady(api: StoreApi(days: days));
      addTearDown(container.dispose);
      await _pumpRouted(
        tester,
        container: container,
        child: const StoreAvailabilityScreen(),
      );
      expect(find.text('11:00 - 14:30\n18:00 - 23:30'), findsOneWidget);
    });

    testWidgets('STAFF cannot change availability', (tester) async {
      final container = await storeReady(role: 'STAFF');
      addTearDown(container.dispose);
      await _pumpRouted(
        tester,
        container: container,
        child: const StoreAvailabilityScreen(),
      );
      expect(find.byKey(const Key('availability-save')), findsNothing);
      expect(find.byKey(const Key('availability-pause-30')), findsNothing);
      expect(find.byKey(const Key('availability-modify-hours')), findsNothing);
      expect(find.byKey(const Key('availability-readonly')), findsOneWidget);
      await tester.tap(find.byKey(const Key('availability-seg-closed')));
      await tester.pump();
      expect(find.byKey(const Key('availability-close-warning')), findsNothing);
    });
  });

  group('temporary closure behaviour', () {
    testWidgets('impact uses the real order total and branch subtitle',
        (tester) async {
      final container = await storeReady();
      addTearDown(container.dispose);
      await _pumpRouted(
        tester,
        container: container,
        child: const TemporaryClosureScreen(),
      );
      final impact = tester
          .widget<RichText>(
            find.descendant(
              of: find.byKey(const Key('temporary-closure-impact-text')),
              matching: find.byType(RichText),
            ),
          )
          .text
          .toPlainText();
      expect(impact, contains('Les 6 commandes en cours seront maintenues'));
      expect(find.byKey(const Key('orders-branch-context')), findsOneWidget);
      expect(find.text('Dar El Benna'), findsOneWidget);
    });

    testWidgets('no active orders reads naturally', (tester) async {
      final container = await storeReady(
        api: StoreApi(orderTotals: const {}),
      );
      addTearDown(container.dispose);
      await _pumpRouted(
        tester,
        container: container,
        child: const TemporaryClosureScreen(),
      );
      final impact = tester
          .widget<RichText>(
            find.descendant(
              of: find.byKey(const Key('temporary-closure-impact-text')),
              matching: find.byType(RichText),
            ),
          )
          .text
          .toPlainText();
      expect(impact, contains(AppStrings.temporaryClosureImpactNone));
      expect(impact, isNot(contains('Les 0')));
    });

    testWidgets('30 minute preset sends closedUntil 30 minutes out',
        (tester) async {
      final api = StoreApi();
      final container = await storeReady(api: api);
      addTearDown(container.dispose);
      await _pumpRouted(
        tester,
        container: container,
        child: const TemporaryClosureScreen(),
      );
      await tester.tap(find.byKey(const Key('temporary-closure-confirm')));
      await _settle(tester);
      final put = api.availabilityPuts.single;
      expect(put.mode, 'TEMPORARY_CLOSED');
      expect(put.reasonCode, 'PEAK_KITCHEN');
      expect(
        DateTime.parse(put.closedUntil!),
        _now.add(const Duration(minutes: 30)),
      );
      expect(find.byKey(const Key('test-hub')), findsOneWidget);
    });

    testWidgets('no "Demain à l’ouverture" option while D-D5 is open',
        (tester) async {
      final container = await storeReady();
      addTearDown(container.dispose);
      await _pumpRouted(
        tester,
        container: container,
        child: const TemporaryClosureScreen(),
      );
      await tester.tap(find.byKey(const Key('temporary-closure-preset')));
      await _settle(tester);
      expect(find.textContaining('Demain à l’ouverture'), findsNothing);
    });

    testWidgets('custom time is today when still ahead', (tester) async {
      final api = StoreApi();
      final container = await storeReady(api: api);
      addTearDown(container.dispose);
      await _pumpRouted(
        tester,
        container: container,
        child: const TemporaryClosureScreen(),
      );
      await tester.tap(find.byKey(const Key('temporary-closure-preset')));
      await _settle(tester);
      await tester.tap(find.text(AppStrings.temporaryClosurePickTime).last);
      await _settle(tester);
      await tester.tap(find.text('OK'));
      await _settle(tester);
      expect(find.text('Aujourd’hui à 13:10'), findsOneWidget);
      await tester.tap(find.byKey(const Key('temporary-closure-confirm')));
      await _settle(tester);
      expect(
        DateTime.parse(api.availabilityPuts.single.closedUntil!),
        DateTime.utc(2026, 9, 30, 12, 10),
      );
    });

    testWidgets('indefinite closure is FORCE_CLOSED without end',
        (tester) async {
      final api = StoreApi();
      final container = await storeReady(api: api);
      addTearDown(container.dispose);
      await _pumpRouted(
        tester,
        container: container,
        child: const TemporaryClosureScreen(),
      );
      await tester.tap(find.byKey(const Key('temporary-closure-reason-TECHNICAL')));
      await tester.tap(find.byKey(const Key('temporary-closure-preset')));
      await _settle(tester);
      await tester.tap(find.text(AppStrings.temporaryClosureIndefinite).last);
      await _settle(tester);
      await tester.tap(find.byKey(const Key('temporary-closure-confirm')));
      await _settle(tester);
      final put = api.availabilityPuts.single;
      expect(put.mode, 'FORCE_CLOSED');
      expect(put.reasonCode, 'TECHNICAL');
      expect(put.closedUntil, isNull);
    });

    testWidgets('STAFF cannot close the store', (tester) async {
      final container = await storeReady(role: 'STAFF');
      addTearDown(container.dispose);
      await _pumpRouted(
        tester,
        container: container,
        child: const TemporaryClosureScreen(),
      );
      expect(find.byKey(const Key('temporary-closure-confirm')), findsNothing);
      expect(find.byKey(const Key('temporary-closure-readonly')), findsOneWidget);
    });
  });

  group('cover and address behaviour', () {
    testWidgets('remove shows only for a saved cover; save needs a new pick',
        (tester) async {
      final container =
          await storeReady(api: StoreApi(coverBytes: _coverFixture));
      addTearDown(container.dispose);
      await _pumpRouted(
        tester,
        container: container,
        child: const StoreCoverScreen(),
      );
      expect(find.byKey(const Key('store-cover-remove')), findsOneWidget);
      final save = tester.widget<FilledButton>(
        find.byKey(const Key('store-cover-save')),
      );
      expect(save.onPressed, isNull);
    });

    testWidgets('no saved cover hides remove', (tester) async {
      final container = await storeReady();
      addTearDown(container.dispose);
      await _pumpRouted(
        tester,
        container: container,
        child: const StoreCoverScreen(),
      );
      expect(find.byKey(const Key('store-cover-remove')), findsNothing);
    });

    testWidgets('address restores wilaya 22 and states who sees the phone',
        (tester) async {
      final container = await storeReady();
      addTearDown(container.dispose);
      await _pumpRouted(
        tester,
        container: container,
        child: const StoreAddressScreen(),
      );
      expect(find.text('22 — Sidi Bel Abbès'), findsOneWidget);
      expect(find.text(AppStrings.storeAddressPhoneHint), findsOneWidget);
      expect(find.textContaining('visible par les clients'), findsNothing);
    });
  });

  group('opening hours helpers', () {
    test('day validation mirrors backend rules', () {
      OpeningInterval i(String o, String c) =>
          OpeningInterval(opens: o, closes: c);
      expect(validateDayIntervals([i('11:00', '14:30'), i('18:00', '23:30')]),
          isNull);
      expect(validateDayIntervals([i('11:00', '14:30'), i('14:30', '18:00')]),
          isNull);
      expect(validateDayIntervals([i('11:00', '15:00'), i('14:30', '18:00')]),
          OpeningDayIssue.overlap);
      expect(validateDayIntervals([i('22:00', '02:00'), i('01:00', '03:00')]),
          isNull);
      expect(validateDayIntervals([i('20:00', '02:00'), i('21:00', '22:00')]),
          OpeningDayIssue.overlap);
      expect(validateDayIntervals([i('00:00', '00:00')]), isNull);
      expect(validateDayIntervals([i('09:00', '09:00')]),
          OpeningDayIssue.zeroLength);
      expect(
        validateDayIntervals([
          i('01:00', '02:00'),
          i('03:00', '04:00'),
          i('05:00', '06:00'),
          i('07:00', '08:00'),
        ]),
        OpeningDayIssue.tooMany,
      );
    });

    test('today follows Algiers local time', () {
      final schedule = OpeningHoursSchedule(
        branchId: 'b1',
        timezone: 'Africa/Algiers',
        hoursConfigured: true,
        version: 1,
        days: _week,
      );
      // Tuesday 23:30 UTC is already Wednesday 00:30 in Algiers.
      final lateTuesday = DateTime.utc(2026, 9, 29, 23, 30);
      expect(todayIntervals(schedule, lateTuesday)!.single.opens, '11:00');
    });
  });

  group('general information (D-D1)', () {
    Finder field() => find.byKey(const Key('store-general-branch-name'));
    FilledButton save(WidgetTester tester) => tester.widget<FilledButton>(
          find.byKey(const Key('store-general-save')),
        );

    testWidgets('profile row opens the general screen', (tester) async {
      final container = await storeReady();
      addTearDown(container.dispose);
      final router = GoRouter(
        initialLocation: '/p',
        routes: [
          GoRoute(path: '/p', builder: (_, _) => const StoreProfileScreen()),
          GoRoute(
            path: '/app/profile/general',
            builder: (_, _) => const StoreGeneralScreen(),
          ),
        ],
      );
      tester.view.physicalSize = const Size(780, 3000);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            theme: AppTheme.light(locale: const Locale('fr')),
            routerConfig: router,
          ),
        ),
      );
      await _settle(tester);
      await tester.tap(find.byKey(const Key('store-profile-general')));
      await _settle(tester);
      expect(find.byKey(const Key('store-general-screen')), findsOneWidget);
    });

    for (final role in const ['OWNER', 'MANAGER']) {
      testWidgets('$role edits the branch name only', (tester) async {
        final api = StoreApi(role: role);
        api.meHandler = () async {
          final saved = api.branchUpdates.isEmpty
              ? null
              : api.branchUpdates.last['name'] as String?;
          return MerchantMe(
            merchantMembershipExists: true,
            memberships: [
              membership(
                role: role,
                branches: [
                  MerchantBranch(
                    id: _branch.id,
                    name: saved ?? _branch.name,
                    phone: _branch.phone,
                    addressText: _branch.addressText,
                    latitude: _branch.latitude,
                    longitude: _branch.longitude,
                    operationalStatus: _branch.operationalStatus,
                  ),
                ],
              ).parityWith(name: 'Dar El Benna'),
            ],
          );
        };
        final container = await storeReady(api: api);
        addTearDown(container.dispose);
        await _pumpRouted(
          tester,
          container: container,
          child: const StoreGeneralScreen(),
        );
        expect(tester.widget<TextField>(field()).enabled, isTrue);
        expect(save(tester).onPressed, isNull);
        expect(
          find.descendant(
            of: find.byKey(const Key('store-general-merchant')),
            matching: find.byType(TextField),
          ),
          findsNothing,
        );
        expect(
          find.byKey(const Key('store-general-merchant-lock')),
          findsOneWidget,
        );
        await tester.enterText(field(), '  Dar El Benna Centre  ');
        await tester.pump();
        expect(save(tester).onPressed, isNotNull);
        await tester.tap(find.byKey(const Key('store-general-save')));
        await _settle(tester);
        expect(api.branchUpdates, [
          {
            'name': 'Dar El Benna Centre',
            'phone': null,
            'addressText': null,
            'latitude': null,
            'longitude': null,
            'wilayaCode': null,
            'communeId': null,
          },
        ]);
        expect(find.byKey(const Key('test-hub')), findsOneWidget);
        expect(
          container.read(accessControllerProvider).selectedBranch?.name,
          'Dar El Benna Centre',
        );
      });
    }

    testWidgets('STAFF sees both names read-only and no save', (tester) async {
      final container = await storeReady(role: 'STAFF');
      addTearDown(container.dispose);
      await _pumpRouted(
        tester,
        container: container,
        child: const StoreGeneralScreen(),
      );
      expect(tester.widget<TextField>(field()).enabled, isFalse);
      expect(find.byKey(const Key('store-general-save')), findsNothing);
      expect(find.byKey(const Key('store-general-read-only')), findsOneWidget);
    });

    testWidgets('empty name is refused locally', (tester) async {
      final api = StoreApi();
      final container = await storeReady(api: api);
      addTearDown(container.dispose);
      await _pumpRouted(
        tester,
        container: container,
        child: const StoreGeneralScreen(),
      );
      await tester.enterText(field(), '   ');
      await tester.pump();
      await tester.tap(find.byKey(const Key('store-general-save')));
      await _settle(tester);
      expect(api.branchUpdates, isEmpty);
      expect(find.text(AppStrings.storeGeneralNameRequired), findsOneWidget);
    });

    for (final (status, message) in const [
      (403, AppStrings.storeGeneralForbidden),
      (409, AppStrings.storeGeneralRestricted),
      (500, AppStrings.storeGeneralSaveError),
    ]) {
      testWidgets('server $status keeps the draft and explains', (
        tester,
      ) async {
        final api = StoreApi()
          ..branchError = ApiException('x', statusCode: status);
        final container = await storeReady(api: api);
        addTearDown(container.dispose);
        await _pumpRouted(
          tester,
          container: container,
          child: const StoreGeneralScreen(),
        );
        await tester.enterText(field(), 'Nouveau nom');
        await tester.pump();
        await tester.tap(find.byKey(const Key('store-general-save')));
        await _settle(tester);
        expect(find.text(message), findsOneWidget);
        expect(tester.widget<TextField>(field()).controller!.text, 'Nouveau nom');
        expect(find.byKey(const Key('test-hub')), findsNothing);
        expect(
          container.read(accessControllerProvider).selectedBranch?.name,
          'Dar El Benna',
        );
      });
    }

    testWidgets('1.35 on 375 keeps the save button reachable', (tester) async {
      final container = await storeReady();
      addTearDown(container.dispose);
      await parityPump(
        tester,
        container: container,
        variant: parityVariants.last,
        height: 667,
        bottomInset: 34,
        child: const StoreGeneralScreen(),
        pushed: true,
      );
      expect(tester.takeException(), isNull);
      final saveRect = tester.getRect(find.byKey(const Key('store-general-save')));
      expect(saveRect.bottom, lessThanOrEqualTo(667 - 34));
    });
  });
}
