import 'package:chronicle/data/database.dart';
import 'package:chronicle/data/repositories.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'e2e_harness.dart';

/// Full-app task lifecycle: create a task through the editor UI (title +
/// step + reminder + due date picked in the UI), then complete a seeded
/// task through the list UI.
void main() {
  testWidgets('task created in UI appears with steps and reminder', (
    tester,
  ) async {
    final db = AppDatabase(NativeDatabase.memory());
    await bootApp(tester, db);

    await goTab(tester, Icons.checklist_outlined);
    expect(find.text('No tasks here'), findsOneWidget);

    await tester.tap(find.widgetWithIcon(FloatingActionButton, Icons.add));
    await tester.pumpAndSettle();
    await pumpForAsync(tester);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Title'),
      'E2E worksheet',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'New step'),
      'Part 1',
    );
    await tester.tap(find.byTooltip('Add step'));
    await tester.pumpAndSettle();
    expect(find.text('Part 1'), findsOneWidget);

    // Queue a reminder while there is still no due date (allowed in the
    // form; saving without a due date would be rejected).
    await tester.ensureVisible(find.text('1 hour before'));
    await tester.tap(find.text('1 hour before'));
    await tester.pumpAndSettle();

    // Pick the due date: accept the day the picker offers (today).
    await tester.ensureVisible(find.text('Not set').first);
    await tester.tap(find.text('Not set').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await pumpForAsync(tester);

    await tester.ensureVisible(find.text('Save task'));
    await tester.tap(find.text('Save task'));
    await tester.pumpAndSettle();
    await pumpForAsync(tester);

    // Back on the list: the new task shows its title and step count.
    expect(find.text('E2E worksheet'), findsWidgets);
    expect(find.textContaining('0/1 steps'), findsOneWidget);

    final tasks = await tester.runAsync(() => db.select(db.tasks).get());
    expect(tasks, hasLength(1));
    expect(tasks!.single.title, 'E2E worksheet');
    expect(tasks.single.dueDate, isNotNull);
    final subs = await tester.runAsync(() => db.select(db.subtasks).get());
    expect(subs, hasLength(1));
    expect(subs!.single.title, 'Part 1');
    final reminders = await tester.runAsync(
      () => db.select(db.taskReminders).get(),
    );
    expect(reminders, hasLength(1));
    expect(reminders!.single.offsetMinutes, 60);
    expect(reminders.single.taskId, tasks.single.id);

    await shutdownApp(tester, db);
  });

  testWidgets('completing a task marks it done', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    await tester.runAsync(() async {
      await TaskRepository(db).create(
        TasksCompanion.insert(title: 'Buy milk'),
      );
    });
    await bootApp(tester, db);

    await goTab(tester, Icons.checklist_outlined);
    expect(find.text('Buy milk'), findsOneWidget);

    await tester.tap(find.byType(Checkbox).first);
    await tester.pumpAndSettle();
    await pumpForAsync(tester);

    // Done tasks are hidden by the default filter.
    expect(find.text('No tasks here'), findsOneWidget);

    // Reveal done tasks: the completed task renders under "Done".
    await tester.ensureVisible(find.text('Hide done'));
    await tester.tap(find.text('Hide done'));
    await tester.pumpAndSettle();
    await pumpForAsync(tester);
    expect(find.text('Buy milk'), findsOneWidget);
    expect(find.text('Done'), findsOneWidget);

    final tasks = await tester.runAsync(() => db.select(db.tasks).get());
    expect(tasks, hasLength(1));
    expect(tasks!.single.isDone, isTrue);

    await shutdownApp(tester, db);
  });
}
