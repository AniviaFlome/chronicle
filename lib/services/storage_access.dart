import 'dart:io';

import 'package:flutter/services.dart';

/// Raw-filesystem access to a user-picked folder on Android (All-files
/// access via system Settings; native side in MainActivity).
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
