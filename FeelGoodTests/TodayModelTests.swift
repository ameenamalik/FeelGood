//
//  TodayModelTests.swift
//  FeelGoodTests
//
//  The loop: what happened goes into history and affinity, and today's screen
//  does not rearrange itself underneath the person looking at it.
//

import Testing
import Foundation
@testable import FeelGood

@Suite("Today")
@MainActor
struct TodayModelTests {

    private func store(_ sessions: [Session] = Fixture.catalog) -> ContentStore {
        ContentStore(catalog: ContentCatalog(version: 1, sessions: sessions, glossary: []))
    }

    private func model(
        log: InMemoryActivityLog = InMemoryActivityLog(),
        profile: PlanProfile = Fixture.profile(),
        sessions: [Session] = Fixture.catalog
    ) -> TodayModel {
        TodayModel(
            store: store(sessions),
            profile: profile,
            checkIn: PlanCheckIn(energy: .steady, time: .some),
            log: log,
            now: Fixture.now,
            calendar: Fixture.utc
        )
    }

    @Test("Finishing something writes it down and moves affinity")
    func finishingIsRecorded() {
        let log = InMemoryActivityLog()
        let model = model(log: log)
        let session = Fixture.catalog.first { $0.id == "a-stretch" }!

        model.record(.finished(.lovedIt), for: session, startedAt: Fixture.now, now: Fixture.now)

        #expect(model.history.last?.sessionID == "a-stretch")
        #expect(model.history.last?.wasCompleted == true)
        #expect((model.affinity["a-stretch"] ?? 0) > 0)
        #expect(log.recorded.count == 1)
    }

    @Test("Leaving early is recorded, and held against nothing")
    func leavingEarlyIsNotAFailure() {
        let model = model()
        let session = Fixture.catalog.first { $0.id == "m-pilates-30" }!

        model.record(.left, for: session, startedAt: Fixture.now, now: Fixture.now)

        #expect(model.history.last?.wasCompleted == false)
        #expect(model.affinity["m-pilates-30"] == nil || model.affinity["m-pilates-30"] == 0)
    }

    @Test("What you just did does not vanish off the screen you're looking at")
    func recordingLeavesTodaysMenuAlone() {
        let model = model()
        let before = model.menu.items.map(\.id)

        for item in model.menu.items {
            model.record(.finished(.lovedIt), for: item.session, startedAt: Fixture.now, now: Fixture.now)
        }

        #expect(model.menu.items.map(\.id) == before)
    }

    @Test("Turning something down is recorded quietly")
    func swappingIsRecorded() throws {
        let log = InMemoryActivityLog()
        let model = model(log: log)
        let main = try #require(model.menu.main)
        #expect(model.canSwap(main, now: Fixture.now))

        model.swap(main, now: Fixture.now)

        #expect(model.menu.main?.session.id != main.session.id)
        #expect(log.recorded.contains { $0.session.id == main.session.id })
        #expect((model.affinity[main.session.id] ?? 0) < 0)
    }

    @Test("Logging your own workout counts toward the week without being kept")
    func loggingWithoutKeeping() {
        let log = InMemoryActivityLog()
        let model = model(log: log)

        model.log(
            LoggedWorkout(activity: .swimming, durationMin: 45, intensity: 3, isKept: false, title: "Swim"),
            now: Fixture.now
        )

        #expect(model.history.last?.activity == .swimming)
        #expect(model.history.last?.qualities.contains(.endurance) == true)
        #expect(model.ownSessions.isEmpty)
        #expect(log.kept.isEmpty)
    }

    @Test("Keeping one puts it on a later menu")
    func keepingAddsItToThePool() {
        // A profile with nothing but a floor, and a catalog whose only main
        // needs a mat: the kept workout is the one thing that can be offered.
        let profile = Fixture.profile(activities: [.strength], equipment: [.none], intent: .strengthen)
        let model = model(
            profile: profile,
            sessions: Fixture.catalog.filter { $0.course != .main } + [
                Fixture.session(id: "m-mat-only", activity: .pilates, qualities: [.strength],
                                durationMin: 30, intensity: 3, course: .main, equipment: [.mat])
            ]
        )
        #expect(model.menu.main == nil)

        model.log(
            LoggedWorkout(activity: .strength, durationMin: 30, intensity: 3, isKept: true, title: "My gym session"),
            now: Fixture.now
        )
        // The menu regenerates on the next check-in, not underfoot.
        model.apply(PlanCheckIn(energy: .strong, time: .plenty), now: Fixture.now)

        #expect(model.menu.main?.session.title == "My gym session")
    }

    @Test("The Library browses exactly what the engine picks from")
    func everythingIsEverything() {
        let model = model()
        #expect(Set(model.everything.map(\.id)) == Set(Fixture.catalog.map(\.id)))

        model.log(
            LoggedWorkout(activity: .strength, durationMin: 30, intensity: 3, isKept: true, title: "Mine"),
            now: Fixture.now
        )
        #expect(model.everything.contains { $0.title == "Mine" })
    }

    @Test("A kept workout can be renamed")
    func keptWorkoutsCanBeRenamed() throws {
        let log = InMemoryActivityLog()
        let model = model(log: log)
        model.log(
            LoggedWorkout(activity: .strength, durationMin: 30, intensity: 3, isKept: true, title: "Mine"),
            now: Fixture.now
        )
        let kept = try #require(model.ownSessions.first)

        model.rename(kept, to: "Thursday lifting")

        #expect(model.ownSessions.first?.title == "Thursday lifting")
        #expect(model.ownSessions.first?.id == kept.id)
        #expect(log.renamed[kept.id] == "Thursday lifting")
        // An empty name is a slip, not an instruction.
        model.rename(kept, to: "   ")
        #expect(model.ownSessions.first?.title == "Thursday lifting")
    }

    @Test("Forgetting a kept workout stops it being offered but not from having happened")
    func keptWorkoutsCanBeForgotten() throws {
        let log = InMemoryActivityLog()
        let model = model(log: log)
        model.log(
            LoggedWorkout(activity: .strength, durationMin: 30, intensity: 3, isKept: true, title: "Mine"),
            now: Fixture.now
        )
        let kept = try #require(model.ownSessions.first)

        model.forget(kept, now: Fixture.now)

        #expect(model.ownSessions.isEmpty)
        #expect(!model.everything.contains { $0.id == kept.id })
        #expect(log.forgotten == [kept.id])
        // The day it was done is still in history.
        #expect(model.history.contains { $0.sessionID == kept.id })
    }

    @Test("Changing the profile updates today's menu without losing the check-in")
    func editingTheProfileKeepsTheDay() {
        // Nothing but a floor: the fixture catalog has no main that fits.
        let model = model(profile: Fixture.profile(activities: [.stretching], equipment: [.none]))
        let checkIn = model.checkIn
        #expect(model.menu.main == nil)

        model.update(profile: Fixture.profile(activities: [.pilates], equipment: [.none, .mat]), now: Fixture.now)

        #expect(model.checkIn == checkIn)
        #expect(model.menu.main?.session.activity == .pilates)
    }
}
