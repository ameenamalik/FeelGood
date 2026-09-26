//
//  RoutineDraft.swift
//  FeelGood
//
//  When Chat has nothing for what someone asked ("I want to play tennis"),
//  it offers to make it a routine. This reads the request on the device and
//  pre-fills the routine builder, so the person tweaks a draft instead of
//  starting from a blank sheet. It also finds a routine they already saved
//  for the same thing, so Chat can offer theirs before offering to build one.
//
//  Pure and on-device: nothing here is sent anywhere.
//

import Foundation

nonisolated struct RoutineDraft: Identifiable, Hashable, Sendable {
    let id = UUID()
    var title: String
    var activity: Activity
    var course: Course
    var intensity: Int
    var parts: [CustomRoutinePart]

    var durationMin: Int { parts.reduce(0) { $0 + $1.durationMin } }

    /// `nil` when the request names no kind of movement: a draft titled
    /// "Something" would be a blank sheet with extra steps.
    static func from(prompt: String) -> RoutineDraft? {
        let text = prompt.lowercased()
        guard let kind = Self.activity(in: text) else { return nil }
        let minutes = Self.requestedMinutes(in: text) ?? 20
        let name = Self.noun(for: kind, typed: Self.matchedWord(in: text))

        let parts: [CustomRoutinePart]
        if minutes >= 15 {
            // A warm-up and an easy finish either side, and the main part in
            // one of the builder's own durations so its picker can show it.
            let main = [20, 15, 10, 5].first { $0 <= minutes - 10 } ?? 5
            parts = [
                CustomRoutinePart(title: "Warm up", durationMin: 5),
                CustomRoutinePart(title: Self.capitalizedFirst(name), durationMin: main),
                CustomRoutinePart(title: "Ease off", durationMin: 5),
            ]
        } else {
            parts = [CustomRoutinePart(title: Self.capitalizedFirst(name), durationMin: max(minutes, 1))]
        }

        return RoutineDraft(
            title: "My \(name)",
            activity: kind,
            course: minutes <= 10 ? .side : .main,
            intensity: 3,
            parts: parts
        )
    }

    /// A routine the person already saved for what they asked for: same kind
    /// of movement, or its title named in the request. Hidden ones never.
    static func savedMatch(
        for prompt: String,
        in ownSessions: [Session],
        isHidden: (String) -> Bool
    ) -> Session? {
        let text = prompt.lowercased()
        let visible = ownSessions.filter { !isHidden($0.id) }
        if let byTitle = visible.first(where: { text.contains($0.title.lowercased()) }) {
            return byTitle
        }
        guard let kind = Self.activity(in: text) else { return nil }
        return visible.first { $0.activity == kind }
    }

    // MARK: - Reading the request

    /// Order matters: "walk" is checked after "run" so "run/walk" reads as a run.
    private static let keywords: [(pattern: String, activity: Activity)] = [
        (#"\b(run|runs|running|jog|jogging|5k|10k)\b"#, .running),
        (#"\b(swim|swims|swimming|laps)\b"#, .swimming),
        (#"\b(bike|biking|cycle|cycling|spin class|ride)\b"#, .biking),
        (#"\b(climb|climbing|bouldering)\b"#, .climbing),
        (#"\b(skate|skating|rollerblad\w*)\b"#, .skating),
        (#"\b(tennis|padel|pickleball|squash|badminton|basketball|soccer|football|volleyball)\b"#, .racquet),
        (#"\b(boxing|kickboxing|karate|judo|jiu.?jitsu|martial arts|taekwondo)\b"#, .martialArts),
        (#"\b(dance|dancing|zumba)\b"#, .dance),
        (#"\b(yoga)\b"#, .yoga),
        (#"\b(pilates)\b"#, .pilates),
        (#"\b(lift|lifting|weights|strength|gym)\b"#, .strength),
        (#"\b(walk|walking|hike|hiking)\b"#, .walking),
        (#"\b(stretch|stretching|mobility)\b"#, .stretching),
    ]

    static func activity(in text: String) -> Activity? {
        keywords.first { text.range(of: $0.pattern, options: .regularExpression) != nil }?.activity
    }

    /// "20 min", "a 30-minute run", "for 45 minutes". Capped at an hour.
    static func requestedMinutes(in text: String) -> Int? {
        guard let range = text.range(of: #"\b(\d{1,3})\s*-?\s*(m|min|mins|minute|minutes)\b"#, options: .regularExpression) else {
            return nil
        }
        let digits = text[range].prefix { $0.isNumber }
        guard let value = Int(digits), value > 0 else { return nil }
        return min(value, 60)
    }

    /// The word the person used for it: "boxing", "tennis", "zumba".
    static func matchedWord(in text: String) -> String? {
        for keyword in keywords {
            if let range = text.range(of: keyword.pattern, options: .regularExpression) {
                return String(text[range])
            }
        }
        return nil
    }

    /// The thing you'd say you went for: "a run", "a swim". For everything
    /// else, their own word — "My boxing", not "My martial arts".
    private static func noun(for activity: Activity, typed: String?) -> String {
        switch activity {
        case .running: "run"
        case .walking: "walk"
        case .biking: "ride"
        case .swimming: "swim"
        case .climbing: "climb"
        default: typed ?? activity.label.lowercased()
        }
    }

    private static func capitalizedFirst(_ text: String) -> String {
        text.prefix(1).uppercased() + text.dropFirst()
    }
}
