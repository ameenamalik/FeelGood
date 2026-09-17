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
    var sportsRaw: [String] = []
    var equipmentRaw: [String]
    // Attributes added after the first build carry defaults so lightweight
    // migration can fill them in for stores that predate them. A new mandatory
    // attribute with no default fails migration outright, and the store then
    // cannot be opened at all.
    var placesRaw: [String] = [Place.home.rawValue]
    var cadenceRaw: String
    var momentsRaw: String = MovementMoments.aCouple.rawValue
    var realisticMinutes: Int
    var bestTimeOfDayRaw: String
    /// Kept for stores written before moving toward became multi-select.
    var intentRaw: String
    var intentsRaw: [String] = []
    var workAroundsRaw: [String]
    /// Sessions explicitly hidden ("Don't suggest this again"). Hard-filtered by the engine.
    var hiddenSessionIDsRaw: [String] = []
    /// Local hour for the optional daily invitation. `nil` means no reminder.
    var reminderHour: Int?
    var createdAt: Date
    var updatedAt: Date

    // MARK: Identity
    //
    // Separate from `answers` on purpose: these are facts about a person, not
    // inputs to the engine, and they never flow into `PlanProfile` or
    // `CopyPayload` — CLAUDE.md's "no name, no free text" rule for anything
    // that leaves the device applies here by construction, not by filtering.

    /// A free-text preference, same footing as a kept workout's own title —
    /// cosmetic, never read by the engine. Defaults to what Sign in with
    /// Apple offers on first grant, but always further editable.
    var nickname: String = ""
    /// A stable identifier for one of the bundled fruit mascots. The literal
    /// default keeps stores created before avatars migration-safe.
    var avatarRaw: String = "apple"
    /// The customizable color behind the mascot. `automatic` uses the
    /// mascot's art-directed default and keeps older stores migration-safe.
    var avatarBackgroundRaw: String = "automatic"
    /// Set once Sign in with Apple succeeds. Also what's handed to
    /// `PurchasesManager.logIn(appUserID:)` so RevenueCat's anonymous id
    /// swaps for a stable one tied to this Apple ID.
    var appleUserID: String?
    /// Apple only ever returns this on the *first* authorization for a given
    /// Apple ID + app pair — never re-sent on a later sign-in — so it is
    /// stored the moment it's seen and never overwritten with `nil`.

    init(answers: ProfileAnswers, reminderHour: Int? = nil, now: Date) {
        let intentValues = answers.intents.map(\.rawValue).sorted()
        activitiesRaw = answers.activities.map(\.rawValue).sorted()
        sportsRaw = answers.sports.map(\.rawValue).sorted()
        equipmentRaw = answers.equipment.map(\.rawValue).sorted()
        placesRaw = answers.places.map(\.rawValue).sorted()
        cadenceRaw = answers.cadence.rawValue
        momentsRaw = answers.moments.rawValue
        realisticMinutes = answers.realisticMinutes
        bestTimeOfDayRaw = answers.bestTimeOfDay.rawValue
        intentsRaw = intentValues
        intentRaw = intentValues.first ?? Intent.energize.rawValue
        workAroundsRaw = answers.workArounds.map(\.rawValue).sorted()
        hiddenSessionIDsRaw = answers.hiddenSessionIDs.sorted()
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
            sports: Set(sportsRaw.compactMap(SportPreference.init(rawValue:))),
            equipment: Set(equipmentRaw.compactMap(Equipment.init(rawValue:))).union([.none]),
            places: Set(placesRaw.compactMap(Place.init(rawValue:))),
            cadence: Cadence(rawValue: cadenceRaw) ?? .mostDays,
            moments: MovementMoments(rawValue: momentsRaw) ?? .aCouple,
            realisticMinutes: realisticMinutes,
            bestTimeOfDay: TimeOfDay(rawValue: bestTimeOfDayRaw) ?? .varies,
            intents: decodedIntents,
            workArounds: Set(workAroundsRaw.compactMap(WorkAround.init(rawValue:))),
            hiddenSessionIDs: Set(hiddenSessionIDsRaw)
        )
    }

    private var decodedIntents: Set<Intent> {
        let stored = Set(intentsRaw.compactMap(Intent.init(rawValue:)))
        if !stored.isEmpty { return stored }
        return [Intent(rawValue: intentRaw) ?? .energize]
    }

    /// Changing your mind is a normal thing to do, and the menu should follow
    /// the same day. `updatedAt` is what the root view re-keys on.
    func apply(_ answers: ProfileAnswers, now: Date) {
        activitiesRaw = answers.activities.map(\.rawValue).sorted()
        sportsRaw = answers.sports.map(\.rawValue).sorted()
        equipmentRaw = answers.equipment.map(\.rawValue).sorted()
        placesRaw = answers.places.map(\.rawValue).sorted()
        cadenceRaw = answers.cadence.rawValue
        momentsRaw = answers.moments.rawValue
        realisticMinutes = answers.realisticMinutes
        bestTimeOfDayRaw = answers.bestTimeOfDay.rawValue
        intentsRaw = answers.intents.map(\.rawValue).sorted()
        intentRaw = intentsRaw.first ?? Intent.energize.rawValue
        workAroundsRaw = answers.workArounds.map(\.rawValue).sorted()
        hiddenSessionIDsRaw = answers.hiddenSessionIDs.sorted()
        updatedAt = now
    }

    func hideSession(_ sessionID: String, now: Date = Date()) {
        var current = Set(hiddenSessionIDsRaw)
        current.insert(sessionID)
        hiddenSessionIDsRaw = current.sorted()
        updatedAt = now
    }

    func unhideSession(_ sessionID: String, now: Date = Date()) {
        var current = Set(hiddenSessionIDsRaw)
        current.remove(sessionID)
        hiddenSessionIDsRaw = current.sorted()
        updatedAt = now
    }

    /// The engine's view of this profile: the answers plus everything they
    /// imply. Derived on read, never stored, so unticking the gym takes the
    /// weights with it.
    var planProfile: PlanProfile { answers.planProfile }

    /// Sign in with Apple succeeded. The app-scoped user id is the only thing
    /// kept: it is what lets a subscription survive a reinstall, and it is not
    /// a name, an email, or anything that reaches analytics. `nickname` stays
    /// whatever the person typed. Does not touch `updatedAt`: identity has no
    /// bearing on the plan or the menu, and bumping it would force
    /// `RootView`'s `.id(profile.updatedAt)` to remount `TodayScreen` for no
    /// reason connected to the day it's showing.
    func applyAppleSignIn(userID: String) {
        appleUserID = userID
    }

    /// Local sign-out. `nickname` survives — it's a preference somebody may
    /// have typed themselves, not a fact about the Apple account.
    func signOutOfApple() {
        appleUserID = nil
    }

    var avatar: ProfileAvatar {
        get { ProfileAvatar(rawValue: avatarRaw) ?? .defaultAvatar }
        set { avatarRaw = newValue.rawValue }
    }

    var avatarBackground: ProfileAvatarBackground {
        get { ProfileAvatarBackground(rawValue: avatarBackgroundRaw) ?? .automatic }
        set { avatarBackgroundRaw = newValue.rawValue }
    }
}

