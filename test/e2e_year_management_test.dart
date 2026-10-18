import 'e2e_harness.dart';
import 'package:chronicle/app.dart';
import 'package:chronicle/data/database.dart';
import 'package:chronicle/data/repositories.dart';
import 'package:chronicle/main.dart';
import 'package:chronicle/providers.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Drags the route's list until [target] is laid out (settings and the
/// class form are lazy lists, so off-screen rows may not exist yet).
/// Mirrors the drag loop in test/e2e_class_lifecycle_test.dart.
Future<void> dragTo(
  WidgetTester tester,
  Finder target,
  Offset delta,
) async {
  for (var i = 0; i < 15 && target.evaluate().isEmpty; i++) {
    await tester.drag(find.byType(ListView).first, delta);
    await tester.pumpAndSettle();
  }
  await tester.pumpAndSettle();
}

const _up = Offset(0, -400);

/// Reboots the full app on the same database without pumping a frame on
/// the old tree first, then lands back on settings.
///
/// Required after showYearDialog's Save: the dialog future completes at pop
/// time (pre-animation) and the app continuation persists the year and
/// disposes the dialog's controllers before the next frame, so any pumped
/// frame would rebuild the animating-out dialog against disposed
/// controllers (framework exceptions, frozen providers). Unmounting first
/// sidesteps those frames; the reboot additionally proves the year
/// persisted.
Future<void> rebootToSettings(WidgetTester tester, AppDatabase db) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pumpAndSettle();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
      child: const StartupRunner(child: ChronicleApp()),
    ),
  );
  await tester.pumpAndSettle();
  await pumpForAsync(tester);
  await goTab(tester, Icons.settings_outlined);
}

/// Creates one academic year through the real UI: settings YearsSection
/// add button -> showYearDialog (name + Starts/Ends date pickers) -> Save.
/// Today's date is accepted for both ends.
Future<void> createYearViaUi(
  WidgetTester tester,
  AppDatabase db,
  String name,
) async {
  final addButton = find.byTooltip('Add academic year');
  await dragTo(tester, addButton, _up);
  await tester.tap(addButton);
  await tester.pumpAndSettle();

  final dialog = find.byType(AlertDialog);
  await tester.enterText(
    find.descendant(
      of: dialog,
      matching: find.widgetWithText(TextFormField, 'Name'),
    ),
    name,
  );
  // Starts row first (both date buttons read 'Pick' until set).
  await tester.tap(
    find.descendant(of: dialog, matching: find.text('Pick')).first,
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('OK'));
  await tester.pumpAndSettle();
  await tester.tap(find.descendant(of: dialog, matching: find.text('Pick')));
  await tester.pumpAndSettle();
  await tester.tap(find.text('OK'));
  await tester.pumpAndSettle();
  await tester.tap(
    find.descendant(of: dialog, matching: find.text('Save')),
  );
  await rebootToSettings(tester, db);
  expect(find.text(name), findsOneWidget);
}

/// Sets the active year through the real UI: taps the year radio in the
/// settings YearsSection and waits for the change to persist.
Future<void> setActiveYearViaUi(
  WidgetTester tester,
  AppDatabase db,
  String name,
) async {
  await dragTo(tester, find.text(name), _up);
  await tester.tap(find.text(name));
  await tester.pumpAndSettle();
  await pumpForAsync(tester);
  final years =
      await tester.runAsync(() => db.select(db.academicYears).get()) ?? [];
  final year = years.firstWhere((y) => y.name == name);
  expect(
    await tester.runAsync(
      () => SettingsRepository(db).watchActiveYearId().first,
    ),
    year.id,
  );
}

void main() {
  testWidgets('years scope the classes list', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    await bootApp(tester, db);

    // Create year A in the UI and make it active there too.
    await goTab(tester, Icons.settings_outlined);
    await createYearViaUi(tester, db, 'E2E Year A');
    await setActiveYearViaUi(tester, db, 'E2E Year A');

    // Create a class in the UI form and assign it to year A.
    await goTab(tester, Icons.school_outlined);
    await tester.tap(
      find.widgetWithIcon(FloatingActionButton, Icons.add),
    );
    await tester.pumpAndSettle();
    await pumpForAsync(tester);
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Class name'),
      'YearScoped',
    );
    await pickClassTimes(tester, db);
    // The form defaults to the active year: the dropdown already shows it.
    final yearField = find.ancestor(
      of: find.text('Academic year'),
      matching: find.byType(DropdownButtonFormField<int?>),
    );
    expect(
      find.descendant(of: yearField, matching: find.text('E2E Year A')),
      findsOneWidget,
    );
    // Explicitly (re-)assign via the dropdown: open it and pick the year.
    // Scoped to the open menu: the settings radio behind shows the name too.
    await tester.tap(yearField);
    await tester.pumpAndSettle();
    await tester.tap(
      find
          .descendant(
            of: find.byType(DropdownMenuItem<int?>),
            matching: find.text('E2E Year A'),
          )
          .first,
    );
    await tester.pumpAndSettle();
    await dragTo(tester, find.text('Save class'), _up);
    await tester.tap(find.text('Save class'));
    await tester.pumpAndSettle();
    await pumpForAsync(tester);
    expect(find.text('YearScoped'), findsOneWidget);

    // Year-less class seeded via repo stays visible under a year filter.
    await tester.runAsync(
      () => ClassRepository(db).create(
        ClassesCompanion.insert(
          name: 'Loose',
          colorValue: 0xFFFF7043,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await pumpForAsync(tester);
    expect(find.text('YearScoped'), findsOneWidget);
    expect(find.text('Loose'), findsOneWidget);

    // Create year B in the UI and switch the active year to it there.
    await goTab(tester, Icons.settings_outlined);
    await createYearViaUi(tester, db, 'E2E Year B');
    await setActiveYearViaUi(tester, db, 'E2E Year B');

    // The year-A class disappears; the year-less class stays.
    await goTab(tester, Icons.school_outlined);
    expect(find.text('YearScoped'), findsNothing);
    expect(find.text('Loose'), findsOneWidget);

    await shutdownApp(tester, db);
  });
}
