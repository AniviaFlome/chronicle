/// Parser for Hacettepe BILSIS weekly schedule PDFs ("Ders Programı").
/// UI- and PDF-free: callers hand over positioned words, see `bilsis_pdf.dart`.
library;

/// One token of PDF text with its page-space horizontal span and vertical
/// center. `y` grows upwards (PDF convention); pages are independent
/// coordinate spaces.
class BilsisWord {
  final String text;
  final double left;
  final double right;
  final double cy;

  const BilsisWord({
    required this.text,
    required this.left,
    required this.right,
    required this.cy,
  });

  double get cx => (left + right) / 2;
}

/// One weekly meeting of a course. [day] is ISO (1 = Monday .. 7 = Sunday).
class BilsisSlot {
  final int day;
  final int startMinutes;
  final int endMinutes;

  const BilsisSlot({
    required this.day,
    required this.startMinutes,
    required this.endMinutes,
  });
}

/// One course with all its weekly meetings.
class BilsisCourse {
  final String code;
  final String section;
  final String title;
  final String? room;
  final String? instructor;
  final List<BilsisSlot> slots;

  const BilsisCourse({
    required this.code,
    required this.section,
    required this.title,
    required this.room,
    required this.instructor,
    required this.slots,
  });
}

class BilsisSchedule {
  final List<BilsisCourse> courses;

  const BilsisSchedule({required this.courses});

  int get slotCount => courses.fold(0, (n, c) => n + c.slots.length);
}

class BilsisParseException implements Exception {
  final String message;
  const BilsisParseException(this.message);

  @override
  String toString() => 'BilsisParseException: $message';
}

// ---------------------------------------------------------------------------
// Normalization helpers.
// ---------------------------------------------------------------------------

/// Lower-cases ASCII + Turkish dotted/dotless I and strips the remaining
/// Turkish diacritics, so header matching survives font/CMap quirks.
String _foldTr(String s) {
  final lower = s
      .replaceAll('İ', 'i')
      .replaceAll('I', 'ı')
      .toLowerCase()
      .replaceAll('ç', 'c')
      .replaceAll('ğ', 'g')
      .replaceAll('ö', 'o')
      .replaceAll('ş', 's')
      .replaceAll('ü', 'u');
  // 'ı' survives toLowerCase as-is; map it last.
  return lower.replaceAll('ı', 'i');
}

const _dayByFolded = <String, int>{
  'pazartesi': 1,
  'sali': 2,
  'carsamba': 3,
  'persembe': 4,
  'cuma': 5,
  'cumartesi': 6,
  'pazar': 7,
  // Common abbreviations, just in case a faculty prints them.
  'pzt': 1,
  'sal': 2,
  'car': 3,
  'per': 4,
  'cum': 5,
  'cmt': 6,
  'pzr': 7,
};

final _timePattern = RegExp(
  r'(\d{1,2})[:.](\d{2})\s*[-\u2013\u2014]\s*(\d{1,2})[:.](\d{2})',
);

final _codePattern = RegExp(
  r'^([A-ZÇĞİÖŞÜ]{2,}[0-9]+[A-Z]*)[(]([0-9]+)[)]$',
);

final _roomPattern = RegExp(r'^[A-Z0-9]+(-[A-Z0-9]+)+\[\d+\]$');

final _alnumPattern = RegExp(r'[0-9A-Za-zÇçĞğİıÖöŞşÜü]');

bool _hasText(String s) => _alnumPattern.hasMatch(s);

int? _dayOf(String line) {
  final folded = _foldTr(line.replaceAll(RegExp(r'\s+'), ''));
  return _dayByFolded[folded];
}

({int start, int end})? _timeOf(String line) {
  final m = _timePattern.firstMatch(line);
  if (m == null) return null;
  int minutes(String h, String min) =>
      int.parse(h) * 60 + int.parse(min);
  final start = minutes(m.group(1)!, m.group(2)!);
  final end = minutes(m.group(3)!, m.group(4)!);
  if (start < 0 || start >= 24 * 60 || end <= start || end > 24 * 60) {
    return null;
  }
  return (start: start, end: end);
}

