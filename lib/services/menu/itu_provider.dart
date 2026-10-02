import 'package:html/dom.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:http/http.dart' as http;

import 'menu_provider.dart';

/// Istanbul Technical University dining-hall menus.
///
/// Display only: dishes, kcal, allergens, service hours. No login, no voting.
///
/// Reads the AJAX menu partial
/// (`yemek-menu.aspx?tip={itu-ogle-yemegi-genel|itu-aksam-yemegi-genel}&&value=DD-MM-YYYY`)
/// served by the `bilgiekrani`/`bidb` hosts (the same path on `sks.itu.edu.tr`
/// 500s). ITU publishes a single `genel` menu with lunch and dinner only.
/// Dish rows link per-dish nutrition (`besin-degerleri.aspx?yemek=ID`) and
/// allergen (`alerjen-detay.aspx?yemek=ID`) pages; a missing allergen link
/// means no allergens. Allergen pages carry full-text descriptions, so codes
/// are synthesized from Turkish keywords. A day with no published menu has no
/// table and throws [MenuFetchException] instead of silently emptying.
class ItuMenuProvider implements MenuProvider {
  final http.Client _client;
  final bool _ownsClient;

  ItuMenuProvider([http.Client? client])
      : _client = client ?? http.Client(),
        _ownsClient = client == null;

  @override
  void close() {
    if (_ownsClient) _client.close();
  }

  static const _menuPath =
      '/ExternalPages/sks/yemek-menu-v2/uzerinde-calisilan/yemek-menu.aspx';

  /// Hosts serving the menu partial, in preference order.
  static const _hosts = ['bilgiekrani.itu.edu.tr', 'bidb.itu.edu.tr'];

  static const _tips = {
    'ogle': 'itu-ogle-yemegi-genel',
    'aksam': 'itu-aksam-yemegi-genel',
  };

  static const _serviceHours = {
    'ogle': '11:30 - 14:00',
    'aksam': '17:00 - 19:30',
  };

  static final RegExp _wordPattern = RegExp(r'[a-zçğöşüıiâîû]+');
  static final RegExp _kcalPattern = RegExp(r'[\d.]+,\d+|\d+');

  /// Turkish keyword → synthesized allergen code, checked in order.
  static const _allergenKeywords = [
    ('gluten', 'G'),
    ('yumurta', 'Y'),
    ('süt', 'S'),
    ('sut', 'S'),
    ('laktoz', 'S'),
    ('balık', 'B'),
    ('balik', 'B'),
    ('kabuklu', 'B'),
    ('soya', 'Sy'),
    ('susam', 'Sm'),
    ('fındık', 'F'),
    ('findik', 'F'),
    ('fıstık', 'F'),
    ('fistik', 'F'),
    ('ceviz', 'F'),
    ('badem', 'F'),
    ('sert kabuklu', 'F'),
    ('kuruyemiş', 'F'),
    ('kereviz', 'K'),
    ('hardal', 'H'),
    ('kükürt', 'Sd'),
    ('kukurt', 'Sd'),
    ('sülfit', 'Sd'),
    ('sulfit', 'Sd'),
    ('acı bakla', 'L'),
    ('aci bakla', 'L'),
    ('lupin', 'L'),
    ('yumuşakça', 'Ym'),
    ('yumusakca', 'Ym'),
  ];

  @override
  String get id => 'itu';

  @override
  String get displayName => 'Itu';

  @override
  Map<String, String> get locations => const {'genel': 'Genel'};

  /// Rejects days stored before dish-name normalization: any cased
  /// ALL-CAPS dish name means the row predates [titleCaseTr] and must
  /// refetch instead of showing until the cache TTL expires.
  @override
  bool isCacheValid(MenuDay day) => !day.meals.any(
    (m) => m.dishes.any((d) => _isAllCaps(d.name)),
  );

  static bool _isAllCaps(String s) =>
      s != s.toLowerCase() && s == s.toUpperCase();

  static String dateParam(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.year.toString().padLeft(4, '0')}';

