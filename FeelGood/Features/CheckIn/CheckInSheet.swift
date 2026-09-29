//
//  CheckInSheet.swift
//  FeelGood
//
//  How do you want to feel, what kind of that, how long. Three taps, and each
//  one moves on by itself — there is no Next button to find, and no answer
//  beyond the first is required to get a menu.
//
//  The goals picked in onboarding lead the first screen, so the check-in
//  follows what someone already said they were moving toward instead of
//  asking from scratch. The others stay one tap away underneath.
//
//  The goal's fruit fills with colour a third at a time as the questions are
//  answered. It is the only progress indicator on the sheet, and it is a
//  fruit, not a bar: nothing here is a score.
//
//  The rules for where a tap goes live in `CheckInFlow`; this file is layout.
//

import SwiftUI
import PostHog

struct CheckInSheet: View {
    let current: PlanCheckIn?
    /// The onboarding goals, which lead the first screen.
    let standingIntents: Set<Intent>
    /// The profile's places. The "At home ▾" line only appears when there is
    /// more than one to choose between.
    let places: Set<Place>
    let onDone: (PlanCheckIn) -> Void

    @State private var flow: CheckInFlow
    @State private var isShowingBodySheet = false
    @State private var isFinishing = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var typeSize

    init(
        current: PlanCheckIn?,
        standingIntents: Set<Intent> = [],
        places: Set<Place> = [],
        onDone: @escaping (PlanCheckIn) -> Void
    ) {
        self.current = current
        self.standingIntents = standingIntents
        self.places = places
        self.onDone = onDone
        // Where you are and what to go easy on carry over from earlier today;
        // the goal and its answer are asked fresh every time.
        _flow = State(initialValue: CheckInFlow(place: current?.place, bodies: current?.bodies ?? []))
    }

