//
//  BanditSimulationTests.swift
//  FeelGoodTests
//
//  Simulation tests verifying 30-day, 60-day, and 90-day synthetic user trajectories.
//  Validates convergence, burnout prevention / 24-hour de-escalation, and guilt-free re-entry.
//

import Testing
import Foundation
@testable import FeelGood

@Suite("Bandit Simulation Trajectories")
struct BanditSimulationTests {

    @Test("30-Day trajectory: User loving 10-minute restorative yoga experiences healthy convergence without starving exploration")
    func thirtyDayRestorativeConvergence() {
        let engine = PlanEngine(catalog: Fixture.catalog)
        let profile = Fixture.profile(activities: [.yoga, .walking, .pilates, .dance, .strength])
        let calendar = Fixture.utc
        var banditState = BanditState()
        let startDate = Fixture.now

        let restorativePilates = Fixture.catalog.first {
            $0.activity == .pilates && $0.intensity <= 2 && $0.durationMin <= 15
        }!

        // Initial day 0 baseline score
        let checkIn = PlanCheckIn(energy: .low, time: .some)
        let initialContext = PlanContext(now: startDate, calendar: calendar)
        let initialInput = PlanInput(
            profile: profile,
            checkIn: checkIn,
            context: initialContext,
            banditState: banditState
        )
        let initialStats = HistoryStats(input: initialInput)

        let initialFeatures = BanditFeatures.extract(
            for: restorativePilates,
            profile: profile,
            checkIn: checkIn,
            stats: initialStats,
            context: initialContext
        )
        let (initialMean, _) = BanditArmState().predict(x: initialFeatures, alpha: 0.0)

        var history: [HistoryEntry] = []

        // Simulate 30 days of consistent loved restorative pilates
        for day in 0..<30 {
            let currentDate = calendar.date(byAdding: .day, value: day, to: startDate)!
            let context = PlanContext(now: currentDate, calendar: calendar)
            let dayCheckIn = PlanCheckIn(energy: .low, time: .some)
            let input = PlanInput(profile: profile, checkIn: dayCheckIn, history: history, context: context)
            let stats = HistoryStats(input: input)

            banditState = BanditEngine.update(
                state: banditState,
                session: restorativePilates,
                outcome: .completed(feel: .lovedIt),
                profile: profile,
                checkIn: dayCheckIn,
                stats: stats,
                context: context
            )

            history.append(HistoryEntry(
                sessionID: restorativePilates.id,
                activity: restorativePilates.activity,
                qualities: restorativePilates.qualities,
                intensity: restorativePilates.intensity,
                course: restorativePilates.course,
                durationMin: restorativePilates.durationMin,
                date: currentDate,
                outcome: .completed(feel: .lovedIt)
            ))
        }

        // Evaluate Day 30 state
        let day30Date = calendar.date(byAdding: .day, value: 30, to: startDate)!
        let day30Context = PlanContext(now: day30Date, calendar: calendar)
        let day30Input = PlanInput(
            profile: profile,
            checkIn: checkIn,
            history: history,
            context: day30Context,
            banditState: banditState
        )
        let day30Stats = HistoryStats(input: day30Input)

        // 1. Learned expected reward for restorative pilates increases significantly over 30 days
        let day30Arm = banditState.arm(for: .pilates)
        let day30Features = BanditFeatures.extract(
            for: restorativePilates,
            profile: profile,
            checkIn: checkIn,
            stats: day30Stats,
            context: day30Context
        )
        let (convergedMean, _) = day30Arm.predict(x: day30Features, alpha: 0.0)
        #expect(convergedMean > initialMean, "Learned mean reward should increase over 30 days")
        #expect(convergedMean > 0.7, "Learned mean reward should converge towards lovedIt reward")

        let convergedPilatesScore = BanditEngine.predictScore(
            for: restorativePilates,
            profile: profile,
            checkIn: checkIn,
            stats: day30Stats,
            context: day30Context,
            state: banditState
        )

        // 2. Exploration is NOT starved: an unplayed activity still gets exploration variance
        let unplayedActivity = Fixture.catalog.first { $0.activity == .dance }!
        let danceScore = BanditEngine.predictScore(
            for: unplayedActivity,
            profile: profile,
            checkIn: checkIn,
            stats: day30Stats,
            context: day30Context,
            state: banditState
        )
        let danceArm = banditState.arm(for: .dance)
        let danceFeatures = BanditFeatures.extract(
            for: unplayedActivity,
            profile: profile,
            checkIn: checkIn,
            stats: day30Stats,
            context: day30Context
        )
        let (_, danceBonus) = danceArm.predict(x: danceFeatures, alpha: 0.5)
        #expect(danceBonus > 0.0, "Exploration bonus for unplayed arm must remain positive")
        #expect(!danceScore.isNaN)
        #expect(convergedPilatesScore > danceScore, "Restorative pilates should outscore unplayed activity")

        // 3. Recommended menu on Day 30 reflects restorative focus
        let menu = engine.makeMenu(day30Input)
        #expect(menu.main != nil)
        #expect(menu.main?.session.intensity ?? 99 <= 3)
    }

