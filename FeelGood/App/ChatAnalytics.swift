//
//  ChatAnalytics.swift
//  FeelGood
//
//  How chat is measured without ever recording what anyone said. Every value
//  here is a closed enum, a number, or a boolean: there is no parameter that
//  can hold the message, a reply, a chip label, or a session title. The
//  privacy policy says analytics never receives text the person typed, so
//  `AnalyticsPayloadTests` asserts these shapes the same way it does for
//  `check_in_completed`.
//

import Foundation

nonisolated enum ChatAnalytics {
    static let replyReceivedEvent = "chat_reply_received"
    static let replyFailedEvent = "chat_reply_failed"
    static let quickReplyTappedEvent = "chat_quick_reply_tapped"
    static let cardCommittedEvent = "chat_card_committed"

    static let replyReceivedKeys: Set<String> = [
        "mode", "intent", "phase", "has_card", "quick_reply_count", "latency_ms", "had_check_in_overrides"
    ]
    static let replyFailedKeys: Set<String> = ["latency_ms"]
    static let quickReplyTappedKeys: Set<String> = ["action_type"]
    static let cardCommittedKeys: Set<String> = ["source"]

    static func replyReceived(
        mode: ChatMode,
        intent: ChatIntent,
        phase: ConversationPhase,
        hasCard: Bool,
        quickReplyCount: Int,
        latencyMs: Int,
        hadCheckInOverrides: Bool
    ) -> [String: Any] {
        [
            "mode": mode.rawValue,
            "intent": intent.rawValue,
            "phase": phase.rawValue,
            "has_card": hasCard,
            "quick_reply_count": quickReplyCount,
            "latency_ms": latencyMs,
            "had_check_in_overrides": hadCheckInOverrides
        ]
    }

    static func replyFailed(latencyMs: Int) -> [String: Any] {
        ["latency_ms": latencyMs]
    }

    /// The chip's action type only. Its label and payload are text, and a
    /// custom prompt's payload can be whatever the server wrote.
    static func quickReplyTapped(_ actionType: QuickReplyType) -> [String: Any] {
        ["action_type": actionType.rawValue]
    }

    enum CardSource: String, Sendable {
        case card
        case chip
    }

    static func cardCommitted(source: CardSource) -> [String: Any] {
        ["source": source.rawValue]
    }
}
