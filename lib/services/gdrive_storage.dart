import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'data_folder.dart';
import 'gdrive_auth.dart';
import 'sync_storage.dart';

class _DriveFileMeta {
  final String id;
  final String name;
  final int sizeBytes;
  final int modifiedAtMs;
  final Map<String, String> appProperties;

  const _DriveFileMeta({
    required this.id,
    required this.name,
    required this.sizeBytes,
    required this.modifiedAtMs,
    required this.appProperties,
  });

  factory _DriveFileMeta.fromJson(Map<String, dynamic> json) {
    final rawSize = json['size'];
    final size = rawSize is int
        ? rawSize
        : int.tryParse(rawSize?.toString() ?? '') ?? 0;
    final modRaw = json['modifiedTime'] as String?;
    final modMs = modRaw != null
        ? (DateTime.tryParse(modRaw)?.millisecondsSinceEpoch ?? 0)
        : 0;
    final rawProps = json['appProperties'];
    final props = <String, String>{};
    if (rawProps is Map) {
      for (final e in rawProps.entries) {
        if (e.key is String && e.value != null) {
          props[e.key as String] = e.value.toString();
        }
      }
    }
    return _DriveFileMeta(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      sizeBytes: size,
      modifiedAtMs: modMs,
      appProperties: props,
    );
  }
}

/// [SyncStorage] backed by Google Drive API v3 `appDataFolder`.
///
/// Files are stored flat in `appDataFolder` using their relative paths
/// (`manifest.json`, `classes.json`, `files/<blob>`, `conflicts/<file>`).
/// This avoids subfolder creation races across devices and lets one
/// `files.list` call index the entire snapshot.
class GoogleDriveStorage implements SyncStorage {
  final GoogleDriveAuth auth;
  final http.Client _http;

  static const _apiBase = 'https://www.googleapis.com/drive/v3';
  static const _uploadBase = 'https://www.googleapis.com/upload/drive/v3';
  static const _metaTimeout = Duration(seconds: 20);
  static const _transferTimeout = Duration(seconds: 60);

  /// Cached name → newest file metadata (plus older duplicate IDs to clean up).
  Map<String, _DriveFileMeta>? _index;
  Future<Map<String, _DriveFileMeta>>? _indexRefreshInFlight;
  final Map<String, List<String>> _duplicates = {};

  static String _randomBoundary() {
    final rng = Random.secure();
    final bytes = List<int>.generate(16, (_) => rng.nextInt(256));
    final hex = [for (final b in bytes) b.toRadixString(16).padLeft(2, '0')].join();
    return 'chronicle_boundary_$hex';
  }

  GoogleDriveStorage({required this.auth, http.Client? httpClient})
    : _http = httpClient ?? http.Client();

  @override
  String get backendId => 'gdrive';

  @override
  String get locationId => 'gdrive';

  @override
  Future<bool> isReady() async {
    final account = await auth.currentAccount();
    return account != null;
  }

  @override
  Future<bool> exists() => isReady();

  @override
  Future<void> ensureReady() async {
    await _refreshIndex();
  }

  Future<String> _requireToken({bool forceRefresh = false}) async {
    final token = await auth.getAccessToken(forceRefresh: forceRefresh);
    if (token == null || token.isEmpty) {
      throw const GoogleDriveAuthException(
        'gdrive-auth-expired',
        'Google Drive sign-in expired. Please sign in again.',
      );
    }
    return token;
  }

  /// Executes [send] with a Bearer token, retrying once after refreshing the
  /// token if Drive responds with HTTP 401.
  Future<http.Response> _authed(
    Future<http.Response> Function(String token) send,
  ) async {
    var token = await _requireToken();
    var res = await send(token);
    if (res.statusCode == 401) {
      token = await _requireToken(forceRefresh: true);
      res = await send(token);
    }
    if (res.statusCode == 401) {
      throw const GoogleDriveAuthException(
        'gdrive-auth-expired',
        'Google Drive authorization rejected (401). Please sign in again.',
      );
    }
    return res;
  }

