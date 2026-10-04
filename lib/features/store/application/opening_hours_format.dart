import 'package:speedygo_merchant_app/features/store/data/store_models.dart';

/// Mirrors backend `OPENING_HOURS_MAX_INTERVALS_PER_DAY`.
const openingHoursMaxIntervalsPerDay = 3;

/// Africa/Algiers is UTC+1 year-round (no DST).
const branchUtcOffset = Duration(hours: 1);

/// ISO weekdays, Monday first (decision D-D6).
const openingHoursDisplayOrder = <int>[1, 2, 3, 4, 5, 6, 7];

const openingHoursDayLabels = <int, String>{
  1: 'Lundi',
  2: 'Mardi',
  3: 'Mercredi',
  4: 'Jeudi',
  5: 'Vendredi',
  6: 'Samedi',
  7: 'Dimanche',
};

DateTime branchLocalNow(DateTime now) => now.toUtc().add(branchUtcOffset);

int? parseHhMm(String value) {
  final parts = value.split(':');
  if (parts.length != 2) return null;
  final h = int.tryParse(parts[0]);
  final m = int.tryParse(parts[1]);
  if (h == null || m == null || h < 0 || h > 23 || m < 0 || m > 59) {
    return null;
  }
  return h * 60 + m;
}

String formatHhMm(int minuteOfDay) {
  final h = (minuteOfDay ~/ 60) % 24;
  final m = minuteOfDay % 60;
  return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
}

String formatInterval(OpeningInterval i) => '${i.opens}–${i.closes}';

String formatIntervals(List<OpeningInterval> intervals) =>
    intervals.map(formatInterval).join(' · ');

/// Like [formatIntervals], but lines only break between intervals.
String formatIntervalsUnbroken(List<OpeningInterval> intervals) =>
    intervals.map((i) => '${i.opens}\u2060–\u2060${i.closes}').join(' · ');

/// Intervals of the branch-local weekday containing [now].
List<OpeningInterval>? todayIntervals(
  OpeningHoursSchedule schedule,
  DateTime now,
) {
  if (!schedule.hoursConfigured) return null;
  final dow = branchLocalNow(now).weekday;
  for (final d in schedule.days) {
    if (d.dayOfWeek == dow) return d.intervals;
  }
  return const [];
}

/// Validation matching the backend day rules; returns null when valid.
///
/// `closes < opens` runs past midnight; `00:00→00:00` is 24h; other
/// zero-length intervals are rejected. Overlaps are half-open.
OpeningDayIssue? validateDayIntervals(List<OpeningInterval> intervals) {
  if (intervals.length > openingHoursMaxIntervalsPerDay) {
    return OpeningDayIssue.tooMany;
  }
  final spans = <(int, int)>[];
  for (final i in intervals) {
    final o = parseHhMm(i.opens);
    final c = parseHhMm(i.closes);
    if (o == null || c == null) return OpeningDayIssue.invalid;
    if (o == c && !(o == 0 && c == 0)) return OpeningDayIssue.zeroLength;
    final end = c <= o ? c + 24 * 60 : c;
    spans.add((o, end));
  }
  spans.sort((a, b) => a.$1.compareTo(b.$1));
  for (var k = 1; k < spans.length; k++) {
    if (spans[k].$1 < spans[k - 1].$2) return OpeningDayIssue.overlap;
  }
  return null;
}

enum OpeningDayIssue { tooMany, invalid, zeroLength, overlap }

/// Validation matching the backend exception rules; returns null when valid.
///
/// Exception intervals stay inside their civil date: `opens < closes`, or
/// `closes == 00:00` meaning midnight. Overnight ranges are rejected.
ExceptionIntervalIssue? validateExceptionIntervals(
  List<OpeningInterval> intervals,
) {
  if (intervals.isEmpty) return ExceptionIntervalIssue.empty;
  if (intervals.length > openingHoursMaxIntervalsPerDay) {
    return ExceptionIntervalIssue.tooMany;
  }
  final spans = <(int, int)>[];
  for (final i in intervals) {
    final o = parseHhMm(i.opens);
    final c = parseHhMm(i.closes);
    if (o == null || c == null) return ExceptionIntervalIssue.invalid;
    if (c == o && c != 0) return ExceptionIntervalIssue.zeroLength;
    if (c != 0 && c < o) return ExceptionIntervalIssue.overnight;
    spans.add((o, c == 0 ? 24 * 60 : c));
  }
  spans.sort((a, b) => a.$1.compareTo(b.$1));
  for (var k = 1; k < spans.length; k++) {
    if (spans[k].$1 < spans[k - 1].$2) return ExceptionIntervalIssue.overlap;
  }
  return null;
}

enum ExceptionIntervalIssue {
  empty,
  tooMany,
  invalid,
  zeroLength,
  overnight,
  overlap,
}

const _frMonths = <String>[
  'Janvier',
  'Février',
  'Mars',
  'Avril',
  'Mai',
  'Juin',
  'Juillet',
  'Août',
  'Septembre',
  'Octobre',
  'Novembre',
  'Décembre',
];

/// `YYYY-MM-DD` civil date (no timezone shift) or null when malformed.
DateTime? parseCivilDate(String value) {
  final parts = value.split('-');
  if (parts.length != 3) return null;
  final y = int.tryParse(parts[0]);
  final m = int.tryParse(parts[1]);
  final d = int.tryParse(parts[2]);
  if (y == null || m == null || d == null) return null;
  final date = DateTime.utc(y, m, d);
  if (date.year != y || date.month != m || date.day != d) return null;
  return date;
}

String civilDateKey(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

/// "Lundi 5 Octobre 2026" for a `YYYY-MM-DD` civil date.
String formatCivilDateFr(String value) {
  final date = parseCivilDate(value);
  if (date == null) return value;
  return '${openingHoursDayLabels[date.weekday]} ${date.day} '
      '${_frMonths[date.month - 1]} ${date.year}';
}
