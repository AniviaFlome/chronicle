/// Plain Dart models used by the schedule occurrence engine.
///
/// Dates are always local-midnight DateTimes; times are minutes-from-midnight
/// ints. Weekday uses ISO numbering: 1 = Monday .. 7 = Sunday.
library;

import '../utils/time_format.dart';

enum RotationType { weekly, weekAB, custom, dayRotation }

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

  /// For [RotationType.dayRotation]: 1-based rotation day indices where
  /// this slot occurs.
  final List<int>? rotationDays;

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
    this.rotationDays,
    this.validFrom,
    this.validTo,
  });
}

/// Day-rotation configuration (MyStudyLife-style rotating days).
///
/// The rotation advances by one each school day and pauses on holidays and
/// non-school days. The anchor date itself is rotation day 1 when it is a
/// school day.
class DayRotationConfig {
  /// Cycle length in days (2-10).
  final int length;

  /// ISO weekdays the rotation advances on, e.g. {1,2,3,4,5}.
  final Set<int> schoolDays;

  final DateTime anchor;

  const DayRotationConfig({
    required this.length,
    required this.schoolDays,
    required this.anchor,
  });
}

/// 0-based rotation day index for [date].
///
/// Counts school days in [anchor, date), skipping [holidays]; dates before
/// the anchor cycle backwards symmetrically.
int rotationDayIndex({
  required DateTime date,
  required DayRotationConfig config,
  required Set<DateTime> holidays,
}) {
  final a = _dayStart(config.anchor);
  final d = _dayStart(date);
  if (a == d) return 0;
  final forward = d.isAfter(a);
  final from = forward ? a : d;
  final to = forward ? d : a;
  var count = 0;
  for (var cursor = from; cursor.isBefore(to); cursor = _nextDay(cursor)) {
    if (config.schoolDays.contains(cursor.weekday) &&
        !holidays.contains(cursor)) {
      count++;
    }
  }
  if (forward) return count % config.length;
  return (config.length - (count % config.length)) % config.length;
}

/// 1-based label for a 0-based rotation [index]: numbers or letters (A-J).
String rotationDayLabel(int index, {required bool letters}) {
  if (!letters) return '${index + 1}';
  return String.fromCharCode('A'.codeUnitAt(0) + (index % 26));
}

DateTime _dayStart(DateTime d) => DateTime(d.year, d.month, d.day);

DateTime _nextDay(DateTime d) => shiftDays(_dayStart(d), 1);

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
      '${hhmm(startMinutes)}-${hhmm(endMinutes)}, room: $room)';
}
