import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';
import 'data/database.dart';
import 'data/repositories.dart';
import 'providers.dart';
import 'services/home_widgets.dart';
import 'services/notifications.dart';
import 'utils/ui_feedback.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting();
  await NotificationService.instance.init();
  // Open the database before the first frame so saved view prefs are
  // available synchronously: screens must not flash the default view and
  // switch once an async load completes. The absence limit rides along
  // so its Settings field builds with text on frame one (no delayed
  // fill, hence no fill animation).
  final db = AppDatabase();
  final settings = SettingsRepository(db);
  final calendarView = await settings.calendarView();
  final absencesView = await settings.absencesView();
  final calendarOrientation = await settings.calendarOrientation();
  final defaultLimit = await settings.defaultMaxAbsences();
  await applyPortraitLock(await settings.portraitLock());
  runApp(
    ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        calendarViewSeedProvider.overrideWithValue(calendarView),
        absencesViewSeedProvider.overrideWithValue(absencesView),
        calendarOrientationSeedProvider.overrideWithValue(calendarOrientation),
        defaultLimitSeedProvider.overrideWithValue((
          ready: true,
          limit: defaultLimit,
        )),
      ],
      child: const StartupRunner(child: ChronicleApp()),
    ),
  );
}

/// Runs one-off startup work after the first frame, when the provider
/// container has finished mounting.
///
/// NOTE: this must not read providers synchronously during the mount
/// cascade (e.g. from a ProviderObserver.didAddProvider): re-entrant reads
/// while providers are still mounting throw ProviderException and poison
/// the provider permanently. Post-frame is always safe.
class StartupRunner extends ConsumerStatefulWidget {
  final Widget child;

  const StartupRunner({super.key, required this.child});

  @override
  ConsumerState<StartupRunner> createState() => StartupRunnerState();
}

class StartupRunnerState extends ConsumerState<StartupRunner>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _runStartupTasks());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Re-push widget data on resume: theme code follows the system
    // brightness + in-memory theme mode, both of which can change while
    // backgrounded with no Settings save to trigger a push.
    if (state == AppLifecycleState.resumed) {
      () async {
        try {
          await refreshHomeWidgets(ProviderScope.containerOf(context));
        } catch (e) {
          logLoadFailure('Resume home widgets', e);
        }
      }();
    }
  }

  Future<void> _runStartupTasks() async {
    if (!mounted) return;
    try {
      final scheduler = ref.read(reminderSchedulerProvider);
      NotificationService.instance.startLinuxDueChecker(scheduler);
      await scheduler.refreshAll();
    } catch (e) {
      logLoadFailure('Startup reminder sync', e);
    }
    if (!mounted) return;
    try {
      await warmCalendarWeek(ProviderScope.containerOf(context));
    } catch (e) {
      logLoadFailure('Startup calendar warm', e);
    }
    if (!mounted) return;
    try {
      await ref.read(folderSyncControllerProvider).start();
    } catch (e) {
      logLoadFailure('Startup folder sync', e);
    }
    if (!mounted) return;
    try {
      await refreshHomeWidgets(ProviderScope.containerOf(context));
    } catch (e) {
      logLoadFailure('Startup home widgets', e);
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
