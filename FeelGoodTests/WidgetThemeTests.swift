//
//  WidgetThemeTests.swift
//  FeelGoodTests
//
//  The widget restates a handful of theme colours (FeelGoodShared/
//  WidgetTheme.swift) because it cannot import the design system. Restated
//  colours drift; this is what stops them. It resolves the real tokens and
//  compares.
//

import Testing
import SwiftUI
@testable import FeelGood

private func components(_ color: Color, theme: FGThemeID, dark: Bool) -> [Float] {
    var env = EnvironmentValues()
    env.colorScheme = dark ? .dark : .light
    env.fgTheme = theme
    let c = color.resolve(in: env)
    return [c.linearRed, c.linearGreen, c.linearBlue]
}

private func same(_ pair: FGThemePair, as token: Color, theme: FGThemeID, dark: Bool) -> Bool {
    let expected = components(Color(light: pair.light, dark: pair.dark), theme: theme, dark: dark)
    let actual = components(token, theme: theme, dark: dark)
    return zip(expected, actual).allSatisfy { abs($0 - $1) < 0.0005 }
}

@Suite("Widget theme")
struct WidgetThemeTests {

    @Test("The widget's page and text colours match the app's tokens", arguments: FGThemeID.allCases, [false, true])
    func surfaceAndInk(theme: FGThemeID, dark: Bool) {
        let palette = WidgetThemePalette.palette(for: theme)
        #expect(same(palette.surface, as: FGColor.surface, theme: theme, dark: dark), "surface \(theme) dark=\(dark)")
        #expect(same(palette.ink, as: FGColor.ink, theme: theme, dark: dark), "ink \(theme) dark=\(dark)")
        #expect(same(palette.inkMuted, as: FGColor.inkMuted, theme: theme, dark: dark), "inkMuted \(theme) dark=\(dark)")
    }

    @Test("The widget's course pill matches the course card in the app", arguments: FGThemeID.allCases, [false, true])
    func coursePill(theme: FGThemeID, dark: Bool) {
        let palette = WidgetThemePalette.palette(for: theme)
        for course in Course.allCases {
            let pill = palette.pill(forCourseLabel: course.label)
            // Kiln and Moss show the glaze with ink on it; Indigo shows the chip.
            let fill = theme == .indigo ? course.chipFill : course.fill
            let text = theme == .indigo ? course.chipText : FGColor.ink
            #expect(same(pill.fill, as: fill, theme: theme, dark: dark), "\(course.label) fill \(theme) dark=\(dark)")
            #expect(same(pill.text, as: text, theme: theme, dark: dark), "\(course.label) text \(theme) dark=\(dark)")
        }
    }

    @Test("An unknown course label falls back to the special pill, not a crash")
    func unknownLabel() {
        let palette = WidgetThemePalette.kiln
        let unknown = palette.pill(forCourseLabel: "Brunch")
        let special = palette.pill(forCourseLabel: "Special")
        #expect(unknown.fill == special.fill && unknown.text == special.text)
    }
}
