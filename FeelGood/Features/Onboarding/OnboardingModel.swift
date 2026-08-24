//
//  OnboardingModel.swift
//  FeelGood
//
//  Six cards, ninety seconds, framed around what's available to you rather than
//  around goals-as-metrics. No account, no email, no paywall — the first menu
//  appears before anything is asked for. See PRD §7.1.
//

import Foundation
import Observation

@Observable
final class OnboardingModel {

    enum Card: Int, CaseIterable {
        case access, cadence, time, timeOfDay, intent, workArounds

        var title: String {
            switch self {
            case .access: "What do you have access to?"
            case .cadence: "How often do you want to move?"
            case .time: "On a normal day, how much time is realistic?"
            case .timeOfDay: "When do you have the most in you?"
            case .intent: "What are you moving toward?"
            case .workArounds: "Anything to work around?"
            }
        }

        var detail: String? {
            switch self {
            case .access: "Pick everything that's genuinely available. This shapes everything else."
            case .cadence: "Used to keep things balanced — never to grade you."
            case .time: nil
            case .timeOfDay: nil
            case .intent: "Pick one."
            case .workArounds: "We'll quietly leave these out. Nothing here is a diagnosis."
            }
        }

        /// Only the first card must be answered — everything else has a sane
        /// default, because a menu is better than an interrogation.
        var isRequired: Bool { self == .access }
    }

    private(set) var card: Card = .access

    /// The answers themselves live in one value so the same six questions can
    /// be asked again later from the profile screen. See `ProfileAnswers`.
    var answers = ProfileAnswers()

    var activities: Set<Activity> {
        get { answers.activities }
        set { answers.activities = newValue }
    }
    var equipment: Set<Equipment> {
        get { answers.equipment }
        set { answers.equipment = newValue }
    }
    var places: Set<Place> {
        get { answers.places }
        set { answers.places = newValue }
    }
    var cadence: Cadence {
        get { answers.cadence }
        set { answers.cadence = newValue }
    }
    var moments: MovementMoments {
        get { answers.moments }
        set { answers.moments = newValue }
    }
    var realisticMinutes: Int {
        get { answers.realisticMinutes }
        set { answers.realisticMinutes = newValue }
    }
    var timeOfDay: TimeOfDay {
        get { answers.bestTimeOfDay }
        set { answers.bestTimeOfDay = newValue }
    }
    var intent: Intent {
        get { answers.intent }
        set { answers.intent = newValue }
    }
    var workArounds: Set<WorkAround> {
        get { answers.workArounds }
        set { answers.workArounds = newValue }
    }

    var isFirstCard: Bool { card == .access }
    var isLastCard: Bool { card == .workArounds }

    var canAdvance: Bool {
        card.isRequired ? answers.isAnswered : true
    }

    var progress: Double {
        Double(card.rawValue + 1) / Double(Card.allCases.count)
    }

    func advance() {
        guard let next = Card(rawValue: card.rawValue + 1) else { return }
        card = next
    }

    func goBack() {
        guard let previous = Card(rawValue: card.rawValue - 1) else { return }
        card = previous
    }

    func makeProfile() -> PlanProfile { answers.planProfile }

    func makeRecord(now: Date) -> UserProfile { UserProfile(answers: answers, now: now) }
}

// MARK: - Answer labels

nonisolated extension Cadence {
    var label: String {
        switch self {
        case .everyDay: "Every day"
        case .mostDays: "Most days"
        case .fewTimesAWeek: "A few times a week"
        case .whenICan: "When I can"
        }
    }
}

nonisolated extension TimeOfDay {
    var label: String {
        switch self {
        case .morning: "Morning"
        case .midday: "Midday"
        case .evening: "Evening"
        case .varies: "It varies"
        }
    }
}

nonisolated extension Place {
    var label: String {
        switch self {
        case .home: "At home"
        case .outdoors: "Outdoors"
        case .gym: "A gym"
        case .studio: "A studio or class"
        case .pool: "A pool"
        }
    }
}

nonisolated extension MovementMoments {
    var label: String {
        switch self {
        case .once: "Once, properly"
        case .aCouple: "A couple of times"
        case .sprinkled: "Sprinkled through the day"
        }
    }
}

nonisolated extension Intent {
    var label: String {
        switch self {
        case .energize: "Energy"
        case .strengthen: "Strength"
        case .calm: "Calm"
        case .mobilize: "Mobility"
        case .joy: "Just showing up"
        }
    }
}

nonisolated extension WorkAround {
    /// Plain words, no clinical register. These filter; they never diagnose.
    var label: String {
        switch self {
        case .lowBack: "Lower back"
        case .knees: "Knees"
        case .wrists: "Wrists"
        case .pregnancy: "Pregnant"
        case .postpartum: "Postpartum"
        case .pelvicFloor: "Pelvic floor"
        case .fatigue: "Low energy or fatigue"
        }
    }
}
