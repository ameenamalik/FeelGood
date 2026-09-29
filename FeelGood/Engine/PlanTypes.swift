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

/// How much the menu should decide by default. This is about the person's
/// relationship with FeelGood, not a fitness score; today's check-in can still
/// ask for something different on any given day.
nonisolated enum GuidancePreference: String, Codable, CaseIterable, Sendable {
    case gettingStarted
    case knowsWhatTheyEnjoy
    case hasOwnRoutine

    var sideCount: Int {
        switch self {
        case .gettingStarted: 0
        case .knowsWhatTheyEnjoy: 1
        case .hasOwnRoutine: 2
        }
    }
}

/// How often you *want* to move. Used for gentle balancing, never for grading.
nonisolated enum Cadence: String, Codable, CaseIterable, Sendable {
    case everyDay, mostDays, fewTimesAWeek, whenICan

    /// Sessions per week being aimed at. Used only to soften suggestions when
    /// the count is below it — there is no penalty branch anywhere in the engine.
    var weeklyTarget: Int {
        switch self {
        case .everyDay: 7
        case .mostDays: 5
        case .fewTimesAWeek: 3
        case .whenICan: 1
        }
    }
}

/// How many times a day you'd like intentional movement. Shapes the menu, not
/// the workload — the same twenty minutes arranged differently. Never a target,
/// never counted back.
nonisolated enum MovementMoments: String, Codable, CaseIterable, Sendable {
    /// One proper session. A hero Main and very little else.
    case once
    /// A main thing and something small.
    case aCouple
    /// Several small things attached to what's already happening.
    case sprinkled

    /// How many Sides belong on the menu.
    var sideCount: Int {
        switch self {
        case .once: 0
        case .aCouple: 1
        case .sprinkled: 2
        }
    }
}

nonisolated enum TimeOfDay: String, Codable, CaseIterable, Sendable {
    case morning, midday, evening, varies

    /// Where an hour falls in the day. The engine and the Look Back both read
    /// this, so the two can never come to different conclusions about what
    /// counts as a morning.
    init(hour: Int) {
        switch hour {
        case ..<11: self = .morning
        case ..<16: self = .midday
        default: self = .evening
        }
    }
}

/// Optional detail beneath the broad Sports movement choice. These preferences
/// make the profile feel specific without pretending every sport is a separate
/// authored session type in the catalog.
nonisolated enum SportPreference: String, Codable, CaseIterable, Sendable {
    case pickleball, tennis, basketball, soccer, volleyball, other
}

/// The engine's view of the profile — the answers from onboarding (PRD §7.1).
nonisolated struct PlanProfile: Hashable, Sendable {
    var guidancePreference: GuidancePreference
    var availableActivities: Set<Activity>
    /// Activities explicitly chosen by the person, before access-derived
    /// activities are added. Used to make familiar movement lead when asked.
    var preferredActivities: Set<Activity>
    var equipment: Set<Equipment>
    /// Where you can realistically be. Always includes `home`: there is always
    /// the floor you're standing on.
    var places: Set<Place>
    var cadence: Cadence
    var moments: MovementMoments
    /// What's realistic on a normal day: 10 / 20 / 30 / 45.
    var realisticMinutes: Int
    var bestTimeOfDay: TimeOfDay
    /// Any direction that feels relevant. A session matching at least one gets
    /// the intent nudge; choosing more never multiplies its score.
    var intents: Set<Intent>

    /// Stable fallback for copy that needs to speak about one direction.
    var primaryIntent: Intent {
        Intent.allCases.first(where: intents.contains) ?? .energize
    }
    var workArounds: Set<WorkAround>
    var hiddenSessionIDs: Set<String>

    init(
        availableActivities: Set<Activity>,
        preferredActivities: Set<Activity>? = nil,
        guidancePreference: GuidancePreference = .knowsWhatTheyEnjoy,
        equipment: Set<Equipment> = [.none],
        places: Set<Place> = [.home],
        cadence: Cadence = .mostDays,
        moments: MovementMoments = .aCouple,
        realisticMinutes: Int = 20,
        bestTimeOfDay: TimeOfDay = .varies,
        intent: Intent = .energize,
        workArounds: Set<WorkAround> = [],
        intents: Set<Intent>? = nil,
        hiddenSessionIDs: Set<String> = []
    ) {
        self.guidancePreference = guidancePreference
        self.availableActivities = availableActivities
        self.preferredActivities = preferredActivities ?? availableActivities
        self.equipment = equipment.union([.none])
        self.places = places.union([.home])
        self.cadence = cadence
        self.moments = moments
        self.realisticMinutes = realisticMinutes
        self.bestTimeOfDay = bestTimeOfDay
        self.intents = intents.flatMap { $0.isEmpty ? nil : $0 } ?? [intent]
        self.workArounds = workArounds
        self.hiddenSessionIDs = hiddenSessionIDs
    }
}

