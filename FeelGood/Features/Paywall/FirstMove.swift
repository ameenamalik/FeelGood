//
//  FirstMove.swift
//  FeelGood
//
//  The one small thing offered right after someone subscribes. Chosen from
//  the catalog by rule, not by the plan engine: the paywall has no profile or
//  menu in hand, so it picks something that is safe and easy for anyone.
//

import Foundation

nonisolated enum FirstMove {
    /// Posted when someone taps "Start now". Today consumes it, so the
    /// session opens on the screen they land on after the paywall closes.
    static let requested = Notification.Name("FeelGoodFirstMoveRequested")

    private static let pendingKey = "firstMovePendingSessionID"

    /// Remembered rather than only posted: after onboarding the paywall
    /// closes before Today exists, so nobody would be listening yet.
    static func stash(sessionID: String, defaults: UserDefaults = .standard) {
        defaults.set(sessionID, forKey: pendingKey)
        NotificationCenter.default.post(name: requested, object: nil)
    }

    /// Returns the stashed session once and forgets it.
    static func takePending(defaults: UserDefaults = .standard) -> String? {
        guard let id = defaults.string(forKey: pendingKey) else { return nil }
        defaults.removeObject(forKey: pendingKey)
        return id
    }

    /// Short, gentle, at home, no equipment, nothing a flagged condition
    /// rules out. Easiest first, then closest to five minutes.
    static func candidates(from sessions: [Session]) -> [Session] {
        sessions
            .filter { session in
                guard session.course == .appetizer,
                      session.durationMin <= 5,
                      session.intensity <= 2,
                      session.equipment.allSatisfy { $0 == .none },
                      session.contraindications.isEmpty,
                      session.places.isEmpty || session.places.contains(.home),
                      !session.isOwn
                else { return false }
                if case .youtube = session.source { return false }
                return true
            }
            .sorted { lhs, rhs in
                if lhs.intensity != rhs.intensity { return lhs.intensity < rhs.intensity }
                let lhsGap = abs(lhs.durationMin - 5)
                let rhsGap = abs(rhs.durationMin - 5)
                if lhsGap != rhsGap { return lhsGap < rhsGap }
                return lhs.id < rhs.id
            }
    }

    /// "your afternoon". Late at night it is "tonight".
    static func daypart(hour: Int) -> String {
        switch hour {
        case 5..<11: "morning"
        case 11..<17: "afternoon"
        case 17..<21: "evening"
        default: "night"
        }
    }

    static func subtitle(hour: Int) -> String {
        let part = daypart(hour: hour)
        return part == "night" ? "We picked one for tonight." : "We picked one for your \(part)."
    }
}
