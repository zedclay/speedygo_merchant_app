import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speedygo_merchant_app/core/constants/app_strings.dart';
import 'package:speedygo_merchant_app/core/widgets/searchable_admin_picker.dart';
import 'package:speedygo_merchant_app/features/access/data/geo_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final wilayas = [
    const AlgeriaWilaya(code: '16', nameFr: 'Alger', nameAr: 'الجزائر'),
    const AlgeriaWilaya(code: '31', nameFr: 'Oran', nameAr: 'وهران'),
  ];

  testWidgets('admin select fields usable at enlarged text on SE-sized surface',
      (tester) async {
    tester.view.physicalSize = const Size(750, 1334); // SE-ish logical*2
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.6)),
          child: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  AdminLocationSelectField(
                    key: const Key('t-wilaya'),
                    label: AppStrings.storeAddressWilaya,
                    valueText: '16 — Alger',
                    enabled: true,
                    onTap: () {},
                  ),
                  const SizedBox(height: 12),
                  AdminLocationSelectField(
                    key: const Key('t-commune'),
                    label: AppStrings.storeAddressCommune,
                    valueText: null,
                    enabled: false,
                    onTap: null,
                    hint: AppStrings.adminLocationWilayaRequired,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('t-wilaya')), findsOneWidget);
    expect(find.byKey(const Key('t-commune')), findsOneWidget);
    expect(tester.takeException(), isNull);

    final overflowables = tester.widgetList<Text>(find.byType(Text));
    for (final _ in overflowables) {
      // Pump completed without exceptions → no hard overflow failure.
    }
  });

  testWidgets('searchable picker filters wilayas', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () {
                    showSearchableAdminPicker<AlgeriaWilaya>(
                      context: context,
                      title: AppStrings.storeAddressWilaya,
                      options: wilayas,
                      labelOf: (w) => w.displayLabel,
                      searchTextOf: (w) => '${w.code} ${w.nameFr}',
                    );
                  },
                  child: const Text('open'),
                ),
              ),
            );
          },
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Ora');
    await tester.pumpAndSettle();
    expect(find.textContaining('Oran'), findsOneWidget);
    expect(find.textContaining('Alger'), findsNothing);
  });
}
