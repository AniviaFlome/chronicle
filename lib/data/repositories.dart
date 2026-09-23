import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';
import 'dart:io';

import '../services/class_files.dart';

import '../services/menu/menu_provider.dart';
import '../utils/time_format.dart';
import 'database.dart';
import 'tables.dart';

/// Epoch millis for sync last-write-wins stamps.
int syncNow() => DateTime.now().millisecondsSinceEpoch;

/// Fresh stable identity for a synced row.
String newUuid() => const Uuid().v4();

/// Absolutizes a stored attachment path: absolute (legacy) rows pass
/// through, relative rows resolve against the app support directory.
Future<String> resolveAttachmentPath(String stored) =>
    ClassFilesService.resolveStoredPath(root: null, stored: stored);

extension ClassCompanions on ClassesCompanion {
  // intentionally minimal; UI constructs companions inline
}

/// Records a tombstone so a hard delete propagates through sync.
/// Keeps the newest deletedAt per (table, uuid).
Future<void> recordTombstone(
  AppDatabase db,
  String table,
  String uuid, [
  int? at,
]) async {
  if (uuid.isEmpty) return;
  final deletedAt = at ?? syncNow();
  final existing =
      await (db.select(db.syncTombstones)..where(
            (t) => t.tableKey.equals(table) & t.uuid.equals(uuid),
          ))
          .getSingleOrNull();
  if (existing != null && existing.deletedAt >= deletedAt) return;
  await db
      .into(db.syncTombstones)
      .insertOnConflictUpdate(
        SyncTombstonesCompanion.insert(
          tableKey: table,
          uuid: uuid,
          deletedAt: Value(deletedAt),
        ),
      );
}

/// Sync table names as stored in [SyncTombstones].
abstract final class SyncTables {
  static const years = 'academic_years';
  static const classes = 'classes';
  static const scheduleItems = 'schedule_items';
  static const exceptions = 'schedule_exceptions';
  static const holidays = 'holidays';
  static const absences = 'absences';
  static const tasks = 'tasks';
  static const subtasks = 'subtasks';
  static const reminders = 'task_reminders';
  static const grades = 'grades';
  static const sessions = 'pomodoro_sessions';
  static const xtra = 'xtra_events';
  static const classFiles = 'class_files';
  static const yearFiles = 'year_files';
}

class ClassRepository {
  final AppDatabase db;
  ClassRepository(this.db);

  Stream<List<ClassesData>> watchAll({bool includeInactive = false}) {
    final query = db.select(db.classes);
    if (!includeInactive) query.where((c) => c.active.equals(true));
    query.orderBy([(c) => OrderingTerm.asc(c.name)]);
    return query.watch();
  }

  Future<List<ClassesData>> all() => db.select(db.classes).get();

  Future<ClassesData> byId(int id) =>
      (db.select(db.classes)..where((c) => c.id.equals(id))).getSingle();

  Future<ClassesData?> byIdOrNull(int id) =>
      (db.select(db.classes)..where((c) => c.id.equals(id))).getSingleOrNull();

  Future<int> create(ClassesCompanion entry) => db
      .into(db.classes)
      .insert(
        entry.copyWith(uuid: Value(newUuid()), updatedAt: Value(syncNow())),
      );

  // --- Academic years ---

  Stream<List<AcademicYear>> watchYears() => (db.select(
    db.academicYears,
  )..orderBy([(y) => OrderingTerm.asc(y.startDate)])).watch();

  Future<List<AcademicYear>> years() => db.select(db.academicYears).get();

  Future<int> createYear(AcademicYearsCompanion entry) => db
      .into(db.academicYears)
      .insert(
        entry.copyWith(uuid: Value(newUuid()), updatedAt: Value(syncNow())),
      );

  Future<bool> updateYear(AcademicYear row) => db
      .update(db.academicYears)
      .replace(row.copyWith(updatedAt: syncNow()));

  /// Deletes a year and records a tombstone so the delete syncs.
  /// Member classes are FK-set-null (no tombstones); both sides derive the
  /// same outcome from the same tombstone set. Attached year files are
  /// tombstoned too, and removed from disk best-effort.
  Future<int> deleteYear(int id) async {
    final row =
        await (db.select(
          db.academicYears,
        )..where((y) => y.id.equals(id))).getSingleOrNull();
    if (row != null) {
      await recordTombstone(db, SyncTables.years, row.uuid);
      try {
        final files = await YearFileRepository(db).forYear(id);
        for (final f in files) {
          await recordTombstone(db, SyncTables.yearFiles, f.uuid);
        }
        for (final f in files) {
          try {
            final file = File(await resolveAttachmentPath(f.storedPath));
            if (await file.exists()) await file.delete();
          } catch (_) {
            // Best-effort: a missing file must not block year deletion.
          }
        }
      } catch (_) {
        // Best-effort cleanup only.
      }
    }
    return (db.delete(db.academicYears)..where((y) => y.id.equals(id))).go();
  }

  /// Creates a class together with its meeting-time slots atomically, so a
  /// partially saved class can never be left behind.
  Future<int> createClassWithSlots(
    ClassesCompanion entry,
    List<ScheduleItemsCompanion> slots,
  ) {
    final now = syncNow();
    return db.transaction(() async {
      final id = await db
          .into(db.classes)
          .insert(
            entry.copyWith(uuid: Value(newUuid()), updatedAt: Value(now)),
          );
      for (final slot in slots) {
        await db
            .into(db.scheduleItems)
            .insert(
              slot.copyWith(
                classId: Value(id),
                uuid: Value(newUuid()),
                updatedAt: Value(now),
              ),
            );
      }
      return id;
    });
  }

  Future<bool> update(ClassesData row) => db
      .update(db.classes)
      .replace(row.copyWith(updatedAt: syncNow()));

