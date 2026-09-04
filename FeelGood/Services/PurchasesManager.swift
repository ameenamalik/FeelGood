//
//  PurchasesManager.swift
//  FeelGood
//

import Foundation
import Observation
import PostHog
import RevenueCat
import os

/// Thin wrapper around the RevenueCat SDK. Owns configuration, exposes the current
/// `CustomerInfo` / `Offerings` reactively, and centralizes purchase/restore error handling
/// so views stay declarative.
@MainActor
@Observable
final class PurchasesManager {
    static let shared = PurchasesManager()

    private(set) var customerInfo: CustomerInfo?
    private(set) var offerings: Offerings?
    private(set) var isLoadingOfferings = false
    var lastError: PurchasesManagerError?

    /// True once `customerInfo` has been fetched at least once, so views can distinguish
    /// "still loading" from "confirmed not subscribed".
    private(set) var hasLoadedCustomerInfo = false

    /// The id RevenueCat knows this subscriber by — its anonymous id before
    /// Apple Sign In, the Apple user id after. The copy Worker looks the
    /// subscriber up by exactly this value, so it must be read from the SDK
    /// rather than generated alongside it.
    var appUserID: String { Purchases.shared.appUserID }

    var isProUnlocked: Bool {
        #if DEBUG
        if debugForceProUnlocked { return true }
        #endif
        return customerInfo?.entitlements[RevenueCatConstants.proEntitlementID]?.isActive == true
    }

    #if DEBUG
    /// Debug-only override so every Pro-gated flow (the copy upgrade,
    /// `ProGateView`, etc.) can be tested without a sandbox purchase.
    /// Reachable from `DebugMenu`; persisted so it survives a relaunch
    /// mid-testing. Compiled out of Release entirely — there is no key for
    /// a reviewer or a real build to stumble into.
    var debugForceProUnlocked: Bool {
        didSet {
            UserDefaults.standard.set(debugForceProUnlocked, forKey: "debugForceProUnlocked")
        }
    }
    #endif

    /// The current offering's monthly/yearly packages, when available, for direct purchase buttons.
    var monthlyPackage: Package? { offerings?.current?.monthly }
    var yearlyPackage: Package? { offerings?.current?.annual }

    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.feelgood.app", category: "Purchases")
    private var customerInfoObservationTask: Task<Void, Never>?

    private init() {
        #if DEBUG
        debugForceProUnlocked = UserDefaults.standard.bool(forKey: "debugForceProUnlocked")
        #endif
    }

    /// Call once, as early as possible in app startup (before any UI reads `isProUnlocked`).
    func configure() {
        #if DEBUG
        Purchases.logLevel = .debug
        #else
        Purchases.logLevel = .warn
        #endif

        Purchases.configure(withAPIKey: RevenueCatConstants.apiKey)

        observeCustomerInfoUpdates()

        Task {
            async let customerInfo: Void = refreshCustomerInfo()
            async let offerings: Void = fetchOfferings()
            _ = await (customerInfo, offerings)
        }
    }

    /// Explicitly refreshes the subscriber record. The update stream handles
    /// changes after launch, but a gate must not depend on a future change to
    /// learn that an existing subscriber is already entitled.
    func refreshCustomerInfo() async {
        do {
            customerInfo = try await Purchases.shared.customerInfo()
        } catch {
            logger.error("Failed to refresh CustomerInfo: \(error.localizedDescription)")
            Analytics.log("CustomerInfo refresh failed", level: .error, attributes: ["error": error.localizedDescription])
        }
        hasLoadedCustomerInfo = true
    }

    /// If your app has its own auth system, call this after login/logout so RevenueCat's
    /// anonymous ID is swapped for your stable user ID (and reset on logout).
    func logIn(appUserID: String) async {
        do {
            let (info, _) = try await Purchases.shared.logIn(appUserID)
            customerInfo = info
            hasLoadedCustomerInfo = true
        } catch {
            lastError = .other(error)
            logger.error("logIn failed: \(error.localizedDescription)")
            Analytics.log("logIn failed", level: .error, attributes: ["error": error.localizedDescription])
        }
    }