({String code, String section})? _codeOf(String compact) {
  final m = _codePattern.firstMatch(compact);
  if (m == null) return null;
  return (code: m.group(1)!, section: m.group(2)!);
}

// ---------------------------------------------------------------------------
// Line grouping.
// ---------------------------------------------------------------------------

class _Line {
  final String text;
  final double cx;
  final double cy;
  final double top;
  final double bottom;

  _Line({
    required this.text,
    required this.cx,
    required this.cy,
    required this.top,
    required this.bottom,
  });
}

/// Groups words into visual lines: one baseline (shared center-y) broken
/// at wide horizontal gaps (table columns). Bilsis rows use ~9pt text on
/// a ~12pt pitch; in-line word gaps are a few points while column gaps
/// are an order of magnitude wider.
List<_Line> _toLines(List<BilsisWord> words) {
  final kept = words.where((w) => _hasText(w.text)).toList();
  const yTolerance = 3.0;
  const xGap = 8.0;
  final bands = <List<BilsisWord>>[];
  final sorted = kept.toList()
    ..sort((a, b) => b.cy.compareTo(a.cy));
  for (final w in sorted) {
    List<BilsisWord>? best;
    var bestDy = yTolerance + 1;
    for (final band in bands) {
      var sum = 0.0;
      for (final o in band) {
        sum += o.cy;
      }
      final dy = (w.cy - sum / band.length).abs();
      if (dy <= yTolerance && dy < bestDy) {
        best = band;
        bestDy = dy;
      }
    }
    if (best == null) {
      bands.add([w]);
    } else {
      best.add(w);
    }
  }
  final lines = <_Line>[];
  for (final band in bands) {
    band.sort((a, b) => a.left.compareTo(b.left));
    var current = <BilsisWord>[band.first];
    for (final w in band.skip(1)) {
      if (w.left - current.last.right > xGap) {
        lines.add(_makeLine(current));
        current = [w];
      } else {
        current.add(w);
      }
    }
    lines.add(_makeLine(current));
  }
  return lines..sort((a, b) => b.cy.compareTo(a.cy));
}

_Line _makeLine(List<BilsisWord> words) {
  var sumY = 0.0;
  for (final w in words) {
    sumY += w.cy;
  }
  final first = words.first;
  final last = words.last;
  return _Line(
    text: words.map((w) => w.text).join(' ').replaceAll(
      RegExp(r'\s+'),
      ' ',
    ).trim(),
    cx: (first.left + last.right) / 2,
    cy: sumY / words.length,
    top: sumY / words.length,
    bottom: sumY / words.length,
  );
}

// ---------------------------------------------------------------------------
// Page model.
// ---------------------------------------------------------------------------

class _DayCol {
  final int day;
  final double centerX;
  _DayCol({required this.day, required this.centerX});
}

class _TimeRow {
  final int start;
  final int end;
  final double cy;
  _TimeRow({required this.start, required this.end, required this.cy});
}

class _Cell {
  final int day;
  final int start;
  final int end;
  final List<String> lines;
  _Cell({
    required this.day,
    required this.start,
    required this.end,
    required this.lines,
  });
}

