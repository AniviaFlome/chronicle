/// Formats DateTime as ISO-8601 date (yyyy-MM-dd), matching the DB format.
String isoFromDateTime(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// Shifts a date by whole calendar days, preserving wall-clock time.
/// Never use [Duration] addition here: exact 24h blocks drift across DST.
DateTime shiftDays(DateTime d, int days) => DateTime(
  d.year,
  d.month,
  d.day + days,
  d.hour,
  d.minute,
  d.second,
  d.millisecond,
  d.microsecond,
);

/// Exact whole days between two dates, ignoring time of day and DST length.
int daysBetween(DateTime a, DateTime b) {
  final ua = DateTime.utc(a.year, a.month, a.day);
  final ub = DateTime.utc(b.year, b.month, b.day);
  return ub.difference(ua).inDays;
}

/// Formats minutes-from-midnight as HH:mm.
String hhmm(int minutes) {
  final h = minutes ~/ 60;
  final m = minutes % 60;
  return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
}

/// Parses "HH:mm" into minutes-from-midnight; null on bad input.
int? parseHHmm(String s) {
  final parts = s.split(':');
  if (parts.length != 2) return null;
  final h = int.tryParse(parts[0]);
  final m = int.tryParse(parts[1]);
  if (h == null || m == null || h < 0 || h > 23 || m < 0 || m > 59) return null;
  return h * 60 + m;
}

/// Fixed lesson/break grid: boundaries plus break gaps.
/// Invalid configs (lesson <= 0, count <= 0) yield empty lists.
({List<int> boundaries, List<({int start, int end})> breaks})
generateFixedGrid({
  required int startMinutes,
  required int lessonMinutes,
  required int breakMinutes,
  required int count,
}) {
  final boundaries = <int>[];
  final breaks = <({int start, int end})>[];
  if (lessonMinutes <= 0 || count <= 0) {
    return (boundaries: boundaries, breaks: breaks);
  }
  var t = startMinutes;
  boundaries.add(t);
  for (var i = 0; i < count; i++) {
    t += lessonMinutes;
    boundaries.add(t);
    if (i < count - 1 && breakMinutes > 0) {
      breaks.add((start: t, end: t + breakMinutes));
      t += breakMinutes;
      boundaries.add(t);
    }
  }
  return (boundaries: boundaries, breaks: breaks);
}

/// Abbreviated weekday name ("Mon"/"Pzt") for ISO [weekday] (1 = Monday).
/// Static tables: only supported app locales, no date-symbol init needed.
String shortWeekdayName(int weekday, String locale) {
  const en = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  const tr = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
  final list = locale == 'tr' ? tr : en;
  return list[weekday.clamp(1, 7) - 1];
}

/// Full weekday name ("Monday"/"Pazartesi") for ISO [weekday].
String fullWeekdayName(int weekday, String locale) {
  const en = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];
  const tr = [
    'Pazartesi',
    'Salı',
    'Çarşamba',
    'Perşembe',
    'Cuma',
    'Cumartesi',
    'Pazar',
  ];
  final list = locale == 'tr' ? tr : en;
  return list[weekday.clamp(1, 7) - 1];
}
