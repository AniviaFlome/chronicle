import 'dart:io';

import 'package:chronicle/data/database.dart';
import 'package:chronicle/data/repositories.dart';
import 'package:chronicle/data/tables.dart';
import 'package:chronicle/services/data_folder.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// Two memory databases act as two devices sharing one data folder.
Future<(AppDatabase, DataFolderService)> makeDevice(Directory folder) async {
  final db = AppDatabase(
    NativeDatabase.memory(
      setup: (db) {
        db.execute('PRAGMA foreign_keys = ON');
      },
    ),
  );
  final settings = SettingsRepository(db);
  await settings.setDataFolder(folder.path);
  addTearDown(() => db.close());
  return (db, DataFolderService(db, settings));
}

Future<String> classUuid(AppDatabase db, int id) async =>
    (await ClassRepository(db).byId(id)).uuid;

void main() {
  late Directory folder;

  setUp(() async {
    folder = await Directory.systemTemp.createTemp('chronicle-data-test');
    addTearDown(() => folder.delete(recursive: true));
  });

  test('unconfigured folder returns no-folder error', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(() => db.close());
    final service = DataFolderService(db);
    expect((await service.exportData()).error, 'no-folder');
    expect((await service.importData()).error, 'no-folder');
  });

  test('export writes one JSON file per table', () async {
    final (db, service) = await makeDevice(folder);
    final classes = ClassRepository(db);
    final id = await classes.create(
      ClassesCompanion.insert(name: 'Math', colorValue: 0xFF4F6BED),
    );
    final row = await classes.byId(id);
    expect(row.uuid, isNotEmpty);
    expect(row.updatedAt, greaterThan(0));

    final result = await service.exportData();
    expect(result.error, isNull);
    expect(result.rowsExported, greaterThan(0));
    for (final name in [
      'manifest.json',
      ...DataFolderService.tableFiles.values,
      'tombstones.json',
    ]) {
      expect(await File('${folder.path}/$name').exists(), isTrue,
          reason: 'missing $name');
    }
    // One JSON object per table file (list), manifest carries the tag.
    expect(
      (await File('${folder.path}/classes.json').readAsString()).startsWith(
        '[',
      ),
      isTrue,
    );
  });

  test('two devices converge with FK remap', () async {
    final (dbA, serviceA) = await makeDevice(folder);
    final (dbB, serviceB) = await makeDevice(folder);
    final classesA = ClassRepository(dbA);
    final absencesA = AbsenceRepository(dbA);
    final tasksA = TaskRepository(dbA);

    // Offset B's ids so file ids differ from local ids.
    final classesB = ClassRepository(dbB);
    final throwaway = await classesB.create(
      ClassesCompanion.insert(name: 'ZZZ', colorValue: 0xFF000000),
    );
    await classesB.delete(throwaway);

    final yearA = await classesA.createYear(
      AcademicYearsCompanion.insert(
        name: '2026/27',
        startDate: '2026-09-01',
        endDate: '2027-06-30',
      ),
    );
    final classA = await classesA.createClassWithSlots(
      ClassesCompanion.insert(
        name: 'Math',
        colorValue: 0xFF4F6BED,
        yearId: Value(yearA),
      ),
      [
        ScheduleItemsCompanion.insert(
          classId: 0, // replaced by createClassWithSlots
          dayOfWeek: 1,
          startMinutes: 540,
          endMinutes: 600,
          rotation: RotationKind.weekly,
        ),
      ],
    );
    final uuidA = await classUuid(dbA, classA);
    await absencesA.mark(
      AbsencesCompanion.insert(
        classId: classA,
        date: '2026-09-14',
        startMinutes: 540,
        endMinutes: 600,
      ),
    );
    await tasksA.create(
      TasksCompanion.insert(title: 'Homework', classId: Value(classA)),
    );

    await serviceA.exportData();
    final imported = await serviceB.importData();
    expect(imported.error, isNull);
    expect(imported.rowsUpserted, greaterThan(0));

    // Same logical rows, stable uuids, local ids remapped.
    final bClasses = await classesB.all();
    final math = bClasses.singleWhere((c) => c.name == 'Math');
    expect(math.uuid, uuidA);
    expect(math.id, isNot(classA));
    final bYears = await classesB.years();
    expect(bYears.single.name, '2026/27');
    expect(math.yearId, bYears.single.id);
    final bSlots = await classesB.scheduleItemsFor(math.id);
    expect(bSlots, hasLength(1));
    expect(bSlots.single.startMinutes, 540);
    final bAbsences = await AbsenceRepository(dbB).forClass(math.id);
    expect(bAbsences.single.date, '2026-09-14');
    expect(
      (await TaskRepository(dbB).watchAll().first).single.task.title,
      'Homework',
    );

    // Re-importing unchanged files is a no-op merge (rows already current).
    final again = await serviceB.importData();
    expect(again.rowsUpserted, 0);
    expect(again.rowsDeleted, 0);
  });

  test('newer edit wins on both sides', () async {
    final (dbA, serviceA) = await makeDevice(folder);
    final (dbB, serviceB) = await makeDevice(folder);
    final classesA = ClassRepository(dbA);
    final classesB = ClassRepository(dbB);

    final classA = await classesA.create(
      ClassesCompanion.insert(name: 'Math', colorValue: 0xFF4F6BED),
    );
    await serviceA.exportData();
    await serviceB.importData();

    // A renames, exports, B imports.
    await classesA.update(
      (await classesA.byId(classA)).copyWith(name: 'Maths'),
    );
    await serviceA.exportData();
    await serviceB.importData();
    expect(
      (await classesB.all()).singleWhere((c) => c.name == 'Maths').name,
      'Maths',
    );

    // B renames, exports, A imports.
    final mathB = (await classesB.all()).singleWhere(
      (c) => c.name == 'Maths',
    );
    await classesB.update(mathB.copyWith(name: 'Mathematics'));
    await serviceB.exportData();
    await serviceA.importData();
    expect(
      (await classesA.all())
          .singleWhere((c) => c.name == 'Mathematics')
          .name,
      'Mathematics',
    );
  });

  test('delete propagates as tombstone', () async {
    final (dbA, serviceA) = await makeDevice(folder);
    final (dbB, serviceB) = await makeDevice(folder);
    final classesA = ClassRepository(dbA);
    final absencesA = AbsenceRepository(dbA);

    final classA = await classesA.create(
      ClassesCompanion.insert(name: 'Math', colorValue: 0xFF4F6BED),
    );
    await absencesA.mark(
      AbsencesCompanion.insert(
        classId: classA,
        date: '2026-09-14',
        startMinutes: 540,
        endMinutes: 600,
      ),
    );
    await serviceA.exportData();
    await serviceB.importData();
    expect(
      await AbsenceRepository(dbB).forClass(
        (await ClassRepository(dbB).all()).single.id,
      ),
      hasLength(1),
    );

    // Delete on A, export, import on B.
    final absenceA = (await absencesA.forClass(classA)).single;
    await absencesA.unmark(absenceA.id);
    await serviceA.exportData();
    final result = await serviceB.importData();
    expect(result.rowsDeleted, 1);
    expect(
      await AbsenceRepository(dbB).forClass(
        (await ClassRepository(dbB).all()).single.id,
      ),
      isEmpty,
    );
    // Tombstone adopted so a later export from B keeps propagating it.
    final tombs = await dbB.select(dbB.syncTombstones).get();
    expect(
      tombs.any(
        (t) => t.tableKey == SyncTables.absences && t.uuid == absenceA.uuid,
      ),
      isTrue,
    );
  });

  test('class delete tombstones cascade children', () async {
    final (dbA, serviceA) = await makeDevice(folder);
    final (dbB, serviceB) = await makeDevice(folder);
    final classesA = ClassRepository(dbA);

    final classA = await classesA.createClassWithSlots(
      ClassesCompanion.insert(name: 'Math', colorValue: 0xFF4F6BED),
      [
        ScheduleItemsCompanion.insert(
          classId: 0,
          dayOfWeek: 1,
          startMinutes: 540,
          endMinutes: 600,
          rotation: RotationKind.weekly,
        ),
      ],
    );
    await AbsenceRepository(dbA).mark(
      AbsencesCompanion.insert(
        classId: classA,
        date: '2026-09-14',
        startMinutes: 540,
        endMinutes: 600,
      ),
    );
    await serviceA.exportData();
    await serviceB.importData();
    expect(await ClassRepository(dbB).all(), hasLength(1));

    await classesA.delete(classA);
    await serviceA.exportData();
    final result = await serviceB.importData();
    expect(await ClassRepository(dbB).all(), isEmpty);
    expect(await dbB.select(dbB.scheduleItems).get(), isEmpty);
    expect(await dbB.select(dbB.absences).get(), isEmpty);
    expect(result.rowsDeleted, greaterThanOrEqualTo(1));
  });

  test('import from empty folder reports manifest-missing', () async {
    final (db, service) = await makeDevice(folder);
    final result = await service.importData();
    expect(result.error, 'manifest-missing');
    expect((await ClassRepository(db).all()), isEmpty);
    await db.close();
  });

  test('import with corrupt manifest reports manifest-unreadable', () async {
    final (db, service) = await makeDevice(folder);
    await File('${folder.path}/manifest.json').writeAsString('{{{');
    final result = await service.importData();
    expect(result.error, startsWith('manifest-unreadable'));
    await db.close();
  });

  test('import from a missing folder reports folder-missing', () async {
    final (db, service) = await makeDevice(folder);
    await SettingsRepository(db).setDataFolder('${folder.path}/gone');
    final result = await service.importData();
    expect(result.error, 'folder-missing');
    await db.close();
  });
}