/// Parses positioned words of a Bilsis schedule PDF (one list per page)
/// into courses with weekly slots.
///
/// Throws [BilsisParseException] when no weekday headers or no time rows
/// are found (e.g. a scanned/image-only PDF).
BilsisSchedule parseBilsisPages(List<List<BilsisWord>> pages) {
  if (pages.isEmpty) {
    throw const BilsisParseException('empty');
  }

  // --- Weekday columns from the header row (dynamic per document). ---
  final headerLines = <_Line>[];
  for (final words in pages) {
    for (final line in _toLines(words)) {
      if (_dayOf(line.text) != null) headerLines.add(line);
    }
  }
  if (headerLines.isEmpty) {
    throw const BilsisParseException('no-header');
  }
  // Average repeated headers (multi-page tables repeat them).
  final byDay = <int, List<double>>{};
  for (final l in headerLines) {
    byDay.putIfAbsent(_dayOf(l.text)!, () => []).add(l.cx);
  }
  final cols = [
    for (final e in byDay.entries)
      _DayCol(
        day: e.key,
        centerX: e.value.reduce((a, b) => a + b) / e.value.length,
      ),
  ]..sort((a, b) => a.centerX.compareTo(b.centerX));
  final headerY =
      headerLines.map((l) => l.cy).reduce((a, b) => a + b) /
      headerLines.length;

  int columnOf(double cx) {
    var best = cols.first;
    var bestDx = (cx - best.centerX).abs();
    for (final c in cols.skip(1)) {
      final dx = (cx - c.centerX).abs();
      if (dx < bestDx) {
        best = c;
        bestDx = dx;
      }
    }
    return best.day;
  }

  // --- Time rows from the Saat column (union over pages, by start time).
  // Labels repeat per page; keep the page index for overflow handling.
  final pageRows = <List<_TimeRow>>[];
  for (final words in pages) {
    final rows = <_TimeRow>[];
    for (final line in _toLines(words)) {
      final t = _timeOf(line.text);
      if (t != null) {
        rows.add(_TimeRow(start: t.start, end: t.end, cy: line.cy));
      }
    }
    rows.sort((a, b) => b.cy.compareTo(a.cy));
    pageRows.add(rows);
  }
  final allRows = {for (final rows in pageRows) for (final r in rows) r.start};
  if (allRows.isEmpty) {
    throw const BilsisParseException('no-times');
  }
  final rowByStart = <int, _TimeRow>{};
  for (final rows in pageRows) {
    for (final r in rows) {
      rowByStart.putIfAbsent(r.start, () => r);
    }
  }
  // Chronological successor for page-break overflow (a cell fragment below
  // the last label of its page belongs to the next slot in time).
  final startsSorted = allRows.toList()..sort();
  int? nextStartAfter(int start) {
    for (final s in startsSorted) {
      if (s > start) return s;
    }
    return null;
  }

  // --- Content cells, code-anchored. ---
  final cells = <_Cell>[];
  for (var p = 0; p < pages.length; p++) {
    final rows = pageRows[p];
    if (rows.isEmpty) continue;
    final lines = _toLines(pages[p]);
    // Slot span per line from this page's labels.
    _TimeRow slotFor(double cy) {
      // Nearest label at or below the line (cells sit above their row
      // label); overflow below the last label goes to the next slot.
      _TimeRow? below;
      for (final r in rows) {
        if (r.cy <= cy + 4) {
          below ??= r;
          if ((cy - r.cy).abs() < (cy - below.cy).abs()) below = r;
        }
      }
      if (below != null) return below;
      // Above the first label (or an empty page top): nearest overall.
      var best = rows.first;
      for (final r in rows.skip(1)) {
        if ((cy - r.cy).abs() < (cy - best.cy).abs()) best = r;
      }
      return best;
    }

    // Content lines only: below the header row, not a header/time line.
    final content = lines.where((l) {
      if (l.cy >= headerY - 6) return false;
      if (_dayOf(l.text) != null) return false;
      if (_timeOf(l.text) != null) return false;
      return true;
    }).toList();
    // Group by day column, keep top-to-bottom order.
    final byCol = <int, List<_Line>>{};
    for (final l in content) {
      byCol.putIfAbsent(columnOf(l.cx), () => []).add(l);
    }
    for (final entry in byCol.entries) {
      final day = entry.key;
      final col = entry.value;
      // Split into cells at code lines.
      var current = <String>[];
      var currentTop = 0.0;
      void flush() {
        if (current.isEmpty) return;
        var row = slotFor(currentTop);
        // Overflow fragment below the last label: next chronological slot.
        if (currentTop < rows.last.cy - 8) {
          final next = nextStartAfter(rows.last.start);
          if (next != null) row = rowByStart[next]!;
        }
        cells.add(
          _Cell(
            day: day,
            start: row.start,
            end: row.end,
            lines: List.of(current),
          ),
        );
        current = <String>[];
      }

      for (final l in col) {
        final compact = l.text.replaceAll(RegExp(r'\s+'), '');
        if (_codeOf(compact) != null) flush();
        if (current.isEmpty) currentTop = l.cy;
        current.add(l.text);
      }
      flush();
    }
  }

  // --- Classify cell lines into code/title/room/instructor. ---
  final courseCells = <String, _CourseAcc>{};
  for (final cell in cells) {
    if (cell.lines.isEmpty) continue;
    final compact = cell.lines.first.replaceAll(RegExp(r'\s+'), '');
    final code = _codeOf(compact);
    if (code == null) continue; // Stray fragment without a course code.
    var roomIdx = -1;
    for (var i = 1; i < cell.lines.length; i++) {
      if (_roomPattern.hasMatch(cell.lines[i].trim())) {
        roomIdx = i;
        break;
      }
    }
    final String? room;
    final String title;
    final String? instructor;
    if (roomIdx == -1) {
      room = null;
      final rest = cell.lines.skip(1).toList();
      if (rest.isNotEmpty && rest.last.contains('.')) {
        instructor = rest.last;
        title = rest.take(rest.length - 1).join(' ');
      } else {
        instructor = null;
        title = rest.join(' ');
      }
    } else {
      room = cell.lines[roomIdx].trim();
      title = cell.lines.sublist(1, roomIdx).join(' ');
      final tail = cell.lines.sublist(roomIdx + 1);
      instructor = tail.isEmpty ? null : tail.join(' ');
    }
    final cleanTitle = title.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (cleanTitle.isEmpty) continue;
    final key = '${cell.day}|${cell.start}|${code.code}';
    final acc = courseCells.putIfAbsent(
      '${code.code}|${code.section}',
      () => _CourseAcc(
        code: code.code,
        section: code.section,
        title: cleanTitle,
      ),
    );
    // First details win, except titles: repeated blocks agree, but keep
    // the longest variant in case one print wraps tighter than another.
    if (cleanTitle.length > acc.title.length) acc.title = cleanTitle;
    if (acc.room == null && room != null) acc.room = room;
    if (acc.instructor == null && instructor != null) {
      acc.instructor = instructor;
    }
    acc.addSlot(key, cell);
  }

  final courses = [
    for (final acc in courseCells.values)
      BilsisCourse(
        code: acc.code,
        section: acc.section,
        title: acc.title,
        room: acc.room,
        instructor: acc.instructor,
        slots: acc.orderedSlots(),
      ),
  ]..sort((a, b) => a.code.compareTo(b.code));
  if (courses.isEmpty) {
    throw const BilsisParseException('no-courses');
  }
  return BilsisSchedule(courses: courses);
}

