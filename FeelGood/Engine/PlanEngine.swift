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
    var affinity: Double = 2.5
    /// Per prior day in the variety window on which this activity was done.
    var repeatedActivity: Double = -2.5
    /// Per intensity point above `restfulIntensity` when recovery is owed.
    var recoveryBalance: Double = -1.2
    var qualityGap: Double = 2.0
    var cadenceNudge: Double = 1.0
    var bodyStateMatch: Double = 2.0
    var returningAfterGap: Double = 3.5

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
        let stats = HistoryStats(input: input)
        let scored = rankedCandidates(input, checkIn: checkIn, stats: stats)

        let special = pickSpecial(input, checkIn: checkIn, stats: stats)
        var taken: Set<String> = special.map { [$0.session.id] } ?? []
        var takenActivities: Set<Activity> = special.map { [$0.session.activity] } ?? []

        let main = first(from: scored, course: .main, excluding: taken)
        if let main {
            taken.insert(main.session.id)
            takenActivities.insert(main.session.activity)
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
        let sideCount = input.profile.moments.sideCount
        var sides: [MenuItem] = []
        if sideCount > 0 {
            for candidate in scored where candidate.session.course == .side {
                guard !taken.contains(candidate.session.id) else { continue }
                if takenActivities.contains(candidate.session.activity) { continue }
                sides.append(candidate.item)
                taken.insert(candidate.session.id)
                takenActivities.insert(candidate.session.activity)
                if sides.count == sideCount { break }
            }
        }

        let appetizer = first(from: scored, course: .appetizer, excluding: taken, excludingActivities: takenActivities)
            ?? first(from: scored, course: .appetizer, excluding: taken, excludingActivities: heroActivities)
            ?? first(from: scored, course: .appetizer, excluding: taken)
            ?? guaranteedAppetizer(input, checkIn: checkIn, stats: stats, excluding: taken)
        if let appetizer {
            taken.insert(appetizer.session.id)
            takenActivities.insert(appetizer.session.activity)
        }

        let dessert = first(from: scored, course: .dessert, excluding: taken, excludingActivities: takenActivities)
            ?? first(from: scored, course: .dessert, excluding: taken, excludingActivities: heroActivities)
            ?? first(from: scored, course: .dessert, excluding: taken)
            ?? guaranteedDessert(input, checkIn: checkIn, stats: stats, excluding: taken)
        if let dessert {
            taken.insert(dessert.session.id)
            takenActivities.insert(dessert.session.activity)
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

        // Give every line on the menu something different to say.
        let spoken = distinctReasons(
            ordered: [appetizer, main] + trimmedSides + [trimmedDessert, special],
            intents: input.profile.intents
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
    private func distinctReasons(ordered items: [MenuItem?], intents: Set<Intent>) -> [String: MenuItem] {
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
                    intent: matchingIntent(for: item.session, from: intents)
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

        if let next = first(from: scored, course: item.course, excluding: excluded) {
            return next
        }
        // An appetizer must always be offerable, even on the third swap.
        if item.course == .appetizer {
            if let guaranteed = guaranteedAppetizer(input, checkIn: checkIn, stats: stats, excluding: excluded) {
                return guaranteed
            }
        }
        // A dessert must always be offerable.
        if item.course == .dessert {
            if let guaranteed = guaranteedDessert(input, checkIn: checkIn, stats: stats, excluding: excluded) {
                return guaranteed
            }
        }
        return nil
    }

    /// Returns the next alternative when cycling back after all unseen options have been seen.
    func cyclicAlternative(for item: MenuItem, onMenu menu: Menu, input: PlanInput) -> MenuItem? {
        let checkIn = resolvedCheckIn(input)
        let stats = HistoryStats(input: input)
        let scored = rankedCandidates(input, checkIn: checkIn, stats: stats)
        let excluded = Set(menu.items.map(\.session.id)).union([item.session.id])

        if let next = first(from: scored, course: item.course, excluding: excluded) {
            return next
        }
        if item.course == .appetizer {
            if let guaranteed = guaranteedAppetizer(input, checkIn: checkIn, stats: stats, excluding: excluded) {
                return guaranteed
            }
        }
        if item.course == .dessert {
            if let guaranteed = guaranteedDessert(input, checkIn: checkIn, stats: stats, excluding: excluded) {
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
        // Work-arounds. For this audience — many postpartum — pelvic floor,
        // joints and pregnancy are not edge cases.
        guard Set(session.contraindications).isDisjoint(with: input.profile.workArounds) else { return false }
        // Never recommend equipment that isn't available.
        guard Set(session.equipment).subtracting([.none]).isSubset(of: input.profile.equipment) else { return false }
        // Specials are planned ahead, so today's time budget doesn't apply.
        if session.course != .special {
            guard session.durationMin <= checkIn.time.maxMinutes else { return false }
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

        // Intent.
        if input.profile.intents.contains(where: { sessionMatches($0, session: session) }) {
            score += weights.intentMatch
            reasons.append(.matchesIntent)
        }

        // Affinity — quietly, over time.
        let affinity = (input.affinity[session.id] ?? 0) + stats.derivedAffinity[session.id, default: 0]
        score += affinity.clamped(to: -1...1) * weights.affinity

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

        // Body.
        if let body = checkIn.body {
            score += bodyScore(session, body: body)
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
                intent: matchingIntent(for: session, from: input.profile.intents)
            )
        )
        return Candidate(session: session, score: score, item: item)
    }

    private func matchingIntent(for session: Session, from intents: Set<Intent>) -> Intent {
        Intent.allCases.first { intents.contains($0) && sessionMatches($0, session: session) }
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

    private func first(from scored: [Candidate], course: Course, excluding: Set<String>, excludingActivities: Set<Activity> = []) -> MenuItem? {
        scored.first {
            $0.session.course == course
                && !excluding.contains($0.session.id)
                && !excludingActivities.contains($0.session.activity)
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
    private func guaranteedAppetizer(_ input: PlanInput, checkIn: PlanCheckIn, stats: HistoryStats, excluding: Set<String>) -> MenuItem? {
        let fallback = catalog.first {
            $0.course == .appetizer
                && $0.needsNoEquipment
                && $0.worksAtHome
                && !$0.source.isVideo
                && !excluding.contains($0.id)
                && Set($0.contraindications).isDisjoint(with: input.profile.workArounds)
        }
        return fallback.map { candidate(for: $0, input: input, checkIn: checkIn, stats: stats).item }
    }

    /// A dessert must always be offerable: zero equipment, home-friendly, safe,
    /// purely for the joy of it.
    private func guaranteedDessert(_ input: PlanInput, checkIn: PlanCheckIn, stats: HistoryStats, excluding: Set<String>) -> MenuItem? {
        let fallback = catalog.first {
            $0.course == .dessert
                && $0.needsNoEquipment
                && $0.worksAtHome
                && !$0.source.isVideo
                && !excluding.contains($0.id)
                && Set($0.contraindications).isDisjoint(with: input.profile.workArounds)
        }
        return fallback.map { candidate(for: $0, input: input, checkIn: checkIn, stats: stats).item }
    }
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

        let lastActiveDaysAgo = input.memory.lastActiveDate.map { daysAgo($0) }
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