// MARK: - Check-in

/// How much time is actually available today.
nonisolated enum TimeBudget: String, Codable, CaseIterable, Sendable {
    case zeroMinutes
    case fiveMinutes
    case aLittle
    case fifteenMinutes
    case twentyMinutes
    case twentyFiveMinutes
    case some
    case thirtyFiveMinutes
    case fortyMinutes
    case fortyFiveMinutes
    case fiftyMinutes
    case plenty

    /// Hard ceiling on session length. Never recommend 30 when the answer was 10.
    var maxMinutes: Int {
        switch self {
        case .zeroMinutes: 0
        case .fiveMinutes: 5
        case .aLittle: 10
        case .fifteenMinutes: 15
        case .twentyMinutes: 20
        case .twentyFiveMinutes: 25
        case .some: 30
        case .thirtyFiveMinutes: 35
        case .fortyMinutes: 40
        case .fortyFiveMinutes: 45
        case .fiftyMinutes: 50
        case .plenty: 60
        }
    }

    /// Whether this represents a rest / recovery day with zero planned minutes.
    var isZero: Bool { maxMinutes == 0 }

    /// The first three timed stops need the short-session treatment and copy.
    var isTight: Bool { maxMinutes > 0 && maxMinutes <= 15 }
}

/// Where you're willing to be today. Optional, and defaults to whatever the
/// profile already says — but on a hard day it carries more signal than
/// anything else on the sheet.
nonisolated enum PlaceIntent: String, Codable, CaseIterable, Sendable {
    case stayingIn
    case happyToGoOut
    case atTheGym

    /// Narrows the profile's places. `home` survives all three, because it
    /// means "the floor you're standing on" rather than "your house".
    var places: Set<Place> {
        switch self {
        case .stayingIn: [.home]
        case .happyToGoOut: [.home, .outdoors, .studio, .pool]
        case .atTheGym: [.home, .gym]
        }
    }
}

nonisolated enum BodyState: String, Codable, CaseIterable, Sendable {
    case sore, stiff, stressed, cramping, good
}

/// Two taps, ten seconds. The optional body question accepts multiple concerns.
nonisolated struct PlanCheckIn: Hashable, Sendable {
    var energy: Energy
    var time: TimeBudget
    /// `nil` falls back to everything the profile allows.
    var place: PlaceIntent?
    var bodies: Set<BodyState>
    /// What was said *today*, e.g. through the chat check-in ("I want to
    /// calm down"). Overrides `profile.intents` for scoring this one menu —
    /// it is not persisted (`CheckInRecord` has no column for it), so a
    /// later swap the same day, or reopening tomorrow, falls back to the
    /// profile's standing intents same as always.
    var todayIntent: Intent?
    /// A body area asked for today ("Where do you want to feel strong?").
    /// A scoring nudge, never a filter. Like `todayIntent`, not persisted.
    var focus: BodyFocus? = nil
    /// Activities today's answer leans toward. Also a nudge only, so a thin
    /// catalog can never be left with an empty menu. Not persisted.
    var favoured: Set<Activity> = []

    /// Compatibility for call sites that provide a single concern. New
    /// check-ins use `bodies`; reading this returns the first display-ordered
    /// answer so older integrations continue to behave deterministically.
    var body: BodyState? {
        get { BodyState.allCases.first(where: bodies.contains) }
        set { bodies = newValue.map { Set([$0]) } ?? [] }
    }

    init(energy: Energy, time: TimeBudget, place: PlaceIntent? = nil, body: BodyState? = nil, todayIntent: Intent? = nil) {
        self.energy = energy
        self.time = time
        self.place = place
        bodies = body.map { Set([$0]) } ?? []
        self.todayIntent = todayIntent
    }

    init(energy: Energy, time: TimeBudget, place: PlaceIntent? = nil, bodies: Set<BodyState>, todayIntent: Intent? = nil) {
        self.energy = energy
        self.time = time
        self.place = place
        self.bodies = bodies
        self.todayIntent = todayIntent
    }
}

