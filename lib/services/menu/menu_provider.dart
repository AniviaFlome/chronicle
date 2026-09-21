import 'package:meta/meta.dart';

/// A single dish on a dining-hall menu.
@immutable
class MenuDish {
  /// Display name, exactly as published (usually the site's language).
  final String name;

  /// Category as published, e.g. soup / main / salad (`ÇORBA`, `ANAYEMEK`).
  final String category;

  /// Kilocalories, null when the publisher doesn't list any.
  final int? kcal;

  /// Allergen codes as published, e.g. `['A', 'D']`.
  final List<String> allergens;

  const MenuDish({
    required this.name,
    required this.category,
    this.kcal,
    this.allergens = const [],
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'category': category,
    'kcal': kcal,
    'allergens': allergens,
  };

  factory MenuDish.fromJson(Map<String, dynamic> json) => MenuDish(
    name: json['name'] as String? ?? '',
    category: json['category'] as String? ?? '',
    kcal: (json['kcal'] as num?)?.toInt(),
    allergens: [
      for (final a in (json['allergens'] as List?) ?? const []) a.toString(),
    ],
  );
}

/// One served meal (breakfast / lunch / dinner / vegan) on a given day.
@immutable
class ServedMeal {
  final String kind;
  final String serviceHours;
  final int? totalKcal;
  final List<MenuDish> dishes;

  const ServedMeal({
    required this.kind,
    required this.serviceHours,
    required this.dishes,
    this.totalKcal,
  });

  Map<String, dynamic> toJson() => {
    'kind': kind,
    'serviceHours': serviceHours,
    'totalKcal': totalKcal,
    'dishes': [for (final d in dishes) d.toJson()],
  };

  factory ServedMeal.fromJson(Map<String, dynamic> json) => ServedMeal(
    kind: json['kind'] as String? ?? '',
    serviceHours: json['serviceHours'] as String? ?? '',
    totalKcal: (json['totalKcal'] as num?)?.toInt(),
    dishes: [
      for (final d in (json['dishes'] as List?) ?? const [])
        MenuDish.fromJson(Map<String, dynamic>.from(d as Map)),
    ],
  );
}

/// A full day of dining-hall menus at one location.
@immutable
class MenuDay {
  final DateTime date;
  final String locationId;
  final String locationName;
  final List<ServedMeal> meals;

  /// Allergen code → description, gathered from the day's dishes.
  final Map<String, String> allergenLegend;

  const MenuDay({
    required this.date,
    required this.locationId,
    required this.locationName,
    required this.meals,
    this.allergenLegend = const {},
  });

  Map<String, dynamic> toJson() => {
    'date':
        '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}',
    'locationId': locationId,
    'locationName': locationName,
    'meals': [for (final m in meals) m.toJson()],
    'allergenLegend': allergenLegend,
  };

  factory MenuDay.fromJson(Map<String, dynamic> json) {
    final parts = (json['date'] as String? ?? '').split('-');
    final legend = <String, String>{};
    final rawLegend = json['allergenLegend'];
    if (rawLegend is Map) {
      for (final e in rawLegend.entries) {
        legend[e.key.toString()] = e.value.toString();
      }
    }
    return MenuDay(
      date: parts.length == 3
          ? DateTime(
              int.parse(parts[0]),
              int.parse(parts[1]),
              int.parse(parts[2]),
            )
          : DateTime.now(),
      locationId: json['locationId'] as String? ?? '',
      locationName: json['locationName'] as String? ?? '',
      meals: [
        for (final m in (json['meals'] as List?) ?? const [])
          ServedMeal.fromJson(Map<String, dynamic>.from(m as Map)),
      ],
      allergenLegend: legend,
    );
  }
}

/// A university dining-menu source. Implementations fetch and parse one
/// provider's site into [MenuDay]s. Only display data flows through this
/// interface — no accounts, no voting.
abstract class MenuProvider {
  /// Stable id, e.g. `'hacettepe'`.
  String get id;

  /// Display name, e.g. `'Hacettepe'`.
  String get displayName;

  /// Location id → display name, e.g. `{'1': 'Beytepe'}`.
  Map<String, String> get locations;

  /// Fetches one day. Throws [MenuFetchException] on network or parse
  /// failures so callers can fall back to cache.
  Future<MenuDay> fetchDay(DateTime date, String locationId);
}

class MenuFetchException implements Exception {
  final String message;
  const MenuFetchException(this.message);

  @override
  String toString() => 'MenuFetchException: $message';
}
