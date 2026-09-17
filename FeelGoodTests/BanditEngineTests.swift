//
//  BanditEngineTests.swift
//  FeelGoodTests
//
//  Unit tests for the Dual-Objective LinUCB Contextual Bandit Engine.
//

import Testing
import Foundation
@testable import FeelGood

@Suite("Contextual Bandit Engine")
struct BanditEngineTests {

    @Test("Arm state initializes with identity inverse covariance and zero bias")
    func armStateInitialization() {
        let arm = BanditArmState(dimension: 8)
        #expect(arm.pullCount == 0)
        #expect(arm.biasVector.count == 8)
        #expect(arm.invCovariance.count == 8)

        for i in 0..<8 {
            #expect(arm.biasVector[i] == 0.0)
            for j in 0..<8 {
                if i == j {
                    #expect(arm.invCovariance[i][j] == 1.0)
                } else {
                    #expect(arm.invCovariance[i][j] == 0.0)
                }
            }
        }
        #expect(arm.theta == Array(repeating: 0.0, count: 8))
    }

    @Test("Sherman-Morrison update maintains numerical stability and reduces variance")
    func shermanMorrisonUpdateStability() {
        var arm = BanditArmState(dimension: 8)
        let x = [1.0, 0.5, 0.2, 1.0, 0.0, 0.4, 1.0, 0.5]

        let (initialMean, initialBonus) = arm.predict(x: x, alpha: 1.0)
        #expect(initialMean == 0.0)
        #expect(initialBonus > 0.0)

        // Update with positive reward
        arm.update(x: x, reward: 1.0)
        #expect(arm.pullCount == 1)

        let (updatedMean, updatedBonus) = arm.predict(x: x, alpha: 1.0)
        #expect(updatedMean > 0.0, "Predicted mean should increase after positive reward")
        #expect(updatedBonus < initialBonus, "Exploration bonus should decay after observation")

        // Multiple updates should remain finite and well-conditioned
        for _ in 0..<50 {
            arm.update(x: x, reward: 1.0)
        }
        let (convergedMean, convergedBonus) = arm.predict(x: x, alpha: 1.0)
        #expect(!convergedMean.isNaN && !convergedMean.isInfinite)
        #expect(!convergedBonus.isNaN && !convergedBonus.isInfinite)
        #expect(convergedBonus < updatedBonus, "Exploration variance monotonically contracts")
    }

    @Test("Dual-objective reward values match PRD specification")
    func rewardValues() {
        let session = Fixture.catalog.first!

        // 1. Loved it: +1.0
        let rLoved = BanditReward.calculate(session: session, outcome: .completed(feel: .lovedIt))
        #expect(rLoved == 1.0)

        // 2. Fine or unrated: +0.6
        let rFine = BanditReward.calculate(session: session, outcome: .completed(feel: .fine))
        #expect(rFine == 0.6)
        let rUnrated = BanditReward.calculate(session: session, outcome: .completed(feel: nil))
        #expect(rUnrated == 0.6)

        // 3. Swapped away: -0.2
        let rSwapped = BanditReward.calculate(session: session, outcome: .swappedAway)
        #expect(rSwapped == -0.2)

        // 4. Skipped: 0.0 (guilt-free absence, never penalized)
        let rSkipped = BanditReward.calculate(session: session, outcome: .skipped)
        #expect(rSkipped == 0.0)

        // 5. Too much: -0.5 base penalty
        let rTooMuch = BanditReward.calculate(session: session, outcome: .completed(feel: .tooMuch))
        #expect(rTooMuch == -0.5)

        // 6. Successive hard days escalate overexertion penalty to prevent burnout
        let rConsecutiveHard = BanditReward.calculate(
            session: session,
            outcome: .completed(feel: .lovedIt),
            consecutiveHardDays: 3
        )
        #expect(rConsecutiveHard < 1.0, "Successive hard days suppress reward")
    }

    @Test("BanditEngine updates arm state and global prior")
    func engineUpdate() {
        var state = BanditState()
        let session = Fixture.catalog.first { $0.activity == .pilates }!
        let profile = Fixture.profile()
        let checkIn = PlanCheckIn(energy: .steady, time: .twentyMinutes)
        let context = Fixture.context()
        let stats = HistoryStats(input: PlanInput(profile: profile, checkIn: checkIn, context: context))

        #expect(state.arms[Activity.pilates.rawValue] == nil)
        #expect(state.globalPrior.pullCount == 0)

        state = BanditEngine.update(
            state: state,
            session: session,
            outcome: .completed(feel: .lovedIt),
            profile: profile,
            checkIn: checkIn,
            stats: stats,
            context: context
        )

        #expect(state.arms[Activity.pilates.rawValue] != nil)
        #expect(state.arms[Activity.pilates.rawValue]?.pullCount == 1)
        #expect(state.globalPrior.pullCount == 1)

        let pilatesScore = BanditEngine.predictScore(
            for: session,
            profile: profile,
            checkIn: checkIn,
            stats: stats,
            context: context,
            state: state
        )
        #expect(!pilatesScore.isNaN)
    }

    @Test("Coarsened preferences extract top activities and intensity tier correctly")
    func coarsenedPreferencesExtraction() {
        var state = BanditState()
        let pilatesSession = Fixture.catalog.first { $0.activity == .pilates && $0.intensity <= 2 }!
        let profile = Fixture.profile()
        let checkIn = PlanCheckIn(energy: .low, time: .aLittle)
        let context = Fixture.context()
        let stats = HistoryStats(input: PlanInput(profile: profile, checkIn: checkIn, context: context))

        // Simulate 5 loved restorative pilates sessions
        for _ in 0..<5 {
            state = BanditEngine.update(
                state: state,
                session: pilatesSession,
                outcome: .completed(feel: .lovedIt),
                profile: profile,
                checkIn: checkIn,
                stats: stats,
                context: context
            )
        }

        let coarsened = BanditEngine.coarsenedPreferences(from: state)
        #expect(coarsened.topExploredActivities?.contains(Activity.pilates.rawValue) == true)
        #expect(coarsened.preferredIntensityTier != nil)
    }
}
