import '../data/repositories.dart';

/// Google Drive hidden app-data folder scope (non-sensitive, private to
/// Chronicle, cannot be accidentally modified by the user in Drive UI).
const String driveAppdataScope =
    'https://www.googleapis.com/auth/drive.appdata';

/// Compile-time Linux Desktop OAuth 2.0 credentials injected via
/// `--dart-define=GOOGLE_DRIVE_LINUX_CLIENT_ID=...` and
/// `--dart-define=GOOGLE_DRIVE_LINUX_CLIENT_SECRET=...` (e.g. in CI).
const String defaultGoogleDriveLinuxClientId = String.fromEnvironment(
  'GOOGLE_DRIVE_LINUX_CLIENT_ID',
);
const String defaultGoogleDriveLinuxClientSecret = String.fromEnvironment(
  'GOOGLE_DRIVE_LINUX_CLIENT_SECRET',
);

/// Resolved Linux OAuth 2.0 Desktop client credentials.
class GoogleDriveOAuthCredentials {
  final String clientId;
  final String clientSecret;
  final bool isCustomOverride;

  const GoogleDriveOAuthCredentials({
    required this.clientId,
    required this.clientSecret,
    this.isCustomOverride = false,
  });

  bool get isConfigured => clientId.trim().isNotEmpty;
}

/// Resolves the effective Linux OAuth credentials: user override stored in
/// Settings takes precedence over compile-time `--dart-define` defaults.
Future<GoogleDriveOAuthCredentials> resolveLinuxDriveCredentials(
  SettingsRepository settings,
) async {
  final customId = (await settings.gdriveCustomClientId())?.trim() ?? '';
  if (customId.isNotEmpty) {
    final customSecret =
        (await settings.gdriveCustomClientSecret())?.trim() ?? '';
    return GoogleDriveOAuthCredentials(
      clientId: customId,
      clientSecret: customSecret,
      isCustomOverride: true,
    );
  }
  return const GoogleDriveOAuthCredentials(
    clientId: defaultGoogleDriveLinuxClientId,
    clientSecret: defaultGoogleDriveLinuxClientSecret,
    isCustomOverride: false,
  );
}
