//
//  Analytics.swift
//  FeelGood
//

import Foundation
import PostHog

/// Where events and logs actually go. A protocol for the same reason
/// `ContentProviding`, `CopyProviding` and `CopyTransport` are: so the app runs
/// offline in tests and previews, and — since `check_in_completed` started
/// carrying check-in state — so a test can see what a call site handed over
/// without a network round trip.
protocol AnalyticsSink {
    func capture(_ event: String, properties: [String: Any])
    func log(_ message: String, level: PostHogLogSeverity, attributes: [String: Any])
}

/// The real one. Both methods no-op until the project is configured, which is
/// what keeps previews, tests and unconfigured builds from reaching the
/// network at all.
struct PostHogAnalyticsSink: AnalyticsSink {
    private var isConfigured: Bool {
        guard let projectToken = Bundle.main.object(forInfoDictionaryKey: "PostHogProjectToken") as? String,
              let host = Bundle.main.object(forInfoDictionaryKey: "PostHogHost") as? String,
              !projectToken.isEmpty,
              !host.isEmpty
        else {
            return false
        }
        return true
    }

    func capture(_ event: String, properties: [String: Any]) {
        guard isConfigured else { return }
        PostHogSDK.shared.capture(event, properties: properties)
    }

    func log(_ message: String, level: PostHogLogSeverity, attributes: [String: Any]) {
        guard isConfigured else { return }
        PostHogSDK.shared.captureLog(message, level: level, attributes: attributes)
    }
}

@MainActor
enum Analytics {
    /// The swap point. MainActor-isolated like everything else in this file, so
    /// a test replaces it without synchronisation.
    static var sink: AnalyticsSink = PostHogAnalyticsSink()

    static func capture(_ event: String, properties: [String: Any] = [:]) {
        sink.capture(event, properties: properties)
    }

    /// Convenience for the payload types that own their own event name and
    /// wire shape, so neither is retyped at a call site.
    static func capture(_ payload: CheckInAnalytics) {
        capture(CheckInAnalytics.eventName, properties: payload.properties)
    }

    /// Mirrors `capture`: sent alongside the equivalent `os.Logger` call, never
    /// in place of it, and only once the PostHog project is configured. Attribute
    /// values must stay within the copy allow-list (session ids, `ReasonCode`s,
    /// coarse state) — never `PlanCheckIn.body` or `PlanProfile.workArounds`.
    static func log(_ message: String, level: PostHogLogSeverity = .info, attributes: [String: Any] = [:]) {
        sink.log(message, level: level, attributes: attributes)
    }
}
