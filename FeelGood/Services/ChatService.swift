//
//  ChatService.swift
//  FeelGood
//
//  Conversational check-in provider. Dispatches sanitized user queries to the
//  Cloudflare Worker /chat endpoint and parses structured check-in overrides
//  alongside the companion's warm response.
//

import Foundation

/// Quick modifications requested through conversation or quick-pivot chips (PRD §10.1).
nonisolated enum QuickFilter: String, Codable, Sendable, CaseIterable {
    case shorter
    case gentler
    case moreEnergizing
    case canNotLeave

    var label: String {
        switch self {
        case .shorter: "Shorter"
        case .gentler: "Gentler"
        case .moreEnergizing: "More energizing"
        case .canNotLeave: "Staying in"
        }
    }

    var symbol: String {
        switch self {
        case .shorter: "clock.arrow.circlepath"
        case .gentler: "leaf"
        case .moreEnergizing: "bolt"
        case .canNotLeave: "house"
        }
    }
}

/// Structured state parsed from conversational check-in.
nonisolated struct ConversationalOverrides: Hashable, Sendable {
    var energy: Energy?
    var time: TimeBudget?
    var place: PlaceIntent?
    var body: BodyState?
    var intent: Intent?
    var quickFilter: QuickFilter?

    init(
        energy: Energy? = nil,
        time: TimeBudget? = nil,
        place: PlaceIntent? = nil,
        body: BodyState? = nil,
        intent: Intent? = nil,
        quickFilter: QuickFilter? = nil
    ) {
        self.energy = energy
        self.time = time
        self.place = place
        self.body = body
        self.intent = intent
        self.quickFilter = quickFilter
    }

    /// Converts the extracted overrides into a `PlanCheckIn`, filling any unstated
    /// fields with gentle sensible defaults.
    func toPlanCheckIn(fallback: PlanCheckIn? = nil) -> PlanCheckIn {
        let finalEnergy = energy ?? fallback?.energy ?? .steady
        let finalTime = time ?? fallback?.time ?? .twentyMinutes
        let finalPlace = place ?? fallback?.place
        let finalBody = body ?? fallback?.body
        return PlanCheckIn(energy: finalEnergy, time: finalTime, place: finalPlace, body: finalBody)
    }

    var hasAnyOverrides: Bool {
        energy != nil || time != nil || place != nil || body != nil || intent != nil || quickFilter != nil
    }
}

nonisolated struct ChatResponse: Sendable {
    let message: String
    let overrides: ConversationalOverrides
}

nonisolated protocol ChatProviding: Sendable {
    func describeDay(prompt: String) async -> ChatResponse?
}

/// Network transport for /chat
nonisolated protocol ChatTransport: Sendable {
    func sendChat(prompt: String, subscriberID: String, timeout: TimeInterval) async throws -> ChatResponse
}

nonisolated struct URLSessionChatTransport: ChatTransport {
    func sendChat(prompt: String, subscriberID: String, timeout: TimeInterval) async throws -> ChatResponse {
        guard let chatURL = WorkerConstants.chatURL else {
            throw ChatTransportError.notConfigured
        }

        var request = URLRequest(url: chatURL)
        request.httpMethod = "POST"
        request.timeoutInterval = timeout
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let payload = WireChatPayload(prompt: prompt, subscriberID: subscriberID)
        request.httpBody = try JSONEncoder().encode(payload)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw ChatTransportError.badResponse
        }

        let decoded = try JSONDecoder().decode(WireChatResponse.self, from: data)
        let overrides = decoded.extractedCheckIn?.toOverrides() ?? ConversationalOverrides()

        return ChatResponse(message: decoded.message, overrides: overrides)
    }

    private struct WireChatPayload: Encodable {
        let prompt: String
        let subscriberID: String
    }

    private struct WireChatResponse: Decodable {
        let message: String
        let extractedCheckIn: WireExtractedCheckIn?
    }

    private struct WireExtractedCheckIn: Decodable {
        let energy: String?
        let timeBudget: String?
        let place: String?
        let body: String?
        let intent: String?
        let quickFilter: String?

        func toOverrides() -> ConversationalOverrides {
            var e: Energy?
            if let energy { e = Energy(rawValue: energy) }

            var t: TimeBudget?
            if let timeBudget { t = TimeBudget(rawValue: timeBudget) }

            var p: PlaceIntent?
            if let place { p = PlaceIntent(rawValue: place) }

            var b: BodyState?
            if let body { b = BodyState(rawValue: body) }

            var i: Intent?
            if let intent { i = Intent(rawValue: intent) }

            var q: QuickFilter?
            if let quickFilter { q = QuickFilter(rawValue: quickFilter) }

            return ConversationalOverrides(energy: e, time: t, place: p, body: b, intent: i, quickFilter: q)
        }
    }

    private enum ChatTransportError: Error {
        case notConfigured
        case badResponse
    }
}

