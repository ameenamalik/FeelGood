//
//  FeelGoodPaywallView.swift
//  FeelGood
//

import RevenueCat
import SwiftUI

/// Why the paywall was opened. The first message should answer the action the
/// person just took instead of dropping every intent into the same sales pitch.
nonisolated enum PaywallContext: String, Sendable {
    case general
    case secondSwap = "second_swap"
    case library
    case chatLimit = "chat_limit"
    case calendar
}

/// FeelGood's own paywall. Unlike the dashboard-configured screen it replaced,
/// the hero shows the real menu — the same course/course-mascot pairing
/// (`Course.menuMascotAsset`) already shipping on Today and My Menu — instead
/// of a standalone illustration. The fruits don't get their own dialogue here;
/// they're doing the job they already do everywhere else in the app: marking
/// which course is which. RevenueCat still owns products, pricing, and the
/// purchase itself; this view only decides what to show and calls
/// `PurchasesManager`.
struct FeelGoodPaywallView: View {
    let context: PaywallContext

    private enum Plan: CaseIterable {
        case yearly
        case monthly

        var title: String {
            switch self {
            case .yearly: "Yearly"
            case .monthly: "Monthly"
            }
        }

        /// Appended to the price on the CTA so the renewal terms are on the button itself.
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

    /// A course teaser row for the hero. Real course/mascot pairing, placeholder
    /// session titles pulled from the app's own App Store screenshots so the copy
    /// is already-approved rather than invented for this screen.
    private struct MenuTeaser {
        let course: Course
        let title: String
    }

    private static let menuTeasers: [MenuTeaser] = [
        MenuTeaser(course: .appetizer, title: "Four rounds of box breathing"),
        MenuTeaser(course: .main, title: "Twenty minutes of flow"),
        MenuTeaser(course: .side, title: "Shoulder reset"),
        MenuTeaser(course: .dessert, title: "Dance to three songs"),
    ]

    /// Which illustration sits above a given slide's line. Most slides show
    /// the menu; "Talk to it when you're stuck" swaps in a chat exchange,
    /// since that's the one benefit the menu card can't demonstrate on its own.
    private enum HeroScene {
        case menu
        case quickPick
        case chat
    }

    /// One slide at a time instead of a fixed headline plus a separate
    /// benefits list — the header rotates through the hook and the benefits
    /// itself, so only one short line is ever on screen in this spot.
    private struct HeroSlide {
        let title: String
        let scene: HeroScene
        /// How long the slide stays up before the carousel advances. Chat
        /// slides play a typing sequence first, so they need that time plus
        /// enough left over to actually read the bubbles.
        let dwell: Duration
    }

    private static let defaultHeroSlides: [HeroSlide] = [
        HeroSlide(title: "Stop deciding. Start moving.", scene: .menu, dwell: .seconds(3.5)),
        HeroSlide(title: "Know what to do in 10 seconds", scene: .quickPick, dwell: .seconds(4.5)),
        HeroSlide(title: "Say how you're feeling", scene: .chat, dwell: .seconds(5)),
        HeroSlide(title: "Talk to it when you're stuck", scene: .chat, dwell: .seconds(7)),
    ]

    /// Lead with the benefit the person just asked for. They can still swipe
    /// through the broader Pro story after seeing that immediate answer.
    private var heroSlides: [HeroSlide] {
        guard let contextualSlide else { return Self.defaultHeroSlides }
        return [contextualSlide] + Self.defaultHeroSlides
    }

    private var contextualSlide: HeroSlide? {
        switch context {
        case .general:
            nil
        case .secondSwap:
            HeroSlide(title: "Keep shaping today’s menu", scene: .quickPick, dwell: .seconds(5))
        case .library:
            HeroSlide(title: "Choose exactly what fits today", scene: .menu, dwell: .seconds(5))
        case .chatLimit:
            HeroSlide(title: "Keep talking it through", scene: .chat, dwell: .seconds(6))
        case .calendar:
            HeroSlide(title: "Plan movement around your actual day", scene: .quickPick, dwell: .seconds(5))
        }
    }

