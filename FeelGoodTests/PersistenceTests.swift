//
//  PersistenceTests.swift
//  FeelGoodTests
//
//  The store side of the loop: answers survive a round trip as answers, and a
//  finished session becomes a record and a score.
//

import Testing
import Foundation
import SwiftData
@testable import FeelGood

@Suite("Persistence")
@MainActor
struct PersistenceTests {

    private func context() throws -> ModelContext {
        let container = try ModelContainer(
            for: Schema(FeelGoodSchema.models),
            configurations: [ModelConfiguration(isStoredInMemoryOnly: true)]
        )
        return ModelContext(container)
    }

    @Test("A profile stores what was ticked, not what it implied")
    func profileStoresAnswersNotImplications() throws {
        let context = try context()
        let answers = ProfileAnswers(activities: [], equipment: [.none, .gym])
        let profile = UserProfile(answers: answers, now: Fixture.now)
        context.insert(profile)

        // Going in: the gym implies somewhere to lift and the kit inside it.
        #expect(profile.planProfile.availableActivities.contains(.strength))
        #expect(profile.planProfile.equipment.contains(.weights))
        // Coming back out: only the tick itself, so the screen shows the truth.
        #expect(profile.answers.equipment == [.none, .gym])
        #expect(profile.answers.activities.isEmpty)
    }

    @Test("Unticking the gym takes the weights with it")
    func implicationsAreNotStuckOn() throws {
        let context = try context()
        let profile = UserProfile(answers: ProfileAnswers(equipment: [.none, .gym]), now: Fixture.now)
        context.insert(profile)

        profile.apply(ProfileAnswers(activities: [.walking], equipment: [.none]), now: Fixture.now)

        #expect(!profile.planProfile.equipment.contains(.weights))
        #expect(!profile.planProfile.availableActivities.contains(.strength))
        #expect(profile.planProfile.equipment.contains(.outdoor))
    }

    @Test("Finishing a session writes a record and a score")
    func recordingPersists() throws {
        let context = try context()
        let log = SwiftDataActivityLog(context: context)
        let session = Fixture.catalog.first { $0.id == "a-stretch" }!

        log.record(session, outcome: .completed(feel: .lovedIt), startedAt: Fixture.now, endedAt: Fixture.now, dayStart: Fixture.now)

        let records = try context.fetch(FetchDescriptor<SessionRecord>())
        #expect(records.count == 1)
        #expect(records.first?.historyEntry.wasCompleted == true)

        let scores = try context.fetch(FetchDescriptor<AffinityRecord>())
        #expect(scores.first?.score == Affinity.updated(0, after: .completed(feel: .lovedIt)))
    }

    @Test("Feedback on the same session accumulates rather than resetting")
    func affinityAccumulates() throws {
        let context = try context()
        let log = SwiftDataActivityLog(context: context)
        let session = Fixture.catalog.first { $0.id == "a-stretch" }!

        for _ in 0..<3 {
            log.record(session, outcome: .completed(feel: .lovedIt), startedAt: Fixture.now, endedAt: Fixture.now, dayStart: Fixture.now)
        }

        let scores = try context.fetch(FetchDescriptor<AffinityRecord>())
        #expect(scores.count == 1)
        #expect((scores.first?.score ?? 0) > Affinity.updated(0, after: .completed(feel: .lovedIt)))
    }

    @Test("Skipping writes the record and leaves the score alone")
    func skippingWritesNoScore() throws {
        let context = try context()
        let log = SwiftDataActivityLog(context: context)
        let session = Fixture.catalog.first { $0.id == "m-pilates-30" }!

        log.record(session, outcome: .skipped, startedAt: Fixture.now, endedAt: nil, dayStart: Fixture.now)

        #expect(try context.fetch(FetchDescriptor<SessionRecord>()).count == 1)
        #expect(try context.fetch(FetchDescriptor<AffinityRecord>()).isEmpty)
    }

    @Test("A kept workout survives as something the engine can offer")
    func keptWorkoutsPersist() throws {
        let context = try context()
        let log = SwiftDataActivityLog(context: context)

        let session = log.keep(title: "My gym session", activity: .strength, durationMin: 30, intensity: 3, now: Fixture.now)

        let kept = try context.fetch(FetchDescriptor<CustomSession>())
        #expect(kept.count == 1)
        #expect(kept.first?.session == session)
        #expect(kept.first?.session.title == "My gym session")
    }
}
