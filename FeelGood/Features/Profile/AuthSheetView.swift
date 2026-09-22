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
import UIKit

struct AuthSheetView: View {
    /// Apple's native authorization control owns its typography and renders
    /// slightly larger than an ordinary 19-point SwiftUI label. Use this
    /// optical match for the adjacent custom provider buttons.
    private static let providerButtonFont = Font.system(size: 21, weight: .semibold)
    private static let providerIconSize: CGFloat = 20

    var title: String = "Save your routine"
    var subtitle: String = "Keep your movement history and personalized daily menus synced safely across devices."
    /// Swaps the small "sparkles" glyph for the brand-mark + fruit-cluster
    /// illustration, for the one entry point (onboarding's welcome screen)
    /// that's a first impression rather than a milestone nudge.
    var showsHeroIllustration: Bool = false
    var guestButtonTitle: String = "Continue as guest"
    var onAuthenticated: (() -> Void)? = nil
    var onDismiss: (() -> Void)? = nil

    @Environment(\.dismiss) private var dismiss
    @Environment(AuthService.self) private var authService
    @Environment(\.colorScheme) private var colorScheme

    @State private var mode: AuthMode
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var isLoading: Bool = false
    @State private var errorMessage: String? = nil
    @State private var successMessage: String? = nil
    @State private var currentRawNonce: String = ""
    @State private var path: [HeroStage] = []

    enum AuthMode {
        case signIn
        case createAccount
    }

    /// Where "Continue with Email" / "Already have an account? Sign in" push
    /// to, in the hero-illustration entry screen. Not used by the four
    /// milestone-nudge call sites, which keep everything on one screen.
    enum HeroStage: Hashable {
        case emailCreate
        case emailSignIn
    }

    init(
        title: String = "Save your routine",
        subtitle: String = "Keep your movement history and personalized daily menus synced safely across devices.",
        showsHeroIllustration: Bool = false,
        initialMode: AuthMode = .signIn,
        guestButtonTitle: String = "Continue as guest",
        onAuthenticated: (() -> Void)? = nil,
        onDismiss: (() -> Void)? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.showsHeroIllustration = showsHeroIllustration
        self.guestButtonTitle = guestButtonTitle
        self.onAuthenticated = onAuthenticated
        self.onDismiss = onDismiss
        _mode = State(initialValue: initialMode)
    }

    private func dismissAfterAuth() {
        path.removeAll()
        dismiss()
    }

    private func dismissWithoutAuth() {
        path.removeAll()
        onDismiss?()
        dismiss()
    }

    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                FGColor.bg.ignoresSafeArea()
                FGBrandWash(reach: 0.55).ignoresSafeArea()

