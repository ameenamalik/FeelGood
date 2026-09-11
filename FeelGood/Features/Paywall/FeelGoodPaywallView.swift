//
//  FeelGoodPaywallView.swift
//  FeelGood
//

import RevenueCat
import SwiftUI

/// A first-party paywall that purchases the same RevenueCat packages while
/// keeping layout, contrast, and dismissal behavior in the FeelGood design
/// system instead of a remotely styled template.
struct FeelGoodPaywallView: View {
    private enum Plan {
        case yearly
        case monthly
    }

    @Environment(PurchasesManager.self) private var purchasesManager
    @Environment(\.dismiss) private var dismiss

    @State private var selectedPlan: Plan = .yearly
    @State private var purchasingPackageID: String?
    @State private var isRestoring = false
    @State private var restoreMessage: String?

    var onFinished: (() -> Void)?

    var body: some View {
        ZStack {
            FGColor.bg.ignoresSafeArea()
            FGBrandWash(reach: 0.42).ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: FGSpace.l) {
                    closeRow
                    heading
                    benefitsCard
                    plans
                    actions
                }
                .padding(.horizontal, FGSpace.page)
                .padding(.top, FGSpace.xs)
                .padding(.bottom, FGSpace.l)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
        .task {
            if purchasesManager.offerings == nil {
                await purchasesManager.fetchOfferings()
            }
        }
        .alert(
            "Restore Purchases",
            isPresented: Binding(
                get: { restoreMessage != nil },
                set: { if !$0 { restoreMessage = nil } }
            )
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(restoreMessage ?? "")
        }
        .alert(
            purchasesManager.lastError.map {
                if case .purchasePending = $0 { "Almost there" } else { "Something went wrong" }
            } ?? "Something went wrong",
            isPresented: Binding(
                get: { purchasesManager.lastError != nil },
                set: { if !$0 { purchasesManager.lastError = nil } }
            )
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(purchasesManager.lastError?.errorDescription ?? "")
        }
    }

