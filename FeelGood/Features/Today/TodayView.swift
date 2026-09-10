//
//  TodayView.swift
//  FeelGood
//
//  The menu. One screen, three to five items, no browsing and no scroll on a
//  normal type size — the app's job is to remove options, not present them.
//

import SwiftUI
import UIKit
import RevenueCatUI
import PostHog

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
    @State private var isAdjusting = false
    @State private var isShowingMyMenu = false
    @State private var selected: MenuItem?
    @State private var littleWinCelebration: LittleWinCelebration?
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

            ScrollView {
                VStack(alignment: .leading, spacing: FGSpace.l) {
                    header
                    checkInPrompt
                    menuHeading
                    calendarFitCard
                    menuItems
                    logFooter
                }
                .padding(FGSpace.page)
            }
            // Content fits at ordinary type sizes; it only scrolls when the
            // text is large enough to need it.
            .scrollBounceBehavior(.basedOnSize)
        }
        .sheet(isPresented: $isCheckingIn, onDismiss: presentPendingLittleWinCelebration) {
            CheckInSheet(
                current: model.checkIn,
                currentCalendarOpening: model.calendarOpening,
                isProUser: model.isProUser,
                preferredTime: model.profile.bestTimeOfDay,
                realisticMinutes: model.profile.realisticMinutes
            ) { checkIn, calendarOpening, completedMovementPlan in
                model.apply(checkIn, calendarOpening: calendarOpening)
                if let completedMovementPlan {
                    model.log(completedMovementPlan)
                }
                isCheckingIn = false
            }
        }
        .sheet(isPresented: $isLogging, onDismiss: presentPendingLittleWinCelebration) {
            LogWorkoutSheet { workout in
                model.log(workout)
            }
        }
        .sheet(isPresented: $isShowingPaywall) {
            RevenueCatUI.PaywallView(displayCloseButton: true)
        }
        .sheet(isPresented: $isShowingMyMenu) {
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
        #if DEBUG
        .sheet(isPresented: $isDebugging) {
            DebugMenu(content: model.store) { model.reload() }
        }
        #endif
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: FGSpace.s) {
            Text(model.greeting())
                .font(FGFont.label)
                .foregroundStyle(FGColor.inkMuted)

            Text(model.upgradedHeadline ?? model.menu.headline)
                .font(FGFont.display)
                .tracking(-0.8)
                .foregroundStyle(FGColor.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        #if DEBUG
        // Long-press anywhere on the header to fabricate history / switch user journeys.
        .onLongPressGesture(minimumDuration: 0.4) {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            isDebugging = true
        }
        #endif
        .accessibilityElement(children: .combine)
    }

    private var menuItems: some View {
        VStack(spacing: FGSpace.s) {
            ForEach(Array(model.menu.items.enumerated()), id: \.element.id) { index, item in
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
                .transition(.opacity.combined(with: .move(edge: .bottom)))
                .fgAnimation(FGMotion.settle.delay(FGMotion.stagger(index)), value: item.id)
            }
        }
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
    private var checkInPrompt: some View {
        Button { isCheckingIn = true } label: {
            HStack(spacing: FGSpace.s + 2) {
                Image(systemName: model.checkIn == nil ? "heart.fill" : "checkmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(FGColor.inkOnAccent)
                    .frame(width: 30, height: 30)
                    .background(FGColor.rose.opacity(0.52), in: Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text(model.checkIn?.summaryLine ?? "Check in for today")
                        .font(FGFont.itemTitle)
                        .foregroundStyle(FGColor.inkOnAccent)
                        .multilineTextAlignment(.leading)
                        .lineLimit(model.checkIn == nil ? 1 : 2)

                    if model.checkIn == nil {
                        Text("Takes about 30 seconds")
                            .font(FGFont.caption)
                            .foregroundStyle(FGColor.inkOnAccent.opacity(0.68))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                if model.checkIn == nil {
                    Image(systemName: "arrow.right")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(FGColor.inkOnAccent.opacity(0.72))
                } else {
                    Text("Edit")
                        .font(FGFont.body.weight(.medium))
                        .foregroundStyle(FGColor.goldDeep)
                        .fixedSize()
                        .padding(.trailing, FGSpace.s)
                }
            }
            .frame(minHeight: 62)
            .padding(.vertical, FGSpace.xs)
            .padding(.horizontal, FGSpace.m)
            .background(
                Capsule(style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [FGAura.blush.core, FGAura.apricot.core],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityLabel(
            model.checkIn.map { "Today's check-in: \($0.summaryLine). Edit" }
                ?? "Check in for today. Takes about 30 seconds"
        )
    }

    /// "Your menu", sum of duration, and collapsible quick adjust drawer.
    private var menuHeading: some View {
        VStack(alignment: .leading, spacing: FGSpace.s) {
            HStack(alignment: .center, spacing: FGSpace.s) {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text("Your menu")
                        .font(FGFont.sectionTitle)
                        .foregroundStyle(FGColor.ink)
                        .accessibilityAddTraits(.isHeader)

                    Text("• \(model.menu.items.reduce(0) { $0 + $1.session.durationMin }) min")
                        .font(FGFont.label)
                        .foregroundStyle(FGColor.inkMuted)
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
                                .glassEffect(.regular.interactive(), in: Circle())
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
            Image(systemName: "plus")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(FGColor.ink)
                .frame(width: 32, height: 32)
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Add custom routine or view My Menu")
    }

    private var legacyMenuControls: some View {
        HStack(spacing: FGSpace.s) {
            routineButtonLabel
                .background(FGColor.surface)
                .clipShape(Circle())
                .overlay(Circle().strokeBorder(FGColor.lineStrong, lineWidth: 1))
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
            withAnimation(FGMotion.settle) {
                model.applyQuickFilter(filter)
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
    }

    private func presentCompletionPaywallIfNeeded() {
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

    private var logFooter: some View {
        // Movement that happened without us. Logging it is how the engine
        // learns what a normal week actually looks like.
        FGQuietButton("I did something else", systemImage: "plus") {
            isLogging = true
        }
        .frame(maxWidth: .infinity)
    }
}

/// The course, named and tinted. Ink on every accent — the accents are far too
/// light to carry white text.
struct CourseTag: View {
    let course: Course

    var body: some View {
        Text(course.label)
            .font(FGFont.label.weight(.semibold))
            .foregroundStyle(course.tagText)
            .padding(.horizontal, 11)
            .padding(.vertical, 5)
            .background(Capsule().fill(course.tagFill))
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
        // All courses share uniform clean styling
        MenuItemBody(
            item: item,
            isDone: isDone,
            isInProgress: isInProgress,
            canSwap: canSwap,
            isReset: isReset,
            isHighlighted: false,
            onSwap: onSwap
        )
        .contentShape(Rectangle())
        .onTapGesture(perform: onOpen)
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
    var body: some View {
        HStack(spacing: FGSpace.xs) {
            Image(systemName: "checkmark.circle.fill")
            Text("Done")
        }
        .font(FGFont.label)
        .foregroundStyle(FGColor.clayDeep)
        .accessibilityHidden(true)
    }
}

private struct ResumeMark: View {
    var body: some View {
        HStack(spacing: FGSpace.xs) {
            Image(systemName: "play.circle.fill")
            Text("Resume")
        }
        .font(FGFont.label)
        // Only ever shown on a not-done item, so this always sits on the
        // course's accent gradient rather than the flat surface — `ink` is
        // the one colour that gradient guarantees stays legible at its
        // darkest point (see `Course.accentGradient`).
        .foregroundStyle(FGColor.ink)
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
        // Identical to the Main's card but for the highlight — every course is
        // the same row, so nothing but the border says which one matters most.
        MenuItemBody(
            item: item,
            isDone: isDone,
            isInProgress: isInProgress,
            canSwap: canSwap,
            isReset: isReset,
            isHighlighted: false,
            onSwap: onSwap
        )
        .contentShape(Rectangle())
        .onTapGesture(perform: onOpen)
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
///
/// The Main and the rest used to be two different layouts, which made the
/// highlight read as a different *kind* of thing rather than as the same thing
/// emphasised. One body now, and `isHighlighted` only changes the border.
private struct MenuItemBody: View {
    let item: MenuItem
    let isDone: Bool
    let isInProgress: Bool
    let canSwap: Bool
    let isReset: Bool
    let isHighlighted: Bool
    let onSwap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Top metadata row: Course tag, status, and shuffle
            HStack(alignment: .center, spacing: FGSpace.s) {
                CourseTag(course: item.course)

                if isDone {
                    DoneMark()
                } else if isInProgress {
                    ResumeMark()
                }

                Spacer(minLength: FGSpace.xs)

                if canSwap {
                    Button(action: onSwap) {
                        Image(systemName: isReset ? "arrow.counterclockwise" : "shuffle")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(FGColor.inkMuted)
                            .frame(width: 28, height: 28)
                            .background(FGColor.bg.opacity(0.7))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(isReset ? "Start over" : "Shuffle")
                    .accessibilityHint(
                        isReset
                            ? "Cycles back to the first \(item.course.label.lowercased()) options"
                            : "Swaps in a different \(item.course.label.lowercased()); doesn't skip it"
                    )
                }
            }

            // Session Title
            Text(item.session.title)
                .font(FGFont.itemTitle)
                .foregroundStyle(isDone ? FGColor.inkMuted : FGColor.ink)
                .strikethrough(isDone, color: FGColor.clayDeep)
                .fixedSize(horizontal: false, vertical: true)

            // Visual target & context pills
            WrapRow(spacing: FGSpace.xs, lineSpacing: FGSpace.xs) {
                ForEach(item.session.chips, id: \.self) { chip in
                    FGChip(text: chip)
                }
                if item.session.isOwn {
                    FGChip(text: "Yours")
                }
            }

        }
        .padding(.vertical, 14)
        .padding(.horizontal, FGSpace.m)
        .background(
            RoundedRectangle(cornerRadius: FGRadius.card - 4, style: .continuous)
                // The gradient is the "this still needs doing" signal, so it
                // only shows while that's true — a done item settles back to
                // the flat surface, which is also what keeps `inkMuted` and
                // the -Deep tag colours (calibrated against white, not this
                // gradient's darkest stop) safe to use on it.
                .fill(isDone ? AnyShapeStyle(FGColor.surface) : AnyShapeStyle(item.course.accentGradient))
        )
        .overlay(
            RoundedRectangle(cornerRadius: FGRadius.card - 4, style: .continuous)
                .strokeBorder(isDone ? FGColor.line : Color.clear, lineWidth: 1)
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
