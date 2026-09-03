//
//  ChatService.swift
//  FeelGood
//
//  Conversational stateful agent provider. Dispatches sanitized user queries
//  with multi-turn context to the backend agent / Cloudflare Worker /chat
//  endpoint, decoding structured schema-driven UI payloads (messages,
//  routine recommendation cards, dynamic quick-reply action chips, and overrides).
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

/// Classified conversational intent
nonisolated enum ChatIntent: String, Codable, Sendable {
    case newRoutineRequest = "new_routine_request"
    case inquiry = "inquiry"
    case acknowledgment = "acknowledgment"
    case refinement = "refinement"
    case actionTrigger = "action_trigger"
    case generalCheckIn = "general_check_in"
}

/// Stateful conversation phase
nonisolated enum ConversationPhase: String, Codable, Sendable {
    case greeting = "greeting"
    case needsDiscovery = "needs_discovery"
    case recommendationActive = "recommendation_active"
    case routineCommitted = "routine_committed"
    case inquiryActive = "inquiry_active"
}

/// Action types supported by quick-reply action chips
nonisolated enum QuickReplyType: String, Codable, Sendable {
    case commitToToday = "commit_to_today"
    case askWhy = "ask_why"
    case swapRoutine = "swap_routine"
    case filterGentler = "filter_gentler"
    case filterShorter = "filter_shorter"
    case filterMoreEnergizing = "filter_more_energizing"
    case filterStayingIn = "filter_staying_in"
    case startSession = "start_session"
    case customPrompt = "custom_prompt"
}

/// Dynamic quick-reply action chip returned by the backend agent
nonisolated struct QuickReplyAction: Identifiable, Hashable, Codable, Sendable {
    let id: String
    let label: String
    let symbol: String?
    let actionType: QuickReplyType
    let payload: String?

    enum CodingKeys: String, CodingKey {
        case id
        case label
        case symbol
        case actionType = "action_type"
        case payload
    }

    init(
        id: String,
        label: String,
        symbol: String? = nil,
        actionType: QuickReplyType,
        payload: String? = nil
    ) {
        self.id = id
        self.label = label
        self.symbol = symbol
        self.actionType = actionType
        self.payload = payload
    }
}

