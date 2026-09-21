//
//  AuthService.swift
//  FeelGood
//
//  Authentication service providing Sign in with Apple, Google Sign-In,
//  and Email/Password using Firebase Authentication.
//
//  Follows CLAUDE.md: protocol-isolated, testable with fakes, and syncs
//  with PurchasesManager for multi-device entitlement restoration.
//

import AuthenticationServices
import CryptoKit
@preconcurrency import FirebaseAuth
import FirebaseCore
import Foundation
import PostHog
@preconcurrency import GoogleSignIn
import SwiftUI

// MARK: - AuthUser Model

nonisolated public struct AuthUser: Equatable, Sendable, Identifiable {
    public let uid: String
    public var id: String { uid }
    public let email: String?
    public let displayName: String?
    public let providerID: String

    public init(
        uid: String,
        email: String? = nil,
        displayName: String? = nil,
        providerID: String = "firebase"
    ) {
        self.uid = uid
        self.email = email
        self.displayName = displayName
        self.providerID = providerID
    }

    public var providerDisplay: String {
        switch providerID {
        case "apple.com": return "Apple"
        case "google.com": return "Google"
        case "password": return "Email"
        default: return "Account"
        }
    }
}

// MARK: - AuthError

nonisolated public enum AuthError: LocalizedError, Sendable, Equatable {
    case firebaseNotConfigured
    case missingWindow
    case invalidAppleCredential
    case missingGoogleIDToken
    case invalidEmail
    case weakPassword
    case emailAlreadyInUse
    case wrongPassword
    case userNotFound
    case userDisabled
    case networkError
    case requiresRecentLogin
    case unknown(String)

    public var errorDescription: String? {
        switch self {
        case .firebaseNotConfigured:
            return "Authentication is in demo mode. Add your GoogleService-Info.plist to enable live accounts."
        case .missingWindow:
            return "Unable to find active window for sign-in."
        case .invalidAppleCredential:
            return "Unable to verify Sign in with Apple credentials."
        case .missingGoogleIDToken:
            return "Unable to verify Google credentials."
        case .invalidEmail:
            return "Please enter a valid email address."
        case .weakPassword:
            return "Password should be at least 6 characters."
        case .emailAlreadyInUse:
            return "An account with this email already exists. Try signing in instead."
        case .wrongPassword:
            return "Incorrect password. Please try again or reset your password."
        case .userNotFound:
            return "No account found with this email. Try creating an account instead."
        case .userDisabled:
            return "This account has been disabled."
        case .networkError:
            return "Network connection error. Please check your internet connection."
        case .requiresRecentLogin:
            return "For security, please sign in again before deleting your account."
        case .unknown(let message):
            return message
        }
    }

    static func mapFirebaseError(_ error: Error) -> AuthError {
        let nsError = error as NSError

        // Fast-path check for requiresRecentLogin across domain variations
        if nsError.code == AuthErrorCode.requiresRecentLogin.rawValue
            || nsError.code == 17014
            || (nsError.domain.contains("Auth") && nsError.code == 17014) {
            return .requiresRecentLogin
        }

        guard nsError.domain == AuthErrorDomain || nsError.domain == "FIRAuthErrorDomain" else {
            return .unknown(error.localizedDescription)
        }

        guard let code = AuthErrorCode(rawValue: nsError.code) else {
            return .unknown(error.localizedDescription)
        }

        switch code {
        case .invalidEmail:
            return .invalidEmail
        case .weakPassword:
            return .weakPassword
        case .emailAlreadyInUse:
            return .emailAlreadyInUse
        case .wrongPassword:
            return .wrongPassword
        case .userNotFound:
            return .userNotFound
        case .userDisabled:
            return .userDisabled
        case .networkError:
            return .networkError
        case .requiresRecentLogin:
            return .requiresRecentLogin
        default:
            return .unknown(error.localizedDescription)
        }
    }
}

// MARK: - AuthProviding Protocol

