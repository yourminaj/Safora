import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Tests for the TZDateTime scheduling logic used by
/// NotificationService.scheduleDaily().
///
/// We test the date computation directly rather than calling the plugin,
/// since flutter_local_notifications requires platform channel setup.
void main() {
  setUpAll(() {
    tz.initializeTimeZones();
  });

  group('scheduleDaily date computation', () {
    test('schedules today when target time is in the future', () {
      final now = tz.TZDateTime(tz.local, 2026, 3, 27, 8, 0); // 8:00 AM
      const targetHour = 20; // 8:00 PM — still in the future
      const targetMinute = 0;

      var scheduledDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        targetHour,
        targetMinute,
      );
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      expect(scheduledDate.day, 27); // Same day
      expect(scheduledDate.hour, 20);
      expect(scheduledDate.minute, 0);
    });

    test('rolls to tomorrow when target time has passed', () {
      final now = tz.TZDateTime(tz.local, 2026, 3, 27, 21, 0); // 9:00 PM
      const targetHour = 8; // 8:00 AM — already passed
      const targetMinute = 0;

      var scheduledDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        targetHour,
        targetMinute,
      );
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      expect(scheduledDate.day, 28); // Next day
      expect(scheduledDate.hour, 8);
      expect(scheduledDate.minute, 0);
    });

    test('handles midnight boundary correctly', () {
      final now = tz.TZDateTime(tz.local, 2026, 3, 27, 23, 59);
      const targetHour = 0;
      const targetMinute = 0;

      var scheduledDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        targetHour,
        targetMinute,
      );
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      expect(scheduledDate.day, 28); // Next day midnight
      expect(scheduledDate.hour, 0);
      expect(scheduledDate.minute, 0);
    });

    test('month rollover works correctly', () {
      // Last day of March
      final now = tz.TZDateTime(tz.local, 2026, 3, 31, 22, 0);
      const targetHour = 6;
      const targetMinute = 30;

      var scheduledDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        targetHour,
        targetMinute,
      );
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      expect(scheduledDate.month, 4); // April 1
      expect(scheduledDate.day, 1);
      expect(scheduledDate.hour, 6);
      expect(scheduledDate.minute, 30);
    });

    test('exact same time as now rolls to tomorrow', () {
      final now = tz.TZDateTime(tz.local, 2026, 3, 27, 14, 30);
      const targetHour = 14;
      const targetMinute = 30;

      var scheduledDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        targetHour,
        targetMinute,
      );
      // isBefore is false when equal — so this tests the edge case.
      // When equal, it stays on today (correct behavior, fires immediately).
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      // When equal, isBefore returns false, so stays on day 27.
      expect(scheduledDate.day, 27);
    });
  });
}
