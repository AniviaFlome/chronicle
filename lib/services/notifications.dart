import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'dart:convert';

import '../l10n/l10n.dart';

import '../data/repositories.dart';
import '../data/schedule_repository.dart';
import '../utils/time_format.dart';

/// Local due moment for a task: dated tasks use their time (or 09:00 when
/// all-day), minus the reminder offset. Null when the task has no due date.
DateTime? reminderFireTime({
  required String? dueDate,
  required int? dueMinutes,
  required int offsetMinutes,
}) {
  if (dueDate == null) return null;
  final due = DateTime.tryParse(dueDate);
  if (due == null) return null;
  final base = dueMinutes == null
      ? DateTime(due.year, due.month, due.day, 9)
      : DateTime(
          due.year,
          due.month,
          due.day,
          dueMinutes ~/ 60,
          dueMinutes % 60,
        );
  return base.subtract(Duration(minutes: offsetMinutes));
}

String _reminderBody(AppLocalizations l10n, String? dueDate, int? dueMinutes) {
  if (dueDate == null) return l10n.noDateLabel;
  if (dueMinutes == null) return l10n.dueOn(dueDate);
  return l10n.dueOnTime(dueDate, ' ${hhmm(dueMinutes)}');
}

/// Stable notification id for one class occurrence. Lives in a high range
/// so it can never collide with task-reminder row ids, and is deterministic
/// so re-scheduling cancels cleanly.
int classReminderId({
  required int classId,
  required String isoDate,
  required int startMinutes,
}) {
  final hash = Object.hash(classId, isoDate, startMinutes) & 0x3FFFFFFF;
  return 0x40000000 | hash;
}

/// System notifications for task reminders.
///
/// Android gets real scheduled notifications. The Linux plugin only supports
/// instant display, so there a due-checker fires reminders while the app
/// runs (at startup and every minute). Everything degrades silently when
/// notifications are unavailable.
class NotificationService {
  NotificationService._();
  static final instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;
  bool _checkerStarted = false;

  /// Channel/action labels in the system language at startup.
  AppLocalizations _labels = AppLocalizationsEn();

  bool get isReady => _ready;

  Future<void> init() async {
    _labels = localizationsForCode(
      PlatformDispatcher.instance.locale.languageCode,
    );
    try {
      tzdata.initializeTimeZones();
      var zone = 'UTC';
      try {
        zone = (await FlutterTimezone.getLocalTimezone()).identifier;
      } catch (_) {
        // Keep UTC; reminders still work, just in the wrong zone.
      }
      try {
        tz.setLocalLocation(tz.getLocation(zone));
      } catch (_) {
        tz.setLocalLocation(tz.UTC);
      }

      const settings = InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        linux: LinuxInitializationSettings(defaultActionName: 'Open'),
      );
      await _plugin.initialize(settings: settings);

      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      await android?.requestNotificationsPermission();
      _ready = true;
    } catch (e) {
      debugPrint('Notifications unavailable: $e');
    }
  }

  Future<void> showNow({
    required int id,
    required String title,
    required String body,
  }) async {
    if (!_ready) return;
    try {
      await _plugin.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            'chronicle_reminders',
            _labels.notifChannel,
            importance: Importance.high,
            priority: Priority.high,
          ),
          linux: LinuxNotificationDetails(
            defaultActionName: _labels.openAction,
          ),
        ),
      );
    } catch (e) {
      debugPrint('Could not show notification: $e');
    }
  }

  /// One-shot scheduled notification. No-op on Linux (unsupported there).
  Future<void> schedule({
    required int id,
    required String title,
    required String body,
    required DateTime fireTime,
  }) async {
    if (!_ready || defaultTargetPlatform == TargetPlatform.linux) return;
    if (fireTime.isBefore(DateTime.now())) return;
    try {
      await _plugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: tz.TZDateTime.from(fireTime, tz.local),
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            'chronicle_reminders',
            _labels.notifChannel,
            importance: Importance.high,
            priority: Priority.high,
          ),
          linux: LinuxNotificationDetails(
            defaultActionName: _labels.openAction,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    } catch (e) {
      debugPrint('Could not schedule notification: $e');
    }
  }

  Future<void> cancel(int id) async {
    if (!_ready) return;
    try {
      await _plugin.cancel(id: id);
    } catch (e) {
      debugPrint('Could not cancel notification: $e');
    }
  }

  /// Starts the Linux in-app due checker. No-op on other platforms and when
  /// called twice.
  void startLinuxDueChecker(ReminderScheduler scheduler) {
    if (_checkerStarted || defaultTargetPlatform != TargetPlatform.linux) {
      return;
    }
    _checkerStarted = true;
    Future.delayed(const Duration(seconds: 5), () async {
      await scheduler.checkDueLinux();
      await scheduler.nudgeOverdue();
    });
    Stream.periodic(const Duration(minutes: 1)).listen((_) async {
      await scheduler.checkDueLinux();
      await scheduler.nudgeOverdue();
    });
  }
}

