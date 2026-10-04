/// Contract-shaped fixtures for `GET /merchant/:id/reports/*`
/// (docs/architecture/MERCHANT_SALES_REPORTS.md). Test-only data.
library;

const _asOf = '2031-03-15T10:30:00.000Z';

List<Map<String, Object?>> _hourlyBuckets({
  Map<int, (int, String?)> values = const {},
  bool missing = false,
}) {
  return [
    for (var h = 0; h < 12; h++)
      {
        'start':
            DateTime.utc(2031, 3, 14, 23).add(Duration(hours: h)).toIso8601String(),
        'localStart': '2031-03-15T${h.toString().padLeft(2, '0')}:00',
        'completedOrderCount': values[h]?.$1 ?? 0,
        'grossMerchandiseMinor': missing ? null : (values[h]?.$2 ?? '0'),
      },
  ];
}

Map<String, Object?> _period(String period) => {
  'period': period,
  'timezone': 'Africa/Algiers',
  'from': '2031-03-14T23:00:00.000Z',
  'to': '2031-03-15T23:00:00.000Z',
  'interval': '[from, to)',
  'localFrom': '2031-03-15',
  'localToInclusive': '2031-03-15',
};

/// 18 completed orders, 42 300 DZD gross, 7 % historical commission.
Map<String, Object?> populatedSummaryJson({
  String period = 'TODAY',
  bool staff = false,
  int refundsCompleted = 0,
  String adjustments = '0',
  String discount = '0',
  int? rate = 700,
}) {
  const gross = 4230000;
  const commission = 296100;
  final net = gross - int.parse(discount) - commission;
  return {
    'scope': {'merchantId': 'm-1', 'branchId': 'b-1'},
    'period': _period(period),
    'asOf': _asOf,
    'currency': 'DZD',
    'dataStatus': 'COMPLETE',
    'completedOrderCount': 18,
    'grossMerchandiseMinor': '$gross',
    'averageBasketMinor': '235000',
    'cancelledOrderCount': 2,
    'financeAccess': staff ? 'ROLE_RESTRICTED' : 'GRANTED',
    'finance': staff
        ? null
        : {
            'merchantDiscountMinor': discount,
            'commissionMinor': '$commission',
            'merchantNetMinor': '$net',
            'uniformCommissionRateBps': rate,
            'refundsCompletedCount': refundsCompleted,
            'recordedRefundAdjustmentsMinor': adjustments,
          },
    'trend': {
      'granularity': 'HOUR',
      'buckets': _hourlyBuckets(
        values: {
          9: (2, '420000'),
          10: (7, '1650000'),
          11: (9, '2160000'),
        },
      ),
    },
  };
}

Map<String, Object?> zeroSummaryJson() => {
  'scope': {'merchantId': 'm-1', 'branchId': 'b-1'},
  'period': _period('TODAY'),
  'asOf': _asOf,
  'currency': 'DZD',
  'dataStatus': 'COMPLETE',
  'completedOrderCount': 0,
  'grossMerchandiseMinor': '0',
  'averageBasketMinor': null,
  'cancelledOrderCount': 0,
  'financeAccess': 'GRANTED',
  'finance': {
    'merchantDiscountMinor': '0',
    'commissionMinor': '0',
    'merchantNetMinor': '0',
    'uniformCommissionRateBps': null,
    'refundsCompletedCount': 0,
    'recordedRefundAdjustmentsMinor': '0',
  },
  'trend': {'granularity': 'HOUR', 'buckets': _hourlyBuckets()},
};

Map<String, Object?> missingSnapshotJson() => {
  'scope': {'merchantId': 'm-1', 'branchId': 'b-1'},
  'period': _period('TODAY'),
  'asOf': _asOf,
  'currency': 'DZD',
  'dataStatus': 'MISSING_FINANCIAL_SNAPSHOT',
  'completedOrderCount': 3,
  'grossMerchandiseMinor': null,
  'averageBasketMinor': null,
  'cancelledOrderCount': 0,
  'financeAccess': 'GRANTED',
  'finance': {
    'merchantDiscountMinor': null,
    'commissionMinor': null,
    'merchantNetMinor': null,
    'uniformCommissionRateBps': null,
    'refundsCompletedCount': 0,
    'recordedRefundAdjustmentsMinor': '0',
  },
  'trend': {
    'granularity': 'HOUR',
    'buckets': _hourlyBuckets(values: {10: (3, null)}, missing: true),
  },
};

/// Four products whose revenue sums to the populated gross (42 300 DZD).
Map<String, Object?> populatedTopJson({int limit = 5, String sort = 'ORDERS'}) {
  const all = [
    {
      'productId': 'p-1',
      'name': 'Couscous Royal',
      'orderCount': 8,
      'quantity': 12,
      'revenueMinor': '2400000',
    },
    {
      'productId': 'p-2',
      'name': 'Chorba Frik',
      'orderCount': 5,
      'quantity': 9,
      'revenueMinor': '900000',
    },
    {
      'productId': 'p-3',
      'name': 'Boisson Sélecto',
      'orderCount': 4,
      'quantity': 12,
      'revenueMinor': '600000',
    },
    {
      'productId': null,
      'name': 'Pain Maison',
      'orderCount': 3,
      'quantity': 11,
      'revenueMinor': '330000',
    },
  ];
  return {
    'scope': {'merchantId': 'm-1', 'branchId': 'b-1'},
    'period': _period('TODAY'),
    'asOf': _asOf,
    'currency': 'DZD',
    'sort': sort,
    'distinctProductCount': all.length,
    'items': [
      for (var i = 0; i < all.length && i < limit; i++)
        {'rank': i + 1, ...all[i]},
    ],
  };
}
