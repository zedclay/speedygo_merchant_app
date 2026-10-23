import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:speedygo_merchant_app/app/app.dart';
import 'package:speedygo_merchant_app/core/constants/app_constants.dart';
import 'package:speedygo_merchant_app/core/navigation/app_routes.dart';
import 'package:speedygo_merchant_app/core/storage/session_store.dart';
import 'package:speedygo_merchant_app/features/auth/application/session_providers.dart';
import 'package:speedygo_merchant_app/features/auth/data/models.dart';
import 'package:speedygo_merchant_app/features/store/presentation/notifications_screen.dart';

/// DEVICE_UI: Merchant IN_APP inbox on iPhone 16e vs live :3000.
/// Dedicated fixture rows only for mark-read. Does not POST read-all on 071.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const expectedApi = 'http://127.0.0.1:3000/api/v1';
  const merchantId = '0d00c071-d000-7000-8000-000000010001';
  const branchId = '0d00c071-d000-7000-8000-000000011001';
  const evidDir = String.fromEnvironment(
    'INAPP_EVIDENCE_DIR',
    defaultValue:
        '/Users/mac/Downloads/speedygo_project/docs/audits/2026-10-23/evidence/merchant_inapp_16e',
  );
  const shotMarker = String.fromEnvironment(
    'INAPP_SHOT_FILE',
    defaultValue: '/tmp/speedygo_merchant_inapp_shot.txt',
  );
  const dedicatedId = String.fromEnvironment(
    'INAPP_DEDICATED_ID',
    defaultValue: 'c1a55e70-1aab-4b03-8003-000000000101',
  );
  const destNotifId = String.fromEnvironment(
    'INAPP_DEST_NOTIF_ID',
    defaultValue: '',
  );
  const destOrderId = String.fromEnvironment(
    'INAPP_DEST_ORDER_ID',
    defaultValue: '',
  );

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

  testWidgets('merchant in-app inbox 16e', (tester) async {
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
    await shot(tester, 'populated_fr');

    final dedicated = find.byKey(Key('notification-$dedicatedId'));
    if (dedicated.evaluate().isNotEmpty) {
      await tester.tap(dedicated);
      await pumpFrames(tester, 20);
      expect(find.byKey(Key('notification-unread-$dedicatedId')), findsNothing);
      await shot(tester, 'after_mark_read_fr');
    }

    if (destNotifId.isNotEmpty && destOrderId.isNotEmpty) {
      final details = find.byKey(Key('notification-details-$destNotifId'));
      final destTile = find.byKey(Key('notification-$destNotifId'));
      if (details.evaluate().isNotEmpty) {
        await tester.tap(details.first);
      } else if (destTile.evaluate().isNotEmpty) {
        await tester.tap(destTile);
      }
      await pumpFrames(tester, 40);
      expect(routerOf(tester).state.uri.path, contains(destOrderId));
      await shot(tester, 'destination_order_fr');
      routerOf(tester).go(AppRoutes.notifications);
      await pumpFrames(tester, 24);
    }

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
    await shot(tester, 'populated_ar');

    File('$evidDir/merchant_inapp_populated.json').writeAsStringSync(
      jsonEncode({
        'app': 'MERCHANT',
        'kind': 'device_ui',
        'readAll': 'skipped_operational_unread',
        'emptyInbox': 'not_available_on_071',
        'destination': destOrderId.isEmpty ? 'none' : destOrderId,
        'result': 'PASS',
      }),
    );
    File(shotMarker).writeAsStringSync('done');
  });
}
