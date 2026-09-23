import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database.dart';
import '../domain/grades.dart';
import '../l10n/l10n.dart';
import '../providers.dart';

enum _Phase { idle, work, rest }

/// Pomodoro focus timer. Sessions are recorded for streaks and statistics.
class FocusScreen extends ConsumerStatefulWidget {
  final int workSeconds;
  final int breakSeconds;

  const FocusScreen({
    super.key,
    this.workSeconds = 25 * 60,
    this.breakSeconds = 5 * 60,
  });

  @override
  ConsumerState<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends ConsumerState<FocusScreen> {
  static const _fallbackWorkSeconds = 25 * 60;
  static const _fallbackBreakSeconds = 5 * 60;

  _Phase _phase = _Phase.idle;
  int _remaining = 0;
  late int _workSecondsState;
  late int _breakSecondsState;
  final _customWork = TextEditingController();
  final _customBreak = TextEditingController();
  DateTime? _workStartedAt;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _remaining = widget.workSeconds;
    _workSecondsState = widget.workSeconds;
    _breakSecondsState = widget.breakSeconds;
    _loadDurations();
  }

  /// Applies persisted custom durations, unless the caller passed explicit
  /// non-default durations (as widget tests do).
  Future<void> _loadDurations() async {
    try {
      final repo = ref.read(settingsRepositoryProvider);
      final work = await repo.focusWorkMinutes();
      final rest = await repo.focusBreakMinutes();
      if (!mounted || _phase != _Phase.idle) return;
      setState(() {
        var applied = false;
        if (widget.workSeconds == _fallbackWorkSeconds) {
          _workSecondsState = work * 60;
          applied = true;
        }
        if (widget.breakSeconds == _fallbackBreakSeconds) {
          _breakSecondsState = rest * 60;
          applied = true;
        }
        if (applied) _remaining = _workSecondsState;
      });
    } catch (e) {
      debugPrint('Load focus durations failed: $e');
    }
  }

