//
//  Persistence.swift
//  FeelGood
//
//  SwiftData models. Enums are persisted as raw strings rather than as Swift
//  enum types so a later vocabulary addition is a decode concern, not a store
//  migration. All timestamps are absolute (UTC); the local day a record belongs
//  to is stored explicitly alongside, because "today" is a calendar question.
//

import Foundation
import SwiftData

/// Everything the app persists. Passed to the container in one place.
enum FeelGoodSchema {
    static let models: [any PersistentModel.Type] = [
        UserProfile.self,
        CheckInRecord.self,
        PlanDay.self,
        PlanItem.self,
        SessionRecord.self,
        AffinityRecord.self,
        ContentVersionRecord.self,
    ]
}

// MARK: - Profile

@Model
final class UserProfile {
    var activitiesRaw: [String]
    var equipmentRaw: [String]
    var cadenceRaw: String
    var realisticMinutes: Int
    var bestTimeOfDayRaw: String
    var intentRaw: String
    var workAroundsRaw: [String]
    /// Local hour for the optional daily invitation. `nil` means no reminder.
    var reminderHour: Int?
    var createdAt: Date
    var updatedAt: Date

    init(
        activities: Set<Activity>,
        equipment: Set<Equipment>,
        cadence: Cadence,
        realisticMinutes: Int,
        bestTimeOfDay: TimeOfDay,
        intent: Intent,
        workArounds: Set<WorkAround>,
        reminderHour: Int? = nil,
        now: Date
    ) {
        activitiesRaw = activities.map(\.rawValue).sorted()
        equipmentRaw = equipment.map(\.rawValue).sorted()
        cadenceRaw = cadence.rawValue
        self.realisticMinutes = realisticMinutes
        bestTimeOfDayRaw = bestTimeOfDay.rawValue
        intentRaw = intent.rawValue
        workAroundsRaw = workArounds.map(\.rawValue).sorted()
        self.reminderHour = reminderHour
        createdAt = now
        updatedAt = now
    }

    /// The engine's view of this profile. Unknown raw values are dropped rather
    /// than crashing — an older build reading a newer store still plans a day.
    var planProfile: PlanProfile {
        PlanProfile(
            availableActivities: Set(activitiesRaw.compactMap(Activity.init(rawValue:))),
            equipment: Set(equipmentRaw.compactMap(Equipment.init(rawValue:))),
            cadence: Cadence(rawValue: cadenceRaw) ?? .mostDays,
            realisticMinutes: realisticMinutes,
            bestTimeOfDay: TimeOfDay(rawValue: bestTimeOfDayRaw) ?? .varies,
            intent: Intent(rawValue: intentRaw) ?? .energize,
            workArounds: Set(workAroundsRaw.compactMap(WorkAround.init(rawValue:)))
        )
    }
}

// MARK: - Check-in

@Model
final class CheckInRecord {
    var takenAt: Date
    /// Start of the local day this check-in belongs to.
    var dayStart: Date
    var energyRaw: String
    var timeRaw: String
    var bodyRaw: String?

    init(checkIn: PlanCheckIn, takenAt: Date, dayStart: Date) {
        self.takenAt = takenAt
        self.dayStart = dayStart
        energyRaw = checkIn.energy.rawValue
        timeRaw = checkIn.time.rawValue
        bodyRaw = checkIn.body?.rawValue
    }

    var planCheckIn: PlanCheckIn? {
        guard let energy = Energy(rawValue: energyRaw),
              let time = TimeBudget(rawValue: timeRaw) else { return nil }
        return PlanCheckIn(energy: energy, time: time, body: bodyRaw.flatMap(BodyState.init(rawValue:)))
    }
}

// MARK: - The day's menu

/// A generated menu, stored so the day is stable: reopening the app shows the
/// same menu rather than quietly regenerating a different one underneath you.
@Model
final class PlanDay {
    @Attribute(.unique) var dayStart: Date
    var generatedAt: Date
    var headline: String
    /// True once the copy layer has upgraded the headline in place.
    var headlineIsWritten: Bool
    @Relationship(deleteRule: .cascade, inverse: \PlanItem.day)
    var items: [PlanItem]

