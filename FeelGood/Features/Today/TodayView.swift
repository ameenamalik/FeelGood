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
    @State private var isCheckingIn = false
    @State private var selected: MenuItem?
    #if DEBUG
    @State private var isDebugging = false
    #endif

    var body: some View {
        ZStack {
            FGColor.bg.ignoresSafeArea()

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
        .sheet(item: $selected) { item in
            SessionDetailView(item: item, model: model)
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
                .textCase(.uppercase)
                .tracking(1.2)
                #if DEBUG
                // Long-press the date to fabricate history. Debug builds only.
                .onLongPressGesture(minimumDuration: 0.7) { isDebugging = true }
                #endif

            Text(model.menu.headline)
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
                            onOpen: { selected = item },
                            onSwap: { withAnimation(FGMotion.swap) { model.swap(item) } }
                        )
                    } else {
                        MenuItemRow(
                            item: item,
                            isDone: model.isCompleted(item),
                            canSwap: model.canSwap(item) && !model.isCompleted(item),
                            onOpen: { selected = item },
                            onSwap: { withAnimation(FGMotion.swap) { model.swap(item) } }
                        )
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .bottom)))
                .fgAnimation(FGMotion.settle.delay(FGMotion.stagger(index)), value: item.id)
            }
        }
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
            .textCase(.uppercase)
            .tracking(1.1)
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
    let onOpen: () -> Void
    let onSwap: () -> Void

    var body: some View {
        FGCard(isHighlighted: item.course == .main) {
            VStack(alignment: .leading, spacing: FGSpace.s) {
                HStack(spacing: FGSpace.s) {
                    CourseTag(course: item.course)
                    if isDone { DoneMark() }
                }

                Text(item.session.title)
                    .font(FGFont.itemTitle)
                    .foregroundStyle(FGColor.ink)
                    .fixedSize(horizontal: false, vertical: true)

                // Principle 4: say why. Every single time.
                Text(item.reasonText)
                    .font(FGFont.reason)
                    .foregroundStyle(FGColor.inkMuted)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: FGSpace.s) {
                    if canSwap {
                        FGQuietButton("Not today", systemImage: "arrow.2.squarepath", action: onSwap)
                            .accessibilityHint("Shows a different \(item.course.label.lowercased())")
                    }
                    Spacer(minLength: FGSpace.s)
                    ForEach(item.session.chips, id: \.self) { FGChip(text: $0) }
                }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture(perform: onOpen)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(item.course.label). \(item.session.title). \(item.session.chips.joined(separator: ", ")). \(item.reasonText)")
        .accessibilityAddTraits(.isButton)
    }
}

/// Marks something already done today. Not a score, not a count, and nothing
/// accrues from it — it's here so a finished item stops asking to be started.
private struct DoneMark: View {
    var body: some View {
        HStack(spacing: FGSpace.xs) {
            Image(systemName: "checkmark")
            Text("Done")
        }
        .font(FGFont.label)
        .foregroundStyle(FGColor.limeDeep)
        .accessibilityLabel("Done today")
    }
}

/// Everything that isn't the Main. Same information, one glance.
private struct MenuItemRow: View {
    let item: MenuItem
    let isDone: Bool
    let canSwap: Bool
    let onOpen: () -> Void
    let onSwap: () -> Void

    var body: some View {
        FGCard {
            HStack(alignment: .top, spacing: FGSpace.s) {
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
                        .foregroundStyle(FGColor.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(item.reasonText)
                        .font(FGFont.caption)
                        .foregroundStyle(FGColor.inkMuted)
                        .fixedSize(horizontal: false, vertical: true)
                }

                if canSwap {
                    Button(action: onSwap) {
                        Image(systemName: "arrow.2.squarepath")
                            .foregroundStyle(FGColor.inkMuted)
                            .frame(width: FGSize.minTouchTarget, height: FGSize.minTouchTarget)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Not today")
                    .accessibilityHint("Shows a different \(item.course.label.lowercased())")
                }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture(perform: onOpen)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(item.course.label). \(item.session.title). \(item.session.durationLabel). \(item.reasonText)")
        .accessibilityAddTraits(.isButton)
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