/// Keeps notifications in sync with stored tasks and reminders.
///
/// Notification ids are reminder row ids (globally unique). Fired state for
/// the Linux checker lives in settings as `fired_reminder_<id>` = fire ISO.
class ReminderScheduler {
  final TaskRepository tasks;
  final SettingsRepository settings;
  final ScheduleRepository schedule;
  final ClassRepository classes;

  ReminderScheduler(this.tasks, this.settings, this.schedule, this.classes);

  static String _firedKey(int reminderId) => 'fired_reminder_$reminderId';
  static const _scheduledClassKey = 'scheduled_class_reminders';

  /// Cancels everything scheduled for the task and re-schedules from the
  /// current stored state. No-ops (except cancelling) for done tasks and
  /// tasks without a due date.
  Future<void> refreshTask(int taskId) async {
    final rows = await tasks.remindersFor(taskId);
    for (final r in rows) {
      await NotificationService.instance.cancel(r.id);
      await settings.remove(_firedKey(r.id));
    }
    final task = await tasks.byId(taskId);
    if (task == null || task.isDone) return;
    final l10n = await _strings();
    for (final r in rows) {
      final fire = reminderFireTime(
        dueDate: task.dueDate,
        dueMinutes: task.dueMinutes,
        offsetMinutes: r.offsetMinutes,
      );
      if (fire == null) continue;
      await NotificationService.instance.schedule(
        id: r.id,
        title: task.title,
        body: _reminderBody(l10n, task.dueDate, task.dueMinutes),
        fireTime: fire,
      );
    }
  }

  /// Cancels everything scheduled for the task (delete / mark done).
  Future<void> cancelTask(int taskId) async {
    final rows = await tasks.remindersFor(taskId);
    for (final r in rows) {
      await NotificationService.instance.cancel(r.id);
      await settings.remove(_firedKey(r.id));
    }
  }

  /// Re-syncs everything from stored state (used after a backup import).
  Future<void> refreshAll() async {
    for (final id in _decodeIds(await settings.get(_scheduledClassKey))) {
      await NotificationService.instance.cancel(id);
    }
    await settings.remove(_scheduledClassKey);
    final open = await tasks.watchAll(onlyOpen: true).first;
    for (final details in open) {
      await refreshTask(details.task.id);
    }
    await refreshClassReminders();
    await nudgeOverdue();
  }

  /// One gentle nudge per overdue task (once per due date). Runs at startup
  /// and inside the Linux checker.
  /// Localized strings for notification titles/bodies: stored override,
  /// else the system language.
  Future<AppLocalizations> _strings() async {
    final override = await settings.localeOverride();
    if (override != 'system') return localizationsForCode(override);
    return localizationsForCode(
      PlatformDispatcher.instance.locale.languageCode,
    );
  }

  Future<void> nudgeOverdue() async {
    final now = DateTime.now();
    final today = isoFromDateTime(now);
    final open = await tasks.watchAll(onlyOpen: true).first;
    final l10n = await _strings();
    for (final details in open) {
      final task = details.task;
      final due = task.dueDate;
      if (due == null || due.compareTo(today) >= 0) continue;
      final key = 'nudged_overdue_${task.id}_$due';
      if (await settings.get(key) != null) continue;
      await NotificationService.instance.showNow(
        id: _overdueId(task.id),
        title: l10n.overdueTitle(task.title),
        body: l10n.wasDue(due),
      );
      await settings.set(key, '1');
    }
  }

  /// Notification id band reserved for overdue nudges.
  static int _overdueId(int taskId) => 0x20000000 | (taskId & 0xFFFFFF);

