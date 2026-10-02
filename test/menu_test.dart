import 'dart:async';
import 'dart:convert';

import 'package:chronicle/data/database.dart';
import 'package:chronicle/data/repositories.dart';
import 'package:chronicle/l10n/l10n.dart';
import 'package:chronicle/providers.dart';
import 'package:chronicle/screens/menu_screen.dart';
import 'package:chronicle/services/menu/hacettepe_provider.dart';
import 'package:chronicle/services/menu/itu_provider.dart';
import 'package:chronicle/services/menu/menu_provider.dart';
import 'package:chronicle/services/menu/menu_sources.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const _fixture = '''
<section id="ogle" class="tab-content">
<div class="daily-view">
<div class="menu-summary-info">
<div class="summary-item time-item"><span><small>Servis Saati</small><strong>12:00 - 13:30</strong></span></div>
<div class="summary-item"><span><strong>1078</strong> kcal</span></div>
</div>
<div class="menu-grid"><div class="menu-card-wrapper">
<div class="menu-card" data-id="1" data-title="Mantı" data-cal="490" data-category="ANAYEMEK" data-alerjenler='[{"kodu":"A","aciklama":"gluten"}]'></div>
<div class="menu-card" data-id="2" data-title="Çorba" data-cal="" data-category="ÇORBA"></div>
</div></div>
</div>
</section>
<section id="sabah" class="tab-content">
<div class="daily-view"><ul class="kahvalti-items"><li>Çay</li><li>Kek</li></ul></div>
</section>
''';

/// Mirrors the real ITU `yemek-menu.aspx` partial: `#pnlYemekMenu` table,
/// category in the first cell, dish nutrition/allergen links in the second.
const _ituOgleFixture = '''
<div id="pnlYemekMenu">
<table class="table table-bordered"><tbody>
<tr><td><a>Çorba</a></td>
<td><div><div style="width: 90%; float: left;">
<a href="https://bidb.itu.edu.tr/ExternalPages/sks/yemek-menu-v2/besin-degerleri.aspx?yemek=294">TUTMAÇ ÇORBASI</a>
</div><div style="width: 10%; float: right;">
<a href="https://bidb.itu.edu.tr/ExternalPages/sks/yemek-menu-v2/alerjen-detay.aspx?yemek=294"></a>
</div></div></td></tr>
<tr><td><a>Ana Yemek</a></td>
<td><div><div style="width: 90%; float: left;">
<a href="https://bidb.itu.edu.tr/ExternalPages/sks/yemek-menu-v2/besin-degerleri.aspx?yemek=694">ORMAN KEBABI</a>
</div><div style="width: 10%; float: right;">
<a href="https://bidb.itu.edu.tr/ExternalPages/sks/yemek-menu-v2/alerjen-detay.aspx?yemek=694"></a>
</div></div></td></tr>
<tr><td><a>Yan Yemek</a></td>
<td><div><div style="width: 90%; float: left;">
<a href="https://bidb.itu.edu.tr/ExternalPages/sks/yemek-menu-v2/besin-degerleri.aspx?yemek=4114">İÇ PİLAV</a>
</div><div style="width: 10%; float: right;">
<a></a>
</div></div></td></tr>
</tbody></table>
</div>
''';

const _ituAksamFixture = '''
<div id="pnlYemekMenu">
<table class="table table-bordered"><tbody>
<tr><td><a>Çorba</a></td>
<td><div><div style="width: 90%; float: left;">
<a href="https://bidb.itu.edu.tr/ExternalPages/sks/yemek-menu-v2/besin-degerleri.aspx?yemek=301">TEL ŞEHRİYELİ HAVUÇ ÇORBASI</a>
</div><div style="width: 10%; float: right;"><a></a></div></div></td></tr>
<tr><td><a>Tatlı-Salata-Meyve-İçecek Çeşitleri</a></td>
<td><div><div style="width: 90%; float: left;">
<a href="https://bidb.itu.edu.tr/ExternalPages/sks/yemek-menu-v2/besin-degerleri.aspx?yemek=4550">MOZAİK PASTA</a>
</div><div style="width: 10%; float: right;"><a></a></div></div></td></tr>
</tbody></table>
</div>
''';

/// Single dish with an allergen link, for enrichment tests.
const _ituOgleEnrichFixture = '''
<div id="pnlYemekMenu">
<table class="table table-bordered"><tbody>
<tr><td><a>Çorba</a></td>
<td><div><div style="width: 90%; float: left;">
<a href="https://bidb.itu.edu.tr/ExternalPages/sks/yemek-menu-v2/besin-degerleri.aspx?yemek=294">TUTMAÇ ÇORBASI</a>
</div><div style="width: 10%; float: right;">
<a href="https://bidb.itu.edu.tr/ExternalPages/sks/yemek-menu-v2/alerjen-detay.aspx?yemek=294"></a>
</div></div></td></tr>
</tbody></table>
</div>
''';

/// Dish without an allergen link: no allergens even with enrichment.
const _ituNoAllergenFixture = '''
<div id="pnlYemekMenu">
<table class="table table-bordered"><tbody>
<tr><td><a>Yan Yemek</a></td>
<td><div><div style="width: 90%; float: left;">
<a href="https://bidb.itu.edu.tr/ExternalPages/sks/yemek-menu-v2/besin-degerleri.aspx?yemek=4114">İÇ PİLAV</a>
</div><div style="width: 10%; float: right;"><a></a></div></div></td></tr>
</tbody></table>
</div>
''';

/// Unpublished meal: title but no menu table.
const _ituEmptyMealFixture = '''
<h2><span id="lbBaslik">30 Eylül Akşam Yemeği</span></h2>
<div id="pnlYemekMenu"></div>
''';

/// Mirrors the real `besin-degerleri.aspx` page: dish name in `#lblYemekAdi`,
/// nutrients as single-cell rows with the value in a right-aligned span.
const _ituNutritionFixture = '''
<span id="lblYemekAdi">TUTMAÇ ÇORBASI</span>
<table class="table table-bordered"><tbody>
<tr><td>Enerji (kcal) <span class="pull-right">114,2027</span></td></tr>
<tr><td>Kolesterol (mg) <span class="pull-right">2,42</span></td></tr>
</tbody></table>
''';

/// Mirrors the real `alerjen-detay.aspx` page: full-text descriptions in
/// `.allergen-detail__content-inner li`, with duplicates.
const _ituAllergenFixture = '''
<div class="allergen-detail__content-inner"><ul>
<li>Yumurta ve yumurta ürünleri</li>
<li>Gluten içeren tahıllar ve bunların ürünleri</li>
<li>Süt ve süt ürünleri (laktoz dahil)</li>
<li>Yumurta ve yumurta ürünleri</li>
</ul></div>
''';

class _FakeMenuProvider implements MenuProvider {
  MenuDay? day;
  bool fail = false;

  @override
  String get id => 'fake';

  @override
  String get displayName => 'Fake';

  @override
  Map<String, String> get locations => const {'1': 'Test'};

  @override
  Future<MenuDay> fetchDay(DateTime date, String locationId) async {
    if (fail || day == null) throw const MenuFetchException('offline');
    return day!;
  }

  @override
  bool isCacheValid(MenuDay day) => true;

  @override
  void close() {}
}

/// Two-campus fake mirroring the real Hacettepe locations, for testing the
/// Beytepe/Sıhhiye switch layout on narrow phone screens.
class _TwoLocationFakeMenuProvider implements MenuProvider {
  MenuDay? day;

  @override
  String get id => 'fake2';

  @override
  String get displayName => 'Fake2';

  @override
  Map<String, String> get locations => const {
    '1': 'Beytepe',
    '2': 'Sıhhiye',
  };

  @override
  Future<MenuDay> fetchDay(DateTime date, String locationId) async {
    if (day == null) throw const MenuFetchException('offline');
    return day!;
  }

  @override
  bool isCacheValid(MenuDay day) => true;

  @override
  void close() {}
}

MenuDay _fakeDay() => MenuDay(
  date: DateTime(2026, 9, 21),
  locationId: '1',
  locationName: 'Test',
  allergenLegend: const {'A': 'Test allergen'},
  meals: const [
    ServedMeal(
      kind: 'ogle',
      serviceHours: '12:00 - 13:30',
      totalKcal: 1078,
      dishes: [
        MenuDish(
          name: 'Mantı',
          category: 'ANAYEMEK',
          kcal: 490,
          allergens: ['A'],
        ),
      ],
    ),
  ],
);

/// Provider whose fetches only complete when the test says so, to
/// simulate slow networks and out-of-order completions.
class _GatedFakeMenuProvider implements MenuProvider {
  final gates = <String, Completer<MenuDay>>{};

  @override
  String get id => 'gated';

  @override
  String get displayName => 'Gated';

  @override
  Map<String, String> get locations => const {'1': 'Test'};

  @override
  Future<MenuDay> fetchDay(DateTime date, String locationId) {
    final iso =
        '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
    final gate = Completer<MenuDay>();
    gates[iso] = gate;
    return gate.future;
  }

  @override
  bool isCacheValid(MenuDay day) => true;

  @override
  void close() {}

  MenuDay dayFor(String iso) => MenuDay(
    date: DateTime.parse(iso),
    locationId: '1',
    locationName: 'Test',
    meals: [
      ServedMeal(
        kind: 'ogle',
        serviceHours: '',
        dishes: [MenuDish(name: 'Dish $iso', category: '')],
      ),
    ],
  );
}

void main() {
  group('hacettepe parser', () {
    test('parses lunch cards with kcal and allergens', () {
      final day = HacettepeMenuProvider().parseDay(
        _fixture,
        DateTime(2026, 9, 21),
        '1',
      );
      expect(day.locationName, 'Beytepe');
      final lunch = day.meals.singleWhere((m) => m.kind == 'ogle');
      expect(lunch.serviceHours, '12:00 - 13:30');
      expect(lunch.totalKcal, 1078);
      expect(lunch.dishes.map((d) => d.name), ['Mantı', 'Çorba']);
      expect(lunch.dishes.first.kcal, 490);
      expect(lunch.dishes.first.allergens, ['A']);
      expect(lunch.dishes[1].kcal, isNull);
    });

    test('parses breakfast list without categories', () {
      final day = HacettepeMenuProvider().parseDay(
        _fixture,
        DateTime(2026, 9, 21),
        '2',
      );
      expect(day.locationName, 'Sıhhiye');
      final breakfast = day.meals.singleWhere((m) => m.kind == 'sabah');
      expect(breakfast.dishes.map((d) => d.name), ['Çay', 'Kek']);
    });

    test('collects the allergen legend for the day', () {
      final day = HacettepeMenuProvider().parseDay(
        _fixture,
        DateTime(2026, 9, 21),
        '1',
      );
      expect(day.allergenLegend, {'A': 'gluten'});
    });

    test('missing meal sections throw instead of emptying', () {
      expect(
        () => HacettepeMenuProvider().parseDay(
          '<html><body>redesign</body></html>',
          DateTime(2026, 9, 21),
          '1',
        ),
        throwsA(isA<MenuFetchException>()),
      );
    });

    test('fetchDay hits the dated location URL', () async {
      Uri? seen;
      final provider = HacettepeMenuProvider(
        MockClient((request) async {
          seen = request.url;
          return http.Response.bytes(
            utf8.encode(_fixture),
            200,
            headers: {'content-type': 'text/html; charset=utf-8'},
          );
        }),
      );
      final day = await provider.fetchDay(DateTime(2026, 9, 21), '2');
      expect(seen?.queryParameters['date'], '2026-09-21');
      expect(seen?.queryParameters['location_id'], '2');
      expect(day.meals, isNotEmpty);
    });

    test('non-200 responses throw', () async {
      final provider = HacettepeMenuProvider(
        MockClient((_) async => http.Response('nope', 500)),
      );
      await expectLater(
        provider.fetchDay(DateTime(2026, 9, 21), '1'),
        throwsA(isA<MenuFetchException>()),
      );
    });

    test('weekends override lunch and vegan hours', () {
      // The site publishes weekday hours on Saturdays; the halls serve
      // 12:00 - 13:30 for lunch and vegan.
      final siteHours = _fixture.replaceAll('12:00 - 13:30', '11:30 - 14:00');
      final html =
          '$siteHours<section id="vegan" class="tab-content"><div class="daily-view">'
          '<div class="menu-summary-info">'
          '<div class="summary-item time-item"><span><small>Servis Saati</small>'
          '<strong>11:30 - 14:00</strong></span></div>'
          '</div></div></section>';
      final day = HacettepeMenuProvider().parseDay(
        html,
        DateTime(2026, 10, 3), // Saturday
        '1',
      );
      expect(
        day.meals.singleWhere((m) => m.kind == 'ogle').serviceHours,
        '12:00 - 13:30',
      );
      expect(
        day.meals.singleWhere((m) => m.kind == 'vegan').serviceHours,
        '12:00 - 13:30',
      );
      expect(
        day.meals.singleWhere((m) => m.kind == 'sabah').serviceHours,
        isEmpty,
      );
    });

    test('weekdays keep the published hours', () {
      final day = HacettepeMenuProvider().parseDay(
        _fixture.replaceAll('12:00 - 13:30', '11:30 - 14:00'),
        DateTime(2026, 9, 21), // Monday
        '1',
      );
      expect(
        day.meals.singleWhere((m) => m.kind == 'ogle').serviceHours,
        '11:30 - 14:00',
      );
    });

    MenuDay hacettepeDay(DateTime date, String hours) => MenuDay(
      date: date,
      locationId: '1',
      locationName: 'Beytepe',
      meals: [
        ServedMeal(
          kind: 'ogle',
          serviceHours: hours,
          dishes: const [MenuDish(name: 'Mantı', category: 'ANAYEMEK')],
        ),
      ],
    );

    test('isCacheValid rejects weekend rows with weekday hours', () {
      final provider = HacettepeMenuProvider();
      expect(
        provider.isCacheValid(
          hacettepeDay(DateTime(2026, 10, 3), '11:30 - 14:00'),
        ),
        isFalse,
      );
      expect(
        provider.isCacheValid(
          hacettepeDay(DateTime(2026, 10, 3), '12:00 - 13:30'),
        ),
        isTrue,
      );
      expect(
        provider.isCacheValid(
          hacettepeDay(DateTime(2026, 9, 21), '11:30 - 14:00'),
        ),
        isTrue,
      );
    });
  });

  group('itu parser', () {
    test('dateParam uses DD-MM-YYYY', () {
      expect(ItuMenuProvider.dateParam(DateTime(2026, 9, 5)), '05-09-2026');
    });

    test('registry name is localized (Itu / İtü)', () {
      expect(ItuMenuProvider().displayName, 'Itu');
      expect(menuSources['itu']?.name(AppLocalizationsEn()), 'Itu');
      expect(menuSources['itu']?.name(AppLocalizationsTr()), 'İtü');
    });

    test('title-cases ALL-CAPS Turkish dish names', () {
      expect(
        ItuMenuProvider.titleCaseTr('TUTMAÇ ÇORBASI'),
        'Tutmaç Çorbası',
      );
      expect(ItuMenuProvider.titleCaseTr('ORMAN KEBABI'), 'Orman Kebabı');
      // Dotted capital İ → i, dotless I → ı.
      expect(ItuMenuProvider.titleCaseTr('İÇ PİLAV'), 'İç Pilav');
      expect(
        ItuMenuProvider.titleCaseTr('TEL ŞEHRİYELİ HAVUÇ ÇORBASI'),
        'Tel Şehriyeli Havuç Çorbası',
      );
      expect(
        ItuMenuProvider.titleCaseTr('KIYMALI BİBER DOLMASI'),
        'Kıymalı Biber Dolması',
      );
      // Hyphenated categories keep every part readable.
      expect(
        ItuMenuProvider.titleCaseTr('TATLI-SALATA-MEYVE-İÇECEK'),
        'Tatlı-Salata-Meyve-İçecek',
      );
      // Already mixed case passes through unchanged.
      expect(ItuMenuProvider.titleCaseTr('Ana Yemek'), 'Ana Yemek');
    });

    test('parses lunch and dinner rows with categories', () async {
      final day = await ItuMenuProvider().parseDay(
        _ituOgleFixture,
        _ituAksamFixture,
        DateTime(2026, 9, 30),
        'genel',
      );
      expect(day.locationName, 'Genel');
      expect(day.meals.map((m) => m.kind), ['ogle', 'aksam']);
      final lunch = day.meals.first;
      expect(
        lunch.dishes.map((d) => d.name),
        ['Tutmaç Çorbası', 'Orman Kebabı', 'İç Pilav'],
      );
      expect(
        lunch.dishes.map((d) => d.category),
        ['Çorba', 'Ana Yemek', 'Yan Yemek'],
      );
      expect(lunch.serviceHours, '11:30 - 14:00');
      expect(day.meals[1].serviceHours, '17:00 - 19:30');
      // No detail fetcher: kcal unknown, allergens unlisted.
      expect(lunch.dishes.every((d) => d.kcal == null), isTrue);
      expect(lunch.dishes.every((d) => d.allergens.isEmpty), isTrue);
      expect(lunch.totalKcal, isNull);
    });

    test('enriches kcal and allergens from detail pages', () async {
      Future<String?> details(Uri uri) async {
        if (uri.path.contains('besin-degerleri')) return _ituNutritionFixture;
        if (uri.path.contains('alerjen-detay')) return _ituAllergenFixture;
        return null;
      }

      final day = await ItuMenuProvider().parseDay(
        _ituOgleEnrichFixture,
        _ituEmptyMealFixture,
        DateTime(2026, 9, 30),
        'genel',
        fetchDetail: details,
      );
      final lunch = day.meals.firstWhere((m) => m.kind == 'ogle');
      // 114,2027 rounds to 114; total sums the enriched dishes.
      expect(lunch.dishes.single.kcal, 114);
      expect(lunch.totalKcal, 114);
      // Yumurta twice dedupes to one Y; legend keeps the full text.
      expect(lunch.dishes.single.allergens, ['Y', 'G', 'S']);
      expect(day.allergenLegend['Y'], 'Yumurta ve yumurta ürünleri');
      expect(
        day.allergenLegend['G'],
        'Gluten içeren tahıllar ve bunların ürünleri',
      );
      // Dinner page has no table: kept as an empty meal, lunch survives.
      final dinner = day.meals.firstWhere((m) => m.kind == 'aksam');
      expect(dinner.dishes, isEmpty);
      expect(dinner.serviceHours, '17:00 - 19:30');
    });

    test('missing allergen link means no allergens', () async {
      Future<String?> details(Uri uri) async => _ituNutritionFixture;
      final day = await ItuMenuProvider().parseDay(
        _ituNoAllergenFixture,
        _ituEmptyMealFixture,
        DateTime(2026, 9, 30),
        'genel',
        fetchDetail: details,
      );
      final lunch = day.meals.firstWhere((m) => m.kind == 'ogle');
      expect(lunch.dishes.single.allergens, isEmpty);
      expect(lunch.dishes.single.kcal, 114);
    });

    test('unknown allergen text maps to X', () {
      final legend = <String, String>{};
      expect(
        ItuMenuProvider.allergenCode('Gizli baharat karışımı', legend),
        'X',
      );
      expect(legend, {'X': 'Gizli baharat karışımı'});
    });

    test('parses Turkish decimal comma kcal', () {
      expect(
        ItuMenuProvider.parseKcal(
          _ituNutritionFixture.replaceFirst('114,2027', '125,6687'),
        ),
        126,
      );
      expect(ItuMenuProvider.parseKcal('<html></html>'), isNull);
    });

    test('dedupes allergen descriptions', () {
      expect(ItuMenuProvider.parseAllergenDescriptions(_ituAllergenFixture), [
        'Yumurta ve yumurta ürünleri',
        'Gluten içeren tahıllar ve bunların ürünleri',
        'Süt ve süt ürünleri (laktoz dahil)',
      ]);
    });

    test('both pages without tables throw instead of emptying', () {
      expect(
        ItuMenuProvider().parseDay(
          '<html><body>redesign</body></html>',
          '<html><body>redesign</body></html>',
          DateTime(2026, 9, 30),
          'genel',
        ),
        throwsA(isA<MenuFetchException>()),
      );
    });

    test('fetchDay hits both tips with the dated value', () async {
      final seen = <Uri>[];
      final provider = ItuMenuProvider(
        MockClient((request) async {
          seen.add(request.url);
          return http.Response.bytes(
            utf8.encode(_ituOgleFixture),
            200,
            headers: {'content-type': 'text/html; charset=utf-8'},
          );
        }),
      );
      final day = await provider.fetchDay(DateTime(2026, 9, 30), 'genel');
      expect(day.meals, hasLength(2));
      final menuHits = [
        for (final u in seen)
          if (u.path.endsWith('yemek-menu.aspx')) u,
      ];
      expect(menuHits, hasLength(2));
      expect(menuHits.first.host, 'bilgiekrani.itu.edu.tr');
      expect(
        menuHits.map((u) => u.queryParameters['tip']),
        containsAll(['itu-ogle-yemegi-genel', 'itu-aksam-yemegi-genel']),
      );
      expect(menuHits.first.queryParameters['value'], '30-09-2026');
    });

    test('fetchDay falls back to the second host', () async {
      final seen = <String>[];
      final provider = ItuMenuProvider(
        MockClient((request) async {
          seen.add(request.url.host);
          if (request.url.host == 'bilgiekrani.itu.edu.tr') {
            return http.Response('boom', 500);
          }
          return http.Response.bytes(
            utf8.encode(_ituOgleFixture),
            200,
            headers: {'content-type': 'text/html; charset=utf-8'},
          );
        }),
      );
      final day = await provider.fetchDay(DateTime(2026, 9, 30), 'genel');
      expect(seen, contains('bidb.itu.edu.tr'));
      expect(day.meals, hasLength(2));
    });

    test('non-200 on both hosts throws', () async {
      final provider = ItuMenuProvider(
        MockClient((_) async => http.Response('nope', 500)),
      );
      await expectLater(
        provider.fetchDay(DateTime(2026, 9, 30), 'genel'),
        throwsA(isA<MenuFetchException>()),
      );
    });

    test('itu source is registered', () {
      expect(menuSources, contains('itu'));
    });

    MenuDay ituDay(List<String> names) => MenuDay(
      date: DateTime(2026, 9, 30),
      locationId: 'genel',
      locationName: 'Genel',
      meals: [
        ServedMeal(
          kind: 'ogle',
          serviceHours: '11:30 - 14:00',
          dishes: [
            for (final n in names) MenuDish(name: n, category: 'Çorba'),
          ],
        ),
      ],
    );

    test('isCacheValid rejects pre-normalization ALL-CAPS rows', () {
      final provider = ItuMenuProvider();
      expect(
        provider.isCacheValid(ituDay(['TUTMAÇ ÇORBASI', 'Tutmaç Çorbası'])),
        isFalse,
      );
    });

    test('isCacheValid accepts normalized and uncased names', () {
      final provider = ItuMenuProvider();
      expect(
        provider.isCacheValid(ituDay(['Tutmaç Çorbası', 'Orman Kebabı'])),
        isTrue,
      );
      // Cased content required: numbers/symbols alone are not "caps".
      expect(provider.isCacheValid(ituDay(['123', '---'])), isTrue);
      expect(provider.isCacheValid(ituDay(const [])), isTrue);
    });

    test('hacettepe cache stays valid by default', () {
      final provider = HacettepeMenuProvider();
      expect(
        provider.isCacheValid(
          ituDay(['TUTMAÇ ÇORBASI']),
        ),
        isTrue,
      );
    });
  });

  group('menu screen', () {
    testWidgets('shows dishes from the provider', (tester) async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(() => db.close());
      final fake = _FakeMenuProvider()..day = _fakeDay();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [appDatabaseProvider.overrideWithValue(db)],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: MenuScreen(provider: fake),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Mantı'), findsOneWidget);
      expect(find.textContaining('1078 kcal'), findsWidgets);
    });

    testWidgets('shows error view when offline with no cache', (
      tester,
    ) async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(() => db.close());
      final fake = _FakeMenuProvider()..fail = true;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [appDatabaseProvider.overrideWithValue(db)],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: MenuScreen(provider: fake),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Mantı'), findsNothing);
    });

    testWidgets('falls back to cache when offline', (tester) async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(() => db.close());
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final iso =
          '${today.year.toString().padLeft(4, '0')}-'
          '${today.month.toString().padLeft(2, '0')}-'
          '${today.day.toString().padLeft(2, '0')}';
      await MenuCacheRepository(db).storeDay(
        'fake',
        '1',
        iso,
        MenuDay(
          date: today,
          locationId: '1',
          locationName: 'Test',
          meals: const [
            ServedMeal(
              kind: 'ogle',
              serviceHours: '12:00 - 13:30',
              totalKcal: 1078,
              dishes: [MenuDish(name: 'Mantı', category: 'ANAYEMEK')],
            ),
          ],
        ),
      );
      final fake = _FakeMenuProvider()..fail = true;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [appDatabaseProvider.overrideWithValue(db)],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: MenuScreen(provider: fake),
          ),
        ),
      );
      await tester.pumpAndSettle();
      // Cached dish shows despite the network failure.
      expect(find.text('Mantı'), findsOneWidget);
    });

    testWidgets('allergen panel expands with a circular toggle', (
      tester,
    ) async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(() => db.close());
      final fake = _FakeMenuProvider()..day = _fakeDay();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [appDatabaseProvider.overrideWithValue(db)],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: MenuScreen(provider: fake),
          ),
        ),
      );
      await tester.pumpAndSettle();
      // The legend lives in the tree (collapsed); the toggle ripple is
      // circular and tapping flips the panel open and shut.
      final toggle = find.ancestor(
        of: find.byIcon(Icons.expand_more),
        matching: find.byType(InkWell),
      );
      expect(toggle, findsOneWidget);
      expect(
        tester.widget<InkWell>(toggle).customBorder,
        isA<CircleBorder>(),
      );
      AnimatedRotation rotation() => tester.widget<AnimatedRotation>(
        find.descendant(of: toggle, matching: find.byType(AnimatedRotation)),
      );
      expect(rotation().turns, 0);
      await tester.tap(toggle);
      await tester.pumpAndSettle();
      expect(rotation().turns, 0.5);
      await tester.tap(toggle);
      await tester.pumpAndSettle();
      expect(rotation().turns, 0);
    });

    testWidgets('allergen chip opens its description', (tester) async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(() => db.close());
      final fake = _FakeMenuProvider()..day = _fakeDay();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [appDatabaseProvider.overrideWithValue(db)],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: MenuScreen(provider: fake),
          ),
        ),
      );
      await tester.pumpAndSettle();
      // The collapsed legend also contains an "A" badge inside a static
      // ListTile (which still builds an InkWell); the dish chip comes
      // first in tree order.
      await tester.tap(
        find
            .ancestor(of: find.text('A'), matching: find.byType(InkWell))
            .first,
      );
      await tester.pumpAndSettle();
      // The legend row carries the same text; assert on the dialog copy.
      expect(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Test allergen'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('slow day loads do not overwrite newer days', (
      tester,
    ) async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(() => db.close());
      final gated = _GatedFakeMenuProvider();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [appDatabaseProvider.overrideWithValue(db)],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: MenuScreen(provider: gated),
          ),
        ),
      );
      // Let the initial cached lookup + fetch kick off (fetch stays gated).
      await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 100)));
      await tester.pump();
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      String iso(DateTime d) =>
          '${d.year.toString().padLeft(4, '0')}-'
          '${d.month.toString().padLeft(2, '0')}-'
          '${d.day.toString().padLeft(2, '0')}';
      final todayIso = iso(today);
      final nextIso = iso(DateTime(today.year, today.month, today.day + 1));
      // Initial load for today is still in flight; move to tomorrow.
      expect(gated.gates.containsKey(todayIso), isTrue);
      await tester.tap(find.byTooltip('Next day'));
      await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 100)));
      await tester.pump();
      expect(gated.gates.containsKey(nextIso), isTrue);
      // Tomorrow resolves first, then the stale today load finishes last.
      gated.gates[nextIso]!.complete(gated.dayFor(nextIso));
      await tester.pumpAndSettle();
      expect(find.text('Dish $nextIso'), findsOneWidget);
      gated.gates[todayIso]!.complete(gated.dayFor(todayIso));
      await tester.pumpAndSettle();
      expect(find.text('Dish $nextIso'), findsOneWidget);
      expect(find.text('Dish $todayIso'), findsNothing);
    });

    testWidgets('menu page is empty until a source is picked', (
      tester,
    ) async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(() => db.close());
      await tester.pumpWidget(
        ProviderScope(
          overrides: [appDatabaseProvider.overrideWithValue(db)],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const MenuScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.text('Choose a menu source in Settings'),
        findsOneWidget,
      );
      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Mantı'), findsNothing);
    });

    testWidgets('picked source loads from cache without a passed provider', (
      tester,
    ) async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(() => db.close());
      await tester.runAsync(
        () => SettingsRepository(db).setMenuProviderId('hacettepe'),
      );
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final iso =
          '${today.year.toString().padLeft(4, '0')}-'
          '${today.month.toString().padLeft(2, '0')}-'
          '${today.day.toString().padLeft(2, '0')}';
      await MenuCacheRepository(db).storeDay(
        'hacettepe',
        '1',
        iso,
        _fakeDay(),
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [appDatabaseProvider.overrideWithValue(db)],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const MenuScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      // Cached Hacettepe day renders with no explicit provider passed.
      expect(find.text('Mantı'), findsOneWidget);
    });

    testWidgets('date label never claims a non-today day is today', (
      tester,
    ) async {      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(() => db.close());
      final gated = _GatedFakeMenuProvider();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [appDatabaseProvider.overrideWithValue(db)],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: MenuScreen(provider: gated),
          ),
        ),
      );
      await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 100)));
      await tester.pump();
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      String iso(DateTime d) =>
          '${d.year.toString().padLeft(4, '0')}-'
          '${d.month.toString().padLeft(2, '0')}-'
          '${d.day.toString().padLeft(2, '0')}';
      // On today: date button shows the iso only, no extra Today button.
      expect(find.text(iso(today)), findsOneWidget);
      expect(find.textContaining('·'), findsNothing);
      // Move to tomorrow: date updates and a jump-back Today button appears.
      await tester.tap(find.byTooltip('Next day'));
      await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 100)));
      await tester.pump();
      final tomorrow = DateTime(today.year, today.month, today.day + 1);
      expect(find.text(iso(tomorrow)), findsOneWidget);
      expect(find.text('Today'), findsOneWidget);
    });

    testWidgets('campus switch fits a narrow phone screen', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(() => db.close());
      final fake = _TwoLocationFakeMenuProvider()..day = _fakeDay();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [appDatabaseProvider.overrideWithValue(db)],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: MenuScreen(provider: fake),
          ),
        ),
      );
      await tester.pumpAndSettle();
      // Both campuses are laid out with no overflow on a 360px phone.
      expect(find.text('Beytepe'), findsOneWidget);
      expect(find.text('Sıhhiye'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}

