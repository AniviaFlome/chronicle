import 'dart:io';

import 'package:chronicle/data/database.dart';
import 'package:chronicle/data/repositories.dart';
import 'package:chronicle/theme.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'e2e_harness.dart';

/// Locale override + theme family end to end: picked in the settings UI,
/// applied live (Turkish nav labels, Nord-accented ThemeData), and still in
/// effect after an app restart against the same database file.
void main() {
  testWidgets('TR locale and theme family apply after restart', (
    tester,
  ) async {
    final tmp = (await tester.runAsync(
      () => Directory.systemTemp.createTemp('e2e-locale-theme'),
    ))!;
    final file = File('${tmp.path}/chronicle.db');
    var db = AppDatabase(NativeDatabase(file));
    try {
      Finder settingsScroll() {
        // The title's Scaffold ancestors are both the Settings screen and
        // the outer shell, and the screen holds a horizontal Scrollable
        // too: filter to vertical and take the document-first one, which
        // is the root settings list. scrollUntilVisible needs exactly one.
        final title = find.descendant(
          of: find.byType(AppBar),
          matching: find.text('Settings'),
        );
        final scaffold = find.ancestor(
          of: title,
          matching: find.byType(Scaffold),
        );
        return find
            .descendant(
              of: scaffold,
              matching: find.byWidgetPredicate(
                (w) =>
                    w is Scrollable &&
                    w.axisDirection == AxisDirection.down,
              ),
            )
            .first;
      }

      /// The Nord family + Frost 2 accent must have flowed into the live
      /// ThemeData (the Default family ignores accents, so its primary
      /// would differ). Brightness follows the host platform, so either
      /// the light or the dark primary counts.
      void expectNordThemeApplied() {
        final context = tester.element(find.byType(Scaffold).first);
        final primary = Theme.of(context).colorScheme.primary;
        final candidates = [
          buildAppTheme(
            themeId: 'nord',
            accentValue: 0xFF88C0D0,
            brightness: Brightness.light,
          ).colorScheme.primary,
          buildAppTheme(
            themeId: 'nord',
            accentValue: 0xFF88C0D0,
            brightness: Brightness.dark,
          ).colorScheme.primary,
        ];
        expect(candidates, contains(primary));
      }

      void expectTurkishNav() {
        // navClasses in app_tr.arb; the Classes screen itself is not open,
        // so this is the navigation rail label.
        expect(find.text('Dersler'), findsOneWidget);
        // Settings AppBar title plus the rail label.
        expect(find.text('Ayarlar'), findsWidgets);
        expect(find.text('Classes'), findsNothing);
        expect(find.text('Settings'), findsNothing);
      }

      await bootApp(tester, db);
      await goTab(tester, Icons.settings_outlined);

      // Non-default theme family, picked in the UI like the widget_test
      // theme test does with the standalone SettingsScreen.
      await tester.tap(find.text('Default'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Nord'));
      await tester.pumpAndSettle();
      await pumpForAsync(tester);
      expect(
        await tester.runAsync(() => SettingsRepository(db).appTheme()),
        'nord',
      );

      // An accent from that family.
      await tester.scrollUntilVisible(
        find.byTooltip('Frost 2'),
        200,
        scrollable: settingsScroll(),
      );
      await tester.tap(find.byTooltip('Frost 2'));
      await tester.pumpAndSettle();
      await pumpForAsync(tester);
      expect(
        await tester.runAsync(() => SettingsRepository(db).accentColor()),
        0xFF88C0D0,
      );

      // Turkish locale, picked in the UI last (it re-labels the settings
      // screen itself, so later taps must use Turkish strings).
      await tester.scrollUntilVisible(
        find.text('Türkçe'),
        400,
        scrollable: settingsScroll(),
      );
      await tester.tap(find.text('Türkçe'));
      await tester.pumpAndSettle();
      await pumpForAsync(tester);
      expect(
        await tester.runAsync(() => SettingsRepository(db).localeOverride()),
        'tr',
      );

      expectTurkishNav();
      expectNordThemeApplied();

      // Same database file, fresh app: locale and theme persist and apply.
      db = await restartApp(tester, db, file);
      expect(
        await tester.runAsync(() => SettingsRepository(db).localeOverride()),
        'tr',
      );
      expect(
        await tester.runAsync(() => SettingsRepository(db).appTheme()),
        'nord',
      );
      expect(
        await tester.runAsync(() => SettingsRepository(db).accentColor()),
        0xFF88C0D0,
      );
      await goTab(tester, Icons.settings_outlined);
      expectTurkishNav();
      expectNordThemeApplied();

      await shutdownApp(tester, db);
    } finally {
      await tester.runAsync(() => tmp.delete(recursive: true));
    }
  });
}
