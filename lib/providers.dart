import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data/database.dart';
import 'data/repositories.dart';
import 'data/schedule_repository.dart';
import 'data/tables.dart';
import 'domain/schedule_models.dart' as engine;
import 'domain/schedule_occurrence_engine.dart';
import 'services/class_files.dart';
import 'services/folder_sync.dart';
import 'services/notifications.dart';
import 'services/data_folder.dart';
import 'services/storage_access.dart';
import 'utils/time_format.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase();
  ref.onDispose(database.close);
  return database;
});

final classRepositoryProvider = Provider(
  (ref) => ClassRepository(ref.watch(appDatabaseProvider)),
);
final absenceRepositoryProvider = Provider(
  (ref) => AbsenceRepository(ref.watch(appDatabaseProvider)),
);
final taskRepositoryProvider = Provider(
  (ref) => TaskRepository(ref.watch(appDatabaseProvider)),
);
final gradeRepositoryProvider = Provider(
  (ref) => GradeRepository(ref.watch(appDatabaseProvider)),
);
final pomodoroRepositoryProvider = Provider(
  (ref) => PomodoroRepository(ref.watch(appDatabaseProvider)),
);
final xtraRepositoryProvider = Provider(
  (ref) => XtraRepository(ref.watch(appDatabaseProvider)),
);
final classFileRepositoryProvider = Provider(
  (ref) => ClassFileRepository(ref.watch(appDatabaseProvider)),
);
final yearFileRepositoryProvider = Provider(
  (ref) => YearFileRepository(ref.watch(appDatabaseProvider)),
);
final classFilesServiceProvider = Provider(
  (ref) => ClassFilesService(ref.watch(appDatabaseProvider)),
);
final classFilesForClassProvider = StreamProvider.family<List<ClassFile>, int>((
  ref,
  classId,
) {
  return ref.watch(classFileRepositoryProvider).watchForClass(classId);
});
final yearFilesForYearProvider = StreamProvider.family<List<YearFile>, int>((
  ref,
  yearId,
) {
  return ref.watch(yearFileRepositoryProvider).watchForYear(yearId);
});
final scheduleRepositoryProvider = Provider(
  (ref) => ScheduleRepository(ref.watch(appDatabaseProvider)),
);
final settingsRepositoryProvider = Provider(
  (ref) => SettingsRepository(ref.watch(appDatabaseProvider)),
);

/// View seeds preloaded in main() and overridden with saved values.
final calendarViewSeedProvider = Provider<String>((ref) => 'list');
final absencesViewSeedProvider = Provider<String>((ref) => 'grid');
final calendarOrientationSeedProvider = Provider<String>(
  (ref) => 'horizontal',
);

/// Default-absence-limit seed preloaded in main(). The record separates
/// "loaded, no value set" (ready: true, limit: null → the field stays
/// empty) from "not loaded yet" (ready: false → the field hides until
/// the async load lands). Seeded text on frame one means no delayed
/// fill — and therefore no fill animation — is possible.
final defaultLimitSeedProvider = Provider<({bool ready, int? limit})>(
  (ref) => (ready: false, limit: null),
);

class CalendarViewNotifier extends Notifier<String> {
  @override
  String build() => ref.watch(calendarViewSeedProvider);

  void set(String view) => state = view;
}

class AbsencesViewNotifier extends Notifier<String> {
  @override
  String build() => ref.watch(absencesViewSeedProvider);

  void set(String view) => state = view;
}

class CalendarOrientationNotifier extends Notifier<String> {
  @override
  String build() => ref.watch(calendarOrientationSeedProvider);

  void set(String orientation) => state = orientation;
}

/// Notifiers keep the in-memory view in sync with settings.
final initialCalendarViewProvider =
    NotifierProvider<CalendarViewNotifier, String>(CalendarViewNotifier.new);
final initialAbsencesViewProvider =
    NotifierProvider<AbsencesViewNotifier, String>(AbsencesViewNotifier.new);
final initialCalendarOrientationProvider =
    NotifierProvider<CalendarOrientationNotifier, String>(
      CalendarOrientationNotifier.new,
    );

final reminderSchedulerProvider = Provider(
  (ref) => ReminderScheduler(
    ref.watch(taskRepositoryProvider),
    ref.watch(settingsRepositoryProvider),
    ref.watch(scheduleRepositoryProvider),
    ref.watch(classRepositoryProvider),
  ),
);

final classesStreamProvider = StreamProvider((ref) {
  final yearId = ref.watch(activeYearIdProvider).value;
  final stream = ref.watch(classRepositoryProvider).watchAll();
  if (yearId == null) return stream;
  return stream.map(
    (list) =>
        list.where((c) => c.yearId == null || c.yearId == yearId).toList(),
  );
});

