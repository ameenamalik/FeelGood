//
//  SessionLogTests.swift
//  FeelGoodTests
//
//  Runs against a real SwiftData store held in memory, so these exercise the
//  actual persistence path rather than a stand-in.
//

import Testing
import Foundation
import SwiftData
@testable import FeelGood

@Suite("Session log")
@MainActor
struct SessionLogTests {

    private func makeLog() throws -> (SessionLog, ModelContext) {
        let container = try ModelContainer(
            for: Schema(FeelGoodSchema.models),
            configurations: [ModelConfiguration(isStoredInMemoryOnly: true)]
        )
        let context = ModelContext(container)
        return (SessionLog(context: context, calendar: Fixture.utc), context)
    }

    private var session: Session {
        Fixture.catalog.first { $0.id == "m-pilates-10" }!
    }

    @Test("A completed session shows up in history")
    func completionIsRecorded() throws {
        let (log, _) = try makeLog()
        log.recordCompletion(
            of: session,
            startedAt: Fixture.now.addingTimeInterval(-600),
            endedAt: Fixture.now,
            feel: .lovedIt
        )

        let history = log.history(before: Fixture.now.addingTimeInterval(60))
        #expect(history.count == 1)
        #expect(history.first?.sessionID == "m-pilates-10")
        #expect(history.first?.wasCompleted == true)
        #expect(history.first?.activity == .pilates)
    }

    @Test("Finishing without answering the reflection still counts")
    func completionWithoutFeelStillCounts() throws {
        let (log, _) = try makeLog()
        log.recordCompletion(of: session, startedAt: Fixture.now, endedAt: Fixture.now, feel: nil)

        #expect(log.history(before: Fixture.now.addingTimeInterval(60)).first?.wasCompleted == true)
        // No opinion given, so no opinion recorded.
        #expect(log.affinity().isEmpty)
    }

    @Test("Loving something raises it; finding it too much lowers it")
    func feelMovesAffinity() throws {
        let (log, _) = try makeLog()

        log.recordCompletion(of: session, startedAt: Fixture.now, endedAt: Fixture.now, feel: .lovedIt)
        let loved = try #require(log.affinity()["m-pilates-10"])
        #expect(loved > 0)

        log.recordCompletion(of: session, startedAt: Fixture.now, endedAt: Fixture.now, feel: .tooMuch)
        let evened = try #require(log.affinity()["m-pilates-10"])
        #expect(evened < loved)
    }

    @Test("Affinity accumulates but never runs away")
    func affinityIsClamped() throws {
        let (log, _) = try makeLog()
        for _ in 0..<40 {
            log.recordCompletion(of: session, startedAt: Fixture.now, endedAt: Fixture.now, feel: .lovedIt)
        }
        let score = try #require(log.affinity()["m-pilates-10"])
        #expect(score <= 1.0)
        #expect(score > 0.5)
    }

    @Test("A swap is recorded as a preference, not as a failure")
    func swapIsRecorded() throws {
        let (log, _) = try makeLog()
        log.recordSwap(of: session, at: Fixture.now)

        let entry = try #require(log.history(before: Fixture.now.addingTimeInterval(60)).first)
        #expect(entry.outcome == .swappedAway)
        #expect(!entry.wasCompleted)
        let score = try #require(log.affinity()["m-pilates-10"])
        #expect(score < 0)
    }

    @Test("History older than the engine's window is not returned")
    func historyWindowIsRespected() throws {
        let (log, _) = try makeLog()
        let longAgo = Fixture.daysAgo(PlanEngine.historyWindowDays + 5)
        log.recordCompletion(of: session, startedAt: longAgo, endedAt: longAgo, feel: .fine)
        log.recordCompletion(of: session, startedAt: Fixture.now, endedAt: Fixture.now, feel: .fine)

        #expect(log.history(before: Fixture.now.addingTimeInterval(60)).count == 1)
    }

    @Test("What gets logged is what the engine reads back")
    func loggedHistoryFeedsTheEngine() throws {
        let (log, _) = try makeLog()
        // Two hard days in a row, recorded through the real path.
        let hard = Fixture.catalog.first { $0.id == "m-strength-30" }!
        for daysAgo in [1, 2] {
            log.recordCompletion(
                of: hard,
                startedAt: Fixture.daysAgo(daysAgo),
                endedAt: Fixture.daysAgo(daysAgo),
                feel: .fine
            )
        }

        let input = PlanInput(
            profile: Fixture.profile(),
            checkIn: PlanCheckIn(energy: .strong, time: .plenty),
            history: log.history(before: Fixture.now),
            context: Fixture.context(),
            affinity: log.affinity()
        )
        let menu = Fixture.engine.makeMenu(input)

        // The engine should now be easing off, from persisted history alone.
        #expect(menu.reasonCodes.contains(.recoveryBalance))
    }
}