  /// Deletes a class, tombstoning it plus cascade children (slots,
  /// exceptions, absences, attached files) so deletes converge on peer
  /// devices. File blobs are removed from disk best-effort.
  Future<int> delete(int id) async {
    final now = syncNow();
    final row =
        await (db.select(
          db.classes,
        )..where((c) => c.id.equals(id))).getSingleOrNull();
    if (row != null) {
      await recordTombstone(db, SyncTables.classes, row.uuid, now);
      final items = await scheduleItemsFor(id);
      for (final item in items) {
        await recordTombstone(db, SyncTables.scheduleItems, item.uuid, now);
        final exceptions = await exceptionsFor(item.id);
        for (final e in exceptions) {
          await recordTombstone(db, SyncTables.exceptions, e.uuid, now);
        }
      }
      final classAbsences = await AbsenceRepository(db).forClass(id);
      for (final a in classAbsences) {
        await recordTombstone(db, SyncTables.absences, a.uuid, now);
      }
      final classFiles = await ClassFileRepository(db).forClass(id);
      for (final f in classFiles) {
        await recordTombstone(db, SyncTables.classFiles, f.uuid, now);
      }
      // Remove file blobs from disk; rows go via FK cascade (or
      // explicit delete when cascade is off, e.g. tests).
      try {
        final files = await ClassFileRepository(db).forClass(id);
        for (final f in files) {
          try {
            final file = File(await resolveAttachmentPath(f.storedPath));
            if (await file.exists()) await file.delete();
          } catch (_) {
            // Best-effort: a missing file must not block class deletion.
          }
        }
      } catch (_) {
        // Best-effort cleanup only.
      }
    }
    return (db.delete(db.classes)..where((c) => c.id.equals(id))).go();
  }

  // --- Schedule items ---

  Stream<List<ScheduleItem>> watchScheduleItems(int classId) => (db.select(
    db.scheduleItems,
  )..where((s) => s.classId.equals(classId))).watch();

  Future<List<ScheduleItem>> scheduleItemsFor(int classId) => (db.select(
    db.scheduleItems,
  )..where((s) => s.classId.equals(classId))).get();

  Future<int> createScheduleItem(ScheduleItemsCompanion entry) => db
      .into(db.scheduleItems)
      .insert(
        entry.copyWith(uuid: Value(newUuid()), updatedAt: Value(syncNow())),
      );

  Future<bool> updateScheduleItem(ScheduleItem row) => db
      .update(db.scheduleItems)
      .replace(row.copyWith(updatedAt: syncNow()));

  /// Deletes a slot, tombstoning it plus its exceptions.
  Future<int> deleteScheduleItem(int id) async {
    final now = syncNow();
    final row =
        await (db.select(
          db.scheduleItems,
        )..where((s) => s.id.equals(id))).getSingleOrNull();
    if (row != null) {
      await recordTombstone(db, SyncTables.scheduleItems, row.uuid, now);
      final exceptions = await exceptionsFor(id);
      for (final e in exceptions) {
        await recordTombstone(db, SyncTables.exceptions, e.uuid, now);
      }
    }
    return (db.delete(db.scheduleItems)..where((s) => s.id.equals(id))).go();
  }

  /// Moves/resizes a slot's times, used by calendar drag editing.
  Future<bool> updateSlotTimes(int id, int startMinutes, int endMinutes) async {
    final row = await (db.select(
      db.scheduleItems,
    )..where((s) => s.id.equals(id))).getSingleOrNull();
    if (row == null) return false;
    return db
        .update(db.scheduleItems)
        .replace(
          row.copyWith(
            startMinutes: startMinutes,
            endMinutes: endMinutes,
            updatedAt: syncNow(),
          ),
        );
  }

  // --- Exceptions ---

  Future<List<ScheduleException>> exceptionsFor(int scheduleItemId) =>
      (db.select(
        db.scheduleExceptions,
      )..where((e) => e.scheduleItemId.equals(scheduleItemId))).get();

  Future<int> createException(ScheduleExceptionsCompanion entry) => db
      .into(db.scheduleExceptions)
      .insert(
        entry.copyWith(uuid: Value(newUuid()), updatedAt: Value(syncNow())),
      );

  Future<int> deleteException(int id) async {
    final row =
        await (db.select(
          db.scheduleExceptions,
        )..where((e) => e.id.equals(id))).getSingleOrNull();
    if (row != null) {
      await recordTombstone(db, SyncTables.exceptions, row.uuid);
    }
    return (db.delete(db.scheduleExceptions)..where((e) => e.id.equals(id)))
        .go();
  }

  // --- Holidays ---

  Stream<List<Holiday>> watchHolidays() => (db.select(
    db.holidays,
  )..orderBy([(h) => OrderingTerm.asc(h.startDate)])).watch();

  Future<int> createHoliday(HolidaysCompanion entry) => db
      .into(db.holidays)
      .insert(
        entry.copyWith(uuid: Value(newUuid()), updatedAt: Value(syncNow())),
      );

  Future<bool> updateHoliday(Holiday row) =>
      db.update(db.holidays).replace(row.copyWith(updatedAt: syncNow()));

  Future<int> deleteHoliday(int id) async {
    final row =
        await (db.select(
          db.holidays,
        )..where((h) => h.id.equals(id))).getSingleOrNull();
    if (row != null) await recordTombstone(db, SyncTables.holidays, row.uuid);
    return (db.delete(db.holidays)..where((h) => h.id.equals(id))).go();
  }
}

class AbsenceRepository {
  final AppDatabase db;
  AbsenceRepository(this.db);

  Stream<List<Absence>> watchForClass(int classId) =>
      (db.select(db.absences)
            ..where((a) => a.classId.equals(classId))
            ..orderBy([
              (a) => OrderingTerm.desc(a.date),
              (a) => OrderingTerm.desc(a.startMinutes),
            ]))
          .watch();

