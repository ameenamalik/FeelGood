//
//  ProfileHeaderView.swift
//  FeelGood
//
//  Identity, entirely optional and entirely separate from the plan: a
//  nickname (a preference, not a fact), Authentication (Apple, Google,
//  Email/Password), subscription status, and the legal links
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
    @Environment(AuthService.self) private var authService
    @State private var signInErrorMessage: String?
    @State private var isShowingAuthSheet = false
    @State private var isShowingDeleteConfirmation = false
    @FocusState private var isEditingNickname: Bool
    @AppStorage(CalendarMovementPreferences.recognitionEnabledKey)
    private var isMovementRecognitionEnabled = false

    var body: some View {
        VStack(alignment: .leading, spacing: FGSpace.m) {
            nicknameField
            identitySection
            subscriptionRow
            if purchasesManager.isProUnlocked {
                calendarPrivacySection
            }
            legalLinks
        }
        .padding(FGSpace.page)
        .padding(.bottom, FGSpace.s)
        .sheet(isPresented: $isShowingAuthSheet) {
            AuthSheetView()
        }
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
        .confirmationDialog(
            "Delete Account",
            isPresented: $isShowingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete Account", role: .destructive) {
                handleDeleteAccount()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will delete your account credentials and sign you out. Your local on-device routine history remains intact.")
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

                HStack(spacing: FGSpace.m) {
                    Button("Sign out") {
                        handleSignOut()
                    }
                    .font(FGFont.caption.weight(.medium))
                    .foregroundStyle(FGColor.inkMuted)

                    Text("•")
                        .font(FGFont.caption)
                        .foregroundStyle(FGColor.line)

                    Button("Delete account") {
                        isShowingDeleteConfirmation = true
                    }
                    .font(FGFont.caption.weight(.medium))
                    .foregroundStyle(FGColor.clayDeep)
                }
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
            signInErrorMessage = error.localizedDescription
        }
    }

    private func handleDeleteAccount() {
        Task {
            do {
                try await authService.deleteAccount()
                profile.signOutOfApple()
                resetAnalyticsIdentity()
            } catch {
                signInErrorMessage = error.localizedDescription
            }
        }
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
        .environment(AuthService.shared)
}
