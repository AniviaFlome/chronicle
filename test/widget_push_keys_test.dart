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

    test('receiver names match AndroidManifest entries', () {
      expect(WidgetReceivers.nextClass, 'NextClassHomeWidgetReceiver');
      expect(WidgetReceivers.todayAgenda, 'TodayAgendaHomeWidgetReceiver');
      expect(WidgetReceivers.dueTasks, 'DueTasksCompactHomeWidgetReceiver');
      expect(WidgetReceivers.hub, 'ChronicleHubHomeWidgetReceiver');
      expect(WidgetReceivers.menu, 'CafeteriaMenuHomeWidgetReceiver');
      expect(WidgetReceivers.weekly, 'WeeklyCalendarHomeWidgetReceiver');
    });

    test('shared field keys are stable', () {
      expect(WidgetKeys.themeBg, 'themeBg');
      expect(WidgetKeys.timedData, 'timedData');
      expect(WidgetKeys.menuTitle, 'menuTitle');
      expect(WidgetKeys.menuRows, 'menuRows');
      expect(WidgetKeys.menuMeals, 'menuMeals');
      expect(WidgetKeys.menuMealDefault, 'menuMealDefault');
      expect(WidgetKeys.menuMealKind, 'menuMealKind');
      expect(WidgetKeys.week, 'week');
    });
  });
}
