import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../data/database.dart';
import '../data/repositories.dart';
import 'class_files.dart';

/// Local data-folder export/import. The app only reads/writes plain JSON
/// files in a user-chosen folder; whatever syncs that folder externally
/// (or nothing at all) is outside the app — no network code, no accounts,
/// no background watchers.
///
/// Layout (one JSON file per table):
/// `manifest.json`, `<table>.json` for each synced table, `tombstones.json`,
/// plus `files/<uuid>[.ext]` content blobs for class/year attachments
/// (referenced by `class_files.json` / `year_files.json`).
/// Export overwrites the files atomically (temp + rename) and prunes
/// unreferenced blobs. Import merges newer rows by `updatedAt` keyed on
/// stable `uuid`s and applies tombstones, then leaves the files alone —
/// export again to publish merged state.
/// Safe workflow is one device at a time: export, let the folder sync
/// elsewhere, import on the other side.
class DataFolderService {
  final AppDatabase db;
  final SettingsRepository settings;

  /// Overrides the app support directory for attachment blobs (hermetic
  /// sync tests).
  final Directory? storageRoot;

  DataFolderService(
    this.db, [
    SettingsRepository? settingsParam,
    this.storageRoot,
  ]) : settings = settingsParam ?? SettingsRepository(db);

  static const formatVersion = 1;
  static const appTag = 'chronicle-data';
  static const manifestFile = 'manifest.json';
  static const tombstonesFile = 'tombstones.json';

  /// Subdirectory holding attachment content blobs, named
  /// `<stem>_<shortid>.<ext>` (human-readable, collision-free).
  static const filesDir = 'files';

  /// Content-blob file name for an attachment: sanitized original stem plus
  /// the first 8 uuid hex chars, so names stay readable and unique, e.g.
  /// `syllabus_a1b2c3d4.pdf`. Lower-cased for case-insensitive filesystems.
  static String blobNameFor(String uuid, String fileName) {
    final dot = fileName.lastIndexOf('.');
    final hasExt = dot > 0 && dot < fileName.length - 1;
    var stem = (hasExt ? fileName.substring(0, dot) : fileName).toLowerCase();
    stem = stem.replaceAll(RegExp('[^a-z0-9_-]'), '_');
    stem = stem.replaceAll(RegExp('_+'), '_');
    stem = stem.replaceAll(RegExp(r'^_+|_+$'), '');
    if (stem.length > 40) stem = stem.substring(0, 40);
    if (stem.isEmpty) stem = 'file';
    var ext = '';
    if (hasExt) {
      ext = fileName.substring(dot + 1).toLowerCase().replaceAll(RegExp('[^a-z0-9]'), '');
      if (ext.length > 10) ext = ext.substring(0, 10);
    }
    final short = uuid.replaceAll('-', '');
    final tag = short.length > 8 ? short.substring(0, 8) : short;
    final base = '${stem}_$tag';
    return ext.isEmpty ? base : '$base.$ext';
  }

  /// Pre-redesign blob name (`<uuid>[.ext]`), checked as a fallback when
  /// importing folders written by older builds.
  static String legacyBlobNameFor(String uuid, String fileName) {
    final dot = fileName.lastIndexOf('.');
    var ext = dot > 0 && dot < fileName.length - 1
        ? fileName.substring(dot + 1).toLowerCase()
        : '';
    ext = ext.replaceAll(RegExp('[^a-z0-9]'), '');
    if (ext.length > 10) ext = ext.substring(0, 10);
    return ext.isEmpty ? uuid : '$uuid.$ext';
  }

  /// Snapshot key → file name. Keys use the same table names everywhere
  /// so exports stay comparable.
  static const tableFiles = <String, String>{
    'academicYears': 'academic_years.json',
    'classes': 'classes.json',
    'scheduleItems': 'schedule_items.json',
    'scheduleExceptions': 'schedule_exceptions.json',
    'holidays': 'holidays.json',
    'absences': 'absences.json',
    'tasks': 'tasks.json',
    'subtasks': 'subtasks.json',
    'taskReminders': 'task_reminders.json',
    'grades': 'grades.json',
    'pomodoroSessions': 'pomodoro_sessions.json',
    'xtraEvents': 'xtra_events.json',
    'classFiles': 'class_files.json',
    'yearFiles': 'year_files.json',
  };

  /// User-chosen data folder. Null when not configured.
  Future<Directory?> dataDir() async {
    final path = await settings.dataFolder();
    if (path == null || path.trim().isEmpty) return null;
    return Directory(path);
  }

  /// Assigns fresh uuids/timestamps to rows missed by normal stamping
  /// (pre-v6 rows without migration, raw test inserts). Idempotent.
  Future<void> ensureSyncIdentity() async {
    final now = DateTime.now().millisecondsSinceEpoch;
    Future<void> fix(
      TableInfo<Table, dynamic> table,
      String sqlTable,
    ) async {
      final pending = await db
          .customSelect(
            "SELECT id, uuid, updated_at FROM $sqlTable "
            "WHERE uuid = '' OR updated_at = 0",
          )
          .get();
      for (final row in pending) {
        final data = row.data;
        final uuid = (data['uuid'] as String).isEmpty
            ? newUuid()
            : data['uuid'];
        final updatedAt = (data['updated_at'] as int) == 0
            ? now
            : data['updated_at'];
        await db.customStatement(
          'UPDATE $sqlTable SET uuid = ?, updated_at = ? WHERE id = ?',
          [uuid, updatedAt, data['id']],
        );
      }
    }

    await fix(db.academicYears, 'academic_years');
    await fix(db.classes, 'classes');
    await fix(db.scheduleItems, 'schedule_items');
    await fix(db.scheduleExceptions, 'schedule_exceptions');
    await fix(db.holidays, 'holidays');
    await fix(db.absences, 'absences');
    await fix(db.tasks, 'tasks');
    await fix(db.subtasks, 'subtasks');
    await fix(db.taskReminders, 'task_reminders');
    await fix(db.grades, 'grades');
    await fix(db.pomodoroSessions, 'pomodoro_sessions');
    await fix(db.xtraEvents, 'xtra_events');
    await fix(db.classFiles, 'class_files');
    await fix(db.yearFiles, 'year_files');
  }