  Stream<List<Absence>> watchAll() =>
      (db.select(db.absences)..orderBy([
            (a) => OrderingTerm.desc(a.date),
            (a) => OrderingTerm.desc(a.startMinutes),
          ]))
          .watch();

  /// One absence for a class on a date (the app allows a single mark per
  /// class-instance; multiple slots per class per day map to one mark).
  Future<Absence?> forClassOnDate(int classId, String isoDate) =>
      (db.select(db.absences)
            ..where((a) => a.classId.equals(classId) & a.date.equals(isoDate))
            ..limit(1))
          .getSingleOrNull();

  Stream<Absence?> watchForClassOnDate(int classId, String isoDate) =>
      (db.select(db.absences)
            ..where((a) => a.classId.equals(classId) & a.date.equals(isoDate))
            ..limit(1))
          .watchSingleOrNull();

  /// One-shot list for tombstoning cascade deletes.
  Future<List<Absence>> forClass(int classId) =>
      (db.select(
        db.absences,
      )..where((a) => a.classId.equals(classId))).get();

  Future<int> mark(AbsencesCompanion entry) => db
      .into(db.absences)
      .insert(
        entry.copyWith(uuid: Value(newUuid()), updatedAt: Value(syncNow())),
      );

  Future<int> countForClass(int classId, {bool? excused}) {
    final count = db.absences.id.count();
    final query = db.selectOnly(db.absences)
      ..addColumns([count])
      ..where(
        db.absences.classId.equals(classId) &
            (excused == null
                ? const Constant(true)
                : db.absences.isExcused.equals(excused)),
      );
    return query.map((row) => row.read(count) ?? 0).getSingle();
  }

  Future<void> unmark(int id) async {
    final row =
        await (db.select(
          db.absences,
        )..where((a) => a.id.equals(id))).getSingleOrNull();
    if (row != null) await recordTombstone(db, SyncTables.absences, row.uuid);
    await (db.delete(db.absences)..where((a) => a.id.equals(id))).go();
  }
}

class TaskRepository {
  final AppDatabase db;
  TaskRepository(this.db);

  Stream<List<TaskWithDetails>> watchAll({
    TaskKind? type,
    bool onlyOpen = false,
    int? classId,
  }) {
    final query = db.select(db.tasks).join([
      leftOuterJoin(db.classes, db.classes.id.equalsExp(db.tasks.classId)),
    ]);
    if (type != null) query.where(db.tasks.type.equalsValue(type));
    if (onlyOpen) query.where(db.tasks.isDone.equals(false));
    if (classId != null) query.where(db.tasks.classId.equals(classId));
    query.orderBy([
      OrderingTerm.desc(db.tasks.isDone),
      OrderingTerm.asc(db.tasks.dueDate),
      OrderingTerm.asc(db.tasks.dueMinutes),
    ]);

    return query.watch().asyncMap((rows) async {
      final tasks = rows.map((r) => r.readTable(db.tasks)).toList();
      final classes = {
        for (final r in rows)
          if (r.readTableOrNull(db.classes) != null)
            r.readTable(db.tasks).id: r.readTable(db.classes),
      };
      final subtasksByTask = <int, List<Subtask>>{};
      if (tasks.isNotEmpty) {
        final subs =
            await (db.select(db.subtasks)
                  ..where((s) => s.taskId.isIn(tasks.map((t) => t.id).toList()))
                  ..orderBy([(s) => OrderingTerm.asc(s.position)]))
                .get();
        for (final s in subs) {
          subtasksByTask.putIfAbsent(s.taskId, () => []).add(s);
        }
      }
      return [
        for (final t in tasks)
          TaskWithDetails(
            task: t,
            classRow: classes[t.id],
            subtasks: subtasksByTask[t.id] ?? const [],
          ),
      ];
    });
  }

  Future<int> create(TasksCompanion entry) => db
      .into(db.tasks)
      .insert(
        entry.copyWith(uuid: Value(newUuid()), updatedAt: Value(syncNow())),
      );

  Future<Task?> byId(int id) =>
      (db.select(db.tasks)..where((t) => t.id.equals(id))).getSingleOrNull();

  /// Creates a task together with its subtasks and reminders atomically.
  Future<int> createTaskFull(
    TasksCompanion entry,
    List<String> subtaskTitles,
    List<int> reminderOffsets,
  ) {
    final now = syncNow();
    return db.transaction(() async {
      final id = await db
          .into(db.tasks)
          .insert(
            entry.copyWith(
              uuid: Value(newUuid()),
              updatedAt: Value(now),
            ),
          );
      for (var i = 0; i < subtaskTitles.length; i++) {
        await db
            .into(db.subtasks)
            .insert(
              SubtasksCompanion.insert(
                taskId: id,
                title: subtaskTitles[i],
                position: Value(i),
                uuid: Value(newUuid()),
                updatedAt: Value(now),
              ),
            );
      }
      for (final offset in reminderOffsets) {
        await db
            .into(db.taskReminders)
            .insert(
              TaskRemindersCompanion.insert(
                taskId: id,
                offsetMinutes: Value(offset),
                uuid: Value(newUuid()),
                updatedAt: Value(now),
              ),
            );
      }
      return id;
    });
  }

  Future<bool> update(Task row) =>
      db.update(db.tasks).replace(row.copyWith(updatedAt: syncNow()));

