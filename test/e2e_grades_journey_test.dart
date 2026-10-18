import 'package:chronicle/data/database.dart';
import 'package:chronicle/data/repositories.dart';
import 'package:chronicle/data/tables.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'e2e_harness.dart';

/// A grade recorded through the exam editor UI must flow to the grades
/// screen (reachable from the tasks appbar) with its score and GPA.
void main() {
  testWidgets('grade recorded in UI flows to grades GPA', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    await tester.runAsync(() async {
      final classId = await seedClassToday(ClassRepository(db), 'History');
      await TaskRepository(db).create(
        TasksCompanion.insert(
          title: 'Midterm',
          classId: Value(classId),
          type: const Value(TaskKind.exam),
          dueDate: Value(todayIso()),
        ),
      );
    });
    await bootApp(tester, db);

    await goTab(tester, Icons.checklist_outlined);
    expect(find.text('Midterm'), findsWidgets);

    // Open the exam editor the same way a user does: by tapping the task.
    final midterm = find.text('Midterm').first;
    await tester.ensureVisible(midterm);
    await tester.pumpAndSettle();
    await tester.tap(midterm);
    await tester.pumpAndSettle();
    await pumpForAsync(tester);

    // Record the grade through the exam result section (copied from the
    // screen-level 'Exam editor records a grade' interaction).
    final scoreField = find.widgetWithText(TextFormField, 'Score');
    await tester.ensureVisible(scoreField);
    await tester.pumpAndSettle();
    await tester.enterText(scoreField, '85');
    final gradeSave = find.text('Save');
    await tester.ensureVisible(gradeSave);
    await tester.pumpAndSettle();
    await tester.tap(gradeSave);
    await tester.pumpAndSettle();
    await pumpForAsync(tester);

    final grades = await tester.runAsync(() => db.select(db.grades).get());
    expect(grades, hasLength(1));
    expect(grades!.single.score, 85);

    // Back to the tasks list, then to the grades screen via the appbar.
    // (Fullscreen-dialog editors show a Close button, not Back.)
    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();
    await pumpForAsync(tester);
    expect(find.text('Midterm'), findsWidgets);

    await tester.tap(find.byIcon(Icons.grade_outlined));
    await tester.pumpAndSettle();
    await pumpForAsync(tester);
    expect(find.text('Midterm'), findsWidgets);
    expect(find.textContaining('85.0 / 100.0'), findsOneWidget);
    expect(find.text('3.00'), findsOneWidget);

    await shutdownApp(tester, db);
  });
}
