import SwiftUI
import WidgetKit

struct GoalioWidgetEntryView: View {
    let entry: MatchEntry

    var body: some View {
        Link(destination: URL(string: "goalio://home")!) {
            VStack(alignment: .leading, spacing: 12) {
                HeaderView()

                switch entry.state {
                case .noFavorites:
                    NoFavoritesView()
                case .error(let message):
                    ErrorView(message: message)
                case .content(let matches):
                    ContentView(matches: matches, logos: entry.logos, page: entry.page)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(WidgetTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 24))
        }
    }
}

private struct HeaderView: View {
    var body: some View {
        HStack(spacing: 8) {
            Image("WidgetLogo")
                .resizable()
                .frame(width: 24, height: 24)
                .clipShape(RoundedRectangle(cornerRadius: 6))

            Text(WidgetTheme.appName)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(WidgetTheme.textPrimary)

            Spacer()

            if #available(iOS 17.0, *) {
                Button(intent: RefreshIntent()) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(WidgetTheme.accent)
                        .frame(width: 22, height: 22)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

private struct ContentView: View {
    let matches: [Match]
    let logos: [String: Data]
    let page: Int

    var body: some View {
        let yesterday = matches.filter { $0.bucket == .yesterday }
        let today     = matches.filter { $0.bucket == .today }
        let tomorrow  = matches.filter { $0.bucket == .tomorrow }

        // systemLarge has fixed height (~382 pt). After header + footer +
        // section pills + padding, only 4–5 match rows fit. Each visible
        // section pill steals ~1 row of capacity, so shrink pageSize as more
        // sections are active — otherwise the widget overflows and iOS clips
        // the header and pager.
        let activeSections =
            (yesterday.isEmpty ? 0 : 1) +
            (today.isEmpty     ? 0 : 1) +
            (tomorrow.isEmpty  ? 0 : 1)
        let pageSize: Int = {
            switch activeSections {
            case 3:  return 1   // 3 pills + 3 rows = fits
            case 2:  return 2   // 2 pills + 4 rows = fits
            default: return 4   // 1 pill  + 4 rows = fits
            }
        }()

        let totalPages = max(
            1,
            max(
                ceilDiv(yesterday.count, pageSize),
                max(ceilDiv(today.count, pageSize), ceilDiv(tomorrow.count, pageSize))
            )
        )
        let safePage = min(max(0, page), totalPages - 1)

        // Compute the slice we want to render for each bucket on this page.
        // Empty buckets (and empty pages of partially-filled buckets) collapse
        // entirely instead of showing a pill + "No matches" placeholder, so the
        // widget doesn't waste vertical space when one of the days is quiet.
        let yesterdayPage = slice(yesterday, page: safePage, size: pageSize)
        let todayPage     = slice(today,     page: safePage, size: pageSize)
        let tomorrowPage  = slice(tomorrow,  page: safePage, size: pageSize)
        let allEmpty = yesterdayPage.isEmpty && todayPage.isEmpty && tomorrowPage.isEmpty

        VStack(alignment: .leading, spacing: 8) {
            if !yesterdayPage.isEmpty {
                SectionPill(label: "Yesterday")
                ForEach(yesterdayPage, id: \.self) { match in
                    MatchRow(match: match, logos: logos)
                }
            }

            if !todayPage.isEmpty {
                SectionPill(label: "Today")
                ForEach(todayPage, id: \.self) { match in
                    MatchRow(match: match, logos: logos)
                }
            }

            if !tomorrowPage.isEmpty {
                SectionPill(label: "Tomorrow")
                ForEach(tomorrowPage, id: \.self) { match in
                    MatchRow(match: match, logos: logos)
                }
            }

            if allEmpty {
                Spacer()
                EmptyRow(text: "No matches in this period")
                    .frame(maxWidth: .infinity, alignment: .center)
            }

            Spacer(minLength: 0)
            if totalPages > 1 {
                Pager(current: safePage + 1, total: totalPages)
            }
        }
    }

    private func slice(_ list: [Match], page: Int, size: Int) -> [Match] {
        let from = page * size
        guard from < list.count else { return [] }
        let to = min(from + size, list.count)
        return Array(list[from..<to])
    }

    private func ceilDiv(_ a: Int, _ b: Int) -> Int {
        b == 0 ? 0 : (a + b - 1) / b
    }
}

private struct SectionPill: View {
    let label: String

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(WidgetTheme.pill)
            Text(label)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(WidgetTheme.textPrimary)
                .padding(.vertical, 5)
        }
        .frame(maxWidth: .infinity)
        .fixedSize(horizontal: false, vertical: true)
    }
}

private struct MatchRow: View {
    let match: Match
    let logos: [String: Data]

