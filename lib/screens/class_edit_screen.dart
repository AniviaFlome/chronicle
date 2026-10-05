import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

import '../data/database.dart';
import '../l10n/l10n.dart';
import '../providers.dart';
import '../services/course_catalog/course_catalog.dart';
import '../services/course_catalog/itu_obs.dart';
import '../theme.dart';
import '../utils/time_format.dart';
import '../utils/ui_feedback.dart';
import 'attachment_panel.dart';
import 'error_dialog.dart';
import 'mark_absence_dialog.dart';
import 'schedule_slot_dialog.dart';
import 'year_widgets.dart';

class ClassEditScreen extends ConsumerStatefulWidget {
  final ClassesData? existing;

  const ClassEditScreen({super.key, this.existing});

  @override
  ConsumerState<ClassEditScreen> createState() => _ClassEditScreenState();
}

class _ClassEditScreenState extends ConsumerState<ClassEditScreen> {
  late final TextEditingController _name;
  late final TextEditingController _teacher;
  late final TextEditingController _email;
  late final TextEditingController _room;
  late final TextEditingController _building;
  late final TextEditingController _module;
  late final TextEditingController _onlineLink;
  late final TextEditingController _notes;
  late final TextEditingController _maxAbsences;
  late final TextEditingController _reminder;
  late final TextEditingController _courseCode;
  late int _color;
  bool _active = true;
  int? _yearId;
  bool _busy = false;

  bool _catalogBusy = false;
  String? _catalogError;

  /// Course-catalog source id ('' = none). Null while loading; the
  /// fetch button stays hidden until a source is picked in Settings.
  String? _catalogSource;

  /// Weekly slots taken from a picked catalog section. Only used when
  /// creating the class; while non-empty the manual meets-on/time
  /// controls are hidden and _save persists these instead.
  List<SlotDraft> _catalogSlots = const [];

