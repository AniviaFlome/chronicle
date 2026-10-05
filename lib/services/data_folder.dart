import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../data/database.dart';
import '../data/repositories.dart';
import 'class_files.dart';

/// Local data-folder export/import as plain JSON in a user-chosen folder.
/// No network code: external sync is outside the app. One device at a time:
/// export, let the folder sync elsewhere, import on the other side.
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

  /// Portable app settings snapshot (opt-in via `sync_settings`).
  /// File-level last-writer-wins: the settings table has no per-row
  /// updatedAt, so keys merge as one snapshot gated by the manifest.
  static const settingsFile = 'settings.json';

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

    // Legacy rows are independent per table, so fix them concurrently.
    await Future.wait([
      fix(db.academicYears, 'academic_years'),
      fix(db.classes, 'classes'),
      fix(db.scheduleItems, 'schedule_items'),
      fix(db.scheduleExceptions, 'schedule_exceptions'),
      fix(db.holidays, 'holidays'),
      fix(db.absences, 'absences'),
      fix(db.tasks, 'tasks'),
      fix(db.subtasks, 'subtasks'),
      fix(db.taskReminders, 'task_reminders'),
      fix(db.grades, 'grades'),
      fix(db.pomodoroSessions, 'pomodoro_sessions'),
      fix(db.xtraEvents, 'xtra_events'),
      fix(db.classFiles, 'class_files'),
      fix(db.yearFiles, 'year_files'),
    ]);
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
  ///
  /// When [pruneBlobs] is false (auto-sync path) unreferenced blobs are
  /// left alone: pruning without a prior merge would delete a peer's
  /// just-uploaded attachment that this device hasn't imported yet.
  /// Manual Export prunes to reclaim space.
  Future<DataFolderResult> exportData({bool pruneBlobs = true}) async {
    final dir = await dataDir();
    if (dir == null) {
      return const DataFolderResult(error: 'no-folder');
    }
    try {
      await ensureSyncIdentity();
      if (!await dir.exists()) await dir.create(recursive: true);
      // One batch: all table scans plus tombstones run concurrently
      // instead of 15 sequential round-trips (drift serializes them safely).
      final scansFuture = Future.wait([
        _rows(db.select(db.academicYears)),
        _rows(db.select(db.classes)),
        _rows(db.select(db.scheduleItems)),
        _rows(db.select(db.scheduleExceptions)),
        _rows(db.select(db.holidays)),
        _rows(db.select(db.absences)),
        _rows(db.select(db.tasks)),
        _rows(db.select(db.subtasks)),
        _rows(db.select(db.taskReminders)),
        _rows(db.select(db.grades)),
        _rows(db.select(db.pomodoroSessions)),
        _rows(db.select(db.xtraEvents)),
        _rows(db.select(db.classFiles)),
        _rows(db.select(db.yearFiles)),
      ]);
      final tombstonesFuture = db.select(db.syncTombstones).get();
      final scans = await scansFuture;
      final tombstones = await tombstonesFuture;
      final tables = <String, List<Map<String, dynamic>>>{
        'academicYears': scans[0],
        'classes': scans[1],
        'scheduleItems': scans[2],
        'scheduleExceptions': scans[3],
        'holidays': scans[4],
        'absences': scans[5],
        'tasks': scans[6],
        'subtasks': scans[7],
        'taskReminders': scans[8],
        'grades': scans[9],
        'pomodoroSessions': scans[10],
        'xtraEvents': scans[11],
        'classFiles': scans[12],
        'yearFiles': scans[13],
      };
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

      // Capture blob sources before relativization rewrites storedPath:
      // the exporter needs local absolute paths to copy bytes from.
      final classBlobRows = _blobRefs(tables['classFiles']!);
      final yearBlobRows = _blobRefs(tables['yearFiles']!);
      tables['classFiles'] = relativized(tables['classFiles']!);
      tables['yearFiles'] = relativized(tables['yearFiles']!);
      var files = 0;
      var rows = 0;
      for (final entry in tables.entries) {
        rows += entry.value.length;
      }
      Future<void> writeJson(String name, Object value) async {
        final target = File('${dir.path}/$name');
        final tmp = File('${target.path}.tmp');
        await tmp.writeAsString(jsonEncode(value));
        await tmp.rename(target.path);
        files++;
      }

      // Table files write concurrently (blob sources were captured above,
      // before path relativization, instead of re-selecting file tables).
      await Future.wait([
        for (final entry in tables.entries)
          writeJson(tableFiles[entry.key]!, entry.value),
      ]);
      final referencedBlobs = <String>{};
      for (final exported in await Future.wait([
        _exportBlobs(dir, classBlobRows),
        _exportBlobs(dir, yearBlobRows),
      ])) {
        referencedBlobs.addAll(exported);
      }
      if (pruneBlobs) {
        await _pruneBlobs(dir, referencedBlobs);
      }
      await writeJson(tombstonesFile, [
        for (final t in tombstones)
          {
            'tableKey': t.tableKey,
            'uuid': t.uuid,
            'deletedAt': t.deletedAt,
          },
      ]);
      // Opt-in settings snapshot: portable keys only, skipped entirely
      // when the toggle is off (a stale file from an earlier opt-in is
      // left for peers that still have it on).
      if (await settings.syncSettings()) {
        final snap = <String, String>{};
        for (final key in syncedSettingKeys) {
          final value = await settings.get(key);
          if (value != null) snap[key] = value;
        }
        await writeJson(settingsFile, {'settings': snap});
      }
      final exportedAt = DateTime.now().millisecondsSinceEpoch;
      await writeJson(manifestFile, {
        'app': appTag,
        'formatVersion': formatVersion,
        'exportedAt': exportedAt,
      });
      await settings.setDataLastExportAt(
        DateTime.now().millisecondsSinceEpoch,
      );
      // Mark our own manifest seen so auto-import never re-imports it.
      await settings.setDataLastSeenExportedAt(exportedAt);
      await settings.setDataSyncError(null);
      return DataFolderResult(filesWritten: files, rowsExported: rows);
    } catch (e) {
      debugPrint('Data folder export failed: $e');
      final result = DataFolderResult(error: '$e');
      try {
        await settings.setDataSyncError('$e');
      } catch (_) {}
      return result;
    }
  }

  /// Blob references from already-scanned file-table rows (local absolute
  /// paths; call before path relativization for export).
  List<({String uuid, String fileName, String storedPath})> _blobRefs(
    List<Map<String, dynamic>> rows,
  ) => [
    for (final r in rows)
      (
        uuid: r['uuid'] as String? ?? '',
        fileName: r['fileName'] as String? ?? '',
        storedPath: r['storedPath'] as String? ?? '',
      ),
  ];

  /// Copies attachment blobs into `<dir>/files/`, named by stable uuid,
  /// and returns the referenced blob names. Missing local blobs are
  /// skipped (metadata still syncs). A blob whose target already has the
  /// same size is left alone: attachment bytes are immutable per uuid
  /// (edits create a new row), so this skips recopying every export.
  Future<Set<String>> _exportBlobs(
    Directory dir,
    List<({String uuid, String fileName, String storedPath})> rows,
  ) async {
    final blobsDir = Directory('${dir.path}/$filesDir');
    if (!await blobsDir.exists()) await blobsDir.create(recursive: true);
    final referenced = <String>{};
    for (final r in rows) {
      if (r.uuid.isEmpty) continue;
      final src = File(r.storedPath);
      if (!await src.exists()) continue;
      final name = blobNameFor(r.uuid, r.fileName);
      referenced.add(name);
      final target = File('${blobsDir.path}/$name');
      if (await target.exists()) {
        final sizes = await Future.wait([src.length(), target.length()]);
        if (sizes[0] == sizes[1]) continue;
      }
      await src.copy(target.path);
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
        return DataFolderResult(error: 'manifest-unreadable: $e');
      }
      if (manifestRaw == null) {
        // File exists but isn't a manifest object (e.g. truncated sync).
        return const DataFolderResult(
          error: 'manifest-unreadable: not-a-json-object',
        );
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
      final lastImportBefore = await settings.dataLastImportAt() ?? 0;
      final merged = await _mergeData(dir, tables, tombs, lastImportBefore);
      // Opt-in settings snapshot: applied only when this device also
      // opted in. Unknown keys and non-string values are ignored so
      // newer peers can't smuggle bookkeeping keys in.
      if (await settings.syncSettings()) {
        final snap = await _readJson(dir, settingsFile);
        final incoming = snap?['settings'];
        if (incoming is Map) {
          for (final entry in incoming.entries) {
            final key = entry.key;
            final value = entry.value;
            if (key is String &&
                value is String &&
                syncedSettingKeys.contains(key)) {
              await settings.set(key, value);
            }
          }
        }
      }
      await settings.setDataLastImportAt(
        DateTime.now().millisecondsSinceEpoch,
      );
      final seenAt = manifest['exportedAt'];
      if (seenAt is int) {
        await settings.setDataLastSeenExportedAt(seenAt);
      }
      await settings.setDataLastConflicts(merged.conflictsPreserved);
      await settings.setDataSyncError(null);
      return DataFolderResult(
        filesRead: tables.length + 1,
        rowsUpserted: merged.rowsUpserted,
        rowsDeleted: merged.rowsDeleted,
        tombstonesAdopted: merged.tombstonesAdopted,
        conflictsPreserved: merged.conflictsPreserved,
        rowsSkipped: merged.rowsSkipped,
      );
    } catch (e) {
      debugPrint('Data folder import failed: $e');
      final result = DataFolderResult(error: '$e');
      try {
        await settings.setDataSyncError('$e');
      } catch (_) {}
      return result;
    }
  }

  /// Subdirectory holding preserved conflict snapshots
  /// (`conflict_<table>_<uuid>_<at>.json` with `{local, incoming}`).
  static const conflictsDir = 'conflicts';

  /// True when any synced file (manifest, tables, tombstones, blobs) was
  /// modified after [sinceMs]. Compares local filesystem mtimes, so peer
  /// wall-clock skew can't hide late-arriving Syncthing files.
  Future<bool> folderHasNewerFiles(Directory dir, int sinceMs) async {
    Future<bool> newer(String path) async {
      try {
        final stat = await FileStat.stat(path);
        if (stat.type == FileSystemEntityType.notFound) return false;
        return stat.modified.millisecondsSinceEpoch > sinceMs;
      } catch (_) {
        return false;
      }
    }

    if (await newer('${dir.path}/$manifestFile')) return true;
    for (final name in tableFiles.values) {
      if (await newer('${dir.path}/$name')) return true;
    }
    if (await newer('${dir.path}/$tombstonesFile')) return true;
    if (await newer('${dir.path}/$settingsFile')) return true;
    final blobsDir = Directory('${dir.path}/$filesDir');
    try {
      if (await blobsDir.exists()) {
        await for (final e in blobsDir.list()) {
          if (e is File) {
            try {
              final stat = await e.stat();
              if (stat.modified.millisecondsSinceEpoch > sinceMs) return true;
            } catch (_) {}
          }
        }
      }
    } catch (_) {}
    return false;
  }

  /// Preserves the losing local row when both sides edited the same uuid
  /// since the last import. Writes both versions to `conflicts/` so no
  /// side is silently lost (Obsidian-style conflict files). Returns 1 when
  /// a file was written, else 0. Never throws.
  Future<int> _preserveConflict(
    Directory dir,
    String table,
    String uuid,
    Map<String, dynamic> local,
    Map<String, dynamic> incoming,
  ) async {
    try {
      final out = Directory('${dir.path}/$conflictsDir');
      if (!await out.exists()) await out.create(recursive: true);
      final at = DateTime.now().millisecondsSinceEpoch;
      final safeUuid = uuid.replaceAll(RegExp('[^a-zA-Z0-9-]'), '_');
      final file = File('${out.path}/conflict_${table}_${safeUuid}_$at.json');
      await file.writeAsString(
        jsonEncode({'table': table, 'uuid': uuid, 'local': local, 'incoming': incoming}),
      );
      // Bound growth: conflicts are rare, but drop files older than 30 days
      // so the folder can't accumulate them forever.
      try {
        final cutoff = DateTime.now().subtract(const Duration(days: 30));
        await for (final e in out.list()) {
          if (e is File && e.path.endsWith('.json')) {
            try {
              if ((await e.stat()).modified.isBefore(cutoff)) {
                await e.delete();
              }
            } catch (_) {}
          }
        }
      } catch (_) {}
      return 1;
    } catch (_) {
      return 0;
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
    int lastImportBefore,
  ) async {
    List<Map<String, dynamic>> listOf(String key) => tables[key] ?? const [];

    var upserted = 0;
    var deleted = 0;
    var adopted = 0;
    var conflicts = 0;
    var skipped = 0;

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
      final freshTombs = <(String, String, int)>[];
      for (final tomb in incomingTombs) {
        final known = localTombs[(tomb.table, tomb.uuid)] ?? -1;
        if (tomb.at > known) {
          await recordTombstone(db, tomb.table, tomb.uuid, tomb.at);
          localTombs[(tomb.table, tomb.uuid)] = tomb.at;
          freshTombs.add((tomb.table, tomb.uuid, tomb.at));
          adopted++;
        }
      }

      // 2. Delete local rows covered by newly-adopted tombstones:
      // only when the row wasn't modified after the delete. Tombstones
      // adopted by an earlier import already swept their rows then; rows
      // kept for being newer can only be removed by a newer tombstone,
      // which arrives as fresh again. This keeps steady-state imports
      // (no new deletes) at zero sweep selects.
      for (final tomb in freshTombs) {
        if (await _deleteIfStale(tomb.$1, tomb.$2, tomb.$3)) {
          deleted++;
        }
      }

      // 3. Upsert rows parents-first, skipping tombstoned or stale rows.
      final merged = await _mergeRows(dir, listOf, localTombs, lastImportBefore);
      upserted += merged.count;
      conflicts += merged.conflicts;
      skipped += merged.skipped;
    });

    return DataFolderResult(
      rowsUpserted: upserted,
      rowsDeleted: deleted,
      tombstonesAdopted: adopted,
      conflictsPreserved: conflicts,
      rowsSkipped: skipped,
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

  /// Settings keys allowed into [settingsFile]. Portable appearance,
  /// calendar, scheduling-default, focus and menu/catalog-source keys
  /// only. Never here: the data folder path, sync bookkeeping markers
  /// (`data_last_*`, `data_sync_error`), the sync toggles themselves
  /// (`auto_sync`, `sync_settings`), device-specific locks
  /// (`portrait_lock`), the active year, and legacy hour keys (minutes
  /// keys are canonical).
  static const syncedSettingKeys = {
    SettingsRepository.appThemeKey,
    SettingsRepository.accentColorKey,
    SettingsRepository.localeOverrideKey,
    SettingsRepository.calendarViewKey,
    SettingsRepository.calendarOrientationKey,
    SettingsRepository.calendarStartTodayKey,
    SettingsRepository.dayStartMinutesKey,
    SettingsRepository.dayEndMinutesKey,
    SettingsRepository.gridMarkersModeKey,
    SettingsRepository.gridFixedLessonKey,
    SettingsRepository.gridFixedBreakKey,
    SettingsRepository.defaultMaxAbsencesKey,
    SettingsRepository.defaultStartMinutesKey,
    SettingsRepository.defaultDurationMinutesKey,
    SettingsRepository.defaultClassReminderKey,
    SettingsRepository.autoEndTimeKey,
    SettingsRepository.slotTimePresetsKey,
    SettingsRepository.focusWorkMinutesKey,
    SettingsRepository.focusBreakMinutesKey,
    SettingsRepository.menuProviderKey,
    SettingsRepository.menuLocationKey,
    SettingsRepository.catalogSourceKey,
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
  Future<({int count, int conflicts, int skipped})> _mergeRows(
    Directory dir,
    List<Map<String, dynamic>> Function(String key) listOf,
    Map<(String, String), int> tombstones,
    int lastImportBefore,
  ) async {
    var count = 0;
    var conflicts = 0;
    var skipped = 0;

    /// Parses one row leniently: a single unparsable map (newer-version
    /// field, corrupt entry) is skipped and counted instead of aborting
    /// the whole import transaction.
    T? parseRow<T>(Map<String, dynamic> m, T Function(Map<String, dynamic>) parse) {
      try {
        return parse(m);
      } catch (e) {
        debugPrint('Sync: skipping unparsable row: $e');
        skipped++;
        return null;
      }
    }

    bool tombstoned(String table, String uuid, int updatedAt) {
      final at = tombstones[(table, uuid)];
      return at != null && at >= updatedAt;
    }

    /// Preserves the local version when both sides edited the same row
    /// since the last import. [localUpdatedAt] is the stored stamp,
    /// [loadLocal] returns its full JSON only on suspected conflict.
    Future<void> maybeConflict(
      String table,
      String uuid,
      int localUpdatedAt,
      Map<String, dynamic> incoming,
      Future<Map<String, dynamic>?> Function() loadLocal,
    ) async {
      if (localUpdatedAt <= lastImportBefore) return;
      final local = await loadLocal();
      if (local == null) return;
      conflicts += await _preserveConflict(dir, table, uuid, local, incoming);
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
    // Prefetched once so per-row merges below are map lookups instead
    // of one SELECT per incoming row (steady-state imports are
    // overwhelmingly already-known rows).
    final exceptionMap =
        await localMap(() => db.select(db.scheduleExceptions).get());
    final holidayMap = await localMap(() => db.select(db.holidays).get());
    final absenceMap = await localMap(() => db.select(db.absences).get());
    final subtaskMap = await localMap(() => db.select(db.subtasks).get());
    final reminderMap =
        await localMap(() => db.select(db.taskReminders).get());
    final gradeMap = await localMap(() => db.select(db.grades).get());
    final pomodoroMap =
        await localMap(() => db.select(db.pomodoroSessions).get());
    final xtraMap = await localMap(() => db.select(db.xtraEvents).get());

    final fileYears = listOf('academicYears');
    final fileClasses = listOf('classes');
    final fileTasks = listOf('tasks');
    final fileItems = listOf('scheduleItems');

    /// File row-id → uuid, built once per table so FK remaps below are
    /// O(1) lookups instead of O(F) scans per incoming row.
    Map<int, String> fileIdUuids(List<Map<String, dynamic>> files) => {
          for (final m in files)
            if (m['id'] is int && m['uuid'] is String)
              (m['id'] as int): (m['uuid'] as String),
        };
    final yearUuids = fileIdUuids(fileYears);
    final classUuids = fileIdUuids(fileClasses);
    final taskUuids = fileIdUuids(fileTasks);
    final itemUuids = fileIdUuids(fileItems);

    int? remapFileId(
      Map<int, String> uuids,
      Map<String, ({int id, int updatedAt})> local,
      int fileId,
    ) {
      final uuid = uuids[fileId];
      if (uuid == null || uuid.isEmpty) return null;
      return local[uuid]?.id;
    }

    // Years (no FKs).
    for (final m in listOf('academicYears')) {
      final row = parseRow(m, AcademicYear.fromJson);
      if (row == null) continue;
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
        await maybeConflict('academic_years', row.uuid, local.updatedAt, m, () async {
          final existing = await (db.select(db.academicYears)
                ..where((t) => t.uuid.equals(row.uuid)))
              .getSingleOrNull();
          return existing == null
              ? null
              : Map<String, dynamic>.from(existing.toJson());
        });
        await db.update(db.academicYears).replace(row.copyWith(id: local.id));
        yearMap[row.uuid] = (id: local.id, updatedAt: row.updatedAt);
        count++;
      }
    }

    // Classes (year FK).
    for (final m in fileClasses) {
      final row = parseRow(m, ClassesData.fromJson);
      if (row == null) continue;
      if (row.uuid.isEmpty ||
          tombstoned('classes', row.uuid, row.updatedAt)) {
        continue;
      }
      final yearId = row.yearId == null
          ? null
          : remapFileId(yearUuids, yearMap, row.yearId!);
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
        await maybeConflict('classes', row.uuid, local.updatedAt, m, () async {
          final existing = await (db.select(db.classes)
                ..where((t) => t.uuid.equals(row.uuid)))
              .getSingleOrNull();
          return existing == null
              ? null
              : Map<String, dynamic>.from(existing.toJson());
        });
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
      final row = parseRow(m, Task.fromJson);
      if (row == null) continue;
      if (row.uuid.isEmpty || tombstoned('tasks', row.uuid, row.updatedAt)) {
        continue;
      }
      final classId = row.classId == null
          ? null
          : remapFileId(classUuids, classMap, row.classId!);
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
        await maybeConflict('tasks', row.uuid, local.updatedAt, m, () async {
          final existing = await (db.select(db.tasks)
                ..where((t) => t.uuid.equals(row.uuid)))
              .getSingleOrNull();
          return existing == null
              ? null
              : Map<String, dynamic>.from(existing.toJson());
        });
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
      final linkedLocal = remapFileId(
        taskUuids,
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
      final row = parseRow(m, ScheduleItem.fromJson);
      if (row == null) continue;
      if (row.uuid.isEmpty ||
          tombstoned('schedule_items', row.uuid, row.updatedAt)) {
        continue;
      }
      final classId = remapFileId(classUuids, classMap, row.classId);
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
        await maybeConflict(
          'schedule_items',
          row.uuid,
          local.updatedAt,
          m,
          () async {
            final existing = await (db.select(db.scheduleItems)
                  ..where((t) => t.uuid.equals(row.uuid)))
                .getSingleOrNull();
            return existing == null
                ? null
                : Map<String, dynamic>.from(existing.toJson());
          },
        );
        await db
            .update(db.scheduleItems)
            .replace(row.copyWith(id: local.id, classId: classId));
        itemMap[row.uuid] = (id: local.id, updatedAt: row.updatedAt);
        count++;
      }
    }

    // Exceptions (slot FK).
    for (final m in listOf('scheduleExceptions')) {
      final row = parseRow(m, ScheduleException.fromJson);
      if (row == null) continue;
      if (row.uuid.isEmpty ||
          tombstoned('schedule_exceptions', row.uuid, row.updatedAt)) {
        continue;
      }
      final slotId = remapFileId(itemUuids, itemMap, row.scheduleItemId);
      if (slotId == null) continue;
      final local = exceptionMap[row.uuid];
      if (local == null) {
        final id = await db
            .into(db.scheduleExceptions)
            .insert(
              row.toCompanion(true).copyWith(
                id: const Value.absent(),
                scheduleItemId: Value(slotId),
              ),
            );
        exceptionMap[row.uuid] = (id: id, updatedAt: row.updatedAt);
        count++;
      } else if (row.updatedAt > local.updatedAt) {
        await maybeConflict(
          'schedule_exceptions',
          row.uuid,
          local.updatedAt,
          m,
          () async {
            final existing = await (db.select(db.scheduleExceptions)
                  ..where((t) => t.uuid.equals(row.uuid)))
                .getSingleOrNull();
            return existing == null
                ? null
                : Map<String, dynamic>.from(existing.toJson());
          },
        );
        await db
            .update(db.scheduleExceptions)
            .replace(
              row.copyWith(id: local.id, scheduleItemId: slotId),
            );
        exceptionMap[row.uuid] = (id: local.id, updatedAt: row.updatedAt);
        count++;
      }
    }

    // Holidays (no FKs).
    for (final m in listOf('holidays')) {
      final row = parseRow(m, Holiday.fromJson);
      if (row == null) continue;
      if (row.uuid.isEmpty ||
          tombstoned('holidays', row.uuid, row.updatedAt)) {
        continue;
      }
      final local = holidayMap[row.uuid];
      if (local == null) {
        final id = await db
            .into(db.holidays)
            .insert(row.toCompanion(true).copyWith(id: const Value.absent()));
        holidayMap[row.uuid] = (id: id, updatedAt: row.updatedAt);
        count++;
      } else if (row.updatedAt > local.updatedAt) {
        await maybeConflict('holidays', row.uuid, local.updatedAt, m,
            () async {
          final existing = await (db.select(
            db.holidays,
          )..where((t) => t.uuid.equals(row.uuid))).getSingleOrNull();
          return existing == null
              ? null
              : Map<String, dynamic>.from(existing.toJson());
        });
        await db.update(db.holidays).replace(row.copyWith(id: local.id));
        holidayMap[row.uuid] = (id: local.id, updatedAt: row.updatedAt);
        count++;
      }
    }

    // Absences (class FK).
    for (final m in listOf('absences')) {
      final row = parseRow(m, Absence.fromJson);
      if (row == null) continue;
      if (row.uuid.isEmpty ||
          tombstoned('absences', row.uuid, row.updatedAt)) {
        continue;
      }
      final classId = remapFileId(classUuids, classMap, row.classId);
      if (classId == null) continue;
      final local = absenceMap[row.uuid];
      if (local == null) {
        final id = await db
            .into(db.absences)
            .insert(
              row.toCompanion(true).copyWith(
                id: const Value.absent(),
                classId: Value(classId),
              ),
            );
        absenceMap[row.uuid] = (id: id, updatedAt: row.updatedAt);
        count++;
      } else if (row.updatedAt > local.updatedAt) {
        await maybeConflict('absences', row.uuid, local.updatedAt, m,
            () async {
          final existing = await (db.select(
            db.absences,
          )..where((t) => t.uuid.equals(row.uuid))).getSingleOrNull();
          return existing == null
              ? null
              : Map<String, dynamic>.from(existing.toJson());
        });
        await db
            .update(db.absences)
            .replace(row.copyWith(id: local.id, classId: classId));
        absenceMap[row.uuid] = (id: local.id, updatedAt: row.updatedAt);
        count++;
      }
    }

    // Subtasks / reminders / grades (task FKs).
    for (final m in listOf('subtasks')) {
      final row = parseRow(m, Subtask.fromJson);
      if (row == null) continue;
      if (row.uuid.isEmpty ||
          tombstoned('subtasks', row.uuid, row.updatedAt)) {
        continue;
      }
      final taskId = remapFileId(taskUuids, taskMap, row.taskId);
      if (taskId == null) continue;
      final local = subtaskMap[row.uuid];
      if (local == null) {
        final id = await db
            .into(db.subtasks)
            .insert(
              row.toCompanion(true).copyWith(
                id: const Value.absent(),
                taskId: Value(taskId),
              ),
            );
        subtaskMap[row.uuid] = (id: id, updatedAt: row.updatedAt);
        count++;
      } else if (row.updatedAt > local.updatedAt) {
        await maybeConflict('subtasks', row.uuid, local.updatedAt, m,
            () async {
          final existing = await (db.select(
            db.subtasks,
          )..where((t) => t.uuid.equals(row.uuid))).getSingleOrNull();
          return existing == null
              ? null
              : Map<String, dynamic>.from(existing.toJson());
        });
        await db
            .update(db.subtasks)
            .replace(row.copyWith(id: local.id, taskId: taskId));
        subtaskMap[row.uuid] = (id: local.id, updatedAt: row.updatedAt);
        count++;
      }
    }
    for (final m in listOf('taskReminders')) {
      final row = parseRow(m, TaskReminder.fromJson);
      if (row == null) continue;
      if (row.uuid.isEmpty ||
          tombstoned('task_reminders', row.uuid, row.updatedAt)) {
        continue;
      }
      final taskId = remapFileId(taskUuids, taskMap, row.taskId);
      if (taskId == null) continue;
      final local = reminderMap[row.uuid];
      if (local == null) {
        final id = await db
            .into(db.taskReminders)
            .insert(
              row.toCompanion(true).copyWith(
                id: const Value.absent(),
                taskId: Value(taskId),
              ),
            );
        reminderMap[row.uuid] = (id: id, updatedAt: row.updatedAt);
        count++;
      } else if (row.updatedAt > local.updatedAt) {
        await maybeConflict(
            'task_reminders', row.uuid, local.updatedAt, m, () async {
          final existing = await (db.select(
            db.taskReminders,
          )..where((t) => t.uuid.equals(row.uuid))).getSingleOrNull();
          return existing == null
              ? null
              : Map<String, dynamic>.from(existing.toJson());
        });
        await db
            .update(db.taskReminders)
            .replace(row.copyWith(id: local.id, taskId: taskId));
        reminderMap[row.uuid] = (id: local.id, updatedAt: row.updatedAt);
        count++;
      }
    }
    for (final m in listOf('grades')) {
      final row = parseRow(m, Grade.fromJson);
      if (row == null) continue;
      if (row.uuid.isEmpty || tombstoned('grades', row.uuid, row.updatedAt)) {
        continue;
      }
      final examId = remapFileId(taskUuids, taskMap, row.examTaskId);
      if (examId == null) continue;
      final local = gradeMap[row.uuid];
      if (local == null) {
        final id = await db
            .into(db.grades)
            .insert(
              row.toCompanion(true).copyWith(
                id: const Value.absent(),
                examTaskId: Value(examId),
              ),
            );
        gradeMap[row.uuid] = (id: id, updatedAt: row.updatedAt);
        count++;
      } else if (row.updatedAt > local.updatedAt) {
        await maybeConflict('grades', row.uuid, local.updatedAt, m,
            () async {
          final existing = await (db.select(
            db.grades,
          )..where((t) => t.uuid.equals(row.uuid))).getSingleOrNull();
          return existing == null
              ? null
              : Map<String, dynamic>.from(existing.toJson());
        });
        await db
            .update(db.grades)
            .replace(row.copyWith(id: local.id, examTaskId: examId));
        gradeMap[row.uuid] = (id: local.id, updatedAt: row.updatedAt);
        count++;
      }
    }

    // Pomodoro sessions (nullable task FK).
    for (final m in listOf('pomodoroSessions')) {
      final row = parseRow(m, PomodoroSession.fromJson);
      if (row == null) continue;
      if (row.uuid.isEmpty ||
          tombstoned('pomodoro_sessions', row.uuid, row.updatedAt)) {
        continue;
      }
      final taskId = row.taskId == null
          ? null
          : remapFileId(taskUuids, taskMap, row.taskId!);
      if (row.taskId != null && taskId == null) continue;
      final local = pomodoroMap[row.uuid];
      if (local == null) {
        final id = await db
            .into(db.pomodoroSessions)
            .insert(
              row.toCompanion(true).copyWith(
                id: const Value.absent(),
                taskId: taskId == null ? const Value(null) : Value(taskId),
              ),
            );
        pomodoroMap[row.uuid] = (id: id, updatedAt: row.updatedAt);
        count++;
      } else if (row.updatedAt > local.updatedAt) {
        await maybeConflict(
          'pomodoro_sessions',
          row.uuid,
          local.updatedAt,
          m,
          () async {
            final existing = await (db.select(
              db.pomodoroSessions,
            )..where((t) => t.uuid.equals(row.uuid))).getSingleOrNull();
            return existing == null
                ? null
                : Map<String, dynamic>.from(existing.toJson());
          },
        );
        await db
            .update(db.pomodoroSessions)
            .replace(
              row.copyWith(
                id: local.id,
                taskId: taskId == null ? const Value(null) : Value(taskId),
              ),
            );
        pomodoroMap[row.uuid] = (id: local.id, updatedAt: row.updatedAt);
        count++;
      }
    }

    // Xtra events (no FKs).
    for (final m in listOf('xtraEvents')) {
      final row = parseRow(m, XtraEvent.fromJson);
      if (row == null) continue;
      if (row.uuid.isEmpty ||
          tombstoned('xtra_events', row.uuid, row.updatedAt)) {
        continue;
      }
      final local = xtraMap[row.uuid];
      if (local == null) {
        final id = await db
            .into(db.xtraEvents)
            .insert(row.toCompanion(true).copyWith(id: const Value.absent()));
        xtraMap[row.uuid] = (id: id, updatedAt: row.updatedAt);
        count++;
      } else if (row.updatedAt > local.updatedAt) {
        await maybeConflict('xtra_events', row.uuid, local.updatedAt, m,
            () async {
          final existing = await (db.select(
            db.xtraEvents,
          )..where((t) => t.uuid.equals(row.uuid))).getSingleOrNull();
          return existing == null
              ? null
              : Map<String, dynamic>.from(existing.toJson());
        });
        await db.update(db.xtraEvents).replace(row.copyWith(id: local.id));
        xtraMap[row.uuid] = (id: local.id, updatedAt: row.updatedAt);
        count++;
      }
    }

    // Class files (class FK remapped by uuid; bytes copied locally).
    final classFilesMerged = await _mergeFileRows(
      dir: dir,
      fileMaps: listOf('classFiles'),
      parentUuids: classUuids,
      parentMap: classMap,
      tombTable: 'class_files',
      isTombstoned: tombstoned,
      lastImportBefore: lastImportBefore,
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
    final yearFilesMerged = await _mergeFileRows(
      dir: dir,
      fileMaps: listOf('yearFiles'),
      parentUuids: yearUuids,
      parentMap: yearMap,
      tombTable: 'year_files',
      isTombstoned: tombstoned,
      lastImportBefore: lastImportBefore,
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
    count += classFilesMerged.count + yearFilesMerged.count;
    conflicts += classFilesMerged.conflicts + yearFilesMerged.conflicts;
    skipped += classFilesMerged.skipped + yearFilesMerged.skipped;

    return (count: count, conflicts: conflicts, skipped: skipped);
  }

  /// Merges one attachment table. Parents are remapped file-id → local-id
  /// via uuid; bytes are copied from the folder's `files/` dir into local
  /// app storage (the incoming absolute path is never trusted). Rows whose
  /// blob is missing from the folder are skipped.
  Future<({int count, int conflicts, int skipped})> _mergeFileRows({
    required Directory dir,
    required List<Map<String, dynamic>> fileMaps,
    required Map<int, String> parentUuids,
    required Map<String, ({int id, int updatedAt})> parentMap,
    required String tombTable,
    required bool Function(String table, String uuid, int updatedAt)
    isTombstoned,
    required int lastImportBefore,
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
    // File row-id → local-id via the prebuilt uuid map (O(1) per row).
    int? resolveParent(int fileId) {
      final uuid = parentUuids[fileId];
      if (uuid == null || uuid.isEmpty) return null;
      return parentMap[uuid]?.id;
    }

    var count = 0;
    var conflicts = 0;
    var skipped = 0;
    for (final m in fileMaps) {
      final dynamic row = _fileRowFromJson(tombTable, m);
      if (row == null) {
        skipped++;
        continue;
      }
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
        final int localUpdatedAt = existing.updatedAt as int;
        if (localUpdatedAt > lastImportBefore) {
          try {
            final localJson = Map<String, dynamic>.from(
              (existing.toJson() as Map),
            );
            conflicts += await _preserveConflict(
              dir,
              tombTable,
              uuid,
              localJson,
              m,
            );
          } catch (_) {}
        }
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
    return (count: count, conflicts: conflicts, skipped: skipped);
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
  final int conflictsPreserved;
  final int rowsSkipped;
  final String? error;

  const DataFolderResult({
    this.filesWritten = 0,
    this.filesRead = 0,
    this.rowsExported = 0,
    this.rowsUpserted = 0,
    this.rowsDeleted = 0,
    this.tombstonesAdopted = 0,
    this.conflictsPreserved = 0,
    this.rowsSkipped = 0,
    this.error,
  });
}
