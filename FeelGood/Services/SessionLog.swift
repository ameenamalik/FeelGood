//
//  SessionLog.swift
//  FeelGood
//
//  What actually happened, written down. This is the only thing that makes the
//  engine's history and affinity signals real rather than theoretical.
//
//  Protocol-backed with an in-memory implementation, so previews and tests run
//  without a store.
//

import Foundation
import SwiftData
import os

protocol SessionLogging {
    /// A session was finished. `feel` is optional — leaving without answering
    /// is a perfectly good outcome and is still a completion.
    func recordCompletion(of session: Session, startedAt: Date, endedAt: Date, feel: Feel?)
    /// "Not today" on a menu item. A swap is a preference signal, never a failure.
    func recordSwap(of session: Session, at date: Date)

    /// The last two weeks, as the engine wants them.
    func history(before now: Date) -> [HistoryEntry]
    /// Rolled-up preference that outlives the history window.
    func affinity() -> [String: Double]
}

// MARK: - SwiftData

@Observable
final class SessionLog: SessionLogging {
    private let context: ModelContext
    private let calendar: Calendar
    private let logger = Logger(subsystem: "com.ameenamalik.FeelGood", category: "sessionLog")

    /// How much one signal moves a session's standing. Deliberately small:
    /// preference should emerge over weeks, not swing on a single Tuesday.
    private enum Weight {
        static let lovedIt = 0.25
        static let tooMuch = -0.25
        static let swappedAway = -0.15
    }

    init(context: ModelContext, calendar: Calendar = .current) {
        self.context = context
        self.calendar = calendar
    }

    func recordCompletion(of session: Session, startedAt: Date, endedAt: Date, feel: Feel?) {
        let record = SessionRecord(
            session: session,
            startedAt: startedAt,
            dayStart: calendar.startOfDay(for: endedAt),
            endedAt: endedAt,
            outcome: .completed(feel: feel)
        )
        context.insert(record)

        switch feel {
        case .lovedIt: adjustAffinity(for: session.id, by: Weight.lovedIt, at: endedAt)
        case .tooMuch: adjustAffinity(for: session.id, by: Weight.tooMuch, at: endedAt)
        case .fine, .none: break
        }
        save()
    }

    func recordSwap(of session: Session, at date: Date) {
        let record = SessionRecord(
            session: session,
            startedAt: date,
            dayStart: calendar.startOfDay(for: date),
            endedAt: date,
            outcome: .swappedAway
        )
        context.insert(record)
        adjustAffinity(for: session.id, by: Weight.swappedAway, at: date)
        save()
    }

    func history(before now: Date) -> [HistoryEntry] {
        let cutoff = calendar.date(byAdding: .day, value: -PlanEngine.historyWindowDays, to: now) ?? now
        let descriptor = FetchDescriptor<SessionRecord>(
            predicate: #Predicate { $0.startedAt >= cutoff },
            sortBy: [SortDescriptor(\.startedAt, order: .reverse)]
        )
        return fetch(descriptor).map(\.historyEntry)
    }

    func affinity() -> [String: Double] {
        Dictionary(
            fetch(FetchDescriptor<AffinityRecord>()).map { ($0.sessionID, $0.score) },
            uniquingKeysWith: { first, _ in first }
        )
    }

    // MARK: Private

    private func adjustAffinity(for sessionID: String, by delta: Double, at date: Date) {
        let descriptor = FetchDescriptor<AffinityRecord>(
            predicate: #Predicate { $0.sessionID == sessionID }
        )
        if let existing = fetch(descriptor).first {
            existing.score = min(max(existing.score + delta, -1), 1)
            existing.updatedAt = date
        } else {
            context.insert(AffinityRecord(
                sessionID: sessionID,
                score: min(max(delta, -1), 1),
                updatedAt: date
            ))
        }
    }

    private func fetch<T>(_ descriptor: FetchDescriptor<T>) -> [T] {
        do {
            return try context.fetch(descriptor)
        } catch {
            // A read failure must not take the screen down: an empty history
            // simply produces a first-day menu.
            logger.error("Fetch failed: \(error, privacy: .public)")
            return []
        }
    }

    private func save() {
        do {
            try context.save()
        } catch {
            // The session still happened. Losing the record costs tomorrow's
            // balancing a little accuracy, and nothing else.
            logger.error("Could not save session log: \(error, privacy: .public)")
        }
    }
}

// MARK: - Fake

/// In-memory log for previews and tests.
@Observable
final class InMemorySessionLog: SessionLogging {
    private(set) var entries: [HistoryEntry] = []
    private(set) var affinityScores: [String: Double] = [:]

    init(entries: [HistoryEntry] = []) {
        self.entries = entries
    }

    func recordCompletion(of session: Session, startedAt: Date, endedAt: Date, feel: Feel?) {
        entries.append(HistoryEntry(
            sessionID: session.id,
            activity: session.activity,
            qualities: session.qualities,
            intensity: session.intensity,
            course: session.course,
            date: endedAt,
            outcome: .completed(feel: feel)
        ))
        switch feel {
        case .lovedIt: affinityScores[session.id, default: 0] += 0.25
        case .tooMuch: affinityScores[session.id, default: 0] -= 0.25
        case .fine, .none: break
        }
    }

    func recordSwap(of session: Session, at date: Date) {
        entries.append(HistoryEntry(
            sessionID: session.id,
            activity: session.activity,
            qualities: session.qualities,
            intensity: session.intensity,
            course: session.course,
            date: date,
            outcome: .swappedAway
        ))
        affinityScores[session.id, default: 0] -= 0.15
    }

    func history(before now: Date) -> [HistoryEntry] { entries }
    func affinity() -> [String: Double] { affinityScores }
}
