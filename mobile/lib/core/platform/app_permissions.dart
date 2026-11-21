import 'package:flutter/services.dart';

abstract final class AppPermissions {
  static const _channel = MethodChannel('uth_room_booking/app_settings');

  static Future<void> requestOnFirstLaunch() async {
    await _invoke('requestOnFirstLaunch');
  }

  static Future<bool> openSettings() => _invoke('open');

  static void onNoticeTap(Future<void> Function()? callback) {
    _channel.setMethodCallHandler(
      callback == null
          ? null
          : (call) async {
              if (call.method == 'noticeTapped') await callback();
            },
    );
  }

  static Future<int?> takeNoticeId() async {
    try {
      return await _channel.invokeMethod<int>('takeNoticeId');
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }

  static Future<String?> androidPushToken() =>
      _channel.invokeMethod<String>('pushToken');

  static Future<bool> showForegroundNotification({
    required int id,
    required String title,
    required String body,
  }) => _invoke('showForegroundNotification', {
    'id': id,
    'title': title,
    'body': body,
  });

  static Future<Map<String, String>> readStatuses() async {
    try {
      return await _channel.invokeMapMethod<String, String>('status') ??
          const {};
    } on PlatformException {
      return const {};
    } on MissingPluginException {
      return const {};
    }
  }

  static Future<bool> _invoke(String method, [Object? arguments]) async {
    try {
      return await _channel.invokeMethod<bool>(method, arguments) ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }
}
