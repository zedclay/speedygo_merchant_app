class OpeningInterval {
  const OpeningInterval({required this.opens, required this.closes});

  final String opens;
  final String closes;

  Map<String, dynamic> toJson() => {'opens': opens, 'closes': closes};

  factory OpeningInterval.fromJson(Map<String, dynamic> json) {
    return OpeningInterval(
      opens: json['opens']?.toString() ?? '09:00',
      closes: json['closes']?.toString() ?? '17:00',
    );
  }
}

class OpeningDay {
  const OpeningDay({required this.dayOfWeek, required this.intervals});

  /// ISO weekday 1=Mon .. 7=Sun
  final int dayOfWeek;
  final List<OpeningInterval> intervals;

  OpeningDay copyWith({List<OpeningInterval>? intervals}) {
    return OpeningDay(
      dayOfWeek: dayOfWeek,
      intervals: intervals ?? this.intervals,
    );
  }

  Map<String, dynamic> toJson() => {
    'dayOfWeek': dayOfWeek,
    'intervals': intervals.map((e) => e.toJson()).toList(),
  };

  factory OpeningDay.fromJson(Map<String, dynamic> json) {
    final raw = json['intervals'];
    return OpeningDay(
      dayOfWeek: (json['dayOfWeek'] as num?)?.toInt() ?? 1,
      intervals: raw is List
          ? raw
                .whereType<Map>()
                .map(
                  (e) => OpeningInterval.fromJson(Map<String, dynamic>.from(e)),
                )
                .toList()
          : const [],
    );
  }
}

class OpeningHoursSchedule {
  const OpeningHoursSchedule({
    required this.branchId,
    required this.timezone,
    required this.hoursConfigured,
    required this.version,
    required this.days,
  });

  final String branchId;
  final String timezone;
  final bool hoursConfigured;
  final int? version;
  final List<OpeningDay> days;

  factory OpeningHoursSchedule.fromJson(Map<String, dynamic> json) {
    final rawDays = json['days'];
    return OpeningHoursSchedule(
      branchId: json['branchId']?.toString() ?? '',
      timezone: json['timezone']?.toString() ?? 'Africa/Algiers',
      hoursConfigured: json['hoursConfigured'] == true,
      version: (json['version'] as num?)?.toInt(),
      days: rawDays is List
          ? rawDays
                .whereType<Map>()
                .map((e) => OpeningDay.fromJson(Map<String, dynamic>.from(e)))
                .toList()
          : const [],
    );
  }

  static List<OpeningDay> blankWeek() {
    return List.generate(
      7,
      (i) => OpeningDay(dayOfWeek: i + 1, intervals: const []),
    );
  }
}

/// Merchant Branch availability override + effective open state.
class BranchAvailabilityState {
  const BranchAvailabilityState({
    required this.branchId,
    required this.timezone,
    required this.availabilityMode,
    required this.effectiveMode,
    required this.hoursConfigured,
    required this.isOpenNow,
    required this.acceptingOrders,
    required this.temporaryExpired,
    required this.outsideWeeklyHours,
    required this.reasonCode,
    required this.customerMessage,
    required this.closedUntil,
    required this.nextOpenAt,
    required this.currentClosesAt,
    required this.version,
    required this.updatedAt,
    this.hoursException,
  });

  final String branchId;
  final String timezone;

  /// Persisted mode (FOLLOW_SCHEDULE / FORCE_CLOSED / TEMPORARY_CLOSED).
  final String availabilityMode;
  final String effectiveMode;
  final bool hoursConfigured;

  /// Server effective Ouvert — never inferred from FOLLOW_SCHEDULE alone.
  final bool isOpenNow;
  final bool acceptingOrders;
  final bool temporaryExpired;
  final bool outsideWeeklyHours;
  final String? reasonCode;
  final String? customerMessage;
  final String? closedUntil;
  final String? nextOpenAt;
  final String? currentClosesAt;
  final int? version;
  final String? updatedAt;

  /// Exception applied to today's branch-local date, when one exists.
  final TodayHoursException? hoursException;

  bool get followsSchedule =>
      availabilityMode == 'FOLLOW_SCHEDULE' ||
      (temporaryExpired && effectiveMode == 'FOLLOW_SCHEDULE');

