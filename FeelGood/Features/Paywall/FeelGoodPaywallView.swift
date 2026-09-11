//
//  FeelGoodPaywallView.swift
//  FeelGood
//

import RevenueCat
import RevenueCatUI
import SwiftUI

/// Presents the paywall attached to RevenueCat's current offering.
///
/// All paywall content, packages, pricing, and styling come from RevenueCat so
/// dashboard changes can ship without an app update. This wrapper only bridges
/// RevenueCat's dismissal and entitlement callbacks into the app's flows.
struct FeelGoodPaywallView: View {
    @Environment(\.dismiss) private var dismiss

    var onFinished: (() -> Void)?

    var body: some View {
        PaywallView(displayCloseButton: true)
            .onRequestedDismissal {
                finish()
            }
            .onPurchaseCompleted { customerInfo in
                finishIfProIsActive(in: customerInfo)
            }
            .onRestoreCompleted { customerInfo in
                finishIfProIsActive(in: customerInfo)
            }
    }

    private func finishIfProIsActive(in customerInfo: CustomerInfo) {
        guard PurchasesManager.hasActiveProEntitlement(in: customerInfo) else {
            return
        }
        finish()
    }

    private func finish() {
        dismiss()
        onFinished?()
    }
}

#Preview {
    FeelGoodPaywallView()
}