                ScrollView {
                    VStack(spacing: FGSpace.l) {
                        headerSection

                        if showsHeroIllustration {
                            heroEntryButtons
                        } else {
                            VStack(spacing: FGSpace.m) {
                                appleButton(label: mode == .signIn ? .signIn : .signUp)
                                googleSignInButton

                                orDivider

                                emailPasswordSection
                            }
                            .frame(maxWidth: 360)
                        }

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
                if !showsHeroIllustration {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Close") {
                            dismissWithoutAuth()
                        }
                        .foregroundStyle(FGColor.inkMuted)
                    }
                }
            }
            .navigationDestination(for: HeroStage.self) { stage in
                heroDestination(stage)
            }
        }
    }

    // MARK: - Hero entry (onboarding welcome screen only)

    /// Three plain "Continue with…" pills and nothing else — no inline form,
    /// no mode picker. Tapping Email or "Sign in" pushes a single-purpose
    /// screen instead of expanding everything in place.
    private var heroEntryButtons: some View {
        VStack(spacing: FGSpace.m) {
            appleButton(label: .continue)
            googleContinueButton
            emailContinueButton

            Button("Already have an account? Sign in") {
                path.append(.emailSignIn)
            }
            .font(.system(size: 19, weight: .medium))
            .foregroundStyle(FGColor.goldDeep)
            .padding(.top, FGSpace.xs)
            .disabled(isLoading)

            if isLoading {
                ProgressView()
                    .tint(FGColor.ink)
                    .padding(.top, FGSpace.xs)
            }
        }
        .frame(maxWidth: 360)
    }

    private var emailContinueButton: some View {
        Button {
            path.append(.emailCreate)
        } label: {
            HStack(spacing: FGSpace.s) {
                Image(systemName: "envelope.fill")
                    .font(.system(size: Self.providerIconSize, weight: .semibold))
                Text("Continue with Email")
                    .font(Self.providerButtonFont)
            }
            .foregroundStyle(FGColor.bg)
            .frame(maxWidth: .infinity, minHeight: 56)
            .background(FGColor.ink)
            .clipShape(RoundedRectangle(cornerRadius: FGRadius.button, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    /// The pushed single-purpose screen for either "Continue with Email"
    /// (create account) or "Already have an account? Sign in".
    @ViewBuilder
    private func heroDestination(_ stage: HeroStage) -> some View {
        let currentMode: AuthMode = stage == .emailCreate ? .createAccount : .signIn

        ZStack {
            FGColor.bg.ignoresSafeArea()
            FGBrandWash(reach: 0.4).ignoresSafeArea()

            ScrollView {
                VStack(spacing: FGSpace.l) {
                    VStack(spacing: FGSpace.s) {
                        Text(stage == .emailCreate ? "Create your account" : "Welcome back")
                            .font(FGFont.display)
                            .tracking(-0.5)
                            .foregroundStyle(FGColor.ink)
                            .multilineTextAlignment(.center)

                        Text(
                            stage == .emailCreate
                                ? "So today's menu is waiting for you next time, wherever you open FeelGood."
                                : "Sign in and we'll pick up right where your menu left off."
                        )
                        .font(FGFont.body)
                        .foregroundStyle(FGColor.inkMuted)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.top, FGSpace.l)

                    VStack(spacing: FGSpace.s) {
                        emailFieldsAndSubmit(mode: currentMode)

                        if stage == .emailCreate {
                            Button("Already have an account? Sign in") {
                                withAnimation(FGMotion.gentle) {
                                    errorMessage = nil
                                    successMessage = nil
                                    path = [.emailSignIn]
                                }
                            }
                            .font(FGFont.caption.weight(.medium))
                            .foregroundStyle(FGColor.goldDeep)
                            .padding(.top, FGSpace.xs)
                        } else {
                            Button("Don't have an account? Create one") {
                                withAnimation(FGMotion.gentle) {
                                    errorMessage = nil
                                    successMessage = nil
                                    path = [.emailCreate]
                                }
                            }
                            .font(FGFont.caption.weight(.medium))
                            .foregroundStyle(FGColor.goldDeep)
                            .padding(.top, FGSpace.xs)
                        }
                    }
                    .frame(maxWidth: 360)

                    if let errorMessage {
                        Text(errorMessage)
                            .font(FGFont.caption)
                            .foregroundStyle(FGColor.clayDeep)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, FGSpace.m)
                    }

                    if let successMessage {
                        Text(successMessage)
                            .font(FGFont.caption)
                            .foregroundStyle(FGColor.sageDeep)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, FGSpace.m)
                    }
                }
                .padding(.horizontal, FGSpace.page)
                .padding(.bottom, FGSpace.xl)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: FGSpace.s) {
            if showsHeroIllustration {
                WelcomeHeroIllustration()
                    .padding(.bottom, FGSpace.xs)
            } else {
                WelcomeHeroIllustration(compact: true)
                    .padding(.bottom, 2)
            }

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

    private func appleButton(label: SignInWithAppleButton.Label) -> some View {
        SignInWithAppleButton(
            label,
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
        .signInWithAppleButtonStyle(colorScheme == .dark ? .white : .black)
        .frame(height: 56)
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
                    dismissAfterAuth()
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
                    .frame(width: Self.providerIconSize, height: Self.providerIconSize)

                Text(mode == .signIn ? "Sign in with Google" : "Sign up with Google")
                    .font(Self.providerButtonFont)
                    .foregroundStyle(Color.black)
            }
            .frame(maxWidth: .infinity, minHeight: 56)
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

    @ViewBuilder
    private var googleGLogo: some View {
        if let image = Self.googleLogoImage {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
        } else {
            Image(systemName: "g.circle.fill")
                .resizable()
                .scaledToFit()
                .foregroundStyle(FGColor.ink)
        }
    }

    /// The real Google "G" mark, read straight from the GoogleSignIn SDK's own
    /// resource bundle — the same lookup `GoogleSignInButton` uses internally,
    /// reimplemented here because that helper isn't exposed publicly. Falls
    /// back to a plain glyph if the bundle ever can't be found.
    private static let googleLogoImage: UIImage? = {
        let bundleName = "GoogleSignIn_GoogleSignIn"
        let resourceBundle: Bundle? = {
            if let mainPath = Bundle.main.path(forResource: bundleName, ofType: "bundle") {
                return Bundle(path: mainPath)
            }
            let classBundle = Bundle(for: GIDSignIn.self)
            if let classPath = classBundle.path(forResource: bundleName, ofType: "bundle") {
                return Bundle(path: classPath)
            }
            return nil
        }()
        guard let url = resourceBundle?.url(forResource: "google", withExtension: "png") else { return nil }
        return UIImage(contentsOfFile: url.path)
    }()

    /// The hero entry screen's Google button — same dark pill as Apple/Email,
    /// carrying the real Google mark, rather than Google's own fixed-size
    /// light button which doesn't match the other two.
    private var googleContinueButton: some View {
        Button {
            signInWithGoogle()
        } label: {
            HStack(spacing: FGSpace.s) {
                googleGLogo
                    .frame(width: Self.providerIconSize, height: Self.providerIconSize)
                Text("Continue with Google")
                    .font(Self.providerButtonFont)
                    .foregroundStyle(FGColor.bg)
            }
            .frame(maxWidth: .infinity, minHeight: 56)
            .background(FGColor.ink)
            .clipShape(RoundedRectangle(cornerRadius: FGRadius.button, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(isLoading)
    }

    private func signInWithGoogle() {
        guard let windowScene = (UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first { $0.activationState == .foregroundActive }
            ?? UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first),
              let window = windowScene.windows.first(where: { $0.isKeyWindow }),
              var topVC = window.rootViewController else {
            errorMessage = "Unable to find presentation window."
            return
        }
        while let presented = topVC.presentedViewController {
            topVC = presented
        }

        isLoading = true
        errorMessage = nil
        Task {
            do {
                try await authService.signInWithGoogle(presentingViewController: topVC)
                isLoading = false
                onAuthenticated?()
                dismissAfterAuth()
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

            emailFieldsAndSubmit(mode: mode)
        }
    }

    /// Fields and submit action configured for the given mode.
    private func emailFieldsAndSubmit(mode: AuthMode) -> some View {
        VStack(spacing: FGSpace.s) {
            // Email Field
            TextField("Email address", text: $email)
                .font(FGFont.body)
                .foregroundStyle(FGColor.ink)
                .textContentType(mode == .signIn ? .username : .emailAddress)
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
                .textContentType(mode == .signIn ? .password : .newPassword)
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
                submitEmailAuth(mode: mode)
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

    private func submitEmailAuth(mode: AuthMode) {
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
                dismissAfterAuth()
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
            Button(guestButtonTitle) {
                dismissWithoutAuth()
            }
            .font(.system(size: 19, weight: .medium))
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

/// The app mark and a small cluster of the onboarding intent fruits, blooming
/// out of a soft apricot wash. Reuses the app-icon-reading trick from
/// `ProductIntroView.promiseHero` rather than a duplicated image asset, so this
/// always shows the exact shipping icon.
///
/// `compact` scales the whole cluster down for the milestone-nudge sheets
/// (save your routine, delete account, etc.) — every entry into auth gets the
/// same fruit-cluster signature, not just onboarding's first impression.
private struct WelcomeHeroIllustration: View {
    var compact: Bool = false

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [FGAura.apricot.core, FGAura.apricot.mid, FGAura.apricot.edge.opacity(0)],
                        center: .center,
                        startRadius: 0,
                        endRadius: compact ? 78 : 130
                    )
                )
                .frame(width: compact ? 150 : 240, height: compact ? 120 : 200)
                .offset(y: compact ? 10 : 18)

            VStack(spacing: compact ? -11 : -18) {
                FeelGoodAppIcon(size: compact ? 46 : 76)

                HStack(spacing: compact ? -9 : -14) {
                    fruit("IntentMobilityPear", size: compact ? 35 : 58, rotation: -10, offsetY: compact ? 6 : 10)
                    fruit("IntentEnergyClementine", size: compact ? 42 : 70, rotation: 0, offsetY: compact ? -4 : -6)
                    fruit("IntentCalmPeach", size: compact ? 36 : 60, rotation: 8, offsetY: compact ? 2 : 4)
                }
            }
        }
        .frame(maxWidth: .infinity, minHeight: compact ? 116 : 190)
        .accessibilityHidden(true)
    }

    private func fruit(_ name: String, size: CGFloat, rotation: Double, offsetY: CGFloat) -> some View {
        Image(name)
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
            .rotationEffect(.degrees(rotation))
            .offset(y: offsetY)
    }
}

/// Reads the shipping app icon from the compiled bundle so every account
/// prompt stays in sync if the icon changes later.
private struct FeelGoodAppIcon: View {
    let size: CGFloat

    var body: some View {
        Group {
            if let appIconImage {
                Image(uiImage: appIconImage)
                    .resizable()
                    .interpolation(.high)
                    .scaledToFit()
            } else {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(Color(light: 0x0D0C15, dark: 0x0D0C15))
                    .overlay {
                        Image(systemName: "heart.fill")
                            .font(.system(size: size * 0.34, weight: .medium))
                            .foregroundStyle(FGColor.clay)
                    }
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .shadow(color: FGColor.ink.opacity(0.12), radius: 10, y: 6)
    }

    private var cornerRadius: CGFloat { size * 0.224 }

    private var appIconImage: UIImage? {
        guard
            let icons = Bundle.main.object(forInfoDictionaryKey: "CFBundleIcons") as? [String: Any],
            let primary = icons["CFBundlePrimaryIcon"] as? [String: Any],
            let files = primary["CFBundleIconFiles"] as? [String]
        else { return nil }

        return files.reversed().lazy.compactMap(UIImage.init(named:)).first
    }
}

#Preview {
    AuthSheetView()
        .environment(AuthService.shared)
}

#Preview("Welcome & sign up") {
    AuthSheetView(
        title: "FeelGood",
        subtitle: "A menu, not a workout. Pick what fits today — no streaks, no scores.",
        showsHeroIllustration: true,
        initialMode: .createAccount,
        guestButtonTitle: "Not now — just show me today"
    )
    .environment(AuthService.shared)
}
