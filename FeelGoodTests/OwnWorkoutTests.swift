//
//  OwnWorkoutTests.swift
//  FeelGoodTests
//
//  Three taps have to be enough to describe a workout the engine can score
//  like any other — and safety cannot be one of the things we skipped asking.
//

import Testing
import Foundation
@testable import FeelGood

@Suite("Somebody's own workout")
struct OwnWorkoutTests {

    private func own(
        _ activity: Activity,
        minutes: Int = 30,
        intensity: Int = 3
    ) -> Session {
        .own(id: "own-1", title: "Mine", activity: activity, durationMin: minutes, intensity: intensity)
    }

    @Test("What it develops is inferred, so it lands in the same quality balance")
    func qualitiesAreInferred() {
        #expect(own(.strength).qualities.contains(.strength))
        #expect(own(.walking).qualities.contains(.endurance))
        #expect(own(.breathwork).qualities.contains(.downRegulation))
    }

    @Test("Anything bouncy is safety-gated exactly like the authored catalog")
    func impactWorkIsGated() {
        let gates = Set(own(.jumpRope).contraindications)
        #expect(gates.isSuperset(of: [.pregnancy, .postpartum, .pelvicFloor]))
        #expect(own(.stretching).contraindications.isEmpty)
    }

    @Test("A saved swim is never offered on a day with no pool")
    func equipmentIsInferred() {
        #expect(own(.swimming).equipment.contains(.pool))
        // Lifting needs nothing we can name from three taps, so it asks for
        // nothing rather than guessing at a gym.
        #expect(own(.strength).needsNoEquipment)
    }

    @Test("Length decides the course", arguments: [(4, Course.appetizer), (9, .side), (30, .main)])
    func lengthDecidesTheCourse(minutes: Int, course: Course) {
        #expect(own(.strength, minutes: minutes).course == course)
    }

    @Test("A hard workout is never offered on an empty day")
    func effortDecidesEnergyFit() {
        #expect(own(.strength, intensity: 4).energyFit == [.strong])
        #expect(own(.stretching, intensity: 1).energyFit.contains(.low))
    }

    @Test("It has no steps, so the app offers to log it rather than play it")
    func ownSessionsHaveNothingToPlay() {
        #expect(own(.strength).isOwn)
        #expect(own(.strength).source.steps.isEmpty)
    }
}
