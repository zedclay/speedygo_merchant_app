import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speedygo_merchant_app/core/constants/app_strings.dart';
import 'package:speedygo_merchant_app/core/errors/app_exception.dart';
import 'package:speedygo_merchant_app/features/access/application/access_controller.dart';
import 'package:speedygo_merchant_app/features/access/data/merchant_api.dart';
import 'package:speedygo_merchant_app/features/auth/application/auth_infrastructure.dart';
import 'package:speedygo_merchant_app/features/auth/application/session_controller.dart';
import 'package:speedygo_merchant_app/features/orders/data/order_models.dart';

class OrdersListState {
  const OrdersListState({
    required this.items,
    required this.total,
    required this.filter,
    required this.hasMore,
    required this.loadingMore,
  });

  final List<MerchantOrderSummary> items;
  final int total;
  final MerchantOrderListFilter filter;
  final bool hasMore;
  final bool loadingMore;

  OrdersListState copyWith({
    List<MerchantOrderSummary>? items,
    int? total,
    MerchantOrderListFilter? filter,
    bool? hasMore,
    bool? loadingMore,
  }) {
    return OrdersListState(
      items: items ?? this.items,
      total: total ?? this.total,
      filter: filter ?? this.filter,
      hasMore: hasMore ?? this.hasMore,
      loadingMore: loadingMore ?? this.loadingMore,
    );
  }
}

class OrdersListController extends AsyncNotifier<OrdersListState> {
  static const pageSize = 50;
  int _generation = 0;

  @override
  Future<OrdersListState> build() async {
    // Watch branch/account so list reloads and drops stale scopes.
    ref.watch(accessControllerProvider);
    ref.watch(sessionControllerProvider.select((s) => s.accountId));
    return _load(
      filter: MerchantOrderListFilter.incoming,
      offset: 0,
      append: false,
    );
  }

  Future<void> setFilter(MerchantOrderListFilter filter) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _load(filter: filter, offset: 0, append: false),
    );
  }

  Future<void> reload() async {
    final current = state.value?.filter ?? MerchantOrderListFilter.incoming;
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _load(filter: current, offset: 0, append: false),
    );
  }

  /// Background refresh without loading flash (alert poller / resume).
  Future<void> reloadQuiet() async {
    final current = state.value?.filter ?? MerchantOrderListFilter.incoming;
    try {
      final next = await _load(filter: current, offset: 0, append: false);
      state = AsyncData(next);
    } catch (_) {
      // Keep previous list; manual refresh still available.
    }
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasMore || current.loadingMore) return;
    state = AsyncData(current.copyWith(loadingMore: true));
    try {
      final next = await _load(
        filter: current.filter,
        offset: current.items.length,
        append: true,
        previous: current,
      );
      state = AsyncData(next);
    } catch (e, st) {
      state = AsyncData(current.copyWith(loadingMore: false));
      state = AsyncError(e, st);
    }
  }

  Future<OrdersListState> _load({
    required MerchantOrderListFilter filter,
    required int offset,
    required bool append,
    OrdersListState? previous,
  }) async {
    final access = ref.read(accessControllerProvider);
    final membership = access.membership;
    final branch = access.selectedBranch;
    final accountId = ref.read(sessionControllerProvider).accountId;
    if (membership == null || branch == null) {
      return OrdersListState(
        items: const [],
        total: 0,
        filter: filter,
        hasMore: false,
        loadingMore: false,
      );
    }
    final gen = ++_generation;
    final merchantId = membership.merchantId;
    final branchId = branch.id;
    final expectedAccount = accountId;
    final api = ref.read(merchantApiProvider);
    final page = await api.listOrders(
      merchantId: merchantId,
      branchId: branchId,
      orderStatus: filter.orderStatus,
      fulfillmentStatus: filter.fulfillmentStatus,
      limit: pageSize,
      offset: offset,
    );

    final latest = ref.read(accessControllerProvider);
    final latestSession = ref.read(sessionControllerProvider);
    if (gen != _generation) {
      return previous ??
          OrdersListState(
            items: const [],
            total: 0,
            filter: filter,
            hasMore: false,
            loadingMore: false,
          );
    }
    if (latest.selectedBranch?.id != branchId) {
      return OrdersListState(
        items: const [],
        total: 0,
        filter: filter,
        hasMore: false,
        loadingMore: false,
      );
    }
    if (latest.membership?.merchantId != merchantId) {
      return OrdersListState(
        items: const [],
        total: 0,
        filter: filter,
        hasMore: false,
        loadingMore: false,
      );
    }
    if (expectedAccount != null &&
        latestSession.accountId != null &&
        latestSession.accountId != expectedAccount) {
      return OrdersListState(
        items: const [],
        total: 0,
        filter: filter,
        hasMore: false,
        loadingMore: false,
      );
    }

    final merged = append && previous != null
        ? [...previous.items, ...page.items]
        : page.items;
    return OrdersListState(
      items: merged,
      total: page.total,
      filter: filter,
      hasMore: page.hasMore,
      loadingMore: false,
    );
  }
}