    var body: some View {
        ZStack {
            FGColor.bg.ignoresSafeArea()

            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: FGSpace.l) {
                        switch flow.step {
                        case .goal:
                            goalScreen
                        case .answer, .time:
                            answerAndTimeScreen(proxy: proxy)
                        }
                    }
                    .padding(FGSpace.page)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .id(flow.step == .goal ? "goal-step" : "detail-step")
                    .transition(
                        reduceMotion
                            ? .opacity
                            : .asymmetric(
                                insertion: .opacity.combined(with: .offset(x: 24)),
                                removal: .opacity
                            )
                    )
                }
                .scrollBounceBehavior(.basedOnSize)
            }
        }
        .fgAnimation(FGMotion.settle, value: flow.step)
        .fgAnimation(FGMotion.gentle, value: flow.answer)
        .sensoryFeedback(.selection, trigger: flow)
        .sheet(isPresented: $isShowingBodySheet) {
            GoEasySheet(bodies: $flow.bodies)
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    // MARK: Screen 1 — the goal

    @ViewBuilder
    private var goalScreen: some View {
        let goals = CheckInFlow.orderedGoals(standing: standingIntents)

        VStack(alignment: .leading, spacing: FGSpace.xs) {
            Text("How do you want to feel today?")
                .font(.system(.title, design: .rounded).weight(.bold))
                .foregroundStyle(FGColor.ink)
                .accessibilityAddTraits(.isHeader)

            Text("Tap what sounds right. That's the whole thing.")
                .font(FGFont.caption)
                .foregroundStyle(FGColor.inkMuted)
        }

        if !goals.picks.isEmpty {
            VStack(alignment: .leading, spacing: FGSpace.s) {
                sectionLabel("Your picks")
                ForEach(goals.picks, id: \.self) { goal in
                    GoalPickCard(goal: goal) {
                        flow.choose(goal: goal)
                    }
                }
            }
        }

        if !goals.others.isEmpty {
            VStack(alignment: .leading, spacing: FGSpace.s) {
                if !goals.picks.isEmpty {
                    Text("Or something different today")
                        .font(FGFont.caption)
                        .foregroundStyle(FGColor.inkMuted)
                }

                LazyVGrid(columns: gridColumns, spacing: FGSpace.choiceGutter) {
                    ForEach(goals.others, id: \.self) { goal in
                        GoalOtherPill(goal: goal) {
                            flow.choose(goal: goal)
                        }
                    }
                }
            }
        }

        FGQuietButton("Just show me my menu") { skip() }
            .frame(maxWidth: .infinity)
            .padding(.top, FGSpace.xs)
    }

    // MARK: Screen 2 & 3 — answer and time

    @ViewBuilder
    private func answerAndTimeScreen(proxy: ScrollViewProxy) -> some View {
        if let goal = flow.goal {
            header(goal)

            Text(goal.checkInQuestion)
                .font(FGFont.title)
                .foregroundStyle(FGColor.ink)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)

            LazyVGrid(columns: gridColumns, spacing: FGSpace.choiceGutter) {
                ForEach(goal.checkInAnswers) { answer in
                    FeelingAnswerCard(
                        answer: answer,
                        aura: goal.aura,
                        isSelected: flow.answer == answer
                    ) {
                        withAnimation(FGMotion.gentle) {
                            flow.choose(answer: answer)
                        }
                        if flow.isComplete {
                            finish()
                        } else if goal.asksForTime {
                            withAnimation(FGMotion.gentle) {
                                proxy.scrollTo("time-section", anchor: .bottom)
                            }
                        }
                    }
                }
            }
            .postHogMask()

            if goal.asksForTime && (flow.step == .time || flow.answer != nil) {
                timeSection(goal: goal)
                    .id("time-section")
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
    }

    @ViewBuilder
    private func timeSection(goal: Intent) -> some View {
        VStack(alignment: .leading, spacing: FGSpace.m) {
            Text("How long have you got?")
                .font(.system(.title2, design: .rounded).weight(.bold))
                .foregroundStyle(FGColor.ink)
                .accessibilityAddTraits(.isHeader)
                .padding(.top, FGSpace.s)

            WrapRow(spacing: FGSpace.s, lineSpacing: FGSpace.s) {
                ForEach(TimeBudget.checkInChoices, id: \.self) { option in
                    FGPill(
                        title: option.checkInChipLabel,
                        selectedAura: goal.aura,
                        isSelected: flow.time == option
                    ) {
                        choose(time: option)
                    }
                    .accessibilityLabel(option.checkInLabel)
                }
            }

            RestingTodayCard(isSelected: flow.time == .zeroMinutes) {
                choose(time: .zeroMinutes)
            }

            VStack(spacing: FGSpace.s) {
                if placeOptions.count > 1 {
                    SwiftUI.Menu {
                        Picker("Where you are", selection: $flow.place) {
                            Text("Anywhere").tag(PlaceIntent?.none)
                            ForEach(placeOptions, id: \.self) { option in
                                Text(option.checkInLabel).tag(Optional(option))
                            }
                        }
                    } label: {
                        Label(
                            flow.place?.checkInLabel ?? "Anywhere",
                            systemImage: "chevron.down"
                        )
                        .labelStyle(TrailingIconLabelStyle())
                        .font(FGFont.body)
                        .foregroundStyle(FGColor.inkMuted)
                        .frame(minHeight: FGSize.minTouchTarget)
                    }
                    .accessibilityLabel("Where you are: \(flow.place?.checkInLabel ?? "Anywhere")")
                }

                Button {
                    isShowingBodySheet = true
                } label: {
                    Text(flow.bodies.isEmpty ? "Anything to go easy on?" : "Going easy on \(flow.bodies.count == 1 ? "one thing" : "a few things")")
                        .font(FGFont.caption.weight(.medium))
                        .underline()
                        .foregroundStyle(FGColor.ink)
                        .frame(minHeight: FGSize.minTouchTarget)
                }
                .buttonStyle(.feelGoodPress)
            }
            .frame(maxWidth: .infinity)
        }
        .postHogMask()
    }

    // MARK: Pieces

    /// The goal's fruit, filling as the questions are answered, beside the way
    /// back to the screen before.
    private func header(_ goal: Intent) -> some View {
        HStack(alignment: .center, spacing: FGSpace.m) {
            Button {
                withAnimation(FGMotion.gentle) {
                    flow.goBack()
                }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(FGColor.ink)
                    .frame(width: FGSize.minTouchTarget, height: FGSize.minTouchTarget)
                    .background(Circle().fill(FGColor.surface))
                    .overlay(Circle().strokeBorder(FGColor.line))
            }
            .buttonStyle(.feelGoodPress)
            .accessibilityLabel("Back")

            Spacer(minLength: 0)

            FruitFillWell(
                artworkName: goal.artworkName,
                aura: goal.aura,
                fraction: flow.fillFraction,
                size: typeSize.isAccessibilitySize ? 72 : 96
            )

            Spacer(minLength: 0)

            // Balances the back button so the fruit sits in the middle.
            Color.clear.frame(width: FGSize.minTouchTarget, height: 1)
        }
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text.uppercased())
            .font(FGFont.label)
            .tracking(0.8)
            .foregroundStyle(FGColor.inkMuted)
    }

    /// Two columns, or one once the type is large enough that two would
    /// truncate the answers.
    private var gridColumns: [GridItem] {
        let count = typeSize.isAccessibilitySize ? 1 : 2
        return Array(repeating: GridItem(.flexible(), spacing: FGSpace.choiceGutter), count: count)
    }

    /// Only the choices the profile can actually use today.
    private var placeOptions: [PlaceIntent] {
        PlaceIntent.allCases.filter { option in
            option == .stayingIn || !option.places.subtracting([.home]).isDisjoint(with: places)
        }
    }

    // MARK: Behaviour

    private func choose(time: TimeBudget) {
        flow.choose(time: time)
        if flow.isComplete { finish() }
    }

    /// Lets the fruit finish filling before the sheet goes, so the last tap
    /// visibly lands. No pause with Reduce Motion on.
    private func finish() {
        guard !isFinishing, let checkIn = flow.checkIn else { return }
        isFinishing = true
        // `bodies` is reduced to a yes/no inside `CheckInAnalytics`; the
        // answer's body area never leaves the device at all.
        Analytics.capture(
            CheckInAnalytics(energy: checkIn.energy, time: checkIn.time, place: checkIn.place, bodies: checkIn.bodies)
        )
        Task {
            if !reduceMotion { try? await Task.sleep(for: .milliseconds(550)) }
            onDone(checkIn)
        }
    }

    /// Straight to the menu: whatever was said earlier today, or the middle.
    private func skip() {
        Analytics.capture(CheckInAnalytics(energy: nil, time: nil, place: nil, bodies: []))
        onDone(current ?? PlanCheckIn(energy: .steady, time: .some, place: flow.place, bodies: flow.bodies))
    }
}

