import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speedygo_merchant_app/app/router/app_router.dart';
import 'package:speedygo_merchant_app/core/constants/app_strings.dart';
import 'package:speedygo_merchant_app/core/navigation/app_routes.dart';
import 'package:speedygo_merchant_app/features/access/application/access_controller.dart';
import 'package:speedygo_merchant_app/features/auth/application/auth_infrastructure.dart';
import 'package:speedygo_merchant_app/features/auth/application/session_controller.dart';
import 'package:speedygo_merchant_app/features/auth/application/session_state.dart';
import 'package:speedygo_merchant_app/features/notifications/application/merchant_push_controller.dart';
import 'package:speedygo_merchant_app/features/notifications/application/order_alert_controller.dart';
import 'package:speedygo_merchant_app/features/notifications/data/push_messaging_gateway.dart';
import 'package:speedygo_merchant_app/features/notifications/presentation/incoming_order_alert_overlay.dart';
import 'package:speedygo_merchant_app/features/orders/application/orders_controller.dart';
import 'package:speedygo_merchant_app/features/orders/data/order_models.dart';

/// Hosts lifecycle polling + incoming-order alert overlay above the shell,
/// and routes native Push taps once auth and navigation are ready.
class MerchantAlertHost extends ConsumerStatefulWidget {
  const MerchantAlertHost({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<MerchantAlertHost> createState() => _MerchantAlertHostState();
}

class _MerchantAlertHostState extends ConsumerState<MerchantAlertHost>
    with WidgetsBindingObserver {
  bool _consumeScheduled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final session = ref.read(sessionControllerProvider);
      if (session.phase == SessionPhase.ready) {
        ref.read(orderAlertControllerProvider.notifier).start();
      }
      _maybeConsumePushTap();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    ref.read(orderAlertControllerProvider.notifier).onLifecycle(state);
    if (state == AppLifecycleState.resumed) {
      // OS permission may have changed in system Settings.
      unawaited(
        ref.read(merchantPushControllerProvider.notifier).syncRegistration(),
      );
    }
  }

  bool _canMutateOrders() => merchantRoleCanMutateOrders(
    ref.read(accessControllerProvider).membership?.role,
  );

  bool _navigationReady() {
    final session = ref.read(sessionControllerProvider);
    final access = ref.read(accessControllerProvider);
    return session.phase == SessionPhase.ready &&
        access.destination == AccessDestination.home &&
        access.membership != null &&
        access.selectedBranch != null;
  }

  /// Opens a tapped notification's order only after session restore, access
  /// resolution and the router's post-login redirect have settled.
  void _maybeConsumePushTap() {
    if (_consumeScheduled || !mounted) return;
    if (ref.read(merchantPushControllerProvider).pendingOpen == null) return;
    if (!_navigationReady()) return;
    _consumeScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _consumeScheduled = false;
      if (!mounted || !_navigationReady()) return;
      final hint = ref
          .read(merchantPushControllerProvider.notifier)
          .takePendingOpen();
      if (hint != null) unawaited(_openFromPush(hint));
    });
  }

  Future<void> _openFromPush(PushOrderHint hint) async {
    final merchantId = ref
        .read(accessControllerProvider)
        .membership
        ?.merchantId;
    if (hint.merchantId != null && hint.merchantId != merchantId) {
      ref
          .read(orderAlertControllerProvider.notifier)
          .markOrderHandled(hint.orderId, promoteNext: false);
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        const SnackBar(content: Text(AppStrings.pushOrderInaccessible)),
      );
      return;
    }
    await _openOrder(
      hint.orderId,
      notificationId: hint.notificationId,
      fromPush: true,
    );
  }

  Future<void> _openOrder(
    String orderId, {
    bool openReject = false,
    String? notificationId,
    bool fromPush = false,
  }) async {
    final alerts = ref.read(orderAlertControllerProvider.notifier);
    final prior = ref.read(orderAlertControllerProvider).activeAlert;
    final readId =
        notificationId ??
        (prior?.orderId == orderId ? prior?.notificationId : null) ??
        '';

    // Dismiss immediately so the overlay does not block navigation.
    // Do not promote the next queued alert while opening detail.
    alerts.markOrderHandled(orderId, promoteNext: false);

    final access = ref.read(accessControllerProvider);
    final branchId = access.selectedBranch?.id;
    final merchantId = access.membership?.merchantId;
    final messenger = ScaffoldMessenger.maybeOf(context);

    var stillIncoming = prior?.orderId == orderId
        ? prior!.isStillIncoming
        : !fromPush;
    if (merchantId != null) {
      try {
        final detail = await ref
            .read(merchantApiProvider)
            .getOrder(merchantId: merchantId, orderId: orderId);
        if (branchId != null && detail.merchantBranchId != branchId) {
          messenger?.showSnackBar(
            const SnackBar(content: Text(AppStrings.permissionDenied)),
          );
          return;
        }
        stillIncoming =
            detail.fulfillmentStatus == 'PENDING_ACCEPTANCE' &&
            detail.status.toUpperCase() != 'CANCELLED';
        if (!stillIncoming && (openReject || fromPush)) {
          messenger?.showSnackBar(
            const SnackBar(content: Text(AppStrings.notificationsOrderStale)),
          );
        }
      } catch (_) {
        if (fromPush) {
          // No access / deleted / network: never open a pushed order blind.
          messenger?.showSnackBar(
            const SnackBar(content: Text(AppStrings.pushOrderInaccessible)),
          );
          return;
        }
        // Navigate anyway; detail screen loads authoritative state.
      }
    }

    if (readId.isNotEmpty) {
      try {
        await ref.read(merchantApiProvider).markNotificationRead(readId);
      } catch (_) {}
    }

    // The detail family is not auto-disposed: drop any state cached from an
    // earlier visit so a handled order is never shown as still incoming.
    ref.invalidate(orderDetailControllerProvider(orderId));
    final router = ref.read(appRouterProvider);
    router.push(AppRoutes.orderDetail(orderId));
    if (openReject && stillIncoming && _canMutateOrders()) {
      messenger?.showSnackBar(
        const SnackBar(content: Text(AppStrings.orderRejectHint)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(
      merchantPushControllerProvider,
      (_, _) => _maybeConsumePushTap(),
    );
    ref.listen(sessionControllerProvider, (prev, next) {
      ref
          .read(merchantPushControllerProvider.notifier)
          .onSessionChanged(prev, next);
      _maybeConsumePushTap();
    });
    ref.listen(accessControllerProvider, (_, _) => _maybeConsumePushTap());
    final alert = ref.watch(orderAlertControllerProvider).activeAlert;
    final canReject = merchantRoleCanMutateOrders(
      ref.watch(accessControllerProvider.select((a) => a.membership?.role)),
    );
    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        if (alert != null)
          // The host sits above the navigator, so the alert needs its own
          // overlay for tooltips and other floating widgets.
          Positioned.fill(
            child: Overlay.wrap(
              child: IncomingOrderAlertOverlay(
                alert: alert,
                onDismiss: () => ref
                    .read(orderAlertControllerProvider.notifier)
                    .dismissActive(),
                onViewDetails: () {
                  unawaited(_openOrder(alert.orderId));
                },
                onRefuse: canReject
                    ? () {
                        if (!_canMutateOrders()) return;
                        unawaited(_openOrder(alert.orderId, openReject: true));
                      }
                    : null,
              ),
            ),
          ),
      ],
    );
  }
}