final ordersListControllerProvider =
    AsyncNotifierProvider<OrdersListController, OrdersListState>(
      OrdersListController.new,
    );

/// Home counts from list.total — never derived from a single page length.
class HomeOrderCounts {
  const HomeOrderCounts({
    this.accepted = 0,
    required this.incoming,
    required this.preparing,
    required this.ready,
  });

  final int incoming;
  final int accepted;
  final int preparing;
  final int ready;

  int get active => incoming + accepted + preparing + ready;
}

class HomeOrderCountsController extends AsyncNotifier<HomeOrderCounts> {
  int _generation = 0;

  @override
  Future<HomeOrderCounts> build() async {
    final access = ref.watch(accessControllerProvider);
    final membership = access.membership;
    final branch = access.selectedBranch;
    final accountId = ref.watch(sessionControllerProvider).accountId;
    if (membership == null || branch == null) {
      return const HomeOrderCounts(incoming: 0, preparing: 0, ready: 0);
    }
    final gen = ++_generation;
    final merchantId = membership.merchantId;
    final branchId = branch.id;
    final expectedAccount = accountId;
    final api = ref.read(merchantApiProvider);

    Future<int> totalFor({
      required String orderStatus,
      required String fulfillmentStatus,
    }) async {
      final page = await api.listOrders(
        merchantId: merchantId,
        branchId: branchId,
        orderStatus: orderStatus,
        fulfillmentStatus: fulfillmentStatus,
        limit: 1,
        offset: 0,
      );
      return page.total;
    }

    final incoming = await totalFor(
      orderStatus: 'CREATED',
      fulfillmentStatus: 'PENDING_ACCEPTANCE',
    );
    final accepted = await totalFor(
      orderStatus: 'CONFIRMED',
      fulfillmentStatus: 'ACCEPTED',
    );
    final preparing = await totalFor(
      orderStatus: 'ACTIVE',
      fulfillmentStatus: 'PREPARING',
    );
    final ready = await totalFor(
      orderStatus: 'ACTIVE',
      fulfillmentStatus: 'READY',
    );

    final latest = ref.read(accessControllerProvider);
    final latestSession = ref.read(sessionControllerProvider);
    if (gen != _generation) {
      return const HomeOrderCounts(incoming: 0, preparing: 0, ready: 0);
    }
    if (latest.selectedBranch?.id != branchId) {
      return const HomeOrderCounts(incoming: 0, preparing: 0, ready: 0);
    }
    if (latest.membership?.merchantId != merchantId) {
      return const HomeOrderCounts(incoming: 0, preparing: 0, ready: 0);
    }
    if (expectedAccount != null &&
        latestSession.accountId != null &&
        latestSession.accountId != expectedAccount) {
      return const HomeOrderCounts(incoming: 0, preparing: 0, ready: 0);
    }
    return HomeOrderCounts(
      incoming: incoming,
      accepted: accepted,
      preparing: preparing,
      ready: ready,
    );
  }

