//
//  TodayView.swift
//  FeelGood
//
//  The menu. One screen, three to five items, no browsing and no scroll on a
//  normal type size — the app's job is to remove options, not present them.
//

import SwiftUI
import UIKit
import PostHog

private struct PendingCheckInUpdate {
    let checkIn: PlanCheckIn
    let calendarOpening: CalendarOpening?
    let completedMovementPlan: CalendarMovementPlan?
}

/// A quiet, check-in-colored glow behind today's rebuilt menu. Replacing the
/// keyed view lets the old and new colors cross-fade instead of snapping.
private struct MenuPersonalizationAura: View {
    let aura: FGAura
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        GeometryReader { proxy in
            RadialGradient(
                colors: [
                    aura.core.opacity(colorScheme == .dark ? 0.16 : 0.38),
                    aura.mid.opacity(colorScheme == .dark ? 0.10 : 0.22),
                    Color.clear,
                ],
                center: UnitPoint(x: 0.5, y: 0.62),
                startRadius: 0,
                endRadius: max(proxy.size.width, proxy.size.height) * 0.68
            )
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

struct TodayView: View {
    @State var model: TodayModel
    /// Set by a widget tap. Consumed here and cleared, so the same link does
    /// not reopen the sheet every time this view is rebuilt.
    var requestedSessionID: Binding<String?> = .constant(nil)
    @State private var isCheckingIn = false
    @State private var isShowingPaywall = false
    @State private var shouldOfferProAfterDismissal = false
    @AppStorage("hasShownFirstCompletionPaywall") private var hasShownFirstCompletionPaywall = false
    @AppStorage("hasShownFirstCompletionAuthPrompt") private var hasShownFirstCompletionAuthPrompt = false
    @State private var isShowingAuthPrompt = false
    @Environment(AuthService.self) private var authService
    @Environment(\.colorScheme) private var colorScheme
    @State private var isShowingMyMenu = false
    @AppStorage("hasSeenDopamineMenuTour") private var hasSeenDopamineMenuTour = false
    @State private var isShowingDopamineMenuTour = false
    @State private var selected: MenuItem?
    @State private var littleWinCelebration: LittleWinCelebration?
    @State private var pendingCheckInUpdate: PendingCheckInUpdate?
    @State private var isRegeneratingMenu = false
    @State private var isMenuCompressed = false
    @State private var visibleMenuCardCount = Int.max
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    #if DEBUG
    @State private var isDebugging = false
    #endif

    var body: some View {
        ZStack {
            FGColor.bg.ignoresSafeArea()

            // Rises through the space below the menu. The cards keep a plain
            // page behind them and still read as cards.
            FGBrandWash(reach: 0.62)
                .ignoresSafeArea()

            MenuPersonalizationAura(aura: currentMenuAura)
                .id(currentMenuAuraID)
                .transition(.opacity)
                .animation(
                    reduceMotion ? .none : .easeInOut(duration: 0.65),
                    value: currentMenuAuraID
                )
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: FGSpace.l) {
                    header
                    menuHeading
                    calendarFitCard
                    menuItems
                }
                .padding(FGSpace.page)
                .containerRelativeFrame(.horizontal)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
        .sheet(isPresented: $isCheckingIn, onDismiss: handleCheckInDismissal) {
            CheckInSheet(
                current: model.checkIn,
                currentCalendarOpening: model.calendarOpening,
                isProUser: model.isProUser,
                preferredTime: model.profile.bestTimeOfDay,
                realisticMinutes: model.profile.realisticMinutes
            ) { checkIn, calendarOpening, completedMovementPlan in
                pendingCheckInUpdate = PendingCheckInUpdate(
                    checkIn: checkIn,
                    calendarOpening: calendarOpening,
                    completedMovementPlan: completedMovementPlan
                )
                isCheckingIn = false
            }
        }
        .sheet(isPresented: $isShowingPaywall) {
            FeelGoodPaywallView()
        }
        .sheet(isPresented: $isShowingMyMenu, onDismiss: clearOneSignalDiscoveryTriggers) {
            MyMenuView(model: model)
        }
        .sheet(isPresented: $isShowingDopamineMenuTour) {
            DopamineMenuTourView {
                hasSeenDopamineMenuTour = true
            }
        }
        .sheet(item: $selected, onDismiss: presentCompletionPaywallIfNeeded) { item in
            SessionDetailView(item: item, model: model) {
                shouldOfferProAfterDismissal = true
            }
        }
        .sheet(item: $littleWinCelebration) { celebration in
            LittleWinCelebrationView(celebration: celebration)
                .presentationDetents([.large])
                .presentationDragIndicator(.hidden)
        }
        .sheet(isPresented: $isShowingAuthPrompt) {
            AuthSheetView(
                title: "Save your routine",
                subtitle: "You finished today's session! Create an account to keep your progress and daily menus across devices."
            )
        }
        .onChange(of: requestedSessionID.wrappedValue, initial: true) { _, id in
            openRequestedSession(id)
        }
        .onAppear {
            // Discovery messaging belongs to the moment after a completion,
            // never to app launch or the start of a calming session.
            clearOneSignalDiscoveryTriggers()
            if !hasSeenDopamineMenuTour {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    isShowingDopamineMenuTour = true
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .oneSignalOpenMyMenu)) { _ in
            // Let OneSignal's overlay finish dismissing before presenting the
            // My Menu sheet; competing presentations can otherwise drop it.
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(250))
                isShowingMyMenu = true
            }
        }
        #if DEBUG
        .sheet(isPresented: $isDebugging) {
            DebugMenu(content: model.store) { model.reload() }
        }
        #endif
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: FGSpace.xs) {
            Text(model.upgradedHeadline ?? model.menu.headline)
                // The copy changes after check-in, but its visual hierarchy
                // should not. A large-title-sized line made longer generated
                // headlines feel dramatically bigger once they wrapped.
                .font(.system(.title, design: .rounded).weight(.bold))
                .tracking(-0.4)
                .foregroundStyle(FGColor.ink)
                // No line cap: the text is data, and a menu restored on launch
                // carries its long personalised headline before any check-in.
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)

