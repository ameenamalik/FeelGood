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
    @State private var isLogging = false
    @State private var isShowingPaywall = false
    @State private var shouldOfferProAfterDismissal = false
    @AppStorage("hasShownFirstCompletionPaywall") private var hasShownFirstCompletionPaywall = false
    @AppStorage("hasShownFirstCompletionAuthPrompt") private var hasShownFirstCompletionAuthPrompt = false
    @State private var isShowingAuthPrompt = false
    @Environment(AuthService.self) private var authService
    @Environment(\.colorScheme) private var colorScheme
    @State private var isAdjusting = false
    @State private var isShowingMyMenu = false
    @State private var showMenuAnyway = false
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
                    checkInPrompt
                    menuHeading
                    calendarFitCard
                    if model.shouldShowCompletionState && !showMenuAnyway {
                        completedSummaryCard
                    } else {
                        menuItems
                        logFooter
                    }
                }
                .padding(FGSpace.page)
            }
            // Content fits at ordinary type sizes; it only scrolls when the
            // text is large enough to need it.
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
        .sheet(isPresented: $isLogging, onDismiss: presentPendingLittleWinCelebration) {
            LogWorkoutSheet { workout in
                model.log(workout)
            }
        }
        .sheet(isPresented: $isShowingPaywall) {
            FeelGoodPaywallView()
        }
        .sheet(isPresented: $isShowingMyMenu, onDismiss: syncOneSignalDiscoveryTriggers) {
            MyMenuView(model: model)
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
                subtitle: "You finished today's session! Create an account to save your progress and keep your daily menus personalized."
            )
        }
        .onChange(of: requestedSessionID.wrappedValue, initial: true) { _, id in
            openRequestedSession(id)
        }
        .onAppear {
            syncOneSignalDiscoveryTriggers()
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
        VStack(alignment: .leading, spacing: FGSpace.s) {
            Text(model.upgradedHeadline ?? model.menu.headline)
                .font(FGFont.display)
                .tracking(-0.8)
                .foregroundStyle(FGColor.ink)
                .fixedSize(horizontal: false, vertical: true)
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
        .accessibilityElement(children: .combine)
    }

    private var menuItems: some View {
        VStack(spacing: FGSpace.s) {
            ForEach(Array(model.menu.items.enumerated()), id: \.element.id) { index, item in
                let isVisible = index < visibleMenuCardCount

                Group {
                    if item.course == .main {
                        MenuItemCard(
                            item: item,
                            isDone: model.isCompleted(item),
                            isInProgress: model.isInProgress(item),
                            canSwap: (model.canSwap(item) || !model.hasRemainingSwaps) && !model.isCompleted(item) && !model.isInProgress(item),
                            isReset: model.isCycleReset(item),
                            onOpen: { selected = item },
                            onSwap: {
                                if model.hasRemainingSwaps {
                                    withAnimation(FGMotion.swap) { model.swap(item) }
                                    if let updated = model.menu.items.first(where: { $0.course == item.course }) {
                                        AccessibilityNotification.Announcement("Swapped \(item.course.label) to \(updated.session.title)").post()
                                    }
                                } else {
                                    isShowingPaywall = true
                                }
                            }
                        )
                    } else {
                        MenuItemRow(
                            item: item,
                            isDone: model.isCompleted(item),
                            isInProgress: model.isInProgress(item),
                            canSwap: (model.canSwap(item) || !model.hasRemainingSwaps) && !model.isCompleted(item) && !model.isInProgress(item),
                            isReset: model.isCycleReset(item),
                            onOpen: { selected = item },
                            onSwap: {
                                if model.hasRemainingSwaps {
                                    withAnimation(FGMotion.swap) { model.swap(item) }
                                    if let updated = model.menu.items.first(where: { $0.course == item.course }) {
                                        AccessibilityNotification.Announcement("Swapped \(item.course.label) to \(updated.session.title)").post()
                                    }
                                } else {
                                    isShowingPaywall = true
                                }
                            }
                        )
                    }
                }
                .opacity(isVisible ? 1 : 0)
                .scaleEffect(isVisible ? 1 : 0.96, anchor: .top)
                .offset(y: isVisible ? 0 : 10)
                .transition(.opacity.combined(with: .move(edge: .bottom)))
                .fgAnimation(FGMotion.settle.delay(FGMotion.stagger(index)), value: item.id)
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
        guard let item = model.menu.items.first(where: { $0.session.id == id }) else { return }
        selected = item
    }

    /// The check-in, as a heading and a card that reads back what you said.
    ///
    /// It used to be a lone button, which meant the answers vanished the moment
    /// they were given — the menu was built from something you could no longer
    /// see. Now the card holds the line and the action beside it changes from
    /// answering to amending.
    private struct CheckInAuraPulse: View {
        let checkIn: PlanCheckIn?
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
                            startRadius: 4,
                            endRadius: 22
                        )
                    )
                    .frame(width: 42, height: 42)
                    .scaleEffect(isPulsing ? 1.28 : 0.88)
                    .opacity(isPulsing ? 0.70 : 0.30)
                    .animation(
                        reduceMotion ? .none : Animation.easeInOut(duration: 2.2).repeatForever(autoreverses: true),
                        value: isPulsing
                    )

                // Core AuraDot
                AuraDot(color: auraColor, size: 28)
                    .scaleEffect(isPulsing && checkIn == nil ? 1.08 : 0.95)
                    .animation(
                        reduceMotion ? .none : Animation.easeInOut(duration: 2.2).repeatForever(autoreverses: true),
                        value: isPulsing
                    )
            }
            .frame(width: 34, height: 34)
            .onAppear {
                isPulsing = true
            }
        }
    }

    private var checkInPrompt: some View {
        Button { isCheckingIn = true } label: {
            HStack(spacing: FGSpace.s + 3) {
                CheckInAuraPulse(checkIn: model.checkIn)

                VStack(alignment: .leading, spacing: 2) {
                    if let checkIn = model.checkIn {
                        Text(checkIn.detailedSummaryPhrase)
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundStyle(FGColor.ink)
                            .multilineTextAlignment(.leading)
                            .lineLimit(2)
                    } else {
                        Text("Check in for today")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundStyle(FGColor.ink)
                            .multilineTextAlignment(.leading)
                            .lineLimit(1)

                        Text("Takes about 30 seconds")
                            .font(.system(size: 13, weight: .regular))
                            .foregroundStyle(FGColor.inkMuted)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                if model.checkIn == nil {
                    Image(systemName: "arrow.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(FGColor.inkMuted)
                } else {
                    HStack(spacing: 4) {
                        Image(systemName: "pencil")
                            .font(.system(size: 11, weight: .medium))
                        Text("Edit")
                            .font(FGFont.label.weight(.semibold))
                    }
                    .foregroundStyle(FGColor.inkMuted)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.white.opacity(colorScheme == .dark ? 0.12 : 0.60))
                    .clipShape(Capsule())
                    .fixedSize()
                    .padding(.trailing, FGSpace.xs)
                }
            }
            .frame(minHeight: 60)
            .padding(.vertical, FGSpace.xs)
            .padding(.horizontal, FGSpace.m)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color.white.opacity(colorScheme == .dark ? 0.10 : 0.72))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .strokeBorder(Color.white.opacity(colorScheme == .dark ? 0.12 : 0.5), lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.2 : 0.04), radius: 8, x: 0, y: 3)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityLabel(
            model.checkIn.map { "Today's check-in: \($0.detailedSummaryPhrase). Edit" }
                ?? "Check in for today. Takes about 30 seconds"
        )
    }

    /// "Your menu", remaining minutes, and collapsible quick adjust drawer.
    private var menuHeading: some View {
        VStack(alignment: .leading, spacing: FGSpace.s) {
            HStack(alignment: .center, spacing: FGSpace.s) {
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    Text("Your menu")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(FGColor.ink)
                        .accessibilityAddTraits(.isHeader)

                    if model.remainingDurationMin > 0 {
                        Text("\(model.remainingDurationMin) min left")
                            .font(.system(size: 16, weight: .regular))
                            .foregroundStyle(FGColor.inkMuted)
                            .contentTransition(
                                .numericText(value: Double(model.remainingDurationMin))
                            )
                            .animation(
                                reduceMotion ? .none : .easeInOut(duration: 0.35),
                                value: model.remainingDurationMin
                            )
                    } else if model.hasCompletedActivityToday {
                        Text("Completed")
                            .font(.system(size: 16, weight: .regular))
                            .foregroundStyle(FGColor.sageDeep)
                    }
                }
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)

                Spacer(minLength: FGSpace.s)

                // Compact icon-only controls for routine and quick adjust.
                // Quick adjust is a Pro feature; free users get only the +,
                // never a lock icon that gates a control they can't see the
                // point of yet.
                #if compiler(>=6.2)
                if #available(iOS 26, *) {
                    GlassEffectContainer(spacing: FGSpace.s) {
                        HStack(spacing: FGSpace.s) {
                            routineButtonLabel
                                .glassEffect(.regular.interactive(), in: Capsule())
                            if model.isProUser {
                                adjustButtonLabel
                                    .glassEffect(
                                        isAdjusting ? .regular.tint(FGColor.surface).interactive() : .regular.interactive(),
                                        in: Circle()
                                    )
                            }
                        }
                    }
                } else {
                    legacyMenuControls
                }
                #else
                legacyMenuControls
                #endif
            }

            // On its own line rather than crowding the title row — that row
            // already has to fit "Your menu" plus the Add/adjust controls,
            // and this is the one piece that's safe to wrap onto a second
            // line without anything else needing to shrink or truncate.
            if model.remainingDurationMin > 0 {
                Text("Room for \(model.remainingDurationMin) min")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundStyle(FGColor.inkMuted)
            } else if model.hasCompletedActivityToday {
                Text("Completed")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundStyle(FGColor.sageDeep)
            }

            if isAdjusting {
                ScrollView(.horizontal, showsIndicators: false) {
                    quickFilterRow
                        .padding(.vertical, 2)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
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
                Text("Add")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .lineLimit(1)
            }
            .fixedSize()
            .foregroundStyle(FGColor.ink)
            .padding(.horizontal, 10)
            .frame(height: 32)
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Add custom routine or view My Menu")
    }

    private var legacyMenuControls: some View {
        HStack(spacing: FGSpace.s) {
            routineButtonLabel
                .background(FGColor.surface)
                .clipShape(Capsule())
                .overlay(Capsule().strokeBorder(FGColor.lineStrong, lineWidth: 1))
            if model.isProUser {
                adjustButtonLabel
                    .background(isAdjusting ? FGColor.surface : FGColor.surface.opacity(0.6))
                    .clipShape(Circle())
                    .overlay(
                        Circle().strokeBorder(isAdjusting ? FGColor.lineStrong : FGColor.line, lineWidth: 1)
                    )
            }
        }
    }

    /// Only rendered for Pro users — see `menuHeading`.
    private var adjustButtonLabel: some View {
        Button {
            withAnimation(FGMotion.gentle) {
                isAdjusting.toggle()
            }
        } label: {
            Image(systemName: isAdjusting ? "xmark" : "slider.horizontal.3")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(FGColor.ink)
                .frame(width: 32, height: 32)
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Adjust today's menu")
    }

    private var quickFilterRow: some View {
        HStack(spacing: 8) {
            ForEach(QuickFilter.allCases, id: \.self) { filter in
                quickFilterButtonLabel(filter)
                    .background(FGColor.surface)
                    .clipShape(Capsule())
                    .overlay(Capsule().strokeBorder(FGColor.lineStrong, lineWidth: 1))
            }
        }
    }

    private func quickFilterButtonLabel(_ filter: QuickFilter) -> some View {
        Button {
            guard !isRegeneratingMenu else { return }
            Task { @MainActor in
                await regenerateMenu {
                    model.applyQuickFilter(filter)
                }
            }
        } label: {
            HStack(spacing: 5) {
                Image(systemName: filter.symbol)
                    .font(.system(size: 11, weight: .medium))
                Text(filter.label)
                    .font(FGFont.label.weight(.medium))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .foregroundStyle(FGColor.ink)
            .fixedSize()
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .disabled(isRegeneratingMenu)
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
        syncOneSignalDiscoveryTriggers()
        guard shouldOfferProAfterDismissal else { return }
        shouldOfferProAfterDismissal = false

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

    private var completedSummaryCard: some View {
        VStack(spacing: FGSpace.m) {
            VStack(alignment: .leading, spacing: FGSpace.s) {
                HStack(alignment: .top, spacing: FGSpace.m) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 32, weight: .semibold))
                        .foregroundStyle(FGColor.sageDeep)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Done for today")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundStyle(FGColor.ink)

                        if let latest = model.completedEntriesToday.first {
                            let title = model.title(for: latest)
                            Text("\(title) • \(latest.durationMin) min")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(FGColor.inkMuted)
                        } else {
                            Text("All routines completed")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(FGColor.inkMuted)
                        }

                        Text("Great job taking time for yourself today.")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundStyle(FGColor.inkMuted.opacity(0.85))
                            .padding(.top, 2)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(FGSpace.l)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color.white.opacity(colorScheme == .dark ? 0.10 : 0.85))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .strokeBorder(Color.white.opacity(colorScheme == .dark ? 0.15 : 0.6), lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.2 : 0.04), radius: 10, x: 0, y: 3)
            )

            HStack(spacing: FGSpace.m) {
                Button {
                    isLogging = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "plus")
                            .font(.system(size: 12, weight: .semibold))
                        Text("Log another activity")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                    }
                    .foregroundStyle(FGColor.inkMuted)
                }
                .buttonStyle(.plain)

                Text("•")
                    .foregroundStyle(FGColor.lineStrong.opacity(0.5))

                Button {
                    withAnimation(FGMotion.settle) {
                        showMenuAnyway = true
                    }
                } label: {
                    Text("View today's menu")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(FGColor.inkMuted)
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 2)
        }
        .frame(maxWidth: .infinity)
    }

    private var logFooter: some View {
        VStack(spacing: FGSpace.s) {
            if showMenuAnyway && model.shouldShowCompletionState {
                Button {
                    withAnimation(FGMotion.settle) {
                        showMenuAnyway = false
                    }
                } label: {
                    Text("Hide menu")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(FGColor.inkMuted)
                }
                .buttonStyle(.plain)
                .padding(.top, 4)
            }
        }
    }
}

