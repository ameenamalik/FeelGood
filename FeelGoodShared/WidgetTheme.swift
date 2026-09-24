//
//  WidgetTheme.swift
//  FeelGood — shared by the app and the widget
//
//  The colours the widget's Plain look needs, per theme. The widget cannot
//  import the design system (it would cost the extension the whole app), so
//  these are restated here — but no longer on trust: `WidgetThemeTests` resolves
//  the real `FGColor` and `Course` tokens and fails if any value below drifts.
//
//  The Fruit look is not themed. It sits on the pastel the person chose for
//  their own fruit, and that choice is theirs, not the theme's.
//

import Foundation

nonisolated struct WidgetThemePalette: Sendable {
    /// The Plain card's background. `FGColor.surface`.
    let surface: FGThemePair
    /// Primary text. `FGColor.ink`.
    let ink: FGThemePair
    /// Secondary text. `FGColor.inkMuted`.
    let inkMuted: FGThemePair

    /// The course pill: the card's glaze with ink on it in Kiln and Moss; the
    /// course's own tint in Indigo. Matches the course card in the app.
    func pill(forCourseLabel label: String) -> (fill: FGThemePair, text: FGThemePair) {
        pills[Self.key(for: label)] ?? pills["special"]!
    }

    private let pills: [String: (fill: FGThemePair, text: FGThemePair)]

    private static func key(for label: String) -> String {
        switch label.lowercased() {
        case "appetizer", "main", "side", "dessert": label.lowercased()
        default: "special"
        }
    }

    static func palette(for theme: FGThemeID) -> WidgetThemePalette {
        switch theme {
        case .kiln: kiln
        case .indigo: indigo
        }
    }

    // Kiln by day, Moss by night.
    private static let kilnInk = FGThemePair(light: 0x2A1E18, dark: 0xF3EDE0)
    static let kiln = WidgetThemePalette(
        surface: FGThemePair(light: 0xFBF6EC, dark: 0x2A3A31),
        ink: kilnInk,
        inkMuted: FGThemePair(light: 0x6B6155, dark: 0xBCC6B8),
        pills: [
            "appetizer": (FGThemePair(light: 0xF0C9A8, dark: 0x5A3A32), kilnInk),
            "main": (FGThemePair(light: 0xE9D392, dark: 0x4F4A25), kilnInk),
            "side": (FGThemePair(light: 0xBBD0B6, dark: 0x2F4A3C), kilnInk),
            "dessert": (FGThemePair(light: 0xE3B9C4, dark: 0x5B3446), kilnInk),
            "special": (FGThemePair(light: 0xD9CFBE, dark: 0x3A3A34), kilnInk),
        ]
    )

    static let indigo = WidgetThemePalette(
        surface: FGThemePair(light: 0xFBF9F5, dark: 0x212948),
        ink: FGThemePair(light: 0x1F2233, dark: 0xEEF0F8),
        inkMuted: FGThemePair(light: 0x555A73, dark: 0xB9BFD8),
        pills: [
            "appetizer": (FGThemePair(light: 0xF6D3B8, dark: 0x5A3520), FGThemePair(light: 0x5E2E0E, dark: 0xF6D3B8)),
            "main": (FGThemePair(light: 0xEFDDA0, dark: 0x4F4210), FGThemePair(light: 0x4F3A00, dark: 0xEFDDA0)),
            "side": (FGThemePair(light: 0xCBDCC6, dark: 0x24463A), FGThemePair(light: 0x1E3B2B, dark: 0xCBDCC6)),
            "dessert": (FGThemePair(light: 0xF0CBD3, dark: 0x5E2A44), FGThemePair(light: 0x5E1F3A, dark: 0xF0CBD3)),
            "special": (FGThemePair(light: 0xE2DED6, dark: 0x33395A), FGThemePair(light: 0x1F2233, dark: 0xEEF0F8)),
        ]
    )
}
