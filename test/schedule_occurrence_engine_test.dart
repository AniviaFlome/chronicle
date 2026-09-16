import 'package:chronicle/domain/schedule_models.dart';
import 'package:chronicle/domain/schedule_occurrence_engine.dart';
import 'package:flutter_test/flutter_test.dart';

ScheduleSlot slot({
  required int id,
  required int classId,
  int dayOfWeek = 1,
  int startMinutes = 540,
  int endMinutes = 630,
  String? room,
  RotationType rotation = RotationType.weekly,
  int? weekParity,
  int? cycleLength,
  List<int>? cycleWeeks,
  DateTime? validFrom,
  DateTime? validTo,
}) =>
    ScheduleSlot(
      id: id,
      classId: classId,
      dayOfWeek: dayOfWeek,
      startMinutes: startMinutes,
      endMinutes: endMinutes,
      room: room,
      rotation: rotation,
      weekParity: weekParity,
      cycleLength: cycleLength,
      cycleWeeks: cycleWeeks,
      validFrom: validFrom,
      validTo: validTo,
    );

DateTime d(int year, int month, int day) => DateTime(year, month, day);

void main() {
  // 2026-09-14 is a Monday. Weeks start Monday.
  final anchor = d(2026, 9, 14);

  group('weekly slots', () {
    test('expands one occurrence per matching weekday', () {
      final engine = ScheduleOccurrenceEngine(
        classes: [ScheduledClass(id: 1, startDate: d(2026, 9, 1), endDate: d(2026, 9, 30))],
        slots: [slot(id: 10, classId: 1, dayOfWeek: 1, room: 'B12')],
        weekABAnchor: anchor,
      );

      final occ = engine.occurrences(rangeStart: d(2026, 9, 1), rangeEnd: d(2026, 9, 30));

      // Mondays in Sept 2026: 7, 14, 21, 28.
      expect(occ.map((o) => o.date), [d(2026, 9, 7), d(2026, 9, 14), d(2026, 9, 21), d(2026, 9, 28)]);
      expect(occ.first.room, 'B12');
      expect(occ.first.startMinutes, 540);
      expect(occ.first.endMinutes, 630);
    });

    test('honours class start/end clamping', () {
      final engine = ScheduleOccurrenceEngine(
        classes: [ScheduledClass(id: 1, startDate: d(2026, 9, 10), endDate: d(2026, 9, 20))],
        slots: [slot(id: 10, classId: 1, dayOfWeek: 1)],
        weekABAnchor: anchor,
      );
      final occ = engine.occurrences(rangeStart: d(2026, 9, 1), rangeEnd: d(2026, 9, 30));
      expect(occ.map((o) => o.date), [d(2026, 9, 14)]); // 7th is before start
    });

    test('weekend weekdays map correctly (Sunday = 7)', () {
      final engine = ScheduleOccurrenceEngine(
        classes: [ScheduledClass(id: 1)],
        slots: [slot(id: 10, classId: 1, dayOfWeek: 7)],
        weekABAnchor: anchor,
      );
      final occ = engine.occurrences(rangeStart: d(2026, 9, 13), rangeEnd: d(2026, 9, 14));
      expect(occ.map((o) => o.date), [d(2026, 9, 13)]); // a Sunday
    });
  });

  group('week A/B rotation', () {
    test('alternates parity across fortnights', () {
      final slotA = slot(id: 10, classId: 1, dayOfWeek: 1, rotation: RotationType.weekAB, weekParity: 0);
      final slotB = slot(id: 11, classId: 1, dayOfWeek: 1, rotation: RotationType.weekAB, weekParity: 1);
      final engine = ScheduleOccurrenceEngine(
        classes: [ScheduledClass(id: 1)],
        slots: [slotA, slotB],
        weekABAnchor: anchor,
      );

      // Mondays: Sep 14 (anchor week = A), Sep 21 (B), Sep 28 (A), Oct 5 (B).
      final occ = engine.occurrences(rangeStart: d(2026, 9, 14), rangeEnd: d(2026, 10, 5));

      final weekA = occ.where((o) => o.scheduleItemId == 10).map((o) => o.date).toList();
      final weekB = occ.where((o) => o.scheduleItemId == 11).map((o) => o.date).toList();
      expect(weekA, [d(2026, 9, 14), d(2026, 9, 28)]);
      expect(weekB, [d(2026, 9, 21), d(2026, 10, 5)]);
    });

    test('custom weekStartDay shifts parity anchor week', () {
      // Weeks start on Sunday; anchor Sep 13 (Sunday).
      final engine = ScheduleOccurrenceEngine(
        classes: [ScheduledClass(id: 1)],
        slots: [slot(id: 10, classId: 1, dayOfWeek: 1, rotation: RotationType.weekAB, weekParity: 0)],
        weekABAnchor: d(2026, 9, 13),
        weekStartDay: 7,
      );
      // Monday Sep 14 belongs to the anchor week (Sun Sep 13 - Sat Sep 19) -> A.
      final occ = engine.occurrences(rangeStart: d(2026, 9, 14), rangeEnd: d(2026, 9, 14));
      expect(occ, isNotEmpty);
      expect(occ.single.scheduleItemId, 10);

      // With weekStartDay = 1 (default), Sep 14 would be in week A anyway,
      // but Sep 21 with Sunday-start weeks: week starts Sep 20 (Sun) ->
      // diff 1 week -> parity B.
      final engineB = ScheduleOccurrenceEngine(
        classes: [ScheduledClass(id: 1)],
        slots: [slot(id: 10, classId: 1, dayOfWeek: 1, rotation: RotationType.weekAB, weekParity: 0)],
        weekABAnchor: d(2026, 9, 13),
        weekStartDay: 7,
      );
      final occB = engineB.occurrences(rangeStart: d(2026, 9, 21), rangeEnd: d(2026, 9, 21));
      expect(occB, isEmpty);
    });
  });

  group('custom cycle rotation', () {
    test('cycles with given length and weeks', () {
      // 3-week cycle, slot on weeks 1 and 3 (1-based).
      final engine = ScheduleOccurrenceEngine(
        classes: [ScheduledClass(id: 1)],
        slots: [
          slot(
            id: 10,
            classId: 1,
            dayOfWeek: 3, // Wednesday
            rotation: RotationType.custom,
            cycleLength: 3,
            cycleWeeks: [1, 3],
          ),
        ],
        weekABAnchor: anchor,
      );

      final occ = engine.occurrences(rangeStart: d(2026, 9, 14), rangeEnd: d(2026, 10, 9));

      // Wednesdays: Sep 16 (cycle week 1 -> yes), Sep 23 (2 -> no),
      // Sep 30 (3 -> yes), Oct 7 (cycle week 1 again -> yes).
      expect(occ.map((o) => o.date), [d(2026, 9, 16), d(2026, 9, 30), d(2026, 10, 7)]);
    });
  });

  group('holidays', () {
    test('suppress occurrences inside range', () {
      final engine = ScheduleOccurrenceEngine(
        classes: [ScheduledClass(id: 1)],
        slots: [slot(id: 10, classId: 1, dayOfWeek: 1)],
        holidays: [HolidayRange(start: d(2026, 9, 10), end: d(2026, 9, 20))],
        weekABAnchor: anchor,
      );
      final occ = engine.occurrences(rangeStart: d(2026, 9, 1), rangeEnd: d(2026, 9, 30));
      // Sep 14 is inside the Sep 10-20 holiday.
      expect(occ.map((o) => o.date), [d(2026, 9, 7), d(2026, 9, 21), d(2026, 9, 28)]);
    });
  });

  group('exceptions', () {
    test('cancelled removes occurrence', () {
      final engine = ScheduleOccurrenceEngine(
        classes: [ScheduledClass(id: 1)],
        slots: [slot(id: 10, classId: 1, dayOfWeek: 1)],
        exceptions: [
          ScheduleException(
            scheduleItemId: 10,
            date: d(2026, 9, 14),
            status: ExceptionStatus.cancelled,
          ),
        ],
        weekABAnchor: anchor,
      );
      final occ = engine.occurrences(rangeStart: d(2026, 9, 14), rangeEnd: d(2026, 9, 28));
      expect(occ.map((o) => o.date), [d(2026, 9, 21), d(2026, 9, 28)]);
    });

    test('moved changes time and room and flags isMoved', () {
      final engine = ScheduleOccurrenceEngine(
        classes: [ScheduledClass(id: 1)],
        slots: [slot(id: 10, classId: 1, dayOfWeek: 1, room: 'B12')],
        exceptions: [
          ScheduleException(
            scheduleItemId: 10,
            date: d(2026, 9, 14),
            status: ExceptionStatus.moved,
            newStartMinutes: 780,
            newEndMinutes: 870,
            newRoom: 'C3',
          ),
        ],
        weekABAnchor: anchor,
      );
      final occ = engine.occurrences(rangeStart: d(2026, 9, 14), rangeEnd: d(2026, 9, 14));
      expect(occ.single.startMinutes, 780);
      expect(occ.single.endMinutes, 870);
      expect(occ.single.room, 'C3');
      expect(occ.single.isMoved, isTrue);
    });
  });

  group('sorting and identity', () {
    test('sorted by date then start time', () {
      final engine = ScheduleOccurrenceEngine(
        classes: [ScheduledClass(id: 1), ScheduledClass(id: 2)],
        slots: [
          slot(id: 10, classId: 1, dayOfWeek: 1, startMinutes: 600),
          slot(id: 11, classId: 2, dayOfWeek: 1, startMinutes: 540),
          slot(id: 12, classId: 2, dayOfWeek: 2, startMinutes: 540),
        ],
        weekABAnchor: anchor,
      );
      final occ = engine.occurrences(rangeStart: d(2026, 9, 14), rangeEnd: d(2026, 9, 15));
      expect(
        occ.map((o) => (o.date, o.startMinutes)),
        [(d(2026, 9, 14), 540), (d(2026, 9, 14), 600), (d(2026, 9, 15), 540)],
      );
    });

    test('two classes same time same day both appear', () {
      final engine = ScheduleOccurrenceEngine(
        classes: [ScheduledClass(id: 1), ScheduledClass(id: 2)],
        slots: [
          slot(id: 10, classId: 1, dayOfWeek: 1),
          slot(id: 11, classId: 2, dayOfWeek: 1),
        ],
        weekABAnchor: anchor,
      );
      final occ = engine.occurrences(rangeStart: d(2026, 9, 14), rangeEnd: d(2026, 9, 14));
      expect(occ.length, 2);
    });
  });

  group('teachingDays', () {
    test('deduplicates multiple slots per day', () {
      final engine = ScheduleOccurrenceEngine(
        classes: [ScheduledClass(id: 1)],
        slots: [
          slot(id: 10, classId: 1, dayOfWeek: 1),
          slot(id: 11, classId: 1, dayOfWeek: 1, startMinutes: 780, endMinutes: 870),
        ],
        weekABAnchor: anchor,
      );
      final days = engine.teachingDays(from: d(2026, 9, 14), to: d(2026, 9, 14));
      expect(days, hasLength(1));
    });
  });
}
