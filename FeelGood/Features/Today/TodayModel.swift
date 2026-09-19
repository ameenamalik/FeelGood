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
@MainActor
final class TodayModel {
    let store: any ContentProviding
    /// Rebuilt when somebody keeps a workout of their own. Not observed: the
    /// menu is what the screen watches, and this only ever produces one.
    @ObservationIgnored private var engine: PlanEngine
    private let log: any SessionLogging
    private let copy: any CopyProviding
    private let progressStore: any SessionProgressStoring
    private let calendar: Calendar
    /// Defaults to the live `PurchasesManager` singleton, but is injectable —
    /// same pattern as `CopyService`/`ChatService` — so tests can pin
    /// entitlement state instead of depending on ambient global state that a
    /// concurrently-run test elsewhere in the suite might mutate.
    private let isProUserProvider: () -> Bool
    /// Same DI pattern as `isProUserProvider` — a thin seam around
    /// `OneSignalManager.shared`, the one external call this file is allowed
    /// to make (CLAUDE.md: every external call sits behind a protocol/closure
    /// with a fake). Fed `HistoryStats.daysSinceLastCompleted`, the same
    /// already-coarsened value `CopyPayload` sends the copy Worker — one
    /// definition of "days since last", reused rather than recomputed.
    private let syncEngagementTrigger: (Int?) -> Void
    /// In flight while the copy layer upgrades the headline. Cancelled and
    /// restarted whenever the menu changes underneath it, so a slow response
    /// can never land on a headline it no longer describes.
    @ObservationIgnored private var copyTask: Task<Void, Never>?

    var profile: PlanProfile
    private(set) var checkIn: PlanCheckIn?
    /// A calendar-derived opening the person explicitly accepted. It is UI
    /// context only: the engine receives the confirmed time budget, not their
    /// calendar, and nothing here is written back to Calendar.
    private(set) var calendarOpening: CalendarOpening?
    private(set) var history: [HistoryEntry]
    private(set) var littleWins: [LittleWinProgress]
    private(set) var pendingLittleWinCelebration: LittleWinCelebration?
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

    /// Kept as observed model state as well as in the persistence store so the
    /// Today cards redraw immediately when the player is left.
    private(set) var inProgressSessionIDs: Set<String> = []

    /// Somebody's own kept workouts, scored alongside the authored catalog.
    private(set) var ownSessions: [Session]

    /// Overrides for courses on Today's menu with a user's custom choice.
    private(set) var todayCustomOverrides: [Course: Session] = [:]

