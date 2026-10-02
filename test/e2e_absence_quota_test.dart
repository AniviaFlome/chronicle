import 'package:chronicle/data/database.dart';
import 'package:chronicle/data/repositories.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'e2e_harness.dart';

/// The absences screen quota card must reflect the rows in the database,
/// live: seeding marks and adding more updates the count without a restart.
void main() {
  testWidgets('quota card tracks unexcused marks', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    final classId = (await tester.runAsync(() async {
      final id = await seedClassToday(
        ClassRepository(db),
        'Biology',
        maxAbsences: 2,
      );
      await AbsenceRepository(db).mark(
        AbsencesCompanion.insert(
          classId: id,
          date: todayIso(),
          startMinutes: 540,
          endMinutes: 600,
        ),
      );
      return id;
    }))!;
    await tester.runAsync(
      () => SettingsRepository(db).setAbsencesView('list'),
    );
    await bootApp(tester, db);

    await goTab(tester, Icons.event_busy_outlined);
    expect(find.text('Quotas'), findsOneWidget);
    expect(find.text('1 / 2 unexcused'), findsOneWidget);

    await tester.runAsync(
      () => AbsenceRepository(db).mark(
        AbsencesCompanion.insert(
          classId: classId,
          date: todayIso(),
          startMinutes: 540,
          endMinutes: 600,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await pumpForAsync(tester);
    expect(find.text('2 / 2 unexcused'), findsOneWidget);

    await shutdownApp(tester, db);
  });
}
