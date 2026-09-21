import 'package:chronicle/services/notifications.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('reminderFireTime', () {
    test('subtracts offset from dated time', () {
      expect(
        reminderFireTime(
          dueDate: '2026-09-20',
          dueMinutes: 540,
          offsetMinutes: 60,
        ),
        DateTime(2026, 9, 20, 8, 0),
      );
    });

    test('all-day tasks count from 09:00', () {
      expect(
        reminderFireTime(
          dueDate: '2026-09-20',
          dueMinutes: null,
          offsetMinutes: 1440,
        ),
        DateTime(2026, 9, 19, 9, 0),
      );
    });

    test('null without due date or with bad date', () {
      expect(
        reminderFireTime(dueDate: null, dueMinutes: 540, offsetMinutes: 60),
        isNull,
      );
      expect(
        reminderFireTime(
          dueDate: 'not-a-date',
          dueMinutes: null,
          offsetMinutes: 60,
        ),
        isNull,
      );
    });

    test('zero offset fires exactly at due time', () {
      expect(
        reminderFireTime(
          dueDate: '2026-09-20',
          dueMinutes: 1020,
          offsetMinutes: 0,
        ),
        DateTime(2026, 9, 20, 17, 0),
      );
    });
  });

  group('classReminderId', () {
    test('is deterministic and in the high range', () {
      final a = classReminderId(
        classId: 1,
        isoDate: '2026-09-14',
        startMinutes: 540,
      );
      final b = classReminderId(
        classId: 1,
        isoDate: '2026-09-14',
        startMinutes: 540,
      );
      expect(a, b);
      expect(a >= 0x40000000 && a <= 0x7FFFFFFF, isTrue);
    });

    test('differs across inputs', () {
      final ids = {
        classReminderId(classId: 1, isoDate: '2026-09-14', startMinutes: 540),
        classReminderId(classId: 2, isoDate: '2026-09-14', startMinutes: 540),
        classReminderId(classId: 1, isoDate: '2026-09-15', startMinutes: 540),
        classReminderId(classId: 1, isoDate: '2026-09-14', startMinutes: 600),
      };
      expect(ids, hasLength(4));
    });
  });
}
