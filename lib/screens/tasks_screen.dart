import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories.dart';
import '../data/tables.dart';
import '../domain/grades.dart';
import '../theme.dart';
import '../l10n/l10n.dart';
import '../providers.dart';
import '../utils/time_format.dart';
import 'focus_screen.dart';
import 'grades_screen.dart';
import 'task_edit_screen.dart';

String _typeLabel(AppLocalizations l10n, TaskKind kind) => switch (kind) {
  TaskKind.homework => l10n.typeHomework,
  TaskKind.essay => l10n.typeEssay,
  TaskKind.project => l10n.typeProject,
  TaskKind.reading => l10n.typeReading,
  TaskKind.revision => l10n.typeRevision,
  TaskKind.exam => l10n.examLabel,
  TaskKind.reminder => l10n.typeReminder,
};

class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({super.key});

  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen> {
  TaskKind? _filter;
  bool _hideDone = true;

  @override
  Widget build(BuildContext context) {
    final tasks = ref.watch(tasksStreamProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.tasksTitle),
        actions: [
          IconButton(
            tooltip: context.l10n.gradesTooltip,
            icon: const Icon(Icons.grade_outlined),
            onPressed: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const GradesScreen())),
          ),
          IconButton(
            tooltip: context.l10n.focusTooltip,
            icon: const Icon(Icons.timer_outlined),
            onPressed: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const FocusScreen())),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(context),
        icon: const Icon(Icons.add),
        label: Text(context.l10n.addTask),
      ),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(context.l10n.allFilter),
                    selected: _filter == null,
                    onSelected: (_) => setState(() => _filter = null),
                  ),
                ),
                for (final kind in TaskKind.values)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(_typeLabel(context.l10n, kind)),
                      selected: _filter == kind,
                      onSelected: (_) => setState(
                        () => _filter = _filter == kind ? null : kind,
                      ),
                    ),
                  ),
                FilterChip(
                  label: Text(context.l10n.hideDone),
                  selected: _hideDone,
                  onSelected: (v) => setState(() => _hideDone = v),
                ),
              ],
            ),
          ),
          Expanded(
            child: tasks.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) =>
                Center(child: Text(context.l10n.couldNotLoadTasks('$e'))),
              data: (list) {
                final visible = _applyFilter(list);
                if (visible.isEmpty) {
                  return const _EmptyState();
                }
                final countdown = _examCountdown(visible);
                final sections = _sectioned(visible);
                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
                  children: [
                    if (countdown.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          context.l10n.examCountdown,
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                      for (final t in countdown)
                        _CountdownCard(
                          details: t,
                          onOpen: () => _openEditor(context, existing: t),
                        ),
                      const SizedBox(height: 4),
                    ],
                    for (final section in sections) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          section.$1,
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                      for (final t in section.$2)
                        _TaskTile(
                          details: t,
                          onOpen: () => _openEditor(context, existing: t),
                        ),
                    ],
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _openEditor(BuildContext context, {TaskWithDetails? existing}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TaskEditScreen(existing: existing),
        fullscreenDialog: true,
      ),
    );
  }

  List<TaskWithDetails> _applyFilter(List<TaskWithDetails> list) {
    return list.where((t) {
      if (_hideDone && t.task.isDone) return false;
      final filter = _filter;
      if (filter == null) return true;
      return t.task.type == filter;
    }).toList();
  }

  /// Open exams with due dates, soonest first, at most three.
  List<TaskWithDetails> _examCountdown(List<TaskWithDetails> list) {
    final exams = list
        .where(
          (t) =>
              t.task.type == TaskKind.exam &&
              !t.task.isDone &&
              t.task.dueDate != null,
        )
        .toList();
    exams.sort((a, b) => a.task.dueDate!.compareTo(b.task.dueDate!));
    return exams.take(3).toList();
  }

  List<(String, List<TaskWithDetails>)> _sectioned(List<TaskWithDetails> list) {
    final today = isoFromDateTime(DateTime.now());
    final overdue = <TaskWithDetails>[];
    final upcoming = <TaskWithDetails>[];
    final noDate = <TaskWithDetails>[];
    final done = <TaskWithDetails>[];
    for (final t in list) {
      if (t.task.isDone) {
        done.add(t);
      } else if (t.task.dueDate == null) {
        noDate.add(t);
      } else if (t.task.dueDate!.compareTo(today) < 0) {
        overdue.add(t);
      } else {
        upcoming.add(t);
      }
    }
    int byDue(TaskWithDetails a, TaskWithDetails b) {
      final d = (a.task.dueDate ?? '').compareTo(b.task.dueDate ?? '');
      if (d != 0) return d;
      return (a.task.dueMinutes ?? 0).compareTo(b.task.dueMinutes ?? 0);
    }

    overdue.sort(byDue);
    upcoming.sort(byDue);
    noDate.sort((a, b) => a.task.title.compareTo(b.task.title));
    final out = <(String, List<TaskWithDetails>)>[];
    if (overdue.isNotEmpty) out.add((context.l10n.sectionOverdue, overdue));
    if (upcoming.isNotEmpty) out.add((context.l10n.sectionUpcoming, upcoming));
    if (noDate.isNotEmpty) out.add((context.l10n.sectionNoDate, noDate));
    if (done.isNotEmpty) out.add((context.l10n.sectionDone, done));
    return out;
  }
}

