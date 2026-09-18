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
    @Environment(\.dismiss) private var dismiss

    @State private var isPaywallPresented = false
    @State private var isCustomerCenterPresented = false
    @State private var isRestoring = false
    @State private var restoreResultMessage: String?

    var body: some View {
        ZStack {
            FGColor.bg.ignoresSafeArea()
            FGBrandWash(reach: 0.34).ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    heading

                    VStack(spacing: 12) {
                        statusCard
                        includedCard
                    }

                    actions
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, FGSpace.page)
                .padding(.top, FGSpace.s)
                .padding(.bottom, FGSpace.l)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
        .navigationTitle("Your plan")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") { dismiss() }
            }
        }
        .sheet(isPresented: $isPaywallPresented) {
            FeelGoodPaywallView()
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
        .task {
            await purchasesManager.refreshCustomerInfo()
            if purchasesManager.offerings == nil {
                await purchasesManager.fetchOfferings()
            }
        }
    }

    private var heading: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Your FeelGood plan")
                .font(.system(.largeTitle, design: .rounded).weight(.semibold))
                .foregroundStyle(FGColor.ink)
            Text("See what you have now, or choose what comes next.")
                .font(FGFont.reason)
                .foregroundStyle(FGColor.inkMuted)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var statusCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .center, spacing: 14) {
                Image(systemName: purchasesManager.isProUnlocked ? "checkmark.seal.fill" : "heart.fill")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(purchasesManager.isProUnlocked ? FGColor.sageDeep : FGColor.clayDeep)
                    .frame(width: 44, height: 44)
                    .background(FGColor.surface.opacity(0.72))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 3) {
                    Text("CURRENT PLAN")
                        .font(FGFont.caption.weight(.semibold))
                        .tracking(0.8)
                        .foregroundStyle(FGColor.inkOnAccent.opacity(0.7))
                    Text(purchasesManager.isProUnlocked ? "FeelGood Pro" : "FeelGood Free")
                        .font(FGFont.sectionTitle)
                        .foregroundStyle(FGColor.inkOnAccent)
                    Text(statusDetail)
                        .font(FGFont.reason)
                        .foregroundStyle(FGColor.inkOnAccent.opacity(0.72))
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)
            }

            if let expirationDate = purchasesManager.customerInfo?
                .entitlements[RevenueCatConstants.proEntitlementID]?.expirationDate {
                Divider().overlay(FGColor.line)
                HStack {
                    Text("Renews or expires")
                    Spacer()
                    Text(expirationDate.formatted(date: .abbreviated, time: .omitted))
                        .fontWeight(.medium)
                }
                .font(FGFont.caption)
                .foregroundStyle(FGColor.inkOnAccent.opacity(0.72))
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(statusGradient)
        .clipShape(RoundedRectangle(cornerRadius: FGRadius.card, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: FGRadius.card, style: .continuous)
                .strokeBorder(FGColor.lineStrong.opacity(0.65), lineWidth: 1)
        )
    }

    private var includedCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(purchasesManager.isProUnlocked ? "Your Pro access" : "Included with Free")
                .font(FGFont.itemTitle)
                .foregroundStyle(FGColor.ink)

            VStack(alignment: .leading, spacing: 14) {
                if purchasesManager.isProUnlocked {
                    feature("Unlimited companion chat", symbol: "bubble.left.and.bubble.right")
                    feature("Unlimited menu adjustments", symbol: "slider.horizontal.3")
                    feature("Calendar-aware planning", symbol: "calendar")
                } else {
                    feature("A fresh daily movement menu", symbol: "sun.max")
                    feature("Daily check-ins", symbol: "heart")
                    feature("One companion chat exchange", symbol: "bubble.left")
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(FGColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: FGRadius.card, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: FGRadius.card, style: .continuous)
                .strokeBorder(FGColor.line, lineWidth: 1)
        )
    }

    private var actions: some View {
        VStack(spacing: FGSpace.xs) {
            if purchasesManager.isProUnlocked {
                FGPrimaryButton(title: "Manage subscription") {
                    isCustomerCenterPresented = true
                }
            } else {
                FGPrimaryButton(title: "See FeelGood Pro plans") {
                    Analytics.capture("subscription_paywall_presented", properties: [
                        "source": "plan_status"
                    ])
                    isPaywallPresented = true
                }

                Text("The next screen shows current prices and any trial you’re eligible for.")
                    .font(FGFont.caption)
                    .foregroundStyle(FGColor.inkMuted)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
            }

            Button {
                Task {
                    isRestoring = true
                    let unlocked = await purchasesManager.restorePurchases()
                    isRestoring = false
                    restoreResultMessage = unlocked
                        ? "FeelGood Pro restored."
                        : "No active purchases found for this Apple ID. Try signing in with the Apple ID you subscribed with."
                }
            } label: {
                if isRestoring {
                    ProgressView()
                        .frame(maxWidth: .infinity, minHeight: FGSize.minTouchTarget)
                } else {
                    Text("Restore purchases")
                        .font(FGFont.body.weight(.medium))
                        .foregroundStyle(FGColor.inkMuted)
                        .frame(maxWidth: .infinity, minHeight: FGSize.minTouchTarget)
                }
            }
            .buttonStyle(.plain)
            .disabled(isRestoring)
        }
        .frame(maxWidth: .infinity)
    }

    private func feature(_ title: String, symbol: String) -> some View {
        Label {
            Text(title)
                .font(FGFont.body)
                .foregroundStyle(FGColor.ink)
        } icon: {
            Image(systemName: symbol)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(FGColor.goldDeep)
                .frame(width: 24)
        }
    }

    private var statusDetail: String {
        if !purchasesManager.hasLoadedCustomerInfo {
            return "Checking your subscription status…"
        }
        return purchasesManager.isProUnlocked
            ? "All FeelGood Pro features are unlocked."
            : "Your daily menu and core check-in are available without a subscription."
    }

    private var statusGradient: LinearGradient {
        LinearGradient(
            colors: purchasesManager.isProUnlocked
                ? [FGAura.sage.core, FGAura.butter.core]
                : [FGAura.blush.core, FGAura.apricot.core],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

#Preview {
    NavigationStack {
        SubscriptionSettingsView()
    }
    .environment(PurchasesManager.shared)
}
