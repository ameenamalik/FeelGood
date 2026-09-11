//
//  ProfileHeaderView.swift
//  FeelGood
//
//  Identity, entirely optional and entirely separate from the plan: a
//  nickname (a preference, not a fact), Authentication (Apple, Google,
//  Email/Password), subscription status, account deletion, and the legal links
//  Apple requires. Nothing here feeds the engine or the copy layer — see
//  CLAUDE.md and `UserProfile`'s "Identity" section.
//

import AuthenticationServices
import PostHog
import SwiftData
import SwiftUI

struct ProfileHeaderView: View {
    @Bindable var profile: UserProfile
    let onManageSubscription: () -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(PurchasesManager.self) private var purchasesManager
    @Environment(AuthService.self) private var authService
    @State private var errorMessage: String?
    @State private var errorTitle = "Error"
    @State private var isShowingAuthSheet = false
    @State private var isShowingDeleteConfirmation = false
    @State private var isShowingSignedOutDeleteDialog = false
    @State private var isShowingDeletionSuccess = false
    @State private var isShowingResetSuccess = false
    @State private var isShowingAcknowledgements = false
    @State private var isDeletingAccount = false
    @State private var isShowingAppleReauth = false
    @State private var reauthAppleNonce = ""
    @State private var isShowingGoogleReauthPrompt = false
    @State private var isShowingPasswordReauthPrompt = false
    @State private var passwordForReauth = ""
    @AppStorage(CalendarMovementPreferences.recognitionEnabledKey)
    private var isMovementRecognitionEnabled = false

