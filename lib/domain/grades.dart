/// Pure helpers for grades, GPA and study statistics. No Flutter imports.
library;

import '../utils/time_format.dart';

/// Percentage score, clamped to 0-100. Zero when max is not positive.
double gradePercent(double score, double maxScore) {
  if (maxScore <= 0) return 0;
  return (score / maxScore * 100).clamp(0, 100).toDouble();
}

/// US 4.0 grade point for a percentage.
double gradePoint(double percent) {
  if (percent >= 90) return 4.0;
  if (percent >= 80) return 3.0;
  if (percent >= 70) return 2.0;
  if (percent >= 60) return 1.0;
  return 0.0;
}

/// Letter grade for a percentage.
String letterGrade(double percent) {
  if (percent >= 90) return 'A';
  if (percent >= 80) return 'B';
  if (percent >= 70) return 'C';
  if (percent >= 60) return 'D';
  return 'F';
}

/// GPA as the mean of grade points. Null when there are no grades.
double? gpa(Iterable<double> percents) {
  final list = percents.toList();
  if (list.isEmpty) return null;
  final total = list.fold(0.0, (sum, p) => sum + gradePoint(p));
  return total / list.length;
}

/// Whole days from [today] until an ISO due date (negative = overdue).
int daysUntil(String isoDue, DateTime today) {
  final due = DateTime.tryParse(isoDue);
  if (due == null) return 0;
  final a = DateTime(today.year, today.month, today.day);
  final b = DateTime(due.year, due.month, due.day);
  return daysBetween(a, b);
}

/// Current streak: consecutive active days ending today or yesterday.
/// [activeDays] are local-midnight dates with any completion or session.
int currentStreak(Set<DateTime> activeDays, DateTime today) {
  var cursor = DateTime(today.year, today.month, today.day);
  if (!activeDays.contains(cursor)) {
    cursor = shiftDays(cursor, -1);
    if (!activeDays.contains(cursor)) return 0;
  }
  var streak = 0;
  while (activeDays.contains(cursor)) {
    streak++;
    cursor = shiftDays(cursor, -1);
  }
  return streak;
}
