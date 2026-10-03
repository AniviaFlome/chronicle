import 'dart:convert';

import 'package:chronicle/services/course_catalog/course_catalog.dart';
import 'package:chronicle/services/course_catalog/itu_obs.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

// Mirrors the live DersBilgiSearch markup (nested tables, single quotes
// elsewhere on OBS pages).
const _ituSearchFixture = '''
<div class="table-responsive">
<table class="table table-bordered"><tbody><tr><td>
<table class="table table-bordered">
<thead><tr><th>Ders Kodu</th><th>Ders Adı</th><th>Dil</th>
<th>Ders Katalog Bilgisi</th><th>Ders Not Dağılımı</th></tr></thead>
<tbody><tr>
<td style="padding: 12px;">MAT103 -MAT103E</td>
<td style="padding: 12px;">Matematik I / Mathematics I</td>
<td style="padding: 12px;">Türkçe/English</td>
<td><a href="/public/DersKatalog/DersKatalogBilgiBransDersKodu?bransKodu=MAT&dersNo=103">Katalog</a></td>
<td><a href="/public/DersNotDagilimi?bransKodu=MAT&dersNo=103&yil=2026">Notlar</a></td>
</tr></tbody></table>
</td></tr></tbody></table></div>
''';

// Mirrors the live catalog form: strong-labeled cells + a 6-cell credits row.
const _ituKatalogFixture = '''
<table><tbody>
<tr><td colspan="3"><strong>Dersin Adı</strong>: Matematik I</td>
<td colspan="3"><strong>Course Name</strong>: Mathematics I</td></tr>
<tr><td colspan="3"><strong>Bölüm / Program</strong>: Matematik / Matematik Mühendisliği
<br /><strong>Department / Program</strong>: Mathematics / Mathematics Engineering</td>
<td colspan="3"><strong>Dersin Dili (Course Language)</strong>: Türkçe/English</td></tr>
<tr><th rowspan="2">Kod<br /> (Code)</th><th rowspan="2">Kredi<br /> (Local Credits)</th>
<th rowspan="2">AKTS Kredi<br /> (ECTS Credits)</th>
<th colspan="3">Ders Uygulaması, Saat/Hafta<br />(Course Implementation, Hours/Week)</th></tr>
<tr><th>Ders<br />(Theoretical)</th><th>Uygulama<br />(Tutorial)</th><th>Laboratuar<br />(Laboratory)</th></tr>
<tr><td class="align-middle text-center">MAT103-MAT103E</td>
<td class="align-middle text-center">5</td>
<td class="align-middle text-center">6,5</td>
<td class="align-middle text-center">4</td>
<td class="align-middle text-center">2</td>
<td class="align-middle text-center">0</td></tr>
</tbody></table>
''';

const _ituBranchesLs = '[{"bransKoduId":26,"dersBransKodu":"MAT"}]';
const _ituBranchesLu = '[{"bransKoduId":77,"dersBransKodu":"MAT"}]';

// Mirrors the live building-code table: code cells, name cells.
const _ituBinaFixture = '''
<table><tbody>
<tr><td><strong>MED</strong></td><td>Merkezi Derslik Binası</td></tr>
</tbody></table>
''';

// Mirrors the live program table: <br/>-separated multi-session cells,
// single-quoted anchors, trailing quota/program/prerequisite columns.
const _ituProgramFixture = '''
<table><thead><tr class="table-baslik"><td>CRN</td><td>Ders Kodu</td><td>Ders Adı</td>
<td>Öğretim Yöntemi</td><td>Öğretim Üyesi</td><td>Bina</td><td>Gün</td><td>Saat</td>
<td>Derslik</td><td>Kontenjan</td><td>Yazılan</td><td>R</td><td>P</td><td>Önşart</td><td>B</td>
</tr></thead><tbody>
<tr><td>10173</td>
<td><a href='https://obs.itu.edu.tr/public/DersBilgi?bransKodu=MAT&dersNo=103'>MAT 103</a></td>
<td>Matematik I</td><td>Fiziksel (Yüz yüze)</td><td>Fuat Ergezen</td>
<td><a href='/public/GenelTanimlamalar/BinaKodlariList'>MED<br/>MED</a></td>
<td>Pazartesi<br />Salı</td><td>08:30/11:29<br />11:30/13:29</td><td>A12<br />A12</td>
<td>127</td><td>125</td><td>-</td><td>x</td><td>-</td><td>-</td></tr>
<tr><td>10182</td>
<td><a href='https://obs.itu.edu.tr/public/DersBilgi?bransKodu=MAT&dersNo=103'>MAT 103E</a></td>
<td>Mathematics I</td><td>Fiziksel (Yüz yüze)</td><td>Ayşegül Tepe</td>
<td>MED</td><td>Pazartesi</td><td>14:30/15:59</td><td>A14</td>
<td>100</td><td>100</td><td>-</td><td>x</td><td>-</td><td>-</td></tr>
</tbody></table>
''';