            // Until there is a check-in, ask for one with a real card; after,
            // collapse to the one-line summary.
            if model.checkIn == nil {
                CheckInBanner { isCheckingIn = true }
                    .padding(.top, FGSpace.s)
            } else {
                checkInSubtitle
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        // Disabled for now — commented out rather than removed so the debug
        // menu (DebugMenu.swift) is still one uncomment away.
        // #if DEBUG
        // // Long-press anywhere on the header to fabricate history / switch user journeys.
        // .onLongPressGesture(minimumDuration: 0.4) {
        //     UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        //     isDebugging = true
        // }
        // #endif
        // `.contain`, not `.combine`: the banner and the summary are buttons,
        // and combining would fold them into the headline and lose that.
        .accessibilityElement(children: .contain)
    }

    private var cardSwapTransition: AnyTransition {
        if reduceMotion {
            return .opacity
        } else {
            return .asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .move(edge: .leading).combined(with: .opacity)
            )
        }
    }

    private func performSwap(_ item: MenuItem) {
        if model.hasRemainingSwaps {
            withAnimation(FGMotion.swap) {
                model.swap(item)
            }
            if let updated = model.menu.items.first(where: { $0.course == item.course }) {
                AccessibilityNotification.Announcement("Swapped \(item.course.label) to \(updated.session.title)").post()
            }
        } else {
            isShowingPaywall = true
        }
    }

    private var menuItems: some View {
        VStack(spacing: FGSpace.s) {
            ForEach(Array(model.menu.items.enumerated()), id: \.offset) { index, item in
                let isVisible = index < visibleMenuCardCount

                ZStack {
                    ForEach([item], id: \.id) { currentItem in
                        if currentItem.course == .main {
                            MenuItemCard(
                                item: currentItem,
                                isDone: model.isCompleted(currentItem),
                                isInProgress: model.isInProgress(currentItem),
                                canSwap: (model.canSwap(currentItem) || !model.hasRemainingSwaps) && !model.isCompleted(currentItem) && !model.isInProgress(currentItem),
                                isReset: model.isCycleReset(currentItem),
                                onOpen: { openSession(currentItem) },
                                onSwap: { performSwap(currentItem) }
                            )
                            .transition(cardSwapTransition)
                        } else {
                            MenuItemRow(
                                item: currentItem,
                                isDone: model.isCompleted(currentItem),
                                isInProgress: model.isInProgress(currentItem),
                                canSwap: (model.canSwap(currentItem) || !model.hasRemainingSwaps) && !model.isCompleted(currentItem) && !model.isInProgress(currentItem),
                                isReset: model.isCycleReset(currentItem),
                                onOpen: { openSession(currentItem) },
                                onSwap: { performSwap(currentItem) }
                            )
                            .transition(cardSwapTransition)
                        }
                    }
                }
                .opacity(isVisible ? 1 : 0)
                .scaleEffect(isVisible ? 1 : 0.96, anchor: .top)
                .offset(y: isVisible ? 0 : 10)
                .fgAnimation(FGMotion.settle.delay(FGMotion.stagger(index)), value: isVisible)
            }
        }
        .opacity(isMenuCompressed ? 0 : 1)
        .scaleEffect(
            x: isMenuCompressed ? 0.985 : 1,
            y: isMenuCompressed ? 0.94 : 1,
            anchor: .top
        )
    }



    /// Opens the session a widget tap asked for.
    ///
    /// Silently does nothing when the id is not on today's menu — the menu may
    /// have regenerated since the widget last drew, and dropping someone on
    /// today's menu is a better answer than an error about a session that is
    /// no longer being suggested.
    private func openRequestedSession(_ id: String?) {
        guard let id else { return }
        defer { requestedSessionID.wrappedValue = nil }
        if let item = model.menu.items.first(where: { $0.session.id == id }) {
            openSession(item)
        } else if let session = model.store.session(id: id) {
            let item = MenuItem(
                session: session,
                course: session.course,
                reasons: [.matchesIntent],
                reasonText: session.subtitle
            )
            openSession(item)
        }
    }

    private func openSession(_ item: MenuItem) {
        clearOneSignalDiscoveryTriggers()
        selected = item
    }

    /// The check-in represented as a seamless, tappable subtitle under the header.
    private struct CheckInAuraPulse: View {
        let checkIn: PlanCheckIn?
        var size: CGFloat = 18
        @State private var isPulsing = false
        @Environment(\.accessibilityReduceMotion) private var reduceMotion

        private var auraColor: Color {
            guard let checkIn else { return FGColor.rose }
            switch checkIn.energy {
            case .low: return FGColor.clay
            case .steady: return FGColor.sageDeep
            case .strong: return FGColor.clayDeep
            }
        }

        var body: some View {
            ZStack {
                // Breathing ambient aura wave
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                (checkIn == nil ? FGColor.rose : auraColor).opacity(0.38),
                                (checkIn == nil ? FGColor.clay : auraColor).opacity(0.18),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 2,
                            endRadius: size * 0.95
                        )
                    )
                    .frame(width: size * 1.6, height: size * 1.6)
                    .scaleEffect(isPulsing ? 1.25 : 0.88)
                    .opacity(isPulsing ? 0.70 : 0.30)
                    .animation(
                        reduceMotion ? .none : Animation.easeInOut(duration: 2.2).repeatForever(autoreverses: true),
                        value: isPulsing
                    )

                // Core AuraDot
                AuraDot(color: auraColor, size: size)
                    .scaleEffect(isPulsing && checkIn == nil ? 1.08 : 0.95)
                    .animation(
                        reduceMotion ? .none : Animation.easeInOut(duration: 2.2).repeatForever(autoreverses: true),
                        value: isPulsing
                    )
            }
            .frame(width: size, height: size)
            .onAppear {
                isPulsing = true
            }
        }
    }

    private var checkInSubtitle: some View {
        Button { isCheckingIn = true } label: {
            HStack(spacing: 8) {
                CheckInAuraPulse(checkIn: model.checkIn, size: 18)

                if let checkIn = model.checkIn {
                    Text(checkIn.detailedSummaryPhrase)
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundStyle(FGColor.inkMuted)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                } else {
                    Text("Tailor today's menu • 30s")
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundStyle(FGColor.inkMuted)
                        .lineLimit(1)
                }

                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(FGColor.inkMuted.opacity(0.6))
            }
            .padding(.vertical, 2)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(
            model.checkIn.map { "Today's check-in: \($0.detailedSummaryPhrase). Tap to adjust" }
                ?? "Tailor today's menu. Takes about 30 seconds"
        )
    }

    /// "Your menu" and the Routine button.
    private var menuHeading: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .center, spacing: FGSpace.s) {
                HStack(alignment: .center, spacing: 8) {
                    Text("Your menu")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(FGColor.ink)
                        .accessibilityAddTraits(.isHeader)

                    Button {
                        isShowingDopamineMenuTour = true
                    } label: {
                        Image(systemName: "info.circle")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(FGColor.inkMuted)
                    }
                    .buttonStyle(.feelGoodPress)
                    .accessibilityLabel("How the Dopamine Menu works")
                }

                Spacer(minLength: FGSpace.s)

                #if compiler(>=6.2)
                if #available(iOS 26, *) {
                    routineButtonLabel
                        .glassEffect(.regular.interactive(), in: Capsule())
                } else {
                    legacyMenuControls
                }
                #else
                legacyMenuControls
                #endif
            }

            if model.checkIn?.time.isZero == true || (model.checkIn == nil && model.menu.assumedCheckIn.time.isZero) {
                Text("Rest day · Untimed")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(FGColor.inkMuted)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var routineButtonLabel: some View {
        Button {
            isShowingMyMenu = true
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "plus")
                    .font(.system(size: 11, weight: .semibold))
                Text("Routine")
                    .font(FGFont.label.weight(.medium))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .foregroundStyle(FGColor.ink)
            .fixedSize()
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Add custom routine or view My Menu")
    }

    @ViewBuilder
    private var legacyMenuControls: some View {
        routineButtonLabel
            .background(FGColor.surface)
            .clipShape(Capsule())
            .overlay(Capsule().strokeBorder(FGColor.lineStrong, lineWidth: 1))
    }

    private var currentMenuAura: FGAura {
        (model.checkIn ?? model.menu.assumedCheckIn).energy.checkInAura
    }

    private var currentMenuAuraID: String {
        (model.checkIn ?? model.menu.assumedCheckIn).energy.rawValue
    }

    private func handleCheckInDismissal() {
        guard let update = pendingCheckInUpdate else {
            presentPendingLittleWinCelebration()
            return
        }
        pendingCheckInUpdate = nil

        let didChange = model.checkIn != update.checkIn
            || model.calendarOpening != update.calendarOpening

        Task { @MainActor in
            if didChange {
                await regenerateMenu {
                    apply(update)
                }
            } else {
                apply(update)
            }
            presentPendingLittleWinCelebration()
        }
    }

    private func apply(_ update: PendingCheckInUpdate) {
        model.apply(update.checkIn, calendarOpening: update.calendarOpening)
        if let completedMovementPlan = update.completedMovementPlan {
            model.log(completedMovementPlan)
        }
    }

    @MainActor
    private func regenerateMenu(_ update: @MainActor () -> Void) async {
        guard !isRegeneratingMenu else {
            update()
            return
        }
        isRegeneratingMenu = true

        guard !reduceMotion else {
            update()
            visibleMenuCardCount = Int.max
            isRegeneratingMenu = false
            return
        }

        withAnimation(.easeInOut(duration: 0.2)) {
            isMenuCompressed = true
        }
        try? await Task.sleep(for: .milliseconds(210))

        visibleMenuCardCount = 0
        withAnimation(.easeInOut(duration: 0.65)) {
            update()
        }
        isMenuCompressed = false

        // Let SwiftUI install the rebuilt, hidden card tree before revealing it.
        try? await Task.sleep(for: .milliseconds(40))
        visibleMenuCardCount = model.menu.items.count

        let settleTime = 560 + (model.menu.items.count * 60)
        try? await Task.sleep(for: .milliseconds(settleTime))
        visibleMenuCardCount = Int.max
        isRegeneratingMenu = false
    }

    private func presentCompletionPaywallIfNeeded() {
        guard shouldOfferProAfterDismissal else { return }
        shouldOfferProAfterDismissal = false

        // Adding these local triggers makes the discovery message eligible
        // only now: the completed session sheet has fully dismissed and Today
        // is visible again. They are deliberately absent while a session is
        // being considered or played.
        syncOneSignalDiscoveryTriggers()

        if !authService.isAuthenticated && !hasShownFirstCompletionAuthPrompt {
            hasShownFirstCompletionAuthPrompt = true
            isShowingAuthPrompt = true
            return
        }

        guard !model.isProUser, !hasShownFirstCompletionPaywall else { return }
        hasShownFirstCompletionPaywall = true
        isShowingPaywall = true
    }

    private func presentPendingLittleWinCelebration() {
        littleWinCelebration = model.takePendingLittleWinCelebration()
    }

    private func syncOneSignalDiscoveryTriggers() {
        OneSignalManager.shared.setInAppTriggers([
            "completed_count": String(model.completedSessionCount),
            "has_custom_routine": model.hasCustomRoutine ? "true" : "false",
        ])
    }

    private func clearOneSignalDiscoveryTriggers() {
        OneSignalManager.shared.removeInAppTriggers([
            "completed_count",
            "has_custom_routine",
        ])
    }

    @ViewBuilder
    private var calendarFitCard: some View {
        if let opening = model.calendarOpening, let main = model.menu.main {
            HStack(alignment: .top, spacing: FGSpace.s) {
                Image(systemName: "calendar.badge.clock")
                    .foregroundStyle(FGColor.goldDeep)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 3) {
                    Text("A good opening today")
                        .font(FGFont.label.weight(.semibold))
                        .foregroundStyle(FGColor.ink)
                    Text("Try \(main.session.title) around \(opening.start.formatted(date: .omitted, time: .shortened)).")
                        .font(FGFont.caption)
                        .foregroundStyle(FGColor.inkMuted)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(FGSpace.m)
            .background(
                RoundedRectangle(cornerRadius: FGRadius.card - 4, style: .continuous)
                    .fill(FGColor.surface.opacity(0.92))
            )
            .postHogMask()
            .accessibilityElement(children: .combine)
        }
    }
}

private struct MenuItemCard: View {
    let item: MenuItem
    let isDone: Bool
    let isInProgress: Bool
    let canSwap: Bool
    let isReset: Bool
    let onOpen: () -> Void
    let onSwap: () -> Void

    @State private var dragOffset: CGFloat = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Button(action: onOpen) {
                MenuItemBody(
                    item: item,
                    isDone: isDone,
                    isInProgress: isInProgress,
                    isHighlighted: false
                )
                .contentShape(Rectangle())
            }
            .buttonStyle(.feelGoodPress)

            if canSwap {
                MenuSwapButton(item: item, isReset: isReset, action: onSwap)
                    .padding(.top, 18)
                    .padding(.trailing, 20)
            }
        }
        .offset(x: dragOffset)
        .highPriorityGesture(
            canSwap ? DragGesture(minimumDistance: 15)
                .onChanged { gesture in
                    guard abs(gesture.translation.width) > abs(gesture.translation.height) else { return }
                    if !reduceMotion {
                        if gesture.translation.width < 0 {
                            dragOffset = max(-80, gesture.translation.width * 0.75)
                        } else {
                            dragOffset = min(15, gesture.translation.width * 0.2)
                        }
                    }
                }
                .onEnded { gesture in
                    guard abs(gesture.translation.width) > abs(gesture.translation.height) else {
                        withAnimation(FGMotion.gentle) { dragOffset = 0 }
                        return
                    }
                    if gesture.translation.width < -30 || gesture.predictedEndTranslation.width < -75 {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        onSwap()
                        withAnimation(FGMotion.gentle) {
                            dragOffset = 0
                        }
                    } else {
                        withAnimation(FGMotion.gentle) {
                            dragOffset = 0
                        }
                    }
                }
            : nil
        )
        .accessibilityElement(children: .contain)
        .accessibilityLabel(
            "\(item.course.label). \(item.session.title). \(isDone ? "Done today. " : isInProgress ? "In progress. Resume. " : "")"
            + "\(item.session.chips.joined(separator: ", ")). \(item.reasonText)"
        )
        .accessibilityAddTraits(.isButton)
        .accessibilityAction(named: isReset ? "Start over \(item.course.label)" : "Swap \(item.course.label)") {
            if canSwap { onSwap() }
        }
    }
}

