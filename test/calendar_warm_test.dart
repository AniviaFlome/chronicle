import 'package:chronicle/providers.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('calendarWeekRange', () {
    test('Monday start contains the week', () {
      // 2026-09-30 is a Wednesday.
      final (start, end) = calendarWeekRange(DateTime(2026, 9, 30), 1);
      expect(start, DateTime(2026, 9, 28));
      expect(end, DateTime(2026, 10, 4));
    });

    test('Sunday start shifts the week', () {
      final (start, end) = calendarWeekRange(DateTime(2026, 9, 30), 7);
      expect(start, DateTime(2026, 9, 27));
      expect(end, DateTime(2026, 10, 3));
    });

    test('today on the start day stays put', () {
      final (start, end) = calendarWeekRange(DateTime(2026, 9, 28), 1);
      expect(start, DateTime(2026, 9, 28));
      expect(end, DateTime(2026, 10, 4));
    });

    test('spans the DST transition without drifting', () {
      // Europe/Berlin springs forward on 2026-03-29; wall-clock math
      // must still land on calendar days.
      final (start, end) = calendarWeekRange(DateTime(2026, 3, 30), 1);
      expect(start, DateTime(2026, 3, 30));
      expect(end, DateTime(2026, 4, 5));
      expect(end.difference(start).inDays, 6);
    });
  });
}
