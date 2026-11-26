import AVFoundation
import Flutter
import Photos
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
      if call.method == "status" {
        Task { @MainActor in
          let settings = await UNUserNotificationCenter.current().notificationSettings()
          let notifications: String
          switch settings.authorizationStatus {
          case .authorized: notifications = "granted"
          case .provisional, .ephemeral: notifications = "limited"
          default: notifications = "denied"
          }
          let photos: String
          switch PHPhotoLibrary.authorizationStatus(for: .readWrite) {
          case .authorized: photos = "granted"
          case .limited: photos = "limited"
          case .notDetermined: photos = "notRequired"
          default: photos = "denied"
          }
          result([
            "notifications": notifications,
            "camera": AVCaptureDevice.authorizationStatus(for: .video) == .authorized
              ? "granted" : "denied",
            "photos": photos,
            "microphone": AVCaptureDevice.authorizationStatus(for: .audio) == .authorized
              ? "granted" : "denied"
          ])
        }
        return
      }
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