@MainActor
public protocol AuthProviding: AnyObject, Sendable {
    var currentUser: AuthUser? { get }
    var isAuthenticated: Bool { get }
    func signInWithEmail(email: String, password: String) async throws
    func signUpWithEmail(email: String, password: String) async throws
    func signInWithApple(authorization: ASAuthorization, rawNonce: String) async throws
    func signInWithGoogle(presentingViewController: UIViewController) async throws
    func sendPasswordReset(email: String) async throws
    func signOut() throws
    func deleteAccount() async throws
    func reauthenticateAndDeleteWithApple(authorization: ASAuthorization, rawNonce: String) async throws
    func reauthenticateAndDeleteWithGoogle(presentingViewController: UIViewController) async throws
    func reauthenticateAndDeleteWithPassword(password: String) async throws
}

// MARK: - Production AuthService

@Observable
@MainActor
public final class AuthService: AuthProviding, @unchecked Sendable {
    public static let shared = AuthService()

    public private(set) var currentUser: AuthUser?
    /// Describes the interactive authentication that most recently completed.
    /// `nil` means Firebase restored an existing session at app launch.
    public private(set) var lastAuthenticationCreatedAccount: Bool?
    public var isAuthenticated: Bool { currentUser != nil }

    private var authStateHandle: AuthStateDidChangeListenerHandle?

    nonisolated public static var isFirebaseConfigured: Bool {
        guard let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
              let dict = NSDictionary(contentsOfFile: path),
              let apiKey = dict["API_KEY"] as? String,
              !apiKey.isEmpty,
              apiKey != "YOUR_API_KEY" else {
            return false
        }
        return true
    }

