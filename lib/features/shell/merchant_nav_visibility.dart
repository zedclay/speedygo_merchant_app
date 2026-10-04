import 'package:flutter/widgets.dart';
import 'package:speedygo_merchant_app/app/theme/app_theme.dart';

/// Hide / reveal rules for the Concept V1 merchant dock.
///
/// Only [applyPrimaryVerticalScroll] changes visibility from scrolling.
/// Callers must already have filtered nested, horizontal, and suppressed
/// notifications.
class MerchantNavVisibilityController extends ChangeNotifier {
  MerchantNavVisibilityController({
    this.hideThreshold = MerchantNavTokens.hideThreshold,
  });

  final double hideThreshold;

  bool _visible = true;
  bool _autoHideEnabled = true;
  double _downAccum = 0;

  bool get visible => _visible;
  bool get autoHideEnabled => _autoHideEnabled;

  @visibleForTesting
  double get downAccum => _downAccum;

  void reveal() {
    _downAccum = 0;
    if (_visible) return;
    _visible = true;
    notifyListeners();
  }

  void hide() {
    if (!_autoHideEnabled || !_visible) return;
    _visible = false;
    _downAccum = 0;
    notifyListeners();
  }

  /// When false, the dock stays revealed and scroll cannot hide it.
  void setAutoHideEnabled(bool enabled) {
    if (_autoHideEnabled == enabled) return;
    _autoHideEnabled = enabled;
    if (!enabled) {
      reveal();
    }
  }

  /// Primary vertical scroll of the selected root page.
  ///
  /// [delta] follows [ScrollUpdateNotification.scrollDelta]: positive when
  /// the user scrolls content down (finger moves up).
  void applyPrimaryVerticalScroll({
    required double pixels,
    required double minScrollExtent,
    required double delta,
  }) {
    if (!_autoHideEnabled) return;
    if (pixels <= minScrollExtent) {
      reveal();
      return;
    }
    if (delta > 0) {
      _downAccum += delta;
      if (_downAccum >= hideThreshold) {
        hide();
      }
      return;
    }
    if (delta < 0) {
      _downAccum = 0;
      reveal();
    }
  }

  /// Returns false so other listeners (pagination, refresh) still run.
  bool handle(ScrollNotification notification) {
    if (!_autoHideEnabled) return false;
    if (notification.depth != 0) return false;
    if (notification.metrics.axis != Axis.vertical) return false;
    if (notification.metrics.pixels <= notification.metrics.minScrollExtent) {
      reveal();
      return false;
    }
    if (notification is ScrollUpdateNotification) {
      final delta = notification.scrollDelta;
      if (delta == null || delta == 0) return false;
      // Ballistic settle and small rebound would jitter hide/reveal.
      if (notification.dragDetails == null) return false;
      applyPrimaryVerticalScroll(
        pixels: notification.metrics.pixels,
        minScrollExtent: notification.metrics.minScrollExtent,
        delta: delta,
      );
    }
    return false;
  }
}
