import 'package:chronicle/domain/schedule_models.dart';
import 'package:chronicle/l10n/app_localizations.dart';
import 'package:chronicle/services/home_widgets.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final l10n = lookupAppLocalizations(const Locale('en'));

  ClassOccurrence occ(
    int id,
    DateTime date,
    int startMin,
    int endMin, {
    String? room,
  }) => ClassOccurrence(
    classId: id,
    scheduleItemId: id,
    date: date,
    startMinutes: startMin,
    endMinutes: endMin,
    room: room,
  );

  Map<String, Object?>? resolveAt(
    Map<String, Map<String, Object?>> timeline,
    DateTime at,
  ) {
    final targetMs = at.millisecondsSinceEpoch;
    final keys = timeline.keys.map(int.parse).toList()..sort();
    int? chosen;
    for (final k in keys) {
      if (k <= targetMs) chosen = k;
    }
    return chosen == null ? null : timeline[chosen.toString()];
  }

  group('buildNextClassTimeline', () {
    test('promotes next-day class at midnight without opening the app', () {
      // Friday 14:00, no classes Friday, first class Saturday 09:00–10:00.
      final sat = DateTime(2026, 11, 28);
      final now = DateTime(2026, 11, 27, 14, 0);

      final timeline = buildNextClassTimeline(
        now: now,
        occurrences: [occ(1, sat, 9 * 60, 10 * 60, room: 'B4')],
        locale: 'en',
        l10n: l10n,
        displayNameOf: (_) => 'MAT 103 · Mathematics',
        colorOf: (_) => 'FF4F6BED',
        teacherOf: (_) => 'Dr. Smith',
        roomOf: (o) => o.room,
        buildingOf: (_) => 'C Blok',
      );

      // Friday afternoon shows quiet state with Saturday class in thenName.
      final friEntry = resolveAt(timeline, DateTime(2026, 11, 27, 18, 0));
      expect(friEntry?['className'], l10n.widgetNoClasses);
      expect(friEntry?['startLabel'], '');
      expect(friEntry?['thenName'], 'MAT 103 · Mathematics');

      // Saturday 00:05 (long before 09:00 start) promotes Mathematics to Hero!
      final satMorning = resolveAt(timeline, DateTime(2026, 11, 28, 0, 5));
      expect(satMorning?['className'], 'MAT 103 · Mathematics');
      expect(satMorning?['startLabel'], isNotEmpty);
      expect(
        satMorning?['startMs'],
        DateTime(2026, 11, 28, 9, 0).millisecondsSinceEpoch,
      );

      // After Saturday 10:00, closing sentinel activates.
      final satAfter = resolveAt(timeline, DateTime(2026, 11, 28, 10, 1));
      expect(satAfter?['className'], '—');
    });

    test(
      'transitions same-day at prev.end, inserts quiet evening, promotes next day at midnight, and anchors lookahead times to active day',
      () {
        final fri = DateTime(2026, 11, 27);
        final mon = DateTime(2026, 11, 30);
        final now = DateTime(2026, 11, 27, 8, 0);
        final names = {1: 'Math', 2: 'Physics', 3: 'Chemistry', 4: 'History'};

        final timeline = buildNextClassTimeline(
          now: now,
          occurrences: [
            occ(1, fri, 9 * 60, 10 * 60),
            occ(2, fri, 11 * 60, 12 * 60),
            occ(3, mon, 9 * 60, 10 * 60),
            occ(4, mon, 13 * 60, 14 * 60),
          ],
          locale: 'en',
          l10n: l10n,
          displayNameOf: (o) => names[o.classId]!,
          colorOf: (_) => 'FF4F6BED',
          teacherOf: (_) => '',
          roomOf: (_) => null,
          buildingOf: (_) => '',
        );

        // Friday 08:30 -> Math hero, same-day Physics thenWhen has no weekday.
        final fri1 = resolveAt(timeline, DateTime(2026, 11, 27, 8, 30))!;
        expect(fri1['className'], 'Math');
        expect(fri1['thenName'], 'Physics');
        expect((fri1['thenWhen'] as String).contains(' '), isFalse);

        // Friday 10:05 -> switches to Physics immediately after Math ends.
        final fri2 = resolveAt(timeline, DateTime(2026, 11, 27, 10, 5))!;
        expect(fri2['className'], 'Physics');
        expect(fri2['thenName'], 'Chemistry');
        expect((fri2['thenWhen'] as String).contains(' '), isTrue);

        // Friday 12:05 (after Physics ends) and Sunday noon -> quiet state.
        final friEve = resolveAt(timeline, DateTime(2026, 11, 27, 12, 5))!;
        expect(friEve['className'], l10n.widgetNoClasses);
        expect(friEve['thenName'], 'Chemistry');

        final sunNoon = resolveAt(timeline, DateTime(2026, 11, 29, 12, 0))!;
        expect(sunNoon['className'], l10n.widgetNoClasses);
        expect(sunNoon['thenName'], 'Chemistry');

        // Monday 00:01 -> Chemistry promoted to Hero, and History (also Monday)
        // has a plain same-day time with no weekday prefix!
        final monEarly = resolveAt(timeline, DateTime(2026, 11, 30, 0, 1))!;
        expect(monEarly['className'], 'Chemistry');
        expect(monEarly['thenName'], 'History');
        expect((monEarly['thenWhen'] as String).contains(' '), isFalse);
      },
    );
  });
}
