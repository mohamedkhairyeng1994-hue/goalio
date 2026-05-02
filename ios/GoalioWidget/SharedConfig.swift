import Foundation

// Edit `appGroup` to match the App Group ID configured in Xcode for both the
// Runner target and the GoalioWidget extension. Same value goes in both
// .entitlements files.
enum SharedConfig {
    static let appGroup = "group.com.example.goalFixturesApp"

    // Fallback — used only if the Flutter app hasn't pushed the URL through
    // the WidgetBridge yet (e.g. the widget loaded before the app opened
    // for the first time). Matches the production branch of
    // ApiConstants.authBaseUrl in lib/core/constants/constants.dart.
    static let defaultBaseURL = "https://goalio.smartoo.site/api"

    // Resolved base URL: prefer whatever the Dart side wrote into the App
    // Group's UserDefaults via WidgetBridge, fall back to the default above.
    // Trailing slashes are stripped so callers can safely append paths with
    // a leading "/" without producing "//widget/matches".
    static var baseURL: String {
        let raw = UserDefaults.widgetShared.string(forKey: Keys.baseUrl)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let resolved = (raw?.isEmpty == false ? raw! : defaultBaseURL)
        var trimmed = resolved
        while trimmed.hasSuffix("/") { trimmed.removeLast() }
        return trimmed
    }

    // Keys used to share state between the Flutter app and this widget through
    // the App Group's UserDefaults suite.
    enum Keys {
        // Flutter's `shared_preferences` plugin prefixes keys with `flutter.` in
        // NSUserDefaults. We mirror the same prefix when writing from the
        // Runner side so the contract matches the Android `AuthTokenReader`.
        static let authToken = "flutter.auth_token"
        static let pageIndex = "widget.page_index"
        static let baseUrl   = "widget.base_url"
    }
}

extension UserDefaults {
    static var widgetShared: UserDefaults {
        UserDefaults(suiteName: SharedConfig.appGroup) ?? .standard
    }
}
