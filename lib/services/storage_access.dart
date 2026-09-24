import 'dart:io';

import 'package:flutter/services.dart';

/// Raw-filesystem access to a user-picked Syncthing folder on Android.
///
/// The system folder picker only grants SAF URI access, but the data
/// folder sync uses plain `dart:io` file paths. On Android 11+ (API 30)
/// those need the "All files access" grant, which the user enables in
/// system Settings (the permission is declared in AndroidManifest.xml).
/// The native side lives in MainActivity (`chronicle/storage` channel).
class StorageAccessService {
  /// Channel override for tests.
  final MethodChannel channel;

  StorageAccessService([MethodChannel? channelParam])
      : channel = channelParam ?? const MethodChannel('chronicle/storage');

  /// Whether raw file access is currently granted. Always true off
  /// Android (desktop platforms have no scoped storage).
  Future<bool> filesAccessGranted() async {
    if (!Platform.isAndroid) return true;
    try {
      return await channel.invokeMethod<bool>('isFilesAccessGranted') ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Opens the system "All files access" page for Chronicle and returns
  /// the grant state at call time (the user finishes the grant in
  /// Settings afterwards — callers re-check on resume). No-op off
  /// Android.
  Future<bool> requestFilesAccess() async {
    if (!Platform.isAndroid) return true;
    try {
      await channel.invokeMethod<void>('requestFilesAccess');
    } catch (_) {
      // Best-effort: the settings page may still have opened.
    }
    return filesAccessGranted();
  }
}
