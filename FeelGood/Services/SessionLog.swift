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

@MainActor
protocol SessionLogging: AnyObject, Sendable {
    /// A session was finished. `feel` is optional — finishing without answering
    /// the reflection question is still a completion.
    func recordCompletion(of session: Session, startedAt: Date, endedAt: Date, feel: Feel?, place: Place?)
    /// "Shuffle" on a menu item. A swap is a preference signal, never a failure.
    func recordSwap(of session: Session, at date: Date)

    /// The last two weeks, as the engine wants them.
    func history(before now: Date) -> [HistoryEntry]
    /// Full retained history for lifetime milestones. Planning continues to use
    /// only the bounded history window above.
    func allHistory() -> [HistoryEntry]
    /// Rolled-up preference that outlives the history window.
    func affinity() -> [String: Double]
    /// On-device contextual bandit model state.
    func banditState() -> BanditState?
    func saveBanditState(_ state: BanditState)

    // MARK: The day

    /// Today's answers, so reopening the app doesn't ask again.
    func record(_ checkIn: PlanCheckIn, at takenAt: Date, dayStart: Date)
    /// The day's menu, so reopening shows the same day rather than quietly
    /// regenerating a different one underneath somebody.
    func save(_ menu: Menu, generatedAt: Date)
    /// The menu already generated for this local day, if there is one.
    func day(_ dayStart: Date, resolving session: (String) -> Session?) -> Menu?
    /// The most recent answers given on this local day.
    func checkIn(on dayStart: Date) -> PlanCheckIn?

    // MARK: Somebody's own workouts

    /// Kept so the engine can offer it back later.
    @discardableResult
    func keep(title: String, description: String?, parts: [CustomRoutinePart], activity: Activity, durationMin: Int, intensity: Int, course: Course?, now: Date) -> Session
    func kept() -> [Session]
    /// They are somebody's own, which means they get to change their mind.
    @discardableResult
    func update(_ sessionID: String, title: String, description: String?, parts: [CustomRoutinePart], activity: Activity, durationMin: Int, intensity: Int, course: Course) -> Session?
    func rename(_ sessionID: String, to title: String)
    func forget(_ sessionID: String)

    // MARK: Hidden exercises ("Don't suggest this again")

    func hideSession(_ sessionID: String, at date: Date)
    func unhideSession(_ sessionID: String, at date: Date)
    func hiddenSessionIDs() -> Set<String>
}

extension SessionLogging {
    func recordCompletion(of session: Session, startedAt: Date, endedAt: Date, feel: Feel?) {
        recordCompletion(of: session, startedAt: startedAt, endedAt: endedAt, feel: feel, place: nil)
    }

    @discardableResult
    func keep(title: String, activity: Activity, durationMin: Int, intensity: Int, now: Date) -> Session {
        keep(title: title, description: nil, parts: [], activity: activity, durationMin: durationMin, intensity: intensity, course: nil, now: now)
    }

    @discardableResult
    func keep(title: String, activity: Activity, durationMin: Int, intensity: Int, course: Course?, now: Date) -> Session {
        keep(title: title, description: nil, parts: [], activity: activity, durationMin: durationMin, intensity: intensity, course: course, now: now)
    }
}

// MARK: - SwiftData

@Observable
@MainActor
final class SessionLog: SessionLogging {
    private let context: ModelContext
    private let calendar: Calendar
    private let logger = Logger(subsystem: "com.ameenamalik.FeelGood", category: "sessionLog")

    init(context: ModelContext, calendar: Calendar = .current) {
        self.context = context
        self.calendar = calendar
    }

    func recordCompletion(of session: Session, startedAt: Date, endedAt: Date, feel: Feel?, place: Place?) {
        let record = SessionRecord(
            session: session,
            startedAt: startedAt,
            dayStart: calendar.movementDayStart(for: endedAt),
            endedAt: endedAt,
            outcome: .completed(feel: feel),
            place: place
        )
        context.insert(record)

        moveAffinity(for: session.id, after: .completed(feel: feel), at: endedAt)
        updateBandit(for: session, outcome: .completed(feel: feel), at: endedAt)
        save()
    }

