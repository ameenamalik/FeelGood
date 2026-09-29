//
//  CheckInSheet.swift
//  FeelGood
//
//  How do you want to feel, what kind of that, how long. Each tap moves on by
//  itself, and no answer beyond the first is required to get a menu. Once a
//  length is picked, "Show my menu" finishes, after the optional place and
//  what-to-go-easy-on lines have had their chance.
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
                        goalSection(proxy: proxy)

                        if let goal = flow.goal {
                            answerSection(goal: goal, proxy: proxy)
                                .id("answer-section")
                                .transition(
                                    reduceMotion
                                        ? .opacity
                                        : .opacity.combined(with: .move(edge: .bottom))
                                )
                        }

                        if let goal = flow.goal, flow.answer != nil, goal.asksForTime {
                            timeSection(goal: goal)
                                .id("time-section")
                                .transition(
                                    reduceMotion
                                        ? .opacity
                                        : .opacity.combined(with: .move(edge: .bottom))
                                )
                        }

                        if !flow.isComplete {
                            FGQuietButton("Just show me my menu") { skip() }
                                .frame(maxWidth: .infinity)
                                .padding(.top, FGSpace.xs)
                        }
                    }
                    .padding(FGSpace.page)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .scrollBounceBehavior(.basedOnSize)
            }
        }
        .fgAnimation(FGMotion.gentle, value: flow.goal)
        .fgAnimation(FGMotion.gentle, value: flow.answer)
        .fgAnimation(FGMotion.gentle, value: flow.time)
        .sensoryFeedback(.selection, trigger: flow)
        .sheet(isPresented: $isShowingBodySheet) {
            GoEasySheet(bodies: $flow.bodies)
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    // MARK: Section 1 — the goal

    @ViewBuilder
    private func goalSection(proxy: ScrollViewProxy) -> some View {
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
            VStack(alignment: .leading, spacing: FGSpace.xs) {
                sectionLabel("Your picks")
                ForEach(goals.picks, id: \.self) { goal in
                    GoalPickCard(goal: goal, isSelected: flow.goal == goal) {
                        withAnimation(FGMotion.gentle) {
                            flow.choose(goal: goal)
                        }
                        Task { @MainActor in
                            try? await Task.sleep(for: .milliseconds(60))
                            withAnimation(FGMotion.gentle) {
                                proxy.scrollTo("answer-section", anchor: .top)
                            }
                        }
                    }
                }
            }
        }

        if !goals.others.isEmpty {
            VStack(alignment: .leading, spacing: FGSpace.xs) {
                if !goals.picks.isEmpty {
                    Text("Or something different today")
                        .font(FGFont.caption.weight(.medium))
                        .foregroundStyle(FGColor.inkMuted)
                }

                LazyVGrid(columns: gridColumns, spacing: FGSpace.choiceGutter) {
                    ForEach(goals.others, id: \.self) { goal in
                        GoalOtherPill(goal: goal, isSelected: flow.goal == goal) {
                            withAnimation(FGMotion.gentle) {
                                flow.choose(goal: goal)
                            }
                            Task { @MainActor in
                                try? await Task.sleep(for: .milliseconds(60))
                                withAnimation(FGMotion.gentle) {
                                    proxy.scrollTo("answer-section", anchor: .top)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: Section 2 — answer

    @ViewBuilder
    private func answerSection(goal: Intent, proxy: ScrollViewProxy) -> some View {
        VStack(alignment: .leading, spacing: FGSpace.m) {
            Divider()
                .padding(.vertical, FGSpace.xs)

            HStack(alignment: .center, spacing: FGSpace.s) {
                Text(goal.checkInQuestion)
                    .font(.system(.title2, design: .rounded).weight(.bold))
                    .foregroundStyle(FGColor.ink)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)

                Spacer(minLength: 0)

                Image(goal.artworkName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 36, height: 36)
            }

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
                            Task { @MainActor in
                                try? await Task.sleep(for: .milliseconds(60))
                                withAnimation(FGMotion.gentle) {
                                    proxy.scrollTo("time-section", anchor: .bottom)
                                }
                            }
                        }
                    }
                }
            }
            .postHogMask()
        }
    }

    // MARK: Section 3 — time

    @ViewBuilder
    private func timeSection(goal: Intent) -> some View {
        VStack(alignment: .leading, spacing: FGSpace.m) {
            Divider()
                .padding(.vertical, FGSpace.xs)

            Text("How long have you got?")
                .font(.system(.title2, design: .rounded).weight(.bold))
                .foregroundStyle(FGColor.ink)
                .accessibilityAddTraits(.isHeader)

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

            // Picking a length no longer ends the check-in, so the optional
            // questions above stay reachable. This is the way out.
            if flow.isComplete {
                FGPrimaryButton(title: "Show my menu") { finish() }
                    .id("done-button")
                    .transition(.opacity)
            }
        }
        .postHogMask()
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(FGFont.caption.weight(.medium))
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

    /// Only records the length. Where you are and what to go easy on are
    /// optional but must stay reachable, so "Show my menu" ends the check-in.
    private func choose(time: TimeBudget) {
        flow.choose(time: time)
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
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(alignment: .center, spacing: FGSpace.m) {
                Text(goal.checkInFeeling)
                    .font(.system(.title3, design: .rounded).weight(.bold))
                    .foregroundStyle(isSelected ? FGColor.inkOnAccent : FGColor.ink)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)


                Image(goal.artworkName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 44, height: 44)
            }
            .padding(.horizontal, FGSpace.m)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, minHeight: 58)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(isSelected ? goal.aura.mid : FGColor.surface)
            )
            .clipShape(.rect(cornerRadius: 18))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(
                        isSelected ? FGColor.inkOnAccent : FGColor.line,
                        lineWidth: isSelected ? 3 : 1
                    )
            )
        }
        .buttonStyle(.feelGoodPress)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
        .accessibilityElement(children: .combine)
        .accessibilityLabel(goal.checkInFeeling)
        .accessibilityHint("Asks one more question about \(goal.checkInFeeling.lowercased())")
    }
}

