import 'dart:io';
import 'dart:math';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database.dart';
import '../data/schedule_repository.dart';
import '../domain/schedule_models.dart' as engine;
import '../providers.dart';
import '../theme.dart';
import '../l10n/l10n.dart';
import '../utils/time_format.dart';
import 'occurrence_sheet.dart';
import 'occurrence_tile.dart';
import 'xtra_dialog.dart';

const _dayColumnWidth = 170.0;
const _dayColumnWidthCompact = 150.0;
const _gridDayWidth = 150.0;
const _gridDayWidthCompact = 132.0;
const _hourHeight = 64.0;
const _gutterWidth = 52.0;

/// Week view: seven day columns with the week's class meetings,
/// either as stacked lists or as a time grid.
class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  late DateTime _focused;
  String _view = 'list';
  final _listCtrl = ScrollController();
  final _gridCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _focused = DateTime(now.year, now.month, now.day);
    // Synchronous: preloaded in main(), so the saved view renders on the
    // first frame with no list→grid flash.
    _view = ref.read(initialCalendarViewProvider);
  }

  @override
  void dispose() {
    _listCtrl.dispose();
    _gridCtrl.dispose();
    super.dispose();
  }

  DateTime _weekStart(int weekStartDay) {
    final diff = (_focused.weekday - weekStartDay) % 7;
    // Wall-clock step: Duration subtraction drifts across DST transitions,
    // breaking day-bucket equality for the whole week.
    final s = shiftDays(_focused, -diff);
    return DateTime(s.year, s.month, s.day);
  }

  void _setView(String view) async {
    setState(() => _view = view);
    ref.read(initialCalendarViewProvider.notifier).set(view);
    try {
      await ref.read(settingsRepositoryProvider).setCalendarView(view);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.couldNotSave('$e'))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final weekStartDay = ref.watch(weekStartDayProvider).value ?? 1;
    final start = _weekStart(weekStartDay);
    final end = shiftDays(start, 6);
    final theme = Theme.of(context);

    // Narrow phones show slimmer day columns. The today auto-scroll below
    // is Android-only: desktop windows keep the full week in view.
    final compactDays =
        Platform.isAndroid && MediaQuery.of(context).size.width < 600;
    final listDayWidth =
        compactDays ? _dayColumnWidthCompact : _dayColumnWidth;
    final gridDayWidth =
        compactDays ? _gridDayWidthCompact : _gridDayWidth;
    final now = DateTime.now();
    final todayMidnight = DateTime(now.year, now.month, now.day);

    final occurrences = ref.watch(occurrencesProvider((start, end)));
    final classes = ref.watch(classesByIdProvider);
    final absenceKeys = _absenceKeys(ref);
    final rotationLabel = _rotationLabeler(ref);
    final xtra = ref.watch(
      xtraRangeProvider((isoFromDateTime(start), isoFromDateTime(end))),
    );

    // On Android phones the week strip is wider than the screen; the body
    // jumps to today's column once laid out (see _WeekBodyState).

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${isoFromDateTime(start)} – ${isoFromDateTime(end)}',
          style: theme.textTheme.titleMedium,
        ),
        actions: [
          IconButton(
            tooltip: context.l10n.addEvent,
            icon: const Icon(Icons.add),
            onPressed: () =>
                showXtraDialog(context, ref, initialDate: _focused),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: Row(
              children: [
                IconButton(
                  tooltip: context.l10n.prevWeek,
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () =>
                      setState(() => _focused = shiftDays(_focused, -7)),
                ),
                TextButton(
                  onPressed: () {
                    final now = DateTime.now();
                    setState(
                      () => _focused = DateTime(now.year, now.month, now.day),
                    );
                  },
                  child: Text(context.l10n.navToday),
                ),
                IconButton(
                  tooltip: context.l10n.nextWeek,
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () =>
                      setState(() => _focused = shiftDays(_focused, 7)),
                ),
                const Spacer(),
                SegmentedButton<String>(
                  style: const ButtonStyle(
                    visualDensity: VisualDensity.compact,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  segments: [
                    ButtonSegment(
                      value: 'list',
                      icon: const Icon(Icons.view_agenda_outlined, size: 20),
                      tooltip: context.l10n.listViewTooltip,
                    ),
                    ButtonSegment(
                      value: 'grid',
                      icon: const Icon(
                        Icons.calendar_view_week_outlined,
                        size: 20,
                      ),
                      tooltip: context.l10n.timeGridTooltip,
                    ),
                  ],
                  selected: {_view},
                  showSelectedIcon: false,
                  onSelectionChanged: (s) => _setView(s.single),
                ),
              ],
            ),
          ),
          Expanded(
            child: occurrences.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) =>
                Center(child: Text(context.l10n.couldNotLoadWeek('$e'))),
              data: (list) {
                return xtra.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) =>
                      Center(child: Text(context.l10n.couldNotLoadEvents('$e'))),
                  data: (xtraList) {
                    return _WeekBody(
                      start: start,
                      end: end,
                      list: list,
                      xtraList: xtraList,
                      classes: classes,
                      absenceKeys: absenceKeys,
                      rotationLabel: rotationLabel,
                      view: _view,
                      listCtrl: _listCtrl,
                      gridCtrl: _gridCtrl,
                      listDayWidth: listDayWidth,
                      gridDayWidth: gridDayWidth,
                      autoScrollToday: compactDays,
                      todayMidnight: todayMidnight,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Set<String> _absenceKeys(WidgetRef ref) {
    final absences = ref.watch(allAbsencesStreamProvider).value ?? const [];
    return {for (final a in absences) '${a.classId}|${a.date}'};
  }

  /// Returns the rotation day label for a date, or null when the active
  /// year has no day rotation configured.
  String? Function(DateTime) _rotationLabeler(WidgetRef ref) {
    final year = ref.watch(activeYearProvider).value;
    if (year == null) return (_) => null;
    final config = dayRotationFromYear(year);
    if (config == null) return (_) => null;
    final letters = year.rotationLabels == 'letters';
    final rows = ref.watch(holidaysStreamProvider).value ?? const [];
    final holidays = <DateTime>{};
    for (final h in rows) {
      final s = DateTime.tryParse(h.startDate);
      final e = DateTime.tryParse(h.endDate);
      if (s == null || e == null) continue;
      var d = DateTime(s.year, s.month, s.day);
      final last = DateTime(e.year, e.month, e.day);
      while (!d.isAfter(last)) {
        holidays.add(d);
        d = shiftDays(d, 1);
      }
    }
    return (date) => engine.rotationDayLabel(
      engine.rotationDayIndex(date: date, config: config, holidays: holidays),
      letters: letters,
    );
  }
}

class _DayColumn extends ConsumerWidget {
  final DateTime date;
  final bool isToday;
  final List<engine.ClassOccurrence> occurrences;
  final Map<int, ClassesData> classesById;
  final Set<String> absenceKeys;
  final String? rotationLabel;
  final List<XtraEvent> xtra;
  final double dayWidth;

  const _DayColumn({
    required this.date,
    required this.isToday,
    required this.occurrences,
    required this.classesById,
    required this.absenceKeys,
    required this.rotationLabel,
    required this.xtra,
    this.dayWidth = _dayColumnWidth,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final allDay = [
      for (final x in xtra)
        if (x.startMinutes == null) x,
    ];
    final timed = [
      for (final x in xtra)
        if (x.startMinutes != null) x,
    ];
    return Container(
      width: dayWidth,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _DayHeader(
            date: date,
            isToday: isToday,
            rotationLabel: rotationLabel,
          ),
          const SizedBox(height: 8),
          for (final x in allDay)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: _AllDayChip(
                event: x,
                onTap: () => showXtraDialog(context, ref, existing: x),
              ),
            ),
          if (occurrences.isEmpty && timed.isEmpty && allDay.isEmpty)
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                '—',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
            )
          else ...[
            for (final occ in occurrences)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: OccurrenceTile(
                  occurrence: occ,
                  classRow: classesById[occ.classId],
                  absent: absenceKeys.contains(
                    '${occ.classId}|${isoFromDateTime(occ.date)}',
                  ),
                  onTap: () => showOccurrenceSheet(context, occ),
                ),
              ),
            for (final x in timed)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: XtraTile(
                  event: x,
                  onTap: () => showXtraDialog(context, ref, existing: x),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _AllDayChip extends StatelessWidget {
  final XtraEvent event;
  final VoidCallback onTap;

  const _AllDayChip({required this.event, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = classBlockColor(theme.colorScheme, Color(event.colorValue));
    final fg = classOnBlockColor(theme.colorScheme, bg);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: bg,
          border: Border.all(
            color: classAccentColor(
              theme.colorScheme,
              Color(event.colorValue),
            ).withValues(alpha: 0.6),
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          event.title,
          style: theme.textTheme.labelMedium?.copyWith(color: fg),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

class _DayHeader extends StatelessWidget {
  final DateTime date;
  final bool isToday;
  final String? rotationLabel;

  const _DayHeader({
    required this.date,
    required this.isToday,
    this.rotationLabel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final labelColor = isToday
        ? theme.colorScheme.onPrimaryContainer
        : theme.colorScheme.outline;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: isToday
            ? theme.colorScheme.primaryContainer
            : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(
            shortWeekdayName(date.weekday, context.l10n.localeName),
            style: theme.textTheme.labelMedium?.copyWith(color: labelColor),
          ),
          Text(
            '${date.day}',
            style: theme.textTheme.titleLarge?.copyWith(
              color: isToday ? theme.colorScheme.onPrimaryContainer : null,
            ),
          ),
          if (rotationLabel != null)
            Text(
              rotationLabel!,
              style: theme.textTheme.labelSmall?.copyWith(color: labelColor),
            ),
        ],
      ),
    );
  }
}

/// Timetable grid: hour gutter plus one column per day, blocks positioned
/// by start time and sized by duration. Minute-precise: supports day starts
/// like 6:40. Draws a proper calendar base (faint hourly lines) plus
/// stronger period/marker lines and labeled break bands.
class _WeekGrid extends ConsumerWidget {
  final DateTime start;
  final Map<DateTime, List<engine.ClassOccurrence>> byDay;
  final Map<int, ClassesData> classesById;
  final Set<String> absenceKeys;
  final DateTime today;
  final String? Function(DateTime) rotationLabel;
  final Map<DateTime, List<XtraEvent>> xtraByDay;
  final double? viewportHeight;
  final ScrollController? controller;
  final double dayWidth;

  const _WeekGrid({
    required this.start,
    required this.byDay,
    required this.classesById,
    required this.absenceKeys,
    required this.today,
    required this.rotationLabel,
    required this.xtraByDay,
    required this.viewportHeight,
    this.controller,
    this.dayWidth = _gridDayWidth,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final all = byDay.values.expand((l) => l).toList();
    // Base range from settings in minutes (defaults 360-1320); classes or
    // fixed-grid boundaries outside it extend the range so nothing is cut off.
    final range =
        ref.watch(dayRangeProvider).value ?? (start: 360, end: 1320);
    final mode = ref.watch(gridMarkersModeProvider).value ?? 'class-times';
    final fixed =
        ref.watch(fixedGridProvider).value ??
        (boundaries: const <int>[], breaks: const <({int start, int end})>[]);
    final showFixed = mode == 'fixed' && fixed.boundaries.isNotEmpty;
    var rangeStart = range.start;
    var rangeEnd = range.end;
    if (all.isNotEmpty) {
      final minStart = all
          .map((o) => o.startMinutes)
          .reduce((a, b) => a < b ? a : b);
      final maxEnd = all
          .map((o) => o.endMinutes)
          .reduce((a, b) => a > b ? a : b);
      rangeStart = min(range.start, minStart - 30).clamp(0, 1439);
      rangeEnd = max(
        range.end,
        maxEnd + 30,
      ).clamp(rangeStart + 120, 1440);
    }
    // Fixed-grid boundaries extend the shown range so none are cut off.
    if (showFixed) {
      rangeStart = min(rangeStart, fixed.boundaries.first).clamp(
        0,
        rangeStart,
      );
      rangeEnd = max(rangeEnd, fixed.boundaries.last).clamp(
        rangeEnd,
        1440,
      );
      if (rangeEnd <= rangeStart) {
        rangeEnd = (rangeStart + 120).clamp(0, 1440);
      }
    }
    var hourHeight = _hourHeight;
    final viewport = viewportHeight;
    if (viewport != null) {
      // Header, spacing and padding above the time area.
      const chrome = 200.0;
      final spanHours = (rangeEnd - rangeStart) / 60.0;
      if (spanHours > 0) {
        final stretched = (viewport - chrome) / spanHours;
        if (stretched > hourHeight) hourHeight = stretched;
      }
    }
    final pxPerMin = hourHeight / 60;
    final totalHeight = (rangeEnd - rangeStart) * pxPerMin;
    final markers = _markers(
      all,
      rangeStart,
      rangeEnd,
      showFixed ? fixed.boundaries : const [],
    );
    final breaks = showFixed ? fixed.breaks : const <({int start, int end})>[];
    // Faint hourly base for a proper calendar feel, always drawn.
    final hourly = <int>[];
    for (var h = 0; h <= 24; h++) {
      final m = h * 60;
      if (m >= rangeStart && m <= rangeEnd) hourly.add(m);
    }
    // Ensure custom start/end edges are drawn even when off-hour.
    if (!hourly.contains(rangeStart)) hourly.add(rangeStart);
    if (!hourly.contains(rangeEnd)) hourly.add(rangeEnd);
    hourly.sort();

    return Scrollbar(
      thumbVisibility: true,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
        physics: const ClampingScrollPhysics(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _HourGutter(
            rangeStart: rangeStart,
            totalHeight: totalHeight,
            hourHeight: hourHeight,
            markers: markers,
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Scrollbar(
              controller: controller,
              thumbVisibility: true,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                controller: controller,
                physics: const ClampingScrollPhysics(),
                dragStartBehavior: DragStartBehavior.down,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var i = 0; i < 7; i++)
                    _GridDayColumn(
                      date: shiftDays(start, i),
                      isToday: shiftDays(start, i) == today,
                      occurrences: byDay[shiftDays(start, i)] ?? const [],
                      classesById: classesById,
                      absenceKeys: absenceKeys,
                      rangeStart: rangeStart,
                      rangeEnd: rangeEnd,
                      totalHeight: totalHeight,
                      hourHeight: hourHeight,
                      showNowLine: shiftDays(start, i) == today,
                      rotationLabel: rotationLabel(shiftDays(start, i)),
                      markers: markers,
                      hourly: hourly,
                      breaks: breaks,
                      xtra: xtraByDay[shiftDays(start, i)] ?? const [],
                      dayWidth: dayWidth,
                    ),
                ],
              ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          _HourGutter(
            rangeStart: rangeStart,
            totalHeight: totalHeight,
            hourHeight: hourHeight,
            markers: markers,
            mirror: true,
          ),
        ],
      ),
      ),
    );
  }

  /// Minute markers for gutter labels and gridlines: class times, or the
  /// fixed lesson/break boundaries when those are configured and selected.
  /// Falls back to hourly lines.
  List<int> _markers(
    List<engine.ClassOccurrence> all,
    int rangeStart,
    int rangeEnd,
    List<int> fixedBoundaries,
  ) {
    List<int> markers;
    if (fixedBoundaries.isNotEmpty) {
      markers = fixedBoundaries;
    } else {
      markers = {
        for (final o in all) ...[o.startMinutes, o.endMinutes],
      }.toList()..sort();
    }
    if (markers.isEmpty) {
      final firstHour = (rangeStart / 60).ceil();
      final lastHour = (rangeEnd / 60).floor();
      markers = [for (var h = firstHour; h <= lastHour; h++) h * 60];
      // Keep custom edges labeled when off-hour.
      if (!markers.contains(rangeStart)) markers.add(rangeStart);
      if (!markers.contains(rangeEnd)) markers.add(rangeEnd);
      markers.sort();
    }
    return [
      for (final m in markers)
        if (m >= rangeStart && m <= rangeEnd) m,
    ];
  }
}

class _HourGutter extends StatelessWidget {
  final int rangeStart;
  final double totalHeight;
  final double hourHeight;
  final List<int> markers;
  final bool mirror;

  const _HourGutter({
    required this.rangeStart,
    required this.totalHeight,
    required this.hourHeight,
    required this.markers,
    this.mirror = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Offset for the day header height so labels align with grid lines.
    const headerOffset = 78.0;
    return SizedBox(
      width: _gutterWidth,
      height: totalHeight + headerOffset,
      child: Stack(
        children: [
          for (final m in markers)
            Positioned(
              top: headerOffset + (m - rangeStart) * hourHeight / 60 - 8,
              left: mirror ? 4 : 0,
              right: mirror ? 0 : 4,
              child: Text(
                hhmm(m),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: mirror ? TextAlign.left : TextAlign.right,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _GridDayColumn extends ConsumerWidget {
  final DateTime date;
  final bool isToday;
  final List<engine.ClassOccurrence> occurrences;
  final Map<int, ClassesData> classesById;
  final Set<String> absenceKeys;
  final int rangeStart;
  final int rangeEnd;
  final double totalHeight;
  final double hourHeight;
  final bool showNowLine;
  final String? rotationLabel;
  final List<XtraEvent> xtra;
  final List<int> markers;
  final List<int> hourly;
  final List<({int start, int end})> breaks;
  final double dayWidth;

  const _GridDayColumn({
    required this.date,
    required this.isToday,
    required this.occurrences,
    required this.classesById,
    required this.absenceKeys,
    required this.rangeStart,
    required this.rangeEnd,
    required this.totalHeight,
    required this.hourHeight,
    required this.showNowLine,
    required this.rotationLabel,
    required this.xtra,
    required this.markers,
    required this.hourly,
    required this.breaks,
    this.dayWidth = _gridDayWidth,
  });

  double get _pxPerMin => hourHeight / 60;

  /// Shaded break bands (recess, lunch) between timetable periods,
  /// clamped to the visible range. Labeled when tall enough.
  List<Widget> _breakBoxes(ThemeData theme) {
    final boxes = <Widget>[];
    final lo = rangeStart;
    final hi = rangeEnd;
    for (final b in breaks) {
      final s = b.start.clamp(lo, hi);
      final e = b.end.clamp(lo, hi);
      if (e <= s) continue;
      final top = (s - lo) * _pxPerMin;
      final h = max(1.0, (e - s) * _pxPerMin);
      boxes.add(
        Positioned(
          key: ValueKey('break_${s}_$e'),
          top: top,
          height: h,
          left: 0,
          right: 0,
          child: Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.secondaryContainer.withValues(
                alpha: 0.45,
              ),
              border: Border.symmetric(
                horizontal: BorderSide(
                  color: theme.colorScheme.outline.withValues(alpha: 0.35),
                  width: 0.75,
                ),
              ),
            ),
            child: h >= 20
                ? Center(
                    child: Text(
                      '${hhmm(s)}–${hhmm(e)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSecondaryContainer.withValues(
                          alpha: 0.85,
                        ),
                        fontSize: 10,
                      ),
                    ),
                  )
                : null,
          ),
        ),
      );
    }
    return boxes;
  }

  /// Must stay in sync with _AdjustableBlock's height formula.
  double _blockHeight(int startMinutes, int endMinutes) =>
      ((endMinutes - startMinutes) * _pxPerMin - 2).clamp(22.0, totalHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final timedXtra = [
      for (final x in xtra)
        if (x.startMinutes != null) x,
    ];
    final allDay = [
      for (final x in xtra)
        if (x.startMinutes == null) x,
    ];
    final ranges = [
      for (final occ in occurrences) (occ.startMinutes, occ.endMinutes),
      for (final x in timedXtra)
        (x.startMinutes!, x.endMinutes ?? x.startMinutes! + 60),
    ];
    final lanes = _layoutRanges(ranges);
    final now = DateTime.now();
    final nowMinutes = now.hour * 60 + now.minute;
    final showNow =
        showNowLine && nowMinutes >= rangeStart && nowMinutes <= rangeEnd;

    Future<void> commitClassTime(
      engine.ClassOccurrence occ,
      int start,
      int end,
    ) async {
      try {
        await ref
            .read(classRepositoryProvider)
            .updateSlotTimes(occ.scheduleItemId, start, end);
        ref.invalidate(engineProvider);
        await ref.read(reminderSchedulerProvider).refreshClassReminders();
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(
              SnackBar(content: Text(context.l10n.couldNotMoveClass('$e'))));
        }
      }
    }

    Future<void> commitXtraTime(XtraEvent event, int start, int end) async {
      try {
        await ref
            .read(xtraRepositoryProvider)
            .updateXtraTimes(event.id, start, end);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(
              SnackBar(content: Text(context.l10n.couldNotMoveEvent('$e'))));
        }
      }
    }

    Widget draggableBlock({
      required int index,
      required String title,
      required int startMinutes,
      required int endMinutes,
      required Widget child,
      required Future<void> Function(int, int) onCommit,
    }) {
      final (lane, laneCount) = lanes[index];
      return _AdjustableBlock(
        title: title,
        startMinutes: startMinutes,
        endMinutes: endMinutes,
        pxPerMin: _pxPerMin,
        rangeStart: rangeStart,
        totalHeight: totalHeight,
        laneLeft: 2 + lane * (dayWidth - 8) / laneCount,
        laneWidth: (dayWidth - 8) / laneCount - 2,
        onCommit: onCommit,
        child: child,
      );
    }

    return Container(
      width: dayWidth,
      margin: const EdgeInsets.symmetric(horizontal: 3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _DayHeader(
            date: date,
            isToday: isToday,
            rotationLabel: rotationLabel,
          ),
          const SizedBox(height: 8),
          for (final x in allDay)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: _AllDayChip(
                event: x,
                onTap: () => showXtraDialog(context, ref, existing: x),
              ),
            ),
          Container(
            height: totalHeight,
            decoration: BoxDecoration(
              color: theme.colorScheme.surface.withValues(alpha: 0.4),
              border: Border.all(
                color: theme.dividerColor.withValues(alpha: 0.35),
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                // Faint hourly base — proper calendar background.
                for (final h in hourly)
                  Positioned(
                    top: (h - rangeStart) * _pxPerMin,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 1,
                      color: theme.dividerColor.withValues(
                        alpha: h % 60 == 0 ? 0.35 : 0.18,
                      ),
                    ),
                  ),
                // Stronger period/marker lines.
                for (final m in markers)
                  Positioned(
                    top: (m - rangeStart) * _pxPerMin,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 1,
                      color: theme.colorScheme.outline.withValues(alpha: 0.45),
                    ),
                  ),
                ..._breakBoxes(theme),
                if (showNow)
                  Positioned(
                    top: (nowMinutes - rangeStart) * _pxPerMin,
                    left: 0,
                    right: 0,
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.error,
                            shape: BoxShape.circle,
                          ),
                        ),
                        Expanded(
                          child: Container(
                            height: 2,
                            color: theme.colorScheme.error,
                          ),
                        ),
                      ],
                    ),
                  ),
                for (var i = 0; i < occurrences.length; i++)
                  draggableBlock(
                    index: i,
                    title: classesById[occurrences[i].classId]?.name ?? context.l10n.classFallback,
                    startMinutes: occurrences[i].startMinutes,
                    endMinutes: occurrences[i].endMinutes,
                    onCommit: (s, e) => commitClassTime(occurrences[i], s, e),
                    child: _GridBlock(
                      occurrence: occurrences[i],
                      classRow: classesById[occurrences[i].classId],
                      absent: absenceKeys.contains(
                        '${occurrences[i].classId}|${isoFromDateTime(occurrences[i].date)}',
                      ),
                      blockHeight: _blockHeight(
                        occurrences[i].startMinutes,
                        occurrences[i].endMinutes,
                      ),
                    ),
                  ),
                for (var j = 0; j < timedXtra.length; j++)
                  draggableBlock(
                    index: occurrences.length + j,
                    title: timedXtra[j].title,
                    startMinutes: timedXtra[j].startMinutes!,
                    endMinutes:
                        timedXtra[j].endMinutes ??
                        timedXtra[j].startMinutes! + 60,
                    onCommit: (s, e) => commitXtraTime(timedXtra[j], s, e),
                    child: _XtraGridBlock(
                      event: timedXtra[j],
                      onTap: () =>
                          showXtraDialog(context, ref, existing: timedXtra[j]),
                      blockHeight: _blockHeight(
                        timedXtra[j].startMinutes!,
                        timedXtra[j].endMinutes ??
                            timedXtra[j].startMinutes! + 60,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Assigns overlap lanes over (start, end) minute ranges.
  List<(int, int)> _layoutRanges(List<(int, int)> ranges) {
    final order = List.generate(ranges.length, (i) => i)
      ..sort((a, b) => ranges[a].$1.compareTo(ranges[b].$1));
    final lanes = List.filled(ranges.length, (0, 1));
    var cluster = <int>[];
    var clusterEnd = -1;

    void flush() {
      if (cluster.isEmpty) return;
      final laneEnds = <int>[];
      final assigned = <int>[];
      for (final i in cluster) {
        var lane = laneEnds.indexWhere((end) => end <= ranges[i].$1);
        if (lane < 0) {
          lane = laneEnds.length;
          laneEnds.add(ranges[i].$2);
        } else {
          laneEnds[lane] = ranges[i].$2;
        }
        assigned.add(lane);
      }
      for (var k = 0; k < cluster.length; k++) {
        lanes[cluster[k]] = (assigned[k], laneEnds.length);
      }
      cluster = [];
      clusterEnd = -1;
    }

    for (final i in order) {
      if (cluster.isNotEmpty && ranges[i].$1 >= clusterEnd) flush();
      cluster.add(i);
      if (ranges[i].$2 > clusterEnd) clusterEnd = ranges[i].$2;
    }
    flush();
    return lanes;
  }
}

class _XtraGridBlock extends StatelessWidget {
  final XtraEvent event;
  final VoidCallback onTap;
  final double blockHeight;

  const _XtraGridBlock({
    required this.event,
    required this.onTap,
    required this.blockHeight,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // blockHeight is the exact Positioned height; minus the 6px vertical
    // padding gives the room for text. Explicit line heights keep the math
    // deterministic: title 14.4px/line, subtitle 13.2px.
    final available = blockHeight - 6;
    final bg = classBlockColor(theme.colorScheme, Color(event.colorValue));
    final accent = classAccentColor(
      theme.colorScheme,
      Color(event.colorValue),
    );
    final fg = classOnBlockColor(theme.colorScheme, bg);
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
        decoration: BoxDecoration(
          color: bg,
          border: Border(left: BorderSide(color: accent, width: 3)),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              event.title,
              maxLines: available < 32 ? 1 : 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
                height: 1.2,
                color: fg,
              ),
            ),
            if (available >= 44)
              Text(
                hhmm(event.startMinutes ?? 0),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: fg.withValues(alpha: 0.75),
                  height: 1.2,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _GridBlock extends StatelessWidget {
  final engine.ClassOccurrence occurrence;
  final ClassesData? classRow;
  final bool absent;
  final double blockHeight;

  const _GridBlock({
    required this.occurrence,
    required this.classRow,
    required this.absent,
    required this.blockHeight,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final raw = classRow == null
        ? theme.colorScheme.primary
        : Color(classRow!.colorValue);
    final bg = classBlockColor(theme.colorScheme, raw);
    final accent = classAccentColor(theme.colorScheme, raw);
    final fg = classOnBlockColor(theme.colorScheme, bg);
    final room = occurrence.room ?? classRow?.room;
    // blockHeight is the exact Positioned height; minus the 6px vertical
    // padding gives the room for text. Explicit line heights keep the math
    // deterministic: title 14.4px/line, subtitle 13.2px.
    final available = blockHeight - 6;

    return InkWell(
      onTap: () => showOccurrenceSheet(context, occurrence),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
        decoration: BoxDecoration(
          color: bg,
          border: Border(
            left: BorderSide(
              color: absent ? theme.colorScheme.error : accent,
              width: 3,
            ),
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              absent
                  ? '${classRow?.name ?? context.l10n.classFallback} · ${context.l10n.absentBadge}'
                  : (classRow?.name ?? context.l10n.classFallback),
              maxLines: available < 32 ? 1 : 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
                height: 1.2,
                color: fg,
              ),
            ),
            if (available >= 44)
              Text(
                '${hhmm(occurrence.startMinutes)}–${hhmm(occurrence.endMinutes)}'
                '${room != null && room.isNotEmpty ? ' · $room' : ''}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: fg.withValues(alpha: 0.75),
                  height: 1.2,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Week content shared by list and grid views: groups occurrences and
/// Xtra events per day. Jumps the horizontal strip to today once per week
/// when [autoScrollToday] is set (Android phones), post-layout so the
/// scroll view always exists when the jump runs.
class _WeekBody extends StatefulWidget {
  final DateTime start;
  final DateTime end;
  final List<engine.ClassOccurrence> list;
  final List<XtraEvent> xtraList;
  final AsyncValue<Map<int, ClassesData>> classes;
  final Set<String> absenceKeys;
  final String? Function(DateTime) rotationLabel;
  final String view;
  final ScrollController? listCtrl;
  final ScrollController? gridCtrl;
  final double listDayWidth;
  final double gridDayWidth;
  final bool autoScrollToday;
  final DateTime? todayMidnight;

  const _WeekBody({
    required this.start,
    required this.end,
    required this.list,
    required this.xtraList,
    required this.classes,
    required this.absenceKeys,
    required this.rotationLabel,
    required this.view,
    this.listCtrl,
    this.gridCtrl,
    this.listDayWidth = _dayColumnWidth,
    this.gridDayWidth = _gridDayWidth,
    this.autoScrollToday = false,
    this.todayMidnight,
  });

  @override
  State<_WeekBody> createState() => _WeekBodyState();
}

class _WeekBodyState extends State<_WeekBody> {
  String? _jumpedFor;

  /// Day width that fits all 7 columns into [available] when possible,
  /// shrinking from [preferred] down to [min] before scrolling is needed.
  double _fitWidth(double available, double preferred, double min) =>
      ((available / 7).clamp(min, preferred)).toDouble();

  @override
  Widget build(BuildContext context) {
    final byId = widget.classes.value ?? const <int, ClassesData>{};
    final byDay = <DateTime, List<engine.ClassOccurrence>>{};
    final xtraByDay = <DateTime, List<XtraEvent>>{};
    for (var i = 0; i < 7; i++) {
      final day = shiftDays(widget.start, i);
      byDay[day] = [];
      xtraByDay[day] = [];
    }
    for (final occ in widget.list) {
      byDay.putIfAbsent(occ.date, () => []).add(occ);
    }
    for (final x in widget.xtraList) {
      final date = DateTime.tryParse(x.date);
      if (date == null) continue;
      final day = DateTime(date.year, date.month, date.day);
      xtraByDay.putIfAbsent(day, () => []).add(x);
    }
    final today = DateTime.now();
    final todayMidnight =
        widget.todayMidnight ??
        DateTime(today.year, today.month, today.day);

    void maybeJump(double listStride, double gridStride) {
      if (!widget.autoScrollToday) return;
      final key = '${widget.view}_${isoFromDateTime(widget.start)}';
      if (_jumpedFor == key) return;
      _jumpedFor = key;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final ctrl = widget.view == 'grid' ? widget.gridCtrl : widget.listCtrl;
        if (ctrl == null || !ctrl.hasClients) {
          // Not laid out yet (e.g. view just switched): retry on the
          // next build instead of dropping the jump silently.
          _jumpedFor = null;
          return;
        }
        final idx = daysBetween(widget.start, todayMidnight).clamp(0, 6);
        final stride = widget.view == 'grid' ? gridStride : listStride;
        ctrl.jumpTo(min(idx * stride, ctrl.position.maxScrollExtent));
      });
    }

    if (widget.view == 'grid') {
      return LayoutBuilder(
        builder: (context, constraints) {
          // Gutters, spacing, padding and the 3px side margins around
          // every day column.
          final avail = constraints.maxWidth - 24 - 104 - 8 - 42;
          final dayWidth = _fitWidth(avail, widget.gridDayWidth, 100);
          maybeJump(0, dayWidth + 6);
          return _WeekGrid(
            start: widget.start,
            byDay: byDay,
            classesById: byId,
            absenceKeys: widget.absenceKeys,
            today: todayMidnight,
            rotationLabel: widget.rotationLabel,
            xtraByDay: xtraByDay,
            viewportHeight: constraints.maxHeight.isFinite
                ? constraints.maxHeight
                : null,
            controller: widget.gridCtrl,
            dayWidth: dayWidth,
          );
        },
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        // Horizontal padding plus the 4px side margins of every column.
        final dayWidth = _fitWidth(
          constraints.maxWidth - 24 - 56,
          widget.listDayWidth,
          110,
        );
        maybeJump(dayWidth + 8, 0);
        return Scrollbar(
          controller: widget.listCtrl,
          thumbVisibility: true,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            controller: widget.listCtrl,
            physics: const ClampingScrollPhysics(),
            dragStartBehavior: DragStartBehavior.down,
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < 7; i++)
                  _DayColumn(
                    date: shiftDays(widget.start, i),
                    isToday: shiftDays(widget.start, i) == todayMidnight,
                    occurrences:
                        byDay[shiftDays(widget.start, i)] ?? const [],
                    classesById: byId,
                    absenceKeys: widget.absenceKeys,
                    rotationLabel: widget.rotationLabel(
                      shiftDays(widget.start, i),
                    ),
                    xtra: xtraByDay[shiftDays(widget.start, i)] ?? const [],
                    dayWidth: dayWidth,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

int _snap5(int minutes) => (minutes / 5).round() * 5;

/// A grid block positioned by time. Long-press opens the adjust sheet
/// (proven deliverable in widget tests, unlike raw drag gestures inside
/// nested scrollables); tap behavior comes from the child itself.
class _AdjustableBlock extends StatelessWidget {
  final String title;
  final int startMinutes;
  final int endMinutes;
  final double pxPerMin;
  final int rangeStart;
  final double totalHeight;
  final double laneLeft;
  final double laneWidth;
  final Widget child;
  final Future<void> Function(int newStart, int newEnd) onCommit;

  const _AdjustableBlock({
    required this.title,
    required this.startMinutes,
    required this.endMinutes,
    required this.pxPerMin,
    required this.rangeStart,
    required this.totalHeight,
    required this.laneLeft,
    required this.laneWidth,
    required this.child,
    required this.onCommit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final top = (startMinutes - rangeStart) * pxPerMin + 1;
    final height = ((endMinutes - startMinutes) * pxPerMin - 2).clamp(
      22.0,
      totalHeight,
    );
    return Positioned(
      top: top,
      height: height,
      left: laneLeft,
      width: laneWidth,
      child: GestureDetector(
        onLongPress: () async {
          final result = await showModalBottomSheet<({int start, int end})>(
            context: context,
            showDragHandle: true,
            builder: (_) => _AdjustTimeSheet(
              title: title,
              startMinutes: startMinutes,
              endMinutes: endMinutes,
            ),
          );
          if (result != null &&
              (result.start != startMinutes || result.end != endMinutes)) {
            await onCommit(result.start, result.end);
          }
        },
        child: Stack(
          children: [
            Positioned.fill(child: child),
            if (height >= 44)
              Positioned(
                top: 2,
                right: 4,
                child: Icon(
                  Icons.edit_outlined,
                  size: 14,
                  color: theme.colorScheme.outline.withValues(alpha: 0.7),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Precise time adjuster for a grid block: 5- and 30-minute steppers.
class _AdjustTimeSheet extends StatefulWidget {
  final String title;
  final int startMinutes;
  final int endMinutes;

  const _AdjustTimeSheet({
    required this.title,
    required this.startMinutes,
    required this.endMinutes,
  });

  @override
  State<_AdjustTimeSheet> createState() => _AdjustTimeSheetState();
}

class _AdjustTimeSheetState extends State<_AdjustTimeSheet> {
  late int _start;
  late int _end;

  @override
  void initState() {
    super.initState();
    _start = widget.startMinutes;
    _end = widget.endMinutes;
  }

  void _shiftStart(int delta) => setState(() {
    _start = (_start + delta).clamp(0, _end - 15);
  });

  void _shiftEnd(int delta) => setState(() {
    _end = (_end + delta).clamp(_start + 15, 24 * 60);
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.adjustTitle(widget.title),
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            Text(
              '${hhmm(_start)} – ${hhmm(_end)} '
              '(${_end - _start} min)',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
            const SizedBox(height: 12),
            _StepperRow(
              label: context.l10n.startsLabel,
              value: hhmm(_start),
              onMinus30: () => _shiftStart(-30),
              onMinus5: () => _shiftStart(-5),
              onPlus5: () => _shiftStart(5),
              onPlus30: () => _shiftStart(30),
            ),
            const SizedBox(height: 8),
            _StepperRow(
              label: context.l10n.endsLabel,
              value: hhmm(_end),
              onMinus30: () => _shiftEnd(-30),
              onMinus5: () => _shiftEnd(-5),
              onPlus5: () => _shiftEnd(5),
              onPlus30: () => _shiftEnd(30),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(context.l10n.cancel),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () =>
                        Navigator.of(context)
                            .pop((start: _snap5(_start), end: _snap5(_end))),
                    child: Text(context.l10n.save),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StepperRow extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onMinus30;
  final VoidCallback onMinus5;
  final VoidCallback onPlus5;
  final VoidCallback onPlus30;

  const _StepperRow({
    required this.label,
    required this.value,
    required this.onMinus30,
    required this.onMinus5,
    required this.onPlus5,
    required this.onPlus30,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Widget step(String text, VoidCallback onTap) => InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: theme.dividerColor),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(text, style: theme.textTheme.titleSmall),
      ),
    );
    return Row(
      children: [
        SizedBox(
          width: 56,
          child: Text(label, style: theme.textTheme.labelLarge),
        ),
        step('−30', onMinus30),
        const SizedBox(width: 6),
        step('−5', onMinus5),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium,
          ),
        ),
        const SizedBox(width: 6),
        step('+5', onPlus5),
        const SizedBox(width: 6),
        step('+30', onPlus30),
      ],
    );
  }
}