  /// Marks a task done or reopens it. When completing a repeating task,
  /// the next instance is created automatically; its id is returned.
  Future<int?> setDone(int id, bool done) {
    if (!done) {
      return (db.update(db.tasks)..where((t) => t.id.equals(id)))
          .write(
            TasksCompanion(
              isDone: const Value(false),
              doneAt: const Value(null),
              updatedAt: Value(syncNow()),
            ),
          )
          .then((_) => null);
    }
    return db.transaction(() async {
      final task = await (db.select(
        db.tasks,
      )..where((t) => t.id.equals(id))).getSingleOrNull();
      if (task == null || task.isDone) return null;
      await (db.update(db.tasks)..where((t) => t.id.equals(id))).write(
        TasksCompanion(
          isDone: const Value(true),
          doneAt: Value(DateTime.now()),
          updatedAt: Value(syncNow()),
        ),
      );
      return _spawnRepeat(task);
    });
  }

  /// Next due date for a repeat rule, or null when repetition ends.
  static DateTime? nextRepeatDate(Task task) {
    final kind = task.repeatKind;
    if (kind == null || task.dueDate == null) return null;
    final due = DateTime.tryParse(task.dueDate!);
    if (due == null) return null;
    final next = switch (kind) {
      // Wall-clock steps: Duration addition shifts the time of day across
      // DST transitions (monthly already used the constructor).
      RepeatKind.daily => shiftDays(due, 1),
      RepeatKind.weekly => shiftDays(due, 7),
      RepeatKind.monthly => DateTime(due.year, due.month + 1, due.day),
    };
    if (task.repeatUntil != null &&
        isoFromDateTime(next).compareTo(task.repeatUntil!) > 0) {
      return null;
    }
    return next;
  }

  /// Creates the next instance of a repeating task inside the current
  /// transaction. Returns the new id, or null when repetition ends.
  Future<int?> _spawnRepeat(Task task) async {
    final next = nextRepeatDate(task);
    if (next == null) return null;
    final now = syncNow();
    final subs =
        await (db.select(db.subtasks)
              ..where((s) => s.taskId.equals(task.id))
              ..orderBy([(s) => OrderingTerm.asc(s.position)]))
            .get();
    final reminders = await remindersFor(task.id);
    final newId = await db
        .into(db.tasks)
        .insert(
          task
              .toCompanion(false)
              .copyWith(
                id: const Value.absent(),
                isDone: const Value(false),
                doneAt: const Value(null),
                progressPercent: const Value(null),
                dueDate: Value(isoFromDateTime(next)),
                createdAt: Value(DateTime.now()),
                uuid: Value(newUuid()),
                updatedAt: Value(now),
              ),
        );
    for (final s in subs) {
      await db
          .into(db.subtasks)
          .insert(
            SubtasksCompanion.insert(
              taskId: newId,
              title: s.title,
              position: Value(s.position),
              uuid: Value(newUuid()),
              updatedAt: Value(now),
            ),
          );
    }
    for (final r in reminders) {
      await db
          .into(db.taskReminders)
          .insert(
            TaskRemindersCompanion.insert(
              taskId: newId,
              offsetMinutes: Value(r.offsetMinutes),
              uuid: Value(newUuid()),
              updatedAt: Value(now),
            ),
          );
    }
    return newId;
  }

  /// Deletes a task, tombstoning it plus children (subtasks, reminders,
  /// grades) so deletes converge on peer devices.
  Future<int> delete(int id) async {
    final now = syncNow();
    final row =
        await (db.select(
          db.tasks,
        )..where((t) => t.id.equals(id))).getSingleOrNull();
    if (row != null) {
      await recordTombstone(db, SyncTables.tasks, row.uuid, now);
      final subs =
          await (db.select(
            db.subtasks,
          )..where((s) => s.taskId.equals(id))).get();
      for (final s in subs) {
        await recordTombstone(db, SyncTables.subtasks, s.uuid, now);
      }
      final rems = await remindersFor(id);
      for (final r in rems) {
        await recordTombstone(db, SyncTables.reminders, r.uuid, now);
      }
      final grades =
          await (db.select(
            db.grades,
          )..where((g) => g.examTaskId.equals(id))).get();
      for (final g in grades) {
        await recordTombstone(db, SyncTables.grades, g.uuid, now);
      }
    }
    return (db.delete(db.tasks)..where((t) => t.id.equals(id))).go();
  }

  // --- Subtasks ---

  Future<int> createSubtask(SubtasksCompanion entry) => db
      .into(db.subtasks)
      .insert(
        entry.copyWith(uuid: Value(newUuid()), updatedAt: Value(syncNow())),
      );

  Future<bool> updateSubtask(Subtask row) =>
      db.update(db.subtasks).replace(row.copyWith(updatedAt: syncNow()));

  Future<int> deleteSubtask(int id) async {
    final row =
        await (db.select(
          db.subtasks,
        )..where((s) => s.id.equals(id))).getSingleOrNull();
    if (row != null) await recordTombstone(db, SyncTables.subtasks, row.uuid);
    return (db.delete(db.subtasks)..where((s) => s.id.equals(id))).go();
  }

  Stream<List<Subtask>> watchSubtasks(int taskId) =>
      (db.select(db.subtasks)
            ..where((s) => s.taskId.equals(taskId))
            ..orderBy([(s) => OrderingTerm.asc(s.position)]))
          .watch();

  // --- Reminders ---

  Stream<List<TaskReminder>> watchReminders(int taskId) =>
      (db.select(db.taskReminders)
            ..where((r) => r.taskId.equals(taskId))
            ..orderBy([(r) => OrderingTerm.asc(r.offsetMinutes)]))
          .watch();

  Future<List<TaskReminder>> remindersFor(int taskId) => (db.select(
    db.taskReminders,
  )..where((r) => r.taskId.equals(taskId))).get();

  Future<int> createReminder(TaskRemindersCompanion entry) => db
      .into(db.taskReminders)
      .insert(
        entry.copyWith(uuid: Value(newUuid()), updatedAt: Value(syncNow())),
      );

  Future<int> deleteReminder(int id) async {
    final row =
        await (db.select(
          db.taskReminders,
        )..where((r) => r.id.equals(id))).getSingleOrNull();
    if (row != null) await recordTombstone(db, SyncTables.reminders, row.uuid);
    return (db.delete(db.taskReminders)..where((r) => r.id.equals(id))).go();
  }
}

