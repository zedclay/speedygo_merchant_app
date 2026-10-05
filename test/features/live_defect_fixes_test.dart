import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speedygo_merchant_app/app/theme/app_theme.dart';
import 'package:speedygo_merchant_app/core/constants/app_strings.dart';
import 'package:speedygo_merchant_app/core/widgets/merchant_ui.dart';
import 'package:speedygo_merchant_app/features/orders/presentation/order_public_reference.dart';
import 'package:speedygo_merchant_app/features/orders/presentation/prep_time_clock.dart';

const _longReference = 'sgm_0123456789abcdef0123456789abcdef';

Future<void> _setView(WidgetTester tester, double width, double scale) async {
  tester.view.physicalSize = Size(width * 3, 812 * 3);
  tester.view.devicePixelRatio = 3;
  tester.platformDispatcher.textScaleFactorTestValue = scale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
}

Widget _app(Widget home) =>
    MaterialApp(theme: AppTheme.light(), home: home);

void main() {
  group('French durations', () {
    test('minutes, hours and days', () {
      expect(AppStrings.durationFr(0), '0 min');
      expect(AppStrings.durationFr(45), '45 min');
      expect(AppStrings.durationFr(60), '1 h');
      expect(AppStrings.durationFr(125), '2 h 5 min');
      expect(AppStrings.durationFr(1440), '1 j');
      expect(AppStrings.durationFr(1500), '1 j 1 h');
      expect(AppStrings.durationFr(2838), '1 j 23 h');
      expect(AppStrings.durationFr(3 * 1440 + 30), '3 j');
    });

    test('late label keeps the real elapsed time readable', () {
      expect(AppStrings.prepLateBy(0), 'En retard');
      expect(AppStrings.prepLateBy(12), '12 min de retard');
      expect(AppStrings.prepLateBy(2838), '1 j 23 h de retard');
      expect(AppStrings.prepLateBy(2838), isNot(contains('2838')));
    });
  });

  group('estimate day', () {
    // Branch time is UTC+1 (Africa/Algiers, no DST).
    final now = DateTime.utc(2026, 9, 30, 17, 16);

    test('same branch day shows the clock only', () {
      expect(formatPrepOtherDayIso('2026-09-30T09:00:00Z', now), isNull);
      expect(formatPrepOtherDayIso('2026-09-30T22:30:00Z', now), isNull);
      expect(formatPrepOtherDayIso('2026-09-30T23:30:00Z', now), '01/10');
    });

    test('an earlier day is dated', () {
      expect(formatPrepOtherDayIso('2026-09-28T17:38:00Z', now), '28/09');
      expect(
        AppStrings.prepScheduledOnLocal('28/09', '18:38'),
        'Heure prévue : le 28/09 à 18:38 (heure locale)',
      );
    });

    test('unparseable estimates stay undated', () {
      expect(formatPrepOtherDayIso(null, now), isNull);
      expect(formatPrepOtherDayIso('not-a-date', now), isNull);
    });
  });

  group('long canonical references', () {
    testWidgets('compact display, full value in the sheet, copy', (
      tester,
    ) async {
      await _setView(tester, 375, 1.35);
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
      await tester.pumpWidget(
        _app(
          Scaffold(
            body: Center(
              child: OrderPublicReferenceLine(
                reference: _longReference,
                label: AppStrings.verificationReferenceFull,
                prefix: 'Réf. : ',
                textKey: Key('ref'),
                openKey: Key('ref-open'),
              ),
            ),
          ),
        ),
      );

      final shown = tester.widget<Text>(find.byKey(const Key('ref'))).data!;
      expect(shown, 'Réf. : sgm_012345…abcdef');
      expect(shown.length, lessThan(_longReference.length));
      expect(
        find.bySemanticsLabel(RegExp(RegExp.escape(_longReference))),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const Key('ref-open')));
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.verificationReferenceFull), findsOneWidget);
      expect(
        tester
            .widget<SelectableText>(find.byKey(const Key('order-ref-full-text')))
            .data,
        _longReference,
      );
      await tester.tap(find.byKey(const Key('order-ref-copy')));
      await tester.pumpAndSettle();
      expect(copied, _longReference);
    });

    testWidgets('short references are shown unchanged', (tester) async {
      await tester.pumpWidget(
        _app(
          const Scaffold(
            body: OrderPublicReferenceLine(
              reference: 'SGM-260803-1842',
              textKey: Key('ref'),
            ),
          ),
        ),
      );
      expect(
        tester.widget<Text>(find.byKey(const Key('ref'))).data,
        'SGM-260803-1842',
      );
    });
  });

  group('app-bar titles', () {
    final titles = [
      AppStrings.storeAddressTitle,
      AppStrings.orderDetailsTitle,
      AppStrings.catalogCategoryDetailTitle,
      AppStrings.catalogExtrasTitle,
      AppStrings.catalogVariantsTitle,
      AppStrings.catalogAvailabilityTitle,
      AppStrings.catalogReorderTitle,
      AppStrings.notifSettingsTitle,
    ];

    for (final (width, scale) in const [(390.0, 1.0), (375.0, 1.35)]) {
      for (final centered in const [false, true]) {
        testWidgets(
          'wrap without ellipsis at ${width.toInt()} pt, text $scale'
          '${centered ? ', centred' : ''}',
          (tester) async {
            await _setView(tester, width, scale);
            for (final title in titles) {
              await tester.pumpWidget(
                _app(
                  MerchantScaffold(
                    title: title,
                    centerTitle: centered,
                    leading: const BackButton(),
                    actions: [
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.refresh),
                      ),
                    ],
                    body: const SizedBox(),
                  ),
                ),
              );
              final paragraph = tester.renderObject<RenderParagraph>(
                find.text(title),
              );
              expect(
                paragraph.didExceedMaxLines,
                isFalse,
                reason: '"$title" is cut at ${width.toInt()} pt / $scale',
              );
              final pageScale = MediaQuery.of(
                tester.element(find.byType(Scaffold)),
              ).textScaler.scale(10);
              // Flutter's AppBar itself caps title scaling at 1.34×; the
              // Merchant header must not reduce it any further.
              expect(
                MediaQuery.of(tester.element(find.text(title))).textScaler
                    .scale(10),
                closeTo(pageScale < 13.4 ? pageScale : 13.4, 0.001),
                reason: 'the header must not clamp text scaling',
              );
              expect(pageScale, greaterThan(10 * scale - 0.2));
              expect(tester.takeException(), isNull);
            }
          },
        );
      }
    }

    testWidgets('reserves only the lines the title renders (catalogue header)', (
      tester,
    ) async {
      await _setView(tester, 375, 1.35);
      final cases = <String, List<Widget>>{
        'icons': [
          IconButton(onPressed: () {}, icon: const Icon(Icons.checklist)),
          IconButton(onPressed: () {}, icon: const Icon(Icons.notifications)),
          const SizedBox(width: 4),
        ],
        'text button': [
          TextButton(onPressed: () {}, child: const Text('Réorganiser')),
          IconButton(onPressed: () {}, icon: const Icon(Icons.notifications)),
          const SizedBox(width: 4),
        ],
      };
      for (final entry in cases.entries) {
        await tester.pumpWidget(
          _app(
            MerchantScaffold(
              title: 'Catalogue',
              centerTitle: true,
              headerHeight: 56,
              titleStyle: const TextStyle(fontSize: 22),
              actions: entry.value,
              body: const SizedBox(),
            ),
          ),
        );
        final paragraph =
            tester.renderObject<RenderParagraph>(find.text('Catalogue'));
        expect(paragraph.didExceedMaxLines, isFalse, reason: entry.key);
        final painter = TextPainter(
          text: paragraph.text,
          textDirection: TextDirection.ltr,
          textScaler: paragraph.textScaler,
        )..layout(maxWidth: paragraph.constraints.maxWidth);
        final rendered = painter.computeLineMetrics().length;
        painter.dispose();
        final budget = tester.widget<Text>(find.text('Catalogue')).maxLines;
        expect(budget, rendered, reason: entry.key);
        if (rendered == 1) {
          expect(
            tester.getSize(find.byType(AppBar)).height,
            56,
            reason: entry.key,
          );
        }
      }
    });
  });
}
