//
//  SchemaMigrationTests.swift
//  FeelGoodTests
//
//  A schema change must never be the reason somebody loses two months of their
//  own history. These tests cover the two ways that happens: a store that no
//  longer opens, and a store that opens into something that quietly discards it.
//

import Testing
import Foundation
import SwiftData
@testable import FeelGood

@Suite("Schema and migration")
@MainActor
struct SchemaMigrationTests {

    private func temporaryDirectory() throws -> URL {
        let url = URL.temporaryDirectory.appending(path: "feelgood-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    /// Writes one of everything, so a migration that drops a model is caught by
    /// the round trip rather than by somebody noticing months later.
    private func seed(_ context: ModelContext) {
        context.insert(UserProfile(answers: ProfileAnswers(activities: [.pilates], equipment: [.none, .gym]), now: Fixture.now))
        context.insert(CheckInRecord(checkIn: PlanCheckIn(energy: .low, time: .aLittle), takenAt: Fixture.now, dayStart: Fixture.now))
        context.insert(CustomSession(title: "Mine", activity: .strength, durationMin: 30, intensity: 3, createdAt: Fixture.now))
        context.insert(AffinityRecord(sessionID: "a-stretch", score: 0.5, updatedAt: Fixture.now))
        context.insert(
            SessionRecord(
                session: Fixture.catalog.first { $0.id == "a-stretch" }!,
                startedAt: Fixture.now,
                dayStart: Fixture.now,
                endedAt: Fixture.now,
                outcome: .completed(feel: .lovedIt)
            )
        )
        context.insert(ContentVersionRecord(version: 2, seededAt: Fixture.now))
        context.insert(BanditStateRecord(state: BanditState(), updatedAt: Fixture.now))
        try? context.save()
    }

    // MARK: - The shape itself

    @Test("The versioned schema is what the app actually persists")
    func versionedSchemaCarriesEveryModel() {
        let entities = Set(FeelGoodSchema.schema.entities.map(\.name))
        let expected: Set<String> = [
            "UserProfile", "CheckInRecord", "PlanDay", "PlanItem",
            "SessionRecord", "AffinityRecord", "CustomSession", "ContentVersionRecord",
            "BanditStateRecord"
        ]
        #expect(entities == expected)
        #expect(FeelGoodSchemaV1.versionIdentifier == Schema.Version(1, 0, 0))
    }

    @Test("Every version the plan knows about is reachable in order")
    func migrationPlanIsWellFormed() {
        #expect(FeelGoodMigrationPlan.schemas.count == FeelGoodMigrationPlan.stages.count + 1,
                "each stage moves between two versions, so there is always one more schema than stages")
        #expect(FeelGoodMigrationPlan.schemas.last?.versionIdentifier == FeelGoodSchema.Current.versionIdentifier,
                "the plan must end on the version this build is written against")
    }

    // MARK: - Nothing is lost on the way through

    @Test("A store survives being closed and opened again")
    func storeRoundTripsThroughTheMigrationPlan() throws {
        let directory = try temporaryDirectory()
        let url = directory.appending(path: "default.store")

        // Held for the length of the test on purpose: SwiftData will take a
        // second container on the same store, but releasing the first one while
        // the second is live takes the process down with it. The app only ever
        // opens one container per store, so this is a test-shape concern.
        let first = Storage.open(at: url)
        seed(first.container.mainContext)

        // A second open is what every launch after the first one is.
        let reopened = Storage.open(at: url)
        #expect(!reopened.isEphemeral)

        let context = reopened.container.mainContext
        #expect(try context.fetch(FetchDescriptor<UserProfile>()).count == 1)
        #expect(try context.fetch(FetchDescriptor<SessionRecord>()).count == 1)
        #expect(try context.fetch(FetchDescriptor<CustomSession>()).first?.title == "Mine")
        #expect(try context.fetch(FetchDescriptor<AffinityRecord>()).first?.score == 0.5)
        #expect(try context.fetch(FetchDescriptor<UserProfile>()).first?.answers.equipment.contains(.gym) == true)
        withExtendedLifetime(first) {}
    }

    @Test("A store written before the migration plan existed still opens")
    func storesFromBeforeThePlanAreNotStranded() throws {
        // Exactly how every store on a device today was made: no plan, no
        // version identifier. Introducing one must not strand them.
        let directory = try temporaryDirectory()
        let url = directory.appending(path: "default.store")
        let schema = Schema(FeelGoodSchema.models)
        let legacy = try ModelContainer(
            for: schema,
            configurations: [ModelConfiguration(schema: schema, url: url)]
        )
        seed(legacy.mainContext)

        let opened = Storage.open(at: url)

        #expect(!opened.isEphemeral)
        #expect(try opened.container.mainContext.fetch(FetchDescriptor<UserProfile>()).count == 1)
    }

    // MARK: - When it cannot be opened

    @Test("A store that won't open falls back to memory and says so")
    func unopenableStoreIsEphemeralRatherThanSilent() throws {
        let directory = try temporaryDirectory()
        // A file cannot contain a directory, so this path can never be opened.
        let blocker = directory.appending(path: "not-a-directory")
        let contents = Data("somebody's history lives here".utf8)
        try contents.write(to: blocker)

        let opened = Storage.open(at: blocker.appending(path: "default.store"))

        #expect(opened.isEphemeral)
        // Usable anyway: there is still a menu today.
        opened.container.mainContext.insert(
            UserProfile(answers: ProfileAnswers(activities: [.walking]), now: Fixture.now)
        )
        #expect(try opened.container.mainContext.fetch(FetchDescriptor<UserProfile>()).count == 1)
    }

    @Test("Failing to open a store never touches what is on disk")
    func failureIsNeverDestructive() throws {
        let directory = try temporaryDirectory()
        let blocker = directory.appending(path: "not-a-directory")
        let contents = Data("somebody's history lives here".utf8)
        try contents.write(to: blocker)

        _ = Storage.open(at: blocker.appending(path: "default.store"))

        // The rule this whole file exists for: recovery never deletes.
        #expect(FileManager.default.fileExists(atPath: blocker.path()))
        #expect(try Data(contentsOf: blocker) == contents)
    }
}
