import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';
import 'data/database.dart';
import 'data/repositories.dart';
import 'providers.dart';
import 'services/notifications.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting();
  await NotificationService.instance.init();
  // Open the database before the first frame so saved view prefs are
  // available synchronously: screens must not flash the default view and
  // switch once an async load completes.
  final db = AppDatabase();
  final settings = SettingsRepository(db);
  final calendarView = await settings.calendarView();
  final absencesView = await settings.absencesView();
  await applyPortraitLock(await settings.portraitLock());
  runApp(
    ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        calendarViewSeedProvider.overrideWithValue(calendarView),
        absencesViewSeedProvider.overrideWithValue(absencesView),
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

class StartupRunnerState extends ConsumerState<StartupRunner> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _runStartupTasks());
  }

  Future<void> _runStartupTasks() async {
    if (!mounted) return;
    try {
      final scheduler = ref.read(reminderSchedulerProvider);
      NotificationService.instance.startLinuxDueChecker(scheduler);
      await scheduler.refreshClassReminders();
      await scheduler.nudgeOverdue();
    } catch (e) {
      debugPrint('Startup reminder sync failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
