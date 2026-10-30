import 'package:chronicle/utils/time_format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('generateFixedGrid', () {
    test('builds the user example: 14:00, 15:00, 15:10', () {
      final grid = generateFixedGrid(
        startMinutes: 14 * 60,
        lessonMinutes: 60,
        breakMinutes: 10,
        count: 2,
      );
      expect(grid.boundaries, [840, 900, 910, 970]);
      expect(grid.breaks, [(start: 900, end: 910)]);
    });

    test('skips breaks after the last lesson and invalid configs', () {
      final grid = generateFixedGrid(
        startMinutes: 480,
        lessonMinutes: 45,
        breakMinutes: 0,
        count: 3,
      );
      expect(grid.boundaries, [480, 525, 570, 615]);
      expect(grid.breaks, isEmpty);
      expect(
        generateFixedGrid(
          startMinutes: 480,
          lessonMinutes: 0,
          breakMinutes: 10,
          count: 3,
        ).boundaries,
        isEmpty,
      );
    });
  });

  group('shiftDays', () {
    test('preserves wall-clock date and time', () {
      final d = DateTime(2026, 3, 23, 9, 30);
      final shifted = shiftDays(d, 7);
      expect((shifted.year, shifted.month, shifted.day), (2026, 3, 30));
      expect((shifted.hour, shifted.minute), (9, 30));
      expect(shiftDays(d, -1).day, 22);
    });

    test('daysBetween counts calendar days, not 24h blocks', () {
      expect(daysBetween(DateTime(2026, 3, 28), DateTime(2026, 3, 29)), 1);
    });
  });

  group('shiftMonths', () {
    test('clamps Jan 31 to Feb last day instead of Mar overflow', () {
      expect(shiftMonths(DateTime(2026, 1, 31), 1), DateTime(2026, 2, 28));
      expect(shiftMonths(DateTime(2024, 1, 31), 1), DateTime(2024, 2, 29));
      expect(shiftMonths(DateTime(2026, 3, 31), -1), DateTime(2026, 2, 28));
      expect(shiftMonths(DateTime(2026, 5, 15), 1).day, 15);
      expect(shiftMonths(DateTime(2026, 1, 15), -1), DateTime(2025, 12, 15));
    });

    test('preserves wall-clock time', () {
      final d = shiftMonths(DateTime(2026, 1, 15, 9, 30), 1);
      expect((d.hour, d.minute), (9, 30));
    });
  });

  group('weekStartOf', () {
    test('returns Monday start for default week', () {
      // Wed 2026-10-28 -> Mon 2026-10-26.
      expect(weekStartOf(DateTime(2026, 10, 28), 1), DateTime(2026, 10, 26));
    });

    test('clamps garbage weekStart into 1..7', () {
      expect(
        weekStartOf(DateTime(2026, 10, 28), 9),
        weekStartOf(DateTime(2026, 10, 28), 7),
      );
      expect(
        weekStartOf(DateTime(2026, 10, 28), 0),
        weekStartOf(DateTime(2026, 10, 28), 1),
      );
    });
  });
}
