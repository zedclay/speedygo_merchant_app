import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speedygo_merchant_app/app/theme/app_theme.dart';
import 'package:speedygo_merchant_app/core/constants/app_strings.dart';
import 'package:speedygo_merchant_app/core/storage/session_store.dart';
import 'package:speedygo_merchant_app/core/widgets/merchant_primary_button.dart';
import 'package:speedygo_merchant_app/features/access/application/access_controller.dart';
import 'package:speedygo_merchant_app/features/access/application/registration_controller.dart';
import 'package:speedygo_merchant_app/features/access/data/location_client.dart';
import 'package:speedygo_merchant_app/features/access/data/models.dart';
import 'package:speedygo_merchant_app/features/access/presentation/location_picker_screen.dart';
import 'package:speedygo_merchant_app/features/auth/application/session_controller.dart';
import 'package:speedygo_merchant_app/features/auth/application/session_providers.dart';
import 'package:speedygo_merchant_app/features/auth/data/models.dart';

import 'phase1_flow_test.dart';
import 'startup_flow_test.dart';

class _FakeLocationClient implements LocationClient {
  _FakeLocationClient(this.access);

  LocationAccess access;
  DeviceLocation fix =
      const DeviceLocation(latitude: 35.2, longitude: -0.63);
  var throwUnavailable = false;
  var requestCount = 0;

  @override
  Future<LocationAccess> requestAccess() async {
    requestCount++;
    if (throwUnavailable) throw const LocationUnavailableException();
    return access;
  }

  @override
  Future<DeviceLocation> readCurrent() async {
    if (throwUnavailable) throw const LocationUnavailableException();
    return fix;
  }
}

