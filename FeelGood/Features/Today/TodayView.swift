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
    @State private var isAdjusting = false
    @State private var selected: MenuItem?
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
        .sheet(isPresented: $isCheckingIn) {
            CheckInSheet(
                current: model.checkIn,
                currentCalendarOpening: model.calendarOpening,
                isProUser: model.isProUser,
                preferredTime: model.profile.bestTimeOfDay,
                realisticMinutes: model.profile.realisticMinutes
            ) { checkIn, calendarOpening in
                model.apply(checkIn, calendarOpening: calendarOpening)
                isCheckingIn = false
            }
        }
        .sheet(isPresented: $isLogging) {
            LogWorkoutSheet { workout in
                model.log(workout)
            }
        }
        .sheet(isPresented: $isShowingPaywall) {
            RevenueCatUI.PaywallView(displayCloseButton: true)
        }
        .sheet(item: $selected) { item in
            SessionDetailView(item: item, model: model)
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
            HStack(spacing: FGSpace.m - 2) {
                AuraDot(color: FGColor.rose, size: 40)

                Text(model.checkIn?.summaryLine ?? "Tell me and today's menu fits it better")
                    .font(FGFont.itemTitle)
                    .foregroundStyle(FGColor.ink)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text(model.checkIn == nil ? "Answer" : "Change")
                    .font(FGFont.body.weight(.medium))
                    .foregroundStyle(FGColor.goldDeep)
                    .fixedSize()
            }
            .padding(.vertical, 14)
            .padding(.horizontal, FGSpace.m)
            .background(
                RoundedRectangle(cornerRadius: FGRadius.card - 4, style: .continuous)
                    .fill(FGColor.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: FGRadius.card - 4, style: .continuous)
                    .strokeBorder(FGColor.lineStrong, lineWidth: 1)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// "Your menu", sum of duration, and collapsible quick adjust drawer.
    private var menuHeading: some View {
        VStack(alignment: .leading, spacing: FGSpace.s) {
            HStack(alignment: .center, spacing: FGSpace.s) {
                Text("Your menu")
                    .font(FGFont.sectionTitle)
                    .foregroundStyle(FGColor.ink)
                    .accessibilityAddTraits(.isHeader)

                Text("• \(model.menu.items.reduce(0) { $0 + $1.session.durationMin }) min")
                    .font(FGFont.label)
                    .foregroundStyle(FGColor.inkMuted)

                Spacer(minLength: FGSpace.s)

                Button {
                    withAnimation(FGMotion.settle) {
                        isAdjusting.toggle()
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "slider.horizontal.3")
                            .font(.system(size: 11, weight: .medium))
                        Text("Adjust")
                            .font(FGFont.label.weight(.medium))
                        Image(systemName: isAdjusting ? "chevron.up" : "chevron.down")
                            .font(.system(size: 9, weight: .semibold))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .foregroundStyle(isAdjusting ? FGColor.ink : FGColor.inkMuted)
                    .background(isAdjusting ? FGColor.surface : FGColor.surface.opacity(0.6))
                    .clipShape(Capsule())
                    .overlay(
                        Capsule().strokeBorder(isAdjusting ? FGColor.lineStrong : FGColor.line, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Adjust today's menu")
            }

            if isAdjusting {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(QuickFilter.allCases, id: \.self) { filter in
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
                                .background(FGColor.surface)
                                .clipShape(Capsule())
                                .overlay(
                                    Capsule().strokeBorder(FGColor.lineStrong, lineWidth: 1)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 2)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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
        .foregroundStyle(FGColor.goldDeep)
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
            }

            // Why it fits today
            Text(item.reasonText)
                .font(FGFont.caption)
                .foregroundStyle(FGColor.inkMuted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 14)
        .padding(.horizontal, FGSpace.m)
        .background(
            RoundedRectangle(cornerRadius: FGRadius.card - 4, style: .continuous)
                .fill(FGColor.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: FGRadius.card - 4, style: .continuous)
                .strokeBorder(FGColor.lineStrong, lineWidth: 1)
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