  /// Title-cases an ALL-CAPS Turkish dish/category name for display:
  /// `TUTMAÇ ÇORBASI` → `Tutmaç Çorbası`. Turkish-aware: plain
  /// lowercasing would turn `İ` into `i̇` (combining dot) and `I` into
  /// the wrong letter, so map those first. Also applied to already
  /// mixed-case categories (`Ana Yemek` passes through unchanged).
  static String titleCaseTr(String raw) {
    final lowered = raw.replaceAll('I', 'ı').replaceAll('İ', 'i').toLowerCase();
    return lowered.replaceAllMapped(_wordPattern, (m) {
      final w = m[0]!;
      final first = w[0] == 'i' ? 'İ' : w[0].toUpperCase();
      return '$first${w.substring(1)}';
    });
  }

  @override
  Future<MenuDay> fetchDay(DateTime date, String locationId) async {
    final value = dateParam(date);
    late final List<String> bodies;
    try {
      bodies = await Future.wait([
        for (final kind in _tips.keys) _getMealPage(kind, value),
      ]).timeout(const Duration(seconds: 40));
    } on MenuFetchException {
      rethrow;
    } catch (e) {
      throw MenuFetchException('Network error: $e');
    }
    return parseDay(
      bodies[0],
      bodies[1],
      date,
      locationId,
      fetchDetail: (uri) async {
        try {
          final response = await _client
              .get(uri, headers: {'Accept': 'text/html'})
              .timeout(const Duration(seconds: 15));
          if (response.statusCode != 200) return null;
          return response.body;
        } catch (_) {
          return null;
        }
      },
    );
  }

  Future<String> _getMealPage(String kind, String value) async {
    final tip = _tips[kind]!;
    MenuFetchException? lastError;
    for (final host in _hosts) {
      // Double && mirrors the site's own form action; servers ignore the
      // empty parameter between them.
      final uri = Uri.parse('https://$host$_menuPath?tip=$tip&&value=$value');
      try {
        final response = await _client
            .get(uri, headers: {'Accept': 'text/html'})
            .timeout(const Duration(seconds: 20));
        if (response.statusCode != 200) {
          lastError = MenuFetchException('HTTP ${response.statusCode}');
          continue;
        }
        return response.body;
      } catch (e) {
        lastError = MenuFetchException('Network error: $e');
      }
    }
    throw lastError ?? const MenuFetchException('Network error');
  }

  /// Parses a lunch + dinner page pair. Public for tests (fixture HTML, no
  /// network unless [fetchDetail] is given for kcal/allergen enrichment).
  Future<MenuDay> parseDay(
    String ogleHtml,
    String aksamHtml,
    DateTime date,
    String locationId, {
    Future<String?> Function(Uri uri)? fetchDetail,
  }) async {
    final legend = <String, String>{};
    final meals = <ServedMeal>[];
    final pages = {'ogle': ogleHtml, 'aksam': aksamHtml};
    for (final entry in pages.entries) {
      // One unpublished meal must not drop the other; a day with
      // nothing at all still throws below.
      try {
        meals.add(
          await _parseMeal(entry.value, entry.key, legend, fetchDetail),
        );
      } on MenuFetchException {
        meals.add(
          ServedMeal(
            kind: entry.key,
            serviceHours: _serviceHours[entry.key] ?? '',
            dishes: const [],
          ),
        );
      }
    }
    if (meals.every((m) => m.dishes.isEmpty)) {
      throw const MenuFetchException('Unexpected page structure');
    }
    return MenuDay(
      date: DateTime(date.year, date.month, date.day),
      locationId: locationId,
      locationName: locations[locationId] ?? locationId,
      meals: meals,
      allergenLegend: legend,
    );
  }

