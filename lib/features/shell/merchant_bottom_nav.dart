import 'package:flutter/material.dart';
import 'package:speedygo_merchant_app/app/theme/app_theme.dart';
import 'package:speedygo_merchant_app/core/constants/app_strings.dart';

/// Concept V1 floating dock. Equal-width destinations, icon above label.
///
/// Used by [MerchantShell] and by mocked harnesses that mount the bar as a
/// Scaffold `bottomNavigationBar` (catalog geometry, parity captures).
class MerchantBottomNav extends StatelessWidget {
  const MerchantBottomNav({
    super.key,
    required this.currentIndex,
    required this.onSelect,
  });

  final int currentIndex;
  final ValueChanged<int> onSelect;

  static List<(IconData, IconData, String, String, String?)> get items => [
        (
          Icons.home_outlined,
          Icons.home,
          AppStrings.tabHome,
          'nav-home',
          null,
        ),
        (
          Icons.receipt_long_outlined,
          Icons.receipt_long,
          AppStrings.tabOrders,
          'nav-orders',
          'nav-orders-active',
        ),
        (
          Icons.inventory_2_outlined,
          Icons.inventory_2,
          AppStrings.tabCatalog,
          'nav-catalog',
          null,
        ),
        (
          Icons.bar_chart_outlined,
          Icons.bar_chart,
          AppStrings.tabReports,
          'nav-reports',
          null,
        ),
        (
          Icons.person_outline,
          Icons.person,
          AppStrings.tabProfile,
          'nav-profile',
          null,
        ),
      ];

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              MerchantNavTokens.dockMarginH,
              MerchantNavTokens.dockMarginV,
              MerchantNavTokens.dockMarginH,
              MerchantNavTokens.dockMarginV,
            ),
            child: DecoratedBox(
              decoration: const BoxDecoration(
                boxShadow: MerchantNavTokens.dockShadow,
              ),
              child: Material(
                key: const Key('merchant-nav-dock'),
                color: AppColors.surface,
                elevation: 0,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    MerchantNavTokens.dockRadius,
                  ),
                  side: MerchantNavTokens.dockBorder,
                ),
                clipBehavior: Clip.antiAlias,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    minHeight: MerchantNavTokens.dockHeight,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 6,
                    ),
                    child: Row(
                      children: [
                        for (var i = 0; i < items.length; i++)
                          Expanded(
                            child: _NavItem(
                              icon: items[i].$1,
                              activeIcon: items[i].$2,
                              label: items[i].$3,
                              inactiveKey: items[i].$4,
                              activeKey: items[i].$5,
                              selected: i == currentIndex,
                              onTap: () => onSelect(i),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.inactiveKey,
    required this.activeKey,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String inactiveKey;
  final String? activeKey;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? AppColors.primary : AppColors.navInactive;
    final iconKey = selected
        ? (activeKey == null ? null : Key(activeKey!))
        : Key(inactiveKey);
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      onTap: onTap,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(MerchantNavTokens.capsuleRadius),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: MerchantNavTokens.minTarget,
            minHeight: MerchantNavTokens.minTarget,
          ),
          child: Center(
            heightFactor: 1,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned.fill(
                  child: AnimatedContainer(
                    duration: MerchantNavTokens.selectionDuration,
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.navCapsule
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(
                        MerchantNavTokens.capsuleRadius,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 4,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        selected ? activeIcon : icon,
                        key: iconKey,
                        color: fg,
                        size: 22,
                      ),
                      const SizedBox(height: 2),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          label,
                          maxLines: 1,
                          softWrap: false,
                          style: TextStyle(
                            fontSize: 11,
                            height: 1.2,
                            fontWeight: selected
                                ? FontWeight.w600
                                : FontWeight.w500,
                            color: fg,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Centered 32×4 handle shown while the dock is hidden.
class MerchantNavHandle extends StatelessWidget {
  const MerchantNavHandle({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Semantics(
          button: true,
          label: AppStrings.navReveal,
          child: SizedBox(
            key: const Key('nav-handle'),
            height: MerchantNavTokens.minTarget,
            width: double.infinity,
            child: Center(
              child: Container(
                width: MerchantNavTokens.handleWidth,
                height: MerchantNavTokens.handleHeight,
                decoration: BoxDecoration(
                  color: AppColors.navHandle,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Animates the dock below the viewport and swaps in the handle.
class MerchantNavSlot extends StatefulWidget {
  const MerchantNavSlot({
    super.key,
    required this.visible,
    required this.dock,
    required this.onReveal,
  });

  final bool visible;
  final Widget dock;
  final VoidCallback onReveal;

  @override
  State<MerchantNavSlot> createState() => _MerchantNavSlotState();
}

class _MerchantNavSlotState extends State<MerchantNavSlot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: MerchantNavTokens.hideDuration,
      value: widget.visible ? 1 : 0,
    );
  }

  @override
  void didUpdateWidget(covariant MerchantNavSlot oldWidget) {
    super.didUpdateWidget(oldWidget);
    final reduce = MediaQuery.disableAnimationsOf(context);
    _controller.duration = reduce
        ? Duration.zero
        : MerchantNavTokens.hideDuration;
    if (widget.visible == oldWidget.visible) return;
    if (widget.visible) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizeTransition(
          sizeFactor: ReverseAnimation(_controller),
          alignment: Alignment.topCenter,
          child: FadeTransition(
            opacity: ReverseAnimation(_controller),
            child: MerchantNavHandle(onTap: widget.onReveal),
          ),
        ),
        SizeTransition(
          sizeFactor: _controller,
          alignment: Alignment.bottomCenter,
          child: FadeTransition(opacity: _controller, child: widget.dock),
        ),
      ],
    );
  }
}
