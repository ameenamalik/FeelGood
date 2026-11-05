//
//  OnboardingModel.swift
//  FeelGood
//
//  Five short cards, framed around what kind of support feels useful and what's available rather than
//  around goals-as-metrics. Still no paywall here — Pro stays out of onboarding
//  entirely, see PRD §10.1 — and these cards themselves ask nothing about
//  an account; that optional ask waits until the first completed session. See
//  PRD §7.1. Today's available time
//  belongs in the daily check-in, so onboarding does not ask for it again.
//

import Foundation
import Observation

@Observable
final class OnboardingModel {

    enum Card: Int, CaseIterable, Codable {
        case guidance, movement, equipment, intent, workArounds

        var title: String {
            switch self {
            case .guidance: "How can we support you?"
            case .movement: "What do you enjoy?"
            case .equipment: "What equipment do you have?"
            case .intent: "What would you like more of?"
            case .workArounds: "What should we be mindful of?"
            }
        }

        var detail: String? {
            switch self {
            case .guidance: "This helps us offer the right amount of guidance. Choose one."
            case .movement: "We’ll shape your options around these. Choose anything you enjoy or want to try."
            case .equipment: "We’ll suggest movement you can do with what you have. Choose any, or No equipment."
            case .intent: nil
            case .workArounds: "We’ll keep these needs in mind. Choose any that apply, or continue if none do."
            }
        }

    }

    private(set) var card: Card = .guidance {
        didSet { saveDraft() }
    }

    @ObservationIgnored private let draftURL: URL?

    /// Tests and profile previews stay in memory unless they opt into a draft URL.
    init(draftURL: URL? = nil) {
        self.draftURL = draftURL
        if let draftURL,
           let data = try? Data(contentsOf: draftURL),
           let draft = try? JSONDecoder().decode(Draft.self, from: data),
           draft.version == 1 {
            answers = draft.answers
            selectedGuidancePreference = draft.selectedGuidancePreference
            card = draft.card
        }
    }

    static var defaultDraftURL: URL {
        URL.applicationSupportDirectory
            .appendingPathComponent("FeelGood", isDirectory: true)
            .appendingPathComponent("onboarding-draft.json")
    }

    private struct Draft: Codable {
        var version = 1
        let card: Card
        let selectedGuidancePreference: GuidancePreference?
        let answers: ProfileAnswers
    }

