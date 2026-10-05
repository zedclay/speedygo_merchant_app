import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:speedygo_merchant_app/app/theme/app_theme.dart';
import 'package:speedygo_merchant_app/core/navigation/app_routes.dart';
import 'package:speedygo_merchant_app/features/catalog/presentation/catalog_screen.dart';
import 'package:speedygo_merchant_app/features/orders/presentation/orders_screen.dart';
import 'package:speedygo_merchant_app/features/reports/presentation/reports_screen.dart';
import 'package:speedygo_merchant_app/features/shell/home_dashboard_screen.dart';
import 'package:speedygo_merchant_app/features/shell/merchant_bottom_nav.dart';
import 'package:speedygo_merchant_app/features/shell/merchant_nav_visibility.dart';
import 'package:speedygo_merchant_app/features/shell/store_profile_screen.dart';

export 'package:speedygo_merchant_app/features/shell/merchant_bottom_nav.dart';
export 'package:speedygo_merchant_app/features/shell/merchant_nav_visibility.dart';

class MerchantShell extends ConsumerStatefulWidget {
  const MerchantShell({
    super.key,
    required this.child,
    @visibleForTesting this.debugPages,
    @visibleForTesting this.debugVisibility,
  });

  final Widget child;

  /// Replaces the five root pages in widget tests. Production ignores this.
  final List<Widget>? debugPages;

  /// Injected visibility controller for widget tests.
  final MerchantNavVisibilityController? debugVisibility;

  static final tabRoutes = [
    AppRoutes.home,
    AppRoutes.orders,
    AppRoutes.catalog,
    AppRoutes.reports,
    AppRoutes.profile,
  ];

  static int indexForLocation(String location) {
    if (location.startsWith(AppRoutes.orders)) return 1;
    if (location.startsWith(AppRoutes.catalog)) return 2;
    if (location.startsWith(AppRoutes.reports)) return 3;
    if (location.startsWith(AppRoutes.profile)) return 4;
    return 0;
  }

  static bool isExactRootTab(String location) => tabRoutes.contains(location);

  @override
  ConsumerState<MerchantShell> createState() => MerchantShellState();
}

