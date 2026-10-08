// cadenceIntervalMinutes cases (Task 29.6), ported from upstream
// `packages/api/src/schedules/cadence.spec.ts` and the KMP
// `core/model/.../schedule/ScheduleCadenceRulesTest.kt`.
import 'package:flutter_test/flutter_test.dart';
import 'package:librechat_flutter/core/models/schedule.dart';
import 'package:librechat_flutter/features/schedules/schedule_cadence.dart';

int? structured(String frequency) => cadenceIntervalMinutes(
  ScheduleCadence(frequency: frequency, hour: 9, minute: 0),
);

int? weekly(List<int>? days) => cadenceIntervalMinutes(
  ScheduleCadence(
    frequency: ScheduleFrequency.weekly,
    hour: 9,
    minute: 0,
    daysOfWeek: days,
  ),
);

int? cron(String? expression) => cadenceIntervalMinutes(
  ScheduleCadence(frequency: ScheduleFrequency.cron, expression: expression),
);

/// The Server admits a cadence when its interval is at least the floor
/// (`handlers.ts`: `cadenceIntervalMinutes(...) >= minIntervalMinutes`).
bool admits(int? interval, int minIntervalMinutes) =>
    interval! >= minIntervalMinutes;

void main() {
  group('structured', () {
    test('hourly is 60', () {
      expect(
        cadenceIntervalMinutes(
          const ScheduleCadence(frequency: 'hourly', hour: 0, minute: 15),
        ),
        60,
      );
    });

    test('daily and weekdays allow for a 2-hour spring-forward', () {
      expect(structured(ScheduleFrequency.daily), 24 * 60 - 120);
      expect(structured(ScheduleFrequency.weekdays), 24 * 60 - 120);
    });

    test('an unknown frequency is null', () {
      expect(
        cadenceIntervalMinutes(const ScheduleCadence(frequency: 'monthly')),
        isNull,
      );
    });
  });

  group('weekly', () {
    test('one day is a week less the allowance', () {
      expect(weekly([3]), 7 * 24 * 60 - 120);
    });
    test('no days means Monday', () {
      expect(weekly(null), 7 * 24 * 60 - 120);
      expect(weekly([]), 7 * 24 * 60 - 120);
    });
    test('adjacent days', () => expect(weekly([1, 2]), 24 * 60 - 120));
    test('the gap wraps the week', () => expect(weekly([0, 6]), 24 * 60 - 120));
    test('repeated days count once', () {
      expect(weekly([1, 1]), 7 * 24 * 60 - 120);
    });
    test('every other day', () => expect(weekly([1, 3, 5]), 2 * 24 * 60 - 120));
    test('the smaller side of the cycle', () {
      expect(weekly([1, 4]), 3 * 24 * 60 - 120);
    });
    test('a day outside 0-6 is null', () {
      expect(weekly([1, 7]), isNull);
      expect(weekly([-1]), isNull);
    });
  });

  group('the minIntervalMinutes floor', () {
    test('daily is admitted up to 1320 and refused from 1321', () {
      final daily = structured(ScheduleFrequency.daily);
      expect(admits(daily, 1320), isTrue);
      expect(admits(daily, 1321), isFalse);
      expect(admits(daily, 1440), isFalse);
    });

    test('weekdays and Mon+Tue weekly behave like daily', () {
      for (final interval in [
        structured(ScheduleFrequency.weekdays),
        weekly([1, 2]),
      ]) {
        expect(admits(interval, 1320), isTrue);
        expect(admits(interval, 1321), isFalse);
      }
    });

    test('a single-day weekly is admitted up to 9960', () {
      final interval = weekly([3]);
      expect(admits(interval, 1440), isTrue);
      expect(admits(interval, 9960), isTrue);
      expect(admits(interval, 9961), isFalse);
      expect(admits(interval, 10080), isFalse);
    });

    test('hourly has no allowance', () {
      final hourly = structured(ScheduleFrequency.hourly);
      expect(admits(hourly, 60), isTrue);
      expect(admits(hourly, 61), isFalse);
    });
  });

  group('cron is left to the Server', () {
    test('any expression is null', () {
      for (final expression in [
        '*/5 * * * *',
        '0 9 * * *',
        '0 0,12 * * *',
        'not a cron',
        '',
      ]) {
        expect(cron(expression), isNull, reason: expression);
      }
    });
    test('a null expression is null', () => expect(cron(null), isNull));
  });

  test('ScheduleCadence JSON drops nulls and unknown keys', () {
    final cadence = ScheduleCadence.fromJson({
      'frequency': 'weekly',
      'hour': 9,
      'minute': 30,
      'daysOfWeek': [1, 4],
      'extra': true,
    });
    expect(
      cadence,
      const ScheduleCadence(
        frequency: 'weekly',
        hour: 9,
        minute: 30,
        daysOfWeek: [1, 4],
      ),
    );
    expect(cadence.toJson(), {
      'frequency': 'weekly',
      'hour': 9,
      'minute': 30,
      'daysOfWeek': [1, 4],
    });
  });
}
