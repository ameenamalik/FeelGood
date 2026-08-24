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
    }

    private var lockedPlaceholder: some View {
        VStack(spacing: 16) {
            Image(systemName: "lock.fill")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            Text("This feature requires FeelGood Pro")
                .font(.headline)
            Button("Unlock FeelGood Pro") {
                isPaywallPresented = true
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}
