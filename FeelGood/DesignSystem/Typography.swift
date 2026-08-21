//
//  Typography.swift
//  FeelGood
//
//  A soft serif for headlines so the menu reads like a menu, and a humanist
//  sans for UI. Everything scales with Dynamic Type — no fixed sizes.
//

import SwiftUI

enum FGFont {
    /// The menu headline. Serif, because this is a menu, not a dashboard.
    static let display = Font.system(.largeTitle, design: .serif).weight(.regular)
    static let title = Font.system(.title2, design: .serif).weight(.regular)
    /// A menu item's name.
    static let itemTitle = Font.system(.headline, design: .serif).weight(.medium)
    static let body = Font.system(.body, design: .default)
    /// The "why this" line under an item.
    static let reason = Font.system(.subheadline, design: .default)
    static let caption = Font.system(.footnote, design: .default)
    /// Duration and equipment chips.
    static let label = Font.system(.caption, design: .default).weight(.medium)
}
