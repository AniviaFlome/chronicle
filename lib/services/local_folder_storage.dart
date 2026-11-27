import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';

import 'data_folder.dart';
import 'sync_storage.dart';

/// [SyncStorage] backed by a user-chosen local [Directory] (e.g. Syncthing).
///
/// Writes are atomic (`.tmp` + rename) so external sync tools never observe
/// half-written JSON or blob files.
class LocalFolderStorage implements SyncStorage {
  final Directory dir;
  static int _tmpCounter = 0;

  LocalFolderStorage(this.dir);

  @override
  String get backendId => 'folder';

  @override
  String get locationId => dir.path;

  @override
  Future<bool> isReady() async => dir.path.trim().isNotEmpty;

  @override
  Future<bool> exists() => dir.exists();

  @override
  Future<void> ensureReady() async {
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
  }

  File _file(String relativePath) {
    if (relativePath.isEmpty ||
        relativePath.startsWith('/') ||
        relativePath.startsWith('\\')) {
      throw ArgumentError.value(
        relativePath,
        'relativePath',
        'Path must be relative and non-empty',
      );
    }
    final base = Uri.file(dir.path).toFilePath();
    final baseWithSep = base.endsWith('/') ? base : '$base/';
    final normalized = Uri.file('$baseWithSep$relativePath').toFilePath();
    if (!normalized.startsWith(baseWithSep)) {
      throw ArgumentError.value(
        relativePath,
        'relativePath',
        'Path escapes sync directory',
      );
    }
    return File(normalized);
  }

  File _tmpFor(File target) {
    final seq = _tmpCounter++;
    final nonce = Random.secure().nextInt(1 << 30);
    return File('${target.path}.$pid.$seq.$nonce.tmp');
  }

  @override
  Future<String?> readString(String relativePath) async {
    final file = _file(relativePath);
    if (!await file.exists()) return null;
    return file.readAsString();
  }

  @override
  Future<Uint8List?> readBytes(String relativePath) async {
    final file = _file(relativePath);
    if (!await file.exists()) return null;
    return file.readAsBytes();
  }

  @override
  Future<void> writeString(
    String relativePath,
    String content, {
    Map<String, String>? properties,
  }) async {
    final target = _file(relativePath);
    if (!await target.parent.exists()) {
      await target.parent.create(recursive: true);
    }
    final tmp = _tmpFor(target);
    try {
      await tmp.writeAsString(content);
      await tmp.rename(target.path);
    } catch (_) {
      try {
        if (await tmp.exists()) await tmp.delete();
      } catch (_) {}
      rethrow;
    }
  }

  @override
  Future<void> writeBytes(String relativePath, Uint8List bytes) async {
    final target = _file(relativePath);
    if (!await target.parent.exists()) {
      await target.parent.create(recursive: true);
    }
    final tmp = _tmpFor(target);
    try {
      await tmp.writeAsBytes(bytes);
      await tmp.rename(target.path);
    } catch (_) {
      try {
        if (await tmp.exists()) await tmp.delete();
      } catch (_) {}
      rethrow;
    }
  }

  @override
  Future<void> delete(String relativePath) async {
    final target = _file(relativePath);
    if (await target.exists()) {
      await target.delete();
    }
  }

  @override
  Future<List<SyncFileEntry>> listPrefix(String prefix) async {
    final clean = prefix.replaceAll(RegExp(r'^/+|/+$'), '');
    final sub = clean.isEmpty ? dir : Directory('${dir.path}/$clean');
    if (!await sub.exists()) return const [];
    final out = <SyncFileEntry>[];
    await for (final entity in sub.list()) {
      if (entity is File) {
        final name = entity.path.split('/').last.split('\\').last;
        if (name.endsWith('.tmp')) continue;
        try {
          final stat = await entity.stat();
          out.add(
            SyncFileEntry(
              path: clean.isEmpty ? name : '$clean/$name',
              sizeBytes: stat.size,
              modifiedAtMs: stat.modified.millisecondsSinceEpoch,
            ),
          );
        } catch (_) {}
      }
    }
    return out;
  }

  @override
  Future<int?> fileSize(String relativePath) async {
    try {
      final stat = await FileStat.stat(_file(relativePath).path);
      if (stat.type == FileSystemEntityType.notFound) return null;
      return stat.size;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<int?> fastManifestExportedAt() async {
    try {
      final raw = await readString(DataFolderService.manifestFile);
      if (raw == null) return null;
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      if (decoded['app'] != DataFolderService.appTag ||
          decoded['formatVersion'] != DataFolderService.formatVersion) {
        return null;
      }
      final exportedAt = decoded['exportedAt'];
      return exportedAt is int ? exportedAt : null;
    } catch (e) {
      debugPrint('LocalFolderStorage: fastManifestExportedAt failed: $e');
      return null;
    }
  }

  @override
  Future<bool> hasNewerFiles(int sinceMs) async {
    Future<bool> newer(String path) async {
      try {
        final stat = await FileStat.stat(path);
        if (stat.type == FileSystemEntityType.notFound) return false;
        return stat.modified.millisecondsSinceEpoch >= sinceMs;
      } catch (_) {
        return false;
      }
    }

    if (await newer('${dir.path}/${DataFolderService.manifestFile}')) {
      return true;
    }
    for (final name in DataFolderService.tableFiles.values) {
      if (await newer('${dir.path}/$name')) return true;
    }
    if (await newer('${dir.path}/${DataFolderService.tombstonesFile}')) {
      return true;
    }
    if (await newer('${dir.path}/${DataFolderService.settingsFile}')) {
      return true;
    }
    final blobsDir = Directory('${dir.path}/${DataFolderService.filesDir}');
    try {
      if (await blobsDir.exists()) {
        await for (final e in blobsDir.list()) {
          if (e is File) {
            try {
              final stat = await e.stat();
              if (stat.modified.millisecondsSinceEpoch >= sinceMs) return true;
            } catch (_) {}
          }
        }
      }
    } catch (_) {}
    return false;
  }

  @override
  Stream<String>? watchChanges() {
    if (!dir.existsSync()) return null;
    return dir
        .watch(recursive: true)
        .map((e) => e.path)
        .where((path) {
          final isJson = path.endsWith('.json');
          final isBlob =
              path.contains('/${DataFolderService.filesDir}/') ||
              path.contains('\\${DataFolderService.filesDir}\\');
          final isConflict =
              path.contains('/${DataFolderService.conflictsDir}/') ||
              path.contains('\\${DataFolderService.conflictsDir}\\');
          return (isJson || isBlob) && !isConflict;
        });
  }
}
