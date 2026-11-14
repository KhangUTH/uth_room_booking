package com.example.uth_room_booking

import android.Manifest
import android.content.ActivityNotFoundException
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "uth_room_booking/app_settings")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "open" -> result.success(openAppSettings())
                    "requestOnFirstLaunch" -> {
                        requestFirstLaunchPermissions()
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun openAppSettings(): Boolean {
        val intent = Intent(
            Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
            Uri.fromParts("package", packageName, null)
        )
        return try {
            startActivity(intent)
            true
        } catch (_: ActivityNotFoundException) {
            false
        }
    }

    private fun requestFirstLaunchPermissions() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) return
        val preferences = getSharedPreferences("app_permissions", MODE_PRIVATE)
        val firstLaunchKey = "initial_permissions_requested"
        if (preferences.getBoolean(firstLaunchKey, false)) return

        val permissions = buildList {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                add(Manifest.permission.POST_NOTIFICATIONS)
            }
            add(Manifest.permission.CAMERA)
        }.filter { checkSelfPermission(it) != PackageManager.PERMISSION_GRANTED }

        if (permissions.isNotEmpty()) requestPermissions(permissions.toTypedArray(), 1001)
        preferences.edit().putBoolean(firstLaunchKey, true).apply()
    }
}
