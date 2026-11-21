import 'package:flutter/services.dart';

abstract final class AppPermissions {
  static const _channel = MethodChannel('uth_room_booking/app_settings');

  static Future<void> requestOnFirstLaunch() async {
    await _invoke('requestOnFirstLaunch');
  }

  static Future<bool> openSettings() => _invoke('open');

  static Future<String?> androidPushToken() =>
      _channel.invokeMethod<String>('pushToken');

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

  static Future<bool> _invoke(String method) async {
    try {
      return await _channel.invokeMethod<bool>(method) ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }
}