    private var closeRow: some View {
        HStack {
            Spacer()
            Button(action: finish) {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(FGColor.inkMuted)
                    .frame(width: FGSize.minTouchTarget, height: FGSize.minTouchTarget)
                    .background(FGColor.surface.opacity(0.86), in: Circle())
                    .overlay(Circle().strokeBorder(FGColor.line, lineWidth: 1))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Close")
        }
    }

    private var heading: some View {
        VStack(alignment: .leading, spacing: FGSpace.s) {
            Text("FeelGood Pro")
                .font(FGFont.label.weight(.semibold))
                .foregroundStyle(FGColor.inkOnAccent)
                .padding(.horizontal, FGSpace.m)
                .padding(.vertical, FGSpace.xs)
                .background(FGAura.apricot.core, in: Capsule())

            Text("Keep it personalized")
                .font(.system(.largeTitle, design: .rounded).weight(.bold))
                .tracking(-0.6)
                .foregroundStyle(FGColor.ink)

            Text("Your menu keeps adjusting to how you're actually doing, day to day.")
                .font(FGFont.reason)
                .foregroundStyle(FGColor.inkMuted)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var benefitsCard: some View {
        VStack(alignment: .leading, spacing: FGSpace.m) {
            benefit(
                artwork: "IntentStrengthApple",
                aura: .apricot,
                title: "Know what to do in 10 seconds",
                detail: "One clear next step, already picked for you."
            )
            benefit(
                artwork: "IntentStrengthPlum",
                aura: .lilac,
                title: "Feel better without tracking anything",
                detail: "No streaks, no logging, no catching up."
            )
            benefit(
                artwork: "IntentMobilityPear",
                aura: .sage,
                title: "Talk to it when you're stuck",
                detail: "Say how you feel, get something that helps."
            )
        }
        .padding(FGSpace.m)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(FGColor.surface.opacity(0.92))
        .clipShape(RoundedRectangle(cornerRadius: FGRadius.card, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: FGRadius.card, style: .continuous)
                .strokeBorder(FGColor.line.opacity(0.75), lineWidth: 1)
        )
    }

    private func benefit(artwork: String, aura: FGAura, title: String, detail: String) -> some View {
        HStack(alignment: .center, spacing: FGSpace.m) {
            Image(artwork)
                .resizable()
                .scaledToFit()
                .frame(width: 42, height: 42)
                .frame(width: 58, height: 58)
                .background(aura.core, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(FGFont.body.weight(.semibold))
                    .foregroundStyle(FGColor.ink)
                Text(detail)
                    .font(FGFont.caption)
                    .foregroundStyle(FGColor.inkMuted)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
    }

    private var plans: some View {
        VStack(spacing: FGSpace.s) {
            planCard(
                plan: .yearly,
                title: "Yearly · 7 days free",
                detail: yearlyDetail,
                badge: "Best value",
                package: purchasesManager.yearlyPackage
            )
            planCard(
                plan: .monthly,
                title: "Monthly",
                detail: monthlyDetail,
                badge: nil,
                package: purchasesManager.monthlyPackage
            )
        }
        .padding(FGSpace.s)
        .background(FGColor.surface.opacity(0.72))
        .clipShape(RoundedRectangle(cornerRadius: FGRadius.card, style: .continuous))
    }

    private func planCard(
        plan: Plan,
        title: String,
        detail: String,
        badge: String?,
        package: Package?
    ) -> some View {
        Button {
            withAnimation(FGMotion.gentle) { selectedPlan = plan }
        } label: {
            HStack(spacing: FGSpace.s) {
                Image(systemName: selectedPlan == plan ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 21, weight: .semibold))
                    .foregroundStyle(selectedPlan == plan ? FGColor.inkOnAccent : FGColor.lineStrong)

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(FGFont.body.weight(.semibold))
                        .foregroundStyle(selectedPlan == plan ? FGColor.inkOnAccent : FGColor.ink)
                    Text(package == nil && purchasesManager.isLoadingOfferings ? "Loading price…" : detail)
                        .font(FGFont.caption)
                        .foregroundStyle(
                            selectedPlan == plan
                                ? FGColor.inkOnAccent.opacity(0.72)
                                : FGColor.inkMuted
                        )
                }

                Spacer(minLength: FGSpace.xs)

                if let badge {
                    Text(badge)
                        .font(FGFont.label.weight(.semibold))
                        .foregroundStyle(FGColor.inkOnAccent)
                        .padding(.horizontal, FGSpace.s)
                        .padding(.vertical, FGSpace.xs)
                        .background(FGAura.apricot.mid, in: Capsule())
                }
            }
            .padding(FGSpace.m)
            .frame(maxWidth: .infinity, minHeight: 76, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: FGRadius.button, style: .continuous)
                    .fill(selectedPlan == plan ? FGAura.apricot.core.opacity(0.7) : FGColor.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: FGRadius.button, style: .continuous)
                    .strokeBorder(
                        selectedPlan == plan ? FGColor.inkOnAccent : FGColor.line,
                        lineWidth: selectedPlan == plan ? 1.5 : 1
                    )
            )
        }
        .buttonStyle(.plain)
        .disabled(package == nil && !purchasesManager.isLoadingOfferings)
        .accessibilityAddTraits(selectedPlan == plan ? .isSelected : [])
    }

    private var actions: some View {
        VStack(spacing: FGSpace.xs) {
            Button {
                purchaseSelectedPlan()
            } label: {
                Group {
                    if purchasingPackageID != nil {
                        ProgressView()
                            .tint(FGColor.bg)
                    } else {
                        Text(primaryButtonTitle)
                            .font(FGFont.body.weight(.semibold))
                            .foregroundStyle(FGColor.bg)
                    }
                }
                .frame(maxWidth: .infinity, minHeight: 56)
                .contentShape(Capsule())
            }
            .buttonStyle(.plain)
            .background(FGColor.ink, in: Capsule())
            .disabled(selectedPackage == nil || purchasingPackageID != nil || isRestoring)
            .opacity(selectedPackage == nil ? 0.62 : 1)

            Button("Continue with free menu", action: finish)
                .font(FGFont.body.weight(.semibold))
                .foregroundStyle(FGColor.inkMuted)
                .frame(maxWidth: .infinity, minHeight: FGSize.minTouchTarget)
                .buttonStyle(.plain)

            Button {
                Task {
                    isRestoring = true
                    let restored = await purchasesManager.restorePurchases()
                    isRestoring = false
                    if restored {
                        finish()
                    } else if purchasesManager.lastError == nil {
                        restoreMessage = "No active purchases were found for this Apple ID."
                    }
                }
            } label: {
                if isRestoring {
                    ProgressView().frame(minHeight: FGSize.minTouchTarget)
                } else {
                    Text("Restore purchases").frame(minHeight: FGSize.minTouchTarget)
                }
            }
            .font(FGFont.caption.weight(.medium))
            .foregroundStyle(FGColor.inkMuted)
            .buttonStyle(.plain)
            .disabled(isRestoring || purchasingPackageID != nil)

            HStack(spacing: FGSpace.s) {
                Link("Terms", destination: LegalLinks.termsOfUse)
                Text("·")
                Link("Privacy Policy", destination: LegalLinks.privacyPolicy)
            }
            .font(FGFont.label)
            .foregroundStyle(FGColor.inkMuted)
        }
        .frame(maxWidth: .infinity)
    }

    private var selectedPackage: Package? {
        switch selectedPlan {
        case .yearly: purchasesManager.yearlyPackage
        case .monthly: purchasesManager.monthlyPackage
        }
    }

    private var primaryButtonTitle: String {
        guard selectedPackage != nil else { return "Loading plans…" }
        return selectedPlan == .yearly ? "Start my 7 days free" : "Continue monthly"
    }

    private var yearlyDetail: String {
        purchasesManager.yearlyPackage.map { "\($0.localizedPriceString) per year" }
            ?? "Annual subscription"
    }

    private var monthlyDetail: String {
        purchasesManager.monthlyPackage.map { "\($0.localizedPriceString) per month" }
            ?? "Monthly subscription"
    }

    private func purchaseSelectedPlan() {
        guard let package = selectedPackage else { return }
        Task {
            purchasingPackageID = package.identifier
            let unlocked = await purchasesManager.purchase(package: package)
            purchasingPackageID = nil
            if unlocked { finish() }
        }
    }

    private func finish() {
        dismiss()
        onFinished?()
    }
}

#Preview {
    FeelGoodPaywallView()
        .environment(PurchasesManager.shared)
}
