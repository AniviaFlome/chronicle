import 'package:flutter/material.dart';

/// Logs a background-load failure. Silent by design: callers already show
/// a fallback or keep defaults.
void logLoadFailure(String what, Object e) {
  debugPrint('$what failed: $e');
}

/// Shows a one-line save-failure snackbar when still mounted.
void showErrorSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(message)));
}
