//
//  LookBack.swift
//  FeelGood
//
//  PRD §7.4 — consistency without streaks.
//
//  Observations, not scores. Nothing here counts down, compares, ranks, or
//  congratulates, and nothing renders a gap: an absence of movement produces
//  fewer observations, never an observation about absence. There is
//  deliberately no case that can say "you missed", "you're behind", or "0".
//
//  Pure, like the engine next door: a function of (history, context). No I/O,
//  no store, and `now` arrives in `PlanContext` rather than from the clock.
//
//  What comes out is *structured*, not written. The wording lives in
//  `Display.swift` with the rest of the copy, so a change of voice is a change
//  to one switch and the tests here keep asserting on meaning.
//

import Foundation

/// What the last two weeks looked like.
nonisolated struct Reflection: Hashable, Sendable {
    /// One thing that is true about the window.
    ///
    /// Named `Note` rather than `Observation` on purpose: a top-level type
    /// called `Observation` shadows Apple's framework of that name, and every
    /// `@Observable` in the app stops compiling.
    nonisolated enum Note: Hashable, Sendable {
        /// How many sessions were finished. Never zero — see `isEarly`.
        case moved(times: Int)
        /// When they mostly happened.
        case mostly(TimeOfDay)
        /// What they mostly were. One or two, never a ranked list.
        case activities([Activity])
        /// A specific session that gets loved or repeated.
        case keepsReturningToSession(sessionID: String, title: String, activity: Activity)
        /// The one that gets loved, as distinct from the one that gets done most.
        case keepsReturningTo(Activity)
        /// Rest counts as showing up. PRD §6 — recovery is part of the balance.
        case madeRoomForRest
    }

    /// `moved` first, then the quieter ones. Empty before anything has
    /// happened — which is a beginning, not a zero, and the view says so.
    var notes: [Note]

    var isEarly: Bool { notes.isEmpty }

    /// The single most interesting true thing, so the view can say one
    /// thing well instead of five things vaguely. Ranked by specificity —
    /// naming an actual session is more specific than naming an activity,
    /// which is more specific than a time of day, which is more specific
    /// than a bare count. `moved` is always present once anything has
    /// happened, so this is only `nil` when `isEarly` is.
    var headline: Note? {
        func specificity(_ note: Note) -> Int {
            switch note {
            case .keepsReturningToSession: 0
            case .keepsReturningTo: 1
            case .activities: 2
            case .mostly: 3
            case .madeRoomForRest: 4
            case .moved: 5
            }
        }
        return notes.min { specificity($0) < specificity($1) }
    }
}

