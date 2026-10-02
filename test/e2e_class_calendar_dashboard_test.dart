import 'package:chronicle/data/database.dart';
import 'package:chronicle/data/repositories.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'e2e_harness.dart';

/// A class created in the database must surface on every surface that
/// renders today's schedule, and the occurrence sheet's mark-absent flow
/// must write a real absence row.
void main() {
  testWidgets('class appears on dashboard, calendar and classes screens', (
    tester,
  ) async {
    final db = AppDatabase(NativeDatabase.memory());
    await tester.runAsync(
      () => seedClassToday(ClassRepository(db), 'Physics'),
    );
    await bootApp(tester, db);

    // Dashboard (Today).
    expect(find.text('Physics'), findsWidgets);

    await goTab(tester, Icons.calendar_month_outlined);
    expect(find.text('Physics'), findsWidgets);

    await goTab(tester, Icons.school_outlined);
    expect(find.text('Physics'), findsOneWidget);

    await shutdownApp(tester, db);
  });

  testWidgets('marking absent from the occurrence sheet sticks', (
    tester,
  ) async {
    final db = AppDatabase(NativeDatabase.memory());
    final classId = (await tester.runAsync(
      () => seedClassToday(ClassRepository(db), 'Chemistry'),
    ))!;
    await bootApp(tester, db);

    await tester.tap(find.text('Chemistry').first);
    await tester.pumpAndSettle();
    expect(find.text('Mark absent'), findsOneWidget);

    await tester.tap(find.text('Mark absent'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Reason (optional)'),
      'Sick',
    );
    await tester.tap(find.text('Save'));
    await pumpForAsync(tester);

    // UI tap wrote a real row, and the sheet now offers the inverse.
    expect(
      await tester.runAsync(
        () => AbsenceRepository(db).countForClass(classId),
      ),
      1,
    );
    expect(find.text('Mark present'), findsOneWidget);

    // Dismiss the sheet via the modal barrier, then the tile shows Absent.
    await tester.tapAt(const Offset(400, 60));
    await tester.pumpAndSettle();
    expect(find.text('Absent'), findsWidgets);

    await shutdownApp(tester, db);
  });
}
