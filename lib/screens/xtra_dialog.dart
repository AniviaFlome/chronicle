import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database.dart';
import '../providers.dart';
import '../theme.dart';
import '../l10n/l10n.dart';
import '../utils/time_format.dart';

/// Add/edit dialog for one Xtra event. Returns true when saved.
Future<bool> showXtraDialog(
  BuildContext context,
  WidgetRef ref, {
  XtraEvent? existing,
  DateTime? initialDate,
}) {
  return showDialog<bool>(
    context: context,
    builder: (_) => _XtraDialog(existing: existing, initialDate: initialDate),
  ).then((v) => v ?? false);
}

class _XtraDialog extends ConsumerStatefulWidget {
  final XtraEvent? existing;
  final DateTime? initialDate;

  const _XtraDialog({this.existing, this.initialDate});

  @override
  ConsumerState<_XtraDialog> createState() => _XtraDialogState();
}

class _XtraDialogState extends ConsumerState<_XtraDialog> {
  late final TextEditingController _title;
  late final TextEditingController _location;
  late final TextEditingController _notes;
  DateTime? _date;
  TimeOfDay? _start;
  TimeOfDay? _end;
  bool _busy = false;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _title = TextEditingController(text: e?.title ?? '');
    _location = TextEditingController(text: e?.location ?? '');
    _notes = TextEditingController(text: e?.notes ?? '');
    _date = e == null ? null : DateTime.tryParse(e.date) ?? widget.initialDate;
    _date ??= widget.initialDate ?? DateTime.now();
    if (e?.startMinutes != null) {
      _start = TimeOfDay(
        hour: e!.startMinutes! ~/ 60,
        minute: e.startMinutes! % 60,
      );
    }
    if (e?.endMinutes != null) {
      _end = TimeOfDay(hour: e!.endMinutes! ~/ 60, minute: e.endMinutes! % 60);
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _location.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? now,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null && mounted) setState(() => _date = picked);
  }

  Future<void> _pickTime({required bool isStart}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime:
          (isStart ? _start : _end) ?? const TimeOfDay(hour: 9, minute: 0),
    );
    if (picked != null && mounted) {
      setState(() => isStart ? _start = picked : _end = picked);
    }
  }

  Future<void> _save() async {
    if (_busy || !_formKey.currentState!.validate() || _date == null) return;
    final startM = _start == null ? null : _start!.hour * 60 + _start!.minute;
    final endM = _end == null ? null : _end!.hour * 60 + _end!.minute;
    if (startM != null && endM != null && endM <= startM) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.endAfterStart)),
      );
      return;
    }
    setState(() => _busy = true);
    try {
      final repo = ref.read(xtraRepositoryProvider);
      String? text(String s) => s.trim().isEmpty ? null : s.trim();
      if (widget.existing == null) {
        await repo.create(
          XtraEventsCompanion.insert(
            title: _title.text.trim(),
            date: isoFromDateTime(_date!),
            startMinutes: Value(startM),
            endMinutes: Value(endM),
            location: Value(text(_location.text)),
            notes: Value(text(_notes.text)),
          ),
        );
      } else {
        final updated = await repo.update(
          widget.existing!.copyWith(
            title: _title.text.trim(),
            date: isoFromDateTime(_date!),
            startMinutes: Value(startM),
            endMinutes: Value(endM),
            location: Value(text(_location.text)),
            notes: Value(text(_notes.text)),
          ),
        );
        if (!updated) throw StateError('Event no longer exists');
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(context.l10n.couldNotSaveEvent('$e'))));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete() async {
    if (_busy || widget.existing == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(context.l10n.deleteEventTitle),
        content: Text(context.l10n.deleteEventBody(widget.existing!.title)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(c).pop(false),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(c).pop(true),
            child: Text(context.l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await ref.read(xtraRepositoryProvider).delete(widget.existing!.id);
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existing == null ? context.l10n.addEvent : context.l10n.editEvent),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _title,
                  decoration: InputDecoration(
                    labelText: context.l10n.eventTitleHint,
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? context.l10n.titleRequired
                      : null,
                  autofocus: true,
                ),
                const SizedBox(height: 12),
                InputDecorator(
                  decoration: InputDecoration(labelText: context.l10n.dateLabel),
                  child: InkWell(
                    onTap: _pickDate,
                    child: Text(
                      _date == null ? context.l10n.pickPlaceholder : isoFromDateTime(_date!),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: InputDecorator(
                        decoration: InputDecoration(labelText: context.l10n.startsLabel),
                        child: InkWell(
                          onTap: () => _pickTime(isStart: true),
                          child: Text(
                            _start == null
                                ? context.l10n.allDayLabel
                                : _start!.format(context),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InputDecorator(
                        decoration: InputDecoration(labelText: context.l10n.endsLabel),
                        child: InkWell(
                          onTap: _end == null && _start == null
                              ? null
                              : () => _pickTime(isStart: false),
                          child: Text(
                            _end == null ? '—' : _end!.format(context),
                          ),
                        ),
                      ),
                    ),
                    if (_start != null || _end != null)
                      IconButton(
                        tooltip: context.l10n.allDayLabel,
                        icon: const Icon(Icons.clear),
                        onPressed: () => setState(() {
                          _start = null;
                          _end = null;
                        }),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _location,
                  decoration: InputDecoration(labelText: context.l10n.locationLabel),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _notes,
                  decoration: InputDecoration(labelText: context.l10n.notesLabel),
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        if (widget.existing != null)
          TextButton(onPressed: _delete, child: Text(context.l10n.delete)),
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(context.l10n.cancel),
        ),
        FilledButton(
          onPressed: _busy ? null : _save,
          child: Text(context.l10n.save),
        ),
      ],
    );
  }
}

/// Compact tile for an Xtra event in day lists.
class XtraTile extends StatelessWidget {
  final XtraEvent event;
  final VoidCallback? onTap;

  const XtraTile({super.key, required this.event, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 6,
                color: classAccentColor(
                  theme.colorScheme,
                  Color(event.colorValue),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(event.title, style: theme.textTheme.titleSmall),
                      const SizedBox(height: 2),
                      Text(
                        [
                          if (event.startMinutes != null)
                            hhmm(event.startMinutes!),
                          if (event.location != null &&
                              event.location!.isNotEmpty)
                            event.location!,
                        ].join(' · '),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(right: 12),
                child: Icon(Icons.sports_soccer_outlined),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