    @Environment(\.dismiss) private var dismiss
    @Environment(PurchasesManager.self) private var purchasesManager
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var typeSize

    var onFinished: (() -> Void)?

    init(
        context: PaywallContext = .general,
        onFinished: (() -> Void)? = nil
    ) {
        self.context = context
        self.onFinished = onFinished
    }

    @State private var selectedPlan: Plan = .yearly
    @State private var isPurchasing = false
    /// Plans this person can still take a free trial on. Apple allows one
    /// intro offer per subscription group per person, so a product having a
    /// trial does not mean this person gets it. Starts empty and only ever
    /// grows on a definite `.eligible`, so until the check answers (or if it
    /// can't) the button never promises a trial.
    @State private var trialEligiblePlans: Set<Plan> = []
    @State private var isRestoring = false
    @State private var restoreResultMessage: String?
    @State private var hasRevealedMenu = false
    @State private var carouselResetToken = 0
    #if DEBUG
    @State private var heroSlideIndex = Self.debugForcedHeroSlideIndex ?? 0
    @State private var chatPhase: ChatPhase = (Self.debugForcedHeroSlideIndex == 3) ? .assistantFollowUp : .userOpener
    @State private var quickPickPhase: QuickPickPhase = (Self.debugForcedHeroSlideIndex == 1) ? .resultShown : .initial
    #else
    @State private var heroSlideIndex = 0
    @State private var chatPhase: ChatPhase = .userOpener
    @State private var quickPickPhase: QuickPickPhase = .initial
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
            await refreshTrialEligibility()
            Analytics.capture("paywall_impression", properties: [
                "plan": selectedPlan.analyticsID,
                "context": context.rawValue,
            ])
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
                VStack(spacing: FGSpace.s + 4) {
                    heroCard {
                        topSceneContent
                    }

                    heroCarousel
                        .padding(.top, FGSpace.xs)
                }
                .contentShape(Rectangle())
                .simultaneousGesture(heroSwipe)
                .accessibilityAdjustableAction { direction in
                    switch direction {
                    case .increment: stepHeroSlide(by: 1)
                    case .decrement: stepHeroSlide(by: -1)
                    @unknown default: break
                    }
                }

                planPicker

                // At accessibility sizes a pinned bar would swallow the screen,
                // so the buy section joins the scroll flow instead.
                if typeSize.isAccessibilitySize {
                    ctaButtons
                }

