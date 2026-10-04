class MerchantRatingSummary {
  const MerchantRatingSummary({
    required this.merchantId,
    required this.count,
    required this.average,
  });

  final String merchantId;
  final int count;
  final double? average;

  factory MerchantRatingSummary.fromJson(Map<String, dynamic> json) {
    final avg = json['average'];
    return MerchantRatingSummary(
      merchantId: json['merchantId']?.toString() ?? '',
      count: (json['count'] as num?)?.toInt() ?? 0,
      average: avg is num ? avg.toDouble() : null,
    );
  }
}

/// Backend period presets (`docs/architecture/MERCHANT_SALES_REPORTS.md`).
enum ReportPeriod {
  today('TODAY'),
  yesterday('YESTERDAY'),
  thisWeek('THIS_WEEK'),
  thisMonth('THIS_MONTH'),
  custom('CUSTOM');

  const ReportPeriod(this.apiValue);
  final String apiValue;
}

/// Selected report period. [from]/[to] are inclusive local civil dates
/// (`YYYY-MM-DD`) and only apply to [ReportPeriod.custom].
class ReportPeriodSelection {
  const ReportPeriodSelection(this.period, {this.from, this.to});

  static const today = ReportPeriodSelection(ReportPeriod.today);

  final ReportPeriod period;
  final String? from;
  final String? to;

  Map<String, String> toQuery() => {
    'period': period.apiValue,
    if (period == ReportPeriod.custom && from != null) 'from': from!,
    if (period == ReportPeriod.custom && to != null) 'to': to!,
  };

  @override
  bool operator ==(Object other) =>
      other is ReportPeriodSelection &&
      other.period == period &&
      other.from == from &&
      other.to == to;

  @override
  int get hashCode => Object.hash(period, from, to);
}

enum TopProductSort {
  orders('ORDERS'),
  revenue('REVENUE');

  const TopProductSort(this.apiValue);
  final String apiValue;
}

String? _nullableString(Object? raw) => raw?.toString();

class MerchantReportPeriodInfo {
  const MerchantReportPeriodInfo({
    required this.period,
    required this.from,
    required this.to,
    required this.localFrom,
    required this.localToInclusive,
  });

  final String period;
  final String from;
  final String to;
  final String localFrom;
  final String localToInclusive;

  factory MerchantReportPeriodInfo.fromJson(Map<String, dynamic> json) {
    return MerchantReportPeriodInfo(
      period: json['period']?.toString() ?? '',
      from: json['from']?.toString() ?? '',
      to: json['to']?.toString() ?? '',
      localFrom: json['localFrom']?.toString() ?? '',
      localToInclusive: json['localToInclusive']?.toString() ?? '',
    );
  }
}

class MerchantSalesFinance {
  const MerchantSalesFinance({
    required this.merchantDiscountMinor,
    required this.commissionMinor,
    required this.merchantNetMinor,
    required this.uniformCommissionRateBps,
    required this.refundsCompletedCount,
    required this.recordedRefundAdjustmentsMinor,
  });

  /// `null` = authoritative snapshot data missing (never shown as zero).
  final String? merchantDiscountMinor;
  final String? commissionMinor;
  final String? merchantNetMinor;

  /// Set only when every sale in the period shares one historical rate.
  final int? uniformCommissionRateBps;
  final int refundsCompletedCount;

  /// Signed minor units (usually ≤ 0).
  final String recordedRefundAdjustmentsMinor;

  factory MerchantSalesFinance.fromJson(Map<String, dynamic> json) {
    final rate = json['uniformCommissionRateBps'];
    return MerchantSalesFinance(
      merchantDiscountMinor: _nullableString(json['merchantDiscountMinor']),
      commissionMinor: _nullableString(json['commissionMinor']),
      merchantNetMinor: _nullableString(json['merchantNetMinor']),
      uniformCommissionRateBps: rate is num ? rate.toInt() : null,
      refundsCompletedCount:
          (json['refundsCompletedCount'] as num?)?.toInt() ?? 0,
      recordedRefundAdjustmentsMinor:
          json['recordedRefundAdjustmentsMinor']?.toString() ?? '0',
    );
  }
}

