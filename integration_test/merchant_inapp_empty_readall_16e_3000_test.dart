import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:speedygo_merchant_app/app/app.dart';
import 'package:speedygo_merchant_app/core/constants/app_constants.dart';
import 'package:speedygo_merchant_app/core/constants/app_strings.dart';
import 'package:speedygo_merchant_app/core/navigation/app_routes.dart';
import 'package:speedygo_merchant_app/core/storage/session_store.dart';
import 'package:speedygo_merchant_app/features/auth/application/session_providers.dart';
import 'package:speedygo_merchant_app/features/auth/data/models.dart';
import 'package:speedygo_merchant_app/features/store/presentation/notifications_screen.dart';

/// DEVICE_UI empty + read-all on an isolated Merchant whose Account has no
/// unrelated notifications. Does not touch operational 071.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const expectedApi = 'http://127.0.0.1:3000/api/v1';
  const merchantId = String.fromEnvironment(
    'INAPP_MERCHANT_ID',
    defaultValue: '01a0bf0f-ae06-7992-a9ee-22fed331d03f',
  );
  const branchId = String.fromEnvironment(
    'INAPP_BRANCH_ID',
    defaultValue: '01a0bf0f-aeef-70bb-8f86-dfe2a5e80154',
  );
  const evidDir = String.fromEnvironment(
    'INAPP_EVIDENCE_DIR',
    defaultValue:
        '/Users/mac/Downloads/speedygo_project/docs/audits/2026-10-23/evidence/merchant_inapp_16e',
  );
  const shotMarker = String.fromEnvironment(
    'INAPP_SHOT_FILE',
    defaultValue: '/tmp/speedygo_merchant_inapp_readall_shot.txt',
  );
  const phase = String.fromEnvironment('INAPP_PHASE', defaultValue: 'empty');
  const dedicatedId = String.fromEnvironment(
    'INAPP_DEDICATED_ID',
    defaultValue: 'c1a55e70-1aab-4b03-8003-000000000301',
  );
  const fixturePhone = String.fromEnvironment('INAPP_FIXTURE_PHONE');

  Map<String, dynamic> tokens() {
    const b64 = String.fromEnvironment('SMOKE_TOKEN_B64');
    if (b64.isEmpty) throw StateError('SMOKE_TOKEN_B64 required');
    return Map<String, dynamic>.from(
      jsonDecode(utf8.decode(base64Decode(b64))) as Map,
    );
  }

  Future<void> pumpFrames(WidgetTester tester, int ticks) async {
    for (var i = 0; i < ticks; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<bool> waitFinder(
    WidgetTester tester,
    Finder finder, {
    int ticks = 80,
  }) async {
    for (var i = 0; i < ticks; i++) {
      if (finder.evaluate().isNotEmpty) return true;
      await tester.pump(const Duration(milliseconds: 100));
    }
    return false;
  }

  String dumpTexts(WidgetTester tester) {
    final texts = <String>[];
    for (final el in find.byType(Text).evaluate()) {
      final w = el.widget;
      if (w is Text) {
        final s = w.data ?? w.textSpan?.toPlainText() ?? '';
        if (s.trim().isNotEmpty) texts.add(s.trim());
      }
    }
    return texts.take(80).join(' | ');
  }

  Future<void> shot(WidgetTester tester, String tag) async {
    debugPrint('INAPP_UI_$tag:${dumpTexts(tester)}');
    Directory(evidDir).createSync(recursive: true);
    File('$evidDir/ui_$tag.txt').writeAsStringSync(dumpTexts(tester));
    await pumpFrames(tester, 6);
    await Future<void>.delayed(const Duration(milliseconds: 800));
    File(shotMarker).writeAsStringSync(tag);
    await Future<void>.delayed(const Duration(milliseconds: 700));
    await pumpFrames(tester, 2);
  }

  GoRouter routerOf(WidgetTester tester) {
    return GoRouter.of(tester.element(find.byType(Navigator).first));
  }

  testWidgets('merchant in-app empty/read-all 16e $phase', (tester) async {
    expect(AppConstants.apiBaseUrl, expectedApi);
    final store = MemorySessionStore();
    await store.write(TokenPair.fromJson(tokens()));
    final launch = MemoryLaunchStore(onboardingSeen: true, languageSeen: true);
    final contextStore = MemoryContextStore()
      ..merchantId = merchantId
      ..branchId = branchId;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionStoreProvider.overrideWithValue(store),
          launchStoreProvider.overrideWithValue(launch),
          contextStoreProvider.overrideWithValue(contextStore),
          splashMinDurationProvider.overrideWithValue(Duration.zero),
          splashAnimateProvider.overrideWithValue(false),
        ],
        child: const SpeedyGoApp(),
      ),
    );
    expect(
      await waitFinder(tester, find.byKey(const Key('home-branch-name')), ticks: 160),
      isTrue,
    );
    routerOf(tester).go(AppRoutes.notifications);
    await pumpFrames(tester, 30);
    expect(
      await waitFinder(tester, find.byType(NotificationsScreen), ticks: 80),
      isTrue,
    );

    if (phase == 'empty') {
      expect(
        await waitFinder(
          tester,
          find.byKey(const Key('notifications-empty')),
          ticks: 80,
        ),
        isTrue,
      );
      expect(find.text(AppStrings.notificationsEmpty), findsOneWidget);
      await shot(tester, 'empty_fr');
      routerOf(tester).go(AppRoutes.languageSettings);
      await pumpFrames(tester, 20);
      expect(
        await waitFinder(
          tester,
          find.byKey(const Key('language-option-ar')),
          ticks: 60,
        ),
        isTrue,
      );
      await tester.tap(find.byKey(const Key('language-option-ar')));
      await pumpFrames(tester, 8);
      await tester.tap(find.byKey(const Key('language-apply')));
      await pumpFrames(tester, 30);
      routerOf(tester).go(AppRoutes.notifications);
      await pumpFrames(tester, 30);
      expect(
        Directionality.of(tester.element(find.byType(NotificationsScreen))),
        TextDirection.rtl,
      );
      expect(find.byKey(const Key('notifications-empty')), findsOneWidget);
      await shot(tester, 'empty_ar');
      File('$evidDir/merchant_inapp_empty.json').writeAsStringSync(
        jsonEncode({
          'app': 'MERCHANT',
          'phase': 'empty',
          'kind': 'device_ui',
          'fixturePhone': fixturePhone,
          'merchantId': merchantId,
          'result': 'PASS',
        }),
      );
      File(shotMarker).writeAsStringSync('done');
      return;
    }

    expect(find.byKey(Key('notification-$dedicatedId')), findsOneWidget);
    await shot(tester, 'readall_populated_fr');
    await tester.tap(find.byKey(Key('notification-$dedicatedId')));
    await pumpFrames(tester, 20);
    expect(find.byKey(Key('notification-unread-$dedicatedId')), findsNothing);
    await shot(tester, 'readall_after_mark_read_fr');
    expect(find.byKey(const Key('notifications-mark-all')), findsOneWidget);
    await tester.tap(find.byKey(const Key('notifications-mark-all')));
    await pumpFrames(tester, 30);
    final markAll = tester.widget(find.byKey(const Key('notifications-mark-all')));
    if (markAll is TextButton) {
      expect(markAll.onPressed, isNull);
    } else if (markAll is IconButton) {
      expect(markAll.onPressed, isNull);
    } else {
      fail('unexpected mark-all widget ${markAll.runtimeType}');
    }
    await shot(tester, 'after_read_all_fr');
    routerOf(tester).go(AppRoutes.home);
    await pumpFrames(tester, 16);
    routerOf(tester).go(AppRoutes.notifications);
    await pumpFrames(tester, 24);
    final markAllReopen = tester.widget(find.byKey(const Key('notifications-mark-all')));
    if (markAllReopen is TextButton) {
      expect(markAllReopen.onPressed, isNull);
    } else if (markAllReopen is IconButton) {
      expect(markAllReopen.onPressed, isNull);
    }
    await shot(tester, 'readall_reopen_fr');
    File('$evidDir/merchant_inapp_readall.json').writeAsStringSync(
      jsonEncode({
        'app': 'MERCHANT',
        'phase': 'readall',
        'kind': 'device_ui',
        'fixturePhone': fixturePhone,
        'merchantId': merchantId,
        'readAll': 'posted_isolated_account',
        'result': 'PASS',
      }),
    );
    File(shotMarker).writeAsStringSync('done');
  });
}