                legalSection
            }
            .padding(.horizontal, FGSpace.page)
            // Clears the close button overlay (pinned to the safe area's top
            // trailing corner) so it never sits on top of the hero card.
            .padding(.top, FGSize.minTouchTarget + FGSpace.s)
            .padding(.bottom, FGSpace.l)
        }
        .scrollBounceBehavior(.basedOnSize)
        // The buy button and its escape hatch stay pinned so they are on
        // screen at every device size and Dynamic Type setting, while the
        // proof and plans scroll behind them.
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
            switch currentSlide.scene {
            case .menu:
                menuHeroContent
                    .transition(.opacity)
            case .quickPick:
                quickPickHeroContent
                    .transition(.opacity)
            case .chat:
                chatSceneContent
                    .transition(.opacity)
            }
        }
        .animation(reduceMotion ? nil : FGMotion.gentle, value: currentSlide.scene)
    }

    /// The shared "printed card" chrome both scenes sit inside, so swapping
    /// between them on a carousel tick reads as one card's content changing
    /// rather than two differently-shaped things trading places.
    /// Pinned to `maxWidth: .infinity`; height tracks the current scene
    /// (menu/quick-pick are short, chat's four bubbles need more) and
    /// animates between them, rather than one fixed height sized for the
    /// tallest scene that leaves the shorter ones with dead space below.
    private var heroCardHeight: CGFloat {
        switch currentSlide.scene {
        case .menu: 196
        case .quickPick: 210
        case .chat: 260
        }
    }

    private func heroCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        ZStack(alignment: .top) {
            content()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(FGSpace.m)
        .frame(maxWidth: .infinity)
        .frame(height: heroCardHeight, alignment: .top)
        .background(
            RoundedRectangle(cornerRadius: FGRadius.card, style: .continuous)
                .fill(FGColor.bg)
                .opacity(hasCardChrome ? 1 : 0)
        )
        .overlay(
            RoundedRectangle(cornerRadius: FGRadius.card, style: .continuous)
                .strokeBorder(FGColor.lineStrong, lineWidth: 1)
                .opacity(hasCardChrome ? 1 : 0)
        )
        .shadow(color: FGColor.ink.opacity(hasCardChrome ? 0.08 : 0), radius: 12, y: 6)
        .rotationEffect(.degrees(hasCardChrome ? -1 : 0))
        .animation(reduceMotion ? nil : FGMotion.gentle, value: currentSlide.scene)
    }

    /// The printed-menu card frames the menu scene only. Chat bubbles float
    /// straight on the page, the way they do in the real Chat tab; the chrome
    /// fades rather than being removed so the frame never re-inserts.
    private var hasCardChrome: Bool { currentSlide.scene != .chat }

    /// A single printed-menu card rather than four separate blocks — the
    /// "creative, skeuomorphic" read the user asked for, and far shorter than
    /// stacked course cards. Each line keeps the real course/mascot pairing
    /// from Today and My Menu; rows settle in staggered on appear the same
    /// way `FGMotion` describes items landing on the menu.
    private var menuHeroContent: some View {
        VStack(spacing: 0) {
            HStack(spacing: 6) {
                Image(systemName: "fork.knife")
                    .font(.system(size: 12, weight: .semibold))
                Text("TODAY'S MENU")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .tracking(0.5)
            }
            .foregroundStyle(FGColor.inkMuted)
            .padding(.bottom, 4)

            Divider()
                .overlay(FGColor.lineStrong)
                .padding(.bottom, 8)

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

    /// Live proof of the "10 seconds" headline, played out instead of stated:
    /// a tap on Energy, a tap on Time — the app's own coarse check-in signals
    /// (`Energy`, `TimeBudget`; see the allow-list in CLAUDE.md) — then one
    /// answer, not a list to choose from. Auto-advances with the carousel,
    /// the same way the chat scene mimes its exchange.
    private enum QuickPickPhase: Int {
        case initial
        case energyPicked
        case timePicked
        case resultShown
    }

    private static let quickPickEnergyOptions = ["Low", "Steady", "Strong"]
    private static let quickPickEnergySelection = 0
    private static let quickPickTimeOptions = ["5 min", "15 min", "30 min"]
    private static let quickPickTimeSelection = 1

    private var quickPickHeroContent: some View {
        VStack(alignment: .leading, spacing: 10) {
            quickPickChipRow(
                label: "ENERGY",
                options: Self.quickPickEnergyOptions,
                selected: quickPickPhase.rawValue >= QuickPickPhase.energyPicked.rawValue ? Self.quickPickEnergySelection : nil
            )
            quickPickChipRow(
                label: "TIME",
                options: Self.quickPickTimeOptions,
                selected: quickPickPhase.rawValue >= QuickPickPhase.timePicked.rawValue ? Self.quickPickTimeSelection : nil
            )

            Divider().overlay(FGColor.line)

            HStack(spacing: FGSpace.s) {
                Image(Course.dessert.menuMascotAsset)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 26, height: 26)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 1) {
                    Text("Barefoot porch breath")
                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                        .foregroundStyle(FGColor.ink)
                    Text("Slow and low-effort. No gear needed.")
                        .font(FGFont.caption)
                        .foregroundStyle(FGColor.inkMuted)
                }
                Spacer(minLength: 0)
            }
            .opacity(quickPickPhase == .resultShown ? 1 : 0)
            .animation(reduceMotion ? nil : FGMotion.gentle, value: quickPickPhase)
        }
        .task(id: heroSlideIndex) { await handleQuickPickSlideChange(heroSlideIndex) }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Example. You pick: low energy, then 15 minutes. FeelGood answers: barefoot porch breath, slow and low-effort, no gear needed.")
    }

    private func quickPickChipRow(label: String, options: [String], selected: Int?) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .tracking(0.5)
                .foregroundStyle(FGColor.inkMuted)
            HStack(spacing: 6) {
                ForEach(options.indices, id: \.self) { index in
                    let isSelected = selected == index
                    Text(options[index])
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(isSelected ? .white : FGColor.ink)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            Capsule().fill(isSelected ? AnyShapeStyle(Course.appetizer.accentGradient) : AnyShapeStyle(FGColor.surface))
                        )
                        .overlay(
                            Capsule().strokeBorder(FGColor.line, lineWidth: isSelected ? 0 : 1)
                        )
                        .scaleEffect(isSelected ? 1.05 : 1)
                        .animation(reduceMotion ? nil : FGMotion.swap, value: selected)
                }
            }
        }
    }

    /// Plays only while slide 2 (index 1) is showing; any other index resets
    /// so returning to this slide replays the tap-through from the top.
    private func handleQuickPickSlideChange(_ index: Int) async {
        guard !reduceMotion else {
            quickPickPhase = .resultShown
            return
        }
        guard index == 1 else {
            quickPickPhase = .initial
            return
        }
        quickPickPhase = .initial
        try? await Task.sleep(for: .milliseconds(500))
        guard !Task.isCancelled else { return }
        quickPickPhase = .energyPicked
        try? await Task.sleep(for: .milliseconds(700))
        guard !Task.isCancelled else { return }
        quickPickPhase = .timePicked
        try? await Task.sleep(for: .milliseconds(700))
        guard !Task.isCancelled else { return }
        quickPickPhase = .resultShown
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
        case assistantThinking1
        case assistantReplied
        case userFollowUp
        case assistantThinking2
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
                        .foregroundStyle(FGColor.onDeepFill)
                        .multilineTextAlignment(.trailing)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(FGColor.userBubble)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .transition(chatBubbleTransition)
            }

            // Turn 1: Assistant thinking
            if chatPhase == .assistantThinking1 {
                HStack {
                    chatTypingIndicator
                    Spacer(minLength: 24)
                }
                .transition(.opacity.combined(with: .scale(scale: 0.9, anchor: .leading)))
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
                    .background(FGColor.panel)
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
                        .foregroundStyle(FGColor.onDeepFill)
                        .multilineTextAlignment(.trailing)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(FGColor.userBubble)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .transition(chatBubbleTransition)
            }

            // Turn 2: Assistant thinking or follow-up reply
            if chatPhase == .assistantThinking2 {
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
                    .background(FGColor.panel)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                    Spacer(minLength: 24)
                }
                .transition(chatBubbleTransition)
            }
        }
        .padding(.horizontal, FGSpace.s)
        .frame(maxWidth: .infinity, alignment: .top)
        .animation(reduceMotion ? nil : FGMotion.settle, value: chatPhase)
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
        .background(FGColor.panel)
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
            try? await Task.sleep(for: .milliseconds(550))
            guard !Task.isCancelled else { return }
            chatPhase = .assistantThinking1
            try? await Task.sleep(for: .milliseconds(950))
            guard !Task.isCancelled else { return }
            chatPhase = .assistantReplied
        } else if index == 3 {
            if chatPhase.rawValue < ChatPhase.assistantReplied.rawValue {
                chatPhase = .assistantReplied
            }
            try? await Task.sleep(for: .milliseconds(700))
            guard !Task.isCancelled else { return }
            chatPhase = .userFollowUp
            try? await Task.sleep(for: .milliseconds(550))
            guard !Task.isCancelled else { return }
            chatPhase = .assistantThinking2
            try? await Task.sleep(for: .milliseconds(950))
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
                .minimumScaleFactor(0.85)

            Spacer(minLength: FGSpace.xs)

            Image(teaser.course.menuMascotAsset)
                .resizable()
                .scaledToFit()
                .frame(width: 24, height: 24)
                .accessibilityHidden(true)
        }
        .padding(.vertical, 6)
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
                ForEach(heroSlides.indices, id: \.self) { index in
                    Capsule()
                        .fill(index == heroSlideIndex ? FGColor.ink : FGColor.line)
                        .frame(width: index == heroSlideIndex ? 16 : 6, height: 6)
                }
            }
        }
        .frame(maxWidth: 340)
        .fgAnimation(FGMotion.gentle, value: heroSlideIndex)
        // Keyed on the reset token so a manual swipe restarts the dwell timer
        // instead of letting it fire right after the person moved on.
        .task(id: carouselResetToken) { await runHeroCarousel() }
    }

    /// Horizontal swipes step the carousel; mostly-vertical drags fall
    /// through so the page still scrolls.
    private var heroSwipe: some Gesture {
        DragGesture(minimumDistance: 24)
            .onEnded { value in
                let dx = value.translation.width
                guard abs(dx) > abs(value.translation.height) * 1.5, abs(dx) > 40 else { return }
                stepHeroSlide(by: dx < 0 ? 1 : -1)
            }
    }

    private func stepHeroSlide(by delta: Int) {
        let count = heroSlides.count
        heroSlideIndex = (heroSlideIndex + delta + count) % count
        carouselResetToken += 1
    }

    private var currentSlide: HeroSlide {
        heroSlides[heroSlideIndex]
    }

    /// Cycles on its own — nothing here needs a tap, and the dots make clear
    /// there's more without asking for one. Stops advancing under Reduce
    /// Motion, since a still-changing headline is itself the kind of motion
    /// that setting asks to avoid.
    private func runHeroCarousel() async {
        guard !reduceMotion else { return }
        while !Task.isCancelled {
            try? await Task.sleep(for: currentSlide.dwell)
            guard !Task.isCancelled else { return }
            heroSlideIndex = (heroSlideIndex + 1) % heroSlides.count
        }
    }

    // MARK: - Proof and boundary

    // MARK: - Plan picker

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
                            .font(.system(.title3, design: .rounded).weight(.medium))
                            .foregroundStyle(FGColor.ink)
                    }

                    HStack(spacing: 4) {
                        Text(priceLine(for: package, plan: plan))
                            .font(FGFont.caption)
                            .foregroundStyle(isSelected ? FGColor.inkMuted : FGColor.ink.opacity(0.75))

                        // Makes the yearly savings concrete rather than abstract —
                        // the percent badge says "cheaper," this says how cheap.
                        if plan == .yearly, let monthlyEquivalent = monthlyEquivalentCaption(for: package) {
                            Text("· \(monthlyEquivalent)")
                                .font(.system(size: 11, weight: .semibold, design: .rounded))
                                .foregroundStyle(isSelected ? FGColor.ink.opacity(0.7) : FGColor.ink.opacity(0.55))
                        }
                    }
                }

                Spacer(minLength: 0)

                selectionMark(isSelected: isSelected)
            }
            .padding(.horizontal, FGSpace.m)
            .padding(.vertical, FGSpace.m)
            .frame(minHeight: FGSize.minTouchTarget + 16)
            .background(
                RoundedRectangle(cornerRadius: FGRadius.card, style: .continuous)
                    .fill(isSelected ? AnyShapeStyle(Course.appetizer.accentGradient) : AnyShapeStyle(FGColor.surface))
            )
            .overlay(
                RoundedRectangle(cornerRadius: FGRadius.card, style: .continuous)
                    .strokeBorder(isSelected ? FGColor.ink.opacity(0.2) : FGColor.lineStrong, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .overlay(alignment: .topTrailing) {
            // Straddles the card's top edge, clear of the plan name.
            if plan == .yearly, let savingsPercent {
                Text("SAVE \(savingsPercent)%")
                    .font(.system(.caption2, design: .rounded).weight(.heavy))
                    .tracking(0.4)
                    .foregroundStyle(FGColor.onDeepFill)
                    .padding(.horizontal, FGSpace.s + 2)
                    .padding(.vertical, 4)
                    // Deep botanical green — the saturated end of the Side
                    // course's sage — so white text clears 4.5:1 and the
                    // pill leads instead of receding into the card.
                    .background(Capsule().fill(FGColor.sideBadge))
                    .padding(.trailing, FGSpace.m)
                    .offset(y: -10)
                    .allowsHitTesting(false)
            }
        }
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

    /// "~just $2.92/mo" — RevenueCat/StoreKit's own per-month breakdown
    /// (`localizedPricePerMonth`), already formatted in the product's real
    /// currency and locale rather than a hand-rolled division.
    private func monthlyEquivalentCaption(for package: Package) -> String? {
        guard let perMonth = package.storeProduct.localizedPricePerMonth else { return nil }
        return "~just \(perMonth)/mo"
    }

    /// Plain plural noun ("7 days", "1 week") for a sentence that already
    /// supplies its own verb — "1 week free, then…," not the clipped
    /// "1-week free."
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
        guard trialEligiblePlans.contains(selectedPlan),
              let discount = selectedPackage.storeProduct.introductoryDiscount,
              discount.paymentMode == .freeTrial else {
            return "Subscribe, \(selectedPackage.storeProduct.localizedPriceString)\(selectedPlan.renewalSuffix)"
        }
        return "\(trialLengthNoun(discount.subscriptionPeriod)) free, then \(selectedPackage.storeProduct.localizedPriceString)\(selectedPlan.renewalSuffix)"
    }

    private var ctaButtons: some View {
        VStack(spacing: FGSpace.s) {
            FGPrimaryButton(title: ctaTitle, isEnabled: selectedPackage != nil && !isPurchasing) {
                purchaseSelectedPlan()
            }

            Button {
                Analytics.capture("paywall_declined", properties: ["plan": selectedPlan.analyticsID])
                finish()
            } label: {
                Text("Continue with free menu")
                    .font(.system(.subheadline).weight(.semibold))
                    .foregroundStyle(FGColor.ink)
                    .frame(maxWidth: .infinity, minHeight: FGSize.minTouchTarget)
                    .contentShape(Rectangle())
                    .background(FGColor.surface.opacity(0.82), in: Capsule())
                    .overlay {
                        Capsule()
                            .strokeBorder(FGColor.lineStrong, lineWidth: 1)
                    }
            }
            .buttonStyle(.feelGoodPress)
        }
    }

    /// One line instead of two stacked blocks: the renewal disclosure and
    /// the legal links read as a single fine-print row, falling back to a
    /// stack only if a device is too narrow to fit it on one line.
    private var legalSection: some View {
        ViewThatFits(in: .horizontal) {
            legalLinks(spacing: FGSpace.xs, isStacked: false)
            legalLinks(spacing: FGSpace.xs, isStacked: true)
        }
        .font(FGFont.caption)
        .foregroundStyle(FGColor.inkMuted.opacity(0.8))
    }

    @ViewBuilder
    private func legalLinks(spacing: CGFloat, isStacked: Bool) -> some View {
        if isStacked {
            VStack(spacing: spacing) {
                Text("Auto-renews. Cancel anytime.")
                HStack(spacing: spacing) {
                    Link("Terms of Use", destination: LegalLinks.termsOfUse)
                    Text("·")
                    Link("Privacy Policy", destination: LegalLinks.privacyPolicy)
                    Text("·")
                    restoreButton
                }
            }
        } else {
            HStack(spacing: spacing) {
                Text("Auto-renews")
                Text("·")
                Link("Terms of Use", destination: LegalLinks.termsOfUse)
                Text("·")
                Link("Privacy Policy", destination: LegalLinks.privacyPolicy)
                Text("·")
                restoreButton
            }
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

#Preview {
    FeelGoodPaywallView()
        .environment(PurchasesManager.shared)
}
