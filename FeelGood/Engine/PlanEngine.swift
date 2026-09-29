//
//  PlanEngine.swift
//  FeelGood
//
//  The rules engine picks; the language model only writes the framing.
//  This type is a pure function of (profile, check-in, history, context) → Menu.
//  No I/O, no networking, no SwiftData, no reads of the system clock — which is
//  what makes it exhaustively testable and impossible to break in a demo.
//  See PRD §7.3.
//

import Foundation

/// Scoring weights, extracted so they can be tuned and asserted on in tests.
nonisolated struct PlanWeights: Hashable, Sendable {
    var energyMatch: Double = 3.0
    var energyMismatch: Double = -1.5
    /// Applied per intensity point above `restfulIntensity` on a low-energy day.
    var highIntensityOnLowEnergy: Double = -1.6
    var timeFit: Double = 2.0
    var intentMatch: Double = 2.0
    /// What was said *today* (e.g. through the chat check-in) outranks a
    /// standing profile intent, so the plan visibly follows what was just
    /// asked for rather than a months-old onboarding answer.
    var todayIntentMatch: Double = 3.5
    /// The body area asked for in today's check-in.
    var focusMatch: Double = 2.0
    /// One of the activities today's check-in answer leans toward.
    var favouredActivityMatch: Double = 1.5
    var affinity: Double = 2.5
    /// New movers get a calm first menu without being locked out of anything.
    var gettingStartedGentleMatch: Double = 2.0
    var gettingStartedIntensityPenalty: Double = -0.8
    /// People who know their preferences should see those choices lead.
    var preferredActivityMatch: Double = 1.5
    /// A person's own routine leads when FeelGood is acting as a companion.
    var ownRoutineMatch: Double = 4.0
    /// Per prior day in the variety window on which this activity was done.
    var repeatedActivity: Double = -2.5
    /// Per intensity point above `restfulIntensity` when recovery is owed.
    var recoveryBalance: Double = -1.2
    var qualityGap: Double = 2.0
    var cadenceNudge: Double = 1.0
    var bodyStateMatch: Double = 2.0
    var returningAfterGap: Double = 3.5
    var banditWeight: Double = 1.5
    var banditAlpha: Double = 0.5

    /// At or below this, a session counts as restful.
    var restfulIntensity: Int = 2
}

