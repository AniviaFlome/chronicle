import 'package:drift/drift.dart';

// Enums are defined first so tables can reference them.
enum RotationKind { weekly, weekAb, custom, dayRotation }

enum WeekParity { a, b }

enum TaskKind { homework, essay, project, reading, revision, exam, reminder }

enum TaskPriority { low, normal, high }

enum RepeatKind { daily, weekly, monthly }

class AcademicYears extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 120)();

  /// ISO-8601 date strings (yyyy-MM-dd).
  TextColumn get startDate => text()();
  TextColumn get endDate => text()();

  /// Day-rotation cycle length (2-10). Null = no day rotation.
  IntColumn get rotationLength => integer().nullable()();

  /// JSON list of ISO weekdays the rotation advances on, e.g. "[1,2,3,4,5]".
  TextColumn get rotationSchoolDays => text().nullable()();

  /// 'numbers' or 'letters'. Defaults to numbers.
  TextColumn get rotationLabels => text().nullable()();

  /// Stable cross-device identity for folder sync (Syncthing transport).
  /// '' only transiently for pre-v6 rows until the v6 migration backfills.
  TextColumn get uuid => text().withDefault(const Constant(''))();

  /// Epoch millis of the last local modification; drives sync
  /// last-write-wins. 0 only transiently until the v6 backfill.
  IntColumn get updatedAt => integer().withDefault(const Constant(0))();
}

class Classes extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 120)();
  IntColumn get colorValue => integer()();
  IntColumn get yearId => integer().nullable().references(
    AcademicYears,
    #id,
    onDelete: KeyAction.setNull,
  )();

  /// ISO-8601 date strings (yyyy-MM-dd), null = unbounded.
  TextColumn get startDate => text().nullable()();
  TextColumn get endDate => text().nullable()();
  TextColumn get teacher => text().nullable()();
  TextColumn get teacherEmail => text().nullable()();
  TextColumn get room => text().nullable()();
  TextColumn get building => text().nullable()();
  TextColumn get module => text().nullable()();
  TextColumn get onlineLink => text().nullable()();
  TextColumn get notes => text().nullable()();

  /// Max tolerated unexcused absences; null = no quota tracking.
  IntColumn get maxAbsences => integer().nullable()();

  /// Minutes before class start to remind; null = follow default setting.
  IntColumn get reminderMinutes => integer().nullable()();
  BoolColumn get active => boolean().withDefault(const Constant(true))();

  /// Stable cross-device identity for folder sync (Syncthing transport).
  /// '' only transiently for pre-v6 rows until the v6 migration backfills.
  TextColumn get uuid => text().withDefault(const Constant(''))();

  /// Epoch millis of the last local modification; drives sync
  /// last-write-wins. 0 only transiently until the v6 backfill.
  IntColumn get updatedAt => integer().withDefault(const Constant(0))();
}

class ScheduleItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get classId =>
      integer().references(Classes, #id, onDelete: KeyAction.cascade)();

  /// 1 = Monday .. 7 = Sunday (ISO weekday).
  IntColumn get dayOfWeek => integer()();

  /// Minutes from midnight.
  IntColumn get startMinutes => integer()();
  IntColumn get endMinutes => integer()();

  /// Room override; falls back to Classes.room.
  TextColumn get room => text().nullable()();
  TextColumn get rotation => textEnum<RotationKind>()();
  IntColumn get weekParity => intEnum<WeekParity>().nullable()();
  IntColumn get cycleLength => integer().nullable()();

  /// JSON-encoded list of 1-based cycle week indices, e.g. "[1,3]".
  TextColumn get cycleWeeks => text().nullable()();

  /// JSON-encoded list of 1-based rotation day indices, e.g. "[1,3]".
  TextColumn get rotationDays => text().nullable()();

  /// ISO-8601 date strings, null = unbounded.
  TextColumn get validFrom => text().nullable()();
  TextColumn get validTo => text().nullable()();

  /// Stable cross-device identity for folder sync (Syncthing transport).
  /// '' only transiently for pre-v6 rows until the v6 migration backfills.
  TextColumn get uuid => text().withDefault(const Constant(''))();

  /// Epoch millis of the last local modification; drives sync
  /// last-write-wins. 0 only transiently until the v6 backfill.
  IntColumn get updatedAt => integer().withDefault(const Constant(0))();
}

