//
//  TodayModel.swift
//  FeelGood
//
//  Holds today's menu and the two things that can change it: the check-in and
//  a swap. All the deciding happens in the engine; this only carries state.
//

import Foundation
import Observation
import WidgetKit

@Observable
final class TodayModel {
    let store: any ContentProviding
    /// Rebuilt when somebody keeps a workout of their own. Not observed: the
    /// menu is what the screen watches, and this only ever produces one.
    @ObservationIgnored private var engine: PlanEngine
    private let log: any SessionLogging
    private let copy: any CopyProviding
    private let calendar: Calendar
    /// In flight while the copy layer upgrades the headline. Cancelled and
    /// restarted whenever the menu changes underneath it, so a slow response
    /// can never land on a headline it no longer describes.
    @ObservationIgnored private var copyTask: Task<Void, Never>?

    var profile: PlanProfile
    private(set) var checkIn: PlanCheckIn?
    private(set) var history: [HistoryEntry]
    private(set) var menu: Menu
    /// `Menu.headline` upgraded by the copy layer, PRD §7.3 — a sibling
    /// property rather than a mutation of `menu.headline` in place, because
    /// `menu` is what gets persisted verbatim: overwriting `headline` there
    /// would either be lost on next launch or force a re-save on every
    /// response. `nil` until (and unless) a warmer line comes back; the view
    /// always has the deterministic one to fall back to.
    private(set) var upgradedHeadline: String?
    /// Sessions already turned down today, so a swap never circles back.
    private(set) var swappedAway: Set<String> = []

    /// Sessions finished today, so a completed item reads as done rather than
    /// as something still waiting. Not a score and not a count — just a mark.
    private(set) var completedToday: Set<String> = []

    /// Somebody's own kept workouts, scored alongside the authored catalog.
    private(set) var ownSessions: [Session]

    init(
        store: any ContentProviding,
        profile: PlanProfile,
        log: any SessionLogging = InMemorySessionLog(),
        copy: any CopyProviding = InMemoryCopyService(),
        checkIn: PlanCheckIn? = nil,
        now: Date,
        calendar: Calendar = .current
    ) {
        let own = log.kept()
        let engine = PlanEngine(catalog: store.sessions + own)
        let today = calendar.startOfDay(for: now)

        // Answers already given today are answers, not a question to ask again.
        let todaysCheckIn = checkIn ?? log.checkIn(on: today)
        let recorded = log.history(before: now)

        self.store = store
        self.engine = engine
        self.log = log
        self.copy = copy
        self.profile = profile
        self.ownSessions = own
        self.checkIn = todaysCheckIn
        self.history = recorded
        self.calendar = calendar

        // The day as it was already generated and stored. Reopening the app is
        // the same day, not a fresh guess at it.
        let sessions = Dictionary(
            (store.sessions + own).map { ($0.id, $0) },
            uniquingKeysWith: { first, _ in first }
        )
        if let stored = log.day(today, resolving: { sessions[$0] }) {
            self.menu = stored
        } else {
            let generated = engine.makeMenu(
                PlanInput(
                    profile: profile,
                    checkIn: todaysCheckIn,
                    history: recorded,
                    context: PlanContext(now: now, calendar: calendar),
                    affinity: log.affinity()
                )
            )
            self.menu = generated
            log.save(generated, generatedAt: now)
        }
        refreshCompletedToday(now: now)
        publishSnapshot(now: now)
        requestCopyUpgrade(now: now)
    }

    /// PRD §7.4. The engine reads the same history to plan; this reads it to
    /// reflect. Both are pure, and both get `now` handed to them.
    func lookBack(now: Date) -> Reflection {
        // Reads the tracked `history` rather than re-querying the log, so the
        // tab redraws when a session is finished.
        LookBack.reflect(
            history: history,
            context: PlanContext(now: now, calendar: calendar)
        )
    }

    private func input(now: Date) -> PlanInput {
        PlanInput(
            profile: profile,
            checkIn: checkIn,
            history: history,
            context: PlanContext(now: now, calendar: calendar),
            affinity: log.affinity()
        )
    }

    /// Rebuilds against whatever the store now holds. Used when history
    /// changes underneath the screen rather than because of it.
    func reload(now: Date = Date()) {
        history = log.history(before: now)
        swappedAway = []
        menu = engine.makeMenu(input(now: now))
        log.save(menu, generatedAt: now)
        refreshCompletedToday(now: now)
        publishSnapshot(now: now)
        requestCopyUpgrade(now: now)
    }

    /// The check-in regenerates the menu in place.
    func apply(_ checkIn: PlanCheckIn, now: Date = Date()) {
        self.checkIn = checkIn
        swappedAway = []
        menu = engine.makeMenu(input(now: now))
        log.record(checkIn, at: now, dayStart: calendar.startOfDay(for: now))
        log.save(menu, generatedAt: now)
        publishSnapshot(now: now)
        requestCopyUpgrade(now: now)
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
        log.recordSwap(of: item.session, at: now)
        history = log.history(before: now)
        menu = menu.replacing(item, with: replacement)
        // The card you exchanged stays exchanged when you come back to it.
        log.save(menu, generatedAt: now)
        publishSnapshot(now: now)
    }

