import 'package:chronicle/services/widget_push.dart';
import 'package:flutter_test/flutter_test.dart';

/// Guards the Dart↔Kotlin wire contract: every prefs prefix and receiver
/// name the Dart push uses must match `WidgetData.kt` / AndroidManifest.xml.
/// The Kotlin side cannot be compiled here, so this pins the Dart half.
void main() {
  group('widget wire keys match native contract', () {
    test('widget prefixes use the home_widget namespace', () {
      expect(WidgetKeys.nextClass, 'home_widget.NextClass');
      expect(WidgetKeys.todayAgenda, 'home_widget.TodayAgenda');
      expect(WidgetKeys.dueTasks, 'home_widget.DueTasksCompact');
      expect(WidgetKeys.hub, 'home_widget.ChronicleHub');
      expect(WidgetKeys.cafeteriaMenu, 'home_widget.CafeteriaMenu');
      expect(WidgetKeys.weeklyCalendar, 'home_widget.WeeklyCalendar');
    });

    test('receiver names match AndroidManifest entries (qualified)', () {
      // Fully qualified: debug installs under a different applicationId, so
      // the push must not rely on package-prefixed resolution.
      const pkg = 'com.chronicleapp.chronicle';
      expect(WidgetReceivers.nextClass, '$pkg.NextClassHomeWidgetReceiver');
      expect(WidgetReceivers.todayAgenda, '$pkg.TodayAgendaHomeWidgetReceiver');
      expect(WidgetReceivers.dueTasks, '$pkg.DueTasksCompactHomeWidgetReceiver');
      expect(WidgetReceivers.hub, '$pkg.ChronicleHubHomeWidgetReceiver');
      expect(WidgetReceivers.menu, '$pkg.CafeteriaMenuHomeWidgetReceiver');
      expect(WidgetReceivers.weekly, '$pkg.WeeklyCalendarHomeWidgetReceiver');
    });

    test('shared field keys are stable', () {
      expect(WidgetKeys.themeBg, 'themeBg');
      expect(WidgetKeys.timedData, 'timedData');
      expect(WidgetKeys.menuTitle, 'menuTitle');
      expect(WidgetKeys.menuRows, 'menuRows');
      expect(WidgetKeys.menuMeals, 'menuMeals');
      expect(WidgetKeys.menuMealDefault, 'menuMealDefault');
      expect(WidgetKeys.menuMealKind, 'menuMealKind');
      expect(WidgetKeys.menuMealKindDate, 'menuMealKindDate');
      expect(WidgetKeys.week, 'week');
    });

    test('widget display flag keys are stable', () {
      // Saved to prefs alongside both timeline pushes (informational: the
      // pushed strings already carry the result) and part of the update
      // fingerprint, so toggling re-renders even with codeless classes.
      expect(WidgetKeys.widgetFullName, 'widgetFullName');
      // Read natively at render time: long hero/Then-line names wrap instead
      // of truncating. Part of the update fingerprint like widgetFullName.
      expect(WidgetKeys.widgetWrapName, 'widgetWrapName');
    });
  });

  group('widget class display names', () {
    // Single source of truth for the hero, Then-line and lookahead rows of
    // both the standalone Next-class widget and the hub class tab, so the
    // two can never diverge.
    test('hideCodes strips the code prefix', () {
      expect(
        widgetClassDisplayName(
          name: 'Müzik Teorisi I',
          code: 'MAT 103E',
          hideCodes: true,
        ),
        'Müzik Teorisi I',
      );
    });

    test('shows CODE · name when codes are on', () {
      expect(
        widgetClassDisplayName(
          name: 'Müzik Teorisi I',
          code: 'MAT 103E',
          hideCodes: false,
        ),
        'MAT 103E · Müzik Teorisi I',
      );
    });

    test('empty codes and placeholder names fall back to plain', () {
      expect(
        widgetClassDisplayName(
          name: 'Müzik Teorisi I',
          code: '  ',
          hideCodes: false,
        ),
        'Müzik Teorisi I',
      );
      expect(
        widgetClassDisplayName(
          name: '—',
          code: 'MAT 103E',
          hideCodes: false,
        ),
        '—',
      );
    });
  });
}
