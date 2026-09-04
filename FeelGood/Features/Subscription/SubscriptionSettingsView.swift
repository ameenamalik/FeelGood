//
//  SubscriptionSettingsView.swift
//  FeelGood
//

import RevenueCat
import RevenueCatUI
import SwiftUI

/// Subscription status, plan picker, restore, and Customer Center entry point. This is the
/// "manage my subscription" screen — link to it from Settings.
struct SubscriptionSettingsView: View {
    @Environment(PurchasesManager.self) private var purchasesManager

    @State private var isPaywallPresented = false
    @State private var isCustomerCenterPresented = false
    @State private var isRestoring = false
    @State private var restoreResultMessage: String?

    var body: some View {
        Form {
            statusSection
            plansSection
            manageSection
        }
        .navigationTitle("Subscription")
        .sheet(isPresented: $isPaywallPresented) {
            PaywallView(displayCloseButton: true)
        }
        .presentCustomerCenter(isPresented: $isCustomerCenterPresented)
        .alert(
            purchasesManager.lastError.map { if case .purchasePending = $0 { "Almost there" } else { "Something went wrong" } } ?? "Something went wrong",
            isPresented: Binding(
                get: { purchasesManager.lastError != nil },
                set: { if !$0 { purchasesManager.lastError = nil } }
            )
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(purchasesManager.lastError?.errorDescription ?? "")
        }
        .alert(
            "Restore Purchases",
            isPresented: Binding(
                get: { restoreResultMessage != nil },
                set: { if !$0 { restoreResultMessage = nil } }
            )
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(restoreResultMessage ?? "")
        }
    }

    private var statusSection: some View {
        Section {
            LabeledContent("Status", value: purchasesManager.isProUnlocked ? "FeelGood Pro active" : "Free")
            if let expirationDate = purchasesManager.customerInfo?
                .entitlements[RevenueCatConstants.proEntitlementID]?.expirationDate {
                LabeledContent("Renews / expires", value: expirationDate.formatted(date: .abbreviated, time: .omitted))
            }
        }
    }

    private var plansSection: some View {
        Section("FeelGood Pro") {
            if purchasesManager.isProUnlocked {
                Text("Your Pro features are unlocked.")
                    .foregroundStyle(.secondary)
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Try FeelGood Pro free")
                        .font(.headline)
                    Text("Eligible new subscribers can try the annual plan free for 7 days.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Button("See plans and start trial") {
                    isPaywallPresented = true
                }
            }
        }
    }

    private var manageSection: some View {
        Section {
            Button("Restore Purchases") {
                Task {
                    isRestoring = true
                    let unlocked = await purchasesManager.restorePurchases()
                    isRestoring = false
                    restoreResultMessage = unlocked
                        ? "FeelGood Pro restored."
                        : "No active purchases found for this Apple ID."
                }
            }
            .disabled(isRestoring)

            // Customer Center needs purchase history to have anything to show; RevenueCat
            // handles that gracefully, but hiding the entry point for never-purchased users
            // avoids a confusing empty screen.
            if purchasesManager.customerInfo?.originalPurchaseDate != nil {
                Button("Manage Subscription") {
                    isCustomerCenterPresented = true
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        SubscriptionSettingsView()
    }
    .environment(PurchasesManager.shared)
}
