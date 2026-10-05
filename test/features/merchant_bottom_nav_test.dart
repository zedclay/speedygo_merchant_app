import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:speedygo_merchant_app/app/theme/app_theme.dart';
import 'package:speedygo_merchant_app/core/constants/app_strings.dart';
import 'package:speedygo_merchant_app/core/navigation/app_routes.dart';
import 'package:speedygo_merchant_app/features/shell/merchant_shell.dart';

const _phone = Size(390, 844);
const _small = Size(375, 667);
const _safeBottom = 34.0;

final _rootKey = GlobalKey<NavigatorState>();

Widget _tab({
  required String name,
  required Key scrollKey,
  required Key lastKey,
  bool withField = false,
  bool withHorizontal = false,
}) {
  return Scaffold(
    body: Column(
      children: [
        Text(name, key: Key('tab-title-$name')),
        if (withField)
          const TextField(
            key: Key('tab-field'),
            decoration: InputDecoration(hintText: 'note'),
          ),
        if (withHorizontal)
          SizedBox(
            height: 56,
            child: ListView(
              key: const Key('nested-h'),
              scrollDirection: Axis.horizontal,
              children: [
                for (var i = 0; i < 16; i++)
                  SizedBox(
                    width: 88,
                    child: Center(child: Text('chip-$i')),
                  ),
              ],
            ),
          ),
        Expanded(
          child: ListView(
            key: scrollKey,
            children: [
              for (var i = 0; i < 40; i++)
                SizedBox(
                  height: 56,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '$name-row-$i',
                      key: i == 39 ? lastKey : Key('$name-row-$i'),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    ),
  );
}

List<Widget> _pages() => [
      _tab(
        name: 'home',
        scrollKey: const Key('scroll-home'),
        lastKey: const Key('last-home'),
        withField: true,
      ),
      _tab(
        name: 'orders',
        scrollKey: const Key('scroll-orders'),
        lastKey: const Key('last-orders'),
        withHorizontal: true,
      ),
      _tab(
        name: 'catalog',
        scrollKey: const Key('scroll-catalog'),
        lastKey: const Key('last-catalog'),
      ),
      _tab(
        name: 'reports',
        scrollKey: const Key('scroll-reports'),
        lastKey: const Key('last-reports'),
      ),
      _tab(
        name: 'profile',
        scrollKey: const Key('scroll-profile'),
        lastKey: const Key('last-profile'),
      ),
    ];

GoRouter _router({
  String initial = AppRoutes.home,
  List<Widget>? pages,
  MerchantNavVisibilityController? visibility,
}) {
  final tabs = pages ?? _pages();
  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: initial,
    routes: [
      ShellRoute(
        builder: (context, state, child) => MerchantShell(
          debugPages: tabs,
          debugVisibility: visibility,
          child: child,
        ),
        routes: [
          for (final path in MerchantShell.tabRoutes)
            GoRoute(
              path: path,
              builder: (_, _) => const SizedBox.shrink(),
            ),
        ],
      ),
      GoRoute(
        path: '/app/orders/:orderId',
        parentNavigatorKey: _rootKey,
        builder: (_, _) => Scaffold(
          appBar: AppBar(),
          body: const Text('detail', key: Key('test-detail')),
        ),
      ),
    ],
  );
}

Future<void> _pumpShell(
  WidgetTester tester, {
  Size size = _phone,
  double textScale = 1.0,
  double safeBottom = _safeBottom,
  double viewInsetsBottom = 0,
  bool accessibleNavigation = false,
  bool disableAnimations = false,
  String initial = AppRoutes.home,
  List<Widget>? pages,
  MerchantNavVisibilityController? visibility,
  GoRouter? router,
}) async {
  tester.view.physicalSize = Size(size.width * 2, size.height * 2);
  tester.view.devicePixelRatio = 2;
  tester.view.padding = FakeViewPadding(bottom: safeBottom * 2);
  tester.view.viewPadding = FakeViewPadding(bottom: safeBottom * 2);
  tester.view.viewInsets = FakeViewPadding(bottom: viewInsetsBottom * 2);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPadding);
  addTearDown(tester.view.resetViewPadding);
  addTearDown(tester.view.resetViewInsets);
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));

  final config = router ??
      _router(initial: initial, pages: pages, visibility: visibility);
  await tester.pumpWidget(
    ProviderScope(
      child: MediaQuery(
        data: MediaQueryData(
          size: size,
          textScaler: TextScaler.linear(textScale),
          padding: EdgeInsets.only(bottom: safeBottom),
          viewPadding: EdgeInsets.only(bottom: safeBottom),
          viewInsets: EdgeInsets.only(bottom: viewInsetsBottom),
          accessibleNavigation: accessibleNavigation,
          disableAnimations: disableAnimations,
        ),
        child: MaterialApp.router(
          theme: AppTheme.light(locale: const Locale('fr')),
          routerConfig: config,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

MerchantShellState _shellState(WidgetTester tester) {
  return tester.state<MerchantShellState>(find.byType(MerchantShell));
}

void main() {
  test('hide threshold and immediate reveal', () {
    final nav = MerchantNavVisibilityController();
    nav.applyPrimaryVerticalScroll(
      pixels: 20,
      minScrollExtent: 0,
      delta: 20,
    );
    expect(nav.visible, isTrue);
    nav.applyPrimaryVerticalScroll(
      pixels: 40,
      minScrollExtent: 0,
      delta: 20,
    );
    expect(nav.visible, isTrue);
    nav.applyPrimaryVerticalScroll(
      pixels: 70,
      minScrollExtent: 0,
      delta: 20,
    );
    expect(nav.visible, isFalse);

    nav.applyPrimaryVerticalScroll(
      pixels: 60,
      minScrollExtent: 0,
      delta: -8,
    );
    expect(nav.visible, isTrue);
  });

  test('top of page always reveals', () {
    final nav = MerchantNavVisibilityController();
    nav.applyPrimaryVerticalScroll(
      pixels: 80,
      minScrollExtent: 0,
      delta: 80,
    );
    expect(nav.visible, isFalse);
    nav.applyPrimaryVerticalScroll(
      pixels: 0,
      minScrollExtent: 0,
      delta: -80,
    );
    expect(nav.visible, isTrue);
  });

  test('small steps around the threshold do not jitter', () {
    final nav = MerchantNavVisibilityController();
    nav.applyPrimaryVerticalScroll(
      pixels: 10,
      minScrollExtent: 0,
      delta: 10,
    );
    nav.applyPrimaryVerticalScroll(
      pixels: 20,
      minScrollExtent: 0,
      delta: 10,
    );
    expect(nav.visible, isTrue);
    expect(nav.downAccum, 20);
    nav.applyPrimaryVerticalScroll(
      pixels: 15,
      minScrollExtent: 0,
      delta: -5,
    );
    expect(nav.visible, isTrue);
    expect(nav.downAccum, 0);
    nav.applyPrimaryVerticalScroll(
      pixels: 25,
      minScrollExtent: 0,
      delta: 10,
    );
    expect(nav.visible, isTrue);
  });

  test('suppressed auto-hide ignores scroll-down', () {
    final nav = MerchantNavVisibilityController();
    nav.setAutoHideEnabled(false);
    nav.applyPrimaryVerticalScroll(
      pixels: 120,
      minScrollExtent: 0,
      delta: 120,
    );
    expect(nav.visible, isTrue);
  });

  testWidgets('each active tab keeps a selected destination', (tester) async {
    await _pumpShell(tester);
    final labels = [
      AppStrings.tabHome,
      AppStrings.tabOrders,
      AppStrings.tabCatalog,
      AppStrings.tabReports,
      AppStrings.tabProfile,
    ];
    const keys = [
      'nav-home',
      'nav-orders',
      'nav-catalog',
      'nav-reports',
      'nav-profile',
    ];
    for (var i = 0; i < labels.length; i++) {
      if (i > 0) {
        await tester.tap(find.byKey(Key(keys[i])));
        await tester.pumpAndSettle();
      }
      expect(_shellState(tester).visibility.visible, isTrue);
      expect(find.byKey(Key('tab-title-${[
        'home',
        'orders',
        'catalog',
        'reports',
        'profile',
      ][i]}')), findsOneWidget);
      final selected = tester
          .widgetList<Semantics>(find.byType(Semantics))
          .where((s) => s.properties.selected == true)
          .map((s) => s.properties.label)
          .toList();
      expect(selected, contains(labels[i]));
    }
  });

  testWidgets('selected destination exposes accessibility semantics', (
    tester,
  ) async {
    await _pumpShell(tester);
    final handle = tester.ensureSemantics();
    try {
      final inactive = tester.getSemantics(find.byKey(const Key('nav-orders')));
      expect(inactive.label, AppStrings.tabOrders);
      expect(inactive.hasFlag(SemanticsFlag.isButton), isTrue);
      expect(inactive.hasFlag(SemanticsFlag.isSelected), isFalse);
      expect(inactive.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
      await tester.tap(find.byKey(const Key('nav-orders')));
      await tester.pumpAndSettle();
      final active =
          tester.getSemantics(find.byKey(const Key('nav-orders-active')));
      expect(active.label, AppStrings.tabOrders);
      expect(active.hasFlag(SemanticsFlag.isButton), isTrue);
      expect(active.hasFlag(SemanticsFlag.isSelected), isTrue);
      expect(active.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
    } finally {
      handle.dispose();
    }
  });

  testWidgets('scroll-down past the threshold hides the dock', (tester) async {
    await _pumpShell(tester);
    expect(find.byKey(const Key('merchant-nav-dock')), findsOneWidget);
    await tester.drag(find.byKey(const Key('scroll-home')), const Offset(0, -80));
    await tester.pumpAndSettle();
    expect(_shellState(tester).visibility.visible, isFalse);
    expect(find.byKey(const Key('nav-handle')), findsOneWidget);
  });

  testWidgets('scroll-up reveals immediately', (tester) async {
    await _pumpShell(tester);
    await tester.drag(find.byKey(const Key('scroll-home')), const Offset(0, -80));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('nav-handle')), findsOneWidget);
    expect(_shellState(tester).visibility.visible, isFalse);
    await tester.drag(find.byKey(const Key('scroll-home')), const Offset(0, 24));
    await tester.pumpAndSettle();
    expect(_shellState(tester).visibility.visible, isTrue);
    expect(find.byKey(const Key('merchant-nav-dock')), findsOneWidget);
  });

  testWidgets('handle tap restores the dock', (tester) async {
    await _pumpShell(tester);
    await tester.drag(find.byKey(const Key('scroll-home')), const Offset(0, -80));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('nav-handle')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('merchant-nav-dock')), findsOneWidget);
  });

  testWidgets('sub-threshold motion does not hide', (tester) async {
    await _pumpShell(tester);
    await tester.drag(find.byKey(const Key('scroll-home')), const Offset(0, -20));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('merchant-nav-dock')), findsOneWidget);
    expect(_shellState(tester).visibility.visible, isTrue);
  });

  testWidgets('tab tap runs a horizontal page transition', (tester) async {
    await _pumpShell(tester);
    await tester.tap(find.byKey(const Key('nav-catalog')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));
    final page = tester
        .widget<PageView>(find.byKey(const Key('merchant-root-pager')));
    expect(page.controller?.page, isNot(0));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('tab-title-catalog')), findsOneWidget);
    expect(
      tester
          .widget<PageView>(find.byKey(const Key('merchant-root-pager')))
          .controller
          ?.page,
      2,
    );
  });

  testWidgets('intentional swipe changes the root tab', (tester) async {
    await _pumpShell(tester);
    await tester.fling(
      find.byKey(const Key('scroll-home')),
      const Offset(-400, 0),
      1200,
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('tab-title-orders')), findsOneWidget);
  });

  testWidgets('scroll position is kept when returning to a tab', (tester) async {
    await _pumpShell(tester);
    final scroll = find.byKey(const Key('scroll-home'));
    await tester.drag(scroll, const Offset(0, -280));
    await tester.pumpAndSettle();
    final before = tester
        .state<ScrollableState>(
          find.descendant(of: scroll, matching: find.byType(Scrollable)),
        )
        .position
        .pixels;
    expect(before, greaterThan(100));
    final router = GoRouter.of(tester.element(find.byType(MerchantShell)));
    router.go(AppRoutes.reports);
    await tester.pumpAndSettle();
    router.go(AppRoutes.home);
    await tester.pumpAndSettle();
    final after = tester
        .state<ScrollableState>(
          find.descendant(
            of: find.byKey(const Key('scroll-home')),
            matching: find.byType(Scrollable),
          ),
        )
        .position
        .pixels;
    expect(after, closeTo(before, 1));
  });

  testWidgets('page state is kept when returning to a tab', (tester) async {
    await _pumpShell(tester);
    await tester.enterText(find.byKey(const Key('tab-field')), 'couscous');
    await tester.pump();
    final router = GoRouter.of(tester.element(find.byType(MerchantShell)));
    router.go(AppRoutes.profile);
    await tester.pumpAndSettle();
    router.go(AppRoutes.home);
    await tester.pumpAndSettle();
    expect(find.widgetWithText(TextField, 'couscous'), findsOneWidget);
  });

  testWidgets('nested horizontal scrolling does not change root tabs', (
    tester,
  ) async {
    await _pumpShell(tester);
    await tester.tap(find.byKey(const Key('nav-orders')));
    await tester.pumpAndSettle();
    await tester.drag(find.byKey(const Key('nested-h')), const Offset(-240, 0));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('tab-title-orders')), findsOneWidget);
    expect(find.byKey(const Key('tab-title-catalog')), findsNothing);
  });

  testWidgets(
    'nested horizontal overscroll at either end does not change root tabs',
    (tester) async {
      await _pumpShell(tester);
      await tester.tap(find.byKey(const Key('nav-orders')));
      await tester.pumpAndSettle();
      final chipRow = find.byKey(const Key('nested-h'));
      final center = tester.getCenter(chipRow);
      // Drag past the end (left), then keep overscrolling in the same gesture.
      final gesture = await tester.startGesture(center);
      await gesture.moveBy(const Offset(-900, 0));
      await tester.pump();
      await gesture.moveBy(const Offset(-400, 0));
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('tab-title-orders')), findsOneWidget);
      expect(find.byKey(const Key('tab-title-catalog')), findsNothing);
      // Other end: drag past the start (right) and overscroll again.
      final gestureBack = await tester.startGesture(center);
      await gestureBack.moveBy(const Offset(900, 0));
      await tester.pump();
      await gestureBack.moveBy(const Offset(400, 0));
      await tester.pump();
      await gestureBack.up();
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('tab-title-orders')), findsOneWidget);
      expect(find.byKey(const Key('tab-title-home')), findsNothing);
    },
  );

  testWidgets('keyboard interaction does not auto-hide the dock', (
    tester,
  ) async {
    await _pumpShell(tester, viewInsetsBottom: 280);
    await tester.enterText(find.byKey(const Key('tab-field')), 'ok');
    await tester.pump();
    await tester.drag(find.byKey(const Key('scroll-home')), const Offset(0, -120));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('merchant-nav-dock')), findsOneWidget);
    expect(_shellState(tester).visibility.autoHideEnabled, isFalse);
  });

  testWidgets('small-screen safe area keeps the dock above the home indicator', (
    tester,
  ) async {
    await _pumpShell(tester, size: _small, safeBottom: 34);
    final dock = tester.getRect(find.byKey(const Key('merchant-nav-dock')));
    expect(dock.bottom, lessThanOrEqualTo(_small.height - 34 + 0.5));
    expect(dock.left, closeTo(MerchantNavTokens.dockMarginH, 0.5));
    expect(
      dock.right,
      closeTo(_small.width - MerchantNavTokens.dockMarginH, 0.5),
    );
  });

  testWidgets('text scale 1.35 does not clip tab labels', (tester) async {
    await _pumpShell(tester, size: _small, textScale: 1.35);
    expect(tester.takeException(), isNull);
    for (final label in [
      AppStrings.tabHome,
      AppStrings.tabOrders,
      AppStrings.tabCatalog,
      AppStrings.tabReports,
      AppStrings.tabProfile,
    ]) {
      expect(find.text(label), findsWidgets);
    }
    final dock = tester.getRect(find.byKey(const Key('merchant-nav-dock')));
    expect(dock.height, greaterThanOrEqualTo(MerchantNavTokens.dockHeight - 1));
  });

  testWidgets('app resume reveals the dock', (tester) async {
    await _pumpShell(tester);
    await tester.drag(find.byKey(const Key('scroll-home')), const Offset(0, -80));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('nav-handle')), findsOneWidget);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('merchant-nav-dock')), findsOneWidget);
  });

  testWidgets('deep link opens the matching root tab', (tester) async {
    await _pumpShell(tester, initial: AppRoutes.reports);
    expect(find.byKey(const Key('tab-title-reports')), findsOneWidget);
    expect(find.byKey(const Key('nav-reports')), findsNothing);
    final selected = tester
        .widgetList<Semantics>(find.byType(Semantics))
        .where((s) => s.properties.selected == true)
        .map((s) => s.properties.label);
    expect(selected, contains(AppStrings.tabReports));
  });

  testWidgets('Android back from a nested route returns to the root dock', (
    tester,
  ) async {
    await _pumpShell(tester);
    await tester.tap(find.byKey(const Key('nav-orders')));
    await tester.pumpAndSettle();
    _rootKey.currentContext!.push('/app/orders/o1');
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('test-detail')), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('test-detail')), findsNothing);
    expect(find.byKey(const Key('merchant-nav-dock')), findsOneWidget);
    expect(find.byKey(const Key('tab-title-orders')), findsOneWidget);
  });

  testWidgets('last list row stays above the dock', (tester) async {
    await _pumpShell(tester);
    await tester.tap(find.byKey(const Key('nav-catalog')));
    await tester.pumpAndSettle();
    await tester.drag(
      find.byKey(const Key('scroll-catalog')),
      const Offset(0, -2400),
    );
    await tester.pumpAndSettle();
    _shellState(tester).visibility.reveal();
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('last-catalog')));
    await tester.pumpAndSettle();
    final last = tester.getRect(find.byKey(const Key('last-catalog')));
    final dock = tester.getRect(find.byKey(const Key('merchant-nav-dock')));
    expect(last.bottom, lessThanOrEqualTo(dock.top + 0.5));
  });

  testWidgets('changing tabs reveals a hidden dock', (tester) async {
    await _pumpShell(tester);
    await tester.drag(find.byKey(const Key('scroll-home')), const Offset(0, -80));
    await tester.pumpAndSettle();
    expect(_shellState(tester).visibility.visible, isFalse);
    GoRouter.of(tester.element(find.byType(MerchantShell))).go(AppRoutes.reports);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('tab-title-reports')), findsOneWidget);
    expect(_shellState(tester).visibility.visible, isTrue);
    expect(find.byKey(const Key('merchant-nav-dock')), findsOneWidget);
  });
}
