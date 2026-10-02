import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database.dart';
import '../l10n/l10n.dart';
import '../providers.dart';
import '../theme.dart';
import 'error_dialog.dart';

/// Opens the quick-edit sheet for one class: color dots plus room, teacher,
/// reminder minutes and the generic notes line. Long-pressing any class tile (calendar list,
/// calendar grid, dashboard) lands here; the full editor stays on
/// [ClassEditScreen], reachable from the occurrence sheet.
Future<void> showClassQuickEditSheet(
  BuildContext context,
  ClassesData classRow,
) {
  return showModalBottomSheet(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => _ClassQuickEditSheet(classRow: classRow),
  );
}

class _ClassQuickEditSheet extends ConsumerStatefulWidget {
  final ClassesData classRow;

  const _ClassQuickEditSheet({required this.classRow});

  @override
  ConsumerState<_ClassQuickEditSheet> createState() =>
      _ClassQuickEditSheetState();
}

class _ClassQuickEditSheetState extends ConsumerState<_ClassQuickEditSheet> {
  late int _color;
  late final TextEditingController _room;
  late final TextEditingController _teacher;
  late final TextEditingController _reminder;
  late final TextEditingController _notes;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final row = widget.classRow;
    _color = row.colorValue;
    _room = TextEditingController(text: row.room ?? '');
    _teacher = TextEditingController(text: row.teacher ?? '');
    _reminder = TextEditingController(
      text: row.reminderMinutes?.toString() ?? '',
    );
    _notes = TextEditingController(text: row.notes ?? '');
  }

  @override
  void dispose() {
    _room.dispose();
    _teacher.dispose();
    _reminder.dispose();
    _notes.dispose();
    super.dispose();
  }

  String? _emptyToNull(String s) => s.trim().isEmpty ? null : s.trim();

  /// Every color offered: base palette plus current theme accents, same
  /// source as the full class editor.
  List<int> _pickerColors() {
    final themeId = ref.watch(appThemeProvider).value ?? defaultAppTheme;
    final accents = lookupAppTheme(themeId).accents.values;
    return [
      ...classColorPalette,
      for (final v in accents) if (!classColorPalette.contains(v)) v,
    ];
  }

  Future<ClassesData?> _freshRow() =>
      ref.read(classRepositoryProvider).byIdOrNull(widget.classRow.id);

  Future<void> _saveColor(int value) async {
    if (_busy || value == _color) return;
    setState(() {
      _busy = true;
      _color = value;
    });
    try {
      final row = await _freshRow();
      if (row == null) throw StateError('Class no longer exists');
      final updated = await ref
          .read(classRepositoryProvider)
          .update(row.copyWith(colorValue: value));
      if (!updated) throw StateError('Class no longer exists');
      ref.invalidate(engineProvider);
      ref.invalidate(classesByIdProvider);
    } catch (e) {
      if (mounted) {
        await showErrorDialog(
          context,
          title: context.l10n.errorSaveClass,
          error: e,
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _saveFields() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final row = await _freshRow();
      if (row == null) throw StateError('Class no longer exists');
      final updated = await ref
          .read(classRepositoryProvider)
          .update(
            row.copyWith(
              room: Value(_emptyToNull(_room.text)),
              teacher: Value(_emptyToNull(_teacher.text)),
              reminderMinutes: Value(int.tryParse(_reminder.text.trim())),
              notes: Value(_emptyToNull(_notes.text)),
            ),
          );
      if (!updated) throw StateError('Class no longer exists');
      if (!mounted) return;
      ref.invalidate(engineProvider);
      ref.invalidate(classesByIdProvider);
      await ref.read(reminderSchedulerProvider).refreshClassReminders();
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        await showErrorDialog(
          context,
          title: context.l10n.errorSaveClass,
          error: e,
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = _pickerColors();
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.classRow.name,
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              Text(
                context.l10n.colorLabel,
                style: theme.textTheme.labelLarge,
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final value in colors)
                    _ColorDot(
                      value: value,
                      selected: _color == value,
                      onTap: _busy ? null : () => _saveColor(value),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _room,
                decoration: InputDecoration(
                  labelText: context.l10n.roomLabel,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _teacher,
                decoration: InputDecoration(
                  labelText: context.l10n.teacherLabel,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _reminder,
                decoration: InputDecoration(
                  labelText: context.l10n.classReminderLabel,
                  hintText: context.l10n.classReminderHint,
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 8),
              // Generic custom text (class code, section, anything).
              TextField(
                controller: _notes,
                decoration: InputDecoration(
                  labelText: context.l10n.notesFieldLabel,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _busy ? null : _saveFields,
                  child: Text(context.l10n.save),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ColorDot extends StatelessWidget {
  final int value;
  final bool selected;
  final VoidCallback? onTap;

  const _ColorDot({
    required this.value,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: classAccentColor(theme.colorScheme, Color(value)),
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? theme.colorScheme.onSurface : Colors.transparent,
            width: 2,
          ),
        ),
        child: selected
            ? Icon(Icons.check, size: 18, color: theme.colorScheme.surface)
            : null,
      ),
    );
  }
}
