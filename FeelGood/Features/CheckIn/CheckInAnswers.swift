//
//  CheckInAnswers.swift
//  FeelGood
//
//  The goal-led check-in: how you want to feel, what kind of that, how long.
//  Each goal asks its own second question with six answers, and every answer
//  is something a person would say about themselves rather than a rating.
//
//  An answer carries what it means to the engine: an energy level (derived,
//  so nobody is asked to score themselves), an optional body area, and the
//  activities it leans toward. The last two are scoring nudges only — see
//  `PlanWeights.focusMatch` — so no answer can empty the menu.
//
//  See docs/design/checkin-flows-brief.md.
//

import Foundation

nonisolated struct CheckInAnswer: Hashable, Sendable, Identifiable {
    let id: String
    let title: String
    let detail: String
    let energy: Energy
    var focus: BodyFocus? = nil
    var favoured: Set<Activity> = []
    var systemImage: String? = nil
    /// Set only where the answer already says how long ("Two minutes"), which
    /// is what lets Just showing up skip the time question.
    var time: TimeBudget? = nil
}

nonisolated extension Intent {

    /// How the goal reads as a feeling on the first screen.
    var checkInFeeling: String {
        switch self {
        case .energize: "Energised"
        case .strengthen: "Strong"
        case .calm: "Calm"
        case .mobilize: "Mobile"
        case .joy: "Like I showed up"
        case .play: "Playful"
        }
    }

    var checkInQuestion: String {
        switch self {
        case .energize: "What kind of energy?"
        case .strengthen: "Where do you want to feel strong?"
        case .calm: "What kind of calm?"
        case .mobilize: "Where do you want more room?"
        case .joy: "What would count today?"
        case .play: "What kind of play?"
        }
    }

    /// Whether the time question follows. Every goal allows the user to choose their time budget.
    var asksForTime: Bool { true }

    var checkInAnswers: [CheckInAnswer] {
        switch self {
        case .energize: [
            CheckInAnswer(id: "energy.gentlyAwake", title: "Gently awake", detail: "Easing into the day", energy: .low, favoured: [.walking, .qigong], systemImage: "sunrise"),
            CheckInAnswer(id: "energy.clearHeaded", title: "Clear-headed", detail: "Fresh air and a bit of pace", energy: .steady, favoured: [.walking, .running], systemImage: "wind"),
            CheckInAnswer(id: "energy.buzzing", title: "Buzzing", detail: "Heart up, music on", energy: .strong, favoured: [.jumpRope, .dance, .agility], systemImage: "bolt"),
            CheckInAnswer(id: "energy.warmAllOver", title: "Warm all over", detail: "Everything moving a little", energy: .steady, focus: .full, favoured: [.stretching, .strength], systemImage: "sun.max"),
            CheckInAnswer(id: "energy.outOfASlump", title: "Out of a slump", detail: "Something short to shift it", energy: .low, favoured: [.qigong, .agility], systemImage: "sparkles"),
            CheckInAnswer(id: "energy.bigDay", title: "Ready for a big day", detail: "A proper start", energy: .strong, favoured: [.running, .walking], systemImage: "flag"),
        ]
        case .strengthen: [
            CheckInAnswer(id: "strength.legs", title: "Legs", detail: "Squats, lunges, stairs", energy: .steady, focus: .lowerBody, favoured: [.strength], systemImage: "figure.walk"),
            CheckInAnswer(id: "strength.middle", title: "Middle", detail: "Core, slow and steady", energy: .steady, focus: .core, favoured: [.pilates, .strength], systemImage: "figure.core.training"),
            CheckInAnswer(id: "strength.arms", title: "Arms & shoulders", detail: "Push, pull, press", energy: .steady, focus: .upperBody, favoured: [.strength, .carries], systemImage: "figure.strengthtraining.traditional"),
            CheckInAnswer(id: "strength.allOver", title: "All over", detail: "A bit of everything", energy: .steady, focus: .full, favoured: [.strength], systemImage: "figure.mixed.cardio"),
            CheckInAnswer(id: "strength.kind", title: "Strong but kind", detail: "Nothing too heavy today", energy: .low, focus: .core, favoured: [.pilates, .strength], systemImage: "heart"),
            CheckInAnswer(id: "strength.properlyWorked", title: "Properly worked", detail: "The full effort", energy: .strong, focus: .full, favoured: [.strength, .carries], systemImage: "flame"),
        ]
        case .calm: [
            CheckInAnswer(id: "calm.quietHead", title: "A quiet head", detail: "Just breathing", energy: .low, favoured: [.breathwork], systemImage: "wind"),
            CheckInAnswer(id: "calm.unwound", title: "Unwind", detail: "Slow stretches on the floor", energy: .low, favoured: [.yoga, .stretching], systemImage: "figure.flexibility"),
            CheckInAnswer(id: "calm.sleep", title: "Ready for sleep", detail: "Soft and slow, lights down", energy: .low, favoured: [.yoga, .breathwork, .stretching], systemImage: "moon.stars"),
            CheckInAnswer(id: "calm.grounded", title: "Grounded", detail: "Outside, feet on the ground", energy: .steady, favoured: [.walking, .qigong], systemImage: "leaf"),
            CheckInAnswer(id: "calm.softShoulders", title: "Soft shoulders", detail: "Neck and shoulders let go", energy: .low, focus: .neckShoulders, favoured: [.stretching, .yoga], systemImage: "figure.mind.and.body"),
            CheckInAnswer(id: "calm.backInMyBody", title: "Back in my body", detail: "Shake it out, then settle", energy: .steady, favoured: [.qigong, .breathwork], systemImage: "figure.cooldown"),
        ]
        case .mobilize: [
            CheckInAnswer(id: "mobility.hips", title: "Hips", detail: "After a long sit", energy: .steady, focus: .hips, favoured: [.stretching, .yoga], systemImage: "figure.flexibility"),
            CheckInAnswer(id: "mobility.back", title: "Back", detail: "Spine, twists, reaches", energy: .steady, focus: .back, favoured: [.stretching, .yoga, .pilates], systemImage: "figure.cooldown"),
            CheckInAnswer(id: "mobility.neck", title: "Neck & shoulders", detail: "Screen-day stiffness", energy: .steady, focus: .neckShoulders, favoured: [.stretching], systemImage: "figure.mind.and.body"),
            CheckInAnswer(id: "mobility.legs", title: "Legs", detail: "Hamstrings, calves, ankles", energy: .steady, focus: .lowerBody, favoured: [.stretching], systemImage: "figure.walk"),
            CheckInAnswer(id: "mobility.wrists", title: "Wrists & hands", detail: "For after typing", energy: .low, focus: .upperBody, favoured: [.stretching], systemImage: "hand.raised"),
            CheckInAnswer(id: "mobility.headToToe", title: "Head to toe", detail: "A bit of everything", energy: .steady, focus: .full, favoured: [.stretching, .yoga], systemImage: "figure.arms.open"),
        ]
        case .joy: [
            CheckInAnswer(id: "showingUp.twoMinutes", title: "Two minutes", detail: "Tiny still counts", energy: .low, favoured: [.breathwork, .qigong], systemImage: "timer"),
            CheckInAnswer(id: "showingUp.withoutThinking", title: "Without thinking", detail: "Just tell me what to do", energy: .low, systemImage: "arrow.right.circle"),
            CheckInAnswer(id: "showingUp.lyingDown", title: "Lying down", detail: "Bed or floor is fine", energy: .low, favoured: [.yoga, .stretching], systemImage: "bed.double"),
            CheckInAnswer(id: "showingUp.freshAir", title: "Some fresh air", detail: "Step outside", energy: .low, favoured: [.walking], systemImage: "sun.and.horizon"),
            CheckInAnswer(id: "showingUp.alongside", title: "While I do something else", detail: "Kettle, teeth, a call", energy: .low, favoured: [.stretching, .walking], systemImage: "cup.and.saucer"),
            CheckInAnswer(id: "showingUp.youPick", title: "You pick", detail: "Surprise me", energy: .steady, systemImage: "sparkles"),
        ]
        case .play: [
            CheckInAnswer(id: "play.dance", title: "Dance it out", detail: "Music on, no rules", energy: .steady, favoured: [.dance], systemImage: "music.note"),
            CheckInAnswer(id: "play.bouncy", title: "Something bouncy", detail: "Jump, hop, skip", energy: .strong, favoured: [.jumpRope, .skating], systemImage: "figure.jumprope"),
            CheckInAnswer(id: "play.exploreOutside", title: "Explore outside", detail: "A new route, a skate", energy: .steady, favoured: [.walking, .skating, .biking], systemImage: "binoculars"),
            CheckInAnswer(id: "play.quickFeet", title: "Quick feet", detail: "Fast and a bit silly", energy: .strong, favoured: [.agility], systemImage: "shoeprints.fill"),
            CheckInAnswer(id: "play.withSomeone", title: "With someone", detail: "A game or a class", energy: .steady, favoured: [.racquet], systemImage: "person.2"),
            CheckInAnswer(id: "play.surprise", title: "Surprise me", detail: "Something I wouldn't pick", energy: .steady, systemImage: "dice"),
        ]
        }
    }
}

nonisolated extension TimeBudget {
    /// The lengths the check-in offers, shortest first. Resting sits apart.
    static let checkInChoices: [TimeBudget] = [
        .fiveMinutes, .aLittle, .fifteenMinutes, .twentyMinutes, .some, .fortyFiveMinutes, .plenty,
    ]

    var checkInChipLabel: String {
        switch self {
        case .zeroMinutes: "Resting today"
        case .fiveMinutes: "5 min"
        case .plenty: "An hour"
        default: "\(maxMinutes)"
        }
    }
}
