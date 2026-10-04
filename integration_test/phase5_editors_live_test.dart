import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:speedygo_merchant_app/app/app.dart';
import 'package:speedygo_merchant_app/core/constants/app_strings.dart';
import 'package:speedygo_merchant_app/core/widgets/merchant_primary_button.dart';

/// Live Phase 5 editor checks on isolated SE with Dar El Bahja
/// (`+213550000071` / `com.speedygo.speedygoMerchantApp`).
///
/// Distinguishes Merchant UI results from prior API-only provenance.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const phoneLocal = String.fromEnvironment(
    'PHASE5_PHONE',
    defaultValue: '550000071',
  );
  const otpFilePath = String.fromEnvironment(
    'PHASE5_OTP_FILE',
    defaultValue: '/Users/mac/.speedygo/dev/otp-last',
  );
  const simulatorUdid = String.fromEnvironment(
    'PHASE5_SIM_UDID',
    defaultValue: '8DB9007A-B816-4EC5-86ED-C627AC60F2C5',
  );
  const simulatorName = String.fromEnvironment(
    'PHASE5_SIM_NAME',
    defaultValue: 'iPhone 16e',
  );
  const shotMarker = '/tmp/phase5_host_shot.txt';
  final liveDir = Directory(
    '/Users/mac/Downloads/speedygo_project/apps/merchant_app/audit/phase-5-ui/live',
  )..createSync(recursive: true);

  final steps = <Map<String, dynamic>>[];

  void record(String id, String status, {String? detail}) {
    steps.add({
      'id': id,
      'status': status,
      'detail': detail,
      'layer': 'live_merchant_ui',
      'bundleId': 'com.speedygo.speedygoMerchantApp',
      'at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  Future<void> pumpFrames(WidgetTester tester, Duration total) async {
    final end = DateTime.now().add(total);
    while (DateTime.now().isBefore(end)) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> markShot(String tag) async {
    File(shotMarker).writeAsStringSync(tag);
    await Future<void>.delayed(const Duration(seconds: 2));
  }

  Future<String> waitForFreshOtp(DateTime after) async {
    final file = File(otpFilePath);
    for (var i = 0; i < 60; i++) {
      if (file.existsSync() && !file.lastModifiedSync().isBefore(after)) {
        final otp = file.readAsStringSync().trim();
        if (otp.length >= 4) return otp;
      }
      await Future<void>.delayed(const Duration(milliseconds: 250));
    }
    throw StateError('OTP not found in $otpFilePath');
  }

  Future<void> reachHome(WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: SpeedyGoApp()));
    await pumpFrames(tester, const Duration(seconds: 6));

    if (find.byKey(const Key('merchant-language')).evaluate().isNotEmpty) {
      await tester.tap(find.text('Français'));
      await pumpFrames(tester, const Duration(seconds: 2));
    }
    if (find.text(AppStrings.onboardingSkip).evaluate().isNotEmpty) {
      await tester.tap(find.text(AppStrings.onboardingSkip));
      await pumpFrames(tester, const Duration(seconds: 2));
    }
    if (find.text(AppStrings.onboardingStart).evaluate().isNotEmpty) {
      await tester.tap(find.text(AppStrings.onboardingStart));
      await pumpFrames(tester, const Duration(seconds: 2));
    }

    if (find.byKey(const Key('home-branch-name')).evaluate().isEmpty) {
      expect(find.byKey(const Key('merchant-phone-continue')), findsOneWidget);
      final phoneField = find.byType(TextField).first;
      await tester.enterText(phoneField, phoneLocal);
      await tester.pump(const Duration(milliseconds: 400));
      final otpBefore = DateTime.now().subtract(const Duration(seconds: 1));
      await tester.tap(find.byKey(const Key('merchant-phone-continue')));
      await pumpFrames(tester, const Duration(seconds: 3));
      expect(find.byKey(const Key('merchant-otp-field')), findsOneWidget);
      final otp = await waitForFreshOtp(otpBefore);
      await tester.enterText(find.byKey(const Key('merchant-otp-field')), otp);
      await tester.pump(const Duration(milliseconds: 300));
      final verifyBtn = tester.widget<MerchantPrimaryButton>(
        find.byKey(const Key('merchant-otp-verify')),
      );
      expect(verifyBtn.onPressed, isNotNull);
      await tester.tap(find.byKey(const Key('merchant-otp-verify')));
      await pumpFrames(tester, const Duration(seconds: 12));
    }

    expect(find.byKey(const Key('home-branch-name')), findsOneWidget);
    expect(find.textContaining('Dar El Bahja'), findsWidgets);
    expect(find.text('Recherche'), findsNothing);
    expect(find.textContaining('Finjan'), findsNothing);
    record('login_home_dar_el_bahja', 'PASS');
  }

  testWidgets('phase-5 live editors navigation validation save reopen',
      (tester) async {
    await reachHome(tester);
    await markShot('live-home-se');

    // Catalog → create product
    await tester.tap(find.text(AppStrings.tabCatalog));
    await pumpFrames(tester, const Duration(seconds: 3));
    expect(find.byKey(const Key('catalog-screen')), findsOneWidget);
    record('nav_catalog', 'PASS');

    final addProduct = find.text(AppStrings.catalogAddProduct);
    if (addProduct.evaluate().isEmpty) {
      // Empty-state CTA or FAB
      final fab = find.byKey(const Key('catalog-add-fab'));
      if (fab.evaluate().isNotEmpty) {
        await tester.tap(fab);
      } else {
        final emptyAdd = find.byKey(const Key('catalog-empty-add-product'));
        if (emptyAdd.evaluate().isNotEmpty) {
          await tester.tap(emptyAdd);
        } else {
          await tester.tap(find.textContaining('produit').first);
        }
      }
    } else {
      await tester.tap(addProduct.first);
    }
    await pumpFrames(tester, const Duration(seconds: 3));
    expect(find.byKey(const Key('product-editor-screen')), findsOneWidget);
    expect(find.text(AppStrings.catalogSectionInfo), findsOneWidget);
    record('nav_product_create', 'PASS');
    await markShot('live-product-create-se');

    // Field validation (not save-failure banner)
    await tester.ensureVisible(find.byKey(const Key('product-editor-save')));
    await tester.tap(find.byKey(const Key('product-editor-save')));
    await pumpFrames(tester, const Duration(seconds: 2));
    expect(find.text(AppStrings.catalogFieldRequired), findsWidgets);
    expect(find.text(AppStrings.catalogSaveRetryHint), findsNothing);
    record('product_field_validation', 'PASS');
    await markShot('live-product-validation-se');

    // Focus name field (native IME on device; TestTextInput not registered here)
    await tester.ensureVisible(find.byKey(const Key('product-editor-name')));
    await tester.tap(find.byKey(const Key('product-editor-name')));
    await pumpFrames(tester, const Duration(seconds: 1));
    final nameFocused = tester
        .widget<TextField>(find.byKey(const Key('product-editor-name')))
        .focusNode
        ?.hasFocus;
    expect(nameFocused, isTrue);
    record(
      'native_keyboard_focus_name',
      'PASS',
      detail: 'product-editor-name focused on device (native IME path)',
    );
    await markShot('live-product-keyboard-se');

    final probeName =
        'Phase5 UI Probe ${DateTime.now().millisecondsSinceEpoch % 100000}';
    await tester.tap(find.byKey(const Key('product-editor-name')));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.enterText(
      find.byKey(const Key('product-editor-name')),
      probeName,
    );
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text(probeName), findsWidgets);

    await tester.ensureVisible(find.byKey(const Key('product-editor-price')));
    await tester.tap(find.byKey(const Key('product-editor-price')));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.enterText(
      find.byKey(const Key('product-editor-price')),
      '18,50',
    );
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('18,50'), findsWidgets);

    // Dismiss keyboard so sticky save is tappable
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump(const Duration(milliseconds: 400));

    await tester.ensureVisible(find.byKey(const Key('product-editor-save')));
    await tester.tap(find.byKey(const Key('product-editor-save')));
    await pumpFrames(tester, const Duration(seconds: 10));

    if (find.text(AppStrings.catalogSaveRetryHint).evaluate().isNotEmpty) {
      record('product_save', 'FAIL', detail: 'save retry hint visible');
      fail('Product save failed on device');
    }
    if (find.text(AppStrings.catalogFieldRequired).evaluate().isNotEmpty ||
        find.text(AppStrings.catalogPriceInvalid).evaluate().isNotEmpty) {
      record('product_save', 'FAIL', detail: 'client validation still visible');
      fail('Product save blocked by client validation');
    }

    final stillOnEditor =
        find.byKey(const Key('product-editor-screen')).evaluate().isNotEmpty;
    record(
      'product_save',
      'PASS',
      detail: stillOnEditor
          ? 'editor retained after save'
          : 'popped after save',
    );
    await markShot('live-product-after-save-se');

    // Return to catalog list
    if (find.byKey(const Key('catalog-screen')).evaluate().isEmpty) {
      if (find.byKey(const Key('merchant-back')).evaluate().isNotEmpty) {
        await tester.tap(find.byKey(const Key('merchant-back')));
        await pumpFrames(tester, const Duration(seconds: 2));
      }
      if (find.byKey(const Key('catalog-screen')).evaluate().isEmpty) {
        await tester.tap(find.text(AppStrings.tabCatalog));
        await pumpFrames(tester, const Duration(seconds: 3));
      }
    }
    // Pull refresh if available
    final refresh = find.byKey(const Key('catalog-refresh'));
    if (refresh.evaluate().isNotEmpty) {
      await tester.tap(refresh);
      await pumpFrames(tester, const Duration(seconds: 3));
    } else {
      await pumpFrames(tester, const Duration(seconds: 2));
    }

    const expectedPriceMajor = '18,50';
    const expectedPriceMinor = 1850;

    if (find.textContaining(probeName).evaluate().isEmpty) {
      // Scroll catalog looking for the new product
      for (var i = 0; i < 6; i++) {
        await tester.drag(
          find.byKey(const Key('catalog-screen')),
          const Offset(0, -240),
        );
        await tester.pump(const Duration(milliseconds: 300));
        if (find.textContaining(probeName).evaluate().isNotEmpty) break;
      }
    }

    expect(
      find.textContaining(probeName),
      findsWidgets,
      reason: 'Created product must appear in Merchant catalog UI',
    );

    // Resolve exact catalog row key → product ID
    final productRow = find.ancestor(
      of: find.textContaining(probeName).first,
      matching: find.byWidgetPredicate((widget) {
        final key = widget.key;
        if (key is! ValueKey<String>) return false;
        return key.value.startsWith('catalog-product-') &&
            !key.value.contains('available') &&
            !key.value.contains('menu');
      }),
    );
    expect(productRow, findsOneWidget);
    final productId =
        (tester.widget(productRow).key! as ValueKey<String>).value
            .replaceFirst('catalog-product-', '');
    expect(productId, isNotEmpty);

    record(
      'product_save_identity',
      'PASS',
      detail: jsonEncode({
        'productId': productId,
        'expectedName': probeName,
        'expectedPriceMajor': expectedPriceMajor,
        'expectedPriceMinor': expectedPriceMinor,
      }),
    );

    await tester.tap(find.textContaining(probeName).first);
    await pumpFrames(tester, const Duration(seconds: 4));
    expect(find.byKey(const Key('product-editor-screen')), findsOneWidget);

    final reopenedName = tester.widget<TextField>(
      find.byKey(const Key('product-editor-name')),
    );
    final reopenedPrice = tester.widget<TextField>(
      find.byKey(const Key('product-editor-price')),
    );
    expect(reopenedName.controller?.text, probeName);
    expect(reopenedPrice.controller?.text, expectedPriceMajor);
    record(
      'product_reopen',
      'PASS',
      detail: jsonEncode({
        'productId': productId,
        'reopenedName': reopenedName.controller?.text,
        'reopenedPriceMajor': reopenedPrice.controller?.text,
      }),
    );
    await markShot('live-product-reopen-se');

    // Cleanup tied to the same product ID (HTTP DELETE; Finjan untouched)
    final cleaned = await _deleteProductById(productId);
    record(
      'product_cleanup',
      cleaned ? 'PASS' : 'FAIL',
      detail: 'DELETE productId=$productId',
    );
    expect(cleaned, isTrue, reason: 'Cleanup must target productId=$productId');

    await tester.tap(find.byKey(const Key('merchant-back')));
    await pumpFrames(tester, const Duration(seconds: 2));
    // Profile → address
    await tester.tap(find.text(AppStrings.tabProfile));
    await pumpFrames(tester, const Duration(seconds: 3));
    final addressEntry = find.text(AppStrings.storeProfileAddress);
    if (addressEntry.evaluate().isNotEmpty) {
      await tester.tap(addressEntry.first);
      await pumpFrames(tester, const Duration(seconds: 3));
      if (find.byKey(const Key('store-address-screen')).evaluate().isNotEmpty) {
        expect(
          find.text(AppStrings.storeAddressLocationSummary),
          findsOneWidget,
        );
        record('nav_address', 'PASS');
        await markShot('live-address-se');
        await tester.tap(find.byKey(const Key('merchant-back')));
        await pumpFrames(tester, const Duration(seconds: 2));
      } else {
        record('nav_address', 'SKIP', detail: 'address route not opened');
      }
    } else {
      record('nav_address', 'SKIP', detail: 'no address entry on profile');
    }

    File('${liveDir.path}/LIVE_UI_PROVENANCE.json').writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert({
        'ok': true,
        'layer': 'live_merchant_ui',
        'bundleId': 'com.speedygo.speedygoMerchantApp',
        'displayName': 'Speedygo Merchant App',
        'phone': '+213$phoneLocal',
        'merchant': 'Dar El Bahja',
        'simulatorUdid': simulatorUdid,
        'simulator': simulatorName,
        'entrypoint': 'integration_test/phase5_editors_live_test.dart',
        'finjanUntouched': true,
        'customerAppUntouched': true,
        'remoteMediaRead':
            'UNRESOLVED — no authorized merchant read route verified',
        'steps': steps,
        'at': DateTime.now().toUtc().toIso8601String(),
      }),
    );
    record('provenance_written', 'PASS');
  });
}