/// Structured routine recommendation payload directly driving the UI card
nonisolated struct StructuredRecommendation: Identifiable, Hashable, Codable, Sendable {
    var id: String { sessionID }
    let sessionID: String
    let title: String
    let subtitle: String
    let durationMin: Int
    let intensity: String
    let course: String
    let reason: String
    let tags: [String]
    let equipment: [String]?
    let targetArea: String?

    enum CodingKeys: String, CodingKey {
        case sessionID = "session_id"
        case title
        case subtitle
        case durationMin = "duration_min"
        case intensity
        case course
        case reason
        case tags
        case equipment
        case targetArea = "target_area"
    }

    init(
        sessionID: String,
        title: String,
        subtitle: String,
        durationMin: Int,
        intensity: String = "gentle",
        course: String = "main",
        reason: String,
        tags: [String] = [],
        equipment: [String]? = nil,
        targetArea: String? = nil
    ) {
        self.sessionID = sessionID
        self.title = title
        self.subtitle = subtitle
        self.durationMin = durationMin
        self.intensity = intensity
        self.course = course
        self.reason = reason
        self.tags = tags
        self.equipment = equipment
        self.targetArea = targetArea
    }

    /// Convert to a Course enum for styling
    var resolvedCourse: Course {
        switch course.lowercased() {
        case "appetizer": .appetizer
        case "side", "sides": .side
        case "dessert": .dessert
        case "special": .special
        default: .main
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

/// Lean 3-mode conversation state (PRD §10.1 & Week 2 Core Loop)
nonisolated enum ChatMode: String, Codable, Sendable {
    case clarifying
    case banter
    case recommendation
}

/// Full structured response from the agent
nonisolated struct ChatResponse: Sendable {
    let message: String
    let mode: ChatMode
    let intent: ChatIntent
    let phase: ConversationPhase
    let recommendation: StructuredRecommendation?
    let quickReplies: [QuickReplyAction]
    let overrides: ConversationalOverrides

    init(
        message: String,
        mode: ChatMode? = nil,
        intent: ChatIntent = .generalCheckIn,
        phase: ConversationPhase = .recommendationActive,
        recommendation: StructuredRecommendation? = nil,
        quickReplies: [QuickReplyAction] = [],
        overrides: ConversationalOverrides = ConversationalOverrides()
    ) {
        self.message = message
        if let mode {
            self.mode = mode
        } else if phase == .needsDiscovery {
            self.mode = .clarifying
        } else if recommendation != nil {
            self.mode = .recommendation
        } else {
            self.mode = .banter
        }
        self.intent = intent
        self.phase = phase
        self.recommendation = (self.mode == .recommendation) ? recommendation : nil
        self.quickReplies = quickReplies
        self.overrides = overrides
    }
}

/// Historical message turn sent to backend
nonisolated struct ChatTurnPayload: Codable, Sendable {
    let role: String // "user" | "model"
    let text: String

    enum CodingKeys: String, CodingKey {
        case role
        case text
        case content
    }

    init(role: String, text: String) {
        self.role = role
        self.text = text
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.role = try container.decode(String.self, forKey: .role)
        if let text = try? container.decode(String.self, forKey: .text) {
            self.text = text
        } else if let content = try? container.decode(String.self, forKey: .content) {
            self.text = content
        } else {
            self.text = ""
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(role, forKey: .role)
        try container.encode(text, forKey: .text)
    }
}

/// Backwards compatibility alias
typealias WireChatMessage = ChatTurnPayload

/// User feedback and habit context influencing recommendations
nonisolated struct ChatUserContext: Codable, Sendable {
    let likedActivities: [String]?
    let lastFeel: String?
    let recentCompletions: Int?
    let recoveryOwed: Bool?

    enum CodingKeys: String, CodingKey {
        case likedActivities = "liked_activities"
        case lastFeel = "last_feel"
        case recentCompletions = "recent_completions"
        case recoveryOwed = "recovery_owed"
    }

    init(
        likedActivities: [String]? = nil,
        lastFeel: String? = nil,
        recentCompletions: Int? = nil,
        recoveryOwed: Bool? = nil
    ) {
        self.likedActivities = likedActivities
        self.lastFeel = lastFeel
        self.recentCompletions = recentCompletions
        self.recoveryOwed = recoveryOwed
    }
}

nonisolated protocol ChatProviding: Sendable {
    func describeDay(
        prompt: String,
        history: [WireChatMessage],
        activeSessionID: String?,
        userContext: ChatUserContext?
    ) async -> ChatResponse?
}

extension ChatProviding {
    func describeDay(
        prompt: String,
        history: [WireChatMessage] = [],
        activeSessionID: String? = nil
    ) async -> ChatResponse? {
        await describeDay(prompt: prompt, history: history, activeSessionID: activeSessionID, userContext: nil)
    }
}

/// Network transport for /chat
nonisolated protocol ChatTransport: Sendable {
    func sendChat(
        prompt: String,
        subscriberID: String,
        history: [WireChatMessage],
        activeSessionID: String?,
        userContext: ChatUserContext?,
        timeout: TimeInterval
    ) async throws -> ChatResponse
}

nonisolated struct URLSessionChatTransport: ChatTransport {
    func sendChat(
        prompt: String,
        subscriberID: String,
        history: [WireChatMessage],
        activeSessionID: String?,
        userContext: ChatUserContext?,
        timeout: TimeInterval
    ) async throws -> ChatResponse {
        guard let chatURL = WorkerConstants.chatURL else {
            throw ChatTransportError.notConfigured
        }

        var request = URLRequest(url: chatURL)
        request.httpMethod = "POST"
        request.timeoutInterval = timeout
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let payload = WireChatPayload(
            prompt: prompt,
            subscriberID: subscriberID,
            history: history.isEmpty ? nil : history,
            activeSessionID: activeSessionID,
            userContext: userContext
        )
        request.httpBody = try JSONEncoder().encode(payload)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw ChatTransportError.badResponse
        }

        let decoded = try JSONDecoder().decode(WireChatResponse.self, from: data)
        let overrides = decoded.extractedCheckIn?.toOverrides() ?? ConversationalOverrides()
        let intent = decoded.intent ?? .generalCheckIn
        let phase = decoded.phase ?? .recommendationActive
        let replies = decoded.quickReplies ?? []

        return ChatResponse(
            message: decoded.message,
            mode: decoded.mode,
            intent: intent,
            phase: phase,
            recommendation: decoded.recommendation,
            quickReplies: replies,
            overrides: overrides
        )
    }

    private struct WireChatPayload: Encodable {
        let prompt: String
        let subscriberID: String
        let history: [WireChatMessage]?
        let activeSessionID: String?
        let userContext: ChatUserContext?

        enum CodingKeys: String, CodingKey {
            case prompt
            case subscriberID
            case history
            case activeSessionID
            case userContext = "user_context"
        }
    }

    private struct WireChatResponse: Decodable {
        let message: String
        let mode: ChatMode?
        let intent: ChatIntent?
        let phase: ConversationPhase?
        let recommendation: StructuredRecommendation?
        let quickReplies: [QuickReplyAction]?
        let extractedCheckIn: WireExtractedCheckIn?

        enum CodingKeys: String, CodingKey {
            case message
            case mode
            case intent
            case phase
            case recommendation
            case quickReplies = "quick_replies"
            case extractedCheckIn = "extracted_check_in"
        }
    }

    private struct WireExtractedCheckIn: Decodable {
        let energy: String?
        let timeBudget: String?
        let place: String?
        let body: String?
        let intent: String?
        let quickFilter: String?

        enum CodingKeys: String, CodingKey {
            case energy
            case timeBudget = "time_budget"
            case place
            case body
            case intent
            case quickFilter = "quick_filter"
        }

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
        timeout: TimeInterval = 10.0,
        isProUnlocked: @escaping @Sendable () async -> Bool = { await MainActor.run { PurchasesManager.shared.isProUnlocked } },
        subscriberID: @escaping @Sendable () async -> String = { await MainActor.run { PurchasesManager.shared.appUserID } }
    ) {
        self.transport = transport
        self.redactor = redactor
        self.timeout = timeout
        self.isProUnlocked = isProUnlocked
        self.subscriberID = subscriberID
    }

    func describeDay(
        prompt: String,
        history: [WireChatMessage] = [],
        activeSessionID: String? = nil,
        userContext: ChatUserContext? = nil
    ) async -> ChatResponse? {
        let sanitized = redactor.sanitize(prompt.trimmingCharacters(in: .whitespacesAndNewlines))
        guard !sanitized.isEmpty else { return nil }

        let subID = await subscriberID()

        // Pre-edge paywall check: free users with exhausted daily quota are routed to on-device engine
        let allowed = await MainActor.run {
            PurchasesManager.shared.canPerformEdgeChat()
        }

        guard allowed else {
            return LocalStatefulChatEngine.orchestrate(prompt: sanitized, history: history, userContext: userContext)
        }

        guard let response = try? await transport.sendChat(
            prompt: sanitized,
            subscriberID: subID,
            history: history,
            activeSessionID: activeSessionID,
            userContext: userContext,
            timeout: timeout
        ) else {
            // Fall back to on-device stateful heuristic engine if offline / network fails
            return LocalStatefulChatEngine.orchestrate(prompt: sanitized, history: history, userContext: userContext)
        }

        await MainActor.run {
            PurchasesManager.shared.recordEdgeChatPerformed()
        }

        return response
    }
}

/// On-device local stateful heuristic engine matching the state machine & schema offline
nonisolated enum LocalStatefulChatEngine {
    static func orchestrate(
        prompt: String,
        history: [WireChatMessage] = [],
        userContext: ChatUserContext? = nil
    ) -> ChatResponse {
        let trimmedLower = prompt.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let vaguePhrases = [
            "no", "nah", "nope", "it feels okay", "feels okay", "not sure", "idk",
            "maybe", "meh", "whatever", "don't know", "dont know", "nothing",
            "nothing really", "im ok", "i'm ok", "im okay", "i'm okay"
        ]

        if vaguePhrases.contains(trimmedLower) {
            return ChatResponse(
                message: "Got it. Would you prefer a short breath reset, a gentle floor stretch, or something to build a little energy?",
                mode: .clarifying,
                intent: .generalCheckIn,
                phase: .needsDiscovery,
                recommendation: nil,
                quickReplies: [
                    QuickReplyAction(id: "floor_stretch", label: "5 min floor stretch", symbol: "figure.mind.and.body", actionType: .customPrompt, payload: "5 min gentle floor stretch"),
                    QuickReplyAction(id: "breath_reset", label: "Breath reset", symbol: "wind", actionType: .customPrompt, payload: "3 min breath reset"),
                    QuickReplyAction(id: "gentle_mobility", label: "Gentle mobility", symbol: "figure.cooldown", actionType: .customPrompt, payload: "10 min gentle mobility"),
                    QuickReplyAction(id: "resting_today", label: "Resting today", symbol: "bed.double", actionType: .customPrompt, payload: "I am taking a full rest day")
                ],
                overrides: ConversationalOverrides()
            )
        }

        let lower = prompt.lowercased()

        // 1. Intent Classification
        var intent: ChatIntent = .generalCheckIn
        var phase: ConversationPhase = .recommendationActive

        if ["k", "ok", "okay", "yes", "sounds good", "perfect", "let's do it", "looks good", "great"].contains(lower) {
            intent = .acknowledgment
            phase = .routineCommitted
        } else if lower.contains("why") || lower.contains("what is") || lower.contains("how does") || lower.contains("what if") {
            intent = .inquiry
            phase = .inquiryActive
        } else if lower.contains("shorter") || lower.contains("gentler") || lower.contains("energiz") || lower.contains("not today") || lower.contains("something else") {
            intent = .refinement
            phase = .recommendationActive
        } else if lower.contains("add to today") || lower.contains("swap") || lower.contains("start") {
            intent = .actionTrigger
            phase = .routineCommitted
        } else if lower.contains("min") || lower.contains("tired") || lower.contains("back") || lower.contains("sore") || lower.contains("stiff") || lower.contains("breath") || lower.contains("wired") {
            intent = .newRoutineRequest
            phase = .recommendationActive
        }

        // 2. Overrides extraction
        var energy: Energy?
        if lower.contains("empty") || lower.contains("tired") || lower.contains("exhaust") || lower.contains("drain") || lower.contains("low") {
            energy = .low
        } else if lower.contains("energ") || lower.contains("strong") || lower.contains("great") || lower.contains("pump") {
            energy = .strong
        } else if lower.contains("steady") || lower.contains("ok") || lower.contains("fine") {
            energy = .steady
        }

        var time: TimeBudget?
        var durMin: Int = 15
        if lower.contains("45 min") || lower.contains("45min") || lower.contains("hour") {
            time = .plenty
            durMin = 45
        } else if lower.contains("35 min") || lower.contains("35min") {
            time = .thirtyFiveMinutes
            durMin = 35
        } else if lower.contains("30 min") || lower.contains("30min") || lower.contains("thirty") {
            time = .some
            durMin = 30
        } else if lower.contains("25 min") || lower.contains("25min") {
            time = .twentyFiveMinutes
            durMin = 25
        } else if lower.contains("20 min") || lower.contains("20min") || lower.contains("twenty") {
            time = .twentyMinutes
            durMin = 20
        } else if lower.contains("15 min") || lower.contains("15min") || lower.contains("fifteen") {
            time = .fifteenMinutes
            durMin = 15
        } else if lower.contains("10 min") || lower.contains("10min") || lower.contains("ten") {
            time = .aLittle
            durMin = 10
        } else if lower.contains("5 min") || lower.contains("5min") || lower.contains("five") {
            time = .fiveMinutes
            durMin = 5
        } else if lower.contains("3 min") || lower.contains("3min") || lower.contains("three") {
            time = .fiveMinutes
            durMin = 3
        } else if lower.contains("2 min") || lower.contains("2min") || lower.contains("two") {
            time = .fiveMinutes
            durMin = 2
        }

        var place: PlaceIntent?
        if lower.contains("gym") {
            place = .atTheGym
        } else if lower.contains("outdoors") || lower.contains("outside") || lower.contains("walk") || lower.contains("park") {
            place = .happyToGoOut
        } else if lower.contains("home") || lower.contains("staying in") || lower.contains("stay in") || lower.contains("bed") || lower.contains("mat") {
            place = .stayingIn
        }

        var body: BodyState?
        if lower.contains("sore") || lower.contains("ache") || lower.contains("hurt") {
            body = .sore
        } else if lower.contains("stiff") || lower.contains("tight") || lower.contains("shoulder") || lower.contains("back") {
            body = .stiff
        } else if lower.contains("stress") || lower.contains("anxious") || lower.contains("tense") || lower.contains("wired") {
            body = .stressed
        } else if lower.contains("good") {
            body = .good
        }

        var filter: QuickFilter?
        if lower.contains("shorter") { filter = .shorter }
        else if lower.contains("gentler") { filter = .gentler }
        else if lower.contains("energiz") { filter = .moreEnergizing }
        else if lower.contains("staying in") || lower.contains("stay in") { filter = .canNotLeave }

        let overrides = ConversationalOverrides(energy: energy, time: time, place: place, body: body, quickFilter: filter)

        // 3. Response copy & structured recommendation
        var message = "Here's a gentle plan that fits your day."
        var recommendation: StructuredRecommendation?

        switch intent {
        case .inquiry:
            if lower.contains("can't sit still") || lower.contains("can not sit") || lower.contains("sitting") {
                message = "Then move first. This one's standing."
                recommendation = StructuredRecommendation(
                    sessionID: "app-jump-rope-ninety",
                    title: "Ninety seconds of jump rope",
                    subtitle: "No rope required if you don't have one",
                    durationMin: 2,
                    intensity: "dynamic",
                    course: "appetizer",
                    reason: "Standing reset to dissipate restless energy before settling down.",
                    tags: ["Appetizer", "2 min", "Standing"]
                )
            } else if lower.contains("why") {
                message = "This sequence unloads spinal tension and opens tight hips without straining your joints."
            } else {
                message = "Here is what this sequence focuses on for your movement today."
            }

        case .acknowledgment:
            message = "You're all set. Take your time, breathe deeply, and enjoy moving."

        case .refinement:
            if lower.contains("shorter") || lower.contains("5 min") || lower.contains("3 min") {
                message = "Adjusted. Here is a quick 3-minute neck and shoulder release."
                recommendation = StructuredRecommendation(
                    sessionID: "app-neck-shoulder-release",
                    title: "Neck and shoulder release",
                    subtitle: "For the hours you spent looking at a screen",
                    durationMin: 3,
                    intensity: "gentle",
                    course: "appetizer",
                    reason: "A 3-minute targeted reset for screen fatigue and tight traps.",
                    tags: ["Appetizer", "3 min", "Gentle"]
                )
            } else if lower.contains("energiz") || lower.contains("strong") {
                message = "Picked up the pace with an uplifting strength reset."
                recommendation = StructuredRecommendation(
                    sessionID: "main-strength-express-15",
                    title: "Fifteen minutes with weights",
                    subtitle: "Move something heavy enough that the rest of the day feels lighter",
                    durationMin: 15,
                    intensity: "moderate",
                    course: "main",
                    reason: "Builds gentle strength and warmth without depleting energy.",
                    tags: ["Main", "15 min", "Strength"]
                )
            } else {
                message = "Swapped to a softer, supported floor sequence."
                recommendation = StructuredRecommendation(
                    sessionID: "main-pilates-gentle-10",
                    title: "Ten gentle minutes on the mat",
                    subtitle: "Slow, low to the ground, no standing up",
                    durationMin: 10,
                    intensity: "gentle",
                    course: "main",
                    reason: "Zero standing, fully supported floor flow for restorative rest.",
                    tags: ["Main", "10 min", "Gentle"]
                )
            }

        case .actionTrigger:
            message = "Added to today's menu. Tap Start whenever you're ready."

        case .newRoutineRequest, .generalCheckIn:
            if lower.contains("neck") || lower.contains("shoulder") || lower.contains("desk") {
                message = "Focused release for upper back and neck tension."
                recommendation = StructuredRecommendation(
                    sessionID: "side-desk-shoulder-reset",
                    title: "Shoulder reset between meetings",
                    subtitle: "Done in a chair. Nobody on the call will notice.",
                    durationMin: 5,
                    intensity: "gentle",
                    course: "side",
                    reason: "Releases upper trap tightness and opens thoracic posture.",
                    tags: ["Side", "5 min", "Gentle"]
                )
            } else if lower.contains("wrist") || lower.contains("forearm") || lower.contains("typing") {
                message = "Gentle release for wrists and hands from typing."
                recommendation = StructuredRecommendation(
                    sessionID: "side-desk-wrist-reset",
                    title: "Desk wrist and forearm reset",
                    subtitle: "For tight forearms, stiff fingers, and mouse hands.",
                    durationMin: 5,
                    intensity: "gentle",
                    course: "side",
                    reason: "Decompresses carpal and wrist flexor tightness.",
                    tags: ["Side", "5 min", "Gentle"]
                )
            } else if lower.contains("hip") || lower.contains("back") || lower.contains("stiff") {
                message = "Gentle mat support to open tight hips and release lower back tension."
                recommendation = StructuredRecommendation(
                    sessionID: "app-hip-openers",
                    title: "Three minutes for your hips",
                    subtitle: "On the floor. Low to the ground.",
                    durationMin: 4,
                    intensity: "gentle",
                    course: "appetizer",
                    reason: "Unloads lumbar spine pressure and releases hip flexor tightness.",
                    tags: ["Appetizer", "4 min", "Gentle"]
                )
            } else if lower.contains("morning") || lower.contains("wake") || lower.contains("qigong") {
                message = "A light, uplifting morning flow to awaken circulation."
                recommendation = StructuredRecommendation(
                    sessionID: "app-morning-qigong",
                    title: "Five minutes of qi gong",
                    subtitle: "Easy breath and gentle circles to start the day",
                    durationMin: 5,
                    intensity: "gentle",
                    course: "appetizer",
                    reason: "Gentle morning circulation without strain.",
                    tags: ["Appetizer", "5 min", "Gentle"]
                )
            } else if lower.contains("evening") || lower.contains("night") || lower.contains("sleep") || lower.contains("unwind") {
                message = "Grounding evening floor relaxation to ease down before sleep."
                recommendation = StructuredRecommendation(
                    sessionID: "dessert-tea-and-quiet-stretch",
                    title: "Tea and quiet floor stretch",
                    subtitle: "Sip first, or stretch while the mug cools",
                    durationMin: 10,
                    intensity: "gentle",
                    course: "dessert",
                    reason: "Prepares your nervous system for deep, restorative sleep.",
                    tags: ["Dessert", "10 min", "Gentle"]
                )
            } else if lower.contains("wired") || lower.contains("stress") || lower.contains("anxious") {
                message = "Down-regulating breath and floor grounding to settle the mind."
                recommendation = StructuredRecommendation(
                    sessionID: "app-box-breathing",
                    title: "Four rounds of box breathing",
                    subtitle: "Two minutes, anywhere, eyes open or closed",
                    durationMin: 2,
                    intensity: "gentle",
                    course: "appetizer",
                    reason: "Calming vagal down-regulation before physical movement.",
                    tags: ["Appetizer", "2 min", "Gentle"]
                )
            } else if durMin <= 10 {
                message = "Calibrated for your \(durMin)-minute window today."
                recommendation = StructuredRecommendation(
                    sessionID: "main-pilates-gentle-10",
                    title: "Ten gentle minutes on the mat",
                    subtitle: "Slow, low to the ground, no standing up",
                    durationMin: 10,
                    intensity: "gentle",
                    course: "main",
                    reason: "A balanced 10-minute floor sequence fitting your time.",
                    tags: ["Main", "10 min", "Gentle"]
                )
            } else {
                message = "Calibrated for your \(durMin)-minute window today."
                recommendation = StructuredRecommendation(
                    sessionID: "main-yoga-flow-20",
                    title: "Twenty minutes of flow",
                    subtitle: "A complete practice that leaves you feeling lighter",
                    durationMin: 20,
                    intensity: "moderate",
                    course: "main",
                    reason: "Complete, balanced practice matching your day.",
                    tags: ["Main", "20 min", "Moderate"]
                )
            }
        }

        // 4. Dynamic Quick Replies
        var quickReplies: [QuickReplyAction] = []
        if recommendation != nil {
            quickReplies = [
                QuickReplyAction(id: "shorter", label: "Something shorter", symbol: "clock.arrow.circlepath", actionType: .filterShorter),
                QuickReplyAction(id: "why_this", label: "Why this?", symbol: "questionmark.circle", actionType: .askWhy),
                QuickReplyAction(id: "not_today", label: "Not today", symbol: "xmark.circle", actionType: .swapRoutine)
            ]
        } else if intent == .acknowledgment {
            quickReplies = [
                QuickReplyAction(id: "start_now", label: "Start routine", symbol: "play.fill", actionType: .startSession),
                QuickReplyAction(id: "something_else", label: "Change mind", symbol: "arrow.triangle.2.circlepath", actionType: .swapRoutine)
            ]
        } else {
            quickReplies = [
                QuickReplyAction(id: "shorter", label: "10 min reset", symbol: "clock", actionType: .customPrompt, payload: "10 min gentle reset"),
                QuickReplyAction(id: "gentler", label: "Gentler option", symbol: "leaf", actionType: .filterGentler),
                QuickReplyAction(id: "staying_in", label: "Staying in", symbol: "house", actionType: .filterStayingIn)
            ]
        }

        let mode: ChatMode
        if recommendation != nil {
            mode = .recommendation
        } else if phase == .needsDiscovery {
            mode = .clarifying
        } else {
            mode = .banter
        }

        return ChatResponse(
            message: message,
            mode: mode,
            intent: intent,
            phase: phase,
            recommendation: recommendation,
            quickReplies: quickReplies,
            overrides: overrides
        )
    }
}

nonisolated struct InMemoryChatService: ChatProviding {
    var response: ChatResponse?

    init(response: ChatResponse? = nil) {
        self.response = response
    }

    func describeDay(
        prompt: String,
        history: [WireChatMessage] = [],
        activeSessionID: String? = nil,
        userContext: ChatUserContext? = nil
    ) async -> ChatResponse? {
        response ?? LocalStatefulChatEngine.orchestrate(prompt: prompt, history: history, userContext: userContext)
    }
}