nonisolated enum LookBack {
    /// Below this, a pattern is a coincidence. Telling someone they are
    /// "mostly mornings" on the strength of one Tuesday is a made-up fact.
    static let minimumForPattern = 3

    /// How many times a thing has to come round before "you keep coming back
    /// to this" is a fair thing to say.
    static let minimumForReturning = 2

    static func reflect(
        history: [HistoryEntry],
        sessions: [Session] = [],
        context: PlanContext
    ) -> Reflection {
        let done = completedInWindow(history, context: context)
        guard !done.isEmpty else { return Reflection(notes: []) }

        var notes: [Reflection.Note] = [.moved(times: done.count)]
        if let when = dominantTimeOfDay(done, context: context) { notes.append(.mostly(when)) }

        let top = topActivities(done)
        if !top.isEmpty { notes.append(.activities(top)) }

        if let returnedSession = mostReturnedSession(done, sessions: sessions) {
            notes.append(returnedSession)
        } else if let loved = mostLoved(done, excluding: Set(top)) {
            notes.append(.keepsReturningTo(loved))
        }
        if madeRoomForRest(done) { notes.append(.madeRoomForRest) }

        return Reflection(notes: notes)
    }

    // MARK: Window

    private static func completedInWindow(
        _ history: [HistoryEntry],
        context: PlanContext
    ) -> [HistoryEntry] {
        let calendar = context.calendar
        let today = calendar.startOfDay(for: context.now)

        func daysAgo(_ date: Date) -> Int {
            calendar.dateComponents([.day], from: calendar.startOfDay(for: date), to: today).day ?? .max
        }

        return history.filter {
            $0.wasCompleted
                && daysAgo($0.date) >= 0
                && daysAgo($0.date) < PlanEngine.historyWindowDays
        }
    }

    // MARK: Patterns

    private static func dominantTimeOfDay(
        _ done: [HistoryEntry],
        context: PlanContext
    ) -> TimeOfDay? {
        guard done.count >= minimumForPattern else { return nil }

        let counts = Dictionary(
            done.map { (bucket(for: $0.date, context: context), 1) },
            uniquingKeysWith: +
        )
        guard let winner = counts.max(by: { ($0.value, $1.key.rawValue) < ($1.value, $0.key.rawValue) })
        else { return nil }
        // "Mostly" has to mean mostly. A three-way split has no dominant time
        // of day, and claiming one would be inventing a habit.
        guard winner.value * 2 >= done.count else { return nil }

        return winner.key
    }

    /// At most two, and only two when one alone doesn't carry "mostly".
    private static func topActivities(_ done: [HistoryEntry]) -> [Activity] {
        guard done.count >= minimumForPattern else { return [] }

        let counts = Dictionary(done.map { ($0.activity, 1) }, uniquingKeysWith: +)
        // Ties break on the raw value so the same history always reads the same.
        let ranked = counts
            .sorted { ($0.value, $1.key.rawValue) > ($1.value, $0.key.rawValue) }
            .map(\.key)

        guard let first = ranked.first else { return [] }
        if (counts[first] ?? 0) * 2 >= done.count { return [first] }
        return Array(ranked.prefix(2))
    }

    private static func mostReturnedSession(
        _ done: [HistoryEntry],
        sessions: [Session]
    ) -> Reflection.Note? {
        guard !sessions.isEmpty else { return nil }
        let sessionsByID = Dictionary(sessions.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })

        struct SessionStats {
            var totalCount: Int = 0
            var lovedCount: Int = 0
            var latestDate: Date = .distantPast
        }

        var statsByID: [String: SessionStats] = [:]
        for entry in done {
            var s = statsByID[entry.sessionID, default: SessionStats()]
            s.totalCount += 1
            if case .completed(let feel) = entry.outcome, feel == .lovedIt {
                s.lovedCount += 1
            }
            if entry.date > s.latestDate {
                s.latestDate = entry.date
            }
            statsByID[entry.sessionID] = s
        }

        let eligible = statsByID.filter { $0.value.totalCount >= minimumForReturning }
        guard !eligible.isEmpty else { return nil }

        let sorted = eligible.sorted { lhs, rhs in
            if lhs.value.lovedCount != rhs.value.lovedCount {
                return lhs.value.lovedCount > rhs.value.lovedCount
            }
            if lhs.value.totalCount != rhs.value.totalCount {
                return lhs.value.totalCount > rhs.value.totalCount
            }
            if lhs.value.latestDate != rhs.value.latestDate {
                return lhs.value.latestDate > rhs.value.latestDate
            }
            return lhs.key < rhs.key
        }

        guard let winnerID = sorted.first?.key,
              let session = sessionsByID[winnerID],
              !session.title.isEmpty
        else {
            return nil
        }

        return .keepsReturningToSession(
            sessionID: session.id,
            title: session.title,
            activity: session.activity
        )
    }

    private static func mostLoved(_ done: [HistoryEntry], excluding named: Set<Activity>) -> Activity? {
        let loved = done.filter {
            if case .completed(let feel) = $0.outcome { return feel == .lovedIt }
            return false
        }
        let counts = Dictionary(loved.map { ($0.activity, 1) }, uniquingKeysWith: +)
        guard let winner = counts.max(by: { ($0.value, $1.key.rawValue) < ($1.value, $0.key.rawValue) }),
              winner.value >= minimumForReturning,
              // Never say the same thing twice in one reflection.
              !named.contains(winner.key)
        else { return nil }

        return winner.key
    }

    private static func madeRoomForRest(_ done: [HistoryEntry]) -> Bool {
        let restful = done.filter { $0.intensity <= PlanWeights().restfulIntensity }
        return restful.count >= minimumForReturning
    }

    private static func bucket(for date: Date, context: PlanContext) -> TimeOfDay {
        switch context.calendar.component(.hour, from: date) {
        case ..<12: .morning
        case 12..<17: .midday
        default: .evening
        }
    }
}
