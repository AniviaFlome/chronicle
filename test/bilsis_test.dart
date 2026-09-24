import 'package:chronicle/screens/bilsis_import_dialog.dart';
import 'package:chronicle/services/bilsis.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'dart:async';

/// Builds words for one visual line centered on [cx], with realistic
/// glyph widths so column gaps survive line splitting.
List<BilsisWord> line(String text, double cx, double cy) {
  final parts = text.split(' ');
  final widths = [for (final p in parts) p.length * 5.2 + 3.0];
  const gap = 4.0;
  final total =
      widths.reduce((a, b) => a + b) + gap * (parts.length - 1);
  var x = cx - total / 2;
  final out = <BilsisWord>[];
  for (var i = 0; i < parts.length; i++) {
    out.add(BilsisWord(text: parts[i], left: x, right: x + widths[i], cy: cy));
    x += widths[i] + gap;
  }
  return out;
}

List<BilsisWord> page(List<List<BilsisWord>> lines) =>
    [for (final l in lines) ...l];

const monX = 152.0;
const tueX = 291.0;
const wedX = 430.0;
const thuX = 569.0;

List<List<BilsisWord>> headers() => [
  line('Saat', 65, 511),
  line('Pazartesi', 178, 511),
  line('Salı', 317, 511),
  line('Çarşamba', 456, 511),
  line('Perşembe', 595, 511),
  line('Cuma', 733, 511),
];