class MerchantSalesTrendBucket {
  const MerchantSalesTrendBucket({
    required this.start,
    required this.localStart,
    required this.completedOrderCount,
    required this.grossMerchandiseMinor,
  });

  final String start;

  /// `YYYY-MM-DDTHH:00` (hourly) or `YYYY-MM-DD` (daily), Africa/Algiers.
  final String localStart;
  final int completedOrderCount;
  final String? grossMerchandiseMinor;

  factory MerchantSalesTrendBucket.fromJson(Map<String, dynamic> json) {
    return MerchantSalesTrendBucket(
      start: json['start']?.toString() ?? '',
      localStart: json['localStart']?.toString() ?? '',
      completedOrderCount: (json['completedOrderCount'] as num?)?.toInt() ?? 0,
      grossMerchandiseMinor: _nullableString(json['grossMerchandiseMinor']),
    );
  }
}

class MerchantSalesSummary {
  const MerchantSalesSummary({
    required this.branchId,
    required this.period,
    required this.asOf,
    required this.dataComplete,
    required this.completedOrderCount,
    required this.grossMerchandiseMinor,
    required this.averageBasketMinor,
    required this.cancelledOrderCount,
    required this.financeGranted,
    required this.finance,
    required this.hourly,
    required this.buckets,
  });

  final String? branchId;
  final MerchantReportPeriodInfo period;
  final String asOf;

  /// False when `dataStatus = MISSING_FINANCIAL_SNAPSHOT`.
  final bool dataComplete;
  final int completedOrderCount;
  final String? grossMerchandiseMinor;
  final String? averageBasketMinor;
  final int cancelledOrderCount;
  final bool financeGranted;
  final MerchantSalesFinance? finance;
  final bool hourly;
  final List<MerchantSalesTrendBucket> buckets;

  factory MerchantSalesSummary.fromJson(Map<String, dynamic> json) {
    final scope = json['scope'];
    final period = json['period'];
    final finance = json['finance'];
    final trend = json['trend'];
    final rawBuckets = trend is Map ? trend['buckets'] : null;
    return MerchantSalesSummary(
      branchId: scope is Map ? _nullableString(scope['branchId']) : null,
      period: MerchantReportPeriodInfo.fromJson(
        period is Map ? Map<String, dynamic>.from(period) : const {},
      ),
      asOf: json['asOf']?.toString() ?? '',
      dataComplete: json['dataStatus'] == 'COMPLETE',
      completedOrderCount: (json['completedOrderCount'] as num?)?.toInt() ?? 0,
      grossMerchandiseMinor: _nullableString(json['grossMerchandiseMinor']),
      averageBasketMinor: _nullableString(json['averageBasketMinor']),
      cancelledOrderCount: (json['cancelledOrderCount'] as num?)?.toInt() ?? 0,
      financeGranted: json['financeAccess'] == 'GRANTED',
      finance: finance is Map && json['financeAccess'] != 'ROLE_RESTRICTED'
          ? MerchantSalesFinance.fromJson(Map<String, dynamic>.from(finance))
          : null,
      hourly: trend is Map && trend['granularity'] == 'HOUR',
      buckets: rawBuckets is List
          ? rawBuckets
                .whereType<Map>()
                .map(
                  (e) => MerchantSalesTrendBucket.fromJson(
                    Map<String, dynamic>.from(e),
                  ),
                )
                .toList()
          : const [],
    );
  }
}

class MerchantTopProduct {
  const MerchantTopProduct({
    required this.rank,
    required this.productId,
    required this.name,
    required this.orderCount,
    required this.quantity,
    required this.revenueMinor,
  });

  final int rank;

  /// `null` when the Product has since been deleted (historical name only).
  final String? productId;
  final String name;
  final int orderCount;
  final int quantity;
  final String revenueMinor;

