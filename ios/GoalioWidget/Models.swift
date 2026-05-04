import Foundation

// JSON contract — must match goalio_backend/app/Http/Controllers/Api/WidgetController.php
struct WidgetResponseDto: Decodable {
    let yesterday: [MatchDto]
    let today: [MatchDto]
    let tomorrow: [MatchDto]
    let hasFavorites: Bool

    enum CodingKeys: String, CodingKey {
        case yesterday, today, tomorrow
        case hasFavorites = "has_favorites"
    }
}

struct MatchDto: Decodable {
    let id: String?
    let homeTeam: String
    let awayTeam: String
    let time: String
    let homeLogo: String
    let awayLogo: String
    let homeScore: String?
    let awayScore: String?
    let status: String?
    let competition: String?

    enum CodingKeys: String, CodingKey {
        case id, time, status, competition
        case homeTeam  = "home_team"
        case awayTeam  = "away_team"
        case homeLogo  = "home_logo"
        case awayLogo  = "away_logo"
        case homeScore = "home_score"
        case awayScore = "away_score"
    }
}

struct Match: Hashable {
    enum Bucket { case yesterday, today, tomorrow }

    let id: String
    let homeTeam: String
    let awayTeam: String
    let time: String
    let homeLogo: String
    let awayLogo: String
    let homeScore: String?
    let awayScore: String?
    let status: String?
    let competition: String?
    let bucket: Bucket

    var hasScore: Bool { homeScore != nil && awayScore != nil }

    var isLive: Bool {
        guard let s = status?.lowercased().trimmingCharacters(in: .whitespaces), !s.isEmpty else {
            return false
        }
        return s == "live" || s == "ht" || s == "1h" || s == "2h"
            || s == "in_play" || s == "playing" || s == "inplay"
            || s.hasPrefix("live")
    }
}

extension MatchDto {
    func toDomain(bucket: Match.Bucket) -> Match {
        Match(
            id: id ?? UUID().uuidString,
            homeTeam: homeTeam,
            awayTeam: awayTeam,
            time: time,
            homeLogo: homeLogo,
            awayLogo: awayLogo,
            homeScore: homeScore,
            awayScore: awayScore,
            status: status,
            competition: competition,
            bucket: bucket
        )
    }
}
