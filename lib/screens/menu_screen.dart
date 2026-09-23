import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/repositories.dart';
import '../l10n/l10n.dart';
import '../providers.dart';
import '../services/menu/menu_provider.dart';
import '../services/menu/menu_sources.dart';
import '../utils/time_format.dart';

/// Dining-hall menu page. v1 shows one provider (Hacettepe): pick a campus
/// and a day, switch between meals. Network failures fall back to the last
/// cached response, marked stale. Dish names are shown as published.
class MenuScreen extends ConsumerStatefulWidget {
  /// Override for tests (a fake provider instead of the network).
  final MenuProvider? provider;

  const MenuScreen({super.key, this.provider});

  @override
  ConsumerState<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends ConsumerState<MenuScreen> {
  static const cacheTtl = Duration(hours: 6);
  static const defaultMeal = 'ogle';

  late DateTime _date;
  String _location = '1';
  String _meal = defaultMeal;
  MenuDay? _day;
  bool _loading = true;
  bool _stale = false;
  String? _error;

  /// Resolved menu source, or null when the user picked none. Stays null
  /// until settings load, so the page is empty by default.
  MenuProvider? _provider;

  /// Monotonic id for the latest load; stale completions (e.g. a slow
  /// fetch for a previous day) are ignored instead of overwriting state.
  int _loadGen = 0;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _date = DateTime(now.year, now.month, now.day);
    _init();
  }

  Future<void> _init() async {
    MenuProvider? provider = widget.provider;
    var location = '1';
    try {
      final settings = ref.read(settingsRepositoryProvider);
      provider ??= menuSources[await settings.menuProviderId()]?.create();
      final saved = await settings.menuLocation();
      if (provider != null && provider.locations.containsKey(saved)) {
        location = saved;
      }
    } catch (e) {
      debugPrint('Load menu source failed: $e');
    }
    if (!mounted) return;
    setState(() {
      _provider = provider;
      _location = location;
      // No source selected: stay on the empty state, don't fetch.
      if (provider == null) _loading = false;
    });
    await _load();
  }

