import 'package:chronicle/domain/schedule_models.dart';
import 'package:chronicle/utils/time_format.dart';

/// Expands recurring [ScheduleSlot]s into concrete [ClassOccurrence]s over a
/// date range.
///
/// Rules:
///  - only days whose weekday matches a slot's day produce occurrences
///  - class [ScheduledClass.startDate]/[endDate] and slot validFrom/validTo
///    clamp the range
///  - holidays suppress occurrences on their dates
///  - a (slot, date) pair matched by a [ScheduleException] is either removed
///    (cancelled) or replaced (moved: new times/room)
///  - week A/B parity is anchored via [weekABAnchor]: the week (starting
///    [weekStartDay]) containing the anchor is week A
///  - custom rotation weeks cycle with length [slot.cycleLength], anchored at
///    the same week start as the A/B parity
///  - day rotation slots match when the date's rotation day (see
///    [rotationDayIndex], driven by [dayRotation]) is in [slot.rotationDays]
class ScheduleOccurrenceEngine {
  final List<ScheduledClass> classes;
  final List<ScheduleSlot> slots;
  final List<ScheduleException> exceptions;
  final List<HolidayRange> holidays;

  /// Anchor date whose week is "week A" (may be any day within that week).
  final DateTime weekABAnchor;

  /// 1 = Monday .. 7 = Sunday (ISO). Week identity and parity cycle start on
  /// this weekday.
  final int weekStartDay;

  /// Day-rotation configuration. Slots with [RotationType.dayRotation] never
  /// match when this is null.
  final DayRotationConfig? dayRotation;

  const ScheduleOccurrenceEngine({
    required this.classes,
    required this.slots,
    this.exceptions = const [],
    this.holidays = const [],
    required this.weekABAnchor,
    this.weekStartDay = 1,
    this.dayRotation,
  });

  /// All occurrences for classes whose id is in [classIds] (empty = all)
  /// between [rangeStart] and [rangeEnd] inclusive, sorted by date then start
  /// time.
  List<ClassOccurrence> occurrences({
    required DateTime rangeStart,
    required DateTime rangeEnd,
    Set<int>? classIds,
  }) {
    assert(!rangeStart.isAfter(rangeEnd), 'rangeStart must be <= rangeEnd');
    final start = _dayStart(rangeStart);
    final end = _dayStart(rangeEnd);

    final activeClasses = {
      for (final c in classes)
        if (classIds == null || classIds.contains(c.id)) c.id: c,
    };
    if (activeClasses.isEmpty) return const [];

    final holidayDates = <DateTime>{};
    for (final h in holidays) {
      var d = _dayStart(h.start);
      final last = _dayStart(h.end);
      while (!d.isAfter(last)) {
        holidayDates.add(d);
        d = shiftDays(d, 1);
      }
    }

    final bySlotDate = <(int, DateTime), ScheduleException>{
      for (final e in exceptions) (e.scheduleItemId, _dayStart(e.date)): e,
    };

    final result = <ClassOccurrence>[];
    final nSlots = slots.length;
    for (
      var cursor = start;
      !cursor.isAfter(end);
      cursor = shiftDays(cursor, 1)
    ) {
      if (holidayDates.contains(cursor)) continue;

      final isoWeekday = cursor.weekday;
      final parity = _parityFor(cursor);

      for (var i = 0; i < nSlots; i++) {
        final slot = slots[i];
        if (slot.dayOfWeek != isoWeekday) continue;
        final klass = activeClasses[slot.classId];
        if (klass == null) continue;

        if (klass.startDate != null &&
            cursor.isBefore(_dayStart(klass.startDate!))) {
          continue;
        }
        if (klass.endDate != null &&
            cursor.isAfter(_dayStart(klass.endDate!))) {
          continue;
        }
        if (slot.validFrom != null &&
            cursor.isBefore(_dayStart(slot.validFrom!))) {
          continue;
        }
        if (slot.validTo != null && cursor.isAfter(_dayStart(slot.validTo!))) {
          continue;
        }

        switch (slot.rotation) {
          case RotationType.weekly:
            break;
          case RotationType.weekAB:
            if (parity != slot.weekParity) continue;
          case RotationType.custom:
            final cycle = slot.cycleLength ?? 1;
            if (cycle < 1) continue;
            final weeks = slot.cycleWeeks ?? const [];
            // cycleWeeks are documented 1-based; the index is 0-based.
            if (!weeks.contains(_cycleWeekIndex(cursor, cycle) + 1)) continue;
          case RotationType.dayRotation:
            final config = dayRotation;
            if (config == null) continue;
            final days = slot.rotationDays ?? const [];
            // rotationDays are documented 1-based; the index is 0-based.
            final index = rotationDayIndex(
              date: cursor,
              config: config,
              holidays: holidayDates,
            );
            if (!days.contains(index + 1)) continue;
        }

        final exception = bySlotDate[(slot.id, cursor)];
        if (exception != null &&
            exception.status == ExceptionStatus.cancelled) {
          continue;
        }

        final startM = exception?.newStartMinutes ?? slot.startMinutes;
        final endM = exception?.newEndMinutes ?? slot.endMinutes;
        final room = exception?.newRoom ?? slot.room;

        result.add(
          ClassOccurrence(
            classId: slot.classId,
            scheduleItemId: slot.id,
            date: cursor,
            startMinutes: startM,
            endMinutes: endM,
            room: room,
            isMoved: exception != null,
          ),
        );
      }
    }

    result.sort((a, b) {
      final byDate = a.date.compareTo(b.date);
      if (byDate != 0) return byDate;
      final byStart = a.startMinutes.compareTo(b.startMinutes);
      if (byStart != 0) return byStart;
      return a.classId.compareTo(b.classId);
    });
    return result;
  }