    var body: some View {
        VStack(alignment: .leading, spacing: FGSpace.m) {
            identitySection
            subscriptionRow
            if purchasesManager.isProUnlocked {
                calendarPrivacySection
            }
            accountDeletionSection
            legalLinks
        }
        .padding(FGSpace.page)
        .padding(.bottom, FGSpace.s)
        .sheet(isPresented: $isShowingAuthSheet) {
            AuthSheetView()
                .environment(authService)
                .environment(purchasesManager)
        }
        .sheet(isPresented: $isShowingAcknowledgements) {
            NavigationStack { AcknowledgementsView() }
        }
        .sheet(isPresented: $isShowingAppleReauth) {
            NavigationStack {
                VStack(spacing: FGSpace.l) {
                    Image(systemName: "apple.logo")
                        .font(.system(size: 48))
                        .foregroundStyle(FGColor.ink)
                        .padding(.top, FGSpace.xl)

                    VStack(spacing: FGSpace.s) {
                        Text("Confirm Apple ID")
                            .font(FGFont.title)
                            .foregroundStyle(FGColor.ink)

                        Text("Apple requires confirming your Apple ID to permanently revoke access and delete your account.")
                            .font(FGFont.body)
                            .foregroundStyle(FGColor.inkMuted)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, FGSpace.m)
                    }

                    SignInWithAppleButton(.continue) { request in
                        let nonce = AuthService.randomNonceString()
                        reauthAppleNonce = nonce
                        request.requestedScopes = [.fullName, .email]
                        request.nonce = AuthService.sha256(nonce)
                    } onCompletion: { result in
                        handleAppleReauthResult(result)
                    }
                    .signInWithAppleButtonStyle(.black)
                    .frame(height: 56)
                    .clipShape(RoundedRectangle(cornerRadius: FGRadius.button, style: .continuous))
                    .padding(.horizontal, FGSpace.page)

                    if isDeletingAccount {
                        ProgressView("Deleting account...")
                            .tint(FGColor.clayDeep)
                    }

                    Spacer()
                }
                .padding(FGSpace.page)
                .background(FGColor.bg.ignoresSafeArea())
                .navigationTitle("Verify Identity")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            isShowingAppleReauth = false
                        }
                    }
                }
            }
            .presentationDetents([.medium])
        }
        .confirmationDialog(
            "Confirm Google Account",
            isPresented: $isShowingGoogleReauthPrompt,
            titleVisibility: .visible
        ) {
            Button("Continue with Google") {
                handleGoogleReauth()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Google requires verifying your account before permanently deleting it.")
        }
        .alert(
            "Confirm Password",
            isPresented: $isShowingPasswordReauthPrompt
        ) {
            SecureField("Password", text: $passwordForReauth)
            Button("Delete Account", role: .destructive) {
                handlePasswordReauth()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Please enter your account password to confirm permanent account deletion.")
        }
        .alert(
            errorTitle,
            isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "")
        }
        .confirmationDialog(
            "Delete Account?",
            isPresented: $isShowingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete Account", role: .destructive) {
                handleDeleteAccount()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete your account, synced preferences, and cloud data. This action cannot be undone.")
        }
        .confirmationDialog(
            "Delete Account",
            isPresented: $isShowingSignedOutDeleteDialog,
            titleVisibility: .visible
        ) {
            Button("Sign In to Delete Account") {
                isShowingAuthSheet = true
            }
            Button("Reset Local Data", role: .destructive) {
                handleResetLocalData()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("You are not currently signed in. If you created an account with Apple, Google, or email, please sign in first to delete your cloud account. You can also reset all local data on this device.")
        }
        .alert(
            "Account Deleted",
            isPresented: $isShowingDeletionSuccess
        ) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("Your account and cloud data have been permanently deleted.")
        }
        .alert(
            "Local Data Reset",
            isPresented: $isShowingResetSuccess
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Your local profile preferences on this device have been cleared.")
        }
    }

    // MARK: Identity

    @ViewBuilder
    private var identitySection: some View {
        if let user = authService.currentUser {
            VStack(alignment: .leading, spacing: FGSpace.s) {
                HStack(spacing: FGSpace.s) {
                    Image(systemName: "person.crop.circle.fill")
                        .font(.title2)
                        .foregroundStyle(FGColor.sageDeep)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(user.email ?? user.displayName ?? "Signed In")
                            .font(FGFont.body.weight(.medium))
                            .foregroundStyle(FGColor.ink)
                            .postHogMask()

                        Text("Signed in with \(user.providerDisplay)")
                            .font(FGFont.caption)
                            .foregroundStyle(FGColor.inkMuted)
                    }

                    Spacer()
                }

                Button("Sign out") {
                    handleSignOut()
                }
                .font(FGFont.caption.weight(.medium))
                .foregroundStyle(FGColor.inkMuted)
                .padding(.leading, 32)
            }
            .padding(FGSpace.m)
            .background(
                RoundedRectangle(cornerRadius: FGRadius.chip, style: .continuous)
                    .fill(FGColor.surface)
            )
        } else {
            Button {
                isShowingAuthSheet = true
            } label: {
                HStack(spacing: FGSpace.s) {
                    Image(systemName: "person.crop.circle.badge.plus")
                        .foregroundStyle(FGColor.goldDeep)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Sign in or create account")
                            .font(FGFont.body.weight(.medium))
                            .foregroundStyle(FGColor.ink)

                        Text("Save your routines and keep your history synced")
                            .font(FGFont.caption)
                            .foregroundStyle(FGColor.inkMuted)
                    }

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
            .accessibilityLabel("Sign in or create account")
            .accessibilityHint("Save your routines across devices with Apple, Google, or email")
        }
    }

    private func handleSignOut() {
        do {
            try authService.signOut()
            profile.signOutOfApple()
            resetAnalyticsIdentity()
        } catch {
            errorTitle = "Couldn't sign out"
            errorMessage = error.localizedDescription
        }
    }

    @MainActor
    private func clearAllUserData() {
        profile.apply(ProfileAnswers(), now: Date())
        profile.nickname = ""
        profile.signOutOfApple()

        try? modelContext.delete(model: SessionRecord.self)
        try? modelContext.delete(model: AffinityRecord.self)
        try? modelContext.delete(model: CheckInRecord.self)
        try? modelContext.delete(model: PlanDay.self)
        try? modelContext.save()

        resetAnalyticsIdentity()
    }

    private func handleDeleteAccount() {
        isDeletingAccount = true
        Task {
            do {
                try await authService.deleteAccount()
                clearAllUserData()
                isDeletingAccount = false
                isShowingDeletionSuccess = true
            } catch let error as AuthError where error == .requiresRecentLogin {
                isDeletingAccount = false
                handleReauthenticationRequired()
            } catch {
                isDeletingAccount = false
                errorTitle = "Couldn't delete account"
                errorMessage = error.localizedDescription
            }
        }
    }

    private func handleReauthenticationRequired() {
        guard let provider = authService.currentUser?.providerID else {
            errorTitle = "Authentication Required"
            errorMessage = "For security, please sign in again before deleting your account."
            return
        }

        switch provider {
        case "apple.com":
            isShowingAppleReauth = true
        case "google.com":
            isShowingGoogleReauthPrompt = true
        case "password":
            passwordForReauth = ""
            isShowingPasswordReauthPrompt = true
        default:
            isShowingAuthSheet = true
        }
    }

    private func handleAppleReauthResult(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            isDeletingAccount = true
            Task {
                do {
                    try await authService.reauthenticateAndDeleteWithApple(
                        authorization: authorization,
                        rawNonce: reauthAppleNonce
                    )
                    clearAllUserData()
                    isDeletingAccount = false
                    isShowingAppleReauth = false
                    isShowingDeletionSuccess = true
                } catch {
                    isDeletingAccount = false
                    errorTitle = "Couldn't delete account"
                    errorMessage = error.localizedDescription
                }
            }
        case .failure(let error):
            if (error as? ASAuthorizationError)?.code != .canceled {
                errorTitle = "Couldn't verify Apple ID"
                errorMessage = error.localizedDescription
            }
        }
    }

    private func handleGoogleReauth() {
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

        isDeletingAccount = true
        Task {
            do {
                try await authService.reauthenticateAndDeleteWithGoogle(presentingViewController: topVC)
                clearAllUserData()
                isDeletingAccount = false
                isShowingDeletionSuccess = true
            } catch {
                isDeletingAccount = false
                errorTitle = "Couldn't delete account"
                errorMessage = error.localizedDescription
            }
        }
    }

    private func handlePasswordReauth() {
        let trimmedPassword = passwordForReauth
        guard !trimmedPassword.isEmpty else { return }

        isDeletingAccount = true
        Task {
            do {
                try await authService.reauthenticateAndDeleteWithPassword(password: trimmedPassword)
                clearAllUserData()
                isDeletingAccount = false
                isShowingDeletionSuccess = true
            } catch {
                isDeletingAccount = false
                errorTitle = "Couldn't delete account"
                errorMessage = error.localizedDescription
            }
        }
    }

    private func handleResetLocalData() {
        clearAllUserData()
        isShowingResetSuccess = true
    }

    /// Analytics is never told who signed in. PostHog keeps its own
    /// per-install distinct id, which is what the privacy policy describes.
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

    // MARK: Calendar privacy

    private var calendarPrivacySection: some View {
        Toggle(isOn: $isMovementRecognitionEnabled) {
            VStack(alignment: .leading, spacing: 3) {
                Text("Recognize movement plans")
                    .font(FGFont.body.weight(.medium))
                    .foregroundStyle(FGColor.ink)
                Text("Checks Calendar event names on this device for workouts and classes. Names are never saved or shared.")
                    .font(FGFont.caption)
                    .foregroundStyle(FGColor.inkMuted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .tint(FGColor.gold)
        .padding(FGSpace.m)
        .background(
            RoundedRectangle(cornerRadius: FGRadius.chip, style: .continuous)
                .fill(FGColor.surface)
        )
        .postHogMask()
    }

    // MARK: Account Deletion & Data

    private var accountDeletionSection: some View {
        VStack(alignment: .leading, spacing: FGSpace.xs) {
            Text("Account & Data")
                .font(FGFont.caption.weight(.semibold))
                .foregroundStyle(FGColor.inkMuted)
                .textCase(.uppercase)
                .padding(.horizontal, FGSpace.xs)

            Button(role: .destructive) {
                if authService.currentUser != nil {
                    isShowingDeleteConfirmation = true
                } else {
                    isShowingSignedOutDeleteDialog = true
                }
            } label: {
                HStack(spacing: FGSpace.s) {
                    Image(systemName: "trash")
                        .font(.body)
                        .foregroundStyle(FGColor.clayDeep)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Delete account")
                            .font(FGFont.body.weight(.medium))
                            .foregroundStyle(FGColor.clayDeep)

                        Text(authService.currentUser != nil
                            ? "Permanently delete your account and cloud data"
                            : "Sign in to delete your cloud account, or reset local data")
                            .font(FGFont.caption)
                            .foregroundStyle(FGColor.inkMuted)
                    }

                    Spacer()

                    if isDeletingAccount {
                        ProgressView()
                            .tint(FGColor.clayDeep)
                    } else {
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(FGColor.inkMuted)
                    }
                }
                .padding(FGSpace.m)
                .background(
                    RoundedRectangle(cornerRadius: FGRadius.chip, style: .continuous)
                        .fill(FGColor.surface)
                )
            }
            .buttonStyle(.plain)
            .disabled(isDeletingAccount)
            .accessibilityLabel("Delete account")
            .accessibilityHint(authService.currentUser != nil
                ? "Permanently deletes your account and cloud data"
                : "Sign in to delete cloud account or reset local data")
        }
    }

    // MARK: Legal

    private var legalLinks: some View {
        HStack(spacing: FGSpace.m) {
            Link("Terms of Use", destination: LegalLinks.termsOfUse)
            Link("Privacy Policy", destination: LegalLinks.privacyPolicy)
            Button("Acknowledgements") { isShowingAcknowledgements = true }
        }
        .font(FGFont.caption)
        .foregroundStyle(FGColor.inkMuted)
    }
}

#Preview("Free, signed out") {
    ProfileHeaderView(profile: UserProfile(answers: ProfileAnswers(), now: .now)) {}
        .environment(PurchasesManager.shared)
        .environment(AuthService.shared)
}

