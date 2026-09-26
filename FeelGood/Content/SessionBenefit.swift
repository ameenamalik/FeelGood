//
//  SessionBenefit.swift
//  FeelGood
//
//  The "Why this feels good" copy on a session's detail screen, built from
//  what the session actually is — what it is for, where in the body it
//  works, how long and how hard — rather than from its activity alone, which
//  gave every stretch in the catalog the same paragraph.
//
//  Says how it feels, never what it does to a body. No physiology, no
//  outcomes, nothing a clinician would have to sign off (CLAUDE.md voice).
//

import Foundation

nonisolated struct SessionBenefit: Equatable, Sendable {
    let headline: String
    let description: String

    init(session: Session) {
        let focus = session.bodyFocus.first { $0 != .full }?.phrase
        let intent = session.intents.first ?? Self.fallbackIntent(for: session.activity)
        headline = Self.headline(for: intent, focus: focus)
        description = [
            session.activity.feelsLike,
            Self.shape(durationMin: session.durationMin, intensity: session.intensity)
        ].joined(separator: " ")
    }

    private static func headline(for intent: Intent, focus: String?) -> String {
        switch (intent, focus) {
        case (.calm, let focus?): "Room to let \(focus) go soft"
        case (.calm, nil): "A few quieter minutes"
        case (.mobilize, let focus?): "More room to move in \(focus)"
        case (.mobilize, nil): "Loosening up, head to toe"
        case (.strengthen, let focus?): "Steady strength through \(focus)"
        case (.strengthen, nil): "Strong and steady, all over"
        case (.energize, let focus?): "Waking up \(focus)"
        case (.energize, nil): "A lift you can feel"
        case (.joy, _): "Moving just because it’s fun"
        case (.play, let focus?): "Something playful for \(focus)"
        case (.play, nil): "A little play in your day"
        }
    }

    /// Length and effort together, because "ten minutes" reads differently
    /// when it is gentle than when it is hard.
    private static func shape(durationMin: Int, intensity: Int) -> String {
        let minutes = max(1, durationMin)
        let length = minutes == 1 ? "1 minute" : "\(minutes) minutes"
        let pace = switch intensity {
        case ...2: "gentle"
        case 3: "steady"
        default: "hard-working"
        }
        let fit = switch minutes {
        case ...5: "short enough to slot in anywhere."
        case ...15: "long enough to settle into."
        default: "a proper stretch of time that’s all yours."
        }
        return "\(length), \(pace) — \(fit)"
    }

    private static func fallbackIntent(for activity: Activity) -> Intent {
        switch activity {
        case .breathwork, .qigong: .calm
        case .yoga, .stretching: .mobilize
        case .pilates, .strength, .carries, .climbing: .strengthen
        case .dance, .skating, .racquet, .jumpRope: .play
        default: .energize
        }
    }
}

nonisolated private extension BodyFocus {
    var phrase: String? {
        switch self {
        case .full: nil
        case .core: "your middle"
        case .lowerBody: "your legs"
        case .upperBody: "your arms and shoulders"
        case .back: "your back"
        case .hips: "your hips"
        case .neckShoulders: "your neck and shoulders"
        }
    }
}

nonisolated private extension Activity {
    /// One sentence on what doing it is like from the inside.
    var feelsLike: String {
        switch self {
        case .pilates: "Slow, controlled work where you feel every muscle you’re using."
        case .yoga: "Breath and movement tied together, so your mind has somewhere to rest."
        case .qigong: "Soft, flowing movement at the pace of your breath."
        case .strength: "Pushing against something solid, and feeling it push back."
        case .stretching: "Slow holds that give tight spots time to let go."
        case .walking: "Just you, your feet, and whatever’s around you."
        case .running: "Your own rhythm, one stride after another."
        case .biking: "Wheels turning under you and air moving past."
        case .swimming: "The water holds you up while you move through it."
        case .skating: "Gliding, balancing, and a little bit of speed."
        case .dance: "Music on, moving however it wants to come out."
        case .jumpRope: "A quick, bouncy rhythm that’s hard not to smile at."
        case .agility: "Quick feet and fast changes of direction."
        case .carries: "Picking up something heavy and walking tall with it."
        case .racquet: "Chasing a ball and the small thrill of sending it back."
        case .climbing: "Working out a route with your hands, feet, and head."
        case .martialArts: "Sharp, deliberate movement that asks for your full attention."
        case .breathwork: "Nothing to do but follow your breath, in and out."
        }
    }
}
