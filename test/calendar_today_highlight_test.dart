import 'package:chronicle/data/database.dart';
import 'package:chronicle/providers.dart';
import 'package:chronicle/screens/calendar_screen.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Gives real-async database round-trips time to finish and flushes frames.
Future<void> pumpForAsync(WidgetTester tester) async {
  await tester.runAsync(
    () => Future.delayed(const Duration(milliseconds: 300)),
  );
  await tester.pumpAndSettle();
}

/// Pumps the calendar at phone width (390 < 600) so the Android
/// auto-scroll-to-today path runs. The week starts six days before today,
/// so today is always the last section (rawIdx=6) and the today-jump must
/// bring it on screen.
Future<void> pumpCalendar(
  WidgetTester tester,
  AppDatabase db, {
  required String view,
  required String orientation,
  bool startToday = true,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  final now = DateTime.now();
  final sixDaysAgo = DateTime(now.year, now.month, now.day - 6);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        calendarViewSeedProvider.overrideWithValue(view),
        calendarOrientationSeedProvider.overrideWithValue(orientation),
        // Weekday of the day six days ago: the displayed week then starts
        // there, putting today last (empty DB, so no occurrence data
        // depends on the real Monday setting).
        weekStartDayProvider.overrideWithValue(
          AsyncValue.data(sixDaysAgo.weekday),
        ),
        calendarStartTodayProvider.overrideWithValue(
          AsyncValue.data(startToday),
        ),
      ],
      child: const MaterialApp(home: CalendarScreen()),
    ),
  );
  await pumpForAsync(tester);
}

/// Asserts today's highlighted day-number header is fully on screen:
/// the today-jump ran and the reveal kept its scroll offset instead of
/// resetting to the week start.
void expectTodayVisible(WidgetTester tester, Color highlight) {
  final now = DateTime.now();
  final dayText = find.text('${now.day}');
  expect(dayText, findsOneWidget);
  final highlightBox = find.ancestor(
    of: dayText,
    matching: find.byWidgetPredicate(
      (w) =>
          w is Container &&
          w.decoration is BoxDecoration &&
          (w.decoration as BoxDecoration).color == highlight,
    ),
  );
  expect(highlightBox, findsOneWidget);
  final rect = tester.getRect(highlightBox);
  final viewport = Offset.zero & const Size(390, 844);
  expect(
    viewport.contains(rect.topLeft) && viewport.contains(rect.bottomRight),
    isTrue,
    reason: 'today header $rect is off screen in $viewport',
  );
}

/// Asserts today's highlighted header is present but NOT fully on screen:
/// with start-on-today disabled the week stays at its start.
/// (Not used for the empty vertical list: its short sections leave the
/// last day barely visible even without scrolling.)
void expectTodayOffscreen(WidgetTester tester, Color highlight) {
  final now = DateTime.now();
  final dayText = find.text('${now.day}');
  expect(dayText, findsOneWidget);
  final highlightBox = find.ancestor(
    of: dayText,
    matching: find.byWidgetPredicate(
      (w) =>
          w is Container &&
          w.decoration is BoxDecoration &&
          (w.decoration as BoxDecoration).color == highlight,
    ),
  );
  expect(highlightBox, findsOneWidget);
  final rect = tester.getRect(highlightBox);
  final viewport = Offset.zero & const Size(390, 844);
  expect(
    viewport.contains(rect.topLeft) && viewport.contains(rect.bottomRight),
    isFalse,
    reason: 'today header $rect should stay off screen in $viewport',
  );
}

Color schemeColor(WidgetTester tester, Color Function(ColorScheme) pick) {
  final ctx = tester.element(find.byType(CalendarScreen));
  return pick(Theme.of(ctx).colorScheme);
}

Future<void> closeDb(WidgetTester tester, AppDatabase db) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pumpAndSettle();
  await tester.runAsync(() => db.close());
}

void main() {
  testWidgets('horizontal list scrolls today on screen', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    await pumpCalendar(tester, db, view: 'list', orientation: 'horizontal');
    expectTodayVisible(tester, schemeColor(tester, (s) => s.primaryContainer));
    await closeDb(tester, db);
  });

  testWidgets('vertical list scrolls today on screen', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    await pumpCalendar(tester, db, view: 'list', orientation: 'vertical');
    expectTodayVisible(tester, schemeColor(tester, (s) => s.primaryContainer));
    await closeDb(tester, db);
  });

  testWidgets('horizontal grid scrolls today on screen', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    await pumpCalendar(tester, db, view: 'grid', orientation: 'horizontal');
    expectTodayVisible(tester, schemeColor(tester, (s) => s.primary));
    await closeDb(tester, db);
  });

  testWidgets('vertical grid scrolls today on screen', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    await pumpCalendar(tester, db, view: 'grid', orientation: 'vertical');
    expectTodayVisible(tester, schemeColor(tester, (s) => s.primary));
    await closeDb(tester, db);
  });

  testWidgets('disabled start-on-today leaves horizontal list at week start', (
    tester,
  ) async {
    final db = AppDatabase(NativeDatabase.memory());
    await pumpCalendar(
      tester,
      db,
      view: 'list',
      orientation: 'horizontal',
      startToday: false,
    );
    expectTodayOffscreen(
      tester,
      schemeColor(tester, (s) => s.primaryContainer),
    );
    await closeDb(tester, db);
  });

  testWidgets('disabled start-on-today leaves horizontal grid at week start', (
    tester,
  ) async {
    final db = AppDatabase(NativeDatabase.memory());
    await pumpCalendar(
      tester,
      db,
      view: 'grid',
      orientation: 'horizontal',
      startToday: false,
    );
    expectTodayOffscreen(tester, schemeColor(tester, (s) => s.primary));
    await closeDb(tester, db);
  });

  testWidgets('disabled start-on-today leaves vertical grid at week start', (
    tester,
  ) async {
    final db = AppDatabase(NativeDatabase.memory());
    await pumpCalendar(
      tester,
      db,
      view: 'grid',
      orientation: 'vertical',
      startToday: false,
    );
    expectTodayOffscreen(tester, schemeColor(tester, (s) => s.primary));
    await closeDb(tester, db);
  });
}