    init(
        store: any ContentProviding,
        profile: PlanProfile,
        log: any SessionLogging = InMemorySessionLog(),
        copy: any CopyProviding = InMemoryCopyService(),
        progressStore: any SessionProgressStoring = UserDefaultsSessionProgressStore(),
        isProUserProvider: @escaping () -> Bool = { PurchasesManager.shared.isProUnlocked },
        syncEngagementTrigger: @escaping (Int?) -> Void = { OneSignalManager.shared.setEngagementTrigger(daysSinceLast: $0) },
        checkIn: PlanCheckIn? = nil,
        calendarOpening: CalendarOpening? = nil,
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
        self.progressStore = progressStore
        self.isProUserProvider = isProUserProvider
        self.syncEngagementTrigger = syncEngagementTrigger
        var activeProfile = profile
        activeProfile.hiddenSessionIDs.formUnion(log.hiddenSessionIDs())
        self.profile = activeProfile
        self.ownSessions = own
        self.checkIn = todaysCheckIn
        self.calendarOpening = calendarOpening
        self.history = recorded
        let initialLittleWins = LittleWins.progress(in: log.allHistory(), sessions: store.sessions + own)
        self.littleWins = initialLittleWins
        self.pendingLittleWinCelebration = nil
        self.calendar = calendar
        self.dailySwapsCount = Self.swapCount(in: recorded, on: now, calendar: calendar)
        self.inProgressSessionIDs = Set(
            (store.sessions + own)
                .filter { progressStore.progress(for: $0.id) != nil }
                .map(\.id)
        )

        // The day as it was already generated and stored. Reopening the app is
        // the same day, not a fresh guess at it.
        let sessions = Dictionary(
            (store.sessions + own).map { ($0.id, $0) },
            uniquingKeysWith: { first, _ in first }
        )
        if let stored = log.day(today, resolving: { sessions[$0] }) {
            self.menu = stored
        } else {
            // Same `.full` / `.recencyOnly` gate as `input(now:)` below — this
            // is the app's very first menu, generated before `self` exists to
            // call that method on, so it stayed on the old unwrapped
            // initializer and every cold start got Pro's memory for free.
            let memory: PlanMemory = isProUserProvider()
                ? .full(history: recorded, affinity: log.affinity())
                : .recencyOnly(lastActiveDate: recorded.filter(\.wasCompleted).map(\.date).max())
            let generated = engine.makeMenu(
                PlanInput(
                    profile: profile,
                    checkIn: todaysCheckIn,
                    memory: memory,
                    context: PlanContext(now: now, calendar: calendar),
                    banditState: isProUserProvider() ? log.banditState() : nil
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

    private(set) var dailySwapsCount: Int = 0
    var isProUser: Bool { isProUserProvider() }
    var hasRemainingSwaps: Bool { isProUser || dailySwapsCount < 1 }
    var completedSessionCount: Int { history.filter(\.wasCompleted).count }
    var hasCustomRoutine: Bool { !ownSessions.isEmpty }

    private func input(now: Date) -> PlanInput {
        let memory: PlanMemory = isProUser
            ? .full(history: history, affinity: log.affinity())
            : .recencyOnly(lastActiveDate: history.filter(\.wasCompleted).map(\.date).max())

        return PlanInput(
            profile: profile,
            checkIn: checkIn,
            memory: memory,
            context: PlanContext(now: now, calendar: calendar),
            banditState: isProUser ? log.banditState() : nil
        )
    }

    var banditCoarsenedPreferences: BanditCoarsenedPreferences {
        guard let state = log.banditState() else { return BanditCoarsenedPreferences() }
        return BanditEngine.coarsenedPreferences(from: state)
    }

    /// Rebuilds against whatever the store now holds. Used when history
    /// changes underneath the screen rather than because of it.
    func reload(now: Date = Date()) {
        history = log.history(before: now)
        littleWins = LittleWins.progress(in: log.allHistory(), sessions: everything)
        dailySwapsCount = Self.swapCount(in: history, on: now, calendar: calendar)
        swappedAway = []
        menu = engine.makeMenu(input(now: now))
        log.save(menu, generatedAt: now)
        refreshCompletedToday(now: now)
        publishSnapshot(now: now)
        requestCopyUpgrade(now: now)
    }

    /// The check-in regenerates the menu in place.
    func apply(
        _ checkIn: PlanCheckIn,
        calendarOpening: CalendarOpening? = nil,
        now: Date = Date()
    ) {
        self.checkIn = checkIn
        self.calendarOpening = calendarOpening
        swappedAway = []
        menu = engine.makeMenu(input(now: now))
        log.record(checkIn, at: now, dayStart: calendar.startOfDay(for: now))
        log.save(menu, generatedAt: now)
        publishSnapshot(now: now)
        requestCopyUpgrade(now: now)
    }

    /// Applies structured conversational check-in and overrides.
    func applyConversationalCheckIn(_ response: ChatResponse, now: Date = Date()) {
        let newCheckIn = response.overrides.toPlanCheckIn(fallback: checkIn ?? menu.assumedCheckIn)
        apply(newCheckIn, now: now)
        if !response.message.isEmpty {
            upgradedHeadline = response.message
        }
    }

    /// Explicitly pins or places a chosen session onto today's menu (e.g. from chat exploration).
    func commitSessionToToday(_ session: Session, now: Date = Date()) {
        let item = MenuItem(
            session: session,
            course: session.course,
            reasons: [.matchesIntent],
            reasonText: "Chosen in conversation with you"
        )

        switch session.course {
        case .main:
            if let existingMain = menu.main {
                menu = menu.replacing(existingMain, with: item)
            } else {
                menu = Menu(
                    dayStart: menu.dayStart,
                    appetizer: menu.appetizer,
                    main: item,
                    sides: menu.sides,
                    dessert: menu.dessert,
                    special: menu.special,
                    headline: menu.headline,
                    assumedCheckIn: menu.assumedCheckIn
                )
            }
        case .appetizer:
            if let existingApp = menu.appetizer {
                menu = menu.replacing(existingApp, with: item)
            } else {
                menu = Menu(
                    dayStart: menu.dayStart,
                    appetizer: item,
                    main: menu.main,
                    sides: menu.sides,
                    dessert: menu.dessert,
                    special: menu.special,
                    headline: menu.headline,
                    assumedCheckIn: menu.assumedCheckIn
                )
            }
        case .side:
            if let firstSide = menu.sides.first {
                menu = menu.replacing(firstSide, with: item)
            } else {
                menu = Menu(
                    dayStart: menu.dayStart,
                    appetizer: menu.appetizer,
                    main: menu.main,
                    sides: [item],
                    dessert: menu.dessert,
                    special: menu.special,
                    headline: menu.headline,
                    assumedCheckIn: menu.assumedCheckIn
                )
            }
        case .dessert:
            if let existingDessert = menu.dessert {
                menu = menu.replacing(existingDessert, with: item)
            } else {
                menu = Menu(
                    dayStart: menu.dayStart,
                    appetizer: menu.appetizer,
                    main: menu.main,
                    sides: menu.sides,
                    dessert: item,
                    special: menu.special,
                    headline: menu.headline,
                    assumedCheckIn: menu.assumedCheckIn
                )
            }
        case .special:
            if let existingSpecial = menu.special {
                menu = menu.replacing(existingSpecial, with: item)
            } else {
                menu = Menu(
                    dayStart: menu.dayStart,
                    appetizer: menu.appetizer,
                    main: menu.main,
                    sides: menu.sides,
                    dessert: menu.dessert,
                    special: item,
                    headline: menu.headline,
                    assumedCheckIn: menu.assumedCheckIn
                )
            }
        }

        log.save(menu, generatedAt: now)
        publishSnapshot(now: now)
    }

    /// Quick-pivot constraint chips (PRD §10.1 Category 2: Change the plan in seconds).
    func applyQuickFilter(_ filter: QuickFilter, now: Date = Date()) {
        var newCheckIn = checkIn ?? menu.assumedCheckIn
        switch filter {
        case .shorter:
            newCheckIn.time = .fiveMinutes
        case .gentler:
            newCheckIn.energy = .low
            if newCheckIn.body == nil { newCheckIn.body = .stiff }
        case .moreEnergizing:
            newCheckIn.energy = .strong
        case .canNotLeave:
            newCheckIn.place = .stayingIn
        }
        apply(newCheckIn, now: now)
    }

    /// "Shuffle". A swap is engagement, not rejection — it is a choice being made,
    /// which is the whole point of the screen.
    func swap(_ item: MenuItem, now: Date = Date()) {
        guard hasRemainingSwaps else { return }
        dailySwapsCount += 1

        let currentInput = input(now: now)
        if let replacement = engine.alternative(
            for: item,
            onMenu: menu,
            input: currentInput,
            alreadySeen: swappedAway
        ) {
            swappedAway.insert(item.session.id)
            log.recordSwap(of: item.session, at: now)
            history = log.history(before: now)
            menu = menu.replacing(item, with: replacement)
            // The card you exchanged stays exchanged when you come back to it.
            log.save(menu, generatedAt: now)
            publishSnapshot(now: now)
        } else if let cycleReplacement = engine.cyclicAlternative(
            for: item,
            onMenu: menu,
            input: currentInput
        ) {
            // Reached the end of unseen candidates — reset seen items and cycle back.
            swappedAway.removeAll()
            swappedAway.insert(item.session.id)
            log.recordSwap(of: item.session, at: now)
            history = log.history(before: now)
            menu = menu.replacing(item, with: cycleReplacement)
            log.save(menu, generatedAt: now)
            publishSnapshot(now: now)
        }
    }

    /// Finished. The menu deliberately does not regenerate — the day stays as
    /// it was, and what happened counts toward tomorrow.
    func complete(
        _ session: Session,
        startedAt: Date,
        feel: Feel?,
        place: Place? = nil,
        now: Date = Date()
    ) {
        let unlockedBefore = Set(littleWins.filter(\.isUnlocked).map(\.win))
        let completedPlace = place ?? inferredCompletionPlace(for: session)
        progressStore.clearProgress(for: session.id)
        inProgressSessionIDs.remove(session.id)
        log.recordCompletion(
            of: session,
            startedAt: startedAt,
            endedAt: now,
            feel: feel,
            place: completedPlace
        )
        history = log.history(before: now)
        littleWins = LittleWins.progress(in: log.allHistory(), sessions: everything)
        let newWins = littleWins.filter {
            $0.isUnlocked && !unlockedBefore.contains($0.win)
        }
        if !newWins.isEmpty {
            pendingLittleWinCelebration = LittleWinCelebration(wins: newWins)
        }
        refreshCompletedToday(now: now)
        publishSnapshot(now: now)

        if let userId = AuthService.shared.currentUser?.uid {
            Task {
                try? await FirestoreService.shared.recordCompletion(
                    userId: userId,
                    sessionTitle: session.title,
                    sessionID: session.id,
                    startedAt: startedAt,
                    endedAt: now,
                    durationMin: session.durationMin,
                    activity: session.activity.rawValue,
                    qualities: session.qualities.map(\.rawValue),
                    intensity: session.intensity,
                    course: session.course.rawValue,
                    place: completedPlace?.rawValue,
                    feel: feel?.rawValue
                )
            }
        }
    }

    func takePendingLittleWinCelebration() -> LittleWinCelebration? {
        defer { pendingLittleWinCelebration = nil }
        return pendingLittleWinCelebration
    }

    private func inferredCompletionPlace(for session: Session) -> Place? {
        switch checkIn?.place {
        case .stayingIn: return .home
        case .atTheGym: return .gym
        case .happyToGoOut:
            let awayPlaces = session.places.filter { $0 != .home }
            return awayPlaces.count == 1 ? awayPlaces[0] : nil
        case nil:
            return nil
        }
    }

    /// Leaving the player is a pause, not a workout outcome. It changes no
    /// history or affinity and exists only so the next tap can continue.
    func pause(_ session: Session, at progress: SessionProgress) {
        progressStore.save(progress, for: session.id)
        inProgressSessionIDs.insert(session.id)
    }

    func progress(for session: Session) -> SessionProgress? {
        progressStore.progress(for: session.id)
    }

    func isInProgress(_ item: MenuItem) -> Bool {
        inProgressSessionIDs.contains(item.session.id) && !isCompleted(item)
    }

    // MARK: Hidden exercises ("Don't suggest this again")

    /// Permanently hides a session so it is never recommended by the engine.
    /// If it is currently on Today's menu, it is immediately swapped out.
    func hide(_ session: Session, now: Date = Date()) {
        progressStore.clearProgress(for: session.id)
        inProgressSessionIDs.remove(session.id)
        profile.hiddenSessionIDs.insert(session.id)
        log.hideSession(session.id, at: now)

        if let item = menu.items.first(where: { $0.session.id == session.id }) {
            let currentInput = input(now: now)
            if let replacement = engine.alternative(
                for: item,
                onMenu: menu,
                input: currentInput,
                alreadySeen: swappedAway.union([session.id])
            ) ?? engine.cyclicAlternative(
                for: item,
                onMenu: menu,
                input: currentInput
            ) {
                swappedAway.insert(item.session.id)
                menu = menu.replacing(item, with: replacement)
                log.save(menu, generatedAt: now)
                publishSnapshot(now: now)
            }
        }
    }

    /// Restores a previously hidden session so it can be recommended again.
    func unhide(sessionID: String, now: Date = Date()) {
        profile.hiddenSessionIDs.remove(sessionID)
        log.unhideSession(sessionID, at: now)
    }

    func isHidden(_ sessionID: String) -> Bool {
        profile.hiddenSessionIDs.contains(sessionID)
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
        complete(session, startedAt: now, feel: nil, place: workout.place, now: now)
    }

    /// A calendar title can suggest that movement was planned, but only this
    /// explicit confirmation turns it into history. The original title is
    /// never available here and therefore cannot be persisted or uploaded.
    func log(_ plan: CalendarMovementPlan, now: Date = Date()) {
        let endedAt = min(plan.end, now)
        guard plan.start < endedAt else { return }

        let duration = min(max(plan.durationMinutes, 5), 180)
        let title = LoggedWorkout.defaultTitle(for: plan.activity, durationMin: duration)
        let session = Session.own(
            id: "calendar-\(UUID().uuidString)",
            title: title,
            activity: plan.activity,
            durationMin: duration,
            intensity: 3
        )
        complete(session, startedAt: plan.start, feel: nil, now: endedAt)
        CalendarMovementPreferences.markHandled(plan.id)
    }

    func rename(_ session: Session, to title: String) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, ownSessions.contains(where: { $0.id == session.id }) else { return }
        log.rename(session.id, to: trimmed)
        ownSessions = log.kept()
        rebuildEngine()
    }

    /// Changes a kept routine without replacing its identity or losing its history.
    @discardableResult
    func updateCustomRoutine(
        _ session: Session,
        title: String,
        description: String?,
        parts: [CustomRoutinePart],
        activity: Activity,
        durationMin: Int,
        intensity: Int,
        course: Course,
        addToToday: Bool,
        now: Date = Date()
    ) -> Session? {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty,
              ownSessions.contains(where: { $0.id == session.id }) else { return nil }
        let trimmedDescription = description?.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalDescription = trimmedDescription.flatMap { $0.isEmpty ? nil : $0 }
        let oldCourse = session.course

        guard let updated = log.update(
            session.id,
            title: trimmedTitle,
            description: finalDescription,
            parts: parts,
            activity: activity,
            durationMin: durationMin,
            intensity: intensity,
            course: course
        ) else { return nil }

        ownSessions = log.kept()
        rebuildEngine()

        let overrideCourse = todayCustomOverrides.first { $0.value.id == session.id }?.key
        let appearsOnMenu = menu.items.contains { $0.session.id == session.id }

        if let overrideCourse {
            todayCustomOverrides.removeValue(forKey: overrideCourse)
            if addToToday {
                todayCustomOverrides[course] = updated
            }
        } else if addToToday {
            todayCustomOverrides[course] = updated
        }

        let needsMenuRebuild = oldCourse != course || (overrideCourse != nil && !addToToday)
        if !needsMenuRebuild, appearsOnMenu || overrideCourse != nil || addToToday {
            menu = menu.replacing(course: course, with: updated)
            log.save(menu, generatedAt: now)
            publishSnapshot(now: now)
        } else if appearsOnMenu || overrideCourse != nil || addToToday {
            menu = engine.makeMenu(input(now: now))
            for (overrideCourse, overrideSession) in todayCustomOverrides {
                menu = menu.replacing(course: overrideCourse, with: overrideSession)
            }
            log.save(menu, generatedAt: now)
            publishSnapshot(now: now)
            requestCopyUpgrade(now: now)
        }

        if let userId = AuthService.shared.currentUser?.uid {
            Task {
                try? await FirestoreService.shared.saveCustomWorkout(
                    id: updated.id,
                    userId: userId,
                    title: updated.title,
                    description: finalDescription,
                    parts: parts.map(FirestoreCustomRoutinePart.init),
                    durationMin: updated.durationMin,
                    intensity: updated.intensity,
                    course: updated.course.rawValue,
                    activity: updated.activity.rawValue
                )
            }
        }

        return updated
    }

    /// Removing a kept workout removes it from what can be offered. It does not
    /// remove the fact that it was done.
    func forget(_ session: Session, now: Date = Date()) {
        progressStore.clearProgress(for: session.id)
        inProgressSessionIDs.remove(session.id)
        log.forget(session.id)
        ownSessions = log.kept()
        todayCustomOverrides = todayCustomOverrides.filter { $0.value.id != session.id }
        rebuildEngine()
        // Today's menu may have been built on it, so the day is rebuilt rather
        // than left pointing at something that no longer exists.
        if menu.items.contains(where: { $0.session.id == session.id }) {
            menu = engine.makeMenu(input(now: now))
            log.save(menu, generatedAt: now)
            publishSnapshot(now: now)
            requestCopyUpgrade(now: now)
        }

        if let userId = AuthService.shared.currentUser?.uid {
            Task {
                try? await FirestoreService.shared.deleteCustomWorkout(userId: userId, workoutId: session.id)
            }
        }
    }

    /// Adds a new custom routine created by the user, keeps it in persistence,
    /// and optionally sets it as an active override on Today's menu.
    @discardableResult
    func addCustomRoutine(
        title: String,
        description: String? = nil,
        parts: [CustomRoutinePart] = [],
        activity: Activity = .stretching,
        durationMin: Int,
        intensity: Int = 3,
        course: Course,
        addToToday: Bool,
        now: Date = Date()
    ) -> Session {
        let session = log.keep(
            title: title,
            description: description,
            parts: parts,
            activity: activity,
            durationMin: durationMin,
            intensity: intensity,
            course: course,
            now: now
        )
        ownSessions = log.kept()
        rebuildEngine()

        if addToToday {
            setTodayCourseOverride(session: session, for: course, now: now)
        }

        if let userId = AuthService.shared.currentUser?.uid {
            Task {
                try? await FirestoreService.shared.saveCustomWorkout(
                    id: session.id,
                    userId: userId,
                    title: title,
                    description: description,
                    parts: parts.map(FirestoreCustomRoutinePart.init),
                    durationMin: durationMin,
                    intensity: intensity,
                    course: course.rawValue,
                    activity: activity.rawValue
                )
            }
        }

        return session
    }

    /// Sets a session as the explicit override for a course slot on Today's menu.
    func setTodayCourseOverride(session: Session, for course: Course, now: Date = Date()) {
        todayCustomOverrides[course] = session
        menu = menu.replacing(course: course, with: session)
        log.save(menu, generatedAt: now)
        publishSnapshot(now: now)
    }

    /// Removes a custom override for a course slot on Today's menu, restoring the engine's suggested pick.
    func removeTodayCourseOverride(for course: Course, now: Date = Date()) {
        todayCustomOverrides.removeValue(forKey: course)
        let freshMenu = engine.makeMenu(input(now: now))
        if let originalItem = freshMenu.items.first(where: { $0.course == course }) {
            menu = menu.replacing(course: course, withItem: originalItem)
        }
        log.save(menu, generatedAt: now)
        publishSnapshot(now: now)
    }

    /// Checks whether a course slot on Today's menu is currently overridden with a custom routine.
    func isCourseOverridden(_ course: Course) -> Bool {
        todayCustomOverrides[course] != nil
    }

    /// Fetches all custom routines created by the user for a given course (or all if nil).
    func customRoutines(for course: Course? = nil) -> [Session] {
        if let course {
            return ownSessions.filter { $0.course == course }
        }
        return ownSessions
    }

    /// Syncs any custom routines stored in Firestore into local persistence
    func syncFromFirestore() {
        guard AuthService.shared.currentUser != nil else { return }
        let remote = FirestoreService.shared.customWorkouts
        guard !remote.isEmpty else { return }

        var didImport = false
        for workout in remote {
            if !ownSessions.contains(where: { $0.id == workout.id || $0.title == workout.title }) {
                let act = workout.activity.flatMap(Activity.init(rawValue:)) ?? .yoga
                let course = workout.course.flatMap(Course.init(rawValue:))
                log.keep(
                    title: workout.title,
                    description: workout.description,
                    parts: workout.parts?.map(\.customRoutinePart) ?? [],
                    activity: act,
                    durationMin: workout.durationMin,
                    intensity: workout.intensity,
                    course: course,
                    now: workout.createdAt
                )
                didImport = true
            }
        }
        if didImport {
            ownSessions = log.kept()
            rebuildEngine()
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

    private static func swapCount(
        in history: [HistoryEntry],
        on date: Date,
        calendar: Calendar
    ) -> Int {
        history.count { entry in
            guard calendar.isDate(entry.date, inSameDayAs: date) else { return false }
            if case .swappedAway = entry.outcome { return true }
            return false
        }
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
        syncEngagementTrigger(stats.daysSinceLastCompleted)
        let copy = copy

        copyTask = Task { @MainActor [weak self] in
            guard let line = await copy.upgradedHeadline(menu: requestedMenu, checkIn: requestedCheckIn, stats: stats) else { return }
            guard let self, !Task.isCancelled else { return }
            // Only lands if the menu/check-in this was asked about are still
            // current — guards a swap or a second check-in landing first.
            guard self.menu == requestedMenu, (self.checkIn ?? self.menu.assumedCheckIn) == requestedCheckIn else { return }
            self.upgradedHeadline = line
        }
    }

    /// The home screen's copy of today's menu.
    ///
    /// Flattened on the way out — the widget gets strings and a colour, never
    /// the model — and re-published on every change, because a widget offering
    /// a session you already finished is worse than one offering nothing.
    private func publishSnapshot(now: Date) {
        guard !menu.items.isEmpty else { return }

        SharedContainer.writeSnapshot(TodaySnapshot(
            day: calendar.startOfDay(for: now),
            items: menu.items.map { item in
                TodayItem(
                    sessionID: item.session.id,
                    courseLabel: item.course.label,
                    accentHex: item.course.accentHex,
                    title: item.session.title,
                    reason: item.reasonText,
                    durationLabel: item.session.durationLabel,
                    isDone: completedToday.contains(item.session.id)
                )
            }
        ))
        WidgetCenter.shared.reloadAllTimelines()
    }

    func isCompleted(_ item: MenuItem) -> Bool {
        completedToday.contains(item.session.id)
    }

    func completedEntriesToday(now: Date = Date()) -> [HistoryEntry] {
        let today = calendar.startOfDay(for: now)
        return history
            .filter { $0.wasCompleted && calendar.startOfDay(for: $0.date) == today }
            .sorted { $0.date > $1.date }
    }

    var completedEntriesToday: [HistoryEntry] {
        completedEntriesToday()
    }

    var hasCompletedActivityToday: Bool {
        !completedEntriesToday.isEmpty
    }

    func hasCompletedSomethingElseToday(now: Date = Date()) -> Bool {
        completedEntriesToday(now: now).contains { entry in
            if let session = everything.first(where: { $0.id == entry.sessionID }) {
                return session.isOwn
            }
            return !menu.items.contains(where: { $0.session.id == entry.sessionID })
        }
    }

    var hasCompletedSomethingElseToday: Bool {
        hasCompletedSomethingElseToday()
    }

    var isMenuCompletedToday: Bool {
        !menu.items.isEmpty && menu.items.allSatisfy { isCompleted($0) }
    }

    var shouldShowCompletionState: Bool {
        false
    }

    var remainingDurationMin: Int {
        menu.items
            .filter { !isCompleted($0) }
            .reduce(0) { $0 + $1.session.durationMin }
    }

    func title(for entry: HistoryEntry) -> String {
        if let session = everything.first(where: { $0.id == entry.sessionID }) {
            return session.title
        }
        return entry.activity.label
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
        let currentInput = input(now: now)
        return engine.alternative(for: item, onMenu: menu, input: currentInput, alreadySeen: swappedAway) != nil
            || engine.cyclicAlternative(for: item, onMenu: menu, input: currentInput) != nil
    }

    /// True if all unseen alternatives for this item have been exhausted, meaning
    /// the next swap action will cycle back to the top alternative.
    func isCycleReset(_ item: MenuItem, now: Date = Date()) -> Bool {
        let currentInput = input(now: now)
        let hasUnseen = engine.alternative(for: item, onMenu: menu, input: currentInput, alreadySeen: swappedAway) != nil
        if hasUnseen { return false }
        return engine.cyclicAlternative(for: item, onMenu: menu, input: currentInput) != nil
    }

    /// Authored steps carry their own `glossaryID`. A custom step typed by
    /// somebody has none, so it gets the same title match `PlayerView` uses
    /// to pick its visual — same matcher, so the "what's this?" sheet and
    /// the drawing on screen always agree.
    func term(for step: Step) -> ExerciseTerm? {
        if let id = step.glossaryID {
            return store.term(id: id)
        }
        return store.term(id: CustomStepMatcher.glossaryID(for: step.name, in: store.glossary))
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
