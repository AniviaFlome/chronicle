import 'package:chronicle/data/database.dart';
import 'package:chronicle/data/repositories.dart';
import 'package:chronicle/screens/occurrence_tile.dart';
import 'package:chronicle/screens/xtra_dialog.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'e2e_harness.dart';

/// An xtra event created through the UI must surface on the dashboard today
/// list and on today's calendar column, stay editable from the calendar tile,
/// and disappear from both surfaces after deletion.
///
/// The dashboard itself exposes no add-xtra affordance (its xtra section
/// only edits existing events), so the add flow runs through the calendar
/// AppBar action; the assertions then pin the event to both surfaces.
void main() {
  testWidgets('xtra event added on dashboard surfaces on calendar', (
    tester,
  ) async {
    final db = AppDatabase(NativeDatabase.memory());
    await tester.runAsync(
      () => seedClassToday(ClassRepository(db), 'Physics'),
    );
    await bootApp(tester, db);

    // Dashboard is the initial route.
    expect(find.text('Physics'), findsWidgets);

    await goTab(tester, Icons.calendar_month_outlined);
    await tester.tap(find.byTooltip('Add event'));
    await tester.pumpAndSettle();
    expect(find.text('Add event'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Title (sport, appointment, club…)'),
      'Dentist',
    );
    // Pick a start time, accepting the offered 9:00 AM. The end stays
    // unset (the dialog allows it), which keeps the save validation
    // deterministic; the event is still timed.
    final dialog = find.widgetWithText(AlertDialog, 'Add event');
    await tester.tap(
      find.descendant(of: dialog, matching: find.text('All day')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    await pumpForAsync(tester);

    // Surfaces in the dashboard today list.
    await goTab(tester, Icons.dashboard_outlined);
    await tester.scrollUntilVisible(find.text('Dentist'), 200);
    expect(find.text('Dentist'), findsOneWidget);

    // And on today's calendar column. Both list and grid views stay
    // mounted in an IndexedStack (which finders treat as onstage), so
    // scope to the list-view XtraTile; the grid block shows the title too.
    // ensureVisible (not scrollUntilVisible) handles the nested
    // horizontal-inside-vertical scrollers.
    await goTab(tester, Icons.calendar_month_outlined);
    await tester.ensureVisible(find.byType(XtraTile));
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byType(XtraTile),
        matching: find.text('Dentist'),
      ),
      findsOneWidget,
    );

    // Tap the calendar tile to open the edit dialog and rename.
    await tester.tap(find.byType(XtraTile));
    await tester.pumpAndSettle();
    expect(find.text('Edit event'), findsOneWidget);
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Title (sport, appointment, club…)'),
      'Dentist follow-up',
    );
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    await pumpForAsync(tester);

    await goTab(tester, Icons.dashboard_outlined);
    await tester.scrollUntilVisible(find.text('Dentist follow-up'), 200);
    expect(find.text('Dentist follow-up'), findsOneWidget);
    expect(find.text('Dentist'), findsNothing);

    // Delete from the calendar edit dialog (confirm uses a FilledButton,
    // the edit action a TextButton, so the two Deletes stay distinct).
    await goTab(tester, Icons.calendar_month_outlined);
    await tester.ensureVisible(find.byType(XtraTile));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(XtraTile));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Delete'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();
    await pumpForAsync(tester);

    final remaining = await tester.runAsync(
      () => db.select(db.xtraEvents).get(),
    );
    expect(remaining, isEmpty);

    await goTab(tester, Icons.dashboard_outlined);
    expect(find.text('Dentist follow-up'), findsNothing);

    // Bring today's column into view so the absence assertion is
    // meaningful (a lazily unbuilt column would pass trivially).
    await goTab(tester, Icons.calendar_month_outlined);
    await tester.ensureVisible(find.byType(OccurrenceTile));
    await tester.pumpAndSettle();
    expect(find.byType(XtraTile), findsNothing);

    await shutdownApp(tester, db);
  });
}
