import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/repositories.dart';
import 'gdrive_config.dart';

/// Signed-in Google account summary shown in Settings.
class GoogleDriveAccount {
  final String email;
  final String? displayName;

  const GoogleDriveAccount({required this.email, this.displayName});
}

/// Structured auth error with a stable [code] for localized UI messages.
class GoogleDriveAuthException implements Exception {
  final String code;
  final String message;

  const GoogleDriveAuthException(this.code, this.message);

  @override
  String toString() => '$code: $message';
}

/// Platform-abstracted Google Drive authentication & token provider.
abstract class GoogleDriveAuth {
  /// True when OAuth configuration is present on this platform (always true
  /// on Android; on Linux requires built-in or user-supplied client ID).
  Future<bool> isConfigured();

  /// Currently signed-in account, or null when signed out.
  Future<GoogleDriveAccount?> currentAccount();

  /// Runs the interactive sign-in + Drive scope consent flow.
  /// Returns null when the user cancels.
  Future<GoogleDriveAccount?> signIn();

  /// Signs out and clears cached tokens.
  Future<void> signOut();

  /// Returns a valid OAuth 2.0 Bearer access token silently (no UI), or null
  /// when signed out or re-authentication is required.
  Future<String?> getAccessToken({bool forceRefresh = false});
}

/// Native Android Google Sign-In using `google_sign_in` v7 (Credential Manager
/// + Play Services account picker + `authorizationClient`).
class AndroidGoogleDriveAuth implements GoogleDriveAuth {
  final SettingsRepository settings;
  bool _initialized = false;
  GoogleSignInAccount? _cachedAccount;

  AndroidGoogleDriveAuth(this.settings);

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    await GoogleSignIn.instance.initialize();
    _initialized = true;
  }

  @override
  Future<bool> isConfigured() async => true;

  @override
  Future<GoogleDriveAccount?> currentAccount() async {
    if (_cachedAccount != null) {
      return GoogleDriveAccount(
        email: _cachedAccount!.email,
        displayName: _cachedAccount!.displayName,
      );
    }
    final email = await settings.gdriveEmail();
    if (email == null || email.isEmpty) return null;
    return GoogleDriveAccount(email: email);
  }

  @override
  Future<GoogleDriveAccount?> signIn() async {
    await _ensureInitialized();
    try {
      final user = await GoogleSignIn.instance.authenticate(
        scopeHint: const [driveAppdataScope],
      );
      final authClient = GoogleSignIn.instance.authorizationClient;
      var auth = await authClient.authorizationForScopes(
        const [driveAppdataScope],
      );
      auth ??= await authClient.authorizeScopes(const [driveAppdataScope]);
      if (auth.accessToken.isEmpty) {
        throw const GoogleDriveAuthException(
          'gdrive-auth-failed',
          'Empty access token returned',
        );
      }
      _cachedAccount = user;
      await settings.setGdriveEmail(user.email);
      return GoogleDriveAccount(
        email: user.email,
        displayName: user.displayName,
      );
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) return null;
      throw GoogleDriveAuthException('gdrive-auth-failed', '${e.description ?? e.code}');
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _ensureInitialized();
      await GoogleSignIn.instance.signOut();
    } catch (e) {
      debugPrint('AndroidGoogleDriveAuth.signOut failed: $e');
    }
    _cachedAccount = null;
    await settings.setGdriveEmail(null);
  }

  @override
  Future<String?> getAccessToken({bool forceRefresh = false}) async {
    final email = await settings.gdriveEmail();
    if (email == null || email.isEmpty) return null;
    try {
      await _ensureInitialized();
      _cachedAccount ??= await GoogleSignIn.instance
          .attemptLightweightAuthentication();
      final auth = await GoogleSignIn.instance.authorizationClient
          .authorizationForScopes(const [driveAppdataScope]);
      final token = auth?.accessToken;
      return (token != null && token.isNotEmpty) ? token : null;
    } catch (e) {
      debugPrint('AndroidGoogleDriveAuth.getAccessToken failed: $e');
      return null;
    }
  }
}

/// Linux desktop Google Sign-In using OAuth 2.0 Authorization Code + PKCE
/// over an ephemeral localhost loopback HTTP server.
///
/// Tokens are stored in `<appSupportDir>/gdrive_auth.json` with `0600`
/// permissions so no `libsecret` / keyring daemon dependency is required.
class LinuxGoogleDriveAuth implements GoogleDriveAuth {
  final SettingsRepository settings;
  final http.Client _http;
  final Directory? storageRoot;
  final Future<bool> Function(Uri url) _launchUrl;
  final Duration authTimeout;
  Future<String?>? _refreshInFlight;

  static const _httpTimeout = Duration(seconds: 20);
  static const _revokeTimeout = Duration(seconds: 10);
  static int _tmpCounter = 0;