  factory MerchantTopProduct.fromJson(Map<String, dynamic> json) {
    return MerchantTopProduct(
      rank: (json['rank'] as num?)?.toInt() ?? 0,
      productId: _nullableString(json['productId']),
      name: json['name']?.toString() ?? '',
      orderCount: (json['orderCount'] as num?)?.toInt() ?? 0,
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      revenueMinor: json['revenueMinor']?.toString() ?? '0',
    );
  }
}

class MerchantTopProducts {
  const MerchantTopProducts({
    required this.asOf,
    required this.sort,
    required this.distinctProductCount,
    required this.items,
  });

  final String asOf;
  final TopProductSort sort;
  final int distinctProductCount;
  final List<MerchantTopProduct> items;

  factory MerchantTopProducts.fromJson(Map<String, dynamic> json) {
    final raw = json['items'];
    return MerchantTopProducts(
      asOf: json['asOf']?.toString() ?? '',
      sort: json['sort'] == TopProductSort.revenue.apiValue
          ? TopProductSort.revenue
          : TopProductSort.orders,
      distinctProductCount:
          (json['distinctProductCount'] as num?)?.toInt() ?? 0,
      items: raw is List
          ? raw
                .whereType<Map>()
                .map(
                  (e) =>
                      MerchantTopProduct.fromJson(Map<String, dynamic>.from(e)),
                )
                .toList()
          : const [],
    );
  }
}

class MerchantDailySummaryBreakdown {
  const MerchantDailySummaryBreakdown({
    required this.completed,
    required this.inProgress,
    required this.cancelled,
    required this.failed,
  });

  final int completed;
  final int inProgress;
  final int cancelled;
  final int failed;

  factory MerchantDailySummaryBreakdown.fromJson(Map<String, dynamic> json) {
    return MerchantDailySummaryBreakdown(
      completed: (json['completed'] as num?)?.toInt() ?? 0,
      inProgress: (json['inProgress'] as num?)?.toInt() ?? 0,
      cancelled: (json['cancelled'] as num?)?.toInt() ?? 0,
      failed: (json['failed'] as num?)?.toInt() ?? 0,
    );
  }
}

class MerchantDailySummaryCancellationReason {
  const MerchantDailySummaryCancellationReason({
    required this.reasonCode,
    required this.label,
    required this.count,
  });

  final String reasonCode;
  final String label;
  final int count;

  factory MerchantDailySummaryCancellationReason.fromJson(
    Map<String, dynamic> json,
  ) {
    return MerchantDailySummaryCancellationReason(
      reasonCode: json['reasonCode']?.toString() ?? 'UNSET',
      label: json['label']?.toString() ?? '',
      count: (json['count'] as num?)?.toInt() ?? 0,
    );
  }
}

/// One-day operational summary (`GET …/reports/daily-summary`).
class MerchantDailySummary {
  const MerchantDailySummary({
    required this.branchId,
    required this.date,
    required this.period,
    required this.asOf,
    required this.currency,
    required this.dataComplete,
    required this.financeGranted,
    required this.ordersCreatedCount,
    required this.completedOrderCount,
    required this.cancelledOrderCount,
    required this.activeOrderCount,
    required this.breakdown,
    required this.grossMerchandiseMinor,
    required this.averageBasketMinor,
    required this.averageActualPreparationMinutes,
    required this.preparationSampleCount,
    required this.onTimeLateSampleCount,
    required this.onTimePreparationCount,
    required this.latePreparationCount,
    required this.onTimePreparationRateBps,
    required this.cancellationReasons,
  });

  final String? branchId;
  final String date;
  final MerchantReportPeriodInfo period;
  final String asOf;
  final String currency;

  /// False when `dataStatus = MISSING_FINANCIAL_SNAPSHOT`.
  final bool dataComplete;
  final bool financeGranted;
  final int ordersCreatedCount;
  final int completedOrderCount;
  final int cancelledOrderCount;
  final int activeOrderCount;
  final MerchantDailySummaryBreakdown breakdown;
  final String? grossMerchandiseMinor;
  final String? averageBasketMinor;
  final int? averageActualPreparationMinutes;
  final int preparationSampleCount;
  final int onTimeLateSampleCount;
  final int onTimePreparationCount;
  final int latePreparationCount;
  final int? onTimePreparationRateBps;
  final List<MerchantDailySummaryCancellationReason> cancellationReasons;

