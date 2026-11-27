import 'dart:async';

import 'package:drift/drift.dart' show TableUpdateQuery;
import 'package:flutter/foundation.dart';

import 'data_folder.dart';

/// Automatic sync controller: debounced export on changes plus periodic
/// import (and FS watch for local-folder backends). Merge semantics stay in
/// [DataFolderService]; this only decides *when* to run. Exports are debounced
/// and never prune blobs on the auto path.
class FolderSyncController {
  final DataFolderService service;
  final Duration exportDebounce;
  final Duration pollInterval;
  final Duration drivePollInterval;
  final Duration watchDebounce;

  Timer? _pollTimer;
  Timer? _debounceTimer;
  Timer? _watchDebounceTimer;
  StreamSubscription<void>? _updatesSub;
  StreamSubscription<String>? _storageWatchSub;
  String? _watchedLocation;
  DateTime? _lastDrivePoll;
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
    this.drivePollInterval = const Duration(seconds: 60),
    this.watchDebounce = const Duration(seconds: 2),
  });

  /// Whether auto-sync is currently allowed (active backend ready + toggle on).
  Future<bool> enabled() async {
    if (!await service.settings.autoSync()) return false;
    final storage = await service.activeStorage();
    if (storage == null) return false;
    return storage.isReady();
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
      await _periodicPoll();
    });
    await _ensureWatching();
  }

  Future<void> _periodicPoll() async {
    final storage = await service.activeStorage();
    if (storage == null) return;
    if (storage.backendId == 'gdrive') {
      final now = DateTime.now();
      if (_lastDrivePoll != null &&
          now.difference(_lastDrivePoll!) < drivePollInterval) {
        return;
      }
      _lastDrivePoll = now;
    }
    await importIfNewer();
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
    await _storageWatchSub?.cancel();
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

  /// Explicit export trigger for portable settings changes (theme,
  /// calendar geometry, menu source, …), which live in the settings table
  /// that [start] deliberately does not watch to avoid bookkeeping churn.
  /// Call after changing a key in [DataFolderService.syncedSettingKeys].
  void scheduleExport() => _markDirty();

  /// Re-arms storage watchers after the user changes sync target or folder.
  Future<void> reconfigure() async {
    _lastDrivePoll = null;
    await _ensureWatching();
  }

  /// Watches the active storage for external changes when supported (Local
  /// folder). Cancels any old watcher when switching targets.
  Future<void> _ensureWatching() async {
    if (_disposed) return;
    final storage = await service.activeStorage();
    final loc = storage == null ? null : '${storage.backendId}:${storage.locationId}';
    if (loc == _watchedLocation && (loc == null || _storageWatchSub != null)) {
      return;
    }
    await _storageWatchSub?.cancel();
    _storageWatchSub = null;
    _watchedLocation = loc;
    if (storage == null) return;
    try {
      final stream = storage.watchChanges();
      if (stream == null) return;
      _storageWatchSub = stream.listen(
        (_) {
          if (_disposed) return;
          _watchDebounceTimer?.cancel();
          _watchDebounceTimer = Timer(watchDebounce, () => importIfNewer());
        },
        onError: (Object e) => debugPrint('Storage watch failed: $e'),
      );
    } catch (e) {
      debugPrint('Storage watch failed: $e');
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
    // Claim _busy synchronously BEFORE awaiting enabled() so concurrent
    // triggers (resume + timer + DB write) cannot interleave.
    _busy = true;
    try {
      if (!await enabled()) return;
      await _guarded(() async {
        // Merge-before-export: pull peer changes so we never overwrite
        // them with a stale full snapshot.
        await _importNewerInternal();
        await service.exportData(pruneBlobs: false);
      });
    } catch (e) {
      debugPrint('Auto-export failed: $e');
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

  /// Imports when the active backend holds state newer than ours. Returns
  /// true when an import ran.
  Future<bool> importIfNewer() async {
    if (_disposed) return false;
    if (_busy) {
      _importQueued = true;
      return false;
    }
    _busy = true;
    try {
      if (!await enabled()) return false;
      final ran = await _guarded(() => _importNewerInternal());
      return ran ?? false;
    } catch (e) {
      debugPrint('Auto-import failed: $e');
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
  /// (for local folders) when any synced file is newer than our last
  /// export/import (catches Syncthing files arriving after the manifest).
  /// Equality-based, so cross-device clock skew can't hide peer data.
  /// Skips the round while a fresh export lock is present.
  Future<bool> _importNewerInternal() async {
    final storage = await service.activeStorage();
    if (storage == null || _disposed) return false;
    if (!await storage.isReady()) return false;
    if (storage.backendId == 'folder' &&
        await service.exportInProgressFor(storage)) {
      return false;
    }
    final exportedAt = await storage.fastManifestExportedAt();
    if (exportedAt == null) return false;
    final seen = await service.settings.dataLastSeenExportedAt();
    if (seen != null && exportedAt == seen) {
      // For local folders (Syncthing), files can arrive after manifest.json.
      // For Google Drive, manifest.json is uploaded last after all tables +
      // blobs, so an identical exportedAt means zero changes (saves API calls).
      if (storage.backendId == 'gdrive') {
        return false;
      }
      final lastExport = await service.settings.dataLastExportAt() ?? 0;
      final lastImport = await service.settings.dataLastImportAt() ?? 0;
      final baseline = lastExport > lastImport ? lastExport : lastImport;
      if (!await storage.hasNewerFiles(baseline)) {
        return false;
      }
    }
    if (storage.backendId == 'gdrive' &&
        await service.exportInProgressFor(storage)) {
      return false;
    }
    final result = await service.importData();
    return result.error == null;
  }
}
