//
//  CopyServiceConstants.swift
//  FeelGood
//

import Foundation

nonisolated enum CopyServiceConstants {
    /// Loaded from the `CopyWorkerBaseURL` build setting via Info.plist, same
    /// shape as `RevenueCatConstants.apiKey` — Debug and Release point at
    /// separate Workers (see worker/README.md), so the dev key never touches
    /// a shipped build.
    /// Optional by design. The deterministic headline is the product's
    /// always-available path, so an unconfigured Worker disables only the
    /// copy upgrade; it must never prevent the app (or a tab) from opening.
    static let workerBaseURL: URL? = workerURL(
        from: Bundle.main.object(forInfoDictionaryKey: "CopyWorkerBaseURL") as? String
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

    /// PRD §11: the Worker is given ~2s before the deterministic template
    /// copy wins by default.
    static let requestTimeout: TimeInterval = 2
}
