/// Contract-shaped fixtures for `GET …/reports/daily-summary`.
library;

const _asOf = '2031-03-15T10:30:00.000Z';
const _date = '2031-03-15';

Map<String, Object?> _scope({String? branchId}) => {
  'merchantId': 'm-1',
  'branchId': branchId ?? 'b-1',
};

Map<String, Object?> _period() => {
  'period': 'CUSTOM',
  'timezone': 'Africa/Algiers',
  'from': '2031-03-14T23:00:00.000Z',
  'to': '2031-03-15T23:00:00.000Z',
  'interval': '[from, to)',
  'localFrom': _date,
  'localToInclusive': _date,
};

Map<String, Object?> populatedDailySummaryJson({bool missingMoney = false}) {
  return {
    'scope': _scope(),
    'date': _date,
    'period': _period(),
    'asOf': _asOf,
    'currency': 'DZD',
    'dataStatus': missingMoney ? 'MISSING_FINANCIAL_SNAPSHOT' : 'OK',
    'financeAccess': 'GRANTED',
    'ordersCreatedCount': 18,
    'completedOrderCount': 15,
    'cancelledOrderCount': 2,
    'activeOrderCount': 1,
    'breakdown': {
      'completed': 15,
      'inProgress': 1,
      'cancelled': 2,
      'failed': 0,
    },
    'grossMerchandiseMinor': missingMoney ? null : '4230000',
    'averageBasketMinor': missingMoney ? null : '235000',
    'averageActualPreparationMinutes': 23,
    'preparationSampleCount': 12,
    'onTimeLateSampleCount': 12,
    'onTimePreparationCount': 10,
    'latePreparationCount': 2,
    'onTimePreparationRateBps': 8333,
    'cancellationReasons': [
      {
        'reasonCode': 'PRODUCT_UNAVAILABLE',
        'label': 'Indisponibilité produit',
        'count': 1,
      },
      {'reasonCode': 'UNSET', 'label': 'Non renseignée', 'count': 1},
    ],
  };
}

Map<String, Object?> emptyDailySummaryJson() => {
  'scope': _scope(),
  'date': _date,
  'period': _period(),
  'asOf': _asOf,
  'currency': 'DZD',
  'dataStatus': 'OK',
  'financeAccess': 'GRANTED',
  'ordersCreatedCount': 0,
  'completedOrderCount': 0,
  'cancelledOrderCount': 0,
  'activeOrderCount': 0,
  'breakdown': {
    'completed': 0,
    'inProgress': 0,
    'cancelled': 0,
    'failed': 0,
  },
  'grossMerchandiseMinor': '0',
  'averageBasketMinor': null,
  'averageActualPreparationMinutes': null,
  'preparationSampleCount': 0,
  'onTimeLateSampleCount': 0,
  'onTimePreparationCount': 0,
  'latePreparationCount': 0,
  'onTimePreparationRateBps': null,
  'cancellationReasons': <Object>[],
};
