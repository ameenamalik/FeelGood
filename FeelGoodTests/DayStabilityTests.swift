//
//  DayStabilityTests.swift
//  FeelGoodTests
//
//  Reopening the app is the same day, not a fresh guess at it. The menu was
//  chosen for you; quietly choosing again while you were away undoes the whole
//  claim. See PRD §7.2a.
//

import Testing
import Foundation
import SwiftData
@testable import FeelGood

@Suite("The day holds")
@MainActor
struct DayStabilityTests {

    private func context() throws -> ModelContext {
        let container = try ModelContainer(
            for: Schema(FeelGoodSchema.models),
            configurations: [ModelConfiguration(isStoredInMemoryOnly: true)]
        )
        return ModelContext(container)
    }

    private func store(_ sessions: [Session] = Fixture.catalog) -> ContentStore {
        ContentStore(catalog: ContentCatalog(version: 1, sessions: sessions, glossary: []))
    }

    private func model(
        log: any SessionLogging = InMemorySessionLog(),
        checkIn: PlanCheckIn? = PlanCheckIn(energy: .steady, time: .some),
        now: Date = Fixture.now
    ) -> TodayModel {
        TodayModel(
            store: store(),
            profile: Fixture.profile(),
            log: log,
            checkIn: checkIn,
            now: now,
            calendar: Fixture.utc
        )
    }

    // MARK: - Round trip

    @Test("A stored day rebuilds into the menu that was shown")
    func storedDayRebuildsExactly() throws {
        let context = try context()
        let log = SessionLog(context: context, calendar: Fixture.utc)
        let original = model().menu

        log.save(original, generatedAt: Fixture.now)

        let catalog = store()
        let restored = log.day(original.dayStart) { catalog.session(id: $0) }

        #expect(restored == original)
        #expect(restored?.items.map(\.reasonText) == original.items.map(\.reasonText))
    }

    @Test("Only one day is ever stored for one day")
    func savingTwiceReplacesTheDay() throws {
        let context = try context()
        let log = SessionLog(context: context, calendar: Fixture.utc)
        let model = model()

        log.save(model.menu, generatedAt: Fixture.now)
        model.apply(PlanCheckIn(energy: .low, time: .aLittle), now: Fixture.now)
        log.save(model.menu, generatedAt: Fixture.now)

        #expect(try context.fetch(FetchDescriptor<PlanDay>()).count == 1)
        // The replaced day took its items with it rather than orphaning them.
        #expect(try context.fetch(FetchDescriptor<PlanItem>()).count == model.menu.items.count)
    }

    @Test("A session the catalog no longer carries leaves a gap, not a crash")
    func missingSessionsAreSkipped() throws {
        let context = try context()
        let log = SessionLog(context: context, calendar: Fixture.utc)
        let original = model().menu
        log.save(original, generatedAt: Fixture.now)

        let thinned = store(Fixture.catalog.filter { $0.course != .main })
        let restored = log.day(original.dayStart) { thinned.session(id: $0) }

        #expect(restored?.main == nil)
        #expect(restored?.items.count == original.items.count - 1)
    }

    // MARK: - Restoring

    @Test("Today's stored menu is shown again rather than regenerated")
    func todaysMenuIsRestored() {
        let log = InMemorySessionLog()
        let first = model(log: log, checkIn: nil)
        first.apply(PlanCheckIn(energy: .low, time: .aLittle), now: Fixture.now)

        let reopened = model(log: log, checkIn: nil)

        #expect(reopened.menu == first.menu)
        // ...and the answers already given today are not asked for again.
        #expect(reopened.checkIn == first.checkIn)
    }

    @Test("Yesterday's menu is not today's")
    func yesterdaysMenuIsNotRestored() {
        let log = InMemorySessionLog()
        let yesterday = model(log: log, now: Fixture.daysAgo(1)).menu

        let today = model(log: log)

        #expect(today.menu.dayStart != yesterday.dayStart)
        #expect(today.menu.dayStart == Fixture.utc.startOfDay(for: Fixture.now))
    }

    @Test("Generating a day stores it; restoring one does not store it again")
    func generatingStoresTheDay() {
        let fresh = InMemorySessionLog()
        _ = model(log: fresh)
        #expect(fresh.savedDays.count == 1)

        _ = model(log: fresh)
        #expect(fresh.savedDays.count == 1, "the second launch restored rather than regenerated")
    }

    // MARK: - What re-saves the day

    @Test("A check-in is recorded and re-stores the day")
    func checkingInStoresTheDay() {
        let log = InMemorySessionLog()
        let model = model(log: log, checkIn: nil)

        model.apply(PlanCheckIn(energy: .low, time: .aLittle), now: Fixture.now)

        #expect(log.checkIns.count == 1)
        #expect(log.savedDays.count == 2)
        #expect(log.savedDays.last == model.menu)
    }

    @Test("A swap stays swapped when you come back to it")
    func swappingStoresTheDay() throws {
        let log = InMemorySessionLog()
        let today = model(log: log)
        let main = try #require(today.menu.main)
        #expect(today.canSwap(main, now: Fixture.now))

        today.swap(main, now: Fixture.now)

        #expect(log.savedDays.last?.main?.session.id != main.session.id)
        #expect(model(log: log, checkIn: nil).menu.main?.session.id != main.session.id)
    }

    @Test("Editing the profile replaces the stored day")
    func editingTheProfileStoresTheDay() {
        let log = InMemorySessionLog()
        let model = model(log: log)

        model.update(profile: Fixture.profile(activities: [.pilates], equipment: [.none, .mat]), now: Fixture.now)

        #expect(log.savedDays.last == model.menu)
    }

    @Test("The stored day belongs to the local day, not to UTC")
    func theDayFollowsTheUsersCalendar() {
        var honolulu = Calendar(identifier: .gregorian)
        honolulu.timeZone = TimeZone(identifier: "Pacific/Honolulu")!
        // 09:00 UTC on the 20th is still the evening of the 19th in Honolulu.
        let model = TodayModel(
            store: store(),
            profile: Fixture.profile(),
            now: Fixture.now,
            calendar: honolulu
        )

        #expect(model.menu.dayStart == honolulu.startOfDay(for: Fixture.now))
        #expect(model.menu.dayStart != Fixture.utc.startOfDay(for: Fixture.now))
    }
}
