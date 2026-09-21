import 'package:chronicle/domain/grades.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('grade math', () {
    test('percent clamps and guards zero max', () {
      expect(gradePercent(85, 100), 85);
      expect(gradePercent(120, 100), 100);
      expect(gradePercent(-5, 100), 0);
      expect(gradePercent(50, 0), 0);
    });

    test('grade points follow the 4.0 scale', () {
      expect(gradePoint(95), 4.0);
      expect(gradePoint(90), 4.0);
      expect(gradePoint(89.9), 3.0);
      expect(gradePoint(80), 3.0);
      expect(gradePoint(70), 2.0);
      expect(gradePoint(60), 1.0);
      expect(gradePoint(59.9), 0.0);
    });

    test('letters match points', () {
      expect(letterGrade(92), 'A');
      expect(letterGrade(85), 'B');
      expect(letterGrade(73), 'C');
      expect(letterGrade(61), 'D');
      expect(letterGrade(20), 'F');
    });

    test('gpa averages points, null when empty', () {
      expect(gpa([]), isNull);
      expect(gpa([100, 80]), 3.5);
      expect(gpa([70]), 2.0);
    });

    test('daysUntil counts whole days', () {
      final today = DateTime(2026, 9, 17);
      expect(daysUntil('2026-09-17', today), 0);
      expect(daysUntil('2026-09-18', today), 1);
      expect(daysUntil('2026-09-15', today), -2);
      expect(daysUntil('junk', today), 0);
    });
  });

  group('currentStreak', () {
    DateTime d(int day) => DateTime(2026, 9, day);

    test('counts back consecutive days', () {
      expect(currentStreak({d(15), d(16), d(17)}, d(17)), 3);
      expect(currentStreak({d(17)}, d(17)), 1);
      expect(currentStreak({d(16)}, d(17)), 1);
      expect(currentStreak({d(15)}, d(17)), 0);
      expect(currentStreak({}, d(17)), 0);
    });
  });
}
