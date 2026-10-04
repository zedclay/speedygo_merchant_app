import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:speedygo_merchant_app/app/theme/app_theme.dart';
import 'package:speedygo_merchant_app/core/constants/app_strings.dart';

/// Lines an app-bar title needs (1–3) in the space the toolbar leaves it,
/// at the current text scale. Long titles wrap instead of being cut.
///
/// The toolbar gives the title everything between the leading widget and the
/// actions, and only moves a centred title off-centre when it must, so
/// centring does not narrow the title. [actionsWidth] overrides the default of
/// [kMinInteractiveDimension] per action.
int appBarTitleLines(
  BuildContext context,
  String title,
  TextStyle? style, {
  required bool hasLeading,
  required int actionCount,
  double? actionsWidth,
  double? titleSpacing,
}) {
  final width = MediaQuery.sizeOf(context).width;
  final leadingWidth = hasLeading ? kToolbarHeight : 0.0;
  final trailing = actionsWidth ?? actionCount * kMinInteractiveDimension;
  final available = width -
      leadingWidth -
      trailing -
      2 * (titleSpacing ?? NavigationToolbar.kMiddleSpacing);
  if (available <= 0) return 3;
  final painter = TextPainter(
    text: TextSpan(text: title, style: style),
    textDirection: Directionality.of(context),
    textScaler: MediaQuery.textScalerOf(context),
  )..layout(maxWidth: available);
  final lines = painter.computeLineMetrics().length.clamp(1, 3);
  painter.dispose();
  return lines;
}

/// Width the app-bar [actions] take: spacers by their width, text buttons by
/// their label (at the current text scale), anything else as one icon button.
double appBarActionsWidth(BuildContext context, List<Widget>? actions) {
  if (actions == null) return 0;
  final scaler = MediaQuery.textScalerOf(context);
  final labelStyle = Theme.of(context).textTheme.labelLarge;
  var total = 0.0;
  for (final action in actions) {
    if (action is SizedBox) {
      total += action.width ?? 0;
    } else if (action is TextButton && action.child is Text) {
      final painter = TextPainter(
        text: TextSpan(
          text: (action.child! as Text).data ?? '',
          style: labelStyle,
        ),
        textDirection: Directionality.of(context),
        textScaler: scaler,
        maxLines: 1,
      )..layout();
      final width = painter.width + 24;
      painter.dispose();
      total += width < 64 ? 64 : width;
    } else {
      total += kMinInteractiveDimension;
    }
  }
  return total;
}

/// Toolbar height that fits a [lines]-line title (plus optional subtitle).
double appBarWrappedHeight(
  BuildContext context,
  TextStyle? style, {
  required int lines,
  bool hasSubtitle = false,
  double? base,
}) {
  final scaler = MediaQuery.textScalerOf(context);
  final lineHeight = scaler.scale(style?.fontSize ?? 20) * (style?.height ?? 1.3);
  final subtitleHeight = hasSubtitle ? scaler.scale(12) * 1.4 : 0.0;
  final needed = lines * lineHeight + subtitleHeight + 16;
  final floor = base ?? kToolbarHeight;
  return needed > floor ? needed : floor;
}

class MerchantScaffold extends StatelessWidget {
  const MerchantScaffold({
    super.key,
    required this.body,
    this.title,
    this.subtitle,
    this.leading,
    this.actions,
    this.bottom,
    this.floatingActionButton,
    this.centerTitle = false,
    this.headerDivider = false,
    this.titleSpacing,
    this.automaticallyImplyLeading = true,
    this.subtitleWidget,
    this.titleStyle,
    this.headerColor,
    this.headerHeight,
    this.bodyPadding = const EdgeInsets.symmetric(horizontal: 16),
  });

  final Widget body;

  /// Horizontal inset of [body]; zero lets sticky footers span the width.
  final EdgeInsetsGeometry bodyPadding;
  final String? title;
  final String? subtitle;

