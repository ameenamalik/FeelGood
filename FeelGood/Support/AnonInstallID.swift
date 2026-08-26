//
//  AnonInstallID.swift
//  FeelGood
//
//  A random per-install identifier, needed so the copy Worker can check
//  entitlement and rate-limit. Pseudonymous, not anonymous: it is verified
//  against RevenueCat, but never linked to a name, email, or account. See
//  PRD §11 "On anonInstallID".
//
//  Deliberately a fresh random UUID rather than `identifierForVendor` — a
//  vendor id can reset or be shared across an app family in ways that don't
//  match "pseudonymous per install".
//

import Foundation

nonisolated enum AnonInstallID {
    private static let defaultsKey = "com.feelgood.anonInstallID"

    static let current: String = {
        if let existing = UserDefaults.standard.string(forKey: defaultsKey) {
            return existing
        }
        let generated = UUID().uuidString
        UserDefaults.standard.set(generated, forKey: defaultsKey)
        return generated
    }()
}
