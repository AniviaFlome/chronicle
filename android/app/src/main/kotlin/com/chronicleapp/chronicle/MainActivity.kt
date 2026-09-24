package com.chronicleapp.chronicle

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val storageChannel = "chronicle/storage"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, storageChannel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "isFilesAccessGranted" -> result.success(isFilesAccessGranted())
                    "requestFilesAccess" -> {
                        requestFilesAccess()
                        result.success(isFilesAccessGranted())
                    }
                    else -> result.notImplemented()
                }
            }
    }

    /// Raw `dart:io` reads of shared-storage folders need the "All files
    /// access" grant on Android 11+ (API 30). Below that the legacy
    /// storage model applies, so there is nothing to check.
    private fun isFilesAccessGranted(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.R) return true
        return Environment.isExternalStorageManager()
    }

    /// Opens the system "All files access" page for Chronicle. The grant
    /// happens there, after this call returns — callers re-check state
    /// when the app resumes.
    private fun requestFilesAccess() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.R) return
        val intent = try {
            Intent(
                Settings.ACTION_MANAGE_APP_ALL_FILES_ACCESS_PERMISSION,
                Uri.parse("package:$packageName"),
            )
        } catch (_: Exception) {
            Intent(Settings.ACTION_MANAGE_ALL_FILES_ACCESS_PERMISSION)
        }
        startActivity(intent)
    }
}
