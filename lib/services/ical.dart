/// Minimal dependency-free iCalendar support: export events to .ics and
/// import VEVENTs (single + simple daily/weekly repeats) back as data.
///
/// Dates are floating local times (no TZ conversion), which matches how the
/// app stores everything.
library;

/// One calendar event for export, or one parsed instance from import.
class IcsEvent {
  final String title;
  final DateTime start;
  final DateTime? end;
  final String? location;
  final String? description;

  const IcsEvent({
    required this.title,
    required this.start,
    this.end,
    this.location,
    this.description,
  });
}

String _escape(String s) => s
    .replaceAll('\\', '\\\\')
    .replaceAll(';', '\\;')
    .replaceAll(',', '\\,')
    .replaceAll('\n', '\\n');

String _stamp(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}'
    '${d.month.toString().padLeft(2, '0')}'
    '${d.day.toString().padLeft(2, '0')}'
    'T${d.hour.toString().padLeft(2, '0')}'
    '${d.minute.toString().padLeft(2, '0')}'
    '${d.second.toString().padLeft(2, '0')}';

String _date(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}'
    '${d.month.toString().padLeft(2, '0')}'
    '${d.day.toString().padLeft(2, '0')}';

/// Builds an .ics calendar. UIDs are synthetic but stable per input order.
String buildIcs({required List<IcsEvent> events}) {
  final now = _stamp(DateTime.now().toUtc());
  final buffer = StringBuffer()
    ..writeln('BEGIN:VCALENDAR')
    ..writeln('VERSION:2.0')
    ..writeln('PRODID:-//chronicle//student planner//EN');
  for (var i = 0; i < events.length; i++) {
    final e = events[i];
    buffer
      ..writeln('BEGIN:VEVENT')
      ..writeln('UID:chronicle-$i@local')
      ..writeln('DTSTAMP:$now')
      ..writeln('SUMMARY:${_escape(e.title)}');
    if (e.end == null &&
        e.start.hour == 0 &&
        e.start.minute == 0 &&
        e.start.second == 0) {
      buffer.writeln('DTSTART;VALUE=DATE:${_date(e.start)}');
    } else {
      buffer.writeln('DTSTART:${_stamp(e.start)}');
      if (e.end != null) buffer.writeln('DTEND:${_stamp(e.end!)}');
    }
    if (e.location != null && e.location!.isNotEmpty) {
      buffer.writeln('LOCATION:${_escape(e.location!)}');
    }
    if (e.description != null && e.description!.isNotEmpty) {
      buffer.writeln('DESCRIPTION:${_escape(e.description!)}');
    }
    buffer.writeln('END:VEVENT');
  }
  buffer.writeln('END:VCALENDAR');
  return buffer.toString();
}

String _unescape(String s) => s
    .replaceAll('\\n', '\n')
    .replaceAll('\\N', '\n')
    .replaceAll('\\,', ',')
    .replaceAll('\\;', ';')
    .replaceAll('\\\\', '\\');

/// Parses the date part of DTSTART/DTEND values. A trailing Z means UTC and
/// is converted to local time. Returns null on bad input.
DateTime? _parseIcsDateOrNull(String? value) {
  if (value == null) return null;
  return _parseIcsDate(value);
}

/// Parses the date part of DTSTART/DTEND values. A trailing Z means UTC and
/// is converted to local time. Returns null on bad input.
DateTime? _parseIcsDate(String value) {
  final v = value.trim();
  final utc = v.endsWith('Z');
  final core = utc ? v.substring(0, v.length - 1) : v;
  DateTime? parsed;
  if (RegExp(r'^\d{8}$').hasMatch(core)) {
    parsed = DateTime(
      int.parse(core.substring(0, 4)),
      int.parse(core.substring(4, 6)),
      int.parse(core.substring(6, 8)),
    );
  } else {
    final m = RegExp(r'^(\d{8})T(\d{6})$').firstMatch(core);
    if (m == null) return null;
    final d = m.group(1)!;
    final t = m.group(2)!;
    parsed = DateTime(
      int.parse(d.substring(0, 4)),
      int.parse(d.substring(4, 6)),
      int.parse(d.substring(6, 8)),
      int.parse(t.substring(0, 2)),
      int.parse(t.substring(2, 4)),
      int.parse(t.substring(4, 6)),
    );
  }
  return utc ? parsed.toLocal() : parsed;
}