  Future<Map<String, _DriveFileMeta>> _refreshIndex({String? query}) async {
    final best = <String, _DriveFileMeta>{};
    final dups = <String, List<String>>{};
    String? pageToken;
    do {
      final params = <String, String>{
        'spaces': 'appDataFolder',
        'fields': 'nextPageToken,files(id,name,size,modifiedTime,appProperties)',
        'pageSize': '1000',
        'q': query ?? 'trashed = false',
      };
      if (pageToken != null) params['pageToken'] = pageToken;
      final uri = Uri.parse('$_apiBase/files').replace(queryParameters: params);
      final res = await _authed(
        (t) => _http
            .get(uri, headers: {'Authorization': 'Bearer $t'})
            .timeout(_metaTimeout),
      );
      if (res.statusCode < 200 || res.statusCode >= 300) {
        throw Exception('Drive list failed (${res.statusCode}): ${res.body}');
      }
      final body = Map<String, dynamic>.from(jsonDecode(res.body) as Map);
      final files = body['files'] as List? ?? const [];
      for (final raw in files) {
        if (raw is! Map) continue;
        final meta = _DriveFileMeta.fromJson(Map<String, dynamic>.from(raw));
        if (meta.id.isEmpty || meta.name.isEmpty) continue;
        final prev = best[meta.name];
        if (prev == null) {
          best[meta.name] = meta;
        } else if (meta.modifiedAtMs > prev.modifiedAtMs) {
          (dups[meta.name] ??= []).add(prev.id);
          best[meta.name] = meta;
        } else {
          (dups[meta.name] ??= []).add(meta.id);
        }
      }
      pageToken = body['nextPageToken'] as String?;
    } while (pageToken != null && pageToken.isNotEmpty);

    if (query == null) {
      _index = best;
      _duplicates
        ..clear()
        ..addAll(dups);
    }
    return best;
  }

  Future<Map<String, _DriveFileMeta>> _getIndex() async {
    final cached = _index;
    if (cached != null) return cached;
    final inflight = _indexRefreshInFlight;
    if (inflight != null) return inflight;
    final future = _refreshIndex().whenComplete(() {
      _indexRefreshInFlight = null;
    });
    _indexRefreshInFlight = future;
    return future;
  }