  Future<void> _load({bool refresh = false}) async {
    final provider = _provider;
    if (provider == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    final gen = ++_loadGen;
    final iso = isoFromDateTime(_date);
    final repo = MenuCacheRepository(ref.read(appDatabaseProvider));
    if (!refresh) {
      final cached = await repo.cachedDay(provider.id, _location, iso);
      if (!mounted || gen != _loadGen) return;
      if (cached != null) {
        final age = DateTime.now().millisecondsSinceEpoch - cached.fetchedAt;
        setState(() {
          _day = cached.day;
          _stale = age > cacheTtl.inMilliseconds;
          _loading = false;
          _error = null;
        });
        if (!_stale) return;
      } else {
        setState(() {
          _loading = true;
          _error = null;
        });
      }
    }
    try {
      final day = await provider.fetchDay(_date, _location);
      await repo.storeDay(provider.id, _location, iso, day);
      if (!mounted || gen != _loadGen) return;
      setState(() {
        _day = day;
        _stale = false;
        _loading = false;
        _error = null;
        if (day.meals.every((m) => m.kind != _meal) && day.meals.isNotEmpty) {
          _meal = day.meals.first.kind;
        }
      });
    } catch (e) {
      debugPrint('Menu fetch failed: $e');
      if (!mounted || gen != _loadGen) return;
      setState(() {
        _loading = false;
        if (_day == null) _error = context.l10n.menuError;
      });
      if (_day != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.menuError)),
        );
      }
    }
  }

  void _shiftDay(int delta) {
    setState(() {
      _date = shiftDays(_date, delta);
      _day = null;
      _error = null;
      _stale = false;
    });
    _load();
  }

  void _goToday() {
    final now = DateTime.now();
    setState(() {
      _date = DateTime(now.year, now.month, now.day);
      _day = null;
      _error = null;
      _stale = false;
    });
    _load();
  }

  Future<void> _setLocation(String value) async {
    setState(() {
      _location = value;
      _day = null;
      _error = null;
      _stale = false;
    });
    try {
      await ref.read(settingsRepositoryProvider).setMenuLocation(value);
    } catch (e) {
      debugPrint('Save menu location failed: $e');
    }
    await _load();
  }

  String _mealLabel(String kind) {
    final l10n = context.l10n;
    return switch (kind) {
      'sabah' => l10n.mealBreakfast,
      'ogle' => l10n.mealLunch,
      'aksam' => l10n.mealDinner,
      'vegan' => l10n.mealVegan,
      _ => kind,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final day = _day;
    ServedMeal? meal;
    if (day != null && day.meals.isNotEmpty) {
      meal = day.meals.first;
      for (final m in day.meals) {
        if (m.kind == _meal) {
          meal = m;
          break;
        }
      }
    }

    final provider = _provider;
    if (provider == null) {
      // No menu source selected: empty by default.
      return Scaffold(
        appBar: AppBar(title: Text(context.l10n.navMenu)),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.restaurant_outlined,
                        size: 64,
                        color: theme.colorScheme.outline,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        context.l10n.menuChooseSource,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: () => context.go('/settings'),
                        icon: const Icon(Icons.settings_outlined),
                        label: Text(context.l10n.navSettings),
                      ),
                    ],
                  ),
                ),
              ),
      );
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final isToday =
        _date.year == today.year &&
        _date.month == today.month &&
        _date.day == today.day;

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.navMenu)),
      body: RefreshIndicator(
        onRefresh: () => _load(refresh: true),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  tooltip: context.l10n.prevDay,
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () => _shiftDay(-1),
                ),
                // Date only: the old "date · Today" label read as if every
                // day were today. Tapping the date still jumps back to today.
                Tooltip(
                  message: context.l10n.navToday,
                  child: TextButton(
                    onPressed: isToday ? null : _goToday,
                    child: Text(isoFromDateTime(_date)),
                  ),
                ),
                IconButton(
                  tooltip: context.l10n.nextDay,
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () => _shiftDay(1),
                ),
              ],
            ),
            if (!isToday)
              Center(
                child: TextButton.icon(
                  onPressed: _goToday,
                  icon: const Icon(Icons.today_outlined, size: 18),
                  label: Text(context.l10n.navToday),
                ),
              ),
            const SizedBox(height: 8),
            // Campus picker: full-width column so the Beytepe/Sıhhiye
            // segments get proper touch targets and never squeeze against
            // the label on narrow Android phones. Scrolls instead of
            // overflowing when the labels are wider than the screen.
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.campusLabel,
                  style: theme.textTheme.labelLarge,
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SegmentedButton<String>(
                    style: const ButtonStyle(
                      visualDensity: VisualDensity.standard,
                      tapTargetSize: MaterialTapTargetSize.padded,
                    ),
                    segments: [
                      for (final entry in provider.locations.entries)
                        ButtonSegment(
                          value: entry.key,
                          label: Text(entry.value),
                        ),
                    ],
                    selected: {_location},
                    showSelectedIcon: false,
                    onSelectionChanged: (s) => _setLocation(s.single),
                  ),
                ),
              ],
            ),
            if (day != null && day.meals.length > 1) ...[
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SegmentedButton<String>(
                  style: const ButtonStyle(
                    visualDensity: VisualDensity.standard,
                    tapTargetSize: MaterialTapTargetSize.padded,
                  ),
                  segments: [
                    for (final m in day.meals)
                      ButtonSegment(
                        value: m.kind,
                        label: Text(_mealLabel(m.kind)),
                      ),
                  ],
                  selected: {
                    day.meals.any((m) => m.kind == _meal)
                        ? _meal
                        : day.meals.first.kind,
                  },
                  showSelectedIcon: false,
                  onSelectionChanged: (s) =>
                      setState(() => _meal = s.single),
                ),
              ),
            ],
            const SizedBox(height: 12),
            if (_loading && day == null)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null && day == null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 48),
                child: Column(
                  children: [
                    Icon(
                      Icons.cloud_off_outlined,
                      size: 48,
                      color: theme.colorScheme.outline,
                    ),
                    const SizedBox(height: 12),
                    Text(_error!, style: theme.textTheme.titleMedium),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: () => _load(refresh: true),
                      icon: const Icon(Icons.refresh),
                      label: Text(context.l10n.menuRetry),
                    ),
                  ],
                ),
              )
            else if (meal == null || meal.dishes.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 48),
                child: Center(
                  child: Text(
                    context.l10n.menuEmpty,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ),
              )
            else ...[
              if (_stale)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Icon(
                        Icons.history_outlined,
                        size: 16,
                        color: theme.colorScheme.outline,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          context.l10n.menuStale,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Icon(
                        Icons.local_fire_department_outlined,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          meal.totalKcal == null
                              ? _mealLabel(meal.kind)
                              : '${_mealLabel(meal.kind)} · '
                                    '${context.l10n.menuKcal(meal.totalKcal!)}',
                          style: theme.textTheme.titleSmall,
                        ),
                      ),
                      if (meal.serviceHours.isNotEmpty) ...[
                        Icon(
                          Icons.schedule_outlined,
                          size: 16,
                          color: theme.colorScheme.outline,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          meal.serviceHours,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              for (final dish in meal.dishes)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                dish.name,
                                style: theme.textTheme.titleSmall,
                              ),
                            ),
                            if (dish.kcal != null)
                              Text(
                                context.l10n.menuKcal(dish.kcal!),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.outline,
                                ),
                              ),
                          ],
                        ),
                        if (dish.category.isNotEmpty ||
                            dish.allergens.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              if (dish.category.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: theme
                                        .colorScheme
                                        .secondaryContainer,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    dish.category,
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: theme.colorScheme
                                          .onSecondaryContainer,
                                    ),
                                  ),
                                ),
                              for (final code in dish.allergens)
                                _AllergenChip(
                                  code: code,
                                  onTap: () => _showAllergen(code),
                                ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              Builder(
                builder: (context) {
                  final legend = day?.allergenLegend ?? const {};
                  if (legend.isEmpty) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: _AllergenPanel(legend: legend),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Shows what an allergen code means (from the day's legend, if known).
  void _showAllergen(String code) {
    final desc = _day?.allergenLegend[code];
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${context.l10n.allergensTitle} · $code'),
        content: Text(
          desc ?? code,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(context.l10n.close),
          ),
        ],
      ),
    );
  }
}

