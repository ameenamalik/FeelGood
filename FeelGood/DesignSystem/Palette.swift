//
//  Palette.swift
//  FeelGood
//
//  Warm, muted, unhurried — closer to a printed cookbook than a fitness
//  tracker. No neon, no performance tropes, and no red: red is the colour of
//  being behind, and this app has no language for that. See PRD §9.
//

import SwiftUI

extension Color {
    /// Resolves per appearance so every token works in both modes.
    init(light: UInt32, dark: UInt32) {
        self.init(uiColor: UIColor { traits in
            UIColor(hex: traits.userInterfaceStyle == .dark ? dark : light)
        })
    }
}

enum FGColor {
    /// Page background. Warm cream, never pure white.
    static let cream = Color(light: 0xFAF6EF, dark: 0x171613)
    /// Raised surfaces — menu cards, sheets.
    static let oat = Color(light: 0xF2EBDF, dark: 0x211F1B)
    /// Primary type. Deep warm ink, never pure black.
    static let ink = Color(light: 0x2B2A26, dark: 0xF3EEE5)
    /// Secondary type. Holds 4.5:1 against cream and oat.
    static let inkMuted = Color(light: 0x63605A, dark: 0xADA79C)
    /// The quiet green the whole thing sits in.
    static let sage = Color(light: 0x7C8C6C, dark: 0xA3B294)
    /// Accent for the one thing that matters on a screen.
    static let clay = Color(light: 0xB2664F, dark: 0xD98F76)
    /// Hairlines and dividers.
    static let line = Color(light: 0xE2D9C9, dark: 0x322F29)
}

private extension UIColor {
    convenience init(hex: UInt32) {
        self.init(
            red: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: 1
        )
    }
}