// MARK: - The filling fruit

/// A fruit in a round well that fills with its goal's colour from the bottom.
/// The unfilled part of the fruit stays grey, so how far along you are reads
/// without a number. Decorative: hidden from VoiceOver, which hears the
/// questions themselves.
struct FruitFillWell: View {
    let artworkName: String
    let aura: FGAura
    /// 0 to 1.
    let fraction: Double
    var size: CGFloat = 96

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        TimelineView(.animation(paused: reduceMotion)) { context in
            let seconds = context.date.timeIntervalSinceReferenceDate
            let phase = reduceMotion ? 0 : seconds * 1.6
            let bob = reduceMotion ? 0 : sin(seconds * 2.1) * 3

            ZStack {
                Circle().fill(FGColor.panel)

                FillWave(level: fraction, phase: phase, amplitude: size * 0.035)
                    .fill(aura.mid)

                fruit
                    .saturation(0)
                    .opacity(0.4)

                fruit
                    .mask(alignment: .bottom) {
                        FillWave(level: fraction, phase: phase, amplitude: size * 0.035)
                    }
            }
            .frame(width: size, height: size)
            .clipShape(Circle())
            .rotationEffect(.degrees(bob))
        }
        .fgAnimation(FGMotion.settle, value: fraction)
        .accessibilityHidden(true)
    }

    private var fruit: some View {
        Image(artworkName)
            .resizable()
            .scaledToFit()
            .padding(size * 0.14)
            .frame(width: size, height: size)
    }
}

