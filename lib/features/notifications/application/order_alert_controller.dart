import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speedygo_merchant_app/features/access/application/access_controller.dart';
import 'package:speedygo_merchant_app/features/access/data/merchant_api.dart';
import 'package:speedygo_merchant_app/features/auth/application/auth_infrastructure.dart';
import 'package:speedygo_merchant_app/features/auth/application/session_controller.dart';
import 'package:speedygo_merchant_app/features/auth/application/session_state.dart';
import 'package:speedygo_merchant_app/features/notifications/application/merchant_push_controller.dart';
import 'package:speedygo_merchant_app/features/notifications/data/notification_preferences.dart';
import 'package:speedygo_merchant_app/features/notifications/data/push_messaging_gateway.dart';
import 'package:speedygo_merchant_app/features/notifications/domain/incoming_order_alert.dart';
import 'package:speedygo_merchant_app/features/orders/application/orders_controller.dart';
import 'package:speedygo_merchant_app/features/orders/data/order_models.dart';
import 'package:speedygo_merchant_app/features/store/application/store_controllers.dart';
import 'package:speedygo_merchant_app/features/store/data/store_models.dart';

/// Documented foreground refresh interval for merchant new-order discovery.
/// Server has no merchant-order Socket.IO channel. Native Push (when
/// configured) only triggers an early reconcile; polling stays authoritative.
const Duration kMerchantOrderAlertPollInterval = Duration(seconds: 8);

/// When set (integration/live harness only), presence of this file simulates offline.
const String kAlertOfflineGateEnv = 'ALERT_OFFLINE_GATE';

class OrderAlertState {
  const OrderAlertState({this.activeAlert, this.busy = false, this.lastError});

  final IncomingOrderAlert? activeAlert;
  final bool busy;
  final String? lastError;

  OrderAlertState copyWith({
    IncomingOrderAlert? activeAlert,
    bool clearAlert = false,
    bool? busy,
    String? lastError,
    bool clearError = false,
  }) {
    return OrderAlertState(
      activeAlert: clearAlert ? null : (activeAlert ?? this.activeAlert),
      busy: busy ?? this.busy,
      lastError: clearError ? null : (lastError ?? this.lastError),
    );
  }
}

/// Lifecycle-aware poller: inbox + incoming orders, session dedupe, one alert.
class OrderAlertController extends Notifier<OrderAlertState> {
  Timer? _timer;
  bool _tickInFlight = false;
  bool _pushReconcilePending = false;
  bool _started = false;
  AppLifecycleState? _lifecycle = AppLifecycleState.resumed;

  /// Bumped on stop/logout so in-flight reconciles cannot mutate UI.
  int _reconcileEpoch = 0;

  /// Order ids already surfaced as alerts this session (push/poll/reconnect).
  final Set<String> _alertedOrderIds = <String>{};

  /// Pending queue (FIFO); only one [activeAlert] shown at a time.
  final List<IncomingOrderAlert> _queue = <IncomingOrderAlert>[];

  MerchantNotificationPreferences _prefs =
      const MerchantNotificationPreferences();

  @override
  OrderAlertState build() {
    ref.onDispose(() {
      _timer?.cancel();
      _timer = null;
      _started = false;
    });
    ref.listen(sessionControllerProvider, (prev, next) {
      if (next.phase != SessionPhase.ready) {
        stop();
        return;
      }
      // Another account's alerts and queue must never survive into this one.
      final accountChanged =
          prev?.accountId != null && prev!.accountId != next.accountId;
      if (accountChanged) stop();
      if (accountChanged ||
          prev?.phase != SessionPhase.ready ||
          prev?.generation != next.generation) {
        unawaited(start());
      }
    });
    ref.listen(accessControllerProvider, (prev, next) {
      if (prev?.selectedBranch?.id != next.selectedBranch?.id) {
        _queue.removeWhere((a) => a.branchId != next.selectedBranch?.id);
        if (state.activeAlert != null &&
            state.activeAlert!.branchId != next.selectedBranch?.id) {
          state = state.copyWith(clearAlert: true);
          unawaited(_promoteQueueFresh());
        }
        unawaited(reconcile(reason: 'branch_switch'));
      }
    });
    return const OrderAlertState();
  }

