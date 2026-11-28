import 'dart:convert';

import 'package:home_widget/home_widget.dart';

/// Wire keys for the Android home widgets — the Dart mirror of
/// `android/.../widget/WidgetData.kt`'s `Keys` object. Keep both sides in
/// lockstep: every key added here needs a matching Kotlin constant and a
/// parser, and vice versa.
abstract final class WidgetKeys {
  // Prefs key prefixes ("home_widget.<Widget>.<key>").
  static const nextClass = 'home_widget.NextClass';
  static const todayAgenda = 'home_widget.TodayAgenda';
  static const dueTasks = 'home_widget.DueTasksCompact';
  static const hub = 'home_widget.ChronicleHub';
  static const cafeteriaMenu = 'home_widget.CafeteriaMenu';
  static const weeklyCalendar = 'home_widget.WeeklyCalendar';

  // Common scalars (all four widgets).
  static const themeBg = 'themeBg';
  static const useYou = 'useYou';
  static const widgetOpacity = 'widgetOpacity';
  static const todayIso = 'todayIso';
  static const staleClassName = 'staleClassName';
  static const emptyText = 'emptyText';
  // Render-time countdown templates (pushed l10n with a "{n}" slot filled
  // natively by liveStatus in WidgetData.kt). widgetCurrently has no slot:
  // running classes show it verbatim (the range already carries the time).
  static const fmtInMin = 'fmtInMin';
  static const fmtInHours = 'fmtInHours';
  static const fmtCurrently = 'fmtCurrently';

  // NextClass (and hub class tab) timeline: a JSON object keyed by
  // epoch-millis strings `{"<epochMs>": {...}}`. Native renders the entry
  // with the greatest key at or before now. Each entry:
  // {className, detailLine, statusLine, startLabel, thenLine, colorHex,
  //  thenColorHex, teacher, room, building, range, startMs, endMs,
  //  looks: [{time, name, colorHex, at, teacher, room, building, range}]}.
  // startMs/endMs drive the render-time countdown; looks time carries a
  // weekday hint for cross-day rows ("Fri 18:09").
  // `looks` rides INSIDE each entry on purpose: the hub's lookahead rows
  // must follow the render-time hero entry, which a flat list cannot.
  static const timedData = 'timedData';

  // TodayAgenda. `week` is [{label, num, isToday}], `dayN` is
  // [{time, name, colorHex}]. selectedDay is pushed as 0 on every refresh
  // (reset-to-today contract); a native day tap writes the index until the
  // next push overwrites it.
  static const selectedDay = 'selectedDay';
  static const week = 'week';
  // day0..day6 built as 'day$index'.

  // DueTasksCompact. `tasks` is [{title, date, urgent, class, steps}];
  // class/steps ride the details meta line ("Physics · 1/2 steps").
  // tasksCount is the string form of the number shown in the count pill.
  static const headerTitle = 'headerTitle';
  static const tasksCount = 'tasksCount';
  static const tasks = 'tasks';

  // ChronicleHub. Tab flags come from Settings; `selectedTab` is
  // native-owned (position within the enabled list) and never pushed.
  // agendaRows is [{time, name, colorHex}]; tasksRows [{title, date,
  // urgent}]; menuRows is a plain JSON string array of dish names.
  static const tabClass = 'tabClass';
  static const tabAgenda = 'tabAgenda';
  static const tabTasks = 'tabTasks';
  static const tabMenu = 'tabMenu';
  static const selectedTab = 'selectedTab';
  static const agendaRows = 'agendaRows';
  static const tasksRows = 'tasksRows';
  static const tasksTitle = 'tasksTitle';
  // Menu (hub tab + standalone widget). `menuMeals` is every servable
  // meal today: [{kind, title, dishes[]}] in day order; `menuMealDefault`
  // is the lunch-first index the menu page itself would open (lunch when
  // servable, else first servable). `menuMealKind` is
  // native-owned (the kind the user picked with the widget arrows) and
  // never pushed — native falls back to the lunch-first default when it
  // is absent or no longer servable. `menuMealKindDate` day-scopes that
  // pick (yyyy-MM-dd, written natively on every arrow step): it sticks
  // for the day, then the default wins again — same reset-to-today
  // contract as the agenda's `selectedDay`. `menuTitle`/`menuRows` stay
  // as the default meal's snapshot for backward compatibility.
  static const menuTitle = 'menuTitle';
  static const menuRows = 'menuRows';
  static const menuMeals = 'menuMeals';
  static const menuMealDefault = 'menuMealDefault';
  static const menuMealKind = 'menuMealKind';
  static const menuMealKindDate = 'menuMealKindDate';
  static const titleClass = 'titleClass';
  static const titleAgenda = 'titleAgenda';
  static const emptyTasks = 'emptyTasks';
  static const emptyMenu = 'emptyMenu';

