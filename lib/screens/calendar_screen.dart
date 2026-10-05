import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database.dart';
import '../data/schedule_repository.dart';
import '../domain/schedule_models.dart' as engine;
import '../providers.dart';
import '../theme.dart';
import '../l10n/l10n.dart';
import '../utils/time_format.dart';
import '../utils/ui_feedback.dart';
import 'occurrence_sheet.dart';
import 'occurrence_tile.dart';
import 'class_quick_edit.dart';
import 'view_switch.dart';
import 'xtra_dialog.dart';

const _dayColumnWidth = 170.0;
const _dayColumnWidthCompact = 150.0;
const _gridDayWidth = 150.0;
const _gridDayWidthCompact = 132.0;
const _hourHeight = 64.0;
const _gutterWidth = 38.0;

/// Sheet look (slot mode): softly rounded corners, hairline gaps so
/// stacked blocks don't touch. Class-times mode keeps its own style.
const _slotRadius = 4.0;
const _slotGap = 1.0;

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
  final _listVertCtrl = ScrollController();
  final _gridVertCtrl = ScrollController();

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
    _listVertCtrl.dispose();
    _gridVertCtrl.dispose();
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
      if (!mounted) return;
      showErrorSnack(context, context.l10n.couldNotSave('$e'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final weekStartDay = ref.watch(weekStartDayProvider).value ?? 1;
    final start = _weekStart(weekStartDay);
    final end = shiftDays(start, 6);
    final theme = Theme.of(context);

    // Narrow phones show slimmer day columns. The today auto-scroll below
    // runs on narrow Android layouts only: wider windows keep the full
    // week in view. defaultTargetPlatform (not Platform.isAndroid) so
    // widget tests, which run on the Android test platform, exercise the
    // auto-scroll path at phone widths.
    final compactDays =
        defaultTargetPlatform == TargetPlatform.android &&
        MediaQuery.of(context).size.width < 600;
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
                ViewSwitch(
                  value: _view,
                  onChanged: _setView,
                  listTooltip: context.l10n.listViewTooltip,
                  gridTooltip: context.l10n.timeGridTooltip,
                ),
              ],
            ),
          ),
          Expanded(
            child: _WeekSwipe(
              onPrevious: () =>
                  setState(() => _focused = shiftDays(_focused, -7)),
              onNext: () =>
                  setState(() => _focused = shiftDays(_focused, 7)),
              child: Builder(
                builder: (context) {
                // Single gate: the week renders only when every source it
                // paints has data. While anything is still resolving, a
                // skeleton with real headers and shimmer bars holds the
                // layout, then everything appears at the same time — no
                // staggered pop-in (xtra chips, class colors, absence
                // badges, rotation labels all arrive together).
                final year = ref.watch(activeYearProvider);
                final holidays = ref.watch(holidaysStreamProvider);
                final absences = ref.watch(allAbsencesStreamProvider);
                // Grid geometry inputs: the grid falls back to defaults
                // while these resolve, visibly repositioning every block.
                // Gating on them keeps first paint final.
                final dayRange = ref.watch(dayRangeProvider);
                final markersMode = ref.watch(gridMarkersModeProvider);
                final fixed = ref.watch(fixedGridProvider);
                final startToday = ref.watch(calendarStartTodayProvider);
                final weekError =
                    occurrences.error ??
                    classes.error ??
                    year.error ??
                    holidays.error ??
                    absences.error ??
                    dayRange.error ??
                    markersMode.error ??
                    fixed.error ??
                    startToday.error;
                if (weekError != null) {
                  return Center(
                    child: Text(context.l10n.couldNotLoadWeek('$weekError')),
                  );
                }
                final eventsError = xtra.error;
                if (eventsError != null) {
                  return Center(
                    child: Text(
                      context.l10n.couldNotLoadEvents('$eventsError'),
                    ),
                  );
                }
                final ready =
                    occurrences.hasValue &&
                    xtra.hasValue &&
                    classes.hasValue &&
                    year.hasValue &&
                    holidays.hasValue &&
                    absences.hasValue &&
                    dayRange.hasValue &&
                    markersMode.hasValue &&
                    fixed.hasValue &&
                    startToday.hasValue;
                if (!ready) {
                  return _WeekSkeleton(
                    start: start,
                    view: _view,
                    listDayWidth: listDayWidth,
                    gridDayWidth: gridDayWidth,
                    todayMidnight: todayMidnight,
                    rotationLabel: rotationLabel,
                  );
                }
                // Day layout is mobile-only: non-mobile platforms always
                // render the horizontal strip, even if a synced/phone-saved
                // 'vertical' value lingers. defaultTargetPlatform (not
                // Platform.isAndroid) keeps widget tests exercising both.
                final savedOrientation = ref.watch(
                  initialCalendarOrientationProvider,
                );
                final mobile =
                    defaultTargetPlatform == TargetPlatform.android ||
                    defaultTargetPlatform == TargetPlatform.iOS;
                return _WeekBody(
                  start: start,
                  end: end,
                  list: occurrences.value ?? const <engine.ClassOccurrence>[],
                  xtraList: xtra.value ?? const <XtraEvent>[],
                  classes: classes,
                  absenceKeys: absenceKeys,
                  rotationLabel: rotationLabel,
                  view: _view,
                  orientation: mobile ? savedOrientation : 'horizontal',
                  listCtrl: _listCtrl,
                  gridCtrl: _gridCtrl,
                  listVertCtrl: _listVertCtrl,
                  gridVertCtrl: _gridVertCtrl,
                  listDayWidth: listDayWidth,
                  gridDayWidth: gridDayWidth,
                  autoScrollToday:
                      compactDays && (startToday.value ?? true),
                  todayMidnight: todayMidnight,
                );
                },
              ),
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

/// Android edge-pull week paging for the calendar body: a vertical drag
/// past the top/bottom edge flips to the previous/next week. Driven by
/// finger-held overscroll notifications only, so normal scrolling and
/// fling bounces never change the week — the flip needs a deliberate
/// extra pull past the edge, then re-arms on finger lift.
class _WeekSwipe extends StatefulWidget {
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final Widget child;

  const _WeekSwipe({
    required this.onPrevious,
    required this.onNext,
    required this.child,
  });

  @override
  State<_WeekSwipe> createState() => _WeekSwipeState();
}

class _WeekSwipeState extends State<_WeekSwipe> {
  /// Deliberate-pull distance before the week flips.
  static const _threshold = 160.0;
  double _pulled = 0;
  bool _armed = true;

  bool _handle(ScrollNotification notification) {
    if (notification is ScrollEndNotification) {
      _pulled = 0;
      _armed = true;
      return false;
    }
    if (!_armed) return false;
    if (notification is OverscrollNotification &&
        notification.dragDetails != null &&
        notification.metrics.axis == Axis.vertical) {
      final delta = notification.overscroll;
      // A direction flip restarts the pull from zero.
      if (_pulled != 0 && delta != 0 && _pulled.sign != delta.sign) {
        _pulled = 0;
      }
      _pulled += delta;
      if (_pulled.abs() >= _threshold) {
        _pulled = 0;
        _armed = false;
        if (delta > 0) {
          widget.onNext();
        } else {
          widget.onPrevious();
        }
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    // defaultTargetPlatform (not Platform.isAndroid) so widget tests,
    // which run on the Android test platform, exercise the gesture.
    if (defaultTargetPlatform != TargetPlatform.android) return widget.child;
    return NotificationListener<ScrollNotification>(
      onNotification: _handle,
      child: widget.child,
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
    final colors = classColors(theme.colorScheme, Color(event.colorValue));
    final bg = colors.bg;
    final fg = colors.onBg;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: bg,
          border: Border.all(color: colors.accent.withValues(alpha: 0.6)),
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

/// Classic calendar time grid: single left gutter, sticky header row,
// and hourly lines only.
class _WeekGrid extends ConsumerStatefulWidget {
  final DateTime start;
  final Map<DateTime, List<engine.ClassOccurrence>> byDay;
  final Map<int, ClassesData> classesById;
  final Set<String> absenceKeys;
  final DateTime today;
  final String? Function(DateTime) rotationLabel;
  final Map<DateTime, List<XtraEvent>> xtraByDay;
  final double? viewportHeight;
  final ScrollController? controller;
  final ScrollController? vertController;
  final double dayWidth;
  final bool vertical;
  final List<GlobalKey>? dayKeys;

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
    this.vertController,
    this.dayWidth = _gridDayWidth,
    this.vertical = false,
    this.dayKeys,
  });

  @override
  ConsumerState<_WeekGrid> createState() => _WeekGridState();
}

class _WeekGridState extends ConsumerState<_WeekGrid> {
  late final ScrollController _headerCtrl = ScrollController();
  bool _syncing = false;

  ScrollController? get _bodyCtrl => widget.controller;

  @override
  void initState() {
    super.initState();
    _bodyCtrl?.addListener(_syncBodyToHeader);
    _headerCtrl.addListener(_syncHeaderToBody);
  }

  @override
  void dispose() {
    _bodyCtrl?.removeListener(_syncBodyToHeader);
    _headerCtrl.dispose();
    super.dispose();
  }

  void _syncBodyToHeader() {
    if (_syncing) return;
    final body = _bodyCtrl;
    if (body == null || !body.hasClients || !_headerCtrl.hasClients) return;
    _syncing = true;
    try {
      _headerCtrl.jumpTo(
        body.offset.clamp(0.0, _headerCtrl.position.maxScrollExtent),
      );
    } finally {
      _syncing = false;
    }
  }

  void _syncHeaderToBody() {
    if (_syncing) return;
    final body = _bodyCtrl;
    if (body == null || !body.hasClients || !_headerCtrl.hasClients) return;
    _syncing = true;
    try {
      body.jumpTo(
        _headerCtrl.offset.clamp(0.0, body.position.maxScrollExtent),
      );
    } finally {
      _syncing = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final start = widget.start;
    final byDay = widget.byDay;
    final classesById = widget.classesById;
    final absenceKeys = widget.absenceKeys;
    final today = widget.today;
    final rotationLabel = widget.rotationLabel;
    final xtraByDay = widget.xtraByDay;
    final viewportHeight = widget.viewportHeight;
    final vertController = widget.vertController;
    final dayWidth = widget.dayWidth;
    // Settings range in minutes; classes outside it extend the range.
    final range =
        ref.watch(dayRangeProvider).value ?? (start: 360, end: 1320);
    final mode = ref.watch(gridMarkersModeProvider).value ?? 'class-times';
    final fixed =
        ref.watch(fixedGridProvider).value ??
        (boundaries: const <int>[], breaks: const <({int start, int end})>[]);
    final showFixed = mode == 'fixed' && fixed.boundaries.isNotEmpty;
    // Single pass over occurrences for the visible-range extension; avoids
    // materializing the flattened list plus two extra map/reduce passes.
    var rangeStart = range.start;
    var rangeEnd = range.end;
    var hasOccurrences = false;
    var minStart = 0;
    var maxEnd = 0;
    for (final dayList in byDay.values) {
      for (final o in dayList) {
        if (!hasOccurrences) {
          hasOccurrences = true;
          minStart = o.startMinutes;
          maxEnd = o.endMinutes;
        } else {
          if (o.startMinutes < minStart) minStart = o.startMinutes;
          if (o.endMinutes > maxEnd) maxEnd = o.endMinutes;
        }
      }
    }
    if (hasOccurrences) {
      // Stretch just enough to fit out-of-range classes — no extra
      // padding, so a custom day start/end is followed as closely as
      // the timetable allows.
      rangeStart = min(range.start, minStart).clamp(0, 1439);
      rangeEnd = max(range.end, maxEnd).clamp(rangeStart + 120, 1440);
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
    final breaks = showFixed ? fixed.breaks : const <({int start, int end})>[];
    // Gutter/grid marks follow the markers mode: class-times uses the
    // visible week's occurrence start/end minutes (clamped to the range),
    // fixed uses the configured slot boundaries. Whole hours remain the
    // fallback when the mark list is empty.
    final markSet = <int>{};
    if (mode == 'fixed') {
      for (final b in fixed.boundaries) {
        if (b >= rangeStart && b <= rangeEnd) markSet.add(b);
      }
    } else {
      for (final dayList in byDay.values) {
        for (final o in dayList) {
          if (o.startMinutes >= rangeStart && o.startMinutes <= rangeEnd) {
            markSet.add(o.startMinutes);
          }
          if (o.endMinutes >= rangeStart && o.endMinutes <= rangeEnd) {
            markSet.add(o.endMinutes);
          }
        }
      }
    }
    final hourly = markSet.toList()..sort();
    if (hourly.isEmpty) {
      for (var h = 0; h <= 24; h++) {
        final m = h * 60;
        if (m >= rangeStart && m <= rangeEnd) hourly.add(m);
      }
    }
    // Ensure custom start/end edges are drawn even when off-mark.
    if (hourly.isEmpty || hourly.first != rangeStart) {
      hourly.insert(0, rangeStart);
    }
    if (hourly.last != rangeEnd) hourly.add(rangeEnd);
    // In fixed mode the generator knows which boundaries start a lesson
    // (the first boundary plus every break end). When an end/start pair
    // collides inside the ~16px label window, the start wins so the
    // gutter reads like the timetable sheet. Grid lines still draw for
    // every mark; only labels are filtered. Class-times mode has no
    // lesson structure, so every mark stays labelable there. Preferred
    // marks outside the visible list can't bully anyone.
    final preferredStarts = <int>{
      if (showFixed) ...[
        if (fixed.boundaries.isNotEmpty &&
            hourly.contains(fixed.boundaries.first))
          fixed.boundaries.first,
        for (final b in fixed.breaks)
          if (hourly.contains(b.end)) b.end,
      ],
    };
    final hourlyLabels = <int>[];
    for (final m in hourly) {
      if (preferredStarts.contains(m)) {
        hourlyLabels.add(m);
        continue;
      }
      var bullied = false;
      for (final s in preferredStarts) {
        if ((m - s).abs() * pxPerMin < 16) {
          bullied = true;
          break;
        }
      }
      if (!bullied) hourlyLabels.add(m);
    }

    // Slot grid (fixed mode only): lesson slots are the fixed-rhythm
    // boundary segments that are not breaks. Each slot becomes one
    // uniform row; breaks collapse to zero space, like the sheet. slotY
    // warps minutes to pixels (linear inside a slot, clamped outside);
    // class-times mode leaves it null and keeps the exact-time layout.
    List<({int start, int end})>? slotRanges;
    double Function(int)? slotY;
    var gridTotalHeight = totalHeight;
    if (showFixed && fixed.boundaries.length >= 2) {
      final slots = <({int start, int end})>[];
      // Out-of-rhythm edges become their own rows so out-of-range
      // classes stay visible (absorbed) instead of collapsing to a line.
      if (rangeStart < fixed.boundaries.first) {
        slots.add((start: rangeStart, end: fixed.boundaries.first));
      }
      for (var i = 0; i + 1 < fixed.boundaries.length; i++) {
        final s = fixed.boundaries[i];
        final e = fixed.boundaries[i + 1];
        if (e <= s) continue;
        final isBreak = fixed.breaks.any((b) => b.start == s && b.end == e);
        if (!isBreak) slots.add((start: s, end: e));
      }
      if (rangeEnd > fixed.boundaries.last) {
        slots.add((start: fixed.boundaries.last, end: rangeEnd));
      }
      if (slots.isNotEmpty) {
        slotRanges = slots;
        gridTotalHeight = slots.length * hourHeight;
        slotY = (int t) {
          if (t <= slots.first.start) return 0.0;
          for (var i = 0; i < slots.length; i++) {
            if (t < slots[i].end) {
              final s = slots[i];
              final frac = ((t - s.start) / (s.end - s.start)).clamp(0.0, 1.0);
              return (i + frac) * hourHeight;
            }
          }
          return slots.length * hourHeight;
        };
      }
    }

    final days = [for (var i = 0; i < 7; i++) shiftDays(start, i)];

    Widget headerCell(DateTime day, {double? width}) {
      final allDay = [
        for (final x in xtraByDay[day] ?? const <XtraEvent>[])
          if (x.startMinutes == null) x,
      ];
      return Container(
        width: width ?? dayWidth,
        margin: const EdgeInsets.symmetric(horizontal: 3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            _GridHeaderCell(
              date: day,
              isToday: day == today,
              rotationLabel: rotationLabel(day),
            ),
            for (final x in allDay)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: _AllDayChip(
                  event: x,
                  onTap: () => showXtraDialog(context, ref, existing: x),
                ),
              ),
          ],
        ),
      );
    }

    final keys = widget.dayKeys;

    if (widget.vertical) {
      // Stacked days: each section gets a full-width header plus its
      // own gutter + single time-grid column. No sticky header row and
      // no horizontal scrollers; the caller provides the vertical
      // scroll. viewportHeight is null here, so every section shares
      // the fixed hour height and times line up across days.
      return LayoutBuilder(
        builder: (context, c) {
          final colWidth = c.maxWidth - _gutterWidth - 4;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < 7; i++)
                Padding(
                  key: keys != null && i < keys.length ? keys[i] : null,
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      headerCell(days[i], width: c.maxWidth),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _HourGutter(
                            rangeStart: rangeStart,
                            totalHeight: gridTotalHeight,
                            hourHeight: hourHeight,
                            hourly: hourlyLabels,
                            slotRanges: slotRanges,
                            slotY: slotY,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: _GridDayColumn(
                              occurrences: byDay[days[i]] ?? const [],
                              classesById: classesById,
                              absenceKeys: absenceKeys,
                              rangeStart: rangeStart,
                              rangeEnd: rangeEnd,
                              totalHeight: gridTotalHeight,
                              hourHeight: hourHeight,
                              showNowLine: days[i] == today,
                              hourly: hourly,
                              breaks: breaks,
                              slotY: slotY,
                              xtra:
                                  xtraByDay[days[i]] ?? const <XtraEvent>[],
                              dayWidth: colWidth,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
            ],
          );
        },
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Sticky header row: gutter spacer plus day headers sharing the
        // body's horizontal scroll via linked controllers.
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(width: _gutterWidth),
              const SizedBox(width: 4),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  controller: _headerCtrl,
                  physics: const ClampingScrollPhysics(),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [for (final day in days) headerCell(day)],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: Scrollbar(
            controller: vertController,
            thumbVisibility: true,
            child: SingleChildScrollView(
              controller: vertController,
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
              physics: const ClampingScrollPhysics(),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _HourGutter(
                    rangeStart: rangeStart,
                    totalHeight: gridTotalHeight,
                    hourHeight: hourHeight,
                    hourly: hourlyLabels,
                    slotRanges: slotRanges,
                    slotY: slotY,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Scrollbar(
                      controller: _bodyCtrl,
                      thumbVisibility: true,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        controller: _bodyCtrl,
                        physics: const ClampingScrollPhysics(),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (final day in days)
                              _GridDayColumn(
                                occurrences: byDay[day] ?? const [],
                                classesById: classesById,
                                absenceKeys: absenceKeys,
                                rangeStart: rangeStart,
                                rangeEnd: rangeEnd,
                                totalHeight: gridTotalHeight,
                                hourHeight: hourHeight,
                                showNowLine: day == today,
                                hourly: hourly,
                                breaks: breaks,
                                slotY: slotY,
                                xtra:
                                    xtraByDay[day] ?? const <XtraEvent>[],
                                dayWidth: dayWidth,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Compact classic day header: weekday over a date number that fills in
/// for today. Used by the sticky grid header row only.
class _GridHeaderCell extends StatelessWidget {
  final DateTime date;
  final bool isToday;
  final String? rotationLabel;

  const _GridHeaderCell({
    required this.date,
    required this.isToday,
    this.rotationLabel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final labelColor = isToday
        ? theme.colorScheme.onPrimary
        : theme.colorScheme.outline;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          shortWeekdayName(date.weekday, context.l10n.localeName),
          style: theme.textTheme.labelMedium?.copyWith(color: labelColor),
        ),
        const SizedBox(height: 2),
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: isToday ? theme.colorScheme.primary : Colors.transparent,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            '${date.day}',
            style: theme.textTheme.titleMedium?.copyWith(
              color: isToday ? theme.colorScheme.onPrimary : null,
              fontWeight: isToday ? FontWeight.w700 : null,
            ),
          ),
        ),
        if (rotationLabel != null)
          Text(
            rotationLabel!,
            style: theme.textTheme.labelSmall?.copyWith(color: labelColor),
          ),
      ],
    );
  }
}

class _HourGutter extends StatelessWidget {
  final int rangeStart;
  final double totalHeight;
  final double hourHeight;
  final List<int> hourly;

  /// Lesson slots for the slot-grid branch (fixed mode only); null keeps
  /// the linear per-mark labels.
  final List<({int start, int end})>? slotRanges;
  final double Function(int)? slotY;

  const _HourGutter({
    required this.rangeStart,
    required this.totalHeight,
    required this.hourHeight,
    required this.hourly,
    this.slotRanges,
    this.slotY,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final slots = slotRanges;
    final yFor = slotY;
    if (slots != null && yFor != null) {
      // Slot mode: one two-line range label per lesson row, like the
      // sheet. Breaks take no space, so there is nothing to skip.
      return SizedBox(
        width: _gutterWidth,
        height: totalHeight,
        child: Stack(
          children: [
            for (final slot in slots)
              Positioned(
                top: yFor(slot.start),
                height: yFor(slot.end) - yFor(slot.start),
                left: 0,
                right: 0,
                child: Center(
                  child: Text(
                    '${hhmmLocale(slot.start, locale)}\n${hhmmLocale(slot.end, locale)}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    }
    // Dense slot boundaries can sit 10 min apart (~hourHeight/6 px), so
    // skip labels that would collide with the previous one. Grid lines
    // still draw for every mark; first and last labels always stay.
    final labeled = <int>[];
    for (var i = 0; i < hourly.length; i++) {
      final h = hourly[i];
      if (i == 0 || i == hourly.length - 1) {
        labeled.add(h);
        continue;
      }
      if ((h - labeled.last) * hourHeight / 60 >= 16) labeled.add(h);
    }
    return SizedBox(
      width: _gutterWidth,
      height: totalHeight,
      child: Stack(
        children: [
          for (final h in labeled)
            Positioned(
              top: (h - rangeStart) * hourHeight / 60 - 8,
              left: 0,
              right: 0,
              child: Text(
                hhmmLocale(h, locale),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
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
  final List<engine.ClassOccurrence> occurrences;
  final Map<int, ClassesData> classesById;
  final Set<String> absenceKeys;
  final int rangeStart;
  final int rangeEnd;
  final double totalHeight;
  final double hourHeight;
  final bool showNowLine;
  final List<XtraEvent> xtra;
  final List<int> hourly;
  final List<({int start, int end})> breaks;
  final double dayWidth;

  /// Warped y-position (slot grid); null keeps the linear time layout.
  final double Function(int)? slotY;

  const _GridDayColumn({
    required this.occurrences,
    required this.classesById,
    required this.absenceKeys,
    required this.rangeStart,
    required this.rangeEnd,
    required this.totalHeight,
    required this.hourHeight,
    required this.showNowLine,
    required this.xtra,
    required this.hourly,
    required this.breaks,
    this.slotY,
    this.dayWidth = _gridDayWidth,
  });

  double get _pxPerMin => hourHeight / 60;

  /// Shaded break bands (recess, lunch) between timetable periods,
  /// clamped to the visible range. Labeled when tall enough.
  List<Widget> _breakBoxes(ThemeData theme, String locale) {
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
                      '${hhmmLocale(s, locale)}–${hhmmLocale(e, locale)}',
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
  double _blockHeight(int startMinutes, int endMinutes) {
    final yFor = slotY;
    if (yFor != null) {
      return (yFor(endMinutes) - yFor(startMinutes) - 2).clamp(
        22.0,
        totalHeight,
      );
    }
    return ((endMinutes - startMinutes) * _pxPerMin - 2).clamp(
      22.0,
      totalHeight,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final timedXtra = [
      for (final x in xtra)
        if (x.startMinutes != null) x,
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
      ClassesData? quickEditRow,
    }) {
      final (lane, laneCount) = lanes[index];
      return _AdjustableBlock(
        title: title,
        startMinutes: startMinutes,
        endMinutes: endMinutes,
        pxPerMin: _pxPerMin,
        rangeStart: rangeStart,
        totalHeight: totalHeight,
        slotY: slotY,
        laneLeft: slotY != null
            ? lane * dayWidth / laneCount + _slotGap
            : 2 + lane * (dayWidth - 8) / laneCount,
        laneWidth: slotY != null
            ? dayWidth / laneCount - 2 * _slotGap
            : (dayWidth - 8) / laneCount - 2,
        onCommit: onCommit,
        quickEditRow: quickEditRow,
        child: child,
      );
    }

    return Container(
      width: dayWidth,
      margin: const EdgeInsets.symmetric(horizontal: 3),
      child: Container(
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
                // Background lines at every gutter mark.
                for (final h in hourly)
                  Positioned(
                    top: (slotY?.call(h) ?? (h - rangeStart) * _pxPerMin),
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 1,
                      color: theme.dividerColor.withValues(alpha: 0.35),
                    ),
                  ),
                if (slotY == null) ..._breakBoxes(theme, locale),
                if (showNow)
                  Positioned(
                    top:
                        (slotY?.call(nowMinutes) ??
                            (nowMinutes - rangeStart) * _pxPerMin),
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 2,
                      color: theme.colorScheme.error,
                    ),
                  ),
                for (var i = 0; i < occurrences.length; i++)
                  draggableBlock(
                    index: i,
                    title: classesById[occurrences[i].classId]?.name ?? context.l10n.classFallback,
                    startMinutes: occurrences[i].startMinutes,
                    endMinutes: occurrences[i].endMinutes,
                    onCommit: (s, e) => commitClassTime(occurrences[i], s, e),
                    quickEditRow: classesById[occurrences[i].classId],
                    child: _GridBlock(
                      square: slotY != null,
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
                      square: slotY != null,
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

  /// Slot mode renders sheet-style rectangles (no radius).
  final bool square;

  const _XtraGridBlock({
    required this.event,
    required this.onTap,
    required this.blockHeight,
    this.square = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // blockHeight is the exact Positioned height; minus the 6px vertical
    // padding gives the room for text.
    final available = blockHeight - 6;
    final colors = classColors(theme.colorScheme, Color(event.colorValue));
    final bg = colors.bg;
    final accent = colors.accent;
    final fg = colors.onBg;
    final timeText = hhmmLocale(
      event.startMinutes ?? 0,
      Localizations.localeOf(context).languageCode,
    );
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(square ? _slotRadius : 10),
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(square ? _slotRadius : 10),
          border: Border.all(
            color: accent.withValues(alpha: 0.55),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 5, color: accent),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 4,
                ),
                // Sliver blocks (e.g. out-of-rhythm classes absorbed at
                // the 22px minimum) can't fit text: spine only, otherwise
                // the Column throws a layout overflow.
                child: available < 20
                    ? const SizedBox.shrink()
                    : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      event.title,
                      maxLines: available < 32 ? 1 : 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        height: 1.2,
                        color: fg,
                      ),
                    ),
                    if (available >= 44) ...[
                      const SizedBox(height: 3),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          timeText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelSmall?.copyWith(
                            height: 1.2,
                            color: fg,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
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

  /// Slot mode renders sheet-style rectangles (no radius).
  final bool square;

  const _GridBlock({
    required this.occurrence,
    required this.classRow,
    required this.absent,
    required this.blockHeight,
    this.square = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final classRow = this.classRow;
    final raw = classRow == null
        ? theme.colorScheme.primary
        : Color(classRow.colorValue);
    final colors = classColors(theme.colorScheme, raw);
    final bg = colors.bg;
    final accent = colors.accent;
    final fg = colors.onBg;
    final room = occurrence.room ?? classRow?.room;
    // blockHeight is the exact Positioned height; minus the 6px vertical
    // padding gives the room for text.
    final available = blockHeight - 6;

    final spine = absent ? theme.colorScheme.error : accent;
    final timeText =
        '${hhmmLocale(occurrence.startMinutes, Localizations.localeOf(context).languageCode)}–${hhmmLocale(occurrence.endMinutes, Localizations.localeOf(context).languageCode)}';
    return InkWell(
      onTap: () => showOccurrenceSheet(context, occurrence),
      borderRadius: BorderRadius.circular(square ? _slotRadius : 10),
      // NOTE: no onLongPress here — this block renders inside
      // _AdjustableBlock, whose long-press owns the adjust-time sheet
      // (gesture arena: an inner handler would steal it). Grid users
      // reach quick-edit from that sheet's details button.
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(square ? _slotRadius : 10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 5, color: spine),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 4,
                ),
                // Sliver blocks (e.g. out-of-rhythm classes absorbed at
                // the 22px minimum) can't fit text: spine only, otherwise
                // the Column throws a layout overflow.
                child: available < 20
                    ? const SizedBox.shrink()
                    : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      classRow?.name ?? context.l10n.classFallback,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        height: 1.2,
                        color: fg,
                      ),
                    ),
                    if (available >= 44) ...[
                      const SizedBox(height: 3),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: (absent
                                  ? theme.colorScheme.error
                                  : accent)
                              .withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          // Absent marker leads the line so it survives
                          // the ellipsis on narrow blocks.
                          absent
                              ? '${context.l10n.absentBadge} · $timeText'
                              : timeText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelSmall?.copyWith(
                            height: 1.2,
                            color: absent
                                ? theme.colorScheme.error
                                : fg,
                          ),
                        ),
                      ),
                    ],
                    if (room != null &&
                        room.isNotEmpty &&
                        available >= 64) ...[
                      const SizedBox(height: 2),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 11,
                            color: fg.withValues(alpha: 0.7),
                          ),
                          const SizedBox(width: 2),
                          Flexible(
                            child: Text(
                              room,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: fg.withValues(alpha: 0.7),
                                height: 1.2,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Pulsing placeholder bar for the calendar loading skeleton: a quiet
/// opacity loop, no package dependency. Staggered via [phase] so adjacent
/// bars don't breathe in sync.
class _PulseBar extends StatefulWidget {
  final double height;
  final double phase;

  const _PulseBar({required this.height, this.phase = 0});

  @override
  State<_PulseBar> createState() => _PulseBarState();
}

class _PulseBarState extends State<_PulseBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  @override
  void initState() {
    super.initState();
    _ctrl.repeat(reverse: true);
    _ctrl.value = widget.phase % 1.0;
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.35, end: 1).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
      ),
      child: Container(
        height: widget.height,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}

/// Loading skeleton for the calendar week: real headers (dates are known
/// synchronously) plus shimmer bars where tiles and blocks will land.
/// Same column widths and chrome as [_WeekBody], so the reveal swaps
/// content in with no layout shift — everything appears at the same time.
class _WeekSkeleton extends StatelessWidget {
  final DateTime start;
  final String view;
  final double listDayWidth;
  final double gridDayWidth;
  final DateTime todayMidnight;
  final String? Function(DateTime) rotationLabel;

  const _WeekSkeleton({
    required this.start,
    required this.view,
    required this.listDayWidth,
    required this.gridDayWidth,
    required this.todayMidnight,
    required this.rotationLabel,
  });

  double _fit(double available, double preferred, double min) =>
      ((available / 7).clamp(min, preferred)).toDouble();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final listW = _fit(
          constraints.maxWidth - 24 - 56,
          listDayWidth,
          110,
        );
        final gridW = _fit(
          constraints.maxWidth - 24 - 52 - 4 - 42,
          gridDayWidth,
          100,
        );
        final days = [for (var i = 0; i < 7; i++) shiftDays(start, i)];
        return IgnorePointer(
          child: IndexedStack(
            index: view == 'grid' ? 1 : 0,
            children: [
              SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const NeverScrollableScrollPhysics(),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (var i = 0; i < 7; i++)
                        Container(
                          width: listW,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _DayHeader(
                                date: days[i],
                                isToday: days[i] == todayMidnight,
                                rotationLabel: rotationLabel(days[i]),
                              ),
                              const SizedBox(height: 8),
                              _PulseBar(
                                height: 52 + (i % 3) * 8.0,
                                phase: (i * 0.23) % 1.0,
                              ),
                              const SizedBox(height: 6),
                              _PulseBar(
                                height: 64 - (i % 2) * 10.0,
                                phase: ((i + 2) * 0.23) % 1.0,
                              ),
                              const SizedBox(height: 6),
                              _PulseBar(
                                height: 44 + (i % 4) * 6.0,
                                phase: ((i + 4) * 0.23) % 1.0,
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(width: _gutterWidth),
                        const SizedBox(width: 4),
                        Expanded(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            physics: const NeverScrollableScrollPhysics(),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                for (final day in days)
                                  Container(
                                    width: gridW,
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 3,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        _GridHeaderCell(
                                          date: day,
                                          isToday: day == todayMidnight,
                                          rotationLabel: rotationLabel(day),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                      child: SizedBox(
                        // Default-range height (16h × 64px); the real grid
                        // replaces it with the exact range on reveal.
                        height: 1024,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            SizedBox(
                              width: _gutterWidth,
                              child: _SkeletonTicks(),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                physics: const NeverScrollableScrollPhysics(),
                                child: Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    for (var i = 0; i < 7; i++)
                                      Container(
                                        width: gridW,
                                        margin: const EdgeInsets.symmetric(
                                          horizontal: 3,
                                        ),
                                        child: _SkeletonLane(
                                          index: i,
                                          ticks: const _SkeletonTicks(),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Faint hour-rhythm lines for the skeleton grid body: same count as a
/// default 6:00–22:00 day, no range knowledge required.
class _SkeletonTicks extends StatelessWidget {
  const _SkeletonTicks();

  @override
  Widget build(BuildContext context) {
    final line = BorderSide(
      color: Theme.of(
        context,
      ).colorScheme.outlineVariant.withValues(alpha: 0.4),
      width: 0.5,
    );
    return Column(
      children: [
        for (var k = 0; k < 17; k++)
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: Border(bottom: line),
              ),
            ),
          ),
      ],
    );
  }
}

/// One skeleton grid lane: tick lines behind two shimmer blocks at
/// staggered fractions so the week reads as loading, not empty.
class _SkeletonLane extends StatelessWidget {
  final int index;
  final Widget ticks;

  const _SkeletonLane({required this.index, required this.ticks});

  @override
  Widget build(BuildContext context) {
    final i = index;
    return Stack(
      children: [
        ticks,
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Spacer(flex: 2 + (i % 3)),
            _PulseBar(height: 60, phase: (i * 0.31) % 1.0),
            Spacer(flex: 3 - (i % 2)),
            _PulseBar(height: 84, phase: ((i + 3) * 0.31) % 1.0),
            const Spacer(flex: 6),
          ],
        ),
      ],
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
  final ScrollController? listVertCtrl;
  final ScrollController? gridVertCtrl;
  final double listDayWidth;
  final double gridDayWidth;
  final bool autoScrollToday;
  final DateTime? todayMidnight;
  final String orientation;

  const _WeekBody({
    required this.start,
    required this.end,
    required this.list,
    required this.xtraList,
    required this.classes,
    required this.absenceKeys,
    required this.rotationLabel,
    required this.view,
    required this.orientation,
    this.listCtrl,
    this.gridCtrl,
    this.listVertCtrl,
    this.gridVertCtrl,
    this.listDayWidth = _dayColumnWidth,
    this.gridDayWidth = _gridDayWidth,
    this.autoScrollToday = false,
    this.todayMidnight,
  });

  @override
  State<_WeekBody> createState() => _WeekBodyState();
}

class _WeekBodyState extends State<_WeekBody> {
  /// Weeks already jumped/revealed per view, keyed as `view_isoStart`.
  /// Both views stay mounted (IndexedStack), so scroll offsets survive
  /// view switches and each week jumps at most once per view.
  final Set<String> _jumpedKeys = {};
  final Set<String> _readyKeys = {};

  /// Stable per-day keys for the vertical today-jump (ensureVisible).
  /// Two sets because both views stay mounted in the IndexedStack — one
  /// shared set would attach the same key twice and throw.
  final _listKeys = [for (var i = 0; i < 7; i++) GlobalKey()];
  final _gridKeys = [for (var i = 0; i < 7; i++) GlobalKey()];

  /// Day width that fits all 7 columns into [available] when possible,
  /// shrinking from [preferred] down to [min] before scrolling is needed.
  double _fitWidth(double available, double preferred, double min) =>
      ((available / 7).clamp(min, preferred)).toDouble();

  @override
  Widget build(BuildContext context) {
    final byId = widget.classes.value ?? const <int, ClassesData>{};
    // Cache the 7 days once; the strip below previously recomputed
    // shiftDays(widget.start, i) ~30x per build for keys, lookups and props.
    final days = [for (var i = 0; i < 7; i++) shiftDays(widget.start, i)];
    final byDay = <DateTime, List<engine.ClassOccurrence>>{};
    final xtraByDay = <DateTime, List<XtraEvent>>{};
    for (final day in days) {
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

    // Jump/reveal keys are per orientation: horizontal jumps move a
    // horizontal controller, vertical jumps scroll a day into view, and
    // the two must not share dedup state.
    String jumpKey(String view) =>
        '${widget.orientation}_${view}_${isoFromDateTime(widget.start)}';

    void maybeJump(String view, double listStride, double gridStride) {
      if (!widget.autoScrollToday) return;
      // Only the week containing today needs a jump; other weeks stay
      // put instead of flashing to a clamped edge.
      final rawIdx = daysBetween(widget.start, todayMidnight);
      if (rawIdx < 0 || rawIdx >= 7) return;
      final key = jumpKey(view);
      if (_readyKeys.contains(key)) return;
      if (_jumpedKeys.contains(key)) return;
      _jumpedKeys.add(key);
      if (widget.orientation == 'vertical') {
        // No horizontal controller to jump: scroll the day into view.
        // The horizontal controllers are detached in vertical mode, so
        // the shared horizontal path below would just spin its retry
        // loop once per build.
        final keys = view == 'grid' ? _gridKeys : _listKeys;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          final ctx = keys[rawIdx].currentContext;
          if (ctx == null) {
            _jumpedKeys.remove(key);
            return;
          }
          Scrollable.ensureVisible(
            ctx,
            duration: const Duration(milliseconds: 1),
            alignment: 0.0,
          ).then((_) {
            if (!mounted) return;
            setState(() => _readyKeys.add(key));
          });
        });
        return;
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final ctrl = view == 'grid' ? widget.gridCtrl : widget.listCtrl;
        if (ctrl == null || !ctrl.hasClients) {
          // Not laid out yet: retry on the next build instead of
          // dropping the jump silently.
          _jumpedKeys.remove(key);
          return;
        }
        final stride = view == 'grid' ? gridStride : listStride;
        ctrl.jumpTo(min(rawIdx * stride, ctrl.position.maxScrollExtent));
        // Reveal after the jump lands so the first painted frame is
        // already on today (no week-start flash).
        setState(() => _readyKeys.add(key));
      });
    }

    // Hide the strip until the today-jump lands: painting offset 0 for
    // one frame is exactly the flicker being fixed. Non-jump weeks and
    // non-Android layouts render immediately. Only the first visit to a
    // week hides; view switches reuse the kept-alive scrolled position.
    bool hideForJump(String view) {
      if (!widget.autoScrollToday) return false;
      final rawIdx = daysBetween(widget.start, todayMidnight);
      if (rawIdx < 0 || rawIdx >= 7) return false;
      return !_readyKeys.contains(jumpKey(view));
    }

    // Both views stay mounted in an IndexedStack: switching is a
    // visibility toggle, so scroll positions survive and the today-jump
    // runs once per week per view instead of on every toggle.
    return LayoutBuilder(
      builder: (context, constraints) {
        final vertical = widget.orientation == 'vertical';
        // Single left gutter, one gap, padding and the 3px side
        // margins around every day column.
        final gridAvail =
            constraints.maxWidth - 24 - _gutterWidth - 4 - 42;
        final gridDayWidth = _fitWidth(gridAvail, widget.gridDayWidth, 100);
        // Horizontal padding plus the 4px side margins of every column.
        final listDayWidth = _fitWidth(
          constraints.maxWidth - 24 - 56,
          widget.listDayWidth,
          110,
        );
        maybeJump('list', listDayWidth + 8, 0);
        maybeJump('grid', 0, gridDayWidth + 6);
        final grid = _WeekGrid(
          start: widget.start,
          byDay: byDay,
          classesById: byId,
          absenceKeys: widget.absenceKeys,
          today: todayMidnight,
          rotationLabel: widget.rotationLabel,
          xtraByDay: xtraByDay,
          vertical: vertical,
          dayKeys: vertical ? _gridKeys : null,
          viewportHeight: vertical
              ? null
              : (constraints.maxHeight.isFinite
                    ? constraints.maxHeight
                    : null),
          controller: widget.gridCtrl,
          vertController: widget.gridVertCtrl,
          dayWidth: gridDayWidth,
        );
        // Two-dimensional scroll: the inner strip scrolls horizontally
        // across days, the outer view vertically through tall columns.
        // Without the outer scroll, busy days overflow the viewport with
        // a yellow/black strip instead of scrolling.
        // The strip fills the viewport even on light weeks so every
        // vertical drag reaches the scrollable (edge-pull week paging
        // and the overscroll glow work over empty areas too).
        final minStripHeight = constraints.maxHeight.isFinite
            ? (constraints.maxHeight - 24).clamp(0.0, double.infinity)
            : 0.0;
        // Vertical layout: the 7 days stack full-width in the outer
        // scroll; no inner horizontal scroller. Horizontal keeps the
        // side-scrolling strip.
        final vertListWidth = constraints.maxWidth - 24;
        final inner = vertical
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < 7; i++)
                    Container(
                      key: _listKeys[i],
                      child: _DayColumn(
                        date: days[i],
                        isToday: days[i] == todayMidnight,
                        occurrences: byDay[days[i]] ?? const [],
                        classesById: byId,
                        absenceKeys: widget.absenceKeys,
                        rotationLabel: widget.rotationLabel(days[i]),
                        xtra: xtraByDay[days[i]] ?? const [],
                        dayWidth: vertListWidth,
                      ),
                    ),
                ],
              )
            : Scrollbar(
                controller: widget.listCtrl,
                thumbVisibility: true,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  controller: widget.listCtrl,
                  physics: const ClampingScrollPhysics(),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (var i = 0; i < 7; i++)
                        _DayColumn(
                          date: days[i],
                          isToday: days[i] == todayMidnight,
                          occurrences: byDay[days[i]] ?? const [],
                          classesById: byId,
                          absenceKeys: widget.absenceKeys,
                          rotationLabel: widget.rotationLabel(days[i]),
                          xtra: xtraByDay[days[i]] ?? const [],
                          dayWidth: listDayWidth,
                        ),
                    ],
                  ),
                ),
              );
        final strip = Scrollbar(
          controller: widget.listVertCtrl,
          thumbVisibility: true,
          child: SingleChildScrollView(
            controller: widget.listVertCtrl,
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: minStripHeight),
              child: inner,
            ),
          ),
        );
        // The stacked vertical grid is taller than the viewport, so it
        // gets its own vertical scroll; the horizontal grid scrolls
        // internally already.
        final gridBody = vertical
            ? Scrollbar(
                controller: widget.gridVertCtrl,
                thumbVisibility: true,
                child: SingleChildScrollView(
                  controller: widget.gridVertCtrl,
                  physics: const ClampingScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 16),
                  child: grid,
                ),
              )
            : grid;
        // Keep the Offstage wrapper across the reveal: swapping
        // Offstage(child: X) for X remounts the scrollable subtree and
        // resets its offset to zero, discarding the just-landed
        // today-jump. Flipping only the flag preserves the ScrollPosition.
        final gridChild = Offstage(
          offstage: hideForJump('grid'),
          child: gridBody,
        );
        final listChild = Offstage(
          offstage: hideForJump('list'),
          child: strip,
        );
        return IndexedStack(
          index: widget.view == 'grid' ? 1 : 0,
          children: [listChild, gridChild],
        );
      },
    );
  }
}

int _snap5(int minutes) => (minutes / 5).round() * 5;

/// A grid block positioned by time. Long-press opens the adjust sheet.
class _AdjustableBlock extends StatelessWidget {
  final String title;
  final int startMinutes;
  final int endMinutes;
  final double pxPerMin;
  final int rangeStart;
  final double totalHeight;

  /// Warped y-position (slot grid); null keeps the linear time layout.
  final double Function(int)? slotY;
  final double laneLeft;
  final double laneWidth;
  final Widget child;
  final Future<void> Function(int newStart, int newEnd) onCommit;

  /// Class row for the quick-edit details button; null for Xtra blocks.
  final ClassesData? quickEditRow;

  const _AdjustableBlock({
    required this.title,
    required this.startMinutes,
    required this.endMinutes,
    required this.pxPerMin,
    required this.rangeStart,
    required this.totalHeight,
    this.slotY,
    required this.laneLeft,
    required this.laneWidth,
    required this.child,
    required this.onCommit,
    this.quickEditRow,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final yFor = slotY;
    final y0 =
        yFor?.call(startMinutes) ?? (startMinutes - rangeStart) * pxPerMin;
    final y1 = yFor?.call(endMinutes) ?? (endMinutes - rangeStart) * pxPerMin;
    // Slot mode fills whole rows edge to edge, like the sheet.
    final gap = yFor == null ? 1.0 : _slotGap;
    final top = y0 + gap;
    final height = (y1 - y0 - 2 * gap).clamp(22.0, totalHeight);
    return Positioned(
      top: top,
      height: height,
      left: laneLeft,
      width: laneWidth,
      child: GestureDetector(
        onLongPress: () async {
          final quickRow = quickEditRow;
          final result = await showModalBottomSheet<({int start, int end})>(
            context: context,
            showDragHandle: true,
            builder: (_) => _AdjustTimeSheet(
              title: title,
              startMinutes: startMinutes,
              endMinutes: endMinutes,
              // The sheet's context is dead after pop, so the callback
              // captures this block's context instead.
              onQuickEdit: quickRow == null
                  ? null
                  : () => showClassQuickEditSheet(context, quickRow),
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
  final VoidCallback? onQuickEdit;

  const _AdjustTimeSheet({
    required this.title,
    required this.startMinutes,
    required this.endMinutes,
    this.onQuickEdit,
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
              '${hhmmLocale(_start, Localizations.localeOf(context).languageCode)} – ${hhmmLocale(_end, Localizations.localeOf(context).languageCode)} '
              '(${_end - _start} min)',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
            const SizedBox(height: 12),
            _StepperRow(
              label: context.l10n.startsLabel,
              value: hhmmLocale(
                _start,
                Localizations.localeOf(context).languageCode,
              ),
              onMinus30: () => _shiftStart(-30),
              onMinus5: () => _shiftStart(-5),
              onPlus5: () => _shiftStart(5),
              onPlus30: () => _shiftStart(30),
            ),
            const SizedBox(height: 8),
            _StepperRow(
              label: context.l10n.endsLabel,
              value: hhmmLocale(
                _end,
                Localizations.localeOf(context).languageCode,
              ),
              onMinus30: () => _shiftEnd(-30),
              onMinus5: () => _shiftEnd(-5),
              onPlus5: () => _shiftEnd(5),
              onPlus30: () => _shiftEnd(30),
            ),
            const SizedBox(height: 16),
            if (widget.onQuickEdit != null) ...[
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    widget.onQuickEdit!.call();
                  },
                  icon: const Icon(Icons.tune_outlined),
                  label: Text(context.l10n.quickEditTitle),
                ),
              ),
              const SizedBox(height: 8),
            ],
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
