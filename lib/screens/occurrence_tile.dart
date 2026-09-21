import 'package:flutter/material.dart';

import '../data/database.dart';
import '../domain/schedule_models.dart' as engine;
import '../theme.dart';
import '../l10n/l10n.dart';
import '../utils/time_format.dart';

/// One class meeting shown in day/week lists.
class OccurrenceTile extends StatelessWidget {
  final engine.ClassOccurrence occurrence;
  final ClassesData? classRow;
  final bool absent;
  final bool showDate;
  final VoidCallback? onTap;

  const OccurrenceTile({
    super.key,
    required this.occurrence,
    required this.classRow,
    this.absent = false,
    this.showDate = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final raw = classRow == null
        ? theme.colorScheme.primary
        : Color(classRow!.colorValue);
    final color = classAccentColor(theme.colorScheme, raw);
    final room = occurrence.room ?? classRow?.room;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
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
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              classRow?.name ?? context.l10n.classFallback,
                              style: theme.textTheme.titleSmall,
                            ),
                          ),
                          if (absent)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.errorContainer,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                context.l10n.absentBadge,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onErrorContainer,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        [
                          if (showDate) isoFromDateTime(occurrence.date),
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
