//
//  LittleWinsTests.swift
//  FeelGoodTests
//

import Foundation
import Testing
@testable import FeelGood

@Suite("Little Wins")
struct LittleWinsTests {
    @Test("Each milestone is derived from completed history")
    func milestonesUnlockFromHistory() throws {
        let history = [
            entry("home-yoga-1", activity: .yoga, duration: 5, place: .home, day: 6),
            entry("home-yoga-2", activity: .yoga, duration: 5, place: .home, day: 5),
            entry("home-yoga-3", activity: .yoga, duration: 5, place: .home, day: 4),
            entry("home-yoga-4", activity: .yoga, duration: 5, place: .home, day: 3),
            entry("home-yoga-5", activity: .yoga, duration: 5, place: .home, day: 2),
            entry("gym-strength-1", activity: .strength, duration: 30, place: .gym, day: 5),
            entry("gym-strength-2", activity: .strength, duration: 30, place: .gym, day: 4),
            entry("gym-strength-3", activity: .strength, duration: 30, place: .gym, day: 3),
            entry("gym-strength-4", activity: .strength, duration: 30, place: .gym, day: 2),
            entry("gym-strength-5", activity: .strength, duration: 30, place: .gym, day: 1),
            entry("outside-walk", activity: .walking, duration: 20, place: .outdoors, day: 0),
        ]

        let progress = Dictionary(
            uniqueKeysWithValues: LittleWins.progress(in: history).map { ($0.win, $0) }
        )

        for win in LittleWin.allCases {
            #expect(try #require(progress[win]).isUnlocked)
        }
    }

    @Test("Partial progress is factual and non-completions do not count")
    func partialProgress() throws {
        var swapped = entry("not-done", activity: .yoga, duration: 5, place: .home, day: 0)
        swapped.outcome = .swappedAway
        let history = [
            entry("yoga", activity: .yoga, duration: 10, place: .home, day: 2),
            entry("strength", activity: .strength, duration: 30, place: .gym, day: 1),
            swapped,
        ]

        let progress = Dictionary(
            uniqueKeysWithValues: LittleWins.progress(in: history).map { ($0.win, $0) }
        )

        #expect(try #require(progress[.firstMove]).isUnlocked)
        #expect(try #require(progress[.homebody]).current == 1)
        #expect(try #require(progress[.gymRegular]).current == 1)
        #expect(try #require(progress[.yogaEra]).current == 1)
        #expect(try #require(progress[.tinyWins]).current == 0)
        #expect(try #require(progress[.varietyPack]).current == 2)
    }

    @Test("Old records can recover authored duration from the catalog")
    func oldDurationIsEnriched() throws {
        let shortSession = Fixture.catalog.first { $0.id == "a-stretch" }!
        let oldEntries = (0..<5).map { day in
            entry(shortSession.id, activity: .stretching, duration: 0, place: .home, day: day)
        }

        let tiny = try #require(
            LittleWins.progress(in: oldEntries, sessions: Fixture.catalog)
                .first { $0.win == .tinyWins }
        )
        #expect(tiny.isUnlocked)
    }

    private func entry(
        _ id: String,
        activity: Activity,
        duration: Int,
        place: Place?,
        day: Int
    ) -> HistoryEntry {
        HistoryEntry(
            sessionID: id,
            activity: activity,
            qualities: [],
            intensity: 2,
            course: .main,
            durationMin: duration,
            place: place,
            date: Fixture.daysAgo(day),
            outcome: .completed(feel: nil)
        )
    }
}
