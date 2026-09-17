//
//  Bandit.swift
//  FeelGood
//
//  Dual-Objective Adaptive Contextual Bandit Engine.
//  Pure function over Foundation types: no SwiftData, no I/O, no network, no clock.
//  See PRD §7.3, §7.4, and CLAUDE.md.
//

import Foundation

/// Mathematical and algorithmic dimensions for the contextual bandit.
nonisolated enum BanditConstants {
    /// Dimension of the feature context vector x_t.
    static let dimension: Int = 8
    /// Default exploration weight alpha for LinUCB upper confidence bounds.
    static let defaultAlpha: Double = 0.5
    /// Weight on the overexertion penalty objective lambda.
    static let defaultLambda: Double = 1.0
}

// MARK: - Dual-Objective Reward Modeling

/// Dual-objective reward formulation:
/// R(s, o) = R_satisfaction(o) - lambda * R_overexertion(s, o)
nonisolated struct BanditReward: Sendable {
    static let satisfactionLovedIt: Double = 1.0
    static let satisfactionFine: Double = 0.6
    static let satisfactionUnrated: Double = 0.6
    static let satisfactionSwapped: Double = -0.2
    static let satisfactionSkipped: Double = 0.0

    static let overexertionTooMuch: Double = 0.5
    static let overexertionConsecutiveHardScale: Double = 0.3

    /// Evaluates the scalar reward for a session and outcome.
    static func calculate(
        session: Session,
        outcome: HistoryOutcome,
        consecutiveHardDays: Int = 0,
        lambda: Double = BanditConstants.defaultLambda
    ) -> Double {
        let satisfaction: Double
        let overexertion: Double

        switch outcome {
        case .completed(let feel):
            switch feel {
            case .lovedIt:
                satisfaction = satisfactionLovedIt
                overexertion = consecutiveHardDays >= 2
                    ? Double(consecutiveHardDays - 1) * overexertionConsecutiveHardScale
                    : 0.0
            case .fine, .none:
                satisfaction = satisfactionFine
                overexertion = consecutiveHardDays >= 2
                    ? Double(consecutiveHardDays - 1) * overexertionConsecutiveHardScale
                    : 0.0
            case .tooMuch:
                satisfaction = 0.0
                overexertion = overexertionTooMuch + (consecutiveHardDays >= 1
                    ? Double(consecutiveHardDays) * overexertionConsecutiveHardScale
                    : 0.0)
            }
        case .swappedAway:
            satisfaction = satisfactionSwapped
            overexertion = 0.0
        case .skipped:
            satisfaction = satisfactionSkipped
            overexertion = 0.0
        }

        return satisfaction - (lambda * overexertion)
    }
}

// MARK: - Feature Representation Vector

nonisolated struct BanditFeatures: Sendable {
    /// Extracts a normalized, bounded feature vector x in R^d for the candidate session in context.
    /// Features:
    /// 0: Bias / intercept (1.0)
    /// 1: Duration fit closeness to target budget [0, 1]
    /// 2: Intensity match with check-in energy [-1, 1]
    /// 3: Energy fit alignment (+1 if in energyFit, -0.5 otherwise)
    /// 4: Restorative / recovery need match [-1, 1]
    /// 5: Recent movement density in past 7 days [0, 1]
    /// 6: Time of day alignment (1 if matches bestTimeOfDay, 0 otherwise)
    /// 7: Equipment simplicity (1.0 for none, 0.5 for mat, 0.0 for full equipment)
    static func extract(
        for session: Session,
        profile: PlanProfile,
        checkIn: PlanCheckIn,
        stats: HistoryStats,
        context: PlanContext
    ) -> [Double] {
        var x = Array(repeating: 0.0, count: BanditConstants.dimension)

        // 0: Intercept
        x[0] = 1.0

        // 1: Duration closeness
        let target = max(10, min(checkIn.time.maxMinutes, profile.realisticMinutes))
        let durationDiff = abs(Double(session.durationMin - target)) / Double(max(10, target))
        x[1] = max(0.0, 1.0 - min(1.0, durationDiff))

        // 2: Intensity match
        switch checkIn.energy {
        case .low:
            x[2] = max(0.0, 1.0 - Double(max(0, session.intensity - 2)) * 0.5)
        case .steady:
            x[2] = max(0.0, 1.0 - min(1.0, abs(Double(session.intensity) - 3.0) / 2.0))
        case .strong:
            x[2] = Double(session.intensity - 1) / 4.0
        }

        // 3: Energy fit
        x[3] = session.energyFit.contains(checkIn.energy) ? 1.0 : 0.0

        // 4: Restorative / recovery alignment
        let needsRest = stats.recoveryOwed
            || checkIn.bodies.contains(.sore)
            || checkIn.bodies.contains(.stiff)
            || checkIn.bodies.contains(.stressed)
        if needsRest {
            x[4] = session.intensity <= 2 ? 1.0 : 0.0
        } else {
            x[4] = session.intensity <= 3 ? 0.5 : 0.0
        }

        // 5: Recent movement density
        x[5] = min(1.0, Double(stats.completedThisWeek) / 7.0)

        // 6: Time of day
        let currentHour = context.calendar.component(.hour, from: context.now)
        let currentTimeOfDay = TimeOfDay(hour: currentHour)
        x[6] = (profile.bestTimeOfDay == currentTimeOfDay || profile.bestTimeOfDay == .varies) ? 1.0 : 0.0

        // 7: Equipment simplicity
        if session.needsNoEquipment {
            x[7] = 1.0
        } else if session.equipment.contains(.mat) && session.equipment.count <= 2 {
            x[7] = 0.5
        } else {
            x[7] = 0.0
        }

        return x
    }
}