  static final _authEndpoint = Uri.parse(
    'https://accounts.google.com/o/oauth2/v2/auth',
  );
  static final _tokenEndpoint = Uri.parse(
    'https://oauth2.googleapis.com/token',
  );
  static final _revokeEndpoint = Uri.parse(
    'https://oauth2.googleapis.com/revoke',
  );
  static final _userInfoEndpoint = Uri.parse(
    'https://www.googleapis.com/oauth2/v2/userinfo',
  );

  LinuxGoogleDriveAuth(
    this.settings, {
    http.Client? httpClient,
    this.storageRoot,
    Future<bool> Function(Uri url)? launchUrlFn,
    this.authTimeout = const Duration(minutes: 3),
  }) : _http = httpClient ?? http.Client(),
       _launchUrl =
           launchUrlFn ??
           ((uri) => launchUrl(uri, mode: LaunchMode.externalApplication));

  /// Generates a 43-char URL-safe PKCE `code_verifier` (RFC 7636).
  static String generateCodeVerifier([Random? rng]) {
    final random = rng ?? Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    return base64UrlEncode(bytes).replaceAll('=', '');
  }

  /// Computes the S256 PKCE `code_challenge` for [verifier].
  static String codeChallengeFor(String verifier) {
    final digest = sha256.convert(utf8.encode(verifier));
    return base64UrlEncode(digest.bytes).replaceAll('=', '');
  }

  /// Extracts the `email` claim from a JWT `id_token` without verifying the
  /// signature (token was just received over TLS directly from Google).
  static String? emailFromIdToken(String? idToken) {
    if (idToken == null || idToken.isEmpty) return null;
    final parts = idToken.split('.');
    if (parts.length < 2) return null;
    try {
      final normalized = base64Url.normalize(parts[1]);
      final decoded = jsonDecode(utf8.decode(base64Url.decode(normalized)));
      if (decoded is Map && decoded['email'] is String) {
        final email = (decoded['email'] as String).trim();
        return email.isEmpty ? null : email;
      }
    } catch (_) {}
    return null;
  }

  Future<File> _tokenFile() async {
    final base = storageRoot ?? await getApplicationSupportDirectory();
    return File('${base.path}/gdrive_auth.json');
  }

  Future<Map<String, dynamic>?> _readTokens() async {
    try {
      final file = await _tokenFile();
      if (!await file.exists()) return null;
      final decoded = jsonDecode(await file.readAsString());
      return decoded is Map ? Map<String, dynamic>.from(decoded) : null;
    } catch (_) {
      return null;
    }
  }

  Future<void> _writeTokens(Map<String, dynamic> data) async {
    final file = await _tokenFile();
    if (!await file.parent.exists()) {
      await file.parent.create(recursive: true);
    }
    // Unique temp file avoids collisions across concurrent writes; chmod 0600
    // BEFORE writing token bytes closes the world-readable TOCTOU window.
    final seq = _tmpCounter++;
    final nonce = Random.secure().nextInt(1 << 30);
    final tmp = File('${file.path}.$pid.$seq.$nonce.tmp');
    try {
      await tmp.create();
      if (!Platform.isWindows) {
        try {
          await Process.run('chmod', ['600', tmp.path]);
        } catch (_) {}
      }
      await tmp.writeAsString(jsonEncode(data));
      await tmp.rename(file.path);
    } catch (_) {
      try {
        if (await tmp.exists()) await tmp.delete();
      } catch (_) {}
      rethrow;
    }
  }

  @override
  Future<bool> isConfigured() async {
    final creds = await resolveLinuxDriveCredentials(settings);
    return creds.isConfigured;
  }

  @override
  Future<GoogleDriveAccount?> currentAccount() async {
    final tokens = await _readTokens();
    if (tokens == null) return null;
    final hasToken =
        (tokens['refreshToken'] as String? ?? '').isNotEmpty ||
        (tokens['accessToken'] as String? ?? '').isNotEmpty;
    if (!hasToken) return null;
    final email =
        (tokens['email'] as String?) ?? await settings.gdriveEmail();
    if (email == null || email.isEmpty) return null;
    return GoogleDriveAccount(email: email);
  }

