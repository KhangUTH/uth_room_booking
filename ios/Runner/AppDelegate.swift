import AVFoundation
import Flutter
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    let channel = FlutterMethodChannel(
      name: "uth_room_booking/app_settings",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    channel.setMethodCallHandler { call, result in
      if call.method == "requestOnFirstLaunch" {
        Task { @MainActor in
          await Self.requestFirstLaunchPermissions()
          result(true)
        }
        return
      }
      guard call.method == "open" else {
        result(FlutterMethodNotImplemented)
        return
      }
      guard let settings = URL(string: UIApplication.openSettingsURLString) else {
        result(false)
        return
      }
      UIApplication.shared.open(settings, options: [:]) { opened in
        result(opened)
      }
    }
  }

  @MainActor
  private static func requestFirstLaunchPermissions() async {
    let preferences = UserDefaults.standard
    let firstLaunchKey = "initial_permissions_requested"
    guard !preferences.bool(forKey: firstLaunchKey) else { return }
    preferences.set(true, forKey: firstLaunchKey)

    let notifications = UNUserNotificationCenter.current()
    let settings = await notifications.notificationSettings()
    if settings.authorizationStatus == .notDetermined {
      _ = try? await notifications.requestAuthorization(options: [.alert, .badge, .sound])
    }
    if AVCaptureDevice.authorizationStatus(for: .video) == .notDetermined {
      _ = await AVCaptureDevice.requestAccess(for: .video)
    }
  }
}
