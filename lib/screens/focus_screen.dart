import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database.dart';
import '../l10n/l10n.dart';
import '../providers.dart';
import '../utils/ui_feedback.dart';

enum _Phase { idle, work, rest }

/// Pomodoro focus timer. Sessions are recorded for statistics.
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
  /// non-default durations (as widget tests do). Only rebuilds when a
  /// value actually changes, so the first frame never flashes.
  Future<void> _loadDurations() async {
    try {
      final repo = ref.read(settingsRepositoryProvider);
      final work = await repo.focusWorkMinutes();
      final rest = await repo.focusBreakMinutes();
      if (!mounted || _phase != _Phase.idle) return;
      var applied = false;
      var nextWork = _workSecondsState;
      var nextRest = _breakSecondsState;
      if (widget.workSeconds == _fallbackWorkSeconds) {
        nextWork = work * 60;
        applied = true;
      }
      if (widget.breakSeconds == _fallbackBreakSeconds) {
        nextRest = rest * 60;
        applied = true;
      }
      if (!applied) return;
      setState(() {
        _workSecondsState = nextWork;
        _breakSecondsState = nextRest;
        _remaining = _workSecondsState;
      });
    } catch (e) {
      logLoadFailure('Load focus durations', e);
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
      logLoadFailure('Record focus session', e);
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
    for (final s in sessions.value ?? const <PomodoroSession>[]) {
      final day = DateTime(
        s.startedAt.year,
        s.startedAt.month,
        s.startedAt.day,
      );
      if (day == todayMidnight) sessionsToday++;
    }

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.focusTitle)),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: SizedBox(
                width: 268,
                height: 268,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Fill the box: an unconstrained indicator falls back
                    // to its 36px default and hides behind the countdown.
                    Positioned.fill(
                      child: CircularProgressIndicator(
                        value: _total <= 0 ? 0 : 1 - _remaining / _total,
                        strokeWidth: 16,
                        backgroundColor:
                            theme.colorScheme.surfaceContainerHighest,
                      ),
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
                          width: 200,
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
          ),
          const SizedBox(height: 16),
          if (_phase == _Phase.idle) ...[
            _DurationRow(
              label: context.l10n.focusWorkLabel,
              presets: const [15, 25, 50],
              selected: _workSecondsState ~/ 60,
              max: 480,
              onSelect: _setWorkMinutes,
            ),
            const SizedBox(height: 12),
            _DurationRow(
              label: context.l10n.focusBreakLabel,
              presets: const [5, 10, 15],
              selected: _breakSecondsState ~/ 60,
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
          Center(
            child: _StatChip(
              icon: Icons.today_outlined,
              value: '$sessionsToday',
              label: context.l10n.todayChip,
            ),
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
  final int max;
  final Future<void> Function(int minutes) onSelect;

  const _DurationRow({
    required this.label,
    required this.presets,
    required this.selected,
    required this.max,
    required this.onSelect,
  });

  /// Custom-minutes dialog behind the custom chip: same validation as the
  /// old inline field (whole number within 1..max), errors shown inline.
  Future<void> _askCustom(BuildContext context) async {
    final minutes = await showDialog<int>(
      context: context,
      builder: (_) => _CustomMinutesDialog(max: max),
    );
    if (minutes != null) await onSelect(minutes);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCustom = !presets.contains(selected);
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
            // Same visual language as the presets: the old inline text
            // field looked like a different control entirely.
            ChoiceChip(
              label: Text(
                isCustom
                    ? context.l10n.minutesShort(selected)
                    : context.l10n.customChipLabel,
              ),
              avatar: const Icon(Icons.edit_outlined, size: 18),
              selected: isCustom,
              onSelected: (_) => _askCustom(context),
            ),
          ],
        ),
      ],
    );
  }
}

/// Custom-minutes dialog: owns its text controller so disposal lines up
/// with the route lifecycle (no use-after-dispose during pop animation).
class _CustomMinutesDialog extends StatefulWidget {
  final int max;

  const _CustomMinutesDialog({required this.max});

  @override
  State<_CustomMinutesDialog> createState() => _CustomMinutesDialogState();
}

class _CustomMinutesDialogState extends State<_CustomMinutesDialog> {
  final _controller = TextEditingController();
  bool _showError = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final parsed = int.tryParse(_controller.text.trim());
    if (parsed == null || parsed < 1 || parsed > widget.max) {
      setState(() => _showError = true);
      return;
    }
    Navigator.of(context).pop(parsed);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(context.l10n.customMinutesLabel),
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          errorText: _showError ? context.l10n.enterNonNegative : null,
        ),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.l10n.cancel),
        ),
        FilledButton(onPressed: _submit, child: Text(context.l10n.save)),
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
