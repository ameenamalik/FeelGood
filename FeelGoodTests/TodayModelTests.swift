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
        log: InMemorySessionLog = InMemorySessionLog(),
        progressStore: InMemorySessionProgressStore = InMemorySessionProgressStore(),
        profile: PlanProfile = Fixture.profile(),
        sessions: [Session] = Fixture.catalog
    ) -> TodayModel {
        TodayModel(
            store: store(sessions),
            profile: profile,
            log: log,
            progressStore: progressStore,
            checkIn: PlanCheckIn(energy: .steady, time: .some),
            now: Fixture.now,
            calendar: Fixture.utc
        )
    }

    @Test("Leaving a workout saves progress without completing it")
    func leavingSavesProgressWithoutCompletion() {
        let log = InMemorySessionLog()
        let progressStore = InMemorySessionProgressStore()
        let model = model(log: log, progressStore: progressStore)
        let session = Fixture.catalog.first { !$0.source.steps.isEmpty }!
        let progress = SessionProgress(stepIndex: 1, remainingSeconds: 24, startedAt: Fixture.now)
        let item = MenuItem(session: session, course: session.course, reasons: [], reasonText: "")

        model.pause(session, at: progress)

        #expect(model.progress(for: session) == progress)
        #expect(model.inProgressSessionIDs.contains(session.id))
        #expect(model.isInProgress(item))
        #expect(!model.isCompleted(item))
        #expect(log.entries.isEmpty)
    }

    @Test("Finishing a resumed workout clears its saved progress")
    func finishingClearsProgress() {
        let progressStore = InMemorySessionProgressStore()
        let model = model(progressStore: progressStore)
        let session = Fixture.catalog.first { !$0.source.steps.isEmpty }!
        model.pause(
            session,
            at: SessionProgress(stepIndex: 1, remainingSeconds: 24, startedAt: Fixture.now)
        )

        model.complete(session, startedAt: Fixture.now, feel: .fine, now: Fixture.now)

        #expect(model.progress(for: session) == nil)
        #expect(!model.inProgressSessionIDs.contains(session.id))
    }

    @Test("Saved progress is visible again when Today is recreated")
    func savedProgressSurvivesRecreation() {
        let progressStore = InMemorySessionProgressStore()
        let session = Fixture.catalog.first { !$0.source.steps.isEmpty }!
        progressStore.save(
            SessionProgress(stepIndex: 1, remainingSeconds: 24, startedAt: Fixture.now),
            for: session.id
        )

        let recreated = model(progressStore: progressStore)
        let item = MenuItem(session: session, course: session.course, reasons: [], reasonText: "")

        #expect(recreated.isInProgress(item))
    }

    @Test("Finishing something writes it down and moves affinity")
    func finishingIsRecorded() {
        let log = InMemorySessionLog()
        let model = model(log: log)
        let session = Fixture.catalog.first { $0.id == "a-stretch" }!

        model.complete(session, startedAt: Fixture.now, feel: .lovedIt, now: Fixture.now)

        #expect(model.history.last?.sessionID == "a-stretch")
        #expect(model.history.last?.wasCompleted == true)
        #expect((log.affinity()["a-stretch"] ?? 0) > 0)
        #expect(model.isCompleted(MenuItem(session: session, course: .appetizer, reasons: [], reasonText: "")))
    }

    @Test("Saying nothing about how it felt is still having done it")
    func finishingWithoutAnAnswerStillCounts() {
        let log = InMemorySessionLog()
        let model = model(log: log)
        let session = Fixture.catalog.first { $0.id == "m-pilates-30" }!

        model.complete(session, startedAt: Fixture.now, feel: nil, now: Fixture.now)

        #expect(model.history.last?.wasCompleted == true)
        // No answer is not a verdict either way.
        #expect(log.affinity()["m-pilates-30"] == nil)
    }

    @Test("What you just did does not vanish off the screen you're looking at")
    func recordingLeavesTodaysMenuAlone() {
        let model = model()
        let before = model.menu.items.map(\.id)

        for item in model.menu.items {
            model.complete(item.session, startedAt: Fixture.now, feel: .lovedIt, now: Fixture.now)
        }

        #expect(model.menu.items.map(\.id) == before)
    }

    @Test("Turning something down is recorded quietly")
    func swappingIsRecorded() throws {
        let log = InMemorySessionLog()
        let model = model(log: log)
        let main = try #require(model.menu.main)
        #expect(model.canSwap(main, now: Fixture.now))

        model.swap(main, now: Fixture.now)

        #expect(model.menu.main?.session.id != main.session.id)
        #expect((log.affinity()[main.session.id] ?? 0) < 0)
    }

    @Test("Logging your own workout counts toward the week without being kept")
    func loggingWithoutKeeping() {
        let log = InMemorySessionLog()
        let model = model(log: log)

        model.log(
            LoggedWorkout(activity: .swimming, durationMin: 45, intensity: 3, isKept: false, title: "Swim"),
            now: Fixture.now
        )

        #expect(model.history.last?.activity == .swimming)
        #expect(model.history.last?.qualities.contains(.endurance) == true)
        #expect(model.ownSessions.isEmpty)
        #expect(log.keptSessions.isEmpty)
    }

    @Test("Keeping one puts it on a later menu")
    func keepingAddsItToThePool() {
        // A profile with nothing but a floor, and a catalog whose only main
        // needs a mat: the kept workout is the one thing that can be offered.
        let profile = Fixture.profile(
            activities: [.strength],
            equipment: [.none],
            places: [.home],
            intent: .strengthen
        )
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
        let log = InMemorySessionLog()
        let model = model(log: log)
        model.log(
            LoggedWorkout(activity: .strength, durationMin: 30, intensity: 3, isKept: true, title: "Mine"),
            now: Fixture.now
        )
        let kept = try #require(model.ownSessions.first)

        model.rename(kept, to: "Thursday lifting")

        #expect(model.ownSessions.first?.title == "Thursday lifting")
        #expect(model.ownSessions.first?.id == kept.id)
        // An empty name is a slip, not an instruction.
        model.rename(kept, to: "   ")
        #expect(model.ownSessions.first?.title == "Thursday lifting")
    }

    @Test("Forgetting a kept workout stops it being offered but not from having happened")
    func keptWorkoutsCanBeForgotten() throws {
        let log = InMemorySessionLog()
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
        let model = model(profile: Fixture.profile(activities: [.stretching], equipment: [.none], places: [.home]))
        let checkIn = model.checkIn
        #expect(model.menu.main == nil)

        model.update(
            profile: Fixture.profile(activities: [.pilates], equipment: [.none, .mat], places: [.home]),
            now: Fixture.now
        )

        #expect(model.checkIn == checkIn)
        #expect(model.menu.main?.session.activity == .pilates)
    }

    @Test("Shuffling cycles back to earlier options when unseen alternatives are exhausted")
    func shufflingCyclesBackWhenOptionsAreExhausted() throws {
        let log = InMemorySessionLog()
        let model = model(log: log)
        let main = try #require(model.menu.main)
        let firstID = main.session.id

        // Swap to the next option
        #expect(!model.isCycleReset(main, now: Fixture.now))
        model.swap(main, now: Fixture.now)
        let secondMain = try #require(model.menu.main)
        #expect(secondMain.session.id != firstID)

        // Keep swapping until we reach the end of unseen options
        while !model.isCycleReset(model.menu.main!, now: Fixture.now) {
            model.swap(model.menu.main!, now: Fixture.now)
        }

        let atEnd = try #require(model.menu.main)
        #expect(model.canSwap(atEnd, now: Fixture.now))
        #expect(model.isCycleReset(atEnd, now: Fixture.now))

        // Swap once more to trigger "Start over" / cycle reset
        model.swap(atEnd, now: Fixture.now)
        let cycledMain = try #require(model.menu.main)
        #expect(cycledMain.session.id != atEnd.session.id)
    }
}
