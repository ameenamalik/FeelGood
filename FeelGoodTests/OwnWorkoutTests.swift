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

    @Test("A custom description replaces the generic Yours subtitle")
    func optionalDescription() {
        let described = Session.own(
            id: "own-described",
            title: "Desk reset",
            description: "Loosen my shoulders after work",
            activity: .stretching,
            durationMin: 10,
            intensity: 2
        )

        #expect(described.subtitle == "Loosen my shoulders after work")
        #expect(own(.strength).subtitle.isEmpty)
    }

    @Test("A custom routine with parts remains owned and becomes playable")
    func customPartsBecomeTimedSteps() {
        let session = Session.own(
            id: "own-morning",
            title: "Morning stretch",
            parts: [
                CustomRoutinePart(title: "Lunges", durationMin: 1),
                CustomRoutinePart(title: "Arm stretch", durationMin: 2),
                CustomRoutinePart(title: "Walking", durationMin: 1),
            ],
            activity: .stretching,
            durationMin: 4,
            intensity: 2
        )

        #expect(session.isOwn)
        #expect(session.source.steps.map(\.name) == ["Lunges", "Arm stretch", "Walking"])
        #expect(session.source.steps.map(\.seconds) == [60, 120, 60])
    }

    @Test("Explicit course overrides length inference")
    func explicitCourseOverridesLength() {
        let session = Session.own(
            id: "own-dessert",
            title: "Dance Break",
            activity: .dance,
            durationMin: 5,
            intensity: 2,
            course: .dessert
        )
        #expect(session.course == .dessert)
    }

    @Test("Adding custom routine overrides Today menu course slot")
    @MainActor
    func customRoutineTodayMenuOverride() {
        let store = ContentStore(catalog: ContentCatalog(version: 1, sessions: Fixture.catalog, glossary: []))
        let model = TodayModel(
            store: store,
            profile: Fixture.profile(),
            log: InMemorySessionLog(),
            now: Fixture.now,
            calendar: Fixture.utc
        )

        let custom = model.addCustomRoutine(
            title: "Morning Sunlight Walk",
            activity: .walking,
            durationMin: 15,
            intensity: 2,
            course: .main,
            addToToday: true,
            now: Fixture.now
        )

        #expect(model.isCourseOverridden(.main))
        #expect(model.menu.main?.session.id == custom.id)
        #expect(model.menu.main?.session.title == "Morning Sunlight Walk")
        #expect(model.menu.main?.session.isOwn == true)

        model.removeTodayCourseOverride(for: .main, now: Fixture.now)
        #expect(!model.isCourseOverridden(.main))
    }

    @Test("Filtering custom routines by course")
    @MainActor
    func filteringCustomRoutinesByCourse() {
        let store = ContentStore(catalog: ContentCatalog(version: 1, sessions: Fixture.catalog, glossary: []))
        let model = TodayModel(
            store: store,
            profile: Fixture.profile(),
            log: InMemorySessionLog(),
            now: Fixture.now,
            calendar: Fixture.utc
        )

        model.addCustomRoutine(
            title: "Quick Reset",
            activity: .breathwork,
            durationMin: 3,
            intensity: 1,
            course: .appetizer,
            addToToday: false,
            now: Fixture.now
        )

        model.addCustomRoutine(
            title: "Fun Dance",
            activity: .dance,
            durationMin: 10,
            intensity: 3,
            course: .dessert,
            addToToday: false,
            now: Fixture.now
        )

        let appetizers = model.customRoutines(for: .appetizer)
        let desserts = model.customRoutines(for: .dessert)
        let mains = model.customRoutines(for: .main)

        #expect(appetizers.count == 1)
        #expect(appetizers.first?.title == "Quick Reset")
        #expect(desserts.count == 1)
        #expect(desserts.first?.title == "Fun Dance")
        #expect(mains.isEmpty)
    }

    @Test("Editing a custom routine keeps its identity and updates every field")
    @MainActor
    func editingCustomRoutine() throws {
        let store = ContentStore(catalog: ContentCatalog(version: 1, sessions: Fixture.catalog, glossary: []))
        let model = TodayModel(
            store: store,
            profile: Fixture.profile(),
            log: InMemorySessionLog(),
            now: Fixture.now,
            calendar: Fixture.utc
        )
        let original = model.addCustomRoutine(
            title: "Quick Reset",
            parts: [CustomRoutinePart(title: "Breathe", durationMin: 5)],
            activity: .stretching,
            durationMin: 5,
            intensity: 2,
            course: .appetizer,
            addToToday: true,
            now: Fixture.now
        )

        let updated = try #require(model.updateCustomRoutine(
            original,
            title: "Evening Reset",
            description: "Unwind after work",
            parts: [
                CustomRoutinePart(title: "Fold", durationMin: 5),
                CustomRoutinePart(title: "Twist", durationMin: 10),
            ],
            activity: .yoga,
            durationMin: 15,
            intensity: 3,
            course: .side,
            addToToday: true,
            now: Fixture.now
        ))

        #expect(updated.id == original.id)
        #expect(updated.title == "Evening Reset")
        #expect(updated.subtitle == "Unwind after work")
        #expect(updated.activity == .yoga)
        #expect(updated.durationMin == 15)
        #expect(updated.intensity == 3)
        #expect(updated.course == .side)
        #expect(updated.source.steps.map(\.name) == ["Fold", "Twist"])
        #expect(model.customRoutines(for: .appetizer).isEmpty)
        #expect(model.customRoutines(for: .side).first == updated)
        #expect(model.todayCustomOverrides[.appetizer] == nil)
        #expect(model.todayCustomOverrides[.side] == updated)
    }

    @Test("Stand still and pace-that-feels-good are universally sanitized")
    func standStillAndVaguePaceAreSanitized() throws {
        // Direct CustomRoutinePart creation
        let part1 = CustomRoutinePart(title: "Stand still", durationMin: 1)
        #expect(part1.step.name == "Closing stillness")
        #expect(part1.step.cue == "Take slow, steady breaths and stay present.")
        #expect(!part1.step.cue.contains("pace that feels good"))

        let part2 = CustomRoutinePart(title: "Push ups", durationMin: 2)
        #expect(part2.step.cue == "Move with control and breathe steadily.")
        #expect(!part2.step.cue.contains("pace that feels good"))

        // Decoded from JSON
        let json = """
        {
            "name": "Stand still",
            "seconds": 30,
            "cue": "Move at a pace that feels good."
        }
        """.data(using: .utf8)!

        let decoded = try JSONDecoder().decode(Step.self, from: json)
        #expect(decoded.name == "Closing stillness")
        #expect(decoded.cue == "Take slow, steady breaths and stay present.")
        #expect(!decoded.name.contains("Stand still"))
        #expect(!decoded.cue.contains("pace that feels good"))
    }

    @Test("A step's own how-to survives saving and reopening")
    func writtenCueRoundTrips() {
        let session = Session.own(
            id: "own-cue",
            title: "Neck reset",
            parts: [CustomRoutinePart(title: "Chin tucks", durationMin: 2, cue: "Draw your chin straight back, like making a double chin.")],
            durationMin: 2,
            intensity: 2
        )
        #expect(session.source.steps.first?.cue == "Draw your chin straight back, like making a double chin.")
        #expect(session.customRoutineParts.first?.cue == "Draw your chin straight back, like making a double chin.")
    }

    @Test("The stand-in line is not shown back as if the person wrote it")
    func fallbackCueReopensEmpty() {
        let session = Session.own(
            id: "own-fallback",
            title: "Quick one",
            parts: [
                CustomRoutinePart(title: "Push ups", durationMin: 2),
                CustomRoutinePart(title: "Rest", durationMin: 1)
            ],
            durationMin: 3,
            intensity: 3
        )
        #expect(session.source.steps.allSatisfy { CustomRoutinePart.fallbackCues.contains($0.cue) })
        #expect(session.customRoutineParts.allSatisfy { $0.cue == nil })
    }
}
