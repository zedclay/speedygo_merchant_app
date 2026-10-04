import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speedygo_merchant_app/app/theme/app_theme.dart';
import 'package:speedygo_merchant_app/core/constants/app_strings.dart';
import 'package:speedygo_merchant_app/features/orders/presentation/preparation_time_widgets.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget wrap(Widget child) {
    return MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(body: child),
    );
  }

  testWidgets('countdown shows remaining time from estimatedReadyAt', (tester) async {
    final ready = DateTime.now().toUtc().add(const Duration(minutes: 12, seconds: 30));
    await tester.pumpWidget(
      wrap(
        PreparationCountdownBanner(
          estimatedReadyAt: ready.toIso8601String(),
          originalEstimatedReadyAt: ready.toIso8601String(),
          isPreparationLate: false,
          onUpdate: () {},
        ),
      ),
    );
    await tester.pump();
    expect(find.byKey(const Key('prep-countdown-banner')), findsOneWidget);
    expect(find.textContaining('Temps restant'), findsOneWidget);
    expect(find.byKey(const Key('prep-update-open')), findsOneWidget);
  });

  testWidgets('countdown shows late when estimate is past', (tester) async {
    final ready = DateTime.now().toUtc().subtract(const Duration(minutes: 8));
    await tester.pumpWidget(
      wrap(
        PreparationCountdownBanner(
          estimatedReadyAt: ready.toIso8601String(),
          originalEstimatedReadyAt: ready.toIso8601String(),
          isPreparationLate: true,
        ),
      ),
    );
    await tester.pump();
    expect(find.textContaining('retard'), findsOneWidget);
    expect(find.text(AppStrings.prepLateHint), findsOneWidget);
  });

  testWidgets('accept sheet singular hint for one article', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: TextButton(
                key: const Key('open-accept'),
                onPressed: () {
                  showAcceptPreparationSheet(
                    context,
                    publicReference: 'sgo_test',
                    itemCount: 1,
                  );
                },
                child: const Text('open'),
              ),
            );
          },
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('open-accept')));
    await tester.pumpAndSettle();
    expect(
      find.text('Sélectionnez le temps nécessaire pour préparer l’article.'),
      findsOneWidget,
    );
    expect(find.textContaining('Recommandé'), findsNothing);
  });

  testWidgets('update sheet preview uses branch timezone for +10', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: TextButton(
                key: const Key('open-update'),
                onPressed: () {
                  showUpdatePreparationSheet(
                    context,
                    estimatedReadyAt: '2026-09-25T04:19:45.801+01:00',
                    originalEstimatedReadyAt: '2026-09-25T04:19:45.801+01:00',
                    now: () => DateTime.utc(2026, 9, 25, 2),
                  );
                },
                child: const Text('open'),
              ),
            );
          },
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('open-update')));
    await tester.pumpAndSettle();
    expect(find.textContaining('→'), findsNothing);
    expect(find.textContaining('Nouvelle estimation :'), findsNothing);
    expect(find.text('04:29'), findsOneWidget);
    expect(find.text('+10 min'), findsOneWidget);
    expect(
      tester.getSemantics(find.byKey(const Key('prep-update-preview'))),
      matchesSemantics(
        label: 'Nouvelle estimation : 04:29 au lieu de 04:19, plus 10 minutes',
      ),
    );
    expect(find.text('04:19'), findsWidgets);
    expect(find.byKey(const Key('prep-preview-from-day')), findsNothing);
    expect(find.byKey(const Key('prep-preview-to-day')), findsNothing);
  });

  group('update sheet: estimates on another Algiers day', () {
    Future<void> openSheet(
      WidgetTester tester, {
      required String estimatedReadyAt,
      String? originalEstimatedReadyAt,
      required DateTime now,
      String? publicReference,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                key: const Key('open-update'),
                onPressed: () => showUpdatePreparationSheet(
                  context,
                  estimatedReadyAt: estimatedReadyAt,
                  originalEstimatedReadyAt:
                      originalEstimatedReadyAt ?? estimatedReadyAt,
                  publicReference: publicReference,
                  isLate: true,
                  now: () => now,
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.byKey(const Key('open-update')));
      await tester.pumpAndSettle();
    }

    String textOf(WidgetTester tester, String key) =>
        tester.widget<Text>(find.byKey(Key(key))).data!;

    testWidgets('overdue previous-day estimate dates current and proposed', (
      tester,
    ) async {
      // 17:45 on 28/09 in Algiers, opened on 02/10 at 16:00 Algiers.
      await openSheet(
        tester,
        estimatedReadyAt: '2026-09-28T16:45:00Z',
        originalEstimatedReadyAt: '2026-09-28T16:30:00Z',
        now: DateTime.utc(2026, 10, 2, 15),
      );
      expect(textOf(tester, 'prep-update-current-ready'), 'le 28/09 à 17:45');
      expect(find.text('Initiale : le 28/09 à 17:30'), findsOneWidget);
      expect(textOf(tester, 'prep-preview-from-day'), 'le 28/09');
      expect(textOf(tester, 'prep-preview-to-day'), 'le 28/09');
      expect(find.text('17:55'), findsOneWidget);
      expect(
        tester.getSemantics(find.byKey(const Key('prep-update-preview'))),
        matchesSemantics(
          label: 'Nouvelle estimation : 17:55 le 28/09 au lieu de 17:45 '
              'le 28/09, plus 10 minutes',
        ),
      );
    });

    testWidgets('update crossing midnight dates only the next-day estimate', (
      tester,
    ) async {
      // 23:55 on 02/10 in Algiers (22:55 UTC). +10 gives 00:05 on 03/10 in
      // Algiers while the UTC date is still 02/10.
      await openSheet(
        tester,
        estimatedReadyAt: '2026-10-02T22:55:00Z',
        now: DateTime.utc(2026, 10, 2, 22, 30),
      );
      expect(textOf(tester, 'prep-update-current-ready'), '23:55');
      expect(find.byKey(const Key('prep-preview-from-day')), findsNothing);
      expect(find.text('00:05'), findsOneWidget);
      expect(textOf(tester, 'prep-preview-to-day'), 'le 03/10');
      expect(
        tester.getSemantics(find.byKey(const Key('prep-update-preview'))),
        matchesSemantics(
          label: 'Nouvelle estimation : 00:05 le 03/10 au lieu de 23:55, '
              'plus 10 minutes',
        ),
      );
    });

    testWidgets('just after midnight, yesterday is dated and today is not', (
      tester,
    ) async {
      // Opened at 00:10 on 03/10 in Algiers (still 02/10 in UTC).
      await openSheet(
        tester,
        estimatedReadyAt: '2026-10-02T22:55:00Z',
        now: DateTime.utc(2026, 10, 2, 23, 10),
      );
      expect(textOf(tester, 'prep-update-current-ready'), 'le 02/10 à 23:55');
      expect(textOf(tester, 'prep-preview-from-day'), 'le 02/10');
      expect(find.byKey(const Key('prep-preview-to-day')), findsNothing);
      expect(find.text('00:05'), findsOneWidget);
    });

    testWidgets('reference is compact with full reveal and copy', (
      tester,
    ) async {
      const full = 'sgo_01a0e8dc8a8f738284816b1ce0a64cdc';
      String? copied;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            copied = (call.arguments as Map)['text'] as String?;
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      await openSheet(
        tester,
        estimatedReadyAt: '2026-10-02T15:45:00Z',
        now: DateTime.utc(2026, 10, 2, 15),
        publicReference: full,
      );
      expect(textOf(tester, 'prep-update-reference'), 'COMMANDE sgo_01a0e8…a64cdc');
      expect(find.textContaining(full), findsNothing);
      expect(
        find.bySemanticsLabel(RegExp(RegExp.escape(full))),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const Key('prep-update-reference-open')));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<SelectableText>(find.byKey(const Key('order-ref-full-text')))
            .data,
        full,
      );
      await tester.tap(find.byKey(const Key('order-ref-copy')));
      await tester.pumpAndSettle();
      expect(copied, full);
      expect(find.byKey(const Key('update-prep-sheet')), findsOneWidget);
    });
  });

  testWidgets('accept sheet returns selected minutes', (tester) async {
    int? selected;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: TextButton(
                key: const Key('open-accept'),
                onPressed: () async {
                  selected = await showAcceptPreparationSheet(
                    context,
                    publicReference: 'sgo_test',
                    itemCount: 4,
                  );
                },
                child: const Text('open'),
              ),
            );
          },
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('open-accept')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('accept-prep-sheet')), findsOneWidget);
    await tester.tap(find.byKey(const Key('prep-minutes-30')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('accept-prep-confirm')));
    await tester.pumpAndSettle();
    expect(selected, 30);
  });

  testWidgets('update sheet returns addMinutes and optional reason', (tester) async {
    ({int addMinutes, String? reason})? result;
    final ready = DateTime.now().toUtc().add(const Duration(minutes: 20));
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: TextButton(
                key: const Key('open-update'),
                onPressed: () async {
                  result = await showUpdatePreparationSheet(
                    context,
                    estimatedReadyAt: ready.toIso8601String(),
                    originalEstimatedReadyAt: ready.toIso8601String(),
                  );
                },
                child: const Text('open'),
              ),
            );
          },
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('open-update')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('update-prep-sheet')), findsOneWidget);
    await tester.tap(find.byKey(const Key('prep-add-15')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('prep-update-reason')), 'affluence');
    await tester.tap(find.byKey(const Key('prep-update-confirm')));
    await tester.pumpAndSettle();
    expect(result?.addMinutes, 15);
    expect(result?.reason, 'affluence');
  });

  group('reason shortcuts', () {
    Future<({int addMinutes, String? reason})?> Function() openSheet(
      WidgetTester tester,
    ) {
      ({int addMinutes, String? reason})? result;
      final ready = DateTime.now().toUtc().subtract(const Duration(minutes: 8));
      return () async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light(),
            home: Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  key: const Key('open-update'),
                  onPressed: () async {
                    result = await showUpdatePreparationSheet(
                      context,
                      estimatedReadyAt: ready.toIso8601String(),
                      originalEstimatedReadyAt: ready.toIso8601String(),
                      isLate: true,
                    );
                  },
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.byKey(const Key('open-update')));
        await tester.pumpAndSettle();
        return result;
      };
    }

    Future<void> tapVisible(WidgetTester tester, Key key) async {
      await tester.ensureVisible(find.byKey(key));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(key));
      await tester.pumpAndSettle();
    }

    String reasonText(WidgetTester tester) => tester
        .widget<TextField>(find.byKey(const Key('prep-update-reason')))
        .controller!
        .text;

    testWidgets('a tile fills the editable reason, presets stay', (
      tester,
    ) async {
      await openSheet(tester)();
      for (final m in const [5, 10, 15, 20]) {
        expect(find.byKey(Key('prep-add-$m')), findsOneWidget);
      }
      expect(reasonText(tester), isEmpty);
      await tapVisible(tester, const Key('prep-reason-busy'));
      expect(reasonText(tester), AppStrings.prepReasonBusy);
      await tapVisible(tester, const Key('prep-reason-ingredient'));
      expect(reasonText(tester), AppStrings.prepReasonMissingIngredient);
      await tester.enterText(
        find.byKey(const Key('prep-update-reason')),
        'Ingrédient manquant : semoule',
      );
      await tester.pumpAndSettle();
      expect(reasonText(tester), 'Ingrédient manquant : semoule');
      expect(find.textContaining('client sera notifié'), findsNothing);
      expect(find.textContaining('catégorie'), findsNothing);
    });

    testWidgets('confirm sends the edited free text as reason', (
      tester,
    ) async {
      ({int addMinutes, String? reason})? result;
      final ready = DateTime.now().toUtc().subtract(const Duration(minutes: 8));
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                key: const Key('open-update'),
                onPressed: () async {
                  result = await showUpdatePreparationSheet(
                    context,
                    estimatedReadyAt: ready.toIso8601String(),
                    originalEstimatedReadyAt: ready.toIso8601String(),
                    isLate: true,
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.byKey(const Key('open-update')));
      await tester.pumpAndSettle();
      await tapVisible(tester, const Key('prep-reason-long'));
      await tester.enterText(
        find.byKey(const Key('prep-update-reason')),
        '${AppStrings.prepReasonLongPrep} (couscous)',
      );
      await tester.pumpAndSettle();
      await tapVisible(tester, const Key('prep-update-confirm'));
      expect(result?.addMinutes, 10);
      expect(result?.reason, 'Préparation longue (couscous)');
    });

    testWidgets('"Autre raison" clears a preset and focuses the field', (
      tester,
    ) async {
      await openSheet(tester)();
      await tapVisible(tester, const Key('prep-reason-busy'));
      await tapVisible(tester, const Key('prep-reason-other'));
      expect(reasonText(tester), isEmpty);
      final field = tester.widget<TextField>(
        find.byKey(const Key('prep-update-reason')),
      );
      expect(field.focusNode!.hasFocus, isTrue);
      await tester.enterText(
        find.byKey(const Key('prep-update-reason')),
        'Coupure de gaz',
      );
      await tester.pumpAndSettle();
      await tapVisible(tester, const Key('prep-reason-other'));
      expect(reasonText(tester), 'Coupure de gaz');
    });
  });
}
