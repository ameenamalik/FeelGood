//
//  PlanTypes.swift
//  FeelGood
//
//  Inputs to the planning engine. All value types: the engine is a pure
//  function of these and never touches SwiftData, the network, or the clock.
//  See PRD §7.3 / §11.
//

import Foundation

// MARK: - Profile

/// How often she *wants* to move. Used for gentle balancing, never for grading.
enum Cadence: String, Codable, CaseIterable, Sendable {
    case everyDay, mostDays, fewTimesAWeek, whenICan

    /// Sessions per week she's aiming at. Used only to soften suggestions when
    /// she's below it — there is no penalty branch anywhere in the engine.
    var weeklyTarget: Int {
        switch self {
        case .everyDay: 7
        case .mostDays: 5
        case .fewTimesAWeek: 3
        case .whenICan: 1
        }
    }
}

enum TimeOfDay: String, Codable, CaseIterable, Sendable {
    case morning, midday, evening, varies
}

/// The engine's view of the profile — the answers from onboarding (PRD §7.1).
struct PlanProfile: Hashable, Sendable {
    var availableActivities: Set<Activity>
    var equipment: Set<Equipment>
    var cadence: Cadence
    /// What's realistic on a normal day: 10 / 20 / 30 / 45.
    var realisticMinutes: Int
    var bestTimeOfDay: TimeOfDay
    var intent: Intent
    var workArounds: Set<WorkAround>

    init(
        availableActivities: Set<Activity>,
        equipment: Set<Equipment> = [.none],
        cadence: Cadence = .mostDays,
        realisticMinutes: Int = 20,
        bestTimeOfDay: TimeOfDay = .varies,
        intent: Intent = .energize,
        workArounds: Set<WorkAround> = []
    ) {
        self.availableActivities = availableActivities
        self.equipment = equipment.union([.none])
        self.cadence = cadence
        self.realisticMinutes = realisticMinutes
        self.bestTimeOfDay = bestTimeOfDay
        self.intent = intent
        self.workArounds = workArounds
    }
}

// MARK: - Check-in

/// How much time she actually has today.
enum TimeBudget: String, Codable, CaseIterable, Sendable {
    case aLittle, some, plenty

    /// Hard ceiling on session length. Never recommend 30 when she said 10.
    var maxMinutes: Int {
        switch self {
        case .aLittle: 10
        case .some: 30
        case .plenty: 60
        }
    }
}

enum BodyState: String, Codable, CaseIterable, Sendable {
    case sore, stiff, stressed, cramping, good
}

/// Two taps, ten seconds. The optional third is body.
struct PlanCheckIn: Hashable, Sendable {
    var energy: Energy
    var time: TimeBudget
    var body: BodyState?

    init(energy: Energy, time: TimeBudget, body: BodyState? = nil) {
        self.energy = energy
        self.time = time
        self.body = body
    }
}

// MARK: - History

/// How a session felt afterwards. Three faces, no score.
enum Feel: String, Codable, CaseIterable, Sendable {
    case lovedIt, fine, tooMuch
}

enum HistoryOutcome: Hashable, Sendable {
    case completed(feel: Feel?)
    case swappedAway
    case skipped
}

/// One day's worth of what actually happened. The engine reads the last 14.
struct HistoryEntry: Hashable, Sendable {
    var sessionID: String
    var activity: Activity
    var qualities: [Quality]
    var intensity: Int
    var course: Course
    /// Absolute instant, stored UTC, rendered local.
    var date: Date
    var outcome: HistoryOutcome

    var wasCompleted: Bool {
        if case .completed = outcome { return true }
        return false
    }
}

// MARK: - Context

/// Something planned ahead of the day — the 8am reformer class on Thursday.
struct ScheduledSpecial: Hashable, Sendable {
    var sessionID: String
    var date: Date
}

/// Everything about right now that isn't her.
struct PlanContext: Hashable, Sendable {
    var now: Date
    /// Offline, or on cellular with data saver — video Mains are filtered out
    /// silently and the authored catalog carries the day.
    var isOffline: Bool
    var dataSaver: Bool
    var scheduledSpecials: [ScheduledSpecial]
    var calendar: Calendar

    init(
        now: Date,
        isOffline: Bool = false,
        dataSaver: Bool = false,
        scheduledSpecials: [ScheduledSpecial] = [],
        calendar: Calendar = .current
    ) {
        self.now = now
        self.isOffline = isOffline
        self.dataSaver = dataSaver
        self.scheduledSpecials = scheduledSpecials
        self.calendar = calendar
    }

    var videoAllowed: Bool { !isOffline && !dataSaver }
}

/// The complete input to `PlanEngine.makeMenu`.
struct PlanInput: Hashable, Sendable {
    var profile: PlanProfile
    /// `nil` when she skipped it — the app never blocks on input, so the
    /// engine infers a check-in from history and time of day instead.
    var checkIn: PlanCheckIn?
    var history: [HistoryEntry]
    var context: PlanContext
    /// Persisted affinity by session id, roughly -1...1. Survives the 14-day
    /// history window so "loved it" keeps counting quietly.
    var affinity: [String: Double]

    init(
        profile: PlanProfile,
        checkIn: PlanCheckIn? = nil,
        history: [HistoryEntry] = [],
        context: PlanContext,
        affinity: [String: Double] = [:]
    ) {
        self.profile = profile
        self.checkIn = checkIn
        self.history = history
        self.context = context
        self.affinity = affinity
    }
}