  Future<ServedMeal> _parseMeal(
    String html,
    String kind,
    Map<String, String> legend,
    Future<String?> Function(Uri uri)? fetchDetail,
  ) async {
    final doc = html_parser.parse(html);
    final table = doc.querySelector('#pnlYemekMenu table');
    if (table == null) {
      throw const MenuFetchException('Unexpected page structure');
    }
    final partials = <_PartialDish>[];
    for (final row in table.querySelectorAll('tr')) {
      final cells = row.querySelectorAll('td');
      if (cells.length < 2) continue;
      final category = cells[0].text.trim();
      final dishCell = cells[1];
      final nutritionLink = dishCell.querySelector('a[href*="besin-degerleri"]');
      final allergenLink = dishCell.querySelector('a[href*="alerjen-detay"]');
      final name = (nutritionLink ?? dishCell).text.trim();
      if (name.isEmpty) continue;
      partials.add(
        _PartialDish(
          name: titleCaseTr(name),
          category: titleCaseTr(category),
          nutritionUri: _href(nutritionLink),
          allergenUri: _href(allergenLink),
        ),
      );
    }
    // Bound concurrency: dishes enrich in small batches so a 20-dish day
    // opens ~12 detail sockets at a time instead of 40+ at once.
    const batchSize = 6;
    final dishes = <MenuDish>[];
    for (var i = 0; i < partials.length; i += batchSize) {
      final batch = partials.skip(i).take(batchSize);
      dishes.addAll(
        await Future.wait([
          for (final p in batch) p.enrich(fetchDetail, legend),
        ]),
      );
    }
    var totalKcal = 0;
    var known = false;
    for (final d in dishes) {
      if (d.kcal != null) {
        totalKcal += d.kcal!;
        known = true;
      }
    }
    return ServedMeal(
      kind: kind,
      serviceHours: _serviceHours[kind] ?? '',
      totalKcal: known ? totalKcal : null,
      dishes: dishes,
    );
  }

  static Uri? _href(Element? link) {
    final href = link?.attributes['href']?.trim();
    if (href == null || href.isEmpty) return null;
    return Uri.tryParse(href);
  }

  /// Maps a full-text allergen description to a synthesized code, recording
  /// the description in [legend]. Public for tests.
  static String allergenCode(String description, Map<String, String> legend) {
    final lower = description.toLowerCase();
    for (final (keyword, code) in _allergenKeywords) {
      if (lower.contains(keyword)) {
        legend.putIfAbsent(code, () => description.trim());
        return code;
      }
    }
    legend.putIfAbsent('X', () => description.trim());
    return 'X';
  }

  /// Parses the kcal value from a nutrition detail page. Public for tests.
  static int? parseKcal(String html) {
    final doc = html_parser.parse(html);
    for (final row in doc.querySelectorAll('tr')) {
      if (!row.text.contains('Enerji (kcal)')) continue;
      final match = _kcalPattern.firstMatch(row.text);
      if (match == null) return null;
      final normalized = match
          .group(0)!
          .replaceAll('.', '')
          .replaceAll(',', '.');
      return double.tryParse(normalized)?.round();
    }
    return null;
  }

  /// Parses allergen descriptions from an allergen detail page, deduped.
  /// Public for tests.
  static List<String> parseAllergenDescriptions(String html) {
    final doc = html_parser.parse(html);
    final seen = <String>[];
    final seenSet = <String>{};
    for (final li in doc.querySelectorAll(
      '.allergen-detail__content-inner li',
    )) {
      final text = li.text.trim();
      if (text.isNotEmpty && seenSet.add(text)) seen.add(text);
    }
    return seen;
  }
}

class _PartialDish {
  final String name;
  final String category;
  final Uri? nutritionUri;
  final Uri? allergenUri;

  const _PartialDish({
    required this.name,
    required this.category,
    this.nutritionUri,
    this.allergenUri,
  });

  Future<MenuDish> enrich(
    Future<String?> Function(Uri uri)? fetchDetail,
    Map<String, String> legend,
  ) async {
    // Nutrition + allergen detail pages fetch concurrently per dish
    // (they were serial: 2 round-trips per dish on the critical path).
    final bodies = await Future.wait([
      nutritionUri != null && fetchDetail != null
          ? fetchDetail(nutritionUri!)
          : Future<String?>.value(),
      allergenUri != null && fetchDetail != null
          ? fetchDetail(allergenUri!)
          : Future<String?>.value(),
    ]);
    final kcal =
        bodies[0] != null ? ItuMenuProvider.parseKcal(bodies[0]!) : null;
    final allergens = <String>[];
    if (bodies[1] != null) {
      for (final desc in ItuMenuProvider.parseAllergenDescriptions(bodies[1]!)) {
        final code = ItuMenuProvider.allergenCode(desc, legend);
        if (!allergens.contains(code)) allergens.add(code);
      }
    }
    return MenuDish(
      name: name,
      category: category,
      kcal: kcal,
      allergens: allergens,
    );
  }
}
