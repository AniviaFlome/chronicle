import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database.dart';
import '../data/repositories.dart';
import '../data/tables.dart';
import '../providers.dart';
import '../l10n/l10n.dart';
import '../utils/time_format.dart';

const _reminderPresetMinutes = <int>[15, 60, 180, 1440, 10080];

String formatReminderOffset(AppLocalizations l10n, int minutes) {
  if (minutes <= 0) return l10n.remindDueTime;
  if (minutes % 10080 == 0) return l10n.remindWeeks(minutes ~/ 10080);
  if (minutes % 1440 == 0) return l10n.remindDays(minutes ~/ 1440);
  if (minutes % 60 == 0) return l10n.remindHours(minutes ~/ 60);
  return l10n.remindMins(minutes);
}

String _typeLabel(AppLocalizations l10n, TaskKind kind) => switch (kind) {
  TaskKind.homework => l10n.typeHomework,
  TaskKind.essay => l10n.typeEssay,
  TaskKind.project => l10n.typeProject,
  TaskKind.reading => l10n.typeReading,
  TaskKind.revision => l10n.typeRevision,
  TaskKind.exam => l10n.examLabel,
  TaskKind.reminder => l10n.typeReminder,
};

String _repeatLabel(AppLocalizations l10n, RepeatKind? kind) =>
    switch (kind) {
      null => l10n.repeatNever,
      RepeatKind.daily => l10n.repeatDaily,
      RepeatKind.weekly => l10n.repeatWeekly,
      RepeatKind.monthly => l10n.repeatMonthly,
    };

String _priorityLabel(AppLocalizations l10n, TaskPriority p) =>
    switch (p) {
      TaskPriority.low => l10n.priorityLow,
      TaskPriority.normal => l10n.priorityNormal,
      TaskPriority.high => l10n.priorityHigh,
    };

class TaskEditScreen extends ConsumerStatefulWidget {
  final TaskWithDetails? existing;

  const TaskEditScreen({super.key, this.existing});

  @override
  ConsumerState<TaskEditScreen> createState() => _TaskEditScreenState();
}

class _TaskEditScreenState extends ConsumerState<TaskEditScreen> {
  late final TextEditingController _title;
  late final TextEditingController _notes;
  late final TextEditingController _subtaskInput;
  int? _classId;
  TaskKind _type = TaskKind.homework;
  TaskPriority _priority = TaskPriority.normal;
  DateTime? _dueDate;
  TimeOfDay? _dueTime;
  bool _trackProgress = false;
  double _progress = 0;
  RepeatKind? _repeat;
  DateTime? _repeatUntil;
  int? _linkedExamId;
  bool _busy = false;
  String? _error;
  final _formKey = GlobalKey<FormState>();

  /// Pending rows for a task that does not exist yet.
  final List<String> _pendingSubtasks = [];
  final Set<int> _pendingReminders = {};