  factory MerchantDailySummary.fromJson(Map<String, dynamic> json) {
    final scope = json['scope'];
    final period = json['period'];
    final breakdown = json['breakdown'];
    final rawReasons = json['cancellationReasons'];
    return MerchantDailySummary(
      branchId: scope is Map ? _nullableString(scope['branchId']) : null,
      date: json['date']?.toString() ?? '',
      period: MerchantReportPeriodInfo.fromJson(
        period is Map ? Map<String, dynamic>.from(period) : const {},
      ),
      asOf: json['asOf']?.toString() ?? '',
      currency: json['currency']?.toString() ?? 'DZD',
      dataComplete: json['dataStatus'] == 'OK',
      financeGranted: json['financeAccess'] == 'GRANTED',
      ordersCreatedCount: (json['ordersCreatedCount'] as num?)?.toInt() ?? 0,
      completedOrderCount: (json['completedOrderCount'] as num?)?.toInt() ?? 0,
      cancelledOrderCount: (json['cancelledOrderCount'] as num?)?.toInt() ?? 0,
      activeOrderCount: (json['activeOrderCount'] as num?)?.toInt() ?? 0,
      breakdown: breakdown is Map
          ? MerchantDailySummaryBreakdown.fromJson(
              Map<String, dynamic>.from(breakdown),
            )
          : const MerchantDailySummaryBreakdown(
              completed: 0,
              inProgress: 0,
              cancelled: 0,
              failed: 0,
            ),
      grossMerchandiseMinor: _nullableString(json['grossMerchandiseMinor']),
      averageBasketMinor: _nullableString(json['averageBasketMinor']),
      averageActualPreparationMinutes:
          (json['averageActualPreparationMinutes'] as num?)?.toInt(),
      preparationSampleCount:
          (json['preparationSampleCount'] as num?)?.toInt() ?? 0,
      onTimeLateSampleCount:
          (json['onTimeLateSampleCount'] as num?)?.toInt() ?? 0,
      onTimePreparationCount:
          (json['onTimePreparationCount'] as num?)?.toInt() ?? 0,
      latePreparationCount:
          (json['latePreparationCount'] as num?)?.toInt() ?? 0,
      onTimePreparationRateBps:
          (json['onTimePreparationRateBps'] as num?)?.toInt(),
      cancellationReasons: rawReasons is List
          ? rawReasons
                .whereType<Map>()
                .map(
                  (e) => MerchantDailySummaryCancellationReason.fromJson(
                    Map<String, dynamic>.from(e),
                  ),
                )
                .toList()
          : const [],
    );
  }
}

class MerchantSettlementSummary {
  const MerchantSettlementSummary({
    required this.settlementId,
    required this.merchantId,
    required this.periodStart,
    required this.periodEnd,
    required this.status,
    required this.currency,
    required this.grossSalesMinor,
    required this.commissionMinor,
    required this.netPayableMinor,
  });

  final String settlementId;
  final String merchantId;
  final String periodStart;
  final String periodEnd;
  final String status;
  final String currency;
  final String grossSalesMinor;
  final String commissionMinor;
  final String netPayableMinor;

  factory MerchantSettlementSummary.fromJson(Map<String, dynamic> json) {
    return MerchantSettlementSummary(
      settlementId: json['settlementId']?.toString() ?? '',
      merchantId: json['merchantId']?.toString() ?? '',
      periodStart: json['periodStart']?.toString() ?? '',
      periodEnd: json['periodEnd']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      currency: json['currency']?.toString() ?? 'DZD',
      grossSalesMinor: json['grossSalesMinor']?.toString() ?? '0',
      commissionMinor: json['commissionMinor']?.toString() ?? '0',
      netPayableMinor: json['netPayableMinor']?.toString() ?? '0',
    );
  }
}
