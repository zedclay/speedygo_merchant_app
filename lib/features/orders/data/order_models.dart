/// Merchant order domain models matching backend MerchantOrder*ResponseDto.
library;

class MerchantOrderPayment {
  const MerchantOrderPayment({required this.method, required this.status});

  final String method;
  final String status;

  factory MerchantOrderPayment.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const MerchantOrderPayment(method: '', status: '');
    }
    return MerchantOrderPayment(
      method: json['method']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
    );
  }
}

/// Server-side Merchant financial visibility (`financialAccess`).
///
/// `restricted` (STAFF): the backend omits commission, merchant net and
/// merchant discount. `unknown`: the field is absent; values are shown only
/// when the server actually sent them.
enum MerchantFinancialAccess { granted, restricted, unknown }

MerchantFinancialAccess parseMerchantFinancialAccess(Object? raw) {
  switch (raw) {
    case 'GRANTED':
      return MerchantFinancialAccess.granted;
    case 'ROLE_RESTRICTED':
      return MerchantFinancialAccess.restricted;
    default:
      return MerchantFinancialAccess.unknown;
  }
}

String? _minorOrNull(Object? raw) => raw?.toString();

/// Missing values stay null — never coerced to zero.
class MerchantOrderFinancial {
  const MerchantOrderFinancial({
    this.currency = 'DZD',
    this.grossMerchandiseSubtotalMinor,
    this.merchantDiscountMinor,
    this.merchantCommissionRateBps,
    this.merchantCommissionAmountMinor,
    this.merchantNetAmountMinor,
    this.deliveryFeeMinor,
  });

  static const empty = MerchantOrderFinancial();

  final String currency;
  final String? grossMerchandiseSubtotalMinor;
  final String? merchantDiscountMinor;
  final int? merchantCommissionRateBps;
  final String? merchantCommissionAmountMinor;
  final String? merchantNetAmountMinor;
  final String? deliveryFeeMinor;

  factory MerchantOrderFinancial.fromJson(
    Map<String, dynamic>? json, {
    MerchantFinancialAccess access = MerchantFinancialAccess.unknown,
  }) {
    if (json == null) return empty;
    final restricted = access == MerchantFinancialAccess.restricted;
    return MerchantOrderFinancial(
      currency: json['currency']?.toString() ?? 'DZD',
      grossMerchandiseSubtotalMinor: _minorOrNull(
        json['grossMerchandiseSubtotalMinor'],
      ),
      merchantDiscountMinor: restricted
          ? null
          : _minorOrNull(json['merchantDiscountMinor']),
      merchantCommissionRateBps: restricted
          ? null
          : (json['merchantCommissionRateBps'] as num?)?.toInt(),
      merchantCommissionAmountMinor: restricted
          ? null
          : _minorOrNull(json['merchantCommissionAmountMinor']),
      merchantNetAmountMinor: restricted
          ? null
          : _minorOrNull(json['merchantNetAmountMinor']),
      deliveryFeeMinor: _minorOrNull(json['deliveryFeeMinor']),
    );
  }
}

class MerchantOrderItemOption {
  const MerchantOrderItemOption({
    required this.optionNameSnapshot,
    required this.additionalPriceMinor,
  });

  final String optionNameSnapshot;
  final String additionalPriceMinor;

  factory MerchantOrderItemOption.fromJson(Map<String, dynamic> json) {
    return MerchantOrderItemOption(
      optionNameSnapshot: json['optionNameSnapshot']?.toString() ?? '',
      additionalPriceMinor: json['additionalPriceMinor']?.toString() ?? '0',
    );
  }
}

class MerchantOrderItem {
  const MerchantOrderItem({
    required this.id,
    required this.productId,
    required this.productNameSnapshot,
    required this.quantity,
    required this.unitPriceMinor,
    required this.lineTotalMinor,
    required this.options,
  });

  final String id;
  final String? productId;
  final String productNameSnapshot;
  final int quantity;
  final String unitPriceMinor;
  final String lineTotalMinor;
  final List<MerchantOrderItemOption> options;