  Future<void> start() async {
    if (_started) return;
    _started = true;
    try {
      _prefs = await MerchantNotificationPreferences.load();
    } catch (_) {
      // Unreadable local prefs must not disable the new-order poll; keep the
      // last known (default: enabled) preferences.
    }
    // Disposed or stopped (logout) while prefs were loading: scheduling now
    // would leave a poll timer nothing cancels.
    if (!ref.mounted || !_started) return;
    _schedule();
    await reconcile(reason: 'start');
  }

  /// Stops polling, clears queue/alerts, invalidates in-flight applies.
  void stop() {
    _timer?.cancel();
    _timer = null;
    _started = false;
    _reconcileEpoch++;
    _alertedOrderIds.clear();
    _queue.clear();
    state = const OrderAlertState();
  }

  void onLifecycle(AppLifecycleState lifecycle) {
    _lifecycle = lifecycle;
    if (lifecycle == AppLifecycleState.resumed) {
      unawaited(reconcile(reason: 'resume'));
      _schedule();
    } else if (lifecycle == AppLifecycleState.paused ||
        lifecycle == AppLifecycleState.inactive ||
        lifecycle == AppLifecycleState.detached ||
        lifecycle == AppLifecycleState.hidden) {
      _timer?.cancel();
      _timer = null;
    }
  }

  Future<void> reloadPreferences() async {
    _prefs = await MerchantNotificationPreferences.load();
  }

  void dismissActive() {
    state = state.copyWith(clearAlert: true);
    unawaited(_promoteQueueFresh());
  }

  /// Mark order as handled for alert dedupe (accepted/rejected/opened).
  /// [promoteNext] false when navigating away so another overlay does not
  /// immediately replace the one just dismissed.
  void markOrderHandled(String orderId, {bool promoteNext = true}) {
    _alertedOrderIds.add(orderId);
    _queue.removeWhere((a) => a.orderId == orderId);
    if (state.activeAlert?.orderId == orderId) {
      state = state.copyWith(clearAlert: true);
      if (promoteNext) {
        unawaited(_promoteQueueFresh());
      }
    }
  }

  /// Visible for tests: how many alerts are waiting behind the active one.
  int get queuedAlertCount => _queue.length;

  /// Foreground native Push for a new order: reconcile now instead of waiting
  /// for the next poll. The same server fetch + [_alertedOrderIds] dedupe
  /// applies, so push and poll never surface the same order twice.
  Future<void> onPushHint(PushOrderHint hint) async {
    if (!_started) return;
    if (_alertedOrderIds.contains(hint.orderId) ||
        state.activeAlert?.orderId == hint.orderId ||
        _queue.any((a) => a.orderId == hint.orderId)) {
      return;
    }
    if (_tickInFlight) {
      _pushReconcilePending = true;
      return;
    }
    await reconcile(reason: 'push');
  }

  bool _reservedForPushNavigation(String orderId) =>
      ref.read(merchantPushControllerProvider).pendingOpen?.orderId == orderId;

