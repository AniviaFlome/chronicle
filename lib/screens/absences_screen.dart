import 'package:drift/drift.dart' show Value;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database.dart';
import '../providers.dart';
import '../theme.dart';
import '../l10n/l10n.dart';
import '../utils/time_format.dart';
import '../utils/ui_feedback.dart';
import 'mark_absence_dialog.dart';
import 'view_switch.dart';

enum _ExcusedFilter { all, excused, unexcused }

/// Full absence list with per-class quota summaries and filters.
class AbsencesScreen extends ConsumerStatefulWidget {
  const AbsencesScreen({super.key});

  @override
  ConsumerState<AbsencesScreen> createState() => _AbsencesScreenState();
}

class _AbsencesScreenState extends ConsumerState<AbsencesScreen> {
  _ExcusedFilter _filter = _ExcusedFilter.all;
  int? _classId;
  String _view = 'grid';

  @override
  void initState() {
    super.initState();
    // Synchronous: preloaded in main(), so the saved view renders on the
    // first frame with no list→grid flash.
    _view = ref.read(initialAbsencesViewProvider);
  }

  void _setView(String view) async {
    setState(() => _view = view);
    ref.read(initialAbsencesViewProvider.notifier).set(view);
    try {
      await ref.read(settingsRepositoryProvider).setAbsencesView(view);
    } catch (e) {
      if (!mounted) return;
      showErrorSnack(context, context.l10n.couldNotSave('$e'));
    }
  }

  Widget _viewSwitch(BuildContext context) {
    return ViewSwitch(
      value: _view,
      onChanged: _setView,
      listTooltip: context.l10n.listViewTooltip,
      gridTooltip: context.l10n.gridViewTooltip,
    );
  }