class GradeWithExam {
  final Grade grade;
  final Task exam;
  final ClassesData? classRow;

  GradeWithExam({required this.grade, required this.exam, this.classRow});
}

class GradeRepository {
  final AppDatabase db;
  GradeRepository(this.db);

  Stream<List<GradeWithExam>> watchAll() {
    final query = db.select(db.grades).join([
      innerJoin(db.tasks, db.tasks.id.equalsExp(db.grades.examTaskId)),
      leftOuterJoin(db.classes, db.classes.id.equalsExp(db.tasks.classId)),
    ]);
    query.orderBy([OrderingTerm.desc(db.grades.date)]);
    return query.watch().map(
      (rows) => [
        for (final r in rows)
          GradeWithExam(
            grade: r.readTable(db.grades),
            exam: r.readTable(db.tasks),
            classRow: r.readTableOrNull(db.classes),
          ),
      ],
    );
  }

  Stream<Grade?> watchForExam(int examTaskId) => (db.select(
    db.grades,
  )..where((g) => g.examTaskId.equals(examTaskId))).watchSingleOrNull();

  Future<int> record(GradesCompanion entry) => db
      .into(db.grades)
      .insert(
        entry.copyWith(uuid: Value(newUuid()), updatedAt: Value(syncNow())),
      );

  Future<bool> update(Grade row) =>
      db.update(db.grades).replace(row.copyWith(updatedAt: syncNow()));

  Future<int> delete(int id) async {
    final row =
        await (db.select(
          db.grades,
        )..where((g) => g.id.equals(id))).getSingleOrNull();
    if (row != null) await recordTombstone(db, SyncTables.grades, row.uuid);
    return (db.delete(db.grades)..where((g) => g.id.equals(id))).go();
  }
}

class PomodoroRepository {
  final AppDatabase db;
  PomodoroRepository(this.db);

  Future<int> recordSession(PomodoroSessionsCompanion entry) => db
      .into(db.pomodoroSessions)
      .insert(
        entry.copyWith(uuid: Value(newUuid()), updatedAt: Value(syncNow())),
      );

  Future<List<PomodoroSession>> since(DateTime from) =>
      (db.select(db.pomodoroSessions)
            ..where((s) => s.startedAt.isBiggerOrEqualValue(from))
            ..orderBy([(s) => OrderingTerm.desc(s.startedAt)]))
          .get();

  Stream<List<PomodoroSession>> watchAll() => (db.select(
    db.pomodoroSessions,
  )..orderBy([(s) => OrderingTerm.desc(s.startedAt)])).watch();
}

class XtraRepository {
  final AppDatabase db;
  XtraRepository(this.db);

  Stream<List<XtraEvent>> watchRange(String fromIso, String toIso) =>
      (db.select(db.xtraEvents)
            ..where(
              (e) =>
                  e.date.isBiggerOrEqualValue(fromIso) &
                  e.date.isSmallerOrEqualValue(toIso),
            )
            ..orderBy([
              (e) => OrderingTerm.asc(e.date),
              (e) => OrderingTerm.asc(e.startMinutes),
            ]))
          .watch();

  Future<List<XtraEvent>> range(String fromIso, String toIso) =>
      (db.select(db.xtraEvents)..where(
            (e) =>
                e.date.isBiggerOrEqualValue(fromIso) &
                e.date.isSmallerOrEqualValue(toIso),
          ))
          .get();

  Future<int> create(XtraEventsCompanion entry) => db
      .into(db.xtraEvents)
      .insert(
        entry.copyWith(uuid: Value(newUuid()), updatedAt: Value(syncNow())),
      );

  Future<bool> update(XtraEvent row) =>
      db.update(db.xtraEvents).replace(row.copyWith(updatedAt: syncNow()));

  /// Moves/resizes an event's times, used by calendar drag editing.
  Future<bool> updateXtraTimes(int id, int startMinutes, int endMinutes) async {
    final row = await (db.select(
      db.xtraEvents,
    )..where((e) => e.id.equals(id))).getSingleOrNull();
    if (row == null) return false;
    return db
        .update(db.xtraEvents)
        .replace(
          row.copyWith(
            startMinutes: Value(startMinutes),
            endMinutes: Value(endMinutes),
            updatedAt: syncNow(),
          ),
        );
  }

  Future<int> delete(int id) async {
    final row =
        await (db.select(
          db.xtraEvents,
        )..where((e) => e.id.equals(id))).getSingleOrNull();
    if (row != null) await recordTombstone(db, SyncTables.xtra, row.uuid);
    return (db.delete(db.xtraEvents)..where((e) => e.id.equals(id))).go();
  }
}

class TaskWithDetails {
  final Task task;
  final ClassesData? classRow;
  final List<Subtask> subtasks;

  TaskWithDetails({
    required this.task,
    this.classRow,
    this.subtasks = const [],
  });

  bool get allSubtasksDone =>
      subtasks.isEmpty || subtasks.every((s) => s.isDone);
}

class SettingsRepository {
  final AppDatabase db;
  SettingsRepository(this.db);

  Future<String?> get(String key) async {
    final row = await (db.select(
      db.settings,
    )..where((s) => s.key.equals(key))).getSingleOrNull();
    return row?.value;
  }

  Future<void> set(String key, String value) => db
      .into(db.settings)
      .insertOnConflictUpdate(SettingsCompanion.insert(key: key, value: value));

  Future<void> remove(String key) =>
      (db.delete(db.settings)..where((s) => s.key.equals(key))).go();

  Future<DateTime> weekABAnchor() async {
    final v = await get('week_ab_anchor');
    return v == null ? DateTime(2026, 9, 7) : DateTime.parse(v);
  }

