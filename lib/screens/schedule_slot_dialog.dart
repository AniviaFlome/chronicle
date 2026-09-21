import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';

import '../data/database.dart';
import '../data/schedule_repository.dart';
import '../data/tables.dart';
import '../domain/schedule_models.dart' as engine;
import '../l10n/l10n.dart';
import '../utils/time_format.dart';

/// In-memory meeting-time data collected by [ScheduleSlotDialog].
///
/// Callers persist it: for saved classes via [ClassRepository], for new
/// classes together with the class row in one transaction.
class SlotDraft {
  final int dayOfWeek;
  final int startMinutes;
  final int endMinutes;
  final String? room;
  final RotationKind rotation;
  final WeekParity? weekParity;
  final int? cycleLength;
  final String? cycleWeeks;
  final String? rotationDays;

  const SlotDraft({
    required this.dayOfWeek,
    required this.startMinutes,
    required this.endMinutes,
    this.room,
    this.rotation = RotationKind.weekly,
    this.weekParity,
    this.cycleLength,
    this.cycleWeeks,
    this.rotationDays,
  });

  factory SlotDraft.fromItem(ScheduleItem item) => SlotDraft(
    dayOfWeek: item.dayOfWeek,
    startMinutes: item.startMinutes,
    endMinutes: item.endMinutes,
    room: item.room,
    rotation: item.rotation,
    weekParity: item.weekParity,
    cycleLength: item.cycleLength,
    cycleWeeks: item.cycleWeeks,
    rotationDays: item.rotationDays,
  );

  ScheduleItemsCompanion toCompanion(int classId) =>
      ScheduleItemsCompanion.insert(
        classId: classId,
        dayOfWeek: dayOfWeek,
        startMinutes: startMinutes,
        endMinutes: endMinutes,
        room: Value(room),
        rotation: rotation,
        weekParity: Value(weekParity),
        cycleLength: Value(cycleLength),
        cycleWeeks: Value(cycleWeeks),
        rotationDays: Value(rotationDays),
      );

}

/// Localized rotation summary for a [SlotDraft] (the model itself carries
/// no locale, so labels resolve at the call site).
String slotRotationLabel(AppLocalizations l10n, SlotDraft draft) =>
    switch (draft.rotation) {
      RotationKind.weekly => l10n.everyWeek,
      RotationKind.weekAb => l10n.weekABLabel(
        draft.weekParity == WeekParity.a ? 'A' : 'B',
      ),
      RotationKind.custom => l10n.customCycleSummary(
        draft.cycleLength ?? 0,
        draft.cycleWeeks ?? '',
      ),
      RotationKind.dayRotation => l10n.rotationDaysSummary(
        draft.rotationDays ?? '',
      ),
    };

/// Dialog to add/edit one schedule slot (weekly pattern entry).
///
/// Returns the collected [SlotDraft] on save, null on cancel. It never
/// touches the database itself so it works for unsaved classes too.
class ScheduleSlotDialog extends StatefulWidget {
  final SlotDraft? initial;

  /// True when editing an existing slot (changes the title only).
  final bool isEdit;

  /// Day-rotation info from the class's academic year. When null, the day
  /// rotation option is hidden.
  final int? dayRotationLength;
  final bool dayRotationLetters;

  /// Default duration in minutes used to auto-set the end time when the
  /// start time changes. Null disables the behavior.
  final int? autoEndMinutes;

  const ScheduleSlotDialog({
    super.key,
    this.initial,
    this.isEdit = false,
    this.dayRotationLength,
    this.dayRotationLetters = false,
    this.autoEndMinutes,
  });

  @override
  State<ScheduleSlotDialog> createState() => _ScheduleSlotDialogState();
}

class _ScheduleSlotDialogState extends State<ScheduleSlotDialog> {
  int _dayOfWeek = 1;
  TimeOfDay _start = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _end = const TimeOfDay(hour: 10, minute: 0);
  final _room = TextEditingController();
  RotationKind _rotation = RotationKind.weekly;
  WeekParity _parity = WeekParity.a;
  int _cycleLength = 2;
  final Set<int> _cycleWeeks = {1};
  final Set<int> _rotationDays = {1};

