import 'dart:io';

import 'package:chronicle/data/database.dart';
import 'package:chronicle/data/repositories.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'e2e_harness.dart';

/// Class attachments end to end: a seeded file row renders in the class
/// editor, survives an app restart against the same database file, and a
/// UI delete removes both the row and the bytes on disk.
///
/// NOTE: the add path is intentionally not driven through the picker UI.
/// `ClassFilesService.pickAndSave` calls the static `FilePicker.pickFiles`
/// with no test seam, so no fake can feed the picker. The seeded row covers
/// the same list/delete code the picker feeds into.
void main() {
  testWidgets('attached file listed, survives restart, deletes cleanly', (
    tester,
  ) async {
    final tmp = (await tester.runAsync(
      () => Directory.systemTemp.createTemp('e2e-class-files'),
    ))!;
    final file = File('${tmp.path}/chronicle.db');
    var db = AppDatabase(NativeDatabase(file));
    try {
      late final int classId;
      late final String storedPath;
      await tester.runAsync(() async {
        classId = await seedClassToday(ClassRepository(db), 'Physics');
        final bytes = File('${tmp.path}/syllabus.pdf');
        await bytes.writeAsString('syllabus-bytes');
        storedPath = bytes.path;
        await ClassFileRepository(db).create(
          ClassFilesCompanion.insert(
            classId: classId,
            fileName: 'syllabus.pdf',
            storedPath: storedPath,
            sizeBytes: const Value(14),
          ),
        );
      });

      Finder editorScroll() {
        // The editor tree holds many horizontal Scrollables (chip rows)
        // plus the root vertical ListView: filter to vertical and take the
        // document-first one, which is the root list that owns the Files
        // section. scrollUntilVisible requires exactly one match.
        final title = find.descendant(
          of: find.byType(AppBar),
          matching: find.text('Edit class'),
        );
        final scaffold = find.ancestor(
          of: title,
          matching: find.byType(Scaffold),
        );
        return find
            .descendant(
              of: scaffold,
              matching: find.byWidgetPredicate(
                (w) =>
                    w is Scrollable &&
                    w.axisDirection == AxisDirection.down,
              ),
            )
            .first;
      }

      Future<void> openEditor() async {
        await goTab(tester, Icons.school_outlined);
        await tester.tap(find.text('Physics'));
        await tester.pumpAndSettle();
        await pumpForAsync(tester);
        expect(find.text('Edit class'), findsOneWidget);
      }

      await bootApp(tester, db);
      await openEditor();
      await tester.scrollUntilVisible(
        find.text('Files'),
        400,
        scrollable: editorScroll(),
      );
      await tester.pumpAndSettle();
      expect(find.text('syllabus.pdf'), findsOneWidget);

      // Same database file, fresh app: the attachment is still listed.
      db = await restartApp(tester, db, file);
      await openEditor();
      await tester.scrollUntilVisible(
        find.text('Files'),
        400,
        scrollable: editorScroll(),
      );
      await tester.pumpAndSettle();
      expect(find.text('syllabus.pdf'), findsOneWidget);

      // Delete in the UI with confirmation: row and bytes go away.
      await tester.scrollUntilVisible(
        find.byTooltip('Delete file'),
        200,
        scrollable: editorScroll(),
      );
      await tester.tap(find.byTooltip('Delete file'));
      await tester.pumpAndSettle();
      expect(find.text('Delete file?'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
      // The confirm tap fires repo.delete from the FakeAsync zone: a
      // multi-step drift transaction with File IO hops. Each hop needs
      // real time to complete plus a pump to deliver the completion, so
      // interleave runAsync delays and pumps until the panel empties. A
      // single pumpAndSettle/pumpForAsync cannot walk it to completion,
      // and any later drift query would queue behind the open transaction.
      for (var i = 0;
          i < 40 && find.text('No files yet.').evaluate().isEmpty;
          i++) {
        await tester.runAsync(
          () => Future.delayed(const Duration(milliseconds: 200)),
        );
        await tester.pump();
      }
      await tester.pumpAndSettle();
      expect(find.text('syllabus.pdf'), findsNothing);
      expect(find.text('No files yet.'), findsOneWidget);
      expect(
        await tester.runAsync(() => ClassFileRepository(db).forClass(classId)),
        isEmpty,
      );
      expect(await tester.runAsync(() => File(storedPath).exists()), isFalse);

      await shutdownApp(tester, db);
    } finally {
      await tester.runAsync(() => tmp.delete(recursive: true));
    }
  });
}
