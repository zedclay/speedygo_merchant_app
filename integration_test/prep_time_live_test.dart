import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:speedygo_merchant_app/app/app.dart';
import 'package:speedygo_merchant_app/core/constants/app_strings.dart';

/// Live prep-time UI on Dar El Bahja.
///
/// Navigation rule: open orders via the visible list card only
/// (`order-card-<id>`), after selecting the matching status filter.
/// Do not deep-link to detail.
///
/// Dart-defines:
/// - PREP_ACCEPT_ORDER_ID — PENDING_ACCEPTANCE order for accept flow
/// - PREP_COLD_ORDER_ID — already-accepted order with estimate (cold relaunch)
/// - PREP_LIVE_MODE = accept | cold | a11y
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const phoneLocal = String.fromEnvironment(
    'PREP_LIVE_PHONE',
    defaultValue: '550000071',
  );
  const acceptId = String.fromEnvironment('PREP_ACCEPT_ORDER_ID');
  const coldId = String.fromEnvironment('PREP_COLD_ORDER_ID');
  const mode = String.fromEnvironment('PREP_LIVE_MODE', defaultValue: 'accept');
  const otpFilePath = String.fromEnvironment(
    'PREP_OTP_FILE',
    defaultValue: '/Users/mac/.speedygo/dev/otp-last',
  );
  const shotMarker = '/tmp/prep_host_shot.txt';
  final outDir = Directory(
    '/Users/mac/Downloads/speedygo_project/apps/merchant_app/audit/phase-5-ui/prep-time-live',
  )..createSync(recursive: true);

  final steps = <Map<String, dynamic>>[];

  void record(String id, String status, {String? detail}) {
    steps.add({
      'id': id,
      'status': status,
      'detail': detail,
      'layer': 'automated_integration',
      'mode': mode,
      'fixture': 'Dar El Bahja',
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
    File(shotMarker).writeAsStringSync('$tag\n');
    await Future<void>.delayed(const Duration(seconds: 3));
  }

  Future<String> waitForFreshOtp(DateTime after) async {
    final file = File(otpFilePath);
    for (var i = 0; i < 60; i++) {
      if (file.existsSync() && !file.lastModifiedSync().isBefore(after)) {
        final otp = file.readAsStringSync().trim();
        if (RegExp(r'^\d{4,8}$').hasMatch(otp)) return otp;
      }
      await Future<void>.delayed(const Duration(milliseconds: 250));
    }
    throw StateError('OTP not found');
  }

  Future<void> reachHome(WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: SpeedyGoApp()));
    await pumpFrames(tester, const Duration(seconds: 8));
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
      await tester.enterText(find.byType(TextField).first, phoneLocal);
      await tester.pump(const Duration(milliseconds: 400));
      final otpBefore = DateTime.now().subtract(const Duration(seconds: 1));
      await tester.tap(find.byKey(const Key('merchant-phone-continue')));
      await pumpFrames(tester, const Duration(seconds: 4));
      expect(find.byKey(const Key('merchant-otp-field')), findsOneWidget);
      final otp = await waitForFreshOtp(otpBefore);
      await tester.enterText(find.byKey(const Key('merchant-otp-field')), otp);
      await tester.tap(find.byKey(const Key('merchant-otp-verify')));
      await pumpFrames(tester, const Duration(seconds: 10));
    }
    expect(find.textContaining('Dar El Bahja'), findsWidgets);
  }

  Future<void> openOrdersTab(WidgetTester tester) async {
    final tab = find.text(AppStrings.tabOrders);
    expect(tab, findsWidgets, reason: 'Orders tab must be visible');
    await tester.tap(tab.last);
    await pumpFrames(tester, const Duration(seconds: 4));
  }

  /// Select status filter then tap the visible order card (scroll if needed).
  Future<void> openOrderViaCard(
    WidgetTester tester, {
    required String orderId,
    required String filterName,
  }) async {
    await openOrdersTab(tester);

    final filterKey = Key('orders-filter-$filterName');
    final filter = find.byKey(filterKey);
    expect(filter, findsOneWidget, reason: 'filter $filterName must exist');
    await tester.ensureVisible(filter);
    await tester.tap(filter);
    await pumpFrames(tester, const Duration(seconds: 4));

    final refresh = find.byKey(const Key('orders-refresh'));
    if (refresh.evaluate().isNotEmpty) {
      await tester.tap(refresh);
      await pumpFrames(tester, const Duration(seconds: 3));
    }

    final card = find.byKey(Key('order-card-$orderId'));
    // Scroll until the card appears (infinite list load-more is scroll-triggered).
    for (var i = 0; i < 15; i++) {
      if (card.evaluate().isNotEmpty) break;
      final list = find.byType(Scrollable);
      if (list.evaluate().isEmpty) break;
      await tester.drag(list.first, const Offset(0, -450));
      await pumpFrames(tester, const Duration(milliseconds: 900));
    }
    expect(
      card,
      findsOneWidget,
      reason: 'order-card-$orderId must appear under filter=$filterName',
    );
    await tester.ensureVisible(card);
    await tester.tap(card);
    await pumpFrames(tester, const Duration(seconds: 4));
  }

  void writeProvenance({String? error}) {
    File('${outDir.path}/PREP_TIME_LIVE_PROVENANCE_$mode.json').writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert({
        'fixture': 'Dar El Bahja',
        'phone': '+213$phoneLocal',
        'mode': mode,
        'acceptOrderId': acceptId.isEmpty ? null : acceptId,
        'coldOrderId': coldId.isEmpty ? null : coldId,
        'harnessResult': error == null ? 'PASS' : 'FAIL',
        'steps': steps,
        if (error != null) 'error': error,
      }),
    );
  }

  testWidgets('prep-time live mode=$mode', (tester) async {
    try {
      if (mode == 'a11y') {
        // Enlarged text for reachability of sheet controls.
        tester.platformDispatcher.textScaleFactorTestValue = 1.35;
        addTearDown(() {
          tester.platformDispatcher.clearTextScaleFactorTestValue();
        });
      }

      await reachHome(tester);
      record('home_loaded', 'PASS');

      if (mode == 'accept' || mode == 'a11y') {
        expect(acceptId.isNotEmpty, isTrue);
        await openOrderViaCard(
          tester,
          orderId: acceptId,
          filterName: 'incoming',
        );
        record('open_via_incoming_card', 'PASS');

        expect(find.byKey(const Key('order-accept')), findsOneWidget);
        await tester.ensureVisible(find.byKey(const Key('order-accept')));
        await tester.tap(find.byKey(const Key('order-accept')));
        await pumpFrames(tester, const Duration(seconds: 2));
        expect(find.byKey(const Key('accept-prep-sheet')), findsOneWidget);
        record('accept_sheet', 'PASS');
        await markShot(mode == 'a11y' ? 'prep-a11y-accept-sheet' : 'prep-accept-sheet');

        await tester.ensureVisible(find.byKey(const Key('prep-minutes-25')));
        await tester.tap(find.byKey(const Key('prep-minutes-25')));
        await pumpFrames(tester, const Duration(milliseconds: 500));
        await tester.ensureVisible(find.byKey(const Key('accept-prep-confirm')));
        await tester.tap(find.byKey(const Key('accept-prep-confirm')));
        await pumpFrames(tester, const Duration(seconds: 6));
        expect(find.byKey(const Key('prep-countdown-banner')), findsOneWidget);
        record('accept_with_estimate_ui', 'PASS');
        await markShot(mode == 'a11y' ? 'prep-a11y-countdown' : 'prep-countdown');

        // Leave detail → reopen via Accepted filter card (normal navigation).
        await tester.tap(find.byKey(const Key('order-detail-back')));
        await pumpFrames(tester, const Duration(seconds: 2));
        await openOrderViaCard(
          tester,
          orderId: acceptId,
          filterName: 'accepted',
        );
        expect(find.byKey(const Key('prep-countdown-banner')), findsOneWidget);
        record('reopen_via_accepted_card', 'PASS');
        await markShot(mode == 'a11y' ? 'prep-a11y-reopen' : 'prep-reopen');

        await tester.ensureVisible(find.byKey(const Key('prep-update-open')));
        await tester.tap(find.byKey(const Key('prep-update-open')));
        await pumpFrames(tester, const Duration(seconds: 2));
        expect(find.byKey(const Key('update-prep-sheet')), findsOneWidget);
        record('update_sheet', 'PASS');
        await markShot(mode == 'a11y' ? 'prep-a11y-update-sheet' : 'prep-update-sheet');

        await tester.ensureVisible(find.byKey(const Key('prep-add-10')));
        await tester.tap(find.byKey(const Key('prep-add-10')));
        await pumpFrames(tester, const Duration(milliseconds: 400));
        await tester.ensureVisible(find.byKey(const Key('prep-update-confirm')));
        await tester.tap(find.byKey(const Key('prep-update-confirm')));
        await pumpFrames(tester, const Duration(seconds: 5));
        expect(find.byKey(const Key('prep-countdown-banner')), findsOneWidget);
        record('update_estimate_ui', 'PASS');
        await markShot(mode == 'a11y' ? 'prep-a11y-after-update' : 'prep-after-update');
      } else if (mode == 'cold') {
        expect(coldId.isNotEmpty, isTrue);
        await openOrderViaCard(
          tester,
          orderId: coldId,
          filterName: 'accepted',
        );
        expect(find.byKey(const Key('prep-countdown-banner')), findsOneWidget);
        record('cold_reopen_via_accepted_card', 'PASS');
        await markShot('prep-cold-reopen');
        // Capture remaining label for non-reset proof (host compares timestamps).
        File('${outDir.path}/PREP_COLD_UI_NOTE.txt').writeAsStringSync(
          'coldOrderId=$coldId bannerVisible=true at=${DateTime.now().toUtc().toIso8601String()}\n',
        );
      } else {
        fail('Unknown PREP_LIVE_MODE=$mode');
      }

      writeProvenance();
    } catch (e, st) {
      record('fatal', 'FAIL', detail: '$e\n$st');
      writeProvenance(error: e.toString());
      rethrow;
    }
  });
}
