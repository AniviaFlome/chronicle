import 'dart:async';

import 'package:drift/drift.dart' show TableUpdateQuery;
import 'package:flutter/foundation.dart';

import 'data_folder.dart';

/// Automatic data-folder sync: debounced export on local changes plus
/// periodic import of folder updates. All merge semantics (last-write-wins
/// rows, tombstones, blob handling) stay in [DataFolderService]; this
/// controller only decides *when* to run it.
///
/// Safety properties:
/// - Exports are debounced ([exportDebounce]) and skipped without a folder.
/// - Imports run at startup, then every [pollInterval], and only when the
///   folder manifest is newer than both our last export and last import
///   (so our own exports never trigger a useless re-import).
/// - Export and import never overlap ([_busy] guard); everything is
///   idempotent, so spurious runs are harmless no-ops.
class FolderSyncController {
  final DataFolderService service;
  final Duration exportDebounce;
  final Duration pollInterval;

  Timer? _pollTimer;
  Timer? _debounceTimer;
  StreamSubscription<void>? _updatesSub;
  bool _busy = false;
  bool _disposed = false;
  bool _started = false;
  int _inflight = 0;

  FolderSyncController({
    required this.service,
    this.exportDebounce = const Duration(seconds: 5),
    this.pollInterval = const Duration(seconds: 30),
  });

  /// Whether auto-sync is currently allowed (folder set + toggle on).
  Future<bool> enabled() async {
    if (!await service.settings.autoSync()) return false;
    return await service.dataDir() != null;
  }

  /// Starts periodic import and change-triggered export. Safe to call once;
  /// subsequent calls are ignored.
  ///
  /// The change watcher only listens to synced data tables
  /// ([DataFolderService.syncedTableNames]). Watching every table would
  /// make each export/import schedule another export via its own settings
  /// bookkeeping writes, so the folder (and its manifest) would churn
  /// forever and Syncthing peers would never converge.
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
    _pollTimer = Timer.periodic(pollInterval, (_) => importIfNewer());
  }

  /// Stops timers and subscriptions, then waits for in-flight runs so
  /// callers can safely close the database right after. The controller
  /// cannot be restarted.
  Future<void> dispose() async {
    _disposed = true;
    _pollTimer?.cancel();
    _debounceTimer?.cancel();
    await _updatesSub?.cancel();
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

  Future<void> _exportIfNeeded() async {
    if (_disposed || _busy) return;
    if (!await enabled()) return;
    _busy = true;
    try {
      await _guarded(() => service.exportData());
    } catch (e) {
      debugPrint('Folder auto-export failed: $e');
    } finally {
      _busy = false;
    }
  }

  /// Imports when the folder holds state newer than ours. Returns true
  /// when an import ran.
  Future<bool> importIfNewer() async {
    if (_disposed || _busy) return false;
    if (!await enabled()) return false;
    _busy = true;
    try {
      final ran = await _guarded(() => _importNewer());
      return ran ?? false;
    } catch (e) {
      debugPrint('Folder auto-import failed: $e');
      return false;
    } finally {
      _busy = false;
    }
  }

  Future<bool> _importNewer() async {
    final dir = await service.dataDir();
    if (dir == null || _disposed) return false;
    final manifest = await service.readManifest(dir);
    final exportedAt = manifest?['exportedAt'];
    if (exportedAt is! int) return false;
    final lastExport = await service.settings.dataLastExportAt() ?? 0;
    final lastImport = await service.settings.dataLastImportAt() ?? 0;
    if (exportedAt <= lastExport || exportedAt <= lastImport) {
      return false;
    }
    final result = await service.importData();
    return result.error == null;
  }
}
