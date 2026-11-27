import 'dart:typed_data';

/// Metadata for a single file stored in a [SyncStorage] backend.
class SyncFileEntry {
  final String path;
  final int sizeBytes;
  final int modifiedAtMs;
  final Map<String, String> properties;

  const SyncFileEntry({
    required this.path,
    required this.sizeBytes,
    required this.modifiedAtMs,
    this.properties = const {},
  });
}

/// Backend-agnostic file storage for Chronicle's JSON + blob sync format.
///
/// Paths are always forward-slash relative names (e.g. `manifest.json`,
/// `classes.json`, `files/syllabus_a1b2c3d4.pdf`, `conflicts/...`).
abstract class SyncStorage {
  /// Stable backend id (`'folder'` or `'gdrive'`).
  String get backendId;

  /// Unique identifier for the current target (e.g. directory path or
  /// `'gdrive'`), used to detect target changes in watchers.
  String get locationId;

  /// True when the backend is configured and ready for sync operations
  /// (e.g. folder path set, or Google Drive signed in).
  Future<bool> isReady();

  /// True when the underlying storage container exists and is accessible.
  Future<bool> exists();

  /// Prepares the storage for a batch of reads or writes (e.g. creates the
  /// local directory or refreshes the remote file index).
  Future<void> ensureReady();

  /// Reads UTF-8 text at [relativePath], or null if the file does not exist.
  /// Throws on permission/I/O/network errors so callers can surface them.
  Future<String?> readString(String relativePath);

  /// Reads raw bytes at [relativePath], or null if the file does not exist.
  Future<Uint8List?> readBytes(String relativePath);

  /// Writes UTF-8 text atomically to [relativePath]. Optional [properties]
  /// are stored as metadata by backends that support them (Google Drive
  /// `appProperties`) and ignored by local filesystem storage.
  Future<void> writeString(
    String relativePath,
    String content, {
    Map<String, String>? properties,
  });

  /// Writes raw bytes atomically to [relativePath].
  Future<void> writeBytes(String relativePath, Uint8List bytes);

  /// Deletes [relativePath] if present. No-op when already absent.
  Future<void> delete(String relativePath);

  /// Lists files under [prefix] (e.g. `'files'` or `'conflicts'`).
  /// Returned [SyncFileEntry.path] values are relative paths like
  /// `'files/syllabus_a1b2c3d4.pdf'`.
  Future<List<SyncFileEntry>> listPrefix(String prefix);

  /// Byte length of [relativePath], or null if absent.
  Future<int?> fileSize(String relativePath);

  /// Fast check for the remote manifest's `exportedAt` timestamp without
  /// downloading full table payloads. Returns null if no valid manifest exists.
  Future<int?> fastManifestExportedAt();

  /// True when any synced file was modified at or after [sinceMs].
  Future<bool> hasNewerFiles(int sinceMs);

  /// Optional live stream of changed relative paths (Local folder FS watch).
  /// Null for backends that rely on polling (Google Drive).
  Stream<String>? watchChanges();
}
