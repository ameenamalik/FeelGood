//
//  ChatSafety.swift
//  FeelGood
//
//  Chat suggestions get the same work-around and availability filters the plan
//  engine applies (availability: see ChatAvailability).
//
//  The chat server never learns someone's work-arounds (they are reproductive
//  and body health data and have no path off the device), so it cannot filter
//  for them, and neither can the on-device fallback engine, which has no
//  profile. Without this, someone who told the app they are pregnant could be
//  handed jump rope by asking chat for something cardio. The check therefore
//  runs here, on the phone, on whatever card comes back. A card that conflicts
//  is swapped for a safe one, or dropped, and the original reply text is not
//  shown because it was written about the unsafe session.
//

import Foundation

nonisolated enum ChatSafety {
    static let replacementMessage = "Here's one that fits how you're moving today."
    static let replacementReason = "Chosen to match your time and energy today."
    static let noCardMessage = "What would feel good right now?"

    static func conflicts(_ session: Session, workArounds: Set<WorkAround>, otherNote: String = "") -> Bool {
        if !Set(session.contraindications).isDisjoint(with: workArounds) { return true }
        if !otherNote.isEmpty {
            let engine = PlanEngine(catalog: [session])
            if engine.conflictsWithCustomWorkAround(session, note: otherNote) { return true }
        }
        return false
    }

    /// - Parameters:
    ///   - lookup: finds a session by id, including the person's own routines.
    ///   - replacement: picks a safe alternative for the card that was rejected.
    static func apply(
        to response: ChatResponse,
        workArounds: Set<WorkAround>,
        otherNote: String = "",
        availability: ChatAvailability? = nil,
        lookup: (String) -> Session?,
        replacement: (StructuredRecommendation) -> Session?
    ) -> ChatResponse {
        guard !workArounds.isEmpty || !otherNote.isEmpty || availability != nil, let card = response.recommendation else { return response }

        func isAcceptable(_ session: Session) -> Bool {
            !conflicts(session, workArounds: workArounds, otherNote: otherNote) && availability?.allows(session) ?? true
        }

        // A card whose session cannot be found is treated as unsafe: the
        // screen would otherwise open a fuzzy match nobody checked.
        if let session = lookup(card.sessionID), isAcceptable(session) {
            return response
        }

        if let safe = replacement(card), isAcceptable(safe) {
            return ChatResponse(
                message: replacementMessage,
                mode: .recommendation,
                intent: response.intent,
                phase: .recommendationActive,
                recommendation: LocalStatefulChatEngine.structuredRecommendation(for: safe, reason: replacementReason),
                quickReplies: recommendationChips,
                overrides: response.overrides
            )
        }

        return ChatResponse(
            message: noCardMessage,
            mode: .clarifying,
            intent: response.intent,
            phase: .needsDiscovery,
            recommendation: nil,
            quickReplies: discoveryChips,
            overrides: response.overrides
        )
    }

    static let recommendationChips: [QuickReplyAction] = [
        QuickReplyAction(id: "commit", label: "Add to today", symbol: "plus", actionType: .commitToToday),
        QuickReplyAction(id: "why_this", label: "Why this?", symbol: "questionmark.circle", actionType: .askWhy),
        QuickReplyAction(id: "shorter", label: "Something shorter", symbol: "clock.arrow.circlepath", actionType: .filterShorter),
        QuickReplyAction(id: "gentler", label: "Gentler option", symbol: "leaf", actionType: .filterGentler),
    ]

    static let discoveryChips: [QuickReplyAction] = [
        QuickReplyAction(id: "floor_stretch", label: "5 min floor stretch", symbol: "figure.mind.and.body", actionType: .customPrompt, payload: "5 min gentle floor stretch"),
        QuickReplyAction(id: "breath_reset", label: "Breath reset", symbol: "wind", actionType: .customPrompt, payload: "3 min breath reset"),
        QuickReplyAction(id: "gentle_mobility", label: "Gentle mobility", symbol: "figure.cooldown", actionType: .customPrompt, payload: "10 min gentle mobility"),
    ]
}
