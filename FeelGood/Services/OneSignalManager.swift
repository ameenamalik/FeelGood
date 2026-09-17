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

    /// Local-only condition an In-App Message can require, e.g. "days since
    /// last session >= 5" configured against `engagementTriggerKey` in the
    /// OneSignal dashboard. Unlike `setTag`, this never syncs to OneSignal's
    /// servers or the dashboard's user record — it only controls what the SDK
    /// is willing to show while someone is already in the app, so it can't be
    /// used for push segmentation (push re-engagement instead targets
    /// OneSignal's own built-in "Last Session" condition, which needs no
    /// client-side trigger at all).
    static let engagementTriggerKey = "days_since_last_session"

    func setEngagementTrigger(daysSinceLast: Int?) {
        guard let daysSinceLast else {
            OneSignal.InAppMessages.removeTrigger(Self.engagementTriggerKey)
            return
        }
        OneSignal.InAppMessages.addTrigger(Self.engagementTriggerKey, withValue: String(daysSinceLast))
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

        func evaluate(_ subscriptionId: String?) {
            guard let subscriptionId, !subscriptionId.isEmpty, !subscriptionId.hasPrefix("local-") else { return }
            DispatchQueue.main.async { [weak self] in
                guard let self, !self.hasFired else { return }
                self.hasFired = true
                self.onRegistered()
            }
        }
    }
}

