/// Plain Dart models used by the schedule occurrence engine.
///
/// Dates are always local-midnight DateTimes; times are minutes-from-midnight
/// ints. Weekday uses ISO numbering: 1 = Monday .. 7 = Sunday.
library;

enum RotationType { weekly, weekAB, custom }

enum ExceptionStatus { cancelled, moved }

/// A recurring weekly slot for a class (one row of `schedule_items`).
class ScheduleSlot {
  final int id;
  final int classId;
  final int dayOfWeek;
  final int startMinutes;
  final int endMinutes;
  final String? room;
  final RotationType rotation;

  /// For [RotationType.weekAB]: 0 = week A, 1 = week B.
  final int? weekParity;

  /// For [RotationType.custom]: length of the repeating rotation in weeks.
  final int? cycleLength;

  /// For [RotationType.custom]: 1-based week indices within the cycle where
  /// this slot occurs.
  final List<int>? cycleWeeks;

  final DateTime? validFrom;
  final DateTime? validTo;

  const ScheduleSlot({
    required this.id,
    required this.classId,
    required this.dayOfWeek,
    required this.startMinutes,
    required this.endMinutes,
    this.room,
    this.rotation = RotationType.weekly,
    this.weekParity,
    this.cycleLength,
    this.cycleWeeks,
    this.validFrom,
    this.validTo,
  });
}

/// A class as the engine needs it.
class ScheduledClass {
  final int id;
  final DateTime? startDate;
  final DateTime? endDate;

  const ScheduledClass({required this.id, this.startDate, this.endDate});
}

/// A one-off override applied to (slot, date).
class ScheduleException {
  final int scheduleItemId;
  final DateTime date;
  final ExceptionStatus status;
  final int? newStartMinutes;
  final int? newEndMinutes;
  final String? newRoom;

  const ScheduleException({
    required this.scheduleItemId,
    required this.date,
    required this.status,
    this.newStartMinutes,
    this.newEndMinutes,
    this.newRoom,
  });
}

/// An inclusive date range with no classes (holiday, break, ...).
class HolidayRange {
  final DateTime start;
  final DateTime end;

  const HolidayRange({required this.start, required this.end});
}

/// One concrete class instance produced by the engine.
class ClassOccurrence {
  final int classId;
  final int scheduleItemId;
  final DateTime date;
  final int startMinutes;
  final int endMinutes;
  final String? room;

  /// True when a [ScheduleException] moved this instance from its regular
  /// time.
  final bool isMoved;

  const ClassOccurrence({
    required this.classId,
    required this.scheduleItemId,
    required this.date,
    required this.startMinutes,
    required this.endMinutes,
    this.room,
    this.isMoved = false,
  });

  DateTime get start => date.add(Duration(minutes: startMinutes));
  DateTime get end => date.add(Duration(minutes: endMinutes));

  @override
  bool operator ==(Object other) =>
      other is ClassOccurrence &&
      other.classId == classId &&
      other.scheduleItemId == scheduleItemId &&
      other.date == date &&
      other.startMinutes == startMinutes &&
      other.endMinutes == endMinutes &&
      other.room == room &&
      other.isMoved == isMoved;

  @override
  int get hashCode => Object.hash(
        classId,
        scheduleItemId,
        date,
        startMinutes,
        endMinutes,
        room,
        isMoved,
      );

  @override
  String toString() =>
      'ClassOccurrence(class $classId, $date '
      '${_hhmm(startMinutes)}-${_hhmm(endMinutes)}, room: $room)';
}

String _hhmm(int minutes) =>
    '${(minutes ~/ 60).toString().padLeft(2, '0')}:'
    '${(minutes % 60).toString().padLeft(2, '0')}';