    init(dayStart: Date, generatedAt: Date, headline: String, headlineIsWritten: Bool = false, items: [PlanItem] = []) {
        self.dayStart = dayStart
        self.generatedAt = generatedAt
        self.headline = headline
        self.headlineIsWritten = headlineIsWritten
        self.items = items
    }

    convenience init(menu: Menu, generatedAt: Date) {
        self.init(
            dayStart: menu.dayStart,
            generatedAt: generatedAt,
            headline: menu.headline,
            items: menu.items.enumerated().map { PlanItem(item: $1, order: $0) }
        )
    }
}

@Model
final class PlanItem {
    var sessionID: String
    var courseRaw: String
    var reasonCodesRaw: [String]
    var reasonText: String
    var order: Int
    /// How many times this slot was turned down. Feeds affinity; it is never
    /// shown on screen and never treated as a failure.
    var swapCount: Int
    var day: PlanDay?

    init(item: MenuItem, order: Int) {
        sessionID = item.session.id
        courseRaw = item.course.rawValue
        reasonCodesRaw = item.reasons.map(\.rawValue)
        reasonText = item.reasonText
        self.order = order
        swapCount = 0
    }

    var course: Course? { Course(rawValue: courseRaw) }
    var reasonCodes: [ReasonCode] { reasonCodesRaw.compactMap(ReasonCode.init(rawValue:)) }
}

// MARK: - What actually happened

@Model
final class SessionRecord {
    var sessionID: String
    var startedAt: Date
    var endedAt: Date?
    var dayStart: Date
    /// `completed` / `swappedAway` / `skipped`.
    var outcomeRaw: String
    var feelRaw: String?
    // Denormalised so history survives a session being dropped from a later
    // catalog — the engine can still balance against what was actually done.
    var activityRaw: String
    var qualitiesRaw: [String]
    var intensity: Int
    var courseRaw: String

    init(
        session: Session,
        startedAt: Date,
        dayStart: Date,
        endedAt: Date? = nil,
        outcome: HistoryOutcome
    ) {
        sessionID = session.id
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.dayStart = dayStart
        activityRaw = session.activity.rawValue
        qualitiesRaw = session.qualities.map(\.rawValue)
        intensity = session.intensity
        courseRaw = session.course.rawValue
        switch outcome {
        case .completed(let feel):
            outcomeRaw = "completed"
            feelRaw = feel?.rawValue
        case .swappedAway:
            outcomeRaw = "swappedAway"
        case .skipped:
            outcomeRaw = "skipped"
        }
    }

    var outcome: HistoryOutcome {
        switch outcomeRaw {
        case "completed": .completed(feel: feelRaw.flatMap(Feel.init(rawValue:)))
        case "swappedAway": .swappedAway
        default: .skipped
        }
    }

    /// The engine reads history as plain values, never as model objects.
    var historyEntry: HistoryEntry {
        HistoryEntry(
            sessionID: sessionID,
            activity: Activity(rawValue: activityRaw) ?? .stretching,
            qualities: qualitiesRaw.compactMap(Quality.init(rawValue:)),
            intensity: intensity,
            course: Course(rawValue: courseRaw) ?? .main,
            date: endedAt ?? startedAt,
            outcome: outcome
        )
    }
}

// MARK: - Affinity

/// Rolled-up preference that outlives the 14-day history window, so "loved it"
/// keeps counting quietly long after the log has scrolled past.
@Model
final class AffinityRecord {
    @Attribute(.unique) var sessionID: String
    /// Roughly -1...1.
    var score: Double
    var updatedAt: Date

    init(sessionID: String, score: Double, updatedAt: Date) {
        self.sessionID = sessionID
        self.score = score
        self.updatedAt = updatedAt
    }
}

// MARK: - Content versioning

/// Which catalog version has been seeded, so a later remote drop knows whether
/// it has anything to do.
@Model
final class ContentVersionRecord {
    var version: Int
    var seededAt: Date

    init(version: Int, seededAt: Date) {
        self.version = version
        self.seededAt = seededAt
    }
}