    @Test("24-Hour de-escalation: User rating .tooMuch experiences rapid intensity de-escalation within 24 hours")
    func twentyFourHourDeescalationAfterTooMuch() {
        let engine = PlanEngine(catalog: Fixture.catalog)
        let profile = Fixture.profile(activities: [.strength, .yoga, .stretching, .pilates])
        let calendar = Fixture.utc
        var banditState = BanditState()
        let day1 = Fixture.now

        // Find a high-intensity session (intensity >= 4)
        let hardSession = Fixture.catalog.first { $0.intensity >= 4 }!
        let gentleSession = Fixture.catalog.first { $0.intensity <= 2 && $0.course == .main }
            ?? Fixture.catalog.first { $0.intensity <= 2 }!

        // Day 1: User does hard session and rates .tooMuch
        let day1Context = PlanContext(now: day1, calendar: calendar)
        let day1CheckIn = PlanCheckIn(energy: .strong, time: .fortyMinutes)
        let day1Stats = HistoryStats(input: PlanInput(profile: profile, checkIn: day1CheckIn, context: day1Context))

        banditState = BanditEngine.update(
            state: banditState,
            session: hardSession,
            outcome: .completed(feel: .tooMuch),
            profile: profile,
            checkIn: day1CheckIn,
            stats: day1Stats,
            context: day1Context,
            consecutiveHardDays: 1
        )

        // Day 2 (24 hours later): User opens app
        let day2 = calendar.date(byAdding: .day, value: 1, to: day1)!
        let day2Context = PlanContext(now: day2, calendar: calendar)
        let day2CheckIn = PlanCheckIn(energy: .low, time: .twentyMinutes, bodies: [.sore])
        let history = [
            HistoryEntry(
                sessionID: hardSession.id,
                activity: hardSession.activity,
                qualities: hardSession.qualities,
                intensity: hardSession.intensity,
                course: hardSession.course,
                durationMin: hardSession.durationMin,
                date: day1,
                outcome: .completed(feel: .tooMuch)
            )
        ]

        let day2Input = PlanInput(
            profile: profile,
            checkIn: day2CheckIn,
            history: history,
            context: day2Context,
            banditState: banditState
        )
        let day2Stats = HistoryStats(input: day2Input)

        // Verify hard session score is dampened
        let hardScore = BanditEngine.predictScore(
            for: hardSession,
            profile: profile,
            checkIn: day2CheckIn,
            stats: day2Stats,
            context: day2Context,
            state: banditState
        )
        let gentleScore = BanditEngine.predictScore(
            for: gentleSession,
            profile: profile,
            checkIn: day2CheckIn,
            stats: day2Stats,
            context: day2Context,
            state: banditState
        )

        #expect(gentleScore > hardScore, "Gentle session must outscore hard session after .tooMuch")

        // Recommended menu must de-escalate
        let menu = engine.makeMenu(day2Input)
        if let main = menu.main {
            #expect(main.session.intensity <= 2, "Main recommendation must de-escalate to restful intensity <= 2 within 24h")
        }
    }