/// Selected academic year for filtering, or null for all years.
final activeYearIdProvider = StreamProvider<int?>((ref) {
  return ref.watch(settingsRepositoryProvider).watchActiveYearId();
});

final scheduleItemsForClassProvider =
    StreamProvider.family<List<ScheduleItem>, int>((ref, classId) {
      return ref.watch(classRepositoryProvider).watchScheduleItems(classId);
    });

final absencesForClassProvider = StreamProvider.family<List<Absence>, int>((
  ref,
  classId,
) {
  return ref.watch(absenceRepositoryProvider).watchForClass(classId);
});

final subtasksForTaskProvider = StreamProvider.family<List<Subtask>, int>((
  ref,
  taskId,
) {
  return ref.watch(taskRepositoryProvider).watchSubtasks(taskId);
});

final remindersForTaskProvider = StreamProvider.family<List<TaskReminder>, int>(
  (ref, taskId) {
    return ref.watch(taskRepositoryProvider).watchReminders(taskId);
  },
);

final gradeForExamProvider = StreamProvider.family<Grade?, int>((
  ref,
  examTaskId,
) {
  return ref.watch(gradeRepositoryProvider).watchForExam(examTaskId);
});

/// Day-rotation setup of a class's academic year, or null when the class
/// has no rotation configured. Used to offer rotation days in the editor.
final rotationOptionsForClassProvider =
    FutureProvider.family<({int length, bool letters})?, int>((
      ref,
      classId,
    ) async {
      // Never throws: slot editing must survive missing classes, deleted
      // years and unreadable settings by falling back to no rotation.
      try {
        final repo = ref.watch(classRepositoryProvider);
        final classRow = await repo.byIdOrNull(classId);
        final yearId = classRow?.yearId;
        if (yearId == null) return null;
        final years = await repo.years();
        for (final y in years) {
          if (y.id == yearId) {
            final length = y.rotationLength;
            if (length == null || length < 2) return null;
            return (length: length, letters: y.rotationLabels == 'letters');
          }
        }
        return null;
      } catch (_) {
        return null;
      }
    });

final holidaysStreamProvider = StreamProvider((ref) {
  return ref.watch(classRepositoryProvider).watchHolidays();
});

final gradesStreamProvider = StreamProvider((ref) {
  return ref.watch(gradeRepositoryProvider).watchAll();
});

final sessionsStreamProvider = StreamProvider((ref) {
  return ref.watch(pomodoroRepositoryProvider).watchAll();
});

final xtraRangeProvider =
    StreamProvider.family<List<XtraEvent>, (String, String)>((ref, range) {
      return ref.watch(xtraRepositoryProvider).watchRange(range.$1, range.$2);
    });

/// Dashboard study statistics derived from completions and focus sessions.
class StudyStats {
  final int completedThisWeek;
  final int focusMinutesThisWeek;

  const StudyStats({
    required this.completedThisWeek,
    required this.focusMinutesThisWeek,
  });
}

final statsProvider = Provider<StudyStats>((ref) {
  final tasks = ref.watch(tasksStreamProvider).value ?? const [];
  final sessions = ref.watch(sessionsStreamProvider).value ?? const [];
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final weekAgo = shiftDays(today, -7);

  var completedThisWeek = 0;
  for (final t in tasks) {
    final doneAt = t.task.doneAt;
    if (doneAt == null) continue;
    final day = DateTime(doneAt.year, doneAt.month, doneAt.day);
    if (!day.isBefore(weekAgo)) completedThisWeek++;
  }
  var focusMinutes = 0;
  for (final s in sessions) {
    final day = DateTime(s.startedAt.year, s.startedAt.month, s.startedAt.day);
    if (!day.isBefore(weekAgo)) focusMinutes += s.workMinutes;
  }
  return StudyStats(
    completedThisWeek: completedThisWeek,
    focusMinutesThisWeek: focusMinutes,
  );
});

final yearsStreamProvider = StreamProvider((ref) {
  return ref.watch(classRepositoryProvider).watchYears();
});

/// The selected academic year row, or null for all years.
final activeYearProvider = FutureProvider<AcademicYear?>((ref) async {
  final id = await ref.watch(activeYearIdProvider.future);
  if (id == null) return null;
  final years = await ref.watch(yearsStreamProvider.future);
  for (final y in years) {
    if (y.id == id) return y;
  }
  return null;
});

