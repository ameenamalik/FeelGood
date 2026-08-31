//
//  CheckInSheet.swift
//  FeelGood
//
//  Two taps, ten seconds. The third and fourth are optional and stay optional —
//  the app never blocks on input, and there is no way to answer this wrongly.
//
//  One page that grows. The first question is all there is until it is
//  answered, then the next arrives underneath it. That keeps the "one thing at
//  a time" feel without paging: nothing is hidden behind a Back button, every
//  answer stays on screen where it can be changed, and the page getting longer
//  is the only progress indicator the sheet needs.
//
//  Each answer is a soft wash rather than an icon on white. Which wash an
//  answer gets means nothing — see the note above `checkInAura` in Palette.
//

import SwiftUI
import PostHog

struct CheckInSheet: View {
    let current: PlanCheckIn?
    let onDone: (PlanCheckIn) -> Void

    @State private var energy: Energy?
    @State private var time: TimeBudget?
    @State private var place: PlaceIntent?
    @State private var body_: BodyState?
    /// How many questions are on screen. Only ever grows within a sitting —
    /// taking an answer back must not make a question you have already seen
    /// disappear out from under you.
    @State private var revealed: Int
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var typeSize

    init(current: PlanCheckIn?, onDone: @escaping (PlanCheckIn) -> Void) {
        self.current = current
        self.onDone = onDone
        _energy = State(initialValue: current?.energy)
        _time = State(initialValue: current?.time)
        _place = State(initialValue: current?.place)
        _body_ = State(initialValue: current?.body)
        // Coming back to change one answer should not re-run the reveal — the
        // whole sheet is already yours at that point.
        _revealed = State(initialValue: current == nil ? 1 : CheckInFlow.stepCount)
    }

