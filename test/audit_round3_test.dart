import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:chronicle/data/database.dart';
import 'package:chronicle/data/repositories.dart';
import 'package:chronicle/data/schedule_repository.dart';
import 'package:chronicle/data/tables.dart';
import 'package:chronicle/services/bilsis.dart';
import 'package:chronicle/services/class_files.dart';
import 'package:chronicle/services/course_catalog/itu_obs.dart';
import 'package:chronicle/services/data_folder.dart';
import 'package:chronicle/services/folder_sync.dart';
import 'package:chronicle/services/gdrive_auth.dart';
import 'package:chronicle/services/gdrive_storage.dart';
import 'package:chronicle/services/ical.dart';
import 'package:chronicle/services/local_folder_storage.dart';
import 'package:chronicle/services/notifications.dart';
import 'package:chronicle/services/sync_storage.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'gdrive_storage_test.dart' show FakeDriveFile, FakeDriveServer;

class _SimpleFakeAuth implements GoogleDriveAuth {
  @override
  Future<bool> isConfigured() async => true;

  @override
  Future<GoogleDriveAccount?> currentAccount() async =>
      const GoogleDriveAccount(email: 'student@example.com');

  @override
  Future<GoogleDriveAccount?> signIn() async => currentAccount();

  @override
  Future<void> signOut() async {}

  @override
  Future<String?> getAccessToken({bool forceRefresh = false}) async => 'tok-1';
}

class _SlowReadyStorage implements SyncStorage {
  final Completer<void> gate;
  int readCount = 0;

  _SlowReadyStorage(this.gate);

  @override
  String get backendId => 'gdrive';

  @override
  String get locationId => 'gdrive';

  @override
  Future<bool> isReady() async {
    await gate.future;
    return true;
  }

  @override
  Future<bool> exists() async => true;

  @override
  Future<void> ensureReady() async {}

  @override
  Future<String?> readString(String relativePath) async => null;

  @override
  Future<Uint8List?> readBytes(String relativePath) async => null;

  @override
  Future<void> writeString(
    String relativePath,
    String content, {
    Map<String, String>? properties,
  }) async {}

  @override
  Future<void> writeBytes(String relativePath, Uint8List bytes) async {}

  @override
  Future<void> delete(String relativePath) async {}

  @override
  Future<List<SyncFileEntry>> listPrefix(String prefix) async => const [];

  @override
  Future<int?> fileSize(String relativePath) async => null;

  @override
  Future<int?> fastManifestExportedAt() async {
    readCount++;
    return null;
  }

  @override
  Future<bool> hasNewerFiles(int sinceMs) async => false;

  @override
  Stream<String>? watchChanges() => null;
}

