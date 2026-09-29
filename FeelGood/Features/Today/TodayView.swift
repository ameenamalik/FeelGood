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
import EventKit

private struct PendingCheckInUpdate {
    let checkIn: PlanCheckIn
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
    let model: TodayModel
    /// Set by a widget tap. Consumed here and cleared, so the same link does
    /// not reopen the sheet every time this view is rebuilt.
    var requestedSessionID: Binding<String?> = .constant(nil)
    @State private var isCheckingIn = false
    @State private var isShowingPaywall = false
    @State private var paywallContext: PaywallContext = .general
    @State private var shouldOfferProAfterDismissal = false
    @AppStorage("hasShownFirstCompletionPaywall") private var hasShownFirstCompletionPaywall = false
    @AppStorage("hasShownFirstCompletionAuthPrompt") private var hasShownFirstCompletionAuthPrompt = false
    // Retain the old first-menu flag so existing installs that already saw
    // that prompt do not receive a duplicate account ask after completion.
    @AppStorage(FirstRunFlow.hasSeenWelcomeSignUpKey) private var hasShownFirstMenuAuthPrompt = false
    @State private var isShowingAuthPrompt = false
    @Environment(AuthService.self) private var authService
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.scenePhase) private var scenePhase
    @State private var isShowingMyMenu = false
    @AppStorage("hasSeenDopamineMenuTour") private var hasSeenDopamineMenuTour = false
    @State private var isShowingDopamineMenuTour = false
    @State private var selected: MenuItem?
    @State private var manualSwapTarget: MenuItem?
    @State private var littleWinCelebration: LittleWinCelebration?
    @State private var pendingCheckInUpdate: PendingCheckInUpdate?
    @State private var isRegeneratingMenu = false
    @State private var isMenuCompressed = false
    @State private var visibleMenuCardCount = Int.max
    @State private var calendarMovementPlan: CalendarMovementPlan?
    @State private var countedCalendarPlanID: String?
    @State private var calendarPlanAwaitingConfirmation: CalendarMovementPlan?
    @State private var calendarRefreshTask: Task<Void, Never>?
    @State private var isViewVisible = false
    @AppStorage(CalendarMovementPreferences.personalizationEnabledKey)
    private var isCalendarPersonalizationEnabled = false
    @AppStorage(CalendarMovementPreferences.recognitionEnabledKey)
    private var isMovementRecognitionEnabled = false
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
                standingIntents: model.profile.intents,
                places: model.profile.places
            ) { checkIn in
                pendingCheckInUpdate = PendingCheckInUpdate(checkIn: checkIn)
                isCheckingIn = false
            }
        }
        .sheet(isPresented: $isShowingPaywall) {
            FeelGoodPaywallView(context: paywallContext)
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
        .sheet(item: $manualSwapTarget) { item in
            CatalogPickerSheet(
                model: model,
                preferredCourse: item.course,
                lockCourse: true
            ) { selectedSession in
                withAnimation(FGMotion.swap) {
                    model.setTodayCourseOverride(session: selectedSession, for: item.course)
                }
                AccessibilityNotification.Announcement("Swapped \(item.course.label) to \(selectedSession.title)").post()
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
                subtitle: "You finished today's session! Create an account to keep your progress and daily menus across devices.",
                showsHeroIllustration: false,
                initialMode: .createAccount,
                guestButtonTitle: "Continue as guest"
            )
        }
        .confirmationDialog(
            "Did this movement happen?",
            isPresented: Binding(
                get: { calendarPlanAwaitingConfirmation != nil },
                set: { isPresented in
                    if !isPresented { calendarPlanAwaitingConfirmation = nil }
                }
            ),
            titleVisibility: .visible,
            presenting: calendarPlanAwaitingConfirmation
        ) { plan in
            Button("Yes, count it") {
                model.log(plan)
                countedCalendarPlanID = plan.id
                calendarPlanAwaitingConfirmation = nil
                AccessibilityNotification.Announcement("Counted for today").post()
            }

            Button("No, it didn't happen", role: .destructive) {
                calendarPlanAwaitingConfirmation = nil
                dismissCalendarMovementPlan(plan)
            }

            Button("Cancel", role: .cancel) {
                calendarPlanAwaitingConfirmation = nil
            }
        } message: { _ in
            Text("FeelGood only adds it to your movement log when you confirm it.")
        }
        .onChange(of: requestedSessionID.wrappedValue, initial: true) { _, id in
            openRequestedSession(id)
        }
        .onAppear {
            isViewVisible = true
            // Calendar availability now shapes the menu quietly. Clear any
            // exact-time reminder saved by the previous scheduling UI.
            CalendarOpeningReminderService.shared.cancel()
            model.setCalendarOpening(nil)

            // Discovery messaging belongs to the moment after a completion,
            // never to app launch or the start of a calming session.
            clearOneSignalDiscoveryTriggers()
            #if DEBUG
            if ProcessInfo.processInfo.arguments.contains("-FGResetTour") {
                hasSeenDopamineMenuTour = false
            }
            #endif
            if !hasSeenDopamineMenuTour {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    if !hasSeenDopamineMenuTour {
                        isShowingDopamineMenuTour = true
                    }
                }
            }
        }
        .task(id: calendarPersonalizationTaskID) {
            await refreshCalendarMovementPlan()
        }
        .onChange(of: scenePhase) { _, phase in
            guard phase == .active else { return }
            scheduleCalendarMovementRefresh(after: .milliseconds(150))
        }
        .onReceive(NotificationCenter.default.publisher(for: .EKEventStoreChanged)) { _ in
            // EventKit commonly emits several notifications for one save.
            // Coalesce them so the visible card changes once, after Calendar
            // has finished committing the edit.
            scheduleCalendarMovementRefresh(after: .milliseconds(350))
        }
        .onDisappear {
            isViewVisible = false
            calendarRefreshTask?.cancel()
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

    /// Returns whether the swipe replaced the card. The gesture keeps the old
    /// card offscreen while its removal transition completes only in that case.
    @discardableResult
    private func performSwipeSkip(_ item: MenuItem) -> Bool {
        if model.hasRemainingSwaps {
            withAnimation(FGMotion.swap) {
                model.swap(item)
            }
            if let updated = model.menu.items.first(where: { $0.course == item.course }) {
                AccessibilityNotification.Announcement("Swapped \(item.course.label) to \(updated.session.title)").post()
                return updated.id != item.id
            }
        } else {
            paywallContext = .secondSwap
            isShowingPaywall = true
        }
        return false
    }

    private func handleSwapButtonTap(_ item: MenuItem) {
        if model.isProUser {
            manualSwapTarget = item
        } else if model.hasRemainingSwaps {
            // Free gets the same single automatic swap whether they discover
            // it by swiping or use the visible, accessible Swap button. The
            // catalog picker remains Pro's more-controlled replacement flow.
            _ = performSwipeSkip(item)
        } else {
            paywallContext = .secondSwap
            isShowingPaywall = true
        }
    }

    private var menuItems: some View {
        VStack(spacing: FGSpace.s) {
            if shouldCalendarMovementReplaceMain, let calendarMovementPlan {
                calendarMovementCard(calendarMovementPlan, replacesMain: true)
                    .transition(cardSwapTransition)

                if let companion = calendarCompanion(for: calendarMovementPlan) {
                    calendarCompanionCard(companion.item, phase: companion.phase, plan: calendarMovementPlan)
                        .transition(cardSwapTransition)
                }
            } else if let calendarMovementPlan {
                calendarMovementCard(calendarMovementPlan, replacesMain: false)
                    .transition(cardSwapTransition)

                regularMenuItems
            } else {
                regularMenuItems
            }
        }
        .opacity(isMenuCompressed ? 0 : 1)
        .scaleEffect(
            x: isMenuCompressed ? 0.985 : 1,
            y: isMenuCompressed ? 0.94 : 1,
            anchor: .top
        )
    }

    private var regularMenuItems: some View {
        ForEach(Array(model.menu.items.enumerated()), id: \.offset) { index, item in
            let isVisible = index < visibleMenuCardCount

            ZStack {
                ForEach([item], id: \.id) { currentItem in
                    if currentItem.course == .main {
                        MenuItemCard(
                            item: currentItem,
                            caption: MenuCopy.cardLine(
                                for: currentItem,
                                checkIn: model.checkIn ?? model.menu.assumedCheckIn
                            ),
                            isDone: model.isCompleted(currentItem),
                            isInProgress: model.isInProgress(currentItem),
                            canSwap: !model.isCompleted(currentItem) && !model.isInProgress(currentItem),
                            isReset: model.isCycleReset(currentItem),
                            isFirstCard: index == 0,
                            onOpen: { openSession(currentItem) },
                            onSelectManual: { handleSwapButtonTap(currentItem) },
                            onSkip: { performSwipeSkip(currentItem) }
                        )
                        .transition(cardSwapTransition)
                    } else {
                        MenuItemRow(
                            item: currentItem,
                            isDone: model.isCompleted(currentItem),
                            isInProgress: model.isInProgress(currentItem),
                            canSwap: !model.isCompleted(currentItem) && !model.isInProgress(currentItem),
                            isReset: model.isCycleReset(currentItem),
                            isFirstCard: index == 0,
                            onOpen: { openSession(currentItem) },
                            onSelectManual: { handleSwapButtonTap(currentItem) },
                            onSkip: { performSwipeSkip(currentItem) }
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

    /// Calendar movement shapes the quiet default menu, but an explicit
    /// non-rest check-in is a fresh statement of intent. If somebody says they
    /// have 20 minutes now, keep the calendar acknowledgement and still give
    /// them a normal menu that fits those 20 minutes.
    private var shouldCalendarMovementReplaceMain: Bool {
        calendarMovementPlan != nil && model.checkIn == nil
    }

    private func calendarCompanion(
        for plan: CalendarMovementPlan,
        now: Date = Date()
    ) -> (item: MenuItem, phase: CalendarMovementCompanionPhase)? {
        let phase: CalendarMovementCompanionPhase
        if now < plan.start {
            phase = .warmUp
        } else if now >= plan.end, countedCalendarPlanID == plan.id {
            phase = .recovery
        } else {
            return nil
        }

        guard let item = model.calendarCompanion(for: plan, phase: phase) else { return nil }
        return (item, phase)
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
                Text("Recovery day · Untimed")
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

        Task { @MainActor in
            let calendarAwareCheckIn = await checkInAdjustedForCalendar(update.checkIn)
            let didChange = model.checkIn != calendarAwareCheckIn || model.calendarOpening != nil

            if didChange {
                await regenerateMenu {
                    model.apply(calendarAwareCheckIn)
                }
            } else {
                model.apply(calendarAwareCheckIn)
            }
            presentPendingLittleWinCelebration()
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

        if !authService.isAuthenticated,
           !hasShownFirstMenuAuthPrompt,
           !hasShownFirstCompletionAuthPrompt {
            hasShownFirstCompletionAuthPrompt = true
            isShowingAuthPrompt = true
            return
        }

        guard !model.isProUser, !hasShownFirstCompletionPaywall else { return }
        hasShownFirstCompletionPaywall = true
        paywallContext = .general
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

    private var calendarPersonalizationTaskID: String {
        "\(model.isProUser)-\(isCalendarPersonalizationEnabled)-\(isMovementRecognitionEnabled)"
    }

    private func checkInAdjustedForCalendar(_ checkIn: PlanCheckIn) async -> PlanCheckIn {
        guard
            model.isProUser,
            isCalendarPersonalizationEnabled,
            EventKitCalendarAvailabilityService.shared.connectionState == .connected
        else { return checkIn }

        do {
            guard let opening = try await EventKitCalendarAvailabilityService.shared.suggestedOpening(
                on: Date(),
                preferredTime: model.profile.bestTimeOfDay,
                realisticMinutes: min(model.profile.realisticMinutes, checkIn.time.maxMinutes),
                calendar: .current
            ), opening.budget.maxMinutes < checkIn.time.maxMinutes else {
                return checkIn
            }

            var adjusted = checkIn
            adjusted.time = opening.budget
            return adjusted
        } catch {
            return checkIn
        }
    }

    private func refreshCalendarMovementPlan() async {
        guard
            model.isProUser,
            isMovementRecognitionEnabled,
            EventKitCalendarAvailabilityService.shared.connectionState == .connected
        else {
            calendarMovementPlan = nil
            countedCalendarPlanID = nil
            return
        }

        do {
            let now = Date()
            let plans = try await EventKitCalendarAvailabilityService.shared
                .movementPlans(on: now, calendar: .current)
                .filter { !CalendarMovementPreferences.isHandled($0.id) }

            let nextPlan = plans
                .filter { $0.end <= now }
                .max { $0.end < $1.end }
                ?? plans.filter { $0.end > now }.min { $0.start < $1.start }

            guard nextPlan != calendarMovementPlan else { return }
            withAnimation(reduceMotion ? nil : FGMotion.gentle) {
                calendarMovementPlan = nextPlan
                countedCalendarPlanID = nil
            }
        } catch {
            // Keep the last known card during a transient EventKit read error.
            // Clearing and restoring it on the next notification looks like a
            // flash even though the calendar data never meaningfully changed.
        }
    }

    private func scheduleCalendarMovementRefresh(after delay: Duration) {
        calendarRefreshTask?.cancel()
        calendarRefreshTask = Task { @MainActor in
            do {
                try await Task.sleep(for: delay)
                try Task.checkCancellation()
                await refreshCalendarMovementPlan()
            } catch {
                // A newer Calendar notification superseded this refresh.
            }
        }
    }

    private func calendarMovementCard(_ plan: CalendarMovementPlan, replacesMain: Bool) -> some View {
        let now = Date()
        let hasEnded = plan.end <= now
        let isHappeningNow = plan.start <= now && !hasEnded
        let wasCounted = countedCalendarPlanID == plan.id

        return Button {
            guard !wasCounted else { return }
            calendarPlanAwaitingConfirmation = plan
        } label: {
            HStack(alignment: .top, spacing: FGSpace.m) {
                Image(plan.activity.calendarMascotAsset)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 44, height: 44)
                    .padding(4)
                    .background(Circle().fill(FGColor.gold.opacity(0.28)))
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: FGSpace.xs) {
                    HStack {
                        Text(replacesMain ? "TODAY'S MAIN" : "FROM YOUR CALENDAR")
                            .font(FGFont.caption.weight(.bold))
                            .foregroundStyle(FGColor.inkMuted)

                        Spacer(minLength: FGSpace.xs)

                        if !wasCounted {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(FGColor.inkMuted)
                                .accessibilityHidden(true)
                        }
                    }

                    Text(plan.activity.label)
                        .font(FGFont.itemTitle)
                        .foregroundStyle(FGColor.ink)

                    Label(calendarMovementTiming(plan, isHappeningNow: isHappeningNow), systemImage: "calendar")
                        .font(FGFont.caption.weight(.semibold))
                        .foregroundStyle(FGColor.inkMuted)

                    Text(calendarMovementDetail(hasEnded: hasEnded, wasCounted: wasCounted))
                        .font(FGFont.caption)
                        .foregroundStyle(FGColor.inkMuted)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(FGSpace.m)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(RoundedRectangle(cornerRadius: FGRadius.card, style: .continuous))
            .background(
                RoundedRectangle(cornerRadius: FGRadius.card, style: .continuous)
                    .fill(FGAura.sage.mid.opacity(colorScheme == .dark ? 0.26 : 0.38))
            )
            .overlay(
                RoundedRectangle(cornerRadius: FGRadius.card, style: .continuous)
                    .strokeBorder(FGColor.lineStrong, lineWidth: 1)
                    .allowsHitTesting(false)
            )
        }
        .buttonStyle(.feelGoodPress)
        .disabled(wasCounted)
        .postHogMask()
        .accessibilityLabel("Today's main, \(plan.activity.label). \(calendarMovementTiming(plan, isHappeningNow: isHappeningNow))")
        .accessibilityHint(wasCounted ? "Counted for today" : "Double tap to say whether it happened")
    }

    private func calendarCompanionCard(
        _ item: MenuItem,
        phase: CalendarMovementCompanionPhase,
        plan: CalendarMovementPlan
    ) -> some View {
        CalendarCompanionCard(item: item, phase: phase, activity: plan.activity) {
            openSession(item)
        }
    }

    private func calendarMovementTiming(_ plan: CalendarMovementPlan, isHappeningNow: Bool) -> String {
        if isHappeningNow { return "On your calendar now" }
        return "\(plan.durationMinutes) min · \(plan.start.formatted(date: .omitted, time: .shortened))"
    }

    private func calendarMovementDetail(hasEnded: Bool, wasCounted: Bool) -> String {
        if wasCounted { return "Counted for today. Nice work." }
        if hasEnded { return "Did this happen? FeelGood only counts it when you say so." }
        return "Already part of your day, so we kept the rest of your menu light."
    }

    private func dismissCalendarMovementPlan(_ plan: CalendarMovementPlan) {
        CalendarMovementPreferences.markHandled(plan.id)
        withAnimation(FGMotion.settle) {
            calendarMovementPlan = nil
        }
        AccessibilityNotification.Announcement("Your regular main routine is back").post()
        scheduleCalendarMovementRefresh(after: .milliseconds(150))
    }
}

private struct CalendarCompanionCard: View {
    let item: MenuItem
    let phase: CalendarMovementCompanionPhase
    let activity: Activity
    let onOpen: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    private var eyebrow: String {
        phase == .warmUp ? "OPTIONAL WARM-UP" : "OPTIONAL RECOVERY"
    }

    private var detail: String {
        switch phase {
        case .warmUp:
            "A little prep for your \(activity.label.lowercased()) — whenever it feels useful."
        case .recovery:
            "A gentle way to settle after your \(activity.label.lowercased())."
        }
    }

    var body: some View {
        Button(action: onOpen) {
            HStack(spacing: FGSpace.m) {
                mascot
                copy
                playButton
            }
            .padding(FGSpace.m)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(RoundedRectangle(cornerRadius: FGRadius.card, style: .continuous))
            .background(cardBackground)
            .overlay(cardBorder)
        }
        .buttonStyle(.feelGoodPress)
        .postHogMask()
        .accessibilityLabel("\(eyebrow), \(item.session.title), \(item.session.durationLabel)")
        .accessibilityHint("Double tap to start")
    }

    private var mascot: some View {
        Image(item.course.menuMascotAsset)
            .resizable()
            .scaledToFit()
            .frame(width: 40, height: 40)
            .padding(4)
            .background(Circle().fill(FGColor.rose.opacity(colorScheme == .dark ? 0.22 : 0.16)))
            .accessibilityHidden(true)
    }

    private var copy: some View {
        VStack(alignment: .leading, spacing: FGSpace.xs) {
            HStack(spacing: FGSpace.xs) {
                Text(eyebrow)
                    .font(FGFont.caption.weight(.bold))
                Spacer(minLength: 0)
                Text(item.session.durationLabel.uppercased())
                    .font(FGFont.caption.weight(.bold))
            }
            .foregroundStyle(FGColor.inkMuted)

            Text(item.session.title)
                .font(FGFont.itemTitle)
                .foregroundStyle(FGColor.ink)
                .fixedSize(horizontal: false, vertical: true)

            Text(detail)
                .font(FGFont.caption)
                .foregroundStyle(FGColor.inkMuted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var playButton: some View {
        Image(systemName: "play.fill")
            .font(.system(size: 14, weight: .bold))
            .foregroundStyle(FGColor.ink)
            .frame(width: 38, height: 38)
            .background(Circle().fill(FGColor.surface))
            .accessibilityHidden(true)
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: FGRadius.card, style: .continuous)
            .fill(FGColor.surface.opacity(colorScheme == .dark ? 0.92 : 0.88))
    }

    private var cardBorder: some View {
        RoundedRectangle(cornerRadius: FGRadius.card, style: .continuous)
            .strokeBorder(FGColor.lineStrong, lineWidth: 1)
            .allowsHitTesting(false)
    }
}

private struct MenuItemCard: View {
    let item: MenuItem
    /// One sentence on why this is the main pick. The rows below carry none.
    let caption: String?
    let isDone: Bool
    let isInProgress: Bool
    let canSwap: Bool
    let isReset: Bool
    /// Whether this is the first card on today's menu — the one that plays
    /// the one-time swipe hint, so the demo never runs more than once per
    /// screen and never on a card someone hasn't scrolled to yet.
    let isFirstCard: Bool
    let onOpen: () -> Void
    let onSelectManual: () -> Void
    let onSkip: () -> Bool

    @State private var dragOffset: CGFloat = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack(alignment: .trailing) {
            if canSwap {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.system(size: 14, weight: .bold))
                    Text("Swap")
                        .font(FGFont.label.weight(.bold))
                }
                .foregroundStyle(FGColor.ink)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(FGAura.apricot.mid.opacity(0.35))
                .clipShape(Capsule())
                .padding(.trailing, 16)
                .opacity(min(1, max(0, -dragOffset / 40)))
            }

            ZStack(alignment: .topTrailing) {
                Button(action: onOpen) {
                    MenuItemBody(
                        item: item,
                        caption: caption,
                        isDone: isDone,
                        isInProgress: isInProgress,
                        isHighlighted: false
                    )
                    .contentShape(Rectangle())
                }
                .buttonStyle(.feelGoodPress)

                if canSwap {
                    MenuSwapButton(item: item, isReset: isReset, action: onSelectManual)
                        .padding(.top, 14)
                        .padding(.trailing, 20)
                }
            }
            .offset(x: dragOffset)
            // Not a DragGesture: any SwiftUI drag on a card stops it scrolling
            // (HorizontalSwipe.swift), so vertical and diagonal drags must fail early.
            .fgSwipeToSkip(isEnabled: canSwap, offset: $dragOffset, reduceMotion: reduceMotion, onSkip: onSkip)
        }
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .accessibilityElement(children: .contain)
        .accessibilityLabel(
            "\(item.course.label). \(item.session.title). \(isDone ? "Done today. " : isInProgress ? "In progress. Resume. " : "")"
            + "\(item.session.chips.joined(separator: ", ")). \(item.reasonText)"
        )
        .accessibilityAddTraits(.isButton)
        .accessibilityAction(named: isReset ? "Start over \(item.course.label)" : "Swap \(item.course.label)") {
            if canSwap { onSelectManual() }
        }
        .accessibilityAction(named: "Quick skip \(item.course.label)") {
            if canSwap { _ = onSkip() }
        }
        .task { await playSwipeHintIfNeeded() }
    }

    /// The tap-to-swap button is self-explanatory; the swipe gesture isn't —
    /// nothing about a resting card signals it can be dragged away. Rather
    /// than a permanent layout change, this plays the real gesture once, on
    /// the first card someone sees, the first time they ever land on Today.
    private func playSwipeHintIfNeeded() async {
        guard isFirstCard, canSwap, !SwipeHint.hasPlayed else { return }
        SwipeHint.hasPlayed = true
        guard !reduceMotion else { return }
        try? await Task.sleep(for: .seconds(1))
        withAnimation(.easeInOut(duration: 0.45)) { dragOffset = -64 }
        try? await Task.sleep(for: .seconds(1))
        withAnimation(FGMotion.gentle) { dragOffset = 0 }
    }
}

/// One-time, across both card shapes that support swiping (`MenuItemCard`,
/// `MenuItemRow`) — whichever kind of session lands in the first course slot
/// is the one that demos it, never both.
private enum SwipeHint {
    private static let key = "FeelGood.HasPlayedSwipeHint"

    static var hasPlayed: Bool {
        get { UserDefaults.standard.bool(forKey: key) }
        set { UserDefaults.standard.set(newValue, forKey: key) }
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
    let isFirstCard: Bool
    let onOpen: () -> Void
    let onSelectManual: () -> Void
    let onSkip: () -> Bool

    @State private var dragOffset: CGFloat = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack(alignment: .trailing) {
            if canSwap {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.system(size: 14, weight: .bold))
                    Text("Swap")
                        .font(FGFont.label.weight(.bold))
                }
                .foregroundStyle(FGColor.ink)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(FGAura.apricot.mid.opacity(0.35))
                .clipShape(Capsule())
                .padding(.trailing, 16)
                .opacity(min(1, max(0, -dragOffset / 40)))
            }

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
                    MenuSwapButton(item: item, isReset: isReset, action: onSelectManual)
                        .padding(.top, 14)
                        .padding(.trailing, 20)
                }
            }
            .offset(x: dragOffset)
            // Not a DragGesture: any SwiftUI drag on a card stops it scrolling
            // (HorizontalSwipe.swift), so vertical and diagonal drags must fail early.
            .fgSwipeToSkip(isEnabled: canSwap, offset: $dragOffset, reduceMotion: reduceMotion, onSkip: onSkip)
        }
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .accessibilityElement(children: .contain)
        .accessibilityLabel(
            "\(item.course.label). \(item.session.title). \(isDone ? "Done today. " : isInProgress ? "In progress. Resume. " : "")"
            + "\(item.session.durationLabel). \(item.reasonText)"
        )
        .accessibilityAddTraits(.isButton)
        .accessibilityAction(named: isReset ? "Start over \(item.course.label)" : "Swap \(item.course.label)") {
            if canSwap { onSelectManual() }
        }
        .accessibilityAction(named: "Quick skip \(item.course.label)") {
            if canSwap { _ = onSkip() }
        }
        .task { await playSwipeHintIfNeeded() }
    }

    /// See `MenuItemCard.playSwipeHintIfNeeded` — same one-time gesture demo,
    /// shared `SwipeHint` flag so only one of the two card shapes ever plays it.
    private func playSwipeHintIfNeeded() async {
        guard isFirstCard, canSwap, !SwipeHint.hasPlayed else { return }
        SwipeHint.hasPlayed = true
        guard !reduceMotion else { return }
        try? await Task.sleep(for: .seconds(1))
        withAnimation(.easeInOut(duration: 0.45)) { dragOffset = -64 }
        try? await Task.sleep(for: .seconds(1))
        withAnimation(FGMotion.gentle) { dragOffset = 0 }
    }
}

/// One menu row: a bloom of the course's colour, the course and its length,
/// the session, and why it is there.
private struct MenuItemBody: View {
    let item: MenuItem
    var caption: String? = nil
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
                // Course and duration read as one compact piece of metadata.
                HStack(alignment: .center, spacing: 6) {
                    Text("\(item.course.label) · \(item.session.durationLabel)")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .foregroundStyle(item.course.chipText)
                        .padding(.horizontal, 11)
                        .padding(.vertical, 5)
                        .background(item.course.chipFill)
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

                if let caption, !isDone {
                    Text(caption)
                        .font(.system(size: 15, weight: .regular))
                        .foregroundStyle(item.course.accentText.opacity(0.85))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 76, alignment: .topLeading)

            // The course's mascot — the same fruit this course wears on My
            // Menu and the paywall, so a Side here and a Side there read as
            // the same thing. Bottom-anchored, clear of the shuffle button
            // floating over the top-trailing corner.
            // On a plate, so the fruit never depends on the glaze behind it.
            Image(item.course.menuMascotAsset)
                .resizable()
                .scaledToFit()
                .frame(width: 40, height: 40)
                .padding(4)
                .background(Circle().fill(item.course.plate))
                .accessibilityHidden(true)
                .padding(.bottom, 2)
        }
        // 14pt, not 18: the cards were ~140pt of mostly empty glaze, which pushed
        // the fourth course under the tab bar. ~116pt keeps the whole menu in view.
        .padding(.vertical, 14)
        .padding(.horizontal, 20)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(item.course.accentGradient)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(isDone ? FGColor.line : item.course.edge, lineWidth: 1.5)
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
