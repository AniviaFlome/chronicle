import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/database.dart';

/// Local file storage for per-class and per-year attachments (syllabus
/// PDFs, slides, images). Files are copied into the app support directory
/// under `class_files/<id>/` or `year_files/<id>/` and tracked in the
/// `ClassFiles`/`YearFiles` tables, which sync through the data folder
/// (metadata JSON plus content blobs under `files/`).
class ClassFilesService {
  final AppDatabase db;

  /// Overrides the app support directory (hermetic sync tests).
  final Directory? storageRoot;

  ClassFilesService(this.db, {this.storageRoot});

  /// Classifies a [pickAndSave] failure for user messaging. The system file
  /// picker surfaces its own failures (e.g. a broken content provider that
  /// refuses to open the picked file) as [PlatformException]; those get a
  /// specific message instead of leaking plugin internals.
  static String pickErrorKind(Object error) =>
      error is PlatformException ? 'unreadable' : 'other';

  Future<Directory> _scopeDir(String scope, int id) async {
    final base =
        storageRoot ?? await getApplicationSupportDirectory();
    final dir = Directory('${base.path}/$scope/$id');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  /// Copies picked files into [dir], calling [onFile] per stored file.
  /// Stored paths are saved relative (`scope/id/name`) so rows survive
  /// reinstalls and user changes; use [resolveStoredPath] to absolutize.
  /// Returns the number of files added.
  Future<int> _importPicked({
    required String scope,
    required int id,
    required Directory dir,
    required Future<void> Function(String name, String path, int size) onFile,
  }) async {
    final picked = await FilePicker.pickFiles();
    if (picked.isEmpty) return 0;
    var added = 0;
    for (final f in picked) {
      final name = _safeName(f.name);
      if (name.isEmpty) continue;
      final target = await _uniqueFile(dir, name);
      try {
        if (f.path != null) {
          await File(f.path!).copy(target.path);
        } else {
          await target.writeAsBytes(await f.readAsBytes());
        }
        final stat = await target.stat();
        final stored = '$scope/$id/${target.path.split('/').last}';
        await onFile(name, stored, stat.size);
        added++;
      } catch (_) {
        // Skip unreadable files; continue with the rest.
        try {
          if (await target.exists()) await target.delete();
        } catch (_) {}
      }
    }
    return added;
  }

  /// Picks files with the platform picker and copies them into app storage.
  /// Returns the number of files added.
  Future<int> pickAndSave(int classId) async {
    final dir = await _scopeDir('class_files', classId);
    return _importPicked(
      scope: 'class_files',
      id: classId,
      dir: dir,
      onFile: (name, path, size) => db
          .into(db.classFiles)
          .insert(
            ClassFilesCompanion.insert(
              classId: classId,
              fileName: name,
              storedPath: path,
              sizeBytes: Value(size),
            ),
          )
          .then((_) {}),
    );
  }

  /// Picks files for an academic year. Returns the number of files added.
  Future<int> pickAndSaveYear(int yearId) async {
    final dir = await _scopeDir('year_files', yearId);
    return _importPicked(
      scope: 'year_files',
      id: yearId,
      dir: dir,
      onFile: (name, path, size) => db
          .into(db.yearFiles)
          .insert(
            YearFilesCompanion.insert(
              yearId: yearId,
              fileName: name,
              storedPath: path,
              sizeBytes: Value(size),
            ),
          )
          .then((_) {}),
    );
  }

  /// Absolutizes a stored path: absolute (legacy) rows pass through,
  /// relative rows resolve against the app support directory.
  static Future<String> resolveStoredPath({
    required Directory? root,
    required String stored,
  }) async {
    if (stored.startsWith('/')) return stored;
    final base = root ?? await getApplicationSupportDirectory();
    return '${base.path}/$stored';
  }

  /// Opens a stored file by name and path: share sheet where supported
  /// (Android and others), default-app open as fallback. The share plugin
  /// cannot share files on Linux (`UnimplementedError`), so Linux goes
  /// straight to `url_launcher`, which opens the file with its default app.
  Future<void> openStoredFile({
    required String fileName,
    required String storedPath,
  }) async {
    final file = File(
      await resolveStoredPath(root: storageRoot, stored: storedPath),
    );
    if (!await file.exists()) throw StateError('File not found');
    if (!Platform.isLinux) {
      try {
        await SharePlus.instance.share(
          ShareParams(files: [XFile(file.path, name: fileName)]),
        );
        return;
      } catch (_) {
        // Fall through to url_launcher below.
      }
    }
    if (!await launchUrl(Uri.file(file.path))) {
      throw StateError('Could not open file');
    }
  }

  /// Opens a stored class attachment.
  Future<void> openFile(ClassFile row) =>
      openStoredFile(fileName: row.fileName, storedPath: row.storedPath);

  /// Extension of [fileName] in upper case ("PDF"), or '' when none.
  /// A leading dot alone (".gitignore") does not count as an extension.
  static String extensionOf(String fileName) {
    final name = fileName.trim().split('/').last.split('\\').last;
    final dot = name.lastIndexOf('.');
    if (dot <= 0 || dot == name.length - 1) return '';
    return name.substring(dot + 1).toUpperCase();
  }

  String _safeName(String raw) {
    final name = raw.trim().split('/').last.split('\\').last;
    return name.length > 255 ? name.substring(name.length - 255) : name;
  }

  Future<File> _uniqueFile(Directory dir, String name) async {
    return ClassFilesService.uniqueTarget(dir, name);
  }

  /// Collision-free target inside [dir] for [name] (`name (1).ext`, …).
  static Future<File> uniqueTarget(Directory dir, String name) async {
    var candidate = File('${dir.path}/$name');
    if (!await candidate.exists()) return candidate;
    final dot = name.lastIndexOf('.');
    final stem = dot <= 0 ? name : name.substring(0, dot);
    final ext = dot <= 0 ? '' : name.substring(dot);
    var i = 1;
    while (true) {
      candidate = File('${dir.path}/$stem ($i)$ext');
      if (!await candidate.exists()) return candidate;
      i++;
      if (i > 999) {
        candidate = File(
          '${dir.path}/$stem-${DateTime.now().millisecondsSinceEpoch}$ext',
        );
        return candidate;
      }
    }
  }
}
