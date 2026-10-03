import 'package:chronicle/data/database.dart';
import 'package:chronicle/data/repositories.dart';
import 'package:chronicle/l10n/l10n.dart';
import 'package:chronicle/providers.dart';
import 'package:chronicle/screens/menu_screen.dart';
import 'package:chronicle/services/menu/hacettepe_provider.dart';
import 'package:chronicle/services/menu/itu_provider.dart';
import 'package:chronicle/services/menu/menu_provider.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'e2e_harness.dart';

const _htmlHeaders = {'content-type': 'text/html; charset=utf-8'};

// Lowercase on purpose: the full stack must normalize names (titleCaseTr)
// before they reach the screen and the cache.
const _ituLunch = '''
<div id="pnlYemekMenu"><table><tbody>
<tr><td><a>Çorba</a></td><td><a>mercimek çorbası</a></td></tr>
<tr><td><a>Ana Yemek</a></td><td><a>kuru köfte</a></td></tr>
</tbody></table></div>
''';

// Mirrors the live unpublished page: no menu table, just the marker.
const _ituYok = '''
<div id="pnlYemekMenu"></div><div id="pnlYemekYok">
<p class="dining-menu__text">Yemek bilgisi henüz girilmemiştir.</p>
</div>
''';

const _hacBreakfastOnly = '''
<section id="sabah" class="tab-content"><div class="view-content daily-view">
<div class="kahvalti-liste-card"><ul class="kahvalti-items">
<li><i class="fa-solid fa-circle-dot"></i>Çay</li>
<li><i class="fa-solid fa-circle-dot"></i>Simit</li>
</ul></div></div></section>
<section id="ogle" class="tab-content"><div class="view-content daily-view">
<div class="empty-state"><p>none</p></div></div>
<div class="weekly-view"><div class="menu-card" data-id="9"
data-title="Leaked Dish" data-cal="100"
data-category="ANAYEMEK"></div></div></section>
<section id="aksam" class="tab-content"><div class="view-content daily-view">
<div class="empty-state"><p>none</p></div></div></section>
<section id="vegan" class="tab-content"><div class="view-content daily-view">
<div class="empty-state"><p>none</p></div></div></section>
''';

const _ituVeganLunch = '''
<div id="pnlYemekMenu"><table><tbody>
<tr><td><a>Çorba</a></td><td><a>arpa şehriye çorbası</a></td></tr>
<tr><td><a>Vegan/Vejetaryen Ana Yemek</a></td><td><a>etsiz havuçlu yeşil mercimek</a></td></tr>
</tbody></table></div>
''';

MockClient _ituClient({required bool publishLunch, String? veganLunch}) {
  return MockClient((request) async {
    final tip = request.url.queryParameters['tip'] ?? '';
    if (tip.contains('vegan')) {
      return http.Response(veganLunch ?? _ituYok, 200, headers: _htmlHeaders);
    }
    final body = publishLunch && tip.contains('ogle') ? _ituLunch : _ituYok;
    return http.Response(body, 200, headers: _htmlHeaders);
  });
}

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

/// Full-stack menu journeys: real providers over stubbed HTTP, real cache
/// repository, real page. Locks in the reliability fixes: unpublished days
/// show the empty state (never the error view) and are never cached, mixed
/// days keep the published meal, and breakfast-only days open on breakfast.
void main() {
  testWidgets('itu unpublished day shows empty and caches nothing', (
    tester,
  ) async {
    final db = AppDatabase(NativeDatabase.memory());
    await _pumpMenu(tester, db, ItuMenuProvider(_ituClient(publishLunch: false)));

    expect(find.text('No menu published for this day'), findsOneWidget);
    expect(find.text('Could not load menu'), findsNothing);

    final cached = await tester.runAsync(
      () => MenuCacheRepository(db).cachedDay('itu', 'genel', todayIso()),
    );
    expect(cached, isNull);

    await shutdownApp(tester, db);
  });

  testWidgets('itu mixed day keeps lunch and stores normalized names', (
    tester,
  ) async {
    final db = AppDatabase(NativeDatabase.memory());
    await _pumpMenu(tester, db, ItuMenuProvider(_ituClient(publishLunch: true)));

    expect(find.text('Mercimek Çorbası'), findsOneWidget);
    expect(find.text('Kuru Köfte'), findsOneWidget);

    await tester.tap(find.text('Dinner'));
    await tester.pumpAndSettle();
    expect(find.text('No menu published for this day'), findsOneWidget);

    await tester.tap(find.text('Lunch'));
    await tester.pumpAndSettle();
    expect(find.text('Mercimek Çorbası'), findsOneWidget);

    final cached = await tester.runAsync(
      () => MenuCacheRepository(db).cachedDay('itu', 'genel', todayIso()),
    );
    final lunch = cached!.day.meals.firstWhere((m) => m.kind == 'ogle');
    expect(
      lunch.dishes.map((d) => d.name),
      ['Mercimek Çorbası', 'Kuru Köfte'],
    );

    await shutdownApp(tester, db);
  });

  testWidgets('itu vegan menu is separate from the standard menu', (
    tester,
  ) async {
    final db = AppDatabase(NativeDatabase.memory());
    await _pumpMenu(
      tester,
      db,
      ItuMenuProvider(
        _ituClient(publishLunch: true, veganLunch: _ituVeganLunch),
      ),
    );

    // Standard menu by default; both locations offered.
    expect(find.text('Mercimek Çorbası'), findsOneWidget);
    expect(find.text('Genel'), findsOneWidget);
    expect(find.text('Vegan'), findsOneWidget);

    await tester.tap(find.text('Vegan'));
    await tester.pumpAndSettle();
    await pumpForAsync(tester);
    expect(find.text('Etsiz Havuçlu Yeşil Mercimek'), findsOneWidget);
    expect(find.text('Mercimek Çorbası'), findsNothing);

    final cached = await tester.runAsync(
      () => MenuCacheRepository(db).cachedDay('itu', 'vegan', todayIso()),
    );
    expect(cached, isNotNull);
    expect(cached!.day.locationName, 'Vegan');

    await shutdownApp(tester, db);
  });

  testWidgets('hacettepe breakfast-only day opens on breakfast', (
    tester,
  ) async {
    final db = AppDatabase(NativeDatabase.memory());
    final provider = HacettepeMenuProvider(
      MockClient(
        (_) async => http.Response(_hacBreakfastOnly, 200, headers: _htmlHeaders),
      ),
    );
    await _pumpMenu(tester, db, provider);

    // Auto-selected sabah (lunch would be empty); other days' weekly
    // cards never leak in.
    expect(find.text('Simit'), findsOneWidget);
    expect(find.text('Leaked Dish'), findsNothing);

    await tester.tap(find.text('Lunch'));
    await tester.pumpAndSettle();
    expect(find.text('No menu published for this day'), findsOneWidget);

    final cached = await tester.runAsync(
      () => MenuCacheRepository(db).cachedDay('hacettepe', '1', todayIso()),
    );
    expect(cached, isNotNull);

    await shutdownApp(tester, db);
  });
}