// MARK: - LinUCB Arm State (Sherman-Morrison)

/// Maintains inverse covariance matrix M = A^{-1} and bias vector b for an activity arm.
nonisolated struct BanditArmState: Codable, Hashable, Sendable {
    /// Inverse covariance matrix M in R^{d x d}, initialized to I_d (ridge parameter = 1.0).
    var invCovariance: [[Double]]
    /// Bias vector b in R^d, initialized to 0.
    var biasVector: [Double]
    /// Number of observations / pulls recorded for this arm.
    var pullCount: Int

    init(dimension: Int = BanditConstants.dimension) {
        var m = Array(repeating: Array(repeating: 0.0, count: dimension), count: dimension)
        for i in 0..<dimension {
            m[i][i] = 1.0
        }
        self.invCovariance = m
        self.biasVector = Array(repeating: 0.0, count: dimension)
        self.pullCount = 0
    }

    /// Parameter vector theta = M * b.
    var theta: [Double] {
        let d = biasVector.count
        var result = Array(repeating: 0.0, count: d)
        for i in 0..<d {
            var sum = 0.0
            for j in 0..<d {
                sum += invCovariance[i][j] * biasVector[j]
            }
            result[i] = sum
        }
        return result
    }

    /// Predicts expected reward theta^T x and exploration bonus alpha * sqrt(x^T M x).
    func predict(x: [Double], alpha: Double) -> (predictedReward: Double, explorationBonus: Double) {
        let d = x.count
        guard d == biasVector.count else { return (0.0, 0.0) }

        // Compute v = M * x
        var v = Array(repeating: 0.0, count: d)
        for i in 0..<d {
            var sum = 0.0
            for j in 0..<d {
                sum += invCovariance[i][j] * x[j]
            }
            v[i] = sum
        }

        // Predicted reward = theta^T x = b^T (M x) = b^T v
        var mean = 0.0
        for i in 0..<d {
            mean += biasVector[i] * v[i]
        }

        // Variance = x^T M x = x^T v
        var variance = 0.0
        for i in 0..<d {
            variance += x[i] * v[i]
        }

        let bonus = alpha * sqrt(max(0.0, variance))
        return (mean, bonus)
    }

    /// Updates M and b using the Sherman-Morrison rank-1 formula for (A + x x^T)^{-1}.
    mutating func update(x: [Double], reward: Double) {
        let d = x.count
        guard d == biasVector.count else { return }

        // v = M * x
        var v = Array(repeating: 0.0, count: d)
        for i in 0..<d {
            var sum = 0.0
            for j in 0..<d {
                sum += invCovariance[i][j] * x[j]
            }
            v[i] = sum
        }

        // c = 1 + x^T v
        var c = 1.0
        for i in 0..<d {
            c += x[i] * v[i]
        }

        guard abs(c) > 1e-9 else { return }

        // M <- M - (v v^T) / c
        for i in 0..<d {
            for j in 0..<d {
                invCovariance[i][j] -= (v[i] * v[j]) / c
            }
        }

        // b <- b + r * x
        for i in 0..<d {
            biasVector[i] += reward * x[i]
        }

        pullCount += 1
    }
}

// MARK: - Bandit State

/// Model state holding arm data per activity and global prior.
nonisolated struct BanditState: Codable, Hashable, Sendable {
    var arms: [String: BanditArmState]
    var globalPrior: BanditArmState

    init() {
        self.arms = [:]
        self.globalPrior = BanditArmState()
    }

    func arm(for activity: Activity) -> BanditArmState {
        arms[activity.rawValue] ?? globalPrior
    }
}

