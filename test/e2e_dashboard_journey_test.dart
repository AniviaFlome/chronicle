import 'package:chronicle/data/database.dart';
import 'package:chronicle/data/repositories.dart';
import 'package:chronicle/data/tables.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'e2e_harness.dart';

/// The dashboard must aggregate one seeded day: the class, its quota
/// warning, a due-today task and a timed xtra event. Navigation to the
/// absences tab and back is by rail tap — the warning cards themselves
/// are display-only. No dialog interactions here (covered by the xtra
/// journey test).
void main() {
  testWidgets('dashboard aggregates a seeded day', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    await tester.runAsync(() async {
      final classId = await seedClassToday(
        ClassRepository(db),
        'Algebra',
        maxAbsences: 2,
      );
      // One unexcused mark against a limit of 2: "one left" warning.
      await AbsenceRepository(db).mark(
        AbsencesCompanion.insert(
          classId: classId,
          date: todayIso(),
          startMinutes: 540,
          endMinutes: 600,
        ),
      );
      await TaskRepository(db).create(
        TasksCompanion.insert(
          title: 'Write essay draft',
          type: const Value(TaskKind.homework),
          dueDate: Value(todayIso()),
        ),
      );
      await XtraRepository(db).create(
        XtraEventsCompanion.insert(
          title: 'Gym session',
          date: todayIso(),
          startMinutes: const Value(780),
          endMinutes: const Value(840),
        ),
      );
      await SettingsRepository(db).setAbsencesView('list');
    });
    await bootApp(tester, db);

    // Dashboard is the initial route: quota warning, class, xtra, task.
    await tester.scrollUntilVisible(find.text('Absence warnings'), 200);
    expect(find.text('Absence warnings'), findsOneWidget);
    expect(
      find.textContaining('one left before the limit of 2'),
      findsOneWidget,
    );
    expect(find.text('Algebra'), findsWidgets);
    await tester.scrollUntilVisible(find.text('Gym session'), 200);
    expect(find.text('Gym session'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Write essay draft'), 200);
    expect(find.text('Write essay draft'), findsOneWidget);

    await goTab(tester, Icons.event_busy_outlined);
    expect(find.text('Quotas'), findsOneWidget);
    expect(find.text('1 / 2 unexcused'), findsOneWidget);

    await goTab(tester, Icons.dashboard_outlined);
    expect(find.text('Algebra'), findsWidgets);

    await shutdownApp(tester, db);
  });
}
