import 'dart:io';

import 'package:chronicle/data/database.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;

/// Guards the pre-v1.10 database rescue: updaters open an empty database
/// at the new support-dir path while their data sits orphaned at the old
/// documents-dir path. The copy must be one-directional (legacy -> target)
/// and must never overwrite real data or throw.
void _seedClasses(File file, int count) {
  final db = sqlite.sqlite3.open(file.path);
  try {
    db.execute('''
      CREATE TABLE classes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        color_value INTEGER NOT NULL,
        uuid TEXT NOT NULL DEFAULT '',
        updated_at INTEGER NOT NULL DEFAULT 0
      )''');
    for (var i = 0; i < count; i++) {
      db.execute(
        "INSERT INTO classes (name, color_value) VALUES ('Class $i', 0)",
      );
    }
  } finally {
    db.close();
  }
}

void main() {
  group('copyLegacyDatabaseFile', () {
    late Directory dir;
    setUp(() async {
      dir = await Directory.systemTemp.createTemp('chronicle-legacy');
    });
    tearDown(() async {
      if (await dir.exists()) await dir.delete(recursive: true);
    });

    test('missing legacy file copies nothing', () async {
      final target = File('${dir.path}/target.sqlite');
      final copied = await copyLegacyDatabaseFile(
        legacy: File('${dir.path}/missing.sqlite'),
        target: target,
      );
      expect(copied, isFalse);
      expect(await target.exists(), isFalse);
    });

    test('copies legacy rows when target is missing', () async {
      final legacy = File('${dir.path}/legacy.sqlite')..createSync();
      _seedClasses(legacy, 2);
      final target = File('${dir.path}/sub/target.sqlite');
      expect(
        await copyLegacyDatabaseFile(legacy: legacy, target: target),
        isTrue,
      );
      final db = sqlite.sqlite3.open(target.path, mode: sqlite.OpenMode.readOnly);
      try {
        expect(
          db.select('SELECT COUNT(*) AS c FROM classes').first['c'],
          2,
        );
      } finally {
        db.close();
      }
    });

    test('never overwrites a target that already has classes', () async {
      final legacy = File('${dir.path}/legacy.sqlite')..createSync();
      _seedClasses(legacy, 3);
      final target = File('${dir.path}/target.sqlite')..createSync();
      _seedClasses(target, 1);
      expect(
        await copyLegacyDatabaseFile(legacy: legacy, target: target),
        isFalse,
      );
      final db = sqlite.sqlite3.open(target.path, mode: sqlite.OpenMode.readOnly);
      try {
        expect(
          db.select('SELECT name FROM classes').map((r) => r['name']),
          ['Class 0'],
        );
      } finally {
        db.close();
      }
    });

    test('replaces an empty target with legacy rows', () async {
      final legacy = File('${dir.path}/legacy.sqlite')..createSync();
      _seedClasses(legacy, 2);
      final target = File('${dir.path}/target.sqlite')..createSync();
      _seedClasses(target, 0);
      expect(
        await copyLegacyDatabaseFile(legacy: legacy, target: target),
        isTrue,
      );
      final db = sqlite.sqlite3.open(target.path, mode: sqlite.OpenMode.readOnly);
      try {
        expect(
          db.select('SELECT COUNT(*) AS c FROM classes').first['c'],
          2,
        );
      } finally {
        db.close();
      }
    });

    test('legacy file without data copies nothing', () async {
      final legacy = File('${dir.path}/legacy.sqlite')..createSync();
      _seedClasses(legacy, 0);
      final target = File('${dir.path}/target.sqlite');
      expect(
        await copyLegacyDatabaseFile(legacy: legacy, target: target),
        isFalse,
      );
      expect(await target.exists(), isFalse);
    });
  });
}