int _weekdayFromByDay(String code) => switch (code) {
  'MO' => 1,
  'TU' => 2,
  'WE' => 3,
  'TH' => 4,
  'FR' => 5,
  'SA' => 6,
  'SU' => 7,
  _ => 0,
};

/// Parses VEVENTs from .ics text. Daily and weekly RRULEs (with COUNT,
/// UNTIL and BYDAY) are expanded, capped at 500 instances within 2 years.
/// Anything else yields single instances. Never throws on malformed input:
/// bad blocks are skipped.
List<IcsEvent> parseIcs(String text) {
  final unfolded = text
      .replaceAll('\r\n', '\n')
      .replaceAll('\r', '\n')
      .split('\n')
      .fold(<String>[], (lines, line) {
        if ((line.startsWith(' ') || line.startsWith('\t')) &&
            lines.isNotEmpty) {
          lines[lines.length - 1] += line.substring(1);
        } else {
          lines.add(line);
        }
        return lines;
      });

  var inEvent = false;
  final props = <String, String>{};
  final out = <IcsEvent>[];

  void flush() {
    if (!inEvent) return;
    inEvent = false;
    try {
      out.addAll(_expandEvent(Map.of(props)));
    } catch (_) {
      // Skip malformed blocks.
    }
    props.clear();
  }

  for (final line in unfolded) {
    if (line == 'BEGIN:VEVENT') {
      inEvent = true;
      props.clear();
    } else if (line == 'END:VEVENT') {
      flush();
    } else if (inEvent) {
      final sep = line.indexOf(':');
      if (sep <= 0) continue;
      final name = line.substring(0, sep).split(';').first;
      props[name] = line.substring(sep + 1);
    }
  }
  flush();
  return out;
}

List<IcsEvent> _expandEvent(Map<String, String> props) {
  final title = props['SUMMARY'] == null ? null : _unescape(props['SUMMARY']!);
  final startRaw = props['DTSTART'];
  if (title == null || title.isEmpty || startRaw == null) return const [];
  final start = _parseIcsDate(startRaw);
  if (start == null) return const [];
  final end = _parseIcsDateOrNull(props['DTEND']);
  final duration = end?.difference(start);
  final location = props['LOCATION'] == null
      ? null
      : _unescape(props['LOCATION']!);
  final description = props['DESCRIPTION'] == null
      ? null
      : _unescape(props['DESCRIPTION']!);

  IcsEvent at(DateTime s) => IcsEvent(
    title: title,
    start: s,
    end: duration == null ? null : s.add(duration),
    location: location,
    description: description,
  );

  final rrule = props['RRULE'];
  if (rrule == null) return [at(start)];

  final rule = <String, String>{};
  for (final part in rrule.split(';')) {
    final kv = part.split('=');
    if (kv.length == 2) rule[kv[0]] = kv[1];
  }
  final freq = rule['FREQ'];
  if (freq != 'DAILY' && freq != 'WEEKLY') return [at(start)];

  var count = int.tryParse(rule['COUNT'] ?? '');
  DateTime? until;
  if (rule['UNTIL'] != null) until = _parseIcsDate(rule['UNTIL']!);
  final byDay = (rule['BYDAY'] ?? '')
      .split(',')
      .map(_weekdayFromByDay)
      .where((d) => d >= 1)
      .toSet();

  final horizon = start.add(const Duration(days: 730));
  final out = <IcsEvent>[];
  var cursor = DateTime(start.year, start.month, start.day);
  var produced = 0;
  while (produced < 500) {
    if (cursor.isAfter(horizon)) break;
    if (until != null && cursor.isAfter(until)) break;
    if (count != null && produced >= count) break;
    final matches = freq == 'DAILY'
        ? true
        : byDay.isEmpty
        ? cursor.weekday == start.weekday
        : byDay.contains(cursor.weekday);
    if (!cursor.isBefore(DateTime(start.year, start.month, start.day)) &&
        matches) {
      final atTime = DateTime(
        cursor.year,
        cursor.month,
        cursor.day,
        start.hour,
        start.minute,
        start.second,
      );
      out.add(at(atTime));
      produced++;
      if (count != null && produced >= count) break;
    }
    cursor = cursor.add(const Duration(days: 1));
  }
  return out;
}
