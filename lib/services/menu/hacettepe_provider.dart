import 'dart:convert';

import 'package:html/dom.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:http/http.dart' as http;

import 'menu_provider.dart';

/// Hacettepe University dining-hall menus (beslenme.hacettepe.edu.tr).
/// Display only: dishes, kcal, allergens, service hours. No login, no voting.
///
/// Reads the server-rendered day page
/// (`?date=YYYY-MM-DD&location_id=N`) and parses the meal sections
/// (`sabah`/`ogle`/`aksam`/`vegan`). Dish cards carry everything in
/// `data-*` attributes, so minor redesigns usually keep working; a missing
/// tab structure throws [MenuFetchException] instead of silently emptying.
class HacettepeMenuProvider implements MenuProvider {
  final http.Client _client;
  final bool _ownsClient;

  HacettepeMenuProvider([http.Client? client])
    : _client = client ?? http.Client(),
      _ownsClient = client == null;

  @override
  void close() {
    if (_ownsClient) _client.close();
  }

  static final RegExp _kcalNumber = RegExp(r'(\d+)');

  @override
  String get id => 'hacettepe';

  @override
  String get displayName => 'Hacettepe';

  @override
  Map<String, String> get locations => const {
    '1': 'Beytepe',
    '2': 'Sıhhiye',
  };

  // No legacy row formats to reject, but weekend rows stored before the
  // hours override carry the site's weekday hours and must refetch.
  @override
  bool isCacheValid(MenuDay day) {
    if (!_isWeekend(day.date)) return true;
    return !day.meals.any(
      (m) =>
          (m.kind == 'ogle' || m.kind == 'vegan') &&
          m.serviceHours.isNotEmpty &&
          m.serviceHours != _weekendHours,
    );
  }

  static String dateParam(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  /// Weekend service window (Sat/Sun) for lunch and vegan: the site keeps
  /// publishing weekday hours on weekends, but the halls actually serve
  /// 12:00 - 13:30. Verified against the live Saturday page, which still
  /// claims 11:30 - 14:00.
  static const _weekendHours = '12:00 - 13:30';

  static bool _isWeekend(DateTime date) =>
      date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;

  @override
  Future<MenuDay> fetchDay(DateTime date, String locationId) async {
    final uri = Uri.https('beslenme.hacettepe.edu.tr', '/', {
      'date': dateParam(date),
      'location_id': locationId,
    });
    late final String body;
    MenuFetchException? lastError;
    // Single host, so transient 500s/timeouts get retries with backoff
    // instead of failing the whole day on one bad response.
    for (var attempt = 0; attempt < 3; attempt++) {
      if (attempt > 0) {
        await Future.delayed(Duration(milliseconds: 500 * attempt));
      }
      try {
        final response = await _client
            .get(uri, headers: menuHttpHeaders)
            .timeout(const Duration(seconds: 12));
        if (response.statusCode != 200) {
          lastError = MenuFetchException('HTTP ${response.statusCode}');
          continue;
        }
        body = decodeMenuBody(response);
        return parseDay(body, date, locationId);
      } on MenuFetchException {
        // Tab structure missing: the markup changed, not the network.
        // Retrying won't help.
        rethrow;
      } catch (e) {
        lastError = MenuFetchException('Network error: $e');
      }
    }
    throw lastError ?? const MenuFetchException('Network error');
  }

  /// Parses a day page. Public for tests (fixture HTML, no network).
  MenuDay parseDay(String html, DateTime date, String locationId) {
    final doc = html_parser.parse(html);
    const meals = ['sabah', 'ogle', 'aksam', 'vegan'];
    if (meals.every((id) => doc.getElementById(id) == null)) {
      throw const MenuFetchException('Unexpected page structure');
    }
    // The sections also embed a `.weekly-view` with other days' menus;
    // strip it so its cards can never leak into this day when the
    // `.daily-view` wrapper is absent (the parser falls back to the
    // whole section then).
    for (final weekly in doc.querySelectorAll('.weekly-view')) {
      weekly.remove();
    }
    final legend = <String, String>{};
    final parsed = <ServedMeal>[];
    // Look each tab up by id: a missing tab (e.g. no vegan section)
    // must not shift the remaining sections onto the wrong kinds.
    for (final id in meals) {
      final section = doc.getElementById(id);
      if (section == null) continue;
      parsed.add(_parseMeal(section, id, legend, date));
    }
    return MenuDay(
      date: DateTime(date.year, date.month, date.day),
      locationId: locationId,
      locationName: locations[locationId] ?? locationId,
      meals: parsed,
      allergenLegend: legend,
    );
  }

  ServedMeal _parseMeal(
    Element section,
    String kind,
    Map<String, String> legend,
    DateTime date,
  ) {
    final daily = section.querySelector('.daily-view') ?? section;
    var serviceHours = '';
    int? totalKcal;
    final summary = daily.querySelector('.menu-summary-info');
    if (summary != null) {
      final timeEl = summary.querySelector('.time-item strong');
      if (timeEl != null) serviceHours = timeEl.text.trim();
      for (final span in summary.querySelectorAll('span')) {
        final text = span.text;
        if (text.contains('kcal')) {
          final match = _kcalNumber.firstMatch(text);
          if (match != null) totalKcal = int.tryParse(match.group(1)!);
        }
      }
    }
    final dishes = <MenuDish>[
      for (final card in daily.querySelectorAll('.menu-card[data-title]'))
        _parseCard(card, legend),
      // Breakfast is a plain list, not cards.
      for (final li in daily.querySelectorAll('.kahvalti-items li'))
        if (li.text.trim().isNotEmpty)
          MenuDish(name: li.text.trim(), category: ''),
    ];
    if (_isWeekend(date) && (kind == 'ogle' || kind == 'vegan')) {
      serviceHours = _weekendHours;
    }
    return ServedMeal(
      kind: kind,
      serviceHours: serviceHours,
      totalKcal: totalKcal,
      dishes: dishes,
    );
  }

  MenuDish _parseCard(Element card, Map<String, String> legend) {
    final attrs = card.attributes;
    final allergens = <String>[];
    final raw = attrs['data-alerjenler'];
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          for (final a in decoded) {
            if (a is Map) {
              final code = a['kodu']?.toString().trim();
              if (code != null && code.isNotEmpty) {
                allergens.add(code);
                final desc = a['aciklama']?.toString().trim();
                if (desc != null && desc.isNotEmpty) {
                  legend.putIfAbsent(code, () => desc);
                }
              }
            }
          }
        }
      } catch (_) {
        // Tolerate malformed allergen payloads; the dish still shows.
      }
    }
    return MenuDish(
      name: (attrs['data-title'] ?? '').trim(),
      category: (attrs['data-category'] ?? '').trim(),
      kcal: int.tryParse((attrs['data-cal'] ?? '').trim()),
      allergens: allergens,
    );
  }
}
