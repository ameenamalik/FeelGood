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
    static let workerBaseURL: URL = {
        guard
            let string = Bundle.main.object(forInfoDictionaryKey: "CopyWorkerBaseURL") as? String,
            !string.isEmpty,
            let url = URL(string: string)
        else {
            fatalError("Missing or invalid CopyWorkerBaseURL in Info.plist — set the COPY_WORKER_BASE_URL build setting for this configuration.")
        }
        return url
    }()

    /// PRD §11: the Worker is given ~2s before the deterministic template
    /// copy wins by default.
    static let requestTimeout: TimeInterval = 2
}