// MARK: - Coarsened Preferences for Edge Alignment

/// Coarsened, privacy-preserving preferences passed to the Cloudflare Edge Worker.
nonisolated struct BanditCoarsenedPreferences: Codable, Hashable, Sendable {
    var preferredIntensityTier: String? // "gentle", "moderate", "dynamic"
    var topExploredActivities: [String]?
    var fatigueSensitivity: Double? // 0.0 to 1.0
}

// MARK: - Bandit Engine (Pure API)

nonisolated struct BanditEngine: Sendable {

    /// Computes the bandit recommendation score for a candidate session.
    static func predictScore(
        for session: Session,
        profile: PlanProfile,
        checkIn: PlanCheckIn,
        stats: HistoryStats,
        context: PlanContext,
        state: BanditState,
        alpha: Double = BanditConstants.defaultAlpha
    ) -> Double {
        let x = BanditFeatures.extract(
            for: session,
            profile: profile,
            checkIn: checkIn,
            stats: stats,
            context: context
        )
        let arm = state.arm(for: session.activity)
        let (mean, bonus) = arm.predict(x: x, alpha: alpha)
        return mean + bonus
    }

    /// Updates the bandit state following an observed session outcome.
    static func update(
        state: BanditState,
        session: Session,
        outcome: HistoryOutcome,
        profile: PlanProfile,
        checkIn: PlanCheckIn,
        stats: HistoryStats,
        context: PlanContext,
        consecutiveHardDays: Int = 0,
        lambda: Double = BanditConstants.defaultLambda
    ) -> BanditState {
        // Skipped sessions are neutral: guilt-free absence philosophy (R = 0, no negative weight swing).
        let reward = BanditReward.calculate(
            session: session,
            outcome: outcome,
            consecutiveHardDays: consecutiveHardDays,
            lambda: lambda
        )

        let x = BanditFeatures.extract(
            for: session,
            profile: profile,
            checkIn: checkIn,
            stats: stats,
            context: context
        )

        var newState = state
        var arm = newState.arm(for: session.activity)
        arm.update(x: x, reward: reward)
        newState.arms[session.activity.rawValue] = arm

        // Also gently update the global prior so all cold-start arms benefit from cross-activity learning.
        newState.globalPrior.update(x: x, reward: reward * 0.25)

        return newState
    }

    /// Derives coarsened preference tiers for synchronization with the edge companion.
    static func coarsenedPreferences(from state: BanditState) -> BanditCoarsenedPreferences {
        // Top explored activities by observation count
        let sortedActivities = state.arms
            .filter { $0.value.pullCount > 0 }
            .sorted { $0.value.pullCount > $1.value.pullCount }
            .map(\.key)

        let topActivities = sortedActivities.isEmpty ? nil : Array(sortedActivities.prefix(3))

        // Preferred intensity tier based on intensity feature weights (index 2) across active arms
        var totalIntensityWeight = 0.0
        var activeCount = 0
        for arm in state.arms.values where arm.pullCount > 0 {
            let theta = arm.theta
            if theta.count > 2 {
                totalIntensityWeight += theta[2]
                activeCount += 1
            }
        }

        let preferredTier: String?
        if activeCount > 0 {
            let avgIntensityCoeff = totalIntensityWeight / Double(activeCount)
            if avgIntensityCoeff > 0.4 {
                preferredTier = "dynamic"
            } else if avgIntensityCoeff < -0.2 {
                preferredTier = "gentle"
            } else {
                preferredTier = "moderate"
            }
        } else {
            preferredTier = nil
        }

        // Fatigue sensitivity based on recovery feature weight (index 4)
        var totalRecoveryWeight = 0.0
        for arm in state.arms.values where arm.pullCount > 0 {
            let theta = arm.theta
            if theta.count > 4 {
                totalRecoveryWeight += theta[4]
            }
        }
        let fatigueSensitivity: Double?
        if activeCount > 0 {
            let normalized = min(1.0, max(0.0, (totalRecoveryWeight / Double(activeCount) + 1.0) / 2.0))
            fatigueSensitivity = (normalized * 100).rounded() / 100
        } else {
            fatigueSensitivity = nil
        }

        return BanditCoarsenedPreferences(
            preferredIntensityTier: preferredTier,
            topExploredActivities: topActivities,
            fatigueSensitivity: fatigueSensitivity
        )
    }
}
