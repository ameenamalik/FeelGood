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

/// The shared physical response for FeelGood's tappable surfaces.
///
/// Pressing moves the control toward the page and tightens its shadow; release
/// returns through one short, soft spring. Reduce Motion keeps the useful
/// shadow-state feedback but removes scaling and interpolation.
struct FGPressButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        let isPressed = isEnabled && configuration.isPressed

        configuration.label
            .scaleEffect(reduceMotion ? 1 : (isPressed ? 0.98 : 1))
            .shadow(
                color: Color.black.opacity(shadowOpacity(isPressed: isPressed)),
                radius: isPressed ? 3 : 8,
                x: 0,
                y: isPressed ? 1 : 3
            )
            .animation(
                reduceMotion
                    ? .none
                    : isPressed
                        ? .easeOut(duration: 0.09)
                        : .spring(response: 0.24, dampingFraction: 0.82),
                value: isPressed
            )
    }

    private func shadowOpacity(isPressed: Bool) -> Double {
        guard isEnabled else { return 0.02 }
        if colorScheme == .dark {
            return isPressed ? 0.12 : 0.20
        }
        return isPressed ? 0.025 : 0.055
    }
}

extension ButtonStyle where Self == FGPressButtonStyle {
    static var feelGoodPress: FGPressButtonStyle { FGPressButtonStyle() }
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
