//
//  PostPurchaseTests.swift
//  FeelGoodTests
//
//  The reminder moment and the first-move pick, both pure so they run
//  without a notification prompt or a purchase.
//

import Testing
import Foundation
@testable import FeelGood

@Suite("Trial reminder plan")
struct TrialReminderPlanTests {
    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }()

    private func date(_ day: Int, _ hour: Int, _ minute: Int = 0) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: 11, day: day, hour: hour, minute: minute))!
    }

    @Test("Reminds one day before the trial ends, at the same time of day")
    func oneDayBefore() {
        let fire = TrialReminderPlan.fireDate(trialEnd: date(9, 15), now: date(2, 15), calendar: calendar)
        #expect(fire == date(8, 15))
    }

    @Test("A late-night trial end moves the reminder into waking hours")
    func clampsLateNight() {
        let late = TrialReminderPlan.fireDate(trialEnd: date(9, 23, 30), now: date(2, 23), calendar: calendar)
        #expect(late == date(8, 20))
    }

    @Test("An early-morning trial end moves the reminder to nine")
    func clampsEarlyMorning() {
        let early = TrialReminderPlan.fireDate(trialEnd: date(9, 3), now: date(2, 3), calendar: calendar)
        #expect(early == date(8, 9))
    }

    @Test("No reminder when the moment has already passed")
    func skipsPastMoment() {
        // Bought with under a day left: the reminder time is behind us.
        #expect(TrialReminderPlan.fireDate(trialEnd: date(9, 15), now: date(8, 18), calendar: calendar) == nil)
    }

    @Test("Only a trial that will renew is reminded about")
    func onlyConvertingTrials() {
        let end = date(9, 15)
        #expect(TrialReminderPlan.shouldRemind(ProSubscriptionStatus(phase: .trial, willRenew: true, expirationDate: end)))
        #expect(!TrialReminderPlan.shouldRemind(ProSubscriptionStatus(phase: .trial, willRenew: false, expirationDate: end)))
        #expect(!TrialReminderPlan.shouldRemind(ProSubscriptionStatus(phase: .active, willRenew: true, expirationDate: end)))
        #expect(!TrialReminderPlan.shouldRemind(ProSubscriptionStatus(phase: .billingIssue, willRenew: true, expirationDate: end)))
        #expect(!TrialReminderPlan.shouldRemind(ProSubscriptionStatus(phase: .trial, willRenew: true, expirationDate: nil)))
    }

    @Test("The copy names the price when it has one and stays true when it does not")
    func copy() {
        #expect(TrialReminderPlan.content(price: "$34.99 a year").body.contains("$34.99 a year"))
        let generic = TrialReminderPlan.content(price: nil).body
        #expect(!generic.contains("$"))
        #expect(generic.contains("renews"))
    }
}

@Suite("First move")
struct FirstMoveTests {
    @Test("Picks only short, gentle, equipment-free appetizers that are safe for everyone")
    func eligibility() {
        var sessions: [Session] = []
        sessions.append(Fixture.session(id: "a-good", activity: .qigong, durationMin: 5, intensity: 1, course: .appetizer))
        sessions.append(Fixture.session(id: "a-long", activity: .qigong, durationMin: 8, intensity: 1, course: .appetizer))
        sessions.append(Fixture.session(id: "a-hard", activity: .strength, durationMin: 5, intensity: 4, course: .appetizer))
        sessions.append(Fixture.session(id: "a-gear", activity: .jumpRope, durationMin: 3, intensity: 1, course: .appetizer, equipment: [.rope]))
        sessions.append(Fixture.session(id: "a-pool", activity: .swimming, durationMin: 5, intensity: 1, course: .appetizer, places: [.pool]))
        sessions.append(Fixture.session(id: "a-flagged", activity: .stretching, durationMin: 5, intensity: 1, course: .appetizer, contraindications: [.pregnancy]))
        sessions.append(Fixture.session(id: "m-main", activity: .yoga, durationMin: 5, intensity: 1, course: .main))
        sessions.append(Fixture.session(id: "a-video", activity: .yoga, durationMin: 5, intensity: 1, course: .appetizer, video: true))

        let picked = FirstMove.candidates(from: sessions).map(\.id)
        #expect(picked == ["a-good"])
    }

    @Test("Easiest first, then closest to five minutes")
    func ordering() {
        var sessions: [Session] = []
        sessions.append(Fixture.session(id: "a-3min", activity: .qigong, durationMin: 3, intensity: 1, course: .appetizer))
        sessions.append(Fixture.session(id: "a-5min-2", activity: .qigong, durationMin: 5, intensity: 2, course: .appetizer))
        sessions.append(Fixture.session(id: "a-5min-1", activity: .qigong, durationMin: 5, intensity: 1, course: .appetizer))

        let picked = FirstMove.candidates(from: sessions).map(\.id)
        #expect(picked == ["a-5min-1", "a-3min", "a-5min-2"])
    }

    @Test("The real catalog always has something to offer")
    func catalogHasCandidates() throws {
        let store = try ContentStore.bundled()
        #expect(!FirstMove.candidates(from: store.sessions).isEmpty)
    }

    @Test("The subtitle follows the hour")
    func subtitle() {
        #expect(FirstMove.subtitle(hour: 8) == "We picked one for your morning.")
        #expect(FirstMove.subtitle(hour: 14) == "We picked one for your afternoon.")
        #expect(FirstMove.subtitle(hour: 19) == "We picked one for your evening.")
        #expect(FirstMove.subtitle(hour: 23) == "We picked one for tonight.")
        #expect(FirstMove.subtitle(hour: 2) == "We picked one for tonight.")
    }

    @Test("A stashed session is handed over once")
    func pendingIsTakenOnce() {
        let defaults = UserDefaults(suiteName: "FirstMoveTests-\(UUID().uuidString)")!
        FirstMove.stash(sessionID: "a-good", defaults: defaults)

        #expect(FirstMove.takePending(defaults: defaults) == "a-good")
        #expect(FirstMove.takePending(defaults: defaults) == nil)
    }
}
