import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../data/database.dart';
import '../data/repositories.dart';
import '../data/tables.dart';
import '../domain/schedule_models.dart' as engine;
import '../providers.dart';
import '../theme.dart';
import '../l10n/l10n.dart';
import '../utils/time_format.dart';
import 'occurrence_sheet.dart';
import 'occurrence_tile.dart';
import 'xtra_dialog.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final theme = Theme.of(context);

    final todayOcc = ref.watch(occurrencesProvider((today, today)));
    final tomorrowOcc = ref.watch(occurrencesProvider((tomorrow, tomorrow)));
    final classes = ref.watch(classesByIdProvider);
    final absenceKeys = _absenceKeys(ref);
    final warnings = ref.watch(quotaWarningsProvider);
    final tasks = ref.watch(tasksStreamProvider);
    final stats = ref.watch(statsProvider);
    final todayXtra = ref.watch(
      xtraRangeProvider((isoFromDateTime(today), isoFromDateTime(today))),
    );
    final tomorrowXtra = ref.watch(
      xtraRangeProvider((isoFromDateTime(tomorrow), isoFromDateTime(tomorrow))),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          context.l10n.todayWithDate(
            DateFormat('EEE, d MMM', context.l10n.localeName).format(today),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          _StatsCard(stats: stats),
          const SizedBox(height: 4),
          if (warnings.isNotEmpty) ...[
            _SectionTitle(context.l10n.absenceWarnings, Icons.warning_amber_outlined),
            for (final w in warnings) _WarningCard(warning: w),
            const SizedBox(height: 8),
          ],
          _SectionTitle(context.l10n.todaysClasses, Icons.school_outlined),
          _OccurrenceList(
            async: todayOcc,
            classes: classes,
            absenceKeys: absenceKeys,
            emptyText: context.l10n.noClassesToday,
          ),
          _XtraDayList(async: todayXtra),
          const SizedBox(height: 8),
          _SectionTitle(context.l10n.tomorrowSection, Icons.wb_sunny_outlined),
          _OccurrenceList(
            async: tomorrowOcc,
            classes: classes,
            absenceKeys: absenceKeys,
            emptyText: context.l10n.noClassesTomorrow,
          ),
          _XtraDayList(async: tomorrowXtra),
          const SizedBox(height: 8),
          _SectionTitle(context.l10n.upcomingSection, Icons.checklist_outlined),
          tasks.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text(context.l10n.couldNotLoadTasks('$e')),
            data: (list) {
              final upcoming = _upcoming(list, today);
              if (upcoming.isEmpty) {
                return Text(
                  context.l10n.nothingDueWeek,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                );
              }
              return Column(
                children: [
                  for (final t in upcoming) _TaskTile(details: t, today: today),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Set<String> _absenceKeys(WidgetRef ref) {
    final absences = ref.watch(allAbsencesStreamProvider).value ?? const [];
    return {for (final a in absences) '${a.classId}|${a.date}'};
  }

  List<TaskWithDetails> _upcoming(List<TaskWithDetails> all, DateTime today) {
    final limit = isoFromDateTime(today.add(const Duration(days: 7)));
    final items = all
        .where(
          (t) =>
              !t.task.isDone &&
              t.task.dueDate != null &&
              t.task.dueDate!.compareTo(limit) <= 0,
        )
        .toList();
    items.sort((a, b) => a.task.dueDate!.compareTo(b.task.dueDate!));
    return items.take(5).toList();
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  final IconData icon;

  const _SectionTitle(this.text, this.icon);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Text(text, style: theme.textTheme.titleMedium),
        ],
      ),
    );
  }
}

class _OccurrenceList extends StatelessWidget {
  final AsyncValue<List<engine.ClassOccurrence>> async;
  final AsyncValue<Map<int, ClassesData>> classes;
  final Set<String> absenceKeys;
  final String emptyText;

  const _OccurrenceList({
    required this.async,
    required this.classes,
    required this.absenceKeys,
    required this.emptyText,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Text(context.l10n.couldNotLoadSchedule('$e')),
      data: (list) {
        if (list.isEmpty) {
          return Text(
            emptyText,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.outline,
            ),
          );
        }
        final byId = classes.value ?? const {};
        return Column(
          children: [
            for (final occ in list)
              OccurrenceTile(
                occurrence: occ,
                classRow: byId[occ.classId],
                absent: absenceKeys.contains(
                  '${occ.classId}|${isoFromDateTime(occ.date)}',
                ),
                onTap: () => showOccurrenceSheet(context, occ),
              ),
          ],
        );
      },
    );
  }
}