  Future<void> reconcile({String reason = 'manual'}) async {
    if (_tickInFlight) return;
    final session = ref.read(sessionControllerProvider);
    if (session.phase != SessionPhase.ready) return;
    final access = ref.read(accessControllerProvider);
    final branchId = access.selectedBranch?.id;
    final merchantId = access.membership?.merchantId;
    if (branchId == null ||
        branchId.isEmpty ||
        merchantId == null ||
        merchantId.isEmpty) {
      return;
    }

    final epoch = _reconcileEpoch;
    final sessionGen = session.generation;
    _tickInFlight = true;
    try {
      _assertOnlineGate();
      final api = ref.read(merchantApiProvider);
      final notifications = await api.listNotifications(limit: 30);
      if (!_mayApply(epoch, sessionGen)) return;

      ref.invalidate(notificationsUnreadCountProvider);
      unawaited(ref.read(ordersListControllerProvider.notifier).reloadQuiet());
      ref.invalidate(homeOrderCountsProvider);

      if (reason == 'resume' && state.activeAlert != null) {
        await refreshActiveFromServer();
        if (!_mayApply(epoch, sessionGen)) return;
      }

      final candidates = <MerchantNotificationItem>[];
      for (final n in notifications) {
        if (n.type != 'MERCHANT_ORDER_CREATED') continue;
        final orderId = n.sourceId;
        if (orderId == null || orderId.isEmpty) continue;
        if (_alertedOrderIds.contains(orderId)) continue;
        if (_queue.any((a) => a.orderId == orderId)) continue;
        if (state.activeAlert?.orderId == orderId) continue;
        candidates.add(n);
      }

      for (final n in candidates) {
        if (!_mayApply(epoch, sessionGen)) return;
        final orderId = n.sourceId!;
        MerchantOrderDetail detail;
        try {
          detail = await api.getOrder(merchantId: merchantId, orderId: orderId);
        } catch (_) {
          // No access / wrong merchant → never surface (anti-leakage).
          _alertedOrderIds.add(orderId);
          continue;
        }
        if (!_mayApply(epoch, sessionGen)) return;
        if (detail.merchantBranchId != branchId) {
          continue;
        }
        if (detail.fulfillmentStatus != 'PENDING_ACCEPTANCE' ||
            detail.status.toUpperCase() == 'CANCELLED') {
          _alertedOrderIds.add(orderId);
          continue;
        }
        if (!_prefs.foregroundAlertsEnabled) {
          _alertedOrderIds.add(orderId);
          continue;
        }
        _enqueue(
          IncomingOrderAlert.fromDetail(detail: detail, notificationId: n.id),
        );
      }

      // Every poll/resume/start also recovers from the incoming list so
      // multiple orders between ticks are not silently lost if inbox lags.
      await _recoverFromIncomingList(
        api: api,
        merchantId: merchantId,
        branchId: branchId,
        epoch: epoch,
        sessionGen: sessionGen,
      );

      if (_mayApply(epoch, sessionGen)) {
        state = state.copyWith(clearError: true);
      }
    } catch (e) {
      // Network / offline: do not open dialogs or enqueue duplicates.
      // Keep _tickInFlight until finally so polls do not overlap.
      if (_mayApply(epoch, sessionGen)) {
        state = state.copyWith(lastError: e.toString());
      }
    } finally {
      _tickInFlight = false;
      if (_pushReconcilePending) {
        _pushReconcilePending = false;
        unawaited(reconcile(reason: 'push'));
      }
    }
  }

  Future<void> _recoverFromIncomingList({
    required MerchantClient api,
    required String merchantId,
    required String branchId,
    required int epoch,
    required int sessionGen,
  }) async {
    if (!_prefs.foregroundAlertsEnabled) return;
    if (!_mayApply(epoch, sessionGen)) return;
    final page = await api.listOrders(
      merchantId: merchantId,
      branchId: branchId,
      orderStatus: MerchantOrderListFilter.incoming.orderStatus,
      fulfillmentStatus: MerchantOrderListFilter.incoming.fulfillmentStatus,
      limit: 20,
    );
    if (!_mayApply(epoch, sessionGen)) return;
    for (final summary in page.items) {
      if (!_mayApply(epoch, sessionGen)) return;
      if (_alertedOrderIds.contains(summary.id)) continue;
      if (_queue.any((a) => a.orderId == summary.id)) continue;
      if (state.activeAlert?.orderId == summary.id) continue;
      if (summary.merchantBranchId != branchId) continue;
      if (summary.fulfillmentStatus != 'PENDING_ACCEPTANCE') continue;
      try {
        final detail = await api.getOrder(
          merchantId: merchantId,
          orderId: summary.id,
        );
        if (!_mayApply(epoch, sessionGen)) return;
        if (detail.merchantBranchId != branchId) continue;
        if (detail.fulfillmentStatus != 'PENDING_ACCEPTANCE' ||
            detail.status.toUpperCase() == 'CANCELLED') {
          _alertedOrderIds.add(summary.id);
          continue;
        }
        _enqueue(
          IncomingOrderAlert.fromDetail(detail: detail, notificationId: ''),
        );
      } catch (_) {
        continue;
      }
    }
  }