  Future<int> weekStartDay() async =>
      int.tryParse(await get('week_start_day') ?? '') ?? 1;

  Future<bool> use24h() async => (await get('time_24h')) != 'false';

  static const appThemeKey = 'app_theme';
  static const accentColorKey = 'accent_color';

  /// Theme family id. Unknown values fall back to default.
  Future<String> appTheme() async {
    final raw = await get(appThemeKey);
    const known = {
      'default',
      'catppuccin',
      'nord',
      'dracula',
      'gruvbox',
      'tokyo-night',
    };
    return raw != null && known.contains(raw) ? raw : 'default';
  }

  Future<void> setAppTheme(String value) => set(appThemeKey, value);

  /// Accent color as 0xAARRGGBB int. Falls back to Catppuccin Mauve.
  Future<int> accentColor() async {
    final raw = await get(accentColorKey);
    final value = raw == null ? null : int.tryParse(raw);
    return value ?? 0xFFCBA6F7;
  }

  Future<void> setAccentColor(int value) =>
      set(accentColorKey, value.toString());

  static const calendarViewKey = 'calendar_view';

  /// 'list' or 'grid'. Defaults to 'list'.
  Future<String> calendarView() async =>
      (await get(calendarViewKey)) == 'grid' ? 'grid' : 'list';

  Future<void> setCalendarView(String value) => set(calendarViewKey, value);

  static const defaultMaxAbsencesKey = 'default_max_absences';

  /// Default absence limit applied to newly created classes. Null means
  /// none — the out-of-the-box default.
  Future<int?> defaultMaxAbsences() async {
    final raw = await get(defaultMaxAbsencesKey);
    if (raw == null || raw.trim().isEmpty) return null;
    final value = int.tryParse(raw.trim());
    return (value == null || value < 0) ? null : value;
  }

  Future<void> setDefaultMaxAbsences(int? value) async {
    if (value == null) {
      await (db.delete(
        db.settings,
      )..where((s) => s.key.equals(defaultMaxAbsencesKey))).go();
    } else {
      await set(defaultMaxAbsencesKey, value.toString());
    }
  }

  static const defaultStartMinutesKey = 'default_start_minutes';
  static const defaultDurationMinutesKey = 'default_duration_minutes';
  static const defaultClassReminderKey = 'default_class_reminder_minutes';

  /// Default meeting start for new classes/slots, minutes from midnight.
  Future<int> defaultStartMinutes() async =>
      int.tryParse(await get(defaultStartMinutesKey) ?? '') ?? 540;

  Future<void> setDefaultStartMinutes(int value) =>
      set(defaultStartMinutesKey, value.toString());

  /// Default meeting length in minutes.
  Future<int> defaultDurationMinutes() async {
    final value = int.tryParse(await get(defaultDurationMinutesKey) ?? '');
    return (value == null || value <= 0) ? 60 : value;
  }

  Future<void> setDefaultDurationMinutes(int value) =>
      set(defaultDurationMinutesKey, value.toString());

  /// Default minutes before class start to remind. Null means off.
  Future<int?> defaultClassReminderMinutes() async {
    final raw = await get(defaultClassReminderKey);
    if (raw == null || raw.trim().isEmpty) return null;
    final value = int.tryParse(raw.trim());
    return (value == null || value < 0) ? null : value;
  }

  Future<void> setDefaultClassReminderMinutes(int? value) async {
    if (value == null) {
      await (db.delete(
        db.settings,
      )..where((s) => s.key.equals(defaultClassReminderKey))).go();
    } else {
      await set(defaultClassReminderKey, value.toString());
    }
  }

  /// 'list' or 'grid'. Defaults to 'list'.
  Future<String> absencesView() async =>
      (await get('absences_view')) == 'grid' ? 'grid' : 'list';

  Future<void> setAbsencesView(String value) => set('absences_view', value);

  static const gridMarkersModeKey = 'grid_markers_mode';

  /// 'class-times' or 'fixed'. Defaults to 'class-times'.
  Future<String> gridMarkersMode() async {
    const known = {'class-times', 'fixed'};
    final raw = await get(gridMarkersModeKey);
    return raw != null && known.contains(raw) ? raw : 'class-times';
  }

  Future<void> setGridMarkersMode(String value) =>
      set(gridMarkersModeKey, value);

  static const gridFixedLessonKey = 'grid_fixed_lesson';
  static const gridFixedBreakKey = 'grid_fixed_break';

  /// Fixed-grid lesson length in minutes. Defaults to 60.
  Future<int> gridFixedLesson() async {
    final value = int.tryParse(await get(gridFixedLessonKey) ?? '');
    return (value == null || value <= 0) ? 60 : value;
  }

  Future<void> setGridFixedLesson(int value) =>
      set(gridFixedLessonKey, value.toString());

  /// Fixed-grid break length in minutes. Defaults to 10.
  Future<int> gridFixedBreak() async {
    final value = int.tryParse(await get(gridFixedBreakKey) ?? '');
    return (value == null || value < 0) ? 10 : value;
  }

  Future<void> setGridFixedBreak(int value) =>
      set(gridFixedBreakKey, value.toString());

  static const autoEndTimeKey = 'auto_end_time';

  /// When true, picking a start time auto-sets end = start + default
  /// duration. Defaults to false.
  Future<bool> autoEndTime() async =>
      (await get(autoEndTimeKey)) == 'true';

  Future<void> setAutoEndTime(bool value) =>
      set(autoEndTimeKey, value ? 'true' : 'false');

  static const localeOverrideKey = 'locale_override';

  /// 'system', 'en' or 'tr'. Defaults to 'system'.
  Future<String> localeOverride() async {
    const known = {'system', 'en', 'tr'};
    final raw = await get(localeOverrideKey);
    return raw != null && known.contains(raw) ? raw : 'system';
  }