class ScheduleExceptions extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get scheduleItemId =>
      integer().references(ScheduleItems, #id, onDelete: KeyAction.cascade)();

  /// ISO-8601 date string of the affected occurrence.
  TextColumn get date => text()();
  TextColumn get status => textEnum<ExceptionKind>()();
  IntColumn get newStartMinutes => integer().nullable()();
  IntColumn get newEndMinutes => integer().nullable()();
  TextColumn get newRoom => text().nullable()();

  /// Stable cross-device identity for folder sync (Syncthing transport).
  /// '' only transiently for pre-v6 rows until the v6 migration backfills.
  TextColumn get uuid => text().withDefault(const Constant(''))();

  /// Epoch millis of the last local modification; drives sync
  /// last-write-wins. 0 only transiently until the v6 backfill.
  IntColumn get updatedAt => integer().withDefault(const Constant(0))();
}

enum ExceptionKind { cancelled, moved }

class Holidays extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 120)();
  TextColumn get startDate => text()();
  TextColumn get endDate => text()();

  /// Stable cross-device identity for folder sync (Syncthing transport).
  /// '' only transiently for pre-v6 rows until the v6 migration backfills.
  TextColumn get uuid => text().withDefault(const Constant(''))();

  /// Epoch millis of the last local modification; drives sync
  /// last-write-wins. 0 only transiently until the v6 backfill.
  IntColumn get updatedAt => integer().withDefault(const Constant(0))();
}

class Absences extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get classId =>
      integer().references(Classes, #id, onDelete: KeyAction.cascade)();

  /// ISO-8601 date string.
  TextColumn get date => text()();

  /// Minutes-from-midnight snapshots so history survives schedule edits.
  IntColumn get startMinutes => integer()();
  IntColumn get endMinutes => integer()();
  TextColumn get reason => text().nullable()();
  BoolColumn get isExcused => boolean().withDefault(const Constant(false))();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// Stable cross-device identity for folder sync (Syncthing transport).
  /// '' only transiently for pre-v6 rows until the v6 migration backfills.
  TextColumn get uuid => text().withDefault(const Constant(''))();

  /// Epoch millis of the last local modification; drives sync
  /// last-write-wins. 0 only transiently until the v6 backfill.
  IntColumn get updatedAt => integer().withDefault(const Constant(0))();
}

class Tasks extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get classId => integer().nullable().references(
    Classes,
    #id,
    onDelete: KeyAction.setNull,
  )();
  TextColumn get title => text().withLength(min: 1, max: 240)();
  TextColumn get notes => text().nullable()();
  TextColumn get type =>
      textEnum<TaskKind>().withDefault(const Constant('homework'))();
  TextColumn get dueDate => text().nullable()();

  /// Minutes from midnight; null = all-day due.
  IntColumn get dueMinutes => integer().nullable()();
  IntColumn get priority =>
      intEnum<TaskPriority>().withDefault(const Constant(1))();
  BoolColumn get isDone => boolean().withDefault(const Constant(false))();
  DateTimeColumn get doneAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// Partial completion 0-100. Null = binary done/not-done tracking.
  IntColumn get progressPercent => integer().nullable()();

  /// Auto-repeat rule. Null = no repeat.
  TextColumn get repeatKind => textEnum<RepeatKind>().nullable()();

  /// ISO date: stop generating repeats after this day. Null = forever.
  TextColumn get repeatUntil => text().nullable()();

  /// For revision tasks: the exam task they prepare for.
  IntColumn get linkedExamId => integer().nullable().references(
    Tasks,
    #id,
    onDelete: KeyAction.setNull,
  )();

  /// Stable cross-device identity for folder sync (Syncthing transport).
  /// '' only transiently for pre-v6 rows until the v6 migration backfills.
  TextColumn get uuid => text().withDefault(const Constant(''))();

  /// Epoch millis of the last local modification; drives sync
  /// last-write-wins. 0 only transiently until the v6 backfill.
  IntColumn get updatedAt => integer().withDefault(const Constant(0))();
}

