//
//  CheckInSheet.swift
//  FeelGood
//
//  Two taps, ten seconds. The third is optional and stays optional — the app
//  never blocks on input, and there is no way to answer this wrongly.
//

import SwiftUI

struct CheckInSheet: View {
    let current: PlanCheckIn?
    let onDone: (PlanCheckIn) -> Void

    @State private var energy: Energy?
    @State private var time: TimeBudget?
    @State private var body_: BodyState?
    @Environment(\.dismiss) private var dismiss

    init(current: PlanCheckIn?, onDone: @escaping (PlanCheckIn) -> Void) {
        self.current = current
        self.onDone = onDone
        _energy = State(initialValue: current?.energy)
        _time = State(initialValue: current?.time)
        _body_ = State(initialValue: current?.body)
    }

    var body: some View {
        ZStack {
            FGColor.bg.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: FGSpace.l) {
                    Text("How's today?")
                        .font(FGFont.title)
                        .foregroundStyle(FGColor.ink)

                    question("What have you got in the tank?") {
                        ForEach(Energy.allCases, id: \.self) { option in
                            FGChoice(title: option.checkInLabel, isSelected: energy == option) {
                                withAnimation(FGMotion.gentle) { energy = option }
                            }
                        }
                    }

                    question("How much time, really?") {
                        ForEach(TimeBudget.allCases, id: \.self) { option in
                            FGChoice(title: option.checkInLabel, isSelected: time == option) {
                                withAnimation(FGMotion.gentle) { time = option }
                            }
                        }
                    }

                    question("Anything going on in your body? (optional)") {
                        ForEach(BodyState.allCases, id: \.self) { option in
                            FGChoice(title: option.checkInLabel, isSelected: body_ == option) {
                                withAnimation(FGMotion.gentle) {
                                    body_ = body_ == option ? nil : option
                                }
                            }
                        }
                    }

                    FGPrimaryButton(title: "Show me today") {
                        onDone(PlanCheckIn(
                            energy: energy ?? .steady,
                            time: time ?? .some,
                            body: body_
                        ))
                    }

                    FGQuietButton("Skip — just show me something") {
                        onDone(PlanCheckIn(energy: energy ?? .steady, time: time ?? .some, body: body_))
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(FGSpace.page)
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    private func question<Options: View>(_ title: String, @ViewBuilder options: () -> Options) -> some View {
        VStack(alignment: .leading, spacing: FGSpace.s) {
            Text(title)
                .font(FGFont.body.weight(.medium))
                .foregroundStyle(FGColor.ink)
            // Wraps rather than truncating when the type is large.
            FlowRow(spacing: FGSpace.s) { options() }
        }
    }
}

#Preview {
    CheckInSheet(current: nil) { _ in }
}
