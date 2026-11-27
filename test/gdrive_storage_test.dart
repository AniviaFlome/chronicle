import 'dart:convert';
import 'dart:typed_data';

import 'package:chronicle/services/gdrive_auth.dart';
import 'package:chronicle/services/gdrive_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

class _FakeDriveAuth implements GoogleDriveAuth {
  String? token;
  String? refreshedToken;
  int refreshCalls = 0;
  GoogleDriveAccount? account = const GoogleDriveAccount(
    email: 'student@example.com',
  );

  _FakeDriveAuth({
    this.token = 'tok-1',
    this.refreshedToken = 'tok-2',
  });

  @override
  Future<bool> isConfigured() async => true;

  @override
  Future<GoogleDriveAccount?> currentAccount() async => account;

  @override
  Future<GoogleDriveAccount?> signIn() async => account;

  @override
  Future<void> signOut() async {
    account = null;
    token = null;
  }

  @override
  Future<String?> getAccessToken({bool forceRefresh = false}) async {
    if (forceRefresh) {
      refreshCalls++;
      token = refreshedToken;
    }
    return token;
  }
}

class FakeDriveFile {
  final String id;
  String name;
  Uint8List bytes;
  DateTime modifiedTime;
  Map<String, String> appProperties;

  FakeDriveFile({
    required this.id,
    required this.name,
    required this.bytes,
    required this.modifiedTime,
    Map<String, String>? appProperties,
  }) : appProperties = appProperties ?? {};

  Map<String, dynamic> toMeta() => {
    'id': id,
    'name': name,
    'size': '${bytes.length}',
    'modifiedTime': modifiedTime.toUtc().toIso8601String(),
    'appProperties': appProperties,
  };
}

/// Minimal in-memory Google Drive v3 `appDataFolder` server for unit tests.
class FakeDriveServer {
  final Map<String, FakeDriveFile> files = {};
  int _nextId = 1;
  String requiredToken = 'tok-1';
  int downloadCount = 0;
  int listCount = 0;

  MockClient client() => MockClient(_handle);

  Future<http.Response> _handle(http.Request req) async {
    if (req.headers['Authorization'] != 'Bearer $requiredToken') {
      return http.Response('{"error":"unauthorized"}', 401);
    }
    final path = req.url.path;

    // List files
    if (req.method == 'GET' && path == '/drive/v3/files') {
      listCount++;
      final q = req.url.queryParameters['q'] ?? '';
      final matched = files.values.where((f) {
        if (q.contains("name = 'manifest.json'")) {
          return f.name == 'manifest.json';
        }
        return true;
      }).toList();
      return http.Response(
        jsonEncode({'files': matched.map((f) => f.toMeta()).toList()}),
        200,
      );
    }

    // Download file media
    if (req.method == 'GET' &&
        path.startsWith('/drive/v3/files/') &&
        req.url.queryParameters['alt'] == 'media') {
      downloadCount++;
      final id = path.substring('/drive/v3/files/'.length);
      final file = files[id];
      if (file == null) return http.Response('not found', 404);
      return http.Response.bytes(file.bytes, 200);
    }

    // Create multipart
    if (req.method == 'POST' && path == '/upload/drive/v3/files') {
      final parsed = _parseMultipart(req);
      final id = 'f_${_nextId++}';
      final props = <String, String>{};
      final rawProps = parsed.meta['appProperties'];
      if (rawProps is Map) {
        for (final e in rawProps.entries) {
          props['${e.key}'] = '${e.value}';
        }
      }
      final file = FakeDriveFile(
        id: id,
        name: parsed.meta['name'] as String,
        bytes: parsed.payload,
        modifiedTime: DateTime.now().toUtc(),
        appProperties: props,
      );
      files[id] = file;
      return http.Response(jsonEncode(file.toMeta()), 200);
    }

    // Update multipart
    if (req.method == 'PATCH' && path.startsWith('/upload/drive/v3/files/')) {
      final id = path.substring('/upload/drive/v3/files/'.length);
      final file = files[id];
      if (file == null) return http.Response('not found', 404);
      final parsed = _parseMultipart(req);
      file.bytes = parsed.payload;
      file.modifiedTime = DateTime.now().toUtc();
      final rawProps = parsed.meta['appProperties'];
      if (rawProps is Map) {
        for (final e in rawProps.entries) {
          file.appProperties['${e.key}'] = '${e.value}';
        }
      }
      return http.Response(jsonEncode(file.toMeta()), 200);
    }

    // Delete file
    if (req.method == 'DELETE' && path.startsWith('/drive/v3/files/')) {
      final id = path.substring('/drive/v3/files/'.length);
      files.remove(id);
      return http.Response('', 204);
    }

    return http.Response('Unhandled ${req.method} $path', 400);
  }

