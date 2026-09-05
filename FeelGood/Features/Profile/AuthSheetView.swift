//
//  AuthSheetView.swift
//  FeelGood
//
//  A serene, respectful authentication sheet presented when users want to
//  save their routine, complete their first activation milestone, or manage
//  their account.
//
//  Supports Apple Sign In, Google Sign In, and Email/Password.
//

import AuthenticationServices
import GoogleSignIn
import SwiftUI

struct AuthSheetView: View {
    var title: String = "Save your routine"
    var subtitle: String = "Keep your movement history and personalized daily menus synced safely across devices."
    var onAuthenticated: (() -> Void)? = nil

    @Environment(\.dismiss) private var dismiss
    @Environment(AuthService.self) private var authService

    @State private var mode: AuthMode = .signIn
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var isLoading: Bool = false
    @State private var errorMessage: String? = nil
    @State private var successMessage: String? = nil
    @State private var currentRawNonce: String = ""

    private enum AuthMode {
        case signIn
        case createAccount
    }

    var body: some View {
        NavigationStack {
            ZStack {
                FGColor.bg.ignoresSafeArea()
                FGBrandWash(reach: 0.55).ignoresSafeArea()

                ScrollView {
                    VStack(spacing: FGSpace.l) {
                        headerSection

                        VStack(spacing: FGSpace.m) {
                            appleSignInButton
                            googleSignInButton

                            orDivider

                            emailPasswordSection
                        }
                        .frame(maxWidth: 360)

                        if let errorMessage {
                            Text(errorMessage)
                                .font(FGFont.caption)
                                .foregroundStyle(FGColor.clayDeep)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, FGSpace.m)
                                .transition(.opacity)
                        }

                        if let successMessage {
                            Text(successMessage)
                                .font(FGFont.caption)
                                .foregroundStyle(FGColor.sageDeep)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, FGSpace.m)
                                .transition(.opacity)
                        }

                        guestFooter
                    }
                    .padding(.horizontal, FGSpace.page)
                    .padding(.top, FGSpace.m)
                    .padding(.bottom, FGSpace.xl)
                }
                .scrollBounceBehavior(.basedOnSize)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundStyle(FGColor.inkMuted)
                }
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: FGSpace.s) {
            Image(systemName: "sparkles")
                .font(.system(size: 32, weight: .medium))
                .foregroundStyle(FGColor.goldDeep)
                .accessibilityHidden(true)
                .padding(.bottom, 2)

            Text(title)
                .font(FGFont.display)
                .tracking(-0.5)
                .foregroundStyle(FGColor.ink)
                .multilineTextAlignment(.center)

            Text(subtitle)
                .font(FGFont.body)
                .foregroundStyle(FGColor.inkMuted)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.top, FGSpace.s)
    }

    // MARK: - Apple Sign In Button

    private var appleSignInButton: some View {
        SignInWithAppleButton(
            mode == .signIn ? .signIn : .signUp,
            onRequest: { request in
                let nonce = AuthService.randomNonceString()
                currentRawNonce = nonce
                request.requestedScopes = [.fullName, .email]
                request.nonce = AuthService.sha256(nonce)
            },
            onCompletion: { result in
                handleAppleResult(result)
            }
        )
        .signInWithAppleButtonStyle(.black)
        .frame(height: 50)
        .clipShape(RoundedRectangle(cornerRadius: FGRadius.button, style: .continuous))
    }

    private func handleAppleResult(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            isLoading = true
            errorMessage = nil
            Task {
                do {
                    try await authService.signInWithApple(
                        authorization: authorization,
                        rawNonce: currentRawNonce
                    )
                    isLoading = false
                    onAuthenticated?()
                    dismiss()
                } catch {
                    isLoading = false
                    errorMessage = error.localizedDescription
                }
            }
        case .failure(let error):
            if (error as? ASAuthorizationError)?.code != .canceled {
                errorMessage = error.localizedDescription
            }
        }
    }

    // MARK: - Google Sign In Button

    private var googleSignInButton: some View {
        Button {
            signInWithGoogle()
        } label: {
            HStack(spacing: FGSpace.s) {
                googleGLogo
                    .frame(width: 18, height: 18)

                Text(mode == .signIn ? "Sign in with Google" : "Sign up with Google")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.black)
            }
            .frame(maxWidth: .infinity, minHeight: 50)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: FGRadius.button, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: FGRadius.button, style: .continuous)
                    .strokeBorder(FGColor.lineStrong, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .disabled(isLoading)
    }

    private var googleGLogo: some View {
        // Subtle multicolor 'G' glyph representation using an SF symbol or layered styling
        Image(systemName: "globe")
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(FGColor.ink)
    }

    private func signInWithGoogle() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = windowScene.windows.first(where: { $0.isKeyWindow })?.rootViewController else {
            errorMessage = "Unable to find presentation window."
            return
        }

        isLoading = true
        errorMessage = nil
        Task {
            do {
                try await authService.signInWithGoogle(presentingViewController: rootVC)
                isLoading = false
                onAuthenticated?()
                dismiss()
            } catch {
                isLoading = false
                if (error as NSError).code != GIDSignInError.canceled.rawValue {
                    errorMessage = error.localizedDescription
                }
            }
        }
    }

    // MARK: - Or Divider

    private var orDivider: some View {
        HStack(spacing: FGSpace.m) {
            Rectangle()
                .fill(FGColor.line)
                .frame(height: 1)

            Text("or with email")
                .font(FGFont.caption)
                .foregroundStyle(FGColor.inkMuted)

            Rectangle()
                .fill(FGColor.line)
                .frame(height: 1)
        }
        .padding(.vertical, FGSpace.xs)
    }

    // MARK: - Email & Password Section

    private var emailPasswordSection: some View {
        VStack(spacing: FGSpace.s) {
            // Mode toggle
            Picker("Mode", selection: $mode) {
                Text("Sign In").tag(AuthMode.signIn)
                Text("Create Account").tag(AuthMode.createAccount)
            }
            .pickerStyle(.segmented)
            .padding(.bottom, FGSpace.xs)

            // Email Field
            TextField("Email address", text: $email)
                .font(FGFont.body)
                .foregroundStyle(FGColor.ink)
                .textInputAutocapitalization(.never)
                .keyboardType(.emailAddress)
                .autocorrectionDisabled(true)
                .padding(.horizontal, FGSpace.m)
                .padding(.vertical, 14)
                .background(FGColor.surface)
                .clipShape(RoundedRectangle(cornerRadius: FGRadius.chip, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: FGRadius.chip, style: .continuous)
                        .strokeBorder(FGColor.line, lineWidth: 1)
                )

            // Password Field
            SecureField("Password", text: $password)
                .font(FGFont.body)
                .foregroundStyle(FGColor.ink)
                .padding(.horizontal, FGSpace.m)
                .padding(.vertical, 14)
                .background(FGColor.surface)
                .clipShape(RoundedRectangle(cornerRadius: FGRadius.chip, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: FGRadius.chip, style: .continuous)
                        .strokeBorder(FGColor.line, lineWidth: 1)
                )

            // Action Button
            Button {
                submitEmailAuth()
            } label: {
                HStack {
                    Spacer()
                    if isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text(mode == .signIn ? "Sign In" : "Create Account")
                            .font(FGFont.body.weight(.semibold))
                    }
                    Spacer()
                }
                .padding(.vertical, 14)
                .foregroundStyle(Color.white)
                .background(Color(light: 0x231F1C, dark: 0x1A1715))
                .clipShape(RoundedRectangle(cornerRadius: FGRadius.button, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(isLoading || email.trimmingCharacters(in: .whitespaces).isEmpty || password.isEmpty)
            .opacity(email.trimmingCharacters(in: .whitespaces).isEmpty || password.isEmpty ? 0.5 : 1.0)

            if mode == .signIn {
                Button("Forgot password?") {
                    handleForgotPassword()
                }
                .font(FGFont.caption)
                .foregroundStyle(FGColor.inkMuted)
                .padding(.top, 4)
            }
        }
    }

    private func submitEmailAuth() {
        let cleanEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanEmail.isEmpty, !password.isEmpty else { return }

        isLoading = true
        errorMessage = nil
        successMessage = nil

        Task {
            do {
                if mode == .signIn {
                    try await authService.signInWithEmail(email: cleanEmail, password: password)
                } else {
                    try await authService.signUpWithEmail(email: cleanEmail, password: password)
                }
                isLoading = false
                onAuthenticated?()
                dismiss()
            } catch {
                isLoading = false
                errorMessage = error.localizedDescription
            }
        }
    }

    private func handleForgotPassword() {
        let cleanEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanEmail.isEmpty else {
            errorMessage = "Please enter your email address above first."
            return
        }

        isLoading = true
        errorMessage = nil
        Task {
            do {
                try await authService.sendPasswordReset(email: cleanEmail)
                isLoading = false
                successMessage = "Password reset email sent. Please check your inbox."
            } catch {
                isLoading = false
                errorMessage = error.localizedDescription
            }
        }
    }

    // MARK: - Guest Footer

    private var guestFooter: some View {
        VStack(spacing: FGSpace.s) {
            Button("Continue as guest") {
                dismiss()
            }
            .font(FGFont.label.weight(.medium))
            .foregroundStyle(FGColor.inkMuted)
            .padding(.top, FGSpace.s)

            Text("FeelGood stores your health reflections on-device. Accounts are used for backup and syncing across devices.")
                .font(FGFont.caption)
                .foregroundStyle(FGColor.inkMuted.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.horizontal, FGSpace.l)
        }
    }
}

#Preview {
    AuthSheetView()
        .environment(AuthService.shared)
}