  bool get _isNew => widget.existing == null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing?.task;
    _title = TextEditingController(text: e?.title ?? '');
    _notes = TextEditingController(text: e?.notes ?? '');
    _subtaskInput = TextEditingController();
    _classId = e?.classId;
    _type = e?.type ?? TaskKind.homework;
    _priority = e?.priority ?? TaskPriority.normal;
    _dueDate = e?.dueDate == null ? null : DateTime.tryParse(e!.dueDate!);
    _dueTime = e?.dueMinutes == null
        ? null
        : TimeOfDay(hour: e!.dueMinutes! ~/ 60, minute: e.dueMinutes! % 60);
    _trackProgress = e?.progressPercent != null;
    _progress = (e?.progressPercent ?? 0).toDouble();
    _repeat = e?.repeatKind;
    _repeatUntil = e?.repeatUntil == null
        ? null
        : DateTime.tryParse(e!.repeatUntil!);
    _linkedExamId = e?.linkedExamId;
  }

  @override
  void dispose() {
    _title.dispose();
    _notes.dispose();
    _subtaskInput.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? now,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 3),
    );
    if (picked != null && mounted) setState(() => _dueDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _dueTime ?? const TimeOfDay(hour: 17, minute: 0),
    );
    if (picked != null && mounted) setState(() => _dueTime = picked);
  }

  int? get _dueMinutes =>
      _dueTime == null ? null : _dueTime!.hour * 60 + _dueTime!.minute;

  Future<void> _save() async {
    if (_busy || !_formKey.currentState!.validate()) return;
    final repo = ref.read(taskRepositoryProvider);
    final scheduler = ref.read(reminderSchedulerProvider);

    final reminderCount = _isNew
        ? _pendingReminders.length
        : (ref
                  .read(remindersForTaskProvider(widget.existing!.task.id))
                  .value
                  ?.length ??
              0);
    if (_dueDate == null && reminderCount > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.remindersNeedDue),
        ),
      );
      return;
    }

    final entry = TasksCompanion.insert(
      title: _title.text.trim(),
      classId: Value(_classId),
      type: Value(_type),
      priority: Value(_priority),
      dueDate: Value(_dueDate == null ? null : isoFromDateTime(_dueDate!)),
      dueMinutes: Value(_dueMinutes),
      progressPercent: Value(_trackProgress ? _progress.round() : null),
      repeatKind: Value(_repeat),
      repeatUntil: Value(
        _repeat == null || _repeatUntil == null
            ? null
            : isoFromDateTime(_repeatUntil!),
      ),
      linkedExamId: Value(_type == TaskKind.revision ? _linkedExamId : null),
      notes: Value(_notes.text.trim().isEmpty ? null : _notes.text.trim()),
    );

    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final int taskId;
      if (_isNew) {
        taskId = await repo.createTaskFull(
          entry,
          _pendingSubtasks,
          _pendingReminders.toList(),
        );
      } else {
        final updated = await repo.update(
          widget.existing!.task.copyWithCompanion(entry),
        );
        if (!updated) throw StateError('Task no longer exists');
        taskId = widget.existing!.task.id;
      }
      await scheduler.refreshTask(taskId);
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      debugPrint('Save task failed: $e');
      if (mounted) {
        setState(() => _error = context.l10n.couldNotSaveTask('$e'));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete() async {
    if (_busy || _isNew) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.deleteTaskTitle),
        content: Text(
          context.l10n.deleteTaskBody(widget.existing!.task.title),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final id = widget.existing!.task.id;
      await ref.read(reminderSchedulerProvider).cancelTask(id);
      await ref.read(taskRepositoryProvider).delete(id);
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      debugPrint('Delete task failed: $e');
      if (mounted) {
        setState(() => _error = 'Could not delete task: $e');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _setDone(bool done) async {
    if (_isNew) return;
    final id = widget.existing!.task.id;
    final spawned = await ref.read(taskRepositoryProvider).setDone(id, done);
    if (done) {
      await ref.read(reminderSchedulerProvider).cancelTask(id);
    } else {
      await ref.read(reminderSchedulerProvider).refreshTask(id);
    }
    if (spawned != null) {
      await ref.read(reminderSchedulerProvider).refreshTask(spawned);
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final classes = ref.watch(classesStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isNew ? context.l10n.addTask : context.l10n.editTask),
        actions: [
          if (!_isNew)
            IconButton(
              tooltip: context.l10n.deleteTaskTooltip,
              onPressed: _busy ? null : _delete,
              icon: const Icon(Icons.delete_outline),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _title,
              decoration: InputDecoration(labelText: context.l10n.titleLabel),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? context.l10n.titleRequired : null,
              autofocus: _isNew,
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final typeField = DropdownButtonFormField<TaskKind>(
                  initialValue: _type,
                  decoration: InputDecoration(
                    labelText: context.l10n.typeLabel,
                  ),
                  items: [
                    for (final k in TaskKind.values)
                      DropdownMenuItem(
                        value: k,
                        child: Text(_typeLabel(context.l10n, k)),
                      ),
                  ],
                  onChanged: (v) => setState(() => _type = v!),
                );
                final priorityField = DropdownButtonFormField<TaskPriority>(
                  initialValue: _priority,
                  decoration: InputDecoration(
                    labelText: context.l10n.priorityLabel,
                  ),
                  items: [
                    for (final p in TaskPriority.values)
                      DropdownMenuItem(
                        value: p,
                        child: Text(_priorityLabel(context.l10n, p)),
                      ),
                  ],
                  onChanged: (v) => setState(() => _priority = v!),
                );
                // Long type names (e.g. "Group project") overflow a
                // side-by-side row on narrow screens: stack them instead.
                if (constraints.maxWidth < 420) {
                  return Column(
                    children: [
                      typeField,
                      const SizedBox(height: 12),
                      priorityField,
                    ],
                  );
                }
                return Row(
                  children: [
                    Expanded(child: typeField),
                    const SizedBox(width: 12),
                    Expanded(child: priorityField),
                  ],
                );
              },
            ),
            const SizedBox(height: 12),
            classes.when(
              loading: () => const SizedBox.shrink(),
              error: (e, _) => Text(context.l10n.couldNotLoadClasses('$e')),
              data: (list) {
                // The task's own class may be hidden by the year filter;
                // keep it selectable so the form never breaks.
                final current = widget.existing?.classRow;
                final items = [
                  ...list,
                  if (current != null && list.every((c) => c.id != current.id))
                    current,
                ];
                return DropdownButtonFormField<int?>(
                  initialValue: _classId,
                  decoration: InputDecoration(labelText: context.l10n.classLabel),
                  items: [
                    DropdownMenuItem(
                      value: null,
                      child: Text(context.l10n.noClass),
                    ),
                    for (final c in items)
                      DropdownMenuItem(value: c.id, child: Text(c.name)),
                  ],
                  onChanged: (v) => setState(() => _classId = v),
                );
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _DateButton(
                    label: context.l10n.dueDateLabel,
                    text: _dueDate == null
                        ? context.l10n.notSet
                        : isoFromDateTime(_dueDate!),
                    onPick: _pickDate,
                    onClear: _dueDate == null
                        ? null
                        : () => setState(() {
                            _dueDate = null;
                            _dueTime = null;
                          }),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _DateButton(
                    label: context.l10n.dueTimeLabel,
                    text: _dueTime == null
                        ? context.l10n.allDay
                        : _dueTime!.format(context),
                    onPick: _dueDate == null ? null : _pickTime,
                    onClear: _dueTime == null
                        ? null
                        : () => setState(() => _dueTime = null),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notes,
              decoration: InputDecoration(labelText: context.l10n.notesLabel),
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              title: Text(context.l10n.trackProgress),
              subtitle: Text(context.l10n.trackProgressHint),
              value: _trackProgress,
              onChanged: (v) => setState(() => _trackProgress = v),
            ),
            if (_trackProgress)
              Row(
                children: [
                  Expanded(
                    child: Slider(
                      value: _progress,
                      max: 100,
                      divisions: 20,
                      label: '${_progress.round()}%',
                      onChanged: (v) => setState(() => _progress = v),
                    ),
                  ),
                  SizedBox(
                    width: 56,
                    child: Text(
                      '${_progress.round()}%',
                      style: Theme.of(context).textTheme.titleMedium,
                      textAlign: TextAlign.end,
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<RepeatKind?>(
                    initialValue: _repeat,
                    decoration: InputDecoration(labelText: context.l10n.repeatsLabel),
                    items: [
                      DropdownMenuItem(value: null, child: Text(context.l10n.repeatNever)),
                      for (final r in RepeatKind.values)
                        DropdownMenuItem(
                          value: r,
                          child: Text(_repeatLabel(context.l10n, r)),
                        ),
                    ],
                    onChanged: (v) => setState(() {
                      _repeat = v;
                      if (v == null) _repeatUntil = null;
                    }),
                  ),
                ),
                if (_repeat != null) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: _DateButton(
                      label: context.l10n.repeatUntilLabel,
                      text: _repeatUntil == null
                          ? context.l10n.foreverLabel
                          : isoFromDateTime(_repeatUntil!),
                      onPick: () async {
                        final now = DateTime.now();
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _repeatUntil ?? now,
                          firstDate: DateTime(now.year - 2),
                          lastDate: DateTime(now.year + 5),
                        );
                        if (picked != null && mounted) {
                          setState(() => _repeatUntil = picked);
                        }
                      },
                      onClear: _repeatUntil == null
                          ? null
                          : () => setState(() => _repeatUntil = null),
                    ),
                  ),
                ],
              ],
            ),
            if (_type == TaskKind.revision) ...[
              const SizedBox(height: 12),
              _ExamLinkDropdown(
                value: _linkedExamId,
                excludeTaskId: widget.existing?.task.id,
                onChanged: (v) => setState(() => _linkedExamId = v),
              ),
            ],
            if (!_isNew) ...[
              const SizedBox(height: 12),
              SwitchListTile(
                title: Text(context.l10n.sectionDone),
                value: widget.existing!.task.isDone,
                onChanged: _setDone,
              ),
            ],
            if (!_isNew && _type == TaskKind.exam) ...[
              const Divider(height: 32),
              Text(context.l10n.resultSection, style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              ExamResultSection(examTaskId: widget.existing!.task.id),
            ],
            const Divider(height: 32),
            Text(context.l10n.stepsSection, style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            if (_isNew)
              _PendingSubtasks(
                titles: _pendingSubtasks,
                input: _subtaskInput,
                onChanged: () => setState(() {}),
              )
            else
              _StoredSubtasks(taskId: widget.existing!.task.id),
            const Divider(height: 32),
            Text(context.l10n.remindersSection, style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            if (_isNew)
              _PendingReminders(
                offsets: _pendingReminders,
                onChanged: () => setState(() {}),
              )
            else
              _StoredReminders(taskId: widget.existing!.task.id),
            const SizedBox(height: 24),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  _error!,
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ),
            FilledButton.icon(
              onPressed: _busy ? null : _save,
              icon: const Icon(Icons.check),
              label: Text(context.l10n.saveTask),
            ),
          ],
        ),
      ),
    );
  }
}

class _DateButton extends StatelessWidget {
  final String label;
  final String text;
  final VoidCallback? onPick;
  final VoidCallback? onClear;

  const _DateButton({
    required this.label,
    required this.text,
    required this.onPick,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: onClear == null
            ? const Icon(Icons.calendar_today, size: 18)
            : IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: onClear,
              ),
      ),
      child: InkWell(onTap: onPick, child: Text(text)),
    );
  }
}

