import '../../core/models/schedule.dart';

/// The shortest gap in minutes between two runs of [cadence], for the
/// Schedule editor's `minIntervalMinutes` check (Req 39.5, 39.6). Null means
/// the App can't judge, and the Server's answer stands.
///
/// Transcribed from upstream `packages/data-provider/src/cadence.ts`
/// (`cadenceIntervalMinutes`), as the KMP `ScheduleCadenceRules.kt` is:
///
/// - hourly is 60.
/// - daily and weekdays are 1440 less [_dstCompressionMinutes].
/// - weekly is 1440 times the smallest cyclic gap between the distinct
///   `daysOfWeek`, less [_dstCompressionMinutes]. No days means Monday, as
///   on the Server. A day outside 0–6 (the Server's schema range) gives null.
/// - cron gives null. The Server measures a cron expression by walking its
///   real occurrences in the schedule's time zone with croner; the App
///   leaves that to the Server rather than guess.
int? cadenceIntervalMinutes(ScheduleCadence cadence) =>
    switch (cadence.frequency) {
      ScheduleFrequency.hourly => 60,
      ScheduleFrequency.daily ||
      ScheduleFrequency.weekdays => _day - _dstCompressionMinutes,
      ScheduleFrequency.weekly => _weeklyInterval(cadence.daysOfWeek),
      _ => null,
    };

const _day = 1440;

/// Spring-forward shortens a day-or-longer gap by up to two hours
/// (Antarctica/Troll), so the Server counts that much off the nominal gap.
/// Hourly gaps only ever lengthen.
const _dstCompressionMinutes = 120;

/// Mirrors the Server default when a weekly cadence has no `daysOfWeek`.
const _weeklyDefaultDay = 1;

int? _weeklyInterval(List<int>? daysOfWeek) {
  final days = (daysOfWeek == null || daysOfWeek.isEmpty)
      ? const [_weeklyDefaultDay]
      : daysOfWeek;
  if (days.any((d) => d < 0 || d > 6)) return null;
  // Deduped, as on the Server: a stored [1, 1] is one day, not a 0-day gap.
  final sorted = days.toSet().toList()..sort();
  var gap = 7 - sorted.last + sorted.first;
  for (var i = 1; i < sorted.length; i++) {
    final step = sorted[i] - sorted[i - 1];
    if (step < gap) gap = step;
  }
  return _day * gap - _dstCompressionMinutes;
}