  Future<void> reload() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(build);
  }
}

final homeOrderCountsProvider =
    AsyncNotifierProvider<HomeOrderCountsController, HomeOrderCounts>(
      HomeOrderCountsController.new,
    );

/// Active home queue: up to 5 orders each for PENDING_ACCEPTANCE / PREPARING / READY.
class HomeActiveOrdersController
    extends AsyncNotifier<List<MerchantOrderSummary>> {
  int _generation = 0;

  @override
  Future<List<MerchantOrderSummary>> build() async {
    final access = ref.watch(accessControllerProvider);
    final membership = access.membership;
    final branch = access.selectedBranch;
    final accountId = ref.watch(sessionControllerProvider).accountId;
    if (membership == null || branch == null) return const [];

    final gen = ++_generation;
    final merchantId = membership.merchantId;
    final branchId = branch.id;
    final expectedAccount = accountId;
    final api = ref.read(merchantApiProvider);

    Future<List<MerchantOrderSummary>> pageFor({
      required String orderStatus,
      required String fulfillment,
    }) async {
      final page = await api.listOrders(
        merchantId: merchantId,
        branchId: branchId,
        orderStatus: orderStatus,
        fulfillmentStatus: fulfillment,
        limit: 5,
        offset: 0,
      );
      return page.items;
    }

    final incoming = await pageFor(
      orderStatus: 'CREATED',
      fulfillment: 'PENDING_ACCEPTANCE',
    );
    final preparing = await pageFor(
      orderStatus: 'ACTIVE',
      fulfillment: 'PREPARING',
    );
    final ready = await pageFor(orderStatus: 'ACTIVE', fulfillment: 'READY');

    final latest = ref.read(accessControllerProvider);
    final latestSession = ref.read(sessionControllerProvider);
    if (gen != _generation) return const [];
    if (latest.selectedBranch?.id != branchId) return const [];
    if (latest.membership?.merchantId != merchantId) return const [];
    if (expectedAccount != null &&
        latestSession.accountId != null &&
        latestSession.accountId != expectedAccount) {
      return const [];
    }

    final merged = <MerchantOrderSummary>[...incoming, ...preparing, ...ready];
    merged.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return merged;
  }

  Future<void> reload() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(build);
  }
}

final homeActiveOrdersProvider =
    AsyncNotifierProvider<
      HomeActiveOrdersController,
      List<MerchantOrderSummary>
    >(HomeActiveOrdersController.new);

class OrderDetailState {
  const OrderDetailState({
    required this.order,
    this.delivery,
    this.pickupHandoff,
    this.pickupHandoffLoading = false,
    this.pickupHandoffRegenerating = false,
    this.pickupHandoffError,
    this.mutating = false,
    this.actionError,
  });

  final MerchantOrderDetail order;
  final MerchantDeliverySummary? delivery;
  final MerchantPickupHandoff? pickupHandoff;
  final bool pickupHandoffLoading;
  final bool pickupHandoffRegenerating;
  final String? pickupHandoffError;
  final bool mutating;
  final String? actionError;

