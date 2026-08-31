//
//  Layout.swift
//  FeelGood
//
//  Generous whitespace, large touch targets, one idea per screen.
//

import SwiftUI

nonisolated enum FGSpace {
    static let xs: CGFloat = 4
    static let s: CGFloat = 8
    static let m: CGFloat = 16
    static let l: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 48
    /// Standard page inset.
    static let page: CGFloat = 24
    /// The gutter between choice tiles. Paired with `FGSize.choiceTileMinimum`:
    /// the two together decide how many tiles fit a row, so neither moves alone.
    static let choiceGutter: CGFloat = 12
}

nonisolated enum FGRadius {
    static let card: CGFloat = 20
    static let chip: CGFloat = 10
    static let button: CGFloat = 16
    /// Check-in aura tiles. Softer than a card because the tile is a colour
    /// field rather than a container — a tighter radius makes the wash read as
    /// a swatch instead of a surface.
    static let tile: CGFloat = 28
}

nonisolated enum FGSize {
    /// Never smaller than this, anywhere.
    static let minTouchTarget: CGFloat = 44

    /// The natural side of a choice tile carrying an icon: its height, and the
    /// width it settles at when the row has room to spare.
    static let choiceTile: CGFloat = 110

    /// An aura tile. Taller than `choiceTile` because the label sits under an
    /// icon with room to breathe rather than tight beneath it — the proportion
    /// the check-in mockup settled on.
    static let auraTile: CGFloat = 132

    /// The narrowest a choice tile may be squeezed before `FlowRow` gives up a
    /// column. Three tiles and two 12pt gutters have to fit inside the page
    /// inset on the smallest phone we support — 3 × 96 + 24 = 312, against the
    /// 327pt of content a 375pt screen leaves after `FGSpace.page` either side.
    ///
    /// This was effectively 110 before, because the tile was pinned to exactly
    /// that width. 3 × 110 + 24 = 354, which no iPhone below the 17 can give,
    /// so every narrower phone silently fell to two columns and an orphan row —
    /// and, since the tile could not stretch either, centred a 110pt tile in a
    /// 161pt slot and left a gutter down the middle.
    ///
    /// Read with `FGSpace.choiceGutter`; `FlowRow.choices` is the only place
    /// the two are combined.
    static let choiceTileMinimum: CGFloat = 96
}