    func recordSwap(of session: Session, at date: Date) {
        let record = SessionRecord(
            session: session,
            startedAt: date,
            dayStart: calendar.movementDayStart(for: date),
            endedAt: date,
            outcome: .swappedAway
        )
        context.insert(record)
        moveAffinity(for: session.id, after: .swappedAway, at: date)
        updateBandit(for: session, outcome: .swappedAway, at: date)
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

    func allHistory() -> [HistoryEntry] {
        let descriptor = FetchDescriptor<SessionRecord>(
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

    func banditState() -> BanditState? {
        fetch(FetchDescriptor<BanditStateRecord>()).first?.banditState
    }

    func saveBanditState(_ state: BanditState) {
        let descriptor = FetchDescriptor<BanditStateRecord>()
        if let existing = fetch(descriptor).first {
            existing.stateData = (try? JSONEncoder().encode(state)) ?? Data()
            existing.updatedAt = Date()
        } else {
            context.insert(BanditStateRecord(state: state, updatedAt: Date()))
        }
    }

    private func updateBandit(for session: Session, outcome: HistoryOutcome, at date: Date) {
        let currentState = banditState() ?? BanditState()
        let planProfile = fetch(FetchDescriptor<UserProfile>()).first?.planProfile
            ?? PlanProfile(availableActivities: [session.activity, .stretching, .walking])
        let dayStart = calendar.movementDayStart(for: date)
        let todaysCheckIn = checkIn(on: dayStart) ?? PlanCheckIn(energy: .steady, time: .some)
        let planContext = PlanContext(now: date, calendar: calendar)
        let entries = history(before: date)
        let input = PlanInput(
            profile: planProfile,
            checkIn: todaysCheckIn,
            history: entries,
            context: planContext
        )
        let stats = HistoryStats(input: input)

        let completedEntries = entries.filter(\.wasCompleted)
        var hardRun = 0
        for dayOffset in 0..<7 {
            let matches = completedEntries.filter {
                let diff = calendar.dateComponents([.day], from: calendar.movementDayStart(for: $0.date), to: dayStart).day ?? 999
                return diff == dayOffset && $0.intensity >= 4
            }
            if !matches.isEmpty {
                hardRun += 1
            } else if dayOffset > 0 {
                break
            }
        }

        let updated = BanditEngine.update(
            state: currentState,
            session: session,
            outcome: outcome,
            profile: planProfile,
            checkIn: todaysCheckIn,
            stats: stats,
            context: planContext,
            consecutiveHardDays: hardRun
        )
        saveBanditState(updated)
    }

    func hideSession(_ sessionID: String, at date: Date) {
        if let profile = fetch(FetchDescriptor<UserProfile>()).first {
            profile.hideSession(sessionID, now: date)
            save()
        }
    }

    func unhideSession(_ sessionID: String, at date: Date) {
        if let profile = fetch(FetchDescriptor<UserProfile>()).first {
            profile.unhideSession(sessionID, now: date)
            save()
        }
    }

    func hiddenSessionIDs() -> Set<String> {
        guard let profile = fetch(FetchDescriptor<UserProfile>()).first else { return [] }
        return Set(profile.hiddenSessionIDsRaw)
    }

    // MARK: Private

    /// Deliberately small deltas, defined once in `Affinity`: preference should
    /// emerge over weeks, not swing on a single Tuesday.
    private func moveAffinity(for sessionID: String, after outcome: HistoryOutcome, at date: Date) {
        guard Affinity.delta(for: outcome) != 0 else { return }
        let descriptor = FetchDescriptor<AffinityRecord>(
            predicate: #Predicate { $0.sessionID == sessionID }
        )
        if let existing = fetch(descriptor).first {
            existing.score = Affinity.updated(existing.score, after: outcome)
            existing.updatedAt = date
        } else {
            context.insert(AffinityRecord(
                sessionID: sessionID,
                score: Affinity.updated(0, after: outcome),
                updatedAt: date
            ))
        }
    }

    // MARK: The day

    func record(_ checkIn: PlanCheckIn, at takenAt: Date, dayStart: Date) {
        // Every check-in is kept, not just the latest: "something's changed"
        // partway through a day is a real thing that happened.
        context.insert(CheckInRecord(checkIn: checkIn, takenAt: takenAt, dayStart: dayStart))
        save()
    }

    func save(_ menu: Menu, generatedAt: Date) {
        // One stored day per local day. Replacing it outright takes the old
        // items with it through the cascade rule, rather than orphaning them.
        let dayStart = menu.dayStart
        for day in fetch(FetchDescriptor<PlanDay>(predicate: #Predicate { $0.dayStart == dayStart })) {
            context.delete(day)
        }
        context.insert(PlanDay(menu: menu, generatedAt: generatedAt))
        save()
    }

    func day(_ dayStart: Date, resolving session: (String) -> Session?) -> Menu? {
        fetch(FetchDescriptor<PlanDay>(predicate: #Predicate { $0.dayStart == dayStart }))
            .first?
            .menu(resolving: session)
    }

    func checkIn(on dayStart: Date) -> PlanCheckIn? {
        var descriptor = FetchDescriptor<CheckInRecord>(
            predicate: #Predicate { $0.dayStart == dayStart },
            sortBy: [SortDescriptor(\.takenAt, order: .reverse)]
        )
        descriptor.fetchLimit = 1
        return fetch(descriptor).first?.planCheckIn
    }

    // MARK: Somebody's own workouts

    @discardableResult
    func keep(title: String, description: String?, parts: [CustomRoutinePart], activity: Activity, durationMin: Int, intensity: Int, course: Course?, now: Date) -> Session {
        let kept = CustomSession(
            title: title,
            description: description,
            parts: parts,
            activity: activity,
            durationMin: durationMin,
            intensity: intensity,
            course: course,
            createdAt: now
        )
        context.insert(kept)
        save()
        return kept.session
    }

    func kept() -> [Session] {
        fetch(FetchDescriptor<CustomSession>(sortBy: [SortDescriptor(\.createdAt)])).map(\.session)
    }

    @discardableResult
    func update(
        _ sessionID: String,
        title: String,
        description: String?,
        parts: [CustomRoutinePart],
        activity: Activity,
        durationMin: Int,
        intensity: Int,
        course: Course
    ) -> Session? {
        guard let record = keptRecord(sessionID) else { return nil }
        record.title = title
        record.sessionDescription = description
        record.parts = parts
        record.activityRaw = activity.rawValue
        record.durationMin = max(1, durationMin)
        record.intensity = min(max(intensity, 1), 5)
        record.courseRaw = course.rawValue
        save()
        return record.session
    }

    func rename(_ sessionID: String, to title: String) {
        keptRecord(sessionID)?.title = title
        save()
    }

    func forget(_ sessionID: String) {
        guard let record = keptRecord(sessionID) else { return }
        context.delete(record)
        // The records of having done it stay: history is denormalised, so what
        // happened still counts even once the workout itself is gone.
        save()
    }

    private func keptRecord(_ sessionID: String) -> CustomSession? {
        fetch(FetchDescriptor<CustomSession>(predicate: #Predicate { $0.id == sessionID })).first
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
@MainActor
final class InMemorySessionLog: SessionLogging {
    private(set) var entries: [HistoryEntry] = []
    private(set) var affinityScores: [String: Double] = [:]
    private(set) var currentBanditState: BanditState?

    init(entries: [HistoryEntry] = [], banditState: BanditState? = nil) {
        self.entries = entries
        self.currentBanditState = banditState
    }

    func recordCompletion(of session: Session, startedAt: Date, endedAt: Date, feel: Feel?, place: Place?) {
        entries.append(HistoryEntry(
            sessionID: session.id,
            activity: session.activity,
            qualities: session.qualities,
            intensity: session.intensity,
            course: session.course,
            durationMin: session.durationMin,
            place: place,
            date: endedAt,
            outcome: .completed(feel: feel)
        ))
        switch feel {
        case .lovedIt: affinityScores[session.id, default: 0] += 0.25
        case .tooMuch: affinityScores[session.id, default: 0] -= 0.25
        case .fine, .none: break
        }
        updateBandit(for: session, outcome: .completed(feel: feel), at: endedAt)
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
        updateBandit(for: session, outcome: .swappedAway, at: date)
    }

    func history(before now: Date) -> [HistoryEntry] { entries }
    func allHistory() -> [HistoryEntry] { entries }
    func affinity() -> [String: Double] { affinityScores }
    func banditState() -> BanditState? { currentBanditState }
    func saveBanditState(_ state: BanditState) { currentBanditState = state }

    private func updateBandit(for session: Session, outcome: HistoryOutcome, at date: Date) {
        let state = currentBanditState ?? BanditState()
        let profile = PlanProfile(availableActivities: [session.activity, .stretching, .walking])
        let checkIn = storedCheckIn ?? PlanCheckIn(energy: .steady, time: .some)
        let context = PlanContext(now: date)
        let input = PlanInput(profile: profile, checkIn: checkIn, history: entries, context: context)
        let stats = HistoryStats(input: input)

        var hardRun = 0
        let completedEntries = entries.filter(\.wasCompleted)
        let dayStart = Calendar.current.movementDayStart(for: date)
        for dayOffset in 0..<7 {
            let matches = completedEntries.filter {
                let diff = Calendar.current.dateComponents([.day], from: Calendar.current.movementDayStart(for: $0.date), to: dayStart).day ?? 999
                return diff == dayOffset && $0.intensity >= 4
            }
            if !matches.isEmpty {
                hardRun += 1
            } else if dayOffset > 0 {
                break
            }
        }

        let updated = BanditEngine.update(
            state: state,
            session: session,
            outcome: outcome,
            profile: profile,
            checkIn: checkIn,
            stats: stats,
            context: context,
            consecutiveHardDays: hardRun
        )
        currentBanditState = updated
    }

    // MARK: The day

    private(set) var checkIns: [PlanCheckIn] = []
    private(set) var savedDays: [Menu] = []
    private(set) var keptSessions: [Session] = []
    private(set) var renamed: [String: String] = [:]
    private(set) var forgotten: [String] = []
    /// Set by a test that wants to open onto a day that already exists.
    var storedDay: Menu?
    var storedCheckIn: PlanCheckIn?

    func record(_ checkIn: PlanCheckIn, at takenAt: Date, dayStart: Date) {
        checkIns.append(checkIn)
        storedCheckIn = checkIn
    }

    func save(_ menu: Menu, generatedAt: Date) {
        savedDays.append(menu)
        storedDay = menu
    }

    func day(_ dayStart: Date, resolving session: (String) -> Session?) -> Menu? {
        storedDay?.dayStart == dayStart ? storedDay : nil
    }

    func checkIn(on dayStart: Date) -> PlanCheckIn? { storedCheckIn }

    // MARK: Somebody's own workouts

    @discardableResult
    func keep(title: String, description: String?, parts: [CustomRoutinePart], activity: Activity, durationMin: Int, intensity: Int, course: Course?, now: Date) -> Session {
        let session = Session.own(
            id: "own-\(keptSessions.count)",
            title: title,
            description: description,
            parts: parts,
            activity: activity,
            durationMin: durationMin,
            intensity: intensity,
            course: course
        )
        keptSessions.append(session)
        return session
    }

    func kept() -> [Session] { keptSessions }

    @discardableResult
    func update(
        _ sessionID: String,
        title: String,
        description: String?,
        parts: [CustomRoutinePart],
        activity: Activity,
        durationMin: Int,
        intensity: Int,
        course: Course
    ) -> Session? {
        guard let index = keptSessions.firstIndex(where: { $0.id == sessionID }) else { return nil }
        let updated = Session.own(
            id: sessionID,
            title: title,
            description: description,
            parts: parts,
            activity: activity,
            durationMin: durationMin,
            intensity: intensity,
            course: course
        )
        keptSessions[index] = updated
        return updated
    }

    func rename(_ sessionID: String, to title: String) {
        renamed[sessionID] = title
        keptSessions = keptSessions.map { session in
            session.id == sessionID
                ? .own(id: session.id, title: title,
                       description: session.subtitle.isEmpty ? nil : session.subtitle,
                       parts: session.customRoutineParts,
                       activity: session.activity,
                       durationMin: session.durationMin, intensity: session.intensity, course: session.course)
                : session
        }
    }

    func forget(_ sessionID: String) {
        forgotten.append(sessionID)
        keptSessions.removeAll { $0.id == sessionID }
    }

    // MARK: Hidden exercises

    private(set) var hiddenSessions: Set<String> = []

    func hideSession(_ sessionID: String, at date: Date) {
        hiddenSessions.insert(sessionID)
    }

    func unhideSession(_ sessionID: String, at date: Date) {
        hiddenSessions.remove(sessionID)
    }

    func hiddenSessionIDs() -> Set<String> {
        hiddenSessions
    }
}
