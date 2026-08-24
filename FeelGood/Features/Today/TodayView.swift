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
    /// What was ticked, so the profile screen can show it back.
    let answers: ProfileAnswers
    let onProfileSaved: (ProfileAnswers) -> Void

    @State private var isCheckingIn = false
    @State private var isEditingProfile = false
    @State private var isLogging = false
    @State private var isLookingBack = false
    @State private var isBrowsing = false
    @State private var selected: MenuItem?

    init(
        model: TodayModel,
        answers: ProfileAnswers = ProfileAnswers(),
        onProfileSaved: @escaping (ProfileAnswers) -> Void = { _ in }
    ) {
        _model = State(initialValue: model)
        self.answers = answers
        self.onProfileSaved = onProfileSaved
    }

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
        .sheet(isPresented: $isEditingProfile) {
            ProfileEditView(answers: answers) { updated in
                onProfileSaved(updated)
                model.update(profile: updated.planProfile)
            }
        }
        .sheet(isPresented: $isLogging) {
            LogWorkoutSheet { workout in
                model.log(workout)
            }
        }
        .sheet(isPresented: $isLookingBack) {
            LookBackView(lookBack: model.lookBack())
        }
        .sheet(isPresented: $isBrowsing) {
            LibraryView(model: model)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: FGSpace.s) {
            HStack(alignment: .firstTextBaseline) {
                Text(model.greeting())
                    .font(FGFont.caption)
                    .foregroundStyle(FGColor.inkMuted)
                    .textCase(.uppercase)
                    .tracking(1.2)

                Spacer(minLength: FGSpace.s)

                // One control rather than a row of icons: the menu is the
                // screen, and everything else is somewhere you go on purpose.
                // (`SwiftUI.Menu` spelled out: `Menu` is this app's own word
                // for the day's plan, and that type wins in this file.)
                SwiftUI.Menu {
                    Button("The last couple of weeks", systemImage: "leaf") { isLookingBack = true }
                    Button("Everything", systemImage: "square.stack") { isBrowsing = true }
                    Button("What's true now", systemImage: "slider.horizontal.3") { isEditingProfile = true }
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundStyle(FGColor.inkMuted)
                        .frame(width: FGSize.minTouchTarget, height: FGSize.minTouchTarget, alignment: .trailing)
                }
                .accessibilityLabel("More")
                .accessibilityHint("Look back, browse everything, or change what you have access to")
            }

            Text(model.menu.headline)
                .font(FGFont.display)
                .foregroundStyle(FGColor.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var menuItems: some View {
        VStack(spacing: FGSpace.s) {
            ForEach(Array(model.menu.items.enumerated()), id: \.element.id) { index, item in
                Group {
                    if item.course == .main {
                        MenuItemCard(
                            item: item,
                            canSwap: model.canSwap(item),
                            onOpen: { selected = item },
                            onSwap: { withAnimation(FGMotion.swap) { model.swap(item) } }
                        )
                    } else {
                        MenuItemRow(
                            item: item,
                            canSwap: model.canSwap(item),
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
    let canSwap: Bool
    let onOpen: () -> Void
    let onSwap: () -> Void

    var body: some View {
        FGCard(isHighlighted: item.course == .main) {
            VStack(alignment: .leading, spacing: FGSpace.s) {
                CourseTag(course: item.course)

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

/// Everything that isn't the Main. Same information, one glance.
private struct MenuItemRow: View {
    let item: MenuItem
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
                intent: .strengthen
            ),
            now: Date()
        )
    )
}
