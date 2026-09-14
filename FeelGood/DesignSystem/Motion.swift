//
//  Motion.swift
//  FeelGood
//
//  Menu items settle in gently; a swap is a soft card exchange. Motion is how
//  "this was chosen for you" gets sold — and it always honours Reduce Motion.
//

import SwiftUI

nonisolated enum FGMotion {
    /// Items settling onto the menu.
    static let settle = Animation.spring(response: 0.55, dampingFraction: 0.86)
    /// The swap exchange.
    static let swap = Animation.spring(response: 0.42, dampingFraction: 0.82)
    static let gentle = Animation.easeInOut(duration: 0.28)
    /// A held step settling into its final-stretch warmth. Slower than
    /// `gentle` on purpose — this is read peripherally over several seconds,
    /// not watched.
    static let settleWarm = Animation.easeInOut(duration: 1.1)

    /// Staggered delay for the nth menu item.
    static func stagger(_ index: Int) -> Double { Double(index) * 0.06 }
}

extension View {
    /// Applies an animation unless the user has asked for less motion, in which
    /// case the change still happens — just without the movement.
    func fgAnimation<V: Equatable>(_ animation: Animation, value: V) -> some View {
        modifier(ReducedMotionAnimation(animation: animation, value: value))
    }
}

private struct ReducedMotionAnimation<V: Equatable>: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let animation: Animation
    let value: V

    func body(content: Content) -> some View {
        content.animation(reduceMotion ? .none : animation, value: value)
    }
}

extension View {
    /// A gentle settle each time a destination becomes visible. `TabView`'s
    /// own tab switch is a hard cut with no public hook to soften — the
    /// UIKit tab bar it's backed by owns that transition — so each incoming
    /// screen settles in on its own instead of the two screens cross-dissolving.
    /// Opacity alone read as barely-there; pairing it with a small rise and
    /// scale gives the switch an actual felt motion without turning into a
    /// slide (which would fight the tab bar's own icon selection animation).
    func tabSettleIn() -> some View {
        modifier(TabSettleIn())
    }
}

private struct TabSettleIn: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isVisible = false

    func body(content: Content) -> some View {
        content
            .opacity(isVisible ? 1 : 0)
            .scaleEffect(isVisible ? 1 : 0.97)
            .offset(y: isVisible ? 0 : 8)
            .onAppear {
                guard !reduceMotion else {
                    isVisible = true
                    return
                }
                // Re-armed on every appearance, not just the first: a tab
                // that's already been shown once still resets to hidden here
                // so switching back to it plays the settle again instead of
                // going stale after one showing.
                isVisible = false
                withAnimation(FGMotion.settle) { isVisible = true }
            }
    }
}
