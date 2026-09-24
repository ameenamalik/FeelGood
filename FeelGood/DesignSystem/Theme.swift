//
//  Theme.swift
//  FeelGood
//
//  Which look the app is wearing, carried as a *trait* so that
//  `Color(light:dark:)` — a `UIColor` dynamic provider that can see nothing but
//  a `UITraitCollection` — can read it without any view passing it along.
//
//  Set it once at the root with `.environment(\.fgTheme, …)`. A subtree can
//  override its parent, which is how a theme preview can sit inside another
//  theme. Verified by `FGThemeTests`; see docs/PRD-themes.md §5 and §13.
//
//  Everything here is `nonisolated`. SwiftUI resolves colours on its rendering
//  thread, and a main-actor-isolated type reached from a colour provider traps
//  the process (see the note in Palette.swift).
//

import SwiftUI
import UIKit

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

// MARK: - The trait

nonisolated struct FGThemeTrait: UITraitDefinition {
    static let defaultValue: FGThemeID = .kiln
    /// Tells UIKit a change here can change how a dynamic colour resolves, so
    /// views that drew with the old theme are redrawn.
    static let affectsColorAppearance = true
    static let identifier = "com.feelgood.theme"
}

nonisolated extension UITraitCollection {
    var fgTheme: FGThemeID { self[FGThemeTrait.self] }
}

nonisolated extension UIMutableTraits {
    var fgTheme: FGThemeID {
        get { self[FGThemeTrait.self] }
        set { self[FGThemeTrait.self] = newValue }
    }
}

// MARK: - The bridge from SwiftUI

/// Carries the SwiftUI environment value into the trait collection, and the
/// trait back out. Without this a theme set in SwiftUI never reaches a
/// `UIColor` provider.
nonisolated struct FGThemeKey: UITraitBridgedEnvironmentKey {
    static let defaultValue: FGThemeID = .kiln

    static func read(from traitCollection: UITraitCollection) -> FGThemeID {
        traitCollection.fgTheme
    }

    static func write(to mutableTraits: inout UIMutableTraits, value: FGThemeID) {
        mutableTraits.fgTheme = value
    }
}

nonisolated extension EnvironmentValues {
    var fgTheme: FGThemeID {
        get { self[FGThemeKey.self] }
        set { self[FGThemeKey.self] = newValue }
    }
}

// MARK: - Applying a theme

/// Why this exists: setting only the SwiftUI environment reaches the screen
/// but not anything *presented* over it. A sheet or full-screen cover is its
/// own hosting controller, and it takes its trait from the UIKit hierarchy, not
/// from the SwiftUI environment of whatever presented it — so it silently kept
/// the default theme. Setting the trait on the window fixes that at the root:
/// every controller presented in the window inherits it. Found by running the
/// app with a loud test colour; the unit tests could not see it.
extension View {
    /// Put this once at the root. A subtree can still override with
    /// `.environment(\.fgTheme, …)`, which is how a theme preview works.
    func fgTheme(_ theme: FGThemeID) -> some View {
        environment(\.fgTheme, theme)
            .background(FGWindowThemeInstaller(theme: theme))
    }
}

private struct FGWindowThemeInstaller: UIViewRepresentable {
    let theme: FGThemeID

    func makeUIView(context: Context) -> InstallerView {
        let view = InstallerView()
        view.isUserInteractionEnabled = false
        view.theme = theme
        return view
    }

    func updateUIView(_ view: InstallerView, context: Context) {
        view.theme = theme
    }

    final class InstallerView: UIView {
        var theme: FGThemeID = .kiln { didSet { apply() } }

        override func didMoveToWindow() {
            super.didMoveToWindow()
            apply()
        }

        /// Leaving the window (for example back to onboarding) puts the window
        /// back to the default, so a theme never outlives the screens it was for.
        override func willMove(toWindow newWindow: UIWindow?) {
            super.willMove(toWindow: newWindow)
            if newWindow == nil, let window, window.traitCollection.fgTheme != FGThemeTrait.defaultValue {
                window.traitOverrides.fgTheme = FGThemeTrait.defaultValue
            }
        }

        private func apply() {
            // Compare against the resolved trait, not `traitOverrides`: reading
            // an override that was never set is an assertion failure in UIKit.
            guard let window, window.traitCollection.fgTheme != theme else { return }
            window.traitOverrides.fgTheme = theme
        }
    }
}
