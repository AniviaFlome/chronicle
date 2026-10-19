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
  static const fmtEnds = 'fmtEnds';
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

  // DueTasksCompact. `tasks` is [{title, date, urgent}]. tasksCount is the
  // string form of the number shown in the count pill.
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
  // is the index the menu page itself would open (_syncMealToDay without a
  // previous selection: first meal with dishes). `menuMealKind` is
  // native-owned (the kind the user picked with the widget arrows) and
  // never pushed — native falls back to the default when it is absent or
  // no longer servable. `menuTitle`/`menuRows` stay as the default meal's
  // snapshot for backward compatibility.
  static const menuTitle = 'menuTitle';
  static const menuRows = 'menuRows';
  static const menuMeals = 'menuMeals';
  static const menuMealDefault = 'menuMealDefault';
  static const menuMealKind = 'menuMealKind';
  static const titleClass = 'titleClass';
  static const titleAgenda = 'titleAgenda';
  static const emptyTasks = 'emptyTasks';
  static const emptyMenu = 'emptyMenu';
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
/// hub): every timeline key (entry switchover + closing sentinel), hourly
/// ticks for the next day, and the next midnight (day rollover). Replaces
/// any previous schedule for those receivers; [boundaries] empty cancels.
/// Times are absolute instants — recompute on every push.
Future<void> scheduleWidgetTimelines({required List<DateTime> boundaries}) async {
  for (final name in const [WidgetReceivers.nextClass, WidgetReceivers.hub]) {
    if (boundaries.isEmpty) {
      await HomeWidget.cancelScheduledWidgetUpdates(
        qualifiedAndroidName: name,
      );
      continue;
    }
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day + 1);
    final times = <DateTime>{
      for (final t in boundaries)
        if (t.isAfter(now)) t,
      for (var i = 1; i <= 24; i++) now.add(Duration(hours: i)),
      midnight,
    }.toList()..sort();
    await HomeWidget.scheduleWidgetUpdates(
      times,
      qualifiedAndroidName: name,
    );
  }
}
