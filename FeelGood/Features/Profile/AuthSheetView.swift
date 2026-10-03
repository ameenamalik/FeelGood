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
import OSLog
import SwiftUI
import UIKit

struct AuthSheetView: View {
    /// Apple's native authorization control owns its typography and renders
    /// slightly larger than an ordinary 19-point SwiftUI label. Use this
    /// optical match for the adjacent custom provider buttons.
    private static let providerButtonFont = Font.system(size: 18, weight: .semibold)
    private static let providerIconSize: CGFloat = 18
    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "com.ameenamalik.FeelGood",
        category: "Authentication"
    )

    var title: String = "FeelGood"
    var subtitle: String = "Keep your movement history and daily menus synced across devices."
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
    @State private var showsPassword: Bool = false
    @State private var isLoading: Bool = false
    @State private var errorMessage: String? = nil
    @State private var successMessage: String? = nil
    @State private var currentRawNonce: String = ""
    @State private var path: [HeroStage] = []
    @State private var appleAuthorizationPerformer = AppleAuthorizationPerformer()

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
        title: String = "FeelGood",
        subtitle: String = "Keep your movement history and daily menus synced across devices.",
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

                GeometryReader { proxy in
                    ScrollView {
                        VStack(spacing: 18) {
                            headerSection

                            heroEntryButtons

                            if let errorMessage {
                                feedbackBanner(errorMessage, isError: true)
                            }

                            if let successMessage {
                                feedbackBanner(successMessage, isError: false)
                            }

                            guestFooter

                            Spacer(minLength: FGSpace.xl)

                            privacyCard
                        }
                        .frame(
                            minHeight: max(0, proxy.size.height - FGSpace.xxl),
                            alignment: .top
                        )
                        .padding(.horizontal, FGSpace.page)
                        .padding(.top, showsHeroIllustration ? 40 : FGSpace.l)
                        .padding(.bottom, FGSpace.l)
                    }
                    .scrollBounceBehavior(.basedOnSize)
                }
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

    // MARK: - Account entry

    /// Keep every account prompt calm and consistent: provider choices first,
    /// then a focused email screen only after the person chooses email.
    private var heroEntryButtons: some View {
        VStack(spacing: 9) {
            appleButton
            googleContinueButton
            emailContinueButton

            Button {
                openEmailStage(accountSwitchStage)
            } label: {
                accountSwitchLabel
            }
            .padding(.top, 10)
            .disabled(isLoading)

            if isLoading {
                ProgressView()
                    .tint(FGColor.ink)
                    .padding(.top, FGSpace.xs)
            }
        }
        .frame(maxWidth: 420)
        .padding(.top, 12)
    }

    private var primaryEmailStage: HeroStage {
        if showsHeroIllustration { return .emailCreate }
        return mode == .createAccount ? .emailCreate : .emailSignIn
    }

    private var accountSwitchStage: HeroStage {
        primaryEmailStage == .emailCreate ? .emailSignIn : .emailCreate
    }

    private var accountSwitchLabel: some View {
        HStack(spacing: 5) {
            Text(primaryEmailStage == .emailCreate ? "Already have an account?" : "New to FeelGood?")
                .foregroundStyle(FGColor.inkMuted)

            Text(primaryEmailStage == .emailCreate ? "Sign in" : "Create an account")
                .fontWeight(.semibold)
                .foregroundStyle(FGColor.ink)
                .underline()
        }
        .font(.system(size: 14, weight: .regular))
        .multilineTextAlignment(.center)
    }

    private var emailContinueButton: some View {
        Button {
            openEmailStage(primaryEmailStage)
        } label: {
            HStack(spacing: FGSpace.s) {
                Image(systemName: "envelope")
                    .font(.system(size: Self.providerIconSize, weight: .semibold))
                Text("Continue with email")
                    .font(Self.providerButtonFont)
            }
            .foregroundStyle(FGColor.onAuthChoiceFill)
            .frame(maxWidth: .infinity, minHeight: 50)
            .background(FGColor.authChoiceFill)
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

            GeometryReader { proxy in
                ScrollView {
                    VStack(spacing: FGSpace.l) {
                        VStack(spacing: FGSpace.s) {
                            WelcomeHeroIllustration(compact: false)
                                .padding(.bottom, -4)

                            Text(stage == .emailCreate ? "Create an account" : "Welcome back")
                                .font(.system(size: 30, weight: .semibold, design: .rounded))
                                .tracking(-0.15)
                                .foregroundStyle(FGColor.ink)
                                .multilineTextAlignment(.center)

                            Text(
                                stage == .emailCreate
                                    ? "Save your menus and movement history across devices."
                                    : "Sign in and we'll pick up right where your menu left off."
                            )
                            .font(FGFont.body)
                            .foregroundStyle(FGColor.inkMuted)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(.top, FGSpace.m)

                        VStack(spacing: FGSpace.s) {
                            emailFieldsAndSubmit(mode: currentMode)

                            if stage == .emailCreate {
                                Button {
                                    withAnimation(FGMotion.gentle) {
                                        errorMessage = nil
                                        successMessage = nil
                                        path = [.emailSignIn]
                                    }
                                } label: {
                                    accountDestinationSwitchLabel(
                                        prompt: "Already have an account?",
                                        action: "Sign in"
                                    )
                                }
                                .padding(.top, FGSpace.xs)
                            } else {
                                Button {
                                    withAnimation(FGMotion.gentle) {
                                        errorMessage = nil
                                        successMessage = nil
                                        path = [.emailCreate]
                                    }
                                } label: {
                                    accountDestinationSwitchLabel(
                                        prompt: "Don't have an account?",
                                        action: "Create one"
                                    )
                                }
                                .padding(.top, FGSpace.xs)
                            }
                        }
                        .frame(maxWidth: 360)

                        if let errorMessage {
                            feedbackBanner(errorMessage, isError: true)
                        }

                        if let successMessage {
                            feedbackBanner(successMessage, isError: false)
                        }

                        Spacer(minLength: FGSpace.l)

                        privacyCard
                    }
                    .frame(
                        minHeight: max(0, proxy.size.height - FGSpace.l),
                        alignment: .top
                    )
                    .padding(.horizontal, FGSpace.page)
                    .padding(.bottom, FGSpace.l)
                }
                .scrollBounceBehavior(.basedOnSize)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            // Provider callbacks and email destinations share this view's
            // state. Never carry an old provider failure into a fresh form.
            errorMessage = nil
            successMessage = nil
        }
    }

    private func openEmailStage(_ stage: HeroStage) {
        errorMessage = nil
        successMessage = nil
        path.append(stage)
    }

    private func accountDestinationSwitchLabel(prompt: String, action: String) -> some View {
        HStack(spacing: 4) {
            Text(prompt)
                .foregroundStyle(FGColor.inkMuted)

            Text(action)
                .fontWeight(.semibold)
                .foregroundStyle(FGColor.goldDeep)
                .underline()
        }
        .font(FGFont.caption)
        .multilineTextAlignment(.center)
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 10) {
            WelcomeHeroIllustration(compact: !showsHeroIllustration)

            Text(title)
                .font(.system(
                    size: title == "FeelGood" ? 34 : (showsHeroIllustration ? 30 : 24),
                    weight: title == "FeelGood" ? .regular : .semibold,
                    design: .rounded
                ))
                .tracking(-0.15)
                .foregroundStyle(FGColor.ink)
                .multilineTextAlignment(.center)

            Text(subtitle)
                .font(.system(size: 15, weight: .regular))
                .lineSpacing(2)
                .foregroundStyle(FGColor.inkMuted)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: 430)
        }
        .padding(.top, showsHeroIllustration ? FGSpace.m : FGSpace.s)
    }

    // MARK: - Apple Sign In Button

    private var appleButton: some View {
        Button {
            beginAppleSignIn()
        } label: {
            HStack(spacing: FGSpace.s) {
                Image(systemName: "apple.logo")
                    .font(.system(size: Self.providerIconSize, weight: .semibold))

                Text("Continue with Apple")
                    .font(Self.providerButtonFont)
            }
            .foregroundStyle(colorScheme == .dark ? Color.black : Color.white)
            .frame(maxWidth: .infinity, minHeight: 50)
            .background(colorScheme == .dark ? Color.white : Color.black)
            .clipShape(RoundedRectangle(cornerRadius: FGRadius.button, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(isLoading)
        .accessibilityLabel("Continue with Apple")
        .accessibilityHint("Signs in using your Apple Account")
    }

    private func beginAppleSignIn() {
        errorMessage = nil
        let nonce = AuthService.randomNonceString()
        currentRawNonce = nonce

        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = AuthService.sha256(nonce)

        appleAuthorizationPerformer.perform(request: request) { result in
            handleAppleResult(result)
        }
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
                    logProviderFailure("Apple", error: error)
                }
            }
        case .failure(let error):
            if (error as? ASAuthorizationError)?.code != .canceled {
                logProviderFailure("Apple", error: error)
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
            .frame(maxWidth: .infinity, minHeight: 50)
            .background(FGColor.authChoiceFill)
            .clipShape(RoundedRectangle(cornerRadius: FGRadius.button, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: FGRadius.button, style: .continuous)
                    .strokeBorder(FGColor.line.opacity(0.8), lineWidth: 1)
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
                    .foregroundStyle(Color.black)
            }
            .frame(maxWidth: .infinity, minHeight: 50)
            .background(FGColor.authChoiceFill)
            .clipShape(RoundedRectangle(cornerRadius: FGRadius.button, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: FGRadius.button, style: .continuous)
                    .strokeBorder(FGColor.line.opacity(0.8), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .disabled(isLoading)
    }

    private func signInWithGoogle() {
        guard let windowScene = (UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first { $0.activationState == .foregroundActive }
            ?? UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first),
              let window = windowScene.windows.first(where: { $0.isKeyWindow }),
              var topVC = window.rootViewController else {
            Self.logger.error("Google sign-in failed: no presentation window")
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
                    logProviderFailure("Google", error: error)
                }
            }
        }
    }

    /// Provider failures are generally configuration or system errors rather
    /// than something a person can repair in this sheet. Keep the raw detail
    /// in Console/Xcode instead of exposing framework diagnostics in the UI.
    private func logProviderFailure(_ provider: String, error: Error) {
        let nsError = error as NSError
        Self.logger.error(
            "\(provider, privacy: .public) sign-in failed [\(nsError.domain, privacy: .public):\(nsError.code)]: \(nsError.localizedDescription)"
        )
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
        let canSubmit = !isLoading
            && !email.trimmingCharacters(in: .whitespaces).isEmpty
            && !password.isEmpty

        return VStack(spacing: FGSpace.s) {
            // Email Field
            TextField(
                "",
                text: $email,
                prompt: Text("Email address").foregroundStyle(FGColor.inkMuted)
            )
                .font(FGFont.body)
                .foregroundStyle(FGColor.ink)
                .textContentType(mode == .signIn ? .username : .emailAddress)
                // A new identity per mode: iOS reads the content type when the
                // field is created and can keep the first one it saw, so a
                // sign-in/sign-up switch would leave AutoFill on the wrong kind.
                .id("email-\(mode)")
                .textInputAutocapitalization(.never)
                .keyboardType(.emailAddress)
                .autocorrectionDisabled(true)
                .padding(.horizontal, FGSpace.m)
                .padding(.vertical, 14)
                .background(FGColor.surface)
                .clipShape(RoundedRectangle(cornerRadius: FGRadius.chip, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: FGRadius.chip, style: .continuous)
                        .strokeBorder(FGColor.lineStrong.opacity(0.72), lineWidth: 1)
                )

            // Password Field
            HStack(spacing: FGSpace.s) {
                Group {
                    if showsPassword {
                        TextField(
                            "",
                            text: $password,
                            prompt: Text("Password").foregroundStyle(FGColor.inkMuted)
                        )
                    } else {
                        SecureField(
                            "",
                            text: $password,
                            prompt: Text("Password").foregroundStyle(FGColor.inkMuted)
                        )
                    }
                }
                .font(FGFont.body)
                .foregroundStyle(FGColor.ink)
                .textContentType(mode == .signIn ? .password : .newPassword)
                .id("password-\(mode)")
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled(true)

                Button {
                    showsPassword.toggle()
                } label: {
                    Image(systemName: showsPassword ? "eye.slash" : "eye")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(FGColor.inkMuted)
                        .frame(width: 32, height: 32)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(showsPassword ? "Hide password" : "Show password")
            }
            .padding(.leading, FGSpace.m)
            .padding(.trailing, FGSpace.s)
            .padding(.vertical, 10)
            .background(FGColor.surface)
            .clipShape(RoundedRectangle(cornerRadius: FGRadius.chip, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: FGRadius.chip, style: .continuous)
                    .strokeBorder(FGColor.lineStrong.opacity(0.72), lineWidth: 1)
            )

            // Action Button
            Button {
                submitEmailAuth(mode: mode)
            } label: {
                HStack {
                    Spacer()
                    if isLoading {
                        ProgressView()
                            .tint(FGColor.onActionFill)
                    } else {
                        Text(mode == .signIn ? "Sign In" : "Create Account")
                            .font(FGFont.body.weight(.semibold))
                    }
                    Spacer()
                }
                .padding(.vertical, 14)
                .foregroundStyle(canSubmit ? FGColor.onActionFill : FGColor.inkMuted)
                .background(canSubmit ? FGColor.actionFill : FGColor.surface.opacity(0.72))
                .clipShape(RoundedRectangle(cornerRadius: FGRadius.button, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: FGRadius.button, style: .continuous)
                        .strokeBorder(
                            canSubmit ? Color.clear : FGColor.lineStrong.opacity(0.4),
                            lineWidth: 1
                        )
                )
            }
            .buttonStyle(.feelGoodPress)
            .disabled(!canSubmit)

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
                successMessage = "Password reset email sent. Please check your inbox and spam folder."
            } catch {
                isLoading = false
                errorMessage = error.localizedDescription
            }
        }
    }

    // MARK: - Guest Footer

    private func feedbackBanner(_ message: String, isError: Bool) -> some View {
        HStack(alignment: .top, spacing: FGSpace.s) {
            Image(systemName: isError ? "exclamationmark.circle" : "checkmark.circle")
                .font(.system(size: 16, weight: .semibold))

            Text(message)
                .font(FGFont.caption)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .foregroundStyle(isError ? FGColor.clayDeep : FGColor.sageDeep)
        .padding(FGSpace.m)
        .background(
            colorScheme == .dark
                ? FGColor.surface.opacity(0.42)
                : (isError ? FGAura.blush.core : FGAura.sage.core).opacity(0.45)
        )
        .clipShape(RoundedRectangle(cornerRadius: FGRadius.chip, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: FGRadius.chip, style: .continuous)
                .strokeBorder(isError ? FGColor.clay : FGColor.sage, lineWidth: 1)
        )
        .frame(maxWidth: 420)
        .transition(.opacity)
    }

    private var privacyCard: some View {
        VStack(spacing: FGSpace.m) {
            Rectangle()
                .fill(FGColor.line)
                .frame(height: 1)

            Text(privacyCopy)
                .font(.system(size: 14, weight: .regular))
                .foregroundStyle(FGColor.inkMuted)
                .tint(FGColor.inkMuted)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: 420)
    }

    private var privacyCopy: AttributedString {
        let markdown = "We use sign-in only to keep your choices synced. We never sell your personal information. [Privacy policy](\(LegalLinks.privacyPolicy.absoluteString))"
        guard var copy = try? AttributedString(markdown: markdown) else {
            return AttributedString("We use sign-in only to keep your choices synced. We never sell your personal information. Privacy policy")
        }
        for run in copy.runs where run.link != nil {
            copy[run.range].underlineStyle = .single
        }
        return copy
    }

    private var guestFooter: some View {
        Button(guestButtonTitle) {
            dismissWithoutAuth()
        }
        .font(.system(size: 16, weight: .medium))
        .foregroundStyle(FGColor.ink)
        .underline()
        .padding(.top, FGSpace.xs)
    }
}

@MainActor
private final class AppleAuthorizationPerformer: NSObject,
    ASAuthorizationControllerDelegate,
    ASAuthorizationControllerPresentationContextProviding
{
    private var controller: ASAuthorizationController?
    private var completion: ((Result<ASAuthorization, Error>) -> Void)?

    func perform(
        request: ASAuthorizationAppleIDRequest,
        completion: @escaping (Result<ASAuthorization, Error>) -> Void
    ) {
        self.completion = completion

        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = self
        self.controller = controller
        controller.performRequests()
    }

    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        finish(with: .success(authorization))
    }

    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithError error: Error
    ) {
        finish(with: .failure(error))
    }

    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        if let window = scenes
            .first(where: { $0.activationState == .foregroundActive })?
            .windows
            .first(where: \.isKeyWindow)
        {
            return window
        }
        return scenes.first?.windows.first ?? ASPresentationAnchor()
    }

    private func finish(with result: Result<ASAuthorization, Error>) {
        let completion = completion
        self.completion = nil
        controller = nil
        completion?(result)
    }
}

/// The shipping app icon presented in its normal rounded-square shape.
private struct WelcomeHeroIllustration: View {
    var compact: Bool = false

    var body: some View {
        FeelGoodAppIcon(size: compact ? 60 : 82)
            .frame(maxWidth: .infinity, minHeight: compact ? 70 : 96)
            .accessibilityHidden(true)
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
                    .fill(FGColor.appIconFallback)
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