ProviderContainer _authed(FakeMerchantApi merchant) {
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
    launch: ControllableLaunchStore(languageSeen: true, onboardingSeen: true),
  );
  container.read(tokenCacheProvider).current = store.value;
  return container;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('picker back returns null; confirm disabled until selection',
      (tester) async {
    final fake = _FakeLocationClient(LocationAccess.granted);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [locationClientProvider.overrideWithValue(fake)],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const LocationPickerScreen(),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byKey(const Key('merchant-location-picker')), findsOneWidget);
    expect(find.byKey(const Key('merchant-location-move-hint')), findsOneWidget);

    final cta = tester.widget<MerchantPrimaryButton>(
      find.byKey(const Key('merchant-location-confirm')),
    );
    expect(cta.onPressed, isNull);

    await tester.tap(find.byKey(const Key('merchant-location-back')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('merchant-location-picker')), findsNothing);
    expect(fake.requestCount, 0);
  });

  testWidgets('reopen with confirmed coords enables confirm', (tester) async {
    LocationPickResult? result;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          locationClientProvider.overrideWithValue(
            _FakeLocationClient(LocationAccess.granted),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: TextButton(
                  onPressed: () async {
                    result = await Navigator.of(context).push<LocationPickResult>(
                      MaterialPageRoute(
                        builder: (_) => const LocationPickerScreen(
                          initialLatitude: 36.75,
                          initialLongitude: 3.05,
                        ),
                      ),
                    );
                  },
                  child: const Text('open'),
                ),
              );
            },
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    final cta = tester.widget<MerchantPrimaryButton>(
      find.byKey(const Key('merchant-location-confirm')),
    );
    expect(cta.onPressed, isNotNull);
    await tester.tap(find.byKey(const Key('merchant-location-confirm')));
    await tester.pumpAndSettle();
    expect(result?.latitude, closeTo(36.75, 0.0001));
    expect(result?.longitude, closeTo(3.05, 0.0001));
  });

  testWidgets('cancel after GPS does not return a result', (tester) async {
    LocationPickResult? result = const LocationPickResult(
      latitude: 1,
      longitude: 1,
    );
    final fake = _FakeLocationClient(LocationAccess.granted);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [locationClientProvider.overrideWithValue(fake)],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: TextButton(
                  onPressed: () async {
                    result = await Navigator.of(context).push<LocationPickResult>(
                      MaterialPageRoute(
                        builder: (_) => const LocationPickerScreen(
                          initialLatitude: 36.75,
                          initialLongitude: 3.05,
                        ),
                      ),
                    );
                  },
                  child: const Text('open'),
                ),
              );
            },
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('merchant-location-use-gps')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text(AppStrings.regLocationGpsSuggestion), findsOneWidget);
    await tester.tap(find.byKey(const Key('merchant-location-back')));
    await tester.pumpAndSettle();
    expect(result, isNull);
  });

  testWidgets('GPS denied / forever / services / unavailable', (tester) async {
    final fake = _FakeLocationClient(LocationAccess.denied);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [locationClientProvider.overrideWithValue(fake)],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const LocationPickerScreen(
            initialLatitude: 36.7,
            initialLongitude: 3.0,
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.byKey(const Key('merchant-location-use-gps')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text(AppStrings.regLocationDenied), findsOneWidget);

    fake.access = LocationAccess.deniedForever;
    await tester.tap(find.byKey(const Key('merchant-location-use-gps')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text(AppStrings.regLocationDeniedForever), findsOneWidget);

    fake.access = LocationAccess.servicesDisabled;
    await tester.tap(find.byKey(const Key('merchant-location-use-gps')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text(AppStrings.regLocationServicesDisabled), findsOneWidget);

    fake.throwUnavailable = true;
    await tester.tap(find.byKey(const Key('merchant-location-use-gps')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text(AppStrings.regLocationUnavailable), findsOneWidget);
  });

  test('continue blocked without confirmed map location; payload mapping',
      () async {
    final base = membership(
      status: 'PENDING_REVIEW',
      approved: false,
      merchantId: 'm-loc',
      branches: const [],
    ).copyWithName('Loc Shop');
    final merchant = FakeMerchantApi(
      meHandler: () async => MerchantMe(
        merchantMembershipExists: true,
        memberships: [base],
      ),
    );
    final container = _authed(merchant);
    addTearDown(container.dispose);
    await container.read(sessionControllerProvider.notifier).restore();
    await container.read(accessControllerProvider.notifier).resolve();
    final reg = container.read(registrationControllerProvider.notifier);
    reg.hydrateFromAccess(base);
    reg.updateBranchDraft(
      name: 'Branch A',
      phone: '0550111222',
      address: 'Rue 1',
    );
    expect(
      container.read(registrationControllerProvider).hasValidConfirmedLocation,
      isFalse,
    );
    await reg.saveEstablishmentAndContinue();
    expect(
      container.read(registrationControllerProvider).errorMessage,
      AppStrings.regLocationRequired,
    );

    reg.confirmLocationDraft(latitude: 35.2, longitude: -0.63);
    final s = container.read(registrationControllerProvider);
    expect(s.hasValidConfirmedLocation, isTrue);
    expect(s.branchLatDraft, '35.2');
    expect(s.branchLngDraft, '-0.63');
    expect(s.locationConfirmed, isTrue);

    reg.confirmLocationDraft(latitude: 200, longitude: 0);
    expect(
      container.read(registrationControllerProvider).errorMessage,
      AppStrings.regCoordsInvalid,
    );
    expect(
      container.read(registrationControllerProvider).branchLatDraft,
      '35.2',
    );
  });

  test('hydrate preserves saved branch location as confirmed', () {
    final withBranch = membership(
      status: 'PENDING_REVIEW',
      approved: false,
      merchantId: 'm-b',
      branches: [
        MerchantBranch(
          id: 'b1',
          name: 'Finjan Centre',
          phone: '0550000001',
          addressText: 'Alger',
          latitude: 36.75,
          longitude: 3.05,
          operationalStatus: 'ACTIVE',
        ),
      ],
    ).copyWithName('Finjan');
    final container = _authed(
      FakeMerchantApi(
        meHandler: () async => MerchantMe(
          merchantMembershipExists: true,
          memberships: [withBranch],
        ),
      ),
    );
    addTearDown(container.dispose);
    container.read(registrationControllerProvider.notifier).hydrateFromAccess(
          withBranch,
        );
    final state = container.read(registrationControllerProvider);
    expect(state.locationConfirmed, isTrue);
    expect(state.branchLatDraft, '36.75');
    expect(state.branchLngDraft, '3.05');
    expect(state.branchNameDraft, 'Finjan Centre');
  });

  testWidgets('address card shows cover thumb and hides coords when address set',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          locationClientProvider.overrideWithValue(
            _FakeLocationClient(LocationAccess.granted),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const LocationPickerScreen(
            initialLatitude: 36.7538,
            initialLongitude: 3.0588,
            branchLabel: 'Comptoir Essai',
            addressHint: '12 rue Larbi Ben M’hidi',
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byKey(const Key('merchant-location-address-card')), findsOneWidget);
    expect(find.byKey(const Key('merchant-location-cover-thumb')), findsOneWidget);
    expect(find.text('Comptoir Essai'), findsOneWidget);
    expect(find.text('12 rue Larbi Ben M’hidi'), findsOneWidget);
    // Coordinates stay in the tree for a11y but are not painted as body text.
    expect(find.byKey(const Key('merchant-location-draft-coords')), findsOneWidget);
    expect(find.textContaining('36.75380'), findsNothing);
  });

  testWidgets('coords stay visible when only the branch label is set',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          locationClientProvider.overrideWithValue(
            _FakeLocationClient(LocationAccess.granted),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const LocationPickerScreen(
            initialLatitude: 36.7538,
            initialLongitude: 3.0588,
            branchLabel: 'Comptoir Essai',
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.textContaining('36.75380'), findsOneWidget);
  });
}
