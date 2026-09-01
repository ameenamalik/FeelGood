//
//  Palette.swift
//  FeelGood
//
//  Clay studio. Warm terracotta and botanical sage on a near-white page: white
//  cards lift off warm cream, ink type, and clay/gold/rose/sage used as small
//  accents rather than as surfaces.
//
//  The accessibility rule that shapes every use below: all four accents are
//  light. Against ink they are 9.0:1 or better; against white they are
//  1.5–1.9:1. So an accent is always a *fill behind ink text*, never a text
//  colour and never a fill behind white text. Where a colour has to carry
//  text on a light background, use the -Deep variants.
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

    /// The page. Warm near-white, so white cards still lift off it.
    static let bg = Color(light: 0xFAF8F5, dark: 0x14100D)
    /// Cards and sheets.
    static let surface = Color(light: 0xFFFFFF, dark: 0x1C1712)
    /// Decorative hairlines — chip outlines, the progress track. Nothing is
    /// identified by these alone, so they stay quiet at ~1.2:1.
    static let line = Color(light: 0xF0ECE5, dark: 0x2A241E)

    /// The boundary of anything you can tap.
    ///
    /// A white tile on the page is 1.06:1, so the border *is* the control's
    /// edge — WCAG 1.4.11 wants 3:1 for that. These are the lightest warm
    /// greys that clear it against both the card fill and the page: 3.63:1
    /// and 3.42:1 in light, 3.02:1 and 3.21:1 in dark.
    static let lineStrong = Color(light: 0x8E857B, dark: 0x6B635B)

    // MARK: Type

    /// Primary type. 16.8:1 on white, 15.8:1 on the page.
    static let ink = Color(light: 0x241C15, dark: 0xF7F3EC)
    /// Secondary type. 6.1:1 on white — still comfortable at footnote sizes.
    static let inkMuted = Color(light: 0x6B6155, dark: 0xB8AC9C)

    // MARK: Accents — fills only, always behind ink text

    /// The one thing on the screen worth doing. 9.4:1 behind ink.
    static let clay = Color(light: 0xEAB79A, dark: 0xEAB79A)
    /// 10.5:1 behind ink.
    static let gold = Color(light: 0xE6CA89, dark: 0xE6CA89)
    /// 9.1:1 behind ink.
    static let rose = Color(light: 0xE8B0B9, dark: 0xE8B0B9)
    /// 10.2:1 behind ink. The soft middle of the cloud gradient.
    static let sage = Color(light: 0xB3D39C, dark: 0xB3D39C)

    /// Type sitting *on* one of the accents above.
    ///
    /// Not `ink`. The accents are the same colour in both appearances, but
    /// `ink` flips to near-white in the dark — so `ink` on `clay` silently
    /// becomes white-on-clay at night, which is the one thing the rule at the
    /// top of this file forbids. This one does not flip, because the surface
    /// underneath it doesn't either.
    static let inkOnAccent = Color(light: 0x241C15, dark: 0x241C15)

    // MARK: Accents darkened enough to carry text or an icon on a light page

    /// 7.3:1 on white, 6.9:1 on the page.
    static let clayDeep = Color(light: 0x8B4218, dark: 0xEACAB8)
    /// 6.8:1 on white, 6.4:1 on the page.
    static let goldDeep = Color(light: 0x745611, dark: 0xE8D7B0)
    /// 8.0:1 on white, 7.5:1 on the page.
    static let sageDeep = Color(light: 0x395922, dark: 0xCEE1C1)
    /// 10.2:1 on white, 9.6:1 on the page.
    static let roseDeep = Color(light: 0x772230, dark: 0xE9C4CA)

    /// The cloud mark. Used once per screen at most, never as a background.
    static let cloud = LinearGradient(
        colors: [Color(light: 0xE8B0B9, dark: 0xE8B0B9), Color(light: 0xE6CA89, dark: 0xE6CA89)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// The wash's colours — see `FGBrandWash`, which blooms them out from the
    /// bottom of the screen. Warm at the core, warm at the edge — clay studio
    /// doesn't have a cool colour to route around, so this stays in-family
    /// rather than needing a routed middle stop.
    ///
    /// Unlike the accents, these *do* change with the appearance, and they have
    /// to. A wash is a background, so `ink` is drawn over it; if the wash
    /// stayed pastel at night, `ink` would have flipped to near-white and the
    /// result would be white-on-rose. Light pastels, dark jewel tones, `ink`
    /// legible on both.
    ///
    /// A bare `Gradient` rather than a `RadialGradient` because the radius has
    /// to come from the frame it is drawn into, not from a constant here.
    /// Rose at the core, warm cream in the middle, gold at the edge.
    ///
    /// The light values are pale on purpose. `inkMuted` captions sit on this
    /// wash, and at full saturation they measured under the 4.5:1 floor before
    /// the grain was even counted. These clear it with the grain's darkest
    /// trough included: 4.78:1 at the core, 5.31:1 at the middle, 4.98:1 at
    /// the edge.
    static let washGradient = Gradient(colors: [
        Color(light: 0xF9DEE0, dark: 0x3A2226),
        Color(light: 0xF7EFE4, dark: 0x241E17),
        Color(light: 0xF3E8CE, dark: 0x332A14),
    ])
}

/// A selectable answer's colour: the fill, and the only text colour that
/// survives on it. Pairing them here means a call site cannot put white type on
/// a pastel by accident — the rule from the top of this file, made structural.
nonisolated struct FGAccent: Equatable {
    let fill: Color
    let text: Color

    static let ink  = FGAccent(fill: FGColor.ink,  text: FGColor.bg)
    static let gold = FGAccent(fill: FGColor.gold, text: FGColor.goldDeep)
    static let clay = FGAccent(fill: FGColor.clay, text: FGColor.clayDeep)
    static let sage = FGAccent(fill: FGColor.sage, text: FGColor.sageDeep)
    static let rose = FGAccent(fill: FGColor.rose, text: FGColor.roseDeep)
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
/// purpose. `inkOnAccent` clears 8:1 or better on every edge value below,
/// which is the darkest point any of them reaches.
///
/// Case names are colour words, not roles — `lilac` keeps its name here even
/// though its hue moved warmer (toward a dusty mauve) to stay in the clay
/// studio family. Nothing outside this file reads meaning into which case is
/// which; see the spread rule below.
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
            Color(light: 0xF6F1E9, dark: 0x1F1912),
            Color(light: 0xEFE7DB, dark: 0x1B160F),
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    var core: Color {
        switch self {
        case .apricot: Color(light: 0xFCE3D2, dark: 0xFCE3D2)
        case .lilac: Color(light: 0xF1E4EB, dark: 0xF1E4EB)
        case .blush: Color(light: 0xFCE2E8, dark: 0xFCE2E8)
        case .sage: Color(light: 0xEAF0DE, dark: 0xEAF0DE)
        }
    }

    var mid: Color {
        switch self {
        case .apricot: Color(light: 0xF7C8A8, dark: 0xF7C8A8)
        case .lilac: Color(light: 0xE2CAD6, dark: 0xE2CAD6)
        case .blush: Color(light: 0xF2C4D3, dark: 0xF2C4D3)
        case .sage: Color(light: 0xC6D8BE, dark: 0xC6D8BE)
        }
    }

    var edge: Color {
        switch self {
        case .apricot: Color(light: 0xF0B090, dark: 0xF0B090)
        case .lilac: Color(light: 0xD7B7C7, dark: 0xD7B7C7)
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
    var checkInAccent: FGAccent { .gold }

    var checkInAura: FGAura {
        switch self {
        case .low: .lilac
        case .steady: .sage
        case .strong: .apricot
        }
    }
}

nonisolated extension TimeBudget {
    var checkInAccent: FGAccent { .clay }

    var checkInAura: FGAura {
        switch self {
        case .fiveMinutes, .aLittle: .sage
        case .fifteenMinutes, .twentyMinutes, .twentyFiveMinutes, .some: .apricot
        case .thirtyFiveMinutes, .fortyMinutes, .plenty: .lilac
        }
    }
}

nonisolated extension PlaceIntent {
    var checkInAccent: FGAccent { .sage }

    var checkInAura: FGAura {
        switch self {
        case .stayingIn: .lilac
        case .happyToGoOut: .sage
        case .atTheGym: .blush
        }
    }
}

nonisolated extension BodyState {
    var checkInAccent: FGAccent { .rose }

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
        case .main: FGColor.clay
        case .appetizer: FGColor.gold
        case .side: FGColor.sage
        case .dessert: FGColor.rose
        case .special: FGColor.ink
        }
    }

    /// The same accent as a raw value, for the widget snapshot. Kept beside
    /// `accent` so the two cannot drift apart unnoticed.
    var accentHex: UInt32 {
        switch self {
        case .main: 0xEAB79A
        case .appetizer: 0xE6CA89
        case .side: 0xB3D39C
        case .dessert: 0xE8B0B9
        case .special: 0x241C15
        }
    }

    /// Ink on every accent; the page colour on the ink-filled one. `.special`
    /// is the exception that keeps `bg`, because its fill flips with the
    /// appearance and so must its text.
    var accentText: Color {
        self == .special ? FGColor.bg : FGColor.inkOnAccent
    }

    /// `accent`, deepened toward its own hue rather than toward `-Deep` —
    /// `-Deep` is calibrated to carry *text*, dark enough that `inkOnAccent`
    /// on top of it would fail contrast. This stays light enough that ink
    /// stays readable across the whole gradient, verified at its darkest
    /// point: 6.4:1 (clay), 8.2:1 (gold/appetizer), 5.6:1 (rose/dessert),
    /// 7.7:1 (sage/side).
    var accentGradient: LinearGradient {
        let dark: Color
        switch self {
        case .main: dark = Color(light: 0xDD8D5F, dark: 0xDD8D5F)
        case .appetizer: dark = Color(light: 0xDAB04E, dark: 0xDAB04E)
        case .side: dark = Color(light: 0x8DBD6B, dark: 0x8DBD6B)
        case .dessert: dark = Color(light: 0xD87989, dark: 0xD87989)
        case .special: dark = FGColor.ink
        }
        return LinearGradient(colors: [accent, dark], startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    /// The course tag as a soft pill rather than a saturated capsule.
    ///
    /// `accent` is a full-strength fill that needs `inkOnAccent` on top and
    /// shouts on a white card next to three siblings. These are the same hues
    /// held right back, carrying the -Deep variant as text — quiet enough that
    /// four of them down a menu read as labels rather than as stickers.
    ///
    /// Unlike `accent`, these flip: the tint has to stay behind the -Deep
    /// colour, and that colour lightens at night. Every fill/text pair below
    /// clears 6:1 or better.
    var tagFill: Color {
        switch self {
        case .appetizer: Color(light: 0xFAF1DA, dark: 0x332812)
        case .main: Color(light: 0xFBE9DD, dark: 0x3A2415)
        case .side: Color(light: 0xE7F0DD, dark: 0x22301A)
        case .dessert: Color(light: 0xFAE5E8, dark: 0x33161C)
        case .special: FGColor.line
        }
    }

    var tagText: Color {
        switch self {
        case .appetizer: FGColor.goldDeep
        case .main: FGColor.clayDeep
        case .side: FGColor.sageDeep
        case .dessert: FGColor.roseDeep
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
