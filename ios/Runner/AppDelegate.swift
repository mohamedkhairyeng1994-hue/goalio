import Flutter
import UIKit
import AppTrackingTransparency

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(handleActivation),
      name: UIApplication.didBecomeActiveNotification,
      object: nil
    )
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(handleActivation),
      name: UIScene.didActivateNotification,
      object: nil
    )
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // ATT must be requested while the app is genuinely .active, otherwise iOS
  // silently no-ops without showing the dialog — that is what App Review hit
  // on iPadOS 26.4.2 with the previous Flutter post-frame approach.
  @objc private func handleActivation() {
    if #available(iOS 14, *) {
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
        guard UIApplication.shared.applicationState == .active else { return }
        guard ATTrackingManager.trackingAuthorizationStatus == .notDetermined else { return }
        ATTrackingManager.requestTrackingAuthorization { _ in }
      }
    }
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "GoalioWidgetBridge") {
      WidgetBridge.register(with: registrar)
    }
  }
}
