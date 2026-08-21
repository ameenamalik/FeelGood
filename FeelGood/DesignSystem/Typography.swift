//
//  Typography.swift
//  FeelGood
//
//  SF Rounded for headlines — softer and more playful than the default face,
//  which suits a menu more than a dashboard. SF Pro for everything that has to
//  be read rather than glanced at.
//
//  Both are system faces, so there are no font files to bundle, no licensing
//  question, and full Dynamic Type support for free.
//

import SwiftUI

nonisolated enum FGFont {
    // Headlines and the menu itself.
    static let display = Font.system(.largeTitle, design: .rounded).weight(.bold)
    static let title = Font.system(.title2, design: .rounded).weight(.bold)
    static let itemTitle = Font.system(.headline, design: .rounded).weight(.semibold)
    /// Course tags and durations — small, so the rounded face keeps them friendly.
    static let label = Font.system(.caption, design: .rounded).weight(.medium)

    // Anything that is read in full.
    static let body = Font.system(.body, design: .default)
    /// The "why this" line under a menu item.
    static let reason = Font.system(.subheadline, design: .default)
    static let caption = Font.system(.footnote, design: .default)
    /// Step instructions and glossary text, where legibility beats character.
    static let instruction = Font.system(.body, design: .default)
}
