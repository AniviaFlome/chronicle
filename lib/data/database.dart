import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import 'tables.dart';

part 'database.g.dart';

@DriftDatabase(
  tables: [
    AcademicYears,
    Classes,
    ScheduleItems,
    ScheduleExceptions,
    Holidays,
    Absences,
    Tasks,
    Subtasks,
    TaskReminders,
    Grades,
    PomodoroSessions,
    XtraEvents,
    SyncTombstones,
    MenuCache,
    ClassFiles,
    YearFiles,
    Settings,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 10;

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'chronicle');
  }

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await _addColumnIfMissing(m, classes, classes.building);
        await _addColumnIfMissing(m, classes, classes.module);
        await _addColumnIfMissing(m, classes, classes.onlineLink);
        await _addColumnIfMissing(m, classes, classes.reminderMinutes);
      }
      // NOTE: createTable always uses the current table definition, which
      // already includes the rotation columns added in v4. So a database
      // that never had academic_years gets them for free here and must
      // skip the v4 column adds; only a v3 database needs them.
      if (from < 3) {
        await m.createTable(academicYears);
        await _addColumnIfMissing(m, classes, classes.yearId);
        await _addColumnIfMissing(m, scheduleItems, scheduleItems.rotationDays);
      } else if (from < 4) {
        await _addColumnIfMissing(
          m,
          academicYears,
          academicYears.rotationLength,
        );
        await _addColumnIfMissing(
          m,
          academicYears,
          academicYears.rotationSchoolDays,
        );
        await _addColumnIfMissing(
          m,
          academicYears,
          academicYears.rotationLabels,
        );
        await _addColumnIfMissing(m, scheduleItems, scheduleItems.rotationDays);
      }
      if (from < 5) {
        await _addColumnIfMissing(m, tasks, tasks.progressPercent);
        await _addColumnIfMissing(m, tasks, tasks.repeatKind);
        await _addColumnIfMissing(m, tasks, tasks.repeatUntil);
        await _addColumnIfMissing(m, tasks, tasks.linkedExamId);
        await m.createTable(grades);
        await m.createTable(pomodoroSessions);
        await m.createTable(xtraEvents);
      }
      if (from < 6) {
        // Sync identity columns for folder sync (Syncthing transport).
        // ADD COLUMN with a constant default keeps this safe for non-empty
        // tables; the Dart backfill below replaces the placeholder values
        // with fresh uuids. Every step is idempotent for killed migrations.
        await m.createTable(syncTombstones);
        final syncColumns =
            <({
              TableInfo<Table, dynamic> table,
              GeneratedColumn<Object> uuid,
              GeneratedColumn<Object> updatedAt,
            })>[
              (
                table: academicYears,
                uuid: academicYears.uuid,
                updatedAt: academicYears.updatedAt,
              ),
              (
                table: classes,
                uuid: classes.uuid,
                updatedAt: classes.updatedAt,
              ),
              (
                table: scheduleItems,
                uuid: scheduleItems.uuid,
                updatedAt: scheduleItems.updatedAt,
              ),
              (
                table: scheduleExceptions,
                uuid: scheduleExceptions.uuid,
                updatedAt: scheduleExceptions.updatedAt,
              ),
              (
                table: holidays,
                uuid: holidays.uuid,
                updatedAt: holidays.updatedAt,
              ),
              (
                table: absences,
                uuid: absences.uuid,
                updatedAt: absences.updatedAt,
              ),
              (
                table: tasks,
                uuid: tasks.uuid,
                updatedAt: tasks.updatedAt,
              ),
              (
                table: subtasks,
                uuid: subtasks.uuid,
                updatedAt: subtasks.updatedAt,
              ),
              (
                table: taskReminders,
                uuid: taskReminders.uuid,
                updatedAt: taskReminders.updatedAt,
              ),
              (
                table: grades,
                uuid: grades.uuid,
                updatedAt: grades.updatedAt,
              ),
              (
                table: pomodoroSessions,
                uuid: pomodoroSessions.uuid,
                updatedAt: pomodoroSessions.updatedAt,
              ),
              (
                table: xtraEvents,
                uuid: xtraEvents.uuid,
                updatedAt: xtraEvents.updatedAt,
              ),
            ];
        for (final entry in syncColumns) {
          await _addColumnIfMissing(m, entry.table, entry.uuid);
          await _addColumnIfMissing(m, entry.table, entry.updatedAt);
        }
        await _backfillSyncColumns(m);
      }
      if (from < 7) {
        await m.createTable(menuCache);
      }
      if (from < 8) {
        // Class file attachments (synced since v10 via uuid/updatedAt).
        await m.createTable(classFiles);
      }
      if (from < 9) {
        // Per-kind absence quotas (+ absence kinds, legacy null = theory)
        // and academic-year file attachments (synced since v10).
        await m.createTable(yearFiles);
        await _addColumnIfMissing(m, classes, classes.maxAbsencesTheory);
        await _addColumnIfMissing(m, classes, classes.maxAbsencesPractical);
        await _addColumnIfMissing(m, absences, absences.kind);
      }
      if (from < 10) {
        // File attachments join folder sync: stable identity columns.
        // Backfilled below for existing rows.
        await _addColumnIfMissing(m, classFiles, classFiles.uuid);
        await _addColumnIfMissing(m, classFiles, classFiles.updatedAt);
        await _addColumnIfMissing(m, yearFiles, yearFiles.uuid);
        await _addColumnIfMissing(m, yearFiles, yearFiles.updatedAt);
        await _backfillSyncColumns(m);
      }
    },
    beforeOpen: (_) => customStatement('PRAGMA foreign_keys = ON'),
  );

  /// Adds [column] unless it already exists. Drift does not run migrations
  /// in a transaction, so a killed process can leave a half-migrated
  /// database behind — every step must be safe to re-run.
  Future<void> _addColumnIfMissing(
    Migrator m,
    TableInfo<Table, dynamic> table,
    GeneratedColumn<Object> column,
  ) async {
    final info = await m.database
        .customSelect("PRAGMA table_info('${table.actualTableName}')")
        .get();
    final names = {
      for (final row in info) (row.data['name'] as String).toLowerCase(),
    };
    if (!names.contains(column.name.toLowerCase())) {
      await m.addColumn(table, column);
    }
  }

  /// Assigns fresh uuids and timestamps to pre-v6 rows still carrying the
  /// placeholder defaults. Idempotent: only touches rows with uuid '' or
  /// updatedAt 0, so re-running after a killed migration is safe.
  Future<void> _backfillSyncColumns(Migrator m) async {
    final tables = <TableInfo<Table, dynamic>>[
      academicYears,
      classes,
      scheduleItems,
      scheduleExceptions,
      holidays,
      absences,
      tasks,
      subtasks,
      taskReminders,
      grades,
      pomodoroSessions,
      xtraEvents,
      classFiles,
      yearFiles,
    ];
    final now = DateTime.now().millisecondsSinceEpoch;
    // Tables may not exist yet when backfilling an older migration step
    // (e.g. file tables during the v6 backfill); skip those — their own
    // migration step backfills later via this same method.
    final existingTables = {
      for (final row in await m.database
          .customSelect("SELECT name FROM sqlite_master WHERE type = 'table'")
          .get())
        (row.data['name'] as String).toLowerCase(),
    };
    for (final table in tables) {
      if (!existingTables.contains(table.actualTableName.toLowerCase())) {
        continue;
      }
      final pending = await m.database
          .customSelect(
            "SELECT id FROM ${table.actualTableName} "
            "WHERE uuid = '' OR updated_at = 0",
          )
          .get();
      for (final row in pending) {
        await m.database.customStatement(
          'UPDATE ${table.actualTableName} SET uuid = ?, updated_at = ? '
          'WHERE id = ?',
          [const Uuid().v4(), now, row.data['id']],
        );
      }
    }
  }

  Future<Directory> databaseDirectory() async {
    final dir = await getApplicationSupportDirectory();
    return dir;
  }
}
