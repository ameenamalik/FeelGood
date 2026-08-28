//
//  TodayView.swift
//  FeelGood
//
//  The menu. One screen, three to five items, no browsing and no scroll on a
//  normal type size — the app's job is to remove options, not present them.
//

import SwiftUI

struct TodayView: View {
    @State var model: TodayModel
    /// Set by a widget tap. Consumed here and cleared, so the same link does
    /// not reopen the sheet every time this view is rebuilt.
    var requestedSessionID: Binding<String?> = .constant(nil)
    @State private var isCheckingIn = false
    @State private var isLogging = false
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
                    menuItems
                    checkInFooter
                }
                .padding(FGSpace.page)
            }
            // Content fits at ordinary type sizes; it only scrolls when the
            // text is large enough to need it.
            .scrollBounceBehavior(.basedOnSize)
        }
        .sheet(isPresented: $isCheckingIn) {
            CheckInSheet(current: model.checkIn) { checkIn in
                model.apply(checkIn)
                isCheckingIn = false
            }
        }
        .sheet(isPresented: $isLogging) {
            LogWorkoutSheet { workout in
                model.log(workout)
            }
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
                .font(FGFont.caption)
                .foregroundStyle(FGColor.inkMuted)
                #if DEBUG
                // Long-press the date to fabricate history. Debug builds only.
                .onLongPressGesture(minimumDuration: 0.7) { isDebugging = true }
                #endif

            Text(model.upgradedHeadline ?? model.menu.headline)
                .font(FGFont.display)
                .foregroundStyle(FGColor.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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
                            canSwap: model.canSwap(item) && !model.isCompleted(item),
                            isReset: model.isCycleReset(item),
                            onOpen: { selected = item },
                            onSwap: {
                                withAnimation(FGMotion.swap) { model.swap(item) }
                                if let updated = model.menu.items.first(where: { $0.course == item.course }) {
                                    AccessibilityNotification.Announcement("Swapped \(item.course.label) to \(updated.session.title)").post()
                                }
                            }
                        )
                    } else {
                        MenuItemRow(
                            item: item,
                            isDone: model.isCompleted(item),
                            canSwap: model.canSwap(item) && !model.isCompleted(item),
                            isReset: model.isCycleReset(item),
                            onOpen: { selected = item },
                            onSwap: {
                                withAnimation(FGMotion.swap) { model.swap(item) }
                                if let updated = model.menu.items.first(where: { $0.course == item.course }) {
                                    AccessibilityNotification.Announcement("Swapped \(item.course.label) to \(updated.session.title)").post()
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

    private var checkInFooter: some View {
        VStack(spacing: FGSpace.s) {
            if model.checkIn == nil {
                FGPrimaryButton(title: "How are you today?") { isCheckingIn = true }
                Text("Ten seconds, and today's menu fits it better.")
                    .font(FGFont.caption)
                    .foregroundStyle(FGColor.inkMuted)
            } else {
                FGQuietButton("Something's changed", systemImage: "arrow.triangle.2.circlepath") {
                    isCheckingIn = true
                }
            }

            // Movement that happened without us. Logging it is how the engine
            // learns what a normal week actually looks like.
            FGQuietButton("I did something else", systemImage: "plus") {
                isLogging = true
            }
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
            .font(FGFont.label)
            .foregroundStyle(course.accentText)
            .padding(.horizontal, FGSpace.s)
            .padding(.vertical, FGSpace.xs)
            .background(
                Capsule().fill(course.accent)
            )
    }
}

private struct MenuItemCard: View {
    let item: MenuItem
    let isDone: Bool
    let canSwap: Bool
    let isReset: Bool
    let onOpen: () -> Void
    let onSwap: () -> Void

    var body: some View {
        // A finished main stops being the highlighted thing to do.
        FGCard(isHighlighted: item.course == .main && !isDone) {
            VStack(alignment: .leading, spacing: FGSpace.s) {
                HStack(spacing: FGSpace.s) {
                    CourseTag(course: item.course)
                    if isDone { DoneMark() }
                }

                Text(item.session.title)
                    .font(FGFont.itemTitle)
                    .foregroundStyle(isDone ? FGColor.inkMuted : FGColor.ink)
                    // Struck through in lime, not grey: this is "ticked off",
                    // not "cancelled" or "unavailable".
                    .strikethrough(isDone, color: FGColor.limeDeep)
                    .fixedSize(horizontal: false, vertical: true)

                // Principle 4: say why. Every single time.
                Text(item.reasonText)
                    .font(FGFont.reason)
                    .foregroundStyle(FGColor.inkMuted)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: FGSpace.s) {
                    if canSwap {
                        if isReset {
                            FGQuietButton("Start over", systemImage: "arrow.counterclockwise", action: onSwap)
                                .accessibilityHint("Cycles back to the first \(item.course.label.lowercased()) options")
                        } else {
                            FGQuietButton("Shuffle", systemImage: "shuffle", action: onSwap)
                                .accessibilityHint("Swaps in a different \(item.course.label.lowercased()); doesn't skip it")
                        }
                    }
                    Spacer(minLength: FGSpace.s)
                    ForEach(item.session.chips, id: \.self) { FGChip(text: $0) }
                }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture(perform: onOpen)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(
            "\(item.course.label). \(item.session.title). \(isDone ? "Done today. " : "")"
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
        .foregroundStyle(FGColor.limeDeep)
        .accessibilityHidden(true)
    }
}

/// Everything that isn't the Main. Same information, one glance.
private struct MenuItemRow: View {
    let item: MenuItem
    let isDone: Bool
    let canSwap: Bool
    let isReset: Bool
    let onOpen: () -> Void
    let onSwap: () -> Void

    var body: some View {
        // Same shape as MenuItemCard: header, title, reason, then a footer
        // row for Shuffle. Every item offers the control in the same spot,
        // not just the Main.
        FGCard {
            VStack(alignment: .leading, spacing: FGSpace.xs) {
                HStack(spacing: FGSpace.s) {
                    CourseTag(course: item.course)
                    Text(item.session.durationLabel)
                        .font(FGFont.label)
                        .foregroundStyle(FGColor.inkMuted)
                    if isDone { DoneMark() }
                }
                Text(item.session.title)
                    .font(FGFont.body.weight(.medium))
                    .foregroundStyle(isDone ? FGColor.inkMuted : FGColor.ink)
                    .strikethrough(isDone, color: FGColor.limeDeep)
                    .fixedSize(horizontal: false, vertical: true)
                Text(item.reasonText)
                    .font(FGFont.caption)
                    .foregroundStyle(FGColor.inkMuted)
                    .fixedSize(horizontal: false, vertical: true)

                if canSwap {
                    if isReset {
                        FGQuietButton("Start over", systemImage: "arrow.counterclockwise", action: onSwap)
                            .accessibilityHint("Cycles back to the first \(item.course.label.lowercased()) options")
                    } else {
                        FGQuietButton("Shuffle", systemImage: "shuffle", action: onSwap)
                            .accessibilityHint("Swaps in a different \(item.course.label.lowercased()); doesn't skip it")
                    }
                }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture(perform: onOpen)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(
            "\(item.course.label). \(item.session.title). \(isDone ? "Done today. " : "")"
            + "\(item.session.durationLabel). \(item.reasonText)"
        )
        .accessibilityAddTraits(.isButton)
        .accessibilityAction(named: isReset ? "Start over \(item.course.label)" : "Shuffle \(item.course.label)") {
            if canSwap { onSwap() }
        }
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
