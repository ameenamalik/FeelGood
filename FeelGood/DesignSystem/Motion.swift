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