  @override
  Future<GoogleDriveAccount?> signIn() async {
    final creds = await resolveLinuxDriveCredentials(settings);
    if (!creds.isConfigured) {
      throw const GoogleDriveAuthException(
        'gdrive-not-configured',
        'Google Drive OAuth Client ID is not configured.',
      );
    }

    final verifier = generateCodeVerifier();
    final challenge = codeChallengeFor(verifier);
    final state = generateCodeVerifier();

    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final redirectUri = 'http://127.0.0.1:${server.port}/callback';
    final callbackCompleter =
        Completer<({String? code, GoogleDriveAuthException? error})>();

    final sub = server.listen((request) async {
      if (request.uri.path != '/callback') {
        request.response
          ..statusCode = HttpStatus.notFound
          ..close();
        return;
      }
      final params = request.uri.queryParameters;
      final returnedState = params['state'];
      final error = params['error'];
      final code = params['code'];

      String html;
      if (returnedState != state) {
        html = _callbackHtml(
          'Sign-in failed',
          'State verification failed. Please close this tab and try again in Chronicle.',
        );
        if (!callbackCompleter.isCompleted) {
          callbackCompleter.complete((
            code: null,
            error: const GoogleDriveAuthException(
              'gdrive-auth-failed',
              'OAuth state mismatch',
            ),
          ));
        }
      } else if (error != null) {
        html = _callbackHtml(
          'Sign-in cancelled',
          'You can close this tab and return to Chronicle.',
        );
        if (!callbackCompleter.isCompleted) {
          callbackCompleter.complete((
            code: null,
            error: error == 'access_denied'
                ? null
                : GoogleDriveAuthException('gdrive-auth-failed', error),
          ));
        }
      } else if (code != null && code.isNotEmpty) {
        html = _callbackHtml(
          'Signed in to Chronicle',
          'You can close this tab and return to Chronicle.',
        );
        if (!callbackCompleter.isCompleted) {
          callbackCompleter.complete((code: code, error: null));
        }
      } else {
        html = _callbackHtml(
          'Sign-in failed',
          'No authorization code received. Close this tab and try again.',
        );
        if (!callbackCompleter.isCompleted) {
          callbackCompleter.complete((
            code: null,
            error: const GoogleDriveAuthException(
              'gdrive-auth-failed',
              'Missing authorization code',
            ),
          ));
        }
      }

      request.response
        ..statusCode = HttpStatus.ok
        ..headers.contentType = ContentType.html
        ..write(html);
      await request.response.close();
    });

    try {
      final authUri = _authEndpoint.replace(
        queryParameters: {
          'client_id': creds.clientId,
          'redirect_uri': redirectUri,
          'response_type': 'code',
          'scope': '$driveAppdataScope openid email',
          'code_challenge': challenge,
          'code_challenge_method': 'S256',
          'state': state,
          'access_type': 'offline',
          'prompt': 'consent',
        },
      );
      final launched = await _launchUrl(authUri);
      if (!launched) {
        throw const GoogleDriveAuthException(
          'gdrive-auth-failed',
          'Could not open browser for Google sign-in.',
        );
      }

      final outcome = await callbackCompleter.future.timeout(
        authTimeout,
        onTimeout: () => throw const GoogleDriveAuthException(
          'gdrive-auth-timeout',
          'Sign-in timed out waiting for browser callback.',
        ),
      );
      if (outcome.error != null) throw outcome.error!;
      if (outcome.code == null) return null;

      return await _exchangeCode(
        code: outcome.code!,
        verifier: verifier,
        redirectUri: redirectUri,
        creds: creds,
      );
    } finally {
      await sub.cancel();
      await server.close(force: true);
    }
  }

  Future<GoogleDriveAccount> _exchangeCode({
    required String code,
    required String verifier,
    required String redirectUri,
    required GoogleDriveOAuthCredentials creds,
  }) async {
    final body = <String, String>{
      'client_id': creds.clientId,
      'code': code,
      'code_verifier': verifier,
      'grant_type': 'authorization_code',
      'redirect_uri': redirectUri,
    };
    if (creds.clientSecret.isNotEmpty) {
      body['client_secret'] = creds.clientSecret;
    }
    final res = await _http.post(_tokenEndpoint, body: body).timeout(_httpTimeout);
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw GoogleDriveAuthException(
        'gdrive-auth-failed',
        'Token exchange failed (${res.statusCode})',
      );
    }
    final data = Map<String, dynamic>.from(jsonDecode(res.body) as Map);
    final accessToken = data['access_token'] as String? ?? '';
    final refreshToken = data['refresh_token'] as String? ?? '';
    final expiresIn = (data['expires_in'] as num?)?.toInt() ?? 3600;
    if (accessToken.isEmpty) {
      throw const GoogleDriveAuthException(
        'gdrive-auth-failed',
        'No access_token in response',
      );
    }

