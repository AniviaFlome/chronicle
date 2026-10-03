import 'package:html/dom.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:http/http.dart' as http;

import '../menu/menu_provider.dart' show decodeMenuBody, menuHttpHeaders;
import 'course_catalog.dart';

/// ITU course lookup over the public ÖBS pages (no login required):
///
/// - `DersBilgiSearch` confirms the code and links the catalog form,
/// - `DersKatalogBilgiBransDersKodu` carries credits / hours / names,
/// - `DersProgramSearch` lists the term's sections (CRN, instructor,
///   building, days, times, room).
///
/// Unknown codes answer HTTP 500, which maps to "not found".
class ItuObsCatalog {
  ItuObsCatalog({http.Client? client})
    : _client = client ?? http.Client(),
      _ownsClient = client == null;

  static const _origin = 'https://obs.itu.edu.tr';
  static const _timeout = Duration(seconds: 12);

  final http.Client _client;
  final bool _ownsClient;

  void close() {
    if (_ownsClient) _client.close();
  }

  /// Looks up [rawCode] (e.g. `MAT 103E`). Returns the catalog facts plus
  /// every section of the current term (Turkish and English rows alike).
  Future<({CatalogCourse course, List<CourseSection> sections})> lookup(
    String rawCode,
  ) async {
    if (looksLikeCrn(rawCode)) {
      throw CourseLookupException(
        CourseLookupFailure.crnNotSupported,
        'CRN lookup is not supported: $rawCode',
      );
    }
    final parsed = parseCourseCode(rawCode);
    if (parsed == null) {
      throw CourseLookupException(
        CourseLookupFailure.invalidCode,
        'Unrecognized course code: $rawCode',
      );
    }
    final search = await _searchCourse(parsed.branch, parsed.number);
    final course = await _fetchDetail(search.detailUri);
    final sections = await _fetchSections(parsed.branch, parsed.number);
    return (course: course, sections: sections);
  }

  /// Confirms the code exists; returns display fields + catalog link.
  Future<
    ({String code, String nameTr, String nameEn, String language, Uri detailUri})
  >
  _searchCourse(String branch, String number) async {
    final uri = Uri.parse(
      '$_origin/public/DersBilgi/DersBilgiSearch'
      '?bransKodu=$branch&dersNo=$number',
    );
    final body = await _get(uri, notFoundAsEmpty: true);
    if (body == null) {
      throw CourseLookupException(
        CourseLookupFailure.notFound,
        'Course not found: $branch $number',
      );
    }
    final doc = html_parser.parse(body);
    for (final anchor in doc.querySelectorAll('a')) {
      final href = anchor.attributes['href'] ?? '';
      if (!href.contains('DersKatalogBilgiBransDersKodu')) continue;
      final row = _ancestorRow(anchor);
      final cells = row?.querySelectorAll('td') ?? const <Element>[];
      final code = cells.isNotEmpty ? cells[0].text.trim() : '$branch $number';
      final names = cells.length > 1 ? cells[1].text.trim().split(' / ') : const <String>[];
      final language = cells.length > 2 ? cells[2].text.trim() : '';
      return (
        code: code.isEmpty ? '$branch $number' : code,
        nameTr: names.isNotEmpty ? names[0].trim() : '',
        nameEn: names.length > 1 ? names[1].trim() : '',
        language: language,
        detailUri: _originUri(href),
      );
    }
    throw CourseLookupException(
      CourseLookupFailure.notFound,
      'Course not found: $branch $number',
    );
  }

