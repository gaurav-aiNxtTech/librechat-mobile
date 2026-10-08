import '../../core/models/schedule.dart';

/// The shortest gap in minutes between two runs of [cadence], for the
/// Schedule editor's `minIntervalMinutes` check (Req 39.5, 39.6). Null means
/// the App can't judge, and the Server's answer stands.
///
/// - hourly is 60, daily and weekdays are 1440.
/// - weekly is 1440 times the smallest cyclic gap between the distinct
///   `daysOfWeek` (7 reads as Sunday, 0). No days means Monday, as on the
///   Server.
/// - cron expands a 5-field `expression` of `*`, numbers, `a-b` ranges,
///   comma lists and `/step`s, and takes the smallest gap between fire
///   times over 2027–2028 (one common and one leap year, by naive UTC wall
///   clock). When day-of-month and day-of-week are both restricted (not
///   `*`), a day matches on either. Names, `?`, `L`, `W` and `#` give null.
///
/// Unlike the KMP `ScheduleCadenceRules.kt`, the values are nominal (no DST
/// allowance) and cron is expanded rather than left to the Server.
int? cadenceIntervalMinutes(ScheduleCadence cadence) =>
    switch (cadence.frequency) {
      ScheduleFrequency.hourly => 60,
      ScheduleFrequency.daily || ScheduleFrequency.weekdays => _day,
      ScheduleFrequency.weekly => _weeklyInterval(cadence.daysOfWeek),
      ScheduleFrequency.cron => _cronInterval(cadence.expression),
      _ => null,
    };

const _day = 1440;

int? _weeklyInterval(List<int>? daysOfWeek) {
  final days = (daysOfWeek == null || daysOfWeek.isEmpty)
      ? const [1]
      : daysOfWeek;
  if (days.any((d) => d < 0 || d > 7)) return null;
  final sorted = {for (final d in days) d % 7}.toList()..sort();
  var gap = 7 - sorted.last + sorted.first;
  for (var i = 1; i < sorted.length; i++) {
    final step = sorted[i] - sorted[i - 1];
    if (step < gap) gap = step;
  }
  return _day * gap;
}

final _cronItem = RegExp(r'^(\*|\d+|\d+-\d+)(?:/(\d+))?$');

/// The values a cron field allows, or null when it doesn't parse.
Set<int>? _field(String field, int min, int max) {
  final values = <int>{};
  for (final item in field.split(',')) {
    final match = _cronItem.firstMatch(item);
    if (match == null) return null;
    final range = match[1]!;
    final stepText = match[2];
    final step = stepText == null ? 1 : int.tryParse(stepText);
    if (step == null || step < 1) return null;
    int from;
    int to;
    if (range == '*') {
      from = min;
      to = max;
    } else if (range.contains('-')) {
      final bounds = range.split('-');
      final a = int.tryParse(bounds[0]);
      final b = int.tryParse(bounds[1]);
      if (a == null || b == null) return null;
      from = a;
      to = b;
    } else {
      final n = int.tryParse(range);
      if (n == null) return null;
      from = n;
      to = stepText == null ? n : max;
    }
    if (from < min || to > max || from > to) return null;
    for (var v = from; v <= to; v += step) {
      values.add(v);
    }
  }
  return values;
}

final _start = DateTime.utc(2027);
final _end = DateTime.utc(2029);

int? _cronInterval(String? expression) {
  if (expression == null) return null;
  final fields = expression.trim().split(RegExp(r'\s+'));
  if (fields.length != 5) return null;
  final minutes = _field(fields[0], 0, 59);
  final hours = _field(fields[1], 0, 23);
  final monthDays = _field(fields[2], 1, 31);
  final months = _field(fields[3], 1, 12);
  final weekDays = _field(fields[4], 0, 7)?.map((d) => d % 7).toSet();
  if (minutes == null ||
      hours == null ||
      monthDays == null ||
      months == null ||
      weekDays == null) {
    return null;
  }
  final monthDayRestricted = fields[2] != '*';
  final weekDayRestricted = fields[4] != '*';
  final sortedHours = hours.toList()..sort();
  final sortedMinutes = minutes.toList()..sort();

  bool dayMatches(DateTime day) {
    if (!months.contains(day.month)) return false;
    final byMonthDay = monthDays.contains(day.day);
    // DateTime.weekday is 1 (Monday) to 7 (Sunday); cron's Sunday is 0.
    final byWeekDay = weekDays.contains(day.weekday % 7);
    if (monthDayRestricted && weekDayRestricted) return byMonthDay || byWeekDay;
    if (monthDayRestricted) return byMonthDay;
    if (weekDayRestricted) return byWeekDay;
    return true;
  }

  int? previous;
  int? shortest;
  final days = _end.difference(_start).inDays;
  for (var index = 0; index < days; index++) {
    // Naive UTC days: DateTime.utc normalizes the day overflow.
    if (!dayMatches(DateTime.utc(_start.year, 1, 1 + index))) continue;
    for (final hour in sortedHours) {
      for (final minute in sortedMinutes) {
        final fire = index * _day + hour * 60 + minute;
        if (previous != null) {
          final gap = fire - previous;
          if (shortest == null || gap < shortest) shortest = gap;
          if (shortest == 1) return 1;
        }
        previous = fire;
      }
    }
  }
  return shortest;
}
