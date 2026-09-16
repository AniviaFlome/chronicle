import 'package:drift/drift.dart';

// Enums are defined first so tables can reference them.
enum RotationKind { weekly, weekAb, custom }

enum WeekParity { a, b }

enum TaskKind { homework, exam, reminder }

enum TaskPriority { low, normal, high }

class Classes extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 120)();
  IntColumn get colorValue => integer()();

  /// ISO-8601 date strings (yyyy-MM-dd), null = unbounded.
  TextColumn get startDate => text().nullable()();
  TextColumn get endDate => text().nullable()();
  TextColumn get teacher => text().nullable()();
  TextColumn get teacherEmail => text().nullable()();
  TextColumn get room => text().nullable()();
  TextColumn get notes => text().nullable()();

  /// Max tolerated unexcused absences; null = no quota tracking.
  IntColumn get maxAbsences => integer().nullable()();
  BoolColumn get active => boolean().withDefault(const Constant(true))();
}

class ScheduleItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get classId => integer().references(Classes, #id, onDelete: KeyAction.cascade)();

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

  /// ISO-8601 date strings, null = unbounded.
  TextColumn get validFrom => text().nullable()();
  TextColumn get validTo => text().nullable()();
}

class ScheduleExceptions extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get scheduleItemId => integer().references(ScheduleItems, #id, onDelete: KeyAction.cascade)();

  /// ISO-8601 date string of the affected occurrence.
  TextColumn get date => text()();
  TextColumn get status => textEnum<ExceptionKind>()();
  IntColumn get newStartMinutes => integer().nullable()();
  IntColumn get newEndMinutes => integer().nullable()();
  TextColumn get newRoom => text().nullable()();
}

enum ExceptionKind { cancelled, moved }

class Holidays extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 120)();
  TextColumn get startDate => text()();
  TextColumn get endDate => text()();
}

class Absences extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get classId => integer().references(Classes, #id, onDelete: KeyAction.cascade)();

  /// ISO-8601 date string.
  TextColumn get date => text()();

  /// Minutes-from-midnight snapshots so history survives schedule edits.
  IntColumn get startMinutes => integer()();
  IntColumn get endMinutes => integer()();
  TextColumn get reason => text().nullable()();
  BoolColumn get isExcused => boolean().withDefault(const Constant(false))();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class Tasks extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get classId => integer().nullable().references(Classes, #id, onDelete: KeyAction.setNull)();
  TextColumn get title => text().withLength(min: 1, max: 240)();
  TextColumn get notes => text().nullable()();
  TextColumn get type => textEnum<TaskKind>().withDefault(const Constant('homework'))();
  TextColumn get dueDate => text().nullable()();

  /// Minutes from midnight; null = all-day due.
  IntColumn get dueMinutes => integer().nullable()();
  IntColumn get priority => intEnum<TaskPriority>().withDefault(const Constant(1))();
  BoolColumn get isDone => boolean().withDefault(const Constant(false))();
  DateTimeColumn get doneAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class Subtasks extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get taskId => integer().references(Tasks, #id, onDelete: KeyAction.cascade)();
  TextColumn get title => text().withLength(min: 1, max: 240)();
  BoolColumn get isDone => boolean().withDefault(const Constant(false))();
  IntColumn get position => integer().withDefault(const Constant(0))();
}

class TaskReminders extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get taskId => integer().references(Tasks, #id, onDelete: KeyAction.cascade)();

  /// Minutes before the due moment.
  IntColumn get offsetMinutes => integer().withDefault(const Constant(60))();
}

/// Key/value store for app settings.
class Settings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}
