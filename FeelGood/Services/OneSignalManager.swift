//
//  OneSignalManager.swift
//  FeelGood
//
//  Centralized wrapper around the OneSignal SDK (push notifications + In-App
//  Messages). No other file may import OneSignalFramework directly — every
//  OneSignal call, including the push subscription observer used for the
//  post-integration verification dialog, is isolated here.
//

import Foundation
import OneSignalFramework

nonisolated final class OneSignalManager: Sendable {
    static let shared = OneSignalManager()

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

    /// Fires once, the first time the push subscription id becomes a real
    /// server-assigned value, so `RootView` can show the "integration
    /// complete" dialog and ask for permission on tap.
    ///
    /// OneSignal retains observers weakly — the caller must hold a strong
    /// reference (e.g. SwiftUI `@State`) for as long as it wants callbacks.
    ///
    /// `nonisolated`: OneSignal invokes `onPushSubscriptionDidChange` on its
    /// own background thread, not the main actor. Letting this class inherit
    /// the project's default MainActor isolation reproduces the
    /// `UIColor(dynamicProvider:)` SIGTRAP documented in CLAUDE.md — a
    /// callback from outside Swift concurrency hitting a MainActor executor
    /// assert. `evaluate` hops to the main queue itself before touching UI state.
    ///
    /// `@unchecked Sendable`: `hasFired` is mutable, but every read and write
    /// of it is confined to `DispatchQueue.main`, so the two SDK entry points
    /// (`onPushSubscriptionDidChange` from an arbitrary thread, `evaluate`
    /// called synchronously right after registering) can't race on it.
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
}