  OrderDetailState copyWith({
    MerchantOrderDetail? order,
    MerchantDeliverySummary? delivery,
    bool clearDelivery = false,
    MerchantPickupHandoff? pickupHandoff,
    bool clearPickupHandoff = false,
    bool? pickupHandoffLoading,
    bool? pickupHandoffRegenerating,
    String? pickupHandoffError,
    bool clearPickupHandoffError = false,
    bool? mutating,
    String? actionError,
    bool clearError = false,
  }) {
    return OrderDetailState(
      order: order ?? this.order,
      delivery: clearDelivery ? null : (delivery ?? this.delivery),
      pickupHandoff: clearPickupHandoff
          ? null
          : (pickupHandoff ?? this.pickupHandoff),
      pickupHandoffLoading: pickupHandoffLoading ?? this.pickupHandoffLoading,
      pickupHandoffRegenerating:
          pickupHandoffRegenerating ?? this.pickupHandoffRegenerating,
      pickupHandoffError: clearPickupHandoffError
          ? null
          : (pickupHandoffError ?? this.pickupHandoffError),
      mutating: mutating ?? this.mutating,
      actionError: clearError ? null : (actionError ?? this.actionError),
    );
  }
}

class OrderDetailController extends AsyncNotifier<OrderDetailState> {
  OrderDetailController(this.orderId);

  final String orderId;
  int _generation = 0;
  bool _inFlight = false;

  @override
  Future<OrderDetailState> build() async {
    ref.watch(accessControllerProvider);
    ref.watch(sessionControllerProvider.select((s) => s.accountId));
    return _fetch(orderId);
  }