  Future<void> setLocaleOverride(String value) =>
      set(localeOverrideKey, value);

  static const portraitLockKey = 'portrait_lock';

  /// When true, the app is locked to portrait orientation (phones).
  /// Defaults to false.
  Future<bool> portraitLock() async =>
      (await get(portraitLockKey)) == 'true';

  Future<void> setPortraitLock(bool value) =>
      set(portraitLockKey, value ? 'true' : 'false');

  static const focusWorkMinutesKey = 'focus_work_minutes';
  static const focusBreakMinutesKey = 'focus_break_minutes';

  /// Focus timer work length in minutes. Defaults to 25.
  Future<int> focusWorkMinutes() async {
    final value = int.tryParse(await get(focusWorkMinutesKey) ?? '');
    return (value == null || value <= 0) ? 25 : value.clamp(1, 480);
  }

  Future<void> setFocusWorkMinutes(int value) =>
      set(focusWorkMinutesKey, value.clamp(1, 480).toString());

  /// Focus timer break length in minutes. Defaults to 5.
  Future<int> focusBreakMinutes() async {
    final value = int.tryParse(await get(focusBreakMinutesKey) ?? '');
    return (value == null || value <= 0) ? 5 : value.clamp(1, 120);
  }

  Future<void> setFocusBreakMinutes(int value) =>
      set(focusBreakMinutesKey, value.clamp(1, 120).toString());

  static const dayStartHourKey = 'day_start_hour';
  static const dayEndHourKey = 'day_end_hour';
  static const dayStartMinutesKey = 'day_start_minutes';
  static const dayEndMinutesKey = 'day_end_minutes';

  /// First hour shown in the calendar grid. Defaults to 6.
  /// Kept for backward compat; new code uses [dayStartMinutes].
  Future<int> dayStartHour() async => (await dayStartMinutes()) ~/ 60;

  Future<void> setDayStartHour(int value) async {
    final h = value.clamp(0, 23);
    await set(dayStartHourKey, h.toString());
    await setDayStartMinutes(h * 60);
  }

  /// Last hour shown in the calendar grid. Defaults to 22.
  /// Kept for backward compat; new code uses [dayEndMinutes].
  Future<int> dayEndHour() async {
    final mins = await dayEndMinutes();
    // Historical semantic: hour value 1..24 where 24 = midnight end.
    final h = (mins / 60).ceil().clamp(1, 24);
    return h;
  }

  Future<void> setDayEndHour(int value) async {
    final h = value.clamp(1, 24);
    await set(dayEndHourKey, h.toString());
    await setDayEndMinutes(h * 60);
  }

  /// First minute shown in the calendar grid (0..1439). Defaults to 6:00.
  /// Supports custom minutes like 6:40. Falls back to the legacy hour key.
  Future<int> dayStartMinutes() async {
    final raw = await get(dayStartMinutesKey);
    final parsed = raw == null ? null : int.tryParse(raw.trim());
    if (parsed != null) return parsed.clamp(0, 1439);
    final legacy =
        int.tryParse(await get(dayStartHourKey) ?? '') ?? 6;
    return (legacy.clamp(0, 23) * 60).clamp(0, 1439);
  }

  Future<void> setDayStartMinutes(int value) async {
    final v = value.clamp(0, 1439);
    await set(dayStartMinutesKey, v.toString());
    // Keep legacy hour in sync for older builds/tests.
    await set(dayStartHourKey, (v ~/ 60).clamp(0, 23).toString());
  }

  /// Last minute shown in the calendar grid (1..1440). Defaults to 22:00.
  Future<int> dayEndMinutes() async {
    final raw = await get(dayEndMinutesKey);
    final parsed = raw == null ? null : int.tryParse(raw.trim());
    if (parsed != null) return parsed.clamp(1, 1440);
    final legacy =
        int.tryParse(await get(dayEndHourKey) ?? '') ?? 22;
    return (legacy.clamp(1, 24) * 60).clamp(1, 1440);
  }

  Future<void> setDayEndMinutes(int value) async {
    final v = value.clamp(1, 1440);
    await set(dayEndMinutesKey, v.toString());
    await set(
      dayEndHourKey,
      ((v / 60).ceil().clamp(1, 24)).toString(),
    );
  }

  static const activeYearKey = 'active_year_id';

  /// Currently selected academic year for filtering. Null means all years.
  Stream<int?> watchActiveYearId() =>
      (db.select(db.settings)..where((s) => s.key.equals(activeYearKey)))
          .watchSingleOrNull()
          .map((row) => row == null ? null : int.tryParse(row.value));

  Future<void> setActiveYearId(int? value) async {
    if (value == null) {
      await (db.delete(
        db.settings,
      )..where((s) => s.key.equals(activeYearKey))).go();
    } else {
      await set(activeYearKey, value.toString());
    }
  }

  static const dataFolderKey = 'data_folder_path';
  static const dataLastExportAtKey = 'data_last_export_at';
  static const dataLastImportAtKey = 'data_last_import_at';

  /// User-chosen folder holding exported data files. Null = unset.
  /// The path is remembered across restarts; if the platform revokes
  /// access, reads/writes fail and the UI asks to pick it again.
  Future<String?> dataFolder() => get(dataFolderKey);

  Future<void> setDataFolder(String? path) async {
    if (path == null || path.trim().isEmpty) {
      await remove(dataFolderKey);
    } else {
      await set(dataFolderKey, path.trim());
    }
  }

  /// Epoch millis of the last completed data-folder export/import.
  Future<int?> dataLastExportAt() async {
    final raw = await get(dataLastExportAtKey);
    return raw == null ? null : int.tryParse(raw);
  }

  Future<void> setDataLastExportAt(int value) =>
      set(dataLastExportAtKey, value.toString());

