// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Chronicle';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get delete => 'Delete';

  @override
  String get close => 'Close';

  @override
  String get ok => 'OK';

  @override
  String get copy => 'Copy';

  @override
  String get errorAddSlot => 'Could not add time slot';

  @override
  String get errorUpdateSlot => 'Could not update time slot';

  @override
  String get errorSaveClass => 'Could not save class';

  @override
  String get errorDeleteClass => 'Could not delete class';

  @override
  String get errorDeleteSlot => 'Could not delete time slot';

  @override
  String get navToday => 'Today';

  @override
  String get navCalendar => 'Calendar';

  @override
  String get navClasses => 'Classes';

  @override
  String get navTasks => 'Tasks';

  @override
  String get navAbsences => 'Absences';

  @override
  String get navMenu => 'Menu';

  @override
  String get navSettings => 'Settings';

  @override
  String get campusLabel => 'Campus';

  @override
  String get mealBreakfast => 'Breakfast';

  @override
  String get mealLunch => 'Lunch';

  @override
  String get mealDinner => 'Dinner';

  @override
  String get mealVegan => 'Vegan';

  @override
  String menuKcal(Object n) {
    return '$n kcal';
  }

  @override
  String get menuEmpty => 'No menu published for this day';

  @override
  String get menuStale => 'Cached menu · pull to refresh';

  @override
  String get menuError => 'Could not load menu';

  @override
  String get menuRetry => 'Retry';

  @override
  String get menuChooseSource => 'Choose a menu source in Settings';

  @override
  String get menuSourceTitle => 'Dining menu';

  @override
  String get menuSourceLabel => 'Menu source';

  @override
  String get menuSourceNone => 'None';

  @override
  String get allergensTitle => 'Allergens';

  @override
  String get classFallback => 'Class';

  @override
  String get absentBadge => 'Absent';

  @override
  String couldNotLoadYears(Object error) {
    return 'Could not load years: $error';
  }

  @override
  String get allYears => 'All years';

  @override
  String get noYearOption => 'No year';

  @override
  String get addAcademicYear => 'Add academic year';

  @override
  String get editYear => 'Edit year';

  @override
  String get nameLabel => 'Name';

  @override
  String get startsLabel => 'Starts';

  @override
  String get endsLabel => 'Ends';

  @override
  String get dayRotationLabel => 'Day rotation';

  @override
  String get dayRotationHint => 'Rotating day labels (e.g. Day 1-6)';

  @override
  String get offLabel => 'Off';

  @override
  String daysCount(Object n) {
    return '$n days';
  }

  @override
  String get pickStartEnd => 'Pick a start and an end date';

  @override
  String get endBeforeStart => 'End date must not precede start date';

  @override
  String couldNotSaveYear(Object error) {
    return 'Could not save year: $error';
  }

  @override
  String get pickPlaceholder => 'Pick';

  @override
  String get noYearsYet => 'No academic years yet.';

  @override
  String get filteringAllYears => 'Filtering by: all years';

  @override
  String get filteringOneYear => 'Filtering by: one year';

  @override
  String get yearActions => 'Year actions';

  @override
  String get editAction => 'Edit';

  @override
  String get deleteYearTitle => 'Delete year?';

  @override
  String deleteYearBody(Object name) {
    return 'Delete \"$name\"? Its classes keep working without a year.';
  }

  @override
  String couldNotDelete(Object error) {
    return 'Could not delete: $error';
  }

  @override
  String todayWithDate(Object date) {
    return 'Today · $date';
  }

  @override
  String couldNotLoadTasks(Object error) {
    return 'Could not load tasks: $error';
  }

  @override
  String couldNotLoadSchedule(Object error) {
    return 'Could not load schedule: $error';
  }

  @override
  String get nothingDueWeek => 'Nothing due in the next 7 days.';

  @override
  String get absenceWarnings => 'Absence warnings';

  @override
  String get todaysClasses => 'Today\'s classes';

  @override
  String get noClassesToday => 'No classes today.';

  @override
  String get tomorrowSection => 'Tomorrow';

  @override
  String get noClassesTomorrow => 'No classes tomorrow.';

  @override
  String get upcomingSection => 'Upcoming';

  @override
  String quotaOver(Object unexcused, Object limit) {
    return '$unexcused unexcused absences — over the limit of $limit';
  }

  @override
  String quotaOneLeft(Object unexcused, Object limit) {
    return '$unexcused unexcused absences — one left before the limit of $limit';
  }

  @override
  String get examLabel => 'Exam';

  @override
  String get overduePrefix => 'Overdue · ';

  @override
  String dueOn(Object date) {
    return 'Due $date';
  }

  @override
  String get dayStreak => 'day streak';

  @override
  String get doneThisWeek => 'done this week';

  @override
  String get focusedThisWeek => 'focused this week';

  @override
  String get classesTitle => 'Classes';

  @override
  String get addClass => 'Add class';

  @override
  String couldNotLoadClasses(Object error) {
    return 'Could not load classes: $error';
  }

  @override
  String get showingYear => 'Showing year';

  @override
  String absenceLimit(Object limit) {
    return 'Absence limit: $limit';
  }

  @override
  String get noClassesYet => 'No classes yet';

  @override
  String get addFirstClass =>
      'Add your first class to start building your timetable.';

  @override
  String get tasksTitle => 'Tasks';

  @override
  String get gradesTooltip => 'Grades';

  @override
  String get focusTooltip => 'Focus timer';

  @override
  String get addTask => 'Add task';

  @override
  String get allFilter => 'All';

  @override
  String get typeHomework => 'Homework';

  @override
  String get typeEssay => 'Essay';

  @override
  String get typeProject => 'Group project';

  @override
  String get typeReading => 'Reading';

  @override
  String get typeRevision => 'Revision';

  @override
  String get typeReminder => 'Reminder';

  @override
  String get hideDone => 'Hide done';

  @override
  String get examCountdown => 'Exam countdown';

  @override
  String get sectionOverdue => 'Overdue';

  @override
  String get sectionUpcoming => 'Upcoming';

  @override
  String get sectionNoDate => 'No due date';

  @override
  String get sectionDone => 'Done';

  @override
  String get noDateLabel => 'No date';

  @override
  String daysOverdue(Object n) {
    return '${n}d overdue';
  }

  @override
  String get tomorrowWord => 'Tomorrow';

  @override
  String inDays(Object n) {
    return 'In $n days';
  }

  @override
  String get noTasksHere => 'No tasks here';

  @override
  String get addTasksHint => 'Add homework, exams and reminders to track them.';

  @override
  String dueOnTime(Object date, Object time) {
    return 'Due $date$time';
  }

  @override
  String stepsCount(Object done, Object total) {
    return '$done/$total steps';
  }

  @override
  String get repeatsLabel => 'Repeats';

  @override
  String get remindDueTime => 'At due time';

  @override
  String remindMins(Object n) {
    return '$n min before';
  }

  @override
  String remindHours(num n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n hours before',
      one: '1 hour before',
    );
    return '$_temp0';
  }

  @override
  String remindDays(num n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n days before',
      one: '1 day before',
    );
    return '$_temp0';
  }

  @override
  String remindWeeks(num n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n weeks before',
      one: '1 week before',
    );
    return '$_temp0';
  }

  @override
  String get repeatNever => 'Never';

  @override
  String get repeatDaily => 'Daily';

  @override
  String get repeatWeekly => 'Weekly';

  @override
  String get repeatMonthly => 'Monthly';

  @override
  String get priorityLow => 'Low';

  @override
  String get priorityNormal => 'Normal';

  @override
  String get priorityHigh => 'High';

  @override
  String get remindersNeedDue =>
      'Reminders need a due date — set one or remove them';

  @override
  String get deleteTaskTitle => 'Delete task?';

  @override
  String deleteTaskBody(Object title) {
    return 'Delete \"$title\" with its subtasks and reminders?';
  }

  @override
  String get deleteTaskTooltip => 'Delete task';

  @override
  String get editTask => 'Edit task';

  @override
  String get titleLabel => 'Title';

  @override
  String get titleRequired => 'Title is required';

  @override
  String get typeLabel => 'Type';

  @override
  String get priorityLabel => 'Priority';

  @override
  String get classLabel => 'Class';

  @override
  String get noClass => 'No class';

  @override
  String get dueDateLabel => 'Due date';

  @override
  String get dueTimeLabel => 'Due time';

  @override
  String get notSet => 'Not set';

  @override
  String get allDay => 'All day';

  @override
  String get notesLabel => 'Notes';

  @override
  String get trackProgress => 'Track progress %';

  @override
  String get trackProgressHint => 'Log partial completion, not just done';

  @override
  String get resultSection => 'Result';

  @override
  String get stepsSection => 'Steps';

  @override
  String get remindersSection => 'Reminders';

  @override
  String get saveTask => 'Save task';

  @override
  String couldNotSaveTask(Object error) {
    return 'Could not save task: $error';
  }

  @override
  String get newStep => 'New step';

  @override
  String get addStep => 'Add step';

  @override
  String couldNotLoadSteps(Object error) {
    return 'Could not load steps: $error';
  }

  @override
  String couldNotLoadReminders(Object error) {
    return 'Could not load reminders: $error';
  }

  @override
  String couldNotLoadExams(Object error) {
    return 'Could not load exams: $error';
  }

  @override
  String get preparesForExam => 'Prepares for exam';

  @override
  String get noExam => 'No exam';

  @override
  String get noRemindersHint => 'No reminders. They need a due date to fire.';

  @override
  String get enterValidScore => 'Enter a valid score and maximum';

  @override
  String couldNotSaveGrade(Object error) {
    return 'Could not save grade: $error';
  }

  @override
  String couldNotLoadGrade(Object error) {
    return 'Could not load grade: $error';
  }

  @override
  String get scoreLabel => 'Score';

  @override
  String get outOfLabel => 'Out of';

  @override
  String get deleteGradeTooltip => 'Delete grade';

  @override
  String resultScore(Object score, Object max) {
    return 'Result: $score / $max';
  }

  @override
  String get listViewTooltip => 'List view';

  @override
  String get gridViewTooltip => 'Weeks grid view';

  @override
  String couldNotLoad(Object error) {
    return 'Could not load: $error';
  }

  @override
  String get quotasTitle => 'Quotas';

  @override
  String get noAbsencesRecorded => 'No absences recorded.';

  @override
  String get excusedBadge => 'Excused';

  @override
  String get unexcusedBadge => 'Unexcused';

  @override
  String get allClasses => 'All classes';

  @override
  String get noClassesToShow => 'No classes to show.';

  @override
  String get weekPrefix => 'W';

  @override
  String quotaCount(Object unexcused, Object limit) {
    return '$unexcused / $limit unexcused';
  }

  @override
  String get deleteAbsenceTooltip => 'Delete absence record';

  @override
  String get timeGridTooltip => 'Time grid view';

  @override
  String get addEvent => 'Add event';

  @override
  String get prevWeek => 'Previous week';

  @override
  String get nextWeek => 'Next week';

  @override
  String get prevDay => 'Previous day';

  @override
  String get nextDay => 'Next day';

  @override
  String couldNotLoadWeek(Object error) {
    return 'Could not load week: $error';
  }

  @override
  String couldNotLoadEvents(Object error) {
    return 'Could not load events: $error';
  }

  @override
  String couldNotMoveClass(Object error) {
    return 'Could not move class: $error';
  }

  @override
  String couldNotMoveEvent(Object error) {
    return 'Could not move event: $error';
  }

  @override
  String adjustTitle(Object title) {
    return 'Adjust $title';
  }

  @override
  String get gradesTitle => 'Grades';

  @override
  String couldNotLoadGrades(Object error) {
    return 'Could not load grades: $error';
  }

  @override
  String get noGradesYet => 'No grades yet';

  @override
  String get recordExamsHint => 'Record results on your exams to track GPA.';

  @override
  String gpaSummary(num n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n graded exams',
      one: '1 graded exam',
    );
    return 'GPA · $_temp0';
  }

  @override
  String examsAverage(num n, Object avg) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n exams',
      one: '1 exam',
    );
    return '$_temp0 · $avg% average';
  }

  @override
  String get focusTitle => 'Focus';

  @override
  String get focusWorkLabel => 'Work length';

  @override
  String get focusBreakLabel => 'Break length';

  @override
  String get customMinutesLabel => 'Custom minutes';

  @override
  String minutesShort(Object n) {
    return '$n min';
  }

  @override
  String get lockPortraitTitle => 'Lock portrait';

  @override
  String get lockPortraitHint => 'Keep the app upright on phones';

  @override
  String get startFocus => 'Start focus session';

  @override
  String get giveUp => 'Give up';

  @override
  String get skipBreak => 'Skip break';

  @override
  String get todayChip => 'today';

  @override
  String get phaseReady => 'Ready';

  @override
  String get phaseFocus => 'Focus';

  @override
  String get phaseBreak => 'Break';

  @override
  String get endAfterStart => 'End time must be after start time';

  @override
  String couldNotSaveEvent(Object error) {
    return 'Could not save event: $error';
  }

  @override
  String get deleteEventTitle => 'Delete event?';

  @override
  String deleteEventBody(Object title) {
    return 'Delete \"$title\"?';
  }

  @override
  String get editEvent => 'Edit event';

  @override
  String get eventTitleHint => 'Title (sport, appointment, club…)';

  @override
  String get dateLabel => 'Date';

  @override
  String get locationLabel => 'Location';

  @override
  String get allDayLabel => 'All day';

  @override
  String couldNotLoadClass(Object error) {
    return 'Could not load class: $error';
  }

  @override
  String couldNotLoadAttendance(Object error) {
    return 'Could not load attendance: $error';
  }

  @override
  String get markAbsent => 'Mark absent';

  @override
  String get editClass => 'Edit class';

  @override
  String couldNotMarkAbsent(Object error) {
    return 'Could not mark absent: $error';
  }

  @override
  String get couldNotOpenLink => 'Could not open link';

  @override
  String get markPresent => 'Mark present';

  @override
  String get reasonOptional => 'Reason (optional)';

  @override
  String get selectCycleWeek => 'Select at least one cycle week';

  @override
  String get selectRotationDay => 'Select at least one rotation day';

  @override
  String get editSlot => 'Edit time slot';

  @override
  String get addSlot => 'Add time slot';

  @override
  String get dayLabel => 'Day';

  @override
  String get startTimeLabel => 'Start';

  @override
  String get endTimeLabel => 'End';

  @override
  String get roomOverrideHint => 'Room (optional, overrides class room)';

  @override
  String get everyWeek => 'Every week';

  @override
  String get weekAbRotation => 'Week A / B rotation';

  @override
  String get customCycle => 'Custom cycle';

  @override
  String get weekA => 'Week A';

  @override
  String get weekB => 'Week B';

  @override
  String weekABLabel(Object letter) {
    return 'Week $letter';
  }

  @override
  String get cycleLengthLabel => 'Cycle length (weeks)';

  @override
  String weeksCount(Object n) {
    return '$n weeks';
  }

  @override
  String get classesOnWeeks => 'Classes on weeks:';

  @override
  String get meetsOnRotationDays => 'Meets on rotation days:';

  @override
  String customCycleSummary(Object length, Object weeks) {
    return 'Cycle $length: weeks $weeks';
  }

  @override
  String rotationDaysSummary(Object days) {
    return 'Rotation days $days';
  }

  @override
  String get selectWeekday => 'Select at least one weekday';

  @override
  String get selectTimes => 'Select start and end times';

  @override
  String get deleteClassTitle => 'Delete class?';

  @override
  String deleteClassBody(Object name) {
    return 'Delete $name, its schedule and absence records? Tasks will be kept without a class.';
  }

  @override
  String get deleteClassTooltip => 'Delete class';

  @override
  String get classNameLabel => 'Class name';

  @override
  String get colorLabel => 'Color';

  @override
  String get meetsOn => 'Meets on';

  @override
  String get startsAtLabel => 'Starts at';

  @override
  String get endsAtLabel => 'Ends at';

  @override
  String get meetingHint =>
      'Weekly meeting hours. Fine-tune per day, A/B weeks or custom cycles after saving.';

  @override
  String get teacherLabel => 'Teacher';

  @override
  String get teacherEmailLabel => 'Teacher email';

  @override
  String get roomLabel => 'Room';

  @override
  String get buildingLabel => 'Building';

  @override
  String get moduleLabel => 'Module';

  @override
  String get onlineLinkLabel => 'Online link';

  @override
  String get onlineLinkHint => 'Video call or course page URL (optional)';

  @override
  String get absenceLimitLabel => 'Absence limit';

  @override
  String get theoryLabel => 'Theory';

  @override
  String get practicalLabel => 'Practical';

  @override
  String get sessionKindLabel => 'Session';

  @override
  String get classReminderLabel => 'Class reminder (minutes before)';

  @override
  String get classReminderHint => 'Empty = follow default setting';

  @override
  String get notesFieldLabel => 'Notes';

  @override
  String get activeLabel => 'Active';

  @override
  String get saveClass => 'Save class';

  @override
  String get meetingTimes => 'Meeting times';

  @override
  String get addSlotTooltip => 'Add time slot';

  @override
  String couldNotLoadSlots(Object error) {
    return 'Could not load slots: $error';
  }

  @override
  String get noSlotsYet => 'No meeting times yet.';

  @override
  String get weeklyHoursHint =>
      'Weekly hours for this class. Tap a slot to edit it.';

  @override
  String get deleteSlotTooltip => 'Delete time slot';

  @override
  String get absencesSection => 'Absences';

  @override
  String couldNotLoadAbsences(Object error) {
    return 'Could not load absences: $error';
  }

  @override
  String get nameRequired => 'Name is required';

  @override
  String couldNotLoadSettings(Object error) {
    return 'Could not load settings: $error';
  }

  @override
  String couldNotSaveSetting(Object error) {
    return 'Could not save setting: $error';
  }

  @override
  String get defaultDurationTitle => 'Default duration (minutes)';

  @override
  String get defaultReminderTitle => 'Default class reminder';

  @override
  String get minutesBeforeClass => 'Minutes before class';

  @override
  String get emptyMeansOff => 'Empty = off';

  @override
  String get enterNonNegative => 'Enter a non-negative whole number';

  @override
  String get defaultLimitSaved => 'Default absence limit saved';

  @override
  String get appearanceHeader => 'Appearance';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get themeLabel => 'Theme';

  @override
  String couldNotSaveTheme(Object error) {
    return 'Could not save theme: $error';
  }

  @override
  String couldNotSaveAccent(Object error) {
    return 'Could not save accent: $error';
  }

  @override
  String get accentLabel => 'Accent';

  @override
  String get generalHeader => 'General';

  @override
  String get languagesHeader => 'Languages';

  @override
  String get languageLabel => 'Language';

  @override
  String get languageSystem => 'System default';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageTurkish => 'Türkçe';

  @override
  String get defaultAbsenceLimit => 'Default absence limit';

  @override
  String get prefilledHint => 'Prefilled for new classes. Empty = none.';

  @override
  String get academicYearsHeader => 'Academic years';

  @override
  String get dataHeader => 'Data';

  @override
  String get exportCalendar => 'Export calendar (.ics)';

  @override
  String get exportCalendarHint => 'Classes, tasks and events, next 90 days';

  @override
  String get importCalendar => 'Import calendar (.ics)';

  @override
  String get importCalendarHint => 'Adds events as Xtra entries';

  @override
  String get scheduleHeader => 'Schedule';

  @override
  String get defaultClassStart => 'Default class start';

  @override
  String prefilledStartHint(Object start) {
    return 'Prefilled for new classes and slots: $start';
  }

  @override
  String get defaultClassDuration => 'Default class duration';

  @override
  String prefilledDurationHint(Object minutes) {
    return 'Prefilled meeting length: $minutes min';
  }

  @override
  String get autoEndTitle => 'Auto-set end time';

  @override
  String get autoEndHint =>
      'Changing a start time sets end = start + default duration';

  @override
  String get reminderOffHint => 'Off — no reminder before classes';

  @override
  String remindsBeforeHint(Object minutes) {
    return 'Reminds $minutes min before each class';
  }

  @override
  String get dayStartsLabel => 'Day starts';

  @override
  String get dayEndsLabel => 'Day ends';

  @override
  String couldNotSave(Object error) {
    return 'Could not save: $error';
  }

  @override
  String get gridRhythmSaved => 'Grid rhythm saved';

  @override
  String get gridValidation => 'Enter positive lesson and break lengths';

  @override
  String get gridTimeLabels => 'Grid time labels';

  @override
  String get modeClassTimes => 'Class times';

  @override
  String get modeFixed => 'Fixed time';

  @override
  String get lessonMinLabel => 'Lesson (min)';

  @override
  String get breakMinLabel => 'Break (min)';

  @override
  String get loadingEllipsis => 'Loading…';

  @override
  String savedTo(Object uri) {
    return 'Saved to $uri';
  }

  @override
  String couldNotExport(Object error) {
    return 'Could not export: $error';
  }

  @override
  String couldNotExportCalendar(Object error) {
    return 'Could not export calendar: $error';
  }

  @override
  String couldNotImportCalendar(Object error) {
    return 'Could not import calendar: $error';
  }

  @override
  String importedEvents(num n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Imported $n events',
      one: 'Imported 1 event',
    );
    return '$_temp0';
  }

  @override
  String get notifChannel => 'Task reminders';

  @override
  String get openAction => 'Open';

  @override
  String overdueTitle(Object title) {
    return 'Overdue: $title';
  }

  @override
  String wasDue(Object date) {
    return 'Was due $date';
  }

  @override
  String startsAt(Object time) {
    return 'Starts at $time';
  }

  @override
  String get repeatUntilLabel => 'Repeat until';

  @override
  String get foreverLabel => 'Forever';

  @override
  String get pickTime => 'Pick time';

  @override
  String absenceSummaryPlain(Object unexcused, Object excused) {
    return '$unexcused unexcused ($excused excused)';
  }

  @override
  String absenceSummaryQuota(Object unexcused, Object limit, Object excused) {
    return '$unexcused / $limit unexcused ($excused excused)';
  }

  @override
  String get excusedAbsenceTitle => 'Excused absence';

  @override
  String get unexcusedAbsenceTitle => 'Unexcused absence';

  @override
  String get customColorTitle => 'Custom color';

  @override
  String get fixedTimeHint => 'Repeats from Day starts to Day ends';

  @override
  String get dataFolderTitle => 'Data folder';

  @override
  String get dataFolderUnset => 'Not set — pick a folder for data files';

  @override
  String get dataFolderNeedsFolder => 'Pick a data folder first';

  @override
  String get exportDataAction => 'Export data';

  @override
  String get importDataAction => 'Import data';

  @override
  String dataExportDone(Object rows) {
    return 'Exported $rows rows';
  }

  @override
  String dataImportDone(Object upserted, Object deleted) {
    return 'Merged $upserted · deleted $deleted';
  }

  @override
  String couldNotExportData(Object error) {
    return 'Could not export data: $error';
  }

  @override
  String couldNotImportData(Object error) {
    return 'Could not import data: $error';
  }

  @override
  String dataLastExport(Object date) {
    return 'Last export: $date';
  }

  @override
  String dataLastImport(Object date) {
    return 'Last import: $date';
  }

  @override
  String get autoSyncTitle => 'Auto-sync';

  @override
  String get autoSyncHint => 'Export changes and import updates automatically';

  @override
  String get classFilesSection => 'Files';

  @override
  String get addFiles => 'Add files';

  @override
  String get noFilesYet => 'No files yet.';

  @override
  String couldNotLoadFiles(Object error) {
    return 'Could not load files: $error';
  }

  @override
  String couldNotPickFiles(Object error) {
    return 'Could not add files: $error';
  }

  @override
  String couldNotOpenFile(Object error) {
    return 'Could not open file: $error';
  }

  @override
  String get deleteFileTitle => 'Delete file?';

  @override
  String deleteFileBody(Object name) {
    return 'Delete \"$name\"?';
  }

  @override
  String get openFileTooltip => 'Open file';

  @override
  String get deleteFileTooltip => 'Delete file';

  @override
  String get couldNotAccessFile =>
      'Could not read the selected file. The system file picker refused access — try again.';
}
