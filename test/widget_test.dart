import 'package:chronicle/app.dart';
import 'package:chronicle/data/database.dart';
import 'package:chronicle/data/repositories.dart';
import 'package:chronicle/providers.dart';
import 'package:chronicle/theme.dart';
import 'package:chronicle/data/tables.dart';
import 'package:chronicle/l10n/l10n.dart';
import 'package:chronicle/domain/schedule_models.dart' as engine;
import 'package:chronicle/screens/absences_screen.dart';
import 'package:chronicle/screens/calendar_screen.dart';
import 'package:chronicle/screens/classes_screen.dart';
import 'package:chronicle/screens/dashboard_screen.dart';
import 'package:chronicle/screens/error_dialog.dart';
import 'package:chronicle/screens/focus_screen.dart';
import 'package:chronicle/screens/grades_screen.dart';
import 'package:chronicle/screens/mark_absence_dialog.dart';
import 'package:chronicle/screens/occurrence_sheet.dart';
import 'package:chronicle/screens/schedule_slot_dialog.dart';
import 'package:chronicle/screens/settings_screen.dart';
import 'package:chronicle/screens/task_edit_screen.dart';
import 'package:chronicle/screens/tasks_screen.dart';
import 'package:chronicle/screens/xtra_dialog.dart';
import 'package:chronicle/screens/class_edit_screen.dart';
import 'package:drift/native.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Gives real-async database round-trips (isolate messages) time to finish
/// and flushes the resulting frames. Needed after pumping screens whose
/// initState loads settings, since pumpAndSettle alone only waits for
/// scheduled frames, not real async work.
Future<void> pumpForAsync(WidgetTester tester) async {
  await tester.runAsync(
    () => Future.delayed(const Duration(milliseconds: 300)),
  );
  await tester.pumpAndSettle();
}

/// Enables auto end time, then picks the start time in a new-class form
/// via the time picker dialog (accepting the offered time). The end time
/// auto-fills as start + default duration, so the form saves.
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

/// Short weekday name selected by default in a new-class form (today only).
String todayShortName() => const [
  'Mon',
  'Tue',
  'Wed',
  'Thu',
  'Fri',
  'Sat',
  'Sun',
][DateTime.now().weekday - 1];