  /// Catalog form: names, credits, ECTS, weekly hours, department.
  Future<CatalogCourse> _fetchDetail(Uri uri) async {
    final body = await _get(uri, notFoundAsEmpty: true);
    if (body == null) {
      throw const CourseLookupException(
        CourseLookupFailure.network,
        'Catalog page failed',
      );
    }
    final doc = html_parser.parse(body);
    String? nameTr;
    String? nameEn;
    String? department;
    String? language;
    for (final td in doc.querySelectorAll('td')) {
      for (final strong in td.querySelectorAll('strong')) {
        final key = strong.text.trim();
        // Catalog cells split values across lines (e.g. department names
        // with <br/>); collapse the runs so notes render on one line.
        final value = _clean(
          td.text.replaceFirst(key, '').replaceFirst(RegExp(r'^:\s*'), ''),
        );
        switch (key) {
          case 'Dersin Adı':
            nameTr = value;
          case 'Course Name':
            nameEn = value;
          case 'Bölüm / Program':
            department = value.split('Department / Program').first.trim();
          case 'Dersin Dili (Course Language)':
            language = value;
        }
      }
    }
    String code = '';
    double? credits;
    double? ects;
    int? theory;
    int? practice;
    int? lab;
    for (final row in doc.querySelectorAll('tr')) {
      final cells = row.querySelectorAll('td');
      if (cells.length < 6) continue;
      if (int.tryParse(cells[1].text.trim()) == null) continue;
      if (_parseDecimal(cells[2].text) == null) continue;
      code = _clean(cells[0].text);
      credits = _parseDecimal(cells[1].text);
      ects = _parseDecimal(cells[2].text);
      theory = int.tryParse(cells[3].text.trim());
      practice = int.tryParse(cells[4].text.trim());
      lab = int.tryParse(cells[5].text.trim());
      break;
    }
    String? description;
    for (final strong in doc.querySelectorAll('strong')) {
      if (strong.text.contains('Dersin Tanımı')) {
        final host = strong.parent;
        if (host != null) {
          description = _clean(
            host.text
                .replaceFirst(strong.text, '')
                .replaceFirst(RegExp(r'^:\s*'), ''),
          );
        }
        break;
      }
    }
    return CatalogCourse(
      code: code,
      name: (nameTr ?? '').isEmpty ? code : nameTr!,
      nameAlt: (nameEn ?? '').isEmpty ? null : nameEn,
      language: (language ?? '').isEmpty ? null : language,
      credits: credits,
      ects: ects,
      theoryHours: theory,
      practiceHours: practice,
      labHours: lab,
      department: (department ?? '').isEmpty ? null : department,
      description: (description ?? '').isEmpty ? null : description,
    );
  }

  /// Term sections for [branch] + [number]. Tries Lisans then Lisansüstü.
  Future<List<CourseSection>> _fetchSections(
    String branch,
    String number,
  ) async {
    for (final level in ['LS', 'LU']) {
      final branches = await _branchIds(level);
      final id = branches[branch];
      if (id == null) continue;
      final uri = Uri.parse(
        '$_origin/public/DersProgram/DersProgramSearch'
        '?ProgramSeviyeTipiAnahtari=$level&DersBransKoduId=$id',
      );
      final body = await _get(uri, notFoundAsEmpty: false);
      if (body == null) continue;
      final sections = _parseSections(body, branch, number);
      if (sections.isNotEmpty) return _withBuildingNames(sections);
      // Branch exists at this level but holds no rows for this number;
      // the other level may still have them.
    }
    return const [];
  }

  /// Building codes keyed by code (`MED` → `Merkezi Derslik Binası`),
  /// fetched once per instance from the public code table.
  Map<String, String>? _buildingNames;

  Future<Map<String, String>> _buildings() async {
    final cached = _buildingNames;
    if (cached != null) return cached;
    final names = <String, String>{};
    try {
      final body = await _get(
        Uri.parse('$_origin/public/GenelTanimlamalar/BinaKodlariList'),
        notFoundAsEmpty: false,
      );
      if (body != null) {
        for (final row in html_parser.parse(body).querySelectorAll('tr')) {
          final cells = row.querySelectorAll('td');
          if (cells.length < 2) continue;
          final code = cells[0].text.trim();
          final name = cells[1].text.trim();
          if (code.isNotEmpty && name.isNotEmpty) names[code] = name;
        }
      }
    } catch (_) {
      // Best effort: a failed table fetch leaves raw codes in place.
    }
    return _buildingNames = names;
  }

