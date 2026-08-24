//
//  TodayModel.swift
//  FeelGood
//
//  Holds today's menu and the two things that can change it: the check-in and
//  a swap. All the deciding happens in the engine; this only carries state.
//

import Foundation
import Observation

@Observable
final class TodayModel {
    private let store: any ContentProviding
    private let log: any ActivityLogging
    /// Rebuilt when somebody keeps a workout of their own. Not observed: the
    /// menu is what the screen watches, and this only ever produces one.
    @ObservationIgnored private var engine: PlanEngine
    private let calendar: Calendar

    var profile: PlanProfile
    private(set) var checkIn: PlanCheckIn?
    private(set) var history: [HistoryEntry]
    /// Long-memory preference, one entry per session id. Outlives the engine's
    /// fourteen-day history window.
    private(set) var affinity: [String: Double]
    /// Somebody's own workouts, scored alongside the authored catalog.
    private(set) var ownSessions: [Session]
    private(set) var menu: Menu
    /// Sessions already turned down today, so a swap never circles back.
    private(set) var swappedAway: Set<String> = []

    init(
        store: any ContentProviding,
        profile: PlanProfile,
        checkIn: PlanCheckIn? = nil,
        history: [HistoryEntry] = [],
        affinity: [String: Double] = [:],
        ownSessions: [Session] = [],
        log: any ActivityLogging = InMemoryActivityLog(),
        /// The day as it was already generated and stored. Used when it belongs
        /// to today, so reopening the app is the same day rather than a new
        /// guess at it.
        restoring stored: Menu? = nil,
        now: Date,
        calendar: Calendar = .current
    ) {
        self.store = store
        self.log = log
        let engine = PlanEngine(catalog: store.sessions + ownSessions)
        self.engine = engine
        self.profile = profile
        self.checkIn = checkIn
        self.history = history
        self.affinity = affinity
        self.ownSessions = ownSessions
        self.calendar = calendar

        if let stored, stored.dayStart == calendar.startOfDay(for: now) {
            menu = stored
        } else {
            let generated = engine.makeMenu(
                PlanInput(
                    profile: profile,
                    checkIn: checkIn,
                    history: history,
                    context: PlanContext(now: now, calendar: calendar),
                    affinity: affinity
                )
            )
            menu = generated
            log.save(generated, generatedAt: now)
        }
    }

    private func input(now: Date) -> PlanInput {
        PlanInput(
            profile: profile,
            checkIn: checkIn,
            history: history,
            context: PlanContext(now: now, calendar: calendar),
            affinity: affinity
        )
    }

    /// The check-in regenerates the menu in place.
    func apply(_ checkIn: PlanCheckIn, now: Date = Date()) {
        self.checkIn = checkIn
        swappedAway = []
        menu = engine.makeMenu(input(now: now))
        log.record(checkIn, at: now, dayStart: calendar.startOfDay(for: now))
        persist(now: now)
    }

    /// "Not today". A swap is engagement, not rejection — it is a choice being made,
    /// which is the whole point of the screen.
    func swap(_ item: MenuItem, now: Date = Date()) {
        guard let replacement = engine.alternative(
            for: item,
            onMenu: menu,
            input: input(now: now),
            alreadySeen: swappedAway
        ) else { return }

        swappedAway.insert(item.session.id)
        menu = menu.replacing(item, with: replacement)
        remember(item.session, outcome: .swappedAway, startedAt: now, endedAt: nil, now: now)
        // The card you exchanged stays exchanged when you come back to it.
        persist(now: now)
    }

    // MARK: - What happened

    /// The player finished or was left. Neither is a failure, and neither
    /// rebuilds the menu: what you just did should not vanish off the screen
    /// you are still looking at. It counts from the next menu on.
    func record(_ outcome: PlayerOutcome, for session: Session, startedAt: Date, now: Date = Date()) {
        remember(session, outcome: outcome.historyOutcome, startedAt: startedAt, endedAt: now, now: now)
    }

    /// Something done that was never on the menu. Kept workouts join the pool
    /// the engine picks from, so they can come back on a later menu.
    func log(_ workout: LoggedWorkout, now: Date = Date()) {
        let id = "own-\(UUID().uuidString)"
        let session: Session = workout.isKept
            ? log.keep(
                title: workout.title,
                activity: workout.activity,
                durationMin: workout.durationMin,
                intensity: workout.intensity,
                now: now
            )
            : .own(
                id: id,
                title: workout.title,
                activity: workout.activity,
                durationMin: workout.durationMin,
                intensity: workout.intensity
            )

        if workout.isKept {
            ownSessions.append(session)
            rebuildEngine()
        }
        remember(session, outcome: .completed(feel: nil), startedAt: now, endedAt: now, now: now)
    }

