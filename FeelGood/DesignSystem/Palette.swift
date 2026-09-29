//
//  Palette.swift
//  FeelGood
//
//  Kiln (light) and Moss (dark). Glazed ceramic on linen by day, a botanical
//  evening by night: the page is linen or deep moss, cards are glazes that
//  hold ink (or cream) type at 7:1 or better, and clay/gold/rose/sage stay
//  small accents. Values are from docs/PRD-themes.md §4.
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
    ///
    /// `overrides` restyles the token for a theme (see `FGThemeID`). A theme
    /// with no entry gets `light` / `dark`, so every existing call site keeps
    /// its exact colour until a theme says otherwise. The theme arrives as a
    /// trait, not a parameter, so no view has to pass it.
    init(light: UInt32, dark: UInt32, overrides: [FGThemeID: FGThemePair] = [:]) {
        self.init(uiColor: UIColor { traits in
            // Most tokens have no override, and this runs for every colour on
            // every draw, so skip the trait lookup for them.
            let pair = overrides.isEmpty
                ? FGThemePair(light: light, dark: dark)
                : (overrides[traits.fgTheme] ?? FGThemePair(light: light, dark: dark))
            return UIColor(hex: traits.userInterfaceStyle == .dark ? pair.dark : pair.light)
        })
    }
}

