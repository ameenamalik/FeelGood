//
//  ProGateView.swift
//  FeelGood
//

import RevenueCatUI
import SwiftUI

/// Wraps a piece of UI that should only be visible to FeelGood Pro subscribers. Shows the
/// wrapped content once the entitlement is active; otherwise shows a locked placeholder that
/// opens RevenueCat's paywall on tap.
///
/// Use this for gating an individual feature/section. To gate an entire screen as soon as it
/// appears, prefer the `.presentPaywallIfNeeded(requiredEntitlementIdentifier:)` modifier —
/// RevenueCat auto-dismisses that paywall once the entitlement becomes active, no extra state
/// needed.
struct ProGateView<Content: View>: View {
    @Environment(PurchasesManager.self) private var purchasesManager
    @State private var isPaywallPresented = false

    @ViewBuilder let content: () -> Content

    var body: some View {
        Group {
            if purchasesManager.isProUnlocked {
                content()
            } else {
                lockedPlaceholder
            }
        }
        .sheet(isPresented: $isPaywallPresented) {
            PaywallView(displayCloseButton: true)
        }
        .task {
            await purchasesManager.refreshCustomerInfo()
        }
    }

    private var lockedPlaceholder: some View {
        ZStack {
            FGColor.bg.ignoresSafeArea()
            FGBrandWash(reach: 0.55).ignoresSafeArea()

            VStack(spacing: FGSpace.l) {
                Image(systemName: "sparkles")
                    .font(.system(size: 34, weight: .medium))
                    .foregroundStyle(FGColor.goldDeep)
                    .accessibilityHidden(true)

                VStack(spacing: FGSpace.s) {
                    Text("Your FeelGood companion")
                        .font(FGFont.title)
                        .foregroundStyle(FGColor.ink)
                    Text("Talk through what you need and reshape today’s menu in seconds with FeelGood Pro.")
                        .font(FGFont.body)
                        .foregroundStyle(FGColor.inkMuted)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }

                FGPrimaryButton(title: "See FeelGood Pro") {
                    isPaywallPresented = true
                }
                .frame(maxWidth: 280)
            }
            .padding(FGSpace.page)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
