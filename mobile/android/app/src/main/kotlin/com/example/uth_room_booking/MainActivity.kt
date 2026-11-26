package com.example.uth_room_booking

import android.Manifest
import android.app.Notification
import android.app.NotificationManager
import android.app.NotificationChannel
import android.app.PendingIntent
import android.content.ActivityNotFoundException
import android.content.Intent
import android.content.pm.PackageManager
import android.graphics.drawable.Icon
import android.net.Uri
import android.os.Build
import android.provider.Settings
import com.google.firebase.messaging.FirebaseMessaging
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var notificationChannel: MethodChannel? = null

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        if (intent.hasExtra("uth_notice_id")) notificationChannel?.invokeMethod("noticeTapped", null)
    }
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            getSystemService(NotificationManager::class.java).createNotificationChannels(
                listOf(
                    NotificationChannel("uth_updates", "Thông báo UTH Lab", NotificationManager.IMPORTANCE_DEFAULT),
                    NotificationChannel("uth_foreground_updates", "Thông báo khi đang mở UTH Lab", NotificationManager.IMPORTANCE_HIGH)
                )
            )
        }
        val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "uth_room_booking/app_settings")
        notificationChannel = channel
        channel
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "open" -> result.success(openAppSettings())
                    "takeNoticeId" -> {
                        val id = intent.getStringExtra("uth_notice_id")?.toLongOrNull()
                        intent.removeExtra("uth_notice_id")
                        result.success(id)
                    }
                    "pushToken" -> FirebaseMessaging.getInstance().token.addOnCompleteListener { task ->
                        if (task.isSuccessful) result.success(task.result)
                        else result.error("push_token_failed", null, null)
                    }
                    "showForegroundNotification" -> {
                        val id = call.argument<Number>("id")?.toLong()
                        val title = call.argument<String>("title")
                        val body = call.argument<String>("body")
                        result.success(
                            id != null && title != null && body != null &&
                                showForegroundNotification(id, title, body)
                        )
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

    private fun showForegroundNotification(id: Long, title: String, body: String): Boolean {
        val manager = getSystemService(NotificationManager::class.java)
        if (!manager.areNotificationsEnabled()) return false
        val launchIntent = Intent(this, MainActivity::class.java)
            .addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP)
            .putExtra("uth_notice_id", id.toString())
        val openApp = PendingIntent.getActivity(
            this, id.toInt(), launchIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        val notification = foregroundNotificationBuilder()
            .setLargeIcon(Icon.createWithResource(this, applicationInfo.icon))
            .setContentTitle(title)
            .setContentText(body)
            .setStyle(Notification.BigTextStyle().bigText(body))
            .setContentIntent(openApp)
            .setVisibility(Notification.VISIBILITY_PRIVATE)
            .setPublicVersion(
                foregroundNotificationBuilder()
                    .setContentTitle("UTH Lab")
                    .setContentText("Bạn có thông báo mới.")
                    .build()
            )
            .setOnlyAlertOnce(true)
            .setAutoCancel(true)
            .build()
        manager.notify("uth-notice-$id", 0, notification)
        return true
    }

    @Suppress("DEPRECATION")
    private fun foregroundNotificationBuilder(): Notification.Builder {
        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(this, "uth_foreground_updates")
        } else {
            Notification.Builder(this)
        }
        return builder.setSmallIcon(R.drawable.ic_notification)
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
