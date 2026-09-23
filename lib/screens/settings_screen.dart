import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:drift/drift.dart' show Value;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../app.dart';
import '../data/database.dart';
import '../data/schedule_repository.dart';
import '../providers.dart';
import '../l10n/l10n.dart';
import '../theme.dart';
import '../services/ical.dart';
import '../services/menu/menu_sources.dart';
import 'year_widgets.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _defaultLimit = TextEditingController();
  final _defaultLimitFormKey = GlobalKey<FormState>();
  bool _defaultLimitLoaded = false;
  bool _savingDefaultLimit = false;
  bool _scheduleLoaded = false;
  bool _busy = false;
  int _defaultStart = 540;
  int _defaultDuration = 60;
  int? _defaultReminder;
  bool _autoEnd = false;
  bool _portraitLock = false;
  String _localeOverride = 'system';
  String _menuProviderId = '';

  @override
  void initState() {
    super.initState();
    _loadDefaultLimit();
    _loadScheduleDefaults();
    _loadLocale();
    _loadPortraitLock();
    _loadMenuProvider();
  }

  Future<void> _loadPortraitLock() async {
    try {
      final value = await ref.read(settingsRepositoryProvider).portraitLock();
      if (!mounted) return;
      setState(() => _portraitLock = value);
    } catch (e) {
      debugPrint('Load portrait lock failed: $e');
    }
  }

  Future<void> _loadMenuProvider() async {
    try {
      final value = await ref
          .read(settingsRepositoryProvider)
          .menuProviderId();
      if (!mounted) return;
      setState(
        () => _menuProviderId = menuSources.containsKey(value) ? value : '',
      );
    } catch (e) {
      debugPrint('Load menu source failed: $e');
    }
  }

  Future<void> _setMenuProvider(String value) async {
    setState(() => _menuProviderId = value);
    try {
      await ref.read(settingsRepositoryProvider).setMenuProviderId(value);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.couldNotSaveSetting('$e'))),
        );
      }
    }
  }

  Future<void> _togglePortraitLock(bool value) async {
    setState(() => _portraitLock = value);
    try {
      await ref.read(settingsRepositoryProvider).setPortraitLock(value);
      await applyPortraitLock(value);
    } catch (e) {
      if (!mounted) return;
      setState(() => _portraitLock = !value);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.couldNotSaveSetting('$e'))),
      );
    }
  }

  Future<void> _loadLocale() async {
    try {
      final value = await ref.read(settingsRepositoryProvider).localeOverride();
      if (!mounted) return;
      setState(() => _localeOverride = value);
    } catch (e) {
      debugPrint('Load locale failed: $e');
    }
  }

  Future<void> _setLocale(String value) async {
    setState(() => _localeOverride = value);
    try {
      await ref.read(settingsRepositoryProvider).setLocaleOverride(value);
      ref.invalidate(appLocaleProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.couldNotSaveSetting('$e'))),
        );
      }
    }
  }

  Future<void> _loadDefaultLimit() async {
    try {
      final value = await ref
          .read(settingsRepositoryProvider)
          .defaultMaxAbsences();
      if (!mounted) return;
      setState(() {
        if (value != null) _defaultLimit.text = value.toString();
        _defaultLimitLoaded = true;
      });
    } catch (e) {
      debugPrint('Load settings failed: $e');
      if (!mounted) return;
      setState(() => _defaultLimitLoaded = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.couldNotLoadSettings('$e'))),
      );
    }
  }

  @override
  void dispose() {
    _defaultLimit.dispose();
    super.dispose();
  }

  Future<void> _loadScheduleDefaults() async {
    try {
      final repo = ref.read(settingsRepositoryProvider);
      final start = await repo.defaultStartMinutes();
      final duration = await repo.defaultDurationMinutes();
      final reminder = await repo.defaultClassReminderMinutes();
      final autoEnd = await repo.autoEndTime();
      if (!mounted) return;
      setState(() {
        _defaultStart = start;
        _defaultDuration = duration;
        _defaultReminder = reminder;
        _autoEnd = autoEnd;
        _scheduleLoaded = true;
      });
    } catch (e) {
      debugPrint('Load schedule defaults failed: $e');
      if (!mounted) return;
      setState(() => _scheduleLoaded = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.couldNotLoadSettings('$e'))),
      );
    }
  }

  String _hhmm(int minutes) {
    final h = (minutes ~/ 60).toString().padLeft(2, '0');
    final m = (minutes % 60).toString().padLeft(2, '0');
    return '$h:$m';
  }

  Future<void> _pickDefaultStart() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: _defaultStart ~/ 60,
        minute: _defaultStart % 60,
      ),
    );
    if (picked == null || !mounted) return;
    try {
      await ref
          .read(settingsRepositoryProvider)
          .setDefaultStartMinutes(picked.hour * 60 + picked.minute);
      if (!mounted) return;
      setState(() => _defaultStart = picked.hour * 60 + picked.minute);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.couldNotSaveSetting('$e'))),
        );
      }
    }
  }

  Future<void> _pickDefaultDuration() async {
    final input = TextEditingController(text: _defaultDuration.toString());
    final minutes = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.defaultDurationTitle),
        content: TextFormField(
          controller: input,
          autofocus: true,
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(context).pop(int.tryParse(input.text.trim())),
            child: Text(context.l10n.save),
          ),
        ],
      ),
    );
    if (minutes == null || minutes <= 0 || !mounted) return;
    try {
      await ref
          .read(settingsRepositoryProvider)
          .setDefaultDurationMinutes(minutes);
      if (!mounted) return;
      setState(() => _defaultDuration = minutes);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.couldNotSaveSetting('$e'))),
        );
      }
    }
  }

  Future<void> _toggleAutoEnd(bool value) async {
    setState(() => _autoEnd = value);
    try {
      await ref.read(settingsRepositoryProvider).setAutoEndTime(value);
    } catch (e) {
      if (mounted) {
        setState(() => _autoEnd = !value);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.couldNotSaveSetting('$e'))),
        );
      }
    }
  }

  Future<void> _pickDefaultReminder() async {
    final input = TextEditingController(
      text: _defaultReminder?.toString() ?? '',
    );
    final result = await showDialog<String?>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.l10n.defaultReminderTitle),
        content: TextFormField(
          controller: input,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: context.l10n.minutesBeforeClass,
            helperText: context.l10n.emptyMeansOff,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            onPressed: () {
              final text = input.text.trim();
              if (text.isNotEmpty && int.tryParse(text) == null) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  SnackBar(content: Text(context.l10n.enterNonNegative)),
                );
                return;
              }
              Navigator.of(dialogContext).pop(text);
            },
            child: Text(context.l10n.save),
          ),
        ],
      ),
    );
    if (result == null || !mounted) return; // Cancelled.
    final minutes = result.isEmpty ? null : int.parse(result);
    if (minutes != null && minutes < 0) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(context.l10n.enterNonNegative)));
      return;
    }
    try {
      await ref
          .read(settingsRepositoryProvider)
          .setDefaultClassReminderMinutes(minutes);
      if (!mounted) return;
      setState(() => _defaultReminder = minutes);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.couldNotSaveSetting('$e'))),
        );
      }
    }
  }

  Future<void> _pickDataFolder() async {
    final l10n = context.l10n;
    try {
      final path = await FilePicker.getDirectoryPath();
      if (path == null || !mounted) return;
      await ref.read(settingsRepositoryProvider).setDataFolder(path);
      ref.invalidate(dataFolderStatusProvider);
      _snack(l10n.savedTo(path));
    } catch (e) {
      _snack(l10n.couldNotExportData('$e'));
    }
  }

  Future<void> _clearDataFolder() async {
    await ref.read(settingsRepositoryProvider).setDataFolder(null);
    ref.invalidate(dataFolderStatusProvider);
  }

  Future<void> _refreshAfterDataChange(int upserted, int deleted) async {
    if (upserted > 0 || deleted > 0) {
      ref.invalidate(engineProvider);
      ref.invalidate(classesByIdProvider);
      await ref.read(reminderSchedulerProvider).refreshAll();
    }
    ref.invalidate(dataFolderStatusProvider);
  }

  Future<void> _exportData() async {
    final l10n = context.l10n;
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final service = ref.read(dataFolderServiceProvider);
      if (await service.dataDir() == null) {
        _snack(l10n.dataFolderNeedsFolder);
        return;
      }
      final result = await service.exportData();
      if (result.error != null) {
        _snack(l10n.couldNotExportData(result.error!));
        return;
      }
      ref.invalidate(dataFolderStatusProvider);
      if (!mounted) return;
      _snack(l10n.dataExportDone(result.rowsExported));
    } catch (e) {
      _snack(l10n.couldNotExportData('$e'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _importData() async {
    final l10n = context.l10n;
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final service = ref.read(dataFolderServiceProvider);
      if (await service.dataDir() == null) {
        _snack(l10n.dataFolderNeedsFolder);
        return;
      }
      final result = await service.importData();
      if (result.error != null) {
        _snack(switch (result.error!) {
          'folder-missing' => l10n.importErrorFolderMissing,
          'manifest-missing' => l10n.importErrorManifestMissing,
          'not-a-data-folder' => l10n.importErrorInvalid,
          final other => l10n.couldNotImportData(other),
        });
        return;
      }
      await _refreshAfterDataChange(result.rowsUpserted, result.rowsDeleted);
      if (!mounted) return;
      _snack(
        l10n.dataImportDone(result.rowsUpserted, result.rowsDeleted),
      );
    } catch (e) {
      _snack(l10n.couldNotImportData('$e'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _snack(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _exportFile({
    required String fileName,
    required List<int> bytes,
  }) async {
    final l10n = context.l10n;
    if (_busy) return;
    setState(() => _busy = true);
    try {
      if (Platform.isLinux) {
        final uri = await FilePicker.saveFile(
          bytes: Uint8List.fromList(bytes),
          fileName: fileName,
        );
        if (uri == null) return;
        _snack(l10n.savedTo(uri));
      } else {
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/$fileName');
        await file.writeAsBytes(bytes);
        await SharePlus.instance.share(ShareParams(files: [XFile(file.path)]));
      }
    } catch (e) {
      _snack(l10n.couldNotExport('$e'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<List<int>?> _pickFile(List<String> extensions) async {
    final files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: extensions,
    );
    if (files.isEmpty) return null;
    final path = files.first.path;
    if (path != null) return File(path).readAsBytes();
    return files.first.xFile.readAsBytes();
  }

  Future<void> _exportCalendar() async {
    final l10n = context.l10n;
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final end = today.add(const Duration(days: 90));
      final engine = await ref.read(engineProvider.future);
      final classesById = await ref.read(classesByIdProvider.future);
      final occs = engine.occurrences(rangeStart: today, rangeEnd: end);
      final tasks = await ref.read(taskRepositoryProvider).watchAll().first;
      final xtra = await ref
          .read(xtraRepositoryProvider)
          .range(isoDate(today), isoDate(end));
      final endIso = isoDate(end);
      final events = <IcsEvent>[
        for (final o in occs)
          IcsEvent(
            title: classesById[o.classId]?.name ?? l10n.classFallback,
            start: o.start,
            end: o.end,
            location: o.room ?? classesById[o.classId]?.room,
          ),
        for (final t in tasks)
          if (t.task.dueDate != null &&
              !t.task.isDone &&
              t.task.dueDate!.compareTo(endIso) <= 0)
            IcsEvent(
              title: t.task.title,
              start: _dueMoment(t.task.dueDate!, t.task.dueMinutes),
              end: null,
              location: t.classRow?.name,
            ),
        for (final x in xtra)
          IcsEvent(
            title: x.title,
            start: _xtraMoment(x.date, x.startMinutes),
            end: x.endMinutes == null
                ? null
                : _xtraMoment(x.date, x.endMinutes),
            location: x.location,
            description: x.notes,
          ),
      ];
      await _exportFile(
        fileName: 'chronicle-calendar.ics',
        bytes: utf8.encode(buildIcs(events: events)),
      );
    } catch (e) {
      _snack(l10n.couldNotExportCalendar('$e'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  DateTime _dueMoment(String iso, int? minutes) {
    final day = DateTime.parse(iso);
    if (minutes == null) return day;
    return DateTime(day.year, day.month, day.day, minutes ~/ 60, minutes % 60);
  }

  DateTime _xtraMoment(String iso, int? minutes) {
    final day = DateTime.parse(iso);
    if (minutes == null) return DateTime(day.year, day.month, day.day);
    return DateTime(day.year, day.month, day.day, minutes ~/ 60, minutes % 60);
  }

  Future<void> _importCalendar() async {
    final l10n = context.l10n;
    if (_busy) return;
    final bytes = await _pickFile(['ics']);
    if (bytes == null || !mounted) return;
    setState(() => _busy = true);
    try {
      final events = parseIcs(utf8.decode(bytes));
      final repo = ref.read(xtraRepositoryProvider);
      for (final e in events.take(1000)) {
        final day = DateTime(e.start.year, e.start.month, e.start.day);
        final allDay =
            e.end == null &&
            e.start.hour == 0 &&
            e.start.minute == 0 &&
            e.start.second == 0;
        await repo.create(
          XtraEventsCompanion.insert(
            title: e.title.length > 240 ? e.title.substring(0, 240) : e.title,
            date: isoDate(day),
            startMinutes: Value(
              allDay ? null : e.start.hour * 60 + e.start.minute,
            ),
            endMinutes: Value(
              e.end == null ? null : e.end!.hour * 60 + e.end!.minute,
            ),
            location: Value(e.location),
            notes: Value(e.description),
          ),
        );
      }
      _snack(l10n.importedEvents(events.length));
    } catch (e) {
      _snack(l10n.couldNotImportCalendar('$e'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _saveDefaultLimit() async {
    if (!_defaultLimitFormKey.currentState!.validate() || _savingDefaultLimit) {
      return;
    }
    final text = _defaultLimit.text.trim();
    setState(() => _savingDefaultLimit = true);
    try {
      await ref
          .read(settingsRepositoryProvider)
          .setDefaultMaxAbsences(text.isEmpty ? null : int.parse(text));
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.l10n.defaultLimitSaved)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.couldNotSaveSetting('$e'))),
        );
      }
    } finally {
      if (mounted) setState(() => _savingDefaultLimit = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.navSettings)),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          _SettingsCard(
            icon: Icons.palette_outlined,
            title: context.l10n.appearanceHeader,
            children: [
              RadioGroup<ThemeMode>(
                groupValue: themeMode,
                onChanged: (v) => ref.read(themeModeProvider.notifier).set(v!),
                child: Column(
                  children: [
                    RadioListTile<ThemeMode>(
                      title: Text(context.l10n.themeSystem),
                      value: ThemeMode.system,
                    ),
                    RadioListTile<ThemeMode>(
                      title: Text(context.l10n.themeLight),
                      value: ThemeMode.light,
                    ),
                    RadioListTile<ThemeMode>(
                      title: Text(context.l10n.themeDark),
                      value: ThemeMode.dark,
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                child: _ThemePicker(),
              ),
              // Phones only: orientation locks are meaningless for
              // user-resizable desktop windows.
              if (Platform.isAndroid || Platform.isIOS)
                SwitchListTile(
                  secondary: const Icon(Icons.screen_lock_portrait_outlined),
                  title: Text(context.l10n.lockPortraitTitle),
                  subtitle: Text(context.l10n.lockPortraitHint),
                  value: _portraitLock,
                  onChanged: _togglePortraitLock,
                ),
            ],
          ),
          _SettingsCard(
            icon: Icons.event_busy_outlined,
            title: context.l10n.navAbsences,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                child: Form(
                  key: _defaultLimitFormKey,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _defaultLimit,
                          enabled: _defaultLimitLoaded,
                          decoration: InputDecoration(
                            labelText: context.l10n.defaultAbsenceLimit,
                            helperText: context.l10n.prefilledHint,
                            helperMaxLines: 2,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 14,
                            ),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            final text = value?.trim() ?? '';
                            if (text.isEmpty) return null;
                            final limit = int.tryParse(text);
                            return limit == null || limit < 0
                                ? context.l10n.enterNonNegative
                                : null;
                          },
                          onFieldSubmitted: (_) => _saveDefaultLimit(),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: FilledButton(
                          onPressed: _savingDefaultLimit
                              ? null
                              : _saveDefaultLimit,
                          child: Text(context.l10n.save),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          _SettingsCard(
            icon: Icons.date_range_outlined,
            title: context.l10n.academicYearsHeader,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: YearsSection(),
              ),
            ],
          ),
          _SettingsCard(
            icon: Icons.storage_outlined,
            title: context.l10n.dataHeader,
            children: [
              ListTile(
                leading: const Icon(Icons.calendar_month_outlined),
                title: Text(context.l10n.exportCalendar),
                subtitle: Text(context.l10n.exportCalendarHint),
                onTap: _busy ? null : _exportCalendar,
              ),
              ListTile(
                leading: const Icon(Icons.calendar_month),
                title: Text(context.l10n.importCalendar),
                subtitle: Text(context.l10n.importCalendarHint),
                onTap: _busy ? null : _importCalendar,
              ),
              const Divider(height: 16),
              _DataFolderTiles(
                busy: _busy,
                onPickFolder: _pickDataFolder,
                onClearFolder: _clearDataFolder,
                onExport: _exportData,
                onImport: _importData,
              ),
            ],
          ),
          _SettingsCard(
            icon: Icons.schedule_outlined,
            title: context.l10n.scheduleHeader,
            children: [
              ListTile(
                leading: const Icon(Icons.schedule_outlined),
                title: Text(context.l10n.defaultClassStart),
                subtitle: Text(
                  _scheduleLoaded
                      ? context.l10n.prefilledStartHint(_hhmm(_defaultStart))
                      : context.l10n.loadingEllipsis,
                ),
                enabled: _scheduleLoaded,
                onTap: _pickDefaultStart,
              ),
              ListTile(
                leading: const Icon(Icons.timelapse_outlined),
                title: Text(context.l10n.defaultClassDuration),
                subtitle: Text(
                  _scheduleLoaded
                      ? context.l10n.prefilledDurationHint(_defaultDuration)
                      : context.l10n.loadingEllipsis,
                ),
                enabled: _scheduleLoaded,
                onTap: _pickDefaultDuration,
              ),
              SwitchListTile(
                secondary: const Icon(Icons.auto_fix_high_outlined),
                title: Text(context.l10n.autoEndTitle),
                subtitle: Text(context.l10n.autoEndHint),
                value: _autoEnd,
                onChanged: _scheduleLoaded ? _toggleAutoEnd : null,
              ),
              ListTile(
                leading: const Icon(Icons.notifications_outlined),
                title: Text(context.l10n.defaultReminderTitle),
                subtitle: Text(
                  !_scheduleLoaded
                      ? context.l10n.loadingEllipsis
                      : (_defaultReminder == null
                            ? context.l10n.reminderOffHint
                            : context.l10n.remindsBeforeHint(
                                _defaultReminder!,
                              )),
                ),
                enabled: _scheduleLoaded,
                onTap: _pickDefaultReminder,
              ),
            ],
          ),
          _SettingsCard(
            icon: Icons.calendar_month_outlined,
            title: context.l10n.navCalendar,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: _DayRangePicker(),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                child: _GridMarkersPicker(),
              ),
            ],
          ),
          _SettingsCard(
            icon: Icons.restaurant_outlined,
            title: context.l10n.menuSourceTitle,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                child: DropdownButtonFormField<String>(
                  initialValue: _menuProviderId,
                  decoration: InputDecoration(
                    labelText: context.l10n.menuSourceLabel,
                  ),
                  items: [
                    DropdownMenuItem(
                      value: '',
                      child: Text(context.l10n.menuSourceNone),
                    ),
                    for (final entry in menuSources.entries)
                      DropdownMenuItem(
                        value: entry.key,
                        child: Text(entry.value.name),
                      ),
                  ],
                  onChanged: (v) {
                    if (v != null) _setMenuProvider(v);
                  },
                ),
              ),
            ],
          ),
          _SettingsCard(
            icon: Icons.translate_outlined,
            title: context.l10n.languagesHeader,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                child: RadioGroup<String>(
                  groupValue: _localeOverride,
                  onChanged: (v) {
                    if (v != null) _setLocale(v);
                  },
                  child: Column(
                    children: [
                      RadioListTile<String>(
                        contentPadding: EdgeInsets.zero,
                        title: Text(context.l10n.languageSystem),
                        value: 'system',
                      ),
                      RadioListTile<String>(
                        contentPadding: EdgeInsets.zero,
                        title: Text(context.l10n.languageEnglish),
                        value: 'en',
                      ),
                      RadioListTile<String>(
                        contentPadding: EdgeInsets.zero,
                        title: Text(context.l10n.languageTurkish),
                        value: 'tr',
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const _VersionFooter(),
        ],
      ),
    );
  }
}

/// App version line at the bottom of Settings.
class _VersionFooter extends StatelessWidget {
  const _VersionFooter();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FutureBuilder<PackageInfo>(
      future: PackageInfo.fromPlatform(),
      builder: (context, snapshot) {
        final info = snapshot.data;
        if (info == null) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Center(
            child: Text(
              '${info.appName} ${info.version} (${info.buildNumber})',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DataFolderTiles extends ConsumerWidget {
  final bool busy;
  final VoidCallback onPickFolder;
  final VoidCallback onClearFolder;
  final VoidCallback onExport;
  final VoidCallback onImport;

  const _DataFolderTiles({
    required this.busy,
    required this.onPickFolder,
    required this.onClearFolder,
    required this.onExport,
    required this.onImport,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(dataFolderStatusProvider);
    final folder = status.value?.folder;
    final exported = status.value?.lastExportAt;
    final imported = status.value?.lastImportAt;
    final autoSync = status.value?.autoSync ?? true;
    String subtitle;
    if (folder == null || folder.isEmpty) {
      subtitle = context.l10n.dataFolderUnset;
    } else {
      final lines = <String>[folder];
      if (exported != null) {
        lines.add(
          context.l10n.dataLastExport(
            DateTime.fromMillisecondsSinceEpoch(
              exported,
            ).toString().substring(0, 16),
          ),
        );
      }
      if (imported != null) {
        lines.add(
          context.l10n.dataLastImport(
            DateTime.fromMillisecondsSinceEpoch(
              imported,
            ).toString().substring(0, 16),
          ),
        );
      }
      subtitle = lines.join('\n');
    }
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.folder_outlined),
          title: Text(context.l10n.dataFolderTitle),
          subtitle: Text(subtitle),
          isThreeLine: folder != null && folder.isNotEmpty,
          onTap: busy ? null : onPickFolder,
          trailing: folder != null && folder.isNotEmpty
              ? IconButton(
                  tooltip: context.l10n.delete,
                  icon: const Icon(Icons.clear_outlined),
                  onPressed: busy ? null : onClearFolder,
                )
              : null,
        ),
        ListTile(
          leading: const Icon(Icons.upload_outlined),
          title: Text(context.l10n.exportDataAction),
          onTap: busy ? null : onExport,
        ),
        ListTile(
          leading: const Icon(Icons.download_outlined),
          title: Text(context.l10n.importDataAction),
          onTap: busy ? null : onImport,
        ),
        SwitchListTile(
          secondary: const Icon(Icons.sync_outlined),
          title: Text(context.l10n.autoSyncTitle),
          subtitle: Text(context.l10n.autoSyncHint),
          value: autoSync,
          onChanged: busy
              ? null
              : (v) async {
                  try {
                    await ref
                        .read(settingsRepositoryProvider)
                        .setAutoSync(v);
                    ref.invalidate(dataFolderStatusProvider);
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            context.l10n.couldNotSaveSetting('$e'),
                          ),
                        ),
                      );
                    }
                  }
                },
        ),
      ],
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<Widget> children;

  const _SettingsCard({
    required this.icon,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(0, 12, 0, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                child: Row(
                  children: [
                    Icon(icon, size: 20, color: theme.colorScheme.primary),
                    const SizedBox(width: 10),
                    Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
              ...children,
            ],
          ),
        ),
      ),
    );
  }
}

/// Theme family picker (Default / Catppuccin) with accent dots.
class _ThemePicker extends ConsumerWidget {
  const _ThemePicker();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeId = ref.watch(appThemeProvider).value ?? defaultAppTheme;
    final accent =
        ref.watch(accentColorProvider).value ?? Catppuccin.defaultAccent;
    final theme = Theme.of(context);

    Future<void> selectTheme(String id) async {
      try {
        await ref.read(settingsRepositoryProvider).setAppTheme(id);
        ref.invalidate(appThemeProvider);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.l10n.couldNotSaveTheme('$e'))),
          );
        }
      }
    }

    Future<void> selectAccent(int value) async {
      try {
        await ref.read(settingsRepositoryProvider).setAccentColor(value);
        ref.invalidate(accentColorProvider);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.l10n.couldNotSaveAccent('$e'))),
          );
        }
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          initialValue: lookupAppTheme(themeId).id,
          decoration: InputDecoration(labelText: context.l10n.themeLabel),
          items: [
            for (final def in appThemes)
              DropdownMenuItem(value: def.id, child: Text(def.name)),
          ],
          onChanged: (v) {
            if (v != null) selectTheme(v);
          },
        ),
        if (lookupAppTheme(themeId).supportsAccent) ...[
          const SizedBox(height: 12),
          Text(
            context.l10n.accentLabel,
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final entry in lookupAppTheme(themeId).accents.entries)
                _AccentDot(
                  color: Color(entry.value),
                  tooltip: entry.key,
                  selected: accent == entry.value,
                  onTap: () => selectAccent(entry.value),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _AccentDot extends StatelessWidget {
  final Color color;
  final String tooltip;
  final bool selected;
  final VoidCallback onTap;

  const _AccentDot({
    required this.color,
    required this.tooltip,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: selected
                ? Border.all(
                    color: Theme.of(context).colorScheme.onSurface,
                    width: 3,
                  )
                : Border.all(
                    color: Theme.of(context).colorScheme.outline
                        .withValues(alpha: 0.4),
                  ),
          ),
          child: selected
              ? const Icon(Icons.check, color: Colors.black54, size: 20)
              : null,
        ),
      ),
    );
  }
}

/// Week-grid visible day range (first/last minute) from settings.
/// Supports custom minutes like 6:40.
class _DayRangePicker extends ConsumerStatefulWidget {
  const _DayRangePicker();

  @override
  ConsumerState<_DayRangePicker> createState() => _DayRangePickerState();
}

class _DayRangePickerState extends ConsumerState<_DayRangePicker> {
  bool _loaded = false;
  int _start = 360;
  int _end = 1320;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final repo = ref.read(settingsRepositoryProvider);
      final start = await repo.dayStartMinutes();
      final end = await repo.dayEndMinutes();
      if (!mounted) return;
      setState(() {
        _start = start;
        _end = end <= start ? (start + 60).clamp(1, 1440) : end;
        _loaded = true;
      });
    } catch (e) {
      debugPrint('Load day range failed: $e');
      if (mounted) setState(() => _loaded = true);
    }
  }

  Future<void> _save(int start, int end) async {
    // Keep at least 30 min span by nudging the other bound.
    if (end <= start) {
      if (start != _start) {
        end = (start + 60).clamp(1, 1440);
      } else {
        start = (end - 60).clamp(0, 1439);
      }
      if (end <= start) return;
    }
    setState(() {
      _start = start;
      _end = end;
    });
    try {
      final repo = ref.read(settingsRepositoryProvider);
      await repo.setDayStartMinutes(start);
      await repo.setDayEndMinutes(end);
      ref.invalidate(dayRangeProvider);
      ref.invalidate(fixedGridProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.couldNotSave('$e'))),
        );
      }
    }
  }

  String _mmLabel(int m) =>
      '${(m ~/ 60).toString().padLeft(2, '0')}:${(m % 60).toString().padLeft(2, '0')}';

  Future<void> _pick(bool isStart) async {
    final initial = isStart ? _start : _end;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: (initial ~/ 60).clamp(0, 23),
        minute: (initial % 60).clamp(0, 59),
      ),
      helpText: isStart
          ? context.l10n.dayStartsLabel
          : context.l10n.dayEndsLabel,
    );
    if (picked == null) return;
    var minutes = picked.hour * 60 + picked.minute;
    // Day end 00:00 means midnight end of day.
    if (!isStart && picked.hour == 0 && picked.minute == 0) {
      minutes = 1440;
    }
    if (isStart) {
      await _save(minutes.clamp(0, 1439), _end);
    } else {
      await _save(_start, minutes.clamp(1, 1440));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) return const SizedBox.shrink();
    Widget field({required String label, required int value, required VoidCallback onTap}) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 14,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                value >= 1440 ? '24:00' : _mmLabel(value),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Icon(
                Icons.schedule_outlined,
                size: 20,
                color: Theme.of(context).colorScheme.outline,
              ),
            ],
          ),
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          child: field(
            label: context.l10n.dayStartsLabel,
            value: _start,
            onTap: () => _pick(true),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: field(
            label: context.l10n.dayEndsLabel,
            value: _end,
            onTap: () => _pick(false),
          ),
        ),
      ],
    );
  }
}

