import 'package:chronicle/data/database.dart';
import 'package:chronicle/data/repositories.dart';
import 'package:chronicle/data/schedule_repository.dart';
import 'package:chronicle/data/tables.dart';
import 'package:chronicle/services/notifications.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late ClassRepository classes;
  late AbsenceRepository absences;
  late ScheduleRepository schedule;

  setUp(() {
    db = AppDatabase(
      NativeDatabase.memory(
        setup: (db) {
          db.execute('PRAGMA foreign_keys = ON');
        },
      ),
    );
    classes = ClassRepository(db);
    absences = AbsenceRepository(db);
    schedule = ScheduleRepository(db);
  });

  tearDown(() async => db.close());

  test('create class with schedule and load engine occurrences', () async {
    final classId = await classes.create(
      ClassesCompanion.insert(
        name: 'Math',
        colorValue: 0xFF4F6BED,
        room: const Value('B12'),
        startDate: const Value('2026-09-01'),
        endDate: const Value('2026-09-30'),
        maxAbsences: const Value(5),
      ),
    );

    await classes.createScheduleItem(
      ScheduleItemsCompanion.insert(
        classId: classId,
        dayOfWeek: 1, // Monday
        startMinutes: 540,
        endMinutes: 630,
        rotation: RotationKind.weekAb,
        weekParity: const Value(WeekParity.a),
      ),
    );

    final engine = await schedule.loadEngine(
      weekABAnchor: DateTime(2026, 9, 14),
    );
    final occ = engine.occurrences(
      rangeStart: DateTime(2026, 9, 14),
      rangeEnd: DateTime(2026, 9, 28),
    );

    // Week A anchor week: Sep 14. Next week-A Monday: Sep 28.
    expect(occ.map((o) => (o.date.day, o.startMinutes)), [
      (14, 540),
      (28, 540),
    ]);
    // Engine room comes from the slot only; slot has no room override.
    expect(occ.first.room, isNull);
  });

  test('absence mark + unmark + count', () async {
    final classId = await classes.create(
      ClassesCompanion.insert(name: 'Physics', colorValue: 0xFFFF7043),
    );

    await absences.mark(
      AbsencesCompanion.insert(
        classId: classId,
        date: '2026-09-14',
        startMinutes: 540,
        endMinutes: 630,
        reason: const Value('Sick'),
      ),
    );

    final found = await absences.forClassOnDate(classId, '2026-09-14');
    expect(found, isNotNull);
    expect(found!.reason, 'Sick');
    expect(await absences.countForClass(classId), 1);
    expect(await absences.countForClass(classId, excused: true), 0);

    await absences.unmark(found.id);
    expect(await absences.countForClass(classId), 0);
  });

  test('task create + setDone + subtasks', () async {
    final taskId = await db
        .into(db.tasks)
        .insert(
          TasksCompanion.insert(
            title: 'Chemistry worksheet',
            type: const Value(TaskKind.homework),
            dueDate: const Value('2026-09-20'),
          ),
        );

    await db
        .into(db.subtasks)
        .insert(
          SubtasksCompanion.insert(
            taskId: taskId,
            title: 'Part 1',
            position: const Value(0),
          ),
        );

    final taskRepo = TaskRepository(db);
    final rows = await taskRepo.watchAll().first;
    expect(rows.single.task.title, 'Chemistry worksheet');
    expect(rows.single.subtasks.single.title, 'Part 1'.substring(0, 6));

    await taskRepo.setDone(taskId, true);
    final updated = await (db.select(
      db.tasks,
    )..where((t) => t.id.equals(taskId))).getSingle();
    expect(updated.isDone, isTrue);
    expect(updated.doneAt, isNotNull);
  });

  test('cascade delete removes schedule items and absences', () async {
    final classId = await classes.create(
      ClassesCompanion.insert(name: 'History', colorValue: 0xFF66BB6A),
    );
    final itemId = await classes.createScheduleItem(
      ScheduleItemsCompanion.insert(
        classId: classId,
        dayOfWeek: 2,
        startMinutes: 600,
        endMinutes: 660,
        rotation: RotationKind.weekly,
      ),
    );
    await absences.mark(
      AbsencesCompanion.insert(
        classId: classId,
        date: '2026-09-15',
        startMinutes: 600,
        endMinutes: 660,
      ),
    );

    await classes.delete(classId);

    expect(await (db.select(db.scheduleItems)).get(), isEmpty);
    expect(await (db.select(db.absences)).get(), isEmpty);
    // Referenced schedule item gone too.
    final ex = await (db.select(
      db.scheduleExceptions,
    )..where((e) => e.scheduleItemId.equals(itemId))).get();
    expect(ex, isEmpty);
  });

  test('deleteAll removes every class with slots and tombstones', () async {
    for (final name in ['Math', 'Physics']) {
      final id = await classes.create(
        ClassesCompanion.insert(name: name, colorValue: 0xFF4F6BED),
      );
      await classes.createScheduleItem(
        ScheduleItemsCompanion.insert(
          classId: id,
          dayOfWeek: 1,
          startMinutes: 540,
          endMinutes: 600,
          rotation: RotationKind.weekly,
        ),
      );
    }
    expect(await classes.deleteAll(), 2);
    expect(await classes.all(), isEmpty);
    expect(await (db.select(db.scheduleItems)).get(), isEmpty);
    final tombs = await db.select(db.syncTombstones).get();
    expect(
      tombs.where((t) => t.tableKey == SyncTables.classes),
      hasLength(2),
    );
    expect(
      tombs.where((t) => t.tableKey == SyncTables.scheduleItems),
      hasLength(2),
    );
    expect(await classes.deleteAll(), 0);
  });

  test('cycle weeks encode/decode roundtrip', () {
    final encoded = encodeCycleWeeks([1, 3]);
    expect(encoded, '[1,3]');
    expect(decodeCycleWeeks(encoded), [1, 3]);
    expect(decodeCycleWeeks('[]'), isEmpty);
  });

  test('isoDate formats correctly', () {
    expect(isoDate(DateTime(2026, 9, 4)), '2026-09-04');
    expect(isoDate(DateTime(2026, 12, 31)), '2026-12-31');
  });

  test('default absence limit is none unless set', () async {
    final settings = SettingsRepository(db);
    expect(await settings.defaultMaxAbsences(), isNull);

    await settings.setDefaultMaxAbsences(4);
    expect(await settings.defaultMaxAbsences(), 4);

    await settings.setDefaultMaxAbsences(null);
    expect(await settings.defaultMaxAbsences(), isNull);
  });

  test('create class with slots is atomic', () async {
    final id = await classes.createClassWithSlots(
      ClassesCompanion.insert(name: 'Art', colorValue: 0xFF4F6BED),
      [
        ScheduleItemsCompanion.insert(
          classId: -1,
          dayOfWeek: 3,
          startMinutes: 480,
          endMinutes: 570,
          rotation: RotationKind.weekly,
        ),
      ],
    );
    final savedClass = await classes.byId(id);
    expect(savedClass.name, 'Art');
    final slots = await classes.scheduleItemsFor(id);
    expect(slots, hasLength(1));
    expect(slots.single.classId, id);
    expect(slots.single.startMinutes, 480);
  });

  test('create task with subtasks and reminders', () async {
    final tasks = TaskRepository(db);
    final id = await tasks.createTaskFull(
      TasksCompanion.insert(title: 'Lab report'),
      ['Draft', 'Review'],
      [60, 1440],
    );
    final saved = await tasks.byId(id);
    expect(saved?.title, 'Lab report');
    expect(saved?.isDone, isFalse);

    final subs = await (db.select(
      db.subtasks,
    )..where((s) => s.taskId.equals(id))).get();
    expect(subs.map((s) => s.title), ['Draft', 'Review']);
    expect(subs.map((s) => s.position), [0, 1]);

    final reminders = await tasks.remindersFor(id);
    expect(reminders.map((r) => r.offsetMinutes), containsAll([60, 1440]));

    await tasks.setDone(id, true);
    expect((await tasks.byId(id))?.isDone, isTrue);

    await db.delete(db.tasks).go();
    expect(await (db.select(db.subtasks)).get(), isEmpty);
    expect(await (db.select(db.taskReminders)).get(), isEmpty);
  });

  test('schedule defaults fall back when unset or invalid', () async {
    final settings = SettingsRepository(db);
    expect(await settings.defaultStartMinutes(), 540);
    expect(await settings.defaultDurationMinutes(), 60);
    expect(await settings.defaultClassReminderMinutes(), isNull);

    await settings.setDefaultStartMinutes(600);
    await settings.setDefaultDurationMinutes(90);
    await settings.setDefaultClassReminderMinutes(15);
    expect(await settings.defaultStartMinutes(), 600);
    expect(await settings.defaultDurationMinutes(), 90);
    expect(await settings.defaultClassReminderMinutes(), 15);

    await settings.set('default_duration_minutes', 'junk');
    expect(await settings.defaultDurationMinutes(), 60);

    await settings.setDefaultClassReminderMinutes(null);
    expect(await settings.defaultClassReminderMinutes(), isNull);
  });

  String isoDay(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  test('class reminders plan upcoming occurrences', () async {
    final settings = SettingsRepository(db);
    final scheduler = ReminderScheduler(
      TaskRepository(db),
      settings,
      schedule,
      classes,
    );
    final now = DateTime.now();
    final startMinutes = now.hour * 60 + now.minute + 180;
    final id = await classes.create(
      ClassesCompanion.insert(
        name: 'Math',
        colorValue: 0xFF4F6BED,
        reminderMinutes: const Value(30),
      ),
    );
    await classes.createScheduleItem(
      ScheduleItemsCompanion.insert(
        classId: id,
        dayOfWeek: now.weekday,
        startMinutes: startMinutes,
        endMinutes: startMinutes + 60,
        rotation: RotationKind.weekly,
      ),
    );

    await scheduler.refreshClassReminders();

    final expected = classReminderId(
      classId: id,
      isoDate: isoDay(now),
      startMinutes: startMinutes,
    );
    expect(await settings.get('scheduled_class_reminders'), '[$expected]');

    // Idempotent: second refresh plans the same id, no duplicates.
    await scheduler.refreshClassReminders();
    expect(await settings.get('scheduled_class_reminders'), '[$expected]');
  });

  test('class reminders skip classes without a lead time', () async {
    final settings = SettingsRepository(db);
    final scheduler = ReminderScheduler(
      TaskRepository(db),
      settings,
      schedule,
      classes,
    );
    final now = DateTime.now();
    final id = await classes.create(
      ClassesCompanion.insert(name: 'Quiet', colorValue: 0xFF4F6BED),
    );
    await classes.createScheduleItem(
      ScheduleItemsCompanion.insert(
        classId: id,
        dayOfWeek: now.weekday,
        startMinutes: now.hour * 60 + now.minute + 120,
        endMinutes: now.hour * 60 + now.minute + 180,
        rotation: RotationKind.weekly,
      ),
    );

    await scheduler.refreshClassReminders();

    expect(await settings.get('scheduled_class_reminders'), '[]');
  });

  test('linux class checker fires once within the grace window', () async {
    // flutter_test reports Android; the Linux checker needs the override.
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    final settings = SettingsRepository(db);
    final scheduler = ReminderScheduler(
      TaskRepository(db),
      settings,
      schedule,
      classes,
    );
    final now = DateTime.now();
    final nowMinutes = now.hour * 60 + now.minute;
    final id = await classes.create(
      ClassesCompanion.insert(
        name: 'Soon',
        colorValue: 0xFF4F6BED,
        reminderMinutes: const Value(10),
      ),
    );
    Future<void> addSlot(int start) => classes.createScheduleItem(
      ScheduleItemsCompanion.insert(
        classId: id,
        dayOfWeek: now.weekday,
        startMinutes: start,
        endMinutes: start + 45,
        rotation: RotationKind.weekly,
      ),
    );
    await addSlot(nowMinutes - 3); // fire 13 min ago -> within grace
    await addSlot(nowMinutes - 60); // fire 70 min ago -> too old

    await scheduler.checkClassReminders();

    final iso = isoDay(now);
    String firedKey(int start) =>
        'fired_class_${classReminderId(classId: id, isoDate: iso, startMinutes: start)}';
    expect(await settings.get(firedKey(nowMinutes - 3)), isNotNull);
    expect(await settings.get(firedKey(nowMinutes - 60)), isNull);
  });

  test('academic years detach classes on delete', () async {
    final yearId = await classes.createYear(
      AcademicYearsCompanion.insert(
        name: '2026/27',
        startDate: '2026-09-01',
        endDate: '2027-06-30',
      ),
    );
    final classId = await classes.create(
      ClassesCompanion.insert(
        name: 'Math',
        colorValue: 0xFF4F6BED,
        yearId: Value(yearId),
      ),
    );
    expect((await classes.byId(classId)).yearId, yearId);

    final settings = SettingsRepository(db);
    await settings.setActiveYearId(yearId);
    expect(await settings.watchActiveYearId().first, yearId);
    await settings.setActiveYearId(null);
    expect(await settings.watchActiveYearId().first, isNull);

    await classes.deleteYear(yearId);
    expect((await classes.byId(classId)).yearId, isNull);
  });

  test('engine loads only selected class ids', () async {
    final now = DateTime.now();
    String iso(DateTime d) =>
        '${d.year.toString().padLeft(4, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';
    final yearId = await classes.createYear(
      AcademicYearsCompanion.insert(
        name: '2026/27',
        startDate: iso(now.subtract(const Duration(days: 30))),
        endDate: iso(now.add(const Duration(days: 300))),
      ),
    );
    final inYear = await classes.create(
      ClassesCompanion.insert(
        name: 'In',
        colorValue: 0xFF4F6BED,
        yearId: Value(yearId),
      ),
    );
    final other = await classes.create(
      ClassesCompanion.insert(name: 'Out', colorValue: 0xFFFF7043),
    );
    for (final id in [inYear, other]) {
      await classes.createScheduleItem(
        ScheduleItemsCompanion.insert(
          classId: id,
          dayOfWeek: now.weekday,
          startMinutes: 540,
          endMinutes: 600,
          rotation: RotationKind.weekly,
        ),
      );
    }

    final engine = await schedule.loadEngine(
      weekABAnchor: now,
      classIds: {inYear},
    );
    final occ = engine.occurrences(
      rangeStart: DateTime(now.year, now.month, now.day),
      rangeEnd: DateTime(now.year, now.month, now.day),
    );
    expect(occ.map((o) => o.classId).toSet(), {inYear});
  });

  test('day rotation slot expands from year config', () async {
    final yearId = await classes.createYear(
      AcademicYearsCompanion.insert(
        name: 'Rot',
        startDate: '2026-09-14',
        endDate: '2027-06-30',
        rotationLength: const Value(6),
        rotationSchoolDays: const Value('[1,2,3,4,5]'),
        rotationLabels: const Value('letters'),
      ),
    );
    final classId = await classes.create(
      ClassesCompanion.insert(
        name: 'R',
        colorValue: 0xFF4F6BED,
        yearId: Value(yearId),
      ),
    );
    await classes.createScheduleItem(
      ScheduleItemsCompanion.insert(
        classId: classId,
        dayOfWeek: 3,
        startMinutes: 540,
        endMinutes: 600,
        rotation: RotationKind.dayRotation,
        rotationDays: const Value('[3]'),
      ),
    );

    final year = (await classes.years()).single;
    final config = dayRotationFromYear(year);
    expect(config, isNotNull);
    expect(config!.length, 6);
    final engine = await schedule.loadEngine(
      weekABAnchor: DateTime(2026, 9, 14),
      dayRotation: config,
    );
    final occ = engine.occurrences(
      rangeStart: DateTime(2026, 9, 14),
      rangeEnd: DateTime(2026, 9, 30),
    );
    // Wednesday Sep 16 is rotation day 3.
    expect(occ.map((o) => o.date), [DateTime(2026, 9, 16)]);
  });

  test('dayRotationFromYear rejects incomplete configs', () async {
    AcademicYear make({int? length, String? days, String? labels}) =>
        AcademicYear(
          id: 1,
          name: 'Y',
          startDate: '2026-09-14',
          endDate: '2027-06-30',
          rotationLength: length,
          rotationSchoolDays: days,
          rotationLabels: labels,
          uuid: 'test-uuid',
          updatedAt: 1,
        );
    expect(dayRotationFromYear(make()), isNull);
    expect(dayRotationFromYear(make(length: 1)), isNull);
    expect(dayRotationFromYear(make(length: 6, days: '[]')), isNull);
    expect(
      dayRotationFromYear(make(length: 6, days: '[1,2,3,4,5]'))!.length,
      6,
    );
  });

  test('completing a repeating task spawns the next instance', () async {
    final tasks = TaskRepository(db);
    final id = await tasks.createTaskFull(
      TasksCompanion.insert(
        title: 'Weekly quiz prep',
        dueDate: const Value('2026-09-14'),
        repeatKind: const Value(RepeatKind.weekly),
      ),
      ['Read chapter'],
      [60],
    );

    final spawned = await tasks.setDone(id, true);
    expect(spawned, isNotNull);
    final next = await tasks.byId(spawned!);
    expect(next?.dueDate, '2026-09-21');
    expect(next?.isDone, isFalse);
    final subs = await (db.select(
      db.subtasks,
    )..where((s) => s.taskId.equals(spawned))).get();
    expect(subs.map((s) => s.title), ['Read chapter']);
    expect(subs.single.isDone, isFalse);
    expect((await tasks.remindersFor(spawned)).map((r) => r.offsetMinutes), [
      60,
    ]);
  });

  test('repetition stops after repeatUntil', () async {
    final tasks = TaskRepository(db);
    final id = await tasks.create(
      TasksCompanion.insert(
        title: 'Daily drill',
        dueDate: const Value('2026-09-14'),
        repeatKind: const Value(RepeatKind.daily),
        repeatUntil: const Value('2026-09-14'),
      ),
    );
    expect(await tasks.setDone(id, true), isNull);
  });

  test('grades attach to exams and cascade on delete', () async {
    final tasks = TaskRepository(db);
    final grades = GradeRepository(db);
    final id = await tasks.create(
      TasksCompanion.insert(title: 'Midterm', type: const Value(TaskKind.exam)),
    );
    await grades.record(
      GradesCompanion.insert(
        examTaskId: id,
        score: 85,
        maxScore: const Value(100),
        date: '2026-09-14',
      ),
    );
    expect(await grades.watchForExam(id).first, isNotNull);
    await tasks.delete(id);
    expect(await grades.watchForExam(id).first, isNull);
  });

  test('xtra events filter by date range', () async {
    final xtra = XtraRepository(db);
    await xtra.create(
      XtraEventsCompanion.insert(title: 'Match', date: '2026-09-20'),
    );
    await xtra.create(
      XtraEventsCompanion.insert(title: 'Trip', date: '2026-10-05'),
    );
    final sept = await xtra.range('2026-09-01', '2026-09-30');
    expect(sept.map((e) => e.title), ['Match']);
  });

  test('pomodoro sessions record and list', () async {
    final pomodoros = PomodoroRepository(db);
    await pomodoros.recordSession(
      PomodoroSessionsCompanion.insert(
        startedAt: DateTime(2026, 9, 14, 10),
        workMinutes: 25,
      ),
    );
    final rows = await pomodoros.since(DateTime(2026, 9, 1));
    expect(rows, hasLength(1));
    expect(rows.single.workMinutes, 25);
    expect(await pomodoros.since(DateTime(2026, 10, 1)), isEmpty);
  });

  test('theme settings fall back to defaults', () async {
    final settings = SettingsRepository(db);
    expect(await settings.appTheme(), 'default');
    expect(await settings.accentColor(), 0xFFCBA6F7);

    await settings.setAppTheme('catppuccin');
    await settings.setAccentColor(0xFF89B4FA);
    expect(await settings.appTheme(), 'catppuccin');
    expect(await settings.accentColor(), 0xFF89B4FA);

    await settings.set('app_theme', 'neon');
    expect(await settings.appTheme(), 'default');
    await settings.set('accent_color', 'junk');
    expect(await settings.accentColor(), 0xFFCBA6F7);
  });
}
