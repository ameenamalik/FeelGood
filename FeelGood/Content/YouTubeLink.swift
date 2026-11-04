//
//  YouTubeLink.swift
//  FeelGood
//
//  A video somebody pastes in themselves. Nothing ships pre-saved: the
//  catalog holds no video, so this is the only way one gets into the app.
//

import Foundation

nonisolated enum YouTubeLink {
    /// The 11-character id in any of the common link shapes, or `nil` for
    /// anything else (a playlist, a channel, another site, plain text).
    static func videoID(from text: String) -> String? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        if isVideoID(trimmed) { return trimmed }

        let withScheme = trimmed.contains("://") ? trimmed : "https://\(trimmed)"
        guard let components = URLComponents(string: withScheme),
              var host = components.host?.lowercased() else { return nil }
        for prefix in ["www.", "m.", "music."] where host.hasPrefix(prefix) {
            host.removeFirst(prefix.count)
        }

        let pathParts = components.path.split(separator: "/").map(String.init)
        switch host {
        case "youtu.be":
            return pathParts.first.flatMap { isVideoID($0) ? $0 : nil }
        case "youtube.com", "youtube-nocookie.com":
            if pathParts.first == "watch" {
                let value = components.queryItems?.first { $0.name == "v" }?.value
                return value.flatMap { isVideoID($0) ? $0 : nil }
            }
            if pathParts.count >= 2, ["shorts", "embed", "live", "v"].contains(pathParts[0]) {
                return isVideoID(pathParts[1]) ? pathParts[1] : nil
            }
            return nil
        default:
            return nil
        }
    }

    static func isVideoID(_ text: String) -> Bool {
        text.count == 11 && text.allSatisfy { $0.isASCII && ($0.isLetter || $0.isNumber || $0 == "-" || $0 == "_") }
    }
}

nonisolated struct YouTubeVideoInfo: Equatable, Sendable {
    let videoID: String
    let title: String
    let channel: String
}

nonisolated enum YouTubeLookupError: Error, Equatable {
    /// Private, removed or mistyped.
    case notFound
    /// The owner doesn't let their video play outside YouTube, so it can't
    /// play in the app either.
    case embeddingDisabled
    /// No connection, or YouTube didn't answer.
    case unreachable
}

nonisolated protocol YouTubeLookup: Sendable {
    func info(for videoID: String) async throws -> YouTubeVideoInfo
}

/// Asks YouTube's public oEmbed endpoint for the title and channel. It needs
/// no key, and it refuses videos that can't be embedded, which is exactly the
/// check the player needs.
nonisolated struct OEmbedYouTubeLookup: YouTubeLookup {
    func info(for videoID: String) async throws -> YouTubeVideoInfo {
        var components = URLComponents(string: "https://www.youtube.com/oembed")!
        components.queryItems = [
            URLQueryItem(name: "url", value: "https://www.youtube.com/watch?v=\(videoID)"),
            URLQueryItem(name: "format", value: "json"),
        ]
        guard let url = components.url else { throw YouTubeLookupError.notFound }

        var request = URLRequest(url: url)
        request.timeoutInterval = 8

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw YouTubeLookupError.unreachable
        }

        let status = (response as? HTTPURLResponse)?.statusCode ?? -1
        switch status {
        case 200..<300:
            break
        case 400, 404:
            throw YouTubeLookupError.notFound
        case 401, 403:
            throw YouTubeLookupError.embeddingDisabled
        default:
            throw YouTubeLookupError.unreachable
        }

        struct Payload: Decodable {
            let title: String
            let authorName: String
            enum CodingKeys: String, CodingKey { case title, authorName = "author_name" }
        }
        guard let payload = try? JSONDecoder().decode(Payload.self, from: data) else {
            throw YouTubeLookupError.unreachable
        }
        return YouTubeVideoInfo(videoID: videoID, title: payload.title, channel: payload.authorName)
    }
}