Future<bool> _deleteProductById(String productId) async {
  const api = 'http://127.0.0.1:3000/api/v1';
  const phone = '+213550000071';
  const mid = '0d00c071-d000-7000-8000-000000010001';
  final otpFile = File('/Users/mac/.speedygo/dev/otp-last');

  Future<Map<String, dynamic>> postJson(String path, Map<String, dynamic> body) async {
    final client = HttpClient();
    try {
      final req = await client.postUrl(Uri.parse('$api$path'));
      req.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
      req.write(jsonEncode(body));
      final res = await req.close();
      final text = await res.transform(utf8.decoder).join();
      if (res.statusCode >= 400) {
        throw StateError('POST $path -> ${res.statusCode} $text');
      }
      return text.isEmpty ? <String, dynamic>{} : jsonDecode(text) as Map<String, dynamic>;
    } finally {
      client.close(force: true);
    }
  }

  await postJson('/auth/otp/request', {
    'channel': 'PHONE',
    'identifier': phone,
    'purpose': 'AUTHENTICATE',
  });
  await Future<void>.delayed(const Duration(milliseconds: 400));
  final otp = otpFile.readAsStringSync().trim();
  final tokens = await postJson('/auth/otp/verify', {
    'channel': 'PHONE',
    'identifier': phone,
    'purpose': 'AUTHENTICATE',
    'code': otp,
    'platform': 'ios',
    'appVersion': '0.0.0-phase5-cleanup',
  });
  final access = tokens['accessToken'] as String;

  final client = HttpClient();
  try {
    final req = await client.deleteUrl(
      Uri.parse('$api/merchant/$mid/products/$productId'),
    );
    req.headers.set(HttpHeaders.authorizationHeader, 'Bearer $access');
    final res = await req.close();
    await res.drain<void>();
    return res.statusCode >= 200 && res.statusCode < 300;
  } finally {
    client.close(force: true);
  }
}