  factory MerchantOrderItem.fromJson(Map<String, dynamic> json) {
    final optionsRaw = json['options'];
    return MerchantOrderItem(
      id: json['id']?.toString() ?? '',
      productId: json['productId']?.toString(),
      productNameSnapshot: json['productNameSnapshot']?.toString() ?? '',
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      unitPriceMinor: json['unitPriceMinor']?.toString() ?? '0',
      lineTotalMinor: json['lineTotalMinor']?.toString() ?? '0',
      options: optionsRaw is List
          ? optionsRaw
                .whereType<Map>()
                .map(
                  (e) => MerchantOrderItemOption.fromJson(
                    Map<String, dynamic>.from(e),
                  ),
                )
                .toList()
          : const [],
    );
  }
}

class MerchantOrderAddress {
  const MerchantOrderAddress({
    required this.addressText,
    required this.latitude,
    required this.longitude,
    this.instructions,
  });

  final String addressText;
  final double latitude;
  final double longitude;
  final String? instructions;

  factory MerchantOrderAddress.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const MerchantOrderAddress(
        addressText: '',
        latitude: 0,
        longitude: 0,
      );
    }
    return MerchantOrderAddress(
      addressText: json['addressText']?.toString() ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
      instructions: json['instructions']?.toString(),
    );
  }
}

class MerchantOrderStatusEvent {
  const MerchantOrderStatusEvent({
    required this.eventType,
    required this.actorType,
    required this.fromStatus,
    required this.toStatus,
    required this.occurredAt,
  });

  final String eventType;
  final String actorType;
  final String? fromStatus;
  final String toStatus;
  final String occurredAt;

  factory MerchantOrderStatusEvent.fromJson(Map<String, dynamic> json) {
    return MerchantOrderStatusEvent(
      eventType: json['eventType']?.toString() ?? '',
      actorType: json['actorType']?.toString() ?? '',
      fromStatus: json['fromStatus']?.toString(),
      toStatus: json['toStatus']?.toString() ?? '',
      occurredAt: json['occurredAt']?.toString() ?? '',
    );
  }
}

/// Structured Merchant reject codes (`OrderCancellation.reasonCode`).
enum MerchantRejectReasonCode {
  productUnavailable('PRODUCT_UNAVAILABLE'),
  tooBusy('TOO_BUSY'),
  closingSoon('CLOSING_SOON'),
  other('OTHER');

  const MerchantRejectReasonCode(this.apiValue);
  final String apiValue;

  static MerchantRejectReasonCode? tryParse(String? raw) {
    if (raw == null) return null;
    for (final code in values) {
      if (code.apiValue == raw) return code;
    }
    return null;
  }
}

class MerchantOrderCancellation {
  const MerchantOrderCancellation({
    required this.reason,
    required this.cancelledAt,
    this.reasonCode,
  });

  final String reason;
  final String cancelledAt;
  final MerchantRejectReasonCode? reasonCode;

  factory MerchantOrderCancellation.fromJson(Map<String, dynamic> json) {
    return MerchantOrderCancellation(
      reason: json['reason']?.toString() ?? '',
      cancelledAt: json['cancelledAt']?.toString() ?? '',
      reasonCode: MerchantRejectReasonCode.tryParse(
        json['reasonCode']?.toString(),
      ),
    );
  }
}

class MerchantPreparationRevision {
  const MerchantPreparationRevision({
    required this.revisionNumber,
    required this.addMinutes,
    required this.reason,
    required this.createdAt,
  });

  final int revisionNumber;
  final int addMinutes;
  final String? reason;
  final String createdAt;

  factory MerchantPreparationRevision.fromJson(Map<String, dynamic> json) {
    return MerchantPreparationRevision(
      revisionNumber: (json['revisionNumber'] as num?)?.toInt() ?? 0,
      addMinutes: (json['addMinutes'] as num?)?.toInt() ?? 0,
      reason: json['reason']?.toString(),
      createdAt: json['createdAt']?.toString() ?? '',
    );
  }
}

