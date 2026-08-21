//
//  Display.swift
//  FeelGood
//
//  How the vocabulary is spoken to her. The taxonomy stays behind the glass —
//  she sees a menu, never a data model.
//

import Foundation

extension Course {
    /// The menu metaphor is user-facing; the rest of the schema is not.
    var label: String {
        switch self {
        case .appetizer: "Appetizer"
        case .main: "Main"
        case .side: "Side"
        case .dessert: "Dessert"
        case .special: "Special"
        }
    }
}

extension Activity {
    var label: String {
        switch self {
        case .pilates: "Pilates"
        case .yoga: "Yoga"
        case .qigong: "Qi gong"
        case .strength: "Strength"
        case .stretching: "Stretching"
        case .walking: "Walking"
        case .biking: "Biking"
        case .swimming: "Swimming"
        case .skating: "Skating"
        case .dance: "Dance"
        case .jumpRope: "Jump rope"
        case .agility: "Footwork"
        case .carries: "Carries"
        case .racquet: "Racquet"
        case .climbing: "Climbing"
        case .martialArts: "Martial arts"
        case .breathwork: "Breathwork"
        }
    }
}

extension Equipment {
    /// `nil` for things that aren't worth saying out loud.
    var label: String? {
        switch self {
        case .none: nil
        case .mat: "Mat"
        case .weights: "Weights"
        case .band: "Band"
        case .rope: "Rope"
        case .bike: "Bike"
        case .pool: "Pool"
        case .skates: "Skates"
        case .outdoor: "Outside"
        case .reformer: "Reformer"
        }
    }
}

extension Session {
    var durationLabel: String { "\(durationMin) min" }

    /// "Mat · 20 min" — what she needs and how long, nothing else.
    var chips: [String] {
        equipment.compactMap(\.label) + [durationLabel]
    }
}

extension Energy {
    var checkInLabel: String {
        switch self {
        case .low: "Running on empty"
        case .steady: "Steady"
        case .strong: "Strong"
        }
    }
}

extension TimeBudget {
    var checkInLabel: String {
        switch self {
        case .aLittle: "A little"
        case .some: "Some"
        case .plenty: "Plenty"
        }
    }

    var checkInDetail: String {
        switch self {
        case .aLittle: "10 minutes or so"
        case .some: "20 to 30"
        case .plenty: "45 or more"
        }
    }
}

extension BodyState {
    var checkInLabel: String {
        switch self {
        case .sore: "Sore"
        case .stiff: "Stiff"
        case .stressed: "Stressed"
        case .cramping: "Cramping"
        case .good: "Good"
        }
    }
}