class _TaskTile extends ConsumerWidget {
  final TaskWithDetails details;
  final VoidCallback onOpen;

  const _TaskTile({required this.details, required this.onOpen});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final task = details.task;
    final color = classAccentColor(
      theme.colorScheme,
      details.classRow == null
          ? theme.colorScheme.primary
          : Color(details.classRow!.colorValue),
    );
    final doneCount = details.subtasks.where((s) => s.isDone).length;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 6, color: color),
              Checkbox(
                value: task.isDone,
                onChanged: (v) async {
                  final spawned = await ref
                      .read(taskRepositoryProvider)
                      .setDone(task.id, v ?? false);
                  if (v ?? false) {
                    await ref
                        .read(reminderSchedulerProvider)
                        .cancelTask(task.id);
                  } else {
                    await ref
                        .read(reminderSchedulerProvider)
                        .refreshTask(task.id);
                  }
                  if (spawned != null) {
                    await ref
                        .read(reminderSchedulerProvider)
                        .refreshTask(spawned);
                  }
                },
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: task.isDone
                            ? const TextStyle(
                                decoration: TextDecoration.lineThrough,
                              )
                            : theme.textTheme.titleSmall,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        [
                          _typeLabel(context.l10n, task.type),
                          if (task.dueDate != null)
                            context.l10n.dueOnTime(
                              task.dueDate!,
                              task.dueMinutes == null
                                  ? ''
                                  : ' ${hhmm(task.dueMinutes!)}',
                            ),
                          if (details.classRow != null) details.classRow!.name,
                          if (details.subtasks.isNotEmpty)
                            context.l10n.stepsCount(doneCount, details.subtasks.length),
                          if (task.progressPercent != null)
                            '${task.progressPercent}%',
                          if (task.repeatKind != null) context.l10n.repeatsLabel,
                        ].join(' · '),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (task.type == TaskKind.exam)
                const Padding(
                  padding: EdgeInsets.only(right: 4),
                  child: Icon(Icons.quiz_outlined),
                ),
              if (task.priority == TaskPriority.high)
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Icon(
                    Icons.priority_high,
                    size: 18,
                    color: theme.colorScheme.error,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.checklist_outlined,
            size: 64,
            color: theme.colorScheme.outline,
          ),
          const SizedBox(height: 12),
          Text(context.l10n.noTasksHere, style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            context.l10n.addTasksHint,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }
}

class _CountdownCard extends StatelessWidget {
  final TaskWithDetails details;
  final VoidCallback onOpen;

  const _CountdownCard({required this.details, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final task = details.task;
    final now = DateTime.now();
    final days = task.dueDate == null ? null : daysUntil(task.dueDate!, now);
    final label = switch (days) {
      null => context.l10n.noDateLabel,
      < 0 => context.l10n.daysOverdue(-days),
      0 => context.l10n.navToday,
      1 => context.l10n.tomorrowWord,
      _ => context.l10n.inDays(days),
    };

    return Card(
      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.45),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              const Icon(Icons.quiz_outlined),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(task.title, style: theme.textTheme.titleSmall),
                    if (details.classRow != null)
                      Text(
                        details.classRow!.name,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: (days != null && days < 0)
                      ? theme.colorScheme.errorContainer
                      : theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: (days != null && days < 0)
                        ? theme.colorScheme.onErrorContainer
                        : theme.colorScheme.onPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
