import 'dart:io';

import 'package:chronicle/app.dart';
import 'package:chronicle/data/database.dart';
import 'package:chronicle/data/repositories.dart';
import 'package:chronicle/data/tables.dart';
import 'package:chronicle/main.dart';
import 'package:chronicle/providers.dart';
import 'package:chronicle/utils/time_format.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Gives real-async database round-trips (isolate messages) time to finish
/// and flushes the resulting frames. Mirrors the helper in test/.
Future<void> pumpForAsync(WidgetTester tester) async {
  await tester.runAsync(
    () => Future.delayed(const Duration(milliseconds: 300)),
  );
  await tester.pumpAndSettle();
}

/// Boots the full app the way main() does: view prefs are read from settings
/// first and seeded into providers, so screens never flash a default view.
Future<void> bootApp(WidgetTester tester, AppDatabase db) async {
  tester.view.physicalSize = const Size(800, 1400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  final settings = SettingsRepository(db);
  final calendarView = await tester.runAsync(() => settings.calendarView()) ??
      'list';
  final absencesView =
      await tester.runAsync(() => settings.absencesView()) ?? 'grid';
  final defaultLimit = await tester.runAsync(
    () => settings.defaultMaxAbsences(),
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        calendarViewSeedProvider.overrideWithValue(calendarView),
        absencesViewSeedProvider.overrideWithValue(absencesView),
        defaultLimitSeedProvider.overrideWithValue((
          ready: true,
          limit: defaultLimit,
        )),
      ],
      child: const StartupRunner(child: ChronicleApp()),
    ),
  );
  await tester.pumpAndSettle();
  await pumpForAsync(tester);
}

/// Tears down the pumped app and closes the database.
Future<void> shutdownApp(WidgetTester tester, AppDatabase db) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pumpAndSettle();
  await tester.runAsync(() => db.close());
}

/// Restarts the app against the same database file: closes [db], reopens
/// it, and boots again. Returns the fresh database (the caller owns it
/// and must eventually pass it to [shutdownApp]).
Future<AppDatabase> restartApp(
  WidgetTester tester,
  AppDatabase db,
  File file,
) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pumpAndSettle();
  await tester.runAsync(() => db.close());
  final fresh = AppDatabase(NativeDatabase(file));
  await bootApp(tester, fresh);
  return fresh;
}

String todayIso() => isoFromDateTime(DateTime.now());

/// Academic year spanning today, set active so seeded classes surface.
Future<int> seedYear(ClassRepository repo) async {
  final now = DateTime.now();
  final id = await repo.createYear(
    AcademicYearsCompanion.insert(
      name: 'e2e-year',
      startDate: isoFromDateTime(shiftDays(now, -60)),
      endDate: isoFromDateTime(shiftDays(now, 300)),
    ),
  );
  await SettingsRepository(repo.db).setActiveYearId(id);
  return id;
}

/// Class with one weekly slot today at [startMinutes]–[endMinutes].
Future<int> seedClassToday(
  ClassRepository repo,
  String name, {
  int? maxAbsences,
  int startMinutes = 540,
  int endMinutes = 600,
}) async {
  await seedYear(repo);
  return repo.createClassWithSlots(
    ClassesCompanion.insert(
      name: name,
      colorValue: 0xFF4F6BED,
      maxAbsences: maxAbsences == null
          ? const Value.absent()
          : Value(maxAbsences),
    ),
    [
      ScheduleItemsCompanion.insert(
        classId: 0,
        dayOfWeek: DateTime.now().weekday,
        startMinutes: startMinutes,
        endMinutes: endMinutes,
        rotation: RotationKind.weekly,
      ),
    ],
  );
}

/// Taps a destination in the navigation rail (800px test viewport).
Future<void> goTab(WidgetTester tester, IconData icon) async {
  await tester.tap(
    find.descendant(
      of: find.byType(NavigationRail),
      matching: find.byIcon(icon),
    ),
  );
  await tester.pumpAndSettle();
  await pumpForAsync(tester);
}

/// Enables auto end time, then picks the start time in a class form via
/// the time picker dialog (accepting the offered time). Copied from the
/// screen-level suite: the end time auto-fills as start + default
/// duration, so the form saves.
Future<void> pickClassTimes(WidgetTester tester, AppDatabase db) async {
  await tester.runAsync(() async {
    final settings = SettingsRepository(db);
    await settings.setAutoEndTime(true);
    await settings.setDefaultDurationMinutes(60);
  });
  await tester.tap(find.text('Pick time').first);
  await tester.pumpAndSettle();
  await tester.tap(find.text('OK'));
  await tester.pumpAndSettle();
}
