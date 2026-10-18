import 'package:chronicle/data/database.dart';
import 'package:chronicle/data/repositories.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'e2e_harness.dart';

/// A class created through the UI must surface on the dashboard and the
/// calendar the same session — the whole point of creating it.
void main() {
  testWidgets('created class flows to dashboard and calendar', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    await bootApp(tester, db);

    await goTab(tester, Icons.school_outlined);
    await tester.tap(
      find.widgetWithIcon(FloatingActionButton, Icons.add),
    );
    await tester.pumpAndSettle();
    await pumpForAsync(tester);
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Class name'),
      'Physics',
    );
    await pickClassTimes(tester, db);
    await tester.tap(find.text('Save class'));
    await tester.pumpAndSettle();
    await pumpForAsync(tester);
    expect(find.text('Physics'), findsWidgets);

    await goTab(tester, Icons.dashboard_outlined);
    expect(find.text('Physics'), findsWidgets);

    await goTab(tester, Icons.calendar_month_outlined);
    expect(find.text('Physics'), findsWidgets);

    await shutdownApp(tester, db);
  });

  testWidgets('edited room persists and delete keeps tasks', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    final classId = await tester.runAsync(() async {
      final repo = ClassRepository(db);
      final id = await seedClassToday(repo, 'History');
      await TaskRepository(db).create(
        TasksCompanion.insert(title: 'Essay', classId: Value(id)),
      );
      return id;
    });
    expect(classId, isNonZero);
    await bootApp(tester, db);

    // Open the editor from the classes list and set a room.
    await goTab(tester, Icons.school_outlined);
    await tester.tap(find.text('History'));
    await tester.pumpAndSettle();
    await pumpForAsync(tester);
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Building'),
      'Science block',
    );
    // Existing classes show schedule/absence/files sections, so Save sits
    // below the fold: drag the form's own list until it is laid out.
    final formList = find.ancestor(
      of: find.widgetWithText(TextFormField, 'Building'),
      matching: find.byType(Scrollable),
    );
    for (var i = 0; i < 8 && find.text('Save class').evaluate().isEmpty; i++) {
      await tester.drag(formList.first, const Offset(0, -400));
      await tester.pumpAndSettle();
    }
    await tester.tap(find.text('Save class'));
    await tester.pumpAndSettle();
    await pumpForAsync(tester);

    // Reopening the editor shows the saved room.
    await tester.tap(find.text('History'));
    await tester.pumpAndSettle();
    await pumpForAsync(tester);
    expect(
      find.widgetWithText(TextFormField, 'Science block'),
      findsOneWidget,
    );

    // Cancel keeps the class; Delete removes it but keeps the task.
    await tester.tap(find.byTooltip('Delete class'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(
      await tester.runAsync(() => db.select(db.classes).get()),
      hasLength(1),
    );
    await tester.tap(find.byTooltip('Delete class'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    await pumpForAsync(tester);
    expect(await tester.runAsync(() => db.select(db.classes).get()), isEmpty);
    final tasks = await tester.runAsync(() => db.select(db.tasks).get());
    expect(tasks, hasLength(1));
    expect(tasks!.single.classId, isNull);

    await shutdownApp(tester, db);
  });
}
