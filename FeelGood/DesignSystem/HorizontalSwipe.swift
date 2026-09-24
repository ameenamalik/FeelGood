//
//  HorizontalSwipe.swift
//  FeelGood
//
//  Swipe-left-to-skip on a Today card, without taking scrolling away.
//
//  SwiftUI's `DragGesture` cannot do this. Even as a `simultaneousGesture` it
//  claims the touch inside a `ScrollView`, so a drag that starts on a card does
//  not scroll: Today only scrolled from the gaps between cards, or from a swipe
//  that began outside one. This recognizer decides the axis as soon as the
//  finger has moved a few points and *fails* if the motion is not clearly
//  horizontal, so vertical and diagonal drags go straight to the scroll view.
//

import SwiftUI
import UIKit

struct FGHorizontalSwipe: UIGestureRecognizerRepresentable {
    var isEnabled: Bool
    /// Called with the horizontal translation while the finger moves.
    var onChanged: (CGFloat) -> Void
    /// Called with the final translation and horizontal velocity. Also called
    /// with zeros if the gesture is cancelled, so a card always snaps back.
    var onEnded: (_ translation: CGFloat, _ velocity: CGFloat) -> Void

    func makeUIGestureRecognizer(context: Context) -> FGHorizontalPanRecognizer {
        FGHorizontalPanRecognizer()
    }

    func updateUIGestureRecognizer(_ recognizer: FGHorizontalPanRecognizer, context: Context) {
        recognizer.isEnabled = isEnabled
    }

    func handleUIGestureRecognizerAction(_ recognizer: FGHorizontalPanRecognizer, context: Context) {
        let x = recognizer.translation(in: recognizer.view).x
        switch recognizer.state {
        case .changed:
            onChanged(x)
        case .ended:
            onEnded(x, recognizer.velocity(in: recognizer.view).x)
        case .cancelled, .failed:
            onEnded(0, 0)
        default:
            break
        }
    }
}

/// A pan that gives up unless the first few points of motion are clearly
/// sideways. Giving up (`.failed`) is what hands the touch to the scroll view.
final class FGHorizontalPanRecognizer: UIPanGestureRecognizer {
    /// How far the finger must move before the axis is decided.
    private let decisionDistance: CGFloat = 8
    /// Sideways motion must beat vertical by this factor (about 34° of slack
    /// either side of horizontal), so a diagonal scroll is never taken.
    private let horizontalBias: CGFloat = 1.5

    private var origin: CGPoint = .zero
    private var hasDecided = false

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        hasDecided = false
        origin = touches.first?.location(in: view) ?? .zero
        super.touchesBegan(touches, with: event)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
        if !hasDecided, let point = touches.first?.location(in: view) {
            let dx = abs(point.x - origin.x)
            let dy = abs(point.y - origin.y)
            if max(dx, dy) >= decisionDistance {
                hasDecided = true
                if dx < dy * horizontalBias {
                    state = .failed
                    return
                }
            }
        }
        super.touchesMoved(touches, with: event)
    }
}

extension View {
    /// Swipe left to skip. `offset` follows the finger; `onSkip` fires once the
    /// swipe is far or fast enough. Vertical and diagonal drags still scroll.
    func fgSwipeToSkip(
        isEnabled: Bool,
        offset: Binding<CGFloat>,
        reduceMotion: Bool,
        onSkip: @escaping () -> Void
    ) -> some View {
        gesture(
            FGHorizontalSwipe(
                isEnabled: isEnabled,
                onChanged: { x in
                    if x < 0, !reduceMotion { offset.wrappedValue = x }
                },
                onEnded: { x, velocity in
                    // Roughly where the finger was headed; the old threshold was
                    // "predicted end translation under -100".
                    let predicted = x + velocity * 0.2
                    if x < -50 || predicted < -100 {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        if reduceMotion {
                            onSkip()
                        } else {
                            withAnimation(.easeOut(duration: 0.18)) {
                                offset.wrappedValue = -UIScreen.main.bounds.width
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.16) {
                                onSkip()
                                offset.wrappedValue = 0
                            }
                        }
                    } else {
                        withAnimation(FGMotion.gentle) { offset.wrappedValue = 0 }
                    }
                }
            )
        )
    }
}
