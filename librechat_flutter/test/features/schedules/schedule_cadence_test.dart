// cadenceIntervalMinutes cases (Task 29.6).
import 'package:flutter_test/flutter_test.dart';
import 'package:librechat_flutter/core/models/schedule.dart';
import 'package:librechat_flutter/features/schedules/schedule_cadence.dart';

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

    test('daily and weekdays are 1440', () {
      for (final frequency in ['daily', 'weekdays']) {
        expect(
          cadenceIntervalMinutes(
            ScheduleCadence(frequency: frequency, hour: 9, minute: 0),
          ),
          1440,
          reason: frequency,
        );
      }
    });

    test('an unknown frequency is null', () {
      expect(
        cadenceIntervalMinutes(const ScheduleCadence(frequency: 'monthly')),
        isNull,
      );
    });
  });

  group('weekly', () {
    test('one day is a week', () => expect(weekly([3]), 10080));
    test('no days means Monday', () {
      expect(weekly(null), 10080);
      expect(weekly([]), 10080);
    });
    test('adjacent days', () => expect(weekly([1, 2]), 1440));
    test('the gap wraps the week', () => expect(weekly([0, 6]), 1440));
    test('repeated days count once', () => expect(weekly([1, 1]), 10080));
    test('every other day', () => expect(weekly([1, 3, 5]), 2880));
    test('the smaller side of the cycle', () => expect(weekly([1, 4]), 4320));
    test('7 is Sunday', () => expect(weekly([0, 7]), 10080));
    test('a day out of range is null', () => expect(weekly([1, 9]), isNull));
  });

  group('cron', () {
    test('*/5 * * * *', () => expect(cron('*/5 * * * *'), 5));
    test('0 * * * *', () => expect(cron('0 * * * *'), 60));
    test('0 9 * * *', () => expect(cron('0 9 * * *'), 1440));
    test('0 9,17 * * *', () => expect(cron('0 9,17 * * *'), 480));
    test('0 9 * * 1-5', () => expect(cron('0 9 * * 1-5'), 1440));
    test('0-30/10 * * * *', () => expect(cron('0-30/10 * * * *'), 10));
    test('n/step runs to the maximum', () => expect(cron('50/5 * * * *'), 5));
    test('30 8 1 * * (February 2027)', () => expect(cron('30 8 1 * *'), 40320));
    test('0 0 1 1 * (yearly)', () => expect(cron('0 0 1 1 *'), 525600));
    test('0 0 29 2 * fires once in the window', () {
      expect(cron('0 0 29 2 *'), isNull);
    });
    test('restricted day-of-month and day-of-week match on either', () {
      expect(cron('0 0 1 * 1'), 1440);
    });
    test('0 0 */2 * * (Jan 31 to Feb 1)', () {
      expect(cron('0 0 */2 * *'), 1440);
    });
    test('0 0 * * 7 (Sunday)', () => expect(cron('0 0 * * 7'), 10080));
    test('surrounding whitespace is trimmed', () {
      expect(cron('  0  9 * *   * '), 1440);
    });

    test('invalid expressions are null', () {
      for (final expression in [
        '* * * *',
        '* * * * * *',
        '61 * * * *',
        '5-1 * * * *',
        '*/0 * * * *',
        '0 0 * * MON',
        '0 0 * JAN *',
        '0 0 ? * *',
        '0 0 L * *',
        '0 0 15W * *',
        '0 0 * * 1#2',
        '0 0 0 * *',
        '1,,2 * * * *',
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
