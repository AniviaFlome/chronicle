import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';

import '../app.dart';
import '../data/repositories.dart';
import '../domain/grades.dart';
import '../domain/schedule_models.dart' as engine;
import '../l10n/app_localizations.dart';
import '../providers.dart';
import './menu/menu_provider.dart';
import '../utils/time_format.dart';
import '../utils/ui_feedback.dart';
import './menu/menu_sources.dart';
import 'widget_push.dart';

/// Last-sent payload fingerprint per widget prefix (in-memory only).
/// See `updateIfChanged` inside `_push`.
final _lastWidgetPayload = <String, String>{};

/// Pushes schedule/task snapshots to the Android home widgets.
///
/// Best-effort only: the widgets also re-render on their own from stored
/// prefs (Glance `updatePeriodMillis`, scheduled timeline updates) and the
/// timeline contract keeps them meaningful between pushes, so a failed
/// push here never leaves a permanently stale widget. No-op off Android
/// (incl. tests on other platforms); plugin errors are swallowed.
///
/// The wire format is the JSON-string contract in [WidgetKeys]; the Kotlin
/// mirror is `android/.../widget/WidgetData.kt` — keep them in lockstep.
/// All dynamic strings are pre-formatted here (locale-aware); native code
/// only lays them out.
Future<void> refreshHomeWidgets(ProviderContainer container) async {
  if (defaultTargetPlatform != TargetPlatform.android) return;
  // Widget tests run with FakeAsync: the push below performs real async
  // I/O (drift streams, an 8s self-heal fetch timeout) that never
  // completes in fake time and wedges pumpAndSettle forever. Widgets
  // re-render from stored prefs on their own cadence, so skipping the
  // push under flutter_test loses no coverage.
  if (Platform.environment.containsKey('FLUTTER_TEST')) return;
  try {
    await _push(container);
  } catch (e) {
    logLoadFailure('Home widget refresh', e);
  }
}

/// Class color as an 8-hex "AARRGGBB" string for the native side (never an
/// ARGB int: raw color ints crashed the Glance render). Empty falls back to
/// the palette accent on the Kotlin side.
String _hexColor(int colorValue) {
  if (colorValue == 0) return '';
  return (colorValue & 0xffffffff)
      .toRadixString(16)
      .padLeft(8, '0')
      .toUpperCase();
}

