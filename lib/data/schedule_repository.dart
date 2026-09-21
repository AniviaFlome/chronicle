import 'package:chronicle/data/database.dart';
import 'package:chronicle/data/tables.dart';
import 'package:chronicle/domain/schedule_models.dart' as engine;
import 'package:chronicle/domain/schedule_occurrence_engine.dart';

String isoDate(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

engine.RotationType rotationFromDb(RotationKind kind) => switch (kind) {
  RotationKind.weekly => engine.RotationType.weekly,
  RotationKind.weekAb => engine.RotationType.weekAB,
  RotationKind.custom => engine.RotationType.custom,
  RotationKind.dayRotation => engine.RotationType.dayRotation,
};

/// Decodes a "[1,3]"-style int list column. Shared by cycle weeks,
/// rotation days and rotation school days.
List<int> decodeIntList(String json) {
  final trimmed = json.trim();
  if (trimmed.isEmpty || trimmed == '[]') return const [];
  final inner = trimmed.substring(1, trimmed.length - 1);
  if (inner.isEmpty) return const [];
  return inner.split(',').map((s) => int.parse(s.trim())).toList();
}

List<int> decodeCycleWeeks(String json) => decodeIntList(json);

String encodeCycleWeeks(List<int> weeks) => '[${weeks.join(',')}]';

String encodeIntList(List<int> values) => '[${values.join(',')}]';

/// Builds a day-rotation config from an academic year row, or null when the
/// year has no rotation configured.
engine.DayRotationConfig? dayRotationFromYear(AcademicYear year) {
  final length = year.rotationLength;
  if (length == null || length < 2) return null;
  final schoolDays = year.rotationSchoolDays == null
      ? const {1, 2, 3, 4, 5}
      : decodeIntList(year.rotationSchoolDays!).toSet();
  if (schoolDays.isEmpty) return null;
  final anchor = DateTime.tryParse(year.startDate);
  if (anchor == null) return null;
  return engine.DayRotationConfig(
    length: length,
    schoolDays: schoolDays,
    anchor: anchor,
  );
}

extension ClassRowExt on ClassesData {
  engine.ScheduledClass toEngine() => engine.ScheduledClass(
    id: id,
    startDate: startDate == null ? null : DateTime.parse(startDate!),
    endDate: endDate == null ? null : DateTime.parse(endDate!),
  );
}

extension ScheduleItemRowExt on ScheduleItem {
  engine.ScheduleSlot toEngine() => engine.ScheduleSlot(
    id: id,
    classId: classId,
    dayOfWeek: dayOfWeek,
    startMinutes: startMinutes,
    endMinutes: endMinutes,
    room: room,
    rotation: rotationFromDb(rotation),
    weekParity: weekParity == null
        ? null
        : (weekParity == WeekParity.a ? 0 : 1),
    cycleLength: cycleLength,
    cycleWeeks: cycleWeeks == null ? null : decodeCycleWeeks(cycleWeeks!),
    rotationDays: rotationDays == null ? null : decodeIntList(rotationDays!),
    validFrom: validFrom == null ? null : DateTime.parse(validFrom!),
    validTo: validTo == null ? null : DateTime.parse(validTo!),
  );
}

extension ExceptionRowExt on ScheduleException {
  engine.ScheduleException toEngine() => engine.ScheduleException(
    scheduleItemId: scheduleItemId,
    date: DateTime.parse(date),
    status: status == ExceptionKind.cancelled
        ? engine.ExceptionStatus.cancelled
        : engine.ExceptionStatus.moved,
    newStartMinutes: newStartMinutes,
    newEndMinutes: newEndMinutes,
    newRoom: newRoom,
  );
}

extension HolidayRowExt on Holiday {
  engine.HolidayRange toEngine() => engine.HolidayRange(
    start: DateTime.parse(startDate),
    end: DateTime.parse(endDate),
  );
}

/// Loads all schedule data and builds the occurrence engine.
class ScheduleRepository {
  final AppDatabase db;
  ScheduleRepository(this.db);

  Future<ScheduleOccurrenceEngine> loadEngine({
    required DateTime weekABAnchor,
    int weekStartDay = 1,
    Set<int>? classIds,
    engine.DayRotationConfig? dayRotation,
  }) async {
    final classQuery = db.select(db.classes);
    if (classIds != null) {
      classQuery.where((c) => c.id.isIn(classIds));
    }
    final classes = await classQuery.get();
    final items = await db.select(db.scheduleItems).get();
    final exceptions = await db.select(db.scheduleExceptions).get();
    final holidays = await db.select(db.holidays).get();

    return ScheduleOccurrenceEngine(
      classes: classes.map((c) => c.toEngine()).toList(),
      slots: items.map((s) => s.toEngine()).toList(),
      exceptions: exceptions.map((e) => e.toEngine()).toList(),
      holidays: holidays.map((h) => h.toEngine()).toList(),
      weekABAnchor: weekABAnchor,
      weekStartDay: weekStartDay,
      dayRotation: dayRotation,
    );
  }
}