/// The filled part of the well, with a soft wave along its top edge. The wave
/// flattens at empty and full so neither end shows a sliver.
///
/// `nonisolated` because SwiftUI asks a shape for its path off the main
/// thread; see the note on UIKit callbacks in CLAUDE.md.
nonisolated struct FillWave: Shape {
    var level: Double
    var phase: Double
    var amplitude: CGFloat

    var animatableData: AnimatablePair<Double, Double> {
        get { AnimatablePair(level, phase) }
        set { level = newValue.first; phase = newValue.second }
    }

    func path(in rect: CGRect) -> Path {
        let clamped = min(max(level, 0), 1)
        guard clamped > 0 else { return Path() }
        let crest = rect.maxY - rect.height * clamped
        let height = amplitude * sin(clamped * .pi)

        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        for x in stride(from: rect.minX, through: rect.maxX, by: 2) {
            let progress = (x - rect.minX) / max(rect.width, 1)
            let y = crest + CGFloat(sin(progress * 2 * .pi + phase)) * height
            path.addLine(to: CGPoint(x: x, y: y))
        }
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

// MARK: - Goal & Answer Cards

private struct GoalPickCard: View {
    let goal: Intent
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(alignment: .center, spacing: FGSpace.m) {
                Text(goal.checkInFeeling)
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundStyle(FGColor.ink)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Image(goal.artworkName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 76, height: 76)
            }
            .padding(.horizontal, FGSpace.l)
            .padding(.vertical, FGSpace.m)
            .frame(maxWidth: .infinity, minHeight: 96)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [goal.aura.core, goal.aura.mid.opacity(0.75)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .clipShape(.rect(cornerRadius: 24))
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .strokeBorder(FGColor.line, lineWidth: 1)
            )
        }
        .buttonStyle(.feelGoodPress)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(goal.checkInFeeling)
        .accessibilityHint("Asks one more question about \(goal.checkInFeeling.lowercased())")
    }
}

private struct GoalOtherPill: View {
    let goal: Intent
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: FGSpace.s) {
                ZStack {
                    Circle()
                        .fill(goal.aura.mid.opacity(0.35))
                        .frame(width: 36, height: 36)

                    Image(goal.artworkName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 28, height: 28)
                }

                Text(goal.checkInFeeling)
                    .font(.system(.body, design: .rounded).weight(.semibold))
                    .foregroundStyle(FGColor.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, minHeight: 54, alignment: .leading)
            .background(FGColor.surface)
            .clipShape(.rect(cornerRadius: 20))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(FGColor.line, lineWidth: 1)
            )
        }
        .buttonStyle(.feelGoodPress)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(goal.checkInFeeling)
        .accessibilityHint("Asks one more question about \(goal.checkInFeeling.lowercased())")
    }
}

