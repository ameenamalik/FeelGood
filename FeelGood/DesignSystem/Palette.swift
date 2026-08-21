//
//  Palette.swift
//  FeelGood
//
//  Cloudy sky blue. Bright, but not loud: white cards on a soft grey page, ink
//  type, and lime/sky/pink used as small accents rather than as surfaces.
//
//  The accessibility rule that shapes every use below: all three accents are
//  light. Against ink they are 8.6:1 or better; against white they are 1.4–2.1:1.
//  So an accent is always a *fill behind ink text*, never a text colour and
//  never a fill behind white text. Where a colour has to carry text on a light
//  background, use the -Deep variants.
//
//  No red anywhere — red is the colour of being behind.
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
    // MARK: Surfaces

    /// The page. Soft grey, so white cards lift off it.
    static let bg = Color(light: 0xF7F8FA, dark: 0x101316)
    /// Cards and sheets.
    static let surface = Color(light: 0xFFFFFF, dark: 0x181C20)
    /// Hairlines. Carries the 3:1 boundary that the accents cannot.
    static let line = Color(light: 0xE4E7EB, dark: 0x262B31)

    // MARK: Type

    /// Primary type. 17.99:1 on white, 16.9:1 on the page.
    static let ink = Color(light: 0x14171A, dark: 0xF7F8FA)
    /// Secondary type. 6.5:1 on white — still comfortable at footnote sizes.
    static let inkMuted = Color(light: 0x565E6B, dark: 0xA8B0BC)

    // MARK: Accents — fills only, always behind ink text

    /// The one thing on the screen worth doing. 13.1:1 behind ink.
    static let lime = Color(light: 0xC7EA4E, dark: 0xC7EA4E)
    /// 8.6:1 behind ink.
    static let sky = Color(light: 0x5FBEE8, dark: 0x5FBEE8)
    /// 9.7:1 behind ink.
    static let pink = Color(light: 0xF0A9D0, dark: 0xF0A9D0)
    /// The soft middle of the cloud gradient.
    static let lavender = Color(light: 0xB9C9F2, dark: 0xB9C9F2)

    // MARK: Accents darkened enough to carry text or an icon on a light page

    /// 5.7:1 on white.
    static let skyDeep = Color(light: 0x0A6E9A, dark: 0x8FD3F2)
    /// 6.3:1 on white.
    static let limeDeep = Color(light: 0x4F6810, dark: 0xD7F07E)
    /// 7.6:1 on white.
    static let pinkDeep = Color(light: 0x8E2F68, dark: 0xF6C3DF)

    /// The cloud mark. Used once per screen at most, never as a background.
    static let cloud = LinearGradient(
        colors: [Color(light: 0xF0A9D0, dark: 0xF0A9D0), Color(light: 0x5FBEE8, dark: 0x5FBEE8)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

extension Course {
    /// Each course gets one accent, as a small tag. The tag is never the only
    /// way a course is identified — its name is written next to it.
    var accent: Color {
        switch self {
        case .main: FGColor.lime
        case .appetizer: FGColor.sky
        case .side: FGColor.lavender
        case .dessert: FGColor.pink
        case .special: FGColor.ink
        }
    }

    /// Ink on every accent; the page colour on the ink-filled one.
    var accentText: Color {
        self == .special ? FGColor.bg : FGColor.ink
    }
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
