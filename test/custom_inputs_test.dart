import 'package:chronicle/data/database.dart';
import 'package:chronicle/data/repositories.dart';
import 'package:chronicle/providers.dart';
import 'package:chronicle/screens/focus_screen.dart';
import 'package:chronicle/screens/schedule_slot_dialog.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Focus custom chip opens minutes dialog and saves', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final db = AppDatabase(NativeDatabase.memory());
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: const MaterialApp(home: FocusScreen()),
      ),
    );
    await tester.pumpAndSettle();

    // Work (25) and break (5) are presets, so both custom chips read
    // 'Custom'. The first one belongs to the work row.
    expect(find.text('Custom'), findsNWidgets(2));
    await tester.tap(find.text('Custom').first);
    await tester.pumpAndSettle();
    expect(find.text('Custom minutes'), findsOneWidget);

    // Invalid input stays open with an inline error.
    await tester.enterText(find.byType(TextField), '0');
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pump();
    expect(find.text('Custom minutes'), findsOneWidget);
    expect(find.text('Enter a non-negative whole number'), findsOneWidget);

    // Valid input applies and persists.
    await tester.enterText(find.byType(TextField), '35');
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();
    expect(find.text('35:00'), findsOneWidget);
    expect(find.text('35 min'), findsOneWidget);
    expect(
      await tester.runAsync(() => SettingsRepository(db).focusWorkMinutes()),
      35,
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await tester.runAsync(() => db.close());
  });

  testWidgets('Slot preset chip sets start time', (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final db = AppDatabase(NativeDatabase.memory());
    SlotDraft? result;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          slotTimePresetsProvider.overrideWith(
            (ref) => Future.value([480, 540]),
          ),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  result = await showDialog<SlotDraft>(
                    context: context,
                    builder: (_) => ScheduleSlotDialog(
                      initial: const SlotDraft(
                        dayOfWeek: 1,
                        startMinutes: 600,
                        endMinutes: 660,
                      ),
                      autoEndMinutes: 60,
                    ),
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('08:00'), findsOneWidget);
    expect(find.text('09:00'), findsOneWidget);
    await tester.tap(find.text('08:00'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();
    expect(result, isNotNull);
    expect(result!.startMinutes, 480);
    // Auto-end follows the preset like a manual pick.
    expect(result!.endMinutes, 540);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await tester.runAsync(() => db.close());
  });

  testWidgets('Slot presets round-trip and fall back on garbage', (
    tester,
  ) async {
    final db = AppDatabase(NativeDatabase.memory());
    final repo = SettingsRepository(db);
    await tester.runAsync(() async {
      expect(
        await repo.slotTimePresets(),
        SettingsRepository.defaultSlotTimePresets,
      );
      await repo.setSlotTimePresets([555, 510]);
      // Sorted, deduped on the way out.
      expect(await repo.slotTimePresets(), [510, 555]);
      await repo.set(SettingsRepository.slotTimePresetsKey, 'nonsense, 25:99');
      expect(
        await repo.slotTimePresets(),
        SettingsRepository.defaultSlotTimePresets,
      );
    });
    await tester.runAsync(() => db.close());
  });
}
