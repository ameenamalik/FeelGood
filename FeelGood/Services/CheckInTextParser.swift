//
//  CheckInTextParser.swift
//  FeelGood
//

import Foundation
#if canImport(FoundationModels)
import FoundationModels
#endif

/// Deterministic, dependency-free keyword matching. This is the primary,
/// first-class implementation — not a rare fallback. The on-device model
/// below needs iOS 26+, Apple-Intelligence-capable hardware, and the
/// setting enabled, none of which the simulator or most demo devices have,
/// so this is what most people typing into the sheet actually get.
nonisolated struct KeywordCheckInParser: CheckInTextParsing {

    func parse(_ text: String) async -> ParsedCheckIn {
        let lowercased = text.lowercased()
        let words = Set(lowercased.components(separatedBy: CharacterSet.alphanumerics.inverted).filter { !$0.isEmpty })

        return ParsedCheckIn(
            energy: energy(in: lowercased, words: words),
            time: time(in: lowercased, words: words),
            place: place(in: lowercased, words: words),
            body: body(in: lowercased, words: words)
        )
    }

    // MARK: Energy

    private static let lowEnergyPhrases = ["running on empty", "on empty", "nothing left"]
    private static let lowEnergyWords: Set<String> = ["empty", "exhausted", "drained", "beat", "wiped", "knackered", "depleted"]
    private static let strongEnergyWords: Set<String> = ["strong", "energized", "energised", "pumped", "great", "amazing", "fantastic"]

    private func energy(in text: String, words: Set<String>) -> Energy? {
        if Self.lowEnergyPhrases.contains(where: text.contains) || !words.isDisjoint(with: Self.lowEnergyWords) {
            return .low
        }
        if !words.isDisjoint(with: Self.strongEnergyWords) {
            return .strong
        }
        return nil
    }

    // MARK: Time

    private static let wordNumbers: [(phrase: String, minutes: Int)] = [
        ("half an hour", 30), ("an hour", 60), ("a couple minutes", 5), ("a few minutes", 5),
        ("ten", 10), ("fifteen", 15), ("twenty", 20), ("thirty", 30), ("forty five", 45), ("sixty", 60),
    ]
    private static let littleTimePhrases = ["not much time", "little time", "quick"]
    private static let plentyTimePhrases = ["plenty of time", "lots of time", "all the time"]

    private func time(in text: String, words: Set<String>) -> TimeBudget? {
        if let minutes = numericMinutes(in: text) {
            return band(minutes)
        }
        for (phrase, minutes) in Self.wordNumbers where text.contains(phrase) {
            return band(minutes)
        }
        if Self.littleTimePhrases.contains(where: text.contains) { return .aLittle }
        if Self.plentyTimePhrases.contains(where: text.contains) { return .plenty }
        // A bare "hour"/"hours" with no leading number ("got a strong hour")
        // reads as a full hour, same as the explicit "an hour" phrase above.
        if words.contains("hour") || words.contains("hours") { return .plenty }
        return nil
    }

    /// "20 minutes", "45 min", "1 hour" — the first number+unit pair found.
    private func numericMinutes(in text: String) -> Int? {
        guard let regex = try? NSRegularExpression(pattern: #"(\d+)\s*(hour|hr|minute|min)s?"#) else { return nil }
        let range = NSRange(text.startIndex..., in: text)
        guard
            let match = regex.firstMatch(in: text, range: range),
            let numberRange = Range(match.range(at: 1), in: text),
            let unitRange = Range(match.range(at: 2), in: text),
            let number = Int(text[numberRange])
        else { return nil }

        return text[unitRange].hasPrefix("h") ? number * 60 : number
    }

    private func band(_ minutes: Int) -> TimeBudget {
        switch minutes {
        case ...TimeBudget.aLittle.maxMinutes: .aLittle
        case ...TimeBudget.some.maxMinutes: .some
        default: .plenty
        }
    }

    // MARK: Place

    private static let stayingInPhrases = ["staying in", "stay in", "stay home", "staying home"]
    private static let gymWords: Set<String> = ["gym"]
    private static let outWords: Set<String> = ["out", "outside", "outdoors", "studio", "park"]

    private func place(in text: String, words: Set<String>) -> PlaceIntent? {
        if Self.stayingInPhrases.contains(where: text.contains) || words.contains("home") {
            return .stayingIn
        }
        if !words.isDisjoint(with: Self.gymWords) {
            return .atTheGym
        }
        if !words.isDisjoint(with: Self.outWords) {
            return .happyToGoOut
        }
        return nil
    }

    // MARK: Body

    /// Matched and returned like any other `BodyState` — this is existing,
    /// already-supported on-device state (`PlanCheckIn.body`). The
    /// constraint elsewhere in this file is that raw text and this value
    /// never leave the device, not that they can't be recognized here.
    private static let crampingWords: Set<String> = ["cramping", "cramps", "cramp"]
    private static let soreWords: Set<String> = ["sore", "achy", "ache"]
    private static let stiffWords: Set<String> = ["stiff", "tight"]
    private static let stressedWords: Set<String> = ["stressed", "anxious", "overwhelmed", "wired"]

    private func body(in text: String, words: Set<String>) -> BodyState? {
        if !words.isDisjoint(with: Self.crampingWords) { return .cramping }
        if !words.isDisjoint(with: Self.soreWords) { return .sore }
        if !words.isDisjoint(with: Self.stiffWords) { return .stiff }
        if !words.isDisjoint(with: Self.stressedWords) { return .stressed }
        return nil
    }
}

#if canImport(FoundationModels)
/// The on-device model path — genuinely understands phrasing the keyword
/// matcher can't, at the cost of needing iOS 26+, Apple-Intelligence-capable
/// hardware, and the feature enabled. Guarded behind an availability check
/// so it's never invoked where it can't run; `CheckInTextParser` below is
/// what actually decides whether to use it.
@available(iOS 26.0, *)
nonisolated struct FoundationModelsCheckInParser: CheckInTextParsing {

    @Generable
    struct Extraction {
        @Guide(description: "Energy level, if mentioned. One of: low, steady, strong. Omit if not mentioned.")
        var energy: String?
        @Guide(description: "Time available in minutes, if mentioned, as a plain integer.")
        var timeMinutes: Int?
        @Guide(description: "Where they'd be, if mentioned. One of: stayingIn, happyToGoOut, atTheGym. Omit if not mentioned.")
        var place: String?
        @Guide(description: "Something going on in their body, if mentioned. One of: sore, stiff, stressed, cramping, good. Omit if not mentioned.")
        var body: String?
    }

    private static let instructions = """
    Extract only what is explicitly stated in a short check-in sentence describing how someone feels \
    right now and how much time they have for movement. Never infer or guess a field that isn't stated. \
    This is for you to fill in known categories only — never invent new ones.
    """

    func parse(_ text: String) async -> ParsedCheckIn {
        guard SystemLanguageModel.default.availability == .available else { return ParsedCheckIn() }

        let session = LanguageModelSession(instructions: Self.instructions)
        do {
            let result = try await session.respond(to: text, generating: Extraction.self)
            let extraction = result.content
            return ParsedCheckIn(
                energy: extraction.energy.flatMap(Energy.init(rawValue:)),
                time: extraction.timeMinutes.map(timeBudget(for:)),
                place: extraction.place.flatMap(PlaceIntent.init(rawValue:)),
                body: extraction.body.flatMap(BodyState.init(rawValue:))
            )
        } catch {
            return ParsedCheckIn()
        }
    }

    private func timeBudget(for minutes: Int) -> TimeBudget {
        switch minutes {
        case ...TimeBudget.aLittle.maxMinutes: .aLittle
        case ...TimeBudget.some.maxMinutes: .some
        default: .plenty
        }
    }
}
#endif

/// The real, injectable `CheckInTextParsing` — what `CheckInSheet` actually
/// uses. Prefers the on-device model when it's genuinely available, falls
/// back to the keyword matcher on unavailability, timeout, or any failure.
nonisolated struct CheckInTextParser: CheckInTextParsing {
    private let keyword = KeywordCheckInParser()

    func parse(_ text: String) async -> ParsedCheckIn {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return ParsedCheckIn() }

        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            let modelParser = FoundationModelsCheckInParser()
            let result = await withTimeout(seconds: 2, operation: { await modelParser.parse(text) })
            if let result, result != ParsedCheckIn() {
                return result
            }
        }
        #endif

        return await keyword.parse(text)
    }

    /// A slow first-use model load must never block the sheet — `nil` here
    /// just means "fall back to the keyword matcher", same as any other
    /// failure of the model path.
    private func withTimeout<T: Sendable>(seconds: TimeInterval, operation: @escaping @Sendable () async -> T) async -> T? {
        await withTaskGroup(of: T?.self) { group in
            group.addTask { await operation() }
            group.addTask {
                try? await Task.sleep(for: .seconds(seconds))
                return nil
            }
            let first = await group.next() ?? nil
            group.cancelAll()
            return first
        }
    }
}

/// Fake for previews and for tests that want deterministic, non-keyword
/// behaviour without touching Apple Intelligence.
nonisolated struct FakeCheckInTextParser: CheckInTextParsing {
    var result: ParsedCheckIn

    init(result: ParsedCheckIn = ParsedCheckIn()) {
        self.result = result
    }

    func parse(_ text: String) async -> ParsedCheckIn {
        result
    }
}
