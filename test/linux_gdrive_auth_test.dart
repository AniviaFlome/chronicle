import 'dart:convert';
import 'dart:io';

import 'package:chronicle/data/database.dart';
import 'package:chronicle/data/repositories.dart';
import 'package:chronicle/services/gdrive_auth.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

String _fakeIdToken(String email) {
  final header = base64UrlEncode(utf8.encode('{"alg":"none"}')).replaceAll('=', '');
  final payload = base64UrlEncode(
    utf8.encode(jsonEncode({'email': email})),
  ).replaceAll('=', '');
  return '$header.$payload.sig';
}

void main() {
  test('PKCE verifier/challenge and id_token email extraction', () {
    final v = LinuxGoogleDriveAuth.generateCodeVerifier();
    expect(v.length, 43);
    expect(v.contains('='), isFalse);
    final c = LinuxGoogleDriveAuth.codeChallengeFor(v);
    expect(c.length, 43);
    expect(c, isNot(v));

    expect(
      LinuxGoogleDriveAuth.emailFromIdToken(_fakeIdToken('alice@example.com')),
      'alice@example.com',
    );
    expect(LinuxGoogleDriveAuth.emailFromIdToken('not-a-jwt'), isNull);
  });

  test('LinuxGoogleDriveAuth loopback sign-in, token refresh, and sign-out', () async {
    final tmpDir = await Directory.systemTemp.createTemp('chronicle_auth_');
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(() async {
      await db.close();
      if (await tmpDir.exists()) await tmpDir.delete(recursive: true);
    });

    final settings = SettingsRepository(db);
    await settings.setGdriveCustomClientId('test-client-id');
    await settings.setGdriveCustomClientSecret('test-client-secret');

    var refreshCount = 0;
    var revokeCalled = false;
    final mockHttp = MockClient((req) async {
      if (req.url.path == '/token') {
        final fields = req.bodyFields;
        if (fields['grant_type'] == 'authorization_code') {
          expect(fields['code'], 'auth-code-123');
          expect(fields['client_id'], 'test-client-id');
          expect(fields['code_verifier'], isNotEmpty);
          return http.Response(
            jsonEncode({
              'access_token': 'access-initial',
              'refresh_token': 'refresh-xyz',
              'expires_in': 3600,
              'id_token': _fakeIdToken('linux@example.com'),
            }),
            200,
          );
        }
        if (fields['grant_type'] == 'refresh_token') {
          refreshCount++;
          expect(fields['refresh_token'], 'refresh-xyz');
          return http.Response(
            jsonEncode({
              'access_token': 'access-refreshed',
              'expires_in': 3600,
            }),
            200,
          );
        }
      }
      if (req.url.path == '/revoke') {
        revokeCalled = true;
        return http.Response('', 200);
      }
      return http.Response('unexpected', 400);
    });

    final auth = LinuxGoogleDriveAuth(
      settings,
      httpClient: mockHttp,
      storageRoot: tmpDir,
      launchUrlFn: (authUri) async {
        // Simulate browser redirecting back to our localhost loopback server.
        final redirect = Uri.parse(authUri.queryParameters['redirect_uri']!);
        final state = authUri.queryParameters['state']!;
        final callback = redirect.replace(
          queryParameters: {'code': 'auth-code-123', 'state': state},
        );
        final client = HttpClient();
        final req = await client.getUrl(callback);
        final res = await req.close();
        expect(res.statusCode, 200);
        client.close();
        return true;
      },
    );

    expect(await auth.isConfigured(), isTrue);
    final account = await auth.signIn();
    expect(account?.email, 'linux@example.com');
    expect(await settings.gdriveEmail(), 'linux@example.com');
    expect(await auth.getAccessToken(), 'access-initial');

    // Force refresh exercises grant_type=refresh_token.
    expect(
      await auth.getAccessToken(forceRefresh: true),
      'access-refreshed',
    );
    expect(refreshCount, 1);

    // Token file exists with 0600 permissions on Linux.
    final tokenFile = File('${tmpDir.path}/gdrive_auth.json');
    expect(await tokenFile.exists(), isTrue);
    if (Platform.isLinux) {
      final mode = (await tokenFile.stat()).mode & 0x1FF;
      expect(mode, 0x180); // 0600
    }

    await auth.signOut();
    expect(revokeCalled, isTrue);
    expect(await tokenFile.exists(), isFalse);
    expect(await settings.gdriveEmail(), isNull);
  });

  test('LinuxGoogleDriveAuth rejects OAuth state mismatch', () async {
    final tmpDir = await Directory.systemTemp.createTemp('chronicle_auth_bad_');
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(() async {
      await db.close();
      if (await tmpDir.exists()) await tmpDir.delete(recursive: true);
    });
    final settings = SettingsRepository(db);
    await settings.setGdriveCustomClientId('test-client-id');

    final auth = LinuxGoogleDriveAuth(
      settings,
      httpClient: MockClient((_) async => http.Response('', 500)),
      storageRoot: tmpDir,
      launchUrlFn: (authUri) async {
        final redirect = Uri.parse(authUri.queryParameters['redirect_uri']!);
        final callback = redirect.replace(
          queryParameters: {'code': 'abc', 'state': 'wrong-state'},
        );
        final client = HttpClient();
        final req = await client.getUrl(callback);
        await req.close();
        client.close();
        return true;
      },
    );

    await expectLater(
      auth.signIn(),
      throwsA(
        isA<GoogleDriveAuthException>().having(
          (e) => e.code,
          'code',
          'gdrive-auth-failed',
        ),
      ),
    );
  });
}