Future<void> _push(ProviderContainer container) async {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final tomorrow = shiftDays(today, 1);
  final locale = await container.read(appLocaleProvider.future) ?? 'en';
  final lang = locale.split(RegExp(r'[_-]')).first;
  final l10n = lookupAppLocalizations(Locale(lang == 'tr' ? 'tr' : 'en'));

  // Widget theme as a small code in themeBg (familyIndex * 2 + darkBit):
  // 0 default, 1 catppuccin, 2 nord, 3 dracula, 4 gruvbox, 5 tokyo-night.
  // Native maps it to hardcoded ColorProvider triples; plain ARGB ints
  // crashed the render (proven by on-device bisect), so the code table is
  // the crash-safe path. Must stay in lockstep with WidgetTheme.kt's
  // THEME_TABLE.
  final themeId = await container.read(appThemeProvider.future);
  final mode = container.read(themeModeProvider);
  final brightness = switch (mode) {
    ThemeMode.light => Brightness.light,
    ThemeMode.dark => Brightness.dark,
    _ => SchedulerBinding.instance.platformDispatcher.platformBrightness,
  };
  final themeBg =
      switch (themeId) {
        'catppuccin' => 1,
        'nord' => 2,
        'dracula' => 3,
        'gruvbox' => 4,
        'tokyo-night' => 5,
        _ => 0,
      } *
      2 +
      (brightness == Brightness.dark ? 1 : 0);
  // Material You toggle (Settings → Widgets): native renders pure GlanceTheme
  // system colors when true, the app-theme triple otherwise.
  final useYou =
      await container.read(settingsRepositoryProvider).widgetStyle() ==
      'you';
  // Background opacity (Settings → Widgets): 0 solid, 1 translucent,
  // 2 transparent. Pushed as an int — widgets can't read app prefs.
  final widgetOpacity =
      await container.read(settingsRepositoryProvider).widgetOpacity();

  final occurrenceEngine = await container.read(engineProvider.future);
  final byId = await container.read(classesByIdProvider.future);
  // Scan a full week ahead so the Next-class widget can show the next
  // real class ("Tue 08:40…") instead of going blank on class-free days.
  final horizon = shiftDays(today, 7);
  final occs = occurrenceEngine
      .occurrences(rangeStart: today, rangeEnd: horizon)
      .where((o) => !o.date.isBefore(today) && !o.date.isAfter(horizon))
      .toList()
    ..sort((a, b) {
      final d = a.date.compareTo(b.date);
      return d != 0 ? d : a.startMinutes.compareTo(b.startMinutes);
    });

  // Next class: remaining classes today plus the next 7 days. Classes past
  // tomorrow get a weekday prefix ("Tue 08:40–09:30"). Each entry is keyed
  // at the time it should appear: the previous class's end (start of today
  // for the first), because the native side shows the entry with the
  // greatest key at or before now — keying at class start would blank the
  // widget before the first class. A trailing "—" entry keyed at the last
  // class end clears it afterwards.
  final nowMinutes = now.hour * 60 + now.minute;
  final upcoming = [
    for (final o in occs)
      if (o.date.isAfter(today) || o.endMinutes > nowMinutes) o,
  ];
  String rangeFor(engine.ClassOccurrence o) {
    final range =
        '${hhmmLocale(o.startMinutes, locale)}–${hhmmLocale(o.endMinutes, locale)}';
    if (o.date == today || o.date == tomorrow) return range;
    return '${shortWeekdayName(o.date.weekday, locale)} $range';
  }

  final listed = upcoming.take(12).toList();
  String nameOf(engine.ClassOccurrence o) => byId[o.classId]?.name ?? '—';
  String codeOf(engine.ClassOccurrence o) =>
      byId[o.classId]?.courseCode?.trim() ?? '';
  String teacherOf(engine.ClassOccurrence o) =>
      byId[o.classId]?.teacher?.trim() ?? '';
  // Display name with the saved university course code when one exists
  // ("MAT 103E · Müzik Teorisi I"), plain name otherwise. Used by the
  // timeline (hero/then/looks); agenda day rows keep plain names.
  String displayNameOf(engine.ClassOccurrence o) {
    final code = codeOf(o);
    final name = nameOf(o);
    if (code.isEmpty || name == '—') return name;
    return '$code · $name';
  }
  String colorOf(engine.ClassOccurrence o) =>
      _hexColor(byId[o.classId]?.colorValue ?? 0);

  // "When" label for Then-lines: plain time same-day, weekday-prefixed
  // otherwise (a bare time after midnight reads as "soon").
  String whenOf(engine.ClassOccurrence o) {
    final time = hhmmLocale(o.startMinutes, locale);
    return o.date == today
        ? time
        : '${shortWeekdayName(o.date.weekday, locale)} $time';
  }

  // "Then" entry at index i names class i+1 (empty for the last class
  // and the sentinel). Pushed as structured name/when parts; `thenLine`
  // keeps the composed string for backward compatibility.
  String thenNameFor(int i) {
    if (i + 1 >= listed.length) return '';
    return displayNameOf(listed[i + 1]);
  }

  String thenWhenFor(int i) {
    if (i + 1 >= listed.length) return '';
    return whenOf(listed[i + 1]);
  }

  String thenFor(int i) {
    if (i + 1 >= listed.length) return '';
    return l10n.widgetThen(displayNameOf(listed[i + 1]), whenOf(listed[i + 1]));
  }

  String detailLineFor(engine.ClassOccurrence o) {
    final room = o.room ?? byId[o.classId]?.room;
    final range = rangeFor(o);
    final roomText = room?.trim();
    // A bare "--" (placeholder users type for "no room") reads as noise
    // on the widget; treat it like an absent room.
    if (roomText == null || roomText.isEmpty || roomText == '--') return range;
    return '$range · $roomText';
  }

  // Countdown lives in its own pill on the new design ("in 12 min",
  // "Currently · ends 09:30"). Only for today's classes — future entries
  // already carry a weekday prefix, and a day-count would go stale between
  // pushes.
  String statusFor(engine.ClassOccurrence o) {
    if (o.date != today) return '';
    if (o.startMinutes > nowMinutes) {
      final mins = o.startMinutes - nowMinutes;
      return mins < 120
          ? l10n.widgetInMin(mins)
          : l10n.widgetInHours(mins ~/ 60);
    }
    // Running: plain "Currently" — the detail line already carries the
    // time range, so an "ends {time}" suffix would repeat the end time.
    return l10n.widgetCurrently;
  }

  // Hub class-tab lookahead rows: the classes after the hero entry,
  // display names with course codes (no Then/Later prefix — the native
  // side lays out time and name separately). Rides inside each timeline
  // entry so the native side can slice it at render time.
  List<Map<String, Object?>> looksFor(int i) => [
    for (var j = i + 1; j < listed.length && j <= i + 2; j++)
      {
        // Cross-day rows carry a weekday hint ("Fri 18:09"); the native
        // chip wraps instead of clipping when the time has a space.
        'time': listed[j].date == today
            ? hhmmLocale(listed[j].startMinutes, locale)
            : '${shortWeekdayName(listed[j].date.weekday, locale)} ${hhmmLocale(listed[j].startMinutes, locale)}',
        'name': displayNameOf(listed[j]),
        'colorHex': colorOf(listed[j]),
      },
  ];

  Map<String, Object?> entryJson({
    required String className,
    required String detailLine,
    required String statusLine,
    required String startLabel,
    required String thenLine,
    required String thenName,
    required String thenWhen,
    required String colorHex,
    required String thenColorHex,
    required String teacher,
    required List<Map<String, Object?>> looks,
    // Class start/end instants (epoch ms) for the render-time countdown;
    // 0 on synthetic entries (no-classes/sentinel).
    required int startMs,
    required int endMs,
  }) => {
    'className': className,
    'detailLine': detailLine,
    'statusLine': statusLine,
    'startLabel': startLabel,
    'thenLine': thenLine,
    'thenName': thenName,
    'thenWhen': thenWhen,
    'colorHex': colorHex,
    'thenColorHex': thenColorHex,
    'teacher': teacher,
    'looks': looks,
    'startMs': startMs,
    'endMs': endMs,
  };

  final firstIsToday = listed.isNotEmpty && listed[0].date == today;
  // Built imperatively: map-literal duplicate keys throw at runtime.
  final timed = <String, Map<String, Object?>>{};
  String keyOf(DateTime at) => at.millisecondsSinceEpoch.toString();
  // Nothing today: say so instead of showing tomorrow's class as if it
  // were happening now; tomorrow rides in the Then-line instead.
  if (!firstIsToday && listed.isNotEmpty) {
    timed[keyOf(today)] = entryJson(
      className: l10n.widgetNoClasses,
      detailLine: '',
      statusLine: '',
      startLabel: '',
      thenLine: l10n.widgetThen(displayNameOf(listed[0]), whenOf(listed[0])),
      thenName: displayNameOf(listed[0]),
      thenWhen: whenOf(listed[0]),
      colorHex: '',
      thenColorHex: colorOf(listed[0]),
      teacher: teacherOf(listed[0]),
      looks: looksFor(-1),
      startMs: 0,
      endMs: 0,
    );
  }
  for (var i = 0; i < listed.length; i++) {
    final o = listed[i];
    final next = i + 1 < listed.length ? listed[i + 1] : null;
    final at = i == 0 ? (firstIsToday ? today : listed[i].start) : listed[i - 1].end;
    timed[keyOf(at)] = entryJson(
      className: displayNameOf(o),
      detailLine: detailLineFor(o),
      statusLine: statusFor(o),
      startLabel: whenOf(o),
      thenLine: thenFor(i),
      thenName: thenNameFor(i),
      thenWhen: thenWhenFor(i),
      colorHex: colorOf(o),
      thenColorHex: next == null ? '' : colorOf(next),
      teacher: teacherOf(o),
      looks: looksFor(i),
      startMs: o.start.millisecondsSinceEpoch,
      endMs: o.end.millisecondsSinceEpoch,
    );
  }
  if (listed.isNotEmpty) {
    timed[keyOf(listed.last.end)] = entryJson(
      className: '—',
      detailLine: '',
      statusLine: '',
      startLabel: '',
      thenLine: '',
      thenName: '',
      thenWhen: '',
      colorHex: '',
      thenColorHex: '',
      teacher: '',
      looks: const [],
      startMs: 0,
      endMs: 0,
    );
  }

  // Agenda: one class list per day of the week ahead (the widget shows the
  // selected rail day's rows, defaulting to today), plus the 7-day rail
  // marking today.
  List<Map<String, Object?>> dayRows(int i) => [
    for (final o in occs.where((o) => o.date == shiftDays(today, i)).take(10))
      {
        'time': hhmmLocale(o.startMinutes, locale),
        'name': nameOf(o),
        'colorHex': colorOf(o),
      },
  ];
  final agendaDays = [for (var i = 0; i < 7; i++) dayRows(i)];
  final week = [
    for (var i = 0; i < 7; i++)
      {
        'label': shortWeekdayName(shiftDays(today, i).weekday, locale),
        'num': '${shiftDays(today, i).day}',
        'isToday': i == 0,
      },
  ];

  // Due tasks: open tasks with a due date, overdue first, capped at 8.
  // The title carries no checkbox prefix (the row draws one) and the date
  // is a friendly label; overdue flips the `urgent` flag (error-colored
  // chip + bold title on the native side).
  final repo = container.read(taskRepositoryProvider);
  final open = await repo.watchAll(onlyOpen: true).first;
  final dated = [
    for (final t in open)
      if (t.task.dueDate != null) t,
  ]..sort((a, b) {
      final d = a.task.dueDate!.compareTo(b.task.dueDate!);
      if (d != 0) return d;
      return (a.task.dueMinutes ?? 0).compareTo(b.task.dueMinutes ?? 0);
    });
  String taskDateLabel(String dueIso, int? dueMinutes) {
    final due = DateTime.tryParse(dueIso);
    final time = dueMinutes != null ? hhmmLocale(dueMinutes, locale) : null;
    if (due == null) return time ?? dueIso;
    final days = daysUntil(dueIso, now);
    if (days == 0) return time ?? l10n.widgetToday;
    final base = days.abs() <= 6
        ? shortWeekdayName(due.weekday, locale)
        : DateFormat.MMMd(lang).format(due);
    return time == null ? base : '$base $time';
  }

  final taskRows = [
    for (final t in dated.take(8))
      {
        'title': t.task.title,
        'date': taskDateLabel(t.task.dueDate!, t.task.dueMinutes),
        'urgent': daysUntil(t.task.dueDate!, now) < 0,
      },
  ];
  final tasksCount = '${dated.length}';

  // Hub widget: one entry per enabled tab. Class tab reuses the exact
  // Next-class timeline (same keying); agenda/tasks reuse the day/task
  // rows; menu shows the current meal's dishes. Tab flags come from
  // Settings (all on by default); the selected tab itself is native-owned
  // and never pushed.
  final settings = container.read(settingsRepositoryProvider);
  final tabClass = await settings.hubTabClass();
  final tabAgenda = await settings.hubTabAgenda();
  final tabTasks = await settings.hubTabTasks();
  final tabMenu = await settings.hubTabMenu();
  // Menu: every servable meal today, in day order. The default index
  // mirrors the menu page's own rule (_syncMealToDay without a previous
  // selection: first meal with dishes). The widget keeps a native-owned
  // kind override (arrows); it falls back to this default when the
  // override is unset or no longer servable.
  String hubMenuTitle = l10n.navMenu;
  var hubMenu = const <String>[];
  var menuMeals = const <Map<String, Object?>>[];
  const menuMealDefault = 0;
  {
    final providerId = await settings.menuProviderId();
    final locationId = await settings.menuLocation();
    if (providerId.isNotEmpty) {
      final db = container.read(appDatabaseProvider);
      final repo = MenuCacheRepository(db);
      var cached = await repo.cachedDay(
        providerId,
        locationId,
        isoFromDateTime(today),
      );
      // Self-healing: the widget push only ever reads the cache, so a
      // missing day (source picked but menu page never opened) would leave
      // widgets permanently empty. Best-effort fetch with a short timeout;
      // any failure keeps the previous behavior (empty state).
      if (cached == null) {
        final factory = menuSources[providerId]?.create;
        if (factory != null) {
          try {
            final provider = factory();
            try {
              final day = await provider
                  .fetchDay(today, locationId)
                  .timeout(const Duration(seconds: 8));
              await repo.storeDay(
                providerId,
                locationId,
                isoFromDateTime(today),
                day,
              );
              cached = await repo.cachedDay(
                providerId,
                locationId,
                isoFromDateTime(today),
              );
            } finally {
              provider.close();
            }
          } catch (_) {
            // Fall through to empty state below.
          }
        }
      }
      final day = cached?.day;
      if (day != null) {
        String mealTitle(ServedMeal m) {
          final kindLabel = switch (m.kind) {
            'sabah' => l10n.mealBreakfast,
            'ogle' => l10n.mealLunch,
            'aksam' => l10n.mealDinner,
            'vegan' => l10n.mealVegan,
            _ => m.kind,
          };
          final providerTag = providerId == 'itu' ? 'ITU' : 'Hacettepe';
          return '$kindLabel · $providerTag';
        }

        menuMeals = [
          for (final m in day.meals)
            if (m.dishes.isNotEmpty)
              {
                'kind': m.kind,
                'title': mealTitle(m),
                'dishes': [for (final d in m.dishes.take(8)) d.name],
              },
        ];
        if (menuMeals.isNotEmpty) {
          hubMenuTitle = menuMeals[menuMealDefault]['title'] as String;
          hubMenu = [
            for (final d in (menuMeals[menuMealDefault]['dishes'] as List))
              d.toString(),
          ];
        }
      }
    }
  }

  // ---- Save every snapshot first, then update every widget, so a theme
  // ---- change re-renders all widgets from the same push.
  //
  // Payload fingerprints skip redundant updates: re-applying identical
  // RemoteViews is what users perceive as flicker on every app resume.
  // Countdown freshness between pushes is covered natively (class
  // instants re-render on every compose) and by the scheduled timeline
  // ticks below. In-memory only: the first push after a restart always
  // goes out. The agenda is exempt (always=true): its selectedDay=0
  // reset-to-today contract must hold on every refresh.
  Map<String, Object?> commonFields(String emptyText) => {
    WidgetKeys.themeBg: themeBg,
    WidgetKeys.useYou: useYou,
    WidgetKeys.widgetOpacity: widgetOpacity,
    WidgetKeys.todayIso: isoFromDateTime(today),
    WidgetKeys.staleClassName: l10n.widgetNoClasses,
    WidgetKeys.emptyText: emptyText,
    WidgetKeys.fmtInMin: l10n.widgetInMin('{n}'),
    WidgetKeys.fmtInHours: l10n.widgetInHours('{n}'),
    WidgetKeys.fmtEnds: l10n.widgetCurrentlyEnds('{n}'),
    WidgetKeys.fmtCurrently: l10n.widgetCurrently,
  };

  Future<Map<String, Object?>> saveCommon(
    String prefix, {
    required String emptyText,
  }) async {
    final fields = commonFields(emptyText);
    for (final e in fields.entries) {
      await widgetSave('$prefix.${e.key}', e.value as Object);
    }
    return fields;
  }

  Future<void> updateIfChanged(
    String prefix,
    String receiver,
    Map<String, Object?> payload, {
    bool always = false,
  }) async {
    if (!always) {
      final fingerprint = jsonEncode(payload);
      if (_lastWidgetPayload[prefix] == fingerprint) return;
      _lastWidgetPayload[prefix] = fingerprint;
    }
    await HomeWidget.updateWidget(qualifiedAndroidName: receiver);
  }

  // Next-class hero.
  final nextCommon = await saveCommon(
    WidgetKeys.nextClass,
    emptyText: l10n.widgetNoClasses,
  );
  await widgetSaveJson('${WidgetKeys.nextClass}.${WidgetKeys.timedData}', timed);
  await updateIfChanged(WidgetKeys.nextClass, WidgetReceivers.nextClass, {
    ...nextCommon,
    WidgetKeys.timedData: timed,
  });

  // Today agenda (+ 7-day rail). selectedDay is pushed as 0 every refresh:
  // native day taps hold until the next push resets to today. Always
  // updated (see updateIfChanged): the reset contract must hold.
  final agendaCommon = await saveCommon(
    WidgetKeys.todayAgenda,
    emptyText: l10n.widgetNoClasses,
  );
  await widgetSave('${WidgetKeys.todayAgenda}.${WidgetKeys.selectedDay}', 0);
  await widgetSaveJson('${WidgetKeys.todayAgenda}.${WidgetKeys.week}', week);
  for (var i = 0; i < 7; i++) {
    await widgetSaveJson('${WidgetKeys.todayAgenda}.day$i', agendaDays[i]);
  }
  await updateIfChanged(WidgetKeys.todayAgenda, WidgetReceivers.todayAgenda, {
    ...agendaCommon,
    WidgetKeys.selectedDay: 0,
    WidgetKeys.week: week,
    for (var i = 0; i < 7; i++) 'day$i': agendaDays[i],
  }, always: true);

  // Due-tasks checklist.
  final tasksCommon = await saveCommon(
    WidgetKeys.dueTasks,
    emptyText: l10n.widgetAllCaughtUp,
  );
  await widgetSave(
    '${WidgetKeys.dueTasks}.${WidgetKeys.headerTitle}',
    l10n.widgetDueTasks,
  );
  await widgetSave('${WidgetKeys.dueTasks}.${WidgetKeys.tasksCount}', tasksCount);
  await widgetSaveJson('${WidgetKeys.dueTasks}.${WidgetKeys.tasks}', taskRows);
  await updateIfChanged(WidgetKeys.dueTasks, WidgetReceivers.dueTasks, {
    ...tasksCommon,
    WidgetKeys.headerTitle: l10n.widgetDueTasks,
    WidgetKeys.tasksCount: tasksCount,
    WidgetKeys.tasks: taskRows,
  });

  // Hub dashboard.
  final hubTasksTitle = '${l10n.widgetDueTasks} · $tasksCount';
  final hubCommon = await saveCommon(
    WidgetKeys.hub,
    emptyText: l10n.widgetNoClasses,
  );
  await widgetSave('${WidgetKeys.hub}.${WidgetKeys.tabClass}', tabClass);
  await widgetSave('${WidgetKeys.hub}.${WidgetKeys.tabAgenda}', tabAgenda);
  await widgetSave('${WidgetKeys.hub}.${WidgetKeys.tabTasks}', tabTasks);
  await widgetSave('${WidgetKeys.hub}.${WidgetKeys.tabMenu}', tabMenu);
  await widgetSaveJson('${WidgetKeys.hub}.${WidgetKeys.timedData}', timed);
  await widgetSaveJson('${WidgetKeys.hub}.${WidgetKeys.agendaRows}', agendaDays[0]);
  await widgetSaveJson('${WidgetKeys.hub}.${WidgetKeys.tasksRows}', taskRows);
  await widgetSave('${WidgetKeys.hub}.${WidgetKeys.tasksTitle}', hubTasksTitle);
  await widgetSave('${WidgetKeys.hub}.${WidgetKeys.menuTitle}', hubMenuTitle);
  await widgetSaveJson('${WidgetKeys.hub}.${WidgetKeys.menuRows}', hubMenu);
  await widgetSaveJson('${WidgetKeys.hub}.${WidgetKeys.menuMeals}', menuMeals);
  await widgetSave(
    '${WidgetKeys.hub}.${WidgetKeys.menuMealDefault}',
    menuMealDefault,
  );
  await widgetSave(
    '${WidgetKeys.hub}.${WidgetKeys.titleClass}',
    l10n.widgetNextClass,
  );
  await widgetSave(
    '${WidgetKeys.hub}.${WidgetKeys.titleAgenda}',
    l10n.widgetToday,
  );
  await widgetSave('${WidgetKeys.hub}.${WidgetKeys.emptyTasks}', l10n.widgetAllCaughtUp);
  await widgetSave('${WidgetKeys.hub}.${WidgetKeys.emptyMenu}', l10n.widgetNoMenuToday);
  await updateIfChanged(WidgetKeys.hub, WidgetReceivers.hub, {
    ...hubCommon,
    WidgetKeys.tabClass: tabClass,
    WidgetKeys.tabAgenda: tabAgenda,
    WidgetKeys.tabTasks: tabTasks,
    WidgetKeys.tabMenu: tabMenu,
    WidgetKeys.timedData: timed,
    WidgetKeys.agendaRows: agendaDays[0],
    WidgetKeys.tasksRows: taskRows,
    WidgetKeys.tasksTitle: hubTasksTitle,
    WidgetKeys.menuTitle: hubMenuTitle,
    WidgetKeys.menuRows: hubMenu,
    WidgetKeys.menuMeals: menuMeals,
    WidgetKeys.menuMealDefault: menuMealDefault,
    WidgetKeys.titleClass: l10n.widgetNextClass,
    WidgetKeys.titleAgenda: l10n.widgetToday,
    WidgetKeys.emptyTasks: l10n.widgetAllCaughtUp,
    WidgetKeys.emptyMenu: l10n.widgetNoMenuToday,
  });

  // Standalone cafeteria-menu widget: every servable meal plus the
  // menu-page default index; the native side keeps the user's picked meal
  // and falls back to the default when it is unset or no longer servable.
  final menuCommon = await saveCommon(
    WidgetKeys.cafeteriaMenu,
    emptyText: l10n.widgetNoMenuToday,
  );
  await widgetSave(
    '${WidgetKeys.cafeteriaMenu}.${WidgetKeys.menuTitle}',
    hubMenuTitle,
  );
  await widgetSaveJson(
    '${WidgetKeys.cafeteriaMenu}.${WidgetKeys.menuRows}',
    hubMenu,
  );
  await widgetSaveJson(
    '${WidgetKeys.cafeteriaMenu}.${WidgetKeys.menuMeals}',
    menuMeals,
  );
  await widgetSave(
    '${WidgetKeys.cafeteriaMenu}.${WidgetKeys.menuMealDefault}',
    menuMealDefault,
  );
  await updateIfChanged(WidgetKeys.cafeteriaMenu, WidgetReceivers.menu, {
    ...menuCommon,
    WidgetKeys.menuTitle: hubMenuTitle,
    WidgetKeys.menuRows: hubMenu,
    WidgetKeys.menuMeals: menuMeals,
    WidgetKeys.menuMealDefault: menuMealDefault,
  });

  // Standalone weekly-calendar widget: the 7-day rail plus one class list
  // per day (same shapes as TodayAgenda's `week` / `dayN`).
  final weeklyCommon = await saveCommon(
    WidgetKeys.weeklyCalendar,
    emptyText: l10n.widgetNoClasses,
  );
  await widgetSaveJson(
    '${WidgetKeys.weeklyCalendar}.${WidgetKeys.week}',
    week,
  );
  for (var i = 0; i < 7; i++) {
    await widgetSaveJson('${WidgetKeys.weeklyCalendar}.day$i', agendaDays[i]);
  }
  await updateIfChanged(WidgetKeys.weeklyCalendar, WidgetReceivers.weekly, {
    ...weeklyCommon,
    WidgetKeys.week: week,
    for (var i = 0; i < 7; i++) 'day$i': agendaDays[i],
  });

  // NOTE: no updateWidgetPreview here on purpose. Preview renders run a
  // full Glance composition on the main thread per widget; fired back to
  // back with the six updates on every push (startup, every save), they
  // stall the method channel for tens of seconds and ANR the app
  // (seen on-device). The launcher gallery keeps its own cadence.
  // Timed entry switchover + closing sentinel drive the hero; hourly ticks
  // and midnight keep the countdown widgets fresh between pushes.
  await scheduleWidgetTimelines(
    boundaries: [
      for (final k in timed.keys) DateTime.fromMillisecondsSinceEpoch(int.parse(k)),
    ],
  );
}
