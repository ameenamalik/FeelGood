//
//  AppleSignIn.swift
//  FeelGood
//
//  Optional identity, layered on top of an app that otherwise needs none of
//  it. Nothing here gates anything — the day's menu works exactly the same
//  signed in or not. This file's only job is turning the system credential
//  into a plain value the rest of the app (and tests) can work with without
//  touching AuthenticationServices directly.
//

import AuthenticationServices
import Foundation

/// What Sign in with Apple gave us, stripped of the SDK type — and stripped of
/// everything the product doesn't use.
///
/// The app-scoped user id is the whole point: it lets a subscription survive a
/// reinstall or a new phone. Name and email are deliberately absent rather than
/// unused. They were requested, stored, and sent to PostHog as a person
/// property while the privacy policy stated in five separate places that we
/// collect neither — and an unused optional on this struct is exactly the
/// affordance that made that easy to do by accident.
///
/// Same reasoning as `CopyPayload`: the guarantee is worth more as a type with
/// nowhere to put the data than as a rule somebody has to remember. Putting
/// `email` back here is a deliberate act, and it means the policy, the privacy
/// manifest, and the App Store nutrition labels all change with it.
nonisolated struct AppleCredential: Sendable {
    let userID: String
}

extension AppleCredential {
    /// `nil` if the authorization wasn't actually an Apple ID credential —
    /// shouldn't happen given how the button is configured, but a silent
    /// no-op is the right failure mode for an optional feature like this one.
    init?(_ authorization: ASAuthorization) {
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else { return nil }
        userID = credential.user
    }
}
