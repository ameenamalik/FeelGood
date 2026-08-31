//
//  CheckInSheet.swift
//  FeelGood
//
//  Two taps, ten seconds. The third is optional and stays optional — the app
//  never blocks on input, and there is no way to answer this wrongly.
//
//  It should also feel like being asked, not like filling in a form: each
//  question carries its own colour, each answer its own small picture, and the
//  four groups arrive one after the other rather than all at once.
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
    @State private var hasAppeared = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var typeSize

    init(current: PlanCheckIn?, onDone: @escaping (PlanCheckIn) -> Void) {
        self.current = current
        self.onDone = onDone
        _energy = State(initialValue: current?.energy)
        _time = State(initialValue: current?.time)
        _place = State(initialValue: current?.place)
        _body_ = State(initialValue: current?.body)
    }

    var body: some View {
        ZStack {
            FGColor.bg.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: FGSpace.l) {
                    title

                    question("What have you got in the tank?", accent: .sky, index: 0) {
                        ForEach(Energy.allCases, id: \.self) { option in
                            FGChoice(
                                title: option.checkInLabel,
                                systemImage: option.checkInSymbol,
                                accent: option.checkInAccent,
                                isSelected: energy == option
                            ) {
                                energy = option
                            }
                        }
                    }

                    question("How much time, really?", accent: .lime, index: 1) {
                        ForEach(TimeBudget.allCases, id: \.self) { option in
                            FGChoice(
                                title: option.checkInLabel,
                                systemImage: option.checkInSymbol,
                                detail: option.checkInDetail,
                                accent: option.checkInAccent,
                                isSelected: time == option
                            ) {
                                time = option
                            }
                        }
                    }

                    question("Where are you today? (optional)", accent: .lavender, index: 2) {
                        ForEach(PlaceIntent.allCases, id: \.self) { option in
                            FGChoice(
                                title: option.checkInLabel,
                                systemImage: option.checkInSymbol,
                                accent: option.checkInAccent,
                                isSelected: place == option
                            ) {
                                place = place == option ? nil : option
                            }
                        }
                    }

                    question("Anything going on in your body? (optional)", accent: .pink, index: 3) {
                        ForEach(BodyState.allCases, id: \.self) { option in
                            FGChoice(
                                title: option.checkInLabel,
                                systemImage: option.checkInSymbol,
                                accent: option.checkInAccent,
                                isSelected: body_ == option
                            ) {
                                body_ = body_ == option ? nil : option
                            }
                        }
                    }

                    FGPrimaryButton(title: "Show me today") { finish() }

                    FGQuietButton("Skip — just show me something") { finish() }
                        .frame(maxWidth: .infinity)
                }
                .padding(FGSpace.page)
            }
        }
        .fgAnimation(FGMotion.gentle, value: selection)
        .sensoryFeedback(.selection, trigger: selection)
        .onAppear { hasAppeared = true }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    // MARK: Pieces

    private var title: some View {
        Text("How's today?")
            .font(FGFont.title)
            .foregroundStyle(FGColor.ink)
            .accessibilityAddTraits(.isHeader)
    }

    private func question<Options: View>(
        _ title: String,
        accent: FGAccent,
        index: Int,
        @ViewBuilder options: () -> Options
    ) -> some View {
        VStack(alignment: .leading, spacing: FGSpace.s) {
            HStack(spacing: FGSpace.s) {
                // Ties the question to the colour its answers fill with.
                Capsule()
                    .fill(accent.fill)
                    .frame(width: 4, height: 18)
                    .accessibilityHidden(true)

                Text(title)
                    .font(FGFont.body.weight(.medium))
                    .foregroundStyle(FGColor.ink)
            }

            // Wraps rather than truncating when the type is large, and drops
            // to a single column once the type is large enough that three
            // would break words apart.
            FlowRow(
                spacing: 12,
                maxPerRow: typeSize.isAccessibilitySize ? 1 : 3,
                minimumItemWidth: 110
            ) { options() }
            .postHogMask()
        }
        .opacity(hasAppeared ? 1 : 0)
        .offset(y: hasAppeared ? 0 : 12)
        .animation(
            reduceMotion ? .none : FGMotion.settle.delay(FGMotion.stagger(index)),
            value: hasAppeared
        )
    }

    // MARK: Answers

    /// Every answer as it actually stands, including the unanswered ones. The
    /// defaults in `answers` would swallow the first tap on "Steady" — nothing
    /// would appear to change — so animation and haptics key off this instead.
    private var selection: [String?] {
        [energy?.rawValue, time?.rawValue, place?.rawValue, body_?.rawValue]
    }

    /// What gets handed back: the unanswered questions fall back to the middle,
    /// because skipping is always allowed to produce a menu.
    private var answers: PlanCheckIn {
        PlanCheckIn(energy: energy ?? .steady, time: time ?? .some, place: place, body: body_)
    }

    private func finish() {
        // `body_` is handed over and dropped: `CheckInAnalytics` has nowhere to
        // put it. That is the whole point of the type — see its header.
        Analytics.capture(
            CheckInAnalytics(energy: energy, time: time, place: place, body: body_)
        )
        onDone(answers)
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