  factory BranchAvailabilityState.fromJson(Map<String, dynamic> json) {
    return BranchAvailabilityState(
      branchId: json['branchId']?.toString() ?? '',
      timezone: json['timezone']?.toString() ?? 'Africa/Algiers',
      availabilityMode:
          json['availabilityMode']?.toString() ?? 'FOLLOW_SCHEDULE',
      effectiveMode: json['effectiveMode']?.toString() ?? 'FOLLOW_SCHEDULE',
      hoursConfigured: json['hoursConfigured'] == true,
      isOpenNow: json['isOpenNow'] == true,
      acceptingOrders: json['acceptingOrders'] == true,
      temporaryExpired: json['temporaryExpired'] == true,
      outsideWeeklyHours: json['outsideWeeklyHours'] == true,
      reasonCode: json['reasonCode']?.toString(),
      customerMessage: json['customerMessage']?.toString(),
      closedUntil: json['closedUntil']?.toString(),
      nextOpenAt: json['nextOpenAt']?.toString(),
      currentClosesAt: json['currentClosesAt']?.toString(),
      version: (json['version'] as num?)?.toInt(),
      updatedAt: json['updatedAt']?.toString(),
      hoursException: json['hoursException'] is Map
          ? TodayHoursException.fromJson(
              Map<String, dynamic>.from(json['hoursException'] as Map),
            )
          : null,
    );
  }
}

class TodayHoursException {
  const TodayHoursException({
    required this.date,
    required this.closed,
    required this.label,
  });

  final String date;
  final bool closed;
  final String label;

  factory TodayHoursException.fromJson(Map<String, dynamic> json) {
    return TodayHoursException(
      date: json['date']?.toString() ?? '',
      closed: json['closed'] == true,
      label: json['label']?.toString() ?? '',
    );
  }
}

/// One branch-local civil date that replaces the weekly schedule.
class OpeningHoursException {
  const OpeningHoursException({
    required this.date,
    required this.closed,
    required this.label,
    required this.customerMessage,
    required this.intervals,
    required this.version,
    required this.updatedAt,
  });

  /// YYYY-MM-DD in Africa/Algiers.
  final String date;
  final bool closed;
  final String label;
  final String? customerMessage;

  /// Same-day intervals; `closes == '00:00'` means until midnight.
  final List<OpeningInterval> intervals;
  final int version;
  final String? updatedAt;

  factory OpeningHoursException.fromJson(Map<String, dynamic> json) {
    final raw = json['intervals'];
    return OpeningHoursException(
      date: json['date']?.toString() ?? '',
      closed: json['closed'] == true,
      label: json['label']?.toString() ?? '',
      customerMessage: json['customerMessage']?.toString(),
      intervals: raw is List
          ? raw
                .whereType<Map>()
                .map(
                  (e) => OpeningInterval.fromJson(Map<String, dynamic>.from(e)),
                )
                .toList()
          : const [],
      version: (json['version'] as num?)?.toInt() ?? 0,
      updatedAt: json['updatedAt']?.toString(),
    );
  }
}

class OpeningHoursExceptionList {
  const OpeningHoursExceptionList({
    required this.branchId,
    required this.timezone,
    required this.today,
    required this.items,
  });

  final String branchId;
  final String timezone;

  /// Branch-local civil date (YYYY-MM-DD) on the server clock.
  final String today;
  final List<OpeningHoursException> items;

  OpeningHoursException? byDate(String date) {
    for (final item in items) {
      if (item.date == date) return item;
    }
    return null;
  }

  factory OpeningHoursExceptionList.fromJson(Map<String, dynamic> json) {
    final raw = json['items'];
    return OpeningHoursExceptionList(
      branchId: json['branchId']?.toString() ?? '',
      timezone: json['timezone']?.toString() ?? 'Africa/Algiers',
      today: json['today']?.toString() ?? '',
      items: raw is List
          ? raw
                .whereType<Map>()
                .map(
                  (e) => OpeningHoursException.fromJson(
                    Map<String, dynamic>.from(e),
                  ),
                )
                .toList()
          : const [],
    );
  }
}

class MerchantNotificationItem {
  const MerchantNotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.read,
    required this.createdAt,
    this.type,
    this.sourceId,
  });

  final String id;
  final String title;
  final String body;
  final bool read;
  final String createdAt;
  final String? type;
  final String? sourceId;

  factory MerchantNotificationItem.fromJson(Map<String, dynamic> json) {
    final type = json['type']?.toString();
    var sourceId = json['sourceId']?.toString();
    final category = json['category']?.toString();
    if ((sourceId == null || sourceId.isEmpty) &&
        category != null &&
        category.contains(':')) {
      sourceId = category.substring(category.indexOf(':') + 1);
    }
    return MerchantNotificationItem(
      id: json['id']?.toString() ?? '',
      title:
          json['title']?.toString() ??
          json['subject']?.toString() ??
          'Notification',
      body: json['body']?.toString() ?? json['message']?.toString() ?? '',
      read: json['read'] == true || json['readAt'] != null,
      createdAt: json['createdAt']?.toString() ?? '',
      type:
          type ??
          (category != null && category.contains(':')
              ? category.substring(0, category.indexOf(':'))
              : null),
      sourceId: sourceId,
    );
  }
}
