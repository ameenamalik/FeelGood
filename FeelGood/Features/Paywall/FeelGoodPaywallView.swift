//
//  FeelGoodPaywallView.swift
//  FeelGood
//

import RevenueCat
import SwiftUI

/// FeelGood's own paywall. Unlike the dashboard-configured screen it replaced,
/// the hero shows the real menu — the same course/course-mascot pairing
/// (`Course.menuMascotAsset`) already shipping on Today and My Menu — instead
/// of a standalone illustration. The fruits don't get their own dialogue here;
/// they're doing the job they already do everywhere else in the app: marking
/// which course is which. RevenueCat still owns products, pricing, and the
/// purchase itself; this view only decides what to show and calls
/// `PurchasesManager`.
struct FeelGoodPaywallView: View {
    private enum Plan: CaseIterable {
        case yearly
        case monthly

        var title: String {
            switch self {
            case .yearly: "Yearly"
            case .monthly: "Monthly"
            }
        }

        var analyticsID: String {
            switch self {
            case .yearly: "yearly"
            case .monthly: "monthly"
            }
        }
    }

    /// A course teaser row for the hero. Real course/mascot pairing, placeholder
    /// session titles pulled from the app's own App Store screenshots so the copy
    /// is already-approved rather than invented for this screen.
    private struct MenuTeaser {
        let course: Course
        let title: String
    }

    private static let menuTeasers: [MenuTeaser] = [
        MenuTeaser(course: .appetizer, title: "Four rounds of box breathing"),
        MenuTeaser(course: .main, title: "Twenty minutes of gentle flow"),
        MenuTeaser(course: .side, title: "Shoulder reset between meetings"),
        MenuTeaser(course: .dessert, title: "Ten minutes in the light"),
    ]

    /// Which illustration sits above a given slide's line. Most slides show
    /// the menu; "Talk to it when you're stuck" swaps in a chat exchange,
    /// since that's the one benefit the menu card can't demonstrate on its own.
    private enum HeroScene {
        case menu
        case chat
    }

    /// One slide at a time instead of a fixed headline plus a separate
    /// benefits list — the header rotates through the hook and the benefits
    /// itself, so only one short line is ever on screen in this spot.
    private struct HeroSlide {
        let title: String
        let scene: HeroScene
    }

    private static let heroSlides: [HeroSlide] = [
        HeroSlide(title: "Stop deciding. Start moving.", scene: .menu),
        HeroSlide(title: "Know what to do in 10 seconds", scene: .menu),
        HeroSlide(title: "Say how you're feeling", scene: .chat),
        HeroSlide(title: "Talk to it when you're stuck", scene: .chat),
    ]

    @Environment(\.dismiss) private var dismiss
    @Environment(PurchasesManager.self) private var purchasesManager
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var onFinished: (() -> Void)?

    @State private var selectedPlan: Plan = .yearly
    @State private var isPurchasing = false
    @State private var isRestoring = false
    @State private var restoreResultMessage: String?
    @State private var hasRevealedMenu = false
    #if DEBUG
    @State private var heroSlideIndex = Self.debugForcedHeroSlideIndex ?? 0
    @State private var chatPhase: ChatPhase = (Self.debugForcedHeroSlideIndex == 3) ? .assistantFollowUp : .userOpener
    #else
    @State private var heroSlideIndex = 0
    @State private var chatPhase: ChatPhase = .userOpener
    #endif

    #if DEBUG
    private static var debugForcedHeroSlideIndex: Int? {
        let args = ProcessInfo.processInfo.arguments
        guard let flagIndex = args.firstIndex(of: "-FGHeroSlideIndex"), args.count > flagIndex + 1 else {
            return nil
        }
        return Int(args[flagIndex + 1])
    }
    #endif

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
            FGBrandWash(reach: 0.7).ignoresSafeArea()

