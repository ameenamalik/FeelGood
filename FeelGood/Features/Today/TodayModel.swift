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
    private let engine: PlanEngine
    private let log: any SessionLogging
    private let calendar: Calendar

    var profile: PlanProfile
    private(set) var checkIn: PlanCheckIn?
    private(set) var history: [HistoryEntry]
    private(set) var menu: Menu
    /// Sessions already turned down today, so a swap never circles back.
    private(set) var swappedAway: Set<String> = []

    /// Sessions finished today, so a completed item reads as done rather than
    /// as something still waiting. Not a score and not a count — just a mark.
    private(set) var completedToday: Set<String> = []

    init(
        store: any ContentProviding,
        profile: PlanProfile,
        log: any SessionLogging = InMemorySessionLog(),
        checkIn: PlanCheckIn? = nil,
        now: Date,
        calendar: Calendar = .current
    ) {
        self.store = store
        self.engine = PlanEngine(catalog: store.sessions)
        self.log = log
        self.profile = profile
        self.checkIn = checkIn
        self.history = log.history(before: now)
        self.calendar = calendar
        self.menu = engine.makeMenu(
            PlanInput(
                profile: profile,
                checkIn: checkIn,
                history: log.history(before: now),
                context: PlanContext(now: now, calendar: calendar),
                affinity: log.affinity()
            )
        )
        refreshCompletedToday(now: now)
        publishSnapshot(now: now)
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
        refreshCompletedToday(now: now)
        publishSnapshot(now: now)
    }

    /// The check-in regenerates the menu in place.
    func apply(_ checkIn: PlanCheckIn, now: Date = Date()) {
        self.checkIn = checkIn
        swappedAway = []
        menu = engine.makeMenu(input(now: now))
        publishSnapshot(now: now)
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
