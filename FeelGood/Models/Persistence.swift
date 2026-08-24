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

    init(answers: ProfileAnswers, reminderHour: Int? = nil, now: Date) {
        activitiesRaw = answers.activities.map(\.rawValue).sorted()
        equipmentRaw = answers.equipment.map(\.rawValue).sorted()
        cadenceRaw = answers.cadence.rawValue
        realisticMinutes = answers.realisticMinutes
        bestTimeOfDayRaw = answers.bestTimeOfDay.rawValue
        intentRaw = answers.intent.rawValue
        workAroundsRaw = answers.workArounds.map(\.rawValue).sorted()
        self.reminderHour = reminderHour
        createdAt = now
        updatedAt = now
    }

    /// What was actually ticked, so the edit screen shows the answers back
    /// rather than everything they implied. Unknown raw values are dropped
    /// rather than crashing — an older build reading a newer store still
    /// plans a day.
    var answers: ProfileAnswers {
        ProfileAnswers(
            activities: Set(activitiesRaw.compactMap(Activity.init(rawValue:))),
            equipment: Set(equipmentRaw.compactMap(Equipment.init(rawValue:))).union([.none]),
            cadence: Cadence(rawValue: cadenceRaw) ?? .mostDays,
            realisticMinutes: realisticMinutes,
            bestTimeOfDay: TimeOfDay(rawValue: bestTimeOfDayRaw) ?? .varies,
            intent: Intent(rawValue: intentRaw) ?? .energize,
            workArounds: Set(workAroundsRaw.compactMap(WorkAround.init(rawValue:)))
        )
    }

    /// Changing your mind is a normal thing to do, and the menu should follow
    /// the same day. `updatedAt` is what the root view re-keys on.
    func apply(_ answers: ProfileAnswers, now: Date) {
        activitiesRaw = answers.activities.map(\.rawValue).sorted()
        equipmentRaw = answers.equipment.map(\.rawValue).sorted()
        cadenceRaw = answers.cadence.rawValue
        realisticMinutes = answers.realisticMinutes
        bestTimeOfDayRaw = answers.bestTimeOfDay.rawValue
        intentRaw = answers.intent.rawValue
        workAroundsRaw = answers.workArounds.map(\.rawValue).sorted()
        updatedAt = now
    }

    /// The engine's view of this profile: the answers plus everything they
    /// imply. Derived on read, never stored, so unticking the gym takes the
    /// weights with it.
    var planProfile: PlanProfile { answers.planProfile }
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
    /// What the engine assumed when the check-in was skipped. Stored so a
    /// restored day is the same day, not a fresh guess at it.
    var assumedEnergyRaw: String
    var assumedTimeRaw: String
    var assumedBodyRaw: String?
    @Relationship(deleteRule: .cascade, inverse: \PlanItem.day)
    var items: [PlanItem]

    init(
        dayStart: Date,
        generatedAt: Date,
        headline: String,
        headlineIsWritten: Bool = false,
        assumedCheckIn: PlanCheckIn = PlanCheckIn(energy: .steady, time: .some),
        items: [PlanItem] = []
    ) {
        self.dayStart = dayStart
        self.generatedAt = generatedAt
        self.headline = headline
        self.headlineIsWritten = headlineIsWritten
        assumedEnergyRaw = assumedCheckIn.energy.rawValue
        assumedTimeRaw = assumedCheckIn.time.rawValue
        assumedBodyRaw = assumedCheckIn.body?.rawValue
        self.items = items
    }

    convenience init(menu: Menu, generatedAt: Date) {
        self.init(
            dayStart: menu.dayStart,
            generatedAt: generatedAt,
            headline: menu.headline,
            assumedCheckIn: menu.assumedCheckIn,
            items: menu.items.enumerated().map { PlanItem(item: $1, order: $0) }
        )
    }

    var assumedCheckIn: PlanCheckIn {
        PlanCheckIn(
            energy: Energy(rawValue: assumedEnergyRaw) ?? .steady,
            time: TimeBudget(rawValue: assumedTimeRaw) ?? .some,
            body: assumedBodyRaw.flatMap(BodyState.init(rawValue:))
        )
    }

    /// Rebuilds the day exactly as it was shown. A session the catalog no
    /// longer carries is simply absent rather than fatal — the rest of the day
    /// stays the day it was.
    func menu(resolving session: (String) -> Session?) -> Menu {
        var appetizer: MenuItem?
        var main: MenuItem?
        var sides: [MenuItem] = []
        var dessert: MenuItem?
        var special: MenuItem?

        for stored in items.sorted(by: { $0.order < $1.order }) {
            guard let found = session(stored.sessionID), let course = stored.course else { continue }
            let item = MenuItem(
                session: found,
                course: course,
                reasons: stored.reasonCodes,
                reasonText: stored.reasonText
            )
            switch course {
            case .appetizer: appetizer = item
            case .main: main = item
            case .side: sides.append(item)
            case .dessert: dessert = item
            case .special: special = item
            }
        }

        return Menu(
            dayStart: dayStart,
            appetizer: appetizer,
            main: main,
            sides: sides,
            dessert: dessert,
            special: special,
            headline: headline,
            assumedCheckIn: assumedCheckIn
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

// MARK: - Somebody's own workout

/// A workout somebody described themselves and chose to keep. It joins the
/// candidate pool and is scored exactly like an authored session — the engine
/// has no notion of "yours" versus "ours", which is the point: your own
/// swimming counts as endurance in the same week the catalog's does.
@Model
final class CustomSession {
    @Attribute(.unique) var id: String
    var title: String
    var activityRaw: String
    var durationMin: Int
    /// 1...5, from three words on the log sheet rather than a number.
    var intensity: Int
    var createdAt: Date

    init(id: String = "own-\(UUID().uuidString)", title: String, activity: Activity, durationMin: Int, intensity: Int, createdAt: Date) {
        self.id = id
        self.title = title
        activityRaw = activity.rawValue
        self.durationMin = durationMin
        self.intensity = intensity
        self.createdAt = createdAt
    }

    var activity: Activity { Activity(rawValue: activityRaw) ?? .strength }

    var session: Session {
        .own(id: id, title: title, activity: activity, durationMin: durationMin, intensity: intensity)
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
