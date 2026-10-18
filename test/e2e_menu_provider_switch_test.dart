import 'dart:io';

import 'package:chronicle/data/database.dart';
import 'package:chronicle/data/repositories.dart';
import 'package:chronicle/services/menu/itu_provider.dart';
import 'package:chronicle/services/menu/menu_sources.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'e2e_harness.dart';

const _htmlHeaders = {'content-type': 'text/html; charset=utf-8'};

// Lowercase on purpose: the full stack must normalize names (titleCaseTr)
// before they reach the screen.
const _ituLunch = '''
<div id="pnlYemekMenu"><table><tbody>
<tr><td><a>Çorba</a></td><td><a>mercimek çorbası</a></td></tr>
<tr><td><a>Ana Yemek</a></td><td><a>kuru köfte</a></td></tr>
</tbody></table></div>
''';

// Second servable meal: same table shape as lunch, distinct dishes.
const _ituDinner = '''
<div id="pnlYemekMenu"><table><tbody>
<tr><td><a>Çorba</a></td><td><a>ezogelin çorbası</a></td></tr>
<tr><td><a>Ana Yemek</a></td><td><a>tavuk sote</a></td></tr>
</tbody></table></div>
''';

const _ituYok = '''
<div id="pnlYemekMenu"></div><div id="pnlYemekYok">
<p class="dining-menu__text">Yemek bilgisi henüz girilmemiştir.</p>
</div>
''';

/// Serves lunch for ogle tips and dinner for aksam tips, mirroring the
/// live page split (one AJAX partial per meal).
MockClient _twoMealClient() {
  return MockClient((request) async {
    final tip = request.url.queryParameters['tip'] ?? '';
    if (tip.contains('vegan')) {
      return http.Response(_ituYok, 200, headers: _htmlHeaders);
    }
    if (tip.contains('aksam')) {
      return http.Response(_ituDinner, 200, headers: _htmlHeaders);
    }
    if (tip.contains('ogle')) {
      return http.Response(_ituLunch, 200, headers: _htmlHeaders);
    }
    return http.Response(_ituYok, 200, headers: _htmlHeaders);
  });
}

/// Points the full-app menu registry at a MockClient-backed ITU provider,
/// the same injection e2e_menu_test does at the screen level. The menu
/// page and the startup widget push both create providers through
/// [menuSources], so this covers every fetch path in the booted app.
void _useMockItu(MockClient client) {
  final original = menuSources['itu']!;
  menuSources['itu'] = (
    name: original.name,
    create: () => ItuMenuProvider(client),
  );
  addTearDown(() {
    menuSources['itu'] = original;
  });
}

/// Picks ITU in the settings UI: opens the dining-menu source dropdown
/// and taps the ITU entry.
Future<void> _pickItuInSettings(WidgetTester tester) async {
  await goTab(tester, Icons.settings_outlined);
  final field = find.widgetWithText(
    DropdownButtonFormField<String>,
    'Menu source',
  );
  await tester.scrollUntilVisible(
    field,
    200,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
  await tester.tap(field);
  await tester.pumpAndSettle();
  await tester.tap(find.text('ITU'));
  await tester.pumpAndSettle();
  await pumpForAsync(tester);
}

/// Full-app provider journeys: picking a source in settings fills the
/// menu page, the choice survives a restart, and the meal switcher steps
/// between the mocked lunch and dinner.
void main() {
  testWidgets(
    'picking ITU in settings shows its dishes, survives restart',
    (tester) async {
      final tmp = (await tester.runAsync(
        () => Directory.systemTemp.createTemp('e2e-menu-switch'),
      ))!;
      _useMockItu(_twoMealClient());
      final file = File('${tmp.path}/c.db');
      var db = AppDatabase(NativeDatabase(file));
      try {
        await bootApp(tester, db);

        // No source picked yet: the menu tab shows the empty state.
        await goTab(tester, Icons.restaurant_outlined);
        expect(
          find.text('Choose a menu source in Settings'),
          findsOneWidget,
        );

        await _pickItuInSettings(tester);
        expect(
          await tester.runAsync(
            () => SettingsRepository(db).menuProviderId(),
          ),
          'itu',
        );

        await goTab(tester, Icons.restaurant_outlined);
        await pumpForAsync(tester);
        expect(find.text('Mercimek Çorbası'), findsOneWidget);
        expect(find.text('Kuru Köfte'), findsOneWidget);

        // Same file, fresh boot: the menu still serves without re-picking.
        db = await restartApp(tester, db, file);
        await goTab(tester, Icons.restaurant_outlined);
        expect(find.text('Mercimek Çorbası'), findsOneWidget);
        expect(find.text('Kuru Köfte'), findsOneWidget);
      } finally {
        await shutdownApp(tester, db);
        await tester.runAsync(() => tmp.delete(recursive: true));
      }
    },
  );

  testWidgets('meal switcher steps to the next servable meal', (
    tester,
  ) async {
    final tmp = (await tester.runAsync(
      () => Directory.systemTemp.createTemp('e2e-menu-meals'),
    ))!;
    _useMockItu(_twoMealClient());
    final file = File('${tmp.path}/c.db');
    final db = AppDatabase(NativeDatabase(file));
    try {
      await tester.runAsync(
        () => SettingsRepository(db).setMenuProviderId('itu'),
      );
      await bootApp(tester, db);
      await goTab(tester, Icons.restaurant_outlined);
      await pumpForAsync(tester);

      // Lunch first; dinner dishes hidden until the switch.
      expect(find.text('Mercimek Çorbası'), findsOneWidget);
      expect(find.text('Tavuk Sote'), findsNothing);

      await tester.tap(find.text('Dinner'));
      await tester.pumpAndSettle();
      await pumpForAsync(tester);
      expect(find.text('Ezogelin Çorbası'), findsOneWidget);
      expect(find.text('Tavuk Sote'), findsOneWidget);
      expect(find.text('Mercimek Çorbası'), findsNothing);
    } finally {
      await shutdownApp(tester, db);
      await tester.runAsync(() => tmp.delete(recursive: true));
    }
  });
}
