import 'package:chronicle/data/database.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'e2e_harness.dart';

/// A focus session run to completion through the full app must be recorded
/// in history/stats. Uses a 1-minute custom work duration (the shortest the
/// UI allows) plus fake-async time control, so nothing waits real minutes.
void main() {
  testWidgets('completed focus session is recorded', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    await bootApp(tester, db);

    await goTab(tester, Icons.checklist_outlined);
    await tester.tap(find.byIcon(Icons.timer_outlined));
    await tester.pumpAndSettle();
    await pumpForAsync(tester);
    expect(find.text('25:00'), findsOneWidget);

    // Shortest possible duration through the UI: the work row's custom
    // chip (first 'Custom' on screen) + the custom-minutes dialog.
    await tester.tap(find.text('Custom').first);
    await tester.pumpAndSettle();
    final dialog = find.byType(AlertDialog);
    expect(dialog, findsOneWidget);
    await tester.enterText(
      find.descendant(of: dialog, matching: find.byType(TextField)),
      '1',
    );
    await tester.tap(
      find.descendant(of: dialog, matching: find.text('Save')),
    );
    await tester.pumpAndSettle();
    await pumpForAsync(tester);
    expect(find.text('01:00'), findsOneWidget);

    // Run it to completion with fake time (mirrors the screen-level
    // 'Focus timer completes a short session' test). No pumpAndSettle
    // while the periodic timer is active.
    await tester.tap(find.text('Start focus session'));
    await tester.pump(const Duration(seconds: 61));
    expect(find.text('Break'), findsOneWidget);

    final sessions = await tester.runAsync(
      () => db.select(db.pomodoroSessions).get(),
    );
    expect(sessions, hasLength(1));
    expect(sessions!.single.workMinutes, 1);
    expect(find.text('today'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);

    // Stop the break timer so teardown can settle.
    await tester.tap(find.text('Skip break'));
    await tester.pumpAndSettle();

    await shutdownApp(tester, db);
  });
}
