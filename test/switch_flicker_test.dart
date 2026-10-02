import 'package:chronicle/data/database.dart';
import 'package:chronicle/data/repositories.dart';
import 'package:chronicle/data/tables.dart';
import 'package:chronicle/providers.dart';
import 'package:chronicle/screens/calendar_screen.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('view switch never flashes loading', (tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
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
    });
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: const MaterialApp(home: CalendarScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(CircularProgressIndicator), findsNothing);

    Future<void> switchAndScan(String tooltip) async {
      await tester.tap(find.byTooltip(tooltip));
      // Scan the next 30 frames for any loading flash.
      for (var i = 0; i < 30; i++) {
        await tester.pump(const Duration(milliseconds: 16));
        expect(
          find.byType(CircularProgressIndicator),
          findsNothing,
          reason: 'loading flash on switch to $tooltip at frame $i',
        );
      }
      await tester.pumpAndSettle();
    }

    await switchAndScan('Time grid view');
    await switchAndScan('List view');
    await switchAndScan('Time grid view');

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await tester.runAsync(() => db.close());
  });

  testWidgets('view switch keeps both views alive', (tester) async {    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
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
    });
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: const MaterialApp(home: CalendarScreen()),
      ),
    );
    await tester.pumpAndSettle();

    // Default list view: the grid stays mounted offstage, so switching
    // back needs no rebuild, no scroll reset and no today-jump flash.
    expect(find.text('Physics'), findsOneWidget);
    expect(find.text('Physics', skipOffstage: false), findsNWidgets(2));

    await tester.tap(find.byTooltip('Time grid view'));
    await tester.pumpAndSettle();
    expect(find.text('Physics'), findsOneWidget);
    expect(find.text('Physics', skipOffstage: false), findsNWidgets(2));

    await tester.tap(find.byTooltip('List view'));
    await tester.pumpAndSettle();
    expect(find.text('Physics'), findsOneWidget);
    expect(find.text('Physics', skipOffstage: false), findsNWidgets(2));

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await tester.runAsync(() => db.close());
  });

  testWidgets('first run shows skeleton then content at once', (tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
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
    });
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          // Hold one gate input back deterministically: the skeleton
          // must own the early frames, content arrives all at once.
          dayRangeProvider.overrideWith((ref) async {
            await Future<void>.delayed(const Duration(milliseconds: 200));
            return (start: 360, end: 1320);
          }),
        ],
        child: const MaterialApp(home: CalendarScreen()),
      ),
    );
    // Fresh providers: the first frames must show the loading
    // skeleton (never a spinner, never half-loaded tiles).
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 16));
      expect(
        find.byType(CircularProgressIndicator),
        findsNothing,
        reason: 'spinner flash on first run at frame $i',
      );
      expect(
        find.text('Physics'),
        findsNothing,
        reason: 'half-loaded content on first run at frame $i',
      );
    }
    await tester.pumpAndSettle();
    expect(find.text('Physics'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await tester.runAsync(() => db.close());
  });

  testWidgets('warmed container paints content on the first frame', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
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
    });
    // Same warm main() performs before runApp: every provider the
    // calendar gate waits on resolves from the root container.
    final container = (await tester.runAsync(() async {
      final c = ProviderContainer(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
      );
      await warmCalendarWeek(c);
      return c;
    }))!;
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: CalendarScreen()),
      ),
    );
    // Exactly one frame: content must already be there — no skeleton,
    // no spinner, no pop-in on the next frames.
    await tester.pump();
    expect(find.text('Physics'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Physics'), findsOneWidget);

    // Drop provider subscriptions before teardown: drift's close waits
    // out live watch streams, and disposal timers must flush inside
    // the settling below, not after the tree is gone.
    container.dispose();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await tester.runAsync(() => db.close());
  });
}
