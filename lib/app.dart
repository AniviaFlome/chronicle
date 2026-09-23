import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'l10n/l10n.dart';
import 'providers.dart';
import 'screens/absences_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/calendar_screen.dart';
import 'screens/classes_screen.dart';
import 'screens/menu_screen.dart';
import 'screens/tasks_screen.dart';
import 'screens/settings_screen.dart';
import 'theme.dart';

class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ThemeMode.system;

  void set(ThemeMode mode) => state = mode;
}

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);

/// Applies the portrait lock on phones. No-op on desktop: windows are
/// user-resizable and must never be orientation-locked.
Future<void> applyPortraitLock(bool lock) {
  if (!Platform.isAndroid && !Platform.isIOS) return Future.value();
  return SystemChrome.setPreferredOrientations(
    lock ? [DeviceOrientation.portraitUp] : [],
  );
}

class ChronicleApp extends ConsumerWidget {
  const ChronicleApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final router = ref.watch(routerProvider);
    final themeId = ref.watch(appThemeProvider).value ?? defaultAppTheme;
    final accent =
        ref.watch(accentColorProvider).value ?? Catppuccin.defaultAccent;
    final localeCode = ref.watch(appLocaleProvider).value;

    return MaterialApp.router(
      onGenerateTitle: (context) => context.l10n.appTitle,
      debugShowCheckedModeBanner: false,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: localeCode == null ? null : Locale(localeCode),
      theme: buildAppTheme(
        themeId: themeId,
        accentValue: accent,
        brightness: Brightness.light,
      ),
      darkTheme: buildAppTheme(
        themeId: themeId,
        accentValue: accent,
        brightness: Brightness.dark,
      ),
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}

class _NavItem {
  final String location;
  final IconData icon;
  final String Function(AppLocalizations) label;

  const _NavItem(this.location, this.icon, this.label);
}

List<_NavItem> _navItems(AppLocalizations l10n) => [
  _NavItem('/', Icons.dashboard_outlined, (l) => l.navToday),
  _NavItem('/calendar', Icons.calendar_month_outlined, (l) => l.navCalendar),
  _NavItem('/classes', Icons.school_outlined, (l) => l.navClasses),
  _NavItem('/tasks', Icons.checklist_outlined, (l) => l.navTasks),
  _NavItem('/absences', Icons.event_busy_outlined, (l) => l.navAbsences),
  _NavItem('/menu', Icons.restaurant_outlined, (l) => l.navMenu),
  _NavItem('/settings', Icons.settings_outlined, (l) => l.navSettings),
];

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      ShellRoute(
        builder: (context, state, child) => _Shell(child: child),
        routes: [
          GoRoute(path: '/', builder: (_, _) => const DashboardScreen()),
          GoRoute(path: '/calendar', builder: (_, _) => const CalendarScreen()),
          GoRoute(path: '/classes', builder: (_, _) => const ClassesScreen()),
          GoRoute(path: '/tasks', builder: (_, _) => const TasksScreen()),
          GoRoute(path: '/absences', builder: (_, _) => const AbsencesScreen()),
          GoRoute(path: '/menu', builder: (_, _) => const MenuScreen()),
          GoRoute(path: '/settings', builder: (_, _) => const SettingsScreen()),
        ],
      ),
    ],
  );
});

class _Shell extends StatelessWidget {
  final Widget child;

  const _Shell({required this.child});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final items = _navItems(context.l10n);
    final selectedIndex = items
        .indexWhere((i) => i.location == location)
        .clamp(0, items.length - 1);
    final wide = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      body: Row(
        children: [
          if (MediaQuery.of(context).size.width >= 600)
            NavigationRail(
              selectedIndex: selectedIndex,
              onDestinationSelected: (i) => context.go(items[i].location),
              extended: wide,
              destinations: [
                for (final item in items)
                  NavigationRailDestination(
                    icon: Icon(item.icon),
                    label: Text(item.label(context.l10n)),
                  ),
              ],
            ),
          Expanded(child: child),
        ],
      ),
      bottomNavigationBar: MediaQuery.of(context).size.width < 600
          ? _PhoneNavBar(
              selectedIndex: selectedIndex,
              items: items,
              onSelect: (i) => context.go(items[i].location),
            )
          : null,
    );
  }
}

/// Phone bottom bar with always-visible labels.
///
/// The stock [NavigationBar] cannot fit seven labels in ~360px (its label
/// has no maxLines, so "Absences" wrapped to two lines), and showing only
/// the selected label makes every item jump on tab switches. This bar
/// instead gives each destination an equal [Expanded] slot with a
/// single-line ellipsis label, so nothing wraps and nothing moves.
class _PhoneNavBar extends StatelessWidget {
  final int selectedIndex;
  final List<_NavItem> items;
  final ValueChanged<int> onSelect;

  const _PhoneNavBar({
    required this.selectedIndex,
    required this.items,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final labelStyle = Theme.of(context).textTheme.labelSmall;
    return Material(
      color: scheme.surfaceContainer,
      child: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Active pill fits inside its slot with room to spare.
            final pillWidth = (constraints.maxWidth / items.length - 8)
                .clamp(40.0, 64.0);
            return SizedBox(
              height: 80,
              child: Row(
                children: [
                  for (var i = 0; i < items.length; i++)
                    Expanded(
                      child: Tooltip(
                        message: items[i].label(l10n),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () => onSelect(i),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: pillWidth,
                                height: 32,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  color: i == selectedIndex
                                      ? scheme.secondaryContainer
                                      : Colors.transparent,
                                ),
                                child: Icon(
                                  items[i].icon,
                                  size: 24,
                                  color: i == selectedIndex
                                      ? scheme.onSecondaryContainer
                                      : scheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                items[i].label(l10n),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: labelStyle?.copyWith(
                                  color: i == selectedIndex
                                      ? scheme.onSurface
                                      : scheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
