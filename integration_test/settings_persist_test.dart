import 'dart:io';

import 'package:chronicle/data/database.dart';
import 'package:chronicle/data/repositories.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'e2e_harness.dart';

/// Settings must survive a database reopen, and a view choice made in the
/// UI must still be active after an app restart against the same file.
void main() {
  testWidgets('settings survive a database reopen', (tester) async {
    final tmp = await Directory.systemTemp.createTemp('e2e-settings');
    try {
      final file = File('${tmp.path}/chronicle.db');
      final db = AppDatabase(NativeDatabase(file));
      await tester.runAsync(() async {
        final settings = SettingsRepository(db);
        await settings.setCalendarView('grid');
        await settings.setDayStartMinutes(480);
        await settings.setLocaleOverride('tr');
      });
      await tester.runAsync(() => db.close());

      final db2 = AppDatabase(NativeDatabase(file));
      final settings2 = SettingsRepository(db2);
      expect(await tester.runAsync(() => settings2.calendarView()), 'grid');
      expect(
        await tester.runAsync(() => settings2.dayStartMinutes()),
        480,
      );
      expect(await tester.runAsync(() => settings2.localeOverride()), 'tr');
      await tester.runAsync(() => db2.close());
    } finally {
      await tmp.delete(recursive: true);
    }
  });

  testWidgets('calendar view survives an app restart', (tester) async {
    final tmp = await Directory.systemTemp.createTemp('e2e-restart');
    final db = AppDatabase(NativeDatabase(File('${tmp.path}/c.db')));
    try {
      await tester.runAsync(
        () => seedClassToday(ClassRepository(db), 'Physics'),
      );
      await bootApp(tester, db);
      await goTab(tester, Icons.calendar_month_outlined);

      // Switch to the grid in the UI; the choice persists to settings.
      await tester.tap(find.byIcon(Icons.calendar_view_week_outlined));
      await tester.pumpAndSettle();
      await pumpForAsync(tester);
      expect(
        await tester.runAsync(
          () => SettingsRepository(db).calendarView(),
        ),
        'grid',
      );

      // Restart the app against the same file: the grid must be active
      // without touching the switch again.
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      await bootApp(tester, db);
      await goTab(tester, Icons.calendar_month_outlined);
      final switcher = tester.widget<SegmentedButton<String>>(
        find.byType(SegmentedButton<String>),
      );
      expect(switcher.selected, {'grid'});
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      await tester.runAsync(() => db.close());
      await tmp.delete(recursive: true);
    }
  });
}
