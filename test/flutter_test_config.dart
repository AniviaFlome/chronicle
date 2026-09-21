import 'dart:async';

import 'package:intl/date_symbol_data_local.dart';

/// Test bootstrap: initialize intl date symbols (production does this in
/// main) so locale-aware DateFormat calls work in widget tests.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  await initializeDateFormatting();
  await testMain();
}