  bool get _isEdit => widget.isEdit;

  @override
  void initState() {
    super.initState();
    final e = widget.initial;
    if (e != null) {
      _dayOfWeek = e.dayOfWeek;
      _start = TimeOfDay(
        hour: e.startMinutes ~/ 60,
        minute: e.startMinutes % 60,
      );
      _end = TimeOfDay(hour: e.endMinutes ~/ 60, minute: e.endMinutes % 60);
      _room.text = e.room ?? '';
      _rotation = e.rotation;
      if (e.weekParity != null) _parity = e.weekParity!;
      if (e.cycleLength != null) _cycleLength = e.cycleLength!;
      if (e.cycleWeeks != null) {
        _cycleWeeks
          ..clear()
          ..addAll(decodeCycleWeeks(e.cycleWeeks!));
      }
      if (e.rotationDays != null) {
        _rotationDays
          ..clear()
          ..addAll(decodeIntList(e.rotationDays!));
      }
      if (e.rotation == RotationKind.dayRotation &&
          (widget.dayRotationLength == null ||
              _rotationDays.any((d) => d > widget.dayRotationLength!))) {
        _rotationDays
          ..clear()
          ..add(1);
      }
      if (e.rotation == RotationKind.dayRotation &&
          widget.dayRotationLength == null) {
        _rotation = RotationKind.weekly;
      }
    }
  }

  @override
  void dispose() {
    _room.dispose();
    super.dispose();
  }