/// The course, named and tinted as a frosted pill consistent with Chat.
struct CourseTag: View {
    let course: Course
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Text(course.label)
            .font(.system(size: 13, weight: .semibold, design: .rounded))
            .foregroundStyle(course.tagText)
            .padding(.horizontal, 12)
            .padding(.vertical, 5)
            .background(Color.white.opacity(colorScheme == .dark ? 0.16 : 0.70))
            .clipShape(Capsule())
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
        .accessibilityElement(children: .contain)
        .accessibilityLabel(
            "\(item.course.label). \(item.session.title). \(isDone ? "Done today. " : isInProgress ? "In progress. Resume. " : "")"
            + "\(item.session.chips.joined(separator: ", ")). \(item.reasonText)"
        )
        .accessibilityAddTraits(.isButton)
        .accessibilityAction(named: isReset ? "Start over \(item.course.label)" : "Shuffle \(item.course.label)") {
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
        .accessibilityElement(children: .contain)
        .accessibilityLabel(
            "\(item.course.label). \(item.session.title). \(isDone ? "Done today. " : isInProgress ? "In progress. Resume. " : "")"
            + "\(item.session.durationLabel). \(item.reasonText)"
        )
        .accessibilityAddTraits(.isButton)
        .accessibilityAction(named: isReset ? "Start over \(item.course.label)" : "Shuffle \(item.course.label)") {
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
        VStack(alignment: .leading, spacing: 10) {
            // Top metadata row: White pill badges matching design reference
            HStack(alignment: .center, spacing: 6) {
                Text(item.course.label.uppercased())
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(item.course.accentText)
                    .padding(.horizontal, 11)
                    .padding(.vertical, 5)
                    .background(Color.white.opacity(colorScheme == .dark ? 0.20 : 0.88))
                    .clipShape(Capsule())

                Text(item.session.durationLabel.uppercased())
                    .font(.system(size: 12, weight: .bold, design: .rounded))
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

                Spacer(minLength: 30)
            }

            // Session Title in SF Pro Rounded Bold
            Text(item.session.title)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(isDone ? FGColor.inkMuted : item.course.accentText)
                .fixedSize(horizontal: false, vertical: true)

            // Subtitle
            let subtitleText = !item.session.subtitle.isEmpty ? item.session.subtitle : item.reasonText
            if !subtitleText.isEmpty {
                Text(subtitleText)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(isDone ? FGColor.inkMuted.opacity(0.8) : item.course.accentText.opacity(0.78))
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
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
            Image(systemName: isReset ? "arrow.counterclockwise" : "shuffle")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(item.course.accentText)
                .frame(width: 30, height: 30)
                .background(Color.white.opacity(colorScheme == .dark ? 0.20 : 0.88))
                .clipShape(Circle())
        }
        .buttonStyle(.feelGoodPress)
        .accessibilityLabel(isReset ? "Start over" : "Shuffle")
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
