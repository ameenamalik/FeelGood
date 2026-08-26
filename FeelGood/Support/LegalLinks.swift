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
    static let termsOfUse = URL(string: "https://www.feelgood.app/terms")!
    static let privacyPolicy = URL(string: "https://www.feelgood.app/privacy")!
}
