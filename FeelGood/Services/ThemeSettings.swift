//
//  ThemeSettings.swift
//  FeelGood
//
//  Which look the person chose. On device only — a theme is not health data,
//  but there is no reason for it to leave the phone either.
//
//  Whether a theme is *earned* is not decided here. This stores a choice; the
//  Little Wins decide what may be chosen (docs/PRD-themes.md §7). Anything
//  unrecognised, or not allowed, falls back to Kiln without an error.
//

import Foundation
import Observation

@Observable
final class ThemeSettings {
    nonisolated static let key = "fgTheme"

    private let defaults: UserDefaults

    /// The look to draw with right now. Always a real theme.
    var selected: FGThemeID {
        didSet { defaults.set(selected.rawValue, forKey: Self.key) }
    }

    /// `defaults` is injected so tests never touch the real store. A DEBUG
    /// launch argument `-fgTheme indigo` overrides the saved value for that run
    /// only, because `UserDefaults` reads launch arguments as its own domain.
    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.selected = defaults.string(forKey: Self.key)
            .flatMap(FGThemeID.init(rawValue:)) ?? .kiln
    }
}
