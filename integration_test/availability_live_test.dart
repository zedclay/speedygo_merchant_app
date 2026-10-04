import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:speedygo_merchant_app/app/app.dart';
import 'package:speedygo_merchant_app/core/constants/app_strings.dart';
import 'package:speedygo_merchant_app/core/navigation/app_routes.dart';

/// Live availability UI proof on iPhone 16e / Dar El Bahja.
/// Does not touch Finjan (17 Pro). Host screenshot watcher uses [shotMarker].
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const phoneLocal = String.fromEnvironment(
    'AVAIL_LIVE_PHONE',
    defaultValue: '550000071',
  );
  const otpFilePath = String.fromEnvironment(
    'AVAIL_OTP_FILE',
    defaultValue: '/Users/mac/.speedygo/dev/otp-last',
  );
  const shotMarker = '/tmp/avail_host_shot.txt';
  final outDir = Directory(
    '/Users/mac/Downloads/speedygo_project/apps/merchant_app/audit/phase-5-ui/availability-live',
  )..createSync(recursive: true);

  final steps = <Map<String, dynamic>>[];

  void record(String id, String status, {String? detail}) {
    steps.add({
      'id': id,
      'status': status,
      'detail': detail,
      'layer': 'live_merchant_ui',
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
    File(shotMarker).writeAsStringSync(tag);
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
      await tester.tap(find.byKey(const Key('merchant-otp-continue')));
      await pumpFrames(tester, const Duration(seconds: 10));
    }
    if (find.textContaining('Dar El Bahja').evaluate().isEmpty) {
      // Leftover session — logout via profile settings if needed.
      final profileTab = find.text(AppStrings.tabProfile);
      if (profileTab.evaluate().isNotEmpty) {
        await tester.tap(profileTab);
        await pumpFrames(tester, const Duration(seconds: 2));
        if (find.byKey(const Key('store-profile-settings')).evaluate().isNotEmpty) {
          await tester.tap(find.byKey(const Key('store-profile-settings')));
          await pumpFrames(tester, const Duration(seconds: 2));
        }
        if (find.text(AppStrings.logoutConfirmAction).evaluate().isNotEmpty ||
            find.textContaining('Déconnexion').evaluate().isNotEmpty) {
          final logout = find.textContaining('Déconnexion');
          await tester.tap(logout.last);
          await pumpFrames(tester, const Duration(seconds: 2));
          final confirm = find.text(AppStrings.logoutConfirmAction);
          if (confirm.evaluate().isNotEmpty) {
            await tester.tap(confirm);
            await pumpFrames(tester, const Duration(seconds: 4));
          }
        }
      }
      await reachHome(tester);
      return;
    }
    expect(find.textContaining('Dar El Bahja'), findsWidgets);
  }

  testWidgets('availability live screens Dar El Bahja', (tester) async {
    try {
      await reachHome(tester);
      record('home_loaded', 'PASS');
      await markShot('avail-home-badge');

      // Open availability via profile nav
      await tester.tap(find.text(AppStrings.tabProfile));
      await pumpFrames(tester, const Duration(seconds: 3));
      await markShot('avail-profile');

      expect(find.byKey(const Key('store-profile-availability')), findsOneWidget);
      await tester.tap(find.byKey(const Key('store-profile-availability')));
      await pumpFrames(tester, const Duration(seconds: 4));
      expect(find.byKey(const Key('store-availability-screen')), findsOneWidget);
      record('availability_screen', 'PASS');
      await markShot('avail-etat-magasin');

      // Segment Fermé then save
      await tester.tap(find.byKey(const Key('availability-seg-closed')));
      await pumpFrames(tester, const Duration(seconds: 1));
      await tester.tap(find.byKey(const Key('availability-save')));
      await pumpFrames(tester, const Duration(seconds: 5));
      record('save_force_closed', 'PASS');
      await markShot('avail-force-closed');

      // Temporary closure 30m
      await tester.tap(find.byKey(const Key('availability-pause-30')));
      await pumpFrames(tester, const Duration(seconds: 4));
      expect(find.byKey(const Key('temporary-closure-screen')), findsOneWidget);
      record('temporary_screen', 'PASS');
      await markShot('avail-fermeture-temp');

      await tester.tap(find.byKey(const Key('temporary-closure-confirm')));
      await pumpFrames(tester, const Duration(seconds: 5));
      record('confirm_temporary', 'PASS');
      await markShot('avail-after-temp');

      // Reopen follow schedule
      if (find.byKey(const Key('store-availability-screen')).evaluate().isEmpty) {
        final ctx = tester.element(find.byType(MaterialApp).first);
        GoRouter.of(ctx).go(AppRoutes.storeAvailability);
        await pumpFrames(tester, const Duration(seconds: 3));
      }
      await tester.tap(find.byKey(const Key('availability-seg-follow')));
      await pumpFrames(tester, const Duration(seconds: 1));
      await tester.tap(find.byKey(const Key('availability-save')));
      await pumpFrames(tester, const Duration(seconds: 5));
      // May show outside-hours dialog
      if (find.text(AppStrings.availabilityConfirmReopen).evaluate().isNotEmpty) {
        await tester.tap(find.text(AppStrings.availabilityConfirmReopen));
        await pumpFrames(tester, const Duration(seconds: 4));
      }
      record('restore_follow', 'PASS');
      await markShot('avail-follow-schedule');

      File('${outDir.path}/AVAILABILITY_LIVE_PROVENANCE.json').writeAsStringSync(
        const JsonEncoder.withIndent('  ').convert({
          'fixture': 'Dar El Bahja',
          'phone': '+213$phoneLocal',
          'steps': steps,
        }),
      );
    } catch (e, st) {
      record('fatal', 'FAIL', detail: '$e\n$st');
      File('${outDir.path}/AVAILABILITY_LIVE_PROVENANCE.json').writeAsStringSync(
        const JsonEncoder.withIndent('  ').convert({
          'fixture': 'Dar El Bahja',
          'phone': '+213$phoneLocal',
          'steps': steps,
          'error': e.toString(),
        }),
      );
      rethrow;
    }
  });
}
