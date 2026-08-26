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

/// What Sign in with Apple actually gave us, stripped of the SDK type.
/// `email`/`fullName` are only ever populated on the first authorization for
/// a given Apple ID and this app — Apple does not resend them later.
nonisolated struct AppleCredential: Sendable {
    let userID: String
    let email: String?
    let fullName: PersonNameComponents?
}

extension AppleCredential {
    /// `nil` if the authorization wasn't actually an Apple ID credential —
    /// shouldn't happen given how the button is configured, but a silent
    /// no-op is the right failure mode for an optional feature like this one.
    init?(_ authorization: ASAuthorization) {
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else { return nil }
        userID = credential.user
        email = credential.email
        fullName = credential.fullName
    }
}
