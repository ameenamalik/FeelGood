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
    /// Decorative hairlines — chip outlines, the progress track. Nothing is
    /// identified by these alone, so they stay quiet at ~1.2:1.
    static let line = Color(light: 0xE4E7EB, dark: 0x262B31)

    /// The boundary of anything you can tap.
    ///
    /// A white tile on the page is 1.06:1, so the border *is* the control's
    /// edge — WCAG 1.4.11 wants 3:1 for that. These are the lightest greys that
    /// clear it against both the card fill and the page, so the outline is as
    /// quiet as it is allowed to be: 3.20:1 and 3.01:1 in light, 3.01:1 and
    /// 3.28:1 in dark.
    static let lineStrong = Color(light: 0x8D9095, dark: 0x63676D)

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
    static let skyDeep = Color(light: 0x075173, dark: 0x8FD3F2)
    /// 6.3:1 on white.
    static let limeDeep = Color(light: 0x344707, dark: 0xD7F07E)
    /// 6.1:1 on white.
    static let lavenderDeep = Color(light: 0x314477, dark: 0xD7DEFA)
    /// 7.6:1 on white.
    static let pinkDeep = Color(light: 0x6E1F4D, dark: 0xF6C3DF)

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
    static let sky      = FGAccent(fill: FGColor.sky,      text: FGColor.skyDeep)
    static let lime     = FGAccent(fill: FGColor.lime,     text: FGColor.limeDeep)
    static let lavender = FGAccent(fill: FGColor.lavender, text: FGColor.lavenderDeep)
    static let pink     = FGAccent(fill: FGColor.pink,     text: FGColor.pinkDeep)
}

