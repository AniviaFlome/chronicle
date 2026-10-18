// NOTE on fidelity: tapping the real `Import schedule` settings tile calls
// FilePicker.pickFiles, which needs a platform channel plus real PDF file
// bytes and cannot be driven inside flutter_test. This journey therefore
// starts at the real settings entry point (catalog source is set in the UI
// and the Import tile is verified present), then feeds mock Bilsis PDF
// words/pages directly into parseBilsisPages (same line()/headers()
// builders as test/bilsis_test.dart), opens the real BilsisPreviewDialog on
// the app navigator exactly like SettingsScreen._importBilsis does, ticks
// 2 courses, confirms, and persists them with the same field mapping
// (name/code, room/teacher null-guards, palette cycling, active year,
// SlotDraft companions) that _importBilsis uses.
import 'e2e_harness.dart';
import 'package:chronicle/data/database.dart';
import 'package:chronicle/data/repositories.dart';
import 'package:chronicle/providers.dart';
import 'package:chronicle/screens/bilsis_import_dialog.dart';
import 'package:chronicle/screens/schedule_slot_dialog.dart';
import 'package:chronicle/services/bilsis.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Builds words for one visual line centered on [cx], with realistic
/// glyph widths so column gaps survive line splitting (copied from
/// test/bilsis_test.dart).
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

List<List<BilsisWord>> headers() => [
  line('Saat', 65, 511),
  line('Pazartesi', 178, 511),
  line('Salı', 317, 511),
  line('Çarşamba', 456, 511),
  line('Perşembe', 595, 511),
  line('Cuma', 733, 511),
];

void main() {
  testWidgets('imported bilsis courses become classes', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    await bootApp(tester, db);

    // Real settings entry point: set the catalog source in the UI.
    await goTab(tester, Icons.settings_outlined);
    final catalogField = find.ancestor(
      of: find.text('Catalog source'),
      matching: find.byType(DropdownButtonFormField<String>),
    );
    for (var i = 0; i < 15 && catalogField.evaluate().isEmpty; i++) {
      await tester.drag(find.byType(ListView).first, const Offset(0, -400));
      await tester.pumpAndSettle();
    }
    await tester.tap(catalogField);
    await tester.pumpAndSettle();
    await tester.tap(find.text('ITU'));
    await tester.pumpAndSettle();
    await pumpForAsync(tester);
    expect(
      await tester.runAsync(() => SettingsRepository(db).catalogSource()),
      'itu',
    );
    // The Bilsis entry point itself is present (dragged back into view:
    // the settings list builds lazily); tapping it would invoke
    // FilePicker.pickFiles (platform file bytes), so the parse step below
    // feeds mock words directly instead.
    for (var i = 0; i < 15 && find.text('Import schedule').evaluate().isEmpty; i++) {
      await tester.drag(find.byType(ListView).first, const Offset(0, 400));
      await tester.pumpAndSettle();
    }
    expect(find.text('Import schedule'), findsOneWidget);

    // Same mock data shape as bilsis_test: Monday GKS104 + Tuesday EFL203
    // in the 08:40 block.
    final words = page([
      ...headers(),
      line('08:40-09:30', 65, 463),
      line('GKS104(3)', monX, 480),
      line('BİLİM VE ARAŞTIRMA ETİĞİ', monX, 468),
      line('C-K2-09[102]', monX, 457),
      line('Doç.Dr. SİNEM DİNÇOL ÖZGÜR', monX, 446),
      line('EFL203(1)', tueX, 480),
      line('İNGİLİZ EDEBİYATI I', tueX, 468),
      line('C-K3-06[52]', tueX, 457),
      line('Doç.Dr. ÖZLEM CANARAN', tueX, 446),
    ]);
    final schedule = parseBilsisPages([words]);
    expect(
      schedule.courses.map((c) => c.code),
      ['EFL203', 'GKS104'],
    );

    // Open the real preview dialog on the app navigator, as
    // SettingsScreen._importBilsis does after parsing.
    final appCtx = tester.element(find.text('Import schedule'));
    final container = ProviderScope.containerOf(appCtx);
    final future = showDialog<Set<String>>(
      context: appCtx,
      builder: (_) => BilsisPreviewDialog(schedule: schedule),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('GKS104 BİLİM VE ARAŞTIRMA ETİĞİ'),
      findsOneWidget,
    );
    expect(find.text('EFL203 İNGİLİZ EDEBİYATI I'), findsOneWidget);
    expect(find.text('Import 2 courses'), findsOneWidget);

    // Exercise selection: untick one, the button counts down, then retick.
    await tester.tap(find.byType(CheckboxListTile).first);
    await tester.pumpAndSettle();
    expect(find.text('Import 1 course'), findsOneWidget);
    await tester.tap(find.byType(CheckboxListTile).first);
    await tester.pumpAndSettle();
    expect(find.text('Import 2 courses'), findsOneWidget);

    await tester.tap(find.text('Import 2 courses'));
    await tester.pumpAndSettle();
    final selected = await future;
    expect(selected, {'EFL203|1', 'GKS104|3'});

    // Persist with the same mapping SettingsScreen._importBilsis uses.
    //
    // Zone split (both halves mirror proven-green paths):
    // - one-shot reads need real async (tester.runAsync); in the test
    //   (FakeAsync) zone they never complete once the app is watching.
    // - the writes run as plain awaits, exactly like the app's own
    //   class-editor _save; under runAsync with the full app watching,
    //   db.transaction never completes.
    final classRepo = ClassRepository(db);
    final settings = SettingsRepository(db);
    final yearId = await tester.runAsync(
      () => settings.watchActiveYearId().first,
    );
    final defaultLimit = await tester.runAsync(
      () => settings.defaultMaxAbsences(),
    );
    final existing = await tester.runAsync(() => classRepo.all()) ?? [];
    var imported = 0;
    for (final course in schedule.courses) {
      if (!selected!.contains('${course.code}|${course.section}')) {
        continue;
      }
      final room = course.room?.trim().isEmpty ?? true ? null : course.room;
      final teacher = course.instructor?.trim().isEmpty ?? true
          ? null
          : course.instructor;
      await classRepo.createClassWithSlots(
        ClassesCompanion.insert(
          name: '${course.code} ${course.title}',
          colorValue:
              classColorPalette[(existing.length + imported) %
                  classColorPalette.length],
          teacher: Value(teacher),
          room: Value(room),
          yearId: Value(yearId),
          maxAbsences: Value(defaultLimit),
        ),
        [
          for (final s in course.slots)
            SlotDraft(
              dayOfWeek: s.day,
              startMinutes: s.startMinutes,
              endMinutes: s.endMinutes,
              room: room,
            ).toCompanion(0),
        ],
      );
      imported++;
    }
    expect(imported, 2);
    container.invalidate(engineProvider);
    container.invalidate(classesByIdProvider);
    await container.read(reminderSchedulerProvider).refreshClassReminders();
    await tester.pumpAndSettle();
    await pumpForAsync(tester);

    // Both imported courses surface as classes ...
    await goTab(tester, Icons.school_outlined);
    expect(
      find.text('GKS104 BİLİM VE ARAŞTIRMA ETİĞİ'),
      findsOneWidget,
    );
    expect(find.text('EFL203 İNGİLİZ EDEBİYATI I'), findsOneWidget);

    // ... and their slots appear on the calendar the same week.
    await goTab(tester, Icons.calendar_month_outlined);
    expect(find.textContaining('GKS104'), findsWidgets);
    expect(find.textContaining('EFL203'), findsWidgets);

    await shutdownApp(tester, db);
  });
}
