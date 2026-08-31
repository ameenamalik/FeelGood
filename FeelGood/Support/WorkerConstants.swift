//
//  WorkerConstants.swift
//  FeelGood
//

import Foundation

/// The app's Cloudflare Worker, which now serves two unrelated routes: the
/// copy proxy (PRD §11) and the video player wrapper (`worker/src/player.ts`).
/// They share a host and nothing else — `/copy` holds the Anthropic key and
/// checks entitlement, `/player` is public and static.
nonisolated enum WorkerConstants {
    /// Loaded from the `WORKER_BASE_URL` build setting via Info.plist, same
    /// shape as `RevenueCatConstants.apiKey` — Debug and Release point at
    /// separate Workers (see worker/README.md), so the dev key never touches
    /// a shipped build.
    ///
    /// This is the Worker's *origin*, with no path: each caller appends its
    /// own route. Optional by design, but the two routes fail differently when
    /// it is missing — see `copyURL` and `playerURL(videoID:)`.
    static let baseURL: URL? = workerURL(
        from: Bundle.main.object(forInfoDictionaryKey: "WorkerBaseURL") as? String
    )

    static func workerURL(from string: String?) -> URL? {
        guard
            let string,
            !string.isEmpty,
            let url = URL(string: string),
            ["http", "https"].contains(url.scheme?.lowercased() ?? ""),
            url.host != nil
        else { return nil }
        return url
    }

    /// The deterministic headline is the product's always-available path, so an
    /// unconfigured Worker disables only the copy upgrade; it must never
    /// prevent the app (or a tab) from opening.
    static var copyURL: URL? { baseURL?.appending(path: "copy") }

    /// Unlike `copyURL`, a missing player URL is user-visible: the embed cannot
    /// be made to work from the client alone (see `worker/src/player.ts`), so
    /// `PlayerView` falls back to opening the video in YouTube rather than
    /// rendering a frame that will refuse to play.
    static func playerURL(videoID: String) -> URL? {
        guard isValidVideoID(videoID), let baseURL else { return nil }
        return baseURL.appending(path: "player").appending(
            queryItems: [URLQueryItem(name: "v", value: videoID)]
        )
    }

    /// Mirrors the allow-list in `worker/src/player.ts`. Validating on both
    /// sides means a malformed id fails here, where the catalog can be fixed,
    /// rather than as a 400 the user sees as a blank player.
    static func isValidVideoID(_ id: String) -> Bool {
        id.count == 11 && id.allSatisfy { $0.isASCII && ($0.isLetter || $0.isNumber || $0 == "_" || $0 == "-") }
    }

    /// PRD §11: the Worker is given ~2s before the deterministic template
    /// copy wins by default.
    static let requestTimeout: TimeInterval = 2
}