nonisolated enum FGColor {
    // MARK: Surfaces

    /// The page. Linen by day, deep moss by night.
    static let bg = Color(light: 0xF4EEE3, dark: 0x1D2922, overrides: [.indigo: FGThemePair(light: 0xECE8E1, dark: 0x131829)])
    /// Cards and sheets.
    static let surface = Color(light: 0xFBF6EC, dark: 0x2A3A31, overrides: [.indigo: FGThemePair(light: 0xFBF9F5, dark: 0x212948)])
    /// Decorative hairlines — chip outlines, the progress track. Nothing is
    /// identified by these alone, so they stay quiet at ~1.2:1.
    static let line = Color(light: 0xE3DACB, dark: 0x33453A, overrides: [.indigo: FGThemePair(light: 0xDDD8CE, dark: 0x2E3760)])

    /// The boundary of anything you can tap.
    ///
    /// A white tile on the page is 1.06:1, so the border *is* the control's
    /// edge — WCAG 1.4.11 wants 3:1 for that. These are the lightest warm
    /// greys that clear it against both the card fill and the page: 3.63:1
    /// and 3.42:1 in light; 4.6:1 and 3.7:1 in dark.
    static let lineStrong = Color(light: 0x8E857B, dark: 0x7A9484, overrides: [.indigo: FGThemePair(light: 0x858282, dark: 0x7480B0)])

    // MARK: Type

    /// Primary type. 14.0:1 on the page in light, 12.9:1 in dark.
    static let ink = Color(light: 0x2A1E18, dark: 0xF3EDE0, overrides: [.indigo: FGThemePair(light: 0x1F2233, dark: 0xEEF0F8)])
    /// Secondary type. 5.3:1 on the page in light, 8.6:1 in dark. Not for use on
    /// the glaze cards in light mode (3.5–4.1:1 there); use `ink` on those.
    static let inkMuted = Color(light: 0x6B6155, dark: 0xBCC6B8, overrides: [.indigo: FGThemePair(light: 0x555A73, dark: 0xB9BFD8)])

    /// The dark fill of a primary action — the chat recommendation's "Start"
    /// and `FGPrimaryButton` both read this, so they can't drift apart.
    /// Kiln plum in light mode and soft sage in dark mode, where a dark fill
    /// would disappear into the moss page.
    static let actionFill = Color(light: 0x4B2A3A, dark: 0xC6DAC4, overrides: [.indigo: FGThemePair(light: 0x2F3A5F, dark: 0xEFE6D2)])
    /// Label on `actionFill`.
    static let onActionFill = Color(light: 0xFBF3E8, dark: 0x2B1A1A, overrides: [.indigo: FGThemePair(light: 0xF5F1EA, dark: 0x1F2233)])

    /// Warm paper used by the secondary authentication choices. It stays
    /// light in both appearances so provider buttons retain a familiar,
    /// trustworthy hierarchy on the dark account screen.
    static let authChoiceFill = Color(light: 0xFFFFFF, dark: 0xF6EFE3)
    static let onAuthChoiceFill = Color(light: 0x2A1E18, dark: 0x2A1E18)

    /// A neutral, intentionally light answer card in either appearance. Its
    /// type uses `inkOnAccent`, so an unselected choice can recede beside a
    /// colored selection without turning into low-contrast dark-on-dark UI.
    static let neutralChoiceFill = Color(light: 0xF8F3EA, dark: 0xF3EDE0)

    /// Interactive controls whose fill must carry a white system affordance
    /// (for example, the thumb of a Toggle). Unlike the pastel accents below,
    /// this stays dark enough for that affordance in both appearances while
    /// still separating clearly from each page background.
    static let controlAccent = Color(light: 0x8B4218, dark: 0xAC5A30)

    // MARK: Accents — fills only, always behind ink text

    /// The one thing on the screen worth doing. 9.4:1 behind ink.
    static let clay = Color(light: 0xEAB79A, dark: 0xEAB79A)
    /// 10.5:1 behind ink.
    static let gold = Color(light: 0xE6CA89, dark: 0xE6CA89)
    /// 9.1:1 behind ink.
    static let rose = Color(light: 0xE8B0B9, dark: 0xE8B0B9)
    /// 10.2:1 behind ink. The soft middle of the cloud gradient.
    static let sage = Color(light: 0xB3D39C, dark: 0xB3D39C)
    /// 10.8:1 behind ink. Breeze sky / periwinkle for micro-breaks & appetizers.
    static let sky = Color(light: 0x98C7F0, dark: 0x98C7F0)

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
    /// 7.8:1 on white, 7.3:1 on the page.
    static let skyDeep = Color(light: 0x1B4B75, dark: 0xA8D4FF)

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
        Color(light: 0xF9DEE0, dark: 0x2E3A30, overrides: [.indigo: FGThemePair(light: 0xE4E8F6, dark: 0x1D2547)]),
        Color(light: 0xF7EFE4, dark: 0x223027, overrides: [.indigo: FGThemePair(light: 0xEDEBE6, dark: 0x161C33)]),
        Color(light: 0xF3E8CE, dark: 0x2A3324, overrides: [.indigo: FGThemePair(light: 0xEEE6D6, dark: 0x191F38)]),
    ])

    // MARK: Roles that used to be literals in feature files
    //
    // Every value below was lifted, unchanged, from a `Color(light:dark:)` call
    // in a view. Named by the job they do so a theme can restyle them without a
    // view being edited. Feature code must not spell a hex value.

    /// A recessed panel on the page: the assistant's chat bubble and the small
    /// tinted pills on the paywall.
    static let panel = Color(light: 0xEBE2D2, dark: 0x33453A, overrides: [.indigo: FGThemePair(light: 0xE2DED6, dark: 0x2B3457)])
    /// A panel one step above `panel`, for a small tappable control that sits
    /// on it (the new-chat button).
    static let panelRaised = Color(light: 0xEBE2D2, dark: 0x3A4D40, overrides: [.indigo: FGThemePair(light: 0xE2DED6, dark: 0x323C66)])
    /// The chat composer's text field.
    static let inputFill = Color(light: 0xEBE2D2, dark: 0x26352C, overrides: [.indigo: FGThemePair(light: 0xE2DED6, dark: 0x1B2240)])
    /// The open conversation's row in the chat history list.
    static let selectedRow = Color(light: 0xEFE6D6, dark: 0x33453A, overrides: [.indigo: FGThemePair(light: 0xE6E2DA, dark: 0x2B3457)])
    /// The assistant's reply inside the check-in, tinted sage.
    static let sagePanel = Color(light: 0xE6EEDD, dark: 0x26402F, overrides: [.indigo: FGThemePair(light: 0xE2EAE0, dark: 0x24392F)])

    /// The person's own chat bubble and the paywall's speech-bubble pills.
    static let userBubble = Color(light: 0x2A1E18, dark: 0x3E5145, overrides: [.indigo: FGThemePair(light: 0x2F3A5F, dark: 0x3A4675)])
    /// Type on a deep fill (`userBubble`, `sideBadge`). Does not flip with the
    /// appearance, because the fills underneath it are dark in both.
    static let onDeepFill = Color(light: 0xFFFFFF, dark: 0xFFFFFF)

    /// The chat send button.
    static let sendGradient = LinearGradient(
        colors: [Color(light: 0xFCCAB5, dark: 0x6E4032, overrides: [.indigo: FGThemePair(light: 0x2F3A5F, dark: 0xEFE6D2)]), Color(light: 0xF5B2A3, dark: 0x5C2E24, overrides: [.indigo: FGThemePair(light: 0x2F3A5F, dark: 0xEFE6D2)])],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    /// The arrow on `sendGradient`.
    static let onSend = Color(light: 0x37241D, dark: 0xFCEFEA, overrides: [.indigo: FGThemePair(light: 0xF5F1EA, dark: 0x1F2233)])

    /// The saturated end of the Side course's sage: a pill that leads instead
    /// of receding into the card. White type on it clears 4.5:1.
    static let sideBadge = Color(light: 0x3F6B26, dark: 0x4C7A2E)

    /// The check-in banner: the one bold block on Today. Deep plum with cream
    /// type in Kiln; soft sage with ink type in Moss, where a dark block would
    /// vanish. Sage rather than blush because the peach mascot disappeared on
    /// blush. Flat (two equal stops) so it stays a `LinearGradient` for callers.
    static let bannerFill = Color(light: 0x4B2A3A, dark: 0xC6DAC4, overrides: [.indigo: FGThemePair(light: 0x2F3A5F, dark: 0xEFE6D2)])
    static let bannerGradient = LinearGradient(
        colors: [bannerFill, bannerFill],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    /// Type on the banner. 11.3:1 on plum, 11.2:1 on sage.
    static let onBanner = Color(light: 0xFBF3E8, dark: 0x2B1A1A, overrides: [.indigo: FGThemePair(light: 0xF5F1EA, dark: 0x1F2233)])
    /// The soft glow behind the banner's mascots.
    static let bannerGlow = Color(light: 0xFFE8CD, dark: 0xFFFFFF, overrides: [.indigo: FGThemePair(light: 0xD5D9EA, dark: 0xFFFFFF)])

    /// The outline of the tab bar. Ink in light; a lifted moss in dark (4.6:1 on the page, 3.7:1 on the bar), where
    /// ink would be near-white and too loud around a bar. 3:1 or better on the page.
    static let tabBarEdge = Color(light: 0x2A1E18, dark: 0x7A9484, overrides: [.indigo: FGThemePair(light: 0x1F2233, dark: 0x7480B0)])

    /// The round plate a mascot sits on, so its colour never depends on the
    /// card behind it (the orange fruit vanished into the peach card).
    static let plate = Color(light: 0xFBF6EC, dark: 0xF3EDE0, overrides: [.indigo: FGThemePair(light: 0xFBF9F5, dark: 0xF3EDE0)])

    /// The stand-in for the app icon while it loads. Fixed: it imitates an
    /// artwork, not a surface.
    static let appIconFallback = Color(light: 0x0D0C15, dark: 0x0D0C15)
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
    case apricot, lilac, blush, sage, butter, sky

    /// Stable name for handing an aura across a process boundary (the widget).
    var key: String {
        switch self {
        case .apricot: "apricot"
        case .lilac: "lilac"
        case .blush: "blush"
        case .sage: "sage"
        case .butter: "butter"
        case .sky: "sky"
        }
    }


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
        case .butter: Color(light: 0xFFF8D8, dark: 0xFFF8D8)
        case .sky: Color(light: 0xE2F1F7, dark: 0xE2F1F7)
        }
    }

    var mid: Color {
        switch self {
        case .apricot: Color(light: 0xF7C8A8, dark: 0xF7C8A8)
        case .lilac: Color(light: 0xE2CAD6, dark: 0xE2CAD6)
        case .blush: Color(light: 0xF2C4D3, dark: 0xF2C4D3)
        case .sage: Color(light: 0xC6D8BE, dark: 0xC6D8BE)
        case .butter: Color(light: 0xF4DF91, dark: 0xF4DF91)
        case .sky: Color(light: 0xBEDCE8, dark: 0xBEDCE8)
        }
    }

    var edge: Color {
        switch self {
        case .apricot: Color(light: 0xF0B090, dark: 0xF0B090)
        case .lilac: Color(light: 0xD7B7C7, dark: 0xD7B7C7)
        case .blush: Color(light: 0xE0AEC2, dark: 0xE0AEC2)
        case .sage: Color(light: 0xB2C8AF, dark: 0xB2C8AF)
        case .butter: Color(light: 0xE8CC69, dark: 0xE8CC69)
        case .sky: Color(light: 0x9CC8D9, dark: 0x9CC8D9)
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
        case .zeroMinutes, .fifteenMinutes, .thirtyFiveMinutes: .lilac
        case .fiveMinutes, .twentyFiveMinutes, .fortyFiveMinutes: .sage
        case .aLittle, .some, .fiftyMinutes: .apricot
        case .twentyMinutes, .fortyMinutes, .plenty: .blush
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

// MARK: - One colour per goal

nonisolated extension Intent {
    /// Shared by onboarding and the check-in, so a goal keeps its colour from
    /// the day it was chosen. Play and Calm used to share blush; they sit on
    /// the same screen, so Play moved to sky.
    var aura: FGAura {
        switch self {
        case .energize: .apricot
        case .strengthen: .lilac
        case .calm: .blush
        case .mobilize: .sage
        case .joy: .butter
        case .play: .sky
        }
    }
}

// MARK: - Session completion, one colour per activity family

nonisolated extension Activity {
    /// The completion screen's glow, grouped by the `Intent` an activity most
    /// often serves — the same aura-per-intent association already used for
    /// onboarding's intent tiles, so finishing a yoga flow and having chosen
    /// "Mobility" during onboarding land on the same sage. `nil` for
    /// activities with no single clear family (see `completionHeadline`) —
    /// those keep the screen's plain, untinted glow rather than being forced
    /// into a family that doesn't really fit.
    var completionAura: FGAura? {
        switch self {
        case .yoga, .stretching, .pilates: .sage // mobilize
        case .qigong, .breathwork: .blush // calm
        case .strength: .lilac // strengthen
        case .walking, .running, .biking, .swimming, .jumpRope: .apricot // energize
        case .dance: .butter // joy / play
        case .agility, .carries, .racquet, .climbing, .martialArts, .skating: nil
        }
    }

    /// "Done." reads fine once there's a colour story backing it up. Without
    /// one, it's worth saying the plainer, warmer thing instead.
    var completionHeadline: String {
        completionAura == nil ? "Still good." : "Done."
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
        case .main: FGColor.gold
        case .appetizer: FGColor.clay
        case .side: FGColor.sage
        case .dessert: FGColor.rose
        case .special: FGColor.ink
        }
    }

    /// The same accent as a raw value, for the widget snapshot. Kept beside
    /// `accent` so the two cannot drift apart unnoticed.
    var accentHex: UInt32 {
        switch self {
        case .main: 0xF3C89B
        case .appetizer: 0xF5B4AB
        case .side: 0xACC5AA
        case .dessert: 0xE6B2BE
        // The widget renders this raw value as a fixed pastel badge in both
        // appearances, so keep it light enough for `inkOnAccent` to remain
        // readable in dark mode too.
        case .special: 0xD8D2C7
        }
    }

    /// Text used directly on course gradients. The gradients become deep in
    /// dark mode, so this must flip from dark ink to light ink with them.
    var accentText: Color {
        FGColor.ink
    }

    /// The course's glaze, as a flat colour. Kiln glazes by day, Moss glazes by
    /// night; ink (or cream) type on each clears 7.7:1. Indigo drops the glaze
    /// for paper (dark: ink cloth) and moves the colour to the chip and plate.
    var fill: Color {
        switch self {
        case .appetizer: Color(light: 0xF0C9A8, dark: 0x5A3A32, overrides: [.indigo: FGThemePair(light: 0xFBF9F5, dark: 0x212948)])
        case .main: Color(light: 0xE9D392, dark: 0x4F4A25, overrides: [.indigo: FGThemePair(light: 0xFBF9F5, dark: 0x212948)])
        case .side: Color(light: 0xBBD0B6, dark: 0x2F4A3C, overrides: [.indigo: FGThemePair(light: 0xFBF9F5, dark: 0x212948)])
        case .dessert: Color(light: 0xE3B9C4, dark: 0x5B3446, overrides: [.indigo: FGThemePair(light: 0xFBF9F5, dark: 0x212948)])
        case .special: Color(light: 0xD9CFBE, dark: 0x3A3A34, overrides: [.indigo: FGThemePair(light: 0xFBF9F5, dark: 0x212948)])
        }
    }

    /// The card's edge. At least 3:1 against the page in both appearances, so a
    /// tappable card has a visible boundary (WCAG 1.4.11).
    var edge: Color {
        switch self {
        case .appetizer: Color(light: 0xA47F61, dark: 0x91685A, overrides: [.indigo: FGThemePair(light: 0x858282, dark: 0x5C6694)])
        case .main: Color(light: 0x9C8543, dark: 0x7C7538, overrides: [.indigo: FGThemePair(light: 0x858282, dark: 0x5C6694)])
        case .side: Color(light: 0x768C6F, dark: 0x517B66, overrides: [.indigo: FGThemePair(light: 0x858282, dark: 0x5C6694)])
        case .dessert: Color(light: 0xA97A87, dark: 0x94647B, overrides: [.indigo: FGThemePair(light: 0x858282, dark: 0x5C6694)])
        case .special: Color(light: 0x8F8676, dark: 0x7B7A6C, overrides: [.indigo: FGThemePair(light: 0x858282, dark: 0x5C6694)])
        }
    }

    /// `fill` as the two-stop gradient existing call sites expect. Flat on
    /// purpose: the glaze is one colour, and edge and plate do the rest.
    var accentGradient: LinearGradient {
        LinearGradient(colors: [fill, fill], startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    /// The round plate the course's mascot sits on. The same cream in Kiln and
    /// Moss; in Indigo it carries the course's colour, since the card does not.
    var plate: Color {
        switch self {
        case .appetizer: Color(light: 0xFBF6EC, dark: 0xF3EDE0, overrides: [.indigo: FGThemePair(light: 0xF6D3B8, dark: 0xF6D3B8)])
        case .main: Color(light: 0xFBF6EC, dark: 0xF3EDE0, overrides: [.indigo: FGThemePair(light: 0xEFDDA0, dark: 0xEFDDA0)])
        case .side: Color(light: 0xFBF6EC, dark: 0xF3EDE0, overrides: [.indigo: FGThemePair(light: 0xCBDCC6, dark: 0xCBDCC6)])
        case .dessert: Color(light: 0xFBF6EC, dark: 0xF3EDE0, overrides: [.indigo: FGThemePair(light: 0xF0CBD3, dark: 0xF0CBD3)])
        case .special: Color(light: 0xFBF6EC, dark: 0xF3EDE0, overrides: [.indigo: FGThemePair(light: 0xE2DED6, dark: 0xD8D2C7)])
        }
    }

    /// The label pill on a Today card ("APPETIZER"). Cream with ink type in
    /// Kiln and Moss; a tint of the course's own colour in Indigo.
    var chipFill: Color {
        switch self {
        case .appetizer: Color(light: 0xFBF6EC, dark: 0xF3EDE0, overrides: [.indigo: FGThemePair(light: 0xF6D3B8, dark: 0x5A3520)])
        case .main: Color(light: 0xFBF6EC, dark: 0xF3EDE0, overrides: [.indigo: FGThemePair(light: 0xEFDDA0, dark: 0x4F4210)])
        case .side: Color(light: 0xFBF6EC, dark: 0xF3EDE0, overrides: [.indigo: FGThemePair(light: 0xCBDCC6, dark: 0x24463A)])
        case .dessert: Color(light: 0xFBF6EC, dark: 0xF3EDE0, overrides: [.indigo: FGThemePair(light: 0xF0CBD3, dark: 0x5E2A44)])
        case .special: Color(light: 0xFBF6EC, dark: 0xF3EDE0, overrides: [.indigo: FGThemePair(light: 0xE2DED6, dark: 0x33395A)])
        }
    }

    /// Type on `chipFill`.
    var chipText: Color {
        switch self {
        case .appetizer: Color(light: 0x2A1E18, dark: 0x2B1A1A, overrides: [.indigo: FGThemePair(light: 0x5E2E0E, dark: 0xF6D3B8)])
        case .main: Color(light: 0x2A1E18, dark: 0x2B1A1A, overrides: [.indigo: FGThemePair(light: 0x4F3A00, dark: 0xEFDDA0)])
        case .side: Color(light: 0x2A1E18, dark: 0x2B1A1A, overrides: [.indigo: FGThemePair(light: 0x1E3B2B, dark: 0xCBDCC6)])
        case .dessert: Color(light: 0x2A1E18, dark: 0x2B1A1A, overrides: [.indigo: FGThemePair(light: 0x5E1F3A, dark: 0xF0CBD3)])
        case .special: Color(light: 0x2A1E18, dark: 0x2B1A1A, overrides: [.indigo: FGThemePair(light: 0x1F2233, dark: 0xEEF0F8)])
        }
    }

    /// The course tag as a soft pill: cream on the light glazes, a darker tint
    /// of the glaze on the dark ones (where `tagText` is the light Deep variant).
    /// Indigo uses the same tint as `chipFill`.
    var tagFill: Color {
        switch self {
        case .appetizer: Color(light: 0xFBF6EC, dark: 0x382018, overrides: [.indigo: FGThemePair(light: 0xF6D3B8, dark: 0x5A3520)])
        case .main: Color(light: 0xFBF6EC, dark: 0x332812, overrides: [.indigo: FGThemePair(light: 0xEFDDA0, dark: 0x4F4210)])
        case .side: Color(light: 0xFBF6EC, dark: 0x1E2B1C, overrides: [.indigo: FGThemePair(light: 0xCBDCC6, dark: 0x24463A)])
        case .dessert: Color(light: 0xFBF6EC, dark: 0x331A24, overrides: [.indigo: FGThemePair(light: 0xF0CBD3, dark: 0x5E2A44)])
        case .special: FGColor.line
        }
    }

    var tagText: Color {
        switch self {
        case .appetizer: Color(light: 0x8B4218, dark: 0xEACAB8, overrides: [.indigo: FGThemePair(light: 0x5E2E0E, dark: 0xF6D3B8)])
        case .main: Color(light: 0x745611, dark: 0xE8D7B0, overrides: [.indigo: FGThemePair(light: 0x4F3A00, dark: 0xEFDDA0)])
        case .side: Color(light: 0x395922, dark: 0xCEE1C1, overrides: [.indigo: FGThemePair(light: 0x1E3B2B, dark: 0xCBDCC6)])
        case .dessert: Color(light: 0x772230, dark: 0xE9C4CA, overrides: [.indigo: FGThemePair(light: 0x5E1F3A, dark: 0xF0CBD3)])
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
