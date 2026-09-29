//
//  FeelGoodPaywallView.swift
//  FeelGood
//

import RevenueCat
import SwiftUI

/// Why the paywall was opened. The screen immediately showcases the relevant
/// superpower before the person explores the broader Pro story.
nonisolated enum PaywallContext: String, Sendable {
    case general
    case secondSwap = "second_swap"
    case library
    case chatLimit = "chat_limit"
    case calendar
}

/// FeelGood Pro Paywall.
///
/// Designed around RevenueCat's LTV & JTBD conversion architecture:
/// 1. Problem-Led Headline ("A menu that bends to your day")
/// 2. Live Superpower Demonstrations (Instant Contrast Swap, Companion Chat, Calendar Auto-Fit)
/// 3. Scannable 3-Point Value Anchors (No tiny grey text)
/// 4. LTV-Optimized Offer Architecture (Yearly default with 7-day free trial & SAVE 58% badge)
/// 5. Value-Led CTA in the Thumb Zone ("Start my 7-day free trial")
struct FeelGoodPaywallView: View {
    let context: PaywallContext
    var onFinished: (() -> Void)?

    private enum Plan: CaseIterable {
        case yearly
        case monthly

        var title: String {
            switch self {
            case .yearly: "Yearly"
            case .monthly: "Monthly"
            }
        }

        var renewalSuffix: String {
            switch self {
            case .yearly: "/yr"
            case .monthly: "/mo"
            }
        }

        var analyticsID: String {
            switch self {
            case .yearly: "yearly"
            case .monthly: "monthly"
            }
        }
    }

    /// The 3 Core Pro Superpowers
    private enum Superpower: Int, CaseIterable, Identifiable {
        case swaps = 0
        case chat = 1
        case calendar = 2

        var id: Int { rawValue }

        var label: String {
            switch self {
            case .swaps: "Swaps"
            case .chat: "Chat"
            case .calendar: "Calendar"
            }
        }

        var sfSymbol: String {
            switch self {
            case .swaps: "arrow.triangle.2.circlepath"
            case .chat: "bubble.left.and.bubble.right"
            case .calendar: "calendar"
            }
        }

        var iconAsset: String {
            switch self {
            case .swaps: Course.appetizer.menuMascotAsset // Clementine
            case .chat: "IntentCalmBlueberryMascot"
            case .calendar: Course.special.menuMascotAsset // Banana
            }
        }

        var badgeLabel: String {
            switch self {
            case .swaps: "Instant Swap"
            case .chat: "AI Companion"
            case .calendar: "Calendar Sync"
            }
        }

        var badgeColor: Color {
            switch self {
            case .swaps: FGColor.clay
            case .chat: FGColor.sky
            case .calendar: FGColor.gold
            }
        }
    }

    @Environment(\.dismiss) private var dismiss
    @Environment(PurchasesManager.self) private var purchasesManager
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var typeSize

    @State private var selectedPlan: Plan = .yearly
    @State private var isPurchasing = false
    @State private var trialEligiblePlans: Set<Plan> = []
    @State private var isRestoring = false
    @State private var restoreResultMessage: String?
    @State private var activeSuperpower: Superpower = .swaps
    @State private var carouselResetToken = 0

    init(
        context: PaywallContext = .general,
        onFinished: (() -> Void)? = nil
    ) {
        self.context = context
        self.onFinished = onFinished
    }

    private var yearlyPackage: Package? { purchasesManager.yearlyPackage }
    private var monthlyPackage: Package? { purchasesManager.monthlyPackage }

    private var selectedPackage: Package? {
        switch selectedPlan {
        case .yearly: yearlyPackage
        case .monthly: monthlyPackage
        }
    }