// MARK: - Check-in

nonisolated private func encodeBodyStates(_ states: Set<BodyState>) -> String? {
    guard !states.isEmpty else { return nil }
    return states.map(\.rawValue).sorted().joined(separator: ",")
}

nonisolated private func decodeBodyStates(_ raw: String?) -> Set<BodyState> {
    guard let raw else { return [] }
    return Set(raw.split(separator: ",").compactMap { BodyState(rawValue: String($0)) })
}

@Model
final class CheckInRecord {
    var takenAt: Date
    /// Start of the local day this check-in belongs to.
    var dayStart: Date
    var energyRaw: String
    var timeRaw: String
    var placeRaw: String?
    var bodyRaw: String?

    init(checkIn: PlanCheckIn, takenAt: Date, dayStart: Date) {
        self.takenAt = takenAt
        self.dayStart = dayStart
        energyRaw = checkIn.energy.rawValue
        timeRaw = checkIn.time.rawValue
        placeRaw = checkIn.place?.rawValue
        bodyRaw = encodeBodyStates(checkIn.bodies)
    }

    var planCheckIn: PlanCheckIn? {
        guard let energy = Energy(rawValue: energyRaw),
              let time = TimeBudget(rawValue: timeRaw) else { return nil }
        return PlanCheckIn(
            energy: energy,
            time: time,
            place: placeRaw.flatMap(PlaceIntent.init(rawValue:)),
            bodies: decodeBodyStates(bodyRaw)
        )
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
        assumedBodyRaw = encodeBodyStates(assumedCheckIn.bodies)
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
            bodies: decodeBodyStates(assumedBodyRaw)
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
    var durationMin: Int = 0
    var placeRaw: String?

    init(
        session: Session,
        startedAt: Date,
        dayStart: Date,
        endedAt: Date? = nil,
        outcome: HistoryOutcome,
        place: Place? = nil
    ) {
        sessionID = session.id
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.dayStart = dayStart
        activityRaw = session.activity.rawValue
        qualitiesRaw = session.qualities.map(\.rawValue)
        intensity = session.intensity
        courseRaw = session.course.rawValue
        durationMin = session.durationMin
        placeRaw = place?.rawValue
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

    /// Mirrors `HistoryEntry.wasCompleted`, so callers don't have to build a
    /// history entry just to ask whether this happened.
    var wasCompleted: Bool {
        if case .completed = outcome { return true }
        return false
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
            durationMin: durationMin,
            place: placeRaw.flatMap(Place.init(rawValue:)),
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
    /// Optional copy written by the person who created the routine.
    var sessionDescription: String? = nil
    /// JSON keeps the ordered value-type parts together without another model
    /// relationship. `nil` is the migration-safe shape for older routines.
    var partsData: Data? = nil
    var activityRaw: String
    var durationMin: Int
    /// 1...5, from three words on the log sheet rather than a number.
    var intensity: Int
    var courseRaw: String? = nil
    var createdAt: Date

    init(
        id: String = "own-\(UUID().uuidString)",
        title: String,
        description: String? = nil,
        parts: [CustomRoutinePart] = [],
        activity: Activity,
        durationMin: Int,
        intensity: Int,
        course: Course? = nil,
        createdAt: Date
    ) {
        self.id = id
        self.title = title
        sessionDescription = description
        partsData = try? JSONEncoder().encode(parts)
        activityRaw = activity.rawValue
        self.durationMin = durationMin
        self.intensity = intensity
        self.courseRaw = course?.rawValue
        self.createdAt = createdAt
    }

    var activity: Activity { Activity(rawValue: activityRaw) ?? .strength }
    var course: Course? { courseRaw.flatMap(Course.init(rawValue:)) }
    var parts: [CustomRoutinePart] {
        get {
            guard let partsData else { return [] }
            return (try? JSONDecoder().decode([CustomRoutinePart].self, from: partsData)) ?? []
        }
        set { partsData = try? JSONEncoder().encode(newValue) }
    }

    var session: Session {
        .own(
            id: id,
            title: title,
            description: sessionDescription,
            parts: parts,
            activity: activity,
            durationMin: durationMin,
            intensity: intensity,
            course: course
        )
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

// MARK: - Bandit State

/// On-device model state for the contextual bandit recommendation loop.
/// Compact covariance and weight tensors persisted locally in SwiftData.
@Model
final class BanditStateRecord {
    @Attribute(.unique) var id: String
    var modelVersion: Int
    var stateData: Data
    var updatedAt: Date

    init(id: String = "default", modelVersion: Int = 1, stateData: Data, updatedAt: Date = Date()) {
        self.id = id
        self.modelVersion = modelVersion
        self.stateData = stateData
        self.updatedAt = updatedAt
    }

    init(id: String = "default", modelVersion: Int = 1, state: BanditState, updatedAt: Date = Date()) {
        self.id = id
        self.modelVersion = modelVersion
        self.stateData = (try? JSONEncoder().encode(state)) ?? Data()
        self.updatedAt = updatedAt
    }

    var banditState: BanditState? {
        try? JSONDecoder().decode(BanditState.self, from: stateData)
    }
}
