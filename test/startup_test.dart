import 'package:chronicle/data/database.dart';
import 'package:chronicle/data/repositories.dart';
import 'package:chronicle/data/tables.dart';
import 'package:chronicle/main.dart';
import 'package:chronicle/providers.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Regression test for the startup ProviderException: the scheduler must be
/// read only after the container has finished mounting (post-frame), never
/// re-entrantly during the mount cascade.
void main() {
  testWidgets('startup runs without poisoning providers', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    final classId = (await tester.runAsync(() async {
      final repo = ClassRepository(db);
      final id = await repo.create(
        ClassesCompanion.insert(
          name: 'Math',
          colorValue: 0xFF4F6BED,
          reminderMinutes: const Value(30),
        ),
      );
      final now = DateTime.now();
      await repo.createScheduleItem(
        ScheduleItemsCompanion.insert(
          classId: id,
          dayOfWeek: now.weekday,
          startMinutes: now.hour * 60 + now.minute + 120,
          endMinutes: now.hour * 60 + now.minute + 180,
          rotation: RotationKind.weekly,
        ),
      );
      return id;
    }))!;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: const StartupRunner(
          child: MaterialApp(home: Scaffold(body: Text('boot'))),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // No exception during startup, and the scheduler stayed usable:
    // class reminders were planned and task saves still work.
    final scheduled = await tester.runAsync(
      () => SettingsRepository(db).get('scheduled_class_reminders'),
    );
    expect(scheduled, isNotNull);
    final tasks = TaskRepository(db);
    final taskId = (await tester.runAsync(
      () => tasks.create(TasksCompanion.insert(title: 'Essay')),
    ))!;
    await tester.runAsync(() => tasks.setDone(taskId, true));
    expect((await tester.runAsync(() => tasks.byId(taskId)))?.isDone, isTrue);

    // The class from setup is untouched.
    expect(
      (await tester.runAsync(() => ClassRepository(db).byId(classId)))?.name,
      'Math',
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await tester.runAsync(() => db.close());
  });
}