    var body: some View {
        ZStack {
            FGColor.bg.ignoresSafeArea()

            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: FGSpace.xl) {
                        title

                        energyQuestion(proxy)
                        if revealed > 1 { timeQuestion(proxy) }
                        if revealed > 2 { placeQuestion(proxy) }
                        if revealed > 3 { bodyQuestion }

                        footer
                    }
                    .padding(FGSpace.page)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .scrollBounceBehavior(.basedOnSize)
            }
        }
        .fgAnimation(FGMotion.settle, value: revealed)
        .sensoryFeedback(.selection, trigger: selection)
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    // MARK: Questions

    private var title: some View {
        Text("How's today?")
            .font(FGFont.title)
            .foregroundStyle(FGColor.ink)
            .accessibilityAddTraits(.isHeader)
    }

    private func energyQuestion(_ proxy: ScrollViewProxy) -> some View {
        question("What have you got in the tank?", index: 0) {
            ForEach(Energy.allCases, id: \.self) { option in
                FGAuraTile(
                    title: option.checkInLabel,
                    aura: option.checkInAura,
                    isSelected: energy == option
                ) {
                    energy = option
                    reveal(after: 0, didAnswer: true, using: proxy)
                }
            }
        }
    }

    private func timeQuestion(_ proxy: ScrollViewProxy) -> some View {
        question("How much time, really?", index: 1) {
            ForEach(TimeBudget.allCases, id: \.self) { option in
                FGAuraTile(
                    title: option.checkInMinutes,
                    detail: "min",
                    titleStyle: .display,
                    aura: option.checkInAura,
                    isSelected: time == option
                ) {
                    time = option
                    reveal(after: 1, didAnswer: true, using: proxy)
                }
            }
        }
    }

    private func placeQuestion(_ proxy: ScrollViewProxy) -> some View {
        question("Where are you today?", index: 2, isOptional: true) {
            ForEach(PlaceIntent.allCases, id: \.self) { option in
                FGAuraTile(
                    title: option.checkInLabel,
                    aura: option.checkInAura,
                    isSelected: place == option
                ) {
                    // Tapping the answer you already gave takes it back.
                    // Un-answering must not reveal the next question — see
                    // `CheckInFlow.next`.
                    let wasSelected = place == option
                    place = wasSelected ? nil : option
                    reveal(after: 2, didAnswer: !wasSelected, using: proxy)
                }
            }
        }
        .overlay(alignment: .topTrailing) {
            // The only question that needs a way past it: the last one is
            // already followed by the button that ends the sheet.
            if revealed == 3 {
                Button("Skip") { reveal(after: 2, didAnswer: true, using: proxy) }
                    .font(FGFont.caption)
                    .foregroundStyle(FGColor.inkMuted)
            }
        }
    }

    private var bodyQuestion: some View {
        question("Anything going on in your body?", index: 3, isOptional: true) {
            ForEach(BodyState.allCases, id: \.self) { option in
                FGAuraTile(
                    title: option.checkInLabel,
                    aura: option.checkInAura,
                    isSelected: body_ == option
                ) {
                    body_ = body_ == option ? nil : option
                }
            }
        }
    }

    /// One question and its answers. `index` doubles as the scroll target, so
    /// a newly revealed question can be brought into view.
    private func question<Options: View>(
        _ text: String,
        index: Int,
        isOptional: Bool = false,
        @ViewBuilder options: () -> Options
    ) -> some View {
        VStack(alignment: .leading, spacing: FGSpace.m) {
            Text(text)
                .font(FGFont.itemTitle)
                .foregroundStyle(isOptional ? FGColor.inkMuted : FGColor.ink)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)

            FlowRow.choices(isAccessibilitySize: typeSize.isAccessibilitySize) { options() }
                .postHogMask()
        }
        .id(index)
        .transition(
            reduceMotion
                ? .opacity
                : .opacity.combined(with: .offset(y: 16))
        )
    }

    // MARK: Footer

    @ViewBuilder
    private var footer: some View {
        VStack(spacing: FGSpace.s) {
            // Appears as soon as there is enough to build a menu from, rather
            // than waiting for the optional questions to be dealt with.
            if energy != nil, time != nil {
                FGPrimaryButton(title: "Show me today") { finish() }
            }

            FGQuietButton("Skip — just show me something") { finish() }
                .frame(maxWidth: .infinity)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: Behaviour

    /// Brings the next question onto the page and scrolls to it.
    ///
    /// `didAnswer` is false when the tap cleared an answer rather than giving
    /// one; nothing new appears in that case.
    private func reveal(after index: Int, didAnswer: Bool, using proxy: ScrollViewProxy) {
        guard let next = CheckInFlow.next(after: index, didAnswer: didAnswer) else { return }
        guard next >= revealed else { return }

        revealed = next + 1

        guard !reduceMotion else {
            proxy.scrollTo(next, anchor: .center)
            return
        }

        withAnimation(FGMotion.settle) {
            proxy.scrollTo(next, anchor: .center)
        }
    }

    /// Every answer as it actually stands, including the unanswered ones. The
    /// defaults in `plan` would swallow the first tap on "Steady" — nothing
    /// would appear to change — so haptics key off this instead.
    private var selection: [String?] {
        [energy?.rawValue, time?.rawValue, place?.rawValue, body_?.rawValue]
    }

    /// What gets handed back: the unanswered questions fall back to the middle,
    /// because skipping is always allowed to produce a menu.
    private var plan: PlanCheckIn {
        PlanCheckIn(energy: energy ?? .steady, time: time ?? .some, place: place, body: body_)
    }

    private func finish() {
        // `body_` is handed over and dropped: `CheckInAnalytics` has nowhere to
        // put it. That is the whole point of the type — see its header.
        Analytics.capture(
            CheckInAnalytics(energy: energy, time: time, place: place, body: body_)
        )
        onDone(plan)
    }
}

#Preview("Empty") {
    CheckInSheet(current: nil) { _ in }
}

#Preview("Answered") {
    CheckInSheet(
        current: PlanCheckIn(energy: .low, time: .aLittle, place: .stayingIn, body: .stiff)
    ) { _ in }
}

#Preview("Aura tiles") {
    FlowRow.choices(isAccessibilitySize: false) {
        ForEach(Array(FGAura.allCases.enumerated()), id: \.offset) { _, aura in
            FGAuraTile(title: "Steady", detail: "20–30", aura: aura, isSelected: aura == .apricot) {}
        }
    }
    .padding(FGSpace.page)
    .background(FGColor.bg)
}