/// Delivery-impact classification from persisted facts only.
enum MerchantDeliveryImpactState {
  notApplicable('NOT_APPLICABLE'),
  deliveryTimingUnavailable('DELIVERY_TIMING_UNAVAILABLE'),
  mayDelayDriverAssignment('MAY_DELAY_DRIVER_ASSIGNMENT'),
  mayDelayPickup('MAY_DELAY_PICKUP'),
  driverWaiting('DRIVER_WAITING'),
  resolved('RESOLVED');

  const MerchantDeliveryImpactState(this.apiValue);
  final String apiValue;

  static MerchantDeliveryImpactState? tryParse(String? raw) {
    if (raw == null) return null;
    for (final state in values) {
      if (state.apiValue == raw) return state;
    }
    return null;
  }

  bool get showOnLateCard =>
      this != notApplicable && this != resolved;
}

class MerchantDeliveryImpact {
  const MerchantDeliveryImpact({
    required this.state,
    this.deliveryStatus,
  });

  final MerchantDeliveryImpactState state;
  final String? deliveryStatus;

  factory MerchantDeliveryImpact.fromJson(Map<String, dynamic> json) {
    return MerchantDeliveryImpact(
      state:
          MerchantDeliveryImpactState.tryParse(json['state']?.toString()) ??
          MerchantDeliveryImpactState.deliveryTimingUnavailable,
      deliveryStatus: json['deliveryStatus']?.toString(),
    );
  }
}

class MerchantOrderSummary {
  const MerchantOrderSummary({
    required this.id,
    required this.publicReference,
    required this.status,
    required this.fulfillmentStatus,
    required this.merchantBranchId,
    required this.createdAt,
    this.confirmedAt,
    this.customerFullName,
    this.payment = const MerchantOrderPayment(method: '', status: ''),
    this.financialAccess = MerchantFinancialAccess.unknown,
    this.financial = MerchantOrderFinancial.empty,
    this.preparationMinutes,
    this.originalPreparationMinutes,
    this.estimatedReadyAt,
    this.originalEstimatedReadyAt,
    this.preparationEstimateVersion = 0,
    this.isPreparationLate = false,
  });

  final String id;
  final String publicReference;
  final String status;
  final String fulfillmentStatus;
  final String merchantBranchId;
  final String createdAt;
  final String? confirmedAt;
  final String? customerFullName;
  final MerchantOrderPayment payment;
  final MerchantFinancialAccess financialAccess;
  final MerchantOrderFinancial financial;

  bool get financeRestricted =>
      financialAccess == MerchantFinancialAccess.restricted;
  final int? preparationMinutes;
  final int? originalPreparationMinutes;
  final String? estimatedReadyAt;
  final String? originalEstimatedReadyAt;
  final int preparationEstimateVersion;
  final bool isPreparationLate;

  factory MerchantOrderSummary.fromJson(Map<String, dynamic> json) {
    return MerchantOrderSummary(
      id: json['id']?.toString() ?? '',
      publicReference: json['publicReference']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      fulfillmentStatus: json['fulfillmentStatus']?.toString() ?? '',
      merchantBranchId: json['merchantBranchId']?.toString() ?? '',
      createdAt: json['createdAt']?.toString() ?? '',
      confirmedAt: json['confirmedAt']?.toString(),
      customerFullName: json['customerFullName']?.toString(),
      payment: MerchantOrderPayment.fromJson(
        json['payment'] is Map
            ? Map<String, dynamic>.from(json['payment'] as Map)
            : null,
      ),
      financialAccess: parseMerchantFinancialAccess(json['financialAccess']),
      financial: MerchantOrderFinancial.fromJson(
        json['financial'] is Map
            ? Map<String, dynamic>.from(json['financial'] as Map)
            : null,
        access: parseMerchantFinancialAccess(json['financialAccess']),
      ),
      preparationMinutes: (json['preparationMinutes'] as num?)?.toInt(),
      originalPreparationMinutes: (json['originalPreparationMinutes'] as num?)
          ?.toInt(),
      estimatedReadyAt: json['estimatedReadyAt']?.toString(),
      originalEstimatedReadyAt: json['originalEstimatedReadyAt']?.toString(),
      preparationEstimateVersion:
          (json['preparationEstimateVersion'] as num?)?.toInt() ?? 0,
      isPreparationLate: json['isPreparationLate'] == true,
    );
  }
}

