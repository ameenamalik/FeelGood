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

/// Simple wrapping row, so choices reflow at large type sizes instead of
/// squeezing below the minimum touch target.
struct FlowRow: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.replacingUnspecifiedDimensions().width
        let rows = arrange(subviews: subviews, width: width)
        let height = rows.reduce(0) { $0 + $1.height } + spacing * CGFloat(max(0, rows.count - 1))
        return CGSize(width: width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var y = bounds.minY
        for row in arrange(subviews: subviews, width: bounds.width) {
            var x = bounds.minX
            for index in row.indices {
                let size = subviews[index].sizeThatFits(.unspecified)
                subviews[index].place(
                    at: CGPoint(x: x, y: y),
                    proposal: ProposedViewSize(width: row.itemWidth, height: size.height)
                )
                x += row.itemWidth + spacing
            }
            y += row.height + spacing
        }
    }

    private struct Row {
        var indices: [Int]
        var height: CGFloat
        var itemWidth: CGFloat
    }

    /// Choices share the row evenly, up to three across.
    private func arrange(subviews: Subviews, width: CGFloat) -> [Row] {
        guard !subviews.isEmpty else { return [] }
        let perRow = width < 340 ? 2 : min(3, subviews.count)
        var rows: [Row] = []
        var index = 0
        while index < subviews.count {
            let indices = Array(index..<min(index + perRow, subviews.count))
            let itemWidth = (width - spacing * CGFloat(perRow - 1)) / CGFloat(perRow)
            let height = indices
                .map { subviews[$0].sizeThatFits(ProposedViewSize(width: itemWidth, height: nil)).height }
                .max() ?? 0
            rows.append(Row(indices: indices, height: height, itemWidth: itemWidth))
            index += perRow
        }
        return rows
    }
}

#Preview {
    CheckInSheet(current: nil) { _ in }
}
