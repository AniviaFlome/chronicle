import 'package:chronicle/data/database.dart';
import 'package:chronicle/data/repositories.dart';
import 'package:chronicle/data/tables.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'e2e_harness.dart';

/// An exam task must show up in the tasks list, and its recorded grade
/// must render on the grades screen reachable from there.
void main() {
  testWidgets('exam task flows to the grades screen with its score', (
    tester,
  ) async {
    final db = AppDatabase(NativeDatabase.memory());
    await tester.runAsync(() async {
      final classId = await seedClassToday(ClassRepository(db), 'History');
      final examId = await TaskRepository(db).create(
        TasksCompanion.insert(
          title: 'Midterm',
          classId: Value(classId),
          type: const Value(TaskKind.exam),
          dueDate: Value(todayIso()),
        ),
      );
      await GradeRepository(db).record(
        GradesCompanion.insert(
          examTaskId: examId,
          score: 85,
          date: todayIso(),
        ),
      );
    });
    await bootApp(tester, db);

    await goTab(tester, Icons.checklist_outlined);
    expect(find.text('Midterm'), findsWidgets);

    await tester.tap(find.byIcon(Icons.grade_outlined));
    await tester.pumpAndSettle();
    await pumpForAsync(tester);
    expect(find.text('Midterm'), findsWidgets);
    expect(find.textContaining('85.0 / 100.0'), findsOneWidget);

    await shutdownApp(tester, db);
  });
}