/// Marks something already done today. Not a score, not a count, and nothing
/// accrues from it — it's here so a finished item stops asking to be started.
private struct DoneMark: View {
    /// Fires once, right after this view is inserted (see `MenuItemBody`'s
    /// `.transition` on it) — a static checkmark landing in a scaled-in pill
    /// reads as arrived, not achieved. The bounce is what actually sells
    /// "you just did that."
    @State private var hasBounced = false

    var body: some View {
        HStack(spacing: FGSpace.xs) {
            Image(systemName: "checkmark.circle.fill")
                .symbolEffect(.bounce, value: hasBounced)
                .foregroundStyle(FGColor.sageDeep)
            Text("Done")
                .foregroundStyle(FGColor.sageDeep)
        }
        .font(.system(size: 13, weight: .semibold, design: .rounded))
        .accessibilityHidden(true)
        .onAppear { hasBounced.toggle() }
    }
}

private struct ResumeMark: View {
    var body: some View {
        HStack(spacing: FGSpace.xs) {
            Image(systemName: "play.circle.fill")
                .foregroundStyle(FGColor.ink)
            Text("Resume")
                .foregroundStyle(FGColor.ink)
        }
        .lineLimit(1)
        .fixedSize()
        .font(.system(size: 13, weight: .semibold, design: .rounded))
        .accessibilityHidden(true)
    }
}