/// A soft three-stop wash for a check-in tile.
///
/// Separate from `FGAccent` because it fills the whole tile rather than tinting
/// it. An accent is a flat wash of colour laid over a white card at 30%; an aura
/// replaces the card. Both appear on selection — see `FGAuraTile`.
///
/// Like the accents and unlike `washGradient`, these do not flip with the
/// appearance: they are pale in both, and the type on them is `inkOnAccent`,
/// which does not flip either. A flipping aura under non-flipping type is the
/// white-on-pastel failure the top of this file rules out.
///
/// Stops run core → mid → edge, and stay the light side of their hue on
/// purpose. `inkOnAccent` measures 11.9:1 or better on every edge value below,
/// which is the darkest point any of them reaches.
nonisolated enum FGAura: Sendable, CaseIterable {
    case apricot, lilac, blush, sage


    /// What a tile looks like before it is picked: barely there.
    ///
    /// Straight off the artboard in light — a warm near-white only just
    /// separable from the page, so the picked tile is the one thing on screen
    /// carrying colour. Dark is the same idea, not the same values: a faint
    /// lift off `bg` rather than the slab the first attempt drew at this size.
    ///
    /// The one aura value that flips with the appearance, because it is a
    /// resting surface carrying `ink` rather than a wash carrying `inkOnAccent`.
    static let resting = LinearGradient(
        colors: [
            Color(light: 0xF6F1E9, dark: 0x171B1F),
            Color(light: 0xEFE7DB, dark: 0x14181C),
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    var core: Color {
        switch self {
        case .apricot: Color(light: 0xFFE0CC, dark: 0xFFE0CC)
        case .lilac: Color(light: 0xECE0F6, dark: 0xECE0F6)
        case .blush: Color(light: 0xFCE2E8, dark: 0xFCE2E8)
        case .sage: Color(light: 0xEAF0DE, dark: 0xEAF0DE)
        }
    }

    var mid: Color {
        switch self {
        case .apricot: Color(light: 0xF9B69C, dark: 0xF9B69C)
        case .lilac: Color(light: 0xD2D8F0, dark: 0xD2D8F0)
        case .blush: Color(light: 0xF2C4D3, dark: 0xF2C4D3)
        case .sage: Color(light: 0xC6D8BE, dark: 0xC6D8BE)
        }
    }

    var edge: Color {
        switch self {
        case .apricot: Color(light: 0xF5B2A8, dark: 0xF5B2A8)
        case .lilac: Color(light: 0xC4CEEE, dark: 0xC4CEEE)
        case .blush: Color(light: 0xE0AEC2, dark: 0xE0AEC2)
        case .sage: Color(light: 0xB2C8AF, dark: 0xB2C8AF)
        }
    }
}

// MARK: The check-in's four questions, one colour each

// Four colours rather than one so the sheet reads as four short moments
// instead of one long form. The colour is never the only thing distinguishing
// a selected answer — see `FGChoice`, which also thickens the border.
//
// `checkInAura` sits beside `checkInAccent` rather than replacing it: the
// accent is per *question*, the aura is per *answer*, so the tiles inside one
// question differ from each other. Which aura an answer gets carries no
// meaning — it is spread so no two neighbours repeat, nothing more. Nobody
// should be able to read their energy off the colour.

nonisolated extension Energy {
    var checkInAccent: FGAccent { .sky }

    var checkInAura: FGAura {
        switch self {
        case .low: .lilac
        case .steady: .sage
        case .strong: .apricot
        }
    }
}

nonisolated extension TimeBudget {
    var checkInAccent: FGAccent { .lime }

    var checkInAura: FGAura {
        switch self {
        case .aLittle: .sage
        case .some: .apricot
        case .plenty: .lilac
        }
    }
}

nonisolated extension PlaceIntent {
    var checkInAccent: FGAccent { .lavender }

    var checkInAura: FGAura {
        switch self {
        case .stayingIn: .lilac
        case .happyToGoOut: .sage
        case .atTheGym: .blush
        }
    }
}

nonisolated extension BodyState {
    var checkInAccent: FGAccent { .pink }

    var checkInAura: FGAura {
        switch self {
        case .sore: .blush
        case .stiff: .lilac
        case .stressed: .apricot
        case .cramping: .blush
        case .good: .sage
        }
    }
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

    /// The same accent as a raw value, for the widget snapshot. Kept beside
    /// `accent` so the two cannot drift apart unnoticed.
    var accentHex: UInt32 {
        switch self {
        case .main: 0xC7EA4E
        case .appetizer: 0x5FBEE8
        case .side: 0xB9C9F2
        case .dessert: 0xF0A9D0
        case .special: 0x14171A
        }
    }

    /// Ink on every accent; the page colour on the ink-filled one. `.special`
    /// is the exception that keeps `bg`, because its fill flips with the
    /// appearance and so must its text.
    var accentText: Color {
        self == .special ? FGColor.bg : FGColor.inkOnAccent
    }

    /// The course tag as a soft pill rather than a saturated capsule.
    ///
    /// `accent` is a full-strength fill that needs `inkOnAccent` on top and
    /// shouts on a white card next to three siblings. These are the same hues
    /// held right back, carrying the -Deep variant as text — quiet enough that
    /// four of them down a menu read as labels rather than as stickers.
    ///
    /// Unlike `accent`, these flip: the tint has to stay behind the -Deep
    /// colour, and that colour lightens at night.
    var tagFill: Color {
        switch self {
        case .appetizer: Color(light: 0xDFF0FA, dark: 0x0E2E3D)
        case .main: Color(light: 0xEDF8D2, dark: 0x22300A)
        case .side: Color(light: 0xE8EDFB, dark: 0x1B2440)
        case .dessert: Color(light: 0xFBE7F1, dark: 0x331127)
        case .special: FGColor.line
        }
    }

    var tagText: Color {
        switch self {
        case .appetizer: FGColor.skyDeep
        case .main: FGColor.limeDeep
        case .side: FGColor.lavenderDeep
        case .dessert: FGColor.pinkDeep
        case .special: FGColor.ink
        }
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