  /// Days (local midnight) between [from] and [to] inclusive that would have
  /// occurrences, ignoring holidays — used for attendance statistics like
  /// "3 of 15 lessons missed".
  List<DateTime> teachingDays({
    required DateTime from,
    required DateTime to,
    int? classId,
  }) => occurrences(
    rangeStart: from,
    rangeEnd: to,
    classIds: classId == null ? null : {classId},
  ).map((o) => o.date).toSet().toList()..sort();

  /// 0 for week A, 1 for week B, relative to [weekABAnchor].
  int _parityFor(DateTime date) {
    final anchorWeekStart = _weekStartOf(_dayStart(weekABAnchor));
    final dateWeekStart = _weekStartOf(_dayStart(date));
    final diffWeeks = (dateWeekStart.difference(anchorWeekStart).inDays / 7)
        .round();
    return ((diffWeeks % 2) + 2) % 2;
  }

  /// 0-based index of the week of [date] within a rotation of [length] weeks,
  /// anchored so the week of the A/B anchor is index 0.
  int _cycleWeekIndex(DateTime date, int cycleLength) {
    final anchorWeekStart = _weekStartOf(_dayStart(weekABAnchor));
    final dateWeekStart = _weekStartOf(_dayStart(date));
    final diffWeeks = (dateWeekStart.difference(anchorWeekStart).inDays / 7)
        .round();
    return ((diffWeeks % cycleLength) + cycleLength) % cycleLength;
  }

  /// Start (local midnight) of the week containing [date], where weeks start
  /// on [weekStartDay].
  DateTime _weekStartOf(DateTime date) {
    // Dart: Monday = 1 .. Sunday = 7. Shift so weekStartDay becomes 0.
    final shift = (date.weekday - weekStartDay) % 7;
    final normalized = shift < 0 ? shift + 7 : shift;
    return shiftDays(date, -normalized);
  }

  static DateTime _dayStart(DateTime d) => DateTime(d.year, d.month, d.day);
}