  // Next-class display flag (Settings → Widgets): plain class names without
  // the course-code prefix when true. Saved to prefs alongside (informational:
  // the pushed timeline strings already carry the result) and included in the
  // update fingerprint so toggling re-renders even when no class has a code.
  static const widgetFullName = 'widgetFullName';

  // Long-name wrapping (Settings → Widgets): when true, hero and Then-line
  // class names wrap onto multiple lines instead of truncating. Saved to
  // prefs (native reads it at render time) and included in the update
  // fingerprint so toggling re-renders immediately.
  static const widgetWrapName = 'widgetWrapName';
}

/// Formats a timeline class name from the stored class [name] and university
/// [code] ("MAT 103E"). When [hideCodes] (Settings → Widgets) is true the
/// plain name is used; otherwise the code prefixes the name ("CODE · name").
/// Empty codes and placeholder names fall back to the plain name.
///
/// Single source of truth for the hero, Then-line and lookahead rows of both
/// the standalone Next-class widget and the hub class tab (both push the
/// same pre-baked strings), so the two can never diverge. Agenda day rows
/// always use plain names and never call this.
String widgetClassDisplayName({
  required String name,
  required String code,
  required bool hideCodes,
}) {
  if (hideCodes) return name;
  final c = code.trim();
  if (c.isEmpty || name == '—') return name;
  return '$c · $name';
}

/// Receiver class names registered in AndroidManifest.xml, fully qualified.
///
/// Qualified on purpose: debug builds install side-by-side under a different
/// applicationId (`.debug` suffix), and the plugin resolves a bare
/// [androidName] against the applicationId — which no longer matches the
/// real (namespace-based) receiver classes. Qualified names work for both
/// flavors. Keep in lockstep with the manifest.
abstract final class WidgetReceivers {
  static const _pkg = 'com.chronicleapp.chronicle';
  static const nextClass = '$_pkg.NextClassHomeWidgetReceiver';
  static const todayAgenda = '$_pkg.TodayAgendaHomeWidgetReceiver';
  static const dueTasks = '$_pkg.DueTasksCompactHomeWidgetReceiver';
  static const hub = '$_pkg.ChronicleHubHomeWidgetReceiver';
  static const menu = '$_pkg.CafeteriaMenuHomeWidgetReceiver';
  static const weekly = '$_pkg.WeeklyCalendarHomeWidgetReceiver';
}

/// Saves one scalar widget value (bool/int/double/String) under a fully
/// qualified key (`<prefix>.<field>`).
Future<void> widgetSave(String key, Object value) =>
    HomeWidget.saveWidgetData<Object>(key, value);

/// Saves a JSON value (list/map) as the string the Kotlin parsers read.
Future<void> widgetSaveJson(String key, Object? value) =>
    HomeWidget.saveWidgetData<String>(key, jsonEncode(value));

/// Arms timed re-renders for the timeline widgets (next-class hero and the
/// hub): every timeline transition (class start, class end, midnight rollover,
/// closing sentinel) across the next 7 days, 15-min countdown ticks over the
/// next 2 hours, and hourly ticks for the next day. Capped at 64 alarms so
/// AlarmManager limits are never exceeded; WorkManager covers periodic 15-min
/// ticks indefinitely beyond this window.
Future<void> scheduleWidgetTimelines({
  required List<DateTime> boundaries,
}) async {
  for (final name in const [WidgetReceivers.nextClass, WidgetReceivers.hub]) {
    if (boundaries.isEmpty) {
      await HomeWidget.cancelScheduledWidgetUpdates(qualifiedAndroidName: name);
      continue;
    }
    final now = DateTime.now();
    final weekHorizon = now.add(const Duration(days: 7));
    final times = <DateTime>{
      for (final t in boundaries)
        if (t.isAfter(now) && !t.isAfter(weekHorizon)) t,
      for (var i = 1; i <= 8; i++) now.add(Duration(minutes: i * 15)),
      for (var i = 3; i <= 24; i++) now.add(Duration(hours: i)),
      for (var d = 1; d <= 7; d++) DateTime(now.year, now.month, now.day + d),
    }.toList()..sort();
    await HomeWidget.scheduleWidgetUpdates(
      times.take(64).toList(),
      qualifiedAndroidName: name,
    );
  }
}
