import 'dart:io';

import 'package:chronicle/data/database.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;

/// Regression test for the v3/v4 migration collision: createTable always
/// uses the current table definition, so a pre-v3 database must not run
/// the v4 column adds for academic_years (they are already included).
/// Creates a faithful v1 database file: no academic_years/grades/
/// pomodoro/xtra tables and none of the columns added since v1.
void _createV1Database(String path) {
  final setup = sqlite.sqlite3.open(path);
  setup.execute('PRAGMA foreign_keys = OFF');
  // Faithful v1 schema: no academic_years/grades/pomodoro/xtra tables,
  // no building/module/online_link/reminder/progress/repeat/link columns.
  setup.execute('''
        CREATE TABLE classes (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          color_value INTEGER NOT NULL,
          start_date TEXT,
          end_date TEXT,
          teacher TEXT,
          teacher_email TEXT,
          room TEXT,
          notes TEXT,
          max_absences INTEGER,
          active INTEGER NOT NULL
        )''');
  setup.execute('''
        CREATE TABLE schedule_items (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          class_id INTEGER NOT NULL REFERENCES classes (id) ON DELETE CASCADE,
          day_of_week INTEGER NOT NULL,
          start_minutes INTEGER NOT NULL,
          end_minutes INTEGER NOT NULL,
          room TEXT,
          rotation TEXT NOT NULL,
          week_parity INTEGER,
          cycle_length INTEGER,
          cycle_weeks TEXT,
          valid_from TEXT,
          valid_to TEXT
        )''');
  setup.execute('''
        CREATE TABLE schedule_exceptions (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          schedule_item_id INTEGER NOT NULL REFERENCES schedule_items (id) ON DELETE CASCADE,
          date TEXT NOT NULL,
          status TEXT NOT NULL,
          new_start_minutes INTEGER,
          new_end_minutes INTEGER,
          new_room TEXT
        )''');
  setup.execute('''
        CREATE TABLE holidays (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          start_date TEXT NOT NULL,
          end_date TEXT NOT NULL
        )''');
  setup.execute('''
        CREATE TABLE absences (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          class_id INTEGER NOT NULL REFERENCES classes (id) ON DELETE CASCADE,
          date TEXT NOT NULL,
          start_minutes INTEGER NOT NULL,
          end_minutes INTEGER NOT NULL,
          reason TEXT,
          is_excused INTEGER NOT NULL,
          notes TEXT,
          created_at INTEGER NOT NULL
        )''');
  setup.execute('''
        CREATE TABLE tasks (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          class_id INTEGER REFERENCES classes (id) ON DELETE SET NULL,
          title TEXT NOT NULL,
          notes TEXT,
          type TEXT NOT NULL,
          due_date TEXT,
          due_minutes INTEGER,
          priority INTEGER NOT NULL,
          is_done INTEGER NOT NULL,
          done_at INTEGER,
          created_at INTEGER NOT NULL
        )''');
  setup.execute('''
        CREATE TABLE subtasks (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          task_id INTEGER NOT NULL REFERENCES tasks (id) ON DELETE CASCADE,
          title TEXT NOT NULL,
          is_done INTEGER NOT NULL,
          position INTEGER NOT NULL
        )''');
  setup.execute('''
        CREATE TABLE task_reminders (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          task_id INTEGER NOT NULL REFERENCES tasks (id) ON DELETE CASCADE,
          offset_minutes INTEGER NOT NULL
        )''');
  setup.execute('''
        CREATE TABLE settings (
          key TEXT NOT NULL PRIMARY KEY,
          value TEXT NOT NULL
        )''');
  setup.execute(
    "INSERT INTO classes (name, color_value, active) VALUES ('Math', 1, 1)",
  );
  setup.execute(
    "INSERT INTO tasks (title, type, priority, is_done, created_at) "
    "VALUES ('Essay', 'homework', 1, 0, 0)",
  );
  setup.execute(
    "INSERT INTO settings (key, value) VALUES ('week_start_day', '1')",
  );
  setup.execute('PRAGMA user_version = 1');
  setup.close();
}