  Future<Uint8List?> _readBytesById(String id, String label) async {
    final uri = Uri.parse('$_apiBase/files/$id?alt=media');
    final res = await _authed(
      (t) => _http
          .get(uri, headers: {'Authorization': 'Bearer $t'})
          .timeout(_transferTimeout),
    );
    if (res.statusCode == 404) return null;
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Drive download failed for $label (${res.statusCode})');
    }
    return res.bodyBytes;
  }

  @override
  Future<String?> readString(String relativePath) async {
    final bytes = await readBytes(relativePath);
    if (bytes == null) return null;
    return utf8.decode(bytes);
  }

  @override
  Future<Uint8List?> readBytes(String relativePath) async {
    final index = await _getIndex();
    final meta = index[relativePath];
    if (meta == null) return null;
    final bytes = await _readBytesById(meta.id, relativePath);
    if (bytes == null) {
      index.remove(relativePath);
      return null;
    }
    return bytes;
  }

  @override
  Future<void> writeString(
    String relativePath,
    String content, {
    Map<String, String>? properties,
  }) => _upload(
    relativePath,
    Uint8List.fromList(utf8.encode(content)),
    contentType: 'application/json; charset=utf-8',
    properties: properties,
  );

  @override
  Future<void> writeBytes(String relativePath, Uint8List bytes) =>
      _upload(relativePath, bytes, contentType: 'application/octet-stream');

  Future<void> _upload(
    String relativePath,
    Uint8List bytes, {
    required String contentType,
    Map<String, String>? properties,
    bool allowCreateOn404 = true,
  }) async {
    final index = await _getIndex();
    final existing = index[relativePath];

    final boundary = _randomBoundary();
    final metadata = <String, dynamic>{
      if (existing == null) 'name': relativePath,
      if (existing == null) 'parents': ['appDataFolder'],
      if (properties != null && properties.isNotEmpty)
        'appProperties': properties,
    };
    final bodyBytes = _buildMultipart(
      boundary: boundary,
      metadataJson: jsonEncode(metadata),
      contentType: contentType,
      payload: bytes,
    );

    final Uri uri;
    final Future<http.Response> Function(String token) send;
    if (existing != null) {
      uri = Uri.parse(
        '$_uploadBase/files/${existing.id}'
        '?uploadType=multipart&fields=id,name,size,modifiedTime,appProperties',
      );
      send = (t) => _http
          .patch(
            uri,
            headers: {
              'Authorization': 'Bearer $t',
              'Content-Type': 'multipart/related; boundary=$boundary',
            },
            body: bodyBytes,
          )
          .timeout(_transferTimeout);
    } else {
      uri = Uri.parse(
        '$_uploadBase/files'
        '?uploadType=multipart&fields=id,name,size,modifiedTime,appProperties',
      );
      send = (t) => _http
          .post(
            uri,
            headers: {
              'Authorization': 'Bearer $t',
              'Content-Type': 'multipart/related; boundary=$boundary',
            },
            body: bodyBytes,
          )
          .timeout(_transferTimeout);
    }

    final res = await _authed(send);
    if (existing != null && res.statusCode == 404 && allowCreateOn404) {
      // Cached Drive ID was deleted remotely by another device: evict and
      // re-create once via POST instead of failing the export.
      index.remove(relativePath);
      return _upload(
        relativePath,
        bytes,
        contentType: contentType,
        properties: properties,
        allowCreateOn404: false,
      );
    }
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception(
        'Drive upload failed for $relativePath (${res.statusCode}): ${res.body}',
      );
    }
    final updated = _DriveFileMeta.fromJson(
      Map<String, dynamic>.from(jsonDecode(res.body) as Map),
    );
    index[relativePath] = updated;

    // Best-effort cleanup of older duplicate-named files created by a race.
    final dupIds = _duplicates.remove(relativePath);
    if (dupIds != null) {
      for (final id in dupIds) {
        try {
          await _deleteById(id);
        } catch (_) {}
      }
    }
  }

  static Uint8List _buildMultipart({
    required String boundary,
    required String metadataJson,
    required String contentType,
    required Uint8List payload,
  }) {
    final builder = BytesBuilder(copy: false);
    builder.add(
      utf8.encode(
        '--$boundary\r\n'
        'Content-Type: application/json; charset=UTF-8\r\n\r\n'
        '$metadataJson\r\n'
        '--$boundary\r\n'
        'Content-Type: $contentType\r\n\r\n',
      ),
    );
    builder.add(payload);
    builder.add(utf8.encode('\r\n--$boundary--'));
    return builder.toBytes();
  }

  Future<void> _deleteById(String id) async {
    final uri = Uri.parse('$_apiBase/files/$id');
    final res = await _authed(
      (t) => _http
          .delete(uri, headers: {'Authorization': 'Bearer $t'})
          .timeout(_metaTimeout),
    );
    if (res.statusCode != 404 &&
        (res.statusCode < 200 || res.statusCode >= 300)) {
      throw Exception('Drive delete failed ($id, ${res.statusCode})');
    }
  }

  @override
  Future<void> delete(String relativePath) async {
    final index = await _getIndex();
    final meta = index.remove(relativePath);
    if (meta != null) {
      await _deleteById(meta.id);
    }
    final dupIds = _duplicates.remove(relativePath);
    if (dupIds != null) {
      for (final id in dupIds) {
        try {
          await _deleteById(id);
        } catch (_) {}
      }
    }
  }

  @override
  Future<List<SyncFileEntry>> listPrefix(String prefix) async {
    final index = await _getIndex();
    final clean = prefix.replaceAll(RegExp(r'^/+|/+$'), '');
    final matchPrefix = clean.isEmpty ? '' : '$clean/';
    return [
      for (final meta in index.values)
        if (matchPrefix.isEmpty || meta.name.startsWith(matchPrefix))
          SyncFileEntry(
            path: meta.name,
            sizeBytes: meta.sizeBytes,
            modifiedAtMs: meta.modifiedAtMs,
            properties: meta.appProperties,
          ),
    ];
  }

  @override
  Future<int?> fileSize(String relativePath) async {
    final index = await _getIndex();
    return index[relativePath]?.sizeBytes;
  }

  @override
  Future<int?> fastManifestExportedAt() async {
    // One lightweight metadata query for manifest.json (no file download).
    try {
      final subset = await _refreshIndex(
        query:
            "name = '${DataFolderService.manifestFile}' and trashed = false",
      );
      final meta = subset[DataFolderService.manifestFile];
      if (meta == null) return null;
      final prop = meta.appProperties['exportedAt'];
      final parsed = prop == null ? null : int.tryParse(prop);
      if (parsed != null) return parsed;
      // Fallback for manifests written without appProperties. Download by
      // Drive ID directly without initializing `_index` to a 1-entry map
      // (which would hide every other file from subsequent `_getIndex()` calls).
      if (_index != null) {
        _index![DataFolderService.manifestFile] = meta;
      }
      final bytes = await _readBytesById(
        meta.id,
        DataFolderService.manifestFile,
      );
      if (bytes == null) return null;
      final decoded = jsonDecode(utf8.decode(bytes));
      if (decoded is Map &&
          decoded['app'] == DataFolderService.appTag &&
          decoded['formatVersion'] == DataFolderService.formatVersion &&
          decoded['exportedAt'] is int) {
        return decoded['exportedAt'] as int;
      }
      return null;
    } catch (e) {
      debugPrint('GoogleDriveStorage: fastManifestExportedAt failed: $e');
      rethrow;
    }
  }

  @override
  Future<bool> hasNewerFiles(int sinceMs) async {
    final index = await _refreshIndex();
    for (final meta in index.values) {
      if (meta.name == DataFolderService.exportLockFile) continue;
      if (meta.name.startsWith('${DataFolderService.conflictsDir}/')) continue;
      if (meta.modifiedAtMs >= sinceMs) return true;
    }
    return false;
  }

  @override
  Stream<String>? watchChanges() => null;
}
