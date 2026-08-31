//
//  WrapRow.swift
//  FeelGood
//
//  Items at their natural width, wrapping onto as many lines as they need.
//
//  The counterpart to `FlowRow`, which gives every item an equal share of the
//  row. Equal shares are right for tiles, which want to line up in columns, and
//  wrong for pills: it stretches "Knees" to the width of "Low energy or fatigue"
//  and then wraps the long one anyway. A pill should be as wide as its word.
//

import SwiftUI

nonisolated struct WrapRow: Layout {
    var spacing: CGFloat = 8
    var lineSpacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = resolvedWidth(proposal.width)
        let rows = arrange(subviews: subviews, width: width)
        guard !rows.isEmpty else { return .zero }

        let height = rows.reduce(0) { $0 + $1.height }
            + lineSpacing * CGFloat(rows.count - 1)
        return CGSize(width: width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var y = bounds.minY
        for row in arrange(subviews: subviews, width: bounds.width) {
            var x = bounds.minX
            for item in row.items {
                subviews[item.index].place(
                    at: CGPoint(x: x, y: y + (row.height - item.size.height) / 2),
                    proposal: ProposedViewSize(item.size)
                )
                x += item.size.width + spacing
            }
            y += row.height + lineSpacing
        }
    }

    /// SwiftUI proposes nil, zero, or infinity while measuring. Any of those
    /// produce nonsense once spacing is subtracted, so resolve first — the same
    /// trap `FlowRow` documents.
    private func resolvedWidth(_ proposed: CGFloat?) -> CGFloat {
        guard let proposed, proposed.isFinite, proposed > 0 else { return 320 }
        return proposed
    }

    private struct Item {
        var index: Int
        var size: CGSize
    }

    private struct Row {
        var items: [Item]
        var height: CGFloat
    }

    /// Greedy: keep adding to the current line until the next item would not
    /// fit, then start another. An item wider than the whole line still gets
    /// its own line rather than being dropped.
    private func arrange(subviews: Subviews, width proposedWidth: CGFloat) -> [Row] {
        guard !subviews.isEmpty else { return [] }
        let width = resolvedWidth(proposedWidth)

        var rows: [Row] = []
        var current: [Item] = []
        var currentWidth: CGFloat = 0

        for index in subviews.indices {
            let size = subviews[index].sizeThatFits(
                ProposedViewSize(width: width, height: nil)
            )
            let needed = current.isEmpty ? size.width : currentWidth + spacing + size.width

            if !current.isEmpty, needed > width {
                rows.append(Row(items: current, height: current.map(\.size.height).max() ?? 0))
                current = []
                currentWidth = 0
            }

            current.append(Item(index: index, size: size))
            currentWidth = current.count == 1 ? size.width : currentWidth + spacing + size.width
        }

        if !current.isEmpty {
            rows.append(Row(items: current, height: current.map(\.size.height).max() ?? 0))
        }
        return rows
    }
}
