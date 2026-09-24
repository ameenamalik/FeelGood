//
//  FGThemeTests.swift
//  FeelGoodTests
//
//  Promoted from the trait-bridge spike (docs/PRD-themes.md §13). These run the
//  real `FGThemeID` / `Color(light:dark:overrides:)`, not a prototype.
//
//  Colours are checked through `Color.resolve(in:)` and offscreen rendering.
//  A window snapshot draws black in the test host, so it is not used.
//

import Testing
import SwiftUI
import UIKit
@testable import FeelGood

private let base = (light: UInt32(0x0000FF), dark: UInt32(0x00FF00))   // blue / green
private let indigoOverride = FGThemePair(light: 0xFF0000, dark: 0xFFFF00) // red / yellow

private func themed() -> Color {
    Color(light: base.light, dark: base.dark, overrides: [.indigo: indigoOverride])
}

private func resolve(_ color: Color, theme: FGThemeID, dark: Bool = false) -> Color.Resolved {
    var env = EnvironmentValues()
    env.fgTheme = theme
    env.colorScheme = dark ? .dark : .light
    return color.resolve(in: env)
}

/// Built outside the suite on purpose. Written inside a `@MainActor` test, the
/// provider closure inherits main-actor isolation and traps the moment it is
/// resolved off the main thread — the exact SIGTRAP `CLAUDE.md` warns about.
nonisolated private func themeProbeColor() -> UIColor {
    UIColor { t in t.fgTheme == .indigo ? UIColor.red : UIColor.blue }
}

@Suite("FGTheme")
@MainActor
struct FGThemeTests {

    @Test("Kiln is the default theme")
    func defaultIsKiln() {
        #expect(EnvironmentValues().fgTheme == .kiln)
        #expect(UITraitCollection().fgTheme == .kiln)
    }

    @Test("A theme with no override keeps the token's own colour, in both appearances")
    func noOverrideKeepsBase() {
        let light = resolve(themed(), theme: .kiln)
        #expect(light.blue > 0.9 && light.red < 0.1)
        let dark = resolve(themed(), theme: .kiln, dark: true)
        #expect(dark.green > 0.9 && dark.blue < 0.1)
    }

    @Test("An override restyles the token for that theme, in both appearances")
    func overrideApplies() {
        let light = resolve(themed(), theme: .indigo)
        #expect(light.red > 0.9 && light.blue < 0.1, "light r\(light.red) b\(light.blue)")
        let dark = resolve(themed(), theme: .indigo, dark: true)
        #expect(dark.red > 0.9 && dark.green > 0.9, "dark r\(dark.red) g\(dark.green)")
    }

    @Test("Tokens with no override look the same in every theme")
    func tokensWithoutOverridesAreThemeInert() {
        // The accents are the same pastel fills in every look, by design.
        let tokens: [Color] = [FGColor.clay, FGColor.gold, FGColor.rose, FGColor.sage, FGColor.sky, FGColor.inkOnAccent, FGColor.sideBadge, FGColor.onDeepFill]
        for token in tokens {
            for dark in [false, true] {
                let a = resolve(token, theme: .kiln, dark: dark)
                let b = resolve(token, theme: .indigo, dark: dark)
                #expect(a.red == b.red && a.green == b.green && a.blue == b.blue)
            }
        }
    }

    @Test("Indigo restyles the page, the type and the primary action")
    func indigoRestylesCoreTokens() {
        for token in [FGColor.bg, FGColor.surface, FGColor.ink, FGColor.actionFill] {
            for dark in [false, true] {
                let a = resolve(token, theme: .kiln, dark: dark)
                let b = resolve(token, theme: .indigo, dark: dark)
                #expect(!(a.red == b.red && a.green == b.green && a.blue == b.blue))
            }
        }
    }

    @Test("The environment value reaches the rendered pixels")
    func environmentReachesPixels() throws {
        let renderer = ImageRenderer(content: themed().environment(\.fgTheme, .indigo).frame(width: 8, height: 8))
        renderer.scale = 1
        let image = try #require(renderer.uiImage)
        #expect(pixel(image).r > 200 && pixel(image).b < 60)
    }

    @Test("A subtree can override its parent")
    func subtreeOverride() throws {
        let view = VStack(spacing: 0) {
            themed()                                        // inherits Indigo
            themed().environment(\.fgTheme, .kiln)          // back to Kiln
        }
        .environment(\.fgTheme, .indigo)
        .frame(width: 8, height: 16)
        let renderer = ImageRenderer(content: view)
        renderer.scale = 1
        let image = try #require(renderer.uiImage)
        #expect(pixel(image, y: 4).r > 200)
        #expect(pixel(image, y: 12).b > 200)
    }