/// Builds a UTF-8 HTML response. The plain [http.Response] string
/// constructor encodes with latin-1 and throws on Turkish characters.
http.Response _htmlResponse(String html) => http.Response.bytes(
  utf8.encode(html),
  200,
  headers: {'content-type': 'text/html; charset=utf-8'},
);

MockClient _ituClient({
  bool searchFound = true,
  bool lsHasMat = true,
  bool programHasRows = true,
}) {
  return MockClient((request) async {
    final path = request.url.path;
    if (path.endsWith('DersBilgiSearch')) {
      if (!searchFound) return http.Response('err', 500);
      return _htmlResponse(_ituSearchFixture);
    }
    if (path.contains('DersKatalogBilgiBransDersKodu')) {
      return _htmlResponse(_ituKatalogFixture);
    }
    if (path.endsWith('SearchBransKoduByProgramSeviye')) {
      final level = request.url.queryParameters['programSeviyeTipiAnahtari'];
      final hasMat =
          (level == 'LS' && lsHasMat) || (level == 'LU' && !lsHasMat);
      return http.Response(hasMat ? _ituBranchesLs : '[]', 200);
    }
    if (path.endsWith('DersProgramSearch')) {
      return programHasRows
          ? _htmlResponse(_ituProgramFixture)
          : _htmlResponse('<table><tbody></tbody></table>');
    }
    if (path.endsWith('BinaKodlariList')) {
      return _htmlResponse(_ituBinaFixture);
    }
    return http.Response('nope', 404);
  });
}