  /// View switch, or null when it lives in the AppBar instead.
  /// Uses [defaultTargetPlatform] so widget tests can override the platform.
  Widget? _viewSwitchOrNull(BuildContext context) =>
      defaultTargetPlatform == TargetPlatform.android
      ? null
      : _viewSwitch(context);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final classes = ref.watch(classesStreamProvider);
    final absences = ref.watch(allAbsencesStreamProvider);
    final activeYear = ref.watch(activeYearIdProvider).value;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.navAbsences),
        // Android only: the list/grid switch sits next to the title
        // instead of floating on its own line below the filters.
        actions: [
          if (defaultTargetPlatform == TargetPlatform.android)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Center(child: _viewSwitch(context)),
            ),
        ],
      ),
      body: classes.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(context.l10n.couldNotLoad('$e'))),
        data: (classList) {
          final byId = {for (final c in classList) c.id: c};
          return absences.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text(context.l10n.couldNotLoad('$e'))),
            data: (all) {
              final visible = all.where((a) {
                if (_classId != null && a.classId != _classId) return false;
                // Classes hidden by the year filter (or inactive ones)
                // only show when no year is selected.
                if (activeYear != null && !byId.containsKey(a.classId)) {
                  return false;
                }
                return switch (_filter) {
                  _ExcusedFilter.all => true,
                  _ExcusedFilter.excused => a.isExcused,
                  _ExcusedFilter.unexcused => !a.isExcused,
                };
              }).toList();

              final withQuota = classList
                  .where((c) => c.active && c.maxAbsences != null)
                  .toList();

              if (_view == 'grid') {
                return _AbsencesGrid(
                  absences: visible,
                  byId: byId,
                  selectedClassId: classList.any((c) => c.id == _classId)
                      ? _classId
                      : null,
                  createExcused: _filter == _ExcusedFilter.excused,
                  filterRow: _FilterRow(
                    filter: _filter,
                    onFilter: (f) => setState(() => _filter = f),
                    classId: classList.any((c) => c.id == _classId)
                        ? _classId
                        : null,
                    classes: classList,
                    onClass: (v) => setState(() => _classId = v),
                    trailing: _viewSwitchOrNull(context),
                  ),
                );
              }

              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                children: [
                  _FilterRow(
                    filter: _filter,
                    onFilter: (f) => setState(() => _filter = f),
                    classId: classList.any((c) => c.id == _classId)
                        ? _classId
                        : null,
                    classes: classList,
                    onClass: (v) => setState(() => _classId = v),
                    trailing: _viewSwitchOrNull(context),
                  ),
                  const SizedBox(height: 16),
                  if (withQuota.isNotEmpty) ...[
                    Text(
                      context.l10n.quotasTitle,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    for (final c in withQuota)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _QuotaCard(
                          classRow: c,
                          unexcused: all
                              .where((a) => a.classId == c.id && !a.isExcused)
                              .length,
                        ),
                      ),
                    const SizedBox(height: 8),
                  ],
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _QuotaCard extends StatelessWidget {
  final ClassesData classRow;
  final int unexcused;

  const _QuotaCard({required this.classRow, required this.unexcused});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final limit = classRow.maxAbsences ?? 0;
    final over = unexcused > 0 && unexcused >= limit;
    final progress = limit <= 0 ? 0.0 : (unexcused / limit).clamp(0.0, 1.0);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 10,
              height: 44,
              decoration: BoxDecoration(
                color: classAccentColor(
                  theme.colorScheme,
                  Color(classRow.colorValue),
                ),
                borderRadius: BorderRadius.circular(5),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(classRow.name, style: theme.textTheme.titleSmall),
                  const SizedBox(height: 6),
                  LinearProgressIndicator(
                    value: progress,
                    color: over ? theme.colorScheme.error : null,
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    context.l10n.quotaCount(unexcused, limit),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: over
                          ? theme.colorScheme.error
                          : theme.colorScheme.outline,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AbsenceTile extends ConsumerWidget {
  final Absence absence;
  final ClassesData? classRow;

  const _AbsenceTile({required this.absence, required this.classRow});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final raw = classRow == null
        ? theme.colorScheme.primary
        : Color(classRow!.colorValue);
    final color = classAccentColor(theme.colorScheme, raw);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 6, color: color),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${absence.date} · ${classRow?.name ?? context.l10n.classFallback}',
                            style: theme.textTheme.titleSmall,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: absence.isExcused
                                ? theme.colorScheme.secondaryContainer
                                : theme.colorScheme.errorContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            absence.isExcused ? context.l10n.excusedBadge : context.l10n.unexcusedBadge,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: absence.isExcused
                                  ? theme.colorScheme.onSecondaryContainer
                                  : theme.colorScheme.onErrorContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (absence.reason != null &&
                        absence.reason!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        '${hhmm(absence.startMinutes)} - '
                        '${hhmm(absence.endMinutes)} · ${absence.reason!}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                    ] else ...[
                      const SizedBox(height: 2),
                      Text(
                        '${hhmm(absence.startMinutes)} - '
                        '${hhmm(absence.endMinutes)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            IconButton(
              tooltip: context.l10n.deleteAbsenceTooltip,
              icon: const Icon(Icons.delete_outline),
              onPressed: () =>
                  ref.read(absenceRepositoryProvider).unmark(absence.id),
            ),
          ],
        ),
      ),
    );
  }
}

/// Excused-state chips plus class picker, shared by list and grid views.
/// Optional [trailing] (the list/grid view switch) sits rightmost on the
/// same line as the All/Excused/Unexcused chips.
class _FilterRow extends StatelessWidget {
  final _ExcusedFilter filter;
  final ValueChanged<_ExcusedFilter> onFilter;
  final int? classId;
  final List<ClassesData> classes;
  final ValueChanged<int?> onClass;
  final Widget? trailing;

