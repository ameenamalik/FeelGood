//
//  PlanMemoryTests.swift
//  FeelGoodTests
//

import Testing
import Foundation
@testable import FeelGood

@Suite("Plan Memory & Tier Split")
struct PlanMemoryTests {

    @Test("Free tier with recencyOnly recognizes gap and returns returningAfterGap reason")
    func recencyOnlyRecognizesGap() {
        let sixDaysAgo = Fixture.daysAgo(6)

        let input = PlanInput(
            profile: Fixture.profile(),
            checkIn: PlanCheckIn(energy: .low, time: .fifteenMinutes),
            memory: .recencyOnly(lastActiveDate: sixDaysAgo),
            context: Fixture.context()
        )

        let menu = Fixture.engine.makeMenu(input)

        // The returningAfterGap reason code must be present for a user returning after a gap
        let allReasons = menu.items.flatMap(\.reasons)
        #expect(allReasons.contains(.returningAfterGap))
    }

    @Test("Free tier with recencyOnly ignores history variety and recovery downweighting")
    func recencyOnlyIgnoresHistory() {
        let input = PlanInput(
            profile: Fixture.profile(),
            checkIn: PlanCheckIn(energy: .steady, time: .twentyMinutes),
            memory: .recencyOnly(lastActiveDate: Fixture.daysAgo(1)),
            context: Fixture.context()
        )

        let stats = HistoryStats(input: input)
        #expect(stats.recoveryOwed == false)
        #expect(stats.derivedAffinity.isEmpty)
        #expect(stats.recentActivityCounts.isEmpty)
    }

    @Test("Pro tier with full memory calculates recovery balance and affinity")
    func fullMemoryCalculatesRecoveryAndAffinity() {
        let hardYesterday = Fixture.completed("s-hard-1", activity: .strength, intensity: 5, daysAgo: 1)
        let hardDayBefore = Fixture.completed("s-hard-2", activity: .strength, intensity: 5, daysAgo: 2)

        let input = PlanInput(
            profile: Fixture.profile(),
            checkIn: PlanCheckIn(energy: .steady, time: .twentyMinutes),
            memory: .full(
                history: [hardYesterday, hardDayBefore],
                affinity: ["s-loved": 0.8]
            ),
            context: Fixture.context()
        )

        let stats = HistoryStats(input: input)
        #expect(stats.recoveryOwed == true)
        #expect(input.affinity["s-loved"] == 0.8)
    }
}
