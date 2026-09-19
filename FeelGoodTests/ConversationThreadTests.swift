//
//  ConversationThreadTests.swift
//  FeelGoodTests
//

import Testing
import Foundation
@testable import FeelGood

@Suite("Conversation Thread & History")
@MainActor
struct ConversationThreadTests {

    @Test("ConversationThread initializes with default values")
    func threadDefaults() {
        let thread = ConversationThread()
        #expect(thread.title == "New Check-In")
        #expect(thread.messages.isEmpty)
        #expect(thread.quickReplies.isEmpty)
        #expect(thread.displayTitle == "New Check-In")
        #expect(thread.previewSnippet == "Tap to start chatting")
    }

    @Test("displayTitle derives cleanly from first user message")
    func displayTitleDerivation() {
        var thread = ConversationThread()

        // Assistant welcome first
        thread.messages.append(ConversationMessage(role: .assistant, text: "How's your body feeling?"))
        #expect(thread.displayTitle == "New Check-In")

        // First user message sets display title
        thread.messages.append(ConversationMessage(role: .user, text: "Stiff lower back, 15 min"))
        #expect(thread.displayTitle == "Stiff lower back, 15 min")

        // Subsequent user message does not override first prompt
        thread.messages.append(ConversationMessage(role: .user, text: "Something gentler please"))
        #expect(thread.displayTitle == "Stiff lower back, 15 min")
    }

    @Test("displayTitle cleanly truncates very long user prompts")
    func displayTitleTruncation() {
        var thread = ConversationThread()
        let longPrompt = "I ran a half marathon yesterday and my legs and lower back are feeling completely destroyed today"
        thread.messages.append(ConversationMessage(role: .user, text: longPrompt))

        #expect(thread.displayTitle.count <= 43)
        #expect(thread.displayTitle.hasSuffix("…"))
    }

    @Test("previewSnippet shows latest user or assistant message or recommendation")
    func previewSnippet() {
        var thread = ConversationThread()

        thread.messages.append(ConversationMessage(role: .user, text: "Need a quick 10 min reset"))
        #expect(thread.previewSnippet == "You: Need a quick 10 min reset")

        let rec = StructuredRecommendation(
            sessionID: "test-rec-1",
            title: "Gentle Morning Flow",
            subtitle: "Unwind tension",
            durationMin: 10,
            course: "main",
            reason: "Targeted reset"
        )
        thread.messages.append(ConversationMessage(role: .assistant, text: "Here is a gentle plan.", recommendation: rec))
        #expect(thread.previewSnippet == "Here is a gentle plan.")

        // Empty text assistant message with recommendation
        thread.messages.append(ConversationMessage(role: .assistant, text: "", recommendation: rec))
        #expect(thread.previewSnippet == "Recommended: Gentle Morning Flow")
    }

    @Test("ConversationThread encodes and decodes losslessly")
    func encodingAndDecoding() throws {
        let rec = StructuredRecommendation(
            sessionID: "s-123",
            title: "Core Grounding",
            subtitle: "15 min mat session",
            durationMin: 15,
            intensity: "gentle",
            course: "main",
            reason: "Eases back tension",
            tags: ["Mat", "15 min"]
        )
        let messages = [
            ConversationMessage(role: .user, text: "My lower back aches"),
            ConversationMessage(role: .assistant, text: "Let's do this gentle reset.", recommendation: rec, isCommittedToToday: true)
        ]
        let quickReplies = [
            QuickReplyAction(id: "why", label: "Why this?", actionType: .askWhy)
        ]

        let originalThread = ConversationThread(
            title: "My lower back aches",
            messages: messages,
            quickReplies: quickReplies
        )

        let encoded = try JSONEncoder().encode([originalThread])
        let decoded = try JSONDecoder().decode([ConversationThread].self, from: encoded)

        #expect(decoded.count == 1)
        let decodedThread = decoded[0]
        #expect(decodedThread.id == originalThread.id)
        #expect(decodedThread.title == "My lower back aches")
        #expect(decodedThread.messages.count == 2)
        #expect(decodedThread.messages[0].text == "My lower back aches")
        #expect(decodedThread.messages[1].recommendation?.title == "Core Grounding")
        #expect(decodedThread.messages[1].isCommittedToToday == true)
        #expect(decodedThread.quickReplies.count == 1)
        #expect(decodedThread.quickReplies[0].id == "why")
    }

    @Test("Legacy single-thread messages migrate seamlessly into ConversationThread")
    func legacyMigration() throws {
        let legacyMessages = [
            ConversationMessage(role: .user, text: "15 min morning yoga"),
            ConversationMessage(role: .assistant, text: "Here's a 15 min morning flow")
        ]

        let legacyData = try JSONEncoder().encode(legacyMessages)
        let decodedLegacy = try JSONDecoder().decode([ConversationMessage].self, from: legacyData)

        let migratedThread = ConversationThread(
            title: "Previous Check-In",
            messages: decodedLegacy,
            quickReplies: []
        )

        #expect(migratedThread.displayTitle == "15 min morning yoga")
        #expect(migratedThread.messages.count == 2)
        #expect(migratedThread.previewSnippet == "Here's a 15 min morning flow")
    }
}
