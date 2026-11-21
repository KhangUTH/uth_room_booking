package com.example.uth_room_booking

import android.Manifest
import android.app.NotificationManager
import android.app.NotificationChannel
import android.content.ActivityNotFoundException
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.provider.Settings
import com.google.firebase.messaging.FirebaseMessaging
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            getSystemService(NotificationManager::class.java).createNotificationChannel(
                NotificationChannel("uth_updates", "Thông báo UTH Lab", NotificationManager.IMPORTANCE_DEFAULT)
            )
        }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "uth_room_booking/app_settings")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "open" -> result.success(openAppSettings())
                    "pushToken" -> FirebaseMessaging.getInstance().token.addOnCompleteListener { task ->
                        if (task.isSuccessful) result.success(task.result)
                        else result.error("push_token_failed", null, null)
                    }
                    "status" -> result.success(mapOf(
                        "notifications" to if (getSystemService(NotificationManager::class.java)
                                .areNotificationsEnabled()) "granted" else "denied",
                        "camera" to if (checkSelfPermission(Manifest.permission.CAMERA) ==
                                PackageManager.PERMISSION_GRANTED) "granted" else "denied",
                        "photos" to "notRequired"
                    ))
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
