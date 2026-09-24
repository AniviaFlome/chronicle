import 'package:chronicle/services/ical.dart';
import 'package:chronicle/services/storage_access.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ical', () {
    test('builds and re-parses a timed event', () {
      final ics = buildIcs(
        events: [
          IcsEvent(
            title: 'Math, final; review',
            start: DateTime(2026, 9, 20, 9, 30),
            end: DateTime(2026, 9, 20, 10, 30),
            location: 'B12',
          ),
        ],
      );
      expect(ics, contains('BEGIN:VEVENT'));
      expect(ics, contains('SUMMARY:Math\\, final\\; review'));
      expect(ics, contains('DTSTART:20260920T093000'));
      expect(ics, contains('DTEND:20260920T103000'));

      final parsed = parseIcs(ics);
      expect(parsed, hasLength(1));
      expect(parsed.single.title, 'Math, final; review');
      expect(parsed.single.start, DateTime(2026, 9, 20, 9, 30));
      expect(parsed.single.end, DateTime(2026, 9, 20, 10, 30));
      expect(parsed.single.location, 'B12');
    });

    test('all-day events use DATE values', () {
      final ics = buildIcs(
        events: [IcsEvent(title: 'Trip', start: DateTime(2026, 9, 20))],
      );
      expect(ics, contains('DTSTART;VALUE=DATE:20260920'));
      final parsed = parseIcs(ics);
      expect(parsed.single.start, DateTime(2026, 9, 20));
      expect(parsed.single.end, isNull);
    });

    test('expands weekly repeats with count', () {
      final parsed = parseIcs(
        'BEGIN:VCALENDAR\r\n'
        'BEGIN:VEVENT\r\n'
        'SUMMARY:Training\r\n'
        'DTSTART:20260914T180000\r\n'
        'DTEND:20260914T190000\r\n'
        'RRULE:FREQ=WEEKLY;COUNT=3\r\n'
        'END:VEVENT\r\n'
        'END:VCALENDAR\r\n',
      );
      expect(parsed.map((e) => e.start), [
        DateTime(2026, 9, 14, 18),
        DateTime(2026, 9, 21, 18),
        DateTime(2026, 9, 28, 18),
      ]);
    });

    test('expands byday repeats', () {
      final parsed = parseIcs(
        'BEGIN:VEVENT\n'
        'SUMMARY:Class\n'
        'DTSTART:20260914T090000\n'
        'RRULE:FREQ=WEEKLY;BYDAY=MO,WE;COUNT=3\n'
        'END:VEVENT\n',
      );
      expect(parsed.map((e) => e.start), [
        DateTime(2026, 9, 14, 9),
        DateTime(2026, 9, 16, 9),
        DateTime(2026, 9, 21, 9),
      ]);
    });

    test('skips malformed blocks', () {
      expect(parseIcs('garbage'), isEmpty);
      expect(parseIcs('BEGIN:VEVENT\nSUMMARY:No date\nEND:VEVENT\n'), isEmpty);
    });
  });

  group('storage access', () {
    test('off Android file access is always granted', () async {
      // This suite runs on Linux, where scoped storage does not exist.
      expect(await StorageAccessService().filesAccessGranted(), isTrue);
      expect(await StorageAccessService().requestFilesAccess(), isTrue);
    });
  });
}