  void _enqueue(IncomingOrderAlert alert) {
    if (_alertedOrderIds.contains(alert.orderId)) return;
    // A notification tap is about to open this order directly.
    if (_reservedForPushNavigation(alert.orderId)) return;
    if (state.activeAlert == null) {
      _alertedOrderIds.add(alert.orderId);
      state = state.copyWith(activeAlert: alert, clearError: true);
      _signalNewAlert();
    } else if (!_queue.any((a) => a.orderId == alert.orderId)) {
      _queue.add(alert);
    }
  }

  /// Promote next queued alert after refreshing server state (stale-safe).
  Future<void> _promoteQueueFresh() async {
    final session = ref.read(sessionControllerProvider);
    if (session.phase != SessionPhase.ready) return;
    final access = ref.read(accessControllerProvider);
    final merchantId = access.membership?.merchantId;
    final branchId = access.selectedBranch?.id;
    if (merchantId == null || branchId == null) {
      _queue.clear();
      return;
    }

    while (_queue.isNotEmpty) {
      final next = _queue.removeAt(0);
      if (_alertedOrderIds.contains(next.orderId) &&
          state.activeAlert?.orderId != next.orderId) {
        continue;
      }
      if (_reservedForPushNavigation(next.orderId)) continue;
      try {
        final detail = await ref
            .read(merchantApiProvider)
            .getOrder(merchantId: merchantId, orderId: next.orderId);
        if (session.phase != SessionPhase.ready) return;
        if (detail.merchantBranchId != branchId) continue;
        if (detail.fulfillmentStatus != 'PENDING_ACCEPTANCE' ||
            detail.status.toUpperCase() == 'CANCELLED') {
          _alertedOrderIds.add(next.orderId);
          continue;
        }
        final fresh = IncomingOrderAlert.fromDetail(
          detail: detail,
          notificationId: next.notificationId,
        );
        _alertedOrderIds.add(fresh.orderId);
        state = state.copyWith(activeAlert: fresh, clearError: true);
        _signalNewAlert();
        return;
      } catch (_) {
        _alertedOrderIds.add(next.orderId);
        continue;
      }
    }
  }

  void _signalNewAlert() {
    if (_prefs.vibrationEnabled) {
      HapticFeedback.heavyImpact();
    }
    if (_prefs.soundEnabled) {
      SystemSound.play(SystemSoundType.alert);
    }
  }

  void _schedule() {
    _timer?.cancel();
    if (_lifecycle != AppLifecycleState.resumed) return;
    if (!_started) return;
    _timer = Timer.periodic(kMerchantOrderAlertPollInterval, (_) {
      unawaited(reconcile(reason: 'poll'));
    });
  }

  /// Refresh active alert from server (outdated → current; never show handled).
  Future<IncomingOrderAlert?> refreshActiveFromServer() async {
    final current = state.activeAlert;
    if (current == null) return null;
    final access = ref.read(accessControllerProvider);
    final merchantId = access.membership?.merchantId;
    if (merchantId == null) return current;
    try {
      final detail = await ref
          .read(merchantApiProvider)
          .getOrder(merchantId: merchantId, orderId: current.orderId);
      final updated = IncomingOrderAlert.fromDetail(
        detail: detail,
        notificationId: current.notificationId,
      );
      if (!updated.isStillIncoming) {
        // Already handled / not awaiting acceptance — do not keep as new-order.
        markOrderHandled(current.orderId, promoteNext: true);
        return updated;
      }
      state = state.copyWith(activeAlert: updated);
      return updated;
    } catch (_) {
      return current;
    }
  }

  bool _mayApply(int epoch, int sessionGen) {
    if (epoch != _reconcileEpoch) return false;
    if (!_started) return false;
    final session = ref.read(sessionControllerProvider);
    if (session.phase != SessionPhase.ready) return false;
    if (session.generation != sessionGen) return false;
    return true;
  }

  void _assertOnlineGate() {
    const gate = String.fromEnvironment(kAlertOfflineGateEnv);
    if (gate.isEmpty) return;
    if (File(gate).existsSync()) {
      throw const SocketException('simulated offline (ALERT_OFFLINE_GATE)');
    }
  }
}

final orderAlertControllerProvider =
    NotifierProvider<OrderAlertController, OrderAlertState>(
      OrderAlertController.new,
    );
