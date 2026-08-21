//
//  FlowRow.swift
//  FeelGood
//
//  Wrapping row of equal-width choices, so answers reflow at large type sizes
//  instead of squeezing below the minimum touch target.
//

import SwiftUI

struct FlowRow: Layout {
    var spacing: CGFloat = 8
    /// Never go below this, whatever the proposal says.
    private let minimumItemWidth: CGFloat = 1

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = resolvedWidth(proposal.width)
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

    /// SwiftUI proposes nil, zero, or infinity while it is measuring. Any of
    /// those produce a negative item width once spacing is subtracted, and
    /// placing a subview at a negative width is a hard trap — so resolve to
    /// something sane before doing any arithmetic.
    private func resolvedWidth(_ proposed: CGFloat?) -> CGFloat {
        guard let proposed, proposed.isFinite, proposed > 0 else { return 320 }
        return proposed
    }

    private struct Row {
        var indices: [Int]
        var height: CGFloat
        var itemWidth: CGFloat
    }

    /// Choices share the row evenly, up to three across.
    private func arrange(subviews: Subviews, width proposedWidth: CGFloat) -> [Row] {
        guard !subviews.isEmpty else { return [] }
        let width = resolvedWidth(proposedWidth)
        let perRow = max(1, width < 340 ? 2 : min(3, subviews.count))
        let itemWidth = max(minimumItemWidth, (width - spacing * CGFloat(perRow - 1)) / CGFloat(perRow))

        var rows: [Row] = []
        var index = 0
        while index < subviews.count {
            let indices = Array(index..<min(index + perRow, subviews.count))
            let height = indices
                .map { subviews[$0].sizeThatFits(ProposedViewSize(width: itemWidth, height: nil)).height }
                .max() ?? 0
            rows.append(Row(indices: indices, height: height, itemWidth: itemWidth))
            index += perRow
        }
        return rows
    }
}
