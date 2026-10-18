import 'package:chronicle/data/database.dart';
import 'package:chronicle/data/repositories.dart';
import 'package:chronicle/utils/time_format.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'e2e_harness.dart';

/// Matrix journey: marking sessions through the week grid updates the quota
/// card and the dashboard warning, and each mark lives in exactly one week
/// (W1 = week containing the year start, Monday-start default).
void main() {
  testWidgets('matrix mark updates quota and dashboard', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    final classId = (await tester.runAsync(
      () => seedClassToday(ClassRepository(db), 'Chemistry', maxAbsences: 2),
    ))!;
    await bootApp(tester, db);

    await goTab(tester, Icons.event_busy_outlined);
    expect(find.text('Chemistry'), findsWidgets);
    expect(find.text('W1'), findsOneWidget);

    // Mark one session absent through the matrix UI: tap a visible empty
    // cell, accept the dialog unexcused.
    await tapVisibleEmptyMatrixCell(tester);
    expect(find.text('Mark absent'), findsOneWidget);
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    await pumpForAsync(tester);

    // Exactly one filled cell, in the week the absence row landed in.
    expect(find.text('1'), findsOneWidget);
    final weekLabel = filledMatrixWeek(tester);
    final check = (await tester.runAsync(() async {
      final rows = await db.select(db.absences).get();
      final years = await db.select(db.academicYears).get();
      final weekStartDay = await SettingsRepository(db).weekStartDay();
      return (
        rows: rows,
        yearStart: years.single.startDate,
        weekStartDay: weekStartDay,
      );
    }))!;
    expect(check.rows, hasLength(1));
    expect(check.rows.single.classId, classId);
    expect(check.rows.single.isExcused, isFalse);
    expect(
      weekLabel,
      'W${weekIndexOf(check.rows.single.date, check.yearStart, check.weekStartDay) + 1}',
    );

    // Slide the matrix to later weeks and back: the mark stays unique to
    // its week.
    final gridScroll = find
        .ancestor(
          of: find.text('W1'),
          matching: find.byType(SingleChildScrollView),
        )
        .first;
    await tester.drag(gridScroll, const Offset(-600, 0));
    await tester.pumpAndSettle();
    await pumpForAsync(tester);
    await tester.drag(gridScroll, const Offset(600, 0));
    await tester.pumpAndSettle();
    await pumpForAsync(tester);
    expect(find.text('1'), findsOneWidget);
    expect(filledMatrixWeek(tester), weekLabel);

    // Quota card (list view) counts the unexcused mark.
    await tester.tap(find.byTooltip('List view'));
    await tester.pumpAndSettle();
    await pumpForAsync(tester);
    expect(find.text('Quotas'), findsOneWidget);
    expect(find.text('1 / 2 unexcused'), findsOneWidget);

    // Dashboard raises the one-left quota warning.
    await goTab(tester, Icons.dashboard_outlined);
    expect(find.text('Absence warnings'), findsOneWidget);
    expect(
      find.textContaining('one left before the limit of 2'),
      findsOneWidget,
    );

    // Second session, excused this time: back to the matrix, tick another
    // empty cell with the Excused box checked.
    await goTab(tester, Icons.event_busy_outlined);
    await tester.tap(find.byTooltip('Weeks grid view'));
    await tester.pumpAndSettle();
    await pumpForAsync(tester);
    await tapVisibleEmptyMatrixCell(tester);
    expect(find.text('Mark absent'), findsOneWidget);
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Excused'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    await pumpForAsync(tester);

    // Excused marks never touch the unexcused quota: the count cell stays
    // unique and the quota card still reads 1 / 2.
    expect(find.text('1'), findsOneWidget);
    final second = await tester.runAsync(() => db.select(db.absences).get());
    expect(second, hasLength(2));
    expect(second!.where((a) => a.isExcused), hasLength(1));
    await tester.tap(find.byTooltip('List view'));
    await tester.pumpAndSettle();
    await pumpForAsync(tester);
    expect(find.text('1 / 2 unexcused'), findsOneWidget);

    await goTab(tester, Icons.dashboard_outlined);
    expect(find.text('Absence warnings'), findsOneWidget);
    expect(
      find.textContaining('one left before the limit of 2'),
      findsOneWidget,
    );

    await shutdownApp(tester, db);
  });
}

/// Taps the first on-screen empty matrix cell (the `+` placeholder). The
/// grid auto-jumps to the current week, so the tapped cell is always near
/// it; the exact week is resolved afterwards from the absence row.
Future<void> tapVisibleEmptyMatrixCell(WidgetTester tester) async {
  final adds = find.byIcon(Icons.add);
  expect(adds, findsWidgets);
  final size = tester.view.physicalSize / tester.view.devicePixelRatio;
  for (var i = 0; i < adds.evaluate().length; i++) {
    final center = tester.getCenter(adds.at(i));
    if (center.dx >= 0 &&
        center.dx <= size.width &&
        center.dy >= 0 &&
        center.dy <= size.height) {
      await tester.tap(adds.at(i));
      await tester.pumpAndSettle();
      await pumpForAsync(tester);
      return;
    }
  }
  fail('no visible empty matrix cell');
}

/// Week label (e.g. 'W9') of the single filled matrix cell, read from its
/// tooltip ('Class · W9 · 1 (tap to remove)'). Fails unless exactly one
/// filled cell exists.
String filledMatrixWeek(WidgetTester tester) {
  final labels = <String>[];
  for (final el in find.byType(Tooltip).evaluate()) {
    final message = (el.widget as Tooltip).message;
    if (message != null && message.contains('(tap to remove)')) {
      labels.add(message.split(' · ')[1]);
    }
  }
  expect(labels, hasLength(1));
  return labels.single;
}

/// 0-based week index of [isoDate] in the year starting [yearStartIso]:
/// W1 is the week containing the year start.
int weekIndexOf(String isoDate, String yearStartIso, int weekStartDay) {
  DateTime weekStartOf(DateTime d) {
    final day = DateTime(d.year, d.month, d.day);
    final diff = ((day.weekday - weekStartDay) + 7) % 7;
    return DateTime(day.year, day.month, day.day - diff);
  }

  final first = weekStartOf(DateTime.parse(yearStartIso));
  final day = DateTime.parse(isoDate);
  return daysBetween(first, weekStartOf(day)) ~/ 7;
}
