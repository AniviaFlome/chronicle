import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/l10n.dart';

/// Shows a failure with selectable details and a Copy button, so errors
/// can be reported verbatim instead of transcribed from a toast.
Future<void> showErrorDialog(
  BuildContext context, {
  required String title,
  required Object error,
}) {
  final details = error.toString();
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(child: SelectableText(details)),
      ),
      actions: [
        TextButton(
          onPressed: () async {
            try {
              await Clipboard.setData(ClipboardData(text: '$title\n$details'));
            } catch (_) {
              // Clipboard unavailable (e.g. headless tests): still close.
            }
            if (dialogContext.mounted) Navigator.of(dialogContext).pop();
          },
          child: Text(dialogContext.l10n.copy),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: Text(dialogContext.l10n.close),
        ),
      ],
    ),
  );
}