class MerchantOrderDetail extends MerchantOrderSummary {
  const MerchantOrderDetail({
    required super.id,
    required super.publicReference,
    required super.status,
    required super.fulfillmentStatus,
    required super.merchantBranchId,
    required super.createdAt,
    super.confirmedAt,
    super.customerFullName,
    super.payment,
    super.financialAccess,
    super.financial,
    super.preparationMinutes,
    super.originalPreparationMinutes,
    super.estimatedReadyAt,
    super.originalEstimatedReadyAt,
    super.preparationEstimateVersion,
    super.isPreparationLate,
    this.delayMinutes,
    this.latestPreparationRevision,
    this.deliveryImpact,
    required this.items,
    required this.deliveryAddress,
    required this.statusHistory,
    this.cancellation,
  });

  final int? delayMinutes;
  final MerchantPreparationRevision? latestPreparationRevision;
  final MerchantDeliveryImpact? deliveryImpact;
  final List<MerchantOrderItem> items;
  final MerchantOrderAddress deliveryAddress;
  final List<MerchantOrderStatusEvent> statusHistory;
  final MerchantOrderCancellation? cancellation;

  factory MerchantOrderDetail.fromJson(Map<String, dynamic> json) {
    final itemsRaw = json['items'];
    final historyRaw = json['statusHistory'];
    final cancellationRaw = json['cancellation'];
    return MerchantOrderDetail(
      id: json['id']?.toString() ?? '',
      publicReference: json['publicReference']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      fulfillmentStatus: json['fulfillmentStatus']?.toString() ?? '',
      merchantBranchId: json['merchantBranchId']?.toString() ?? '',
      createdAt: json['createdAt']?.toString() ?? '',
      confirmedAt: json['confirmedAt']?.toString(),
      customerFullName: json['customerFullName']?.toString(),
      payment: MerchantOrderPayment.fromJson(
        json['payment'] is Map
            ? Map<String, dynamic>.from(json['payment'] as Map)
            : null,
      ),
      financialAccess: parseMerchantFinancialAccess(json['financialAccess']),
      financial: MerchantOrderFinancial.fromJson(
        json['financial'] is Map
            ? Map<String, dynamic>.from(json['financial'] as Map)
            : null,
        access: parseMerchantFinancialAccess(json['financialAccess']),
      ),
      preparationMinutes: (json['preparationMinutes'] as num?)?.toInt(),
      originalPreparationMinutes: (json['originalPreparationMinutes'] as num?)
          ?.toInt(),
      estimatedReadyAt: json['estimatedReadyAt']?.toString(),
      originalEstimatedReadyAt: json['originalEstimatedReadyAt']?.toString(),
      preparationEstimateVersion:
          (json['preparationEstimateVersion'] as num?)?.toInt() ?? 0,
      isPreparationLate: json['isPreparationLate'] == true,
      delayMinutes: (json['delayMinutes'] as num?)?.toInt(),
      latestPreparationRevision: json['latestPreparationRevision'] is Map
          ? MerchantPreparationRevision.fromJson(
              Map<String, dynamic>.from(
                json['latestPreparationRevision'] as Map,
              ),
            )
          : null,
      deliveryImpact: json['deliveryImpact'] is Map
          ? MerchantDeliveryImpact.fromJson(
              Map<String, dynamic>.from(json['deliveryImpact'] as Map),
            )
          : null,
      items: itemsRaw is List
          ? itemsRaw
                .whereType<Map>()
                .map(
                  (e) =>
                      MerchantOrderItem.fromJson(Map<String, dynamic>.from(e)),
                )
                .toList()
          : const [],
      deliveryAddress: MerchantOrderAddress.fromJson(
        json['deliveryAddress'] is Map
            ? Map<String, dynamic>.from(json['deliveryAddress'] as Map)
            : null,
      ),
      statusHistory: historyRaw is List
          ? historyRaw
                .whereType<Map>()
                .map(
                  (e) => MerchantOrderStatusEvent.fromJson(
                    Map<String, dynamic>.from(e),
                  ),
                )
                .toList()
          : const [],
      cancellation: cancellationRaw is Map
          ? MerchantOrderCancellation.fromJson(
              Map<String, dynamic>.from(cancellationRaw),
            )
          : null,
    );
  }
}