  /// Rich subtitle (e.g. branch + open dot); wins over [subtitle].
  final Widget? subtitleWidget;
  final TextStyle? titleStyle;
  final Color? headerColor;
  final double? headerHeight;
  final Widget? leading;
  final List<Widget>? actions;
  final Widget? bottom;
  final Widget? floatingActionButton;
  final bool centerTitle;
  final bool headerDivider;
  final double? titleSpacing;
  final bool automaticallyImplyLeading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canPop = ModalRoute.of(context)?.canPop ?? false;
    final hasLeading =
        leading != null || (canPop && automaticallyImplyLeading);
    final resolvedTitleStyle = titleStyle ??
        theme.appBarTheme.titleTextStyle ??
        theme.textTheme.titleLarge;
    final titleLines = title == null
        ? 1
        : appBarTitleLines(
            context,
            title!,
            resolvedTitleStyle,
            hasLeading: hasLeading,
            actionCount: actions?.length ?? 0,
            actionsWidth: appBarActionsWidth(context, actions),
            titleSpacing: titleSpacing,
          );
    final hasSubtitle = subtitleWidget != null ||
        (subtitle != null && subtitle!.isNotEmpty);
    final toolbarHeight = titleLines > 1
        ? appBarWrappedHeight(
            context,
            resolvedTitleStyle,
            lines: titleLines,
            hasSubtitle: hasSubtitle,
            base: headerHeight,
          )
        : headerHeight;
    return MerchantSnackBarScope(
      child: Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: title == null
          ? null
          : AppBar(
              centerTitle: centerTitle,
              automaticallyImplyLeading: automaticallyImplyLeading,
              backgroundColor: headerColor,
              toolbarHeight: toolbarHeight,
              titleSpacing: titleSpacing,
              shape: headerDivider
                  ? const Border(
                      bottom: BorderSide(color: AppColors.outlineVariant),
                    )
                  : null,
              titleTextStyle: titleStyle,
              leading: leading ??
                  (canPop && automaticallyImplyLeading
                      ? IconButton(
                          key: const Key('merchant-back'),
                          tooltip: MaterialLocalizations.of(context)
                              .backButtonTooltip,
                          icon: const Icon(Icons.arrow_back),
                          onPressed: () {
                            if (Navigator.of(context).canPop()) {
                              Navigator.of(context).pop();
                            }
                          },
                        )
                      : null),
              title: !hasSubtitle
                  ? Text(
                      title!,
                      maxLines: titleLines,
                      overflow: TextOverflow.ellipsis,
                      textAlign:
                          centerTitle ? TextAlign.center : TextAlign.start,
                    )
                  : Column(
                      crossAxisAlignment:
                          centerTitle ? CrossAxisAlignment.center : CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title!,
                          maxLines: titleLines,
                          overflow: TextOverflow.ellipsis,
                          textAlign:
                              centerTitle ? TextAlign.center : TextAlign.start,
                        ),
                        subtitleWidget ??
                            Text(
                              subtitle!,
                              key: const Key('orders-branch-context'),
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: AppColors.onSurfaceVariant,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                      ],
                    ),
              actions: actions,
            ),
      body: SafeArea(
        // Keep bottom free for sticky bars / keyboard; top uses AppBar.
        bottom: false,
        child: Padding(
          padding: bodyPadding,
          child: body,
        ),
      ),
      bottomNavigationBar: bottom,
      floatingActionButton: floatingActionButton,
      ),
    );
  }
}

/// Gap between a lifted snack bar and the sticky bar below it.
const double _snackBarStickyGap = 8;

/// Wraps a [Scaffold] whose body may end with a [MerchantStickyBar].
///
/// The Scaffold anchors snack bars to the bottom of its body, which is where
/// an in-body sticky bar sits, so they would cover its primary action. Each
/// sticky bar below this scope reports its height above the bottom safe area
/// (it follows text scale and the keyboard), and the scope floats the
/// Scaffold's snack bars that far up. Without a sticky bar nothing changes.
class MerchantSnackBarScope extends StatefulWidget {
  const MerchantSnackBarScope({super.key, required this.child});

  final Widget child;

  @override
  State<MerchantSnackBarScope> createState() => _MerchantSnackBarScopeState();
}

class _MerchantSnackBarScopeState extends State<MerchantSnackBarScope> {
  final _bars = <Object, double>{};
  double _lift = 0;

  /// Height of the tallest sticky bar reported here.
  @visibleForTesting
  double get lift => _lift;

  void _report(Object bar, double? height) {
    if (height == null) {
      _bars.remove(bar);
    } else {
      _bars[bar] = height;
    }
    final lift = _bars.values.fold<double>(0, math.max);
    if (lift != _lift && mounted) setState(() => _lift = lift);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Theme(
      data: _lift <= 0
          ? theme
          : theme.copyWith(
              snackBarTheme: theme.snackBarTheme.copyWith(
                behavior: SnackBarBehavior.floating,
                insetPadding: EdgeInsets.fromLTRB(
                  16,
                  5,
                  16,
                  _lift + _snackBarStickyGap,
                ),
              ),
            ),
      child: widget.child,
    );
  }
}

/// Calls [onSize] after the frame in which its child's size changed.
class MerchantSizeReporter extends SingleChildRenderObjectWidget {
  const MerchantSizeReporter({
    super.key,
    required this.onSize,
    super.child,
  });

  final ValueChanged<Size> onSize;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderSizeReporter(onSize);

  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) {
    (renderObject as _RenderSizeReporter).onSize = onSize;
  }
}