  Future<void> reload() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetch(orderId));
  }

  Future<OrderDetailState> _fetch(String id) async {
    final access = ref.read(accessControllerProvider);
    final membership = access.membership;
    final branch = access.selectedBranch;
    final accountId = ref.read(sessionControllerProvider).accountId;
    if (membership == null) {
      throw const ApiException(
        'Commerce introuvable.',
        code: 'MERCHANT_NOT_FOUND',
        statusCode: 404,
      );
    }
    final gen = ++_generation;
    final merchantId = membership.merchantId;
    final expectedBranch = branch?.id;
    final expectedAccount = accountId;
    final api = ref.read(merchantApiProvider);
    final detail = await api.getOrder(merchantId: merchantId, orderId: id);

    final latest = ref.read(accessControllerProvider);
    final latestSession = ref.read(sessionControllerProvider);
    if (gen != _generation) {
      throw const ApiException('Réponse obsolète.', code: 'STALE');
    }
    if (latest.membership?.merchantId != merchantId) {
      throw const ApiException(
        'Commerce introuvable.',
        code: 'MERCHANT_NOT_FOUND',
        statusCode: 404,
      );
    }
    if (expectedAccount != null &&
        latestSession.accountId != null &&
        latestSession.accountId != expectedAccount) {
      throw const ApiException(
        'Commerce introuvable.',
        code: 'MERCHANT_NOT_FOUND',
        statusCode: 404,
      );
    }
    if (expectedBranch != null && detail.merchantBranchId != expectedBranch) {
      throw const ApiException(
        'Commande introuvable.',
        code: 'MERCHANT_ORDER_NOT_FOUND',
        statusCode: 404,
      );
    }
    if (latest.selectedBranch != null &&
        detail.merchantBranchId != latest.selectedBranch!.id) {
      throw const ApiException(
        'Commande introuvable.',
        code: 'MERCHANT_ORDER_NOT_FOUND',
        statusCode: 404,
      );
    }

    MerchantDeliverySummary? delivery;
    if (detail.fulfillmentStatus == 'READY' ||
        detail.status == 'ACTIVE' ||
        detail.status == 'COMPLETED') {
      try {
        delivery = await api.getOrderDelivery(
          merchantId: merchantId,
          orderId: id,
        );
      } catch (_) {
        delivery = null;
      }
    }

    final handoffBundle = await _loadPickupHandoff(
      api: api,
      merchantId: merchantId,
      orderId: id,
      delivery: delivery,
    );

    return OrderDetailState(
      order: detail,
      delivery: delivery,
      pickupHandoff: handoffBundle.handoff,
      pickupHandoffError: handoffBundle.error,
    );
  }

  bool _shouldLoadPickupHandoff(MerchantDeliverySummary? delivery) {
    return delivery?.status == 'AT_PICKUP' &&
        delivery?.assignedDriver != null;
  }

  Future<({MerchantPickupHandoff? handoff, String? error})> _loadPickupHandoff({
    required MerchantClient api,
    required String merchantId,
    required String orderId,
    required MerchantDeliverySummary? delivery,
  }) async {
    if (!_shouldLoadPickupHandoff(delivery)) {
      return (handoff: null, error: null);
    }
    try {
      final handoff = await api.getPickupHandoff(
        merchantId: merchantId,
        orderId: orderId,
      );
      return (handoff: handoff, error: null);
    } on AppException catch (e) {
      return (handoff: null, error: e.message);
    } catch (e) {
      return (handoff: null, error: AppStrings.pickupHandoffLoadError);
    }
  }

  Future<void> reloadPickupHandoff() async {
    final current = state.value;
    if (current == null || !_shouldLoadPickupHandoff(current.delivery)) {
      return;
    }
    final membership = ref.read(accessControllerProvider).membership;
    if (membership == null) return;

    state = AsyncData(
      current.copyWith(
        pickupHandoffLoading: true,
        clearPickupHandoff: true,
        clearPickupHandoffError: true,
      ),
    );
    final bundle = await _loadPickupHandoff(
      api: ref.read(merchantApiProvider),
      merchantId: membership.merchantId,
      orderId: orderId,
      delivery: current.delivery,
    );
    if (!ref.mounted) return;
    final latest = state.value;
    if (latest == null) return;
    state = AsyncData(
      latest.copyWith(
        pickupHandoff: bundle.handoff,
        pickupHandoffLoading: false,
        pickupHandoffError: bundle.error,
        clearPickupHandoff: bundle.handoff == null && bundle.error != null,
      ),
    );
  }

  Future<void> regeneratePickupHandoff() async {
    final current = state.value;
    if (current == null || !_shouldLoadPickupHandoff(current.delivery)) {
      return;
    }
    final membership = ref.read(accessControllerProvider).membership;
    if (membership == null) return;

    state = AsyncData(
      current.copyWith(
        pickupHandoffRegenerating: true,
        clearPickupHandoffError: true,
      ),
    );
    try {
      final handoff = await ref
          .read(merchantApiProvider)
          .regeneratePickupHandoff(
            merchantId: membership.merchantId,
            orderId: orderId,
          );
      if (!ref.mounted) return;
      final latest = state.value;
      if (latest == null) return;
      state = AsyncData(
        latest.copyWith(
          pickupHandoff: handoff,
          pickupHandoffRegenerating: false,
        ),
      );
    } on AppException catch (e) {
      if (!ref.mounted) return;
      final latest = state.value ?? current;
      state = AsyncData(
        latest.copyWith(
          pickupHandoffRegenerating: false,
          pickupHandoffError: e.message,
        ),
      );
    } catch (_) {
      if (!ref.mounted) return;
      final latest = state.value ?? current;
      state = AsyncData(
        latest.copyWith(
          pickupHandoffRegenerating: false,
          pickupHandoffError: AppStrings.pickupHandoffLoadError,
        ),
      );
    }
  }

  Future<void> runAction(Future<MerchantOrderDetail> Function() mutate) async {
    if (_inFlight) return;
    _inFlight = true;
    final current = state.value;
    if (current != null) {
      state = AsyncData(current.copyWith(mutating: true, clearError: true));
    }
    try {
      final access = ref.read(accessControllerProvider);
      final membership = access.membership;
      if (membership == null) {
        throw const ApiException(
          'Commerce introuvable.',
          code: 'MERCHANT_NOT_FOUND',
        );
      }
      final scope = ref.read(merchantDataScopeProvider);
      final updated = await mutate();
      if (!ref.mounted || ref.read(merchantDataScopeProvider) != scope) {
        return;
      }
      MerchantDeliverySummary? delivery;
      if (updated.fulfillmentStatus == 'READY') {
        try {
          delivery = await ref
              .read(merchantApiProvider)
              .getOrderDelivery(
                merchantId: membership.merchantId,
                orderId: updated.id,
              );
        } catch (_) {
          delivery = null;
        }
      }
      final handoffBundle = await _loadPickupHandoff(
        api: ref.read(merchantApiProvider),
        merchantId: membership.merchantId,
        orderId: updated.id,
        delivery: delivery,
      );
      state = AsyncData(
        OrderDetailState(
          order: updated,
          delivery: delivery,
          pickupHandoff: handoffBundle.handoff,
          pickupHandoffError: handoffBundle.error,
          mutating: false,
        ),
      );
      ref.invalidate(ordersListControllerProvider);
      ref.invalidate(homeOrderCountsProvider);
      ref.invalidate(homeActiveOrdersProvider);
    } on NetworkException catch (e) {
      try {
        final reconciled = await _fetch(orderId);
        state = AsyncData(
          reconciled.copyWith(mutating: false, actionError: e.message),
        );
      } catch (_) {
        if (current != null) {
          state = AsyncData(
            current.copyWith(mutating: false, actionError: e.message),
          );
        }
      }
    } on ApiException catch (e) {
      try {
        final reconciled = await _fetch(orderId);
        state = AsyncData(
          reconciled.copyWith(mutating: false, actionError: e.message),
        );
      } catch (_) {
        if (current != null) {
          state = AsyncData(
            current.copyWith(mutating: false, actionError: e.message),
          );
        } else {
          state = AsyncError(e, StackTrace.current);
        }
      }
    } catch (e, st) {
      if (current != null) {
        state = AsyncData(
          current.copyWith(
            mutating: false,
            actionError: e is AppException ? e.message : e.toString(),
          ),
        );
      } else {
        state = AsyncError(e, st);
      }
    } finally {
      _inFlight = false;
    }
  }

  Future<void> accept({int? preparationMinutes}) async {
    final membership = ref.read(accessControllerProvider).membership;
    if (membership == null) return;
    final api = ref.read(merchantApiProvider);
    await runAction(
      () => api.acceptOrder(
        merchantId: membership.merchantId,
        orderId: orderId,
        preparationMinutes: preparationMinutes,
      ),
    );
  }

  Future<void> updatePreparationEstimate({
    required int addMinutes,
    String? reason,
  }) async {
    final membership = ref.read(accessControllerProvider).membership;
    final current = state.value?.order;
    if (membership == null || current == null) return;
    final api = ref.read(merchantApiProvider);
    await runAction(
      () => api.updatePreparationEstimate(
        merchantId: membership.merchantId,
        orderId: orderId,
        addMinutes: addMinutes,
        expectedEstimateVersion: current.preparationEstimateVersion,
        reason: reason,
      ),
    );
  }

  Future<void> reject(String reason, {String? reasonCode}) async {
    final membership = ref.read(accessControllerProvider).membership;
    if (membership == null) return;
    final api = ref.read(merchantApiProvider);
    await runAction(
      () => api.rejectOrder(
        merchantId: membership.merchantId,
        orderId: orderId,
        reason: reason,
        reasonCode: reasonCode,
      ),
    );
  }

  Future<void> startPreparation() async {
    final membership = ref.read(accessControllerProvider).membership;
    if (membership == null) return;
    final api = ref.read(merchantApiProvider);
    await runAction(
      () => api.startPreparation(
        merchantId: membership.merchantId,
        orderId: orderId,
      ),
    );
  }

  Future<void> markReady() async {
    final membership = ref.read(accessControllerProvider).membership;
    if (membership == null) return;
    final api = ref.read(merchantApiProvider);
    await runAction(
      () => api.markReady(merchantId: membership.merchantId, orderId: orderId),
    );
  }
}

final orderDetailControllerProvider =
    AsyncNotifierProvider.family<
      OrderDetailController,
      OrderDetailState,
      String
    >(OrderDetailController.new);