  /// Linux fallback: show reminders whose time has come while the app runs.
  /// Each (reminder, fire-time) pair fires at most once.
  Future<void> checkDueLinux() async {
    if (defaultTargetPlatform != TargetPlatform.linux) return;
    final open = await tasks.watchAll(onlyOpen: true).first;
    final now = DateTime.now();
    final l10n = await _strings();
    for (final details in open) {
      final task = details.task;
      if (task.dueDate == null) continue;
      final reminders = await tasks.remindersFor(task.id);
      for (final r in reminders) {
        final fire = reminderFireTime(
          dueDate: task.dueDate,
          dueMinutes: task.dueMinutes,
          offsetMinutes: r.offsetMinutes,
        );
        if (fire == null || fire.isAfter(now)) continue;
        final key = _firedKey(r.id);
        if (await settings.get(key) == fire.toIso8601String()) continue;
        await NotificationService.instance.showNow(
          id: r.id,
          title: task.title,
          body: _reminderBody(l10n, task.dueDate, task.dueMinutes),
        );
        await settings.set(key, fire.toIso8601String());
      }
    }
    await checkClassReminders();
  }

  /// Class-start reminders for today's and tomorrow's occurrences.
  ///
  /// On Android the upcoming ones are scheduled (previously scheduled ids
  /// are tracked in settings and cancelled first). On Linux they are fired
  /// by [checkClassReminders] while the app runs. Call after any class or
  /// schedule change and at startup.
  Future<void> refreshClassReminders() async {
    final previously = _decodeIds(await settings.get(_scheduledClassKey));
    for (final id in previously) {
      await NotificationService.instance.cancel(id);
    }
    final planned = <({int id, String title, String body, DateTime fire})>[];
    for (final item in await _upcomingClassStarts()) {
      planned.add(item);
      await NotificationService.instance.schedule(
        id: item.id,
        title: item.title,
        body: item.body,
        fireTime: item.fire,
      );
    }
    await settings.set(
      _scheduledClassKey,
      jsonEncode([for (final p in planned) p.id]),
    );
  }

  /// Linux fallback: fire class-start reminders whose time has come while
  /// the app runs. Each occurrence fires at most once.
  Future<void> checkClassReminders() async {
    if (defaultTargetPlatform != TargetPlatform.linux) return;
    final now = DateTime.now();
    for (final item in await _upcomingClassStarts(includePast: true)) {
      if (item.fire.isAfter(now)) continue;
      if (now.difference(item.fire) > const Duration(minutes: 15)) continue;
      final key = 'fired_class_${item.id}';
      if (await settings.get(key) != null) continue;
      await NotificationService.instance.showNow(
        id: item.id,
        title: item.title,
        body: item.body,
      );
      await settings.set(key, item.fire.toIso8601String());
    }
  }

  /// Occurrences starting within the reminder window: today and tomorrow
  /// ([includePast] also returns already-started ones for the Linux grace
  /// check). Only classes with an effective lead time are included.
  Future<List<({int id, String title, String body, DateTime fire})>>
  _upcomingClassStarts({bool includePast = false}) async {
    final defaultLead = await settings.defaultClassReminderMinutes();
    final l10n = await _strings();
    final anchor = await settings.weekABAnchor();
    final weekStartDay = await settings.weekStartDay();
    final engine = await schedule.loadEngine(
      weekABAnchor: anchor,
      weekStartDay: weekStartDay,
    );
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final occurrences = engine.occurrences(
      rangeStart: today,
      rangeEnd: today.add(const Duration(days: 1)),
    );
    final byId = {for (final c in await classes.all()) c.id: c};
    final out = <({int id, String title, String body, DateTime fire})>[];
    for (final occ in occurrences) {
      final classRow = byId[occ.classId];
      if (classRow == null || !classRow.active) continue;
      final lead = classRow.reminderMinutes ?? defaultLead;
      if (lead == null) continue;
      final start = occ.date.add(Duration(minutes: occ.startMinutes));
      final fire = start.subtract(Duration(minutes: lead));
      if (!includePast && fire.isBefore(now)) continue;
      final room = occ.room ?? classRow.room;
      out.add((
        id: classReminderId(
          classId: occ.classId,
          isoDate: isoDate(occ.date),
          startMinutes: occ.startMinutes,
        ),
        title: classRow.name,
        body:
            '${l10n.startsAt(hhmm(occ.startMinutes))}'
            '${room != null && room.isNotEmpty ? ' · $room' : ''}',
        fire: fire,
      ));
    }
    return out;
  }

  List<int> _decodeIds(String? raw) {
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw) as List;
      return [for (final v in decoded) (v as num).toInt()];
    } catch (_) {
      return const [];
    }
  }
}
