import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_tr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('tr'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Chronicle'**
  String get appTitle;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @copy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copy;

  /// No description provided for @errorAddSlot.
  ///
  /// In en, this message translates to:
  /// **'Could not add time slot'**
  String get errorAddSlot;

  /// No description provided for @errorUpdateSlot.
  ///
  /// In en, this message translates to:
  /// **'Could not update time slot'**
  String get errorUpdateSlot;

  /// No description provided for @errorSaveClass.
  ///
  /// In en, this message translates to:
  /// **'Could not save class'**
  String get errorSaveClass;

  /// No description provided for @errorDeleteClass.
  ///
  /// In en, this message translates to:
  /// **'Could not delete class'**
  String get errorDeleteClass;

  /// No description provided for @errorDeleteSlot.
  ///
  /// In en, this message translates to:
  /// **'Could not delete time slot'**
  String get errorDeleteSlot;

  /// No description provided for @navToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get navToday;

  /// No description provided for @navCalendar.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get navCalendar;

  /// No description provided for @navClasses.
  ///
  /// In en, this message translates to:
  /// **'Classes'**
  String get navClasses;

  /// No description provided for @navTasks.
  ///
  /// In en, this message translates to:
  /// **'Tasks'**
  String get navTasks;

  /// No description provided for @navAbsences.
  ///
  /// In en, this message translates to:
  /// **'Absences'**
  String get navAbsences;

  /// No description provided for @navMenu.
  ///
  /// In en, this message translates to:
  /// **'Menu'**
  String get navMenu;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @campusLabel.
  ///
  /// In en, this message translates to:
  /// **'Campus'**
  String get campusLabel;

  /// No description provided for @mealBreakfast.
  ///
  /// In en, this message translates to:
  /// **'Breakfast'**
  String get mealBreakfast;

  /// No description provided for @mealLunch.
  ///
  /// In en, this message translates to:
  /// **'Lunch'**
  String get mealLunch;

  /// No description provided for @mealDinner.
  ///
  /// In en, this message translates to:
  /// **'Dinner'**
  String get mealDinner;

  /// No description provided for @mealVegan.
  ///
  /// In en, this message translates to:
  /// **'Vegan'**
  String get mealVegan;

  /// No description provided for @menuKcal.
  ///
  /// In en, this message translates to:
  /// **'{n} kcal'**
  String menuKcal(Object n);

  /// No description provided for @menuEmpty.
  ///
  /// In en, this message translates to:
  /// **'No menu published for this day'**
  String get menuEmpty;

  /// No description provided for @menuStale.
  ///
  /// In en, this message translates to:
  /// **'Cached menu · pull to refresh'**
  String get menuStale;

  /// No description provided for @menuError.
  ///
  /// In en, this message translates to:
  /// **'Could not load menu'**
  String get menuError;

  /// No description provided for @menuRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get menuRetry;

  /// No description provided for @menuChooseSource.
  ///
  /// In en, this message translates to:
  /// **'Choose a menu source in Settings'**
  String get menuChooseSource;

  /// No description provided for @menuSourceTitle.
  ///
  /// In en, this message translates to:
  /// **'Dining menu'**
  String get menuSourceTitle;

  /// No description provided for @menuSourceLabel.
  ///
  /// In en, this message translates to:
  /// **'Menu source'**
  String get menuSourceLabel;

  /// No description provided for @menuSourceNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get menuSourceNone;

  /// No description provided for @allergensTitle.
  ///
  /// In en, this message translates to:
  /// **'Allergens'**
  String get allergensTitle;

  /// No description provided for @classFallback.
  ///
  /// In en, this message translates to:
  /// **'Class'**
  String get classFallback;

  /// No description provided for @absentBadge.
  ///
  /// In en, this message translates to:
  /// **'Absent'**
  String get absentBadge;

  /// No description provided for @couldNotLoadYears.
  ///
  /// In en, this message translates to:
  /// **'Could not load years: {error}'**
  String couldNotLoadYears(Object error);

  /// No description provided for @allYears.
  ///
  /// In en, this message translates to:
  /// **'All years'**
  String get allYears;

  /// No description provided for @noYearOption.
  ///
  /// In en, this message translates to:
  /// **'No year'**
  String get noYearOption;

  /// No description provided for @addAcademicYear.
  ///
  /// In en, this message translates to:
  /// **'Add academic year'**
  String get addAcademicYear;

  /// No description provided for @editYear.
  ///
  /// In en, this message translates to:
  /// **'Edit year'**
  String get editYear;

  /// No description provided for @nameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get nameLabel;

  /// No description provided for @startsLabel.
  ///
  /// In en, this message translates to:
  /// **'Starts'**
  String get startsLabel;

  /// No description provided for @endsLabel.
  ///
  /// In en, this message translates to:
  /// **'Ends'**
  String get endsLabel;

  /// No description provided for @dayRotationLabel.
  ///
  /// In en, this message translates to:
  /// **'Day rotation'**
  String get dayRotationLabel;

  /// No description provided for @dayRotationHint.
  ///
  /// In en, this message translates to:
  /// **'Rotating day labels (e.g. Day 1-6)'**
  String get dayRotationHint;

  /// No description provided for @offLabel.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get offLabel;

  /// No description provided for @daysCount.
  ///
  /// In en, this message translates to:
  /// **'{n} days'**
  String daysCount(Object n);

  /// No description provided for @pickStartEnd.
  ///
  /// In en, this message translates to:
  /// **'Pick a start and an end date'**
  String get pickStartEnd;

  /// No description provided for @endBeforeStart.
  ///
  /// In en, this message translates to:
  /// **'End date must not precede start date'**
  String get endBeforeStart;

  /// No description provided for @couldNotSaveYear.
  ///
  /// In en, this message translates to:
  /// **'Could not save year: {error}'**
  String couldNotSaveYear(Object error);

  /// No description provided for @pickPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Pick'**
  String get pickPlaceholder;

  /// No description provided for @noYearsYet.
  ///
  /// In en, this message translates to:
  /// **'No academic years yet.'**
  String get noYearsYet;

  /// No description provided for @filteringAllYears.
  ///
  /// In en, this message translates to:
  /// **'Filtering by: all years'**
  String get filteringAllYears;

  /// No description provided for @filteringOneYear.
  ///
  /// In en, this message translates to:
  /// **'Filtering by: one year'**
  String get filteringOneYear;

  /// No description provided for @yearActions.
  ///
  /// In en, this message translates to:
  /// **'Year actions'**
  String get yearActions;

  /// No description provided for @editAction.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get editAction;

  /// No description provided for @deleteYearTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete year?'**
  String get deleteYearTitle;

  /// No description provided for @deleteYearBody.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{name}\"? Its classes keep working without a year.'**
  String deleteYearBody(Object name);

  /// No description provided for @couldNotDelete.
  ///
  /// In en, this message translates to:
  /// **'Could not delete: {error}'**
  String couldNotDelete(Object error);

  /// No description provided for @todayWithDate.
  ///
  /// In en, this message translates to:
  /// **'Today · {date}'**
  String todayWithDate(Object date);

  /// No description provided for @couldNotLoadTasks.
  ///
  /// In en, this message translates to:
  /// **'Could not load tasks: {error}'**
  String couldNotLoadTasks(Object error);

  /// No description provided for @couldNotLoadSchedule.
  ///
  /// In en, this message translates to:
  /// **'Could not load schedule: {error}'**
  String couldNotLoadSchedule(Object error);

  /// No description provided for @nothingDueWeek.
  ///
  /// In en, this message translates to:
  /// **'Nothing due in the next 7 days.'**
  String get nothingDueWeek;

  /// No description provided for @absenceWarnings.
  ///
  /// In en, this message translates to:
  /// **'Absence warnings'**
  String get absenceWarnings;

  /// No description provided for @todaysClasses.
  ///
  /// In en, this message translates to:
  /// **'Today\'s classes'**
  String get todaysClasses;

  /// No description provided for @noClassesToday.
  ///
  /// In en, this message translates to:
  /// **'No classes today.'**
  String get noClassesToday;

  /// No description provided for @tomorrowSection.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get tomorrowSection;

  /// No description provided for @noClassesTomorrow.
  ///
  /// In en, this message translates to:
  /// **'No classes tomorrow.'**
  String get noClassesTomorrow;

  /// No description provided for @upcomingSection.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get upcomingSection;

  /// No description provided for @quotaOver.
  ///
  /// In en, this message translates to:
  /// **'{unexcused} unexcused absences — over the limit of {limit}'**
  String quotaOver(Object unexcused, Object limit);

  /// No description provided for @quotaOneLeft.
  ///
  /// In en, this message translates to:
  /// **'{unexcused} unexcused absences — one left before the limit of {limit}'**
  String quotaOneLeft(Object unexcused, Object limit);

  /// No description provided for @examLabel.
  ///
  /// In en, this message translates to:
  /// **'Exam'**
  String get examLabel;

  /// No description provided for @overduePrefix.
  ///
  /// In en, this message translates to:
  /// **'Overdue · '**
  String get overduePrefix;

  /// No description provided for @dueOn.
  ///
  /// In en, this message translates to:
  /// **'Due {date}'**
  String dueOn(Object date);

  /// No description provided for @dayStreak.
  ///
  /// In en, this message translates to:
  /// **'day streak'**
  String get dayStreak;

  /// No description provided for @doneThisWeek.
  ///
  /// In en, this message translates to:
  /// **'done this week'**
  String get doneThisWeek;

  /// No description provided for @focusedThisWeek.
  ///
  /// In en, this message translates to:
  /// **'focused this week'**
  String get focusedThisWeek;

  /// No description provided for @classesTitle.
  ///
  /// In en, this message translates to:
  /// **'Classes'**
  String get classesTitle;

  /// No description provided for @addClass.
  ///
  /// In en, this message translates to:
  /// **'Add class'**
  String get addClass;

  /// No description provided for @couldNotLoadClasses.
  ///
  /// In en, this message translates to:
  /// **'Could not load classes: {error}'**
  String couldNotLoadClasses(Object error);

  /// No description provided for @showingYear.
  ///
  /// In en, this message translates to:
  /// **'Showing year'**
  String get showingYear;

  /// No description provided for @absenceLimit.
  ///
  /// In en, this message translates to:
  /// **'Absence limit: {limit}'**
  String absenceLimit(Object limit);

  /// No description provided for @noClassesYet.
  ///
  /// In en, this message translates to:
  /// **'No classes yet'**
  String get noClassesYet;

  /// No description provided for @addFirstClass.
  ///
  /// In en, this message translates to:
  /// **'Add your first class to start building your timetable.'**
  String get addFirstClass;

  /// No description provided for @tasksTitle.
  ///
  /// In en, this message translates to:
  /// **'Tasks'**
  String get tasksTitle;

  /// No description provided for @gradesTooltip.
  ///
  /// In en, this message translates to:
  /// **'Grades'**
  String get gradesTooltip;

  /// No description provided for @focusTooltip.
  ///
  /// In en, this message translates to:
  /// **'Focus timer'**
  String get focusTooltip;

  /// No description provided for @addTask.
  ///
  /// In en, this message translates to:
  /// **'Add task'**
  String get addTask;

  /// No description provided for @allFilter.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get allFilter;

  /// No description provided for @typeHomework.
  ///
  /// In en, this message translates to:
  /// **'Homework'**
  String get typeHomework;

  /// No description provided for @typeEssay.
  ///
  /// In en, this message translates to:
  /// **'Essay'**
  String get typeEssay;

  /// No description provided for @typeProject.
  ///
  /// In en, this message translates to:
  /// **'Group project'**
  String get typeProject;

  /// No description provided for @typeReading.
  ///
  /// In en, this message translates to:
  /// **'Reading'**
  String get typeReading;

  /// No description provided for @typeRevision.
  ///
  /// In en, this message translates to:
  /// **'Revision'**
  String get typeRevision;

  /// No description provided for @typeReminder.
  ///
  /// In en, this message translates to:
  /// **'Reminder'**
  String get typeReminder;

  /// No description provided for @hideDone.
  ///
  /// In en, this message translates to:
  /// **'Hide done'**
  String get hideDone;

  /// No description provided for @examCountdown.
  ///
  /// In en, this message translates to:
  /// **'Exam countdown'**
  String get examCountdown;

  /// No description provided for @sectionOverdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get sectionOverdue;

  /// No description provided for @sectionUpcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get sectionUpcoming;

  /// No description provided for @sectionNoDate.
  ///
  /// In en, this message translates to:
  /// **'No due date'**
  String get sectionNoDate;

  /// No description provided for @sectionDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get sectionDone;

  /// No description provided for @noDateLabel.
  ///
  /// In en, this message translates to:
  /// **'No date'**
  String get noDateLabel;

  /// No description provided for @daysOverdue.
  ///
  /// In en, this message translates to:
  /// **'{n}d overdue'**
  String daysOverdue(Object n);

  /// No description provided for @tomorrowWord.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get tomorrowWord;

  /// No description provided for @inDays.
  ///
  /// In en, this message translates to:
  /// **'In {n} days'**
  String inDays(Object n);

  /// No description provided for @noTasksHere.
  ///
  /// In en, this message translates to:
  /// **'No tasks here'**
  String get noTasksHere;

  /// No description provided for @addTasksHint.
  ///
  /// In en, this message translates to:
  /// **'Add homework, exams and reminders to track them.'**
  String get addTasksHint;

  /// No description provided for @dueOnTime.
  ///
  /// In en, this message translates to:
  /// **'Due {date}{time}'**
  String dueOnTime(Object date, Object time);

  /// No description provided for @stepsCount.
  ///
  /// In en, this message translates to:
  /// **'{done}/{total} steps'**
  String stepsCount(Object done, Object total);

  /// No description provided for @repeatsLabel.
  ///
  /// In en, this message translates to:
  /// **'Repeats'**
  String get repeatsLabel;

  /// No description provided for @remindDueTime.
  ///
  /// In en, this message translates to:
  /// **'At due time'**
  String get remindDueTime;

  /// No description provided for @remindMins.
  ///
  /// In en, this message translates to:
  /// **'{n} min before'**
  String remindMins(Object n);

  /// No description provided for @remindHours.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 hour before} other{{n} hours before}}'**
  String remindHours(num n);

  /// No description provided for @remindDays.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 day before} other{{n} days before}}'**
  String remindDays(num n);

  /// No description provided for @remindWeeks.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 week before} other{{n} weeks before}}'**
  String remindWeeks(num n);

  /// No description provided for @repeatNever.
  ///
  /// In en, this message translates to:
  /// **'Never'**
  String get repeatNever;

  /// No description provided for @repeatDaily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get repeatDaily;

  /// No description provided for @repeatWeekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get repeatWeekly;

  /// No description provided for @repeatMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get repeatMonthly;

  /// No description provided for @priorityLow.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get priorityLow;

  /// No description provided for @priorityNormal.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get priorityNormal;

  /// No description provided for @priorityHigh.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get priorityHigh;

  /// No description provided for @remindersNeedDue.
  ///
  /// In en, this message translates to:
  /// **'Reminders need a due date — set one or remove them'**
  String get remindersNeedDue;

  /// No description provided for @deleteTaskTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete task?'**
  String get deleteTaskTitle;

  /// No description provided for @deleteTaskBody.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{title}\" with its subtasks and reminders?'**
  String deleteTaskBody(Object title);

  /// No description provided for @deleteTaskTooltip.
  ///
  /// In en, this message translates to:
  /// **'Delete task'**
  String get deleteTaskTooltip;

  /// No description provided for @editTask.
  ///
  /// In en, this message translates to:
  /// **'Edit task'**
  String get editTask;

  /// No description provided for @titleLabel.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get titleLabel;

  /// No description provided for @titleRequired.
  ///
  /// In en, this message translates to:
  /// **'Title is required'**
  String get titleRequired;

  /// No description provided for @typeLabel.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get typeLabel;

  /// No description provided for @priorityLabel.
  ///
  /// In en, this message translates to:
  /// **'Priority'**
  String get priorityLabel;

  /// No description provided for @classLabel.
  ///
  /// In en, this message translates to:
  /// **'Class'**
  String get classLabel;

  /// No description provided for @noClass.
  ///
  /// In en, this message translates to:
  /// **'No class'**
  String get noClass;

  /// No description provided for @dueDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Due date'**
  String get dueDateLabel;

  /// No description provided for @dueTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'Due time'**
  String get dueTimeLabel;

  /// No description provided for @notSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get notSet;

  /// No description provided for @allDay.
  ///
  /// In en, this message translates to:
  /// **'All day'**
  String get allDay;

  /// No description provided for @notesLabel.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notesLabel;

  /// No description provided for @trackProgress.
  ///
  /// In en, this message translates to:
  /// **'Track progress %'**
  String get trackProgress;

  /// No description provided for @trackProgressHint.
  ///
  /// In en, this message translates to:
  /// **'Log partial completion, not just done'**
  String get trackProgressHint;

  /// No description provided for @resultSection.
  ///
  /// In en, this message translates to:
  /// **'Result'**
  String get resultSection;

  /// No description provided for @stepsSection.
  ///
  /// In en, this message translates to:
  /// **'Steps'**
  String get stepsSection;

  /// No description provided for @remindersSection.
  ///
  /// In en, this message translates to:
  /// **'Reminders'**
  String get remindersSection;

  /// No description provided for @saveTask.
  ///
  /// In en, this message translates to:
  /// **'Save task'**
  String get saveTask;

  /// No description provided for @couldNotSaveTask.
  ///
  /// In en, this message translates to:
  /// **'Could not save task: {error}'**
  String couldNotSaveTask(Object error);

  /// No description provided for @newStep.
  ///
  /// In en, this message translates to:
  /// **'New step'**
  String get newStep;

  /// No description provided for @addStep.
  ///
  /// In en, this message translates to:
  /// **'Add step'**
  String get addStep;

  /// No description provided for @couldNotLoadSteps.
  ///
  /// In en, this message translates to:
  /// **'Could not load steps: {error}'**
  String couldNotLoadSteps(Object error);

  /// No description provided for @couldNotLoadReminders.
  ///
  /// In en, this message translates to:
  /// **'Could not load reminders: {error}'**
  String couldNotLoadReminders(Object error);

  /// No description provided for @couldNotLoadExams.
  ///
  /// In en, this message translates to:
  /// **'Could not load exams: {error}'**
  String couldNotLoadExams(Object error);

  /// No description provided for @preparesForExam.
  ///
  /// In en, this message translates to:
  /// **'Prepares for exam'**
  String get preparesForExam;

  /// No description provided for @noExam.
  ///
  /// In en, this message translates to:
  /// **'No exam'**
  String get noExam;

  /// No description provided for @noRemindersHint.
  ///
  /// In en, this message translates to:
  /// **'No reminders. They need a due date to fire.'**
  String get noRemindersHint;

  /// No description provided for @enterValidScore.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid score and maximum'**
  String get enterValidScore;

  /// No description provided for @couldNotSaveGrade.
  ///
  /// In en, this message translates to:
  /// **'Could not save grade: {error}'**
  String couldNotSaveGrade(Object error);

  /// No description provided for @couldNotLoadGrade.
  ///
  /// In en, this message translates to:
  /// **'Could not load grade: {error}'**
  String couldNotLoadGrade(Object error);

  /// No description provided for @scoreLabel.
  ///
  /// In en, this message translates to:
  /// **'Score'**
  String get scoreLabel;

  /// No description provided for @outOfLabel.
  ///
  /// In en, this message translates to:
  /// **'Out of'**
  String get outOfLabel;

  /// No description provided for @deleteGradeTooltip.
  ///
  /// In en, this message translates to:
  /// **'Delete grade'**
  String get deleteGradeTooltip;

  /// No description provided for @resultScore.
  ///
  /// In en, this message translates to:
  /// **'Result: {score} / {max}'**
  String resultScore(Object score, Object max);

  /// No description provided for @listViewTooltip.
  ///
  /// In en, this message translates to:
  /// **'List view'**
  String get listViewTooltip;

  /// No description provided for @gridViewTooltip.
  ///
  /// In en, this message translates to:
  /// **'Weeks grid view'**
  String get gridViewTooltip;

  /// No description provided for @couldNotLoad.
  ///
  /// In en, this message translates to:
  /// **'Could not load: {error}'**
  String couldNotLoad(Object error);

  /// No description provided for @quotasTitle.
  ///
  /// In en, this message translates to:
  /// **'Quotas'**
  String get quotasTitle;

  /// No description provided for @noAbsencesRecorded.
  ///
  /// In en, this message translates to:
  /// **'No absences recorded.'**
  String get noAbsencesRecorded;

  /// No description provided for @excusedBadge.
  ///
  /// In en, this message translates to:
  /// **'Excused'**
  String get excusedBadge;

  /// No description provided for @unexcusedBadge.
  ///
  /// In en, this message translates to:
  /// **'Unexcused'**
  String get unexcusedBadge;

  /// No description provided for @allClasses.
  ///
  /// In en, this message translates to:
  /// **'All classes'**
  String get allClasses;

  /// No description provided for @noClassesToShow.
  ///
  /// In en, this message translates to:
  /// **'No classes to show.'**
  String get noClassesToShow;

  /// No description provided for @weekPrefix.
  ///
  /// In en, this message translates to:
  /// **'W'**
  String get weekPrefix;

  /// No description provided for @quotaCount.
  ///
  /// In en, this message translates to:
  /// **'{unexcused} / {limit} unexcused'**
  String quotaCount(Object unexcused, Object limit);

  /// No description provided for @deleteAbsenceTooltip.
  ///
  /// In en, this message translates to:
  /// **'Delete absence record'**
  String get deleteAbsenceTooltip;

  /// No description provided for @timeGridTooltip.
  ///
  /// In en, this message translates to:
  /// **'Time grid view'**
  String get timeGridTooltip;

  /// No description provided for @addEvent.
  ///
  /// In en, this message translates to:
  /// **'Add event'**
  String get addEvent;

  /// No description provided for @prevWeek.
  ///
  /// In en, this message translates to:
  /// **'Previous week'**
  String get prevWeek;

  /// No description provided for @nextWeek.
  ///
  /// In en, this message translates to:
  /// **'Next week'**
  String get nextWeek;

  /// No description provided for @prevDay.
  ///
  /// In en, this message translates to:
  /// **'Previous day'**
  String get prevDay;

  /// No description provided for @nextDay.
  ///
  /// In en, this message translates to:
  /// **'Next day'**
  String get nextDay;

  /// No description provided for @couldNotLoadWeek.
  ///
  /// In en, this message translates to:
  /// **'Could not load week: {error}'**
  String couldNotLoadWeek(Object error);

  /// No description provided for @couldNotLoadEvents.
  ///
  /// In en, this message translates to:
  /// **'Could not load events: {error}'**
  String couldNotLoadEvents(Object error);

  /// No description provided for @couldNotMoveClass.
  ///
  /// In en, this message translates to:
  /// **'Could not move class: {error}'**
  String couldNotMoveClass(Object error);

  /// No description provided for @couldNotMoveEvent.
  ///
  /// In en, this message translates to:
  /// **'Could not move event: {error}'**
  String couldNotMoveEvent(Object error);

  /// No description provided for @adjustTitle.
  ///
  /// In en, this message translates to:
  /// **'Adjust {title}'**
  String adjustTitle(Object title);

  /// No description provided for @gradesTitle.
  ///
  /// In en, this message translates to:
  /// **'Grades'**
  String get gradesTitle;

  /// No description provided for @couldNotLoadGrades.
  ///
  /// In en, this message translates to:
  /// **'Could not load grades: {error}'**
  String couldNotLoadGrades(Object error);

  /// No description provided for @noGradesYet.
  ///
  /// In en, this message translates to:
  /// **'No grades yet'**
  String get noGradesYet;

  /// No description provided for @recordExamsHint.
  ///
  /// In en, this message translates to:
  /// **'Record results on your exams to track GPA.'**
  String get recordExamsHint;

  /// No description provided for @gpaSummary.
  ///
  /// In en, this message translates to:
  /// **'GPA · {n, plural, =1{1 graded exam} other{{n} graded exams}}'**
  String gpaSummary(num n);

  /// No description provided for @examsAverage.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 exam} other{{n} exams}} · {avg}% average'**
  String examsAverage(num n, Object avg);

  /// No description provided for @focusTitle.
  ///
  /// In en, this message translates to:
  /// **'Focus'**
  String get focusTitle;

  /// No description provided for @focusWorkLabel.
  ///
  /// In en, this message translates to:
  /// **'Work length'**
  String get focusWorkLabel;

  /// No description provided for @focusBreakLabel.
  ///
  /// In en, this message translates to:
  /// **'Break length'**
  String get focusBreakLabel;

  /// No description provided for @customMinutesLabel.
  ///
  /// In en, this message translates to:
  /// **'Custom minutes'**
  String get customMinutesLabel;

  /// No description provided for @minutesShort.
  ///
  /// In en, this message translates to:
  /// **'{n} min'**
  String minutesShort(Object n);

  /// No description provided for @lockPortraitTitle.
  ///
  /// In en, this message translates to:
  /// **'Lock portrait'**
  String get lockPortraitTitle;

  /// No description provided for @lockPortraitHint.
  ///
  /// In en, this message translates to:
  /// **'Keep the app upright on phones'**
  String get lockPortraitHint;

  /// No description provided for @startFocus.
  ///
  /// In en, this message translates to:
  /// **'Start focus session'**
  String get startFocus;

  /// No description provided for @giveUp.
  ///
  /// In en, this message translates to:
  /// **'Give up'**
  String get giveUp;

  /// No description provided for @skipBreak.
  ///
  /// In en, this message translates to:
  /// **'Skip break'**
  String get skipBreak;

  /// No description provided for @todayChip.
  ///
  /// In en, this message translates to:
  /// **'today'**
  String get todayChip;

  /// No description provided for @phaseReady.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get phaseReady;

  /// No description provided for @phaseFocus.
  ///
  /// In en, this message translates to:
  /// **'Focus'**
  String get phaseFocus;

  /// No description provided for @phaseBreak.
  ///
  /// In en, this message translates to:
  /// **'Break'**
  String get phaseBreak;

  /// No description provided for @endAfterStart.
  ///
  /// In en, this message translates to:
  /// **'End time must be after start time'**
  String get endAfterStart;

  /// No description provided for @couldNotSaveEvent.
  ///
  /// In en, this message translates to:
  /// **'Could not save event: {error}'**
  String couldNotSaveEvent(Object error);

  /// No description provided for @deleteEventTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete event?'**
  String get deleteEventTitle;

  /// No description provided for @deleteEventBody.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{title}\"?'**
  String deleteEventBody(Object title);

  /// No description provided for @editEvent.
  ///
  /// In en, this message translates to:
  /// **'Edit event'**
  String get editEvent;

  /// No description provided for @eventTitleHint.
  ///
  /// In en, this message translates to:
  /// **'Title (sport, appointment, club…)'**
  String get eventTitleHint;

  /// No description provided for @dateLabel.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get dateLabel;

  /// No description provided for @locationLabel.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get locationLabel;

  /// No description provided for @allDayLabel.
  ///
  /// In en, this message translates to:
  /// **'All day'**
  String get allDayLabel;

  /// No description provided for @couldNotLoadClass.
  ///
  /// In en, this message translates to:
  /// **'Could not load class: {error}'**
  String couldNotLoadClass(Object error);

  /// No description provided for @couldNotLoadAttendance.
  ///
  /// In en, this message translates to:
  /// **'Could not load attendance: {error}'**
  String couldNotLoadAttendance(Object error);

  /// No description provided for @markAbsent.
  ///
  /// In en, this message translates to:
  /// **'Mark absent'**
  String get markAbsent;

  /// No description provided for @editClass.
  ///
  /// In en, this message translates to:
  /// **'Edit class'**
  String get editClass;

  /// No description provided for @couldNotMarkAbsent.
  ///
  /// In en, this message translates to:
  /// **'Could not mark absent: {error}'**
  String couldNotMarkAbsent(Object error);

  /// No description provided for @couldNotOpenLink.
  ///
  /// In en, this message translates to:
  /// **'Could not open link'**
  String get couldNotOpenLink;

  /// No description provided for @markPresent.
  ///
  /// In en, this message translates to:
  /// **'Mark present'**
  String get markPresent;

  /// No description provided for @reasonOptional.
  ///
  /// In en, this message translates to:
  /// **'Reason (optional)'**
  String get reasonOptional;

  /// No description provided for @selectCycleWeek.
  ///
  /// In en, this message translates to:
  /// **'Select at least one cycle week'**
  String get selectCycleWeek;

  /// No description provided for @selectRotationDay.
  ///
  /// In en, this message translates to:
  /// **'Select at least one rotation day'**
  String get selectRotationDay;

  /// No description provided for @editSlot.
  ///
  /// In en, this message translates to:
  /// **'Edit time slot'**
  String get editSlot;

  /// No description provided for @addSlot.
  ///
  /// In en, this message translates to:
  /// **'Add time slot'**
  String get addSlot;

  /// No description provided for @dayLabel.
  ///
  /// In en, this message translates to:
  /// **'Day'**
  String get dayLabel;

  /// No description provided for @startTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get startTimeLabel;

  /// No description provided for @endTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'End'**
  String get endTimeLabel;

  /// No description provided for @roomOverrideHint.
  ///
  /// In en, this message translates to:
  /// **'Room (optional, overrides class room)'**
  String get roomOverrideHint;

  /// No description provided for @everyWeek.
  ///
  /// In en, this message translates to:
  /// **'Every week'**
  String get everyWeek;

  /// No description provided for @weekAbRotation.
  ///
  /// In en, this message translates to:
  /// **'Week A / B rotation'**
  String get weekAbRotation;

  /// No description provided for @customCycle.
  ///
  /// In en, this message translates to:
  /// **'Custom cycle'**
  String get customCycle;

  /// No description provided for @weekA.
  ///
  /// In en, this message translates to:
  /// **'Week A'**
  String get weekA;

  /// No description provided for @weekB.
  ///
  /// In en, this message translates to:
  /// **'Week B'**
  String get weekB;

  /// No description provided for @weekABLabel.
  ///
  /// In en, this message translates to:
  /// **'Week {letter}'**
  String weekABLabel(Object letter);

  /// No description provided for @cycleLengthLabel.
  ///
  /// In en, this message translates to:
  /// **'Cycle length (weeks)'**
  String get cycleLengthLabel;

  /// No description provided for @weeksCount.
  ///
  /// In en, this message translates to:
  /// **'{n} weeks'**
  String weeksCount(Object n);

  /// No description provided for @classesOnWeeks.
  ///
  /// In en, this message translates to:
  /// **'Classes on weeks:'**
  String get classesOnWeeks;

  /// No description provided for @meetsOnRotationDays.
  ///
  /// In en, this message translates to:
  /// **'Meets on rotation days:'**
  String get meetsOnRotationDays;

  /// No description provided for @customCycleSummary.
  ///
  /// In en, this message translates to:
  /// **'Cycle {length}: weeks {weeks}'**
  String customCycleSummary(Object length, Object weeks);

  /// No description provided for @rotationDaysSummary.
  ///
  /// In en, this message translates to:
  /// **'Rotation days {days}'**
  String rotationDaysSummary(Object days);

  /// No description provided for @selectWeekday.
  ///
  /// In en, this message translates to:
  /// **'Select at least one weekday'**
  String get selectWeekday;

  /// No description provided for @selectTimes.
  ///
  /// In en, this message translates to:
  /// **'Select start and end times'**
  String get selectTimes;

  /// No description provided for @deleteClassTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete class?'**
  String get deleteClassTitle;

  /// No description provided for @deleteClassBody.
  ///
  /// In en, this message translates to:
  /// **'Delete {name}, its schedule and absence records? Tasks will be kept without a class.'**
  String deleteClassBody(Object name);

  /// No description provided for @deleteClassTooltip.
  ///
  /// In en, this message translates to:
  /// **'Delete class'**
  String get deleteClassTooltip;

  /// No description provided for @classNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Class name'**
  String get classNameLabel;

  /// No description provided for @colorLabel.
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get colorLabel;

  /// No description provided for @meetsOn.
  ///
  /// In en, this message translates to:
  /// **'Meets on'**
  String get meetsOn;

  /// No description provided for @startsAtLabel.
  ///
  /// In en, this message translates to:
  /// **'Starts at'**
  String get startsAtLabel;

  /// No description provided for @endsAtLabel.
  ///
  /// In en, this message translates to:
  /// **'Ends at'**
  String get endsAtLabel;

  /// No description provided for @meetingHint.
  ///
  /// In en, this message translates to:
  /// **'Weekly meeting hours. Fine-tune per day, A/B weeks or custom cycles after saving.'**
  String get meetingHint;

  /// No description provided for @teacherLabel.
  ///
  /// In en, this message translates to:
  /// **'Teacher'**
  String get teacherLabel;

  /// No description provided for @teacherEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Teacher email'**
  String get teacherEmailLabel;

  /// No description provided for @roomLabel.
  ///
  /// In en, this message translates to:
  /// **'Room'**
  String get roomLabel;

  /// No description provided for @buildingLabel.
  ///
  /// In en, this message translates to:
  /// **'Building'**
  String get buildingLabel;

  /// No description provided for @moduleLabel.
  ///
  /// In en, this message translates to:
  /// **'Module'**
  String get moduleLabel;

  /// No description provided for @onlineLinkLabel.
  ///
  /// In en, this message translates to:
  /// **'Online link'**
  String get onlineLinkLabel;

  /// No description provided for @onlineLinkHint.
  ///
  /// In en, this message translates to:
  /// **'Video call or course page URL (optional)'**
  String get onlineLinkHint;

  /// No description provided for @absenceLimitLabel.
  ///
  /// In en, this message translates to:
  /// **'Absence limit'**
  String get absenceLimitLabel;

  /// No description provided for @theoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Theory'**
  String get theoryLabel;

  /// No description provided for @practicalLabel.
  ///
  /// In en, this message translates to:
  /// **'Practical'**
  String get practicalLabel;

  /// No description provided for @sessionKindLabel.
  ///
  /// In en, this message translates to:
  /// **'Session'**
  String get sessionKindLabel;

  /// No description provided for @classReminderLabel.
  ///
  /// In en, this message translates to:
  /// **'Class reminder (minutes before)'**
  String get classReminderLabel;

  /// No description provided for @classReminderHint.
  ///
  /// In en, this message translates to:
  /// **'Empty = follow default setting'**
  String get classReminderHint;

  /// No description provided for @notesFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notesFieldLabel;

  /// No description provided for @activeLabel.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get activeLabel;

  /// No description provided for @saveClass.
  ///
  /// In en, this message translates to:
  /// **'Save class'**
  String get saveClass;

  /// No description provided for @meetingTimes.
  ///
  /// In en, this message translates to:
  /// **'Meeting times'**
  String get meetingTimes;

  /// No description provided for @addSlotTooltip.
  ///
  /// In en, this message translates to:
  /// **'Add time slot'**
  String get addSlotTooltip;

  /// No description provided for @couldNotLoadSlots.
  ///
  /// In en, this message translates to:
  /// **'Could not load slots: {error}'**
  String couldNotLoadSlots(Object error);

  /// No description provided for @noSlotsYet.
  ///
  /// In en, this message translates to:
  /// **'No meeting times yet.'**
  String get noSlotsYet;

  /// No description provided for @weeklyHoursHint.
  ///
  /// In en, this message translates to:
  /// **'Weekly hours for this class. Tap a slot to edit it.'**
  String get weeklyHoursHint;

  /// No description provided for @deleteSlotTooltip.
  ///
  /// In en, this message translates to:
  /// **'Delete time slot'**
  String get deleteSlotTooltip;

  /// No description provided for @absencesSection.
  ///
  /// In en, this message translates to:
  /// **'Absences'**
  String get absencesSection;

  /// No description provided for @couldNotLoadAbsences.
  ///
  /// In en, this message translates to:
  /// **'Could not load absences: {error}'**
  String couldNotLoadAbsences(Object error);

  /// No description provided for @nameRequired.
  ///
  /// In en, this message translates to:
  /// **'Name is required'**
  String get nameRequired;

  /// No description provided for @couldNotLoadSettings.
  ///
  /// In en, this message translates to:
  /// **'Could not load settings: {error}'**
  String couldNotLoadSettings(Object error);

  /// No description provided for @couldNotSaveSetting.
  ///
  /// In en, this message translates to:
  /// **'Could not save setting: {error}'**
  String couldNotSaveSetting(Object error);

  /// No description provided for @defaultDurationTitle.
  ///
  /// In en, this message translates to:
  /// **'Default duration (minutes)'**
  String get defaultDurationTitle;

  /// No description provided for @defaultReminderTitle.
  ///
  /// In en, this message translates to:
  /// **'Default class reminder'**
  String get defaultReminderTitle;

  /// No description provided for @minutesBeforeClass.
  ///
  /// In en, this message translates to:
  /// **'Minutes before class'**
  String get minutesBeforeClass;

  /// No description provided for @emptyMeansOff.
  ///
  /// In en, this message translates to:
  /// **'Empty = off'**
  String get emptyMeansOff;

  /// No description provided for @enterNonNegative.
  ///
  /// In en, this message translates to:
  /// **'Enter a non-negative whole number'**
  String get enterNonNegative;

  /// No description provided for @defaultLimitSaved.
  ///
  /// In en, this message translates to:
  /// **'Default absence limit saved'**
  String get defaultLimitSaved;

  /// No description provided for @appearanceHeader.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearanceHeader;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @themeLabel.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get themeLabel;

  /// No description provided for @couldNotSaveTheme.
  ///
  /// In en, this message translates to:
  /// **'Could not save theme: {error}'**
  String couldNotSaveTheme(Object error);

  /// No description provided for @couldNotSaveAccent.
  ///
  /// In en, this message translates to:
  /// **'Could not save accent: {error}'**
  String couldNotSaveAccent(Object error);

  /// No description provided for @accentLabel.
  ///
  /// In en, this message translates to:
  /// **'Accent'**
  String get accentLabel;

  /// No description provided for @generalHeader.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get generalHeader;

  /// No description provided for @languagesHeader.
  ///
  /// In en, this message translates to:
  /// **'Languages'**
  String get languagesHeader;

  /// No description provided for @languageLabel.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageLabel;

  /// No description provided for @languageSystem.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get languageSystem;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageTurkish.
  ///
  /// In en, this message translates to:
  /// **'Türkçe'**
  String get languageTurkish;

  /// No description provided for @defaultAbsenceLimit.
  ///
  /// In en, this message translates to:
  /// **'Default absence limit'**
  String get defaultAbsenceLimit;

  /// No description provided for @prefilledHint.
  ///
  /// In en, this message translates to:
  /// **'Prefilled for new classes. Empty = none.'**
  String get prefilledHint;

  /// No description provided for @academicYearsHeader.
  ///
  /// In en, this message translates to:
  /// **'Academic years'**
  String get academicYearsHeader;

  /// No description provided for @dataHeader.
  ///
  /// In en, this message translates to:
  /// **'Data'**
  String get dataHeader;

  /// No description provided for @exportCalendar.
  ///
  /// In en, this message translates to:
  /// **'Export calendar (.ics)'**
  String get exportCalendar;

  /// No description provided for @exportCalendarHint.
  ///
  /// In en, this message translates to:
  /// **'Classes, tasks and events, next 90 days'**
  String get exportCalendarHint;

  /// No description provided for @importCalendar.
  ///
  /// In en, this message translates to:
  /// **'Import calendar (.ics)'**
  String get importCalendar;

  /// No description provided for @importCalendarHint.
  ///
  /// In en, this message translates to:
  /// **'Adds events as Xtra entries'**
  String get importCalendarHint;

  /// No description provided for @scheduleHeader.
  ///
  /// In en, this message translates to:
  /// **'Schedule'**
  String get scheduleHeader;

  /// No description provided for @defaultClassStart.
  ///
  /// In en, this message translates to:
  /// **'Default class start'**
  String get defaultClassStart;

  /// No description provided for @prefilledStartHint.
  ///
  /// In en, this message translates to:
  /// **'Prefilled for new classes and slots: {start}'**
  String prefilledStartHint(Object start);

  /// No description provided for @defaultClassDuration.
  ///
  /// In en, this message translates to:
  /// **'Default class duration'**
  String get defaultClassDuration;

  /// No description provided for @prefilledDurationHint.
  ///
  /// In en, this message translates to:
  /// **'Prefilled meeting length: {minutes} min'**
  String prefilledDurationHint(Object minutes);

  /// No description provided for @autoEndTitle.
  ///
  /// In en, this message translates to:
  /// **'Auto-set end time'**
  String get autoEndTitle;

  /// No description provided for @autoEndHint.
  ///
  /// In en, this message translates to:
  /// **'Changing a start time sets end = start + default duration'**
  String get autoEndHint;

  /// No description provided for @reminderOffHint.
  ///
  /// In en, this message translates to:
  /// **'Off — no reminder before classes'**
  String get reminderOffHint;

  /// No description provided for @remindsBeforeHint.
  ///
  /// In en, this message translates to:
  /// **'Reminds {minutes} min before each class'**
  String remindsBeforeHint(Object minutes);

  /// No description provided for @dayStartsLabel.
  ///
  /// In en, this message translates to:
  /// **'Day starts'**
  String get dayStartsLabel;

  /// No description provided for @dayEndsLabel.
  ///
  /// In en, this message translates to:
  /// **'Day ends'**
  String get dayEndsLabel;

  /// No description provided for @couldNotSave.
  ///
  /// In en, this message translates to:
  /// **'Could not save: {error}'**
  String couldNotSave(Object error);

  /// No description provided for @gridRhythmSaved.
  ///
  /// In en, this message translates to:
  /// **'Grid rhythm saved'**
  String get gridRhythmSaved;

  /// No description provided for @gridValidation.
  ///
  /// In en, this message translates to:
  /// **'Enter positive lesson and break lengths'**
  String get gridValidation;

  /// No description provided for @gridTimeLabels.
  ///
  /// In en, this message translates to:
  /// **'Grid time labels'**
  String get gridTimeLabels;

  /// No description provided for @modeClassTimes.
  ///
  /// In en, this message translates to:
  /// **'Class times'**
  String get modeClassTimes;

  /// No description provided for @modeFixed.
  ///
  /// In en, this message translates to:
  /// **'Fixed time'**
  String get modeFixed;

  /// No description provided for @lessonMinLabel.
  ///
  /// In en, this message translates to:
  /// **'Lesson (min)'**
  String get lessonMinLabel;

  /// No description provided for @breakMinLabel.
  ///
  /// In en, this message translates to:
  /// **'Break (min)'**
  String get breakMinLabel;

  /// No description provided for @loadingEllipsis.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get loadingEllipsis;

  /// No description provided for @savedTo.
  ///
  /// In en, this message translates to:
  /// **'Saved to {uri}'**
  String savedTo(Object uri);

  /// No description provided for @couldNotExport.
  ///
  /// In en, this message translates to:
  /// **'Could not export: {error}'**
  String couldNotExport(Object error);

  /// No description provided for @couldNotExportCalendar.
  ///
  /// In en, this message translates to:
  /// **'Could not export calendar: {error}'**
  String couldNotExportCalendar(Object error);

  /// No description provided for @couldNotImportCalendar.
  ///
  /// In en, this message translates to:
  /// **'Could not import calendar: {error}'**
  String couldNotImportCalendar(Object error);

  /// No description provided for @importedEvents.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{Imported 1 event} other{Imported {n} events}}'**
  String importedEvents(num n);

  /// No description provided for @notifChannel.
  ///
  /// In en, this message translates to:
  /// **'Task reminders'**
  String get notifChannel;

  /// No description provided for @openAction.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get openAction;

  /// No description provided for @overdueTitle.
  ///
  /// In en, this message translates to:
  /// **'Overdue: {title}'**
  String overdueTitle(Object title);

  /// No description provided for @wasDue.
  ///
  /// In en, this message translates to:
  /// **'Was due {date}'**
  String wasDue(Object date);

  /// No description provided for @startsAt.
  ///
  /// In en, this message translates to:
  /// **'Starts at {time}'**
  String startsAt(Object time);

  /// No description provided for @repeatUntilLabel.
  ///
  /// In en, this message translates to:
  /// **'Repeat until'**
  String get repeatUntilLabel;

  /// No description provided for @foreverLabel.
  ///
  /// In en, this message translates to:
  /// **'Forever'**
  String get foreverLabel;

  /// No description provided for @pickTime.
  ///
  /// In en, this message translates to:
  /// **'Pick time'**
  String get pickTime;

  /// No description provided for @absenceSummaryPlain.
  ///
  /// In en, this message translates to:
  /// **'{unexcused} unexcused ({excused} excused)'**
  String absenceSummaryPlain(Object unexcused, Object excused);

  /// No description provided for @absenceSummaryQuota.
  ///
  /// In en, this message translates to:
  /// **'{unexcused} / {limit} unexcused ({excused} excused)'**
  String absenceSummaryQuota(Object unexcused, Object limit, Object excused);

  /// No description provided for @excusedAbsenceTitle.
  ///
  /// In en, this message translates to:
  /// **'Excused absence'**
  String get excusedAbsenceTitle;

  /// No description provided for @unexcusedAbsenceTitle.
  ///
  /// In en, this message translates to:
  /// **'Unexcused absence'**
  String get unexcusedAbsenceTitle;

  /// No description provided for @customColorTitle.
  ///
  /// In en, this message translates to:
  /// **'Custom color'**
  String get customColorTitle;

  /// No description provided for @fixedTimeHint.
  ///
  /// In en, this message translates to:
  /// **'Repeats from Day starts to Day ends'**
  String get fixedTimeHint;

  /// No description provided for @dataFolderTitle.
  ///
  /// In en, this message translates to:
  /// **'Data folder'**
  String get dataFolderTitle;

  /// No description provided for @dataFolderUnset.
  ///
  /// In en, this message translates to:
  /// **'Not set — pick a folder for data files'**
  String get dataFolderUnset;

  /// No description provided for @dataFolderNeedsFolder.
  ///
  /// In en, this message translates to:
  /// **'Pick a data folder first'**
  String get dataFolderNeedsFolder;

  /// No description provided for @exportDataAction.
  ///
  /// In en, this message translates to:
  /// **'Export data'**
  String get exportDataAction;

  /// No description provided for @importDataAction.
  ///
  /// In en, this message translates to:
  /// **'Import data'**
  String get importDataAction;

  /// No description provided for @dataExportDone.
  ///
  /// In en, this message translates to:
  /// **'Exported {rows} rows'**
  String dataExportDone(Object rows);

  /// No description provided for @dataImportDone.
  ///
  /// In en, this message translates to:
  /// **'Merged {upserted} · deleted {deleted}'**
  String dataImportDone(Object upserted, Object deleted);

  /// No description provided for @couldNotExportData.
  ///
  /// In en, this message translates to:
  /// **'Could not export data: {error}'**
  String couldNotExportData(Object error);

  /// No description provided for @couldNotImportData.
  ///
  /// In en, this message translates to:
  /// **'Could not import data: {error}'**
  String couldNotImportData(Object error);

  /// No description provided for @dataLastExport.
  ///
  /// In en, this message translates to:
  /// **'Last export: {date}'**
  String dataLastExport(Object date);

  /// No description provided for @dataLastImport.
  ///
  /// In en, this message translates to:
  /// **'Last import: {date}'**
  String dataLastImport(Object date);

  /// No description provided for @autoSyncTitle.
  ///
  /// In en, this message translates to:
  /// **'Auto-sync'**
  String get autoSyncTitle;

  /// No description provided for @autoSyncHint.
  ///
  /// In en, this message translates to:
  /// **'Export changes and import updates automatically'**
  String get autoSyncHint;

  /// No description provided for @classFilesSection.
  ///
  /// In en, this message translates to:
  /// **'Files'**
  String get classFilesSection;

  /// No description provided for @addFiles.
  ///
  /// In en, this message translates to:
  /// **'Add files'**
  String get addFiles;

  /// No description provided for @noFilesYet.
  ///
  /// In en, this message translates to:
  /// **'No files yet.'**
  String get noFilesYet;

  /// No description provided for @couldNotLoadFiles.
  ///
  /// In en, this message translates to:
  /// **'Could not load files: {error}'**
  String couldNotLoadFiles(Object error);

  /// No description provided for @couldNotPickFiles.
  ///
  /// In en, this message translates to:
  /// **'Could not add files: {error}'**
  String couldNotPickFiles(Object error);

  /// No description provided for @couldNotOpenFile.
  ///
  /// In en, this message translates to:
  /// **'Could not open file: {error}'**
  String couldNotOpenFile(Object error);

  /// No description provided for @deleteFileTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete file?'**
  String get deleteFileTitle;

  /// No description provided for @deleteFileBody.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{name}\"?'**
  String deleteFileBody(Object name);

  /// No description provided for @openFileTooltip.
  ///
  /// In en, this message translates to:
  /// **'Open file'**
  String get openFileTooltip;

  /// No description provided for @deleteFileTooltip.
  ///
  /// In en, this message translates to:
  /// **'Delete file'**
  String get deleteFileTooltip;

  /// No description provided for @couldNotAccessFile.
  ///
  /// In en, this message translates to:
  /// **'Could not read the selected file. The system file picker refused access — try again.'**
  String get couldNotAccessFile;

  /// No description provided for @importErrorFolderMissing.
  ///
  /// In en, this message translates to:
  /// **'Data folder not found. Re-pick it in Settings.'**
  String get importErrorFolderMissing;

  /// No description provided for @importErrorManifestMissing.
  ///
  /// In en, this message translates to:
  /// **'No Chronicle export in this folder yet. Export from your other device first.'**
  String get importErrorManifestMissing;

  /// No description provided for @importErrorInvalid.
  ///
  /// In en, this message translates to:
  /// **'This folder is not a Chronicle data folder.'**
  String get importErrorInvalid;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'tr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'tr':
      return AppLocalizationsTr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
