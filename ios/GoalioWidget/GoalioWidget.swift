import WidgetKit
import SwiftUI

enum WidgetUiState {
    case content(matches: [Match])
    case noFavorites
    case error(message: String)
}

struct MatchEntry: TimelineEntry {
    let date: Date
    let state: WidgetUiState
    let logos: [String: Data]
    let page: Int
}

struct Provider: TimelineProvider {

    func placeholder(in context: Context) -> MatchEntry {
        MatchEntry(date: Date(), state: .content(matches: []), logos: [:], page: 0)
    }

    func getSnapshot(in context: Context, completion: @escaping (MatchEntry) -> Void) {
        Task {
            let entry = await buildEntry()
            completion(entry)
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<MatchEntry>) -> Void) {
        Task {
            let entry = await buildEntry()
            // Mirror the Android `WidgetUpdateWorker` 30-minute refresh cadence.
            let nextRefresh = Date().addingTimeInterval(30 * 60)
            completion(Timeline(entries: [entry], policy: .after(nextRefresh)))
        }
    }

    private func buildEntry() async -> MatchEntry {
        let defaults = UserDefaults.widgetShared
        let force = defaults.bool(forKey: "widget.force_refresh")
        if force { defaults.set(false, forKey: "widget.force_refresh") }

        let page = defaults.integer(forKey: SharedConfig.Keys.pageIndex)

        do {
            let snapshot = try await MatchAPI.fetchMatches(forceRefresh: force)
            if !snapshot.hasFavorites {
                return MatchEntry(date: Date(), state: .noFavorites, logos: [:], page: page)
            }
            let logos = await MatchAPI.preloadLogos(for: snapshot.matches)
            return MatchEntry(
                date: Date(),
                state: .content(matches: snapshot.matches),
                logos: logos,
                page: page
            )
        } catch {
            return MatchEntry(
                date: Date(),
                state: .error(message: friendlyMessage(error)),
                logos: [:],
                page: page
            )
        }
    }

    private func friendlyMessage(_ error: Error) -> String {
        switch error {
        case MatchAPIError.invalidURL:        return "Invalid URL"
        case MatchAPIError.badStatus(let c):  return "HTTP \(c)"
        case MatchAPIError.decoding:          return "Couldn't parse server response"
        case MatchAPIError.transport(let e):  return e.localizedDescription
        default:                              return error.localizedDescription
        }
    }
}

struct GoalioWidget: Widget {
    let kind = "GoalioWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            GoalioWidgetEntryView(entry: entry)
                .containerBackground(WidgetTheme.surface, for: .widget)
        }
        .configurationDisplayName("Goalio")
        .description("Latest matches for your favorite teams.")
        .supportedFamilies([.systemMedium, .systemLarge])
        .contentMarginsDisabled()
    }
}
