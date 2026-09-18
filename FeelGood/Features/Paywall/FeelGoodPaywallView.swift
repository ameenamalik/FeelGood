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
        MenuTeaser(course: .main, title: "Twenty minutes on the machines"),
        MenuTeaser(course: .side, title: "Carry the shopping in one trip"),
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
    @State private var chatPhase: ChatPhase = .empty
    #if DEBUG
    @State private var heroSlideIndex = Self.debugForcedHeroSlideIndex ?? 0
    #else
    @State private var heroSlideIndex = 0
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
                        .id(heroSlideIndex)
                        .transition(.opacity)
                        .animation(reduceMotion ? nil : FGMotion.gentle, value: heroSlideIndex)
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

    /// Just the content that differs per slide — no box/border/shadow here.
    /// Those live once on `heroCard` at the call site so the card itself
    /// never re-inserts (and never animates) when the content swaps.
    @ViewBuilder
    private var topSceneContent: some View {
        switch currentSlide.scene {
        case .menu: menuHeroContent
        case .chat: chatSceneContent
        }
    }

    /// The shared "printed card" chrome both scenes sit inside, so swapping
    /// between them on a carousel tick reads as one card's content changing
    /// rather than two differently-shaped things trading places.
    /// An exact height, not a floor — the menu card (four rows) is naturally
    /// taller than the chat card (two bubbles), so a `minHeight` only pinned
    /// the shorter one and left the actual jump between them unfixed. Sized
    /// to comfortably fit the taller (menu) content with room to spare.
    private static let heroCardHeight: CGFloat = 246

    private func heroCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .padding(FGSpace.m)
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
        case empty, userSent, assistantThinking, assistantReplied
    }

    private var chatSceneContent: some View {
        VStack(alignment: .trailing, spacing: 8) {
            if chatPhase.rawValue >= ChatPhase.userSent.rawValue {
                HStack {
                    Spacer(minLength: 30)
                    Text("My back is sore, I have 20 minutes, and I'm tired.")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.trailing)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(Color(light: 0x26231F, dark: 0x36322E))
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .transition(chatBubbleTransition)
            }

            if chatPhase == .assistantThinking {
                HStack {
                    chatTypingIndicator
                    Spacer(minLength: 30)
                }
                .transition(.opacity.combined(with: .scale(scale: 0.9, anchor: .leading)))
            } else if chatPhase == .assistantReplied {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Here's something gentle for your back.")
                            .font(.system(size: 13, weight: .regular))
                            .foregroundStyle(FGColor.ink)

                        HStack(spacing: 8) {
                            Image(Course.appetizer.menuMascotAsset)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 24, height: 24)

                            Text("Five-minute shake-out")
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                                .foregroundStyle(FGColor.ink)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .background(FGAura.sage.core.opacity(0.55))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Color(light: 0xF3EEE7, dark: 0x262320))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                    Spacer(minLength: 30)
                }
                .transition(chatBubbleTransition)
            }
        }
        .animation(reduceMotion ? nil : FGMotion.gentle, value: chatPhase)
        .task { await runChatSequence() }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Example chat. You: my back is sore, I have 20 minutes, and I'm tired. FeelGood: here's something gentle for your back — a five-minute shake-out.")
    }

    private var chatBubbleTransition: AnyTransition {
        reduceMotion ? .opacity : .opacity.combined(with: .move(edge: .bottom))
    }

    private var chatTypingIndicator: some View {
        HStack(spacing: 6) {
            ProgressView()
                .scaleEffect(0.7)
                .tint(FGColor.clay)
            Text("Shaping routine...")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(FGColor.inkMuted)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 14)
        .background(Color(light: 0xF3EEE7, dark: 0x262320))
        .clipShape(Capsule())
    }

    /// Replays from the top each time a chat slide comes onto the carousel —
    /// `.task` restarts automatically because `topSceneContent` above is keyed to
    /// `heroSlideIndex`, so this needs no cancellation bookkeeping of its own.
    private func runChatSequence() async {
        chatPhase = .empty
        guard !reduceMotion else {
            chatPhase = .assistantReplied
            return
        }
        try? await Task.sleep(for: .milliseconds(400))
        guard !Task.isCancelled else { return }
        chatPhase = .userSent
        try? await Task.sleep(for: .milliseconds(700))
        guard !Task.isCancelled else { return }
        chatPhase = .assistantThinking
        try? await Task.sleep(for: .milliseconds(900))
        guard !Task.isCancelled else { return }
        chatPhase = .assistantReplied
    }

    private func menuTeaserRow(_ teaser: MenuTeaser) -> some View {
        HStack(spacing: FGSpace.s) {
            Circle()
                .fill(teaser.course.accent)
                .frame(width: 7, height: 7)

            Text(teaser.course.label.uppercased())
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(teaser.course.tagText)
                .frame(width: 64, alignment: .leading)

            Text(teaser.title)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(FGColor.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Spacer(minLength: FGSpace.xs)

            Image(teaser.course.menuMascotAsset)
                .resizable()
                .scaledToFit()
                .frame(width: 26, height: 26)
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
            Text(currentSlide.title)
                .font(FGFont.display)
                .tracking(-0.6)
                .foregroundStyle(FGColor.ink)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .id("title-\(heroSlideIndex)")
                .transition(.opacity)
                .accessibilityAddTraits(.isHeader)

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
                                .foregroundStyle(FGColor.sageDeep)
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

            Text("Cancel anytime in Settings.")
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
                    restoreResultMessage = "No active purchases found for this Apple ID."
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
