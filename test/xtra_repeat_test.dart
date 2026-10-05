import 'package:chronicle/data/database.dart';
import 'package:chronicle/data/repositories.dart';
import 'package:chronicle/data/tables.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// Read-time expansion of repeating Xtra events.
void main() {
  late AppDatabase db;
  late XtraRepository xtra;

  setUp(() {
    db = AppDatabase(
      NativeDatabase.memory(
        setup: (db) {
          db.execute('PRAGMA foreign_keys = ON');
        },
      ),
    );
    xtra = XtraRepository(db);
  });

  tearDown(() async => db.close());

  Future<int> addEvent(
    String title,
    String date, {
    RepeatKind? repeat,
    String? until,
  }) {
    return xtra.create(
      XtraEventsCompanion.insert(
        title: title,
        date: date,
        repeatKind: Value(repeat),
        repeatUntil: Value(until),
      ),
    );
  }

  test('one-off events pass through only in range', () async {
    await addEvent('Party', '2026-10-07');
    final inRange = await xtra.range('2026-10-05', '2026-10-11');
    expect(inRange.map((e) => e.date), ['2026-10-07']);
    final outOfRange = await xtra.range('2026-10-08', '2026-10-11');
    expect(outOfRange, isEmpty);
  });

  test('daily repeat expands across the range', () async {
    await addEvent('Gym', '2026-10-01', repeat: RepeatKind.daily);
    final rows = await xtra.range('2026-10-05', '2026-10-07');
    expect(
      rows.map((e) => e.date),
      ['2026-10-05', '2026-10-06', '2026-10-07'],
    );
    expect(rows.map((e) => e.title).toSet(), {'Gym'});
  });

  test('weekly repeat hits the same weekday only', () async {
    // 2026-10-05 is a Monday.
    await addEvent('Club', '2026-10-05', repeat: RepeatKind.weekly);
    final rows = await xtra.range('2026-10-05', '2026-10-19');
    expect(
      rows.map((e) => e.date),
      ['2026-10-05', '2026-10-12', '2026-10-19'],
    );
  });

  test('repeatUntil stops the series', () async {
    await addEvent(
      'Course',
      '2026-10-05',
      repeat: RepeatKind.daily,
      until: '2026-10-06',
    );
    final rows = await xtra.range('2026-10-05', '2026-10-12');
    expect(
      rows.map((e) => e.date),
      ['2026-10-05', '2026-10-06'],
    );
  });

  test('monthly repeat steps by calendar month', () async {
    await addEvent('Payday', '2026-10-15', repeat: RepeatKind.monthly);
    final rows = await xtra.range('2026-10-01', '2027-01-31');
    expect(
      rows.map((e) => e.date),
      ['2026-10-15', '2026-11-15', '2026-12-15', '2027-01-15'],
    );
  });

  test('expanded copies share the series id', () async {
    final id = await addEvent('Gym', '2026-10-01', repeat: RepeatKind.daily);
    final rows = await xtra.range('2026-10-05', '2026-10-06');
    expect(rows.map((e) => e.id), [id, id]);
  });

  test('watchRange emits expansions', () async {
    await addEvent('Gym', '2026-10-01', repeat: RepeatKind.daily);
    final rows = await xtra.watchRange('2026-10-05', '2026-10-06').first;
    expect(
      rows.map((e) => e.date),
      ['2026-10-05', '2026-10-06'],
    );
  });
}
