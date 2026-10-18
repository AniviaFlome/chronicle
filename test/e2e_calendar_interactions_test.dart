import 'dart:io';

import 'package:chronicle/data/database.dart';
import 'package:chronicle/data/repositories.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'e2e_harness.dart';

/// Calendar interactions across tabs and a restart: the grid view choice
/// and the current week survive reopening, and a mark made in the
/// occurrence sheet still warns on the dashboard afterwards.
void main() {
  testWidgets('calendar view and week survive restart, marks stick',
      (tester) async {
    final tmp = (await tester.runAsync(
      () => Directory.systemTemp.createTemp('e2e-cal'),
    ))!;
    final file = File('${tmp.path}/chronicle.db');
    var db = AppDatabase(NativeDatabase(file));
    try {
      await tester.runAsync(
        () => seedClassToday(ClassRepository(db), 'Physics', maxAbsences: 2),
      );
      await bootApp(tester, db);

      await goTab(tester, Icons.calendar_month_outlined);
      String appBarTitle() => tester
          .widget<Text>(
            find.descendant(
              of: find.byType(AppBar),
              matching: find.byType(Text),
            ),
          )
          .data!;
      final currentWeek = appBarTitle();

      // Switch to the grid in the UI.
      await tester.tap(find.byIcon(Icons.calendar_view_week_outlined));
      await tester.pumpAndSettle();
      await pumpForAsync(tester);
      expect(
        tester
            .widget<SegmentedButton<String>>(
              find.byType(SegmentedButton<String>),
            )
            .selected,
        {'grid'},
      );
      expect(find.text('Physics'), findsWidgets);

      // One week forward and back: the title moves, then returns.
      await tester.tap(find.byTooltip('Next week'));
      await tester.pumpAndSettle();
      await pumpForAsync(tester);
      expect(appBarTitle(), isNot(currentWeek));
      await tester.tap(find.byTooltip('Previous week'));
      await tester.pumpAndSettle();
      await pumpForAsync(tester);
      expect(appBarTitle(), currentWeek);

      // Mark today's occurrence absent through its sheet.
      await tester.ensureVisible(find.text('Physics').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Physics').first);
      await tester.pumpAndSettle();
      await pumpForAsync(tester);
      expect(find.text('Mark absent'), findsOneWidget);
      await tester.tap(find.text('Mark absent'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      await pumpForAsync(tester);
      expect(find.text('Unexcused absence'), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      await pumpForAsync(tester);
      expect(find.text('Unexcused absence'), findsNothing);

      // Dashboard shows the quota warning in the same session.
      await goTab(tester, Icons.dashboard_outlined);
      expect(find.text('Absence warnings'), findsOneWidget);
      expect(
        find.textContaining('one left before the limit of 2'),
        findsOneWidget,
      );

      // Restart against the same file: grid view and week survive, and the
      // mark sticks around with them.
      db = await restartApp(tester, db, file);
      await goTab(tester, Icons.calendar_month_outlined);
      expect(
        tester
            .widget<SegmentedButton<String>>(
              find.byType(SegmentedButton<String>),
            )
            .selected,
        {'grid'},
      );
      expect(appBarTitle(), currentWeek);

      await goTab(tester, Icons.dashboard_outlined);
      expect(find.text('Absence warnings'), findsOneWidget);
      expect(
        find.textContaining('one left before the limit of 2'),
        findsOneWidget,
      );

      await shutdownApp(tester, db);
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      await tester.runAsync(() => tmp.delete(recursive: true));
    }
  });
}
