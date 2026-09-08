//
//  LegalLinks.swift
//  FeelGood
//

import Foundation

/// Hosted Terms of Use and Privacy Policy, required both in-app and in App
/// Store Connect metadata (Guideline 3.1.2 for auto-renewable subscriptions,
/// and general metadata requirements for every app).
///
/// The privacy policy text must stay in sync with what the app actually
/// collects — it currently needs an update for the Firebase Auth/Firestore
/// account sync added alongside this file's last change; see conversation
/// context, not restated here since the doc itself is the source of truth.
nonisolated enum LegalLinks {
    static var termsOfUse: URL {
        URL(string: "https://feelgood-web.vercel.app/terms")!
    }

    static var privacyPolicy: URL {
        URL(string: "https://feelgood-web.vercel.app/privacy")!
    }
}