void main() {
  test('migrates a v1 database file all the way to latest', () async {
    final dir = await Directory.systemTemp.createTemp('chronicle-mig');
    final path = '${dir.path}/old.sqlite';

    _createV1Database(path);

    final db = AppDatabase(NativeDatabase(File(path)));
    addTearDown(db.close);

    // Migration must complete without "duplicate column" errors, landing
    // on the latest schema (whatever it currently is).
    final latest = AppDatabase(NativeDatabase.memory());
    addTearDown(latest.close);
    final want = await latest.customSelect('PRAGMA user_version').getSingle();
    final version = await db.customSelect('PRAGMA user_version').getSingle();
    expect(version.data['user_version'], want.data['user_version']);

    final columns = await db
        .customSelect("PRAGMA table_info('academic_years')")
        .get();
    final names = [for (final c in columns) c.data['name'] as String];
    expect(names.where((n) => n == 'rotation_length'), hasLength(1));
    expect(
      names,
      containsAll([
        'name',
        'start_date',
        'end_date',
        'rotation_length',
        'rotation_school_days',
        'rotation_labels',
      ]),
    );

    final slotColumns = await db
        .customSelect("PRAGMA table_info('schedule_items')")
        .get();
    expect([
      for (final c in slotColumns)
        if ((c.data['name'] as String) == 'rotation_days') 1,
    ], hasLength(1));

    // v6 sync columns are backfilled with usable identity stamps.
    final migratedClass = (await db.select(db.classes).get()).single;
    expect(migratedClass.uuid, isNotEmpty);
    expect(migratedClass.updatedAt, greaterThan(0));
    // v6/v7 tables exist.
    for (final name in [
      'sync_tombstones',
      'menu_cache',
      'class_files',
      'year_files',
    ]) {
      final info = await db
          .customSelect("SELECT name FROM sqlite_master WHERE name = '$name'")
          .get();
      expect(info, hasLength(1), reason: 'missing table $name');
    }
    // v9 per-kind quota columns exist.
    for (final column in ['max_absences_theory', 'max_absences_practical']) {
      final classColumns = await db
          .customSelect("PRAGMA table_info('classes')")
          .get();
      expect(
        [for (final c in classColumns) c.data['name'] as String],
        contains(column),
      );
    }
    final absenceColumns = await db
        .customSelect("PRAGMA table_info('absences')")
        .get();
    expect(
      [for (final c in absenceColumns) c.data['name'] as String],
      contains('kind'),
    );

    // Old data survives.
    expect(await db.select(db.classes).get(), hasLength(1));
    expect(await db.select(db.tasks).get(), hasLength(1));
    expect(
      await (db.select(
        db.settings,
      )..where((s) => s.key.equals('week_start_day'))).getSingleOrNull(),
      isNotNull,
    );

    await dir.delete(recursive: true);
  });

  test('recovers a half-migrated database', () async {
    // Simulates a process killed mid-migration: v2 columns applied but the
    // schema version never bumped. The upgrade must be safe to re-run.
    final dir = await Directory.systemTemp.createTemp('chronicle-mig');
    final path = '${dir.path}/half.sqlite';
    _createV1Database(path);

    final partial = sqlite.sqlite3.open(path);
    partial.execute('ALTER TABLE "classes" ADD COLUMN "building" TEXT NULL');
    partial.execute('ALTER TABLE "classes" ADD COLUMN "module" TEXT NULL');
    partial.execute('ALTER TABLE "classes" ADD COLUMN "online_link" TEXT NULL');
    partial.execute(
      'ALTER TABLE "classes" ADD COLUMN "reminder_minutes" INTEGER NULL',
    );
    partial.execute('PRAGMA user_version = 1');
    partial.close();

    final db = AppDatabase(NativeDatabase(File(path)));
    addTearDown(db.close);

    final latest = AppDatabase(NativeDatabase.memory());
    addTearDown(latest.close);
    final want = await latest.customSelect('PRAGMA user_version').getSingle();
    final version = await db.customSelect('PRAGMA user_version').getSingle();
    expect(version.data['user_version'], want.data['user_version']);
    expect(await db.select(db.classes).get(), hasLength(1));
    expect(await db.select(db.tasks).get(), hasLength(1));

    final classColumns = await db
        .customSelect("PRAGMA table_info('classes')")
        .get();
    expect([
      for (final c in classColumns)
        if ((c.data['name'] as String) == 'building') 1,
    ], hasLength(1));

    await dir.delete(recursive: true);
  });
}
