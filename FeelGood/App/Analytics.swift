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
nonisolated protocol AnalyticsSink {
    func capture(_ event: String, properties: [String: Any])
    func log(_ message: String, level: PostHogLogSeverity, attributes: [String: Any])
    func identify(_ userID: String, properties: [String: Any])
    func reset()
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

    /// Links every event and replay this device has already sent — under its
    /// anonymous distinct ID — to the signed-in person, so `Persons` and
    /// Session Replay show someone real instead of an anonymous UUID.
    func identify(_ userID: String, properties: [String: Any]) {
        guard isConfigured else { return }
        PostHogSDK.shared.identify(userID, userProperties: properties)
    }

    /// Ends the identity link on sign-out, so whatever the device does next —
    /// a different person signing in on a shared device, or nobody signed in
    /// at all — goes back to being anonymous rather than attributed to
    /// whoever last signed in.
    func reset() {
        guard isConfigured else { return }
        PostHogSDK.shared.reset()
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

    /// Call once someone is signed in — identity only (email, display name,
    /// auth provider), never health/body data, same allow-list discipline as
    /// `capture`.
    static func identify(_ userID: String, properties: [String: Any] = [:]) {
        sink.identify(userID, properties: properties)
    }

    /// Emails that belong to the team, so PostHog can filter them out of
    /// real-user counts. Add more here; Apple "hide my email" relay addresses
    /// won't match, so tag those people by hand in PostHog.
    static let internalEmails: Set<String> = ["ameenazara3@gmail.com"]

    /// Identifies the Firebase user to PostHog (uid as distinct ID) and flags
    /// team accounts with `is_internal`. Safe to call on every auth-state
    /// change, including launch restores.
    static func identifySignedIn(_ user: AuthUser) {
        var properties: [String: Any] = [
            "auth_provider": user.providerID,
            "is_internal": user.email.map { internalEmails.contains($0.lowercased()) } ?? false,
        ]
        if let email = user.email { properties["email"] = email }
        if let name = user.displayName { properties["name"] = name }
        identify(user.uid, properties: properties)
    }

    /// Call on sign-out so a shared device doesn't keep attributing the next
    /// person's activity to whoever signed out.
    static func reset() {
        sink.reset()
    }
}