  const _FilterRow({
    required this.filter,
    required this.onFilter,
    required this.classId,
    required this.classes,
    required this.onClass,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final chips = SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final f in _ExcusedFilter.values)
                    Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: FilterChip(
                        label: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
                          child: Text(switch (f) {
                            _ExcusedFilter.all => context.l10n.allFilter,
                            _ExcusedFilter.excused =>
                              context.l10n.excusedBadge,
                            _ExcusedFilter.unexcused =>
                              context.l10n.unexcusedBadge,
                          }),
                        ),
                        selected: filter == f,
                        onSelected: (_) => onFilter(f),
                      ),
                    ),
                ],
              ),
            );
            // Narrow screens (phones): stack the view switch on its own
            // right-aligned line so chips and switch are never squeezed
            // into an unreadable strip.
            if (trailing != null && constraints.maxWidth < 520) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  chips,
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: trailing!,
                  ),
                ],
              );
            }
            return Row(
              children: [
                Expanded(child: chips),
                if (trailing != null) ...[
                  const SizedBox(width: 12),
                  trailing!,
                ],
              ],
            );
          },
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<int?>(
          initialValue: classId,
          decoration: InputDecoration(
            labelText: context.l10n.classLabel,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 14,
            ),
          ),
          items: [
            DropdownMenuItem(value: null, child: Text(context.l10n.allClasses)),
            for (final c in classes)
              DropdownMenuItem(value: c.id, child: Text(c.name)),
          ],
          onChanged: onClass,
        ),
      ],
    );
  }
}

/// Attendance matrix: one row per class, one column per week of the year.
/// A filled box means at least one unexcused absence that week; a hollow
/// box with count means excused only. Tap empty to mark (tick), tap filled
/// single to remove, tap multi to see details.
class _AbsencesGrid extends ConsumerStatefulWidget {
  final List<Absence> absences;
  final Map<int, ClassesData> byId;
  final Widget filterRow;
  final int? selectedClassId;
  final bool createExcused;

  const _AbsencesGrid({
    required this.absences,
    required this.byId,
    required this.filterRow,
    required this.selectedClassId,
    this.createExcused = false,
  });

  @override
  ConsumerState<_AbsencesGrid> createState() => _AbsencesGridState();
}

class _AbsencesGridState extends ConsumerState<_AbsencesGrid> {
  final _hScroll = ScrollController();
  List<DateTime>? _lastWeeks;
  int _lastCurrentIndex = -1;

  @override
  void dispose() {
    _hScroll.dispose();
    super.dispose();
  }

  DateTime _weekStartOf(DateTime d, int weekStartDay) {
    final day = DateTime(d.year, d.month, d.day);
    final diff = ((day.weekday - weekStartDay) + 7) % 7;
    return DateTime(day.year, day.month, day.day - diff);
  }