/// Everything that isn't the Main. Same information, one glance.
private struct MenuItemRow: View {
    let item: MenuItem
    let isDone: Bool
    let isInProgress: Bool
    let canSwap: Bool
    let isReset: Bool
    let onOpen: () -> Void
    let onSwap: () -> Void

    @State private var dragOffset: CGFloat = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Button(action: onOpen) {
                MenuItemBody(
                    item: item,
                    isDone: isDone,
                    isInProgress: isInProgress,
                    isHighlighted: false
                )
                .contentShape(Rectangle())
            }
            .buttonStyle(.feelGoodPress)

            if canSwap {
                MenuSwapButton(item: item, isReset: isReset, action: onSwap)
                    .padding(.top, 18)
                    .padding(.trailing, 20)
            }
        }
        .offset(x: dragOffset)
        .highPriorityGesture(
            canSwap ? DragGesture(minimumDistance: 15)
                .onChanged { gesture in
                    guard abs(gesture.translation.width) > abs(gesture.translation.height) else { return }
                    if !reduceMotion {
                        if gesture.translation.width < 0 {
                            dragOffset = max(-80, gesture.translation.width * 0.75)
                        } else {
                            dragOffset = min(15, gesture.translation.width * 0.2)
                        }
                    }
                }
                .onEnded { gesture in
                    guard abs(gesture.translation.width) > abs(gesture.translation.height) else {
                        withAnimation(FGMotion.gentle) { dragOffset = 0 }
                        return
                    }
                    if gesture.translation.width < -30 || gesture.predictedEndTranslation.width < -75 {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        onSwap()
                        withAnimation(FGMotion.gentle) {
                            dragOffset = 0
                        }
                    } else {
                        withAnimation(FGMotion.gentle) {
                            dragOffset = 0
                        }
                    }
                }
            : nil
        )
        .accessibilityElement(children: .contain)
        .accessibilityLabel(
            "\(item.course.label). \(item.session.title). \(isDone ? "Done today. " : isInProgress ? "In progress. Resume. " : "")"
            + "\(item.session.durationLabel). \(item.reasonText)"
        )
        .accessibilityAddTraits(.isButton)
        .accessibilityAction(named: isReset ? "Start over \(item.course.label)" : "Swap \(item.course.label)") {
            if canSwap { onSwap() }
        }
    }
}