actor ChatService: ChatProviding {
    private let transport: any ChatTransport
    private let redactor: RedactionService
    private let timeout: TimeInterval
    private let isProUnlocked: @Sendable () async -> Bool
    private let subscriberID: @Sendable () async -> String

    init(
        transport: any ChatTransport = URLSessionChatTransport(),
        redactor: RedactionService = .shared,
        timeout: TimeInterval = 3.0,
        isProUnlocked: @escaping @Sendable () async -> Bool = { await MainActor.run { PurchasesManager.shared.isProUnlocked } },
        subscriberID: @escaping @Sendable () async -> String = { await MainActor.run { PurchasesManager.shared.appUserID } }
    ) {
        self.transport = transport
        self.redactor = redactor
        self.timeout = timeout
        self.isProUnlocked = isProUnlocked
        self.subscriberID = subscriberID
    }

    func describeDay(prompt: String) async -> ChatResponse? {
        let sanitized = redactor.sanitize(prompt.trimmingCharacters(in: .whitespacesAndNewlines))
        guard !sanitized.isEmpty else { return nil }

        let subID = await subscriberID()

        guard let response = try? await transport.sendChat(
            prompt: sanitized,
            subscriberID: subID,
            timeout: timeout
        ) else {
            // Fall back to on-device heuristic parsing if network fails
            return LocalHeuristicParser.parse(sanitized)
        }

        return response
    }
}

/// On-device local heuristic parser as offline fallback
nonisolated enum LocalHeuristicParser {
    static func parse(_ text: String) -> ChatResponse {
        let lower = text.lowercased()

        var energy: Energy?
        if lower.contains("empty") || lower.contains("tired") || lower.contains("exhaust") || lower.contains("drain") || lower.contains("low") {
            energy = .low
        } else if lower.contains("energ") || lower.contains("strong") || lower.contains("great") || lower.contains("pump") {
            energy = .strong
        } else if lower.contains("steady") || lower.contains("ok") || lower.contains("fine") {
            energy = .steady
        }

        var time: TimeBudget?
        if lower.contains("45") || lower.contains("hour") || lower.contains("60 min") {
            time = .plenty
        } else if lower.contains("40 min") || lower.contains("forty") {
            time = .fortyMinutes
        } else if lower.contains("35 min") {
            time = .thirtyFiveMinutes
        } else if lower.contains("30 min") || lower.contains("thirty") {
            time = .some
        } else if lower.contains("25 min") {
            time = .twentyFiveMinutes
        } else if lower.contains("20 min") || lower.contains("twenty") {
            time = .twentyMinutes
        } else if lower.contains("15 min") || lower.contains("fifteen") {
            time = .fifteenMinutes
        } else if lower.contains("10 min") || lower.contains("ten") {
            time = .aLittle
        } else if lower.contains("5 min") || lower.contains("five") {
            time = .fiveMinutes
        }

        var place: PlaceIntent?
        if lower.contains("gym") {
            place = .atTheGym
        } else if lower.contains("outdoors") || lower.contains("outside") || lower.contains("go out") || lower.contains("walk") || lower.contains("park") {
            place = .happyToGoOut
        } else if lower.contains("home") || lower.contains("staying in") || lower.contains("stay in") || lower.contains("bed") || lower.contains("mat") {
            place = .stayingIn
        }

        var body: BodyState?
        if lower.contains("sore") || lower.contains("ache") || lower.contains("hurt") {
            body = .sore
        } else if lower.contains("stiff") || lower.contains("tight") {
            body = .stiff
        } else if lower.contains("stress") || lower.contains("anxious") || lower.contains("tense") {
            body = .stressed
        } else if lower.contains("good") {
            body = .good
        }

        let overrides = ConversationalOverrides(energy: energy, time: time, place: place, body: body)
        return ChatResponse(message: "Here's a gentle plan that fits your day.", overrides: overrides)
    }
}

nonisolated struct InMemoryChatService: ChatProviding {
    var response: ChatResponse?

    init(response: ChatResponse? = nil) {
        self.response = response
    }

    func describeDay(prompt: String) async -> ChatResponse? {
        response ?? LocalHeuristicParser.parse(prompt)
    }
}
