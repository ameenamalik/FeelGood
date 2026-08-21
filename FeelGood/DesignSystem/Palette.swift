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

nonisolated extension Color {
    /// Resolves per appearance so every token works in both modes.
    ///
    /// This must stay `nonisolated`. The project defaults to MainActor
    /// isolation, but SwiftUI resolves colours on a background rendering
    /// thread — a main-actor-isolated provider closure trips the executor
    /// assert and traps the process the first time a colour is drawn.
    init(light: UInt32, dark: UInt32) {
        self.init(uiColor: UIColor { traits in
            UIColor(hex: traits.userInterfaceStyle == .dark ? dark : light)
        })
    }
}

nonisolated enum FGColor {
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

    /// Type sitting *on* one of the accents above.
    ///
    /// Not `ink`. The accents are the same colour in both appearances, but
    /// `ink` flips to near-white in the dark — so `ink` on `lime` silently
    /// becomes white-on-lime at night, which is the one thing the rule at the
    /// top of this file forbids. This one does not flip, because the surface
    /// underneath it doesn't either.
    static let inkOnAccent = Color(light: 0x14171A, dark: 0x14171A)

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

    /// The wash's colours — see `FGBrandWash`, which blooms them out from the
    /// bottom of the screen. Warm at the core, cool at the edge.
    ///
    /// Unlike the accents, these *do* change with the appearance, and they have
    /// to. A wash is a background, so `ink` is drawn over it; if the wash
    /// stayed pastel at night, `ink` would have flipped to near-white and the
    /// result would be white-on-pink. Light pastels, dark jewel tones, `ink`
    /// legible on both.
    ///
    /// A bare `Gradient` rather than a `RadialGradient` because the radius has
    /// to come from the frame it is drawn into, not from a constant here.
    /// Rose at the core, a warm near-neutral in the middle, sky at the edge.
    /// The middle stop is what keeps this out of purple: interpolating pink
    /// straight to blue runs through lavender, so the ramp is routed around it.
    ///
    /// The light values are pale on purpose. `inkMuted` captions sit on this
    /// wash, and at full saturation they measured 4.3:1 — under the 4.5:1 floor
    /// before the grain was even counted. These clear it with the grain's
    /// darkest trough included.
    static let washGradient = Gradient(colors: [
        Color(light: 0xFBDDE5, dark: 0x3D2530),
        Color(light: 0xF9EAE2, dark: 0x2B2A31),
        Color(light: 0xCFE8F7, dark: 0x11293A),
    ])
}

/// A selectable answer's colour: the fill, and the only text colour that
/// survives on it. Pairing them here means a call site cannot put white type on
/// a pastel by accident — the rule from the top of this file, made structural.
nonisolated struct FGAccent: Equatable {
    let fill: Color
    let text: Color

    static let ink      = FGAccent(fill: FGColor.ink,      text: FGColor.bg)
    static let sky      = FGAccent(fill: FGColor.sky,      text: FGColor.inkOnAccent)
    static let lime     = FGAccent(fill: FGColor.lime,     text: FGColor.inkOnAccent)
    static let lavender = FGAccent(fill: FGColor.lavender, text: FGColor.inkOnAccent)
    static let pink     = FGAccent(fill: FGColor.pink,     text: FGColor.inkOnAccent)
}

// MARK: The check-in's four questions, one colour each

// Four colours rather than one so the sheet reads as four short moments
// instead of one long form. The colour is never the only thing distinguishing
// a selected answer — see `FGChoice`, which also thickens the border.

nonisolated extension Energy {
    var checkInAccent: FGAccent { .sky }
}

nonisolated extension TimeBudget {
    var checkInAccent: FGAccent { .lime }
}

nonisolated extension PlaceIntent {
    var checkInAccent: FGAccent { .lavender }
}

nonisolated extension BodyState {
    var checkInAccent: FGAccent { .pink }
}

nonisolated extension Course {
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

    /// Ink on every accent; the page colour on the ink-filled one. `.special`
    /// is the exception that keeps `bg`, because its fill flips with the
    /// appearance and so must its text.
    var accentText: Color {
        self == .special ? FGColor.bg : FGColor.inkOnAccent
    }
}

nonisolated private extension UIColor {
    convenience init(hex: UInt32) {
        self.init(
            red: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: 1
        )
    }
}