    var email = emailFromIdToken(data['id_token'] as String?);
    if (email == null || email.isEmpty) {
      email = await _fetchUserEmail(accessToken) ?? 'Google Drive';
    }
    final expiresAtMs =
        DateTime.now().millisecondsSinceEpoch + expiresIn * 1000;
    await _writeTokens({
      'accessToken': accessToken,
      'refreshToken': refreshToken,
      'expiresAtMs': expiresAtMs,
      'email': email,
    });
    await settings.setGdriveEmail(email);
    return GoogleDriveAccount(email: email);
  }

  Future<String?> _fetchUserEmail(String accessToken) async {
    try {
      final res = await _http
          .get(
            _userInfoEndpoint,
            headers: {'Authorization': 'Bearer $accessToken'},
          )
          .timeout(_httpTimeout);
      if (res.statusCode >= 200 && res.statusCode < 300) {
        final decoded = jsonDecode(res.body);
        if (decoded is Map && decoded['email'] is String) {
          return decoded['email'] as String;
        }
      }
    } catch (_) {}
    return null;
  }

  @override
  Future<String?> getAccessToken({bool forceRefresh = false}) async {
    final tokens = await _readTokens();
    if (tokens == null) return null;
    final accessToken = tokens['accessToken'] as String? ?? '';
    final expiresAtMs = (tokens['expiresAtMs'] as num?)?.toInt() ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    if (!forceRefresh && accessToken.isNotEmpty && expiresAtMs > now + 60000) {
      return accessToken;
    }

    // Single-flight refresh: concurrent Drive uploads/downloads share one
    // `/token` exchange instead of racing on the token file.
    final inflight = _refreshInFlight;
    if (inflight != null) return inflight;

    final future = _refreshAccessToken(tokens, now).whenComplete(() {
      _refreshInFlight = null;
    });
    _refreshInFlight = future;
    return future;
  }

  Future<String?> _refreshAccessToken(
    Map<String, dynamic> tokens,
    int now,
  ) async {
    final refreshToken = tokens['refreshToken'] as String? ?? '';
    if (refreshToken.isEmpty) return null;

    final creds = await resolveLinuxDriveCredentials(settings);
    if (!creds.isConfigured) return null;

    final body = <String, String>{
      'client_id': creds.clientId,
      'refresh_token': refreshToken,
      'grant_type': 'refresh_token',
    };
    if (creds.clientSecret.isNotEmpty) {
      body['client_secret'] = creds.clientSecret;
    }
    try {
      final res = await _http
          .post(_tokenEndpoint, body: body)
          .timeout(_httpTimeout);
      if (res.statusCode < 200 || res.statusCode >= 300) {
        debugPrint('LinuxGoogleDriveAuth: refresh failed (${res.statusCode})');
        return null;
      }
      final data = Map<String, dynamic>.from(jsonDecode(res.body) as Map);
      final newAccess = data['access_token'] as String? ?? '';
      final expiresIn = (data['expires_in'] as num?)?.toInt() ?? 3600;
      if (newAccess.isEmpty) return null;
      await _writeTokens({
        ...tokens,
        'accessToken': newAccess,
        if (data['refresh_token'] is String &&
            (data['refresh_token'] as String).isNotEmpty)
          'refreshToken': data['refresh_token'],
        'expiresAtMs': now + expiresIn * 1000,
      });
      return newAccess;
    } catch (e) {
      debugPrint('LinuxGoogleDriveAuth: refresh error: $e');
      return null;
    }
  }

  @override
  Future<void> signOut() async {
    final tokens = await _readTokens();
    final tokenToRevoke =
        (tokens?['refreshToken'] as String?) ??
        (tokens?['accessToken'] as String?);
    if (tokenToRevoke != null && tokenToRevoke.isNotEmpty) {
      try {
        // RFC 7009: pass token in POST form body, never in URL query string.
        await _http
            .post(_revokeEndpoint, body: {'token': tokenToRevoke})
            .timeout(_revokeTimeout);
      } catch (_) {}
    }
    try {
      final file = await _tokenFile();
      if (await file.exists()) await file.delete();
    } catch (_) {}
    await settings.setGdriveEmail(null);
  }

  static String _callbackHtml(String title, String body) =>
      '<!doctype html><html><head><meta charset="utf-8">'
      '<title>$title</title>'
      '<style>body{font-family:system-ui,sans-serif;display:flex;'
      'align-items:center;justify-content:center;min-height:100vh;'
      'margin:0;background:#111;color:#eee;}'
      '.card{padding:2rem 2.5rem;border-radius:12px;background:#1d1d1d;'
      'text-align:center;max-width:420px;}</style></head>'
      '<body><div class="card"><h2>$title</h2><p>$body</p></div></body></html>';
}

/// Safe no-op auth provider for unsupported platforms or hermetic tests.
class UnsupportedGoogleDriveAuth implements GoogleDriveAuth {
  const UnsupportedGoogleDriveAuth();

  @override
  Future<bool> isConfigured() async => false;

  @override
  Future<GoogleDriveAccount?> currentAccount() async => null;

  @override
  Future<GoogleDriveAccount?> signIn() async => null;

  @override
  Future<void> signOut() async {}

  @override
  Future<String?> getAccessToken({bool forceRefresh = false}) async => null;
}
