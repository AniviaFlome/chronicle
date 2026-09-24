import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../l10n/l10n.dart';
import '../services/bilsis.dart';

/// Course picker shown after a Bilsis schedule PDF is parsed. Returns the
/// selected `code|section` keys, or null when cancelled.
class BilsisPreviewDialog extends StatefulWidget {
  final BilsisSchedule schedule;

  const BilsisPreviewDialog({super.key, required this.schedule});

  @override
  State<BilsisPreviewDialog> createState() => _BilsisPreviewDialogState();
}

String _bilsisKey(BilsisCourse c) => '${c.code}|${c.section}';

String _hhmm(int minutes) =>
    '${(minutes ~/ 60).toString().padLeft(2, '0')}:'
    '${(minutes % 60).toString().padLeft(2, '0')}';

/// Short weekday name (Mon..Sun) in the ambient locale, derived from a
/// fixed reference week so no new l10n strings are needed.
String _weekdayShort(BuildContext context, int isoDay) {
  // 2026-09-07 is a Monday.
  final date = DateTime(2026, 9, 7 + ((isoDay - 1) % 7));
  return DateFormat.E(Localizations.localeOf(context).languageCode).format(
    date,
  );
}

String _slotsSummary(BuildContext context, BilsisCourse course) {
  return course.slots
      .map(
        (s) =>
            '${_weekdayShort(context, s.day)} '
            '${_hhmm(s.startMinutes)}–${_hhmm(s.endMinutes)}',
      )
      .join(' · ');
}

class _BilsisPreviewDialogState extends State<BilsisPreviewDialog> {
  late final Set<String> _selected = {
    for (final c in widget.schedule.courses) _bilsisKey(c),
  };

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final courses = widget.schedule.courses;
    return AlertDialog(
      title: Text(l10n.bilsisPreviewTitle),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.bilsisPreviewHint,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: courses.length,
                itemBuilder: (context, i) {
                  final course = courses[i];
                  final key = _bilsisKey(course);
                  final checked = _selected.contains(key);
                  final details = [
                    if (course.room != null && course.room!.isNotEmpty)
                      course.room!,
                    if (course.instructor != null &&
                        course.instructor!.isNotEmpty)
                      course.instructor!,
                  ].join(' · ');
                  return CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    value: checked,
                    onChanged: (v) => setState(() {
                      if (v == true) {
                        _selected.add(key);
                      } else {
                        _selected.remove(key);
                      }
                    }),
                    title: Text(
                      '${course.code} ${course.title}',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    subtitle: Text(
                      [
                        _slotsSummary(context, course),
                        if (details.isNotEmpty) details,
                      ].join('\n'),
                    ),
                    isThreeLine: details.isNotEmpty,
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: _selected.isEmpty
              ? () => ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.bilsisNoSelection)),
                )
              : () => Navigator.of(context).pop(Set.of(_selected)),
          child: Text(l10n.bilsisImportCourses(_selected.length)),
        ),
      ],
    );
  }
}