  Future<void> _pickTime({required bool isStart}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _start : _end,
    );
    if (picked == null || !mounted) return;
    final autoEnd = widget.autoEndMinutes;
    setState(() {
      if (isStart) {
        _start = picked;
        if (autoEnd != null) {
          final m = (picked.hour * 60 + picked.minute + autoEnd).clamp(1, 1439);
          _end = TimeOfDay(hour: m ~/ 60, minute: m % 60);
        }
      } else {
        _end = picked;
      }
    });
  }

  void _save() {
    final startM = _start.hour * 60 + _start.minute;
    final endM = _end.hour * 60 + _end.minute;
    if (endM <= startM) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.endAfterStart)),
      );
      return;
    }
    if (_rotation == RotationKind.custom && _cycleWeeks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.selectCycleWeek)),
      );
      return;
    }
    if (_rotation == RotationKind.dayRotation && _rotationDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.selectRotationDay)),
      );
      return;
    }
    Navigator.of(context).pop(
      SlotDraft(
        dayOfWeek: _dayOfWeek,
        startMinutes: startM,
        endMinutes: endM,
        room: _room.text.trim().isEmpty ? null : _room.text.trim(),
        rotation: _rotation,
        weekParity: _rotation == RotationKind.weekAb ? _parity : null,
        cycleLength: _rotation == RotationKind.custom ? _cycleLength : null,
        cycleWeeks: _rotation == RotationKind.custom
            ? encodeCycleWeeks(_cycleWeeks.toList()..sort())
            : null,
        rotationDays: _rotation == RotationKind.dayRotation
            ? encodeIntList(_rotationDays.toList()..sort())
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEdit ? context.l10n.editSlot : context.l10n.addSlot),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<int>(
                initialValue: _dayOfWeek,
                decoration: InputDecoration(labelText: context.l10n.dayLabel),
                items: [
                  DropdownMenuItem(value: 1, child: Text(fullWeekdayName(1, context.l10n.localeName))),
                  DropdownMenuItem(value: 2, child: Text(fullWeekdayName(2, context.l10n.localeName))),
                  DropdownMenuItem(value: 3, child: Text(fullWeekdayName(3, context.l10n.localeName))),
                  DropdownMenuItem(value: 4, child: Text(fullWeekdayName(4, context.l10n.localeName))),
                  DropdownMenuItem(value: 5, child: Text(fullWeekdayName(5, context.l10n.localeName))),
                  DropdownMenuItem(value: 6, child: Text(fullWeekdayName(6, context.l10n.localeName))),
                  DropdownMenuItem(value: 7, child: Text(fullWeekdayName(7, context.l10n.localeName))),
                ],
                onChanged: (v) => setState(() => _dayOfWeek = v!),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _TimeField(
                      label: context.l10n.startTimeLabel,
                      time: _start,
                      onTap: () => _pickTime(isStart: true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _TimeField(
                      label: context.l10n.endTimeLabel,
                      time: _end,
                      onTap: () => _pickTime(isStart: false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _room,
                decoration: InputDecoration(
                  labelText: context.l10n.roomOverrideHint,
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<RotationKind>(
                initialValue: _rotation,
                isExpanded: true,
                decoration: InputDecoration(labelText: context.l10n.repeatsLabel),
                items: [
                  DropdownMenuItem(
                    value: RotationKind.weekly,
                    child: Text(context.l10n.everyWeek),
                  ),
                  DropdownMenuItem(
                    value: RotationKind.weekAb,
                    child: Text(context.l10n.weekAbRotation),
                  ),
                  DropdownMenuItem(
                    value: RotationKind.custom,
                    child: Text(context.l10n.customCycle),
                  ),
                  if (widget.dayRotationLength != null)
                    DropdownMenuItem(
                      value: RotationKind.dayRotation,
                      child: Text(context.l10n.dayRotationLabel),
                    ),
                ],
                onChanged: (v) => setState(() => _rotation = v!),
              ),
              if (_rotation == RotationKind.weekAb)
                RadioGroup<WeekParity>(
                  groupValue: _parity,
                  onChanged: (v) => setState(() => _parity = v!),
                  child: Row(
                    children: [
                      Expanded(
                        child: RadioListTile<WeekParity>(
                          title: Text(context.l10n.weekA),
                          value: WeekParity.a,
                        ),
                      ),
                      Expanded(
                        child: RadioListTile<WeekParity>(
                          title: Text(context.l10n.weekB),
                          value: WeekParity.b,
                        ),
                      ),
                    ],
                  ),
                ),
              if (_rotation == RotationKind.custom) ...[
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  initialValue: _cycleLength,
                  decoration: InputDecoration(
                    labelText: context.l10n.cycleLengthLabel,
                  ),
                  items: [
                    for (final n in [2, 3, 4])
                      DropdownMenuItem(value: n, child: Text(context.l10n.weeksCount(n))),
                  ],
                  onChanged: (v) => setState(() {
                    _cycleLength = v!;
                    _cycleWeeks.removeWhere((w) => w > v);
                  }),
                ),
                const SizedBox(height: 12),
                Text(
                  context.l10n.classesOnWeeks,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                Wrap(
                  spacing: 8,
                  children: [
                    for (var w = 1; w <= _cycleLength; w++)
                      FilterChip(
                        label: Text('${context.l10n.weekPrefix}$w'),
                        selected: _cycleWeeks.contains(w),
                        onSelected: (sel) => setState(() {
                          sel ? _cycleWeeks.add(w) : _cycleWeeks.remove(w);
                        }),
                      ),
                  ],
                ),
              ],
              if (_rotation == RotationKind.dayRotation &&
                  widget.dayRotationLength != null) ...[
                const SizedBox(height: 12),
                Text(
                  context.l10n.meetsOnRotationDays,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                Wrap(
                  spacing: 8,
                  children: [
                    for (var d = 1; d <= widget.dayRotationLength!; d++)
                      FilterChip(
                        label: Text(
                          engine.rotationDayLabel(
                            d - 1,
                            letters: widget.dayRotationLetters,
                          ),
                        ),
                        selected: _rotationDays.contains(d),
                        onSelected: (sel) => setState(() {
                          sel ? _rotationDays.add(d) : _rotationDays.remove(d);
                        }),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.l10n.cancel),
        ),
        FilledButton(onPressed: _save, child: Text(context.l10n.save)),
      ],
    );
  }
}

class _TimeField extends StatelessWidget {
  final String label;
  final TimeOfDay time;
  final VoidCallback onTap;

  const _TimeField({
    this.label = 'Start',
    required this.time,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(labelText: label),
      child: InkWell(onTap: onTap, child: Text(time.format(context))),
    );
  }
}
