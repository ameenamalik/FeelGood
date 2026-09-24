//
//  ThemeContrastTests.swift
//  FeelGoodTests
//
//  The contrast table in docs/PRD-themes.md §4 is arithmetic on hex values, and
//  arithmetic on a document rots. These resolve the real tokens, in both
//  appearances, and fail the build if a pair drops below its floor.
//
//  Floors: 4.5:1 for text, 3:1 for the boundary of anything you can tap
//  (WCAG 1.4.11). Known exceptions are written down here rather than skipped:
//  `inkMuted` on the light glaze cards is 3.5–4.1:1, so it is not asserted —
//  use `ink` on those.
//

import Testing
import SwiftUI
@testable import FeelGood

private enum Mode: String, CaseIterable { case light, dark }

private func luminance(_ color: Color, _ mode: Mode) -> Double {
    var env = EnvironmentValues()
    env.colorScheme = mode == .dark ? .dark : .light
    let c = color.resolve(in: env)   // linear sRGB components
    return 0.2126 * Double(c.linearRed) + 0.7152 * Double(c.linearGreen) + 0.0722 * Double(c.linearBlue)
}

private func contrast(_ a: Color, _ b: Color, _ mode: Mode) -> Double {
    let (x, y) = (luminance(a, mode), luminance(b, mode))
    return (max(x, y) + 0.05) / (min(x, y) + 0.05)
}

private let courses: [Course] = [.appetizer, .main, .side, .dessert, .special]

@Suite("Theme contrast")
struct ThemeContrastTests {

    @Test("Ink and muted ink read on the page and on cards", arguments: Mode.allCases)
    private func inkOnSurfaces(mode: Mode) {
        for (name, fg, bg) in [
            ("ink/bg", FGColor.ink, FGColor.bg),
            ("ink/surface", FGColor.ink, FGColor.surface),
            ("ink/panel", FGColor.ink, FGColor.panel),
            ("inkMuted/bg", FGColor.inkMuted, FGColor.bg),
            ("inkMuted/surface", FGColor.inkMuted, FGColor.surface),
        ] {
            let ratio = contrast(fg, bg, mode)
            #expect(ratio >= 4.5, "\(name) \(mode.rawValue): \(ratio)")
        }
    }

    @Test("Ink reads on every course glaze", arguments: Mode.allCases)
    private func inkOnGlaze(mode: Mode) {
        for course in courses {
            let ratio = contrast(course.accentText, course.fill, mode)
            #expect(ratio >= 7, "\(course.label) ink/glaze \(mode.rawValue): \(ratio)")
        }
    }

    @Test("Course tag text reads on its pill and directly on the glaze", arguments: Mode.allCases)
    private func tagText(mode: Mode) {
        for course in courses {
            let onPill = contrast(course.tagText, course.tagFill, mode)
            #expect(onPill >= 4.5, "\(course.label) tag/pill \(mode.rawValue): \(onPill)")
            let onGlaze = contrast(course.tagText, course.fill, mode)
            #expect(onGlaze >= 4.5, "\(course.label) tag/glaze \(mode.rawValue): \(onGlaze)")
        }
    }

    @Test("A tappable card has an edge that is visible against the page", arguments: Mode.allCases)
    private func cardEdges(mode: Mode) {
        for course in courses {
            let ratio = contrast(course.edge, FGColor.bg, mode)
            #expect(ratio >= 3, "\(course.label) edge \(mode.rawValue): \(ratio)")
        }
        #expect(contrast(FGColor.tabBarEdge, FGColor.bg, mode) >= 3, "tabBarEdge/bg \(mode.rawValue)")
        #expect(contrast(FGColor.tabBarEdge, FGColor.surface, mode) >= 3, "tabBarEdge/surface \(mode.rawValue)")
        for (name, bg) in [("bg", FGColor.bg), ("surface", FGColor.surface)] {
            let ratio = contrast(FGColor.lineStrong, bg, mode)
            #expect(ratio >= 3, "lineStrong/\(name) \(mode.rawValue): \(ratio)")
        }
    }

    @Test("The check-in banner and the primary action carry their type", arguments: Mode.allCases)
    private func bannerAndAction(mode: Mode) {
        // The banner fill is a flat two-stop gradient; the first stop is the fill.
        let bannerFill = mode == .dark ? Color(light: 0xC6DAC4, dark: 0xC6DAC4) : Color(light: 0x4B2A3A, dark: 0x4B2A3A)
        #expect(contrast(FGColor.onBanner, bannerFill, mode) >= 7, "banner \(mode.rawValue)")
        #expect(contrast(FGColor.onActionFill, FGColor.actionFill, mode) >= 7, "action \(mode.rawValue)")
        #expect(contrast(FGColor.onDeepFill, FGColor.userBubble, mode) >= 7, "bubble \(mode.rawValue)")
        #expect(contrast(FGColor.onDeepFill, FGColor.sideBadge, mode) >= 4.5, "badge \(mode.rawValue)")
    }
}