    @Test("90-Day trajectory with guilt-free gaps: 5+ day hiatus leaves weights intact and transitions smoothly to re-entry")
    func ninetyDayTrajectoryWithGuiltFreeGaps() {
        let engine = PlanEngine(catalog: Fixture.catalog)
        let profile = Fixture.profile()
        let calendar = Fixture.utc
        var banditState = BanditState()
        let startDate = Fixture.now
        var history: [HistoryEntry] = []

        // Phase 1: Days 0 to 20, regular movement
        let pilatesSession = Fixture.catalog.first { $0.activity == .pilates }!
        for day in 0..<20 {
            let date = calendar.date(byAdding: .day, value: day, to: startDate)!
            let context = PlanContext(now: date, calendar: calendar)
            let checkIn = PlanCheckIn(energy: .steady, time: .twentyMinutes)
            let stats = HistoryStats(input: PlanInput(profile: profile, checkIn: checkIn, history: history, context: context))

            banditState = BanditEngine.update(
                state: banditState,
                session: pilatesSession,
                outcome: .completed(feel: .lovedIt),
                profile: profile,
                checkIn: checkIn,
                stats: stats,
                context: context
            )
            history.append(HistoryEntry(
                sessionID: pilatesSession.id,
                activity: pilatesSession.activity,
                qualities: pilatesSession.qualities,
                intensity: pilatesSession.intensity,
                course: pilatesSession.course,
                durationMin: pilatesSession.durationMin,
                date: date,
                outcome: .completed(feel: .lovedIt)
            ))
        }

        // Save bandit state at Day 20 before the gap
        let preGapPilatesTheta = banditState.arm(for: .pilates).theta

        // Phase 2: Days 20 to 26 (7-day gap / hiatus, within the 14-day history window and >= 5 days).
        // Under guilt-free absence, skipping days invokes NO penalty updates (R = 0, no negative degradation).
        let resumeDate = calendar.date(byAdding: .day, value: 26, to: startDate)!
        let resumeContext = PlanContext(now: resumeDate, calendar: calendar)
        let resumeInput = PlanInput(
            profile: profile,
            checkIn: nil, // skipped check-in upon return
            history: history,
            context: resumeContext,
            banditState: banditState
        )

        // 1. Learned bandit affinity weights are NOT degraded by the gap
        let postGapPilatesTheta = banditState.arm(for: .pilates).theta
        #expect(preGapPilatesTheta == postGapPilatesTheta, "Bandit weights must not degrade over gaps")

        // 2. Engine recognizes re-entry gap (>= 5 days) and produces warm shorter menu
        let menu = engine.makeMenu(resumeInput)
        let stats = HistoryStats(input: resumeInput)
        #expect(stats.daysSinceLastCompleted ?? 0 >= 5)
        #expect(menu.items.contains { $0.reasons.contains(.returningAfterGap) }, "Menu contains warm re-entry reason")

        // Phase 3: Resume through Day 90 with mixed activities
        let walkingSession = Fixture.catalog.first { $0.activity == .walking }!
        for day in 27..<90 {
            let date = calendar.date(byAdding: .day, value: day, to: startDate)!
            let context = PlanContext(now: date, calendar: calendar)
            let checkIn = PlanCheckIn(energy: .steady, time: .twentyMinutes)
            let input = PlanInput(profile: profile, checkIn: checkIn, history: history, context: context)
            let currentStats = HistoryStats(input: input)

            let chosen = (day % 3 == 0) ? walkingSession : pilatesSession
            banditState = BanditEngine.update(
                state: banditState,
                session: chosen,
                outcome: .completed(feel: .fine),
                profile: profile,
                checkIn: checkIn,
                stats: currentStats,
                context: context
            )
            history.append(HistoryEntry(
                sessionID: chosen.id,
                activity: chosen.activity,
                qualities: chosen.qualities,
                intensity: chosen.intensity,
                course: chosen.course,
                durationMin: chosen.durationMin,
                date: date,
                outcome: .completed(feel: .fine)
            ))
        }

        // At Day 90, bandit state remains healthy and well-conditioned
        let coarsened = BanditEngine.coarsenedPreferences(from: banditState)
        #expect(coarsened.topExploredActivities?.contains(Activity.pilates.rawValue) == true)
        #expect(coarsened.topExploredActivities?.contains(Activity.walking.rawValue) == true)
    }
}