void main() {
  testWidgets('Mark-absent dialog returns reason and excused flag', (
    tester,
  ) async {
    AbsenceDraft? result;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                result = await showMarkAbsenceDialog(
                  context,
                  title: 'Mark absent',
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    // No session-kind selector: quotas are total-based.
    expect(find.text('Theory'), findsNothing);
    expect(find.text('Practical'), findsNothing);
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Reason (optional)'),
      'Sick',
    );
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(result, isNotNull);
    expect(result!.reason, 'Sick');
    expect(result!.kind, AbsenceKind.theory);
    expect(result!.excused, isFalse);
  });

  testWidgets('Class form rejects invalid quotas and saves zero', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final db = AppDatabase(NativeDatabase.memory());
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: const MaterialApp(home: ClassEditScreen()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Class name'),
      'Biology',
    );
    await pickClassTimes(tester, db);
    final quota = find.widgetWithText(TextFormField, 'Absence limit');
    for (final invalid in ['-1', '1.5', 'abc']) {
      await tester.enterText(quota, invalid);
      await tester.tap(find.text('Save class'));
      await tester.pumpAndSettle();
      expect(find.text('Enter a non-negative whole number'), findsOneWidget);
      expect(await tester.runAsync(() => db.select(db.classes).get()), isEmpty);
    }
    await tester.enterText(quota, '0');
    await tester.tap(find.text('Save class'));
    await tester.pumpAndSettle();
    final rows = await tester.runAsync(() => db.select(db.classes).get());
    expect(rows, hasLength(1));
    expect(rows!.single.name, 'Biology');
    expect(rows.single.maxAbsences, 0);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await tester.runAsync(() => db.close());
  });

  testWidgets('Class deletion requires confirmation and preserves tasks', (
    tester,
  ) async {
    final db = AppDatabase(NativeDatabase.memory());
    final row = await tester.runAsync(() async {
      final id = await db
          .into(db.classes)
          .insert(
            ClassesCompanion.insert(name: 'History', colorValue: 0xFF4F6BED),
          );
      await db
          .into(db.scheduleItems)
          .insert(
            ScheduleItemsCompanion.insert(
              classId: id,
              dayOfWeek: 1,
              startMinutes: 540,
              endMinutes: 600,
              rotation: RotationKind.weekly,
            ),
          );
      await db
          .into(db.absences)
          .insert(
            AbsencesCompanion.insert(
              classId: id,
              date: '2026-09-14',
              startMinutes: 540,
              endMinutes: 600,
            ),
          );
      await db
          .into(db.tasks)
          .insert(TasksCompanion.insert(title: 'Essay', classId: Value(id)));
      return db.select(db.classes).getSingle();
    });
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: MaterialApp(home: ClassEditScreen(existing: row)),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Delete class'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(
      await tester.runAsync(() => db.select(db.classes).get()),
      hasLength(1),
    );
    await tester.tap(find.byTooltip('Delete class'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(await tester.runAsync(() => db.select(db.classes).get()), isEmpty);
    expect(
      await tester.runAsync(() => db.select(db.scheduleItems).get()),
      isEmpty,
    );
    expect(await tester.runAsync(() => db.select(db.absences).get()), isEmpty);
    final tasks = await tester.runAsync(() => db.select(db.tasks).get());
    expect(tasks, hasLength(1));
    expect(tasks!.single.classId, isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await tester.runAsync(() => db.close());
  });

  testWidgets('New class creates slots from days and hours', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final db = AppDatabase(NativeDatabase.memory());
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: const MaterialApp(home: ClassEditScreen()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Class name'),
      'Physics',
    );
    // Only today is selected by default; pick times and save.
    await pickClassTimes(tester, db);
    await tester.tap(find.text('Save class'));
    await tester.pumpAndSettle();
    final savedClasses = await tester.runAsync(
      () => db.select(db.classes).get(),
    );
    expect(savedClasses, hasLength(1));
    final slots = await tester.runAsync(
      () => db.select(db.scheduleItems).get(),
    );
    expect(slots, hasLength(1));
    expect(slots!.single.dayOfWeek, DateTime.now().weekday);
    expect(slots.single.endMinutes, greaterThan(slots.single.startMinutes));
    expect(slots.single.rotation, RotationKind.weekly);
    expect(slots.single.classId, savedClasses!.single.id);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await tester.runAsync(() => db.close());
  });

  testWidgets('New class requires at least one weekday', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final db = AppDatabase(NativeDatabase.memory());
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: const MaterialApp(home: ClassEditScreen()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Class name'),
      'Physics',
    );
    // Only today is selected by default; deselect it.
    await tester.tap(find.text(todayShortName()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save class'));
    await tester.pumpAndSettle();
    expect(find.text('Select at least one weekday'), findsOneWidget);
    expect(await tester.runAsync(() => db.select(db.classes).get()), isEmpty);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await tester.runAsync(() => db.close());
  });

  testWidgets('Slot dialog returns a weekly meeting draft', (tester) async {
    SlotDraft? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return TextButton(
                onPressed: () async {
                  result = await showDialog<SlotDraft>(
                    context: context,
                    builder: (_) => const ScheduleSlotDialog(),
                  );
                },
                child: const Text('Open slot'),
              );
            },
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open slot'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(result, isNotNull);
    expect(result!.dayOfWeek, 1);
    expect(result!.startMinutes, 540);
    expect(result!.endMinutes, 600);
    expect(result!.rotation, RotationKind.weekly);
  });

  testWidgets('New class starts with today only and empty times', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final db = AppDatabase(NativeDatabase.memory());
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: const MaterialApp(home: ClassEditScreen()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Class name'),
      'Physics',
    );
    // Today only is selected and times start empty.
    expect(find.text('Pick time'), findsNWidgets(2));
    await pickClassTimes(tester, db);
    await tester.tap(find.text('Save class'));
    await tester.pumpAndSettle();
    final savedClasses = await tester.runAsync(
      () => db.select(db.classes).get(),
    );
    expect(savedClasses, hasLength(1));
    final slots = await tester.runAsync(
      () => db.select(db.scheduleItems).get(),
    );
    expect(slots, hasLength(1));
    expect(slots!.single.dayOfWeek, DateTime.now().weekday);
    expect(slots.single.classId, savedClasses!.single.id);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await tester.runAsync(() => db.close());
  });

  testWidgets('Existing class saves meeting times from the editor', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final db = AppDatabase(NativeDatabase.memory());
    final row = await tester.runAsync(
      () => db
          .into(db.classes)
          .insert(
            ClassesCompanion.insert(name: 'Physics', colorValue: 0xFF4F6BED),
          )
          .then((id) => db.select(db.classes).getSingle()),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: MaterialApp(home: ClassEditScreen(existing: row)),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Add time slot'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    final slots = await tester.runAsync(
      () => db.select(db.scheduleItems).get(),
    );
    expect(slots, hasLength(1));
    expect(slots!.single.classId, row!.id);
    expect(slots.single.rotation, RotationKind.weekly);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await tester.runAsync(() => db.close());
  });

  testWidgets('New class prefills default absence limit from settings', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 2200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final db = AppDatabase(NativeDatabase.memory());
    await tester.runAsync(
      () => SettingsRepository(db).setDefaultMaxAbsences(3),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: const MaterialApp(home: ClassEditScreen()),
      ),
    );
    await tester.pumpAndSettle();
    await pumpForAsync(tester);
    final quota = find.widgetWithText(TextFormField, 'Absence limit');
    expect(tester.widget<TextFormField>(quota).controller!.text, '3');
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await tester.runAsync(() => db.close());
  });

  testWidgets('App shell renders navigation and dashboard', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: const ChronicleApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Today'), findsWidgets);
    expect(find.text('Calendar'), findsWidgets);
    expect(find.text('Classes'), findsWidgets);
    expect(find.text('Tasks'), findsWidgets);
    expect(find.text('Absences'), findsWidgets);
    expect(find.text('Settings'), findsWidgets);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await tester.runAsync(() => db.close());
  });

  testWidgets('Navigating to classes tab works', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: const ChronicleApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.descendant(
        of: find.byType(NavigationRail),
        matching: find.byIcon(Icons.school_outlined),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No classes yet'), findsOneWidget);
    expect(find.text('Add class'), findsWidgets);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await tester.runAsync(() => db.close());
  });

  testWidgets('Classes screen filters by active academic year', (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final db = AppDatabase(NativeDatabase.memory());
    await tester.runAsync(() async {
      final repo = ClassRepository(db);
      final y1 = await repo.createYear(
        AcademicYearsCompanion.insert(
          name: '2026/27',
          startDate: '2026-09-01',
          endDate: '2027-06-30',
        ),
      );
      final y2 = await repo.createYear(
        AcademicYearsCompanion.insert(
          name: '2027/28',
          startDate: '2027-09-01',
          endDate: '2028-06-30',
        ),
      );
      await repo.create(
        ClassesCompanion.insert(
          name: 'Math',
          colorValue: 0xFF4F6BED,
          yearId: Value(y1),
        ),
      );
      await repo.create(
        ClassesCompanion.insert(
          name: 'History',
          colorValue: 0xFFFF7043,
          yearId: Value(y2),
        ),
      );
      await SettingsRepository(db).setActiveYearId(y1);
    });
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: const MaterialApp(home: ClassesScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Math'), findsOneWidget);
    expect(find.text('History'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await tester.runAsync(() => db.close());
  });

  testWidgets('Dashboard shows absence quota warnings', (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final db = AppDatabase(NativeDatabase.memory());
    await tester.runAsync(() async {
      final id = await db
          .into(db.classes)
          .insert(
            ClassesCompanion.insert(
              name: 'Math',
              colorValue: 0xFF4F6BED,
              maxAbsences: const Value(1),
            ),
          );
      final now = DateTime.now();
      final today =
          '${now.year.toString().padLeft(4, '0')}-'
          '${now.month.toString().padLeft(2, '0')}-'
          '${now.day.toString().padLeft(2, '0')}';
      await db
          .into(db.absences)
          .insert(
            AbsencesCompanion.insert(
              classId: id,
              date: today,
              startMinutes: 540,
              endMinutes: 600,
              reason: const Value('Sick'),
            ),
          );
    });
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: const MaterialApp(home: DashboardScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Absence warnings'), findsOneWidget);
    expect(find.textContaining('over the limit of 1'), findsOneWidget);
    expect(find.text('Nothing due in the next 7 days.'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await tester.runAsync(() => db.close());
  });

  testWidgets('Calendar week view shows class meetings', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    await tester.runAsync(() async {
      final id = await db
          .into(db.classes)
          .insert(
            ClassesCompanion.insert(name: 'Physics', colorValue: 0xFF4F6BED),
          );
      await db
          .into(db.scheduleItems)
          .insert(
            ScheduleItemsCompanion.insert(
              classId: id,
              dayOfWeek: 1,
              startMinutes: 540,
              endMinutes: 600,
              rotation: RotationKind.weekly,
            ),
          );
    });
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: const MaterialApp(home: CalendarScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Physics'), findsOneWidget);
    expect(find.textContaining('09:00 - 10:00'), findsOneWidget);
    expect(find.text('Mon'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await tester.runAsync(() => db.close());
  });

  testWidgets('Occurrence sheet marks absent with reason', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    final classId = await tester.runAsync(
      () => db
          .into(db.classes)
          .insert(
            ClassesCompanion.insert(name: 'Chem', colorValue: 0xFF4F6BED),
          ),
    );
    final now = DateTime.now();
    final occ = engine.ClassOccurrence(
      classId: classId!,
      scheduleItemId: 1,
      date: DateTime(now.year, now.month, now.day),
      startMinutes: 540,
      endMinutes: 600,
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showOccurrenceSheet(context, occ),
                child: const Text('Open sheet'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open sheet'));
    await tester.pumpAndSettle();
    expect(find.text('Chem'), findsWidgets);
    await tester.tap(find.text('Mark absent'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Reason (optional)'),
      'Sick',
    );
    await tester.tap(find.text('Excused'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    final rows = await tester.runAsync(() => db.select(db.absences).get());
    expect(rows, hasLength(1));
    expect(rows!.single.reason, 'Sick');
    expect(rows.single.isExcused, isTrue);
    expect(find.text('Excused absence'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await tester.runAsync(() => db.close());
  });

  testWidgets('Occurrence sheet marks present again', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    final setup = (await tester.runAsync(() async {
      final id = await db
          .into(db.classes)
          .insert(ClassesCompanion.insert(name: 'Bio', colorValue: 0xFF4F6BED));
      final now = DateTime.now();
      final today =
          '${now.year.toString().padLeft(4, '0')}-'
          '${now.month.toString().padLeft(2, '0')}-'
          '${now.day.toString().padLeft(2, '0')}';
      await db
          .into(db.absences)
          .insert(
            AbsencesCompanion.insert(
              classId: id,
              date: today,
              startMinutes: 540,
              endMinutes: 600,
            ),
          );
      return (id, DateTime(now.year, now.month, now.day));
    }))!;
    final occ = engine.ClassOccurrence(
      classId: setup.$1,
      scheduleItemId: 1,
      date: setup.$2,
      startMinutes: 540,
      endMinutes: 600,
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showOccurrenceSheet(context, occ),
                child: const Text('Open sheet'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open sheet'));
    await tester.pumpAndSettle();
    expect(find.text('Unexcused absence'), findsOneWidget);
    await tester.tap(find.text('Mark present'));
    await tester.pumpAndSettle();
    expect(await tester.runAsync(() => db.select(db.absences).get()), isEmpty);
    expect(find.text('Mark absent'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await tester.runAsync(() => db.close());
  });

  testWidgets('Class editor lists absences with quota progress', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final db = AppDatabase(NativeDatabase.memory());
    final row = await tester.runAsync(() async {
      final id = await db
          .into(db.classes)
          .insert(
            ClassesCompanion.insert(
              name: 'History',
              colorValue: 0xFF4F6BED,
              maxAbsences: const Value(3),
            ),
          );
      await db
          .into(db.absences)
          .insert(
            AbsencesCompanion.insert(
              classId: id,
              date: '2026-09-14',
              startMinutes: 540,
              endMinutes: 600,
              reason: const Value('Dentist'),
            ),
          );
      return db.select(db.classes).getSingle();
    });
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: MaterialApp(home: ClassEditScreen(existing: row)),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Absences'), findsOneWidget);
    expect(find.text('1 / 3 unexcused (0 excused)'), findsOneWidget);
    expect(find.textContaining('Dentist'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byTooltip('Delete absence record'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byTooltip('Delete absence record'));
    await tester.pumpAndSettle();
    expect(await tester.runAsync(() => db.select(db.absences).get()), isEmpty);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await tester.runAsync(() => db.close());
  });
  testWidgets('Calendar grid view positions meetings by time', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    await tester.runAsync(() async {
      final id = await db
          .into(db.classes)
          .insert(
            ClassesCompanion.insert(name: 'Physics', colorValue: 0xFF4F6BED),
          );
      await db
          .into(db.scheduleItems)
          .insert(
            ScheduleItemsCompanion.insert(
              classId: id,
              dayOfWeek: 1,
              startMinutes: 540,
              endMinutes: 600,
              rotation: RotationKind.weekly,
            ),
          );
    });
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: const MaterialApp(home: CalendarScreen()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Time grid view'));
    await tester.pumpAndSettle();
    // Block rendered once in the grid (list tiles are gone).
    expect(find.text('Physics'), findsOneWidget);
    // Hour gutter labels the rows.
    expect(find.text('09:00'), findsWidgets);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await tester.runAsync(() => db.close());
  });

  testWidgets('Tasks screen sections seeded tasks', (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final db = AppDatabase(NativeDatabase.memory());
    await tester.runAsync(() async {
      final now = DateTime.now();
      String iso(DateTime d) =>
          '${d.year.toString().padLeft(4, '0')}-'
          '${d.month.toString().padLeft(2, '0')}-'
          '${d.day.toString().padLeft(2, '0')}';
      await db
          .into(db.tasks)
          .insert(
            TasksCompanion.insert(
              title: 'Overdue essay',
              type: const Value(TaskKind.homework),
              dueDate: Value(iso(now.subtract(const Duration(days: 1)))),
            ),
          );
      await db
          .into(db.tasks)
          .insert(
            TasksCompanion.insert(
              title: 'Final exam',
              type: const Value(TaskKind.exam),
              dueDate: Value(iso(now.add(const Duration(days: 2)))),
            ),
          );
      await db.into(db.tasks).insert(TasksCompanion.insert(title: 'Buy pens'));
    });
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: const MaterialApp(home: TasksScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Overdue'), findsOneWidget);
    expect(find.text('Overdue essay'), findsOneWidget);
    expect(find.text('Upcoming'), findsOneWidget);
    // Shown both in the countdown card and in its section tile.
    expect(find.text('Final exam'), findsWidgets);
    expect(find.text('No due date'), findsOneWidget);
    expect(find.text('Buy pens'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await tester.runAsync(() => db.close());
  });

  testWidgets('Task editor saves steps with the task', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final db = AppDatabase(NativeDatabase.memory());
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: const MaterialApp(home: TaskEditScreen()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Title'),
      'Worksheet',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'New step'),
      'Part 1',
    );
    await tester.tap(find.byTooltip('Add step'));
    await tester.pumpAndSettle();
    expect(find.text('Part 1'), findsOneWidget);
    await tester.tap(find.text('Save task'));
    await tester.pumpAndSettle();
    final tasks = await tester.runAsync(() => db.select(db.tasks).get());
    expect(tasks, hasLength(1));
    expect(tasks!.single.title, 'Worksheet');
    final subs = await tester.runAsync(() => db.select(db.subtasks).get());
    expect(subs, hasLength(1));
    expect(subs!.single.title, 'Part 1');
    expect(subs.single.taskId, tasks.single.id);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await tester.runAsync(() => db.close());
  });

  testWidgets('Task editor blocks reminders without a due date', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final db = AppDatabase(NativeDatabase.memory());
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: const MaterialApp(home: TaskEditScreen()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Title'),
      'Read chapter',
    );
    await tester.tap(find.text('1 hour before'));
    await tester.pumpAndSettle();
    expect(find.text('1 hour before'), findsWidgets);
    await tester.tap(find.text('Save task'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Reminders need a due date'), findsOneWidget);
    expect(await tester.runAsync(() => db.select(db.tasks).get()), isEmpty);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await tester.runAsync(() => db.close());
  });

  testWidgets('Absences list shows per-class quotas without history', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final db = AppDatabase(NativeDatabase.memory());
    await tester.runAsync(() async {
      final id = await db
          .into(db.classes)
          .insert(
            ClassesCompanion.insert(
              name: 'Math',
              colorValue: 0xFF4F6BED,
              maxAbsences: const Value(2),
            ),
          );
      await db
          .into(db.absences)
          .insert(
            AbsencesCompanion.insert(
              classId: id,
              date: '2026-09-14',
              startMinutes: 540,
              endMinutes: 600,
              reason: const Value('Sick'),
            ),
          );
      await db
          .into(db.absences)
          .insert(
            AbsencesCompanion.insert(
              classId: id,
              date: '2026-09-15',
              startMinutes: 540,
              endMinutes: 600,
              reason: const Value('Dentist'),
              isExcused: const Value(true),
            ),
          );
    });
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          absencesViewSeedProvider.overrideWithValue('list'),
        ],
        child: const MaterialApp(home: AbsencesScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('1 / 2 unexcused'), findsOneWidget);
    // History tiles are gone from the list view: quotas carry the signal.
    expect(find.textContaining('Sick'), findsNothing);
    expect(find.textContaining('Dentist'), findsNothing);
    // Filters still render and stay interactive.
    await tester.tap(
      find.descendant(
        of: find.byType(FilterChip),
        matching: find.text('Excused'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('1 / 2 unexcused'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await tester.runAsync(() => db.close());
  });

  testWidgets('New class leaves meeting times empty', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final db = AppDatabase(NativeDatabase.memory());
    await tester.runAsync(() async {
      final settings = SettingsRepository(db);
      await settings.setDefaultStartMinutes(600);
      await settings.setDefaultDurationMinutes(90);
    });
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: const MaterialApp(home: ClassEditScreen()),
      ),
    );
    await tester.pumpAndSettle();
    await pumpForAsync(tester);
    // Saved defaults must not prefill the form; only today is selected.
    expect(find.text('Pick time'), findsNWidgets(2));
    expect(find.text('10:00'), findsNothing);
    expect(find.text(todayShortName()), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await tester.runAsync(() => db.close());
  });

  testWidgets('Class editor saves building, module and link', (tester) async {
    tester.view.physicalSize = const Size(800, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final db = AppDatabase(NativeDatabase.memory());
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: const MaterialApp(home: ClassEditScreen()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Class name'),
      'Physics',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Building'),
      'Science block',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Module'),
      'Mechanics 101',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Online link'),
      'https://example.invalid/class',
    );
    await pickClassTimes(tester, db);
    await tester.tap(find.text('Save class'));
    await tester.pumpAndSettle();
    final rows = await tester.runAsync(() => db.select(db.classes).get());
    expect(rows, hasLength(1));
    expect(rows!.single.building, 'Science block');
    expect(rows.single.module, 'Mechanics 101');
    expect(rows.single.onlineLink, 'https://example.invalid/class');
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await tester.runAsync(() => db.close());
  });

  testWidgets('Class editor saves per-class reminder lead', (tester) async {
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final db = AppDatabase(NativeDatabase.memory());
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: const MaterialApp(home: ClassEditScreen()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Class name'),
      'Physics',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Class reminder (minutes before)'),
      '20',
    );
    await pickClassTimes(tester, db);
    await tester.tap(find.text('Save class'));
    await tester.pumpAndSettle();
    final rows = await tester.runAsync(() => db.select(db.classes).get());
    expect(rows, hasLength(1));
    expect(rows!.single.reminderMinutes, 20);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await tester.runAsync(() => db.close());
  });

  testWidgets('Slot dialog offers rotation days when configured', (
    tester,
  ) async {
    SlotDraft? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return TextButton(
                onPressed: () async {
                  result = await showDialog<SlotDraft>(
                    context: context,
                    builder: (_) => const ScheduleSlotDialog(
                      dayRotationLength: 6,
                      dayRotationLetters: true,
                    ),
                  );
                },
                child: const Text('Open slot'),
              );
            },
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open slot'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.widgetWithText(DropdownButtonFormField<RotationKind>, 'Every week'),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Day rotation').last);
    await tester.pumpAndSettle();
    expect(find.text('Meets on rotation days:'), findsOneWidget);
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(result, isNotNull);
    expect(result!.rotation, RotationKind.dayRotation);
    expect(result!.rotationDays, '[1]');
  });

  testWidgets('Calendar headers show rotation day labels', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    await tester.runAsync(() async {
      final repo = ClassRepository(db);
      final yearId = await repo.createYear(
        AcademicYearsCompanion.insert(
          name: '2026/27',
          startDate: '2026-09-14',
          endDate: '2027-06-30',
          rotationLength: const Value(6),
          rotationSchoolDays: const Value('[1,2,3,4,5]'),
          rotationLabels: const Value('letters'),
        ),
      );
      await repo.create(
        ClassesCompanion.insert(
          name: 'Math',
          colorValue: 0xFF4F6BED,
          yearId: Value(yearId),
        ),
      );
      await SettingsRepository(db).setActiveYearId(yearId);
    });
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: const MaterialApp(home: CalendarScreen()),
      ),
    );
    await tester.pumpAndSettle();
    // Rotation labels A-F appear under the day numbers.
    expect(find.text('A'), findsWidgets);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await tester.runAsync(() => db.close());
  });

  testWidgets('Task editor saves progress and repeat rule', (tester) async {
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final db = AppDatabase(NativeDatabase.memory());
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: const MaterialApp(home: TaskEditScreen()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Title'),
      'Essay draft',
    );
    await tester.tap(find.text('Track progress %'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Never'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Weekly').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save task'));
    await tester.pumpAndSettle();
    final rows = await tester.runAsync(() => db.select(db.tasks).get());
    expect(rows, hasLength(1));
    expect(rows!.single.progressPercent, 0);
    expect(rows.single.repeatKind, RepeatKind.weekly);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await tester.runAsync(() => db.close());
  });

  testWidgets('Exam editor records a grade', (tester) async {
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final db = AppDatabase(NativeDatabase.memory());
    final existing = await tester.runAsync(() async {
      final repo = TaskRepository(db);
      final id = await repo.create(
        TasksCompanion.insert(
          title: 'Midterm',
          type: const Value(TaskKind.exam),
        ),
      );
      return (await repo.watchAll().first).singleWhere((t) => t.task.id == id);
    });
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: MaterialApp(home: TaskEditScreen(existing: existing)),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextFormField, 'Score'), '85');
    await tester.tap(find.text('Save').first);
    await tester.pumpAndSettle();
    final grades = await tester.runAsync(() => db.select(db.grades).get());
    expect(grades, hasLength(1));
    expect(grades!.single.score, 85);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await tester.runAsync(() => db.close());
  });

  testWidgets('Tasks screen shows exam countdown', (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final db = AppDatabase(NativeDatabase.memory());
    await tester.runAsync(() async {
      final now = DateTime.now();
      final due = now.add(const Duration(days: 2));
      final iso =
          '${due.year.toString().padLeft(4, '0')}-'
          '${due.month.toString().padLeft(2, '0')}-'
          '${due.day.toString().padLeft(2, '0')}';
      await db
          .into(db.tasks)
          .insert(
            TasksCompanion.insert(
              title: 'Finals',
              type: const Value(TaskKind.exam),
              dueDate: Value(iso),
            ),
          );
    });
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: const MaterialApp(home: TasksScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Exam countdown'), findsOneWidget);
    expect(find.text('In 2 days'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await tester.runAsync(() => db.close());
  });

  testWidgets('Grades screen shows GPA', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    await tester.runAsync(() async {
      final tasks = TaskRepository(db);
      final grades = GradeRepository(db);
      for (final entry in [(85.0, 'Midterm'), (70.0, 'Quiz')]) {
        final id = await tasks.create(
          TasksCompanion.insert(
            title: entry.$2,
            type: const Value(TaskKind.exam),
          ),
        );
        await grades.record(
          GradesCompanion.insert(
            examTaskId: id,
            score: entry.$1,
            maxScore: const Value(100),
            date: '2026-09-14',
          ),
        );
      }
    });
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: const MaterialApp(home: GradesScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('2.50'), findsOneWidget);
    expect(find.textContaining('85.0 / 100.0'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await tester.runAsync(() => db.close());
  });

  testWidgets('Focus timer completes a short session', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: const MaterialApp(
          home: FocusScreen(workSeconds: 3, breakSeconds: 2),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start focus session'));
    await tester.pump(const Duration(seconds: 4));
    expect(find.text('Break'), findsOneWidget);
    // Stop the break timer so the test can settle.
    await tester.tap(find.text('Skip break'));
    await tester.pumpAndSettle();
    final sessions = await tester.runAsync(
      () => db.select(db.pomodoroSessions).get(),
    );
    expect(sessions, hasLength(1));
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await tester.runAsync(() => db.close());
  });

  testWidgets('Xtra dialog saves an event', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: MaterialApp(
          home: Scaffold(
            body: Consumer(
              builder: (context, ref, _) => TextButton(
                onPressed: () => showXtraDialog(context, ref),
                child: const Text('Open xtra'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open xtra'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Title (sport, appointment, club…)'),
      'Football',
    );
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    final rows = await tester.runAsync(() => db.select(db.xtraEvents).get());
    expect(rows, hasLength(1));
    expect(rows!.single.title, 'Football');
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await tester.runAsync(() => db.close());
  });

  testWidgets('Settings selects theme family and accent', (tester) async {
    tester.view.physicalSize = const Size(800, 2200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final db = AppDatabase(NativeDatabase.memory());
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: const MaterialApp(home: SettingsScreen()),
      ),
    );
    await tester.pumpAndSettle();
    // Default theme shows no accent dots.
    expect(find.byTooltip('Blue'), findsNothing);
    await tester.tap(find.text('Default'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nord').last);
    await tester.pumpAndSettle();
    final settings = SettingsRepository(db);
    expect(await tester.runAsync(() => settings.appTheme()), 'nord');
    // Nord supports accents; an unknown stored id falls back to default.
    await tester.tap(find.byTooltip('Frost 2'));
    await tester.pumpAndSettle();
    expect(await tester.runAsync(() => settings.accentColor()), 0xFF88C0D0);
    await tester.runAsync(() => settings.set('app_theme', 'nope'));
    expect(await tester.runAsync(() => settings.appTheme()), 'default');
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await tester.runAsync(() => db.close());
  });

  testWidgets('Error dialog shows selectable details', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showErrorDialog(
                context,
                title: 'Could not save class',
                error: StateError('disk is full'),
              ),
              child: const Text('Fail'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Fail'));
    await tester.pumpAndSettle();
    expect(find.text('Could not save class'), findsOneWidget);
    expect(find.textContaining('disk is full'), findsOneWidget);
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
    expect(find.text('Could not save class'), findsNothing);
  });
  testWidgets('Absences matrix shows class rows and week columns', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final db = AppDatabase(NativeDatabase.memory());
    await tester.runAsync(() async {
      final repo = ClassRepository(db);
      final id = await repo.create(
        ClassesCompanion.insert(name: 'Math', colorValue: 0xFF4F6BED),
      );
      final now = DateTime.now();
      String iso(DateTime d) =>
          '${d.year.toString().padLeft(4, '0')}-'
          '${d.month.toString().padLeft(2, '0')}-'
          '${d.day.toString().padLeft(2, '0')}';
      await AbsenceRepository(db).mark(
        AbsencesCompanion.insert(
          classId: id,
          date: iso(now),
          startMinutes: 540,
          endMinutes: 600,
          reason: const Value('Sick'),
        ),
      );
    });
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: const MaterialApp(home: AbsencesScreen()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Weeks grid view'));
    await tester.pumpAndSettle();
    // Current week is the last of the trailing 12.
    expect(find.text('W12'), findsOneWidget);
    expect(find.text('Math'), findsOneWidget);
    final closing = db.close();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await closing;
  });

  testWidgets('Calendar grid honors fixed lesson rhythm', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    await tester.runAsync(() async {
      final repo = ClassRepository(db);
      final id = await repo.create(
        ClassesCompanion.insert(name: 'Physics', colorValue: 0xFF4F6BED),
      );
      await repo.createScheduleItem(
        ScheduleItemsCompanion.insert(
          classId: id,
          dayOfWeek: 1,
          startMinutes: 540,
          endMinutes: 600,
          rotation: RotationKind.weekly,
        ),
      );
      final settings = SettingsRepository(db);
      await settings.setGridMarkersMode('fixed');
      await settings.setDayStartHour(14);
      await settings.setDayEndHour(17);
      await settings.setGridFixedLesson(60);
      await settings.setGridFixedBreak(10);
    });
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: const MaterialApp(home: CalendarScreen()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Time grid view'));
    await tester.pumpAndSettle();
    // Fixed lesson/break boundaries label both gutters:
    // 14:00, 15:00, 15:10, 16:10.
    expect(find.text('14:00'), findsWidgets);
    expect(find.text('15:00'), findsWidgets);
    expect(find.text('15:10'), findsWidgets);
    expect(find.text('16:10'), findsWidgets);
    final closing = db.close();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await closing;
  });

  testWidgets('Calendar grid adjusts a class time', (tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final db = AppDatabase(NativeDatabase.memory());
    final slotId = await tester.runAsync(() async {
      final repo = ClassRepository(db);
      final id = await repo.create(
        ClassesCompanion.insert(name: 'Physics', colorValue: 0xFF4F6BED),
      );
      return repo.createScheduleItem(
        ScheduleItemsCompanion.insert(
          classId: id,
          dayOfWeek: 1,
          startMinutes: 540,
          endMinutes: 600,
          rotation: RotationKind.weekly,
        ),
      );
    });
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: const MaterialApp(home: CalendarScreen()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Time grid view'));
    await tester.pumpAndSettle();

    await tester.longPress(find.text('Physics').first);
    await tester.pumpAndSettle();
    expect(find.textContaining('Adjust Physics'), findsOneWidget);
    // Nudge the start +5 minutes twice, then save.
    final plus5 = find.text('+5');
    await tester.tap(plus5.first);
    await tester.pumpAndSettle();
    await tester.tap(plus5.first);
    await tester.pumpAndSettle();
    expect(find.textContaining('09:10'), findsWidgets);
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    final slots = await tester.runAsync(
      () => db.select(db.scheduleItems).get(),
    );
    final moved = slots!.singleWhere((s) => s.id == slotId);
    expect(moved.startMinutes, 550);
    expect(moved.endMinutes, 600);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await tester.runAsync(() => db.close());
  });

  testWidgets('Year-less classes stay visible under a year filter', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final db = AppDatabase(NativeDatabase.memory());
    await tester.runAsync(() async {
      final repo = ClassRepository(db);
      final yearId = await repo.createYear(
        AcademicYearsCompanion.insert(
          name: '2026/27',
          startDate: '2026-09-01',
          endDate: '2027-06-30',
        ),
      );
      await repo.create(
        ClassesCompanion.insert(
          name: 'Filed',
          colorValue: 0xFF4F6BED,
          yearId: Value(yearId),
        ),
      );
      final looseId = await repo.create(
        ClassesCompanion.insert(
          name: 'Loose',
          colorValue: 0xFFFF7043,
          maxAbsences: const Value(3),
        ),
      );
      final now = DateTime.now();
      final iso =
          '${now.year.toString().padLeft(4, '0')}-'
          '${now.month.toString().padLeft(2, '0')}-'
          '${now.day.toString().padLeft(2, '0')}';
      await AbsenceRepository(db).mark(
        AbsencesCompanion.insert(
          classId: looseId,
          date: iso,
          startMinutes: 540,
          endMinutes: 600,
        ),
      );
      await SettingsRepository(db).setActiveYearId(yearId);
    });
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          absencesViewSeedProvider.overrideWithValue('list'),
        ],
        child: const MaterialApp(home: ClassesScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Filed'), findsOneWidget);
    expect(find.text('Loose'), findsOneWidget);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          absencesViewSeedProvider.overrideWithValue('list'),
        ],
        child: const MaterialApp(home: AbsencesScreen()),
      ),
    );
    await tester.pumpAndSettle();
    // Year-less quota card stays visible under a year filter (no history
    // tiles in list view anymore).
    expect(find.textContaining('Loose'), findsWidgets);
    expect(find.text('1 / 3 unexcused'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await tester.runAsync(() => db.close());
  });

  testWidgets('Fixed grid uses defaults from day start', (
    tester,
  ) async {
    final db = AppDatabase(NativeDatabase.memory());
    await tester.runAsync(() async {
      final repo = ClassRepository(db);
      final id = await repo.create(
        ClassesCompanion.insert(name: 'Physics', colorValue: 0xFF4F6BED),
      );
      await repo.createScheduleItem(
        ScheduleItemsCompanion.insert(
          classId: id,
          dayOfWeek: 1,
          startMinutes: 580,
          endMinutes: 630,
          rotation: RotationKind.weekly,
        ),
      );
      final settings = SettingsRepository(db);
      await settings.setGridMarkersMode('fixed');
      // No lesson/break configured: 60/10 rhythm from the day start.
    });
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: const MaterialApp(home: CalendarScreen()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Time grid view'));
    await tester.pumpAndSettle();
    await pumpForAsync(tester);
    // Default 60/10 rhythm from 06:00 labels the grid.
    expect(find.text('06:00'), findsWidgets);
    expect(find.text('07:00'), findsWidgets);
    expect(find.text('07:10'), findsWidgets);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await tester.runAsync(() => db.close());
  });

  testWidgets('Grid defaults to class-time boundaries', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    await tester.runAsync(() async {
      final repo = ClassRepository(db);
      final id = await repo.create(
        ClassesCompanion.insert(name: 'Physics', colorValue: 0xFF4F6BED),
      );
      await repo.createScheduleItem(
        ScheduleItemsCompanion.insert(
          classId: id,
          dayOfWeek: 1,
          startMinutes: 580,
          endMinutes: 630,
          rotation: RotationKind.weekly,
        ),
      );
    });
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: const MaterialApp(home: CalendarScreen()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Time grid view'));
    await tester.pumpAndSettle();
    expect(find.text('09:40'), findsWidgets);
    expect(find.text('10:30'), findsWidgets);
    expect(find.text('06:00'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await tester.runAsync(() => db.close());
  });

  testWidgets('Grid blocks never overflow in narrow lanes', (tester) async {
    tester.view.physicalSize = const Size(800, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final db = AppDatabase(NativeDatabase.memory());
    await tester.runAsync(() async {
      final repo = ClassRepository(db);
      for (final name in [
        'A very long class name that certainly wraps around',
        'Another lengthy class name for overlap testing',
      ]) {
        final id = await repo.create(
          ClassesCompanion.insert(name: name, colorValue: 0xFF4F6BED),
        );
        await repo.createScheduleItem(
          ScheduleItemsCompanion.insert(
            classId: id,
            dayOfWeek: 1,
            startMinutes: 540,
            endMinutes: 570,
            rotation: RotationKind.weekly,
          ),
        );
      }
    });
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: const MaterialApp(home: CalendarScreen()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Time grid view'));
    await tester.pumpAndSettle();
    // Overlapping lanes render without RenderFlex overflow errors.
    expect(find.textContaining('very long'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await tester.runAsync(() => db.close());
  });

  testWidgets('Absences matrix keeps DST-transition weeks', (tester) async {
    // Regression: week columns built with Duration arithmetic drifted by
    // one hour across the Mar 29 2026 DST change (Europe/Berlin), so the
    // whole Mar-30 week silently vanished from the matrix. Meaningful only
    // in a DST timezone; run with TZ=Europe/Berlin to exercise it.
    final db = AppDatabase(NativeDatabase.memory());
    await tester.runAsync(() async {
      final classId = await db
          .into(db.classes)
          .insert(
            ClassesCompanion.insert(name: 'Mathe', colorValue: 0xFF4F6BED),
          );
      for (final date in [
        '2026-03-30',
        '2026-03-31',
        '2026-04-01',
        '2026-04-02',
      ]) {
        await db
            .into(db.absences)
            .insert(
              AbsencesCompanion.insert(
                classId: classId,
                date: date,
                startMinutes: 540,
                endMinutes: 600,
              ),
            );
      }
      final yearId = await db
          .into(db.academicYears)
          .insert(
            AcademicYearsCompanion.insert(
              name: '2025/26',
              startDate: '2025-12-08',
              endDate: '2026-09-30',
            ),
          );
      await SettingsRepository(db).setActiveYearId(yearId);
    });
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          absencesViewSeedProvider.overrideWithValue('grid'),
        ],
        child: const MaterialApp(home: AbsencesScreen()),
      ),
    );
    await tester.pumpAndSettle();
    // All four absences aggregate into a single week cell.
    expect(find.text('4'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await tester.runAsync(() => db.close());
  });

  testWidgets('Absences screen opens directly in the saved view', (
    tester,
  ) async {
    // No async initState flip: the preloaded pref drives the first frame.
    for (final pref in ['grid', 'list']) {
      final db = AppDatabase(NativeDatabase.memory());
      await tester.runAsync(() async {
        await db
            .into(db.classes)
            .insert(
              ClassesCompanion.insert(name: 'Mathe', colorValue: 0xFF4F6BED),
            );
      });
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            absencesViewSeedProvider.overrideWithValue(pref),
          ],
          child: const MaterialApp(home: AbsencesScreen()),
        ),
      );
      await tester.pumpAndSettle();
      if (pref == 'grid') {
        expect(find.text('W1'), findsOneWidget);
      } else {
        // List view has no history section and no empty-state message.
        expect(find.text('No absences recorded.'), findsNothing);
        expect(find.text('W1'), findsNothing);
      }
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      await tester.runAsync(() => db.close());
    }
  });

  testWidgets('Calendar grid honours the configured day range', (tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final db = AppDatabase(NativeDatabase.memory());
    await tester.runAsync(() async {
      final settings = SettingsRepository(db);
      await settings.setDayStartHour(7);
      await settings.setDayEndHour(20);
    });
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          calendarViewSeedProvider.overrideWithValue('grid'),
        ],
        child: const MaterialApp(home: CalendarScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('07:00'), findsWidgets);
    expect(find.text('20:00'), findsWidgets);
    expect(find.text('06:00'), findsNothing);
    expect(find.text('21:00'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await tester.runAsync(() => db.close());
  });

  testWidgets('Fixed grid draws boundaries and shaded breaks', (tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final db = AppDatabase(NativeDatabase.memory());
    await tester.runAsync(() async {
      final settings = SettingsRepository(db);
      await settings.setGridMarkersMode('fixed');
      await settings.setDayStartHour(12);
      await settings.setDayEndHour(14);
      await settings.setGridFixedLesson(45);
      await settings.setGridFixedBreak(10);
    });
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          calendarViewSeedProvider.overrideWithValue('grid'),
        ],
        child: const MaterialApp(home: CalendarScreen()),
      ),
    );
    await tester.pumpAndSettle();
    // Generated boundaries: 12:00, 12:45, 12:55, 13:40.
    expect(find.text('12:00'), findsWidgets);
    expect(find.text('12:45'), findsWidgets);
    expect(find.text('12:55'), findsWidgets);
    expect(find.text('13:40'), findsWidgets);
    // One shaded break box per gap per day column (1 gap x 7 days).
    final breaks = find.byWidgetPredicate(
      (w) =>
          w.key is ValueKey &&
          (w.key as ValueKey).value.toString().startsWith('break_'),
    );
    expect(breaks, findsNWidgets(7));
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await tester.runAsync(() => db.close());
  });

  testWidgets('Saving without times shows validation', (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final db = AppDatabase(NativeDatabase.memory());
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: const MaterialApp(home: ClassEditScreen()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Class name'),
      'Physics',
    );
    // Toggle off by default: picking start leaves end empty.
    await tester.tap(find.text('Pick time').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(find.text('Pick time'), findsOneWidget);
    await tester.tap(find.text('Save class'));
    await tester.pumpAndSettle();
    expect(find.text('Select start and end times'), findsOneWidget);
    expect(await tester.runAsync(() => db.select(db.classes).get()), isEmpty);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await tester.runAsync(() => db.close());
  });

  testWidgets('Auto end fills end time when enabled', (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final db = AppDatabase(NativeDatabase.memory());
    await tester.runAsync(() async {
      final settings = SettingsRepository(db);
      await settings.setAutoEndTime(true);
      await settings.setDefaultDurationMinutes(60);
    });
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: const MaterialApp(home: ClassEditScreen()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Class name'),
      'Physics',
    );
    await tester.tap(find.text('Pick time').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    // End auto-filled: no empty time button left.
    expect(find.text('Pick time'), findsNothing);
    await tester.tap(find.text('Save class'));
    await tester.pumpAndSettle();
    expect(
      await tester.runAsync(() => db.select(db.classes).get()),
      hasLength(1),
    );
    expect(
      await tester.runAsync(() => db.select(db.scheduleItems).get()),
      hasLength(1),
    );
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await tester.runAsync(() => db.close());
  });

  testWidgets('Class form saves the picked color', (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final db = AppDatabase(NativeDatabase.memory());
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: const MaterialApp(home: ClassEditScreen()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Class name'),
      'Physics',
    );
    final dots = find.byWidgetPredicate(
      (w) =>
          w is Container &&
          (w.decoration as BoxDecoration?)?.shape == BoxShape.circle,
    );
    // Base palette + 1 custom picker (Default theme has no accents).
    expect(dots, findsNWidgets(classColorPalette.length + 1));
    await tester.tap(dots.at(1));
    await tester.pumpAndSettle();
    await pickClassTimes(tester, db);
    await tester.tap(find.text('Save class'));
    await tester.pumpAndSettle();
    final rows = await tester.runAsync(() => db.select(db.classes).get());
    expect(rows, hasLength(1));
    expect(rows!.single.colorValue, classColorPalette[1]);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await tester.runAsync(() => db.close());
  });

  testWidgets('Slot dialog auto-fills end from start', (tester) async {
    SlotDraft? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return TextButton(
                onPressed: () async {
                  result = await showDialog<SlotDraft>(
                    context: context,
                    builder: (_) =>
                        const ScheduleSlotDialog(autoEndMinutes: 90),
                  );
                },
                child: const Text('Open slot'),
              );
            },
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open slot'));
    await tester.pumpAndSettle();
    // Default 09:00 start; re-confirming it auto-sets end to 10:30.
    await tester.tap(find.text('9:00 AM'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(find.text('10:30 AM'), findsOneWidget);
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(result, isNotNull);
    expect(result!.startMinutes, 540);
    expect(result!.endMinutes, 630);
  });

  testWidgets('Absences screen renders Turkish with TR locale', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          absencesViewSeedProvider.overrideWithValue('list'),
        ],
        child: MaterialApp(
          locale: const Locale('tr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const AbsencesScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Devamsızlık'), findsOneWidget);
    expect(find.text('Kayıtlı devamsızlık yok.'), findsNothing);
    expect(find.text('Absences'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await tester.runAsync(() => db.close());
  });

  testWidgets('Settings groups sections into cards', (tester) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final db = AppDatabase(NativeDatabase.memory());
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: const MaterialApp(home: SettingsScreen()),
      ),
    );
    await tester.pumpAndSettle();
    await pumpForAsync(tester);
    for (final title in [
      'Languages',
      'Appearance',
      'Absences',
      'Academic years',
      'Schedule',
      'Calendar',
      'Data',
    ]) {
      expect(find.text(title), findsWidgets);
    }
    // Language picker offers system default plus English and Turkish.
    expect(find.text('System default'), findsOneWidget);
    expect(find.text('Türkçe'), findsOneWidget);
    // Folder data tiles live in the Data card.
    expect(find.text('Data folder'), findsOneWidget);
    expect(find.text('Export data'), findsOneWidget);
    expect(find.text('Import data'), findsOneWidget);
    await tester.tap(find.text('Export data'));
    await tester.pumpAndSettle();
    expect(find.text('Pick a data folder first'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await tester.runAsync(() => db.close());
  });

  test('Settings round-trip new prefs', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final settings = SettingsRepository(db);
    expect(await settings.localeOverride(), 'system');
    await settings.setLocaleOverride('tr');
    expect(await settings.localeOverride(), 'tr');
    expect(await settings.autoEndTime(), isFalse);
    await settings.setAutoEndTime(true);
    expect(await settings.autoEndTime(), isTrue);
    expect(await settings.dayStartHour(), 6);
    await settings.setDayStartHour(7);
    expect(await settings.dayStartHour(), 7);
    expect(await settings.portraitLock(), isFalse);
    await settings.setPortraitLock(true);
    expect(await settings.portraitLock(), isTrue);
    expect(await settings.focusWorkMinutes(), 25);
    await settings.setFocusWorkMinutes(45);
    expect(await settings.focusWorkMinutes(), 45);
    expect(await settings.focusBreakMinutes(), 5);
    await settings.setFocusBreakMinutes(15);
    expect(await settings.focusBreakMinutes(), 15);
    expect(await settings.menuProviderId(), '');
    await settings.setMenuProviderId('hacettepe');
    expect(await settings.menuProviderId(), 'hacettepe');
    await db.close();
  });

  testWidgets('Class picker follows the current theme accents', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final db = AppDatabase(NativeDatabase.memory());
    await tester.runAsync(() => SettingsRepository(db).setAppTheme('nord'));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: const MaterialApp(home: ClassEditScreen()),
      ),
    );
    await tester.pumpAndSettle();
    await pumpForAsync(tester);
    final dots = find.byWidgetPredicate(
      (w) =>
          w is Container &&
          (w.decoration as BoxDecoration?)?.shape == BoxShape.circle,
    );
    // 8 palette + Nord accents not already in the palette + 1 custom.
    final nordExtras = lookupAppTheme(
      'nord',
    ).accents.values.where((v) => !classColorPalette.contains(v)).length;
    expect(dots, findsNWidgets(classColorPalette.length + nordExtras + 1));
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await tester.runAsync(() => db.close());
  });

  testWidgets('Calendar view switch persists across screen rebuilds', (
    tester,
  ) async {
    final db = AppDatabase(NativeDatabase.memory());
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: const MaterialApp(home: _ViewSwapper(child: CalendarScreen())),
      ),
    );
    await tester.pumpAndSettle();
    // Starts in list view (empty days show placeholders, no time gutter).
    expect(find.text('—'), findsWidgets);
    expect(find.text('06:00'), findsNothing);
    await tester.tap(find.byTooltip('Time grid view'));
    await tester.pumpAndSettle();
    await pumpForAsync(tester);
    expect(find.text('—'), findsNothing);
    expect(find.text('06:00'), findsWidgets);
    // Saved to settings for the next app start.
    expect(
      await tester.runAsync(
        () => SettingsRepository(db).calendarView(),
      ),
      'grid',
    );
    // Navigate away and back within the same session: a fresh screen state
    // must keep the picked view, not reset to the app-start snapshot.
    await tester.tap(find.byKey(const ValueKey('swapper_toggle')));
    await tester.pumpAndSettle();
    expect(find.text('swapper_away'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('swapper_toggle')));
    await tester.pumpAndSettle();
    expect(find.text('—'), findsNothing);
    expect(find.text('06:00'), findsWidgets);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await tester.runAsync(() => db.close());
  });

  testWidgets('Absences toolbar fits a narrow phone screen', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final db = AppDatabase(NativeDatabase.memory());
    await tester.runAsync(
      () => db
          .into(db.classes)
          .insert(
            ClassesCompanion.insert(name: 'Math', colorValue: 0xFF4F6BED),
          ),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          absencesViewSeedProvider.overrideWithValue('list'),
        ],
        child: const MaterialApp(home: AbsencesScreen()),
      ),
    );
    await tester.pumpAndSettle();
    // Chips and the view switch are all laid out with no overflow.
    expect(find.text('All'), findsOneWidget);
    expect(find.byTooltip('Weeks grid view'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await tester.runAsync(() => db.close());
  });

  testWidgets('Absences switch moves into the AppBar on Android', (
    tester,
  ) async {
    // try/finally (not addTearDown): the binding verifies foundation
    // invariants before teardowns run.
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    try {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      final db = AppDatabase(NativeDatabase.memory());
      await tester.runAsync(
        () => db
            .into(db.classes)
            .insert(
              ClassesCompanion.insert(name: 'Math', colorValue: 0xFF4F6BED),
            ),
      );
      try {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [appDatabaseProvider.overrideWithValue(db)],
            child: MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: const AbsencesScreen(),
            ),
          ),
        );
        await pumpForAsync(tester);
        // The switch lives in the AppBar title row, not in the filter body.
        expect(find.byTooltip('Weeks grid view'), findsOneWidget);
        expect(
          find.descendant(
            of: find.byType(AppBar),
            matching: find.byType(SegmentedButton<String>),
          ),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
      } finally {
        await tester.runAsync(() => db.close());
      }
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('Absences view switch persists across screen rebuilds', (
    tester,
  ) async {
    final db = AppDatabase(NativeDatabase.memory());
    await tester.runAsync(
      () => db
          .into(db.classes)
          .insert(
            ClassesCompanion.insert(name: 'Math', colorValue: 0xFF4F6BED),
          ),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: const MaterialApp(home: _ViewSwapper(child: AbsencesScreen())),
      ),
    );
    await tester.pumpAndSettle();
    // Grid is the default: week columns instead of the empty-list message.
    expect(find.text('No absences recorded.'), findsNothing);
    expect(find.text('W1'), findsOneWidget);
    await tester.tap(find.byTooltip('List view'));
    await tester.pumpAndSettle();
    await pumpForAsync(tester);
    expect(
      await tester.runAsync(
        () => SettingsRepository(db).absencesView(),
      ),
      'list',
    );
    await tester.tap(find.byKey(const ValueKey('swapper_toggle')));
    await tester.pumpAndSettle();
    expect(find.text('swapper_away'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('swapper_toggle')));
    await tester.pumpAndSettle();
    // List view shows quotas without history or week columns.
    expect(find.text('No absences recorded.'), findsNothing);
    expect(find.text('W1'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await tester.runAsync(() => db.close());
  });

  testWidgets('Calendar lays out on a narrow phone screen', (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final db = AppDatabase(NativeDatabase.memory());
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: const MaterialApp(home: CalendarScreen()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Time grid view'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await tester.runAsync(() => db.close());
  });

  testWidgets('Calendar list scrolls vertically through busy days', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final db = AppDatabase(NativeDatabase.memory());
    await tester.runAsync(() async {
      final repo = ClassRepository(db);
      // Eight Monday meetings: the day column is far taller than the
      // viewport and must scroll instead of overflowing.
      for (var i = 0; i < 8; i++) {
        await repo.createClassWithSlots(
          ClassesCompanion.insert(
            name: 'Class $i',
            colorValue: 0xFF4F6BED,
          ),
          [
            ScheduleItemsCompanion.insert(
              classId: 0,
              dayOfWeek: 1,
              startMinutes: 480 + i * 60,
              endMinutes: 530 + i * 60,
              rotation: RotationKind.weekly,
            ),
          ],
        );
      }
    });
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: const MaterialApp(home: CalendarScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    final vertical = find.byWidgetPredicate(
      (w) => w is Scrollable && w.axis == Axis.vertical,
    );
    await tester.scrollUntilVisible(
      find.text('Class 7'),
      300,
      scrollable: vertical,
    );
    await tester.pumpAndSettle();
    expect(find.text('Class 7'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await tester.runAsync(() => db.close());
  });

  testWidgets('Bottom nav fits seven destinations on a narrow phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final db = AppDatabase(NativeDatabase.memory());
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: const ChronicleApp(),
      ),
    );
    await pumpForAsync(tester);
    // Seven destinations share ~360px in a fixed-geometry bar: every label
    // stays visible on a single line and icons never shift on tab switches
    // (the old stock bar wrapped "Absences" to two lines).
    const labels = [
      'Today',
      'Calendar',
      'Classes',
      'Tasks',
      'Absences',
      'Menu',
      'Settings',
    ];
    // Only bar labels sit inside an InkWell; body texts with the same
    // wording (e.g. screen titles) must not pollute the assertions.
    Finder barLabel(String label) => find.descendant(
      of: find.byType(InkWell),
      matching: find.text(label),
    );
    for (final label in labels) {
      expect(barLabel(label), findsOneWidget);
    }
    const navIcons = [
      Icons.dashboard_outlined,
      Icons.calendar_month_outlined,
      Icons.school_outlined,
      Icons.checklist_outlined,
      Icons.event_busy_outlined,
      Icons.restaurant_outlined,
      Icons.settings_outlined,
    ];
    // Only bar icons sit inside an InkWell; body icons (e.g. the empty
    // classes illustration) must not pollute the measurement.
    Finder barIcon(IconData icon) => find.descendant(
      of: find.byType(InkWell),
      matching: find.byIcon(icon),
    );
    List<double> iconCenters() => [
      for (final icon in navIcons) tester.getCenter(barIcon(icon)).dx,
    ];
    final before = iconCenters();
    expect(before, hasLength(7));
    // Switch tabs: labels stay and icon positions do not move.
    await tester.tap(barIcon(Icons.school_outlined));
    await pumpForAsync(tester);
    expect(find.text('No classes yet'), findsOneWidget);
    for (final label in labels) {
      expect(barLabel(label), findsOneWidget);
    }
    expect(iconCenters(), before);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await tester.runAsync(() => db.close());
  });

  testWidgets('Empty states keep text but no add buttons', (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final db = AppDatabase(NativeDatabase.memory());
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: const MaterialApp(home: ClassesScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('No classes yet'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Add class'), findsNothing);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: const MaterialApp(home: TasksScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('No tasks here'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Add task'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await tester.runAsync(() => db.close());
  });

  testWidgets('Focus screen applies persisted custom durations', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final db = AppDatabase(NativeDatabase.memory());
    await tester.runAsync(() async {
      final settings = SettingsRepository(db);
      await settings.setFocusWorkMinutes(45);
      await settings.setFocusBreakMinutes(15);
    });
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: const MaterialApp(home: FocusScreen()),
      ),
    );
    await tester.pumpAndSettle();
    await pumpForAsync(tester);
    expect(find.text('45:00'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await tester.runAsync(() => db.close());
  });
}

/// Test-only harness: toggles between [child] and a placeholder inside one
/// stable ProviderScope, simulating go_router navigation away and back.
class _ViewSwapper extends StatefulWidget {
  final Widget child;

  const _ViewSwapper({required this.child});

  @override
  State<_ViewSwapper> createState() => _ViewSwapperState();
}

class _ViewSwapperState extends State<_ViewSwapper> {
  bool _away = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          TextButton(
            key: const ValueKey('swapper_toggle'),
            onPressed: () => setState(() => _away = !_away),
            child: const Text('swapper_nav'),
          ),
          Expanded(
            child: _away
                ? const Center(child: Text('swapper_away'))
                : widget.child,
          ),
        ],
      ),
    );
  }
}
