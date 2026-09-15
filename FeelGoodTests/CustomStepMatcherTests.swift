//
//  CustomStepMatcherTests.swift
//  FeelGoodTests
//
//  A custom routine's steps are whatever somebody typed. These pin down what
//  the player is allowed to infer from that, and what it must leave alone.
//

import Testing
import Foundation
@testable import FeelGood

@Suite("Custom step matching")
struct CustomStepMatcherTests {
    private func glossary() throws -> [ExerciseTerm] {
        try ContentStore.bundled().glossary
    }

    @Test("A typed title finds its drawing by name, alias, case, or plural",
          arguments: [
            ("Push-up", "push-up"),
            ("push ups", "push-up"),
            ("Knee push-ups", "knee-push-up"),
            ("10 squats", "bodyweight-squat"),
            ("Barbell squat", "squat"),
            ("Glute bridge", "glute-bridge"),
            ("Bridge", "glute-bridge"),
            ("Reclined pigeon", "figure-four-stretch"),
            ("Plank (Right)", "plank"),
            ("Cat cow", "cat-cow"),
          ])
    func titlesMatchDrawings(title: String, expected: String) throws {
        #expect(CustomStepMatcher.glossaryID(for: title, in: try glossary()) == expected)
    }

    @Test("A title that names nothing the app can draw gets no drawing",
          arguments: ["Rest", "Round 1", "Song two", "Shake it out", ""])
    func unknownTitlesMatchNothing(title: String) throws {
        #expect(CustomStepMatcher.glossaryID(for: title, in: try glossary()) == nil)
    }

    @Test("A word inside another word is not a match")
    func noPartialWordMatches() throws {
        // "row" must not fire on "throw", and "dip" must not fire on "dipping".
        let terms = [
            ExerciseTerm(id: "row", name: "Row", aka: [], instructions: ["x"], muscles: []),
            ExerciseTerm(id: "dip", name: "Dip", aka: [], instructions: ["x"], muscles: []),
        ]
        #expect(CustomStepMatcher.glossaryID(for: "Throw the ball", in: terms) == nil)
        #expect(CustomStepMatcher.glossaryID(for: "Dipping", in: terms) == nil)
        #expect(CustomStepMatcher.glossaryID(for: "Band row", in: terms) == "row")
    }

    @Test("Breathing is read from the title, with box breathing paced four-four-four-four")
    func breathingIsInferred() {
        let box = BreathingCadence(inhale: 4, holdIn: 4, exhale: 4, holdOut: 4)
        #expect(CustomStepMatcher.breathingVisual(for: "Box breathing")?.breathingCadence == box)
        #expect(CustomStepMatcher.breathingVisual(for: "Round 1 box breath")?.breathingCadence == box)
        #expect(CustomStepMatcher.breathingVisual(for: "4-7-8 breathing")?.breathingCadence
                == BreathingCadence(inhale: 4, holdIn: 7, exhale: 8, holdOut: 0))
        #expect(CustomStepMatcher.breathingVisual(for: "Deep breaths")?.breathingCadence == .default)
        #expect(CustomStepMatcher.breathingVisual(for: "Squats") == nil)
        #expect(CustomStepMatcher.breathingVisual(for: "Round 1") == nil)
    }

    @Test("Inference fills a blank custom step and leaves an authored one alone")
    func inferenceOnlyFillsBlanks() throws {
        let typed = CustomRoutinePart(title: "Box breathing", durationMin: 2).step
        let resolved = typed.inferringVisual(from: try glossary())
        #expect(resolved.visual?.breathingCadence == BreathingCadence(inhale: 4, holdIn: 4, exhale: 4, holdOut: 4))
        #expect(resolved.name == typed.name && resolved.seconds == typed.seconds && resolved.cue == typed.cue)

        let authored = Step(name: "Plank", seconds: 30, cue: "Hold.", glossaryID: "side-plank")
        #expect(authored.inferringVisual(from: try glossary()) == authored)
    }
}
