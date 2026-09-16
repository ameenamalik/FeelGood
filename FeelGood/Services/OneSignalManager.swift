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
}
