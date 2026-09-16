//
//  BreathingOrbView.swift
//  FeelGood
//
//  The paced orb for a breathing step, and the phase label that shares its
//  clock. Lives inside the exercise card's visual slot, the same place a
//  drawn demo goes, so it can never sit behind the cue text.
//

import SwiftUI

/// Grows through the inhale, rests full through a hold, softens through the
/// exhale, rests empty through the second hold. Cosine easing has zero
/// velocity at both ends of every phase, so a breath never snaps.
///
/// No progress arc: step progress is the waterline behind the whole screen,
/// the same as every other step, and a ring is a ring.
struct BreathingOrbView: View {
    let cadence: BreathingCadence
    let aura: FGAura
    let isActive: Bool
    let startedAt: Date
    let pausedAt: Date?
    var diameter: CGFloat = 200

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 60.0, paused: reduceMotion || !isActive)) { timeline in
            let state = BreathingCycleState(
                at: timeline.date,
                cadence: cadence,
                isActive: isActive,
                reduceMotion: reduceMotion,
                startedAt: startedAt,
                pausedAt: pausedAt
            )

            ZStack {
                Circle()
                    .fill(aura.edge.opacity(0.22))
                    .frame(width: diameter * 0.92, height: diameter * 0.92)
                    .blur(radius: 20)
                    .scaleEffect(state.scale * 1.08)

                // Edge-weighted rather than core-weighted: it sits on a card
                // already painted in this aura's core and mid, so the orb has
                // to carry the deeper end of the same hue to read as a shape
                // on it rather than a smudge in it. The white highlight is
                // the same idea as `AuraDot`: lit from just above centre.
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                .white.opacity(0.9),
                                aura.mid.opacity(0.95),
                                aura.edge.opacity(0.9),
                            ],
                            center: UnitPoint(x: 0.42, y: 0.36),
                            startRadius: 4,
                            endRadius: diameter * 0.6
                        )
                    )
                    .overlay {
                        Circle().stroke(.white.opacity(0.55), lineWidth: 1.5)
                    }
                    .frame(width: diameter, height: diameter)
                    .scaleEffect(state.scale)
                    .shadow(color: aura.edge.opacity(0.3), radius: 18, y: 8)
            }
        }
        .accessibilityHidden(true)
    }
}

/// Text and orb share the same clock, so "Breathe in" always appears while
/// the orb is growing and "Hold" only while it is still.
struct BreathingPhaseLabel: View {
    let cadence: BreathingCadence
    let isActive: Bool
    let startedAt: Date
    let pausedAt: Date?

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: reduceMotion || !isActive)) { timeline in
            let state = BreathingCycleState(
                at: timeline.date,
                cadence: cadence,
                isActive: isActive,
                reduceMotion: reduceMotion,
                startedAt: startedAt,
                pausedAt: pausedAt
            )
            let text = isActive && !reduceMotion ? state.phase.label : (isActive ? "Breathe slowly" : "Paused")

            Label(text, systemImage: state.phase.systemImage)
                .font(FGFont.label)
                .foregroundStyle(FGColor.goldDeep)
                .contentTransition(.opacity)
                .accessibilityLabel(text)
        }
    }
}

/// Where in the breath the clock currently is. Pure: a function of the date
/// and the cadence, so it can be checked in a test without a view.
nonisolated struct BreathingCycleState: Equatable, Sendable {
    enum Phase: Equatable, Sendable {
        case inhale, holdIn, exhale, holdOut

        var label: String {
            switch self {
            case .inhale: "Breathe in"
            case .exhale: "Breathe out"
            case .holdIn, .holdOut: "Hold"
            }
        }

        var systemImage: String {
            switch self {
            case .inhale: "arrow.up"
            case .exhale: "arrow.down"
            case .holdIn, .holdOut: "minus"
            }
        }
    }

    /// Where the orb sits between empty and full, as a scale factor.
    let scale: CGFloat
    let phase: Phase

    private static let emptyScale: CGFloat = 0.56
    private static let fullScale: CGFloat = 1.0

    /// Where an orb rests when it isn't breathing: Reduce Motion, or a step
    /// that hasn't started yet.
    static let resting = BreathingCycleState(scale: 0.62, phase: .inhale)

    init(scale: CGFloat, phase: Phase) {
        self.scale = scale
        self.phase = phase
    }

    /// `pausedAt` freezes the clock at that moment; `startedAt` is moved
    /// forward by the paused duration on resume (see `PlayerView`), so the
    /// same breath continues rather than jumping to another phase. A step
    /// that is neither running nor paused has not begun, and rests.
    init(
        at date: Date,
        cadence: BreathingCadence,
        isActive: Bool,
        reduceMotion: Bool,
        startedAt: Date,
        pausedAt: Date?
    ) {
        guard !reduceMotion, isActive || pausedAt != nil, cadence.cycleSeconds > 0 else {
            self = .resting
            return
        }
        let sampleDate = isActive ? date : (pausedAt ?? date)
        let elapsed = max(sampleDate.timeIntervalSince(startedAt), 0)
            .truncatingRemainder(dividingBy: Double(cadence.cycleSeconds))
        self = Self.state(atSecond: elapsed, in: cadence)
    }

    /// `second` is the offset into one cycle, already wrapped.
    static func state(atSecond second: Double, in cadence: BreathingCadence) -> BreathingCycleState {
        let phases: [(Phase, Int)] = [
            (.inhale, cadence.inhale),
            (.holdIn, cadence.holdIn),
            (.exhale, cadence.exhale),
            (.holdOut, cadence.holdOut),
        ]
        var phaseStart = 0.0
        for (phase, length) in phases where length > 0 {
            let phaseEnd = phaseStart + Double(length)
            if second < phaseEnd {
                let progress = (second - phaseStart) / Double(length)
                let eased = 0.5 - (0.5 * cos(.pi * progress))
                let fullness: Double = switch phase {
                case .inhale: eased
                case .holdIn: 1
                case .exhale: 1 - eased
                case .holdOut: 0
                }
                return BreathingCycleState(
                    scale: emptyScale + CGFloat(fullness) * (fullScale - emptyScale),
                    phase: phase
                )
            }
            phaseStart = phaseEnd
        }
        // Only reachable if the cycle wrapped on a floating-point edge.
        return BreathingCycleState(scale: emptyScale, phase: .holdOut)
    }
}