    func logOut() async {
        do {
            customerInfo = try await Purchases.shared.logOut()
            hasLoadedCustomerInfo = true
        } catch {
            lastError = .other(error)
            logger.error("logOut failed: \(error.localizedDescription)")
            Analytics.log("logOut failed", level: .error, attributes: ["error": error.localizedDescription])
        }
    }

    /// Streams CustomerInfo updates for the lifetime of the app — fires on launch, after
    /// purchases/restores, and when entitlements change remotely (e.g. a refund or renewal).
    /// This is the modern replacement for `PurchasesDelegate`.
    private func observeCustomerInfoUpdates() {
        customerInfoObservationTask?.cancel()
        customerInfoObservationTask = Task { [weak self] in
            guard let self else { return }
            for await info in Purchases.shared.customerInfoStream {
                self.customerInfo = info
                self.hasLoadedCustomerInfo = true
                let proActive = info.entitlements[RevenueCatConstants.proEntitlementID]?.isActive == true
                self.logger.debug("CustomerInfo updated — pro active: \(proActive)")
                Analytics.log("CustomerInfo updated", level: .debug, attributes: ["pro_active": proActive])
            }
        }
    }

    func fetchOfferings() async {
        isLoadingOfferings = true
        defer { isLoadingOfferings = false }
        do {
            offerings = try await Purchases.shared.offerings()
        } catch {
            lastError = .offeringsFetchFailed(error)
            logger.error("Failed to fetch offerings: \(error.localizedDescription)")
            Analytics.log("Failed to fetch offerings", level: .error, attributes: ["error": error.localizedDescription])
        }
    }

    /// Purchases a package. Returns `true` only if the purchase completed and the Pro
    /// entitlement is active afterward — `false` covers both cancellation and failure
    /// (check `lastError` to tell them apart).
    @discardableResult
    func purchase(package: Package) async -> Bool {
        do {
            let result = try await Purchases.shared.purchase(package: package)
            guard !result.userCancelled else { return false }
            customerInfo = result.customerInfo
            let unlocked = result.customerInfo.entitlements[RevenueCatConstants.proEntitlementID]?.isActive == true
            if unlocked {
                Analytics.capture("subscription_purchased", properties: [
                    "package_id": package.identifier
                ])
            }
            return unlocked
        } catch ErrorCode.paymentPendingError {
            // Ask to Buy / deferred approval: no unlock yet — Transaction.updates
            // (via customerInfoStream) delivers entitlement once a parent approves.
            lastError = .purchasePending
            logger.info("Purchase pending approval (Ask to Buy or deferred transaction).")
            return false
        } catch {
            lastError = .purchaseFailed(error)
            logger.error("Purchase failed: \(error.localizedDescription)")
            Analytics.log("Purchase failed", level: .error, attributes: ["error": error.localizedDescription])
            return false
        }
    }

    @discardableResult
    func restorePurchases() async -> Bool {
        do {
            let info = try await Purchases.shared.restorePurchases()
            customerInfo = info
            let unlocked = info.entitlements[RevenueCatConstants.proEntitlementID]?.isActive == true
            if unlocked {
                Analytics.capture("subscription_restored")
            }
            return unlocked
        } catch {
            lastError = .restoreFailed(error)
            logger.error("Restore failed: \(error.localizedDescription)")
            Analytics.log("Restore failed", level: .error, attributes: ["error": error.localizedDescription])
            return false
        }
    }
}

enum PurchasesManagerError: LocalizedError, Identifiable {
    case offeringsFetchFailed(Error)
    case purchaseFailed(Error)
    case purchasePending
    case restoreFailed(Error)
    case other(Error)

    var id: String { errorDescription ?? UUID().uuidString }

    var errorDescription: String? {
        switch self {
        case .offeringsFetchFailed(let error):
            "Couldn't load subscription plans. \(error.localizedDescription)"
        case .purchaseFailed(let error):
            "Purchase failed. \(error.localizedDescription)"
        case .purchasePending:
            "Waiting for approval — ask the account holder to approve this purchase, then check back."
        case .restoreFailed(let error):
            "Restore failed. \(error.localizedDescription)"
        case .other(let error):
            error.localizedDescription
        }
    }
}
