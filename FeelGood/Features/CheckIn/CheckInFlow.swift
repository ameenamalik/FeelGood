//
//  CheckInFlow.swift
//  FeelGood
//
//  The goal-led check-in as a value: which screen is showing, what has been
//  said, and what that hands the engine. Kept out of the view so the rules
//  that decide where a tap goes have tests rather than a careful reading of a
//  view body.
//
//  Three taps: a goal, one of that goal's answers, a length. Just showing up
//  answers the length itself, so it is two.
//

import Foundation

nonisolated struct CheckInFlow: Hashable, Sendable {

    enum Step: Int, Hashable, Sendable, CaseIterable {
        case goal, answer, time
    }

    private(set) var step: Step = .goal
    private(set) var goal: Intent?
    private(set) var answer: CheckInAnswer?
    private(set) var time: TimeBudget?
    var place: PlaceIntent?
    var bodies: Set<BodyState> = []

    init(place: PlaceIntent? = nil, bodies: Set<BodyState> = []) {
        self.place = place
        self.bodies = bodies
    }

    /// Picking a different goal clears the answer given under the old one:
    /// "Legs" means something else to Strength than to Mobility.
    mutating func choose(goal: Intent) {
        if goal != self.goal {
            answer = nil
        }
        time = nil
        self.goal = goal
        step = .answer
    }

    /// Answers from another goal's list are refused rather than mixed in.
    mutating func choose(answer: CheckInAnswer) {
        guard let goal, goal.checkInAnswers.contains(answer) else { return }
        self.answer = answer
        time = nil
        if goal.asksForTime {
            step = .time
        } else {
            time = answer.time
        }
    }

    mutating func choose(time: TimeBudget) {
        guard answer != nil, goal?.asksForTime == true else { return }
        self.time = time
    }

    /// One screen back. The answers stay, so going back to look is free.
    mutating func goBack() {
        guard let previous = Step(rawValue: step.rawValue - 1) else { return }
        step = previous
        time = nil
    }

    var isComplete: Bool { checkIn != nil }

    /// How full the fruit is: a third per question answered.
    var fillFraction: Double {
        if isComplete { return 1 }
        if answer != nil { return 2.0 / 3.0 }
        if goal != nil { return 1.0 / 3.0 }
        return 0
    }

    /// What the engine gets, once there is enough to build a menu from.
    var checkIn: PlanCheckIn? {
        guard let goal, let answer, let time else { return nil }
        var result = PlanCheckIn(
            energy: answer.energy,
            time: time,
            place: place,
            bodies: bodies,
            todayIntent: goal
        )
        result.focus = answer.focus
        result.favoured = answer.favoured
        return result
    }
}

nonisolated extension CheckInFlow {
    /// Your onboarding goals first, the rest after, both in the order
    /// onboarding shows them. Nothing picked means nothing leads.
    static func orderedGoals(standing: Set<Intent>) -> (picks: [Intent], others: [Intent]) {
        let picks = Intent.allCases.filter(standing.contains)
        let others = Intent.allCases.filter { !standing.contains($0) }
        return picks.count == Intent.allCases.count ? ([], picks) : (picks, others)
    }
}