class _PendingSubtasks extends StatelessWidget {
  final List<String> titles;
  final TextEditingController input;
  final VoidCallback onChanged;

  const _PendingSubtasks({
    required this.titles,
    required this.input,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < titles.length; i++)
          ListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            title: Text(titles[i]),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () {
                titles.removeAt(i);
                onChanged();
              },
            ),
          ),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: input,
                decoration: InputDecoration(labelText: context.l10n.newStep),
                onFieldSubmitted: (_) {
                  if (input.text.trim().isNotEmpty) {
                    titles.add(input.text.trim());
                    input.clear();
                    onChanged();
                  }
                },
              ),
            ),
            IconButton(
              tooltip: context.l10n.addStep,
              icon: const Icon(Icons.add),
              onPressed: () {
                if (input.text.trim().isNotEmpty) {
                  titles.add(input.text.trim());
                  input.clear();
                  onChanged();
                }
              },
            ),
          ],
        ),
      ],
    );
  }
}

class _StoredSubtasks extends ConsumerWidget {
  final int taskId;

  const _StoredSubtasks({required this.taskId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subtasks = ref.watch(subtasksForTaskProvider(taskId));

    return subtasks.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Text(context.l10n.couldNotLoadSteps('$e')),
      data: (list) => Column(
        children: [
          for (final s in list)
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              controlAffinity: ListTileControlAffinity.leading,
              value: s.isDone,
              title: Text(
                s.title,
                style: s.isDone
                    ? const TextStyle(decoration: TextDecoration.lineThrough)
                    : null,
              ),
              secondary: IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () =>
                    ref.read(taskRepositoryProvider).deleteSubtask(s.id),
              ),
              onChanged: (v) => ref
                  .read(taskRepositoryProvider)
                  .updateSubtask(s.copyWith(isDone: v ?? false)),
            ),
          _SubtaskAdder(taskId: taskId),
        ],
      ),
    );
  }
}