void main() {
  group('BUG-001: GoogleDriveStorage.fastManifestExportedAt index integrity', () {
    test(
      'manifest without appProperties does not poison _index with partial map',
      () async {
        final server = FakeDriveServer();
        server.files['m1'] = FakeDriveFile(
          id: 'm1',
          name: 'manifest.json',
          bytes: Uint8List.fromList(
            utf8.encode(
              '{"app":"chronicle-data","formatVersion":1,"exportedAt":424242}',
            ),
          ),
          modifiedTime: DateTime.utc(2026, 5, 1),
          appProperties: {}, // no exportedAt property -> triggers fallback read
        );
        server.files['c1'] = FakeDriveFile(
          id: 'c1',
          name: 'classes.json',
          bytes: Uint8List.fromList(utf8.encode('[{"name":"Math"}]')),
          modifiedTime: DateTime.utc(2026, 5, 1),
        );

        final storage = GoogleDriveStorage(
          auth: _SimpleFakeAuth(),
          httpClient: server.client(),
        );

        // Call fastManifestExportedAt BEFORE ensureReady (real poll order).
        expect(await storage.fastManifestExportedAt(), 424242);

        // Subsequent readString must still see classes.json from full index.
        expect(await storage.readString('classes.json'), '[{"name":"Math"}]');

        // Writing classes.json must update c1 in place, not create a duplicate.
        await storage.writeString('classes.json', '[{"name":"Physics"}]');
        expect(
          server.files.values.where((f) => f.name == 'classes.json').length,
          1,
        );
      },
    );
  });

  group('BUG-002 & BUG-004 & BUG-011: LinuxGoogleDriveAuth security & concurrency', () {
    test('signOut sends revoke token in POST body, not URL query string', () async {
      final tmpDir = await Directory.systemTemp.createTemp('chronicle_revoke_');
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(() async {
        await db.close();
        if (await tmpDir.exists()) await tmpDir.delete(recursive: true);
      });
      final settings = SettingsRepository(db);
      final tokenFile = File('${tmpDir.path}/gdrive_auth.json');
      await tokenFile.writeAsString(
        jsonEncode({
          'accessToken': 'acc-1',
          'refreshToken': 'secret-refresh-token',
          'expiresAtMs': DateTime.now().millisecondsSinceEpoch + 3600000,
          'email': 'u@example.com',
        }),
      );

      http.Request? captured;
      final auth = LinuxGoogleDriveAuth(
        settings,
        storageRoot: tmpDir,
        httpClient: MockClient((req) async {
          if (req.url.path == '/revoke') captured = req;
          return http.Response('', 200);
        }),
      );

      await auth.signOut();
      expect(captured, isNotNull);
      expect(captured!.url.queryParameters.containsKey('token'), isFalse);
      expect(captured!.bodyFields['token'], 'secret-refresh-token');
    });

    test('concurrent getAccessToken refreshes share a single /token POST', () async {
      final tmpDir = await Directory.systemTemp.createTemp('chronicle_sf_');
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(() async {
        await db.close();
        if (await tmpDir.exists()) await tmpDir.delete(recursive: true);
      });
      final settings = SettingsRepository(db);
      await settings.setGdriveCustomClientId('cid');
      await File('${tmpDir.path}/gdrive_auth.json').writeAsString(
        jsonEncode({
          'accessToken': 'old',
          'refreshToken': 'rt',
          'expiresAtMs': 0,
          'email': 'u@example.com',
        }),
      );

      var tokenPosts = 0;
      final auth = LinuxGoogleDriveAuth(
        settings,
        storageRoot: tmpDir,
        httpClient: MockClient((req) async {
          tokenPosts++;
          await Future.delayed(const Duration(milliseconds: 30));
          return http.Response(
            jsonEncode({'access_token': 'fresh-$tokenPosts', 'expires_in': 3600}),
            200,
          );
        }),
      );

      final results = await Future.wait([
        auth.getAccessToken(),
        auth.getAccessToken(),
        auth.getAccessToken(),
      ]);
      expect(tokenPosts, 1);
      expect(results.toSet(), {'fresh-1'});
    });

    test('currentAccount returns null when token file is missing', () async {
      final tmpDir = await Directory.systemTemp.createTemp('chronicle_notok_');
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(() async {
        await db.close();
        if (await tmpDir.exists()) await tmpDir.delete(recursive: true);
      });
      final settings = SettingsRepository(db);
      await settings.setGdriveEmail('stale@example.com');
      final auth = LinuxGoogleDriveAuth(settings, storageRoot: tmpDir);

      expect(await auth.currentAccount(), isNull);
    });
  });

  group('BUG-004: GoogleDriveStorage 404 on PATCH falls back to POST', () {
    test('re-creates file when cached Drive ID was deleted remotely', () async {
      final server = FakeDriveServer();
      final storage = GoogleDriveStorage(
        auth: _SimpleFakeAuth(),
        httpClient: server.client(),
      );
      await storage.ensureReady();
      await storage.writeString('classes.json', '["v1"]');
      // Remotely delete the file behind storage's cached index.
      server.files.clear();

      await storage.writeString('classes.json', '["v2"]');
      expect(server.files.values.length, 1);
      expect(await storage.readString('classes.json'), '["v2"]');
    });
  });

  group('BUG-003: FolderSyncController._busy re-entrancy guard', () {
    test('concurrent importIfNewer calls do not overlap across await enabled()', () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final gate = Completer<void>();
      final storage = _SlowReadyStorage(gate);
      final service = DataFolderService(db, null, null, null, storage);
      final controller = FolderSyncController(service: service);

      final f1 = controller.importIfNewer();
      final f2 = controller.importIfNewer();
      gate.complete();
      await Future.wait([f1, f2]);

      // Second call should have been coalesced/queued, not executed concurrently.
      // Because f2 sets _importQueued while f1 is busy, at most 2 sequential
      // checks run, never 2 overlapping; verify by checking _busy serialization
      // with a second gate test: f2 must return false immediately without
      // awaiting gate!
      final gate2 = Completer<void>();
      final storage2 = _SlowReadyStorage(gate2);
      final controller2 = FolderSyncController(
        service: DataFolderService(db, null, null, null, storage2),
      );
      final first = controller2.importIfNewer();
      // Yield a microtask so first enters `await enabled()`.
      await Future<void>.delayed(Duration.zero);
      var secondFinishedWhileFirstBlocked = false;
      final second = controller2.importIfNewer().then((v) {
        secondFinishedWhileFirstBlocked = true;
        return v;
      });
      await Future<void>.delayed(Duration.zero);
      expect(secondFinishedWhileFirstBlocked, isTrue);
      gate2.complete();
      await Future.wait([first, second]);
    });
  });

  group('BUG-005: Path traversal & dot-filename hardening', () {
    test('LocalFolderStorage rejects .. traversal and absolute paths', () async {
      final tmpDir = await Directory.systemTemp.createTemp('chronicle_local_');
      addTearDown(() async {
        if (await tmpDir.exists()) await tmpDir.delete(recursive: true);
      });
      final storage = LocalFolderStorage(tmpDir);

      expect(() => storage.readString('../escape.json'), throwsArgumentError);
      expect(
        () => storage.writeString('/etc/passwd', 'bad'),
        throwsArgumentError,
      );
      expect(
        () => storage.delete('files/../../escape.bin'),
        throwsArgumentError,
      );
    });

    test('DataFolderService import sanitizes ".." attachment filename', () async {
      final tmpDir = await Directory.systemTemp.createTemp('chronicle_blob_');
      final syncDir = await Directory.systemTemp.createTemp('chronicle_sync_');
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(() async {
        await db.close();
        if (await tmpDir.exists()) await tmpDir.delete(recursive: true);
        if (await syncDir.exists()) await syncDir.delete(recursive: true);
      });

      final service = DataFolderService(db, null, tmpDir);
      final settings = SettingsRepository(db);
      await settings.setDataFolder(syncDir.path);
      await settings.setSyncBackend('folder');

      final clsUuid = '11111111-1111-1111-1111-111111111111';
      final fileUuid = '22222222-2222-2222-2222-222222222222';
      final now = DateTime.now().millisecondsSinceEpoch;
      final storage = LocalFolderStorage(syncDir);
      await storage.writeString('classes.json', jsonEncode([
        {
          'id': 1,
          'name': 'Math',
          'colorValue': 0xFF4F6BED,
          'active': true,
          'uuid': clsUuid,
          'updatedAt': now,
        },
      ]));
      await storage.writeString('class_files.json', jsonEncode([
        {
          'id': 1,
          'classId': 1,
          'fileName': 'foo/..',
          'storedPath': 'class_files/1/..',
          'sizeBytes': 3,
          'createdAt': now,
          'uuid': fileUuid,
          'updatedAt': now,
        },
      ]));
      await storage.writeBytes(
        'files/${DataFolderService.blobNameFor(fileUuid, 'foo/..')}',
        Uint8List.fromList([1, 2, 3]),
      );
      await storage.writeString(
        'manifest.json',
        jsonEncode({
          'app': DataFolderService.appTag,
          'formatVersion': DataFolderService.formatVersion,
          'exportedAt': now,
        }),
      );

      final res = await service.importData();
      expect(res.error, isNull);
      final rows = await db.select(db.classFiles).get();
      expect(rows.length, 1);
      expect(rows.first.storedPath, isNot(endsWith('/..')));
      expect(rows.first.storedPath, isNot(contains('..')));
      final resolved = await ClassFilesService.resolveStoredPath(
        root: tmpDir,
        stored: rows.first.storedPath,
      );
      expect(await File(resolved).exists(), isTrue);
    });
  });

  group('BUG-006: iCal preserves location & description without DTEND', () {
    test('VEVENT without DTEND keeps LOCATION and DESCRIPTION', () {
      const ics = '''
BEGIN:VCALENDAR
VERSION:2.0
BEGIN:VEVENT
SUMMARY:All-day Exam
DTSTART;VALUE=DATE:20261110
LOCATION:Room B4
DESCRIPTION:Bring calculator
END:VEVENT
END:VCALENDAR
''';
      final events = parseIcs(ics);
      expect(events.length, 1);
      expect(events.first.end, isNull);
      expect(events.first.location, 'Room B4');
      expect(events.first.description, 'Bring calculator');
    });
  });

  group('BUG-007: ReminderScheduler respects dayRotation', () {
    test('day-rotation class produces upcoming reminder occurrences', () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final classes = ClassRepository(db);
      final settings = SettingsRepository(db);
      final tasks = TaskRepository(db);
      final schedule = ScheduleRepository(db);

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final todayIso =
          '${today.year.toString().padLeft(4, '0')}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      final yearId = await classes.createYear(
        AcademicYearsCompanion.insert(
          name: '2026',
          startDate: todayIso,
          endDate: '2027-06-30',
          rotationLength: const Value(2),
          rotationSchoolDays: const Value('[1,2,3,4,5,6,7]'),
        ),
      );
      await settings.setActiveYearId(yearId);
      await settings.setDefaultClassReminderMinutes(10);

      final classId = await classes.create(
        ClassesCompanion.insert(
          name: 'Rotated Physics',
          colorValue: 0xFF4F6BED,
          yearId: Value(yearId),
        ),
      );
      final tomorrow = DateTime(today.year, today.month, today.day + 1);
      await classes.createScheduleItem(
        ScheduleItemsCompanion.insert(
          classId: classId,
          dayOfWeek: tomorrow.weekday,
          startMinutes: 600,
          endMinutes: 660,
          rotation: RotationKind.dayRotation,
          rotationDays: const Value('[2]'),
        ),
      );

      final scheduler = ReminderScheduler(tasks, settings, schedule, classes);
      await scheduler.refreshClassReminders();

      final scheduledRaw = await settings.get('scheduled_class_reminders');
      final ids = jsonDecode(scheduledRaw ?? '[]') as List;
      expect(ids, isNotEmpty);
    });
  });

  group('BUG-008: Monthly XtraEvent anchored on day 31 does not drift', () {
    test('Jan 31 expands to Feb 28, Mar 31, Apr 30, May 31', () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final xtra = XtraRepository(db);

      await xtra.create(
        XtraEventsCompanion.insert(
          title: 'Month-end Review',
          date: '2026-01-31',
          repeatKind: const Value(RepeatKind.monthly),
        ),
      );

      final full = await xtra.range('2026-01-01', '2026-05-31');
      expect(
        full.map((e) => e.date),
        ['2026-01-31', '2026-02-28', '2026-03-31', '2026-04-30', '2026-05-31'],
      );

      // Fast-forward query starting in March must still hit Mar 31, not Mar 28.
      final jumped = await xtra.range('2026-03-01', '2026-05-31');
      expect(
        jumped.map((e) => e.date),
        ['2026-03-31', '2026-04-30', '2026-05-31'],
      );
    });
  });

  group('BUG-013: Time bounds & ItuObsCatalog JSON parsing', () {
    test('Bilsis rejects invalid minute values like 10:99-11:00', () {
      final words = [
        const BilsisWord(text: 'Pazartesi', left: 100, right: 160, cy: 700),
        const BilsisWord(text: '10:99-11:00', left: 10, right: 70, cy: 650),
      ];
      expect(
        () => parseBilsisPages([words]),
        throwsA(
          isA<BilsisParseException>().having(
            (e) => e.message,
            'message',
            'no-times',
          ),
        ),
      );
    });

    test('ItuObsCatalog parses branch JSON regardless of key order', () async {
      const utf8Html = {'content-type': 'text/html; charset=utf-8'};
      final client = MockClient((req) async {
        if (req.url.path.contains('DersBilgiSearch')) {
          return http.Response(
            '<table><tr><td>MAT 103E</td><td>Mat / Math</td><td>EN</td>'
            '<td><a href="/public/DersBilgi/DersKatalogBilgiBransDersKodu?x=1">d</a></td>'
            '</tr></table>',
            200,
            headers: utf8Html,
          );
        }
        if (req.url.path.contains('DersKatalogBilgiBransDersKodu')) {
          return http.Response(
            '<table><tr><td><strong>Dersin Adı</strong>: Matematik</td></tr>'
            '<tr><td>MAT 103E</td><td>4</td><td>6,5</td><td>3</td><td>2</td><td>0</td></tr></table>',
            200,
            headers: utf8Html,
          );
        }
        if (req.url.path.contains('SearchBransKoduByProgramSeviye')) {
          // Reversed key order vs original regex!
          return http.Response(
            jsonEncode([
              {'dersBransKodu': 'MAT', 'extra': true, 'bransKoduId': 26},
            ]),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }
        if (req.url.path.contains('DersProgramSearch')) {
          return http.Response(
            '<table><tbody><tr>'
            '<td>12345</td><td>MAT 103E</td><td>Math</td><td>Yüz Yüze</td>'
            '<td>Prof</td><td>MED</td><td>Pazartesi</td><td>08:30/10:29</td>'
            '<td>A101</td><td>50</td><td>40</td><td>0</td><td>0</td><td>-</td>'
            '</tr></tbody></table>',
            200,
            headers: utf8Html,
          );
        }
        return http.Response('', 200);
      });
      final cat = ItuObsCatalog(client: client);
      final res = await cat.lookup('MAT 103E');
      expect(res.sections.length, 1);
      expect(res.sections.first.crn, '12345');
    });
  });
}