class _WarningCard extends StatelessWidget {
  final QuotaWarning warning;

  const _WarningCard({required this.warning});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = classAccentColor(
      theme.colorScheme,
      Color(warning.classRow.colorValue),
    );
    return Card(
      color: theme.colorScheme.errorContainer.withValues(alpha: 0.35),
      child: ListTile(
        leading: Container(
          width: 10,
          height: 40,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(5),
          ),
        ),
        title: Text(warning.classRow.name),
        subtitle: Text(
          warning.overLimit
              ? context.l10n.quotaOver(warning.unexcused, warning.limit)
              : context.l10n.quotaOneLeft(warning.unexcused, warning.limit),
        ),
        trailing: Icon(
          Icons.warning_amber_outlined,
          color: theme.colorScheme.error,
        ),
      ),
    );
  }
}

class _TaskTile extends ConsumerWidget {
  final TaskWithDetails details;
  final DateTime today;

  const _TaskTile({required this.details, required this.today});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final task = details.task;
    final overdue =
        task.dueDate != null &&
        task.dueDate!.compareTo(isoFromDateTime(today)) < 0;
    final isExam = task.type == TaskKind.exam;

    return Card(
      child: CheckboxListTile(
        value: task.isDone,
        controlAffinity: ListTileControlAffinity.leading,
        onChanged: (v) async {
          final done = v ?? false;
          final spawned = await ref
              .read(taskRepositoryProvider)
              .setDone(task.id, done);
          if (done) {
            await ref.read(reminderSchedulerProvider).cancelTask(task.id);
          } else {
            await ref.read(reminderSchedulerProvider).refreshTask(task.id);
          }
          if (spawned != null) {
            await ref.read(reminderSchedulerProvider).refreshTask(spawned);
          }
        },
        title: Text(
          task.title,
          style: task.isDone
              ? const TextStyle(decoration: TextDecoration.lineThrough)
              : null,
        ),
        subtitle: Text(
          [
            if (isExam) context.l10n.examLabel,
            if (task.dueDate != null)
              '${overdue ? context.l10n.overduePrefix : ''}${context.l10n.dueOn(task.dueDate!)}',
            if (details.classRow != null) details.classRow!.name,
          ].join(' · '),
          style: overdue && !task.isDone
              ? theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                )
              : null,
        ),
        secondary: isExam ? const Icon(Icons.quiz_outlined) : null,
      ),
    );
  }
}

class _StatsCard extends StatelessWidget {
  final StudyStats stats;

  const _StatsCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.5),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
              child: _Stat(
                icon: Icons.local_fire_department_outlined,
                value: '${stats.streakDays}',
                label: context.l10n.dayStreak,
              ),
            ),
            Expanded(
              child: _Stat(
                icon: Icons.check_circle_outline,
                value: '${stats.completedThisWeek}',
                label: context.l10n.doneThisWeek,
              ),
            ),
            Expanded(
              child: _Stat(
                icon: Icons.timer_outlined,
                value: '${stats.focusMinutesThisWeek}m',
                label: context.l10n.focusedThisWeek,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _Stat({required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        Text(value, style: theme.textTheme.titleMedium),
        Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.outline,
          ),
        ),
      ],
    );
  }
}

class _XtraDayList extends ConsumerWidget {
  final AsyncValue<List<XtraEvent>> async;

  const _XtraDayList({required this.async});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return async.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (list) {
        if (list.isEmpty) return const SizedBox.shrink();
        return Column(
          children: [
            for (final x in list)
              XtraTile(
                event: x,
                onTap: () => showXtraDialog(context, ref, existing: x),
              ),
          ],
        );
      },
    );
  }
}
