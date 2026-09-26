//
//  ChatConsent.swift
//  FeelGood
//
//  Whether the person has agreed to send what they type in Chat to our server
//  and on to a third-party language model. Asked once, before the first message
//  that would leave the device, and never again unless they change it.
//
//  Declining is a real choice with a real outcome: Chat keeps working, answered
//  entirely on the device. `ChatService` enforces this, so a view that forgets
//  to ask still cannot send anything.
//

import Foundation

nonisolated enum ChatConsent {
    enum Status: String, Sendable {
        case notAsked
        case granted
        case declined
    }

    /// The `@AppStorage` key. One place, so views and the service agree.
    static let key = "chatAIConsent.v1"

    static var status: Status {
        Status(rawValue: UserDefaults.standard.string(forKey: key) ?? "") ?? .notAsked
    }

    static var isGranted: Bool { status == .granted }

    static func set(_ status: Status) {
        UserDefaults.standard.set(status.rawValue, forKey: key)
    }
}

/// The one AI exchange a free user gets before the paywall. Stored with the
/// same key Chat's composer reads, so the paywall and the service agree on
/// whether it has been spent.
nonisolated struct FreeChatAllowance: Sendable {
    static let key = "hasUsedFreeChatExchange"

    let isAvailable: @Sendable () -> Bool
    let markUsed: @Sendable () -> Void

    static let standard = FreeChatAllowance(
        isAvailable: { !UserDefaults.standard.bool(forKey: key) },
        markUsed: { UserDefaults.standard.set(true, forKey: key) }
    )

    /// For tests and previews: never grants a free exchange.
    static let none = FreeChatAllowance(isAvailable: { false }, markUsed: {})
}