  Future<void> _setWorkMinutes(int minutes) async {
    setState(() {
      _workSecondsState = minutes * 60;
      if (_phase == _Phase.idle) _remaining = minutes * 60;
    });
    try {
      await ref.read(settingsRepositoryProvider).setFocusWorkMinutes(minutes);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.couldNotSaveSetting('$e'))),
        );
      }
    }
  }

  Future<void> _setBreakMinutes(int minutes) async {
    setState(() {
      _breakSecondsState = minutes * 60;
      if (_phase == _Phase.idle) _remaining = _workSecondsState;
    });
    try {
      await ref.read(settingsRepositoryProvider).setFocusBreakMinutes(minutes);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.couldNotSaveSetting('$e'))),
        );
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _customWork.dispose();
    _customBreak.dispose();
    super.dispose();
  }

  int get _total =>
      _phase == _Phase.rest ? _breakSecondsState : _workSecondsState;

  String get _phaseLabel => switch (_phase) {
    _Phase.idle => context.l10n.phaseReady,
    _Phase.work => context.l10n.phaseFocus,
    _Phase.rest => context.l10n.phaseBreak,
  };

  void _startWork() {
    _timer?.cancel();
    setState(() {
      _phase = _Phase.work;
      _remaining = _workSecondsState;
      _workStartedAt = DateTime.now();
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    if (!mounted) return;
    if (_remaining > 1) {
      setState(() => _remaining--);
      return;
    }
    _timer?.cancel();
    if (_phase == _Phase.work) {
      _recordSession();
      setState(() {
        _phase = _Phase.rest;
        _remaining = _breakSecondsState;
      });
      _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    } else {
      setState(() {
        _phase = _Phase.idle;
        _remaining = _workSecondsState;
      });
    }
  }

  Future<void> _recordSession() async {
    try {
      await ref
          .read(pomodoroRepositoryProvider)
          .recordSession(
            PomodoroSessionsCompanion.insert(
              startedAt: _workStartedAt ?? DateTime.now(),
              workMinutes: (_workSecondsState / 60).ceil().clamp(1, 24 * 60),
              taskId: const Value(null),
            ),
          );
    } catch (e) {
      debugPrint('Record focus session failed: $e');
    }
  }

  void _pause() {
    _timer?.cancel();
    setState(() => _phase = _Phase.idle);
  }

  void _skipBreak() {
    _timer?.cancel();
    setState(() {
      _phase = _Phase.idle;
      _remaining = _workSecondsState;
    });
  }

  String _mmss(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sessions = ref.watch(sessionsStreamProvider);

    final today = DateTime.now();
    final todayMidnight = DateTime(today.year, today.month, today.day);
    var sessionsToday = 0;
    final activeDays = <DateTime>{};
    for (final s in sessions.value ?? const <PomodoroSession>[]) {
      final day = DateTime(
        s.startedAt.year,
        s.startedAt.month,
        s.startedAt.day,
      );
      activeDays.add(day);
      if (day == todayMidnight) sessionsToday++;
    }
    final streak = currentStreak(activeDays, todayMidnight);

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.focusTitle)),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Center(
            child: SizedBox(
              width: 220,
              height: 220,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: _total <= 0 ? 0 : 1 - _remaining / _total,
                    strokeWidth: 12,
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _phaseLabel,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                      // Fixed width + scale-down: large system fonts must
                      // never push the countdown into the progress ring.
                      SizedBox(
                        width: 164,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.center,
                          child: Text(
                            _mmss(_remaining),
                            style: theme.textTheme.displayMedium,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (_phase == _Phase.idle) ...[
            _DurationRow(
              label: context.l10n.focusWorkLabel,
              presets: const [15, 25, 50],
              selected: _workSecondsState ~/ 60,
              controller: _customWork,
              max: 480,
              onSelect: _setWorkMinutes,
            ),
            const SizedBox(height: 12),
            _DurationRow(
              label: context.l10n.focusBreakLabel,
              presets: const [5, 10, 15],
              selected: _breakSecondsState ~/ 60,
              controller: _customBreak,
              max: 120,
              onSelect: _setBreakMinutes,
            ),
            const SizedBox(height: 16),
          ],
          if (_phase == _Phase.idle)
            FilledButton.icon(
              onPressed: _startWork,
              icon: const Icon(Icons.play_arrow),
              label: Text(context.l10n.startFocus),
            )
          else if (_phase == _Phase.work)
            FilledButton.tonalIcon(
              onPressed: _pause,
              icon: const Icon(Icons.pause),
              label: Text(context.l10n.giveUp),
            )
          else
            FilledButton.tonalIcon(
              onPressed: _skipBreak,
              icon: const Icon(Icons.skip_next),
              label: Text(context.l10n.skipBreak),
            ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _StatChip(
                icon: Icons.local_fire_department_outlined,
                value: '$streak',
                label: context.l10n.dayStreak,
              ),
              _StatChip(
                icon: Icons.today_outlined,
                value: '$sessionsToday',
                label: context.l10n.todayChip,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DurationRow extends StatelessWidget {
  final String label;
  final List<int> presets;
  final int selected;
  final TextEditingController controller;
  final int max;
  final Future<void> Function(int minutes) onSelect;

  const _DurationRow({
    required this.label,
    required this.presets,
    required this.selected,
    required this.controller,
    required this.max,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.labelLarge),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            for (final p in presets)
              ChoiceChip(
                label: Text(context.l10n.minutesShort(p)),
                selected: selected == p,
                onSelected: (_) {
                  onSelect(p);
                },
              ),
            SizedBox(
              width: 120,
              child: TextFormField(
                controller: controller,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: context.l10n.customMinutesLabel,
                  isDense: true,
                ),
                onFieldSubmitted: (value) {
                  final minutes = int.tryParse(value.trim());
                  if (minutes == null || minutes < 1 || minutes > max) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(context.l10n.enterNonNegative),
                      ),
                    );
                    return;
                  }
                  controller.clear();
                  onSelect(minutes);
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _StatChip({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Icon(icon, color: theme.colorScheme.primary),
        Text(value, style: theme.textTheme.headlineSmall),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.outline,
          ),
        ),
      ],
    );
  }
}