    public init() {
        if Self.isFirebaseConfigured && FirebaseApp.app() != nil {
            // GoogleSignIn does not read GoogleService-Info.plist on its own —
            // without this, GIDSignIn.signIn(withPresenting:) throws an
            // uncaught NSInvalidArgumentException ("No active configuration.
            // Make sure GIDClientID is set in Info.plist.") that crashes the
            // app the moment someone taps "Continue with Google."
            if let clientID = FirebaseApp.app()?.options.clientID {
                GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)
            }
            self.authStateHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
                Task { @MainActor in
                    self?.handleFirebaseUserChanged(user)
                }
            }
            if let user = Auth.auth().currentUser {
                self.currentUser = Self.mapUser(user)
            }
        }
    }

    private func handleFirebaseUserChanged(_ user: User?) {
        guard let user else {
            self.currentUser = nil
            Analytics.reset()
            FirestoreService.shared.stopListening()
            Task {
                await PurchasesManager.shared.ensureAnonymousUserForSignedOutSession()
            }
            return
        }
        let mapped = Self.mapUser(user)
        self.currentUser = mapped
        FirestoreService.shared.startListening(for: mapped.uid)
        // Subscription identity is secondary to authentication. Keep it in a
        // separate task so RevenueCat can never hold the sign-in UI open.
        Task {
            await PurchasesManager.shared.logIn(appUserID: mapped.uid)
        }
    }

    private static func mapUser(_ user: User) -> AuthUser {
        let providerID = user.providerData.first?.providerID ?? "password"
        return AuthUser(
            uid: user.uid,
            email: user.email,
            displayName: user.displayName,
            providerID: providerID
        )
    }

    // MARK: - Email Sign In & Sign Up

    public func signInWithEmail(email: String, password: String) async throws {
        guard Self.isFirebaseConfigured else {
            // Mock sign-in when Firebase is not configured with live credentials
            let mock = AuthUser(
                uid: "demo-\(UUID().uuidString.prefix(8))",
                email: email,
                displayName: email.components(separatedBy: "@").first?.capitalized,
                providerID: "password"
            )
            self.lastAuthenticationCreatedAccount = false
            self.currentUser = mock
            Task { await PurchasesManager.shared.logIn(appUserID: mock.uid) }
            return
        }

        do {
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            let mapped = Self.mapUser(result.user)
            self.lastAuthenticationCreatedAccount = false
            self.currentUser = mapped
            FirestoreService.shared.startListening(for: mapped.uid)
        } catch {
            throw AuthError.mapFirebaseError(error)
        }
    }

    public func signUpWithEmail(email: String, password: String) async throws {
        guard Self.isFirebaseConfigured else {
            let mock = AuthUser(
                uid: "demo-\(UUID().uuidString.prefix(8))",
                email: email,
                displayName: email.components(separatedBy: "@").first?.capitalized,
                providerID: "password"
            )
            self.lastAuthenticationCreatedAccount = true
            self.currentUser = mock
            Task { await PurchasesManager.shared.logIn(appUserID: mock.uid) }
            return
        }

        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            let mapped = Self.mapUser(result.user)
            self.lastAuthenticationCreatedAccount = true
            self.currentUser = mapped
            FirestoreService.shared.startListening(for: mapped.uid)
        } catch {
            throw AuthError.mapFirebaseError(error)
        }
    }

    // MARK: - Sign in with Apple

    public func signInWithApple(authorization: ASAuthorization, rawNonce: String) async throws {
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
              let appleIDToken = appleIDCredential.identityToken,
              let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
            throw AuthError.invalidAppleCredential
        }

        guard Self.isFirebaseConfigured else {
            let email = appleIDCredential.email ?? "apple-user@feelgood.app"
            let mock = AuthUser(
                uid: "apple-\(appleIDCredential.user.prefix(8))",
                email: email,
                displayName: appleIDCredential.fullName?.givenName,
                providerID: "apple.com"
            )
            self.lastAuthenticationCreatedAccount = true
            self.currentUser = mock
            Task { await PurchasesManager.shared.logIn(appUserID: mock.uid) }
            return
        }

        let credential = OAuthProvider.appleCredential(
            withIDToken: idTokenString,
            rawNonce: rawNonce,
            fullName: appleIDCredential.fullName
        )

        do {
            let result = try await Auth.auth().signIn(with: credential)
            let mapped = Self.mapUser(result.user)
            self.lastAuthenticationCreatedAccount = result.additionalUserInfo?.isNewUser ?? false
            self.currentUser = mapped
        } catch {
            throw AuthError.mapFirebaseError(error)
        }
    }

    // MARK: - Sign in with Google

    public func signInWithGoogle(presentingViewController: UIViewController) async throws {
        guard Self.isFirebaseConfigured else {
            let mock = AuthUser(
                uid: "google-\(UUID().uuidString.prefix(8))",
                email: "google-user@feelgood.app",
                displayName: "Google User",
                providerID: "google.com"
            )
            self.lastAuthenticationCreatedAccount = true
            self.currentUser = mock
            Task { await PurchasesManager.shared.logIn(appUserID: mock.uid) }
            return
        }

        guard let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
              let dict = NSDictionary(contentsOfFile: path),
              let clientID = dict["CLIENT_ID"] as? String,
              !clientID.isEmpty else {
            throw AuthError.unknown("Google Sign-In requires enabling the Google provider in Firebase Console to download your Client ID.")
        }

        if GIDSignIn.sharedInstance.configuration == nil {
            GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)
        }

        do {
            let signInResult = try await GIDSignIn.sharedInstance.signIn(withPresenting: presentingViewController)
            guard let idToken = signInResult.user.idToken?.tokenString else {
                throw AuthError.missingGoogleIDToken
            }
            let accessToken = signInResult.user.accessToken.tokenString

            let credential = GoogleAuthProvider.credential(
                withIDToken: idToken,
                accessToken: accessToken
            )

            let result = try await Auth.auth().signIn(with: credential)
            let mapped = Self.mapUser(result.user)
            self.lastAuthenticationCreatedAccount = result.additionalUserInfo?.isNewUser ?? false
            self.currentUser = mapped
        } catch {
            throw AuthError.mapFirebaseError(error)
        }
    }

    // MARK: - Password Reset

    public func sendPasswordReset(email: String) async throws {
        guard Self.isFirebaseConfigured else { return }
        do {
            try await Auth.auth().sendPasswordReset(withEmail: email)
        } catch {
            throw AuthError.mapFirebaseError(error)
        }
    }

    // MARK: - Sign Out & Delete Account

    public func signOut() throws {
        if Self.isFirebaseConfigured {
            try Auth.auth().signOut()
            GIDSignIn.sharedInstance.signOut()
        }
        self.currentUser = nil
        self.lastAuthenticationCreatedAccount = nil
        Task { @MainActor in
            FirestoreService.shared.stopListening()
            Analytics.reset()
            await PurchasesManager.shared.logOut()
        }
    }

    public func deleteAccount() async throws {
        guard Self.isFirebaseConfigured else {
            self.currentUser = nil
            Task { @MainActor in
                FirestoreService.shared.stopListening()
                Analytics.reset()
                await PurchasesManager.shared.logOut()
            }
            return
        }

        guard let user = Auth.auth().currentUser else {
            self.currentUser = nil
            Task { @MainActor in
                FirestoreService.shared.stopListening()
                Analytics.reset()
                await PurchasesManager.shared.logOut()
            }
            return
        }

        // Firebase requires a "recent" sign-in to delete an account. Checking this
        // up front — before touching any data — matters because Firestore data
        // must be deleted *before* the auth user (the security rules key off
        // request.auth.uid, which stops resolving the moment the account is
        // gone). If we deleted data first and then discovered reauth was needed,
        // a user who cancels or fails the reauth prompt is left with a live
        // account and permanently wiped cloud data. Bailing out here instead
        // means a stale session never touches data at all — it goes straight to
        // the reauth flow, which deletes data only once re-authentication has
        // actually refreshed the session.
        guard !Self.requiresReauthentication(lastSignInDate: user.metadata.lastSignInDate) else {
            throw AuthError.requiresRecentLogin
        }

        let uid = user.uid

        await Self.deleteCloudData(uid: uid)

        do {
            try await Self.withTimeout(seconds: 8.0) {
                try await user.delete()
            }
            GIDSignIn.sharedInstance.signOut()
            self.currentUser = nil
            Task { @MainActor in
                FirestoreService.shared.stopListening()
                Analytics.reset()
                await PurchasesManager.shared.logOut()
            }
        } catch is AuthTimeoutError {
            throw AuthError.networkError
        } catch {
            throw AuthError.mapFirebaseError(error)
        }
    }

    /// Removes the person's synced data before their auth user goes, because
    /// Firestore's rules key access off the signed-in uid. Deleting the account
    /// never waits on this: if it fails or times out the account is still
    /// deleted, and the failure is logged (no identifiers) so it is visible.
    /// Anything left behind needs a server-side cleanup on user deletion.
    private static func deleteCloudData(uid: String) async {
        do {
            try await withTimeout(seconds: 15.0) {
                try await FirestoreService.shared.deleteUserData(userId: uid)
            }
        } catch {
            Analytics.log("account_deletion_cloud_cleanup_incomplete", level: .error)
        }
    }

    /// Conservative local guess at whether Firebase will demand a fresh sign-in
    /// before allowing a sensitive operation like account deletion. Firebase
    /// doesn't expose its exact server-side threshold, so this stays well under
    /// the ~5 minute window reported in practice — a false positive just means
    /// one extra reauth prompt, while a false negative is the data-loss race
    /// described in `deleteAccount()`.
    static func requiresReauthentication(lastSignInDate: Date?, now: Date = Date()) -> Bool {
        guard let lastSignInDate else { return true }
        return now.timeIntervalSince(lastSignInDate) > 240
    }

    public func reauthenticateAndDeleteWithApple(authorization: ASAuthorization, rawNonce: String) async throws {
        guard Self.isFirebaseConfigured else {
            self.currentUser = nil
            Task { @MainActor in
                FirestoreService.shared.stopListening()
                Analytics.reset()
                await PurchasesManager.shared.logOut()
            }
            return
        }

        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
              let appleIDToken = appleIDCredential.identityToken,
              let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
            throw AuthError.invalidAppleCredential
        }

        guard let user = Auth.auth().currentUser else {
            self.currentUser = nil
            Task { @MainActor in
                FirestoreService.shared.stopListening()
                Analytics.reset()
                await PurchasesManager.shared.logOut()
            }
            return
        }

        let credential = OAuthProvider.appleCredential(
            withIDToken: idTokenString,
            rawNonce: rawNonce,
            fullName: appleIDCredential.fullName
        )

        do {
            try await user.reauthenticate(with: credential)
        } catch {
            throw AuthError.mapFirebaseError(error)
        }

        // Revoke Apple token in accordance with App Store Review Guideline 5.1.1(v)
        if let authCode = appleIDCredential.authorizationCode,
           let authCodeString = String(data: authCode, encoding: .utf8) {
            try? await Auth.auth().revokeToken(withAuthorizationCode: authCodeString)
        }

        let uid = user.uid
        await Self.deleteCloudData(uid: uid)

        do {
            try await Self.withTimeout(seconds: 8.0) {
                try await user.delete()
            }
            GIDSignIn.sharedInstance.signOut()
            self.currentUser = nil
            Task { @MainActor in
                FirestoreService.shared.stopListening()
                Analytics.reset()
                await PurchasesManager.shared.logOut()
            }
        } catch is AuthTimeoutError {
            throw AuthError.networkError
        } catch {
            throw AuthError.mapFirebaseError(error)
        }
    }

    public func reauthenticateAndDeleteWithGoogle(presentingViewController: UIViewController) async throws {
        guard Self.isFirebaseConfigured else {
            self.currentUser = nil
            Task { @MainActor in
                FirestoreService.shared.stopListening()
                Analytics.reset()
                await PurchasesManager.shared.logOut()
            }
            return
        }

        guard let user = Auth.auth().currentUser else {
            self.currentUser = nil
            Task { @MainActor in
                FirestoreService.shared.stopListening()
                Analytics.reset()
                await PurchasesManager.shared.logOut()
            }
            return
        }

        guard let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
              let dict = NSDictionary(contentsOfFile: path),
              let clientID = dict["CLIENT_ID"] as? String,
              !clientID.isEmpty else {
            throw AuthError.unknown("Google Sign-In configuration is missing.")
        }

        if GIDSignIn.sharedInstance.configuration == nil {
            GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)
        }

        let signInResult: GIDSignInResult
        do {
            signInResult = try await GIDSignIn.sharedInstance.signIn(withPresenting: presentingViewController)
        } catch {
            throw AuthError.mapFirebaseError(error)
        }

        guard let idToken = signInResult.user.idToken?.tokenString else {
            throw AuthError.missingGoogleIDToken
        }
        let accessToken = signInResult.user.accessToken.tokenString
        let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)

        do {
            try await user.reauthenticate(with: credential)
        } catch {
            throw AuthError.mapFirebaseError(error)
        }

        let uid = user.uid
        await Self.deleteCloudData(uid: uid)

        do {
            try await Self.withTimeout(seconds: 8.0) {
                try await user.delete()
            }
            GIDSignIn.sharedInstance.signOut()
            self.currentUser = nil
            Task { @MainActor in
                FirestoreService.shared.stopListening()
                Analytics.reset()
                await PurchasesManager.shared.logOut()
            }
        } catch is AuthTimeoutError {
            throw AuthError.networkError
        } catch {
            throw AuthError.mapFirebaseError(error)
        }
    }

    public func reauthenticateAndDeleteWithPassword(password: String) async throws {
        guard Self.isFirebaseConfigured else {
            self.currentUser = nil
            Task { @MainActor in
                FirestoreService.shared.stopListening()
                Analytics.reset()
                await PurchasesManager.shared.logOut()
            }
            return
        }

        guard let user = Auth.auth().currentUser else {
            self.currentUser = nil
            Task { @MainActor in
                FirestoreService.shared.stopListening()
                Analytics.reset()
                await PurchasesManager.shared.logOut()
            }
            return
        }

        guard let email = user.email, !email.isEmpty else {
            throw AuthError.userNotFound
        }

        let credential = EmailAuthProvider.credential(withEmail: email, password: password)
        do {
            try await user.reauthenticate(with: credential)
        } catch {
            throw AuthError.mapFirebaseError(error)
        }

        let uid = user.uid
        await Self.deleteCloudData(uid: uid)

        do {
            try await Self.withTimeout(seconds: 8.0) {
                try await user.delete()
            }
            GIDSignIn.sharedInstance.signOut()
            self.currentUser = nil
            Task { @MainActor in
                FirestoreService.shared.stopListening()
                Analytics.reset()
                await PurchasesManager.shared.logOut()
            }
        } catch is AuthTimeoutError {
            throw AuthError.networkError
        } catch {
            throw AuthError.mapFirebaseError(error)
        }
    }

    // MARK: - Async Timeout Helpers

    private struct AuthTimeoutError: LocalizedError, Sendable {
        var errorDescription: String? { "Operation timed out." }
    }

    private final class TimeoutLock: @unchecked Sendable {
        private let lock = NSLock()
        private var hasCompleted = false

        func completeOnce(_ block: () -> Void) {
            lock.lock()
            defer { lock.unlock() }
            guard !hasCompleted else { return }
            hasCompleted = true
            block()
        }
    }

    static func withTimeout<T: Sendable>(
        seconds: TimeInterval,
        operation: @escaping @Sendable () async throws -> T
    ) async throws -> T {
        try await withCheckedThrowingContinuation { continuation in
            let state = TimeoutLock()

            let workTask = Task {
                do {
                    let result = try await operation()
                    state.completeOnce {
                        continuation.resume(returning: result)
                    }
                } catch {
                    state.completeOnce {
                        continuation.resume(throwing: error)
                    }
                }
            }

            Task {
                try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                state.completeOnce {
                    workTask.cancel()
                    continuation.resume(throwing: AuthTimeoutError())
                }
            }
        }
    }

    static func withTimeout<T: Sendable>(
        seconds: TimeInterval,
        defaultValue: T,
        operation: @escaping @Sendable () async -> T
    ) async -> T {
        await withCheckedContinuation { continuation in
            let state = TimeoutLock()

            let workTask = Task {
                let result = await operation()
                state.completeOnce {
                    continuation.resume(returning: result)
                }
            }

            Task {
                try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                state.completeOnce {
                    workTask.cancel()
                    continuation.resume(returning: defaultValue)
                }
            }
        }
    }

    // MARK: - Nonce Helpers for Apple Sign In

    nonisolated public static func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        if errorCode != errSecSuccess {
            fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
        }

        let charset: [Character] =
            Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        let nonce = randomBytes.map { byte in
            charset[Int(byte) % charset.count]
        }
        return String(nonce)
    }

    nonisolated public static func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            String(format: "%02x", $0)
        }.joined()
        return hashString
    }
}