class MerchantOrderListPage {
  const MerchantOrderListPage({
    required this.items,
    required this.limit,
    required this.offset,
    required this.total,
  });

  final List<MerchantOrderSummary> items;
  final int limit;
  final int offset;
  final int total;

  bool get hasMore => offset + items.length < total;

  factory MerchantOrderListPage.fromJson(Map<String, dynamic> json) {
    final itemsRaw = json['items'];
    return MerchantOrderListPage(
      items: itemsRaw is List
          ? itemsRaw
                .whereType<Map>()
                .map(
                  (e) => MerchantOrderSummary.fromJson(
                    Map<String, dynamic>.from(e),
                  ),
                )
                .toList()
          : const [],
      limit: (json['limit'] as num?)?.toInt() ?? 0,
      offset: (json['offset'] as num?)?.toInt() ?? 0,
      total: (json['total'] as num?)?.toInt() ?? 0,
    );
  }
}

class AssignedDriverVehicleSummary {
  const AssignedDriverVehicleSummary({
    required this.type,
    required this.plateNumber,
  });

  final String type;
  final String plateNumber;

  factory AssignedDriverVehicleSummary.fromJson(Map<String, dynamic> json) {
    return AssignedDriverVehicleSummary(
      type: json['type']?.toString() ?? '',
      plateNumber: json['plateNumber']?.toString() ?? '',
    );
  }
}

class AssignedDriverSummary {
  const AssignedDriverSummary({
    required this.driverId,
    required this.assignmentId,
    required this.assignmentVersion,
    required this.displayName,
    required this.callAllowed,
    required this.deliveryStatus,
    this.vehicle,
    this.contactPhone,
    this.arrivedPickupAt,
    this.estimatedArrivalAt,
  });

  final String driverId;
  final String assignmentId;
  final int assignmentVersion;
  final String displayName;
  final AssignedDriverVehicleSummary? vehicle;
  final String? contactPhone;
  final bool callAllowed;
  final String deliveryStatus;
  final String? arrivedPickupAt;
  final String? estimatedArrivalAt;

  bool get canCall {
    final phone = contactPhone?.trim();
    return callAllowed && phone != null && phone.isNotEmpty;
  }

  factory AssignedDriverSummary.fromJson(Map<String, dynamic> json) {
    final vehicleRaw = json['vehicle'];
    return AssignedDriverSummary(
      driverId: json['driverId']?.toString() ?? '',
      assignmentId: json['assignmentId']?.toString() ?? '',
      assignmentVersion: (json['assignmentVersion'] as num?)?.toInt() ?? 0,
      displayName: json['displayName']?.toString() ?? '',
      vehicle: vehicleRaw is Map
          ? AssignedDriverVehicleSummary.fromJson(
              Map<String, dynamic>.from(vehicleRaw),
            )
          : null,
      contactPhone: json['contactPhone']?.toString(),
      callAllowed: json['callAllowed'] == true,
      deliveryStatus: json['deliveryStatus']?.toString() ?? '',
      arrivedPickupAt: json['arrivedPickupAt']?.toString(),
      estimatedArrivalAt: json['estimatedArrivalAt']?.toString(),
    );
  }
}

class MerchantPickupHandoff {
  const MerchantPickupHandoff({
    required this.id,
    required this.pickupCode,
    required this.status,
    required this.expiresAt,
    required this.assignmentId,
    required this.assignmentVersion,
    required this.version,
    required this.attemptsRemaining,
  });