void main() {
  group('parseBilsisPages', () {
    test('parses courses, wrapped lines and page-break duplicates', () {
      final p0 = [
        ...headers(),
        line('08:40-09:30', 65, 463),
        line('09:40-10:30', 65, 404),
        // Monday: one course, two slots.
        line('GKS104(3)', monX, 480),
        line('BİLİM VE ARAŞTIRMA ETİĞİ', monX, 468),
        line('C-K2-09[102]', monX, 457),
        line('Doç.Dr. SİNEM DİNÇOL ÖZGÜR', monX, 446),
        line('GKS104(3)', monX, 427),
        line('BİLİM VE ARAŞTIRMA ETİĞİ', monX, 415),
        line('C-K2-09[102]', monX, 404 - 0.5),
        line('Doç.Dr. SİNEM DİNÇOL ÖZGÜR', monX, 393),
        // Tuesday 08:40.
        line('EFL203(1)', tueX, 480),
        line('İNGİLİZ EDEBİYATI I', tueX, 468),
        line('C-K3-06[52]', tueX, 457),
        line('Doç.Dr. ÖZLEM CANARAN', tueX, 446),
        // Wednesday 09:40 with wrapped title and wrapped instructor.
        line('EGT202(2)', wedX, 168),
        line('ÖĞRETİM İLKE VE', wedX, 156),
        line('YÖNTEMLERİ', wedX, 144),
        line('C-K1-12[132]', wedX, 132),
        line('Doç.Dr. SEVİNÇ GELMEZ', wedX, 121),
        line('BURAKGAZİ', wedX, 111),
        // Overflow fragment of Thursday 10:40 below the last label,
        // repeated in full on the next page (page-break split row).
        line('EGT251(1)', thuX, 30),
        line('ÇOCUK PSİKOLOJİSİ', thuX, 20),
        line('C-K1-12[132]', thuX, 12),
        line('Doç.Dr. GÖKHAN TÖRET', thuX, 4),
      ];
      final p1 = [
        ...headers(),
        line('10:40-11:30', 65, 564),
        line('EGT251(1)', thuX, 581),
        line('ÇOCUK PSİKOLOJİSİ', thuX, 569),
        line('C-K1-12[132]', thuX, 558),
        line('Doç.Dr. GÖKHAN TÖRET', thuX, 547),
      ];
      final schedule = parseBilsisPages([page(p0), page(p1)]);

      expect(schedule.courses.map((c) => c.code),
          ['EFL203', 'EGT202', 'EGT251', 'GKS104']);
      // Back-to-back rows of one course merge into a single block.
      expect(schedule.slotCount, 4);

      final gks = schedule.courses.firstWhere((c) => c.code == 'GKS104');
      expect(gks.section, '3');
      expect(gks.title, 'BİLİM VE ARAŞTIRMA ETİĞİ');
      expect(gks.room, 'C-K2-09[102]');
      expect(gks.instructor, 'Doç.Dr. SİNEM DİNÇOL ÖZGÜR');
      expect(gks.slots.map((s) => (s.day, s.startMinutes, s.endMinutes)), [
        (1, 520, 630),
      ]);

      final efl = schedule.courses.firstWhere((c) => c.code == 'EFL203');
      expect(efl.slots.single.day, 2);

      final egt = schedule.courses.firstWhere((c) => c.code == 'EGT202');
      expect(egt.title, 'ÖĞRETİM İLKE VE YÖNTEMLERİ');
      expect(egt.instructor, 'Doç.Dr. SEVİNÇ GELMEZ BURAKGAZİ');
      expect(egt.slots.single.day, 3);

      // The page-break duplicate must collapse into one slot.
      final cocuk = schedule.courses.firstWhere((c) => c.code == 'EGT251');
      expect(cocuk.slots, hasLength(1));
      expect(cocuk.slots.single.day, 4);
      expect(cocuk.slots.single.startMinutes, 640);
      expect(cocuk.slots.single.endMinutes, 690);
    });

    test('maps all five weekdays and supports room-less cells', () {
      final words = [
        ...headers(),
        line('13:40-14:30', 65, 139),
        line('SEM101(1)', 715, 168),
        line('SERBEST ÇALIŞMA', 715, 156),
        line('Dr. AD SOYAD', 715, 144),
        line('LAB101(2)', tueX, 168),
        line('UYGULAMA', tueX, 156),
        line('B-Z1-01[40]', tueX, 144),
      ];
      final schedule = parseBilsisPages([page(words)]);
      final seminer = schedule.courses.firstWhere((c) => c.code == 'SEM101');
      expect(seminer.slots.single.day, 5);
      expect(seminer.room, isNull);
      expect(seminer.instructor, 'Dr. AD SOYAD');
      expect(seminer.title, 'SERBEST ÇALIŞMA');
      final lab = schedule.courses.firstWhere((c) => c.code == 'LAB101');
      expect(lab.slots.single.day, 2);
    });

    test('keeps widely separated sessions apart', () {
      final words = page([
        ...headers(),
        line('08:40-09:30', 65, 463),
        line('13:40-14:30', 65, 139),
        line('MAT101(1)', monX, 480),
        line('MATEMATİK I', monX, 468),
        line('A-101[50]', monX, 457),
        line('MAT101(1)', monX, 168),
        line('MATEMATİK I', monX, 156),
        line('A-101[50]', monX, 144),
      ]);
      final schedule = parseBilsisPages([words]);
      final mat = schedule.courses.single;
      expect(mat.slots.map((s) => (s.startMinutes, s.endMinutes)), [
        (520, 570),
        (820, 870),
      ]);
    });

    test('throws on missing headers, times and courses', () {
      expect(
        () => parseBilsisPages([
          page([line('08:40-09:30', 65, 463)]),
        ]),
        throwsA(isA<BilsisParseException>()),
      );
      expect(
        () => parseBilsisPages([
          page([line('Pazartesi', 178, 511)]),
        ]),
        throwsA(isA<BilsisParseException>()),
      );
      expect(() => parseBilsisPages([]), throwsA(isA<BilsisParseException>()));
      expect(
        () => parseBilsisPages([
          page([
            ...headers(),
            line('08:40-09:30', 65, 463),
          ]),
        ]),
        throwsA(isA<BilsisParseException>()),
      );
    });
  });

  group('BilsisPreviewDialog', () {
    BilsisSchedule twoCourses() => BilsisSchedule(courses: [
      const BilsisCourse(
        code: 'GKS104',
        section: '3',
        title: 'BİLİM VE ARAŞTIRMA ETİĞİ',
        room: 'C-K2-09[102]',
        instructor: 'Doç.Dr. SİNEM DİNÇOL ÖZGÜR',
        slots: [
          BilsisSlot(day: 1, startMinutes: 520, endMinutes: 570),
          BilsisSlot(day: 1, startMinutes: 580, endMinutes: 630),
        ],
      ),
      const BilsisCourse(
        code: 'EFL203',
        section: '1',
        title: 'İNGİLİZ EDEBİYATI I',
        room: 'C-K3-06[52]',
        instructor: 'Doç.Dr. ÖZLEM CANARAN',
        slots: [BilsisSlot(day: 2, startMinutes: 520, endMinutes: 570)],
      ),
    ]);

    Future<Future<Set<String>?>> openDialog(
      WidgetTester tester,
      BilsisSchedule schedule,
    ) async {
      final completer = Completer<Set<String>?>();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () async {
                  completer.complete(
                    await showDialog<Set<String>>(
                      context: context,
                      builder: (_) => BilsisPreviewDialog(schedule: schedule),
                    ),
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      return completer.future;
    }

    testWidgets('lists courses and returns the ticked selection', (
      tester,
    ) async {
      final schedule = twoCourses();
      final future = await openDialog(tester, schedule);

      expect(find.text('GKS104 BİLİM VE ARAŞTIRMA ETİĞİ'), findsOneWidget);
      expect(find.text('EFL203 İNGİLİZ EDEBİYATI I'), findsOneWidget);
      expect(find.textContaining('C-K2-09[102]'), findsOneWidget);
      expect(find.text('Import 2 courses'), findsOneWidget);

      // Untick the first course; the import button counts down.
      await tester.tap(find.byType(CheckboxListTile).first);
      await tester.pumpAndSettle();
      expect(find.text('Import 1 course'), findsOneWidget);

      await tester.tap(find.text('Import 1 course'));
      await tester.pumpAndSettle();
      expect(await future, {'EFL203|1'});
    });

    testWidgets('import with nothing ticked stays open', (tester) async {
      final schedule = twoCourses();
      final future = await openDialog(tester, schedule);

      await tester.tap(find.byType(CheckboxListTile).first);
      await tester.pumpAndSettle();
      await tester.tap(find.byType(CheckboxListTile).last);
      await tester.pumpAndSettle();
      // Button offers no import; tapping explains instead of closing.
      await tester.tap(find.text('Import 0 courses'));
      await tester.pumpAndSettle();
      expect(find.text('Select at least one course'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(await future, isNull);
    });
  });
}