    private func saveDraft() {
        guard let draftURL,
              let data = try? JSONEncoder().encode(Draft(
                card: card,
                selectedGuidancePreference: selectedGuidancePreference,
                answers: answers
              )) else { return }
        let directory = draftURL.deletingLastPathComponent()
        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            // Drafts contain the same private preferences as the finished
            // profile. Keep them on this device and protected while locked.
            try data.write(to: draftURL, options: [.atomic, .completeFileProtection])
            var protectedURL = draftURL
            var values = URLResourceValues()
            values.isExcludedFromBackup = true
            try protectedURL.setResourceValues(values)
        } catch {
            // A failed draft write must never block answering the next question.
            // Never log the draft or its free-text contents.
        }
    }

    func clearDraft() {
        guard let draftURL else { return }
        Self.removeSavedDraft(at: draftURL)
    }

    static func removeSavedDraft(at url: URL) {
        try? FileManager.default.removeItem(at: url)
    }

    /// `nil` until tapped so the first question never looks pre-answered.
    var selectedGuidancePreference: GuidancePreference? {
        didSet {
            if let selectedGuidancePreference {
                answers.guidancePreference = selectedGuidancePreference
            }
            saveDraft()
        }
    }

    /// Every answer change is saved immediately, including optional notes.
    var answers = ProfileAnswers() {
        didSet { saveDraft() }
    }

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
    var otherWorkAroundNote: String {
        get { answers.otherWorkAroundNote }
        set { answers.otherWorkAroundNote = newValue }
    }
    var otherMovementNote: String {
        get { answers.otherMovementNote }
        set { answers.otherMovementNote = newValue }
    }

    var isFirstCard: Bool { card == .guidance }
    var isLastCard: Bool { card == .workArounds }

    var canAdvance: Bool {
        switch card {
        case .guidance:
            selectedGuidancePreference != nil
        case .movement:
            !activities.isEmpty
        case .equipment:
            !equipment.isEmpty
        case .intent:
            !intents.isEmpty
        case .workArounds:
            true
        }
    }

    /// Makes disabled navigation explainable, including requirements below the fold.
    var selectionHint: String? {
        switch card {
        case .guidance:
            selectedGuidancePreference == nil ? "Choose one answer to continue." : nil
        case .movement:
            activities.isEmpty ? "Choose at least one movement to continue." : nil
        case .equipment:
            equipment.isEmpty ? "Choose equipment or No equipment to continue." : nil
        case .intent:
            intents.isEmpty ? "Choose at least one answer to continue." : nil
        case .workArounds:
            nil
        }
    }

    /// Short replies share the footer's existing instruction space.
    var acknowledgement: String? {
        switch card {
        case .guidance:
            switch selectedGuidancePreference {
            case .gettingStarted: "We’ll take it one step at a time."
            case .knowsWhatTheyEnjoy: "We’ll help you find what fits."
            case .hasOwnRoutine: "We’ll build around your routine."
            case nil: nil
            }
        case .movement:
            activities.isEmpty ? nil : "Got it—more of what you enjoy."
        case .equipment:
            if equipment.isEmpty {
                nil
            } else if equipment == [.none] {
                "You can start with just yourself."
            } else {
                "We’ll work with what you have."
            }
        case .intent:
            intents.isEmpty ? nil : "We’ll keep what matters to you in mind."
        case .workArounds:
            workArounds.isEmpty
                ? "You can update this whenever you need."
                : "Thanks—we’ll keep these needs in mind."
        }
    }

    var progress: Double {
        Double(card.rawValue + 1) / Double(Card.allCases.count)
    }

    func advance() {
        guard canAdvance else { return }
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

nonisolated extension GuidancePreference {
    var label: String {
        switch self {
        case .gettingStarted: "I’m getting started"
        case .knowsWhatTheyEnjoy: "I know what I enjoy"
        case .hasOwnRoutine: "I have my own routine"
        }
    }

    var detail: String {
        switch self {
        case .gettingStarted: "I’d like clear guidance."
        case .knowsWhatTheyEnjoy: "Help me narrow it down."
        case .hasOwnRoutine: "Suggest movement that complements it."
        }
    }

}

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
        case .neckShoulders: "Neck & shoulders"
        case .hips: "Hips"
        case .lowImpact: "No jumping"
        case .pregnancy: "Pregnant"
        case .postpartum: "Postpartum"
        case .pelvicFloor: "Pelvic floor"
        case .fatigue: "Low energy or fatigue"
        case .other: "Other"
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
        case .running: "figure.run"
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
        case .generalWellness: "leaf"
        case .other: "sparkles"
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
        case .neckShoulders: "figure.mind.and.body"
        case .hips: "figure.flexibility"
        case .lowImpact: "shoeprints.fill"
        case .fatigue: "battery.25percent"
        case .pregnancy: "figure.and.child.holdinghands"
        case .postpartum: "figure.2.and.child.holdinghands"
        case .pelvicFloor: "figure.core.training"
        case .other: "ellipsis.circle"
        }
    }
}

/// Readable, stable summaries of explicit choices, never inferred equipment or
/// daily check-in state. Kept separate from the view so the result is testable.
nonisolated struct OnboardingSummary {
    struct Row: Identifiable, Equatable {
        let id: String
        let title: String
        let symbol: String
        let value: String
    }

    let rows: [Row]

    init(answers: ProfileAnswers) {
        var movement: [String] = []
        for activity in Activity.allCases where answers.activities.contains(activity) {
            if activity == .racquet && !answers.sports.isEmpty {
                movement += SportPreference.allCases.filter { answers.sports.contains($0) }.map(\.label)
            } else {
                movement.append(activity.label)
            }
        }
        let equipment = Equipment.allCases.filter { answers.equipment.contains($0) }
            .map { $0.label ?? "No equipment" }
        let intentions = Intent.allCases.filter { answers.intents.contains($0) }.map(\.label)
        let needs = WorkAround.allCases.filter { answers.workArounds.contains($0) }.map(\.label)
        rows = [
            Row(id: "movement", title: "Movement you enjoy", symbol: "figure.walk", value: movement.joined(separator: ", ")),
            Row(id: "equipment", title: "What you have", symbol: "dumbbell", value: equipment.joined(separator: ", ")),
            Row(id: "intent", title: "What matters to you", symbol: "heart", value: intentions.joined(separator: ", ")),
            Row(id: "needs", title: "Needs to keep in mind", symbol: "hand.raised", value: needs.joined(separator: ", ")),
        ].filter { !$0.value.isEmpty }
    }
}
