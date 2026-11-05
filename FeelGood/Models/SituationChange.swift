//
//  SituationChange.swift
//  FeelGood
//
//  "Something changed." A faster way to adjust the profile than the full
//  preferences form: pick what changed, say whether it is for now or for
//  good, and today's menu follows. Pure value types, so the rules are tested
//  without a screen.
//

import Foundation

nonisolated enum SituationChange: Hashable, Sendable {
    /// Something hurts. The chosen areas join "anything to work around".
    case pain(Set<WorkAround>)
    /// Short on time or energy: shorter sessions, gentler ones.
    case lessCapacity
    /// A different direction. Replaces what the person is moving toward.
    case newGoal(Set<Intent>)

    /// The body areas offered when something hurts.
    static let painAreas: [WorkAround] = [.lowBack, .knees, .wrists, .neckShoulders, .hips]

    /// Minutes a session may run while energy or time is short.
    static let reducedMinutes = 10
    /// How long a temporary change lasts before we ask whether to go back.
    static let temporaryDays = 14

    /// A change with nothing chosen does nothing, so the screen keeps its
    /// button disabled until this is true.
    var isValid: Bool {
        switch self {
        case .pain(let areas): !areas.isEmpty
        case .lessCapacity: true
        case .newGoal(let intents): !intents.isEmpty
        }
    }

    func applied(to answers: ProfileAnswers) -> ProfileAnswers {
        var updated = answers
        switch self {
        case .pain(let areas):
            updated.workArounds.formUnion(areas.intersection(Set(Self.painAreas)))
        case .lessCapacity:
            updated.realisticMinutes = min(answers.realisticMinutes, Self.reducedMinutes)
            updated.workArounds.insert(.fatigue)
        case .newGoal(let intents):
            updated.intents = intents
        }
        return updated
    }

    var analyticsName: String {
        switch self {
        case .pain: "pain"
        case .lessCapacity: "less_capacity"
        case .newGoal: "new_goal"
        }
    }
}

/// What a temporary change overwrote, so it can be put back. Records only
/// the fields the change touched: anything the person edited elsewhere in
/// the meantime is left alone.
nonisolated struct AdjustmentRevert: Codable, Hashable, Sendable {
    var workArounds: [String]?
    var realisticMinutes: Int?
    var intents: [String]?

    init(workArounds: [String]? = nil, realisticMinutes: Int? = nil, intents: [String]? = nil) {
        self.workArounds = workArounds
        self.realisticMinutes = realisticMinutes
        self.intents = intents
    }

    /// The values `change` is about to overwrite.
    init(before answers: ProfileAnswers, change: SituationChange) {
        switch change {
        case .pain:
            self.init(workArounds: answers.workArounds.map(\.rawValue).sorted())
        case .lessCapacity:
            self.init(
                workArounds: answers.workArounds.map(\.rawValue).sorted(),
                realisticMinutes: answers.realisticMinutes
            )
        case .newGoal:
            self.init(intents: answers.intents.map(\.rawValue).sorted())
        }
    }

    /// A second temporary change before the first has been answered keeps
    /// the original values: going back means going back to before either.
    func merging(_ newer: AdjustmentRevert) -> AdjustmentRevert {
        AdjustmentRevert(
            workArounds: workArounds ?? newer.workArounds,
            realisticMinutes: realisticMinutes ?? newer.realisticMinutes,
            intents: intents ?? newer.intents
        )
    }

    /// A permanent change owns the fields it touched, so an older pending
    /// revert must stop restoring them. `nil` when nothing is left to restore.
    func dropping(fieldsTouchedBy change: SituationChange) -> AdjustmentRevert? {
        var kept = self
        switch change {
        case .pain:
            kept.workArounds = nil
        case .lessCapacity:
            kept.workArounds = nil
            kept.realisticMinutes = nil
        case .newGoal:
            kept.intents = nil
        }
        return kept == AdjustmentRevert() ? nil : kept
    }

    func restoring(into answers: ProfileAnswers) -> ProfileAnswers {
        var updated = answers
        if let workArounds {
            updated.workArounds = Set(workArounds.compactMap(WorkAround.init(rawValue:)))
        }
        if let realisticMinutes {
            updated.realisticMinutes = realisticMinutes
        }
        if let intents {
            let restored = Set(intents.compactMap(Intent.init(rawValue:)))
            if !restored.isEmpty { updated.intents = restored }
        }
        return updated
    }

    func encoded() -> Data? { try? JSONEncoder().encode(self) }

    static func decode(_ data: Data?) -> AdjustmentRevert? {
        guard let data else { return nil }
        return try? JSONDecoder().decode(AdjustmentRevert.self, from: data)
    }
}
