import 'dart:async';
import 'dart:io';

import 'package:drift/drift.dart' show TableUpdateQuery;
import 'package:flutter/foundation.dart';

import 'data_folder.dart';

/// Automatic data-folder sync: debounced export on changes plus periodic
/// import. Merge semantics stay in [DataFolderService]; this only decides
/// *when* to run. Exports are debounced and never prune blobs on auto path.
class FolderSyncController {
  final DataFolderService service;
  final Duration exportDebounce;
  final Duration pollInterval;
  final Duration watchDebounce;

  Timer? _pollTimer;
  Timer? _debounceTimer;
  Timer? _watchDebounceTimer;
  StreamSubscription<void>? _updatesSub;
  StreamSubscription<FileSystemEvent>? _folderWatchSub;
  String? _watchedPath;
  bool _busy = false;
  bool _exportQueued = false;
  bool _importQueued = false;
  bool _disposed = false;
  bool _started = false;
  int _inflight = 0;

  FolderSyncController({
    required this.service,
    this.exportDebounce = const Duration(seconds: 5),
    this.pollInterval = const Duration(seconds: 30),
    this.watchDebounce = const Duration(seconds: 2),
  });

  /// Whether auto-sync is currently allowed (folder set + toggle on).
  Future<bool> enabled() async {
    if (!await service.settings.autoSync()) return false;
    return await service.dataDir() != null;
  }

  /// Starts periodic import and change-triggered export (once).
  /// Watches only synced tables to avoid export churn from own bookkeeping.
  Future<void> start() async {
    if (_started) return;
    _started = true;
    await importIfNewer();
    if (_disposed) return;
    _updatesSub = service.db
        .tableUpdates(
          TableUpdateQuery.allOf([
            for (final name in DataFolderService.syncedTableNames)
              TableUpdateQuery.onTableName(name),
          ]),
        )
        .listen(
          (_) => _markDirty(),
          onError: (Object e) => debugPrint('Folder sync watch failed: $e'),
        );
    _pollTimer = Timer.periodic(pollInterval, (_) async {
      await _ensureWatching();
      await importIfNewer();
    });
    await _ensureWatching();
  }

  /// Stops timers and subscriptions, then waits for in-flight runs so
  /// callers can safely close the database right after. The controller
  /// cannot be restarted.
  Future<void> dispose() async {
    _disposed = true;
    _pollTimer?.cancel();
    _debounceTimer?.cancel();
    _watchDebounceTimer?.cancel();
    await _updatesSub?.cancel();
    await _folderWatchSub?.cancel();
    for (var i = 0; i < 500 && _inflight > 0; i++) {
      await Future.delayed(const Duration(milliseconds: 10));
    }
  }

  /// Runs [work] unless disposed, tracking it for [dispose].
  Future<T?> _guarded<T>(Future<T> Function() work) async {
    if (_disposed) return null;
    _inflight++;
    try {
      return await work();
    } finally {
      _inflight--;
    }
  }

  void _markDirty() {
    if (_disposed) return;
    _debounceTimer?.cancel();
    _debounceTimer = Timer(exportDebounce, () => _exportIfNeeded());
  }

  /// Watches the data folder for external (Syncthing) changes. Debounced
  /// into [importIfNewer]; re-arms when the user picks a new folder.
  Future<void> _ensureWatching() async {
    if (_disposed) return;
    final dir = await service.dataDir();
    if (dir == null) return;
    if (_watchedPath == dir.path && _folderWatchSub != null) return;
    await _folderWatchSub?.cancel();
    _folderWatchSub = null;
    _watchedPath = dir.path;
    try {
      if (!await Directory(dir.path).exists()) return;
      _folderWatchSub = Directory(
        dir.path,
      ).watch(recursive: true).listen((event) {
        if (_disposed) return;
        final path = event.path;
        final isJson = path.endsWith('.json');
        final isBlob =
            path.contains('/${DataFolderService.filesDir}/') ||
            path.contains('\\${DataFolderService.filesDir}\\');
        final isConflict = path.contains('/${DataFolderService.conflictsDir}/');
        if (!isJson && !isBlob) return;
        if (isConflict) return;
        _watchDebounceTimer?.cancel();
        _watchDebounceTimer = Timer(watchDebounce, () => importIfNewer());
      }, onError: (Object e) => debugPrint('Folder watch failed: $e'));
    } catch (e) {
      debugPrint('Folder watch failed: $e');
    }
  }

  /// Queued auto-export: merges peer state first, then writes without
  /// pruning blobs (see [DataFolderService.exportData]).
  Future<void> _exportIfNeeded() async {
    if (_disposed) return;
    if (_busy) {
      _exportQueued = true;
      return;
    }
    if (!await enabled()) return;
    _busy = true;
    try {
      await _guarded(() async {
        // Merge-before-export: pull peer changes so we never overwrite
        // them with a stale full snapshot.
        await _importNewerInternal();
        await service.exportData(pruneBlobs: false);
      });
    } catch (e) {
      debugPrint('Folder auto-export failed: $e');
      try {
        await service.settings.setDataSyncError('auto-export: $e');
      } catch (_) {}
    } finally {
      _busy = false;
      if (!_disposed && (_exportQueued || _importQueued)) {
        final runExport = _exportQueued;
        _exportQueued = false;
        _importQueued = false;
        if (runExport) {
          _markDirty();
        }
        // Import was already merged before this export; no extra import.
      }
    }
  }

  /// Imports when the folder holds state newer than ours. Returns true
  /// when an import ran.
  Future<bool> importIfNewer() async {
    if (_disposed) return false;
    if (_busy) {
      _importQueued = true;
      return false;
    }
    if (!await enabled()) return false;
    _busy = true;
    try {
      final ran = await _guarded(() => _importNewerInternal());
      return ran ?? false;
    } catch (e) {
      debugPrint('Folder auto-import failed: $e');
      try {
        await service.settings.setDataSyncError('auto-import: $e');
      } catch (_) {}
      return false;
    } finally {
      _busy = false;
      if (!_disposed && (_exportQueued || _importQueued)) {
        final runExport = _exportQueued;
        final runImport = _importQueued;
        _exportQueued = false;
        _importQueued = false;
        if (runExport) {
          _markDirty();
        } else if (runImport) {
          await importIfNewer();
        }
      }
    }
  }

  /// Gate: import when the manifest differs from the last seen one, or
  /// when any synced file is newer than our last export/import (catches
  /// Syncthing files arriving after the manifest). Equality-based, so
  /// cross-device clock skew can't hide peer data.
  Future<bool> _importNewerInternal() async {
    final dir = await service.dataDir();
    if (dir == null || _disposed) return false;
    final manifest = await service.readManifest(dir);
    if (manifest == null) return false;
    final exportedAt = manifest['exportedAt'];
    if (exportedAt is! int) return false;
    final seen = await service.settings.dataLastSeenExportedAt();
    if (seen != null && exportedAt == seen) {
      final lastExport = await service.settings.dataLastExportAt() ?? 0;
      final lastImport = await service.settings.dataLastImportAt() ?? 0;
      final baseline = lastExport > lastImport ? lastExport : lastImport;
      if (!await service.folderHasNewerFiles(dir, baseline)) {
        return false;
      }
    }
    final result = await service.importData();
    return result.error == null;
  }
}