    @Test("A theme set on a UIKit host arrives in the SwiftUI environment")
    func uikitTraitReachesEnvironment() throws {
        final class Box: @unchecked Sendable { var seen: FGThemeID? }
        struct Probe: View {
            let box: Box
            @Environment(\.fgTheme) private var theme
            var body: some View { box.seen = theme; return Color.clear }
        }
        guard let scene = UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).first else {
            Issue.record("No window scene in the test host")
            return
        }
        let box = Box()
        let host = UIHostingController(rootView: Probe(box: box))
        host.traitOverrides.fgTheme = .indigo
        let window = UIWindow(windowScene: scene)
        window.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
        window.rootViewController = host
        window.isHidden = false
        host.view.layoutIfNeeded()
        window.isHidden = true
        #expect(box.seen == .indigo)
    }

    @Test("A theme installed at the root reaches controllers presented over it")
    func themeReachesPresentedControllers() throws {
        guard let scene = UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).first else {
            Issue.record("No window scene in the test host")
            return
        }
        // The SwiftUI environment alone does NOT reach a sheet or full-screen
        // cover: each is its own hosting controller and takes its trait from
        // the UIKit hierarchy. Caught by running the app, not by any earlier test.
        let host = UIHostingController(rootView: Color.clear.fgTheme(.indigo))
        let window = UIWindow(windowScene: scene)
        window.frame = CGRect(x: 0, y: 0, width: 200, height: 200)
        window.rootViewController = host
        window.isHidden = false
        host.view.layoutIfNeeded()
        defer { window.isHidden = true }

        let presented = UIViewController()
        host.present(presented, animated: false)
        _ = presented.view
        presented.view.layoutIfNeeded()
        RunLoop.current.run(until: Date().addingTimeInterval(0.2))
        #expect(window.traitCollection.fgTheme == .indigo, "window saw \(window.traitCollection.fgTheme)")
        #expect(host.traitCollection.fgTheme == .indigo, "root saw \(host.traitCollection.fgTheme)")
        #expect(presented.presentingViewController === host, "not presented")
        #expect(presented.traitCollection.fgTheme == .indigo, "presented saw \(presented.traitCollection.fgTheme)")
    }

    @Test("Settings default to Kiln and fall back to it for anything unrecognised")
    func settingsFallBack() {
        let defaults = UserDefaults(suiteName: "FGThemeTests.\(UUID().uuidString)")!
        #expect(ThemeSettings(defaults: defaults).selected == .kiln)

        defaults.set("not-a-theme", forKey: ThemeSettings.key)
        #expect(ThemeSettings(defaults: defaults).selected == .kiln)
    }

    @Test("A chosen theme is remembered on device")
    func settingsPersist() {
        let defaults = UserDefaults(suiteName: "FGThemeTests.\(UUID().uuidString)")!
        let settings = ThemeSettings(defaults: defaults)
        settings.selected = .indigo
        #expect(ThemeSettings(defaults: defaults).selected == .indigo)
    }

    @Test("The provider resolves off the main thread")
    func resolvesOffMainThread() async {
        let traits = UITraitCollection { $0.fgTheme = .indigo }
        let color = themeProbeColor()
        let resolved = await Task.detached { color.resolvedColor(with: traits) }.value
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        resolved.getRed(&r, green: &g, blue: &b, alpha: &a)
        #expect(r == 1 && b == 0)
    }

    @Test("Theme ids round-trip through Codable, for persistence")
    func codable() throws {
        for id in FGThemeID.allCases {
            let data = try JSONEncoder().encode(id)
            #expect(try JSONDecoder().decode(FGThemeID.self, from: data) == id)
        }
    }

    private func pixel(_ image: UIImage, y: Int = 4) -> (r: Int, g: Int, b: Int) {
        guard let cg = image.cgImage else { return (0, 0, 0) }
        var px = [UInt8](repeating: 0, count: 4)
        let ctx = CGContext(data: &px, width: 1, height: 1, bitsPerComponent: 8, bytesPerRow: 4,
                            space: CGColorSpaceCreateDeviceRGB(),
                            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
        ctx?.draw(cg, in: CGRect(x: -4, y: -(cg.height - y - 1), width: cg.width, height: cg.height))
        return (Int(px[0]), Int(px[1]), Int(px[2]))
    }
}

// MARK: - Which looks are earned

@Suite("Theme unlocks")
struct ThemeUnlockTests {

    private func progress(unlocked wins: Set<LittleWin>) -> [LittleWinProgress] {
        LittleWin.allCases.map {
            LittleWinProgress(win: $0, current: 0, unlockedAt: wins.contains($0) ? Date(timeIntervalSince1970: 0) : nil)
        }
    }

    @Test("Everyone has Kiln, and nothing else before earning it")
    func kilnOnly() {
        #expect(FGThemeID.unlocked(by: progress(unlocked: [])) == [.kiln])
        #expect(FGThemeID.unlocked(by: progress(unlocked: [.firstMove, .homebody, .tinyWins])) == [.kiln])
    }

    @Test("Variety Pack unlocks Indigo")
    func varietyUnlocksIndigo() {
        #expect(FGThemeID.unlocked(by: progress(unlocked: [.varietyPack])) == [.kiln, .indigo])
    }

    @Test("An unearned choice draws as Kiln, without an error")
    @MainActor
    func unearnedFallsBack() {
        let defaults = UserDefaults(suiteName: "FGThemeTests.\(UUID().uuidString)")!
        let settings = ThemeSettings(defaults: defaults)
        settings.selected = .indigo
        #expect(settings.effective(unlocked: [.kiln]) == .kiln)
        #expect(settings.effective(unlocked: [.kiln, .indigo]) == .indigo)
        // The choice itself is kept, so earning it later restores it.
        #expect(settings.selected == .indigo)
    }

    @Test("Only the Variety Pack win mentions a new look")
    func themeUnlockLine() {
        for win in LittleWin.allCases {
            #expect((win.themeUnlockLine != nil) == (win == .varietyPack))
        }
    }
}
