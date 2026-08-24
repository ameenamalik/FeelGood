//
//  AffinityTests.swift
//  FeelGoodTests
//
//  "Loved it" has to keep counting after the fortnight of history it happened
//  in has scrolled past — and "too much" has to keep counting the other way.
//

import Testing
import Foundation
@testable import FeelGood

@Suite("Affinity")
struct AffinityTests {

    @Test("Loving something moves it up, finding it too much moves it down")
    func feelMovesTheScore() {
        #expect(Affinity.updated(0, after: .completed(feel: .lovedIt)) > 0)
        #expect(Affinity.updated(0, after: .completed(feel: .tooMuch)) < 0)
        #expect(Affinity.updated(0, after: .completed(feel: .fine)) > 0)
    }

    @Test("Skipping is not held against anything")
    func skippingMovesNothing() {
        #expect(Affinity.updated(0.4, after: .skipped) == 0.4)
        #expect(Affinity.delta(for: .skipped) == 0)
    }

    @Test("Turning something down nudges, it doesn't condemn")
    func swappingAwayNudges() {
        let once = Affinity.updated(0, after: .swappedAway)
        #expect(once < 0)
        #expect(once > Affinity.delta(for: .completed(feel: .tooMuch)))
    }

    @Test("No amount of feedback runs off the end of the scale")
    func scoreStaysInRange() {
        var loved = 0.0
        var hated = 0.0
        for _ in 0..<50 {
            loved = Affinity.updated(loved, after: .completed(feel: .lovedIt))
            hated = Affinity.updated(hated, after: .completed(feel: .tooMuch))
        }
        #expect(loved == Affinity.range.upperBound)
        #expect(hated == Affinity.range.lowerBound)
    }

    @Test("A loved session still wins long after the history window has passed")
    func affinityOutlivesTheHistoryWindow() {
        // Two identical sides. Nothing in history, nothing to tell them apart
        // except a score that survived the fortnight.
        let engine = PlanEngine(catalog: [
            Fixture.session(id: "s-one", activity: .stretching, qualities: [.mobility],
                            durationMin: 5, intensity: 1, course: .side),
            Fixture.session(id: "s-two", activity: .stretching, qualities: [.mobility],
                            durationMin: 5, intensity: 1, course: .side)
        ])
        let input = PlanInput(
            profile: Fixture.profile(activities: [.stretching], equipment: [.none]),
            checkIn: PlanCheckIn(energy: .steady, time: .some),
            context: Fixture.context(),
            affinity: ["s-two": 1.0]
        )

        #expect(engine.makeMenu(input).sides.first?.session.id == "s-two")
    }
}