class _SubtaskAdder extends ConsumerStatefulWidget {
  final int taskId;

  const _SubtaskAdder({required this.taskId});

  @override
  ConsumerState<_SubtaskAdder> createState() => _SubtaskAdderState();
}

class _SubtaskAdderState extends ConsumerState<_SubtaskAdder> {
  final _input = TextEditingController();

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    final text = _input.text.trim();
    if (text.isEmpty) return;
    final existing =
        ref.read(subtasksForTaskProvider(widget.taskId)).value ?? const [];
    await ref
        .read(taskRepositoryProvider)
        .createSubtask(
          SubtasksCompanion.insert(
            taskId: widget.taskId,
            title: text,
            position: Value(existing.length),
          ),
        );
    _input.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: _input,
            decoration: InputDecoration(labelText: context.l10n.newStep),
            onFieldSubmitted: (_) => _add(),
          ),
        ),
        IconButton(
          tooltip: context.l10n.addStep,
          icon: const Icon(Icons.add),
          onPressed: _add,
        ),
      ],
    );
  }
}

class _PendingReminders extends StatelessWidget {
  final Set<int> offsets;
  final VoidCallback onChanged;

  const _PendingReminders({required this.offsets, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return _ReminderPicker(
      offsets: offsets.toList()..sort(),
      onAdd: (m) {
        offsets.add(m);
        onChanged();
      },
      onRemove: (m) {
        offsets.remove(m);
        onChanged();
      },
    );
  }
}

class _StoredReminders extends ConsumerWidget {
  final int taskId;

