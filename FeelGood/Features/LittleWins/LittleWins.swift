//
//  LittleWins.swift
//  FeelGood
//
//  Lifetime milestones derived from completion history. No counters are
//  persisted: history remains the source of truth, so progress cannot drift.
//

import Foundation

nonisolated enum LittleWin: String, CaseIterable, Codable, Hashable, Identifiable, Sendable {
    case firstMove
    case homebody
    case gymRegular
    case yogaEra
    case tinyWins
    case varietyPack

    var id: String { rawValue }

    var title: String {
        switch self {
        case .firstMove: "First Move"
        case .homebody: "Homebody"
        case .gymRegular: "Gym Regular"
        case .yogaEra: "Yoga Era"
        case .tinyWins: "Tiny Wins"
        case .varietyPack: "Variety Pack"
        }
    }

    var detail: String {
        switch self {
        case .firstMove: "Complete your first session."
        case .homebody: "Complete 5 sessions at home."
        case .gymRegular: "Complete 5 sessions at the gym."
        case .yogaEra: "Complete 5 yoga sessions."
        case .tinyWins: "Complete 5 sessions that are 5 minutes or less."
        case .varietyPack: "Complete 3 different movement types."
        }
    }

    var unlockedLine: String {
        switch self {
        case .firstMove: "The first one counts."
        case .homebody: "Your space, your pace."
        case .gymRegular: "Five gym sessions. Okayyy."
        case .yogaEra: "A little more room to breathe."
        case .tinyWins: "Small sessions still count."
        case .varietyPack: "You found more than one way to move."
        }
    }

    var mascotAsset: String {
        switch self {
        case .firstMove: "LittleWinFirstMoveStrawberry"
        case .homebody: "LittleWinHomebodyAvocado"
        case .gymRegular: "LittleWinGymPineapple"
        case .yogaEra: "LittleWinYogaDragonFruit"
        case .tinyWins: "LittleWinTinyRaspberry"
        case .varietyPack: "LittleWinVarietyKiwi"
        }
    }

    var target: Int {
        switch self {
        case .firstMove: 1
        case .varietyPack: 3
        default: 5
        }
    }
}

nonisolated struct LittleWinProgress: Hashable, Identifiable, Sendable {
    let win: LittleWin
    let current: Int
    let unlockedAt: Date?

    var id: LittleWin { win }
    var target: Int { win.target }
    var isUnlocked: Bool { unlockedAt != nil }

    var statusLine: String {
        if isUnlocked { return "Unlocked" }
        switch win {
        case .firstMove:
            return "Complete one session"
        case .homebody:
            return "\(current) of \(target) at-home sessions"
        case .gymRegular:
            return "\(current) of \(target) gym sessions"
        case .yogaEra:
            return "\(current) of \(target) yoga sessions"
        case .tinyWins:
            return "\(current) of \(target) tiny sessions"
        case .varietyPack:
            return "\(current) of \(target) movement types"
        }
    }
}

nonisolated struct LittleWinCelebration: Identifiable, Hashable, Sendable {
    let wins: [LittleWinProgress]
    var id: LittleWin { wins[0].win }
    var featured: LittleWinProgress { wins[0] }
}

nonisolated enum LittleWins {
    static func progress(in history: [HistoryEntry], sessions: [Session] = []) -> [LittleWinProgress] {
        let knownSessions = Dictionary(sessions.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        let completed = history
            .filter(\.wasCompleted)
            .map { entry -> HistoryEntry in
                guard entry.durationMin == 0, let session = knownSessions[entry.sessionID] else { return entry }
                var enriched = entry
                enriched.durationMin = session.durationMin
                return enriched
            }
            .sorted { $0.date < $1.date }

        return LittleWin.allCases.map { win in
            switch win {
            case .firstMove:
                return threshold(win, matches: completed)
            case .homebody:
                return threshold(win, matches: completed.filter { $0.place == .home })
            case .gymRegular:
                return threshold(win, matches: completed.filter { $0.place == .gym })
            case .yogaEra:
                return threshold(win, matches: completed.filter { $0.activity == .yoga })
            case .tinyWins:
                return threshold(win, matches: completed.filter { $0.durationMin > 0 && $0.durationMin <= 5 })
            case .varietyPack:
                return varietyProgress(win, completed: completed)
            }
        }
    }

    private static func threshold(_ win: LittleWin, matches: [HistoryEntry]) -> LittleWinProgress {
        LittleWinProgress(
            win: win,
            current: min(matches.count, win.target),
            unlockedAt: matches.count >= win.target ? matches[win.target - 1].date : nil
        )
    }

    private static func varietyProgress(_ win: LittleWin, completed: [HistoryEntry]) -> LittleWinProgress {
        var activities: Set<Activity> = []
        var unlockedAt: Date?
        for entry in completed {
            activities.insert(entry.activity)
            if activities.count >= win.target {
                unlockedAt = entry.date
                break
            }
        }
        return LittleWinProgress(
            win: win,
            current: min(activities.count, win.target),
            unlockedAt: unlockedAt
        )
    }
}
