//
//  OnboardingModel.swift
//  FeelGood
//
//  Three cards, ninety seconds, framed around what's available to you rather than
//  around goals-as-metrics. No account, no email, no paywall — the first menu
//  appears before anything is asked for. See PRD §7.1. Today's available time
//  belongs in the daily check-in, so onboarding does not ask for it again.
//

import Foundation
import Observation

@Observable
final class OnboardingModel {

    enum Card: Int, CaseIterable {
        case access, intent, workArounds

        var title: String {
            switch self {
            case .access: "What do you have access to?"
            case .intent: "What are you moving toward?"
            case .workArounds: "Anything to work around?"
            }
        }

        var detail: String? {
            switch self {
            case .access: nil
            case .intent: "Pick one or more."
            case .workArounds: nil
            }
        }

    }

    private(set) var card: Card = .access

    /// The answers themselves live in one value so the same six questions can
    /// be asked again later from the profile screen. See `ProfileAnswers`.
    var answers = ProfileAnswers()

    var activities: Set<Activity> {
        get { answers.activities }
        set { answers.activities = newValue }
    }
    var sports: Set<SportPreference> {
        get { answers.sports }
        set { answers.sports = newValue }
    }
    var equipment: Set<Equipment> {
        get { answers.equipment }
        set { answers.equipment = newValue }
    }
    var places: Set<Place> {
        get { answers.places }
        set { answers.places = newValue }
    }
    var realisticMinutes: Int {
        get { answers.realisticMinutes }
        set { answers.realisticMinutes = newValue }
    }
    var timeOfDay: TimeOfDay {
        get { answers.bestTimeOfDay }
        set { answers.bestTimeOfDay = newValue }
    }
    var intents: Set<Intent> {
        get { answers.intents }
        set { answers.intents = newValue }
    }
    var workArounds: Set<WorkAround> {
        get { answers.workArounds }
        set { answers.workArounds = newValue }
    }

    var isFirstCard: Bool { card == .access }
    var isLastCard: Bool { card == .workArounds }

    /// Slide one has three distinct inputs. Each needs an explicit answer so
    /// the menu does not infer access from a choice made in another section.
    var accessSectionsAreComplete: Bool {
        !activities.isEmpty && !equipment.isEmpty && !places.isEmpty
    }

    var canAdvance: Bool {
        switch card {
        case .access:
            accessSectionsAreComplete
        case .intent, .workArounds:
            true
        }
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
        case .fewTimesAWeek: "A few days"
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
        case .once: "Once"
        case .aCouple: "Twice"
        case .sprinkled: "Throughout"
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
        case .play: "Play"
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

// MARK: - Onboarding symbols

nonisolated extension Activity {
    var onboardingSymbol: String {
        switch self {
        case .pilates: "figure.pilates"
        case .yoga: "figure.yoga"
        case .qigong: "figure.mind.and.body"
        case .strength: "dumbbell"
        case .stretching: "figure.flexibility"
        case .walking: "figure.walk"
        case .biking: "bicycle"
        case .swimming: "figure.pool.swim"
        case .skating: "figure.skating"
        case .dance: "figure.dance"
        case .jumpRope: "figure.jumprope"
        case .agility: "figure.run"
        case .carries: "figure.strengthtraining.functional"
        case .racquet: "sportscourt"
        case .climbing: "figure.climbing"
        case .martialArts: "figure.martial.arts"
        case .breathwork: "wind"
        }
    }
}

nonisolated extension SportPreference {
    var onboardingSymbol: String { "sportscourt" }
}

nonisolated extension Equipment {
    var onboardingSymbol: String {
        switch self {
        case .none: "figure.stand"
        case .mat: "rectangle"
        case .weights: "dumbbell"
        case .band: "oval.portrait"
        case .rope: "figure.jumprope"
        case .bike: "bicycle"
        case .pool: "figure.pool.swim"
        case .skates: "figure.skating"
        case .outdoor: "tree"
        case .gym: "building.2"
        case .reformer: "figure.pilates"
        }
    }
}

nonisolated extension Place {
    var onboardingSymbol: String {
        switch self {
        case .home: "house"
        case .outdoors: "tree"
        case .gym: "dumbbell"
        case .studio: "person.3"
        case .pool: "figure.pool.swim"
        }
    }
}

nonisolated extension Cadence {
    var onboardingSymbol: String {
        switch self {
        case .everyDay: "calendar"
        case .mostDays: "calendar.badge.checkmark"
        case .fewTimesAWeek: "calendar.badge.clock"
        case .whenICan: "sparkles"
        }
    }
}

nonisolated extension MovementMoments {
    var onboardingSymbol: String {
        switch self {
        case .once: "1.circle"
        case .aCouple: "2.circle"
        case .sprinkled: "circle.grid.3x3"
        }
    }
}

nonisolated extension Intent {
    var onboardingSymbol: String {
        switch self {
        case .energize: "bolt"
        case .strengthen: "dumbbell"
        case .calm: "leaf"
        case .mobilize: "figure.flexibility"
        case .joy: "heart"
        case .play: "figure.dance"
        }
    }
}

nonisolated extension WorkAround {
    var onboardingSymbol: String {
        switch self {
        case .lowBack: "figure.core.training"
        case .knees: "figure.walk"
        case .wrists: "hand.raised"
        case .fatigue: "battery.25percent"
        case .pregnancy: "figure.and.child.holdinghands"
        case .postpartum: "figure.2.and.child.holdinghands"
        case .pelvicFloor: "figure.core.training"
        }
    }
}
