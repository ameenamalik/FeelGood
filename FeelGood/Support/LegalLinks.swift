//
//  LegalLinks.swift
//  FeelGood
//

import Foundation

/// PLACEHOLDER URLS. Apple requires working Terms of Use and Privacy Policy
/// links — both in-app and in App Store Connect metadata — before this can
/// be submitted (App Store Review Guideline 3.1.2 for auto-renewable
/// subscriptions specifically, and general metadata requirements for every
/// app). Swap these for real, hosted pages before shipping.
nonisolated enum LegalLinks {
    static let fallbackBase = URL(string: "https://feelgood-copy-production.ameenazara3.workers.dev")!

    static var termsOfUse: URL {
        WorkerConstants.baseURL?.appending(path: "terms") ?? fallbackBase.appending(path: "terms")
    }

    static var privacyPolicy: URL {
        WorkerConstants.baseURL?.appending(path: "privacy") ?? fallbackBase.appending(path: "privacy")
    }
}
