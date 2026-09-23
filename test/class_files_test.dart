import 'dart:io';

import 'package:chronicle/data/database.dart';
import 'package:chronicle/data/repositories.dart';
import 'package:chronicle/services/class_files.dart';
import 'package:chronicle/services/data_folder.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:flutter_test/flutter_test.dart';

Future<int> _makeClass(AppDatabase db) {
  return ClassRepository(db).create(
    ClassesCompanion.insert(name: 'Physics', colorValue: 1),
  );
}

void main() {
  group('class files', () {
    test('create, list and delete remove the file from disk', () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final repo = ClassFileRepository(db);
      final classId = await _makeClass(db);

      final dir = await Directory.systemTemp.createTemp('chronicle-files');
      addTearDown(() => dir.delete(recursive: true));
      final stored = File('${dir.path}/syllabus.pdf');
      await stored.writeAsString('pdf-bytes');

      final id = await repo.create(
        ClassFilesCompanion.insert(
          classId: classId,
          fileName: 'syllabus.pdf',
          storedPath: stored.path,
          sizeBytes: const Value(9),
        ),
      );
      expect(await repo.forClass(classId), hasLength(1));

      // Stream emits the new file.
      expect(await repo.watchForClass(classId).first, hasLength(1));

      await repo.delete(id);
      expect(await repo.forClass(classId), isEmpty);
      expect(await stored.exists(), isFalse);
    });

    test('deleting the row survives a missing file', () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final repo = ClassFileRepository(db);
      final classId = await _makeClass(db);
      final id = await repo.create(
        ClassFilesCompanion.insert(
          classId: classId,
          fileName: 'ghost.pdf',
          storedPath: '/nonexistent-chronicle/ghost.pdf',
        ),
      );
      expect(await repo.delete(id), 1);
    });

    test('deleting a class cleans up its files from disk', () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final classes = ClassRepository(db);
      final files = ClassFileRepository(db);
      final classId = await _makeClass(db);

      final dir = await Directory.systemTemp.createTemp('chronicle-files');
      addTearDown(() => dir.delete(recursive: true));
      final stored = File('${dir.path}/notes.png');
      await stored.writeAsString('img');
      await files.create(
        ClassFilesCompanion.insert(
          classId: classId,
          fileName: 'notes.png',
          storedPath: stored.path,
        ),
      );

      await classes.delete(classId);
      expect(await stored.exists(), isFalse);
    });

    test('extensionOf uppercases real extensions only', () {
      expect(ClassFilesService.extensionOf('syllabus.pdf'), 'PDF');
      expect(ClassFilesService.extensionOf('slides.PPTX'), 'PPTX');
      expect(ClassFilesService.extensionOf('archive.tar.gz'), 'GZ');
      expect(ClassFilesService.extensionOf('README'), '');
      expect(ClassFilesService.extensionOf('.gitignore'), '');
      expect(ClassFilesService.extensionOf('trailing.'), '');
    });

    test('opening a missing file throws before touching the OS', () async {      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final service = ClassFilesService(db);
      final ghost = ClassFile(
        id: 1,
        classId: 1,
        fileName: 'ghost.pdf',
        storedPath: '/nonexistent-chronicle/ghost.pdf',
        sizeBytes: 0,
        createdAt: DateTime(2026, 1, 1),
        uuid: 'ghost-uuid',
        updatedAt: 1,
      );
      await expectLater(
        () => service.openFile(ghost),
        throwsA(isA<StateError>()),
      );
    });

    test('linux open skips the share sheet (no UnimplementedError)', () async {
      // Unit tests run on Linux, so Platform.isLinux is true here. With a
      // real file on disk, openFile must reach url_launcher (which throws
      // MissingPluginException under flutter_test) and must NOT throw the
      // share plugin's "Sharing files not supported on Linux".
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final dir = await Directory.systemTemp.createTemp('chronicle-open');
      addTearDown(() => dir.delete(recursive: true));
      final file = File('${dir.path}/note.txt');
      await file.writeAsString('hello');
      final row = ClassFile(
        id: 1,
        classId: 1,
        fileName: 'note.txt',
        storedPath: file.path,
        sizeBytes: 5,
        createdAt: DateTime(2026, 1, 1),
        uuid: 'note-uuid',
        updatedAt: 1,
      );
      await expectLater(
        () => ClassFilesService(db).openFile(row),
        throwsA(
          predicate(
            (e) => e is! UnimplementedError,
            'not the share-sheet UnimplementedError',
          ),
        ),
      );
    });

    test('system picker failures classify as unreadable', () {      // The platform file picker surfaces its own failures (e.g. a content
      // provider refusing to open the picked file) as PlatformException.
      expect(
        ClassFilesService.pickErrorKind(
          PlatformException(code: 'unknown_path', message: 'Failed to retrieve path.'),
        ),
        'unreadable',
      );
      expect(ClassFilesService.pickErrorKind(StateError('x')), 'other');
    });

    test('class files are part of the sync export', () async {
      // SyncTables has entries for file tables, so folder sync covers them.
      expect(SyncTables.classes, 'classes');
      final names = [
        SyncTables.years,
        SyncTables.classes,
        SyncTables.scheduleItems,
        SyncTables.exceptions,
        SyncTables.holidays,
        SyncTables.absences,
        SyncTables.tasks,
        SyncTables.subtasks,
        SyncTables.reminders,
        SyncTables.grades,
        SyncTables.sessions,
        SyncTables.xtra,
        SyncTables.classFiles,
        SyncTables.yearFiles,
      ];
      expect(names, contains('class_files'));
      expect(names, contains('year_files'));
      expect(
        DataFolderService.tableFiles.values,
        contains('class_files.json'),
      );
      expect(DataFolderService.tableFiles.values, contains('year_files.json'));
    });
  });

  group('year files', () {
    Future<int> makeYear(AppDatabase db) {
      return ClassRepository(db).createYear(
        AcademicYearsCompanion.insert(
          name: '2026/27',
          startDate: '2026-09-01',
          endDate: '2027-06-30',
        ),
      );
    }

    test('create, list and delete remove the file from disk', () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final repo = YearFileRepository(db);
      final yearId = await makeYear(db);

      final dir = await Directory.systemTemp.createTemp('chronicle-yfiles');
      addTearDown(() => dir.delete(recursive: true));
      final stored = File('${dir.path}/program.pdf');
      await stored.writeAsString('pdf-bytes');

      final id = await repo.create(
        YearFilesCompanion.insert(
          yearId: yearId,
          fileName: 'program.pdf',
          storedPath: stored.path,
          sizeBytes: const Value(9),
        ),
      );
      expect(await repo.forYear(yearId), hasLength(1));
      expect(await repo.watchForYear(yearId).first, hasLength(1));

      await repo.delete(id);
      expect(await repo.forYear(yearId), isEmpty);
      expect(await stored.exists(), isFalse);
    });

    test('deleting a year cleans up its files from disk', () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final classes = ClassRepository(db);
      final files = YearFileRepository(db);
      final yearId = await makeYear(db);

      final dir = await Directory.systemTemp.createTemp('chronicle-yfiles');
      addTearDown(() => dir.delete(recursive: true));
      final stored = File('${dir.path}/program.pdf');
      await stored.writeAsString('pdf');
      await files.create(
        YearFilesCompanion.insert(
          yearId: yearId,
          fileName: 'program.pdf',
          storedPath: stored.path,
        ),
      );

      await classes.deleteYear(yearId);
      expect(await stored.exists(), isFalse);
      expect(await files.forYear(yearId), isEmpty);
    });
  });

  group('file folder sync', () {
    test('blobNameFor is readable and stable', () {
      expect(
        DataFolderService.blobNameFor(
          'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
          'syllabus.pdf',
        ),
        'syllabus_a1b2c3d4.pdf',
      );
      expect(
        DataFolderService.blobNameFor('abc-123', 'README'),
        'readme_abc123',
      );
      expect(
        DataFolderService.blobNameFor('abc-123', 'My Slides.PPTX'),
        'my_slides_abc123.pptx',
      );
      // Legacy uuid-only names are still recognized on import.
      expect(
        DataFolderService.legacyBlobNameFor(
          'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
          'syllabus.pdf',
        ),
        'a1b2c3d4-e5f6-7890-abcd-ef1234567890.pdf',
      );
    });

    test('resolveStoredPath joins relative rows, passes absolute through', () async {
      final base = await Directory.systemTemp.createTemp('chronicle-base');
      addTearDown(() => base.delete(recursive: true));
      expect(
        await ClassFilesService.resolveStoredPath(
          root: base,
          stored: 'class_files/7/syllabus.pdf',
        ),
        '${base.path}/class_files/7/syllabus.pdf',
      );
      expect(
        await ClassFilesService.resolveStoredPath(
          root: base,
          stored: '/elsewhere/x.pdf',
        ),
        '/elsewhere/x.pdf',
      );
    });

    test('export carries blobs, import restores bytes and parents', () async {
      final folder = await Directory.systemTemp.createTemp('chronicle-sync');
      addTearDown(() => folder.delete(recursive: true));
      final baseA = await Directory.systemTemp.createTemp('chronicle-stA');
      addTearDown(() => baseA.delete(recursive: true));
      final baseB = await Directory.systemTemp.createTemp('chronicle-stB');
      addTearDown(() => baseB.delete(recursive: true));
      final dbA = AppDatabase(NativeDatabase.memory());
      addTearDown(dbA.close);
      final dbB = AppDatabase(NativeDatabase.memory());
      addTearDown(dbB.close);

      // Device A: year + class + one file each, with real bytes.
      await SettingsRepository(dbA).setDataFolder(folder.path);
      final yearIdA = await ClassRepository(dbA).createYear(
        AcademicYearsCompanion.insert(
          name: '2026/27',
          startDate: '2026-09-01',
          endDate: '2027-06-30',
        ),
      );
      final classIdA = await ClassRepository(dbA).create(
        ClassesCompanion.insert(name: 'Physics', colorValue: 1),
      );
      Future<String> seedBlob(
        Directory base,
        String scope,
        int parentId,
        String name,
        String bytes,
      ) async {
        final dir = Directory('${base.path}/$scope/$parentId');
        await dir.create(recursive: true);
        final file = File('${dir.path}/$name');
        await file.writeAsString(bytes);
        return file.path;
      }

      const classBytes = 'syllabus-bytes';
      final classPathA = await seedBlob(
        baseA,
        'class_files',
        classIdA,
        'syllabus.pdf',
        classBytes,
      );
      final classFileId = await ClassFileRepository(dbA).create(
        ClassFilesCompanion.insert(
          classId: classIdA,
          fileName: 'syllabus.pdf',
          storedPath: classPathA,
          sizeBytes: Value(classBytes.length),
        ),
      );
      const yearBytes = 'program-bytes';
      final yearPathA = await seedBlob(
        baseA,
        'year_files',
        yearIdA,
        'program.pdf',
        yearBytes,
      );
      await YearFileRepository(dbA).create(
        YearFilesCompanion.insert(
          yearId: yearIdA,
          fileName: 'program.pdf',
          storedPath: yearPathA,
          sizeBytes: Value(yearBytes.length),
        ),
      );
      final classUuid =
          (await ClassFileRepository(dbA).forClass(classIdA)).single.uuid;

      final exported = await DataFolderService(dbA, null, baseA).exportData();
      expect(exported.error, isNull);
      expect(File('${folder.path}/class_files.json').existsSync(), isTrue);
      expect(File('${folder.path}/year_files.json').existsSync(), isTrue);
      final blobs = Directory(
        '${folder.path}/files',
      ).listSync().whereType<File>().toList();
      expect(blobs, hasLength(2));
      // Blobs keep human-readable names (not uuid soup).
      final blobNames = {
        for (final b in blobs) b.path.split('/').last,
      };
      expect(
        blobNames.any((n) => n.startsWith('syllabus_') && n.endsWith('.pdf')),
        isTrue,
      );
      expect(
        blobNames.any((n) => n.startsWith('program_') && n.endsWith('.pdf')),
        isTrue,
      );

      // Device B: different local ids (dummy class first) to prove the
      // parent FK remaps by uuid instead of raw id.
      await SettingsRepository(dbB).setDataFolder(folder.path);
      await ClassRepository(dbB).create(
        ClassesCompanion.insert(name: 'Dummy', colorValue: 2),
      );
      final imported = await DataFolderService(dbB, null, baseB).importData();
      expect(imported.error, isNull);
      expect(imported.rowsUpserted, greaterThan(0));

      final classesB = await ClassRepository(dbB).all();
      final physicsB = classesB.singleWhere((c) => c.name == 'Physics');
      expect(physicsB.id, isNot(classIdA));
      final filesB = await ClassFileRepository(dbB).forClass(physicsB.id);
      expect(filesB, hasLength(1));
      expect(filesB.single.uuid, classUuid);
      expect(filesB.single.fileName, 'syllabus.pdf');
      // Stored paths are relative (portable); bytes land under baseB.
      expect(filesB.single.storedPath, isNot(startsWith('/')));
      final restoredB = File('${baseB.path}/${filesB.single.storedPath}');
      expect(await restoredB.exists(), isTrue);
      expect(await restoredB.readAsString(), classBytes);

      final yearsB = await ClassRepository(dbB).years();
      expect(yearsB, hasLength(1));
      final yfilesB = await YearFileRepository(dbB).forYear(yearsB.single.id);
      expect(yfilesB, hasLength(1));
      expect(yfilesB.single.storedPath, isNot(startsWith('/')));
      expect(
        await File(
          '${baseB.path}/${yfilesB.single.storedPath}',
        ).readAsString(),
        yearBytes,
      );

      // Exported metadata carries no absolute device paths.
      final classJson = await File(
        '${folder.path}/class_files.json',
      ).readAsString();
      expect(classJson, isNot(contains(baseA.path)));

      // Re-import is a no-op (no churn).
      final again = await DataFolderService(dbB, null, baseB).importData();
      expect(again.error, isNull);
      expect(again.rowsUpserted, 0);

      // Delete on A propagates the delete plus the blob to B.
      await ClassFileRepository(dbA).delete(classFileId);
      final reexported = await DataFolderService(dbA, null, baseA).exportData();
      expect(reexported.error, isNull);
      expect(
        Directory(
          '${folder.path}/files',
        ).listSync().whereType<File>().toList(),
        hasLength(1),
      );
      final reimported = await DataFolderService(dbB, null, baseB).importData();
      expect(reimported.error, isNull);
      expect(reimported.rowsDeleted, 1);
      expect(await ClassFileRepository(dbB).forClass(physicsB.id), isEmpty);
      expect(await ClassFileRepository(dbB).forClass(physicsB.id), isEmpty);
      expect(await restoredB.exists(), isFalse);
    });

    test('legacy uuid blobs still import', () async {
      // Folders written before human-readable names carry `<uuid>[.ext]`
      // blobs; import must still find them.
      final folder = await Directory.systemTemp.createTemp('chronicle-leg');
      addTearDown(() => folder.delete(recursive: true));
      final baseB = await Directory.systemTemp.createTemp('chronicle-stC');
      addTearDown(() => baseB.delete(recursive: true));
      final dbB = AppDatabase(NativeDatabase.memory());
      addTearDown(dbB.close);
      await SettingsRepository(dbB).setDataFolder(folder.path);

      final dbA = AppDatabase(NativeDatabase.memory());
      addTearDown(dbA.close);
      await SettingsRepository(dbA).setDataFolder(folder.path);
      final classIdA = await ClassRepository(dbA).create(
        ClassesCompanion.insert(name: 'Math', colorValue: 1),
      );
      final srcDir = await Directory.systemTemp.createTemp('chronicle-src');
      addTearDown(() => srcDir.delete(recursive: true));
      final src = File('${srcDir.path}/notes.txt');
      await src.writeAsString('legacy-bytes');
      await ClassFileRepository(dbA).create(
        ClassFilesCompanion.insert(
          classId: classIdA,
          fileName: 'notes.txt',
          storedPath: src.path,
        ),
      );
      final uuid = (await ClassFileRepository(
        dbA,
      ).forClass(classIdA)).single.uuid;
      await DataFolderService(dbA, null, baseB).exportData();
      // Simulate an old export: rename the blob to the legacy uuid name.
      final blobsDir = Directory('${folder.path}/files');
      final current = blobsDir.listSync().whereType<File>().single;
      final legacy = File(
        '${blobsDir.path}/${DataFolderService.legacyBlobNameFor(uuid, 'notes.txt')}',
      );
      await current.rename(legacy.path);

      final imported = await DataFolderService(
        dbB,
        null,
        baseB,
      ).importData();
      expect(imported.error, isNull);
      final classesB = await ClassRepository(dbB).all();
      final filesB = await ClassFileRepository(
        dbB,
      ).forClass(classesB.singleWhere((c) => c.name == 'Math').id);
      expect(filesB, hasLength(1));
      expect(filesB.single.uuid, uuid);
      expect(
        await File(
          '${baseB.path}/${filesB.single.storedPath}',
        ).readAsString(),
        'legacy-bytes',
      );
    });
  });
}
