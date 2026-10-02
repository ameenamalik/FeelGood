//
//  SwapTieBreakTests.swift
//  FeelGoodTests
//
//  Many sides score identically. Ranking used to fall back to the session id,
//  so the alphabetically-first one, "side-ankle-mobility-five", answered every
//  swap. These run the real catalog to pin down the replacement behaviour:
//  stable inside a day, free to vary across days.
//

import Testing
import Foundation
@testable import FeelGood

@Suite("Swap tie-break")
struct SwapTieBreakTests {

    private func input(daysFromNow days: Int = 0) -> PlanInput {
        let now = Fixture.utc.date(byAdding: .day, value: days, to: Fixture.now)!
        return PlanInput(
            profile: Fixture.profile(
                activities: [.stretching],
                preferredActivities: [.stretching],
                equipment: [.none]
            ),
            checkIn: PlanCheckIn(energy: .steady, time: .some),
            context: PlanContext(
                now: now,
                isOffline: false,
                dataSaver: false,
                scheduledSpecials: [],
                calendar: Fixture.utc
            )
        )
    }

    /// Every side a person would meet by swapping the side card until it runs out.
    private func sideSwapOrder(_ input: PlanInput, engine: PlanEngine) -> [String] {
        var menu = engine.makeMenu(input)
        guard var side = menu.items.first(where: { $0.course == .side }) else { return [] }
        var seen: Set<String> = []
        var order = [side.session.id]
        while let next = engine.alternative(for: side, onMenu: menu, input: input, alreadySeen: seen) {
            seen.insert(side.session.id)
            menu = engine.fitting(menu.replacing(side, with: next), to: input)
            side = menu.items.first(where: { $0.course == .side }) ?? next
            order.append(next.session.id)
            if order.count > 80 { break }
        }
        return order
    }

    @Test("The same day gives the same swap order every time")
    func stableWithinADay() throws {
        let engine = PlanEngine(catalog: try ContentStore.bundled().sessions)
        let first = sideSwapOrder(input(), engine: engine)
        let second = sideSwapOrder(input(), engine: engine)
        #expect(first.count > 3)
        #expect(first == second)
    }

    @Test("Tied sides come in a different order on different days")
    func tiedOrderVariesAcrossDays() throws {
        let engine = PlanEngine(catalog: try ContentStore.bundled().sessions)
        let orders = Set((0..<14).map { sideSwapOrder(input(daysFromNow: $0), engine: engine) })
        #expect(orders.count > 1, "every one of 14 days gave the same swap order")
    }

    @Test("Past the top scorers the order is not simply alphabetical")
    func notAlphabetical() throws {
        let engine = PlanEngine(catalog: try ContentStore.bundled().sessions)
        let sortedEveryDay = (0..<14).allSatisfy { day in
            let tail = Array(sideSwapOrder(input(daysFromNow: day), engine: engine).dropFirst(3))
            return tail == tail.sorted()
        }
        #expect(!sortedEveryDay)
    }
}
