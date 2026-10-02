import 'package:chronicle/data/database.dart';
import 'package:chronicle/data/repositories.dart';
import 'package:chronicle/l10n/l10n.dart';
import 'package:chronicle/providers.dart';
import 'package:chronicle/screens/menu_screen.dart';
import 'package:chronicle/services/menu/menu_provider.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'e2e_harness.dart';

class _FailingMenuProvider implements MenuProvider {
  @override
  String get id => 'test-cache';

  @override
  String get displayName => 'Test cache';

  @override
  Map<String, String> get locations => const {'1': 'Hall'};

  @override
  Future<MenuDay> fetchDay(DateTime date, String locationId) =>
      throw const MenuFetchException('offline');

  @override
  bool isCacheValid(MenuDay day) => true;

  @override
  void close() {}
}

MenuDay _cachedDay() => MenuDay(
  date: DateTime.now(),
  locationId: '1',
  locationName: 'Hall',
  meals: const [
    ServedMeal(
      kind: 'ogle',
      serviceHours: '11:30-14:00',
      dishes: [MenuDish(name: 'Mercimek Çorbası', category: 'Çorba')],
    ),
  ],
);

Future<void> _pumpMenu(
  WidgetTester tester,
  AppDatabase db,
  MenuProvider provider,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: MenuScreen(provider: provider),
      ),
    ),
  );
  await tester.pumpAndSettle();
  await pumpForAsync(tester);
}

/// Offline with a cached day must still render the cached dishes;
/// offline with nothing cached must show the error state, not a spinner.
void main() {
  testWidgets('menu falls back to cache when the fetch fails', (
    tester,
  ) async {
    final db = AppDatabase(NativeDatabase.memory());
    await tester.runAsync(
      () => MenuCacheRepository(db).storeDay(
        'test-cache',
        '1',
        todayIso(),
        _cachedDay(),
      ),
    );
    await _pumpMenu(tester, db, _FailingMenuProvider());

    expect(find.text('Mercimek Çorbası'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await shutdownApp(tester, db);
  });

  testWidgets('menu shows the error state with no cache and no network', (
    tester,
  ) async {
    final db = AppDatabase(NativeDatabase.memory());
    await _pumpMenu(tester, db, _FailingMenuProvider());

    expect(find.text('Could not load menu'), findsOneWidget);

    await shutdownApp(tester, db);
  });
}
