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

  HacettepeMenuProvider([http.Client? client])
    : _client = client ?? http.Client();

  @override
  String get id => 'hacettepe';

  @override
  String get displayName => 'Hacettepe';

  @override
  Map<String, String> get locations => const {
    '1': 'Beytepe',
    '2': 'Sıhhiye',
  };

  static String dateParam(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  @override
  Future<MenuDay> fetchDay(DateTime date, String locationId) async {
    final uri = Uri.https('beslenme.hacettepe.edu.tr', '/', {
      'date': dateParam(date),
      'location_id': locationId,
    });
    late final String body;
    try {
      final response = await _client
          .get(uri, headers: {'Accept': 'text/html'})
          .timeout(const Duration(seconds: 20));
      if (response.statusCode != 200) {
        throw MenuFetchException('HTTP ${response.statusCode}');
      }
      body = response.body;
    } on MenuFetchException {
      rethrow;
    } catch (e) {
      throw MenuFetchException('Network error: $e');
    }
    return parseDay(body, date, locationId);
  }

  /// Parses a day page. Public for tests (fixture HTML, no network).
  MenuDay parseDay(String html, DateTime date, String locationId) {
    final doc = html_parser.parse(html);
    const meals = ['sabah', 'ogle', 'aksam', 'vegan'];
    final sections = [
      for (final id in meals) doc.getElementById(id),
    ].whereType<Element>().toList();
    if (sections.isEmpty) {
      throw const MenuFetchException('Unexpected page structure');
    }
    final legend = <String, String>{};
    final parsed = <ServedMeal>[];
    for (var i = 0; i < sections.length; i++) {
      parsed.add(_parseMeal(sections[i], meals[i], legend));
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
          final match = RegExp(r'(\d+)').firstMatch(text);
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
