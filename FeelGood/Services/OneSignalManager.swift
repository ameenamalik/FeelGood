//
//  OneSignalManager.swift
//  FeelGood
//
//  Centralized wrapper around the OneSignal SDK (push notifications + In-App
//  Messages). No other file may import OneSignalFramework directly, keeping
//  initialization, identity, targeting, and message triggers in one place.
//

import Foundation
import OneSignalCore
import OneSignalFramework

extension Notification.Name {
    static let oneSignalOpenMyMenu = Notification.Name("OneSignalOpenMyMenu")
}

/// Converts OneSignal dashboard action IDs into app navigation requests.
/// The SDK may invoke this listener away from the main thread, so UI work is
/// handed back through NotificationCenter on the main queue.
nonisolated private final class OneSignalInAppClickListener: NSObject, OSInAppMessageClickListener, @unchecked Sendable {
    func onClick(event: OSInAppMessageClickEvent) {
        guard event.result.actionId == "open_my_menu" else { return }
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .oneSignalOpenMyMenu, object: nil)
        }
    }
}

nonisolated final class OneSignalManager: Sendable {
    static let shared = OneSignalManager()

    /// The Journey waits this long before offering to resume a paused reset.
    /// Keep this in sync with the Wait Until expiration in OneSignal.
    private static let pausedSessionReminderDelay: TimeInterval = 2.5 * 60 * 60

    /// Latest acceptable delivery time in the user's current time zone. A
    /// pause that would put the reminder after this point still reaches
    /// OneSignal for analytics, but is ineligible to enter the Journey.
    private static let pausedSessionReminderCutoff = DateComponents(hour: 20, minute: 30)

    private let inAppClickListener = OneSignalInAppClickListener()

    private init() {}

    /// Call once, as early as possible in app startup.
    func initialize(appId: String) {
        #if DEBUG
        OneSignal.Debug.setLogLevel(.LL_VERBOSE)
        #else
        OneSignal.Debug.setLogLevel(.LL_NONE)
        #endif
        // SwiftUI app lifecycle has no `launchOptions` to forward.
        OneSignal.initialize(appId, withLaunchOptions: nil)
        OneSignal.InAppMessages.addClickListener(inAppClickListener)
    }

    func login(externalId: String) {
        OneSignal.login(externalId)
    }

    func logout() {
        OneSignal.logout()
    }

    func setEmail(_ email: String) {
        OneSignal.User.addEmail(email)
    }

    func setSmsNumber(_ number: String) {
        OneSignal.User.addSms(number)
    }

    func setTag(key: String, value: String) {
        OneSignal.User.addTag(key: key, value: value)
    }

    func removeTag(key: String) {
        OneSignal.User.removeTag(key)
    }

    /// Local-only value used by dashboard-defined In-App Messages. This is
    /// intentionally an IAM trigger rather than a server-side user tag.
    static let engagementTriggerKey = "days_since_last_session"

    func setEngagementTrigger(daysSinceLast: Int?) {
        guard let daysSinceLast else {
            OneSignal.InAppMessages.removeTrigger(Self.engagementTriggerKey)
            return
        }
        OneSignal.InAppMessages.addTrigger(
            Self.engagementTriggerKey,
            withValue: String(daysSinceLast)
        )
    }

    /// Sends behavior to OneSignal Custom Events. These events drive Journeys;
    /// they are separate from the local In-App Message triggers below.
    func trackEvent(name: String, properties: [String: Any] = [:]) {
        OneSignal.User.trackEvent(
            name: name,
            properties: properties.isEmpty ? nil : properties
        )
    }

    func trackSessionPaused(
        sessionID: String,
        startedAt: Date,
        pausedAt: Date = Date(),
        calendar: Calendar = .autoupdatingCurrent
    ) {
        var properties = sessionEventProperties(sessionID: sessionID, startedAt: startedAt)
        properties["reminder_eligible"] = Self.isPausedSessionReminderEligible(
            pausedAt: pausedAt,
            calendar: calendar
        )
        trackEvent(name: "session_paused", properties: properties)
    }

    func trackSessionResumed(sessionID: String, startedAt: Date) {
        trackEvent(
            name: "session_resumed",
            properties: sessionEventProperties(sessionID: sessionID, startedAt: startedAt)
        )
    }

    func trackSessionCompleted(sessionID: String, startedAt: Date) {
        trackEvent(
            name: "session_completed",
            properties: sessionEventProperties(sessionID: sessionID, startedAt: startedAt)
        )
    }

    func trackSessionDiscarded(sessionID: String, startedAt: Date) {
        trackEvent(
            name: "session_discarded",
            properties: sessionEventProperties(sessionID: sessionID, startedAt: startedAt)
        )
    }

    /// Makes a dashboard-defined In-App Message eligible. Trigger names and
    /// values are case-sensitive and must exactly match the OneSignal rule.
    func setInAppTrigger(key: String, value: String) {
        OneSignal.InAppMessages.addTrigger(key, withValue: value)
    }

    /// Adds related values together so OneSignal never evaluates a message
    /// against a half-updated set of conditions.
    func setInAppTriggers(_ triggers: [String: String]) {
        OneSignal.InAppMessages.addTriggers(triggers)
    }

    /// Removes a local In-App Message condition when its moment has passed.
    /// OneSignal trigger values are session-scoped UI state, not durable user
    /// attributes, so callers should clear moment-specific triggers eagerly.
    func removeInAppTriggers(_ keys: [String]) {
        for key in keys {
            OneSignal.InAppMessages.removeTrigger(key)
        }
    }

    /// A real, server-assigned subscription ID is non-empty and not the SDK's
    /// `local-` placeholder, which is assigned before the device registers.
    var currentPushSubscriptionId: String? {
        OneSignal.User.pushSubscription.id
    }

    func addPushSubscriptionObserver(_ observer: PushSubscriptionObserver) {
        OneSignal.User.pushSubscription.addObserver(observer)
    }

    func requestPushPermission(completion: @escaping @Sendable (Bool) -> Void) {
        OneSignal.Notifications.requestPermission(completion, fallbackToSettings: true)
    }

    nonisolated final class PushSubscriptionObserver: NSObject, OSPushSubscriptionObserver, @unchecked Sendable {
        private let onRegistered: @Sendable () -> Void
        private var hasFired = false

        init(onRegistered: @escaping @Sendable () -> Void) {
            self.onRegistered = onRegistered
        }

        func onPushSubscriptionDidChange(state: OSPushSubscriptionChangedState) {
            evaluate(state.current.id)
        }

        /// Call immediately after registering, in case the id was already
        /// server-assigned before this observer attached.
        func evaluate(_ subscriptionId: String?) {
            guard let subscriptionId, !subscriptionId.isEmpty, !subscriptionId.hasPrefix("local-") else { return }
            DispatchQueue.main.async { [weak self] in
                guard let self, !self.hasFired else { return }
                self.hasFired = true
                self.onRegistered()
            }
        }
    }

    private func sessionEventProperties(sessionID: String, startedAt: Date) -> [String: Any] {
        var properties: [String: Any] = [
            "session_id": sessionID,
            "session_run_id": Self.sessionRunID(sessionID: sessionID, startedAt: startedAt)
        ]
        if let launchURL = DeepLink.session(sessionID)?.absoluteString {
            properties["launch_url"] = launchURL
        }
        return properties
    }

    private static func sessionRunID(sessionID: String, startedAt: Date) -> String {
        let startedAtMilliseconds = Int64((startedAt.timeIntervalSince1970 * 1_000).rounded())
        return "\(sessionID):\(startedAtMilliseconds)"
    }

    private static func isPausedSessionReminderEligible(
        pausedAt: Date,
        calendar: Calendar
    ) -> Bool {
        let reminderAt = pausedAt.addingTimeInterval(pausedSessionReminderDelay)
        guard calendar.isDate(pausedAt, inSameDayAs: reminderAt),
              let cutoff = calendar.date(
                bySettingHour: pausedSessionReminderCutoff.hour ?? 20,
                minute: pausedSessionReminderCutoff.minute ?? 30,
                second: 0,
                of: pausedAt
              )
        else { return false }
        return reminderAt <= cutoff
    }
}