  Future<int?> dataLastImportAt() async {
    final raw = await get(dataLastImportAtKey);
    return raw == null ? null : int.tryParse(raw);
  }

  Future<void> setDataLastImportAt(int value) =>
      set(dataLastImportAtKey, value.toString());

  static const menuLocationKey = 'menu_location';
  /// Dining-hall location id for the menu page. Defaults to '1'.
  /// Validated against the provider's locations by the caller.
  Future<String> menuLocation() async =>
      (await get(menuLocationKey)) ?? '1';

  Future<void> setMenuLocation(String value) => set(menuLocationKey, value);

  static const menuProviderKey = 'menu_provider';
  /// Dining-menu source id, or '' for none. Menu page stays empty until
  /// the user picks a source. Defaults to ''.
  Future<String> menuProviderId() async =>
      (await get(menuProviderKey)) ?? '';

  Future<void> setMenuProviderId(String value) => set(menuProviderKey, value);

  static const autoSyncKey = 'auto_sync';

  /// Whether the data folder syncs automatically (debounced export on
  /// changes, periodic import). Defaults to true.
  Future<bool> autoSync() async => (await get(autoSyncKey)) != 'false';

  Future<void> setAutoSync(bool value) =>
      set(autoSyncKey, value ? 'true' : 'false');
}

class MenuCacheRepository {
  final AppDatabase db;
  MenuCacheRepository(this.db);

  Future<({MenuDay day, int fetchedAt})?> cachedDay(
    String providerId,
    String locationId,
    String isoDate,
  ) async {
    final row =
        await (db.select(db.menuCache)..where(
              (t) =>
                  t.providerId.equals(providerId) &
                  t.locationId.equals(locationId) &
                  t.date.equals(isoDate),
            ))
            .getSingleOrNull();
    if (row == null) return null;
    try {
      final day = MenuDay.fromJson(
        Map<String, dynamic>.from(
          jsonDecode(row.payload) as Map,
        ),
      );
      return (day: day, fetchedAt: row.fetchedAt);
    } catch (_) {
      return null;
    }
  }

  Future<void> storeDay(
    String providerId,
    String locationId,
    String isoDate,
    MenuDay day,
  ) async {
    await (db.delete(db.menuCache)..where(
          (t) =>
              t.providerId.equals(providerId) &
              t.locationId.equals(locationId) &
              t.date.equals(isoDate),
        ))
        .go();
    await db
        .into(db.menuCache)
        .insert(
          MenuCacheCompanion.insert(
            providerId: providerId,
            locationId: locationId,
            date: isoDate,
            payload: jsonEncode(day.toJson()),
            fetchedAt: Value(DateTime.now().millisecondsSinceEpoch),
          ),
        );
  }
}

/// File attachments for an academic year. Synced through the data folder
/// like other tables; rows cascade-delete with the year. Physical files are
/// removed best-effort on delete; a missing file never fails the delete.
class YearFileRepository {
  final AppDatabase db;
  YearFileRepository(this.db);

  Stream<List<YearFile>> watchForYear(int yearId) =>
      (db.select(db.yearFiles)
            ..where((t) => t.yearId.equals(yearId))
            ..orderBy([(t) => OrderingTerm.asc(t.fileName)]))
          .watch();

  Future<List<YearFile>> forYear(int yearId) =>
      (db.select(db.yearFiles)
            ..where((t) => t.yearId.equals(yearId))
            ..orderBy([(t) => OrderingTerm.asc(t.fileName)]))
          .get();

  Future<int> create(YearFilesCompanion entry) => db
      .into(db.yearFiles)
      .insert(
        entry.copyWith(uuid: Value(newUuid()), updatedAt: Value(syncNow())),
      );

  Future<int> delete(int id) async {
    final row =
        await (db.select(
          db.yearFiles,
        )..where((t) => t.id.equals(id))).getSingleOrNull();
    if (row != null) {
      await recordTombstone(db, SyncTables.yearFiles, row.uuid);
    }
    final count = await (db.delete(
      db.yearFiles,
    )..where((t) => t.id.equals(id))).go();
    if (row != null) {
      try {
        final file = File(await resolveAttachmentPath(row.storedPath));
        if (await file.exists()) await file.delete();
      } catch (_) {
        // Best-effort: DB row is already gone.
      }
    }
    return count;
  }
}

/// File attachments for a class. Synced through the data folder like
/// other tables; rows cascade-delete with the class. Physical files are
/// removed best-effort on delete; a missing file never fails the delete.
class ClassFileRepository {
  final AppDatabase db;
  ClassFileRepository(this.db);

  Stream<List<ClassFile>> watchForClass(int classId) =>
      (db.select(db.classFiles)
            ..where((t) => t.classId.equals(classId))
            ..orderBy([(t) => OrderingTerm.asc(t.fileName)]))
          .watch();

  Future<List<ClassFile>> forClass(int classId) =>
      (db.select(db.classFiles)
            ..where((t) => t.classId.equals(classId))
            ..orderBy([(t) => OrderingTerm.asc(t.fileName)]))
          .get();

  Future<int> create(ClassFilesCompanion entry) => db
      .into(db.classFiles)
      .insert(
        entry.copyWith(uuid: Value(newUuid()), updatedAt: Value(syncNow())),
      );

  Future<int> delete(int id) async {
    final row =
        await (db.select(
          db.classFiles,
        )..where((t) => t.id.equals(id))).getSingleOrNull();
    if (row != null) {
      await recordTombstone(db, SyncTables.classFiles, row.uuid);
    }
    final count = await (db.delete(
      db.classFiles,
    )..where((t) => t.id.equals(id))).go();
    if (row != null) {
      try {
        final file = File(await resolveAttachmentPath(row.storedPath));
        if (await file.exists()) await file.delete();
      } catch (_) {
        // Best-effort: DB row is already gone.
      }
    }
    return count;
  }
}
