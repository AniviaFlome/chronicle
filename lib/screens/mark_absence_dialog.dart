import 'package:flutter/material.dart';

import '../data/tables.dart';
import '../l10n/l10n.dart';

/// Result of [showMarkAbsenceDialog]: optional reason and excused flag.
/// Absences are always recorded with the default [AbsenceKind.theory] kind.
class AbsenceDraft {
  final String reason;
  final bool excused;
  final AbsenceKind kind;

  const AbsenceDraft(this.reason, this.excused, this.kind);
}

/// Display word for an absence kind ("Theory"/"Practical", localized).
String absenceKindLabel(AppLocalizations l10n, AbsenceKind kind) =>
    kind == AbsenceKind.theory ? l10n.theoryLabel : l10n.practicalLabel;

/// Lower-case variant for inline sentences.
String absenceKindInline(AppLocalizations l10n, AbsenceKind kind) =>
    absenceKindLabel(l10n, kind).toLowerCase();

/// Dialog to mark an absence: reason and excused flag.
/// Returns null when cancelled.
Future<AbsenceDraft?> showMarkAbsenceDialog(
  BuildContext context, {
  required String title,
  bool initialExcused = false,
}) {
  return showDialog<AbsenceDraft>(
    context: context,
    builder: (_) => _MarkAbsenceDialog(
      title: title,
      initialExcused: initialExcused,
    ),
  );
}

class _MarkAbsenceDialog extends StatefulWidget {
  final String title;
  final bool initialExcused;

  const _MarkAbsenceDialog({
    required this.title,
    required this.initialExcused,
  });

  @override
  State<_MarkAbsenceDialog> createState() => _MarkAbsenceDialogState();
}

class _MarkAbsenceDialogState extends State<_MarkAbsenceDialog> {
  final _reason = TextEditingController();
  late bool _excused;

  @override
  void initState() {
    super.initState();
    _excused = widget.initialExcused;
  }

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _reason,
            decoration: InputDecoration(labelText: l10n.reasonOptional),
            autofocus: true,
          ),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.excusedBadge),
            value: _excused,
            onChanged: (v) => setState(() => _excused = v ?? false),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(
            AbsenceDraft(_reason.text.trim(), _excused, AbsenceKind.theory),
          ),
          child: Text(l10n.save),
        ),
      ],
    );
  }
}
