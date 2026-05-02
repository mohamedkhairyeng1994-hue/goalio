import Flutter
import Foundation
import WidgetKit

// Mirrors flutter.auth_token into the App Group's UserDefaults so the
// GoalioWidget extension can authenticate against /api/widget/matches.
// The App Group ID below MUST match the one set on:
//   - Runner.entitlements
//   - GoalioWidget.entitlements
//   - SharedConfig.swift (in the GoalioWidget target)
enum WidgetBridge {
    static let appGroup = "group.com.example.goalFixturesApp"

    private enum Keys {
        static let authToken = "flutter.auth_token"
        static let baseUrl   = "widget.base_url"
    }

    static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "com.goalio.widget/bridge",
            binaryMessenger: registrar.messenger()
        )
        channel.setMethodCallHandler { call, result in
            switch call.method {
            case "setAuthToken":
                let args = call.arguments as? [String: Any]
                let token = (args?["token"] as? String)?
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                let defaults = UserDefaults(suiteName: appGroup)
                if let token = token, !token.isEmpty {
                    defaults?.set(token, forKey: Keys.authToken)
                } else {
                    defaults?.removeObject(forKey: Keys.authToken)
                }
                if #available(iOS 14.0, *) {
                    WidgetCenter.shared.reloadAllTimelines()
                }
                result(nil)

            case "setBaseUrl":
                let args = call.arguments as? [String: Any]
                let url = (args?["url"] as? String)?
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                let defaults = UserDefaults(suiteName: appGroup)
                if let url = url, !url.isEmpty {
                    defaults?.set(url, forKey: Keys.baseUrl)
                } else {
                    defaults?.removeObject(forKey: Keys.baseUrl)
                }
                if #available(iOS 14.0, *) {
                    WidgetCenter.shared.reloadAllTimelines()
                }
                result(nil)

            case "reloadTimelines":
                if #available(iOS 14.0, *) {
                    WidgetCenter.shared.reloadAllTimelines()
                }
                result(nil)

            default:
                result(FlutterMethodNotImplemented)
            }
        }
    }
}
