//
//  ProSubscriptionStatusTests.swift
//  FeelGoodTests
//

import Testing
import Foundation
@testable import FeelGood

@Suite("Pro subscription status")
struct ProSubscriptionStatusTests {
    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }()

    private func date(_ day: Int) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: 11, day: day, hour: 15))!
    }

    @Test("A trial counts whole calendar days, not 24-hour blocks")
    func countsCalendarDays() {
        let status = ProSubscriptionStatus(phase: .trial, willRenew: true, expirationDate: date(9))

        #expect(status.daysRemaining(now: date(2), calendar: calendar) == 7)
        #expect(status.daysRemaining(now: date(9), calendar: calendar) == 0)
        #expect(status.daysRemaining(now: date(12), calendar: calendar) == 0)
    }

    @Test("The trial badge says how long is left")
    func trialBadge() {
        let status = ProSubscriptionStatus(phase: .trial, willRenew: true, expirationDate: date(9))

        #expect(status.badge(now: date(4), calendar: calendar) == "Free trial · 5 days left")
        #expect(status.badge(now: date(8), calendar: calendar) == "Free trial · 1 day left")
        #expect(status.badge(now: date(9), calendar: calendar) == "Free trial · ends today")
    }

    @Test("A paid subscription is just Pro")
    func paidBadge() {
        let status = ProSubscriptionStatus(phase: .active, willRenew: true, expirationDate: date(30))

        #expect(status.badge(now: date(2), calendar: calendar) == "FeelGood Pro")
        #expect(!status.isTrial)
    }

    @Test("A cancelled trial says it will not renew instead of promising a charge")
    func cancelledTrialDoesNotPromiseCharge() {
        let renewing = ProSubscriptionStatus(phase: .trial, willRenew: true, expirationDate: date(9))
        let cancelled = ProSubscriptionStatus(phase: .trial, willRenew: false, expirationDate: date(9))

        #expect(renewing.detail().contains("charged"))
        #expect(!cancelled.detail().contains("charged"))
        #expect(cancelled.detail().contains("won't renew"))
        #expect(renewing.dateLabel == "Trial ends, then charged")
        #expect(cancelled.dateLabel == "Trial ends")
    }

    @Test("A billing issue is called out")
    func billingIssue() {
        let status = ProSubscriptionStatus(phase: .billingIssue, willRenew: true, expirationDate: date(9))

        #expect(status.badge() == "Payment issue")
    }
}
