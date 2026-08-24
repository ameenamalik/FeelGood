//
//  RevenueCatConstants.swift
//  FeelGood
//

import Foundation

enum RevenueCatConstants {
    /// Loaded from the `REVENUECAT_API_KEY` build setting via Info.plist so Debug/Release
    /// (and any future staging configuration) can point at different RevenueCat projects.
    /// See project.pbxproj build settings — swap the Release value for your production key
    /// before shipping; the current value is a RevenueCat Test Store key ("test_" prefix).
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
    static let proEntitlementID = "FeelGood Pro"

    /// Standard RevenueCat package types for the "monthly" and "yearly" products/offerings.
    static let monthlyProductID = "monthly"
    static let yearlyProductID = "yearly"
}