    /// Finished. The menu deliberately does not regenerate — the day stays as
    /// it was, and what happened counts toward tomorrow.
    func complete(_ session: Session, startedAt: Date, feel: Feel?, now: Date = Date()) {
        log.recordCompletion(of: session, startedAt: startedAt, endedAt: now, feel: feel)
        history = log.history(before: now)
        refreshCompletedToday(now: now)
        publishSnapshot(now: now)
    }

    // MARK: Somebody's own movement

    /// Everything that can be offered — the catalogue and somebody's own kept
    /// workouts alike. What the Library browses is exactly what the engine
    /// picks from; there is no second, smaller world.
    var everything: [Session] {
        (store.sessions + ownSessions).sorted { $0.title < $1.title }
    }

    /// Something done that was never on the menu. Kept workouts join the pool
    /// the engine picks from, so they can come back on a later menu.
    func log(_ workout: LoggedWorkout, now: Date = Date()) {
        let session: Session = workout.isKept
            ? log.keep(
                title: workout.title,
                activity: workout.activity,
                durationMin: workout.durationMin,
                intensity: workout.intensity,
                now: now
            )
            : .own(
                id: "own-\(UUID().uuidString)",
                title: workout.title,
                activity: workout.activity,
                durationMin: workout.durationMin,
                intensity: workout.intensity
            )

        if workout.isKept {
            ownSessions = log.kept()
            rebuildEngine()
        }
        complete(session, startedAt: now, feel: nil, now: now)
    }

    func rename(_ session: Session, to title: String) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, ownSessions.contains(where: { $0.id == session.id }) else { return }
        log.rename(session.id, to: trimmed)
        ownSessions = log.kept()
        rebuildEngine()
    }

    /// Removing a kept workout removes it from what can be offered. It does not
    /// remove the fact that it was done.
    func forget(_ session: Session, now: Date = Date()) {
        log.forget(session.id)
        ownSessions = log.kept()
        rebuildEngine()
        // Today's menu may have been built on it, so the day is rebuilt rather
        // than left pointing at something that no longer exists.
        if menu.items.contains(where: { $0.session.id == session.id }) {
            menu = engine.makeMenu(input(now: now))
            log.save(menu, generatedAt: now)
            publishSnapshot(now: now)
            requestCopyUpgrade(now: now)
        }
    }

    /// The profile changed on the profile screen. The menu follows the same
    /// day, keeping today's check-in — changing your mind is not a reset.
    func update(profile: PlanProfile, now: Date = Date()) {
        self.profile = profile
        swappedAway = []
        menu = engine.makeMenu(input(now: now))
        log.save(menu, generatedAt: now)
        publishSnapshot(now: now)
        requestCopyUpgrade(now: now)
    }

    private func rebuildEngine() {
        engine = PlanEngine(catalog: store.sessions + ownSessions)
    }

    /// Asks the copy layer to upgrade `menu.headline` in place. Not called
    /// from `swap(_:)` — the headline depends on `reasons`/`checkIn`, not on
    /// which specific items are on the menu, so a swap shouldn't re-bill a
    /// call for a line that wouldn't actually change.
    private func requestCopyUpgrade(now: Date) {
        copyTask?.cancel()
        // Clears immediately rather than waiting for the new response, so a
        // stale line never lingers on screen through a menu change.
        upgradedHeadline = nil

        let requestedMenu = menu
        let requestedCheckIn = checkIn ?? menu.assumedCheckIn
        let stats = HistoryStats(input: input(now: now))
        let copy = copy

        copyTask = Task { [weak self] in
            guard let line = await copy.upgradedHeadline(menu: requestedMenu, checkIn: requestedCheckIn, stats: stats) else { return }
            guard let self, !Task.isCancelled else { return }
            // Only lands if the menu/check-in this was asked about are still
            // current — guards a swap or a second check-in landing first.
            guard self.menu == requestedMenu, (self.checkIn ?? self.menu.assumedCheckIn) == requestedCheckIn else { return }
            self.upgradedHeadline = line
        }
    }

    /// The home screen's copy of today's Main.
    ///
    /// Flattened on the way out — the widget gets strings and a colour, never
    /// the model — and re-published on every change, because a widget offering
    /// a session you already finished is worse than one offering nothing.
    private func publishSnapshot(now: Date) {
        guard let main = menu.items.first(where: { $0.course == .main }) ?? menu.items.first
        else { return }

        SharedContainer.writeSnapshot(TodaySnapshot(
            day: calendar.startOfDay(for: now),
            sessionID: main.session.id,
            courseLabel: main.course.label,
            accentHex: main.course.accentHex,
            title: main.session.title,
            reason: main.reasonText,
            durationLabel: main.session.durationLabel,
            isDone: completedToday.contains(main.session.id)
        ))
        WidgetCenter.shared.reloadAllTimelines()
    }

    func isCompleted(_ item: MenuItem) -> Bool {
        completedToday.contains(item.session.id)
    }

    private func refreshCompletedToday(now: Date) {
        let today = calendar.startOfDay(for: now)
        completedToday = Set(
            history
                .filter { $0.wasCompleted && calendar.startOfDay(for: $0.date) == today }
                .map(\.sessionID)
        )
    }

    func canSwap(_ item: MenuItem, now: Date = Date()) -> Bool {
        engine.alternative(for: item, onMenu: menu, input: input(now: now), alreadySeen: swappedAway) != nil
    }

    func term(for step: Step) -> ExerciseTerm? {
        store.term(id: step.glossaryID)
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
