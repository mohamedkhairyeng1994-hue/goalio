import Foundation
import UIKit

enum MatchAPIError: Error {
    case invalidURL
    case badStatus(Int)
    case decoding(Error)
    case transport(Error)
}

struct WidgetSnapshot {
    let matches: [Match]
    let hasFavorites: Bool
}

enum MatchAPI {

    static func fetchMatches(forceRefresh: Bool) async throws -> WidgetSnapshot {
        var components = URLComponents(string: "\(SharedConfig.baseURL)/widget/matches")
        if forceRefresh {
            components?.queryItems = [URLQueryItem(name: "refresh", value: "1")]
        }
        guard let url = components?.url else { throw MatchAPIError.invalidURL }

        var req = URLRequest(url: url)
        req.timeoutInterval = 15
        req.setValue("application/json", forHTTPHeaderField: "Accept")

        if let token = UserDefaults.widgetShared.string(forKey: SharedConfig.Keys.authToken)?
            .trimmingCharacters(in: .whitespacesAndNewlines), !token.isEmpty
        {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: req)
        } catch {
            throw MatchAPIError.transport(error)
        }
        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            throw MatchAPIError.badStatus(http.statusCode)
        }

        let dto: WidgetResponseDto
        do {
            dto = try JSONDecoder().decode(WidgetResponseDto.self, from: data)
        } catch {
            throw MatchAPIError.decoding(error)
        }

        let matches =
            dto.yesterday.map { $0.toDomain(bucket: .yesterday) } +
            dto.today.map     { $0.toDomain(bucket: .today)     } +
            dto.tomorrow.map  { $0.toDomain(bucket: .tomorrow)  }

        return WidgetSnapshot(matches: matches, hasFavorites: dto.hasFavorites)
    }

    // Widgets can't run async work inside SwiftUI views, so logos are downloaded
    // up front in the TimelineProvider and packed into the entry as raw bytes.
    static func preloadLogos(for matches: [Match]) async -> [String: Data] {
        let urls = Set(matches.flatMap { [$0.homeLogo, $0.awayLogo] })
            .filter { !$0.isEmpty }

        return await withTaskGroup(of: (String, Data?).self) { group in
            for raw in urls {
                guard let url = URL(string: raw) else { continue }
                group.addTask {
                    do {
                        var req = URLRequest(url: url)
                        req.timeoutInterval = 8
                        let (data, _) = try await URLSession.shared.data(for: req)
                        let resized = resizeImageData(data, maxDim: 96) ?? data
                        return (raw, resized)
                    } catch {
                        return (raw, nil)
                    }
                }
            }

            var dict: [String: Data] = [:]
            for await (key, data) in group {
                if let data = data { dict[key] = data }
            }
            return dict
        }
    }

    // Keeps the entry payload small so we don't blow past WidgetKit's serialized
    // entry budget (entries are kept in memory by the system).
    private static func resizeImageData(_ data: Data, maxDim: CGFloat) -> Data? {
        guard let img = UIImage(data: data) else { return nil }
        let size = img.size
        let scale = min(maxDim / max(size.width, 1), maxDim / max(size.height, 1), 1)
        if scale >= 1 { return img.pngData() }
        let target = CGSize(width: size.width * scale, height: size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: target)
        let resized = renderer.image { _ in
            img.draw(in: CGRect(origin: .zero, size: target))
        }
        return resized.pngData()
    }
}