            if purchasesManager.isLoadingOfferings, yearlyPackage == nil, monthlyPackage == nil {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                content
            }
        }
        .guaranteedPaywallCloseButton { finish() }
        .sensoryFeedback(.selection, trigger: selectedPlan)
        .task {
            if purchasesManager.offerings == nil {
                await purchasesManager.fetchOfferings()
            }
            if yearlyPackage == nil, monthlyPackage != nil {
                selectedPlan = .monthly
            }
            Analytics.capture("paywall_impression", properties: ["plan": selectedPlan.analyticsID])
            withAnimation(reduceMotion ? nil : FGMotion.settle) {
                hasRevealedMenu = true
            }
        }
        .alert(
            "Something went wrong",
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
                heroCard {
                    topSceneContent
                }

                heroCarousel

                planPicker

                ctaSection
            }
            .padding(.horizontal, FGSpace.page)
            .padding(.top, FGSpace.l)
            .padding(.bottom, FGSpace.m)
        }
        .scrollBounceBehavior(.basedOnSize)
    }

    // MARK: - Hero scene

    /// Just the content that differs per scene — no box/border/shadow here.
    /// Those live once on `heroCard` at the call site so the card itself
    /// never re-inserts (and never animates) when the content swaps.
    /// Cross-fades inside a top-aligned `ZStack` keyed on `currentSlide.scene`,
    /// so slides sharing the same scene (e.g. slides 1–2 or 3–4) stay perfectly
    /// stable with zero glitching or teardown.
    @ViewBuilder
    private var topSceneContent: some View {
        ZStack(alignment: .top) {
            if currentSlide.scene == .menu {
                menuHeroContent
                    .transition(.opacity)
            } else {
                chatSceneContent
                    .transition(.opacity)
            }
        }
        .animation(reduceMotion ? nil : FGMotion.gentle, value: currentSlide.scene)
    }

    /// The shared "printed card" chrome both scenes sit inside, so swapping
    /// between them on a carousel tick reads as one card's content changing
    /// rather than two differently-shaped things trading places.
    /// Pinned to `maxWidth: .infinity` and exact height 246 so the card frame,
    /// background, border, and shadow never shift, shrink into a square, or glitch
    /// regardless of child layout.
    /// Sized to comfortably fit both scenes with room to spare.
    private static let heroCardHeight: CGFloat = 260

    private func heroCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        ZStack(alignment: .top) {
            content()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(FGSpace.m)
        .frame(maxWidth: .infinity)
        .frame(height: Self.heroCardHeight, alignment: .top)
        .background(
            RoundedRectangle(cornerRadius: FGRadius.card, style: .continuous)
                .fill(FGColor.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: FGRadius.card, style: .continuous)
                .strokeBorder(FGColor.lineStrong, lineWidth: 1)
        )
        .shadow(color: FGColor.ink.opacity(0.08), radius: 12, y: 6)
        .rotationEffect(.degrees(-1))
    }

    /// A single printed-menu card rather than four separate blocks — the
    /// "creative, skeuomorphic" read the user asked for, and far shorter than
    /// stacked course cards. Each line keeps the real course/mascot pairing
    /// from Today and My Menu; rows settle in staggered on appear the same
    /// way `FGMotion` describes items landing on the menu.
    private var menuHeroContent: some View {
        VStack(spacing: 0) {
            Image(systemName: "fork.knife")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(FGColor.inkMuted)
                .padding(.bottom, 6)

            Divider()
                .overlay(FGColor.lineStrong)
                .padding(.bottom, 10)

            VStack(spacing: 0) {
                ForEach(Array(Self.menuTeasers.enumerated()), id: \.offset) { index, teaser in
                    if index > 0 {
                        Divider().overlay(FGColor.line)
                    }
                    menuTeaserRow(teaser)
                        .opacity(hasRevealedMenu ? 1 : 0)
                        .offset(y: hasRevealedMenu ? 0 : 10)
                        .animation(
                            reduceMotion ? nil : FGMotion.settle.delay(FGMotion.stagger(index)),
                            value: hasRevealedMenu
                        )
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Today's menu preview")
    }

    /// "Talk to it when you're stuck," shown rather than told: a two-line
    /// exchange in the app's own bubble style (see `ExploreView`'s
    /// `userTextBubble`/`assistantTextBubble`) ending in a recommendation,
    /// not a promise about what chat can do.
    /// Mirrors how a real reply actually arrives in Chat (see `ExploreView`'s
    /// `messageRow`/`typingIndicator`): the user's line lands first, a typing
    /// indicator holds the beat, then the reply replaces it — rather than
    /// dropping the whole exchange on screen at once.
    private enum ChatPhase: Int {
        case userOpener
        case assistantReplied
        case userFollowUp
        case assistantThinking
        case assistantFollowUp
    }

    private var chatSceneContent: some View {
        VStack(alignment: .trailing, spacing: 6) {
            // Turn 1: User check-in
            if chatPhase.rawValue >= ChatPhase.userOpener.rawValue {
                HStack {
                    Spacer(minLength: 24)
                    Text("My back is sore, I have 20 minutes, and I'm tired.")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.trailing)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(Color(light: 0x26231F, dark: 0x36322E))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .transition(chatBubbleTransition)
            }

            // Turn 1: Assistant gentle recommendation
            if chatPhase.rawValue >= ChatPhase.assistantReplied.rawValue {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Here's something gentle for your back:")
                            .font(.system(size: 11, weight: .regular))
                            .foregroundStyle(FGColor.ink)

                        HStack(spacing: 6) {
                            Image(Course.main.menuMascotAsset)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 18, height: 18)

                            Text("Ten gentle minutes on the mat")
                                .font(.system(size: 11, weight: .semibold, design: .rounded))
                                .foregroundStyle(FGColor.ink)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(FGAura.sage.core.opacity(0.55))
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(Color(light: 0xF3EEE7, dark: 0x262320))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                    Spacer(minLength: 24)
                }
                .transition(chatBubbleTransition)
            }

            // Turn 2: User follow-up asking for something shorter
            if chatPhase.rawValue >= ChatPhase.userFollowUp.rawValue {
                HStack {
                    Spacer(minLength: 24)
                    Text("Hmm, something else shorter?")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.trailing)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(Color(light: 0x26231F, dark: 0x36322E))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .transition(chatBubbleTransition)
            }

            // Turn 2: Assistant thinking or follow-up reply
            if chatPhase == .assistantThinking {
                HStack {
                    chatTypingIndicator
                    Spacer(minLength: 24)
                }
                .transition(.opacity.combined(with: .scale(scale: 0.9, anchor: .leading)))
            } else if chatPhase == .assistantFollowUp {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Five minutes on the floor, zero pressure:")
                            .font(.system(size: 11, weight: .regular))
                            .foregroundStyle(FGColor.ink)

                        HStack(spacing: 6) {
                            Image(Course.dessert.menuMascotAsset)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 18, height: 18)

                            Text("Living room floor unwind")
                                .font(.system(size: 11, weight: .semibold, design: .rounded))
                                .foregroundStyle(FGColor.ink)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(FGAura.apricot.core.opacity(0.45))
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(Color(light: 0xF3EEE7, dark: 0x262320))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                    Spacer(minLength: 24)
                }
                .transition(chatBubbleTransition)
            }
        }
        .frame(maxWidth: .infinity, alignment: .top)
        .animation(reduceMotion ? nil : FGMotion.gentle, value: chatPhase)
        .task(id: heroSlideIndex) { await handleSlideChange(heroSlideIndex) }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Example chat. You: my back is sore, I have 20 minutes, and I'm tired. FeelGood: here's something gentle for your back — ten gentle minutes on the mat. You: hmm, something else shorter? FeelGood: five minutes on the floor, zero pressure — living room floor unwind.")
    }

    private var chatBubbleTransition: AnyTransition {
        reduceMotion ? .opacity : .opacity.combined(with: .move(edge: .bottom))
    }

    private var chatTypingIndicator: some View {
        HStack(spacing: 6) {
            ProgressView()
                .scaleEffect(0.7)
                .tint(FGColor.controlAccent)
            Text("Adapting routine...")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(FGColor.inkMuted)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 12)
        .background(Color(light: 0xF3EEE7, dark: 0x262320))
        .clipShape(Capsule())
    }

    /// Choreographs the dialogue turns with the carousel slides:
    /// - Slide 3 ("Say how you're feeling"): Turn 1 (check-in + initial recommendation)
    /// - Slide 4 ("Talk to it when you're stuck"): Turn 2 (request shorter session + adapted 5-min floor unwind)
    private func handleSlideChange(_ index: Int) async {
        guard !reduceMotion else {
            chatPhase = .assistantFollowUp
            return
        }
        if index == 2 {
            chatPhase = .userOpener
            try? await Task.sleep(for: .milliseconds(350))
            guard !Task.isCancelled else { return }
            chatPhase = .assistantReplied
        } else if index == 3 {
            if chatPhase.rawValue < ChatPhase.assistantReplied.rawValue {
                chatPhase = .assistantReplied
            }
            try? await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled else { return }
            chatPhase = .userFollowUp
            try? await Task.sleep(for: .milliseconds(400))
            guard !Task.isCancelled else { return }
            chatPhase = .assistantThinking
            try? await Task.sleep(for: .milliseconds(550))
            guard !Task.isCancelled else { return }
            chatPhase = .assistantFollowUp
        }
    }

    private func menuTeaserRow(_ teaser: MenuTeaser) -> some View {
        HStack(spacing: FGSpace.s) {
            Circle()
                .fill(teaser.course.accent)
                .frame(width: 6, height: 6)

            Text(teaser.course.label.uppercased())
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .tracking(0.5)
                .foregroundStyle(FGColor.inkMuted)
                .frame(width: 66, alignment: .leading)

            Text(teaser.title)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(FGColor.ink)
                .lineLimit(1)

            Spacer(minLength: FGSpace.xs)

            Image(teaser.course.menuMascotAsset)
                .resizable()
                .scaledToFit()
                .frame(width: 24, height: 24)
                .accessibilityHidden(true)
        }
        .padding(.vertical, 8)
    }

    // MARK: - Hero carousel

    /// The hook and the three benefits, one line at a time — replaces a fixed
    /// headline sitting above a separate rotating benefits card. Fewer things
    /// on screen at once, and each slide is short enough to read at a glance.
    private var heroCarousel: some View {
        VStack(spacing: FGSpace.s) {
            ZStack {
                Text(currentSlide.title)
                    .font(FGFont.display)
                    .tracking(-0.6)
                    .foregroundStyle(FGColor.ink)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .id("title-\(heroSlideIndex)")
                    .transition(.opacity)
                    .accessibilityAddTraits(.isHeader)
            }

            HStack(spacing: 6) {
                ForEach(Self.heroSlides.indices, id: \.self) { index in
                    Capsule()
                        .fill(index == heroSlideIndex ? FGColor.ink : FGColor.line)
                        .frame(width: index == heroSlideIndex ? 16 : 6, height: 6)
                }
            }
        }
        .frame(maxWidth: 340)
        .fgAnimation(FGMotion.gentle, value: heroSlideIndex)
        .task { await runHeroCarousel() }
    }

    private var currentSlide: HeroSlide {
        Self.heroSlides[heroSlideIndex]
    }

    /// Cycles on its own — nothing here needs a tap, and the dots make clear
    /// there's more without asking for one. Stops advancing under Reduce
    /// Motion, since a still-changing headline is itself the kind of motion
    /// that setting asks to avoid.
    private func runHeroCarousel() async {
        guard !reduceMotion else { return }
        while !Task.isCancelled {
            try? await Task.sleep(for: .seconds(3))
            guard !Task.isCancelled else { return }
            heroSlideIndex = (heroSlideIndex + 1) % Self.heroSlides.count
        }
    }

    // MARK: - Plan picker

    private var planPicker: some View {
        VStack(spacing: FGSpace.s) {
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
                            .font(FGFont.itemTitle)
                            .foregroundStyle(FGColor.ink)

                        if plan == .yearly, let savingsPercent {
                            Text("SAVE ABOUT \(savingsPercent)%")
                                .font(FGFont.label.weight(.bold))
                                .foregroundStyle(FGColor.inkOnAccent)
                                .padding(.horizontal, FGSpace.xs)
                                .padding(.vertical, 2)
                                .background(Capsule().fill(FGAura.sage.core))
                        }
                    }

                    Text(priceLine(for: package, plan: plan))
                        .font(FGFont.caption)
                        .foregroundStyle(FGColor.inkMuted)
                }

                Spacer(minLength: 0)

                selectionMark(isSelected: isSelected)
            }
            .padding(FGSpace.m)
            .frame(minHeight: FGSize.minTouchTarget + 8)
            .background(
                RoundedRectangle(cornerRadius: FGRadius.card, style: .continuous)
                    .fill(isSelected ? FGAura.apricot.core.opacity(0.4) : FGColor.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: FGRadius.card, style: .continuous)
                    .strokeBorder(isSelected ? FGColor.ink : FGColor.lineStrong, lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }

    private func selectionMark(isSelected: Bool) -> some View {
        ZStack {
            Circle()
                .strokeBorder(isSelected ? FGColor.ink : FGColor.lineStrong, lineWidth: 1.5)
                .frame(width: 22, height: 22)
            if isSelected {
                Circle()
                    .fill(FGColor.ink)
                    .frame(width: 12, height: 12)
            }
        }
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

    private func priceLine(for package: Package, plan: Plan) -> String {
        let product = package.storeProduct
        let unit = plan == .yearly ? "a year" : "a month"
        if let discount = product.introductoryDiscount, discount.paymentMode == .freeTrial {
            return "\(trialLengthNoun(discount.subscriptionPeriod)) free, then \(product.localizedPriceString) \(unit)"
        }
        return "\(product.localizedPriceString) \(unit)"
    }

    /// Plain plural noun ("7 days", "1 week") for a sentence that already
    /// supplies its own verb — "Start my 7 days free," not the clipped
    /// "Start my 7-day free."
    private func trialLengthNoun(_ period: SubscriptionPeriod) -> String {
        let unit: String
        switch period.unit {
        case .day: unit = "day"
        case .week: unit = "week"
        case .month: unit = "month"
        case .year: unit = "year"
        @unknown default: unit = "day"
        }
        return period.value == 1 ? "\(period.value) \(unit)" : "\(period.value) \(unit)s"
    }

    // MARK: - Actions

    /// Selecting a plan only changes its price line and this button's label —
    /// never whether the button itself can be tapped. A plan is selected the
    /// moment this screen appears (Yearly, by default), so there is always a
    /// single, obvious next step.
    private var ctaTitle: String {
        guard let selectedPackage else { return "Continue" }
        guard let discount = selectedPackage.storeProduct.introductoryDiscount,
              discount.paymentMode == .freeTrial else {
            return "Subscribe"
        }
        return "Start my \(trialLengthNoun(discount.subscriptionPeriod)) free"
    }

    private var ctaSection: some View {
        VStack(spacing: FGSpace.xs) {
            FGPrimaryButton(title: ctaTitle, isEnabled: selectedPackage != nil && !isPurchasing) {
                purchaseSelectedPlan()
            }

            HStack(spacing: FGSpace.xs) {
                Button {
                    Analytics.capture("paywall_declined", properties: ["plan": selectedPlan.analyticsID])
                    finish()
                } label: {
                    Text("Continue with free menu")
                }
                .buttonStyle(.plain)

                Text("·")
                    .foregroundStyle(FGColor.inkMuted.opacity(0.6))

                restoreButton
            }
            .font(FGFont.caption.weight(.medium))
            .foregroundStyle(FGColor.inkMuted)
            .frame(minHeight: FGSize.minTouchTarget)

            Text("Auto-renews until canceled. Cancel anytime in Settings.")
                .font(FGFont.caption)
                .foregroundStyle(FGColor.inkMuted.opacity(0.8))

            HStack(spacing: FGSpace.xs) {
                Link("Terms of Use", destination: LegalLinks.termsOfUse)
                Text("·")
                Link("Privacy Policy", destination: LegalLinks.privacyPolicy)
            }
            .font(FGFont.caption)
            .foregroundStyle(FGColor.inkMuted.opacity(0.8))
        }
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
            } else {
                Text("Restore purchases")
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

#Preview {
    FeelGoodPaywallView()
        .environment(PurchasesManager.shared)
}