  Future<List<Map<String, dynamic>>> _rows(
    SimpleSelectStatement<TableInfo<Table, dynamic>, DataClass> query,
  ) async {
    final result = await query.get();
    return [
      for (final r in result)
        Map<String, dynamic>.from((r as dynamic).toJson() as Map),
    ];
  }

  /// Writes every table plus tombstones and a manifest into the folder.
  /// Returns counts; never throws for a missing folder (see [dataDir]).
  Future<DataFolderResult> exportData() async {
    final dir = await dataDir();
    if (dir == null) {
      return const DataFolderResult(error: 'no-folder');
    }
    try {
      await ensureSyncIdentity();
      if (!await dir.exists()) await dir.create(recursive: true);
      final tables = <String, List<Map<String, dynamic>>>{
        'academicYears': await _rows(db.select(db.academicYears)),
        'classes': await _rows(db.select(db.classes)),
        'scheduleItems': await _rows(db.select(db.scheduleItems)),
        'scheduleExceptions': await _rows(db.select(db.scheduleExceptions)),
        'holidays': await _rows(db.select(db.holidays)),
        'absences': await _rows(db.select(db.absences)),
        'tasks': await _rows(db.select(db.tasks)),
        'subtasks': await _rows(db.select(db.subtasks)),
        'taskReminders': await _rows(db.select(db.taskReminders)),
        'grades': await _rows(db.select(db.grades)),
        'pomodoroSessions': await _rows(db.select(db.pomodoroSessions)),
        'xtraEvents': await _rows(db.select(db.xtraEvents)),
        'classFiles': await _rows(db.select(db.classFiles)),
        'yearFiles': await _rows(db.select(db.yearFiles)),
      };
      final tombstones = await db.select(db.syncTombstones).get();
      // Exported metadata must not leak absolute device paths: store the
      // path relative to app storage (import ignores it anyway and copies
      // bytes locally). Legacy absolute rows keep working via the resolver.
      // The support dir is only resolved when file rows exist, so plain
      // unit tests without platform bindings still pass.
      String supportPrefix = '';
      if (tables['classFiles']!.isNotEmpty ||
          tables['yearFiles']!.isNotEmpty) {
        try {
          final supportBase =
              storageRoot ?? await getApplicationSupportDirectory();
          supportPrefix = '${supportBase.path}/';
        } catch (_) {
          // No platform bindings: export paths as-is (or basenames).
        }
      }

      String exportStoredPath(String stored) {
        if (supportPrefix.isNotEmpty && stored.startsWith(supportPrefix)) {
          return stored.substring(supportPrefix.length);
        }
        if (stored.startsWith('/')) return stored.split('/').last;
        return stored;
      }

      List<Map<String, dynamic>> relativized(List<Map<String, dynamic>> rows) {
        return [
          for (final r in rows)
            {
              ...r,
              'storedPath': exportStoredPath(r['storedPath'] as String? ?? ''),
            },
        ];
      }

      tables['classFiles'] = relativized(tables['classFiles']!);
      tables['yearFiles'] = relativized(tables['yearFiles']!);
      var files = 0;
      var rows = 0;
      Future<void> writeJson(String name, Object value) async {
        final target = File('${dir.path}/$name');
        final tmp = File('${target.path}.tmp');
        await tmp.writeAsString(jsonEncode(value));
        await tmp.rename(target.path);
        files++;
      }

      for (final entry in tables.entries) {
        await writeJson(tableFiles[entry.key]!, entry.value);
        rows += entry.value.length;
      }
      final referencedBlobs = <String>{};
      referencedBlobs.addAll(
        await _exportBlobs(dir, [
          for (final r in await db.select(db.classFiles).get())
            (uuid: r.uuid, fileName: r.fileName, storedPath: r.storedPath),
        ]),
      );
      referencedBlobs.addAll(
        await _exportBlobs(dir, [
          for (final r in await db.select(db.yearFiles).get())
            (uuid: r.uuid, fileName: r.fileName, storedPath: r.storedPath),
        ]),
      );
      await _pruneBlobs(dir, referencedBlobs);
      await writeJson(tombstonesFile, [
        for (final t in tombstones)
          {
            'tableKey': t.tableKey,
            'uuid': t.uuid,
            'deletedAt': t.deletedAt,
          },
      ]);
      await writeJson(manifestFile, {
        'app': appTag,
        'formatVersion': formatVersion,
        'exportedAt': DateTime.now().millisecondsSinceEpoch,
      });
      await settings.setDataLastExportAt(
        DateTime.now().millisecondsSinceEpoch,
      );
      return DataFolderResult(filesWritten: files, rowsExported: rows);
    } catch (e) {
      debugPrint('Data folder export failed: $e');
      return DataFolderResult(error: '$e');
    }
  }

