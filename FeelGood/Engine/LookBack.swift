//
//  LookBack.swift
//  FeelGood
//
//  Consistency without streaks (PRD §7.4). Observations, not scores: nothing
//  here can be broken, lost or restored, and **absence is never rendered.**
//  There is no sentence in this type that names a day somebody wasn't here.
//
//  Pure, like the engine: a function of (history, affinity, calendar, now).
//

import Foundation

nonisolated struct LookBack: Sendable, Hashable {

    /// One plain sentence. Never a number out of a target, never a percentage.
    struct Observation: Sendable, Hashable, Identifiable {
        let id: String
        let text: String
    }

    let observations: [Observation]

    /// Below this there is nothing worth generalising from, and guessing at a
    /// pattern from two sessions would be worse than saying nothing.
    static let minimumSessions = 3

    /// The forward-looking empty state. Not "you haven't been here" — this is
    /// where the last two weeks will appear once there are some.
    static let openingLine = "This is where your last couple of weeks will show up."

    var isEmpty: Bool { observations.isEmpty }

    init(
        history: [HistoryEntry],
        affinity: [String: Double] = [:],
        calendar: Calendar,
        now: Date
    ) {
        let today = calendar.startOfDay(for: now)
        func daysAgo(_ date: Date) -> Int {
            calendar.dateComponents([.day], from: calendar.startOfDay(for: date), to: today).day ?? .max
        }

        let window = history.filter {
            $0.wasCompleted && (0..<PlanEngine.historyWindowDays).contains(daysAgo($0.date))
        }

        guard window.count >= Self.minimumSessions else {
            observations = []
            return
        }

        var lines: [Observation] = []

        lines.append(Observation(id: "count", text: Self.countLine(window.count)))

        if let when = Self.modal(window.map { TimeOfDay(hour: calendar.component(.hour, from: $0.date)) }) {
            lines.append(Observation(id: "when", text: "Mostly \(Self.spoken(when))."))
        }

        let activities = Self.mostCommon(window.map(\.activity), limit: 2)
        if !activities.isEmpty {
            let named = activities.map(Self.spoken).joined(separator: " and ")
            lines.append(Observation(id: "what", text: "Mostly \(named)."))
        }

        if let favourite = Self.favourite(in: window, affinity: affinity) {
            lines.append(
                Observation(
                    id: "favourite",
                    text: "The \(Self.spoken(favourite)) sessions are the ones you keep coming back to."
                )
            )
        }

        observations = lines
    }

    // MARK: - Copy

    private static func countLine(_ count: Int) -> String {
        switch count {
        case 1: "You've moved once in the last two weeks."
        case 2: "You've moved twice in the last two weeks."
        default: "You've moved \(count) times in the last two weeks."
        }
    }

    /// Mid-sentence, so everything is lowercase except the one activity that
    /// is a proper name.
    private static func spoken(_ activity: Activity) -> String {
        activity == .pilates ? activity.label : activity.label.lowercased()
    }

    private static func spoken(_ when: TimeOfDay) -> String {
        switch when {
        case .morning: "mornings"
        case .midday: "the middle of the day"
        case .evening: "evenings"
        case .varies: "whenever there's room"
        }
    }

    // MARK: - Patterns

    /// The clear winner, or nothing. A pattern that only just edges ahead is
    /// not a pattern, and stating it as one would be making something up.
    private static func modal<T: Hashable>(_ values: [T]) -> T? {
        var counts: [T: Int] = [:]
        for value in values { counts[value, default: 0] += 1 }
        let ranked = counts.sorted { $0.value > $1.value }
        guard let top = ranked.first else { return nil }
        guard Double(top.value) > Double(values.count) / 2 else { return nil }
        if ranked.count > 1, ranked[1].value == top.value { return nil }
        return top.key
    }

    private static func mostCommon(_ activities: [Activity], limit: Int) -> [Activity] {
        var counts: [Activity: Int] = [:]
        for activity in activities { counts[activity, default: 0] += 1 }
        return counts
            // Count first, then the raw value, so the same fortnight always
            // reads the same way.
            .sorted { $0.value == $1.value ? $0.key.rawValue < $1.key.rawValue : $0.value > $1.value }
            .prefix(limit)
            .filter { $0.value > 1 }
            .map(\.key)
    }

    /// What genuinely got loved, not merely what got done most.
    private static func favourite(in window: [HistoryEntry], affinity: [String: Double]) -> Activity? {
        var byActivity: [Activity: Double] = [:]
        for entry in window {
            guard let score = affinity[entry.sessionID], score > 0 else { continue }
            byActivity[entry.activity, default: 0] += score
        }
        let ranked = byActivity.sorted {
            $0.value == $1.value ? $0.key.rawValue < $1.key.rawValue : $0.value > $1.value
        }
        guard let top = ranked.first, top.value > 0 else { return nil }
        if ranked.count > 1, ranked[1].value == top.value { return nil }
        return top.key
    }
}
