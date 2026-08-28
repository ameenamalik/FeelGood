//
//  RevenueCatConstants.swift
//  FeelGood
//

import Foundation

enum RevenueCatConstants {
    /// Loaded from the `REVENUECAT_API_KEY` build setting via Info.plist so Debug/Release
    /// (and any future staging configuration) can point at different RevenueCat projects.
    /// Debug stays on the RevenueCat Test Store key ("test_" prefix) so `DebugMenu` can drive
    /// real purchases without a sandbox account; Release points at the production App Store app.
    static let apiKey: String = {
        guard
            let key = Bundle.main.object(forInfoDictionaryKey: "RevenueCatAPIKey") as? String,
            !key.isEmpty
        else {
            fatalError("Missing RevenueCatAPIKey in Info.plist — set the REVENUECAT_API_KEY build setting for this configuration.")
        }
        return key
    }()

    /// Identifier exactly as configured on the Entitlements tab of the RevenueCat dashboard.
    static let proEntitlementID = "pro"
}
