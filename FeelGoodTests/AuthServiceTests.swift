//
//  AuthServiceTests.swift
//  FeelGoodTests
//
//  Unit tests for authentication service, protocol conformance, and mock state.
//

import Foundation
import Testing
@testable import FeelGood

@Suite("Auth Service Tests")
@MainActor
struct AuthServiceTests {

    @Test("MockAuthService starts unauthenticated")
    func initialState() {
        let auth = MockAuthService()
        #expect(!auth.isAuthenticated)
        #expect(auth.currentUser == nil)
    }

    @Test("Email sign-in updates current user and auth state")
    func emailSignIn() async throws {
        let auth = MockAuthService()
        try await auth.signInWithEmail(email: "test@feelgood.app", password: "password123")
        #expect(auth.isAuthenticated)
        #expect(auth.currentUser?.email == "test@feelgood.app")
        #expect(auth.currentUser?.providerID == "password")
        #expect(auth.currentUser?.providerDisplay == "Email")
    }

    @Test("Email sign-up updates current user")
    func emailSignUp() async throws {
        let auth = MockAuthService()
        try await auth.signUpWithEmail(email: "newuser@feelgood.app", password: "password123")
        #expect(auth.isAuthenticated)
        #expect(auth.currentUser?.email == "newuser@feelgood.app")
    }

    @Test("Sign-out clears current user")
    func signOut() async throws {
        let auth = MockAuthService()
        try await auth.signInWithEmail(email: "test@feelgood.app", password: "password123")
        #expect(auth.isAuthenticated)

        try auth.signOut()
        #expect(!auth.isAuthenticated)
        #expect(auth.currentUser == nil)
    }

    @Test("Delete account clears current user")
    func deleteAccount() async throws {
        let auth = MockAuthService()
        try await auth.signInWithEmail(email: "test@feelgood.app", password: "password123")
        #expect(auth.isAuthenticated)

        try await auth.deleteAccount()
        #expect(!auth.isAuthenticated)
        #expect(auth.currentUser == nil)
    }

    @Test("Reauthenticate and delete with password clears current user")
    func reauthenticateAndDeleteWithPassword() async throws {
        let auth = MockAuthService()
        try await auth.signInWithEmail(email: "test@feelgood.app", password: "password123")
        #expect(auth.isAuthenticated)

        try await auth.reauthenticateAndDeleteWithPassword(password: "password123")
        #expect(!auth.isAuthenticated)
        #expect(auth.currentUser == nil)
    }

    @Test("Reauthenticate and delete with Google clears current user")
    func reauthenticateAndDeleteWithGoogle() async throws {
        let auth = MockAuthService()
        try await auth.signInWithEmail(email: "test@feelgood.app", password: "password123")
        #expect(auth.isAuthenticated)

        try await auth.reauthenticateAndDeleteWithGoogle(presentingViewController: UIViewController())
        #expect(!auth.isAuthenticated)
        #expect(auth.currentUser == nil)
    }

    @Test("AuthError conforms to Equatable and provides requiresRecentLogin description")
    func authErrorRequiresRecentLogin() {
        let error = AuthError.requiresRecentLogin
        #expect(error == .requiresRecentLogin)
        #expect(error.errorDescription == "For security, please sign in again before deleting your account.")
    }

    @Test("Nonce generation generates unique random nonces")
    func nonceGeneration() {
        let nonce1 = AuthService.randomNonceString()
        let nonce2 = AuthService.randomNonceString()
        #expect(nonce1 != nonce2)
        #expect(nonce1.count == 32)
        #expect(nonce2.count == 32)

        let hash1 = AuthService.sha256(nonce1)
        let hash2 = AuthService.sha256(nonce2)
        #expect(hash1 != hash2)
        #expect(!hash1.isEmpty)
    }

    @Test("AuthUser providerDisplay mapping")
    func authUserProviderDisplay() {
        let appleUser = AuthUser(uid: "1", providerID: "apple.com")
        #expect(appleUser.providerDisplay == "Apple")

        let googleUser = AuthUser(uid: "2", providerID: "google.com")
        #expect(googleUser.providerDisplay == "Google")

        let emailUser = AuthUser(uid: "3", providerID: "password")
        #expect(emailUser.providerDisplay == "Email")

        let customUser = AuthUser(uid: "4", providerID: "custom")
        #expect(customUser.providerDisplay == "Account")
    }

    @Test("AuthSheetView initializes with custom onDismiss and onAuthenticated closures")
    func authSheetViewCallbacks() {
        var didAuthenticate = false
        var didDismiss = false
        let sheet = AuthSheetView(
            showsHeroIllustration: true,
            onAuthenticated: { didAuthenticate = true },
            onDismiss: { didDismiss = true }
        )
        #expect(sheet.showsHeroIllustration)
        sheet.onAuthenticated?()
        #expect(didAuthenticate)
        sheet.onDismiss?()
        #expect(didDismiss)
    }

    @Test("FirstRunFlow AppStorage keys are stable")
    func firstRunFlowKeys() {
        #expect(FirstRunFlow.hasSeenIntroKey == "hasSeenProductIntro")
        #expect(FirstRunFlow.hasSeenWelcomeSignUpKey == "hasSeenWelcomeSignUp")
        #expect(FirstRunFlow.hasSeenOnboardingPaywallKey == "hasSeenOnboardingPaywall")
    }
}