class MerchantShellState extends ConsumerState<MerchantShell>
    with WidgetsBindingObserver {
  late final MerchantNavVisibilityController visibility;
  late final List<Widget> _pages;
  PageController? _pageController;
  int _index = 0;
  var _initialized = false;
  var _syncing = false;
  var _wasOnNested = false;

  /// Locks root paging while a nested horizontal scroller (chips, etc.) is
  /// dragging, so end-of-row overscroll cannot steal the tab gesture.
  var _lockPagerForNestedHorizontal = false;

  @override
  void initState() {
    super.initState();
    visibility = widget.debugVisibility ?? MerchantNavVisibilityController();
    _pages =
        widget.debugPages ??
        const [
          HomeScreen(),
          OrdersScreen(),
          CatalogScreen(),
          ReportsScreen(),
          StoreProfileScreen(),
        ];
    assert(
      _pages.length == MerchantShell.tabRoutes.length,
      'Merchant shell expects five root pages.',
    );
    WidgetsBinding.instance.addObserver(this);
    FocusManager.instance.addListener(_syncAutoHide);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final location = GoRouterState.of(context).uri.path;
    final index = MerchantShell.indexForLocation(location);
    if (!_initialized) {
      _index = index;
      _pageController = PageController(initialPage: index);
      _initialized = true;
      _wasOnNested = !MerchantShell.isExactRootTab(location);
      return;
    }
    if (MerchantShell.isExactRootTab(location)) {
      if (_wasOnNested) {
        visibility.reveal();
      }
      _wasOnNested = false;
    } else {
      _wasOnNested = true;
    }
    if (index != _index) {
      _index = index;
      visibility.reveal();
      _syncPage(index);
    }
    _syncAutoHide();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      visibility.reveal();
    }
  }

  @override
  void dispose() {
    FocusManager.instance.removeListener(_syncAutoHide);
    WidgetsBinding.instance.removeObserver(this);
    _pageController?.dispose();
    if (widget.debugVisibility == null) {
      visibility.dispose();
    }
    super.dispose();
  }

  void _syncAutoHide() {
    if (!mounted) return;
    final keyboard = MediaQuery.viewInsetsOf(context).bottom > 0;
    final a11y = MediaQuery.accessibleNavigationOf(context);
    final routeCurrent = ModalRoute.of(context)?.isCurrent ?? true;
    final editing = _focusIsEditing();
    final enabled = !keyboard && !a11y && routeCurrent && !editing;
    if (visibility.autoHideEnabled == enabled) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) visibility.setAutoHideEnabled(enabled);
    });
  }

  bool _focusIsEditing() {
    final focus = FocusManager.instance.primaryFocus;
    final ctx = focus?.context;
    if (ctx == null) return false;
    return ctx.widget is EditableText ||
        ctx.findAncestorWidgetOfExactType<EditableText>() != null ||
        ctx.findAncestorWidgetOfExactType<TextField>() != null;
  }

  Future<void> _syncPage(int index) async {
    final controller = _pageController;
    if (controller == null || !controller.hasClients) return;
    final current = controller.page?.round() ?? controller.initialPage;
    if (current == index) return;
    _syncing = true;
    final reduce = MediaQuery.disableAnimationsOf(context);
    if (reduce) {
      controller.jumpToPage(index);
    } else {
      await controller.animateToPage(
        index,
        duration: MerchantNavTokens.tabTransition,
        curve: MerchantNavTokens.tabCurve,
      );
    }
    if (mounted) _syncing = false;
  }

  void _onSelect(int index) {
    if (index == _index) return;
    context.go(MerchantShell.tabRoutes[index]);
  }

  void _onPageChanged(int index) {
    if (_syncing || index == _index) return;
    _index = index;
    visibility.reveal();
    context.go(MerchantShell.tabRoutes[index]);
  }

  bool _onScroll(ScrollNotification notification) {
    return visibility.handle(notification);
  }

  /// Nested horizontal scroll notifications bubble through [PageView].
  /// Depth ≥ 1 is a descendant scroller (chip rows); depth 0 is the pager.
  bool _onPagerScrollGate(ScrollNotification notification) {
    if (notification.metrics.axis != Axis.horizontal) return false;
    if (notification.depth < 1) return false;
    if (notification is ScrollStartNotification ||
        (notification is ScrollUpdateNotification &&
            notification.dragDetails != null)) {
      if (!_lockPagerForNestedHorizontal) {
        setState(() => _lockPagerForNestedHorizontal = true);
      }
      return false;
    }
    if (notification is ScrollEndNotification ||
        (notification is UserScrollNotification &&
            notification.direction == ScrollDirection.idle)) {
      if (_lockPagerForNestedHorizontal) {
        setState(() => _lockPagerForNestedHorizontal = false);
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final controller = _pageController;
    if (controller == null) {
      return widget.child;
    }
    return ListenableBuilder(
      listenable: visibility,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: AppColors.background,
          body: Column(
            children: [
              Expanded(
                child: MediaQuery.removePadding(
                  context: context,
                  removeBottom: true,
                  child: NotificationListener<ScrollNotification>(
                    onNotification: _onPagerScrollGate,
                    child: PageView.builder(
                      key: const Key('merchant-root-pager'),
                      controller: controller,
                      physics: _lockPagerForNestedHorizontal
                          ? const NeverScrollableScrollPhysics()
                          : const PageScrollPhysics(),
                      itemCount: _pages.length,
                      onPageChanged: _onPageChanged,
                      itemBuilder: (context, index) {
                        return _KeptPage(
                          child: _FadingPage(
                            controller: controller,
                            index: index,
                            child: NotificationListener<ScrollNotification>(
                              onNotification: (notification) {
                                if (index != _index) return false;
                                return _onScroll(notification);
                              },
                              child: _pages[index],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              MerchantNavSlot(
                visible: visibility.visible,
                onReveal: visibility.reveal,
                dock: MerchantBottomNav(
                  currentIndex: _index,
                  onSelect: _onSelect,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _KeptPage extends StatefulWidget {
  const _KeptPage({required this.child});

  final Widget child;

  @override
  State<_KeptPage> createState() => _KeptPageState();
}

class _KeptPageState extends State<_KeptPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}

class _FadingPage extends StatelessWidget {
  const _FadingPage({
    required this.controller,
    required this.index,
    required this.child,
  });

  final PageController controller;
  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final page = controller.hasClients
            ? (controller.page ?? controller.initialPage.toDouble())
            : index.toDouble();
        final dist = (page - index).abs().clamp(0.0, 1.0);
        return Opacity(
          opacity: 1 - dist * MerchantNavTokens.tabFade,
          child: child,
        );
      },
      child: child,
    );
  }
}

/// Kept for optional placeholder routes; unused by the main shell tabs.
class PlaceholderTabScreen extends StatelessWidget {
  const PlaceholderTabScreen({
    super.key,
    required this.title,
    required this.body,
  });
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Center(child: Text(body, textAlign: TextAlign.center)),
        ),
      ),
    );
  }
}