    var body: some View {
        ZStack {
            FGColor.bg.ignoresSafeArea()
            // Vibrant ambient brand aura bloom
            FGBrandWash(reach: 0.85).ignoresSafeArea()

            if purchasesManager.isLoadingOfferings, yearlyPackage == nil, monthlyPackage == nil {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                content
            }
        }
        .guaranteedPaywallCloseButton { finish() }
        .sensoryFeedback(.selection, trigger: selectedPlan)
        .sensoryFeedback(.impact(weight: .medium), trigger: activeSuperpower)
        .task {
            // Set initial superpower tab based on presentation context
            switch context {
            case .secondSwap, .library, .general:
                activeSuperpower = .swaps
            case .chatLimit:
                activeSuperpower = .chat
            case .calendar:
                activeSuperpower = .calendar
            }

            if purchasesManager.offerings == nil {
                await purchasesManager.fetchOfferings()
            }
            if yearlyPackage == nil, monthlyPackage != nil {
                selectedPlan = .monthly
            }
            await refreshTrialEligibility()
            Analytics.capture("paywall_impression", properties: [
                "plan": selectedPlan.analyticsID,
                "context": context.rawValue,
            ])
        }
        .alert(
            purchasesManager.lastError?.alertTitle ?? "Something went wrong",
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

    private var content: some View {
        ScrollView {
            VStack(spacing: FGSpace.m) {
                // 1. Problem-Led Headline & Eyebrow
                headerSection

                // 2. Interactive Superpower Tabs & Hero Demo
                VStack(spacing: FGSpace.s + 2) {
                    superpowerTabBar
                    superpowerHeroCard
                }

                // 3. LTV-Optimized Plan Picker
                planPicker

                // 4. Thumb-Zone CTA for Accessibility sizes
                if typeSize.isAccessibilitySize {
                    ctaButtons
                }

                // 5. Transparent Fine Print & Legal
                legalSection
            }
            .padding(.horizontal, FGSpace.page)
            .padding(.top, FGSize.minTouchTarget + FGSpace.xs)
            .padding(.bottom, FGSpace.l)
        }
        .scrollBounceBehavior(.basedOnSize)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if !typeSize.isAccessibilitySize {
                ctaButtons
                    .padding(.horizontal, FGSpace.page)
                    .padding(.top, FGSpace.s)
                    .overlay(alignment: .top) {
                        Divider().overlay(FGColor.line)
                    }
            }
        }
    }

    // MARK: - 1. Header Section (Problem-Led JTBD)

    private var headerSection: some View {
        VStack(spacing: 8) {
            HStack(spacing: 6) {
                Text("✦ FeelGood Pro")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .tracking(0.3)
                    .foregroundStyle(FGColor.sageDeep)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            .background(Capsule().fill(FGColor.sagePanel))
            .overlay(Capsule().strokeBorder(FGColor.sideBadge.opacity(0.3), lineWidth: 1))

            Text("Stop deciding.\nStart moving.")
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .tracking(-0.8)
                .foregroundStyle(FGColor.ink)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            Text("Movement that bends to your day.")
                .font(FGFont.reason.weight(.medium))
                .foregroundStyle(FGColor.inkMuted)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 2)
    }

    // MARK: - 2. Superpower Tab Bar & Hero Card

    private var superpowerTabBar: some View {
        HStack(spacing: 6) {
            ForEach(Superpower.allCases) { power in
                let isSelected = activeSuperpower == power
                Button {
                    withAnimation(reduceMotion ? nil : FGMotion.swap) {
                        activeSuperpower = power
                        carouselResetToken += 1
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: power.sfSymbol)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(isSelected ? FGColor.inkOnAccent : FGColor.inkMuted)

                        Text(power.label)
                            .font(.system(size: 12, weight: isSelected ? .bold : .semibold, design: .rounded))
                            .foregroundStyle(isSelected ? FGColor.inkOnAccent : FGColor.inkMuted)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(
                        Capsule().fill(isSelected ? AnyShapeStyle(power.badgeColor) : AnyShapeStyle(FGColor.surface.opacity(0.7)))
                    )
                    .overlay(
                        Capsule().strokeBorder(isSelected ? FGColor.ink.opacity(0.2) : FGColor.line, lineWidth: 1)
                    )
                    .scaleEffect(isSelected ? 1.03 : 1.0)
                }
                .buttonStyle(.plain)
            }
        }
        .task(id: carouselResetToken) { await runSuperpowerAutoCycle() }
    }

    /// Fixed 170pt height so there is zero screen jumping between slides
    private var superpowerHeroCard: some View {
        ZStack(alignment: .center) {
            switch activeSuperpower {
            case .swaps:
                swapsHeroContent
                    .transition(.opacity)
            case .chat:
                chatHeroContent
                    .transition(.opacity)
            case .calendar:
                calendarHeroContent
                    .transition(.opacity)
            }
        }
        .padding(FGSpace.m)
        .frame(maxWidth: .infinity)
        .frame(height: 170, alignment: .center)
        .background(
            RoundedRectangle(cornerRadius: FGRadius.card, style: .continuous)
                .fill(FGColor.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: FGRadius.card, style: .continuous)
                .strokeBorder(FGColor.lineStrong, lineWidth: 1)
        )
        .shadow(color: FGColor.ink.opacity(0.06), radius: 12, y: 4)
        .animation(reduceMotion ? nil : FGMotion.gentle, value: activeSuperpower)
    }

    // MARK: - Hero Content 1: Instant Contrast Swap

    private var swapsHeroContent: some View {
        VStack(spacing: 12) {
            // The Before -> After Transformation
            HStack(spacing: 10) {
                // Before Card
                VStack(spacing: 5) {
                    Image(Course.main.menuMascotAsset)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 36, height: 36)
                        .padding(5)
                        .background(Circle().fill(FGColor.surface))

                    Text("20m Flow")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(FGColor.ink)

                    Text("Scheduled")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(FGColor.inkMuted)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Course.main.fill.opacity(0.35))
                )

                // Plum Animated Arrow
                ZStack {
                    Circle()
                        .fill(FGColor.actionFill)
                        .frame(width: 32, height: 32)
                    Image(systemName: "arrow.right")
                        .font(.system(size: 13, weight: .black))
                        .foregroundStyle(FGColor.onActionFill)
                }

                // After Card
                VStack(spacing: 5) {
                    Image(Course.dessert.menuMascotAsset)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 36, height: 36)
                        .padding(5)
                        .background(Circle().fill(FGColor.surface))

                    Text("5m Unwind")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(FGColor.ink)

                    Text("Subbed in 1 tap")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(FGColor.sageDeep)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Course.dessert.fill.opacity(0.35))
                )
            }