  final String id;
  final String pickupCode;
  final String status;
  final String expiresAt;
  final String assignmentId;
  final int assignmentVersion;
  final int version;
  final int attemptsRemaining;

  bool get isConsumed => status == 'CONSUMED';

  factory MerchantPickupHandoff.fromJson(Map<String, dynamic> json) {
    return MerchantPickupHandoff(
      id: json['id']?.toString() ?? '',
      pickupCode: json['pickupCode']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      expiresAt: json['expiresAt']?.toString() ?? '',
      assignmentId: json['assignmentId']?.toString() ?? '',
      assignmentVersion: (json['assignmentVersion'] as num?)?.toInt() ?? 0,
      version: (json['version'] as num?)?.toInt() ?? 0,
      attemptsRemaining: (json['attemptsRemaining'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Read-only Merchant delivery view.
class MerchantDeliverySummary {
  const MerchantDeliverySummary({
    required this.id,
    required this.orderId,
    required this.publicReference,
    required this.status,
    required this.orderStatus,
    required this.fulfillmentStatus,
    this.assignedDriverId,
    this.assignedDriver,
    this.driverSearchStartedAt,
    this.pickedUpAt,
    this.estimatedArrivalAt,
    this.arrivedCustomerAt,
    this.deliveredAt,
  });

  final String id;
  final String orderId;
  final String publicReference;
  final String status;
  final String orderStatus;
  final String fulfillmentStatus;
  final String? assignedDriverId;
  final AssignedDriverSummary? assignedDriver;
  final String? driverSearchStartedAt;
  final String? pickedUpAt;
  final String? estimatedArrivalAt;
  final String? arrivedCustomerAt;
  final String? deliveredAt;

  factory MerchantDeliverySummary.fromJson(Map<String, dynamic> json) {
    final assignedDriverRaw = json['assignedDriver'];
    return MerchantDeliverySummary(
      id: json['id']?.toString() ?? '',
      orderId: json['orderId']?.toString() ?? '',
      publicReference: json['publicReference']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      orderStatus: json['orderStatus']?.toString() ?? '',
      fulfillmentStatus: json['fulfillmentStatus']?.toString() ?? '',
      assignedDriverId: json['assignedDriverId']?.toString(),
      assignedDriver: assignedDriverRaw is Map
          ? AssignedDriverSummary.fromJson(
              Map<String, dynamic>.from(assignedDriverRaw),
            )
          : null,
      driverSearchStartedAt: json['driverSearchStartedAt']?.toString(),
      pickedUpAt: json['pickedUpAt']?.toString(),
      estimatedArrivalAt: json['estimatedArrivalAt']?.toString(),
      arrivedCustomerAt: json['arrivedCustomerAt']?.toString(),
      deliveredAt: json['deliveredAt']?.toString(),
    );
  }
}

/// Server-backed list tab filters.
///
/// ## En cours / Historique mapping (API queries — filter before pagination)
///
/// **Segment En cours** (orderStatus ∧ fulfillmentStatus):
/// Reject keeps `fulfillmentStatus=PENDING_ACCEPTANCE` while `status=CANCELLED`.
/// Fulfillment-only queries therefore leak terminals into En cours / Home.
/// Active chips send both dimensions so the backend AND excludes them.
/// - Nouvelles → `CREATED` + `PENDING_ACCEPTANCE`
/// - Acceptées → `CONFIRMED` + `ACCEPTED`
/// - En préparation → `ACTIVE` + `PREPARING`
/// - Prêtes → `ACTIVE` + `READY`
///
/// **Segment Historique** (orderStatus; Terminées is the default):
/// - Terminées → `COMPLETED`
/// - Annulées → `CANCELLED`
/// - Échouées → `FAILED`
///
/// No unfiltered “Toutes” / combined OR query: each chip is one supported
/// API filter. Counts use `list.total` for the active filter only.
enum MerchantOrderListFilter {
  incoming,
  accepted,
  preparing,
  ready,
  cancelled,
  completed,
  failed,
}

extension MerchantOrderListFilterX on MerchantOrderListFilter {
  String get label {
    switch (this) {
      case MerchantOrderListFilter.incoming:
        return 'Nouveaux';
      case MerchantOrderListFilter.accepted:
        return 'Acceptées';
      case MerchantOrderListFilter.preparing:
        return 'En préparation';
      case MerchantOrderListFilter.ready:
        return 'Prêtes';
      case MerchantOrderListFilter.cancelled:
        return 'Annulées';
      case MerchantOrderListFilter.completed:
        return 'Terminées';
      case MerchantOrderListFilter.failed:
        return 'Échouées';
    }
  }

  bool get isHistory {
    switch (this) {
      case MerchantOrderListFilter.cancelled:
      case MerchantOrderListFilter.completed:
      case MerchantOrderListFilter.failed:
        return true;
      case MerchantOrderListFilter.incoming:
      case MerchantOrderListFilter.accepted:
      case MerchantOrderListFilter.preparing:
      case MerchantOrderListFilter.ready:
        return false;
    }
  }

  static const activeFilters = <MerchantOrderListFilter>[
    MerchantOrderListFilter.incoming,
    MerchantOrderListFilter.accepted,
    MerchantOrderListFilter.preparing,
    MerchantOrderListFilter.ready,
  ];

  static const historyFilters = <MerchantOrderListFilter>[
    MerchantOrderListFilter.completed,
    MerchantOrderListFilter.cancelled,
    MerchantOrderListFilter.failed,
  ];

  /// Fulfillment filter when supported; history uses orderStatus only.
  String? get fulfillmentStatus {
    switch (this) {
      case MerchantOrderListFilter.incoming:
        return 'PENDING_ACCEPTANCE';
      case MerchantOrderListFilter.accepted:
        return 'ACCEPTED';
      case MerchantOrderListFilter.preparing:
        return 'PREPARING';
      case MerchantOrderListFilter.ready:
        return 'READY';
      case MerchantOrderListFilter.cancelled:
      case MerchantOrderListFilter.completed:
      case MerchantOrderListFilter.failed:
        return null;
    }
  }

  String? get orderStatus {
    switch (this) {
      case MerchantOrderListFilter.incoming:
        return 'CREATED';
      case MerchantOrderListFilter.accepted:
        return 'CONFIRMED';
      case MerchantOrderListFilter.preparing:
      case MerchantOrderListFilter.ready:
        return 'ACTIVE';
      case MerchantOrderListFilter.cancelled:
        return 'CANCELLED';
      case MerchantOrderListFilter.completed:
        return 'COMPLETED';
      case MerchantOrderListFilter.failed:
        return 'FAILED';
    }
  }
}

/// Merchant workflow actions exposed by the API.
enum MerchantOrderAction { accept, reject, startPreparation, markReady }

/// Mirrors the backend `ORDER_WORKFLOW_MUTATE` capability (OWNER, MANAGER):
/// accept, reject, start-preparation, mark-ready and preparation-estimate.
/// Presentation only; the server stays authoritative (STAFF → 403).
bool merchantRoleCanMutateOrders(String? role) =>
    role == 'OWNER' || role == 'MANAGER';

/// Maps server order/fulfillment state + role to allowed actions.
List<MerchantOrderAction> merchantActionsFor({
  required String orderStatus,
  required String fulfillmentStatus,
  required String role,
}) {
  if (!merchantRoleCanMutateOrders(role)) return const [];

  if (orderStatus == 'CREATED' && fulfillmentStatus == 'PENDING_ACCEPTANCE') {
    return const [MerchantOrderAction.accept, MerchantOrderAction.reject];
  }
  if (orderStatus == 'CONFIRMED' && fulfillmentStatus == 'ACCEPTED') {
    return const [MerchantOrderAction.startPreparation];
  }
  if (orderStatus == 'ACTIVE' && fulfillmentStatus == 'PREPARING') {
    return const [MerchantOrderAction.markReady];
  }
  return const [];
}
