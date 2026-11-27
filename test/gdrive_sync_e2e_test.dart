import 'dart:io';

import 'package:chronicle/data/database.dart';
import 'package:chronicle/data/repositories.dart';
import 'package:chronicle/services/data_folder.dart';
import 'package:chronicle/services/folder_sync.dart';
import 'package:chronicle/services/gdrive_auth.dart';
import 'package:chronicle/services/gdrive_storage.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'gdrive_storage_test.dart' show FakeDriveServer;

class _StaticAuth implements GoogleDriveAuth {
  @override
  Future<bool> isConfigured() async => true;
  @override
  Future<GoogleDriveAccount?> currentAccount() async =>
      const GoogleDriveAccount(email: 'sync@example.com');
  @override
  Future<GoogleDriveAccount?> signIn() async => currentAccount();
  @override
  Future<void> signOut() async {}
  @override
  Future<String?> getAccessToken({bool forceRefresh = false}) async => 'tok-1';
}

void main() {
  test('two-device round-trip sync over GoogleDriveStorage incl. blobs, tombstones, and fast poll', () async {
    final server = FakeDriveServer();
    final rootA = await Directory.systemTemp.createTemp('chronicle_gd_a_');
    final rootB = await Directory.systemTemp.createTemp('chronicle_gd_b_');
    final dbA = AppDatabase(NativeDatabase.memory());
    final dbB = AppDatabase(NativeDatabase.memory());

    addTearDown(() async {
      await dbA.close();
      await dbB.close();
      if (await rootA.exists()) await rootA.delete(recursive: true);
      if (await rootB.exists()) await rootB.delete(recursive: true);
    });

    final settingsA = SettingsRepository(dbA);
    final settingsB = SettingsRepository(dbB);
    await settingsA.setSyncBackend('gdrive');
    await settingsB.setSyncBackend('gdrive');
    await settingsA.setSyncSettings(true);
    await settingsB.setSyncSettings(true);
    await settingsA.setAppTheme('nord');

    final storageA = GoogleDriveStorage(
      auth: _StaticAuth(),
      httpClient: server.client(),
    );
    final storageB = GoogleDriveStorage(
      auth: _StaticAuth(),
      httpClient: server.client(),
    );
    final serviceA = DataFolderService(
      dbA,
      settingsA,
      rootA,
      _StaticAuth(),
      storageA,
    );
    final serviceB = DataFolderService(
      dbB,
      settingsB,
      rootB,
      _StaticAuth(),
      storageB,
    );

    // Device A creates a class, a task, and a class attachment blob.
    final classIdA = await ClassRepository(dbA).create(
      ClassesCompanion.insert(name: 'Algorithms', colorValue: 0xFF4F6BED),
    );
    final taskIdA = await TaskRepository(dbA).create(
      TasksCompanion.insert(title: 'Problem Set 1', classId: Value(classIdA)),
    );
    final blobDir = Directory('${rootA.path}/class_files/$classIdA');
    await blobDir.create(recursive: true);
    final blobFile = File('${blobDir.path}/syllabus.txt');
    await blobFile.writeAsString('Week 1: Graphs');
    await ClassFileRepository(dbA).create(
      ClassFilesCompanion.insert(
        classId: classIdA,
        fileName: 'syllabus.txt',
        storedPath: 'class_files/$classIdA/syllabus.txt',
        sizeBytes: Value(await blobFile.length()),
      ),
    );

    final expA = await serviceA.exportData();
    expect(expA.error, isNull);
    expect(expA.rowsExported, 3);

    // Device B imports via FolderSyncController.
    final controllerB = FolderSyncController(service: serviceB);
    addTearDown(controllerB.dispose);

    final imported = await controllerB.importIfNewer();
    expect(imported, isTrue);

    final classesB = await ClassRepository(dbB).all();
    final tasksB = await dbB.select(dbB.tasks).get();
    final filesB = await dbB.select(dbB.classFiles).get();
    expect(classesB.map((c) => c.name), ['Algorithms']);
    expect(tasksB.map((t) => t.title), ['Problem Set 1']);
    expect(filesB.length, 1);
    final localBlobB = File('${rootB.path}/${filesB.single.storedPath}');
    expect(await localBlobB.readAsString(), 'Week 1: Graphs');
    expect(await settingsB.appTheme(), 'nord');

    // Second poll short-circuits via fastManifestExportedAt with ZERO downloads.
    final downloadsBefore = server.downloadCount;
    expect(await controllerB.importIfNewer(), isFalse);
    expect(server.downloadCount, downloadsBefore);

    // Device B deletes the task and exports; Device A imports and deletes it too.
    await Future.delayed(const Duration(milliseconds: 5));
    await TaskRepository(dbB).delete(tasksB.single.id);
    final expB = await serviceB.exportData();
    expect(expB.error, isNull);

    final impA = await serviceA.importData();
    expect(impA.error, isNull);
    expect(impA.rowsDeleted, 1);
    expect(await TaskRepository(dbA).byId(taskIdA), isNull);
  });
}