nonisolated struct PlanEngine: Sendable {

    /// Days of history the engine reads.
    static let historyWindowDays = 14
    /// A quality unseen for this long gets a nudge back onto the menu.
    static let qualityGapDays = 14
    /// Same activity within this window is downweighted.
    static let varietyWindowDays = 3
    /// Away this long, and the menu gets shorter and easier — with no comment
    /// on the gap itself. There is no visual language in this app for absence.
    static let reentryGapDays = 5
    /// Three to five items. If we ever need a "see more", we've failed.
    static let maxMenuItems = 5

    let catalog: [Session]
    var weights: PlanWeights

    init(catalog: [Session], weights: PlanWeights = PlanWeights()) {
        // Sorted once so every downstream tie-break is stable.
        self.catalog = catalog.sorted { $0.id < $1.id }
        self.weights = weights
    }

    // MARK: - Public API

    func makeMenu(_ input: PlanInput) -> Menu {
        let checkIn = resolvedCheckIn(input)
        if checkIn.time.isZero {
            return makeRestDayMenu(input, checkIn: checkIn)
        }
        let stats = HistoryStats(input: input)
        let scored = rankedCandidates(input, checkIn: checkIn, stats: stats)

        let special = pickSpecial(input, checkIn: checkIn, stats: stats)
        var taken: Set<String> = special.map { [$0.session.id] } ?? []
        var takenActivities: Set<Activity> = special.map { [$0.session.activity] } ?? []

        // Each course was previously eligible only if it individually fit the
        // whole check-in budget (`isEligible`'s `durationMin <= maxMinutes`),
        // with no running total across the main, every side, the appetizer,
        // and the dessert — so a 30-minute main plus a 20-minute side plus a
        // 5-minute appetizer could all individually pass and still add up to
        // 55 minutes against a 30-minute budget. `usedMinutes` tracks the
        // cumulative total as courses are added so the rest of assembly can
        // respect what's actually left, not just the original ceiling.
        // Specials are exempt — `isEligible` already lets them ignore today's
        // time budget because they're planned ahead — so they don't count
        // against it here either.
        let budget = checkIn.time.maxMinutes
        var usedMinutes = 0

        // The appetizer and dessert both carry a floor guarantee — "always
        // something to offer" — and honoring that after the main and sides
        // have already spent the whole budget is what pushed a 30-minute
        // target to 36: the floor items aren't optional, so they landed on
        // top instead. Reserve room for them *before* picking the main, so
        // the common case never needs their overshoot-prone fallback at all.
        // `floorDuration` mirrors `guaranteedAppetizer`/`guaranteedDessert`'s
        // own filter (safe, no-equipment, home-friendly, not hidden) so the
        // reservation reflects what could actually be guaranteed, not an
        // arbitrary constant.
        func floorDuration(course: Course) -> Int {
            catalog.filter {
                $0.course == course
                    && $0.needsNoEquipment
                    && $0.worksAtHome
                    && !$0.source.isVideo
                    && !taken.contains($0.id)
                    && !input.profile.hiddenSessionIDs.contains($0.id)
                    && Set($0.contraindications).isDisjoint(with: input.profile.workArounds)
            }.map(\.durationMin).min() ?? 0
        }
        let reservedFloor = floorDuration(course: .appetizer) + floorDuration(course: .dessert)
        // What's left for the main and sides to actually work with. Can be 0
        // (or even negative before clamping) on a very tight budget, in which
        // case no main is chosen at all — the same graceful "just the floor
        // items" degradation `alwaysOffersAnAppetizer` already covers.
        let mainAndSidesBudget = max(0, budget - reservedFloor)

        let main = first(from: scored, course: .main, excluding: taken, maxDuration: mainAndSidesBudget)
        if let main {
            taken.insert(main.session.id)
            takenActivities.insert(main.session.activity)
            usedMinutes += main.session.durationMin
        }

        // When every activity on the menu is already spoken for, the
        // distinctness constraint has to relax — but relaxing it to "best
        // score" decides by the alphabetical id tie-break, which silently
        // flips the menu when a session is renamed. The Special and the Main
        // are the items being offered as the day's real thing, so contrast
        // with *those* is the contrast a person notices; quietly echoing a
        // Side or the Appetizer is not. Relax in that order, deliberately.
        var heroActivities: Set<Activity> = []
        if let special { heroActivities.insert(special.session.activity) }
        if let main { heroActivities.insert(main.session.activity) }

        // How many small things belong on the menu is a shape question, not a
        // workload one: the same time, arranged to fit the day being described.
        let sideCount: Int = switch input.profile.guidancePreference {
        case .gettingStarted:
            0
        case .knowsWhatTheyEnjoy:
            input.profile.moments.sideCount
        case .hasOwnRoutine:
            max(2, input.profile.moments.sideCount)
        }
        var sides: [MenuItem] = []
        if sideCount > 0 {
            for candidate in scored where candidate.session.course == .side {
                guard !taken.contains(candidate.session.id) else { continue }
                if takenActivities.contains(candidate.session.activity) { continue }
                // A side that individually fits the budget can still blow it
                // once stacked on the main — only take it if it fits what's
                // actually left of the main-and-sides pool (not the whole
                // remaining budget, which would eat into room reserved for
                // the appetizer/dessert floor above), and keep scanning for
                // a shorter one instead of stopping at the first
                // (highest-scored) candidate.
                guard candidate.session.durationMin <= mainAndSidesBudget - usedMinutes else { continue }
                sides.append(candidate.item)
                taken.insert(candidate.session.id)
                takenActivities.insert(candidate.session.activity)
                usedMinutes += candidate.session.durationMin
                if sides.count == sideCount { break }
            }
        }

        // The appetizer is the floor of the product — `alwaysOffersAnAppetizer`
        // and `neverFailsAcrossTheCheckInMatrix` guarantee one exists no
        // matter how little time or access someone has, so it can never be
        // skipped outright the way a side or dessert can. Try first for one
        // that fits what's left of the budget; only when nothing does, fall
        // straight to `guaranteedAppetizer` — a specifically small,
        // no-equipment session by design — rather than re-trying the same
        // top-scored `scored` pool with no duration cap at all. That
        // distinction matters: `scored` entries are only bounded by the
        // *whole* budget (`isEligible`), so an uncapped retry of `first(from:
        // scored, ...)` could hand back something nearly as long as the full
        // budget on top of what was already used — which is exactly how a
        // 35-minute check-in was landing at 48 minutes.
        let remainingForAppetizer = max(0, budget - usedMinutes)
        let appetizer = first(from: scored, course: .appetizer, excluding: taken, excludingActivities: takenActivities, maxDuration: remainingForAppetizer)
            ?? first(from: scored, course: .appetizer, excluding: taken, excludingActivities: heroActivities, maxDuration: remainingForAppetizer)
            ?? first(from: scored, course: .appetizer, excluding: taken, maxDuration: remainingForAppetizer)
            ?? guaranteedAppetizer(input, checkIn: checkIn, stats: stats, excluding: taken, maxDuration: remainingForAppetizer)
            ?? guaranteedAppetizer(input, checkIn: checkIn, stats: stats, excluding: taken)
        if let appetizer {
            taken.insert(appetizer.session.id)
            takenActivities.insert(appetizer.session.activity)
            usedMinutes += appetizer.session.durationMin
        }

        // `guaranteedDessert` should only be offered if it fits within the
        // remaining budget. Unlike the appetizer, dessert carries no floor
        // promise that allows it to overshoot the user's check-in budget.
        // If nothing fits what remains of the budget, no dessert is offered.
        let remainingForDessert = max(0, budget - usedMinutes)
        let dessert = first(from: scored, course: .dessert, excluding: taken, excludingActivities: takenActivities, maxDuration: remainingForDessert)
            ?? first(from: scored, course: .dessert, excluding: taken, excludingActivities: heroActivities, maxDuration: remainingForDessert)
            ?? first(from: scored, course: .dessert, excluding: taken, maxDuration: remainingForDessert)
            ?? guaranteedDessert(input, checkIn: checkIn, stats: stats, excluding: taken, maxDuration: remainingForDessert)
        if let dessert {
            taken.insert(dessert.session.id)
            takenActivities.insert(dessert.session.activity)
            usedMinutes += dessert.session.durationMin
        }

        // Trim to one screen. The appetizer and the main are the two things the
        // product promises, so they are the last to go.
        var trimmedSides = sides
        var trimmedDessert = dessert
        var count = [special, main, appetizer, dessert].compactMap { $0 }.count + sides.count
        if count > Self.maxMenuItems, trimmedSides.count > 1 {
            trimmedSides.removeLast()
            count -= 1
        }
        if count > Self.maxMenuItems, trimmedDessert != nil {
            trimmedDessert = nil
            count -= 1
        }
        if count > Self.maxMenuItems, !trimmedSides.isEmpty {
            trimmedSides.removeLast()
        }

        // Ensure total duration of non-special courses strictly respects the
        // check-in budget. If items ever stack beyond the budget, drop optional
        // courses in reverse priority (dessert first, then sides) until the
        // menu fits.
        func totalDuration() -> Int {
            (trimmedDessert?.session.durationMin ?? 0)
                + trimmedSides.reduce(0) { $0 + $1.session.durationMin }
                + (main?.session.durationMin ?? 0)
                + (appetizer?.session.durationMin ?? 0)
        }
        while totalDuration() > budget {
            if trimmedDessert != nil {
                trimmedDessert = nil
            } else if !trimmedSides.isEmpty {
                trimmedSides.removeLast()
            } else {
                break
            }
        }

        // Give every line on the menu something different to say.
        let spoken = distinctReasons(
            ordered: [appetizer, main] + trimmedSides + [trimmedDessert, special],
            intents: input.profile.intents,
            todayIntent: checkIn.todayIntent
        )
        let reasons = Set(spoken.values.flatMap(\.reasons))
        func said(_ item: MenuItem?) -> MenuItem? { item.flatMap { spoken[$0.id] } }

        return Menu(
            dayStart: input.context.calendar.startOfDay(for: input.context.now),
            appetizer: said(appetizer),
            main: said(main),
            sides: trimmedSides.compactMap { said($0) },
            dessert: said(trimmedDessert),
            special: said(special),
            headline: MenuCopy.headline(reasons: reasons, checkIn: checkIn),
            assumedCheckIn: checkIn
        )
    }

    /// Rewrites any reason that has already been used further up the menu,
    /// walking down this item's remaining reasons before falling back to
    /// something specific to the session itself. Menu order decides who keeps
    /// the good line, so this order matches the cards the person sees.
    private func distinctReasons(ordered items: [MenuItem?], intents: Set<Intent>, todayIntent: Intent? = nil) -> [String: MenuItem] {
        var used: Set<String> = []
        var result: [String: MenuItem] = [:]

        for item in items.compactMap({ $0 }) {
            var codes = item.reasons
            var text = item.reasonText

            while used.contains(text) && !codes.isEmpty {
                codes = Array(codes.dropFirst())
                text = MenuCopy.reason(
                    for: item.session,
                    codes: codes,
                    gapQuality: nil,
                    intent: matchingIntent(for: item.session, from: intents, today: todayIntent)
                )
            }
            if used.contains(text) { text = MenuCopy.fallbackLine(for: item.session) }
            if used.contains(text), !item.session.subtitle.isEmpty { text = item.session.subtitle }

            used.insert(text)
            result[item.id] = MenuItem(
                session: item.session,
                course: item.course,
                reasons: item.reasons,
                reasonText: text
            )
        }
        return result
    }

    /// "Shuffle" — returns the next-best candidate for the same course.
    /// A swap is a success signal, not a rejection: it means engaging with the
    /// decision instead of closing the app.
    func alternative(for item: MenuItem, onMenu menu: Menu, input: PlanInput, alreadySeen: Set<String> = []) -> MenuItem? {
        let checkIn = resolvedCheckIn(input)
        let stats = HistoryStats(input: input)
        let scored = rankedCandidates(input, checkIn: checkIn, stats: stats)
        let excluded = Set(menu.items.map(\.session.id)).union(alreadySeen).union([item.session.id])

        let maxDuration = swapCeiling(for: item, onMenu: menu, budget: checkIn.time.maxMinutes)

        if let next = first(from: scored, course: item.course, excluding: excluded, maxDuration: maxDuration) {
            return next
        }
        // An appetizer must always be offerable, even on the third swap.
        if item.course == .appetizer {
            if let guaranteed = guaranteedAppetizer(input, checkIn: checkIn, stats: stats, excluding: excluded, maxDuration: maxDuration) {
                return guaranteed
            }
        }
        // A dessert can be offered if it fits within the remaining duration.
        if item.course == .dessert {
            if let guaranteed = guaranteedDessert(input, checkIn: checkIn, stats: stats, excluding: excluded, maxDuration: maxDuration) {
                return guaranteed
            }
        }
        return nil
    }

    /// The longest a replacement for `item` may be.
    ///
    /// A main or appetizer is a required course, so it may use whatever the
    /// *other required* course leaves free — the dessert and sides are optional
    /// and `fitting(_:to:)` drops them to make room. Without that a person with
    /// few options (one main that fits their equipment) got a swap that
    /// silently refused, because the optional courses had already filled the
    /// budget. Sides and dessert are themselves the optional courses, so they
    /// stay bounded by everything else on the menu.
    private func swapCeiling(for item: MenuItem, onMenu menu: Menu, budget: Int) -> Int? {
        if item.course == .special { return nil }
        let others = menu.items.filter { $0.id != item.id && $0.course != .special }
        let counted = item.course == .main || item.course == .appetizer
            ? others.filter { $0.course == .main || $0.course == .appetizer }
            : others
        return max(0, budget - counted.reduce(0) { $0 + $1.session.durationMin })
    }

    /// Drops the dessert, then sides from the end, until the timed courses fit
    /// the check-in budget — the order `makeMenu` uses. Call this after a swap
    /// so the menu never ends up longer than the time the person gave.
    func fitting(_ menu: Menu, to input: PlanInput) -> Menu {
        let budget = resolvedCheckIn(input).time.maxMinutes
        func total(_ menu: Menu) -> Int {
            menu.items.filter { $0.course != .special }.reduce(0) { $0 + $1.session.durationMin }
        }
        var result = menu
        while total(result) > budget {
            if result.dessert != nil {
                result = result.replacing(course: .dessert, withItem: nil)
            } else if let lastSide = result.sides.last {
                result = Menu(
                    dayStart: result.dayStart, appetizer: result.appetizer, main: result.main,
                    sides: result.sides.filter { $0.id != lastSide.id }, dessert: result.dessert,
                    special: result.special, headline: result.headline, assumedCheckIn: result.assumedCheckIn
                )
            } else {
                break
            }
        }
        return result
    }

    /// Returns the next alternative when cycling back after all unseen options have been seen.
    func cyclicAlternative(for item: MenuItem, onMenu menu: Menu, input: PlanInput) -> MenuItem? {
        let checkIn = resolvedCheckIn(input)
        let stats = HistoryStats(input: input)
        let scored = rankedCandidates(input, checkIn: checkIn, stats: stats)
        let excluded = Set(menu.items.map(\.session.id)).union([item.session.id])

        let maxDuration = swapCeiling(for: item, onMenu: menu, budget: checkIn.time.maxMinutes)

        if let next = first(from: scored, course: item.course, excluding: excluded, maxDuration: maxDuration) {
            return next
        }
        if item.course == .appetizer {
            if let guaranteed = guaranteedAppetizer(input, checkIn: checkIn, stats: stats, excluding: excluded, maxDuration: maxDuration) {
                return guaranteed
            }
        }
        if item.course == .dessert {
            if let guaranteed = guaranteedDessert(input, checkIn: checkIn, stats: stats, excluding: excluded, maxDuration: maxDuration) {
                return guaranteed
            }
        }
        return nil
    }

    // MARK: - Check-in inference

    /// The check-in was skipped, so we infer one and show a menu anyway.
    /// The app never blocks on input (PRD §7.2).
    func resolvedCheckIn(_ input: PlanInput) -> PlanCheckIn {
        if let checkIn = input.checkIn { return checkIn }

        let stats = HistoryStats(input: input)
        let time: TimeBudget = switch input.profile.realisticMinutes {
        case ..<15: .aLittle
        case ..<40: .some
        default: .plenty
        }

        var energy: Energy = .steady
        if stats.recoveryOwed {
            energy = .low
        } else if input.profile.bestTimeOfDay == timeOfDay(for: input.context) {
            energy = .strong
        }
        return PlanCheckIn(energy: energy, time: time, body: nil)
    }

    private func timeOfDay(for context: PlanContext) -> TimeOfDay {
        TimeOfDay(hour: context.calendar.component(.hour, from: context.now))
    }

    // MARK: - Filtering

    /// Hard filters. Everything here is a "never", not a preference.
    func isEligible(_ session: Session, input: PlanInput, checkIn: PlanCheckIn) -> Bool {
        // Hidden sessions: when someone hides a routine ("Don't suggest this again"),
        // it is never recommended anywhere on the menu.
        guard !input.profile.hiddenSessionIDs.contains(session.id) else { return false }
        // Work-arounds. For this audience — many postpartum — pelvic floor,
        // joints and pregnancy are not edge cases.
        guard Set(session.contraindications).isDisjoint(with: input.profile.workArounds) else { return false }
        // Never recommend equipment that isn't available.
        guard Set(session.equipment).subtracting([.none]).isSubset(of: input.profile.equipment) else { return false }
        // Specials are planned ahead, so today's time budget doesn't apply.
        // Rest days only match untimed (0-minute) sessions; active days only match positive durations.
        if checkIn.time.isZero {
            guard session.durationMin == 0 else { return false }
        } else if session.course != .special {
            guard session.durationMin > 0 && session.durationMin <= checkIn.time.maxMinutes else { return false }
        }
        // Activities that need a pool, a bike or a pair of skates are asked
        // about; the rest are always on the table and earn their place through
        // scoring. See `Activity.isAlwaysAvailable`.
        guard session.activity.isAlwaysAvailable
            || input.profile.availableActivities.contains(session.activity) else { return false }
        // Place. Nothing that needs leaving the house reaches somebody who has
        // already decided they're staying in.
        guard isReachable(session, input: input, checkIn: checkIn) else { return false }
        // Offline or data saver: video is silently unavailable, and it never
        // shows, because the authored catalog covers the day.
        if session.source.isVideo && !input.context.videoAllowed { return false }
        return true
    }

    /// Somewhere this session can actually happen today. An untagged session
    /// carries no place constraint.
    private func isReachable(_ session: Session, input: PlanInput, checkIn: PlanCheckIn) -> Bool {
        guard !session.places.isEmpty else { return true }
        var allowed = input.profile.places
        if let intent = checkIn.place {
            allowed.formIntersection(intent.places)
        }
        return !Set(session.places).isDisjoint(with: allowed)
    }

    // MARK: - Scoring

    private struct Candidate {
        let session: Session
        let score: Double
        let item: MenuItem
    }

    private func rankedCandidates(_ input: PlanInput, checkIn: PlanCheckIn, stats: HistoryStats) -> [Candidate] {
        catalog
            .filter { isEligible($0, input: input, checkIn: checkIn) }
            .map { candidate(for: $0, input: input, checkIn: checkIn, stats: stats) }
            // Deterministic: score first, id as the stable tie-break.
            .sorted { $0.score == $1.score ? $0.session.id < $1.session.id : $0.score > $1.score }
    }

    private func candidate(for session: Session, input: PlanInput, checkIn: PlanCheckIn, stats: HistoryStats) -> Candidate {
        var score = 0.0
        var reasons: [ReasonCode] = []
        var gapQuality: Quality?
        let restful = session.intensity <= weights.restfulIntensity

        // Energy match.
        if session.energyFit.contains(checkIn.energy) {
            score += weights.energyMatch
        } else {
            score += weights.energyMismatch
        }
        if checkIn.energy == .low {
            let over = max(0, session.intensity - weights.restfulIntensity)
            score += Double(over) * weights.highIntensityOnLowEnergy
            if restful { reasons.append(.lowEnergy) }
        }

        // The first onboarding answer changes how assertively the menu
        // curates. It never changes eligibility or safety—only ranking and
        // how many optional choices are assembled above.
        switch input.profile.guidancePreference {
        case .gettingStarted:
            if restful {
                score += weights.gettingStartedGentleMatch
            } else {
                let over = max(0, session.intensity - weights.restfulIntensity)
                score += Double(over) * weights.gettingStartedIntensityPenalty
            }
        case .knowsWhatTheyEnjoy:
            if input.profile.preferredActivities.contains(session.activity) {
                score += weights.preferredActivityMatch
            }
        case .hasOwnRoutine:
            if session.isOwn {
                score += weights.ownRoutineMatch
            } else if input.profile.preferredActivities.contains(session.activity) {
                score += weights.preferredActivityMatch
            }
        }

        // Time fit — use the time available without overrunning it.
        let target = min(checkIn.time.maxMinutes, max(input.profile.realisticMinutes, 10))
        if session.course == .main {
            let closeness = 1.0 - min(1.0, abs(Double(session.durationMin - target)) / Double(target))
            score += closeness * weights.timeFit
        }
        if checkIn.time.isTight && session.durationMin <= checkIn.time.maxMinutes {
            reasons.append(.timeConstrained)
        }

        // Recovery balance — two hard days running should not become three.
        if stats.recoveryOwed {
            let over = max(0, session.intensity - weights.restfulIntensity)
            score += Double(over) * weights.recoveryBalance
            if restful { reasons.append(.recoveryBalance) }
        }

        // Variety — prevents monotony without banning a favourite.
        let repeats = stats.recentActivityCounts[session.activity] ?? 0
        score += Double(repeats) * weights.repeatedActivity
        if repeats == 0 && stats.hasRepeatedActivityRecently {
            reasons.append(.varietyBreak)
        }

        // Intent. What was said today overrides the standing profile intents
        // for this menu — a louder, more specific signal than an onboarding
        // answer that may be months old. Unstated, profile intents apply.
        if let todayIntent = checkIn.todayIntent {
            if sessionMatches(todayIntent, session: session) {
                score += weights.todayIntentMatch
                reasons.append(.matchesIntent)
            }
        } else if input.profile.intents.contains(where: { sessionMatches($0, session: session) }) {
            score += weights.intentMatch
            reasons.append(.matchesIntent)
        }

        // Today's answer, beyond the goal itself. Both are nudges: a session
        // that misses them is still eligible, it just stops leading.
        if let focus = checkIn.focus, session.bodyFocus.contains(focus) {
            score += weights.focusMatch
        }
        if checkIn.favoured.contains(session.activity) {
            score += weights.favouredActivityMatch
        }

        // Affinity — quietly, over time.
        let affinity = (input.affinity[session.id] ?? 0) + stats.derivedAffinity[session.id, default: 0]
        score += affinity.clamped(to: -1...1) * weights.affinity

        // Adaptive contextual bandit score.
        if let banditState = input.banditState, weights.banditWeight != 0 {
            let banditScore = BanditEngine.predictScore(
                for: session,
                profile: input.profile,
                checkIn: checkIn,
                stats: stats,
                context: input.context,
                state: banditState,
                alpha: weights.banditAlpha
            )
            score += banditScore * weights.banditWeight
        }

        // Quality coverage. Only once there's enough history for "absent" to
        // mean anything — a new user is not behind on anything.
        if stats.qualityCoverageIsMeaningful {
            if let uncovered = session.qualities.first(where: { !stats.coveredQualities.contains($0) }) {
                score += weights.qualityGap
                gapQuality = uncovered
                reasons.append(.qualityGap)
            }
        }

        // Cadence nudge — below the stated cadence means gentler entry
        // points, never a penalty on anything.
        if stats.completedThisWeek < input.profile.cadence.weeklyTarget {
            score += weights.cadenceNudge * (1.0 - Double(session.intensity) / 5.0)
        }

        // Body. Every selected concern contributes, with a cap so checking
        // several does not overpower time, energy, and the user's preferences.
        if !checkIn.bodies.isEmpty {
            let bodyAdjustment = checkIn.bodies.reduce(0.0) {
                $0 + bodyScore(session, body: $1)
            }
            score += bodyAdjustment.clamped(
                to: -weights.bodyStateMatch...(weights.bodyStateMatch * 2)
            )
        }

        // Coming back after a gap: shorter and easier, and said warmly.
        if stats.daysSinceLastCompleted.map({ $0 >= Self.reentryGapDays }) ?? stats.hasNoHistory {
            let easy = restful && session.durationMin <= 15
            if easy {
                score += weights.returningAfterGap
                if stats.daysSinceLastCompleted != nil { reasons.insert(.returningAfterGap, at: 0) }
            }
        }

        let ordered = prioritise(reasons)
        let item = MenuItem(
            session: session,
            course: session.course,
            reasons: ordered,
            reasonText: MenuCopy.reason(
                for: session,
                codes: ordered,
                gapQuality: gapQuality,
                intent: matchingIntent(for: session, from: input.profile.intents, today: checkIn.todayIntent)
            )
        )
        return Candidate(session: session, score: score, item: item)
    }

    /// `today`, when stated, is what the reason line talks about — it's the
    /// louder, just-asked-for signal `sessionMatches`/scoring above already
    /// prefers. Falls through to the standing profile intents, in their
    /// declared order, when nothing was said today or today's doesn't fit
    /// this particular session.
    private func matchingIntent(for session: Session, from intents: Set<Intent>, today: Intent? = nil) -> Intent {
        if let today, sessionMatches(today, session: session) { return today }
        return Intent.allCases.first { intents.contains($0) && sessionMatches($0, session: session) }
            ?? Intent.allCases.first(where: intents.contains)
            ?? .energize
    }

    /// "Just showing up" describes the size of the ask, not a content genre.
    /// Play remains a normal authored tag; showing up matches any short,
    /// gentle session so it can influence the menu without duplicating tags.
    private func sessionMatches(_ intent: Intent, session: Session) -> Bool {
        if intent == .joy {
            return session.intensity <= 2 && session.durationMin <= 15
        }
        return session.intents.contains(intent)
    }

    private func bodyScore(_ session: Session, body: BodyState) -> Double {
        let w = weights.bodyStateMatch
        switch body {
        case .sore, .cramping:
            var s = 0.0
            if session.qualities.contains(where: { $0 == .mobility || $0 == .downRegulation }) { s += w }
            if session.intensity >= 4 { s -= w }
            return s
        case .stiff:
            return session.qualities.contains(.mobility) ? w : 0
        case .stressed:
            var s = 0.0
            if session.qualities.contains(.downRegulation) { s += w }
            if session.intents.contains(.calm) { s += w / 2 }
            return s
        case .good:
            return 0
        }
    }

    /// Most specific reason first — the copy layer shows one.
    private func prioritise(_ reasons: [ReasonCode]) -> [ReasonCode] {
        let order: [ReasonCode] = [
            .returningAfterGap, .lowEnergy, .timeConstrained,
            .recoveryBalance, .qualityGap, .varietyBreak, .matchesIntent
        ]
        var seen: Set<ReasonCode> = []
        return order.filter { reasons.contains($0) && seen.insert($0).inserted }
    }

    // MARK: - Assembly helpers

    private func first(from scored: [Candidate], course: Course, excluding: Set<String>, excludingActivities: Set<Activity> = [], maxDuration: Int? = nil) -> MenuItem? {
        scored.first {
            $0.session.course == course
                && !excluding.contains($0.session.id)
                && !excludingActivities.contains($0.session.activity)
                && (maxDuration == nil || $0.session.durationMin <= maxDuration!)
        }?.item
    }

    private func pickSpecial(_ input: PlanInput, checkIn: PlanCheckIn, stats: HistoryStats) -> MenuItem? {
        let calendar = input.context.calendar
        let today = calendar.startOfDay(for: input.context.now)
        // Specials are surfaced *ahead* of the day they happen.
        let upcoming = input.context.scheduledSpecials
            .filter { special in
                let day = calendar.startOfDay(for: special.date)
                guard let diff = calendar.dateComponents([.day], from: today, to: day).day else { return false }
                return (0...3).contains(diff)
            }
            .sorted { $0.date < $1.date }

        for special in upcoming {
            guard let session = catalog.first(where: { $0.id == special.sessionID }),
                  isEligible(session, input: input, checkIn: checkIn) else { continue }
            return candidate(for: session, input: input, checkIn: checkIn, stats: stats).item
        }
        return nil
    }

    /// The floor of the whole product: a day where you did two minutes is a day
    /// you showed up, so there is always something to offer. Ignores activity
    /// availability (you always have your own breath) but never safety.
    ///
    /// When `maxDuration` is nil — nothing fit what was actually left of the
    /// budget — this falls back to the *whole* check-in budget as its ceiling
    /// (never higher; `neverFailsAcrossTheCheckInMatrix` requires every
    /// non-special item, guaranteed ones included, to individually respect
    /// `time.maxMinutes`) and picks the *shortest* eligible match under that
    /// ceiling, rather than the first one in catalog order. The guarantee is
    /// allowed to push past what's left of the budget — that's the point of
    /// a floor — but never past the original whole-budget ceiling, and by as
    /// little as the catalog allows.
    private func guaranteedAppetizer(_ input: PlanInput, checkIn: PlanCheckIn, stats: HistoryStats, excluding: Set<String>, maxDuration: Int? = nil) -> MenuItem? {
        let cap = maxDuration ?? checkIn.time.maxMinutes
        let eligible = catalog.filter {
            $0.course == .appetizer
                && $0.needsNoEquipment
                && $0.worksAtHome
                && $0.durationMin <= cap
                && !$0.source.isVideo
                && !excluding.contains($0.id)
                && !input.profile.hiddenSessionIDs.contains($0.id)
                && Set($0.contraindications).isDisjoint(with: input.profile.workArounds)
        }
        let fallback = maxDuration == nil ? eligible.min(by: { $0.durationMin < $1.durationMin }) : eligible.first
        return fallback.map { candidate(for: $0, input: input, checkIn: checkIn, stats: stats).item }
    }

    /// A dessert must always be offerable: zero equipment, home-friendly, safe,
    /// purely for the joy of it. Same whole-budget-ceiling, shortest-match
    /// fallback as the appetizer when `maxDuration` is nil — see its doc
    /// comment. Unlike the appetizer there's no test requiring a dessert
    /// survive every budget — when nothing in the catalog fits even the
    /// whole budget (a real possibility here since desserts run longer),
    /// this returns nil and the menu simply has no dessert.
    private func guaranteedDessert(_ input: PlanInput, checkIn: PlanCheckIn, stats: HistoryStats, excluding: Set<String>, maxDuration: Int? = nil) -> MenuItem? {
        let cap = maxDuration ?? checkIn.time.maxMinutes
        let eligible = catalog.filter {
            $0.course == .dessert
                && $0.needsNoEquipment
                && $0.worksAtHome
                && $0.durationMin <= cap
                && !$0.source.isVideo
                && !excluding.contains($0.id)
                && !input.profile.hiddenSessionIDs.contains($0.id)
                && Set($0.contraindications).isDisjoint(with: input.profile.workArounds)
        }
        let fallback = maxDuration == nil ? eligible.min(by: { $0.durationMin < $1.durationMin }) : eligible.first
        return fallback.map { candidate(for: $0, input: input, checkIn: checkIn, stats: stats).item }
    }

    // MARK: - Rest Day Menu

    private func makeRestDayMenu(_ input: PlanInput, checkIn: PlanCheckIn) -> Menu {
        let appSession = catalog.first {
            $0.course == .appetizer && $0.durationMin == 0 && !input.profile.hiddenSessionIDs.contains($0.id)
        } ?? Self.fallbackRestAppetizer

        let mainSession = catalog.first {
            $0.course == .main && $0.durationMin == 0 && !input.profile.hiddenSessionIDs.contains($0.id)
        } ?? Self.fallbackRestMain

        let appetizerItem = MenuItem(
            session: appSession,
            course: .appetizer,
            reasons: [],
            reasonText: "Untimed · Soft breathing"
        )
        let mainItem = MenuItem(
            session: mainSession,
            course: .main,
            reasons: [],
            reasonText: "Restorative posture · Take your time"
        )

        return Menu(
            dayStart: input.context.calendar.startOfDay(for: input.context.now),
            appetizer: appetizerItem,
            main: mainItem,
            sides: [],
            dessert: nil,
            special: nil,
            headline: MenuCopy.headline(reasons: [], checkIn: checkIn),
            assumedCheckIn: checkIn
        )
    }

    static let fallbackRestAppetizer = Session(
        id: "app-rest-box-breathing",
        title: "Box breathing & unwind",
        subtitle: "Untimed, anywhere, eyes open or closed",
        activity: .breathwork,
        qualities: [.downRegulation],
        durationMin: 0,
        intensity: 1,
        energyFit: [.low, .steady, .strong],
        equipment: [.none],
        places: [.home, .gym],
        bodyFocus: [.full],
        contraindications: [],
        intents: [.calm],
        course: .appetizer,
        source: .authored(steps: [
            Step(
                name: "Settle & breathe",
                seconds: 60,
                cue: "Rest is part of the practice. Take a gentle breath in, exhale softly, and give yourself permission to do nothing.",
                visual: .breathing(BreathingCadence(inhale: 4, holdIn: 4, exhale: 4, holdOut: 4))
            )
        ]),
        attribution: nil
    )

    static let fallbackRestMain = Session(
        id: "main-rest-legs-up-the-wall",
        title: "Legs up the wall & release",
        subtitle: "A restorative posture to reset body and mind",
        activity: .stretching,
        qualities: [.downRegulation, .mobility],
        durationMin: 0,
        intensity: 1,
        energyFit: [.low, .steady, .strong],
        equipment: [.none],
        places: [.home],
        bodyFocus: [.full],
        contraindications: [],
        intents: [.calm],
        course: .main,
        source: .authored(steps: [
            Step(
                name: "Settle by the wall",
                seconds: 120,
                cue: "Lie on your back and swing your legs up against a wall or resting on a sofa. Rest your arms comfortably by your sides."
            ),
            Step(
                name: "Rest & let go",
                seconds: 180,
                cue: "Let your hips feel heavy into the floor. Soften your jaw, release your shoulders, and stay here for as long as feels good."
            )
        ]),
        attribution: nil
    )
}

