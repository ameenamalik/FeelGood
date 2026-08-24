//
//  ActivityLog.swift
//  FeelGood
//
//  What actually happened, written down. Behind a protocol like every other
//  service, so the app runs in previews and tests without a store. Isolated to
//  the main actor because a SwiftData context is — the engine stays pure and
//  never sees any of this. See PRD §11.
//

import Foundation
import OSLog
import SwiftData

protocol ActivityLogging {
    /// Records an outcome and moves the long-memory affinity score with it.
    /// Skipping writes a record but moves nothing: it is not a judgement.
    func record(
        _ session: Session,
        outcome: HistoryOutcome,
        startedAt: Date,
        endedAt: Date?,
        dayStart: Date
    )

    /// Keeps somebody's own workout so the engine can offer it back later.
    @discardableResult
    func keep(title: String, activity: Activity, durationMin: Int, intensity: Int, now: Date) -> Session

    /// Kept workouts are somebody's own, which means they get to change their
    /// mind about them.
    func rename(_ sessionID: String, to title: String)
    func forget(_ sessionID: String)

    /// Today's answers, so reopening the app doesn't ask again.
    func record(_ checkIn: PlanCheckIn, at takenAt: Date, dayStart: Date)

    /// The day's menu, so reopening shows the same day rather than quietly
    /// regenerating a different one underneath somebody.
    func save(_ menu: Menu, generatedAt: Date)
}

final class SwiftDataActivityLog: ActivityLogging {
    private let context: ModelContext
    private let logger = Logger(subsystem: "com.ameenamalik.FeelGood", category: "activity-log")

    init(context: ModelContext) {
        self.context = context
    }

    func record(
        _ session: Session,
        outcome: HistoryOutcome,
        startedAt: Date,
        endedAt: Date?,
        dayStart: Date
    ) {
        context.insert(
            SessionRecord(
                session: session,
                startedAt: startedAt,
                dayStart: dayStart,
                endedAt: endedAt,
                outcome: outcome
            )
        )
        moveAffinity(for: session.id, after: outcome, now: endedAt ?? startedAt)
        save("recording \(session.id)")
    }

    @discardableResult
    func keep(title: String, activity: Activity, durationMin: Int, intensity: Int, now: Date) -> Session {
        let kept = CustomSession(
            title: title,
            activity: activity,
            durationMin: durationMin,
            intensity: intensity,
            createdAt: now
        )
        context.insert(kept)
        save("keeping \(kept.id)")
        return kept.session
    }

    func rename(_ sessionID: String, to title: String) {
        kept(sessionID)?.title = title
        save("renaming \(sessionID)")
    }

    func forget(_ sessionID: String) {
        guard let kept = kept(sessionID) else { return }
        context.delete(kept)
        // The records of having done it stay: history is denormalised, so what
        // happened still counts even once the workout itself is gone.
        save("forgetting \(sessionID)")
    }

    private func kept(_ sessionID: String) -> CustomSession? {
        try? context.fetch(
            FetchDescriptor<CustomSession>(predicate: #Predicate { $0.id == sessionID })
        ).first
    }

    func record(_ checkIn: PlanCheckIn, at takenAt: Date, dayStart: Date) {
        // Every check-in is kept, not just the latest: "something's changed"
        // partway through a day is a real thing that happened.
        context.insert(CheckInRecord(checkIn: checkIn, takenAt: takenAt, dayStart: dayStart))
        save("recording a check-in")
    }

    func save(_ menu: Menu, generatedAt: Date) {
        // One stored day per local day. Replacing it outright takes the old
        // items with it through the cascade rule, rather than orphaning them.
        let dayStart = menu.dayStart
        let existing = try? context.fetch(
            FetchDescriptor<PlanDay>(predicate: #Predicate { $0.dayStart == dayStart })
        )
        for day in existing ?? [] {
            context.delete(day)
        }
        context.insert(PlanDay(menu: menu, generatedAt: generatedAt))
        save("saving the day's menu")
    }

    private func moveAffinity(for sessionID: String, after outcome: HistoryOutcome, now: Date) {
        guard Affinity.delta(for: outcome) != 0 else { return }
        let existing = try? context.fetch(
            FetchDescriptor<AffinityRecord>(predicate: #Predicate { $0.sessionID == sessionID })
        ).first

        if let existing {
            existing.score = Affinity.updated(existing.score, after: outcome)
            existing.updatedAt = now
        } else {
            context.insert(
                AffinityRecord(
                    sessionID: sessionID,
                    score: Affinity.updated(0, after: outcome),
                    updatedAt: now
                )
            )
        }
    }

    private func save(_ what: String) {
        do {
            try context.save()
        } catch {
            // A failed write must never interrupt somebody's day: the menu is
            // already on screen and correct. It costs a signal, not a session.
            logger.error("Failed while \(what, privacy: .public): \(error, privacy: .public)")
        }
    }
}

/// Remembers everything, persists nothing. Previews, tests, and the SwiftUI
/// canvas all run through this.
final class InMemoryActivityLog: ActivityLogging {
    private(set) var recorded: [(session: Session, outcome: HistoryOutcome)] = []
    private(set) var kept: [Session] = []
    private(set) var checkIns: [PlanCheckIn] = []
    private(set) var savedDays: [Menu] = []
    private(set) var renamed: [String: String] = [:]
    private(set) var forgotten: [String] = []

    init() {}

    func record(
        _ session: Session,
        outcome: HistoryOutcome,
        startedAt: Date,
        endedAt: Date?,
        dayStart: Date
    ) {
        recorded.append((session, outcome))
    }

    @discardableResult
    func keep(title: String, activity: Activity, durationMin: Int, intensity: Int, now: Date) -> Session {
        let session = Session.own(
            id: "own-preview-\(kept.count)",
            title: title,
            activity: activity,
            durationMin: durationMin,
            intensity: intensity
        )
        kept.append(session)
        return session
    }

    func rename(_ sessionID: String, to title: String) {
        renamed[sessionID] = title
    }

    func forget(_ sessionID: String) {
        forgotten.append(sessionID)
    }

    func record(_ checkIn: PlanCheckIn, at takenAt: Date, dayStart: Date) {
        checkIns.append(checkIn)
    }

    func save(_ menu: Menu, generatedAt: Date) {
        savedDays.append(menu)
    }
}
