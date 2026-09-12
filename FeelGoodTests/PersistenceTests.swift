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

    @Test("A profile preserves every selected direction")
    func profileStoresMultipleIntents() throws {
        let context = try context()
        let answers = ProfileAnswers(activities: [.pilates], intents: [.strengthen, .calm])
        let profile = UserProfile(answers: answers, now: Fixture.now)
        context.insert(profile)

        #expect(profile.answers.intents == [.strengthen, .calm])
        #expect(profile.planProfile.intents == [.strengthen, .calm])
    }

    @Test("A profile preserves its mascot appearance and safely falls back from unknown values")
    func profileStoresAvatar() throws {
        let context = try context()
        let profile = UserProfile(answers: ProfileAnswers(), now: Fixture.now)
        context.insert(profile)

        profile.avatar = .blueberry
        #expect(profile.avatar == .blueberry)
        #expect(profile.avatarRaw == "blueberry")

        profile.avatarBackground = .sage
        #expect(profile.avatarBackground == .sage)
        #expect(profile.avatarBackgroundRaw == "sage")

        profile.avatarRaw = "future-fruit"
        #expect(profile.avatar == .defaultAvatar)

        profile.avatarBackgroundRaw = "future-color"
        #expect(profile.avatarBackground == .automatic)
    }

    @Test("A profile preserves optional sport details")
    func profileStoresSports() throws {
        let context = try context()
        let answers = ProfileAnswers(
            activities: [.racquet],
            sports: [.pickleball, .soccer]
        )
        let profile = UserProfile(answers: answers, now: Fixture.now)
        context.insert(profile)

        #expect(profile.answers.activities.contains(.racquet))
        #expect(profile.answers.sports == [.pickleball, .soccer])
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
        let log = SessionLog(context: context, calendar: Fixture.utc)
        let session = Fixture.catalog.first { $0.id == "a-stretch" }!

        log.recordCompletion(of: session, startedAt: Fixture.now, endedAt: Fixture.now, feel: .lovedIt)

        let records = try context.fetch(FetchDescriptor<SessionRecord>())
        #expect(records.count == 1)
        #expect(records.first?.historyEntry.wasCompleted == true)

        let scores = try context.fetch(FetchDescriptor<AffinityRecord>())
        #expect(scores.first?.score == Affinity.updated(0, after: .completed(feel: .lovedIt)))
    }

    @Test("Feedback on the same session accumulates rather than resetting")
    func affinityAccumulates() throws {
        let context = try context()
        let log = SessionLog(context: context, calendar: Fixture.utc)
        let session = Fixture.catalog.first { $0.id == "a-stretch" }!

        for _ in 0..<3 {
            log.recordCompletion(of: session, startedAt: Fixture.now, endedAt: Fixture.now, feel: .lovedIt)
        }

        let scores = try context.fetch(FetchDescriptor<AffinityRecord>())
        #expect(scores.count == 1)
        #expect((scores.first?.score ?? 0) > Affinity.updated(0, after: .completed(feel: .lovedIt)))
    }

    @Test("Saying nothing after a session writes the record and no score")
    func sayingNothingWritesNoScore() throws {
        let context = try context()
        let log = SessionLog(context: context, calendar: Fixture.utc)
        let session = Fixture.catalog.first { $0.id == "m-pilates-30" }!

        log.recordCompletion(of: session, startedAt: Fixture.now, endedAt: Fixture.now, feel: nil)

        #expect(try context.fetch(FetchDescriptor<SessionRecord>()).count == 1)
        #expect(try context.fetch(FetchDescriptor<AffinityRecord>()).isEmpty)
    }

    @Test("A kept workout survives as something the engine can offer")
    func keptWorkoutsPersist() throws {
        let context = try context()
        let log = SessionLog(context: context, calendar: Fixture.utc)

        let session = log.keep(title: "My gym session", activity: .strength, durationMin: 30, intensity: 3, now: Fixture.now)

        #expect(log.kept().count == 1)
        #expect(log.kept().first == session)
        #expect(try context.fetch(FetchDescriptor<CustomSession>()).first?.title == "My gym session")
    }

    @Test("Renaming and forgetting are somebody's own to do")
    func keptWorkoutsCanBeChanged() throws {
        let context = try context()
        let log = SessionLog(context: context, calendar: Fixture.utc)
        let session = log.keep(title: "Mine", activity: .strength, durationMin: 30, intensity: 3, now: Fixture.now)

        log.rename(session.id, to: "Thursday lifting")
        #expect(log.kept().first?.title == "Thursday lifting")

        log.forget(session.id)
        #expect(log.kept().isEmpty)
    }

    @Test("Today's answers come back on the same day and not on the next one")
    func checkInsBelongToTheirDay() throws {
        let context = try context()
        let log = SessionLog(context: context, calendar: Fixture.utc)
        let today = Fixture.utc.startOfDay(for: Fixture.now)

        log.record(PlanCheckIn(energy: .low, time: .aLittle), at: Fixture.now, dayStart: today)

        #expect(log.checkIn(on: today)?.energy == .low)
        #expect(log.checkIn(on: Fixture.utc.startOfDay(for: Fixture.daysAgo(1))) == nil)
    }

    @Test("Cloud completion identifiers are stable and session-specific")
    func completionIdentifiersAreIdempotent() {
        let first = FirestoreService.completionID(sessionID: "a/stretch", startedAt: Fixture.now)
        let retry = FirestoreService.completionID(sessionID: "a/stretch", startedAt: Fixture.now)
        let other = FirestoreService.completionID(sessionID: "a/stretch", startedAt: Fixture.daysAgo(1))

        #expect(first == retry)
        #expect(first != other)
        #expect(!first.contains("/"))
    }

    @Test("Signing out removes account data from the device")
    func accountSignOutClearsLocalData() throws {
        let context = try context()
        let profile = UserProfile(answers: ProfileAnswers(activities: [.walking]), now: Fixture.now)
        context.insert(profile)
        let log = SessionLog(context: context, calendar: Fixture.utc)
        let session = Fixture.catalog.first { $0.id == "a-stretch" }!
        log.recordCompletion(of: session, startedAt: Fixture.now, endedAt: Fixture.now, feel: nil)
        _ = log.keep(title: "My walk", activity: .walking, durationMin: 10, intensity: 1, now: Fixture.now)

        UserDefaults.standard.set("test-user", forKey: AccountDataSyncService.localOwnerKey)
        UserDefaults.standard.set(Data([1]), forKey: "FeelGood.ChatThreads.v1")

        AccountDataSyncService.clearAccountDataFromDevice(context: context)

        #expect(try context.fetch(FetchDescriptor<UserProfile>()).isEmpty)
        #expect(try context.fetch(FetchDescriptor<SessionRecord>()).isEmpty)
        #expect(try context.fetch(FetchDescriptor<CustomSession>()).isEmpty)
        #expect(AccountDataSyncService.localOwnerUID() == nil)
        #expect(UserDefaults.standard.data(forKey: "FeelGood.ChatThreads.v1") == nil)
    }
}