private struct FeelingAnswerCard: View {
    let answer: CheckInAnswer
    let aura: FGAura
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 6) {
                if let systemImage = answer.systemImage {
                    Image(systemName: systemImage)
                        .font(.system(size: 20, weight: .regular))
                        .foregroundStyle(FGColor.ink)
                        .frame(height: 22)
                } else {
                    Color.clear.frame(height: 22)
                }

                Text(answer.title)
                    .font(.system(.headline, design: .rounded).weight(.bold))
                    .foregroundStyle(FGColor.ink)
                    .fixedSize(horizontal: false, vertical: true)

                Text(answer.detail)
                    .font(FGFont.caption)
                    .foregroundStyle(FGColor.inkMuted)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: 0)
            }
            .padding(FGSpace.m)
            .frame(maxWidth: .infinity, minHeight: 124, alignment: .topLeading)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(isSelected ? aura.core : FGColor.surface)
            )
            .clipShape(.rect(cornerRadius: 24))
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .strokeBorder(isSelected ? FGColor.ink : FGColor.line, lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.feelGoodPress)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(answer.title), \(answer.detail)")
    }
}

private struct RestingTodayCard: View {
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text("Resting today")
                    .font(.system(.body, design: .rounded).weight(.bold))
                    .foregroundStyle(FGColor.ink)

                Text("Something soft, nothing to prove")
                    .font(FGFont.caption)
                    .foregroundStyle(FGColor.inkMuted)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .padding(.horizontal, FGSpace.m)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(isSelected ? FGAura.lilac.core : FGColor.surface.opacity(0.5))
            )
            .clipShape(.rect(cornerRadius: 22))
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .strokeBorder(
                        isSelected ? FGColor.ink : FGColor.lineStrong,
                        style: StrokeStyle(lineWidth: isSelected ? 2 : 1.5, dash: [5, 4])
                    )
            )
        }
        .buttonStyle(.feelGoodPress)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Resting today. Something soft, nothing to prove")
    }
}

// MARK: - Anything to go easy on

/// The existing body answers, moved off the main screen: optional, and asked
/// only by someone who goes looking. "Feeling good" is left out — not asking
/// already means that.
private struct GoEasySheet: View {
    @Binding var bodies: Set<BodyState>
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: FGSpace.l) {
            VStack(alignment: .leading, spacing: FGSpace.xs) {
                Text("Anything to go easy on?")
                    .font(FGFont.title)
                    .foregroundStyle(FGColor.ink)
                    .accessibilityAddTraits(.isHeader)
                Text("Pick any that fit. The menu works around them.")
                    .font(FGFont.caption)
                    .foregroundStyle(FGColor.inkMuted)
            }

            WrapRow(spacing: FGSpace.s, lineSpacing: FGSpace.s) {
                ForEach(BodyState.allCases.filter { $0 != .good }, id: \.self) { option in
                    FGPill(
                        title: option.checkInLabel,
                        selectedAura: option.checkInAura,
                        isSelected: bodies.contains(option)
                    ) {
                        if bodies.contains(option) {
                            bodies.remove(option)
                        } else {
                            bodies.remove(.good)
                            bodies.insert(option)
                        }
                    }
                }
            }
            .postHogMask()

            Spacer(minLength: 0)

            FGPrimaryButton(title: "Done") { dismiss() }
        }
        .padding(FGSpace.page)
        .background(FGColor.bg.ignoresSafeArea())
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
}

private struct TrailingIconLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: FGSpace.xs) {
            configuration.title
            configuration.icon.imageScale(.small)
        }
    }
}

#Preview("Picked Calm and Mobility") {
    CheckInSheet(current: nil, standingIntents: [.calm, .mobilize], places: [.home, .outdoors]) { _ in }
}

#Preview("Nothing picked in onboarding") {
    CheckInSheet(current: nil) { _ in }
}

#Preview("Fruit fill") {
    HStack(spacing: FGSpace.m) {
        ForEach([0.0, 1.0 / 3.0, 2.0 / 3.0, 1.0], id: \.self) { fraction in
            FruitFillWell(artworkName: Intent.play.artworkName, aura: Intent.play.aura, fraction: fraction, size: 80)
        }
    }
    .padding(FGSpace.page)
    .background(FGColor.bg)
}