class _CourseAcc {
  final String code;
  final String section;
  String title;
  String? room;
  String? instructor;
  final _slots = <String, BilsisSlot>{};

  _CourseAcc({required this.code, required this.section, required this.title});

  void addSlot(String key, _Cell cell) {
    _slots.putIfAbsent(
      key,
      () => BilsisSlot(
        day: cell.day,
        startMinutes: cell.start,
        endMinutes: cell.end,
      ),
    );
  }

  List<BilsisSlot> orderedSlots() {
    final sorted = _slots.values.toList()
      ..sort((a, b) {
        final d = a.day.compareTo(b.day);
        return d != 0 ? d : a.startMinutes.compareTo(b.startMinutes);
      });
    // Bilsis prints a multi-hour block as one row per hour with a short
    // break between rows (e.g. 08:40-09:30 + 09:40-10:30). Merge rows of
    // the same course on the same day separated by at most a break, so
    // the import creates one two-hour slot instead of two one-hour ones.
    const breakMinutes = 15;
    final merged = <BilsisSlot>[];
    for (final slot in sorted) {
      final last = merged.isEmpty ? null : merged.last;
      if (last != null &&
          last.day == slot.day &&
          slot.startMinutes - last.endMinutes <= breakMinutes) {
        merged[merged.length - 1] = BilsisSlot(
          day: last.day,
          startMinutes: last.startMinutes,
          endMinutes: slot.endMinutes > last.endMinutes
              ? slot.endMinutes
              : last.endMinutes,
        );
      } else {
        merged.add(slot);
      }
    }
    return merged;
  }
}
