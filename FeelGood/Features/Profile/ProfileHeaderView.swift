//
//  ProfileHeaderView.swift
//  FeelGood
//
//  Identity, entirely optional and entirely separate from the plan: a
//  nickname (a preference, not a fact), Sign in with Apple (off by default,
//  never required to see a menu), subscription status, and the legal links
//  Apple requires. Nothing here feeds the engine or the copy layer — see
//  CLAUDE.md and `UserProfile`'s "Identity" section.
//

import AuthenticationServices
import PostHog
import SwiftUI

struct ProfileHeaderView: View {
    @Bindable var profile: UserProfile
    let onManageSubscription: () -> Void

    @Environment(PurchasesManager.self) private var purchasesManager
    @State private var signInErrorMessage: String?
    @FocusState private var isEditingNickname: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: FGSpace.m) {
            nicknameField
            identitySection
            subscriptionRow
            legalLinks
        }
        .padding(FGSpace.page)
        .padding(.bottom, FGSpace.s)
        .task { await refreshAppleCredentialState() }
        .alert(
            "Couldn't sign in",
            isPresented: Binding(
                get: { signInErrorMessage != nil },
                set: { if !$0 { signInErrorMessage = nil } }
            )
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(signInErrorMessage ?? "")
        }
    }

    // MARK: Nickname

    private var nicknameField: some View {
        TextField("Add a nickname", text: $profile.nickname)
            .font(FGFont.title)
            .foregroundStyle(FGColor.ink)
            .textFieldStyle(.plain)
            .textInputAutocapitalization(.words)
            .focused($isEditingNickname)
            .submitLabel(.done)
            .onSubmit { isEditingNickname = false }
            .accessibilityLabel("Nickname")
            .accessibilityHint("A name for you, shown only on this device")
            .postHogMask()
    }

    // MARK: Identity

    @ViewBuilder
    private var identitySection: some View {
        if profile.appleUserID != nil {
            HStack(spacing: FGSpace.s) {
                Image(systemName: "person.crop.circle.fill")
                    .foregroundStyle(FGColor.inkMuted)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Signed in with Apple")
                        .font(FGFont.body)
                        .foregroundStyle(FGColor.ink)
                        .postHogMask()
                    Button("Sign out", action: signOut)
                        .font(FGFont.caption)
                        .foregroundStyle(FGColor.inkMuted)
                }
                Spacer()
            }
        } else {
            SignInWithAppleButton(.signIn, onRequest: configure, onCompletion: handle)
                .signInWithAppleButtonStyle(.black)
                .frame(height: FGSize.minTouchTarget)
                .clipShape(RoundedRectangle(cornerRadius: FGRadius.button, style: .continuous))
        }
    }

    /// No scopes requested. Sign in with Apple is here so a subscription
    /// survives a reinstall or a new phone, and the app-scoped user id alone
    /// does that. Name and email were requested before, stored, and sent to
    /// PostHog — while the privacy policy said in five places that we collect
    /// neither. Asking for identity the product never uses is the part that
    /// was wrong, not the policy.
    private func configure(_ request: ASAuthorizationAppleIDRequest) {
        request.requestedScopes = []
    }

    private func handle(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            guard let credential = AppleCredential(authorization) else { return }
            profile.applyAppleSignIn(userID: credential.userID)
            Task { await purchasesManager.logIn(appUserID: credential.userID) }

        case .failure(let error):
            // Tapping "Cancel" on the system sheet is not something to alert
            // about — it's the same as never having tapped the button.
            if (error as? ASAuthorizationError)?.code == .canceled { return }
            signInErrorMessage = error.localizedDescription
        }
    }

    private func signOut() {
        profile.signOutOfApple()
        resetAnalyticsIdentity()
        Task { await purchasesManager.logOut() }
    }

    /// Analytics is never told who signed in. PostHog keeps its own
    /// per-install distinct id, which is what the privacy policy describes;
    /// calling `identify` with the Apple user id would tie every event to a
    /// stable account and make that description false again.
    private func resetAnalyticsIdentity() {
        guard isPostHogConfigured else { return }
        PostHogSDK.shared.reset()
    }

    private var isPostHogConfigured: Bool {
        guard let projectToken = Bundle.main.object(forInfoDictionaryKey: "PostHogProjectToken") as? String,
              let host = Bundle.main.object(forInfoDictionaryKey: "PostHogHost") as? String else {
            return false
        }
        return !projectToken.isEmpty && !host.isEmpty
    }

    /// Apple ID sign-in can be revoked from the user's device settings
    /// without the app ever hearing about it. A stale "signed in" row is
    /// worse than a quiet local sign-out the next time You is opened.
    private func refreshAppleCredentialState() async {
        guard let userID = profile.appleUserID else { return }
        let state = await withCheckedContinuation { continuation in
            ASAuthorizationAppleIDProvider().getCredentialState(forUserID: userID) { state, _ in
                continuation.resume(returning: state)
            }
        }
        if state == .revoked || state == .notFound {
            profile.signOutOfApple()
            resetAnalyticsIdentity()
        }
    }

    // MARK: Subscription

    private var subscriptionRow: some View {
        Button(action: onManageSubscription) {
            HStack(spacing: FGSpace.s) {
                Image(systemName: purchasesManager.isProUnlocked ? "checkmark.seal.fill" : "sparkles")
                    .foregroundStyle(purchasesManager.isProUnlocked ? FGColor.clayDeep : FGColor.inkMuted)
                Text(purchasesManager.isProUnlocked ? "FeelGood Pro" : "Free plan")
                    .font(FGFont.body.weight(.medium))
                    .foregroundStyle(FGColor.ink)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(FGColor.inkMuted)
            }
            .padding(FGSpace.m)
            .background(
                RoundedRectangle(cornerRadius: FGRadius.chip, style: .continuous)
                    .fill(FGColor.surface)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(purchasesManager.isProUnlocked ? "FeelGood Pro" : "Free plan")
        .accessibilityHint("Manage your subscription")
    }

    // MARK: Legal

    private var legalLinks: some View {
        HStack(spacing: FGSpace.m) {
            Link("Terms of Use", destination: LegalLinks.termsOfUse)
            Link("Privacy Policy", destination: LegalLinks.privacyPolicy)
        }
        .font(FGFont.caption)
        .foregroundStyle(FGColor.inkMuted)
    }
}

#Preview("Free, signed out") {
    ProfileHeaderView(profile: UserProfile(answers: ProfileAnswers(), now: .now)) {}
        .environment(PurchasesManager.shared)
}