/// Week-grid time marker configuration: class times or a fixed
/// lesson/break rhythm generated from a start time.
class _GridMarkersPicker extends ConsumerStatefulWidget {
  const _GridMarkersPicker();

  @override
  ConsumerState<_GridMarkersPicker> createState() => _GridMarkersPickerState();
}

class _GridMarkersPickerState extends ConsumerState<_GridMarkersPicker> {
  final _lesson = TextEditingController();
  final _recess = TextEditingController();
  bool _loaded = false;
  String _mode = 'class-times';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final repo = ref.read(settingsRepositoryProvider);
      final mode = await repo.gridMarkersMode();
      final lesson = await repo.gridFixedLesson();
      final recess = await repo.gridFixedBreak();
      if (!mounted) return;
      setState(() {
        _mode = mode;
        _lesson.text = lesson.toString();
        _recess.text = recess.toString();
        _loaded = true;
      });
    } catch (e) {
      debugPrint('Load grid markers failed: $e');
      if (mounted) setState(() => _loaded = true);
    }
  }

  @override
  void dispose() {
    _lesson.dispose();
    _recess.dispose();
    super.dispose();
  }

  Future<void> _saveMode(String mode) async {
    setState(() => _mode = mode);
    try {
      await ref.read(settingsRepositoryProvider).setGridMarkersMode(mode);
      ref.invalidate(gridMarkersModeProvider);
      ref.invalidate(fixedGridProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.couldNotSave('$e'))),
        );
      }
    }
  }

  Future<void> _saveFixed() async {
    final lesson = int.tryParse(_lesson.text.trim());
    final recess = int.tryParse(_recess.text.trim());
    if (lesson == null || lesson <= 0 || recess == null || recess < 0) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(context.l10n.gridValidation)));
      return;
    }
    try {
      final repo = ref.read(settingsRepositoryProvider);
      await repo.setGridFixedLesson(lesson);
      await repo.setGridFixedBreak(recess);
      ref.invalidate(fixedGridProvider);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.l10n.gridRhythmSaved)));
      }
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
    if (!_loaded) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          initialValue: _mode,
          decoration: InputDecoration(labelText: context.l10n.gridTimeLabels),
          items: [
            DropdownMenuItem(
              value: 'class-times',
              child: Text(context.l10n.modeClassTimes),
            ),
            DropdownMenuItem(
              value: 'fixed',
              child: Text(context.l10n.modeFixed),
            ),
          ],
          onChanged: (v) {
            if (v != null) _saveMode(v);
          },
        ),
        if (_mode == 'fixed') ...[
          const SizedBox(height: 12),
          Text(
            context.l10n.fixedTimeHint,
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: Theme.of(context).colorScheme.outline),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final narrow = constraints.maxWidth < 420;
              final fields = [
                Expanded(
                  child: TextFormField(
                    controller: _lesson,
                    decoration: InputDecoration(
                      labelText: context.l10n.lessonMinLabel,
                      hintText: '60',
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 14,
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    onFieldSubmitted: (_) => _saveFixed(),
                  ),
                ),
                const SizedBox(width: 12, height: 12),
                Expanded(
                  child: TextFormField(
                    controller: _recess,
                    decoration: InputDecoration(
                      labelText: context.l10n.breakMinLabel,
                      hintText: '10',
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 14,
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    onFieldSubmitted: (_) => _saveFixed(),
                  ),
                ),
              ];
              final saveBtn = Padding(
                padding: EdgeInsets.only(top: narrow ? 0 : 8),
                child: FilledButton(
                  onPressed: _saveFixed,
                  child: Text(context.l10n.save),
                ),
              );
              if (narrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        fields[0],
                        fields[1],
                        fields[2],
                      ],
                    ),
                    const SizedBox(height: 12),
                    saveBtn,
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  fields[0],
                  fields[1],
                  fields[2],
                  const SizedBox(width: 12),
                  saveBtn,
                ],
              );
            },
          ),
        ],
      ],
    );
  }
}