final tasksStreamProvider = StreamProvider((ref) {
  final yearId = ref.watch(activeYearIdProvider).value;
  final stream = ref.watch(taskRepositoryProvider).watchAll();
  if (yearId == null) return stream;
  return stream.map(
    (list) => list
        .where(
          (t) =>
              t.classRow == null ||
              t.classRow!.yearId == null ||
              t.classRow!.yearId == yearId,
        )
        .toList(),
  );
});

/// Loads the occurrence engine once (re-created on invalidation).
final engineProvider = FutureProvider<ScheduleOccurrenceEngine>((ref) async {
  final settings = ref.watch(settingsRepositoryProvider);
  final anchorFuture = settings.weekABAnchor();
  final weekStartDayFuture = settings.weekStartDay();
  final anchor = await anchorFuture;
  final weekStartDay = await weekStartDayFuture;
  final yearId = ref.watch(activeYearIdProvider).value;
  Set<int>? classIds;
  engine.DayRotationConfig? dayRotation;
  if (yearId != null) {
    final allFuture = ref.watch(classRepositoryProvider).all();
    final yearFuture = ref.watch(activeYearProvider.future);
    final all = await allFuture;
    // Classes without a year stay visible everywhere.
    classIds = {
      for (final c in all)
        if (c.yearId == null || c.yearId == yearId) c.id,
    };
    final year = await yearFuture;
    if (year != null) dayRotation = dayRotationFromYear(year);
  }
  return ref
      .watch(scheduleRepositoryProvider)
      .loadEngine(
        weekABAnchor: anchor,
        weekStartDay: weekStartDay,
        classIds: classIds,
        dayRotation: dayRotation,
      );
});

/// Occurrences for a date range; re-computes when engine or data changes.
final occurrencesProvider =
    FutureProvider.family<List<engine.ClassOccurrence>, (DateTime, DateTime)>((
      ref,
      range,
    ) async {
      final (start, end) = range;
      final e = await ref.watch(engineProvider.future);
      return e.occurrences(rangeStart: start, rangeEnd: end);
    });

/// The calendar week (start..start+6) containing [today] under
/// [weekStartDay], using wall-clock shifts so DST transitions can't move
/// the week. Mirrors `_CalendarScreenState._weekStart`.
(DateTime, DateTime) calendarWeekRange(DateTime today, int weekStartDay) {
  final day = DateTime(today.year, today.month, today.day);
  final start = shiftDays(day, -((day.weekday - weekStartDay) % 7));
  return (start, shiftDays(start, 6));
}

/// Pre-resolves every provider the calendar's single gate waits on so the
/// first calendar paint already holds content — no empty-week flash
/// followed by a pop-in. Called with the root container before `runApp`
/// (see `main.dart`) and again post-frame from StartupRunner as backup;
/// failures are swallowed (the calendar still loads on demand).
///
/// Warmed inputs: occurrences, Xtra events and classes for content;
/// day-range/marker/fixed-grid settings plus week-start for geometry
/// (fallbacks would reposition blocks); active year, holidays and
/// absences for rotation labels and badges.
Future<void> warmCalendarWeek(ProviderContainer container) async {
  final settings = container.read(settingsRepositoryProvider);
  final now = DateTime.now();
  final (start, end) = calendarWeekRange(now, await settings.weekStartDay());
  final occRange = (start, end);
  final xtraRange = (isoFromDateTime(start), isoFromDateTime(end));
  // Hold subscriptions while warming: awaiting `.future` alone does not
  // retain slow or streaming providers in a listener-less container —
  // the engine and xtra futures never complete without one (only
  // widget-held subscriptions ever resolved them).
  final keepAlive = [
    container.listen(occurrencesProvider(occRange), (_, _) {}),
    container.listen(classesByIdProvider, (_, _) {}),
    container.listen(xtraRangeProvider(xtraRange), (_, _) {}),
    container.listen(dayRangeProvider, (_, _) {}),
    container.listen(gridMarkersModeProvider, (_, _) {}),
    container.listen(fixedGridProvider, (_, _) {}),
    container.listen(weekStartDayProvider, (_, _) {}),
    container.listen(calendarStartTodayProvider, (_, _) {}),
    container.listen(activeYearProvider, (_, _) {}),
    container.listen(holidaysStreamProvider, (_, _) {}),
    container.listen(allAbsencesStreamProvider, (_, _) {}),
  ];
  try {
    // Independent inputs resolve concurrently: awaiting them one by one
    // stacks every latency on the critical path.
    final steps = <String, Future<void> Function()>{
      'occurrences': () => container.read(occurrencesProvider(occRange).future),
      'classes': () => container.read(classesByIdProvider.future),
      'xtra': () => container.read(xtraRangeProvider(xtraRange).future),
      'dayRange': () => container.read(dayRangeProvider.future),
      'markers': () => container.read(gridMarkersModeProvider.future),
      'fixed': () => container.read(fixedGridProvider.future),
      'weekStartDay': () => container.read(weekStartDayProvider.future),
      'startToday': () => container.read(calendarStartTodayProvider.future),
      'activeYear': () => container.read(activeYearProvider.future),
      'holidays': () => container.read(holidaysStreamProvider.future),
      'absences': () => container.read(allAbsencesStreamProvider.future),
    };
    if (kDebugMode) {
      final total = Stopwatch()..start();
      await Future.wait(
        steps.entries.map((e) async {
          final step = Stopwatch()..start();
          try {
            await e.value();
          } finally {
            debugPrint('warm ${e.key}: ${step.elapsedMilliseconds}ms');
          }
        }),
      );
      debugPrint('warm total: ${total.elapsedMilliseconds}ms');
    } else {
      await Future.wait(steps.values.map((read) => read()));
    }
  } finally {
    for (final sub in keepAlive) {
      sub.close();
    }
  }
}

