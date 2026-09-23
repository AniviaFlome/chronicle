import 'dart:io';

import 'package:chronicle/data/database.dart';
import 'package:chronicle/data/repositories.dart';
import 'package:chronicle/services/data_folder.dart';
import 'package:chronicle/services/folder_sync.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// Real-timer tests (short controller intervals) for the auto-sync
/// scheduling: debounced export on changes, manifest-gated import, and
/// the disabled toggle. Merge semantics are covered by the sync round-trip
/// tests in class_files_test.dart.
void main() {
  testWidgets('auto-export writes the folder after a change', (tester) async {
    await tester.runAsync(() async {
      final folder = await Directory.systemTemp.createTemp('fs-auto-exp');
      final base = await Directory.systemTemp.createTemp('fs-auto-st');
      final db = AppDatabase(NativeDatabase.memory());
      try {
        await SettingsRepository(db).setDataFolder(folder.path);
        final service = DataFolderService(db, null, base);
        final controller = FolderSyncController(
          service: service,
          exportDebounce: const Duration(milliseconds: 50),
          pollInterval: const Duration(hours: 1),
        );
        try {
          await controller.start();
          expect(
            File('${folder.path}/manifest.json').existsSync(),
            isFalse,
          );
          await ClassRepository(db).create(
            ClassesCompanion.insert(name: 'Math', colorValue: 1),
          );
          await Future.delayed(const Duration(milliseconds: 500));
          expect(File('${folder.path}/manifest.json').existsSync(), isTrue);
          expect(
            File('${folder.path}/classes.json').readAsStringSync(),
            contains('Math'),
          );
        } finally {
          await controller.dispose();
        }
      } finally {
        await db.close();
        await folder.delete(recursive: true);
        await base.delete(recursive: true);
      }
    });
  });

  testWidgets('no auto-export when the toggle is off', (tester) async {
    await tester.runAsync(() async {
      final folder = await Directory.systemTemp.createTemp('chronicle-fs-off');
      final base = await Directory.systemTemp.createTemp('chronicle-fs-st');
      final db = AppDatabase(NativeDatabase.memory());
      try {
        await SettingsRepository(db).setDataFolder(folder.path);
        await SettingsRepository(db).setAutoSync(false);
        final service = DataFolderService(db, null, base);
        final controller = FolderSyncController(
          service: service,
          exportDebounce: const Duration(milliseconds: 50),
          pollInterval: const Duration(hours: 1),
        );
        try {
          await controller.start();
          await ClassRepository(db).create(
            ClassesCompanion.insert(name: 'Math', colorValue: 1),
          );
          await Future.delayed(const Duration(milliseconds: 400));
          expect(
            File('${folder.path}/manifest.json').existsSync(),
            isFalse,
          );
        } finally {
          await controller.dispose();
        }
      } finally {
        await db.close();
        await folder.delete(recursive: true);
        await base.delete(recursive: true);
      }
    });
  });

  testWidgets('poll imports a peer export, then ignores own state', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final folder = await Directory.systemTemp.createTemp('chronicle-fs-im');
      final baseA = await Directory.systemTemp.createTemp('chronicle-fs-a');
      final baseB = await Directory.systemTemp.createTemp('chronicle-fs-b');
      final dbA = AppDatabase(NativeDatabase.memory());
      final dbB = AppDatabase(NativeDatabase.memory());
      try {
        await SettingsRepository(dbA).setDataFolder(folder.path);
        await SettingsRepository(dbB).setDataFolder(folder.path);
        await ClassRepository(dbA).create(
          ClassesCompanion.insert(name: 'Physics', colorValue: 1),
        );
        await DataFolderService(dbA, null, baseA).exportData();

        final serviceB = DataFolderService(dbB, null, baseB);
        final controller = FolderSyncController(
          service: serviceB,
          exportDebounce: const Duration(hours: 1),
          pollInterval: const Duration(milliseconds: 100),
        );
        try {
          // Startup import picks up the peer export.
          await controller.start();
          final names = [
            for (final c in await ClassRepository(dbB).all()) c.name,
          ];
          expect(names, contains('Physics'));
          final lastImport = await SettingsRepository(
            dbB,
          ).dataLastImportAt();
          expect(lastImport, isNotNull);
          // Later polls are no-ops: nothing new, and our own state never
          // counts as an update.
          await Future.delayed(const Duration(milliseconds: 400));
          expect(
            await SettingsRepository(dbB).dataLastImportAt(),
            lastImport,
          );
        } finally {
          await controller.dispose();
        }
      } finally {
        await dbA.close();
        await dbB.close();
        await folder.delete(recursive: true);
        await baseA.delete(recursive: true);
        await baseB.delete(recursive: true);
      }
    });
  });
}
