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

    /// Mirrors `capture`: sent alongside the equivalent `os.Logger` call, never
    /// in place of it, and only once the PostHog project is configured. Attribute
    /// values must stay within the copy allow-list (session ids, `ReasonCode`s,
    /// coarse state) — never `PlanCheckIn.body` or `PlanProfile.workArounds`.
    static func log(_ message: String, level: PostHogLogSeverity = .info, attributes: [String: Any] = [:]) {
        guard let projectToken = Bundle.main.object(forInfoDictionaryKey: "PostHogProjectToken") as? String,
              let host = Bundle.main.object(forInfoDictionaryKey: "PostHogHost") as? String,
              !projectToken.isEmpty,
              !host.isEmpty else {
            return
        }
        PostHogSDK.shared.captureLog(message, level: level, attributes: attributes)
    }
}