            Text("Too tired? Swap any session instantly.")
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(FGColor.inkMuted)
        }
    }

    // MARK: - Hero Content 2: Companion Chat

    private var chatHeroContent: some View {
        VStack(spacing: 8) {
            // Subtle time marker indicating an evening check-in
            HStack(spacing: 5) {
                Image(systemName: "moon.stars.fill")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(FGColor.sageDeep)

                Text("8:00 PM · Evening check-in")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(FGColor.sageDeep)

                Spacer()

                Text("Unlimited")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(FGColor.inkMuted)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(FGColor.surface.opacity(0.8)))
            }

            VStack(alignment: .leading, spacing: 6) {
                // User check-in bubble
                HStack {
                    Spacer(minLength: 24)
                    Text("Exhausted and brain won't shut off.")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(FGColor.onDeepFill)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(FGColor.userBubble)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }

                // Companion recommendation
                HStack(spacing: 8) {
                    Image("IntentCalmBlueberryMascot")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 28, height: 28)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("7-min legs-up-the-wall breathwork")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundStyle(FGColor.ink)
                        Text("Floor rest · Quiet the noise")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(FGColor.inkMuted)
                    }

                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(FGColor.sagePanel)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }

            Text("Check in whenever your energy changes.")
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(FGColor.inkMuted)
        }
    }

    // MARK: - Hero Content 3: Calendar Sync

    private var calendarHeroContent: some View {
        VStack(spacing: 10) {
            VStack(spacing: 6) {
                HStack {
                    Text("1:00 PM – 2:00 PM")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(FGColor.inkMuted)
                    Spacer()
                    Text("Team Sync")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(FGColor.inkMuted)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(FGColor.panel.opacity(0.5))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                HStack(spacing: 8) {
                    Image(Course.special.menuMascotAsset)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 26, height: 26)

                    VStack(alignment: .leading, spacing: 1) {
                        Text("15-min free gap detected")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(FGColor.sageDeep)
                        Text("10-min Posture Reset")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundStyle(FGColor.ink)
                    }

                    Spacer()

                    Text("Auto-fit")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(FGColor.sageDeep)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(FGColor.surface))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(FGColor.sagePanel)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }

            Text("Finds open windows between meetings automatically.")
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(FGColor.inkMuted)
        }
    }

    private func runSuperpowerAutoCycle() async {
        guard !reduceMotion else { return }
        while !Task.isCancelled {
            try? await Task.sleep(for: .seconds(4))
            guard !Task.isCancelled else { return }
            withAnimation(FGMotion.swap) {
                let all = Superpower.allCases
                let nextIdx = (activeSuperpower.rawValue + 1) % all.count
                activeSuperpower = all[nextIdx]
            }
        }
    }

    // MARK: - 4. Plan Picker (LTV-Optimized Offer Architecture)

    private var planPicker: some View {
        VStack(spacing: FGSpace.s + 4) {
            if let yearlyPackage {
                planCard(.yearly, package: yearlyPackage)
            }
            if let monthlyPackage {
                planCard(.monthly, package: monthlyPackage)
            }
        }
    }

    private func planCard(_ plan: Plan, package: Package) -> some View {
        let isSelected = selectedPlan == plan

        return Button {
            withAnimation(FGMotion.swap) { selectedPlan = plan }
        } label: {
            HStack(spacing: FGSpace.m) {
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: FGSpace.xs) {
                        Text(plan.title)
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundStyle(isSelected ? FGColor.inkOnAccent : FGColor.ink)

                        if let trial = freeTrialPeriod(for: plan, package: package) {
                            Text("· \(trialLength(trial)) free")
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundStyle(isSelected ? FGColor.inkOnAccent : FGColor.sageDeep)
                        }
                    }

                    // Guideline 3.1.2(c): the amount billed has to be the most
                    // prominent price on the card, so it carries the weight and
                    // the per-month figure stays secondary.
                    HStack(spacing: 4) {
                        Text(priceLine(for: package, plan: plan))
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundStyle(isSelected ? FGColor.inkOnAccent : FGColor.ink)

                        if plan == .yearly, let monthlyEquivalent = monthlyEquivalentCaption(for: package) {
                            Text("· \(monthlyEquivalent)")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(isSelected ? FGColor.inkOnAccent : FGColor.inkMuted)
                        }
                    }
                }

                Spacer(minLength: 0)

            }
            .padding(.horizontal, FGSpace.m)
            .padding(.vertical, FGSpace.m - 2)
            .frame(minHeight: FGSize.minTouchTarget + 14)
            .background(
                RoundedRectangle(cornerRadius: FGRadius.card, style: .continuous)
                    .fill(isSelected ? AnyShapeStyle(FGAura.sage.mid) : AnyShapeStyle(FGColor.surface.opacity(0.8)))
            )
            .overlay(
                RoundedRectangle(cornerRadius: FGRadius.card, style: .continuous)
                    .strokeBorder(isSelected ? FGColor.inkOnAccent : FGColor.lineStrong, lineWidth: isSelected ? 3 : 1)
            )
            .shadow(color: FGColor.ink.opacity(isSelected ? 0.08 : 0), radius: 8, y: 4)
        }
        .buttonStyle(.plain)
        .overlay(alignment: .topTrailing) {
            if plan == .yearly, let savingsPercent {
                Text("Save \(savingsPercent)%")
                    .font(.system(.caption2, design: .rounded).weight(.bold))
                    .tracking(0.3)
                    .foregroundStyle(FGColor.onDeepFill)
                    .padding(.horizontal, FGSpace.s + 2)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(FGColor.sideBadge))
                    .padding(.trailing, FGSpace.m)
                    .offset(y: -10)
                    .allowsHitTesting(false)
            }
        }
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }

    private var savingsPercent: Int? {
        guard let yearlyPackage, let monthlyPackage else { return nil }
        let yearlyPrice = NSDecimalNumber(decimal: yearlyPackage.storeProduct.price).doubleValue
        let annualizedMonthly = NSDecimalNumber(decimal: monthlyPackage.storeProduct.price).doubleValue * 12
        guard annualizedMonthly > 0 else { return nil }
        let saved = 1 - (yearlyPrice / annualizedMonthly)
        guard saved > 0 else { return nil }
        return Int((saved * 100).rounded())
    }

    private func refreshTrialEligibility() async {
        var eligible: Set<Plan> = []
        for (plan, package) in [(Plan.yearly, yearlyPackage), (Plan.monthly, monthlyPackage)] {
            guard let package else { continue }
            let status = await Purchases.shared.checkTrialOrIntroDiscountEligibility(product: package.storeProduct)
            if status == .eligible { eligible.insert(plan) }
        }
        trialEligiblePlans = eligible
    }

    private func priceLine(for package: Package, plan: Plan) -> String {
        let product = package.storeProduct
        let unit = plan == .yearly ? "a year" : "a month"
        return "\(product.localizedPriceString) \(unit)"
    }

    private func monthlyEquivalentCaption(for package: Package) -> String? {
        guard let perMonth = package.storeProduct.localizedPricePerMonth else { return nil }
        return "\(perMonth)/mo"
    }

    /// The free trial this person would actually get on `plan`, or nil. Read
    /// from StoreKit rather than written into the copy, so the card, the
    /// button and App Store Connect can never disagree about its length.
    private func freeTrialPeriod(for plan: Plan, package: Package) -> SubscriptionPeriod? {
        guard trialEligiblePlans.contains(plan),
              let discount = package.storeProduct.introductoryDiscount,
              discount.paymentMode == .freeTrial else { return nil }
        return discount.subscriptionPeriod
    }

    /// "7 days" rather than "1 week", so the badge and the button read the same.
    private func trialLength(_ period: SubscriptionPeriod) -> String {
        let (value, unit): (Int, String) = switch period.unit {
        case .day: (period.value, "day")
        case .week: (period.value * 7, "day")
        case .month: (period.value, "month")
        case .year: (period.value, "year")
        @unknown default: (period.value, "day")
        }
        return value == 1 ? "1 \(unit)" : "\(value) \(unit)s"
    }

    // MARK: - 5. Value-Led CTA Buttons (Thumb-Zone)

    private var selectedTrial: SubscriptionPeriod? {
        guard let selectedPackage else { return nil }
        return freeTrialPeriod(for: selectedPlan, package: selectedPackage)
    }

    private var ctaTitle: String {
        guard let selectedPackage else { return "Continue" }
        guard let trial = selectedTrial else {
            return "Subscribe · \(selectedPackage.storeProduct.localizedPriceString)\(selectedPlan.renewalSuffix)"
        }
        return "Try \(trialLength(trial)) free"
    }

    /// What happens after the tap, next to the tap: the billed amount, when
    /// it's charged, and that it renews until cancelled (Guideline 3.1.2).
    private var billingDisclosure: String? {
        guard let selectedPackage else { return nil }
        let price = priceLine(for: selectedPackage, plan: selectedPlan)
        let renewal = "Renews automatically until you cancel in Settings."
        guard let trial = selectedTrial else { return "\(price). \(renewal)" }
        return "Free for \(trialLength(trial)), then \(price). \(renewal)"
    }

    private var ctaButtons: some View {
        VStack(spacing: FGSpace.s) {
            if let billingDisclosure {
                Text(billingDisclosure)
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(FGColor.ink)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity)
            }

            FGPrimaryButton(title: ctaTitle, isEnabled: selectedPackage != nil && !isPurchasing) {
                purchaseSelectedPlan()
            }

            Button {
                Analytics.capture("paywall_declined", properties: ["plan": selectedPlan.analyticsID])
                finish()
            } label: {
                Text("Continue with free menu")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(FGColor.inkMuted)
                    .frame(maxWidth: .infinity, minHeight: FGSize.minTouchTarget - 4)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - 6. Transparent Fine Print & Legal

    private var legalSection: some View {
        HStack(spacing: 8) {
            Text("Auto-renews")
            Text("·")
            Link("Terms", destination: LegalLinks.termsOfUse)
            Text("·")
            Link("Privacy", destination: LegalLinks.privacyPolicy)
            Text("·")
            restoreButton
        }
        .font(.system(size: 11, weight: .medium))
        .foregroundStyle(FGColor.inkMuted.opacity(0.8))
        .padding(.top, 2)
    }

    private var restoreButton: some View {
        Button {
            Task {
                isRestoring = true
                let unlocked = await purchasesManager.restorePurchases()
                isRestoring = false
                if unlocked {
                    finish()
                } else {
                    restoreResultMessage = "No active purchases found for this Apple ID. Try signing in with the Apple ID you subscribed with."
                }
            }
        } label: {
            if isRestoring {
                ProgressView()
                    .scaleEffect(0.8)
            } else {
                Text("Restore")
            }
        }
        .buttonStyle(.plain)
        .disabled(isRestoring)
    }

    private func purchaseSelectedPlan() {
        guard let selectedPackage, !isPurchasing else { return }
        isPurchasing = true
        Analytics.capture("paywall_purchase_tapped", properties: ["plan": selectedPlan.analyticsID])
        Task {
            let unlocked = await purchasesManager.purchase(package: selectedPackage)
            isPurchasing = false
            if unlocked { finish() }
        }
    }

    private func finish() {
        dismiss()
        onFinished?()
    }
}

#Preview("General (Swaps)") {
    FeelGoodPaywallView(context: .general)
        .environment(PurchasesManager.shared)
}

#Preview("Chat Limit (Evening Check-in)") {
    FeelGoodPaywallView(context: .chatLimit)
        .environment(PurchasesManager.shared)
}

#Preview("Calendar Context") {
    FeelGoodPaywallView(context: .calendar)
        .environment(PurchasesManager.shared)
}
