import 'package:freezed_annotation/freezed_annotation.dart';

part 'schedule.freezed.dart';
part 'schedule.g.dart';

/// `ScheduleCadence.frequency` values. The field stays a String, so an
/// unknown one decodes.
abstract final class ScheduleFrequency {
  static const hourly = 'hourly';
  static const daily = 'daily';
  static const weekdays = 'weekdays';
  static const weekly = 'weekly';
  static const cron = 'cron';
}

/// `Schedule.cadence`: a structured cadence (`hour`, `minute`, and
/// `daysOfWeek` for weekly, numbered as in cron with 0 = Sunday) or a cron
/// `expression`. Mirrors the KMP `core/model/.../schedule/Schedule.kt`.
@freezed
abstract class ScheduleCadence with _$ScheduleCadence {
  const factory ScheduleCadence({
    required String frequency,
    int? hour,
    int? minute,
    List<int>? daysOfWeek,
    String? expression,
  }) = _ScheduleCadence;

  factory ScheduleCadence.fromJson(Map<String, Object?> json) =>
      _$ScheduleCadenceFromJson(json);
}