    /// The profile changed on the profile screen. The menu follows the same
    /// day, keeping today's check-in — changing your mind is not a reset.
    func update(profile: PlanProfile, now: Date = Date()) {
        self.profile = profile
        swappedAway = []
        menu = engine.makeMenu(input(now: now))
        persist(now: now)
    }

    private func persist(now: Date) {
        log.save(menu, generatedAt: now)
    }

    private func remember(
        _ session: Session,
        outcome: HistoryOutcome,
        startedAt: Date,
        endedAt: Date?,
        now: Date
    ) {
        history.append(
            HistoryEntry(
                sessionID: session.id,
                activity: session.activity,
                qualities: session.qualities,
                intensity: session.intensity,
                course: session.course,
                date: endedAt ?? startedAt,
                outcome: outcome
            )
        )
        affinity[session.id] = Affinity.updated(affinity[session.id] ?? 0, after: outcome)
        log.record(
            session,
            outcome: outcome,
            startedAt: startedAt,
            endedAt: endedAt,
            dayStart: calendar.startOfDay(for: now)
        )
    }

    func canSwap(_ item: MenuItem, now: Date = Date()) -> Bool {
        engine.alternative(for: item, onMenu: menu, input: input(now: now), alreadySeen: swappedAway) != nil
    }

    func term(for step: Step) -> ExerciseTerm? {
        store.term(id: step.glossaryID)
    }

    /// Everything that can be offered — the catalogue and somebody's own kept
    /// workouts alike. What the Library browses is exactly what the engine
    /// picks from; there is no second, smaller world.
    var everything: [Session] {
        (store.sessions + ownSessions).sorted { $0.title < $1.title }
    }

    /// A gentle reflection on the last fortnight. Never a score. See PRD §7.4.
    func lookBack(now: Date = Date()) -> LookBack {
        LookBack(history: history, affinity: affinity, calendar: calendar, now: now)
    }

    func rename(_ session: Session, to title: String) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let index = ownSessions.firstIndex(where: { $0.id == session.id }) else { return }
        ownSessions[index] = .own(
            id: session.id,
            title: trimmed,
            activity: session.activity,
            durationMin: session.durationMin,
            intensity: session.intensity
        )
        rebuildEngine()
        log.rename(session.id, to: trimmed)
    }

    /// Removing a kept workout removes it from what can be offered. It does not
    /// remove the fact that it was done.
    func forget(_ session: Session, now: Date = Date()) {
        ownSessions.removeAll { $0.id == session.id }
        rebuildEngine()
        log.forget(session.id)
        // Today's menu may have been built on it, so the day is rebuilt rather
        // than left pointing at something that no longer exists.
        if menu.items.contains(where: { $0.session.id == session.id }) {
            menu = engine.makeMenu(input(now: now))
            persist(now: now)
        }
    }

    private func rebuildEngine() {
        engine = PlanEngine(catalog: store.sessions + ownSessions)
    }

    /// "Thursday morning" — a place in the week, never a count of days.
    func greeting(now: Date = Date()) -> String {
        let weekday = now.formatted(.dateTime.weekday(.wide))
        let part = switch calendar.component(.hour, from: now) {
        case ..<11: "morning"
        case ..<16: "afternoon"
        default: "evening"
        }
        return "\(weekday) \(part)"
    }
}

extension Menu {
    /// Swaps one item for another in place, keeping the rest of the menu as it
    /// was — the card exchanges, the screen does not rebuild.
    func replacing(_ item: MenuItem, with replacement: MenuItem) -> Menu {
        Menu(
            dayStart: dayStart,
            appetizer: appetizer?.id == item.id ? replacement : appetizer,
            main: main?.id == item.id ? replacement : main,
            sides: sides.map { $0.id == item.id ? replacement : $0 },
            dessert: dessert?.id == item.id ? replacement : dessert,
            special: special?.id == item.id ? replacement : special,
            headline: headline,
            assumedCheckIn: assumedCheckIn
        )
    }
}
