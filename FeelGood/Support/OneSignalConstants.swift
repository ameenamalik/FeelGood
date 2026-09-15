//
//  OneSignalConstants.swift
//  FeelGood
//

import Foundation

enum OneSignalConstants {
    /// Loaded from the `ONESIGNAL_APP_ID` build setting via Info.plist, mirroring
    /// `RevenueCatConstants.apiKey` so a future staging OneSignal app is a build-setting
    /// change rather than a code change.
    static let appID: String = {
        guard
            let id = Bundle.main.object(forInfoDictionaryKey: "OneSignalAppID") as? String,
            !id.isEmpty
        else {
            fatalError("Missing OneSignalAppID in Info.plist — set the ONESIGNAL_APP_ID build setting for this configuration.")
        }
        return id
    }()
}
