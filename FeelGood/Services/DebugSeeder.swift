//
//  DebugSeeder.swift
//  FeelGood
//
//  Fabricates history so the time-dependent parts of the product can be seen
//  without waiting days for them. Debug builds only — the whole file compiles
//  to nothing in release.
//
//  Nothing here fakes the UI. It writes real records through the real store,
//  and the real engine reacts to them exactly as it would for a real person.
//

#if DEBUG

import Foundation
import SwiftData

nonisolated enum DebugScenario: String, CaseIterable, Identifiable {
    case freshStart
    case returningAfterGap
    case twoHardDays
    case oneNoteFortnight
    case lovedTheGentleOne

    var id: String { rawValue }

    var title: String {
        switch self {
        case .freshStart: "Wipe everything"
        case .returningAfterGap: "Away for 9 days"
        case .twoHardDays: "Two hard days in a row"
        case .oneNoteFortnight: "Two weeks of Pilates only"
        case .lovedTheGentleOne: "Loved the gentle mat session"
        }
    }

    var detail: String {
        switch self {
        case .freshStart:
            "Profile and history gone. Next launch starts at onboarding."
        case .returningAfterGap:
            "One session, nine days ago. Expect a shorter menu and \"Good to see you.\""
        case .twoHardDays:
            "Intensity 4 yesterday and the day before. Expect today to be easy on purpose."
        case .oneNoteFortnight:
            "Five Pilates sessions over two weeks. Expect a nudge toward something missing."
        case .lovedTheGentleOne:
            "Marks one session as loved, several times over. Expect it to surface more."
        }
    }
}

@MainActor
struct DebugSeeder {
    let context: ModelContext
    let content: any ContentProviding
    var calendar: Calendar = .current

    func apply(_ scenario: DebugScenario, now: Date = Date()) {
        switch scenario {
        case .freshStart:
            wipe(includingProfile: true)

        case .returningAfterGap:
            wipe(includingProfile: false)
            complete("main-pilates-core-20", daysAgo: 9, feel: .fine, now: now)

        case .twoHardDays:
            wipe(includingProfile: false)
            complete("main-strength-full-30", daysAgo: 1, feel: .fine, now: now)
            complete("main-strength-full-30", daysAgo: 2, feel: .tooMuch, now: now)

        case .oneNoteFortnight:
            wipe(includingProfile: false)
            // Enough sessions for coverage to mean something, all one flavour,
            // and none in the last two days so variety isn't the active signal.
            for daysAgo in [3, 5, 7, 9, 11] {
                complete("main-pilates-core-20", daysAgo: daysAgo, feel: .fine, now: now)
            }

        case .lovedTheGentleOne:
            for daysAgo in [2, 4, 6] {
                complete("main-pilates-gentle-10", daysAgo: daysAgo, feel: .lovedIt, now: now)
            }
        }
        try? context.save()
    }

    /// What the engine can currently see, so the effect of a scenario is legible.
    func summary(now: Date = Date()) -> String {
        let records = (try? context.fetch(FetchDescriptor<SessionRecord>())) ?? []
        let completed = records.filter(\.wasCompleted)
        guard let last = completed.map(\.startedAt).max() else {
            return "No history. The engine is planning a first day."
        }
        let days = calendar.dateComponents(
            [.day],
            from: calendar.startOfDay(for: last),
            to: calendar.startOfDay(for: now)
        ).day ?? 0
        return "\(completed.count) completed, \(records.count - completed.count) swapped. "
            + (days == 0 ? "Last one today." : "Last one \(days) day\(days == 1 ? "" : "s") ago.")
    }

    // MARK: Private

    private func complete(_ sessionID: String, daysAgo: Int, feel: Feel, now: Date) {
        guard let session = content.session(id: sessionID),
              let date = calendar.date(byAdding: .day, value: -daysAgo, to: now) else { return }

        context.insert(SessionRecord(
            session: session,
            startedAt: date,
            dayStart: calendar.startOfDay(for: date),
            endedAt: date,
            outcome: .completed(feel: feel)
        ))

        let delta = switch feel {
        case .lovedIt: 0.25
        case .tooMuch: -0.25
        case .fine: 0.0
        }
        guard delta != 0 else { return }
        let existing = (try? context.fetch(FetchDescriptor<AffinityRecord>(
            predicate: #Predicate { $0.sessionID == sessionID }
        )))?.first
        if let existing {
            existing.score = min(max(existing.score + delta, -1), 1)
            existing.updatedAt = date
        } else {
            context.insert(AffinityRecord(sessionID: sessionID, score: delta, updatedAt: date))
        }
    }

    private func wipe(includingProfile: Bool) {
        try? context.delete(model: SessionRecord.self)
        try? context.delete(model: AffinityRecord.self)
        try? context.delete(model: CheckInRecord.self)
        try? context.delete(model: PlanDay.self)
        if includingProfile {
            try? context.delete(model: UserProfile.self)
        }
    }
}

#endif