class Subtasks extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get taskId =>
      integer().references(Tasks, #id, onDelete: KeyAction.cascade)();
  TextColumn get title => text().withLength(min: 1, max: 240)();
  BoolColumn get isDone => boolean().withDefault(const Constant(false))();
  IntColumn get position => integer().withDefault(const Constant(0))();

  /// Stable cross-device identity for folder sync (Syncthing transport).
  /// '' only transiently for pre-v6 rows until the v6 migration backfills.
  TextColumn get uuid => text().withDefault(const Constant(''))();

  /// Epoch millis of the last local modification; drives sync
  /// last-write-wins. 0 only transiently until the v6 backfill.
  IntColumn get updatedAt => integer().withDefault(const Constant(0))();
}

class TaskReminders extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get taskId =>
      integer().references(Tasks, #id, onDelete: KeyAction.cascade)();

  /// Minutes before the due moment.
  IntColumn get offsetMinutes => integer().withDefault(const Constant(60))();

  /// Stable cross-device identity for folder sync (Syncthing transport).
  /// '' only transiently for pre-v6 rows until the v6 migration backfills.
  TextColumn get uuid => text().withDefault(const Constant(''))();

  /// Epoch millis of the last local modification; drives sync
  /// last-write-wins. 0 only transiently until the v6 backfill.
  IntColumn get updatedAt => integer().withDefault(const Constant(0))();
}

/// Exam results. One row per graded exam task.
class Grades extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get examTaskId =>
      integer().references(Tasks, #id, onDelete: KeyAction.cascade)();
  RealColumn get score => real()();
  RealColumn get maxScore => real().withDefault(const Constant(100))();

  /// ISO-8601 date the result was recorded.
  TextColumn get date => text()();
  TextColumn get notes => text().nullable()();

  /// Stable cross-device identity for folder sync (Syncthing transport).
  /// '' only transiently for pre-v6 rows until the v6 migration backfills.
  TextColumn get uuid => text().withDefault(const Constant(''))();

  /// Epoch millis of the last local modification; drives sync
  /// last-write-wins. 0 only transiently until the v6 backfill.
  IntColumn get updatedAt => integer().withDefault(const Constant(0))();
}

/// Completed focus sessions for streaks and statistics.
class PomodoroSessions extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get startedAt => dateTime()();
  IntColumn get workMinutes => integer()();
  IntColumn get taskId => integer().nullable().references(
    Tasks,
    #id,
    onDelete: KeyAction.setNull,
  )();

  /// Stable cross-device identity for folder sync (Syncthing transport).
  /// '' only transiently for pre-v6 rows until the v6 migration backfills.
  TextColumn get uuid => text().withDefault(const Constant(''))();

  /// Epoch millis of the last local modification; drives sync
  /// last-write-wins. 0 only transiently until the v6 backfill.
  IntColumn get updatedAt => integer().withDefault(const Constant(0))();
}

/// Non-class events: sports, appointments, clubs.
class XtraEvents extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text().withLength(min: 1, max: 240)();

  /// ISO-8601 date string.
  TextColumn get date => text()();
  IntColumn get startMinutes => integer().nullable()();
  IntColumn get endMinutes => integer().nullable()();
  TextColumn get location => text().nullable()();
  TextColumn get notes => text().nullable()();
  IntColumn get colorValue =>
      integer().withDefault(const Constant(0xFF30A46C))();

  /// Stable cross-device identity for folder sync (Syncthing transport).
  /// '' only transiently for pre-v6 rows until the v6 migration backfills.
  TextColumn get uuid => text().withDefault(const Constant(''))();

  /// Epoch millis of the last local modification; drives sync
  /// last-write-wins. 0 only transiently until the v6 backfill.
  IntColumn get updatedAt => integer().withDefault(const Constant(0))();
}

/// Tombstones for hard-deleted rows, propagated through the sync folder
/// so deletes converge across devices. Tombstones are retained (they are
/// tiny); a device joining with very old state should rejoin via a manual
/// backup import instead of relying on pruned history.
class SyncTombstones extends Table {
  TextColumn get tableKey => text()();
  TextColumn get uuid => text()();
  IntColumn get deletedAt => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {tableKey, uuid};
}

/// Cached dining-hall menus. Display-only derived data: excluded from
/// folder sync and backups, rebuilt from the provider on demand.
class MenuCache extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get providerId => text()();
  TextColumn get locationId => text()();
  TextColumn get date => text()();
  TextColumn get payload => text()();
  IntColumn get fetchedAt => integer().withDefault(const Constant(0))();
}

/// Key/value store for app settings.
class Settings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}
