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

    /// Opens the user's mail client with a pre-addressed message, so there's
    /// an in-app way to reach the developer (App Review looks for this on
    /// paid-subscription apps).
    static var contactSupport: URL {
        URL(string: "mailto:ameenazara3@gmail.com?subject=FeelGood%20Support")!
    }
}
