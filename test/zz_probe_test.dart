import 'package:chronicle/data/database.dart';
import 'package:chronicle/data/repositories.dart';
import 'package:chronicle/data/tables.dart';
import 'package:chronicle/providers.dart';
import 'package:chronicle/screens/class_edit_screen.dart';
import 'package:chronicle/screens/dashboard_screen.dart';
import 'package:chronicle/screens/grades_screen.dart';
import 'package:chronicle/screens/schedule_slot_dialog.dart';
import 'package:chronicle/screens/settings_screen.dart';
import 'package:chronicle/screens/year_widgets.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> narrow(WidgetTester tester) async {
  tester.view.physicalSize = const Size(360, 700);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

void main() {
  testWidgets('probe dashboard populated 360px', (tester) async {
    await narrow(tester);
    final db = AppDatabase(NativeDatabase.memory());
    await tester.runAsync(() async {
      final repo = ClassRepository(db);
      final id = await repo.create(
        ClassesCompanion.insert(
          name: 'A very long class name that certainly wraps around',
          colorValue: 0xFF4F6BED,
        ),
      );
      await repo.createScheduleItem(
        ScheduleItemsCompanion.insert(
          classId: id,
          dayOfWeek: DateTime.now().weekday,
          startMinutes: 540,
          endMinutes: 600,
          rotation: RotationKind.weekly,
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
    await tester.runAsync(() => db.close());
  });

  testWidgets('probe slot dialog 360px', (tester) async {
    await narrow(tester);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showDialog(
                context: context,
                builder: (_) => const ScheduleSlotDialog(),
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.runAsync(() => Future<void>.value());
  });

  testWidgets('probe year dialog 360px', (tester) async {
    await narrow(tester);
    final db = AppDatabase(NativeDatabase.memory());
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: MaterialApp(
          home: Scaffold(
            body: Consumer(
              builder: (context, ref, _) => TextButton(
                onPressed: () => showYearDialog(context, ref),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.runAsync(() => db.close());
  });

  testWidgets('probe grades + settings-fixed-editor 360px', (tester) async {
    await narrow(tester);
    final db = AppDatabase(NativeDatabase.memory());
    await tester.runAsync(() async {
      final settings = SettingsRepository(db);
      await settings.setGridMarkersMode('fixed');
    });
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: const MaterialApp(home: GradesScreen()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: const MaterialApp(home: SettingsScreen()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.runAsync(
      () => Future.delayed(const Duration(milliseconds: 300)),
    );
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await tester.runAsync(() => db.close());
  });

  testWidgets('probe class form 360px', (tester) async {
    await narrow(tester);
    final db = AppDatabase(NativeDatabase.memory());
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: const MaterialApp(home: ClassEditScreen()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.runAsync(() => db.close());
  });
}