  ({Map<String, dynamic> meta, Uint8List payload}) _parseMultipart(
    http.Request req,
  ) {
    final ct = req.headers['Content-Type'] ?? '';
    final boundary = ct.split('boundary=').last.trim();
    final delim = utf8.encode('--$boundary');
    final bytes = req.bodyBytes;
    final positions = <int>[];
    for (var i = 0; i <= bytes.length - delim.length; i++) {
      var match = true;
      for (var j = 0; j < delim.length; j++) {
        if (bytes[i + j] != delim[j]) {
          match = false;
          break;
        }
      }
      if (match) positions.add(i);
    }
    expect(positions.length, greaterThanOrEqualTo(3));

    Uint8List extractPart(int startIdx, int endIdx) {
      final slice = bytes.sublist(startIdx + delim.length, endIdx);
      final sep = utf8.encode('\r\n\r\n');
      var headerEnd = -1;
      for (var i = 0; i <= slice.length - sep.length; i++) {
        if (slice[i] == 13 &&
            slice[i + 1] == 10 &&
            slice[i + 2] == 13 &&
            slice[i + 3] == 10) {
          headerEnd = i + 4;
          break;
        }
      }
      var bodyEnd = slice.length;
      if (bodyEnd >= 2 &&
          slice[bodyEnd - 2] == 13 &&
          slice[bodyEnd - 1] == 10) {
        bodyEnd -= 2;
      }
      return Uint8List.fromList(slice.sublist(headerEnd, bodyEnd));
    }

    final metaBytes = extractPart(positions[0], positions[1]);
    final payloadBytes = extractPart(positions[1], positions[2]);
    return (
      meta: Map<String, dynamic>.from(
        jsonDecode(utf8.decode(metaBytes)) as Map,
      ),
      payload: payloadBytes,
    );
  }
}

void main() {
  test('write, update, read, listPrefix, and delete in appDataFolder', () async {
    final server = FakeDriveServer();
    final auth = _FakeDriveAuth();
    final storage = GoogleDriveStorage(auth: auth, httpClient: server.client());

    await storage.ensureReady();
    await storage.writeString(
      'manifest.json',
      '{"app":"chronicle-data","formatVersion":1,"exportedAt":12345}',
      properties: {'exportedAt': '12345'},
    );
    final blob = Uint8List.fromList([0, 1, 2, 255, 128, 42]);
    await storage.writeBytes('files/notes_a1b2c3d4.bin', blob);

    expect(await storage.fileSize('files/notes_a1b2c3d4.bin'), blob.length);
    expect(await storage.readBytes('files/notes_a1b2c3d4.bin'), equals(blob));

    final listed = await storage.listPrefix('files');
    expect(listed.map((e) => e.path), ['files/notes_a1b2c3d4.bin']);

    // Update existing file in place (same file ID, no duplicate).
    await storage.writeString(
      'manifest.json',
      '{"app":"chronicle-data","formatVersion":1,"exportedAt":99999}',
      properties: {'exportedAt': '99999'},
    );
    expect(
      server.files.values.where((f) => f.name == 'manifest.json').length,
      1,
    );

    // Fast manifest check uses appProperties without downloading file body.
    final downloadsBefore = server.downloadCount;
    expect(await storage.fastManifestExportedAt(), 99999);
    expect(server.downloadCount, downloadsBefore);

    await storage.delete('files/notes_a1b2c3d4.bin');
    expect(await storage.readBytes('files/notes_a1b2c3d4.bin'), isNull);
  });

  test('picks newest duplicate on read and cleans up older duplicate on write', () async {
    final server = FakeDriveServer();
    server.files['old'] = FakeDriveFile(
      id: 'old',
      name: 'classes.json',
      bytes: Uint8List.fromList(utf8.encode('["old"]')),
      modifiedTime: DateTime.utc(2026, 1, 1),
    );
    server.files['new'] = FakeDriveFile(
      id: 'new',
      name: 'classes.json',
      bytes: Uint8List.fromList(utf8.encode('["new"]')),
      modifiedTime: DateTime.utc(2026, 2, 1),
    );

    final storage = GoogleDriveStorage(
      auth: _FakeDriveAuth(),
      httpClient: server.client(),
    );
    await storage.ensureReady();
    expect(await storage.readString('classes.json'), '["new"]');

    await storage.writeString('classes.json', '["updated"]');
    expect(server.files.containsKey('old'), isFalse);
    expect(server.files.containsKey('new'), isTrue);
  });

  test('retries once on HTTP 401 after refreshing token', () async {
    final server = FakeDriveServer()..requiredToken = 'tok-2';
    final auth = _FakeDriveAuth(token: 'tok-1', refreshedToken: 'tok-2');
    final storage = GoogleDriveStorage(auth: auth, httpClient: server.client());

    await storage.ensureReady();
    expect(auth.refreshCalls, 1);
  });

  test('throws gdrive-auth-expired when refresh also fails', () async {
    final server = FakeDriveServer()..requiredToken = 'tok-valid';
    final auth = _FakeDriveAuth(token: 'tok-stale', refreshedToken: null);
    final storage = GoogleDriveStorage(auth: auth, httpClient: server.client());

    await expectLater(
      storage.ensureReady(),
      throwsA(
        isA<GoogleDriveAuthException>().having(
          (e) => e.code,
          'code',
          'gdrive-auth-expired',
        ),
      ),
    );
  });
}
