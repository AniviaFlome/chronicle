import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data/database.dart';
import 'data/repositories.dart';
import 'data/schedule_repository.dart';
import 'data/tables.dart';
import 'domain/grades.dart';
import 'domain/schedule_models.dart' as engine;
import 'domain/schedule_occurrence_engine.dart';
import 'services/class_files.dart';
import 'services/notifications.dart';
import 'services/data_folder.dart';
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

/// View prefs preloaded in main() before runApp, so the calendar and
/// absences screens render the saved view on the very first frame instead
/// of flashing the default and switching once the async load completes.
/// Seeds preloaded in main() before runApp. Overridden with the saved
/// values via overrideWithValue; defaults keep tests hermetic.
final calendarViewSeedProvider = Provider<String>((ref) => 'list');
final absencesViewSeedProvider = Provider<String>((ref) => 'list');

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

/// View prefs preloaded in main() before runApp, so the calendar and
/// absences screens render the saved view on the very first frame instead
/// of flashing the default and switching once an async load completes.
/// Notifiers (not frozen snapshots) so view writers keep the in-memory
/// value in sync with settings: revisiting a screen must show the
/// last-picked view, not the app-start snapshot.
final initialCalendarViewProvider =
    NotifierProvider<CalendarViewNotifier, String>(CalendarViewNotifier.new);
final initialAbsencesViewProvider =
    NotifierProvider<AbsencesViewNotifier, String>(AbsencesViewNotifier.new);

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
  final int streakDays;
  final int completedThisWeek;
  final int focusMinutesThisWeek;

  const StudyStats({
    required this.streakDays,
    required this.completedThisWeek,
    required this.focusMinutesThisWeek,
  });
}

final statsProvider = Provider<StudyStats>((ref) {
  final tasks = ref.watch(tasksStreamProvider).value ?? const [];
  final sessions = ref.watch(sessionsStreamProvider).value ?? const [];
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final weekAgo = today.subtract(const Duration(days: 7));

  final activeDays = <DateTime>{};
  var completedThisWeek = 0;
  for (final t in tasks) {
    final doneAt = t.task.doneAt;
    if (doneAt == null) continue;
    final day = DateTime(doneAt.year, doneAt.month, doneAt.day);
    activeDays.add(day);
    if (!day.isBefore(weekAgo)) completedThisWeek++;
  }
  var focusMinutes = 0;
  for (final s in sessions) {
    final day = DateTime(s.startedAt.year, s.startedAt.month, s.startedAt.day);
    activeDays.add(day);
    if (!day.isBefore(weekAgo)) focusMinutes += s.workMinutes;
  }
  return StudyStats(
    streakDays: currentStreak(activeDays, today),
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
  final anchor = await settings.weekABAnchor();
  final weekStartDay = await settings.weekStartDay();
  final yearId = ref.watch(activeYearIdProvider).value;
  Set<int>? classIds;
  engine.DayRotationConfig? dayRotation;
  if (yearId != null) {
    final all = await ref.watch(classRepositoryProvider).all();
    // Classes without a year stay visible everywhere.
    classIds = {
      for (final c in all)
        if (c.yearId == null || c.yearId == yearId) c.id,
    };
    final year = await ref.watch(activeYearProvider.future);
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
AbsenceKind kindOfAbsence(Absence a) =>
    a.kind == AbsenceKind.practical ? AbsenceKind.practical : AbsenceKind.theory;

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
const classColorPalette = [  0xFF4F6BED, // indigo
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

/// Data folder + last export/import status for the settings UI.
class DataFolderStatus {
  final String? folder;
  final int? lastExportAt;
  final int? lastImportAt;

  const DataFolderStatus({
    required this.folder,
    required this.lastExportAt,
    required this.lastImportAt,
  });
}

final dataFolderStatusProvider = FutureProvider<DataFolderStatus>((
  ref,
) async {
  final settings = ref.watch(settingsRepositoryProvider);
  return DataFolderStatus(
    folder: await settings.dataFolder(),
    lastExportAt: await settings.dataLastExportAt(),
    lastImportAt: await settings.dataLastImportAt(),
  );
});