  const _StoredReminders({required this.taskId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reminders = ref.watch(remindersForTaskProvider(taskId));

    return reminders.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Text(context.l10n.couldNotLoadReminders('$e')),
      data: (list) => _ReminderPicker(
        offsets: [for (final r in list) r.offsetMinutes],
        onAdd: (m) => ref
            .read(taskRepositoryProvider)
            .createReminder(
              TaskRemindersCompanion.insert(
                taskId: taskId,
                offsetMinutes: Value(m),
              ),
            )
            .then(
              (_) => ref.read(reminderSchedulerProvider).refreshTask(taskId),
            ),
        onRemove: (m) async {
          final match = list.where((r) => r.offsetMinutes == m);
          for (final r in match) {
            await ref.read(taskRepositoryProvider).deleteReminder(r.id);
          }
          await ref.read(reminderSchedulerProvider).refreshTask(taskId);
        },
      ),
    );
  }
}

class _ReminderPicker extends StatelessWidget {
  final List<int> offsets;
  final ValueChanged<int> onAdd;
  final ValueChanged<int> onRemove;

  const _ReminderPicker({
    required this.offsets,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (offsets.isEmpty)
          Text(
            context.l10n.noRemindersHint,
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: Theme.of(context).colorScheme.outline),
          )
        else
          for (final m in offsets)
            ListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              leading: const Icon(Icons.notifications_outlined),
              title: Text(formatReminderOffset(context.l10n, m)),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () => onRemove(m),
              ),
            ),
        Wrap(
          spacing: 8,
          children: [
            for (final minutes in _reminderPresetMinutes)
              if (!offsets.contains(minutes))
                ActionChip(
                  label: Text(formatReminderOffset(context.l10n, minutes)),
                  onPressed: () => onAdd(minutes),
                ),
          ],
        ),
      ],
    );
  }
}

