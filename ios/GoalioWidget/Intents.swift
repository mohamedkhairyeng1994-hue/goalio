import AppIntents
import WidgetKit

@available(iOS 17.0, *)
struct RefreshIntent: AppIntent {
    static var title: LocalizedStringResource = "Refresh"
    static var description = IntentDescription("Reload the latest matches.")
    static var isDiscoverable = false

    func perform() async throws -> some IntentResult {
        UserDefaults.widgetShared.set(true, forKey: "widget.force_refresh")
        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}

@available(iOS 17.0, *)
struct NextPageIntent: AppIntent {
    static var title: LocalizedStringResource = "Next page"
    static var isDiscoverable = false

    func perform() async throws -> some IntentResult {
        let current = UserDefaults.widgetShared.integer(forKey: SharedConfig.Keys.pageIndex)
        UserDefaults.widgetShared.set(current + 1, forKey: SharedConfig.Keys.pageIndex)
        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}

@available(iOS 17.0, *)
struct PrevPageIntent: AppIntent {
    static var title: LocalizedStringResource = "Previous page"
    static var isDiscoverable = false

    func perform() async throws -> some IntentResult {
        let current = UserDefaults.widgetShared.integer(forKey: SharedConfig.Keys.pageIndex)
        UserDefaults.widgetShared.set(max(0, current - 1), forKey: SharedConfig.Keys.pageIndex)
        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}