/// Expandable allergen legend panel. The stock [ExpansionTile] header
/// flashes a full-width rectangular ripple; here the only control is a
/// circular expander button, so the tap highlight is circular too. Tapping
/// the header row toggles without any splash.
class _AllergenPanel extends StatefulWidget {
  final Map<String, String> legend;

  const _AllergenPanel({required this.legend});

  @override
  State<_AllergenPanel> createState() => _AllergenPanelState();
}

class _AllergenPanelState extends State<_AllergenPanel>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;

  static const _animDuration = Duration(milliseconds: 120);

  void _toggle() => setState(() => _expanded = !_expanded);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _toggle,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 4, 4),
              child: Row(
                children: [
                  const SizedBox(width: 12),
                  Icon(
                    Icons.warning_amber_outlined,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      context.l10n.allergensTitle,
                      style: theme.textTheme.titleSmall,
                    ),
                  ),
                  Material(
                    color: Colors.transparent,
                    shape: const CircleBorder(),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: _toggle,
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: AnimatedRotation(
                          turns: _expanded ? 0.5 : 0,
                          duration: _animDuration,
                          child: const Icon(Icons.expand_more),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
              ),
            ),
          ),
          // Height-only animation: AnimatedCrossFade squeezed the outgoing
          // child horizontally, wrapping legend text letter-by-letter.
          AnimatedSize(
            duration: _animDuration,
            child: _expanded
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final entry in widget.legend.entries)
                        ListTile(
                          dense: true,
                          leading: _AllergenBadge(code: entry.key),
                          title: Text(
                            entry.value,
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

/// Tappable allergen code chip. Small single-letter chips read as circular,
/// so the chip, its background and its tap highlight all use a stadium
/// (pill) shape: the splash can never paint a rectangle. The background is
/// painted with an [Ink] widget so the splash clips to the very same shape.
class _AllergenChip extends StatelessWidget {
  final String code;
  final VoidCallback onTap;

  const _AllergenChip({required this.code, required this.onTap});

  static const _shape = StadiumBorder();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          color: theme.colorScheme.errorContainer.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(999),
        ),
        child: InkWell(
          onTap: onTap,
          customBorder: _shape,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            child: Text(
              code,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onErrorContainer,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Static allergen code badge for the legend (same pill, no splash).
class _AllergenBadge extends StatelessWidget {
  final String code;

  const _AllergenBadge({required this.code});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        code,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onErrorContainer,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
