import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:speedygo_merchant_app/app/app.dart';
import 'package:speedygo_merchant_app/core/constants/app_strings.dart';
import 'package:speedygo_merchant_app/core/money/money_format.dart';
import 'package:speedygo_merchant_app/features/access/application/access_controller.dart';
import 'package:speedygo_merchant_app/features/reports/application/sales_report_controller.dart';

/// Owner → logout → STAFF → logout → owner on one app process, against the
/// local dev backend and the isolated fixture from
/// `audit/phase-5-ui/financial-visibility/seed_financial_visibility_fixture.sql`.
///
/// Screenshots are taken by a host watcher reading [shotMarker] (simctl).
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const ownerPhone = '550000071';
  const staffPhone = '550000081';
  const orderId = String.fromEnvironment('FINVIS_ORDER_ID');
  const otpFilePath = String.fromEnvironment(
    'FINVIS_OTP_FILE',
    defaultValue: '/Users/mac/.speedygo/dev/otp-last',
  );
  const prefix = String.fromEnvironment(
    'FINVIS_SHOT_PREFIX',
    defaultValue: 'live',
  );
  const device = String.fromEnvironment('FINVIS_DEVICE', defaultValue: '');
  const restoreOnly = bool.fromEnvironment('FINVIS_RESTORE_ONLY');
  const shotMarker = '/tmp/finvis_live_shot.txt';
  final outDir = Directory(
    '/Users/mac/Downloads/speedygo_project/apps/merchant_app/audit/phase-5-ui/financial-visibility/live',
  )..createSync(recursive: true);

  final ownerNet = MoneyFormat.dzd('232500');
  final ownerCommission = MoneyFormat.dzd('17500');
  final ownerDiscount = MoneyFormat.dzd('5000');
  final orderGross = MoneyFormat.dzd('255000');
  final reportsNet = MoneyFormat.dzd('111600');
  final reportsCommission = MoneyFormat.dzdDeduction('8400');
  final reportsGross = MoneyFormat.dzd('120000');
  final ownerOnlyTexts = [ownerNet, ownerCommission, ownerDiscount, reportsNet];

  final steps = <Map<String, Object?>>[];
  final observed = <String, Object?>{};
  var staffFramesChecked = 0;

  void record(String id, String status, [Object? detail]) {
    steps.add({
      'id': id,
      'status': status,
      'detail': detail,
      'at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  bool ownerFinanceVisible() =>
      ownerOnlyTexts.any((t) => find.text(t).evaluate().isNotEmpty) ||
      find.text(reportsCommission).evaluate().isNotEmpty;

  /// While a non-owner identity is active, every pumped frame is checked.
  var guardOwnerFinance = false;

  Future<void> pumpFrames(WidgetTester tester, Duration total) async {
    final end = DateTime.now().add(total);
    while (DateTime.now().isBefore(end)) {
      await tester.pump(const Duration(milliseconds: 100));
      if (guardOwnerFinance) {
        staffFramesChecked++;
        if (ownerFinanceVisible()) {
          throw TestFailure('owner financial value visible in a non-owner frame');
        }
      }
    }
  }

  Future<void> waitFor(
    WidgetTester tester,
    Finder finder, {
    Duration timeout = const Duration(seconds: 25),
  }) async {
    final end = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(end)) {
      await pumpFrames(tester, const Duration(milliseconds: 200));
      if (finder.evaluate().isNotEmpty) return;
    }
    throw TestFailure('Timed out waiting for $finder');
  }

  Future<void> markShot(WidgetTester tester, String tag) async {
    await pumpFrames(tester, const Duration(milliseconds: 1200));
    File(shotMarker).writeAsStringSync('${prefix}_$tag\n');
    await pumpFrames(tester, const Duration(seconds: 3));
  }

  Future<String> waitForFreshOtp(DateTime after) async {
    final file = File(otpFilePath);
    for (var i = 0; i < 80; i++) {
      if (file.existsSync() && !file.lastModifiedSync().isBefore(after)) {
        final otp = file.readAsStringSync().trim();
        if (RegExp(r'^\d{4,8}$').hasMatch(otp)) return otp;
      }
      await Future<void>.delayed(const Duration(milliseconds: 250));
    }
    throw StateError('OTP not found');
  }

  final alertFinder = find.byKey(const Key('incoming-order-alert'));
  final refuseFinder = find.byKey(const Key('incoming-alert-refuse'));
  final detailsFinder = find.byKey(const Key('incoming-alert-details'));

  ProviderContainer containerOf(WidgetTester tester) =>
      ProviderScope.containerOf(tester.element(find.byType(MaterialApp).first));

  Finder listOf(String key) => find
      .descendant(of: find.byKey(Key(key)), matching: find.byType(Scrollable))
      .first;

  Future<void> login(WidgetTester tester, String phone) async {
    await waitFor(tester, find.byKey(const Key('merchant-phone-continue')));
    await tester.enterText(find.byType(TextField).first, phone);
    await pumpFrames(tester, const Duration(milliseconds: 400));
    final otpBefore = DateTime.now().subtract(const Duration(seconds: 1));
    await tester.tap(find.byKey(const Key('merchant-phone-continue')));
    await waitFor(tester, find.byKey(const Key('merchant-otp-field')));
    final otp = await waitForFreshOtp(otpBefore);
    await tester.enterText(find.byKey(const Key('merchant-otp-field')), otp);
    await pumpFrames(tester, const Duration(milliseconds: 800));
    await tester.tap(find.byKey(const Key('merchant-otp-verify')));
    await pumpFrames(tester, const Duration(seconds: 6));
    if (find.byKey(const Key('merchant-otp-verify')).evaluate().isNotEmpty &&
        find.byKey(const Key('home-branch-name')).evaluate().isEmpty) {
      await tester.tap(find.byKey(const Key('merchant-otp-verify')));
      await pumpFrames(tester, const Duration(seconds: 6));
    }
    final branchTile = find.textContaining('Dar El Bahja');
    if (find.byKey(const Key('home-branch-name')).evaluate().isEmpty &&
        branchTile.evaluate().isNotEmpty) {
      await tester.tap(branchTile.first);
      await pumpFrames(tester, const Duration(seconds: 3));
    }
    await waitFor(tester, find.byKey(const Key('home-branch-name')));
  }

  Future<void> reachOwnerHome(
    WidgetTester tester,
    Future<void> Function(WidgetTester) signOut,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: SpeedyGoApp()));
    await pumpFrames(tester, const Duration(seconds: 4));
    final end = DateTime.now().add(const Duration(seconds: 40));
    while (DateTime.now().isBefore(end) &&
        find.byKey(const Key('home-branch-name')).evaluate().isEmpty &&
        find.byKey(const Key('merchant-phone-continue')).evaluate().isEmpty) {
      await tester.pump(const Duration(milliseconds: 250));
    }
    final existingRole = find
            .byKey(const Key('home-branch-name'))
            .evaluate()
            .isEmpty
        ? null
        : containerOf(tester).read(accessControllerProvider).membership?.role;
    if (existingRole == 'OWNER') {
      record('owner_login', 'PASS', 'existing Dar El Bahja owner session');
      return;
    }
    if (existingRole != null) {
      await signOut(tester);
      record('prior_session_signed_out', 'PASS', existingRole);
    }
    await login(tester, ownerPhone);
    record('owner_login', 'PASS', 'OTP login (dev OTP file)');
  }

  String? role(WidgetTester tester) =>
      containerOf(tester).read(accessControllerProvider).membership?.role;

  /// The pending fixture order raises the incoming-order alert over the shell.
  Future<bool> dismissIncomingAlert(WidgetTester tester, {String? shot}) async {
    final dismiss = find.byKey(const Key('incoming-alert-dismiss'));
    if (dismiss.evaluate().isEmpty) return false;
    if (shot != null) await markShot(tester, shot);
    await tester.tap(dismiss.first);
    await pumpFrames(tester, const Duration(milliseconds: 800));
    return true;
  }

  Future<void> logout(WidgetTester tester) async {
    await dismissIncomingAlert(tester);
    await tester.tap(find.byKey(const Key('nav-profile')));
    final gear = find.byKey(const Key('store-profile-gear'));
    final profile = find.byKey(const Key('profile-screen'));
    await waitFor(tester, gear);
    for (var attempt = 0; attempt < 5 && profile.evaluate().isEmpty; attempt++) {
      // Tab switch animates the gear in from off-screen; tap once it settled.
      await pumpFrames(tester, const Duration(milliseconds: 1200));
      if (gear.evaluate().isNotEmpty) {
        await tester.tap(gear, warnIfMissed: false);
      }
      await pumpFrames(tester, const Duration(milliseconds: 1200));
    }
    await waitFor(tester, profile);
    await tester.scrollUntilVisible(
      find.byKey(const Key('merchant-logout')),
      300,
      scrollable: listOf('profile-screen'),
    );
    await tester.tap(find.byKey(const Key('merchant-logout')));
    await pumpFrames(tester, const Duration(milliseconds: 800));
    await tester.tap(find.text(AppStrings.logoutConfirmAction).last);
    await waitFor(tester, find.byKey(const Key('merchant-phone-continue')));
  }

  Future<void> openFixtureOrder(WidgetTester tester) async {
    await dismissIncomingAlert(tester);
    final navHome = find.byKey(const Key('nav-home'));
    if (navHome.evaluate().isNotEmpty) {
      await tester.tap(navHome);
      await pumpFrames(tester, const Duration(seconds: 1));
    }
    await dismissIncomingAlert(tester);
    final card = find.byKey(const Key('home-order-card-$orderId'));
    await waitFor(tester, card);
    await tester.ensureVisible(card);
    await pumpFrames(tester, const Duration(milliseconds: 300));
    await tester.tap(card);
    await waitFor(tester, find.byKey(const Key('order-detail-ref')));
    await waitFor(tester, find.text('Couscous royal'));
  }

  Future<void> scrollToFinance(WidgetTester tester) async {
    await tester.scrollUntilVisible(
      find.text(AppStrings.orderFinanceTitle),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -220));
    await pumpFrames(tester, const Duration(milliseconds: 500));
  }

  Future<void> openReports(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('order-detail-back')));
    await pumpFrames(tester, const Duration(seconds: 1));
    await dismissIncomingAlert(tester);
    await tester.tap(find.byKey(const Key('nav-reports')));
    await waitFor(tester, find.byKey(const Key('reports-screen')));
    final end = DateTime.now().add(const Duration(seconds: 20));
    while (DateTime.now().isBefore(end)) {
      await pumpFrames(tester, const Duration(milliseconds: 200));
      final v = containerOf(tester).read(salesReportControllerProvider);
      if (!v.isLoading && v.hasValue && v.value != null) return;
    }
    throw TestFailure('sales report did not settle');
  }

  void writeProvenance({Object? error}) {
    File('${outDir.path}/FINVIS_LIVE_PROVENANCE_$prefix.json').writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert({
        'layer': 'live_authenticated_ui',
        'fixture':
            'Dar El Bahja synthetic owner (+213$ownerPhone), isolated STAFF '
            '(+213$staffPhone), sgo_finvis_* orders in speedygo_dev',
        'orderId': orderId,
        'device': device,
        'backend': 'local dev backend http://127.0.0.1:3000',
        'result': error == null ? 'PASS' : 'FAIL',
        'error': error?.toString(),
        'staffFramesCheckedForOwnerFinance': staffFramesChecked,
        'observed': observed,
        'steps': steps,
      }),
    );
  }

  testWidgets('owner vs STAFF financial visibility, same app process', (
    tester,
  ) async {
    if (restoreOnly) {
      // Only re-establishes the fixture owner session (e.g. after an OTP
      // rate limit interrupted the final restore step).
      await reachOwnerHome(tester, logout);
      expect(role(tester), 'OWNER');
      record('owner_restored', 'PASS', 'restore-only run');
      writeProvenance();
      return;
    }
    expect(orderId, isNotEmpty, reason: 'FINVIS_ORDER_ID dart-define');
    try {
      // 1. OWNER.
      await reachOwnerHome(tester, logout);
      expect(role(tester), 'OWNER');
      await waitFor(tester, alertFinder);
      expect(refuseFinder, findsOneWidget);
      expect(
        tester.widget<ButtonStyleButton>(refuseFinder).onPressed,
        isNotNull,
      );
      expect(detailsFinder, findsOneWidget);
      record('owner_incoming_alert', 'PASS', 'view and refuse offered');
      await dismissIncomingAlert(tester, shot: '00_owner_incoming_alert');
      await openFixtureOrder(tester);
      expect(find.byKey(const Key('order-accept')), findsOneWidget);
      await markShot(tester, '01_owner_order_detail');
      await scrollToFinance(tester);
      expect(find.text(ownerNet), findsOneWidget);
      expect(find.text(ownerCommission), findsOneWidget);
      expect(find.text(ownerDiscount), findsOneWidget);
      expect(find.byKey(const Key('order-finance-restricted')), findsNothing);
      record('owner_order_detail', 'PASS', {
        'net': ownerNet,
        'commission': ownerCommission,
        'discount': ownerDiscount,
      });
      await markShot(tester, '02_owner_order_finance');

      await openReports(tester);
      await tester.scrollUntilVisible(
        find.byKey(const Key('reports-finance-section')),
        250,
        scrollable: listOf('reports-screen'),
      );
      await pumpFrames(tester, const Duration(milliseconds: 500));
      expect(find.text(reportsNet), findsOneWidget);
      expect(find.text(reportsCommission), findsOneWidget);
      record('owner_reports', 'PASS', {'net': reportsNet});
      await markShot(tester, '03_owner_reports_finance');

      // 2. Sign out, sign in as the isolated STAFF member.
      await logout(tester);
      record('owner_logout', 'PASS');
      guardOwnerFinance = true;
      await login(tester, staffPhone);
      expect(role(tester), 'STAFF');
      record('staff_login', 'PASS', 'OTP login (dev OTP file)');
      await waitFor(tester, alertFinder);
      expect(refuseFinder, findsNothing);
      expect(find.text(AppStrings.alertRefuse), findsNothing);
      expect(detailsFinder, findsOneWidget);
      record('staff_incoming_alert', 'PASS', 'view offered, refuse absent');
      await markShot(tester, '04_staff_incoming_alert');
      // STAFF order-read path: the alert's view action opens the detail.
      await tester.tap(detailsFinder);
      await waitFor(tester, find.byKey(const Key('order-detail-ref')));
      await waitFor(tester, find.text('Couscous royal'));
      record('staff_alert_view_details', 'PASS');
      expect(find.byKey(const Key('order-accept')), findsNothing);
      expect(find.byKey(const Key('order-reject')), findsNothing);
      await markShot(tester, '05_staff_order_detail');
      await scrollToFinance(tester);
      expect(find.text(orderGross), findsWidgets);
      expect(find.byKey(const Key('order-finance-restricted')), findsOneWidget);
      expect(find.text(AppStrings.orderFinanceNet), findsNothing);
      expect(find.textContaining('Commission SpeedyGo'), findsNothing);
      expect(find.text(MoneyFormat.dzd('0')), findsNothing);
      record('staff_order_detail', 'PASS', {'gross': orderGross});
      await markShot(tester, '06_staff_order_finance');

      await openReports(tester);
      await tester.scrollUntilVisible(
        find.byKey(const Key('reports-finance-section')),
        250,
        scrollable: listOf('reports-screen'),
      );
      await pumpFrames(tester, const Duration(milliseconds: 500));
      expect(find.text(AppStrings.reportsFinanceRestricted), findsOneWidget);
      expect(find.text(reportsGross), findsWidgets);
      final staffSales = containerOf(
        tester,
      ).read(salesReportControllerProvider).value!;
      observed['staffSales'] = {
        'financeGranted': staffSales.summary.financeGranted,
        'finance': staffSales.summary.finance == null ? null : 'present',
        'gross': staffSales.summary.grossMerchandiseMinor,
      };
      expect(staffSales.summary.financeGranted, isFalse);
      expect(staffSales.summary.finance, isNull);
      record('staff_reports', 'PASS', observed['staffSales']);
      await markShot(tester, '07_staff_reports_finance');

      // 3. Restore the owner session on this fixture device.
      await logout(tester);
      guardOwnerFinance = false;
      await login(tester, ownerPhone);
      expect(role(tester), 'OWNER');
      record('owner_restored', 'PASS');
      await markShot(tester, '99_done');
      writeProvenance();
    } catch (e) {
      writeProvenance(error: e);
      await markShot(tester, '99_done');
      rethrow;
    }
  });
}