  /// Weekdays (1 = Monday .. 7 = Sunday) the class meets on. Only used when
  /// creating the class; afterwards meeting times are managed per slot.
  final Set<int> _days = {DateTime.now().weekday};
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _name = TextEditingController(text: e?.name ?? '');
    _teacher = TextEditingController(text: e?.teacher ?? '');
    _email = TextEditingController(text: e?.teacherEmail ?? '');
    _room = TextEditingController(text: e?.room ?? '');
    _building = TextEditingController(text: e?.building ?? '');
    _module = TextEditingController(text: e?.module ?? '');
    _onlineLink = TextEditingController(text: e?.onlineLink ?? '');
    _notes = TextEditingController(text: e?.notes ?? '');
    _maxAbsences = TextEditingController(
      text: e?.maxAbsences?.toString() ?? '',
    );
    _reminder = TextEditingController(
      text: e?.reminderMinutes?.toString() ?? '',
    );
    _courseCode = TextEditingController();
    _color = e?.colorValue ?? classColorPalette.first;
    _active = e?.active ?? true;
    _yearId = e?.yearId;
    if (e == null) {
      _prefillDefaults();
    }
    _loadCatalogSource();
  }

  Future<void> _loadCatalogSource() async {
    try {
      final value = await ref.read(settingsRepositoryProvider).catalogSource();
      if (!mounted) return;
      setState(
        () => _catalogSource = catalogSourceIds.contains(value) ? value : '',
      );
    } catch (e) {
      logLoadFailure('Load catalog source', e);
    }
  }

  Future<void> _prefillDefaults() async {
    try {
      final repo = ref.read(settingsRepositoryProvider);
      final limit = await repo.defaultMaxAbsences();
      final activeYear = await repo.watchActiveYearId().first;
      if (!mounted) return;
      setState(() {
        if (limit != null && _maxAbsences.text.isEmpty) {
          _maxAbsences.text = limit.toString();
        }
        // Start/end times stay empty until the user picks them.
        // New classes join the currently selected year, if any.
        _yearId ??= activeYear;
      });
    } catch (e) {
      logLoadFailure('Prefill defaults', e);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _teacher.dispose();
    _email.dispose();
    _room.dispose();
    _building.dispose();
    _module.dispose();
    _onlineLink.dispose();
    _notes.dispose();
    _maxAbsences.dispose();
    _reminder.dispose();
    _courseCode.dispose();
    super.dispose();
  }

  Future<void> _pickTime({required bool isStart}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime:
          (isStart ? _startTime : _endTime) ?? _startTime ?? TimeOfDay.now(),
    );
    if (picked == null || !mounted) return;
    TimeOfDay? end = _endTime;
    if (isStart) {
      // Auto-set end = start + default duration when the option is on.
      try {
        final repo = ref.read(settingsRepositoryProvider);
        if (await repo.autoEndTime()) {
          final duration = await repo.defaultDurationMinutes();
          final m = (picked.hour * 60 + picked.minute + duration).clamp(
            1,
            1439,
          );
          end = TimeOfDay(hour: m ~/ 60, minute: m % 60);
        }
      } catch (e) {
        logLoadFailure('Auto end time', e);
      }
    }
    setState(() {
      if (isStart) {
        _startTime = picked;
        _endTime = end;
      } else {
        _endTime = picked;
      }
    });
  }

  Future<void> _pickCustomColor() async {
    var temp = Color(_color);
    final picked = await showDialog<Color>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(context.l10n.customColorTitle),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: temp,
            onColorChanged: (v) => temp = v,
            enableAlpha: false,
            displayThumbColor: true,
            portraitOnly: true,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(c).pop(),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(c).pop(temp),
            child: Text(context.l10n.save),
          ),
        ],
      ),
    );
    if (picked != null && mounted) setState(() => _color = picked.toARGB32());
  }

  /// Looks up the typed course code in the ITU catalog and fills the
  /// form. Results with sections open a section picker on new classes;
  /// the picked section also supplies the weekly slots.
  Future<void> _fetchCatalog() async {
    if (_catalogBusy || _catalogSource != 'itu') return;
    setState(() {
      _catalogBusy = true;
      _catalogError = null;
    });
    try {
      final result = await ItuObsCatalog().lookup(_courseCode.text);
      if (!mounted) return;
      _applyCourse(result.course);
      CourseSection? picked;
      if (widget.existing == null && result.sections.isNotEmpty) {
        picked = await _pickSection(result.sections);
        if (!mounted) return;
      }
      if (picked != null) _applySection(picked);
    } catch (e) {
      logLoadFailure('Fetch course details', e);
      if (mounted) {
        setState(
          () => _catalogError = e is CourseLookupException &&
                  e.failure == CourseLookupFailure.crnNotSupported
              ? context.l10n.catalogCrnHint
              : context.l10n.catalogNotFound,
        );
      }
    } finally {
      if (mounted) setState(() => _catalogBusy = false);
    }
  }

  /// Fills empty fields from a catalog course; never overwrites what the
  /// user already typed. Catalog facts append to notes (once per code).
  void _applyCourse(CatalogCourse course) {
    final l10n = context.l10n;
    final name = l10n.localeName.startsWith('tr')
        ? course.name
        : (course.nameAlt ?? course.name);
    final facts = [
      course.code,
      if (course.credits != null) 'Kredi: ${_trimNum(course.credits!)}',
      if (course.ects != null) 'AKTS: ${_trimNum(course.ects!)}',
      if (course.language != null) course.language!,
      if (course.department != null) course.department!,
      if (course.type != null) course.type!,
    ].join(' · ');
    setState(() {
      if (_name.text.trim().isEmpty) _name.text = name;
      if (facts.isNotEmpty && !_notes.text.contains(course.code)) {
        _notes.text = _notes.text.trim().isEmpty
            ? facts
            : '${_notes.text.trim()}\n$facts';
      }
      _catalogError = null;
    });
  }

  String _trimNum(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toString();

  void _applySection(CourseSection section) {
    final facts = [
      'CRN ${section.crn}',
      if (section.method != null) section.method!,
      if (section.quota != null)
        'Kontenjan: ${section.quota}'
        '${section.enrolled != null ? ' · Yazılan: ${section.enrolled}' : ''}',
      if (section.prerequisites != null)
        'Önşart: ${section.prerequisites}',
    ].join(' · ');
    setState(() {
      if (_teacher.text.trim().isEmpty && section.instructor.isNotEmpty) {
        _teacher.text = section.instructor;
      }
      if (_room.text.trim().isEmpty && section.room.isNotEmpty) {
        _room.text = section.room;
      }
      if (_building.text.trim().isEmpty && section.building.isNotEmpty) {
        _building.text = section.building;
      }
      if (facts.isNotEmpty && !_notes.text.contains('CRN ${section.crn}')) {
        _notes.text = _notes.text.trim().isEmpty
            ? facts
            : '${_notes.text.trim()}\n$facts';
      }
      _catalogSlots = [
        for (final s in section.slots)
          SlotDraft(
            dayOfWeek: s.weekday,
            startMinutes: s.startMinutes,
            endMinutes: s.endMinutes,
            room: s.room.isEmpty ? null : s.room,
          ),
      ];
    });
  }

  String _fmtMinutes(int m) =>
      TimeOfDay(hour: m ~/ 60, minute: m % 60).format(context);

  /// Lets the user choose one of the course's weekly sections (ITU).
  Future<CourseSection?> _pickSection(List<CourseSection> sections) {
    final l10n = context.l10n;
    final rows = [
      for (final s in sections)
        (
          title: s.instructor.isEmpty ? s.code : s.instructor,
          subtitle: [
            [
              for (final slot in s.slots)
                '${shortWeekdayName(slot.weekday, l10n.localeName)} '
                    '${_fmtMinutes(slot.startMinutes)}–'
                    '${_fmtMinutes(slot.endMinutes)}',
            ].join(', '),
            [
              if (s.room.isNotEmpty) s.room,
              'CRN ${s.crn}',
            ].join(' · '),
          ].join('\n'),
        ),
    ];
    return showDialog<CourseSection>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(l10n.catalogSectionTitle),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: sections.length,
            itemBuilder: (_, i) => ListTile(
              title: Text(rows[i].title),
              subtitle: Text(rows[i].subtitle),
              onTap: () => Navigator.of(c).pop(sections[i]),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(c).pop(),
            child: Text(l10n.cancel),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    if (_busy || !_formKey.currentState!.validate()) return;
    final repo = ref.read(classRepositoryProvider);

    // Meeting times for a new class: catalog section slots win when the
    // user picked one, otherwise one weekly slot per selected weekday.
    List<SlotDraft> newSlots = const [];
    if (widget.existing == null) {
      if (_catalogSlots.isNotEmpty) {
        newSlots = _catalogSlots;
      } else {
      if (_days.isEmpty) {
        showErrorSnack(context, context.l10n.selectWeekday);
        return;
      }
      if (_startTime == null || _endTime == null) {
        showErrorSnack(context, context.l10n.selectTimes);
        return;
      }
      final startM = _startTime!.hour * 60 + _startTime!.minute;
      final endM = _endTime!.hour * 60 + _endTime!.minute;
      if (endM <= startM) {
        showErrorSnack(context, context.l10n.endAfterStart);
        return;
      }
      newSlots = [
        for (final d in _days.toList()..sort())
          SlotDraft(dayOfWeek: d, startMinutes: startM, endMinutes: endM),
      ];
      }
    }

    final entry = ClassesCompanion.insert(
      name: _name.text.trim(),
      colorValue: _color,
      teacher: Value(_emptyToNull(_teacher.text)),
      teacherEmail: Value(_emptyToNull(_email.text)),
      room: Value(_emptyToNull(_room.text)),
      building: Value(_emptyToNull(_building.text)),
      module: Value(_emptyToNull(_module.text)),
      onlineLink: Value(_emptyToNull(_onlineLink.text)),
      notes: Value(_emptyToNull(_notes.text)),
      maxAbsences: Value(int.tryParse(_maxAbsences.text.trim())),
      // Per-kind quotas were dropped: keep those columns cleared so no
      // stale split limits linger.
      maxAbsencesTheory: const Value(null),
      maxAbsencesPractical: const Value(null),
      reminderMinutes: Value(int.tryParse(_reminder.text.trim())),
      yearId: Value(_yearId),
      active: Value(_active),
    );

    setState(() {
      _busy = true;
    });
    try {
      if (widget.existing == null) {
        await repo.createClassWithSlots(entry, [
          for (final draft in newSlots) draft.toCompanion(0),
        ]);
      } else {
        final updated = await repo.update(
          widget.existing!.copyWithCompanion(entry),
        );
        if (!updated) throw StateError('Class no longer exists');
      }
      if (!mounted) return;
      ref.invalidate(engineProvider);
      ref.invalidate(classesByIdProvider);
      await ref.read(reminderSchedulerProvider).refreshClassReminders();
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      logLoadFailure('Save class', e);
      if (mounted) {
        await showErrorDialog(context, title: context.l10n.errorSaveClass, error: e);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete() async {
    if (_busy || widget.existing == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.deleteClassTitle),
        content: Text(
          context.l10n.deleteClassBody(widget.existing!.name),
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
    });
    try {
      await ref.read(classRepositoryProvider).delete(widget.existing!.id);
      if (!mounted) return;
      ref.invalidate(engineProvider);
      ref.invalidate(classesByIdProvider);
      await ref.read(reminderSchedulerProvider).refreshClassReminders();
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      logLoadFailure('Delete class', e);
      if (mounted) {
        await showErrorDialog(
          context,
          title: context.l10n.errorDeleteClass,
          error: e,
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String? _emptyToNull(String s) => s.trim().isEmpty ? null : s.trim();

  /// Accents of the currently selected theme family, excluding ones already
  /// in the base palette. The class color picker follows the active theme.
  List<int> _themeAccents() {
    final themeId = ref.watch(appThemeProvider).value ?? defaultAppTheme;
    final accents = lookupAppTheme(themeId).accents.values;
    return [for (final v in accents) if (!classColorPalette.contains(v)) v];
  }

  /// Every color offered in the picker: base palette plus current theme.
  List<int> _pickerColors() => [...classColorPalette, ..._themeAccents()];

  @override
  Widget build(BuildContext context) {
    final pickerColors = _pickerColors();
    final isCustomColor = !pickerColors.contains(_color);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existing == null ? context.l10n.addClass : context.l10n.editClass),
        actions: [
          if (widget.existing != null)
            IconButton(
              tooltip: context.l10n.deleteClassTooltip,
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
              controller: _name,
              decoration: InputDecoration(labelText: context.l10n.classNameLabel),
              validator: (v) => (v == null || v.trim().isEmpty)
                      ? context.l10n.nameRequired
                      : null,
              autofocus: widget.existing == null,
            ),
            ...[
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _courseCode,
                      decoration: InputDecoration(
                        labelText: context.l10n.courseCodeLabel,
                        hintText: context.l10n.courseCodeHint,
                      ),
                      textCapitalization: TextCapitalization.characters,
                      onFieldSubmitted: (_) => _fetchCatalog(),
                    ),
                  ),
                  if (_catalogSource == 'itu') ...[
                    const SizedBox(width: 12),
                    FilledButton.tonalIcon(
                      onPressed: _catalogBusy ? null : _fetchCatalog,
                      icon: _catalogBusy
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.cloud_download_outlined),
                      label: Text(
                        _catalogBusy
                            ? context.l10n.catalogFetching
                            : context.l10n.fetchCatalogButton,
                      ),
                    ),
                  ],
                ],
              ),
              if (_catalogError != null) ...[
                const SizedBox(height: 4),
                Text(
                  _catalogError!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ],
              if (widget.existing == null && _catalogSlots.isNotEmpty) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        context.l10n.catalogSlotsSummary(_catalogSlots.length),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () =>
                          setState(() => _catalogSlots = const []),
                      child: Text(context.l10n.catalogClearSlots),
                    ),
                  ],
                ),
              ],
            ],
            const SizedBox(height: 12),
            Text(context.l10n.colorLabel, style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final value in pickerColors)
                  InkWell(
                    onTap: () => setState(() => _color = value),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: classAccentColor(
                          Theme.of(context).colorScheme,
                          Color(value),
                        ),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _color == value
                              ? Theme.of(context).colorScheme.onSurface
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: _color == value
                          ? Icon(
                              Icons.check,
                              size: 18,
                              color: Theme.of(context).colorScheme.surface,
                            )
                          : null,
                    ),
                  ),
                InkWell(
                  onTap: _pickCustomColor,
                  borderRadius: BorderRadius.circular(16),
                  child: Tooltip(
                    message: context.l10n.customColorTitle,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isCustomColor
                                ? Color(_color)
                                : Theme.of(
                                  context,
                                ).colorScheme.surfaceContainerHighest,
                        border: Border.all(
                          color: isCustomColor
                                  ? Theme.of(context).colorScheme.onSurface
                                  : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: !isCustomColor
                              ? Icon(
                                Icons.add,
                                size: 18,
                                color: Theme.of(context).colorScheme.onSurface,
                              )
                              : Icon(
                                Icons.check,
                                size: 18,
                                color:
                                    ThemeData.estimateBrightnessForColor(
                                          Color(_color),
                                        ) ==
                                        Brightness.light
                                        ? Colors.black
                                        : Colors.white,
                              ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (widget.existing == null && _catalogSlots.isEmpty) ...[
              Text(context.l10n.meetsOn, style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                children: [
                  for (var d = 1; d <= 7; d++)
                    FilterChip(
                      label: Text(shortWeekdayName(d, context.l10n.localeName)),
                      selected: _days.contains(d),
                      onSelected: (sel) => setState(() {
                        sel ? _days.add(d) : _days.remove(d);
                      }),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _TimeButton(
                      label: context.l10n.startsAtLabel,
                      text: _startTime?.format(context) ?? context.l10n.pickTime,
                      onPick: () => _pickTime(isStart: true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _TimeButton(
                      label: context.l10n.endsAtLabel,
                      text: _endTime?.format(context) ?? context.l10n.pickTime,
                      onPick: () => _pickTime(isStart: false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                context.l10n.meetingHint,
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: Theme.of(context).colorScheme.outline),
              ),
            ],
            const SizedBox(height: 12),
            TextFormField(
              controller: _teacher,
              decoration: InputDecoration(labelText: context.l10n.teacherLabel),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _email,
              decoration: InputDecoration(labelText: context.l10n.teacherEmailLabel),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _room,
              decoration: InputDecoration(labelText: context.l10n.roomLabel),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _building,
              decoration: InputDecoration(labelText: context.l10n.buildingLabel),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _module,
              decoration: InputDecoration(labelText: context.l10n.moduleLabel),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _onlineLink,
              decoration: InputDecoration(
                labelText: context.l10n.onlineLinkLabel,
                helperText: context.l10n.onlineLinkHint,
              ),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _maxAbsences,
              decoration: InputDecoration(labelText: context.l10n.absenceLimitLabel),
              keyboardType: TextInputType.number,
              validator: (value) {
                final text = value?.trim() ?? '';
                if (text.isEmpty) return null;
                final limit = int.tryParse(text);
                return limit == null || limit < 0
                    ? context.l10n.enterNonNegative
                    : null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _reminder,
              decoration: InputDecoration(
                labelText: context.l10n.classReminderLabel,
                helperText: context.l10n.classReminderHint,
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                final text = value?.trim() ?? '';
                if (text.isEmpty) return null;
                final lead = int.tryParse(text);
                return lead == null || lead < 0
                    ? context.l10n.enterNonNegative
                    : null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notes,
              decoration: InputDecoration(labelText: context.l10n.notesFieldLabel),
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            YearDropdown(
              value: _yearId,
              onChanged: (v) => setState(() => _yearId = v),
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              title: Text(context.l10n.activeLabel),
              value: _active,
              onChanged: (v) => setState(() => _active = v),
            ),
            if (widget.existing != null) ...[
              const Divider(height: 32),
              _ScheduleSection(classId: widget.existing!.id),
              const Divider(height: 32),
              _AbsenceSection(
                classId: widget.existing!.id,
                limit: widget.existing!.maxAbsences,
              ),
              const Divider(height: 32),
              _FilesSection(classId: widget.existing!.id),
            ],
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _busy ? null : _save,
              icon: const Icon(Icons.check),
              label: Text(context.l10n.saveClass),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimeButton extends StatelessWidget {
  final String label;
  final String text;
  final VoidCallback onPick;

  const _TimeButton({
    required this.label,
    required this.text,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: const Icon(Icons.schedule, size: 18),
      ),
      child: InkWell(onTap: onPick, child: Text(text)),
    );
  }
}

class _ScheduleSection extends ConsumerWidget {
  final int classId;

  const _ScheduleSection({required this.classId});

  Future<void> _add(BuildContext context, WidgetRef ref) async {
    var start = 540;
    var end = 600;
    int? autoEnd;
    try {
      final repo = ref.read(settingsRepositoryProvider);
      start = await repo.defaultStartMinutes();
      final duration = await repo.defaultDurationMinutes();
      end = (start + duration).clamp(1, 1439);
      if (end <= start) end = (start + 60).clamp(1, 1439);
      if (await repo.autoEndTime()) autoEnd = duration;
    } catch (e) {
      logLoadFailure('Load schedule defaults', e);
    }
    if (!context.mounted) return;
    ({int length, bool letters})? rot;
    try {
      rot = await ref.read(rotationOptionsForClassProvider(classId).future);
    } catch (e) {
      logLoadFailure('Rotation options, continuing without', e);
    }
    if (!context.mounted) return;
    final draft = await showDialog<SlotDraft>(
      context: context,
      builder: (_) => ScheduleSlotDialog(
        initial: SlotDraft(dayOfWeek: 1, startMinutes: start, endMinutes: end),
        dayRotationLength: rot?.length,
        dayRotationLetters: rot?.letters ?? false,
        autoEndMinutes: autoEnd,
      ),
    );
    if (draft == null || !context.mounted) return;
    try {
      await ref
          .read(classRepositoryProvider)
          .createScheduleItem(draft.toCompanion(classId));
      ref.invalidate(engineProvider);
      await ref.read(reminderSchedulerProvider).refreshClassReminders();
    } catch (e) {
      if (context.mounted) {
        await showErrorDialog(
          context,
          title: context.l10n.errorAddSlot,
          error: e,
        );
      }
    }
  }

  Future<void> _edit(
    BuildContext context,
    WidgetRef ref,
    ScheduleItem item,
  ) async {
    ({int length, bool letters})? rot;
    try {
      rot = await ref.read(
        rotationOptionsForClassProvider(item.classId).future,
      );
    } catch (e) {
      logLoadFailure('Rotation options, continuing without', e);
    }
    int? autoEnd;
    try {
      final repo = ref.read(settingsRepositoryProvider);
      if (await repo.autoEndTime()) {
        autoEnd = await repo.defaultDurationMinutes();
      }
    } catch (e) {
      logLoadFailure('Load auto end', e);
    }
    if (!context.mounted) return;
    final draft = await showDialog<SlotDraft>(
      context: context,
      builder: (_) => ScheduleSlotDialog(
        initial: SlotDraft.fromItem(item),
        isEdit: true,
        dayRotationLength: rot?.length,
        dayRotationLetters: rot?.letters ?? false,
        autoEndMinutes: autoEnd,
      ),
    );
    if (draft == null || !context.mounted) return;
    try {
      await ref
          .read(classRepositoryProvider)
          .updateScheduleItem(
            item.copyWithCompanion(draft.toCompanion(classId)),
          );
      ref.invalidate(engineProvider);
      await ref.read(reminderSchedulerProvider).refreshClassReminders();
    } catch (e) {
      if (context.mounted) {
        await showErrorDialog(
          context,
          title: context.l10n.errorUpdateSlot,
          error: e,
        );
      }
    }
  }

  Future<void> _remove(
    BuildContext context,
    WidgetRef ref,
    ScheduleItem item,
  ) async {
    try {
      await ref.read(classRepositoryProvider).deleteScheduleItem(item.id);
      ref.invalidate(engineProvider);
      await ref.read(reminderSchedulerProvider).refreshClassReminders();
    } catch (e) {
      if (context.mounted) {
        await showErrorDialog(
          context,
          title: context.l10n.errorDeleteSlot,
          error: e,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final slots = ref.watch(scheduleItemsForClassProvider(classId));
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(context.l10n.meetingTimes, style: theme.textTheme.titleMedium),
            ),
            IconButton(
              tooltip: context.l10n.addSlotTooltip,
              icon: const Icon(Icons.add),
              onPressed: () => _add(context, ref),
            ),
          ],
        ),
        Text(
          context.l10n.weeklyHoursHint,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.outline,
          ),
        ),
        const SizedBox(height: 4),
        slots.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(16),
            child: CircularProgressIndicator(),
          ),
          error: (e, _) => Text(context.l10n.couldNotLoadSlots('$e')),
          data: (list) {
            if (list.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(context.l10n.noSlotsYet),
              );
            }
            return Column(
              children: [
                for (final s in list)
                  _SlotTile(
                    draft: SlotDraft.fromItem(s),
                    onTap: () => _edit(context, ref, s),
                    onDelete: () => _remove(context, ref, s),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _SlotTile extends StatelessWidget {
  final SlotDraft draft;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _SlotTile({
    required this.draft,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Text(fullWeekdayName(draft.dayOfWeek, context.l10n.localeName)),
      title: Text('${hhmm(draft.startMinutes)} - ${hhmm(draft.endMinutes)}'),
      subtitle: Text(slotRotationLabel(context.l10n, draft)),
      onTap: onTap,
      trailing: IconButton(
        tooltip: context.l10n.deleteSlotTooltip,
        icon: const Icon(Icons.delete_outline),
        onPressed: onDelete,
      ),
    );
  }
}

/// Recorded absences for a saved class, with quota progress.
class _AbsenceSection extends ConsumerWidget {
  final int classId;
  final int? limit;

  const _AbsenceSection({required this.classId, required this.limit});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final absences = ref.watch(absencesForClassProvider(classId));
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(context.l10n.absencesSection, style: theme.textTheme.titleMedium),
        const SizedBox(height: 4),
        absences.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(16),
            child: CircularProgressIndicator(),
          ),
          error: (e, _) => Text(context.l10n.couldNotLoadAbsences('$e')),
          data: (list) {
            final unexcused = list.where((a) => !a.isExcused).length;
            final excused = list.length - unexcused;
            final summary = limit == null
                ? context.l10n.absenceSummaryPlain(unexcused, excused)
                : context.l10n.absenceSummaryQuota(unexcused, limit!, excused);
            final over = limit != null && unexcused > 0 && unexcused >= limit!;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  summary,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: over
                        ? theme.colorScheme.error
                        : theme.colorScheme.outline,
                  ),
                ),
                const SizedBox(height: 4),
                if (list.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(context.l10n.noAbsencesRecorded),
                  )
                else
                  for (final a in list)
                    _AbsenceRow(absence: a),
              ],
            );
          },
        ),
      ],
    );
  }
}

/// One recorded absence row with its session kind.
class _AbsenceRow extends ConsumerWidget {
  final Absence absence;

  const _AbsenceRow({required this.absence});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final a = absence;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Text(a.date.substring(5).replaceAll('-', '/')),
      title: Text('${hhmm(a.startMinutes)} - ${hhmm(a.endMinutes)}'),
      subtitle: Text(
        [
          absenceKindInline(context.l10n, kindOfAbsence(a)),
          if (a.reason != null && a.reason!.isNotEmpty) a.reason!,
          a.isExcused
              ? context.l10n.excusedBadge
              : context.l10n.unexcusedBadge,
        ].join(' · '),
      ),
      trailing: IconButton(
        tooltip: context.l10n.deleteAbsenceTooltip,
        icon: const Icon(Icons.delete_outline),
        onPressed: () => ref.read(absenceRepositoryProvider).unmark(a.id),
      ),
    );
  }
}


/// File attachments for a saved class (syllabus PDFs, slides, images).
/// Picked via the platform picker, copied into app storage, synced
/// through the data folder.
class _FilesSection extends ConsumerWidget {
  final int classId;

  const _FilesSection({required this.classId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final files = ref.watch(classFilesForClassProvider(classId));
    return AttachmentPanel(
      files: files.whenData(
        (list) => [
          for (final f in list)
            AttachedFile(
              id: f.id,
              fileName: f.fileName,
              storedPath: f.storedPath,
              sizeBytes: f.sizeBytes,
            ),
        ],
      ),
      onAdd: () => ref.read(classFilesServiceProvider).pickAndSave(classId),
      onOpen: (f) => ref
          .read(classFilesServiceProvider)
          .openStoredFile(fileName: f.fileName, storedPath: f.storedPath),
      onDelete: (f) => ref.read(classFileRepositoryProvider).delete(f.id),
    );
  }
}
