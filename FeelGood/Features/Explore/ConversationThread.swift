//
//  ConversationThread.swift
//  FeelGood
//
//  Data models representing conversational threads and messages in Explore/Chat.
//  Enables multi-session history, thread switching, auto-naming, and persistent storage.
//

import Foundation

nonisolated struct ConversationMessage: Identifiable, Codable, Sendable, Equatable {
    enum Role: String, Codable, Sendable {
        case user
        case assistant
    }

    let id: UUID
    let role: Role
    let text: String
    let timestamp: Date
    var recommendation: StructuredRecommendation?
    var isReasonVisible: Bool
    var isCommittedToToday: Bool

    init(
        id: UUID = UUID(),
        role: Role,
        text: String,
        timestamp: Date = Date(),
        recommendation: StructuredRecommendation? = nil,
        isReasonVisible: Bool = false,
        isCommittedToToday: Bool = false
    ) {
        self.id = id
        self.role = role
        self.text = text
        self.timestamp = timestamp
        self.recommendation = recommendation
        self.isReasonVisible = isReasonVisible
        self.isCommittedToToday = isCommittedToToday
    }
}

nonisolated struct ConversationThread: Identifiable, Codable, Sendable, Equatable {
    let id: UUID
    var title: String
    var createdAt: Date
    var updatedAt: Date
    var messages: [ConversationMessage]
    var quickReplies: [QuickReplyAction]

    init(
        id: UUID = UUID(),
        title: String = "New Check-In",
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        messages: [ConversationMessage] = [],
        quickReplies: [QuickReplyAction] = []
    ) {
        self.id = id
        self.title = title
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.messages = messages
        self.quickReplies = quickReplies
    }

    /// Clean, readable display title derived from the first user prompt or fallback title.
    var displayTitle: String {
        if let firstUserPrompt = messages.first(where: { $0.role == .user })?.text.trimmingCharacters(in: .whitespacesAndNewlines),
           !firstUserPrompt.isEmpty {
            if firstUserPrompt.count > 42 {
                return String(firstUserPrompt.prefix(42)) + "…"
            }
            return firstUserPrompt
        }
        return title
    }

    /// Snippet preview of the latest message for the history drawer.
    var previewSnippet: String {
        if let last = messages.last {
            let prefix = last.role == .user ? "You: " : ""
            let text = last.text.trimmingCharacters(in: .whitespacesAndNewlines)
            if !text.isEmpty {
                return prefix + text
            } else if let rec = last.recommendation {
                return "Recommended: \(rec.title)"
            }
        }
        return "Tap to start chatting"
    }

    /// Human-friendly relative timestamp.
    var formattedDate: String {
        let calendar = Calendar.current
        if calendar.isDateInToday(updatedAt) {
            return "Today, " + updatedAt.formatted(date: .omitted, time: .shortened)
        } else if calendar.isDateInYesterday(updatedAt) {
            return "Yesterday, " + updatedAt.formatted(date: .omitted, time: .shortened)
        } else {
            return updatedAt.formatted(date: .abbreviated, time: .shortened)
        }
    }
}