// MARK: - Mock AuthService (For Previews and Tests)

public final class MockAuthService: AuthProviding, @unchecked Sendable {
    public var currentUser: AuthUser?
    public var isAuthenticated: Bool { currentUser != nil }

    public init(currentUser: AuthUser? = nil) {
        self.currentUser = currentUser
    }

    public func signInWithEmail(email: String, password: String) async throws {
        currentUser = AuthUser(uid: "mock-123", email: email, displayName: "Mock User", providerID: "password")
    }

    public func signUpWithEmail(email: String, password: String) async throws {
        currentUser = AuthUser(uid: "mock-123", email: email, displayName: "Mock User", providerID: "password")
    }

    public func signInWithApple(authorization: ASAuthorization, rawNonce: String) async throws {
        currentUser = AuthUser(uid: "mock-apple", email: "apple@mock.com", displayName: "Apple User", providerID: "apple.com")
    }

    public func signInWithGoogle(presentingViewController: UIViewController) async throws {
        currentUser = AuthUser(uid: "mock-google", email: "google@mock.com", displayName: "Google User", providerID: "google.com")
    }

    public func sendPasswordReset(email: String) async throws {}

    public func signOut() throws {
        currentUser = nil
    }

    public func deleteAccount() async throws {
        currentUser = nil
    }

    public func reauthenticateAndDeleteWithApple(authorization: ASAuthorization, rawNonce: String) async throws {
        currentUser = nil
    }

    public func reauthenticateAndDeleteWithGoogle(presentingViewController: UIViewController) async throws {
        currentUser = nil
    }

    public func reauthenticateAndDeleteWithPassword(password: String) async throws {
        currentUser = nil
    }
}
