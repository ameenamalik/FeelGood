//
//  RemotePaywallView.swift
//  FeelGood
//

import PostHog
import RevenueCat
import RevenueCatUI
import SwiftUI

/// Renders the paywall designed in RevenueCat's Paywall Builder for one
/// offering, so layout, copy, imagery and packages can change from the
/// dashboard without an App Store release.
///
/// Purchase and restore run inside RevenueCatUI; this view only reports the
/// outcome so `FeelGoodPaywallView` can keep its post-purchase welcome flow,
/// trial reminder and dismissal. Close affordance is the host's
/// `guaranteedPaywallCloseButton`, so a template edited to drop its own close
/// element can never trap anyone.
struct RemotePaywallView: View {
    let offering: Offering
    let context: PaywallContext
    /// Values for `{{ custom.<name> }}` text in the Builder paywall. Each name
    /// must also be defined in the dashboard, where its default is what shows
    /// when a value isn't supplied. Stays on device: never sent to analytics.
    var variables: [String: String] = [:]
    var onPurchased: () -> Void
    var onRestored: (CustomerInfo) -> Void

    var body: some View {
        PaywallView(offering: offering, displayCloseButton: false)
            .customPaywallVariables(variables.mapValues { .string($0) })
            .onPurchaseStarted { _ in
                Analytics.capture("paywall_purchase_tapped", properties: properties)
            }
            .onPurchaseCompleted { _ in
                Analytics.capture("subscription_purchased", properties: properties)
                onPurchased()
            }
            .onPurchaseFailure { error in
                Analytics.log(
                    "Purchase failed",
                    level: .error,
                    attributes: ["error": error.localizedDescription, "source": "remote_paywall"]
                )
            }
            .onRestoreCompleted { info in
                onRestored(info)
            }
    }

    private var properties: [String: Any] {
        [
            "context": context.rawValue,
            "offering_id": offering.identifier,
            "paywall_source": "remote",
        ]
    }
}
