import 'package:flutter/material.dart';

import '../data/database.dart';
import '../domain/schedule_models.dart' as engine;
import '../theme.dart';
import '../l10n/l10n.dart';
import '../utils/time_format.dart';
import 'class_quick_edit.dart';

/// One class meeting shown in day/week lists.
class OccurrenceTile extends StatelessWidget {
  final engine.ClassOccurrence occurrence;
  final ClassesData? classRow;
  final bool absent;
  final VoidCallback? onTap;

  const OccurrenceTile({
    super.key,
    required this.occurrence,
    required this.classRow,
    this.absent = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final classRow = this.classRow;
    final raw = classRow == null
        ? theme.colorScheme.primary
        : Color(classRow.colorValue);
    final color = classAccentColor(theme.colorScheme, raw);
    final room = occurrence.room ?? classRow?.room;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        // Every tile (calendar list, dashboard) gets long-press quick-edit.
        onLongPress: classRow == null
            ? null
            : () => showClassQuickEditSheet(context, classRow),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 6,
                color: absent ? theme.colorScheme.error : color,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        classRow?.name ?? context.l10n.classFallback,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall,
                      ),
                      // Absent marker lives on its own line under the name:
                      // next to the name it squeezed the title into a few px
                      // on narrow day columns and wrapped it letter by letter.
                      if (absent)
                        Text(
                          context.l10n.absentBadge,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      const SizedBox(height: 2),
                      Text(
                        [
                          '${hhmm(occurrence.startMinutes)} - ${hhmm(occurrence.endMinutes)}',
                          if (room != null && room.isNotEmpty) room,
                        ].join(' · '),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