    var body: some View {
        Link(destination: URL(string: "goalio://match?id=\(match.id)")!) {
            HStack(alignment: .center, spacing: 8) {
                TeamSide(name: match.homeTeam, logoData: logos[match.homeLogo], alignEnd: false)
                    .frame(maxWidth: .infinity)

                CenterTime(match: match)
                    .padding(.horizontal, 4)

                TeamSide(name: match.awayTeam, logoData: logos[match.awayLogo], alignEnd: true)
                    .frame(maxWidth: .infinity)
            }
            .padding(.vertical, 6)
        }
    }
}

private struct TeamSide: View {
    let name: String
    let logoData: Data?
    let alignEnd: Bool

    private let logoSize: CGFloat = 18

    var body: some View {
        // Home side (alignEnd=false): crest on the left, name to its right.
        // Away side (alignEnd=true):  name on the left, crest on the right —
        // crests sit at the outer edges of each team's slot, names hug the
        // score in the centre. Mirrors the Android TeamSide layout.
        HStack(alignment: .center, spacing: 6) {
            if alignEnd {
                Text(name)
                    .font(.system(size: 12))
                    .foregroundColor(WidgetTheme.textSecondary)
                    .lineLimit(1)
                    .multilineTextAlignment(.trailing)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                crest
            } else {
                crest
                Text(name)
                    .font(.system(size: 12))
                    .foregroundColor(WidgetTheme.textSecondary)
                    .lineLimit(1)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    @ViewBuilder
    private var crest: some View {
        if let data = logoData, let img = UIImage(data: data) {
            Image(uiImage: img)
                .resizable()
                .scaledToFit()
                .frame(width: logoSize, height: logoSize)
        } else {
            Circle()
                .fill(WidgetTheme.divider)
                .frame(width: logoSize, height: logoSize)
        }
    }
}

private struct CenterTime: View {
    let match: Match

    var body: some View {
        VStack(spacing: 4) {
            if match.hasScore {
                let scoreColor = match.isLive ? WidgetTheme.live : WidgetTheme.textPrimary
                Text("\u{200E}\(match.homeScore ?? "") - \(match.awayScore ?? "")")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(scoreColor)

                if match.isLive {
                    let label: String = {
                        let trimmed = match.time.trimmingCharacters(in: .whitespaces)
                        if !trimmed.isEmpty { return trimmed }
                        return match.status ?? "Live"
                    }()
                    Text("\u{200E}\(label)")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(WidgetTheme.live)
                } else {
                    Text(match.status ?? "FT")
                        .font(.system(size: 10))
                        .foregroundColor(WidgetTheme.textSecondary)
                }
            } else {
                Text("\u{200E}\(match.time)")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(WidgetTheme.textPrimary)
                HStack(spacing: 4) {
                    Image(systemName: "soccerball")
                        .font(.system(size: 10))
                        .foregroundColor(WidgetTheme.textSecondary)
                    Text("-")
                        .font(.system(size: 11))
                        .foregroundColor(WidgetTheme.textSecondary)
                }
            }
        }
    }
}

private struct Pager: View {
    let current: Int
    let total: Int

    var body: some View {
        HStack(spacing: 14) {
            if #available(iOS 17.0, *) {
                Button(intent: PrevPageIntent()) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(WidgetTheme.accent)
                        .frame(width: 20, height: 20)
                }
                .buttonStyle(.plain)
            }

            Text("\(current)/\(total)")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(WidgetTheme.textSecondary)

            if #available(iOS 17.0, *) {
                Button(intent: NextPageIntent()) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(WidgetTheme.accent)
                        .frame(width: 20, height: 20)
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 4)
    }
}

private struct EmptyRow: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(size: 12))
            .foregroundColor(WidgetTheme.textSecondary)
            .padding(.vertical, 8)
    }
}

private struct NoFavoritesView: View {
    var body: some View {
        VStack(spacing: 6) {
            Spacer()
            Text("No favorite teams")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(WidgetTheme.textPrimary)
            Text("Pick favorite teams in the app to see their matches here")
                .font(.system(size: 11))
                .foregroundColor(WidgetTheme.textSecondary)
                .multilineTextAlignment(.center)
                .lineLimit(3)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}

private struct ErrorView: View {
    let message: String

    var body: some View {
        VStack(spacing: 6) {
            Spacer()
            Text("Couldn't load matches")
                .font(.system(size: 13))
                .foregroundColor(WidgetTheme.textPrimary)
            Text(message)
                .font(.system(size: 10))
                .foregroundColor(WidgetTheme.textSecondary)
                .multilineTextAlignment(.center)
                .lineLimit(3)
            if #available(iOS 17.0, *) {
                Button(intent: RefreshIntent()) {
                    Text("Retry")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(WidgetTheme.onAccentText)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 6)
                        .background(WidgetTheme.accent)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}
