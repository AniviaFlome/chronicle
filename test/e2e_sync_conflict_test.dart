import 'dart:convert';
import 'dart:io';

import 'package:chronicle/data/database.dart';
import 'package:chronicle/data/repositories.dart';
import 'package:chronicle/services/data_folder.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// Two databases share one data folder (the documented one-device-at-a-time
/// flow via export/import). When both sides edit the same class after the
/// last shared import, the newer edit wins and the losing local version is
/// preserved under `conflicts/` as `conflict_<table>_<uuid>_<at>.json` with
/// `{local, incoming}`. The second test is the control: a one-sided edit
/// converges with no conflict snapshot.
void main() {
  testWidgets('concurrent edits keep the newer row and preserve a conflict',
      (tester) async {
    final folder = (await tester.runAsync(
      () => Directory.systemTemp.createTemp('e2e-sync-conflict'),
    ))!;
    final base1 = (await tester.runAsync(
      () => Directory.systemTemp.createTemp('e2e-sync-conflict-s1'),
    ))!;
    final base2 = (await tester.runAsync(
      () => Directory.systemTemp.createTemp('e2e-sync-conflict-s2'),
    ))!;
    final db1 = AppDatabase(NativeDatabase.memory());
    final db2 = AppDatabase(NativeDatabase.memory());
    try {
      await tester.runAsync(() async {
        await SettingsRepository(db1).setDataFolder(folder.path);
        await SettingsRepository(db2).setDataFolder(folder.path);

        final id1 = await ClassRepository(db1).create(
          ClassesCompanion.insert(name: 'Math', colorValue: 0xFF4F6BED),
        );
        final seed = await ClassRepository(db1).byId(id1);
        final uuid = seed.uuid;
        expect(uuid, isNotEmpty);

        await DataFolderService(db1, null, base1).exportData();
        final firstImport =
            await DataFolderService(db2, null, base2).importData();
        expect(firstImport.error, isNull);
        final lastImport =
            await SettingsRepository(db2).dataLastImportAt() ?? 0;
        expect(lastImport, greaterThan(0));

        // Both sides edit the same row after the shared import. Explicit
        // stamps keep the ordering deterministic: the folder version is
        // strictly newer than the local edit.
        await db2.customStatement(
          'UPDATE classes SET name = ?, updated_at = ? WHERE uuid = ?',
          ['Local Edit', lastImport + 60000, uuid],
        );
        await db1.customStatement(
          'UPDATE classes SET name = ?, updated_at = ? WHERE uuid = ?',
          ['Incoming Edit', lastImport + 120000, uuid],
        );

        await DataFolderService(db1, null, base1).exportData();
        final result = await DataFolderService(db2, null, base2).importData();
        expect(result.error, isNull);
        expect(result.conflictsPreserved, 1);
        expect(await SettingsRepository(db2).dataLastConflicts(), 1);

        // Newer wins in the database.
        final after = (await ClassRepository(db2).all())
            .singleWhere((c) => c.uuid == uuid);
        expect(after.name, 'Incoming Edit');
        expect(after.updatedAt, lastImport + 120000);

        // The losing local version is preserved on disk.
        final conflictsDir =
            Directory('${folder.path}/${DataFolderService.conflictsDir}');
        expect(conflictsDir.existsSync(), isTrue);
        final files = conflictsDir
            .listSync()
            .whereType<File>()
            .where((f) => f.path.endsWith('.json'))
            .toList();
        expect(files, hasLength(1));
        expect(
          files.single.path.split('/').last,
          startsWith('conflict_classes_'),
        );
        final payload =
            jsonDecode(files.single.readAsStringSync()) as Map<String, dynamic>;
        expect(payload['table'], 'classes');
        expect(payload['uuid'], uuid);
        expect((payload['local'] as Map)['name'], 'Local Edit');
        expect((payload['incoming'] as Map)['name'], 'Incoming Edit');
      });
    } finally {
      await tester.runAsync(() => db1.close());
      await tester.runAsync(() => db2.close());
      await tester.runAsync(() => folder.delete(recursive: true));
      await tester.runAsync(() => base1.delete(recursive: true));
      await tester.runAsync(() => base2.delete(recursive: true));
    }
  });

  testWidgets('sequential edit converges without a conflict file',
      (tester) async {
    final folder = (await tester.runAsync(
      () => Directory.systemTemp.createTemp('e2e-sync-noconflict'),
    ))!;
    final base1 = (await tester.runAsync(
      () => Directory.systemTemp.createTemp('e2e-sync-noconflict-s1'),
    ))!;
    final base2 = (await tester.runAsync(
      () => Directory.systemTemp.createTemp('e2e-sync-noconflict-s2'),
    ))!;
    final db1 = AppDatabase(NativeDatabase.memory());
    final db2 = AppDatabase(NativeDatabase.memory());
    try {
      await tester.runAsync(() async {
        await SettingsRepository(db1).setDataFolder(folder.path);
        await SettingsRepository(db2).setDataFolder(folder.path);

        final id1 = await ClassRepository(db1).create(
          ClassesCompanion.insert(name: 'Math', colorValue: 0xFF4F6BED),
        );
        final uuid = (await ClassRepository(db1).byId(id1)).uuid;

        await DataFolderService(db1, null, base1).exportData();
        expect(
          (await DataFolderService(db2, null, base2).importData()).error,
          isNull,
        );

        // Only one side edits, then exports; the peer adopts it cleanly.
        final row =
            (await ClassRepository(db1).all()).singleWhere((c) => c.uuid == uuid);
        await ClassRepository(db1).update(row.copyWith(name: 'Maths'));
        await DataFolderService(db1, null, base1).exportData();
        final result = await DataFolderService(db2, null, base2).importData();
        expect(result.error, isNull);
        expect(result.rowsUpserted, greaterThan(0));
        expect(result.conflictsPreserved, 0);
        expect(
          (await ClassRepository(db2).all()).singleWhere((c) => c.uuid == uuid).name,
          'Maths',
        );

        final conflictsDir =
            Directory('${folder.path}/${DataFolderService.conflictsDir}');
        final leftovers = conflictsDir.existsSync()
            ? conflictsDir
                .listSync()
                .whereType<File>()
                .where((f) => f.path.endsWith('.json'))
                .toList()
            : <File>[];
        expect(leftovers, isEmpty);
      });
    } finally {
      await tester.runAsync(() => db1.close());
      await tester.runAsync(() => db2.close());
      await tester.runAsync(() => folder.delete(recursive: true));
      await tester.runAsync(() => base1.delete(recursive: true));
      await tester.runAsync(() => base2.delete(recursive: true));
    }
  });
}
