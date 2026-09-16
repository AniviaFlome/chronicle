import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:chronicle/app.dart';

void main() {
  testWidgets('App shell renders navigation and dashboard', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: ChronicleApp()));
    await tester.pumpAndSettle();

    expect(find.text('Today'), findsWidgets);
    expect(find.text('Calendar'), findsWidgets);
    expect(find.text('Classes'), findsWidgets);
    expect(find.text('Tasks'), findsWidgets);
    expect(find.text('Settings'), findsWidgets);
  });

  testWidgets('Navigating to classes tab works', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: ChronicleApp()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Classes').first);
    await tester.pumpAndSettle();

    expect(find.text('Class list and schedule editor will appear here'), findsOneWidget);
  });
}