  /// Replaces known building codes with `Name - CODE`; unknown codes
  /// (or a failed table fetch) stay as-is.
  Future<List<CourseSection>> _withBuildingNames(
    List<CourseSection> sections,
  ) async {
    final names = await _buildings();
    if (names.isEmpty) return sections;
    return [
      for (final s in sections)
        CourseSection(
          crn: s.crn,
          code: s.code,
          name: s.name,
          instructor: s.instructor,
          building: names[s.building] == null
              ? s.building
              : '${names[s.building]} - ${s.building}',
          room: s.room,
          slots: s.slots,
          method: s.method,
          prerequisites: s.prerequisites,
          quota: s.quota,
          enrolled: s.enrolled,
        ),
    ];
  }

  Future<Map<String, int>> _branchIds(String level) async {
    final uri = Uri.parse(
      '$_origin/public/DersProgram/SearchBransKoduByProgramSeviye'
      '?programSeviyeTipiAnahtari=$level',
    );
    final response = await _client
        .get(uri, headers: menuHttpHeaders)
        .timeout(_timeout);
    if (response.statusCode != 200) {
      throw CourseLookupException(
        CourseLookupFailure.network,
        'Branch list failed: HTTP ${response.statusCode}',
      );
    }
    // Minimal JSON decode without dart:convert ceremony: the payload is
    // [{"bransKoduId":26,"dersBransKodu":"MAT"}, ...].
    final ids = <String, int>{};
    for (final match in RegExp(
      r'"bransKoduId"\s*:\s*(\d+)\s*,\s*"dersBransKodu"\s*:\s*"([A-Z]+)"',
    ).allMatches(decodeMenuBody(response))) {
      ids[match.group(2)!] = int.parse(match.group(1)!);
    }
    return ids;
  }

  /// Parses section rows; keeps rows of this branch + number in any
  /// language suffix (MAT 103 and MAT 103E alike — the UI shows the code).
  List<CourseSection> _parseSections(
    String html,
    String branch,
    String number,
  ) {
    final doc = html_parser.parse(html);
    final sections = <CourseSection>[];
    for (final row in doc.querySelectorAll('tbody tr')) {
      final cells = row.querySelectorAll('td');
      if (cells.length < 14) continue;
      if (int.tryParse(cells[0].text.trim()) == null) continue;
      final code = cells[1].text.trim().replaceAll(RegExp(r'\s+'), ' ');
      final parsed = parseCourseCode(code.replaceAll(' ', ''));
      if (parsed == null ||
          parsed.branch != branch ||
          parsed.number != number) {
        continue;
      }
      final buildings = _brSplit(cells[5]);
      final days = _brSplit(cells[6]);
      final times = _brSplit(cells[7]);
      final rooms = _brSplit(cells[8]);
      final slots = <CourseDaySlot>[];
      for (var i = 0; i < days.length; i++) {
        final weekday = _turkishWeekday(days[i]);
        final range = i < times.length ? _parseRange(times[i]) : null;
        if (weekday == null || range == null) continue;
        // Building/room cells align with the day cells by index.
        slots.add(
          CourseDaySlot(
            weekday: weekday,
            startMinutes: range.$1,
            endMinutes: range.$2,
            room: i < rooms.length ? rooms[i] : '',
          ),
        );
      }
      final prereq = cells[13].text.trim();
      final method = cells[3].text.trim();
      sections.add(
        CourseSection(
          crn: cells[0].text.trim(),
          code: code,
          name: cells[2].text.trim(),
          instructor: cells[4].text.trim(),
          building: buildings.isNotEmpty ? buildings.first : '',
          room: rooms.isNotEmpty ? rooms.first : '',
          slots: slots,
          method: method.isEmpty ? null : method,
          prerequisites: prereq == '-' || prereq.isEmpty ? null : prereq,
          quota: int.tryParse(cells[9].text.trim()),
          enrolled: int.tryParse(cells[10].text.trim()),
        ),
      );
    }
    return sections;
  }

