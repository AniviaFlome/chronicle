import 'dart:io';

import 'package:chronicle/data/database.dart';
import 'package:chronicle/data/repositories.dart';
import 'package:chronicle/services/data_folder.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// The documented one-device-at-a-time flow: export on the first database,
/// import on a fresh second one, and the class (with its sync identity)
/// must arrive intact.
void main() {
  testWidgets('export then import moves a class to a fresh database', (
    tester,
  ) async {
    final folder = (await tester.runAsync(
      () => Directory.systemTemp.createTemp('e2e-sync-folder'),
    ))!;
    final base1 = (await tester.runAsync(
      () => Directory.systemTemp.createTemp('e2e-sync-st1'),
    ))!;
    final base2 = (await tester.runAsync(
      () => Directory.systemTemp.createTemp('e2e-sync-st2'),
    ))!;
    final db1 = AppDatabase(NativeDatabase.memory());
    final db2 = AppDatabase(NativeDatabase.memory());
    try {
      await tester.runAsync(() async {
        await SettingsRepository(db1).setDataFolder(folder.path);
        final id = await ClassRepository(db1).create(
          ClassesCompanion.insert(name: 'SyncMath', colorValue: 0xFF4F6BED),
        );
        final before = await ClassRepository(db1).byId(id);

        await DataFolderService(db1, null, base1).exportData();
        expect(
          File('${folder.path}/manifest.json').existsSync(),
          isTrue,
        );
        expect(
          File('${folder.path}/classes.json').readAsStringSync(),
          contains('SyncMath'),
        );

        await SettingsRepository(db2).setDataFolder(folder.path);
        await DataFolderService(db2, null, base2).importData();
        final rows = await db2.select(db2.classes).get();
        final match = rows.where((c) => c.name == 'SyncMath').toList();
        expect(match, hasLength(1));
        expect(match.single.uuid, before.uuid);
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
