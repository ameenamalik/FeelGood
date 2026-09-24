//
//  ThemeContrastTests.swift
//  FeelGoodTests
//
//  The contrast table in docs/PRD-themes.md §4 is arithmetic on hex values, and
//  arithmetic on a document rots. These resolve the real tokens, in both
//  appearances, and fail the build if a pair drops below its floor.
//
//  Floors: 4.5:1 for text, 3:1 for the boundary of anything you can tap
//  (WCAG 1.4.11). Every theme in both appearances. Known exceptions are written down here rather than skipped:
//  `inkMuted` on the light glaze cards is 3.5–4.1:1, so it is not asserted —
//  use `ink` on those.
//

import Testing
import SwiftUI
@testable import FeelGood

/// One look: a theme in one appearance. Every floor is checked for all of them.
private struct Look: CustomTestStringConvertible {
    let theme: FGThemeID
    let isDark: Bool
    var name: String { "\(theme.rawValue) \(isDark ? "dark" : "light")" }
    var testDescription: String { name }
    static let all: [Look] = FGThemeID.allCases.flatMap { [Look(theme: $0, isDark: false), Look(theme: $0, isDark: true)] }
}

private func luminance(_ color: Color, _ look: Look) -> Double {
    var env = EnvironmentValues()
    env.colorScheme = look.isDark ? .dark : .light
    env.fgTheme = look.theme
    let c = color.resolve(in: env)   // linear sRGB components
    return 0.2126 * Double(c.linearRed) + 0.7152 * Double(c.linearGreen) + 0.0722 * Double(c.linearBlue)
}

private func contrast(_ a: Color, _ b: Color, _ look: Look) -> Double {
    let (x, y) = (luminance(a, look), luminance(b, look))
    return (max(x, y) + 0.05) / (min(x, y) + 0.05)
}

private let courses: [Course] = [.appetizer, .main, .side, .dessert, .special]

@Suite("Theme contrast")
struct ThemeContrastTests {

    @Test("Ink and muted ink read on the page and on cards", arguments: Look.all)
    private func inkOnSurfaces(look: Look) {
        for (name, fg, bg) in [
            ("ink/bg", FGColor.ink, FGColor.bg),
            ("ink/surface", FGColor.ink, FGColor.surface),
            ("ink/panel", FGColor.ink, FGColor.panel),
            ("inkMuted/bg", FGColor.inkMuted, FGColor.bg),
            ("inkMuted/surface", FGColor.inkMuted, FGColor.surface),
        ] {
            let ratio = contrast(fg, bg, look)
            #expect(ratio >= 4.5, "\(name) \(look.name): \(ratio)")
        }
    }

    @Test("Ink reads on every course glaze", arguments: Look.all)
    private func inkOnGlaze(look: Look) {
        for course in courses {
            let ratio = contrast(course.accentText, course.fill, look)
            #expect(ratio >= 7, "\(course.label) ink/glaze \(look.name): \(ratio)")
        }
    }

    @Test("Course tag text reads on its pill and directly on the glaze", arguments: Look.all)
    private func tagText(look: Look) {
        for course in courses {
            let onPill = contrast(course.tagText, course.tagFill, look)
            #expect(onPill >= 4.5, "\(course.label) tag/pill \(look.name): \(onPill)")
            let onGlaze = contrast(course.tagText, course.fill, look)
            #expect(onGlaze >= 4.5, "\(course.label) tag/glaze \(look.name): \(onGlaze)")
        }
    }

    @Test("A tappable card has an edge that is visible against the page", arguments: Look.all)
    private func cardEdges(look: Look) {
        for course in courses {
            let ratio = contrast(course.edge, FGColor.bg, look)
            #expect(ratio >= 3, "\(course.label) edge \(look.name): \(ratio)")
        }
        #expect(contrast(FGColor.tabBarEdge, FGColor.bg, look) >= 3, "tabBarEdge/bg \(look.name)")
        #expect(contrast(FGColor.tabBarEdge, FGColor.surface, look) >= 3, "tabBarEdge/surface \(look.name)")
        for (name, bg) in [("bg", FGColor.bg), ("surface", FGColor.surface)] {
            let ratio = contrast(FGColor.lineStrong, bg, look)
            #expect(ratio >= 3, "lineStrong/\(name) \(look.name): \(ratio)")
        }
    }

    @Test("Today's label chip and the mascot plate read", arguments: Look.all)
    private func chipsAndPlates(look: Look) {
        for course in courses {
            let chip = contrast(course.chipText, course.chipFill, look)
            #expect(chip >= 7, "\(course.label) chip \(look.name): \(chip)")
            // The mascot's dark outline must read on the plate.
            let plate = contrast(FGColor.inkOnAccent, course.plate, look)
            #expect(plate >= 7, "\(course.label) plate \(look.name): \(plate)")
        }
    }

    @Test("The check-in banner and the primary action carry their type", arguments: Look.all)
    private func bannerAndAction(look: Look) {
        #expect(contrast(FGColor.onBanner, FGColor.bannerFill, look) >= 7, "banner \(look.name)")
        #expect(contrast(FGColor.onActionFill, FGColor.actionFill, look) >= 7, "action \(look.name)")
        #expect(contrast(FGColor.onDeepFill, FGColor.userBubble, look) >= 7, "bubble \(look.name)")
        #expect(contrast(FGColor.onDeepFill, FGColor.sideBadge, look) >= 4.5, "badge \(look.name)")
    }
}