void main() {
  group('parseCourseCode', () {
    test('parses spaced and suffixed codes', () {
      expect(parseCourseCode('MAT 103E'), (branch: 'MAT', number: '103'));
      expect(parseCourseCode('mat103'), (branch: 'MAT', number: '103'));
      expect(parseCourseCode('TRO 601'), (branch: 'TRO', number: '601'));
    });

    test('rejects garbage', () {
      expect(parseCourseCode('hello'), isNull);
      expect(parseCourseCode('123'), isNull);
      expect(parseCourseCode(''), isNull);
    });
  });

  group('itu catalog', () {
    test('full lookup returns course facts and sections', () async {
      final catalog = ItuObsCatalog(client: _ituClient());
      final (course: course, sections: sections) = await catalog.lookup(
        'MAT 103E',
      );
      expect(course.code, 'MAT103-MAT103E');
      expect(course.name, 'Matematik I');
      expect(course.nameAlt, 'Mathematics I');
      expect(course.language, 'Türkçe/English');
      expect(course.credits, 5);
      expect(course.ects, 6.5);
      expect(course.theoryHours, 4);
      expect(course.practiceHours, 2);
      expect(course.labHours, 0);
      expect(course.department, 'Matematik / Matematik Mühendisliği');

      expect(sections, hasLength(2));
      final first = sections.first;
      expect(first.crn, '10173');
      expect(first.code, 'MAT 103');
      expect(first.instructor, 'Fuat Ergezen');
      expect(first.room, 'A12');
      expect(first.slots, hasLength(2));
      expect(first.slots[0].weekday, DateTime.monday);
      expect(first.slots[0].startMinutes, 8 * 60 + 30);
      // ITU prints inclusive end minutes (:29 tiles against the next
      // session's :30 start), so ends round up to the displayed time.
      expect(first.slots[0].endMinutes, 11 * 60 + 30);
      expect(first.slots[0].room, 'A12');
      expect(first.slots[1].weekday, DateTime.tuesday);
      expect(first.slots[1].endMinutes, 13 * 60 + 30);
      expect(first.method, 'Fiziksel (Yüz yüze)');
      expect(first.building, 'Merkezi Derslik Binası - MED');
      expect(first.quota, 127);
      expect(first.enrolled, 125);
      expect(first.prerequisites, isNull);
      expect(sections.last.code, 'MAT 103E');
      expect(sections.last.slots.single.startMinutes, 14 * 60 + 30);
      expect(sections.last.slots.single.endMinutes, 16 * 60);
    });

    test('unknown code maps HTTP 500 to notFound', () async {
      final catalog = ItuObsCatalog(
        client: _ituClient(searchFound: false),
      );
      await expectLater(
        catalog.lookup('ZZZ 999'),
        throwsA(
          isA<CourseLookupException>().having(
            (e) => e.failure,
            'failure',
            CourseLookupFailure.notFound,
          ),
        ),
      );
    });

    test('garbage code fails validation without network', () async {
      var calls = 0;
      final catalog = ItuObsCatalog(
        client: MockClient((_) async {
          calls++;
          return http.Response('', 500);
        }),
      );
      await expectLater(
        catalog.lookup('???'),
        throwsA(
          isA<CourseLookupException>().having(
            (e) => e.failure,
            'failure',
            CourseLookupFailure.invalidCode,
          ),
        ),
      );
      expect(calls, 0);
    });

    test('looksLikeCrn spots section identifiers', () {
      expect(looksLikeCrn('10173'), isTrue);
      expect(looksLikeCrn('CRN 10173'), isTrue);
      expect(looksLikeCrn('crn:10173'), isTrue);
      expect(looksLikeCrn('CRN#10173'), isTrue);
      expect(looksLikeCrn('1'), isFalse); // too short for a CRN
      expect(looksLikeCrn('MAT 103'), isFalse);
      expect(looksLikeCrn('MAT103E'), isFalse);
      expect(looksLikeCrn('???'), isFalse);
    });

    test('CRN input explains instead of notFound, without network', () async {
      var calls = 0;
      final catalog = ItuObsCatalog(
        client: MockClient((_) async {
          calls++;
          return http.Response('', 500);
        }),
      );
      for (final input in ['10173', 'CRN 10173']) {
        await expectLater(
          catalog.lookup(input),
          throwsA(
            isA<CourseLookupException>().having(
              (e) => e.failure,
              'failure',
              CourseLookupFailure.crnNotSupported,
            ),
          ),
        );
      }
      expect(calls, 0);
    });

    test('branch missing at LS falls back to LU', () async {
      final seen = <String>[];
      final catalog = ItuObsCatalog(
        client: MockClient((request) async {
          final path = request.url.path;
          if (path.endsWith('DersBilgiSearch')) {
            return _htmlResponse(_ituSearchFixture);
          }
          if (path.contains('DersKatalogBilgiBransDersKodu')) {
            return _htmlResponse(_ituKatalogFixture);
          }
          if (path.endsWith('SearchBransKoduByProgramSeviye')) {
            final level =
                request.url.queryParameters['programSeviyeTipiAnahtari'];
            seen.add(level!);
            return _htmlResponse(level == 'LU' ? _ituBranchesLu : '[]');
          }
          if (path.endsWith('DersProgramSearch')) {
            expect(
              request.url.queryParameters['ProgramSeviyeTipiAnahtari'],
              'LU',
            );
            return _htmlResponse(_ituProgramFixture);
          }
          return http.Response('nope', 404);
        }),
      );
      final result = await catalog.lookup('MAT 103');
      final sections = result.sections;
      expect(seen, ['LS', 'LU']);
      expect(sections, hasLength(2));
    });

    test('empty program table yields sections-less course', () async {
      final catalog = ItuObsCatalog(
        client: _ituClient(programHasRows: false),
      );
      final (course: course, sections: sections) = await catalog.lookup(
        'MAT 103',
      );
      expect(course.name, 'Matematik I');
      expect(sections, isEmpty);
    });
  });
}