/// One menu row: a bloom of the course's colour, the course and its length,
/// the session, and why it is there.
private struct MenuItemBody: View {
    let item: MenuItem
    let isDone: Bool
    let isInProgress: Bool
    let isHighlighted: Bool
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        // Bottom-aligned, with the text column held to a minimum height —
        // the shuffle button floats over the top-trailing corner, so the
        // mascot needs to clear it even when the title is one short line.
        HStack(alignment: .bottom, spacing: FGSpace.m) {
            VStack(alignment: .leading, spacing: 10) {
                // Top metadata row: White pill badge matching design reference
                HStack(alignment: .center, spacing: 6) {
                    Text(item.course.label.uppercased())
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .lineLimit(1)
                        .fixedSize()
                        .foregroundStyle(item.course.accentText)
                        .padding(.horizontal, 11)
                        .padding(.vertical, 5)
                        .background(Color.white.opacity(colorScheme == .dark ? 0.20 : 0.88))
                        .clipShape(Capsule())

                    if isDone {
                        DoneMark()
                            .padding(.leading, 2)
                            .transition(.scale(scale: 0.7).combined(with: .opacity))
                    } else if isInProgress {
                        ResumeMark()
                            .padding(.leading, 2)
                    }
                }

                // Session Title in SF Rounded Semibold — lighter than the bold
                // pills above it so the card has a weight hierarchy. The why
                // waits behind a tap, on the session's own detail screen.
                Text(item.session.title)
                    .font(.system(size: 22, weight: .semibold, design: .rounded))
                    .foregroundStyle(isDone ? FGColor.inkMuted : item.course.accentText)
                    .lineSpacing(-2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, minHeight: 106, alignment: .topLeading)

            // The course's mascot — the same fruit this course wears on My
            // Menu and the paywall, so a Side here and a Side there read as
            // the same thing. Bottom-anchored, clear of the shuffle button
            // floating over the top-trailing corner.
            Image(item.course.menuMascotAsset)
                .resizable()
                .scaledToFit()
                .frame(width: 64, height: 64)
                .accessibilityHidden(true)
                .padding(.bottom, 2)
        }
        .padding(.vertical, 18)
        .padding(.horizontal, 20)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(item.course.accentGradient)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(
                    isDone
                        ? FGColor.line
                        : Color.white.opacity(colorScheme == .dark ? 0.12 : 0.35),
                    lineWidth: 1
                )
        )
        // Done reads as "chosen, not crossed off" — a quieter card rather
        // than a strikethrough, which read like a to-do list item.
        .opacity(isDone ? 0.6 : 1)
        .fgAnimation(FGMotion.settle, value: isDone)
    }
}

private struct MenuSwapButton: View {
    let item: MenuItem
    let isReset: Bool
    let action: () -> Void
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: isReset ? "arrow.counterclockwise" : "arrow.triangle.2.circlepath")
                    .font(.system(size: 11, weight: .bold))
                Text(isReset ? "Reset" : "Swap")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
            }
            .foregroundStyle(item.course.accentText)
            .padding(.horizontal, 9)
            .padding(.vertical, 5)
            .background(Color.white.opacity(colorScheme == .dark ? 0.20 : 0.88))
            .clipShape(Capsule())
        }
        .buttonStyle(.feelGoodPress)
        .accessibilityLabel(isReset ? "Start over" : "Swap \(item.course.label)")
        .accessibilityHint(
            isReset
                ? "Cycles back to the first \(item.course.label.lowercased()) options"
                : "Swaps in a different \(item.course.label.lowercased()); doesn't skip it"
        )
    }
}

#Preview {
    TodayView(
        model: TodayModel(
            store: try! ContentStore.bundled(),
            profile: PlanProfile(
                availableActivities: Set(Activity.allCases),
                equipment: [.none, .mat, .weights, .outdoor],
                places: Set(Place.allCases),
                intent: .strengthen
            ),
            now: Date()
        )
    )
}