private struct GoalOtherPill: View {
    let goal: Intent
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: FGSpace.xs) {
                ZStack {
                    Circle()
                        .fill(goal.aura.mid.opacity(0.35))
                        .frame(width: 32, height: 32)

                    Image(goal.artworkName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                }

                Text(goal.checkInFeeling)
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    .foregroundStyle(isSelected ? FGColor.inkOnAccent : FGColor.ink)
                    .lineLimit(2)
                    .minimumScaleFactor(0.75)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, minHeight: 54, alignment: .leading)
            .background(isSelected ? goal.aura.mid : FGColor.surface)
            .clipShape(.rect(cornerRadius: 20))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(
                        isSelected ? FGColor.inkOnAccent : FGColor.line,
                        lineWidth: isSelected ? 3 : 1
                    )
            )
        }
        .buttonStyle(.feelGoodPress)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
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
                HStack {
                    if let systemImage = answer.systemImage {
                        Image(systemName: systemImage)
                            .font(.system(size: 20, weight: .regular))
                            .foregroundStyle(isSelected ? FGColor.inkOnAccent : FGColor.ink)
                            .frame(height: 22)
                    } else {
                        Color.clear.frame(height: 22)
                    }
                    Spacer(minLength: 0)
                }

                Text(answer.title)
                    .font(.system(.headline, design: .rounded).weight(.bold))
                    .foregroundStyle(isSelected ? FGColor.inkOnAccent : FGColor.ink)
                    .fixedSize(horizontal: false, vertical: true)

                Text(answer.detail)
                    .font(FGFont.caption)
                    .foregroundStyle(isSelected ? FGColor.inkOnAccent : FGColor.inkMuted)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: 0)
            }
            .padding(FGSpace.m)
            .frame(maxWidth: .infinity, minHeight: 124, alignment: .topLeading)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(isSelected ? aura.mid : FGColor.surface)
            )
            .clipShape(.rect(cornerRadius: 24))
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .strokeBorder(isSelected ? FGColor.inkOnAccent : FGColor.line, lineWidth: isSelected ? 3 : 1)
            )
        }
        .buttonStyle(.feelGoodPress)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
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
                    .foregroundStyle(isSelected ? FGColor.inkOnAccent : FGColor.ink)

                Text("Something soft, nothing to prove")
                    .font(FGFont.caption)
                    .foregroundStyle(isSelected ? FGColor.inkOnAccent : FGColor.inkMuted)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .padding(.horizontal, FGSpace.m)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(isSelected ? FGAura.lilac.mid : FGColor.surface.opacity(0.5))
            )
            .clipShape(.rect(cornerRadius: 22))
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .strokeBorder(
                        isSelected ? FGColor.inkOnAccent : FGColor.lineStrong,
                        style: StrokeStyle(lineWidth: isSelected ? 3 : 1.5, dash: isSelected ? [] : [5, 4])
                    )
            )
        }
        .buttonStyle(.feelGoodPress)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
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