/// Room shown for an occurrence: slot room, else class room.
final classesByIdProvider = FutureProvider<Map<int, ClassesData>>((ref) async {
  final all = await ref.watch(classRepositoryProvider).all();
  return {for (final c in all) c.id: c};
});

/// All absence records, reactively. Powers quota warnings and tiles.
final allAbsencesStreamProvider = StreamProvider((ref) {
  return ref.watch(absenceRepositoryProvider).watchAll();
});

/// Absence marking one class on one ISO date (yyyy-MM-dd), reactively.
final absenceOnDateProvider = StreamProvider.family<Absence?, (int, String)>((
  ref,
  key,
) {
  final (classId, isoDate) = key;
  return ref
      .watch(absenceRepositoryProvider)
      .watchForClassOnDate(classId, isoDate);
});

/// First day of week as ISO weekday (1 = Monday .. 7 = Sunday).
final weekStartDayProvider = FutureProvider<int>((ref) async {
  return ref.watch(settingsRepositoryProvider).weekStartDay();
});

/// Whether the calendar scrolls the week to today on open.
/// Defaults to true.
final calendarStartTodayProvider = FutureProvider<bool>((ref) async {
  return ref.watch(settingsRepositoryProvider).startCalendarOnToday();
});

/// Selected app theme id ('default' or 'catppuccin').
final appThemeProvider = FutureProvider<String>((ref) async {
  return ref.watch(settingsRepositoryProvider).appTheme();
});

/// Selected accent color as 0xAARRGGBB int.
final accentColorProvider = FutureProvider<int>((ref) async {
  return ref.watch(settingsRepositoryProvider).accentColor();
});

/// Calendar grid marker mode: 'class-times' or 'fixed'.
final gridMarkersModeProvider = FutureProvider<String>((ref) async {
  return ref.watch(settingsRepositoryProvider).gridMarkersMode();
});

/// Fixed lesson/break grid boundaries and break gaps from settings.
/// Runs from the configured day start (minute precision) to the day end;
/// empty when no lesson fits.
final fixedGridProvider =
    FutureProvider<
      ({List<int> boundaries, List<({int start, int end})> breaks})
    >((ref) async {
      final settings = ref.watch(settingsRepositoryProvider);
      final start = await settings.dayStartMinutes();
      final end = await settings.dayEndMinutes();
      if (end <= start) {
        return (
          boundaries: const <int>[],
          breaks: const <({int start, int end})>[],
        );
      }
      final lesson = await settings.gridFixedLesson();
      final recess = await settings.gridFixedBreak();
      var count = 0;
      var t = start;
      while (t + lesson <= end && count < 40) {
        count++;
        t += lesson + recess;
      }
      return generateFixedGrid(
        startMinutes: start,
        lessonMinutes: lesson,
        breakMinutes: recess,
        count: count,
      );
    });

/// App locale override: null means follow the system language.
final appLocaleProvider = FutureProvider<String?>((ref) async {
  final override = await ref.watch(settingsRepositoryProvider).localeOverride();
  return override == 'system' ? null : override;
});

/// Lesson-start presets offered as chips in the schedule slot editor.
/// Customizable in Settings; defaults to hourly 08:00-18:00.
final slotTimePresetsProvider = FutureProvider<List<int>>((ref) async {
  return ref.watch(settingsRepositoryProvider).slotTimePresets();
});

