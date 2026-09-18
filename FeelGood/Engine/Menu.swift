//
//  Menu.swift
//  FeelGood
//
//  The engine's output, and the deterministic copy that ships with it.
//  Every string here renders instantly and offline; the LLM layer (PRD §7.3)
//  only ever *replaces* the headline in place, never blocks it.
//

import Foundation

/// Machine-readable reason for a pick. Travels to the copy layer as-is;
/// nothing here identifies a person.
nonisolated enum ReasonCode: String, Codable, Sendable, CaseIterable {
    case recoveryBalance
    case lowEnergy
    case timeConstrained
    case varietyBreak
    case returningAfterGap
    case matchesIntent
    case qualityGap
}

/// One line on the menu.
nonisolated struct MenuItem: Hashable, Sendable, Identifiable {
    let session: Session
    let course: Course
    let reasons: [ReasonCode]
    /// Plain-language "why this" — principle 4, say why. Always populated.
    let reasonText: String

    var id: String { session.id }
}

/// Today. Never longer than one screen, never scrolls (PRD §3).
nonisolated struct Menu: Hashable, Sendable {
    /// Start of the local day this menu belongs to.
    let dayStart: Date
    let appetizer: MenuItem?
    let main: MenuItem?
    let sides: [MenuItem]
    let dessert: MenuItem?
    let special: MenuItem?
    /// Deterministic template copy. Upgraded in place by the copy layer.
    let headline: String
    /// What the engine assumed when the check-in was skipped.
    let assumedCheckIn: PlanCheckIn

    /// Menu order, top to bottom.
    var items: [MenuItem] {
        var result: [MenuItem] = []
        if let appetizer { result.append(appetizer) }
        if let main { result.append(main) }
        result.append(contentsOf: sides)
        if let dessert { result.append(dessert) }
        if let special { result.append(special) }
        return result
    }

    /// Unique reason codes across the whole menu, in menu order.
    var reasonCodes: [ReasonCode] {
        var seen: Set<ReasonCode> = []
        return items.flatMap(\.reasons).filter { seen.insert($0).inserted }
    }

    /// Returns a copy of this menu with the given course slot replaced.
    func replacing(course: Course, with session: Session) -> Menu {
        let item = MenuItem(
            session: session,
            course: course,
            reasons: [],
            reasonText: session.isOwn ? "Your custom routine" : MenuCopy.fallbackLine(for: session)
        )
        return replacing(course: course, withItem: item)
    }

    /// Returns a copy of this menu with the given course slot replaced with an optional item.
    func replacing(course: Course, withItem item: MenuItem?) -> Menu {
        var newAppetizer = appetizer
        var newMain = main
        var newSides = sides
        var newDessert = dessert
        var newSpecial = special

        switch course {
        case .appetizer:
            newAppetizer = item
        case .main:
            newMain = item
        case .side:
            if let item {
                if !newSides.isEmpty {
                    newSides[0] = item
                } else {
                    newSides = [item]
                }
            } else {
                newSides = []
            }
        case .dessert:
            newDessert = item
        case .special:
            newSpecial = item
        }

        return Menu(
            dayStart: dayStart,
            appetizer: newAppetizer,
            main: newMain,
            sides: newSides,
            dessert: newDessert,
            special: newSpecial,
            headline: headline,
            assumedCheckIn: assumedCheckIn
        )
    }
}

// MARK: - Template copy

/// Deterministic copy. Warm, never clinical; no shame register anywhere, and
/// no medical or outcome claims (PRD §4, §11).
nonisolated enum MenuCopy {

    static func headline(reasons: Set<ReasonCode>, checkIn: PlanCheckIn) -> String {
        if checkIn.time.isZero {
            return "Rest is part of it. Take the day."
        }
        if reasons.contains(.returningAfterGap) {
            return "Good to see you. Let's start small."
        }
        if reasons.contains(.recoveryBalance) {
            return "You've shown up a few days running — today's a lighter one on purpose."
        }
        if checkIn.energy == .low && checkIn.time.isTight {
            return "Not much time, not much left in the tank. Here's a small one."
        }
        if checkIn.energy == .low {
            return "Low tank today. Everything here is gentle."
        }
        if checkIn.time.isTight {
            return "You've got a little time. This fits it."
        }
        if checkIn.energy == .strong && checkIn.time == .plenty {
            return "Time and energy today — here's something worth it."
        }
        return "Here's today."
    }

    static func reason(for session: Session, codes: [ReasonCode], gapQuality: Quality?, intent: Intent) -> String {
        // One reason, the most specific one. More than one line of "why" turns
        // an answer back into a decision.
        for code in codes {
            switch code {
            case .returningAfterGap:
                return "An easy way back in."
            case .lowEnergy:
                return "Gentle on a low-energy day."
            case .timeConstrained:
                return "Fits in \(session.durationMin) minutes."
            case .recoveryBalance:
                return "Easier than the last couple of days."
            case .qualityGap:
                if let gapQuality { return qualityGapLine(gapQuality) }
                continue
            case .varietyBreak:
                return "Not the same shape you've been in all week."
            case .matchesIntent:
                return intentLine(intent)
            }
        }
        return defaultLine(for: session)
    }

    private static func qualityGapLine(_ quality: Quality) -> String {
        switch quality {
        case .impact: "It's been a while since anything bouncy."
        case .grip: "A bit of grip work — your hands haven't had much lately."
        case .agility: "Nothing quick on your feet in a while."
        case .coordination: "Something new for your brain, not just your body."
        case .downRegulation: "You haven't had much that's purely calming."
        case .balance: "A little balance work, which has been missing."
        case .strength: "It's been a stretch since anything loaded."
        case .mobility: "Your body hasn't had much opening lately."
        case .endurance: "Nothing long and steady in a while."
        }
    }

    private static func intentLine(_ intent: Intent) -> String {
        switch intent {
        case .energize: "Toward waking the body up."
        case .strengthen: "Toward the strength you're building."
        case .calm: "Toward the calm you're after."
        case .mobilize: "Toward moving more easily."
        case .joy: "Showing up is enough today."
        case .play: "Because it sounds fun."
        }
    }

    /// Used when a reason has already been spoken on this menu. Repeating one
    /// line down the whole screen turns "say why" into noise.
    static func fallbackLine(for session: Session) -> String {
        switch session.course {
        case .appetizer: "Short, and it counts."
        case .main: "Today's main thing, in \(session.durationMin) minutes."
        case .side: "\(session.durationMin) minutes, alongside something you're already doing."
        case .dessert: "\(session.durationMin) minutes, purely because you want to."
        case .special: "Worth putting in the diary."
        }
    }

    private static func defaultLine(for session: Session) -> String {
        switch session.course {
        // The duration has to come from the session: the appetizer course runs
        // from two minutes to ten, and telling someone "two minutes" about a
        // five-minute thing is a small lie they will notice.
        case .appetizer: "\(session.durationMin) minutes, and that counts."
        case .main: "Today's main thing."
        case .side: "Pairs with something you're already doing."
        case .dessert: "Purely for the joy of it."
        case .special: "Worth planning for."
        }
    }
}
