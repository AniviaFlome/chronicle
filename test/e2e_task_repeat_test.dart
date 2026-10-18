import 'package:chronicle/data/database.dart';
import 'package:chronicle/data/repositories.dart';
import 'package:chronicle/data/tables.dart';
import 'package:chronicle/utils/time_format.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'e2e_harness.dart';

/// UI loop for repeating tasks (the date-arithmetic itself is covered by
/// unit tests): completing a daily repeating task in the tasks list must
/// spawn the next instance with tomorrow's due date.
void main() {
  testWidgets('completing a repeating task spawns the next instance', (
    tester,
  ) async {
    final db = AppDatabase(NativeDatabase.memory());
    final today = todayIso();
    final tomorrow = isoFromDateTime(shiftDays(DateTime.now(), 1));
    await tester.runAsync(() async {
      await TaskRepository(db).create(
        TasksCompanion.insert(
          title: 'Water plants',
          dueDate: Value(today),
          repeatKind: const Value(RepeatKind.daily),
        ),
      );
    });
    await bootApp(tester, db);

    await goTab(tester, Icons.checklist_outlined);
    expect(find.text('Water plants'), findsOneWidget);

    await tester.tap(find.byType(Checkbox).first);
    await tester.pumpAndSettle();
    await pumpForAsync(tester);

    // The original is done (hidden by the filter); the spawned instance
    // stays visible with the next due date.
    expect(find.text('Water plants'), findsOneWidget);
    expect(find.textContaining(tomorrow), findsOneWidget);

    final tasks = await tester.runAsync(() => db.select(db.tasks).get());
    expect(tasks, hasLength(2));
    final done = tasks!.where((t) => t.isDone).toList();
    final open = tasks.where((t) => !t.isDone).toList();
    expect(done, hasLength(1));
    expect(open, hasLength(1));
    expect(open.single.title, 'Water plants');
    expect(open.single.dueDate, tomorrow);
    expect(open.single.repeatKind, RepeatKind.daily);

    await shutdownApp(tester, db);
  });
}