  /// Copies attachment blobs into `<dir>/files/`, named by stable uuid,
  /// and returns the referenced blob names. Missing local blobs are
  /// skipped (metadata still syncs).
  Future<Set<String>> _exportBlobs(
    Directory dir,
    List<({String uuid, String fileName, String storedPath})> rows,
  ) async {
    final blobsDir = Directory('${dir.path}/$filesDir');
    if (!await blobsDir.exists()) await blobsDir.create(recursive: true);
    final referenced = <String>{};
    for (final r in rows) {
      final src = File(r.storedPath);
      if (!await src.exists()) continue;
      final name = blobNameFor(r.uuid, r.fileName);
      referenced.add(name);
      await src.copy('${blobsDir.path}/$name');
    }
    return referenced;
  }

  /// Deletes blobs in `<dir>/files/` that no attachment references anymore.
  Future<void> _pruneBlobs(Directory dir, Set<String> referenced) async {
    final blobsDir = Directory('${dir.path}/$filesDir');
    if (!await blobsDir.exists()) return;
    await for (final e in blobsDir.list()) {
      if (e is File) {
        final name = e.path.split('/').last;
        if (!referenced.contains(name) && !name.endsWith('.tmp')) {
          try {
            await e.delete();
          } catch (_) {}
        }
      }
    }
  }

  /// Reads shared table files and merges newer rows plus tombstones into
  /// the local database. Missing table files are skipped (that table is
  /// left untouched). A missing manifest is an error, not an empty import.
  Future<DataFolderResult> importData() async {
    final dir = await dataDir();
    if (dir == null) {
      return const DataFolderResult(error: 'no-folder');
    }
    try {
      if (!await dir.exists()) {
        return const DataFolderResult(error: 'folder-missing');
      }
      final manifestHandle = File('${dir.path}/$manifestFile');
      if (!await manifestHandle.exists()) {
        // Folder exists but no export landed here yet.
        return const DataFolderResult(error: 'manifest-missing');
      }
      final Map<String, dynamic>? manifestRaw;
      try {
        final decoded = jsonDecode(await manifestHandle.readAsString());
        manifestRaw = decoded is Map
            ? Map<String, dynamic>.from(decoded)
            : null;
      } catch (e) {
        debugPrint('Data folder: unreadable $manifestFile: $e');
        return const DataFolderResult(error: 'manifest-unreadable');
      }
      if (manifestRaw == null) {
        // File exists but isn't a manifest object (e.g. truncated sync).
        return const DataFolderResult(error: 'manifest-unreadable');
      }
      final manifest = manifestRaw;
      if (manifest['app'] != appTag ||
          manifest['formatVersion'] != formatVersion) {
        return const DataFolderResult(error: 'not-a-data-folder');
      }
      final tables = <String, List<Map<String, dynamic>>>{};
      for (final entry in tableFiles.entries) {
        final list = await _readJsonList(dir, entry.value);
        if (list != null) tables[entry.key] = list;
      }
      final tombs = await _readJsonList(dir, tombstonesFile) ?? const [];
      final merged = await _mergeData(dir, tables, tombs);
      await settings.setDataLastImportAt(
        DateTime.now().millisecondsSinceEpoch,
      );
      return DataFolderResult(
        filesRead: tables.length + 1,
        rowsUpserted: merged.rowsUpserted,
        rowsDeleted: merged.rowsDeleted,
        tombstonesAdopted: merged.tombstonesAdopted,
      );
    } catch (e) {
      debugPrint('Data folder import failed: $e');
      return DataFolderResult(error: '$e');
    }
  }

  /// Reads and validates the folder manifest, or null when missing or
  /// foreign. Used by the auto-sync poll to decide whether an import is
  /// worthwhile without parsing every table file.
  Future<Map<String, dynamic>?> readManifest(Directory dir) async {
    final manifest = await _readJson(dir, manifestFile);
    if (manifest == null ||
        manifest['app'] != appTag ||
        manifest['formatVersion'] != formatVersion) {
      return null;
    }
    return manifest;
  }

