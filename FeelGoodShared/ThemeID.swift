//
//  ThemeID.swift
//  FeelGood — shared by the app and the widget
//
//  Which look the app is wearing, and the one-colour-both-appearances pair
//  every theme value is made of. Foundation only, so the widget compiles it too.
//  The trait and SwiftUI bridge that carry a theme through the app live in
//  DesignSystem/Theme.swift; the widget has no use for them.
//

import Foundation

/// The looks the app can wear. Light and dark are not separate themes: each
/// theme carries both, and the system appearance picks between them.
///
/// `kiln` is the default and what everyone gets. `indigo` is earned — the
/// unlock rule lives in the Little Wins, not here.
nonisolated enum FGThemeID: String, Codable, CaseIterable, Hashable, Sendable {
    case kiln
    case indigo
}

/// One colour, both appearances.
nonisolated struct FGThemePair: Hashable, Sendable {
    let light: UInt32
    let dark: UInt32
}