class _RenderSizeReporter extends RenderProxyBox {
  _RenderSizeReporter(this.onSize);

  ValueChanged<Size> onSize;
  Size? _reported;

  @override
  void performLayout() {
    super.performLayout();
    if (size == _reported) return;
    _reported = size;
    final reported = size;
    // Listeners rebuild widgets, which is not allowed during layout.
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (attached) onSize(reported);
    });
  }
}

/// Reference status chip: `label-md` text, 4 px radius (or pill), optional
/// leading icon (DESIGN.md: status chips carry an icon).
class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.label,
    this.tone = StatusTone.info,
    this.icon,
    this.pill = false,
  });

  final String label;
  final StatusTone tone;
  final IconData? icon;
  final bool pill;

  @override
  Widget build(BuildContext context) {
    final (Color bg, Color fg) = statusToneColors(tone);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: pill ? 10 : 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(pill ? 999 : 4),
        border: Border.all(color: fg.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: fg),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: fg,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    height: 1.33,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

enum StatusTone { success, warning, error, info, fresh, neutral }

(Color, Color) statusToneColors(StatusTone tone) => switch (tone) {
      StatusTone.success => (const Color(0xFFE8F5D3), AppColors.tertiary),
      StatusTone.warning => (AppColors.warningWash, AppColors.warning),
      StatusTone.error => (AppColors.errorContainer, AppColors.error),
      StatusTone.info => (AppColors.surfaceContainer, AppColors.primary),
      StatusTone.fresh => (AppColors.tertiaryFixed, AppColors.onTertiaryFixed),
      StatusTone.neutral => (
          AppColors.surfaceContainerHigh,
          AppColors.onSurfaceVariant,
        ),
    };

/// Header bell with the reference 8 px error dot; the count stays in
/// semantics only.
class MerchantBellButton extends StatelessWidget {
  const MerchantBellButton({
    super.key,
    required this.unread,
    required this.onPressed,
  });

  final int unread;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: unread > 0
          ? '${AppStrings.notificationsTitle} ($unread)'
          : AppStrings.notificationsTitle,
      button: true,
      excludeSemantics: true,
      child: IconButton(
        tooltip: AppStrings.notificationsTitle,
        onPressed: onPressed,
        icon: Stack(
          clipBehavior: Clip.none,
          children: [
            const Icon(
              Icons.notifications_outlined,
              color: AppColors.onSurfaceVariant,
            ),
            if (unread > 0)
              Positioned(
                top: 1,
                right: 2,
                child: Container(
                  key: const Key('bell-unread-dot'),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.background, width: 1),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class LoadingBody extends StatelessWidget {
  const LoadingBody({super.key, this.message});
  final String? message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(message ?? AppStrings.loading),
        ],
      ),
    );
  }
}

class ErrorBody extends StatelessWidget {
  const ErrorBody({
    super.key,
    required this.message,
    this.onRetry,
  });

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, textAlign: TextAlign.center),
          if (onRetry != null) ...[
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text(AppStrings.retry)),
          ],
        ],
      ),
    );
  }
}

/// White card: 12 px radius, soft `shadow-card`, `outline-variant/30` edge.
class MerchantCard extends StatelessWidget {
  const MerchantCard({super.key, required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(MerchantLayout.radiusCard);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: merchantCardShadow,
      ),
      child: Material(
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(
            color: AppColors.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: padding ?? const EdgeInsets.all(MerchantLayout.gutter),
          child: child,
        ),
      ),
    );
  }
}

/// Green-dot operational / account status pill (reference “Actif”, not Ouvert).
class MerchantStatusPill extends StatelessWidget {
  const MerchantStatusPill({
    super.key,
    required this.label,
    this.tone = StatusTone.success,
  });

  final String label;
  final StatusTone tone;