  /// GET with one retry. Returns null on HTTP 500 when [notFoundAsEmpty]
  /// (ITU answers unknown codes that way) instead of throwing.
  Future<String?> _get(Uri uri, {required bool notFoundAsEmpty}) async {
    CourseLookupException? lastError;
    for (var attempt = 0; attempt < 2; attempt++) {
      if (attempt > 0) {
        await Future.delayed(const Duration(milliseconds: 500));
      }
      try {
        final response = await _client
            .get(uri, headers: menuHttpHeaders)
            .timeout(_timeout);
        if (response.statusCode == 200) return decodeMenuBody(response);
        if (response.statusCode == 500 && notFoundAsEmpty) return null;
        lastError = CourseLookupException(
          CourseLookupFailure.network,
          'HTTP ${response.statusCode}',
        );
      } catch (e) {
        lastError = CourseLookupException(
          CourseLookupFailure.network,
          'Network error: $e',
        );
      }
    }
    throw lastError ?? const CourseLookupException(CourseLookupFailure.network);
  }

  static Uri _originUri(String href) {
    final parsed = Uri.tryParse(href);
    if (parsed == null) return Uri.parse(_origin);
    if (parsed.hasScheme) return parsed;
    return Uri.parse(_origin).resolveUri(parsed);
  }

  static Element? _ancestorRow(Element element) {
    Element? node = element.parent;
    while (node != null && node.localName != 'tr') {
      node = node.parent;
    }
    return node;
  }

  /// Splits a cell on <br> at any depth (building/day/time/room cells
  /// nest the breaks inside anchors).
  static List<String> _brSplit(Element cell) {
    final parts = <String>[];
    final current = StringBuffer();
    void flush() {
      final text = current.toString().trim();
      if (text.isNotEmpty) parts.add(text);
      current.clear();
    }

    void walk(Node node) {
      if (node is Element && node.localName == 'br') {
        flush();
        return;
      }
      if (node is Text) {
        current.write(node.text);
        return;
      }
      for (final child in node.nodes) {
        walk(child);
      }
    }

    walk(cell);
    flush();
    return parts;
  }

  static const _weekdays = {
    'pazartesi': DateTime.monday,
    'salı': DateTime.tuesday,
    'çarşamba': DateTime.wednesday,
    'perşembe': DateTime.thursday,
    'cuma': DateTime.friday,
    'cumartesi': DateTime.saturday,
    'pazar': DateTime.sunday,
  };

  static int? _turkishWeekday(String raw) =>
      _weekdays[raw.trim().toLowerCase()];

  /// Collapses inner newlines/whitespace runs from catalog cells so
  /// multi-line values (department names, descriptions) land on one line.
  static String _clean(String raw) =>
      raw.replaceAll(RegExp(r'\s+'), ' ').trim();

  /// Parses `08:30/11:29` into (start, end) minutes. ITU prints inclusive
  /// end minutes (`:29`/`:59` tile exactly against the next session's
  /// start, e.g. `08:30/11:29` then `11:30/…`), so those round up to the
  /// displayed `:30`/`:00`.
  static (int, int)? _parseRange(String raw) {
    final match = RegExp(
      r'(\d{1,2}):(\d{2})\s*/\s*(\d{1,2}):(\d{2})',
    ).firstMatch(raw.trim());
    if (match == null) return null;
    final start = int.parse(match.group(1)!) * 60 + int.parse(match.group(2)!);
    var end = int.parse(match.group(3)!) * 60 + int.parse(match.group(4)!);
    final endMinute = int.parse(match.group(4)!);
    if (endMinute == 29 || endMinute == 59) end += 1;
    if (end <= start || end > 24 * 60) return null;
    return (start, end);
  }

  /// Parses `6,5` / `5` decimals.
  static double? _parseDecimal(String raw) {
    final cleaned = raw.trim().replaceAll('.', '').replaceAll(',', '.');
    return double.tryParse(cleaned);
  }
}
