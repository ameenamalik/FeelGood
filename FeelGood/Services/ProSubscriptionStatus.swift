//
//  ProSubscriptionStatus.swift
//  FeelGood
//

import Foundation
import RevenueCat

/// What the Pro entitlement is doing right now: on a free trial, paid, or
/// failing to renew. The plan screen and the profile row read this so nobody
/// has to guess whether a charge is coming.
nonisolated struct ProSubscriptionStatus: Equatable, Sendable {
    enum Phase: Equatable, Sendable {
        case trial
        case active
        case billingIssue
    }

    var phase: Phase
    /// False once the person has cancelled (or turned off auto-renew). The
    /// entitlement stays active until `expirationDate`.
    var willRenew: Bool
    var expirationDate: Date?

    init(phase: Phase, willRenew: Bool, expirationDate: Date?) {
        self.phase = phase
        self.willRenew = willRenew
        self.expirationDate = expirationDate
    }

    /// `nil` when the entitlement is not active.
    init?(entitlement: EntitlementInfo) {
        guard entitlement.isActive else { return nil }
        if entitlement.billingIssueDetectedAt != nil {
            phase = .billingIssue
        } else if entitlement.periodType == .trial {
            phase = .trial
        } else {
            phase = .active
        }
        willRenew = entitlement.willRenew
        expirationDate = entitlement.expirationDate
    }

    var isTrial: Bool { phase == .trial }

    /// Whole calendar days until the entitlement ends. Today counts as 0.
    func daysRemaining(now: Date = .now, calendar: Calendar = .current) -> Int? {
        guard let expirationDate else { return nil }
        let start = calendar.startOfDay(for: now)
        let end = calendar.startOfDay(for: expirationDate)
        return max(0, calendar.dateComponents([.day], from: start, to: end).day ?? 0)
    }

    /// Short text for a pill or a row.
    func badge(now: Date = .now, calendar: Calendar = .current) -> String {
        switch phase {
        case .billingIssue:
            return "Payment issue"
        case .trial:
            switch daysRemaining(now: now, calendar: calendar) {
            case 0: return "Free trial · ends today"
            case 1: return "Free trial · 1 day left"
            case let days?: return "Free trial · \(days) days left"
            case nil: return "Free trial"
            }
        case .active:
            return "FeelGood Pro"
        }
    }

    /// One plain sentence about what happens next.
    func detail(now: Date = .now, calendar: Calendar = .current) -> String {
        let date = expirationDate?.formatted(date: .abbreviated, time: .omitted)
        switch phase {
        case .billingIssue:
            return "Apple couldn't take your last payment. Update it to keep Pro."
        case .trial:
            guard let date else { return "Your free trial is on." }
            return willRenew
                ? "Your free trial is on. You're charged on \(date) unless you cancel first."
                : "Your free trial ends on \(date) and won't renew."
        case .active:
            guard let date else { return "All FeelGood Pro features are unlocked." }
            return willRenew
                ? "All FeelGood Pro features are unlocked. Renews on \(date)."
                : "All FeelGood Pro features are unlocked until \(date). It won't renew."
        }
    }

    /// Label for the date row on the plan screen.
    var dateLabel: String {
        switch (phase, willRenew) {
        case (.trial, true): "Trial ends, then charged"
        case (.trial, false): "Trial ends"
        case (_, true): "Renews"
        case (_, false): "Access ends"
        }
    }
}
