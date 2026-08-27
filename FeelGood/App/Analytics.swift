//
//  Analytics.swift
//  FeelGood
//

import Foundation
import PostHog

enum Analytics {
    static func capture(_ event: String, properties: [String: Any] = [:]) {
        guard let projectToken = Bundle.main.object(forInfoDictionaryKey: "PostHogProjectToken") as? String,
              let host = Bundle.main.object(forInfoDictionaryKey: "PostHogHost") as? String,
              !projectToken.isEmpty,
              !host.isEmpty else {
            return
        }
        PostHogSDK.shared.capture(event, properties: properties)
    }
}
