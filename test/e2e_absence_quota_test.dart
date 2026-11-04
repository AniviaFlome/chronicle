import 'package:chronicle/data/database.dart';
import 'package:chronicle/data/repositories.dart';
import 'package:chronicle/utils/time_format.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'e2e_harness.dart';

/// The absences screen quota card must reflect the rows in the database,
/// live: seeding marks and adding more updates the count without a restart.
void main() {
  testWidgets('quota card tracks unexcused marks', (tester) async {
    String isoDaysFromNow(int days) =>
        isoFromDateTime(shiftDays(DateTime.now(), days));
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
          date: isoDaysFromNow(0),
          startMinutes: 540,
          endMinutes: 600,
        ),
      );
      // Class without a limit: visible in list view, never highlighted.
      await seedClassToday(ClassRepository(db), 'History');
      return id;
    }))!;
    await tester.runAsync(
      () => SettingsRepository(db).setAbsencesView('list'),
    );
    await bootApp(tester, db);

    await goTab(tester, Icons.event_busy_outlined);
    expect(find.text('Quotas'), findsOneWidget);
    expect(find.text('1 / 2 unexcused'), findsOneWidget);
    expect(find.text('No absence limit'), findsOneWidget);
    expect(find.text('History'), findsOneWidget);
    expect(find.text('0 unexcused (0 excused)'), findsOneWidget);

    await tester.runAsync(
      () => AbsenceRepository(db).mark(
        AbsencesCompanion.insert(
          classId: classId,
          date: isoDaysFromNow(7),
          startMinutes: 540,
          endMinutes: 600,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await pumpForAsync(tester);
    // Exactly at the limit: distinct at-limit state, not the over state.
    expect(find.text('2 / 2 unexcused'), findsOneWidget);
    expect(
      find.textContaining('at the limit of 2, none left'),
      findsOneWidget,
    );
    expect(find.textContaining('over the limit of 2'), findsNothing);

    // One more mark exceeds the limit: the over state takes over.
    await tester.runAsync(
      () => AbsenceRepository(db).mark(
        AbsencesCompanion.insert(
          classId: classId,
          date: isoDaysFromNow(14),
          startMinutes: 540,
          endMinutes: 600,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await pumpForAsync(tester);
    expect(find.text('3 / 2 unexcused'), findsOneWidget);
    expect(
      find.textContaining('over the limit of 2'),
      findsOneWidget,
    );

    await shutdownApp(tester, db);
  });
}
