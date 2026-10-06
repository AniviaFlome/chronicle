import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app.dart';
import '../domain/grades.dart';
import '../domain/schedule_models.dart' as engine;
import '../providers.dart';
import '../src/home_widget/due_tasks_compact.home_widget.dart';
import '../src/home_widget/next_class.home_widget.dart';
import '../src/home_widget/today_agenda.home_widget.dart';
import '../utils/time_format.dart';
import '../utils/ui_feedback.dart';

/// Pushes schedule/task snapshots to the Android home widgets.
///
/// Best-effort only: the widgets also re-render on their own from stored
/// prefs (Glance `updatePeriodMillis`) and the next-class widget fires
/// exact timed updates per class start, so a failed push here never leaves
/// a permanently stale widget. No-op off Android (incl. tests on other
/// platforms); plugin errors are swallowed.
Future<void> refreshHomeWidgets(ProviderContainer container) async {
  if (defaultTargetPlatform != TargetPlatform.android) return;
  try {
    await _push(container);
  } catch (e) {
    logLoadFailure('Home widget refresh', e);
  }
}

Future<void> _push(ProviderContainer container) async {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final tomorrow = shiftDays(today, 1);
  final locale = await container.read(appLocaleProvider.future) ?? 'en';

  // App-theme colors for the widgets: resolve the same ColorScheme the
  // app itself uses (theme id + accent + effective brightness) and push
  // the ARGB ints; native code falls back to system Glance colors when 0.
  final themeId = await container.read(appThemeProvider.future);
  final mode = container.read(themeModeProvider);
  final brightness = switch (mode) {
    ThemeMode.light => Brightness.light,
    ThemeMode.dark => Brightness.dark,
    _ => SchedulerBinding.instance.platformDispatcher.platformBrightness,
  };
  // Widget theme as a small code in themeBg (familyIndex * 2 + darkBit):
  // 0 default, 1 catppuccin, 2 nord, 3 dracula, 4 gruvbox, 5 tokyo-night.
  // Native maps it to hardcoded ColorProvider(day/night) triples; plain
  // ARGB ints crashed the render (proven by on-device bisect), so the
  // code table is the crash-safe path. themeFg/themeAccent stay 0
  // (native ignores them for now).
  final themeCode =
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
  final themeBg = themeCode;
  final themeFg = 0;
  final themeAccent = 0;

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

  // Next class: remaining classes today plus the next 7 days, so the
  // widget shows the next real class instead of going blank. Classes
  // past tomorrow get a weekday prefix ("Tue 08:40–09:30"). Each entry
  // is keyed at the time it should appear: the previous class's end
  // (start of today for the first), because the native side shows the
  // entry with the greatest key at or before now — keying at class
  // start would blank the widget before the first class. A trailing
  // "—" entry keyed at the last class end clears it afterwards.
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
  // "Then ..." line for the entry at index i names class i+1
  // ("Then Physics · 10:20"); empty for the last class and the sentinel.
  String nameWhen(engine.ClassOccurrence o) {
    final name = byId[o.classId]?.name ?? '—';
    final when =
        '${shortWeekdayName(o.date.weekday, locale)} ${hhmmLocale(o.startMinutes, locale)}';
    return locale.startsWith('tr')
        ? 'Sonra $name · $when'
        : 'Then $name · $when';
  }

  String thenFor(int i) {
    if (i + 1 >= listed.length) return '';
    return nameWhen(listed[i + 1]);
  }

  String detailFor(engine.ClassOccurrence o) {
    final room = o.room ?? byId[o.classId]?.room;
    final range = rangeFor(o);
    final base = room != null && room.isNotEmpty ? '$range · $room' : range;
    // Countdown folded into the detail line (C6 design: "· in 47 min").
    // Only for today's classes — future entries already carry a weekday
    // prefix, and a day-count here would go stale between pushes.
    String count = '';
    if (o.date == today) {
      if (o.startMinutes > nowMinutes) {
        final mins = o.startMinutes - nowMinutes;
        final when = mins < 120 ? 'in $mins min' : 'in ${mins ~/ 60} h';
        count = locale.startsWith('tr')
            ? '${mins < 120 ? '$mins dk' : '${mins ~/ 60} sa'} içinde'
            : when;
      } else {
        // Mid-class: say so explicitly instead of a bare end time.
        final ends = hhmmLocale(o.endMinutes, locale);
        count = locale.startsWith('tr')
            ? 'Şu an · bitiş $ends'
            : 'Currently · ends $ends';
      }
    }
    return count.isEmpty ? base : '$base · $count';
  }

  final firstIsToday = listed.isNotEmpty && listed[0].date == today;
  final timed = <DateTime, NextClassTimedData>{
    // Nothing today: say so instead of showing tomorrow's class as if
    // it were happening now; tomorrow rides in the Then-line instead.
    if (!firstIsToday && listed.isNotEmpty)
      today: NextClassTimedData(
        className: locale.startsWith('tr')
            ? 'Bugün ders yok'
            : 'No classes today',
        detailLine: '',
        thenLine: nameWhen(listed[0]),
      ),
    for (var i = 0; i < listed.length; i++)
      (i == 0 ? (firstIsToday ? today : listed[i].start) : listed[i - 1].end):
          NextClassTimedData(
        className: byId[listed[i].classId]?.name ?? '—',
        detailLine: detailFor(listed[i]),
        thenLine: thenFor(i),
      ),
    if (listed.isNotEmpty)
      listed.last.end: NextClassTimedData(
        className: '—',
        detailLine: '',
        thenLine: '',
      ),
  };
  await NextClassHomeWidget.saveData(
    timedData: timed,
    themeBg: themeBg,
    themeFg: themeFg,
    themeAccent: themeAccent,
  );

  // Agenda: one class list per day of the week ahead (the widget shows
  // the selected rail day's rows, defaulting to today), plus the 7-day
  // rail marking today. Row gaps come from the schema row spacing.
  List<({String time, String name})> dayRows(int i) => [
    for (final o in occs.where((o) => o.date == shiftDays(today, i)).take(4))
      (
        time: hhmmLocale(o.startMinutes, locale),
        name: byId[o.classId]?.name ?? '—',
      ),
  ];
  final week = [
    for (var i = 0; i < 7; i++)
      TodayAgendaWeekItem(
        label: shortWeekdayName(shiftDays(today, i).weekday, locale),
      ),
  ];
  await TodayAgendaHomeWidget.saveData(
    week: week,
    selectedDay: 0,
    day0: [for (final r in dayRows(0)) TodayAgendaDay0Item(time: r.time, name: r.name)],
    day1: [for (final r in dayRows(1)) TodayAgendaDay1Item(time: r.time, name: r.name)],
    day2: [for (final r in dayRows(2)) TodayAgendaDay2Item(time: r.time, name: r.name)],
    day3: [for (final r in dayRows(3)) TodayAgendaDay3Item(time: r.time, name: r.name)],
    day4: [for (final r in dayRows(4)) TodayAgendaDay4Item(time: r.time, name: r.name)],
    day5: [for (final r in dayRows(5)) TodayAgendaDay5Item(time: r.time, name: r.name)],
    day6: [for (final r in dayRows(6)) TodayAgendaDay6Item(time: r.time, name: r.name)],
    themeBg: themeBg,
    themeFg: themeFg,
    themeAccent: themeAccent,
  );

  // Due tasks: open tasks with a due date, overdue first, capped at 8.
  // Rows are (title, date) pairs; the title carries a "☐ " checkbox glyph
  // prefix and the date a leading " · " gap. Overdue keeps the `! ` marker
  // after the box. The progress line shows "N of M done" plus a block-char
  // bar (Glance exposes no progress indicator); counts cover dated tasks.
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
  final rows = <({String title, String date})>[];
  for (final t in dated.take(8)) {
    final due = t.task.dueMinutes == null
        ? t.task.dueDate!
        : '${t.task.dueDate} ${hhmm(t.task.dueMinutes!)}';
    final late = daysUntil(t.task.dueDate!, now) < 0 ? '! ' : '';
    rows.add((title: '☐ $late${t.task.title}', date: ' · $due'));
  }
  final headerLine = locale.startsWith('tr')
      ? 'Yaklaşan Görevler · ${rows.length}'
      : 'Due tasks · ${rows.length}';
  // Compact due-tasks (2x2): same header, top 3 rows in the same format.
  final compact = [
    for (final r in rows.take(3))
      DueTasksCompactTasksItem(title: r.title, date: r.date),
  ];
  await DueTasksCompactHomeWidget.saveData(
    headerLine: headerLine,
    tasks: compact,
    themeBg: themeBg,
    themeFg: themeFg,
    themeAccent: themeAccent,
  );
  // Update all three only after every snapshot is saved, so a theme
  // change re-renders every widget from the same push instead of one
  // widget at a time (which read as parts lagging behind in the picker).
  await NextClassHomeWidget.updateWidget();
  await TodayAgendaHomeWidget.updateWidget();
  await DueTasksCompactHomeWidget.updateWidget();
}
