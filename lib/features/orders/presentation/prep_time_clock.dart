/// Branch-local clock formatting for preparation estimates.
///
/// Server timestamps are absolute instants. Display uses the branch timezone
/// (SpeedyGo merchant branches: Africa/Algiers, UTC+1 year-round, no DST).
/// Arithmetic is always on the UTC instant — never on wall-clock digits alone.
library;

/// Africa/Algiers offset from UTC (no DST). Not a display patch: the branch zone.
const Duration kMerchantBranchUtcOffset = Duration(hours: 1);

/// Parses a server timestamp to a UTC [DateTime].
///
/// Accepts ISO-8601 (`…T…Z` / `…+01:00`) and Postgres-style
/// (`2026-09-25 04:19:45.801+01`).
DateTime? parsePrepInstant(String? raw) {
  if (raw == null) return null;
  var s = raw.trim();
  if (s.isEmpty) return null;
  if (s.contains(' ') && !s.contains('T')) {
    s = s.replaceFirst(' ', 'T');
  }
  // Expand bare ±HH to ±HH:00 for DateTime.parse.
  final bare = RegExp(r'([+-]\d{2})$').firstMatch(s);
  if (bare != null) {
    s = '${s}:00';
  }
  final parsed = DateTime.tryParse(s);
  if (parsed == null) return null;
  return parsed.toUtc();
}

/// Formats an absolute instant as `HH:mm` in the merchant branch timezone.
String formatPrepClock(
  DateTime instant, {
  Duration branchUtcOffset = kMerchantBranchUtcOffset,
}) {
  final utc = instant.toUtc();
  final wall = utc.add(branchUtcOffset);
  final h = wall.hour.toString().padLeft(2, '0');
  final m = wall.minute.toString().padLeft(2, '0');
  return '$h:$m';
}

/// Formats a server ISO string, or `—` if unparseable.
String formatPrepClockIso(
  String? iso, {
  Duration branchUtcOffset = kMerchantBranchUtcOffset,
}) {
  final instant = parsePrepInstant(iso);
  if (instant == null) return '—';
  return formatPrepClock(instant, branchUtcOffset: branchUtcOffset);
}

/// Branch-local `dd/MM` of [iso] when it is not the same branch day as
/// [now]; null when it is today or unparseable.
String? formatPrepOtherDayIso(
  String? iso,
  DateTime now, {
  Duration branchUtcOffset = kMerchantBranchUtcOffset,
}) {
  final instant = parsePrepInstant(iso);
  if (instant == null) return null;
  return formatPrepOtherDay(instant, now, branchUtcOffset: branchUtcOffset);
}

/// Branch-local `dd/MM` of [instant] when it is not the same branch day as
/// [now]; null when it is today.
String? formatPrepOtherDay(
  DateTime instant,
  DateTime now, {
  Duration branchUtcOffset = kMerchantBranchUtcOffset,
}) {
  final wall = instant.toUtc().add(branchUtcOffset);
  final today = now.toUtc().add(branchUtcOffset);
  if (wall.year == today.year &&
      wall.month == today.month &&
      wall.day == today.day) {
    return null;
  }
  final d = wall.day.toString().padLeft(2, '0');
  final m = wall.month.toString().padLeft(2, '0');
  return '$d/$m';
}

/// Current + proposed clocks after adding [addMinutes] to the absolute estimate.
///
/// With [now], [fromDay] / [toDay] carry the branch-local `dd/MM` of an
/// estimate that falls on another branch day than [now] (null otherwise).
({String from, String to, DateTime? nextUtc, String? fromDay, String? toDay})
prepEstimatePreview({
  required String? estimatedReadyAt,
  required int addMinutes,
  DateTime? now,
  Duration branchUtcOffset = kMerchantBranchUtcOffset,
}) {
  final current = parsePrepInstant(estimatedReadyAt);
  if (current == null) {
    return (from: '—', to: '—', nextUtc: null, fromDay: null, toDay: null);
  }
  final next = current.add(Duration(minutes: addMinutes));
  return (
    from: formatPrepClock(current, branchUtcOffset: branchUtcOffset),
    to: formatPrepClock(next, branchUtcOffset: branchUtcOffset),
    nextUtc: next,
    fromDay: now == null
        ? null
        : formatPrepOtherDay(current, now, branchUtcOffset: branchUtcOffset),
    toDay: now == null
        ? null
        : formatPrepOtherDay(next, now, branchUtcOffset: branchUtcOffset),
  );
}