  void _maybeJumpToCurrent() {
    if (!_hScroll.hasClients) return;
    final weeks = _lastWeeks;
    final index = _lastCurrentIndex;
    // Prevent repeated jumps.
    _lastCurrentIndex = -1;
    if (weeks == null || index < 0) return;
    // Only auto-jump for long year grids where current is off-screen.
    if (weeks.length <= 8 || index <= 2) return;
    const cellWidth = 44.0;
    const nameWidth = 120.0;
    final pos = _hScroll.position;
    // Skip when the current week is already visible: no slide on entry.
    if (nameWidth + index * cellWidth <
        pos.pixels + pos.viewportDimension - cellWidth) {
      return;
    }
    // Clamp: near the last weeks the raw target overshoots maxScrollExtent
    // and lands off-screen (throws in debug).
    final target =
        (index * cellWidth - (pos.viewportDimension - nameWidth - cellWidth * 2))
            .clamp(0.0, pos.maxScrollExtent);
    // Post-frame jump once per weeks change.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_hScroll.hasClients) return;
      if ((_hScroll.offset - target).abs() > 1) {
        _hScroll.jumpTo(target);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final year = ref.watch(activeYearProvider).value;
    final weekStartDay = ref.watch(weekStartDayProvider).value ?? 1;

    late final DateTime firstWeekStart;
    late final DateTime lastWeekEnd;
    final yearStart = year == null ? null : DateTime.tryParse(year.startDate);
    final yearEnd = year == null ? null : DateTime.tryParse(year.endDate);
    if (yearStart != null && yearEnd != null && !yearEnd.isBefore(yearStart)) {
      // W1 is the very week containing the year start — never the next week.
      firstWeekStart = _weekStartOf(yearStart, weekStartDay);
      final lastStart = _weekStartOf(yearEnd, weekStartDay);
      lastWeekEnd = DateTime(
        lastStart.year,
        lastStart.month,
        lastStart.day + 6,
      );
    } else {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final currentStart = _weekStartOf(today, weekStartDay);
      // Trailing 12 weeks ending with the current week.
      firstWeekStart = DateTime(
        currentStart.year,
        currentStart.month,
        currentStart.day - 7 * 11,
      );
      lastWeekEnd = DateTime(
        currentStart.year,
        currentStart.month,
        currentStart.day + 6,
      );
    }

    DateTime weekStartOfDay(DateTime d) => _weekStartOf(d, weekStartDay);

    final byCell = <(int, DateTime), List<Absence>>{};
    for (final a in widget.absences) {
      final parsed = DateTime.tryParse(a.date);
      if (parsed == null) continue;
      final day = DateTime(parsed.year, parsed.month, parsed.day);
      byCell.putIfAbsent((a.classId, weekStartOfDay(day)), () => []).add(a);
    }

    final weeks = <DateTime>[];
    for (
      var ws = firstWeekStart;
      !ws.isAfter(lastWeekEnd);
      // Wall-clock step: Duration addition drifts across DST transitions.
      ws = DateTime(ws.year, ws.month, ws.day + 7)
    ) {
      weeks.add(ws);
    }

    final today = DateTime.now();
    final todayStart = _weekStartOf(
      DateTime(today.year, today.month, today.day),
      weekStartDay,
    );
    var currentIndex = -1;
    for (var i = 0; i < weeks.length; i++) {
      if (weeks[i] == todayStart) {
        currentIndex = i;
        break;
      }
    }
    // Cache for post-frame jump.
    if (_lastWeeks == null || _lastWeeks!.length != weeks.length) {
      _lastWeeks = weeks;
      _lastCurrentIndex = currentIndex;
      WidgetsBinding.instance.addPostFrameCallback((_) => _maybeJumpToCurrent());
    }

    final rows = [
      for (final c in widget.byId.values)
        if (widget.selectedClassId == null || c.id == widget.selectedClassId)
          c,
    ]..sort((a, b) => a.name.compareTo(b.name));

    const nameWidth = 120.0;
    const cellWidth = 44.0;

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: widget.filterRow,
        ),
        const SizedBox(height: 16),
        if (rows.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text(
                context.l10n.noClassesToShow,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
            ),
          )
        else
          SingleChildScrollView(
            controller: _hScroll,
            scrollDirection: Axis.horizontal,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const SizedBox(width: nameWidth),
                    for (var i = 0; i < weeks.length; i++)
                      SizedBox(
                        width: cellWidth,
                        child: Tooltip(
                          message:
                              '${isoFromDateTime(weeks[i])} – '
                              '${isoFromDateTime(shiftDays(weeks[i], 6))}',
                          child: Text(
                            '${context.l10n.weekPrefix}${i + 1}',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: weeks[i] == todayStart
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.outline,
                              fontWeight: weeks[i] == todayStart
                                  ? FontWeight.bold
                                  : null,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                for (final c in rows)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        SizedBox(
                          width: nameWidth,
                          child: Row(
                            children: [
                              Container(
                                width: 8,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: classAccentColor(
                                    theme.colorScheme,
                                    Color(c.colorValue),
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  c.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodyMedium,
                                ),
                              ),
                            ],
                          ),
                        ),
                        for (var i = 0; i < weeks.length; i++)
                          _MatrixCell(
                            items: byCell[(c.id, weeks[i])] ?? const [],
                            color: Color(c.colorValue),
                            className: c.name,
                            weekLabel: '${context.l10n.weekPrefix}${i + 1}',
                            classId: c.id,
                            weekStart: weeks[i],
                            weekEnd: shiftDays(weeks[i], 6),
                            createExcused: widget.createExcused,
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _MatrixCell extends ConsumerWidget {
  final List<Absence> items;
  final Color color;
  final String className;
  final String weekLabel;
  final int classId;
  final DateTime weekStart;
  final DateTime weekEnd;
  final bool createExcused;

  const _MatrixCell({
    required this.items,
    required this.color,
    required this.className,
    required this.weekLabel,
    required this.classId,
    required this.weekStart,
    required this.weekEnd,
    this.createExcused = false,
  });

  Future<void> _toggle(BuildContext context, WidgetRef ref) async {
    if (items.isEmpty) {
      // Tick: mark absence on the first day of the week (kind picked in
      // the same dialog as everywhere else; cancel aborts the mark).
      final draft = await showMarkAbsenceDialog(
        context,
        title: context.l10n.markAbsent,
        initialExcused: createExcused,
      );
      if (draft == null || !context.mounted) return;
      try {
        await ref
            .read(absenceRepositoryProvider)
            .mark(
              AbsencesCompanion.insert(
                classId: classId,
                date: isoFromDateTime(weekStart),
                startMinutes: 540,
                endMinutes: 600,
                reason: Value(
                  draft.reason.isEmpty ? null : draft.reason,
                ),
                isExcused: Value(draft.excused),
                kind: Value(draft.kind),
              ),
            );
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Could not save: $e')));
        }
      }
      return;
    }
    if (items.length == 1) {
      // Untick single.
      try {
        await ref.read(absenceRepositoryProvider).unmark(items.single.id);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Could not save: $e')));
        }
      }
      return;
    }
    // Multiple: show details.
    if (context.mounted) {
      showDialog(
        context: context,
        builder: (_) =>
            _MatrixCellDialog(items: items, title: '$className · $weekLabel'),
      );
    }
  }

  void _showSingleDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) =>
          _MatrixCellDialog(items: items, title: '$className · $weekLabel'),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final accent = classAccentColor(theme.colorScheme, color);
    final hasUnexcused = items.any((a) => !a.isExcused);
    final hasAny = items.isNotEmpty;
    final bg = hasUnexcused ? accent : Colors.transparent;
    final fg = hasUnexcused
        ? classOnBlockColor(theme.colorScheme, accent)
        : accent;
    final box = Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(
          color: hasAny ? accent : theme.dividerColor.withValues(alpha: 0.5),
          width: hasAny ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: hasAny
          ? Center(
              child: hasUnexcused
                  ? Text(
                      '${items.length}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: fg,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : Icon(Icons.check, size: 16, color: accent),
            )
          : Icon(
              Icons.add,
              size: 14,
              color: theme.dividerColor.withValues(alpha: 0.6),
            ),
    );
    return SizedBox(
      width: 44,
      child: Center(
        child: Tooltip(
          message:
              hasAny
                  ? '$className · $weekLabel · ${items.length} (tap to ${items.length == 1 ? 'remove' : 'view'})'
                  : '$className · $weekLabel · ${isoFromDateTime(weekStart)} (tap to mark)',
          child: InkWell(
            onTap: () => _toggle(context, ref),
            onLongPress: hasAny ? () => _showSingleDialog(context) : null,
            borderRadius: BorderRadius.circular(8),
            child: box,
          ),
        ),
      ),
    );
  }
}

class _MatrixCellDialog extends ConsumerWidget {
  final List<Absence> items;
  final String title;

  const _MatrixCellDialog({required this.items, required this.title});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final byId = ref.watch(classesStreamProvider).value ?? const [];
    final names = {for (final c in byId) c.id: c};
    return AlertDialog(
      title: Text(title),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final a in items)
                _AbsenceTile(absence: a, classRow: names[a.classId]),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.l10n.close),
        ),
      ],
    );
  }
}
