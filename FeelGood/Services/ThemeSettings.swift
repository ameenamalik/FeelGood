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

    /// The look the person chose. May name a theme they can no longer use (for
    /// example after their history was cleared); draw with `effective(unlocked:)`.
    var selected: FGThemeID {
        didSet { defaults.set(selected.rawValue, forKey: Self.key) }
    }

    /// What to actually draw with: the choice if it is available, otherwise
    /// Kiln, with no error and nothing said. Unlocks are derived from history,
    /// so a theme is never taken away — this only covers a wiped history.
    func effective(unlocked: [FGThemeID]) -> FGThemeID {
        unlocked.contains(selected) ? selected : .kiln
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

// MARK: - Which themes are earned

nonisolated extension FGThemeID {
    /// What the person calls it.
    var title: String {
        switch self {
        case .kiln: "Kiln"
        case .indigo: "Indigo"
        }
    }

    /// The Little Win that unlocks this look. `nil` means everyone has it.
    var unlockingWin: LittleWin? {
        switch self {
        case .kiln: nil
        case .indigo: .varietyPack
        }
    }

    /// The looks available given the person's Little Wins. Additive only: it is
    /// derived from history, so nothing here is counted, stored, or lost.
    static func unlocked(by progress: [LittleWinProgress]) -> [FGThemeID] {
        #if DEBUG
        // `-FGUnlockAllThemes` on the launch arguments, to see every look
        // without earning it. Compiled out of release builds.
        if ProcessInfo.processInfo.arguments.contains("-FGUnlockAllThemes") { return allCases }
        #endif
        return allCases.filter { id in
            guard let win = id.unlockingWin else { return true }
            return progress.contains { $0.win == win && $0.isUnlocked }
        }
    }
}
