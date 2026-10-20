import 'dart:convert';
import 'dart:io';

import 'package:chronicle/data/database.dart';
import 'package:chronicle/data/repositories.dart';
import 'package:chronicle/services/data_folder.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// The export lock (see DataFolderService.exportLockFile): fresh locks make
/// auto-import skip its round; stale/missing/corrupt ones never block.
/// Manual imports bypass the gate on purpose.
void main() {
  group('export lock', () {
    testWidgets('fresh lock reads in-progress, stale/missing do not', (
      tester,
    ) async {
      await tester.runAsync(() async {
        final folder = await Directory.systemTemp.createTemp('fs-lock');
        final base = await Directory.systemTemp.createTemp('fs-lock-st');
        final db = AppDatabase(NativeDatabase.memory());
        try {
          final service = DataFolderService(db, null, base);
          final lock = File('${folder.path}/export.lock');
          expect(await service.exportInProgress(folder), isFalse);

          await lock.writeAsString(
            jsonEncode({
              'startedAt': DateTime.now().millisecondsSinceEpoch,
            }),
          );
          expect(await service.exportInProgress(folder), isTrue);

          await lock.writeAsString(
            jsonEncode({
              'startedAt':
                  DateTime.now().millisecondsSinceEpoch -
                  DataFolderService.exportLockStaleMs -
                  1000,
            }),
          );
          expect(await service.exportInProgress(folder), isFalse);

          await lock.writeAsString('not json');
          expect(await service.exportInProgress(folder), isFalse);

          await lock.writeAsString(jsonEncode({'nope': 1}));
          expect(await service.exportInProgress(folder), isFalse);
        } finally {
          await db.close();
          await folder.delete(recursive: true);
          await base.delete(recursive: true);
        }
      });
    });

    testWidgets('manual import proceeds despite a fresh lock', (tester) async {
      await tester.runAsync(() async {
        final folder = await Directory.systemTemp.createTemp('fs-lock-man');
        final base = await Directory.systemTemp.createTemp('fs-lock-man-st');
        final db = AppDatabase(NativeDatabase.memory());
        try {
          await SettingsRepository(db).setDataFolder(folder.path);
          final service = DataFolderService(db, null, base);
          final exported = await service.exportData();
          expect(exported.error, isNull);

          await File('${folder.path}/export.lock').writeAsString(
            jsonEncode({'startedAt': DateTime.now().millisecondsSinceEpoch}),
          );
          final result = await service.importData();
          expect(result.error, isNull);
        } finally {
          await db.close();
          await folder.delete(recursive: true);
          await base.delete(recursive: true);
        }
      });
    });
  });
}
