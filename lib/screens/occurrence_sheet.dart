import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/database.dart';
import '../data/schedule_repository.dart';
import '../domain/schedule_models.dart' as engine;
import '../providers.dart';
import '../theme.dart';
import '../l10n/l10n.dart';
import '../utils/time_format.dart';
import 'class_edit_screen.dart';
import 'mark_absence_dialog.dart';

/// Opens the detail sheet for one class meeting: time, room, teacher and
/// absence marking.
Future<void> showOccurrenceSheet(
  BuildContext context,
  engine.ClassOccurrence occurrence,
) {
  return showModalBottomSheet(
    context: context,
    showDragHandle: true,
    builder: (_) => _OccurrenceSheet(occurrence: occurrence),
  );
}

class _OccurrenceSheet extends ConsumerWidget {
  final engine.ClassOccurrence occurrence;

  const _OccurrenceSheet({required this.occurrence});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final classes = ref.watch(classesByIdProvider);
    final absence = ref.watch(
      absenceOnDateProvider((occurrence.classId, isoDate(occurrence.date))),
    );

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: classes.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text(context.l10n.couldNotLoadClass('$e')),
          data: (byId) {
            final classRow = byId[occurrence.classId];
            final color = classAccentColor(
              theme.colorScheme,
              classRow == null
                  ? theme.colorScheme.primary
                  : Color(classRow.colorValue),
            );
            final room = occurrence.room ?? classRow?.room;

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 12,
                      height: 44,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            classRow?.name ?? context.l10n.classFallback,
                            style: theme.textTheme.titleLarge,
                          ),
                          Text(
                            '${DateFormat('EEE, d MMM', context.l10n.localeName).format(occurrence.date)} · '
                            '${hhmm(occurrence.startMinutes)} - ${hhmm(occurrence.endMinutes)}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.outline,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (room != null && room.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _DetailRow(icon: Icons.room_outlined, text: room),
                ],
                if (classRow?.building != null &&
                    classRow?.building?.isNotEmpty == true) ...[
                  const SizedBox(height: 4),
                  _DetailRow(
                    icon: Icons.business_outlined,
                    text: classRow?.building ?? '',
                  ),
                ],
                if (classRow?.teacher != null &&
                    classRow?.teacher?.isNotEmpty == true) ...[
                  const SizedBox(height: 4),
                  _DetailRow(
                    icon: Icons.person_outline,
                    text: classRow?.teacher ?? '',
                  ),
                ],
                if (classRow?.module != null &&
                    classRow?.module?.isNotEmpty == true) ...[
                  const SizedBox(height: 4),
                  _DetailRow(
                    icon: Icons.book_outlined,
                    text: classRow?.module ?? '',
                  ),
                ],
                if (classRow?.onlineLink != null &&
                    classRow?.onlineLink?.isNotEmpty == true) ...[
                  const SizedBox(height: 4),
                  _DetailRow(
                    icon: Icons.link_outlined,
                    text: classRow?.onlineLink ?? '',
                    onTap: () => _openLink(context, classRow!.onlineLink!),
                  ),
                ],
                const SizedBox(height: 16),
                absence.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Text(context.l10n.couldNotLoadAttendance('$e')),
                  data: (marked) {
                    if (marked != null) {
                      return _AbsentState(
                        absence: marked,
                        onPresent: () => ref
                            .read(absenceRepositoryProvider)
                            .unmark(marked.id),
                      );
                    }
                    return SizedBox(
                      width: double.infinity,
                      child: FilledButton.tonalIcon(
                        onPressed: () => _markAbsent(context, ref),
                        icon: const Icon(Icons.person_off_outlined),
                        label: Text(context.l10n.markAbsent),
                      ),
                    );
                  },
                ),
                if (classRow != null) ...[
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ClassEditScreen(existing: classRow),
                            fullscreenDialog: true,
                          ),
                        );
                      },
                      icon: const Icon(Icons.edit_outlined),
                      label: Text(context.l10n.editClass),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _markAbsent(BuildContext context, WidgetRef ref) async {
    final result = await showMarkAbsenceDialog(
      context,
      title: context.l10n.markAbsent,
    );
    if (result == null || !context.mounted) return;
    try {
      await ref
          .read(absenceRepositoryProvider)
          .mark(
            AbsencesCompanion.insert(
              classId: occurrence.classId,
              date: isoDate(occurrence.date),
              startMinutes: occurrence.startMinutes,
              endMinutes: occurrence.endMinutes,
              reason: Value(result.reason.isEmpty ? null : result.reason),
              isExcused: Value(result.excused),
              kind: Value(result.kind),
            ),
          );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(context.l10n.couldNotMarkAbsent('$e'))));
      }
    }
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback? onTap;

  const _DetailRow({required this.icon, required this.text, this.onTap});

  @override
  Widget build(BuildContext context) {
    final row = Row(
      children: [
        Icon(icon, size: 18, color: Theme.of(context).colorScheme.outline),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: onTap == null
                ? null
                : TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    decoration: TextDecoration.underline,
                  ),
          ),
        ),
      ],
    );
    if (onTap == null) return row;
    return InkWell(onTap: onTap, child: row);
  }
}

Future<void> _openLink(BuildContext context, String raw) async {
  var url = raw.trim();
  if (!url.contains('://')) url = 'https://$url';
  final uri = Uri.tryParse(url);
  if (uri == null ||
      !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(context.l10n.couldNotOpenLink)));
    }
  }
}

class _AbsentState extends StatelessWidget {
  final Absence absence;
  final VoidCallback onPresent;

  const _AbsentState({required this.absence, required this.onPresent});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            absence.isExcused ? context.l10n.excusedAbsenceTitle : context.l10n.unexcusedAbsenceTitle,
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.onErrorContainer,
            ),
          ),
          if (absence.reason != null && absence.reason!.isNotEmpty)
            Text(
              absence.reason!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onErrorContainer,
              ),
            ),
          const SizedBox(height: 8),
          FilledButton.tonalIcon(
            onPressed: onPresent,
            icon: const Icon(Icons.check),
            label: Text(context.l10n.markPresent),
          ),
        ],
      ),
    );
  }
}