/// Picker for the exam a revision task prepares for.
class _ExamLinkDropdown extends ConsumerWidget {
  final int? value;
  final int? excludeTaskId;
  final ValueChanged<int?> onChanged;

  const _ExamLinkDropdown({
    required this.value,
    required this.excludeTaskId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(tasksStreamProvider);
    return tasks.when(
      loading: () => const SizedBox.shrink(),
      error: (e, _) => Text(context.l10n.couldNotLoadExams('$e')),
      data: (list) {
        final exams = list
            .where((t) => t.task.type == TaskKind.exam && !t.task.isDone)
            .toList();
        if (value != null && exams.every((t) => t.task.id != value)) {
          exams.addAll(list.where((t) => t.task.id == value));
        }
        if (excludeTaskId != null) {
          exams.removeWhere((t) => t.task.id == excludeTaskId);
        }
        return DropdownButtonFormField<int?>(
          initialValue: value,
          decoration: InputDecoration(labelText: context.l10n.preparesForExam),
          items: [
            DropdownMenuItem(value: null, child: Text(context.l10n.noExam)),
            for (final t in exams)
              DropdownMenuItem(value: t.task.id, child: Text(t.task.title)),
          ],
          onChanged: onChanged,
        );
      },
    );
  }
}

/// Result entry for an exam task.
class ExamResultSection extends ConsumerStatefulWidget {
  final int examTaskId;

  const ExamResultSection({super.key, required this.examTaskId});

  @override
  ConsumerState<ExamResultSection> createState() => _ExamResultSectionState();
}

class _ExamResultSectionState extends ConsumerState<ExamResultSection> {
  final _score = TextEditingController();
  final _max = TextEditingController(text: '100');
  bool _initialized = false;
  bool _busy = false;

  @override
  void dispose() {
    _score.dispose();
    _max.dispose();
    super.dispose();
  }

  Future<void> _save(Grade? current) async {
    final score = double.tryParse(_score.text.trim().replaceAll(',', '.'));
    final max = double.tryParse(_max.text.trim().replaceAll(',', '.'));
    if (score == null || max == null || max <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.enterValidScore)),
      );
      return;
    }
    setState(() => _busy = true);
    try {
      final repo = ref.read(gradeRepositoryProvider);
      final now = DateTime.now();
      if (current == null) {
        await repo.record(
          GradesCompanion.insert(
            examTaskId: widget.examTaskId,
            score: score,
            maxScore: Value(max),
            date:
                '${now.year.toString().padLeft(4, '0')}-'
                '${now.month.toString().padLeft(2, '0')}-'
                '${now.day.toString().padLeft(2, '0')}',
          ),
        );
      } else {
        await repo.update(current.copyWith(score: score, maxScore: max));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(context.l10n.couldNotSaveGrade('$e'))));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final grade = ref.watch(gradeForExamProvider(widget.examTaskId));
    return grade.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Text(context.l10n.couldNotLoadGrade('$e')),
      data: (current) {
        if (!_initialized && current != null) {
          _initialized = true;
          // Defer: writing controllers during build would mark the
          // enclosing Form dirty mid-build.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            _score.text = current.score.toString();
            _max.text = current.maxScore.toString();
          });
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (current != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  context.l10n.resultScore(current.score, current.maxScore),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _score,
                    decoration: InputDecoration(labelText: context.l10n.scoreLabel),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _max,
                    decoration: InputDecoration(labelText: context.l10n.outOfLabel),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: _busy ? null : () => _save(current),
                  child: Text(context.l10n.save),
                ),
                if (current != null)
                  IconButton(
                    tooltip: context.l10n.deleteGradeTooltip,
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () =>
                        ref.read(gradeRepositoryProvider).delete(current.id),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }
}