// MARK: - History

/// How a session felt afterwards. Three faces, no score.
nonisolated enum Feel: String, Codable, CaseIterable, Sendable {
    case lovedIt, fine, tooMuch
}

nonisolated enum HistoryOutcome: Hashable, Sendable {
    case completed(feel: Feel?)
    case swappedAway
    case skipped
}

/// One day's worth of what actually happened. The engine reads the last 14.
nonisolated struct HistoryEntry: Hashable, Sendable {
    var sessionID: String
    var activity: Activity
    var qualities: [Quality]
    var intensity: Int
    var course: Course
    /// Authored or explicitly logged length. This is intentionally not derived
    /// from wall-clock time: a paused five-minute reset is still a five-minute
    /// reset for Little Wins.
    var durationMin: Int = 0
    /// Where it actually happened when the person told us. `nil` means unknown,
    /// never "home by default".
    var place: Place? = nil
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
nonisolated struct ScheduledSpecial: Hashable, Sendable {
    var sessionID: String
    var date: Date
}

/// Everything about right now that isn't the person.
nonisolated struct PlanContext: Hashable, Sendable {
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

/// Memory handed to the engine (PRD §10.1, Decision 16).
///
/// Free tier gets `.recencyOnly`: enough to know whether you're returning after a gap
/// (so the return-after-a-gap warm shorter menu is available to everyone), but without
/// multi-day history balancing or affinity carrying forward.
///
/// Pro tier gets `.full`: 14-day history balancing, recovery downweighting, and long-term affinity.
nonisolated enum PlanMemory: Hashable, Sendable {
    case recencyOnly(lastActiveDate: Date?)
    case full(history: [HistoryEntry], affinity: [String: Double])

    var lastActiveDate: Date? {
        switch self {
        case .recencyOnly(let date):
            return date
        case .full(let history, _):
            return history.filter(\.wasCompleted).map(\.date).max()
        }
    }

    var historyEntries: [HistoryEntry] {
        switch self {
        case .recencyOnly:
            return []
        case .full(let history, _):
            return history
        }
    }

    var affinityScores: [String: Double] {
        switch self {
        case .recencyOnly:
            return [:]
        case .full(_, let affinity):
            return affinity
        }
    }
}

/// The complete input to `PlanEngine.makeMenu`.
nonisolated struct PlanInput: Hashable, Sendable {
    var profile: PlanProfile
    /// `nil` when it was skipped — the app never blocks on input, so the
    /// engine infers a check-in from history and time of day instead.
    var checkIn: PlanCheckIn?
    var memory: PlanMemory
    var context: PlanContext
    var banditState: BanditState?

    var history: [HistoryEntry] { memory.historyEntries }
    var affinity: [String: Double] { memory.affinityScores }

    init(
        profile: PlanProfile,
        checkIn: PlanCheckIn? = nil,
        memory: PlanMemory,
        context: PlanContext,
        banditState: BanditState? = nil
    ) {
        self.profile = profile
        self.checkIn = checkIn
        self.memory = memory
        self.context = context
        self.banditState = banditState
    }

    /// Test-only. Always builds `.full` memory, so a production call site
    /// using this instead of the primary initializer silently hands every
    /// install Pro's history and affinity regardless of entitlement — this
    /// already happened once, at `TodayModel`'s cold-start menu.
    init(
        profile: PlanProfile,
        checkIn: PlanCheckIn? = nil,
        history: [HistoryEntry] = [],
        context: PlanContext,
        affinity: [String: Double] = [:],
        banditState: BanditState? = nil
    ) {
        self.profile = profile
        self.checkIn = checkIn
        self.memory = .full(history: history, affinity: affinity)
        self.context = context
        self.banditState = banditState
    }
}
