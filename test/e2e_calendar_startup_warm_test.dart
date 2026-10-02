import 'package:chronicle/data/database.dart';
import 'package:chronicle/data/repositories.dart';
import 'package:chronicle/providers.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'e2e_harness.dart';

/// StartupRunner warms the current calendar week's occurrence cache
/// post-frame, so the first calendar visit paints data instead of flashing
/// a loading spinner. Nothing else reads this exact week range before the
/// calendar opens (the dashboard watches single-day ranges), so a hot
/// cache here proves the warming ran.
void main() {
  testWidgets('startup warms the current calendar week', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    await tester.runAsync(() async {
      await seedClassToday(ClassRepository(db), 'Warmedish');
    });
    await bootApp(tester, db);

    final container = ProviderScope.containerOf(
      tester.element(find.byType(NavigationRail)),
    );
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final (start, end) = calendarWeekRange(now, 1);
    final occurrences = container.read(occurrencesProvider((start, end)));
    expect(occurrences.hasValue, isTrue);
    expect(occurrences.value!.any((o) => o.date == today), isTrue);

    await shutdownApp(tester, db);
  });
}