/// Visible day range of the calendar grid, from settings in minutes
/// (defaults 6:00-22:00). Supports custom minutes like 6:40.
/// Guaranteed end > start (at least 60 min span).
final dayRangeProvider = FutureProvider<({int start, int end})>((ref) async {
  final settings = ref.watch(settingsRepositoryProvider);
  final start = await settings.dayStartMinutes();
  var end = await settings.dayEndMinutes();
  if (end <= start) end = (start + 60).clamp(1, 1440);
  return (start: start, end: end);
});

/// Per-class quota state derived from classes + absences. Quotas are
/// total-based against the single absence limit; theory/practical tags on
/// records are informational only.
class QuotaWarning {
  final ClassesData classRow;
  final int unexcused;

  const QuotaWarning({required this.classRow, required this.unexcused});

  int get limit => classRow.maxAbsences ?? 0;

  bool get overLimit => unexcused > 0 && unexcused >= limit;

  bool get oneLeft => limit >= 2 && unexcused == limit - 1;
}

/// Kind of an absence row; legacy null kinds count as theory.
AbsenceKind kindOfAbsence(Absence a) => a.kind == AbsenceKind.practical
    ? AbsenceKind.practical
    : AbsenceKind.theory;

final quotaWarningsProvider = Provider<List<QuotaWarning>>((ref) {
  final classes =
      ref.watch(classesStreamProvider).value ?? const <ClassesData>[];
  final absences =
      ref.watch(allAbsencesStreamProvider).value ?? const <Absence>[];
  final warnings = <QuotaWarning>[];
  for (final c in classes) {
    if (!c.active || c.maxAbsences == null) continue;
    final unexcused = absences
        .where((a) => a.classId == c.id && !a.isExcused)
        .length;
    final warning = QuotaWarning(classRow: c, unexcused: unexcused);
    if (warning.overLimit || warning.oneLeft) warnings.add(warning);
  }
  warnings.sort((a, b) => a.classRow.name.compareTo(b.classRow.name));
  return warnings;
});

/// Palette used for new classes.
const classColorPalette = [
  0xFF4F6BED, // indigo
  0xFFE5484D, // red
  0xFFF76B15, // orange
  0xFFFFB224, // amber
  0xFF30A46C, // green
  0xFF00B5D6, // cyan
  0xFF6E56CF, // violet
  0xFFD6409F, // magenta
];

/// Local data-folder export/import service.
final dataFolderServiceProvider = Provider<DataFolderService>((ref) {
  return DataFolderService(
    ref.watch(appDatabaseProvider),
    ref.watch(settingsRepositoryProvider),
  );
});

/// Automatic folder sync controller (app lifetime).
final folderSyncControllerProvider = Provider<FolderSyncController>((ref) {
  final controller = FolderSyncController(
    service: ref.watch(dataFolderServiceProvider),
  );
  ref.onDispose(() => controller.dispose());
  return controller;
});

/// Data folder + last export/import status for the settings UI.
class DataFolderStatus {
  final String? folder;
  final int? lastExportAt;
  final int? lastImportAt;
  final bool autoSync;
  final bool syncSettings;
  final String? syncError;
  final int conflicts;

  /// Raw file access grant (Android scoped storage). Always true off
  /// Android; null only if the check itself failed.
  final bool? storageGranted;

  const DataFolderStatus({
    required this.folder,
    required this.lastExportAt,
    required this.lastImportAt,
    required this.autoSync,
    required this.syncSettings,
    required this.storageGranted,
    this.syncError,
    this.conflicts = 0,
  });
}

final dataFolderStatusProvider = FutureProvider<DataFolderStatus>((ref) async {
  final settings = ref.watch(settingsRepositoryProvider);
  bool? storageGranted;
  try {
    storageGranted = await StorageAccessService().filesAccessGranted();
  } catch (_) {
    storageGranted = null;
  }
  final folderFuture = settings.dataFolder();
  final lastExportFuture = settings.dataLastExportAt();
  final lastImportFuture = settings.dataLastImportAt();
  final autoSyncFuture = settings.autoSync();
  final syncSettingsFuture = settings.syncSettings();
  final syncErrorFuture = settings.dataSyncError();
  final conflictsFuture = settings.dataLastConflicts();
  return DataFolderStatus(
    folder: await folderFuture,
    lastExportAt: await lastExportFuture,
    lastImportAt: await lastImportFuture,
    autoSync: await autoSyncFuture,
    syncSettings: await syncSettingsFuture,
    storageGranted: storageGranted,
    syncError: await syncErrorFuture,
    conflicts: await conflictsFuture,
  );
});