  Future<Map<String, dynamic>?> _readJson(Directory dir, String name) async {    final file = File('${dir.path}/$name');
    if (!await file.exists()) return null;
    try {
      final decoded = jsonDecode(await file.readAsString());
      return decoded is Map ? Map<String, dynamic>.from(decoded) : null;
    } catch (e) {
      debugPrint('Data folder: skipping unreadable $name: $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>?> _readJsonList(
    Directory dir,
    String name,
  ) async {
    final file = File('${dir.path}/$name');
    if (!await file.exists()) return null;
    try {
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! List) throw FormatException('Bad table file: $name');
      return [for (final m in decoded) Map<String, dynamic>.from(m as Map)];
    } catch (e) {
      debugPrint('Data folder: skipping unreadable $name: $e');
      return null;
    }
  }

  /// Merges table lists plus tombstones. Returns counts.
  Future<DataFolderResult> _mergeData(
    Directory dir,
    Map<String, List<Map<String, dynamic>>> tables,
    List<Map<String, dynamic>> rawTombs,
  ) async {
    List<Map<String, dynamic>> listOf(String key) => tables[key] ?? const [];

    var upserted = 0;
    var deleted = 0;
    var adopted = 0;

    await db.transaction(() async {
      // 1. Adopt tombstones (union, keep newest), so deletes propagate the
      // next time this device exports.
      final incomingTombs = <({String table, String uuid, int at})>[];
      for (final m in rawTombs) {
        final t = m['tableKey'];
        final u = m['uuid'];
        final d = m['deletedAt'];
        if (t is! String || u is! String || d is! int) continue;
        if (!syncedTableNames.contains(t) || u.isEmpty) continue;
        incomingTombs.add((table: t, uuid: u, at: d));
      }
      final localTombs = {
        for (final t in await db.select(db.syncTombstones).get())
          (t.tableKey, t.uuid): t.deletedAt,
      };
      for (final tomb in incomingTombs) {
        final known = localTombs[(tomb.table, tomb.uuid)] ?? -1;
        if (tomb.at > known) {
          await recordTombstone(db, tomb.table, tomb.uuid, tomb.at);
          localTombs[(tomb.table, tomb.uuid)] = tomb.at;
          adopted++;
        }
      }

      // 2. Delete local rows covered by tombstones:
      // only when the row wasn't modified after the delete.
      for (final entry in localTombs.entries) {
        if (await _deleteIfStale(entry.key.$1, entry.key.$2, entry.value)) {
          deleted++;
        }
      }

      // 3. Upsert rows parents-first, skipping tombstoned or stale rows.
      upserted += await _mergeRows(dir, listOf, localTombs);
    });

    return DataFolderResult(
      rowsUpserted: upserted,
      rowsDeleted: deleted,
      tombstonesAdopted: adopted,
    );
  }

  /// Actual SQL names of the tables carried in the data folder. The
  /// auto-sync watcher ([FolderSyncController]) only listens to these, so
  /// bookkeeping writes (settings export/import markers, menu cache,
  /// tombstone store) never schedule another export on their own.
  static const syncedTableNames = {
    'academic_years',
    'classes',
    'schedule_items',
    'schedule_exceptions',
    'holidays',
    'absences',
    'tasks',
    'subtasks',
    'task_reminders',
    'grades',
    'pomodoro_sessions',
    'xtra_events',
    'class_files',
    'year_files',
  };

  /// Deletes the local row with [uuid] in [tableKey] when its updatedAt is
  /// not newer than [deletedAt]. Returns true when a row was removed.
  /// FK cascades remove children; their own tombstones were adopted above.
  /// Branches are concrete per table so drift's typed columns resolve.
  Future<bool> _deleteIfStale(
    String tableKey,
    String uuid,
    int deletedAt,
  ) async {
    Future<bool> remove(
      Future<dynamic> Function() fetch,
      Future<int> Function(int id) remove,
    ) async {
      final row = await fetch();
      if (row == null) return false;
      if ((row.updatedAt as int) > deletedAt) return false;
      await remove(row.id as int);
      return true;
    }

    switch (tableKey) {
      case 'academic_years':
        return remove(
          () => (db.select(
            db.academicYears,
          )..where((t) => t.uuid.equals(uuid))).getSingleOrNull(),
          (id) => (db.delete(
            db.academicYears,
          )..where((t) => t.id.equals(id))).go(),
        );
      case 'classes':
        return remove(
          () => (db.select(
            db.classes,
          )..where((t) => t.uuid.equals(uuid))).getSingleOrNull(),
          (id) =>
              (db.delete(db.classes)..where((t) => t.id.equals(id))).go(),
        );
      case 'schedule_items':
        return remove(
          () => (db.select(
            db.scheduleItems,
          )..where((t) => t.uuid.equals(uuid))).getSingleOrNull(),
          (id) => (db.delete(
            db.scheduleItems,
          )..where((t) => t.id.equals(id))).go(),
        );
      case 'schedule_exceptions':
        return remove(
          () => (db.select(
            db.scheduleExceptions,
          )..where((t) => t.uuid.equals(uuid))).getSingleOrNull(),
          (id) => (db.delete(
            db.scheduleExceptions,
          )..where((t) => t.id.equals(id))).go(),
        );
      case 'holidays':
        return remove(
          () => (db.select(
            db.holidays,
          )..where((t) => t.uuid.equals(uuid))).getSingleOrNull(),
          (id) =>
              (db.delete(db.holidays)..where((t) => t.id.equals(id))).go(),
        );
      case 'absences':
        return remove(
          () => (db.select(
            db.absences,
          )..where((t) => t.uuid.equals(uuid))).getSingleOrNull(),
          (id) =>
              (db.delete(db.absences)..where((t) => t.id.equals(id))).go(),
        );
      case 'tasks':
        return remove(
          () => (db.select(
            db.tasks,
          )..where((t) => t.uuid.equals(uuid))).getSingleOrNull(),
          (id) => (db.delete(db.tasks)..where((t) => t.id.equals(id))).go(),
        );
      case 'subtasks':
        return remove(
          () => (db.select(
            db.subtasks,
          )..where((t) => t.uuid.equals(uuid))).getSingleOrNull(),
          (id) =>
              (db.delete(db.subtasks)..where((t) => t.id.equals(id))).go(),
        );
      case 'task_reminders':
        return remove(
          () => (db.select(
            db.taskReminders,
          )..where((t) => t.uuid.equals(uuid))).getSingleOrNull(),
          (id) => (db.delete(
            db.taskReminders,
          )..where((t) => t.id.equals(id))).go(),
        );
      case 'grades':
        return remove(
          () => (db.select(
            db.grades,
          )..where((t) => t.uuid.equals(uuid))).getSingleOrNull(),
          (id) =>
              (db.delete(db.grades)..where((t) => t.id.equals(id))).go(),
        );
      case 'pomodoro_sessions':
        return remove(
          () => (db.select(
            db.pomodoroSessions,
          )..where((t) => t.uuid.equals(uuid))).getSingleOrNull(),
          (id) => (db.delete(
            db.pomodoroSessions,
          )..where((t) => t.id.equals(id))).go(),
        );
      case 'xtra_events':
        return remove(
          () => (db.select(
            db.xtraEvents,
          )..where((t) => t.uuid.equals(uuid))).getSingleOrNull(),
          (id) => (db.delete(
            db.xtraEvents,
          )..where((t) => t.id.equals(id))).go(),
        );
      // Attachment rows also drop their blobs from disk.
      case 'class_files':
        return _removeFile(
          () => (db.select(
            db.classFiles,
          )..where((t) => t.uuid.equals(uuid))).getSingleOrNull(),
          (id) => (db.delete(
            db.classFiles,
          )..where((t) => t.id.equals(id))).go(),
          deletedAt,
        );
      case 'year_files':
        return _removeFile(
          () => (db.select(
            db.yearFiles,
          )..where((t) => t.uuid.equals(uuid))).getSingleOrNull(),
          (id) => (db.delete(
            db.yearFiles,
          )..where((t) => t.id.equals(id))).go(),
          deletedAt,
        );
    }
    return false;
  }

  /// [_deleteIfStale] for attachment tables: removes the row plus its blob.
  Future<bool> _removeFile(
    Future<dynamic> Function() fetch,
    Future<int> Function(int id) remove,
    int deletedAt,
  ) async {
    final row = await fetch();
    if (row == null) return false;
    if ((row.updatedAt as int) > deletedAt) return false;
    await remove(row.id as int);
    try {
      final file = File(
        await ClassFilesService.resolveStoredPath(
          root: storageRoot,
          stored: row.storedPath as String,
        ),
      );
      if (await file.exists()) await file.delete();
    } catch (_) {
      // Best-effort: the row is already gone.
    }
    return true;
  }

  /// Upserts every table. FKs are remapped file-id → local-id via uuid maps
  /// built from the imported files (full state) plus local rows.
  /// Attachment bytes come from `<dir>/files/` and are copied into local
  /// app storage; incoming absolute paths are never trusted.
  Future<int> _mergeRows(
    Directory dir,
    List<Map<String, dynamic>> Function(String key) listOf,
    Map<(String, String), int> tombstones,
  ) async {
    var count = 0;

    bool tombstoned(String table, String uuid, int updatedAt) {
      final at = tombstones[(table, uuid)];
      return at != null && at >= updatedAt;
    }

    // Local uuid → (id, updatedAt) per table.
    Future<Map<String, ({int id, int updatedAt})>> localMap(
      Future<List<dynamic>> Function() all,
    ) async {
      final rows = await all();
      return {
        for (final r in rows)
          (r as dynamic).uuid as String: (
            id: (r as dynamic).id as int,
            updatedAt: (r as dynamic).updatedAt as int,
          ),
      };
    }

    final yearMap = await localMap(() => db.select(db.academicYears).get());
    final classMap = await localMap(() => db.select(db.classes).get());
    final itemMap = await localMap(() => db.select(db.scheduleItems).get());
    final taskMap = await localMap(() => db.select(db.tasks).get());

    int? fileLocalId(
      List<Map<String, dynamic>> files,
      Map<String, ({int id, int updatedAt})> local,
      int fileId,
    ) {
      String? uuid;
      for (final m in files) {
        if (m['id'] == fileId) {
          uuid = m['uuid'] as String?;
          break;
        }
      }
      if (uuid == null || uuid.isEmpty) return null;
      return local[uuid]?.id;
    }

    // Years (no FKs).
    for (final m in listOf('academicYears')) {
      final row = AcademicYear.fromJson(m);
      if (row.uuid.isEmpty ||
          tombstoned('academic_years', row.uuid, row.updatedAt)) {
        continue;
      }
      final local = yearMap[row.uuid];
      if (local == null) {
        final id = await db
            .into(db.academicYears)
            .insert(row.toCompanion(true).copyWith(id: const Value.absent()));
        yearMap[row.uuid] = (id: id, updatedAt: row.updatedAt);
        count++;
      } else if (row.updatedAt > local.updatedAt) {
        await db.update(db.academicYears).replace(row.copyWith(id: local.id));
        yearMap[row.uuid] = (id: local.id, updatedAt: row.updatedAt);
        count++;
      }
    }

    final fileYears = listOf('academicYears');
    final fileClasses = listOf('classes');
    final fileTasks = listOf('tasks');

    // Classes (year FK).
    for (final m in fileClasses) {
      final row = ClassesData.fromJson(m);
      if (row.uuid.isEmpty ||
          tombstoned('classes', row.uuid, row.updatedAt)) {
        continue;
      }
      final yearId = row.yearId == null
          ? null
          : fileLocalId(fileYears, yearMap, row.yearId!);
      if (row.yearId != null && yearId == null) continue;
      final local = classMap[row.uuid];
      if (local == null) {
        final id = await db
            .into(db.classes)
            .insert(
              row.toCompanion(true).copyWith(
                id: const Value.absent(),
                yearId: yearId == null ? const Value(null) : Value(yearId),
              ),
            );
        classMap[row.uuid] = (id: id, updatedAt: row.updatedAt);
        count++;
      } else if (row.updatedAt > local.updatedAt) {
        await db
            .update(db.classes)
            .replace(
              row.copyWith(
                id: local.id,
                yearId: yearId == null ? const Value(null) : Value(yearId),
              ),
            );
        classMap[row.uuid] = (id: local.id, updatedAt: row.updatedAt);
        count++;
      }
    }

    // Tasks, pass 1 (no linkedExamId; fixed up below).
    final wonTasks = <String>{};
    for (final m in fileTasks) {
      final row = Task.fromJson(m);
      if (row.uuid.isEmpty || tombstoned('tasks', row.uuid, row.updatedAt)) {
        continue;
      }
      final classId = row.classId == null
          ? null
          : fileLocalId(fileClasses, classMap, row.classId!);
      if (row.classId != null && classId == null) continue;
      final local = taskMap[row.uuid];
      if (local == null) {
        final id = await db
            .into(db.tasks)
            .insert(
              row.toCompanion(true).copyWith(
                id: const Value.absent(),
                classId: classId == null ? const Value(null) : Value(classId),
                linkedExamId: const Value(null),
              ),
            );
        taskMap[row.uuid] = (id: id, updatedAt: row.updatedAt);
        wonTasks.add(row.uuid);
        count++;
      } else if (row.updatedAt > local.updatedAt) {
        await db
            .update(db.tasks)
            .replace(
              row.copyWith(
                id: local.id,
                classId: classId == null
                    ? const Value(null)
                    : Value(classId),
                linkedExamId: const Value(null),
              ),
            );
        taskMap[row.uuid] = (id: local.id, updatedAt: row.updatedAt);
        wonTasks.add(row.uuid);
        count++;
      }
    }
    // Tasks, pass 2 (linkedExamId fixup, only for rows this import won).
    for (final m in fileTasks) {
      final uuid = m['uuid'] as String? ?? '';
      if (!wonTasks.contains(uuid)) continue;
      final linkedFile = m['linkedExamId'];
      if (linkedFile == null) continue;
      final linkedLocal = fileLocalId(
        fileTasks,
        taskMap,
        (linkedFile as num).toInt(),
      );
      if (linkedLocal == null) continue;
      final local = taskMap[uuid]!;
      await (db.update(db.tasks)..where((t) => t.id.equals(local.id))).write(
        TasksCompanion(linkedExamId: Value(linkedLocal)),
      );
    }

    // Schedule items (class FK).
    for (final m in listOf('scheduleItems')) {
      final row = ScheduleItem.fromJson(m);
      if (row.uuid.isEmpty ||
          tombstoned('schedule_items', row.uuid, row.updatedAt)) {
        continue;
      }
      final classId = fileLocalId(fileClasses, classMap, row.classId);
      if (classId == null) continue;
      final local = itemMap[row.uuid];
      if (local == null) {
        final id = await db
            .into(db.scheduleItems)
            .insert(
              row.toCompanion(true).copyWith(
                id: const Value.absent(),
                classId: Value(classId),
              ),
            );
        itemMap[row.uuid] = (id: id, updatedAt: row.updatedAt);
        count++;
      } else if (row.updatedAt > local.updatedAt) {
        await db
            .update(db.scheduleItems)
            .replace(row.copyWith(id: local.id, classId: classId));
        itemMap[row.uuid] = (id: local.id, updatedAt: row.updatedAt);
        count++;
      }
    }

    final fileItems = listOf('scheduleItems');

    // Exceptions (slot FK).
    for (final m in listOf('scheduleExceptions')) {
      final row = ScheduleException.fromJson(m);
      if (row.uuid.isEmpty ||
          tombstoned('schedule_exceptions', row.uuid, row.updatedAt)) {
        continue;
      }
      final slotId = fileLocalId(fileItems, itemMap, row.scheduleItemId);
      if (slotId == null) continue;
      final existing =
          await (db.select(db.scheduleExceptions)..where(
                (t) => t.uuid.equals(row.uuid),
              ))
              .getSingleOrNull();
      if (existing == null) {
        await db
            .into(db.scheduleExceptions)
            .insert(
              row.toCompanion(true).copyWith(
                id: const Value.absent(),
                scheduleItemId: Value(slotId),
              ),
            );
        count++;
      } else if (row.updatedAt > existing.updatedAt) {
        await db
            .update(db.scheduleExceptions)
            .replace(
              row.copyWith(id: existing.id, scheduleItemId: slotId),
            );
        count++;
      }
    }

    // Holidays (no FKs).
    for (final m in listOf('holidays')) {
      final row = Holiday.fromJson(m);
      if (row.uuid.isEmpty ||
          tombstoned('holidays', row.uuid, row.updatedAt)) {
        continue;
      }
      final existing =
          await (db.select(
            db.holidays,
          )..where((t) => t.uuid.equals(row.uuid))).getSingleOrNull();
      if (existing == null) {
        await db
            .into(db.holidays)
            .insert(row.toCompanion(true).copyWith(id: const Value.absent()));
        count++;
      } else if (row.updatedAt > existing.updatedAt) {
        await db.update(db.holidays).replace(row.copyWith(id: existing.id));
        count++;
      }
    }

    // Absences (class FK).
    for (final m in listOf('absences')) {
      final row = Absence.fromJson(m);
      if (row.uuid.isEmpty ||
          tombstoned('absences', row.uuid, row.updatedAt)) {
        continue;
      }
      final classId = fileLocalId(fileClasses, classMap, row.classId);
      if (classId == null) continue;
      final existing =
          await (db.select(
            db.absences,
          )..where((t) => t.uuid.equals(row.uuid))).getSingleOrNull();
      if (existing == null) {
        await db
            .into(db.absences)
            .insert(
              row.toCompanion(true).copyWith(
                id: const Value.absent(),
                classId: Value(classId),
              ),
            );
        count++;
      } else if (row.updatedAt > existing.updatedAt) {
        await db
            .update(db.absences)
            .replace(row.copyWith(id: existing.id, classId: classId));
        count++;
      }
    }

    // Subtasks / reminders / grades (task FKs).
    for (final m in listOf('subtasks')) {
      final row = Subtask.fromJson(m);
      if (row.uuid.isEmpty ||
          tombstoned('subtasks', row.uuid, row.updatedAt)) {
        continue;
      }
      final taskId = fileLocalId(fileTasks, taskMap, row.taskId);
      if (taskId == null) continue;
      final existing =
          await (db.select(
            db.subtasks,
          )..where((t) => t.uuid.equals(row.uuid))).getSingleOrNull();
      if (existing == null) {
        await db
            .into(db.subtasks)
            .insert(
              row.toCompanion(true).copyWith(
                id: const Value.absent(),
                taskId: Value(taskId),
              ),
            );
        count++;
      } else if (row.updatedAt > existing.updatedAt) {
        await db
            .update(db.subtasks)
            .replace(row.copyWith(id: existing.id, taskId: taskId));
        count++;
      }
    }
    for (final m in listOf('taskReminders')) {
      final row = TaskReminder.fromJson(m);
      if (row.uuid.isEmpty ||
          tombstoned('task_reminders', row.uuid, row.updatedAt)) {
        continue;
      }
      final taskId = fileLocalId(fileTasks, taskMap, row.taskId);
      if (taskId == null) continue;
      final existing =
          await (db.select(
            db.taskReminders,
          )..where((t) => t.uuid.equals(row.uuid))).getSingleOrNull();
      if (existing == null) {
        await db
            .into(db.taskReminders)
            .insert(
              row.toCompanion(true).copyWith(
                id: const Value.absent(),
                taskId: Value(taskId),
              ),
            );
        count++;
      } else if (row.updatedAt > existing.updatedAt) {
        await db
            .update(db.taskReminders)
            .replace(row.copyWith(id: existing.id, taskId: taskId));
        count++;
      }
    }
    for (final m in listOf('grades')) {
      final row = Grade.fromJson(m);
      if (row.uuid.isEmpty || tombstoned('grades', row.uuid, row.updatedAt)) {
        continue;
      }
      final examId = fileLocalId(fileTasks, taskMap, row.examTaskId);
      if (examId == null) continue;
      final existing =
          await (db.select(
            db.grades,
          )..where((t) => t.uuid.equals(row.uuid))).getSingleOrNull();
      if (existing == null) {
        await db
            .into(db.grades)
            .insert(
              row.toCompanion(true).copyWith(
                id: const Value.absent(),
                examTaskId: Value(examId),
              ),
            );
        count++;
      } else if (row.updatedAt > existing.updatedAt) {
        await db
            .update(db.grades)
            .replace(row.copyWith(id: existing.id, examTaskId: examId));
        count++;
      }
    }

    // Pomodoro sessions (nullable task FK).
    for (final m in listOf('pomodoroSessions')) {
      final row = PomodoroSession.fromJson(m);
      if (row.uuid.isEmpty ||
          tombstoned('pomodoro_sessions', row.uuid, row.updatedAt)) {
        continue;
      }
      final taskId = row.taskId == null
          ? null
          : fileLocalId(fileTasks, taskMap, row.taskId!);
      if (row.taskId != null && taskId == null) continue;
      final existing =
          await (db.select(
            db.pomodoroSessions,
          )..where((t) => t.uuid.equals(row.uuid))).getSingleOrNull();
      if (existing == null) {
        await db
            .into(db.pomodoroSessions)
            .insert(
              row.toCompanion(true).copyWith(
                id: const Value.absent(),
                taskId: taskId == null ? const Value(null) : Value(taskId),
              ),
            );
        count++;
      } else if (row.updatedAt > existing.updatedAt) {
        await db
            .update(db.pomodoroSessions)
            .replace(
              row.copyWith(
                id: existing.id,
                taskId: taskId == null ? const Value(null) : Value(taskId),
              ),
            );
        count++;
      }
    }

    // Xtra events (no FKs).
    for (final m in listOf('xtraEvents')) {
      final row = XtraEvent.fromJson(m);
      if (row.uuid.isEmpty ||
          tombstoned('xtra_events', row.uuid, row.updatedAt)) {
        continue;
      }
      final existing =
          await (db.select(
            db.xtraEvents,
          )..where((t) => t.uuid.equals(row.uuid))).getSingleOrNull();
      if (existing == null) {
        await db
            .into(db.xtraEvents)
            .insert(row.toCompanion(true).copyWith(id: const Value.absent()));
        count++;
      } else if (row.updatedAt > existing.updatedAt) {
        await db.update(db.xtraEvents).replace(row.copyWith(id: existing.id));
        count++;
      }
    }

    // Class files (class FK remapped by uuid; bytes copied locally).
    count += await _mergeFileRows(
      dir: dir,
      fileMaps: listOf('classFiles'),
      parentFiles: fileClasses,
      parentMap: classMap,
      tombTable: 'class_files',
      isTombstoned: tombstoned,
      fetchExisting: (uuid) => (db.select(
        db.classFiles,
      )..where((t) => t.uuid.equals(uuid))).getSingleOrNull(),
      insert: (row, parentId, storedPath) => db
          .into(db.classFiles)
          .insert(
            row.toCompanion(true).copyWith(
              id: const Value<int>.absent(),
              classId: Value(parentId),
              storedPath: Value(storedPath),
            ),
          ),
      update: (row, existing, parentId, storedPath) => db
          .update(db.classFiles)
          .replace(
            row.copyWith(
              id: existing.id,
              classId: parentId,
              storedPath: storedPath,
            ),
          ),
      parentIdOf: (row) => row.classId as int,
      scope: 'class_files',
    );

    // Year files (year FK remapped by uuid; bytes copied locally).
    count += await _mergeFileRows(
      dir: dir,
      fileMaps: listOf('yearFiles'),
      parentFiles: fileYears,
      parentMap: yearMap,
      tombTable: 'year_files',
      isTombstoned: tombstoned,
      fetchExisting: (uuid) => (db.select(
        db.yearFiles,
      )..where((t) => t.uuid.equals(uuid))).getSingleOrNull(),
      insert: (row, parentId, storedPath) => db
          .into(db.yearFiles)
          .insert(
            row.toCompanion(true).copyWith(
              id: const Value<int>.absent(),
              yearId: Value(parentId),
              storedPath: Value(storedPath),
            ),
          ),
      update: (row, existing, parentId, storedPath) => db
          .update(db.yearFiles)
          .replace(
            row.copyWith(
              id: existing.id,
              yearId: parentId,
              storedPath: storedPath,
            ),
          ),
      parentIdOf: (row) => row.yearId as int,
      scope: 'year_files',
    );

    return count;
  }

  /// Merges one attachment table. Parents are remapped file-id → local-id
  /// via uuid; bytes are copied from the folder's `files/` dir into local
  /// app storage (the incoming absolute path is never trusted). Rows whose
  /// blob is missing from the folder are skipped.
  Future<int> _mergeFileRows({
    required Directory dir,
    required List<Map<String, dynamic>> fileMaps,
    required List<Map<String, dynamic>> parentFiles,
    required Map<String, ({int id, int updatedAt})> parentMap,
    required String tombTable,
    required bool Function(String table, String uuid, int updatedAt)
    isTombstoned,
    required Future<dynamic> Function(String uuid) fetchExisting,
    required Future<void> Function(dynamic row, int parentId, String storedPath)
    insert,
    required Future<void> Function(
      dynamic row,
      dynamic existing,
      int parentId,
      String storedPath,
    )
    update,
    required int Function(dynamic row) parentIdOf,
    required String scope,
  }) async {
    // Local helper mirroring _mergeRows' file-id → local-id remap.
    int? resolveParent(int fileId) {
      String? uuid;
      for (final m in parentFiles) {
        if (m['id'] == fileId) {
          uuid = m['uuid'] as String?;
          break;
        }
      }
      if (uuid == null || uuid.isEmpty) return null;
      return parentMap[uuid]?.id;
    }

    var count = 0;
    for (final m in fileMaps) {
      final dynamic row = _fileRowFromJson(tombTable, m);
      if (row == null) continue;
      final String uuid = row.uuid as String;
      final int updatedAt = row.updatedAt as int;
      if (uuid.isEmpty || isTombstoned(tombTable, uuid, updatedAt)) continue;
      final parentId = resolveParent(parentIdOf(row));
      if (parentId == null) continue;
      final blob = await _findBlob(dir, uuid, row.fileName as String);
      if (blob == null) continue;
      final existing = await fetchExisting(uuid);
      final localPath = await _storeBlob(
        scope,
        parentId,
        row.fileName as String,
        blob,
      );
      if (existing == null) {
        await insert(row, parentId, localPath);
        count++;
      } else if (updatedAt > (existing.updatedAt as int)) {
        final oldPath = existing.storedPath as String;
        await update(row, existing, parentId, localPath);
        if (oldPath != localPath) {
          try {
            final old = File(oldPath);
            if (await old.exists()) await old.delete();
          } catch (_) {}
        }
        count++;
      }
    }
    return count;
  }

  /// Parses one attachment metadata map for [tombTable], or null when the
  /// payload is malformed. Returns the typed drift row as dynamic.
  dynamic _fileRowFromJson(String tombTable, Map<String, dynamic> m) {
    try {
      return switch (tombTable) {
        'class_files' => ClassFile.fromJson(m),
        'year_files' => YearFile.fromJson(m),
        _ => null,
      };
    } catch (_) {
      return null;
    }
  }

  /// Locates an attachment blob: current human-readable name first, then
  /// the legacy `<uuid>[.ext]` name from older exports. Null when absent.
  Future<File?> _findBlob(Directory dir, String uuid, String fileName) async {
    final primary = File(
      '${dir.path}/$filesDir/${blobNameFor(uuid, fileName)}',
    );
    if (await primary.exists()) return primary;
    final legacy = File(
      '${dir.path}/$filesDir/${legacyBlobNameFor(uuid, fileName)}',
    );
    if (await legacy.exists()) return legacy;
    return null;
  }

  /// Copies a folder blob into local app storage
  /// (`<scope>/<parentId>/`), returning the *relative* stored path.
  Future<String> _storeBlob(
    String scope,
    int parentId,
    String fileName,
    File blob,
  ) async {
    final base =
        storageRoot ?? await getApplicationSupportDirectory();
    final dir = Directory('${base.path}/$scope/$parentId');
    if (!await dir.exists()) await dir.create(recursive: true);
    final target = await ClassFilesService.uniqueTarget(dir, fileName);
    await blob.copy(target.path);
    return '$scope/$parentId/${target.path.split('/').last}';
  }
}

/// Outcome of [DataFolderService.exportData] / [DataFolderService.importData].
class DataFolderResult {
  final int filesWritten;
  final int filesRead;
  final int rowsExported;
  final int rowsUpserted;
  final int rowsDeleted;
  final int tombstonesAdopted;
  final String? error;

  const DataFolderResult({
    this.filesWritten = 0,
    this.filesRead = 0,
    this.rowsExported = 0,
    this.rowsUpserted = 0,
    this.rowsDeleted = 0,
    this.tombstonesAdopted = 0,
    this.error,
  });
}