  @override
  Widget build(BuildContext context) {
    final (Color bg, Color fg, Color dot) = switch (tone) {
      StatusTone.success || StatusTone.fresh => (
          AppColors.tertiaryFixed,
          AppColors.onTertiaryFixed,
          AppColors.tertiary,
        ),
      StatusTone.neutral => (
          AppColors.surfaceContainerHigh,
          AppColors.onSurfaceVariant,
          AppColors.outline,
        ),
      StatusTone.warning => (
          AppColors.warningWash,
          AppColors.warning,
          AppColors.warning,
        ),
      StatusTone.error => (
          AppColors.errorContainer,
          AppColors.error,
          AppColors.error,
        ),
      StatusTone.info => (
          AppColors.surfaceContainer,
          AppColors.primary,
          AppColors.primary,
        ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: fg,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

class MerchantSectionLabel extends StatelessWidget {
  const MerchantSectionLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text.toUpperCase(),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: AppColors.primary,
              letterSpacing: 0.8,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class MerchantIconCircle extends StatelessWidget {
  const MerchantIconCircle({super.key, required this.icon, this.size = 40});

  final IconData icon;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainerLow,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: AppColors.primary, size: size * 0.45),
    );
  }
}

/// Settings / store-profile navigation row matching reference lists.
class MerchantNavRow extends StatelessWidget {
  const MerchantNavRow({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.enabled = true,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: enabled ? onTap : null,
      child: Opacity(
        opacity: enabled ? 1 : 0.45,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MerchantIconCircle(icon: icon),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (subtitle != null && subtitle!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) ...[
                Flexible(child: trailing!),
                const SizedBox(width: 4),
              ],
              const Icon(
                Icons.chevron_right,
                color: AppColors.outline,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MerchantStickyBar extends StatefulWidget {
  const MerchantStickyBar({super.key, required this.child});

  final Widget child;

  @override
  State<MerchantStickyBar> createState() => _MerchantStickyBarState();
}

class _MerchantStickyBarState extends State<MerchantStickyBar> {
  _MerchantSnackBarScopeState? _scope;
  double _safeBottom = 0;
  Size? _size;

  void _onSize(Size size) {
    if (!mounted) return;
    _size = size;
    _scope?._report(this, math.max(0, size.height - _safeBottom));
  }

  @override
  void dispose() {
    final scope = _scope;
    // The tree is locked while this state is disposed.
    if (scope != null) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (scope.mounted) scope._report(this, null);
      });
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scope = context.findAncestorStateOfType<_MerchantSnackBarScopeState>();
    if (!identical(scope, _scope)) {
      final previous = _scope;
      if (previous != null) {
        SchedulerBinding.instance.addPostFrameCallback((_) {
          if (previous.mounted) previous._report(this, null);
        });
      }
      _scope = scope;
      final size = _size;
      if (scope != null && size != null) {
        SchedulerBinding.instance.addPostFrameCallback((_) => _onSize(size));
      }
    }
    // The inner SafeArea pads by this; the Scaffold already keeps floating
    // snack bars above it.
    _safeBottom = MediaQuery.paddingOf(context).bottom;
    return MerchantSizeReporter(onSize: _onSize, child: _bar());
  }

  Widget _bar() {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(
            color: AppColors.outlineVariant.withValues(alpha: 0.45),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            offset: const Offset(0, -2),
            blurRadius: 8,
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: widget.child,
        ),
      ),
    );
  }
}

/// Section card with icon + title matching MerchantScreens editor references.
class MerchantEditorSection extends StatelessWidget {
  const MerchantEditorSection({
    super.key,
    required this.title,
    required this.icon,
    required this.children,
    this.trailing,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return MerchantCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: AppColors.primaryContainer),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 14),
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            children[i],
          ],
        ],
      ),
    );
  }
}

/// Persistent label above the field (avoids floating-label clip at card top).
class MerchantLabeledField extends StatelessWidget {
  const MerchantLabeledField({
    super.key,
    required this.label,
    required this.child,
    this.requiredMark = false,
    this.helper,
  });

  final String label;
  final Widget child;
  final bool requiredMark;
  final String? helper;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text.rich(
          TextSpan(
            text: label,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.onSurface,
            ),
            children: [
              if (requiredMark)
                const TextSpan(
                  text: ' *',
                  style: TextStyle(color: AppColors.error),
                ),
            ],
          ),
        ),
        if (helper != null && helper!.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            helper!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

/// Compact disabled row for reference-only controls (merchant-facing copy).
class MerchantContractGapRow extends StatelessWidget {
  const MerchantContractGapRow({
    super.key,
    required this.label,
    this.detail = AppStrings.contractFieldUnavailable,
  });

  final String label;
  final String detail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ExcludeSemantics(
      excluding: false,
      child: Opacity(
        opacity: 0.55,
        child: IgnorePointer(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.outlineVariant.withValues(alpha: 0.7),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    detail,
                    textAlign: TextAlign.end,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
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

class MerchantDualStickyBar extends StatelessWidget {
  const MerchantDualStickyBar({
    super.key,
    required this.secondary,
    required this.primary,
  });

  final Widget secondary;
  final Widget primary;

  @override
  Widget build(BuildContext context) {
    final stacked = MediaQuery.textScalerOf(context).scale(1) >= 1.25;
    return MerchantStickyBar(
      child: stacked
          ? Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [primary, const SizedBox(height: 8), secondary],
            )
          : Row(
              children: [
                Expanded(flex: 2, child: secondary),
                const SizedBox(width: 12),
                Expanded(flex: 3, child: primary),
              ],
            ),
    );
  }
}
