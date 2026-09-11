//
//  LegalLinks.swift
//  FeelGood
//

import Foundation

/// Hosted Terms of Use and Privacy Policy, required both in-app and in App
/// Store Connect metadata (Guideline 3.1.2 for auto-renewable subscriptions,
/// and general metadata requirements for every app).
nonisolated enum LegalLinks {
    static var termsOfUse: URL {
        URL(string: "https://feelgood-web.vercel.app/terms")!
    }

    static var privacyPolicy: URL {
        URL(string: "https://feelgood-web.vercel.app/privacy")!
    }
}