// MARK: - History stats

/// Everything the engine needs to know about the last two weeks, computed once.
nonisolated struct HistoryStats: Sendable {
    let completedThisWeek: Int
    let daysSinceLastCompleted: Int?
    let recentActivityCounts: [Activity: Int]
    let hasRepeatedActivityRecently: Bool
    let coveredQualities: Set<Quality>
    let qualityCoverageIsMeaningful: Bool
    let recoveryOwed: Bool
    let derivedAffinity: [String: Double]
    let hasNoHistory: Bool

    init(input: PlanInput) {
        let calendar = input.context.calendar
        let today = calendar.startOfDay(for: input.context.now)

        func daysAgo(_ date: Date) -> Int {
            calendar.dateComponents([.day], from: calendar.startOfDay(for: date), to: today).day ?? .max
        }

        let window = input.history.filter { daysAgo($0.date) < PlanEngine.historyWindowDays && daysAgo($0.date) >= 0 }
        let completed = window.filter(\.wasCompleted)

        let lastActiveDaysAgo: Int? = switch input.memory {
        case .recencyOnly(let date):
            date.map { daysAgo($0) }.flatMap { $0 >= 0 ? $0 : nil }
        case .full:
            nil
        }
        hasNoHistory = completed.isEmpty && lastActiveDaysAgo == nil
        completedThisWeek = completed.filter { daysAgo($0.date) < 7 }.count
        daysSinceLastCompleted = completed.map { daysAgo($0.date) }.min() ?? lastActiveDaysAgo

        // Variety.
        var counts: [Activity: Int] = [:]
        for entry in completed where daysAgo(entry.date) < PlanEngine.varietyWindowDays {
            counts[entry.activity, default: 0] += 1
        }
        recentActivityCounts = counts
        hasRepeatedActivityRecently = counts.values.contains { $0 >= 2 }

        // Quality coverage.
        coveredQualities = Set(
            completed
                .filter { daysAgo($0.date) < PlanEngine.qualityGapDays }
                .flatMap(\.qualities)
        )
        // A brand-new user is not "missing" anything. Wait for enough signal
        // before the engine starts noticing absences.
        qualityCoverageIsMeaningful = completed.count >= 4

        // Recovery: two hard days back to back should not become three.
        let hardDays = Set(
            completed
                .filter { $0.intensity >= 4 }
                .map { daysAgo($0.date) }
        )
        recoveryOwed = hardDays.contains(0) && hardDays.contains(1)
            || hardDays.contains(1) && hardDays.contains(2)

        // Affinity from what actually happened.
        var affinity: [String: Double] = [:]
        for entry in window {
            switch entry.outcome {
            case .completed(let feel):
                switch feel {
                case .lovedIt: affinity[entry.sessionID, default: 0] += 0.5
                case .tooMuch: affinity[entry.sessionID, default: 0] -= 0.5
                case .fine, .none: break
                }
            case .swappedAway:
                affinity[entry.sessionID, default: 0] -= 0.3
            case .skipped:
                break // Skipping is not a judgement. It's a Tuesday.
            }
        }
        derivedAffinity = affinity
    }
}

nonisolated private extension Double {
    func clamped(to range: ClosedRange<Double>) -> Double {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
