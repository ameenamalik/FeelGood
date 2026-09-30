//
//  StepVisualView.swift
//  FeelGood
//
//  The one visual slot on the exercise card, under the step's name. Every
//  kind of motion the player has goes here and nowhere else, so nothing can
//  ever be drawn behind the cue text.
//
//  Resolution order: a drawn demo for the step's `glossaryID` (Lottie, then
//  the PNG flipbook) → the paced breathing orb, if the content declared one
//  → nothing at all, in which case the slot takes no space.
//

import SwiftUI

struct StepVisualView: View {
    /// The square the slot reserves whenever it has something to show, so a
    /// card is the same height whether it holds a figure or an orb.
    static let slotSize: CGFloat = 220

    let step: Step
    let aura: FGAura
    /// Whether the breathing clock is running: past the get-ready countdown,
    /// not paused, not in a side-switch buffer.
    let isBreathingActive: Bool
    let breathingStartedAt: Date
    let breathingPausedAt: Date?
    var narrationPosition: (Date) -> NarrationPlaybackPosition? = { _ in nil }

    var body: some View {
        if ExerciseDemo.hasDemo(for: step.glossaryID) {
            ExerciseDemoView(glossaryID: step.glossaryID)
        } else if let cadence = step.visual?.breathingCadence {
            BreathingOrbView(
                cadence: cadence,
                aura: aura,
                isActive: isBreathingActive,
                startedAt: breathingStartedAt,
                pausedAt: breathingPausedAt,
                narrationPosition: narrationPosition
            )
            .frame(width: Self.slotSize, height: Self.slotSize)
        }
    }
}
