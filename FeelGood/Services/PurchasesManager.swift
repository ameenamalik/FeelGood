//
//  PurchasesManager.swift
//  FeelGood
//

import Foundation
import Observation
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

    var isProUnlocked: Bool {
        customerInfo?.entitlements[RevenueCatConstants.proEntitlementID]?.isActive == true
    }

    /// The current offering's monthly/yearly packages, when available, for direct purchase buttons.
    var monthlyPackage: Package? { offerings?.current?.monthly }
    var yearlyPackage: Package? { offerings?.current?.annual }

    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.feelgood.app", category: "Purchases")
    private var customerInfoObservationTask: Task<Void, Never>?

    private init() {}

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
            await fetchOfferings()
        }
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
        }
    }

    func logOut() async {
        do {
            customerInfo = try await Purchases.shared.logOut()
            hasLoadedCustomerInfo = true
        } catch {
            lastError = .other(error)
            logger.error("logOut failed: \(error.localizedDescription)")
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
                self.logger.debug("CustomerInfo updated — pro active: \(info.entitlements[RevenueCatConstants.proEntitlementID]?.isActive == true)")
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
            return result.customerInfo.entitlements[RevenueCatConstants.proEntitlementID]?.isActive == true
        } catch {
            lastError = .purchaseFailed(error)
            logger.error("Purchase failed: \(error.localizedDescription)")
            return false
        }
    }

    @discardableResult
    func restorePurchases() async -> Bool {
        do {
            let info = try await Purchases.shared.restorePurchases()
            customerInfo = info
            return info.entitlements[RevenueCatConstants.proEntitlementID]?.isActive == true
        } catch {
            lastError = .restoreFailed(error)
            logger.error("Restore failed: \(error.localizedDescription)")
            return false
        }
    }
}

enum PurchasesManagerError: LocalizedError, Identifiable {
    case offeringsFetchFailed(Error)
    case purchaseFailed(Error)
    case restoreFailed(Error)
    case other(Error)

    var id: String { errorDescription ?? UUID().uuidString }

    var errorDescription: String? {
        switch self {
        case .offeringsFetchFailed(let error):
            "Couldn't load subscription plans. \(error.localizedDescription)"
        case .purchaseFailed(let error):
            "Purchase failed. \(error.localizedDescription)"
        case .restoreFailed(let error):
            "Restore failed. \(error.localizedDescription)"
        case .other(let error):
            error.localizedDescription
        }
    }
}
