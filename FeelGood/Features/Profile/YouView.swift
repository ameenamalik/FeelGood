//
//  YouView.swift
//  FeelGood
//
//  The second tab. A quiet identity mark sits above the Look Back: recent
//  patterns rendered as observations, never scores or streaks. Account details
//  and the broader library wait behind secondary controls.
//

import SwiftData
import SwiftUI

struct YouView: View {
    let model: TodayModel
    @Bindable var profile: UserProfile
    let onProfileSaved: (ProfileAnswers) -> Void

    @State private var isEditingProfile = false
    @State private var isShowingSubscription = false
    @State private var isShowingAccount = false
    @State private var isShowingHiddenExercises = false
    @State private var isChoosingAvatar = false
    @Environment(\.modelContext) private var modelContext
    @Environment(AuthService.self) private var authService
    #if DEBUG
    @State private var isDebugging = false
    #endif

    var body: some View {
        NavigationStack {
            page
                .toolbar(.hidden, for: .navigationBar)
        }
        .sheet(isPresented: $isEditingProfile) {
            ProfileEditView(
                answers: profile.answers,
                onShowHiddenExercises: { isShowingHiddenExercises = true }
            ) { updated in
                onProfileSaved(updated)
                model.update(profile: updated.planProfile)
            }
            .sheet(isPresented: $isShowingHiddenExercises) {
                HiddenExercisesView(model: model)
            }
        }
        .sheet(isPresented: $isShowingAccount) {
            NavigationStack {
                ScrollView {
                    ProfileHeaderView(profile: profile) {
                        isShowingSubscription = true
                    }
                }
                .background(FGColor.bg)
                .navigationTitle("Account & privacy")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") { isShowingAccount = false }
                    }
                }
            }
            .sheet(isPresented: $isShowingSubscription) {
                NavigationStack {
                    SubscriptionSettingsView()
                }
            }
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $isChoosingAvatar) {
            ProfileAvatarPickerView(
                selection: Binding(
                    get: { profile.avatar },
                    set: { saveAvatar($0) }
                ),
                background: Binding(
                    get: { profile.avatarBackground },
                    set: { saveAvatarBackground($0) }
                )
            )
        }
        #if DEBUG
        .sheet(isPresented: $isDebugging) {
            DebugMenu(content: model.store) { model.reload() }
        }
        #endif
    }

    private var page: some View {
        ZStack {
            FGColor.bg.ignoresSafeArea()
            FGBrandWash(reach: 0.38).ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: FGSpace.l) {
                    profileHeader

                    VStack(alignment: .leading, spacing: FGSpace.s) {
                        Text("You, lately.")
                            .font(FGFont.display)
                            .foregroundStyle(FGColor.ink)
                            .accessibilityAddTraits(.isHeader)

                        Text("A quiet look at your last two weeks.")
                            .font(FGFont.body)
                            .foregroundStyle(FGColor.inkMuted)
                    }

                    LookBackView(reflection: model.lookBack(now: .now))

                    LittleWinsSection(progress: model.littleWins)

                    Text("FeelGood provides general wellness recommendations and is not a substitute for medical advice or physical therapy.")
                        .font(FGFont.caption)
                        .foregroundStyle(FGColor.inkMuted)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .padding(.top, FGSpace.m)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, FGSpace.page)
                .padding(.top, FGSpace.s)
                .padding(.bottom, FGSpace.page)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
    }

    private var profileHeader: some View {
        VStack(alignment: .leading, spacing: FGSpace.m) {
            profileHero

            HStack(spacing: FGSpace.s) {
                preferencePill(
                    "My preferences",
                    fill: FGAura.blush.core
                ) {
                    isEditingProfile = true
                }
                preferencePill(
                    "My account",
                    fill: FGAura.sage.core
                ) {
                    isShowingAccount = true
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    /// Filled factual-chip styling, matching the pills used on menu cards.
    private func preferencePill(
        _ title: String,
        fill: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundStyle(FGColor.inkOnAccent)
                .lineLimit(1)
                .minimumScaleFactor(0.88)
                .padding(.horizontal, FGSpace.s)
                .frame(maxWidth: .infinity, minHeight: 40)
                .background(Capsule().fill(fill))
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity, minHeight: FGSize.minTouchTarget)
        .contentShape(Rectangle())
    }

    @ViewBuilder
    private var profileHero: some View {
        #if DEBUG
        profileHeroContent
            .contextMenu {
                Button("Time travel", systemImage: "clock.arrow.circlepath") {
                    isDebugging = true
                }
            }
        #else
        profileHeroContent
        #endif
    }

    private var profileHeroContent: some View {
        HStack(spacing: FGSpace.s) {
            Button {
                isChoosingAvatar = true
            } label: {
                ProfileAvatarView(
                    avatar: profile.avatar,
                    background: profile.avatarBackground,
                    size: 48
                )
                    .overlay {
                        Circle().strokeBorder(FGColor.lineStrong, lineWidth: 1)
                    }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Profile mascot, \(profile.avatar.displayName)")
            .accessibilityHint("Choose a different mascot")

            Text(welcomeLine)
                .font(FGFont.sectionTitle)
                .foregroundStyle(FGColor.ink)
        }
    }

    private func saveAvatar(_ avatar: ProfileAvatar) {
        guard profile.avatar != avatar else { return }
        profile.avatar = avatar
        try? modelContext.save()
        Analytics.capture("profile_avatar_changed", properties: ["avatar": avatar.rawValue])

        if let userID = authService.currentUser?.uid {
            Task {
                try? await AccountDataSyncService.syncProfile(userID: userID, profile: profile)
            }
        }
    }

    private func saveAvatarBackground(_ background: ProfileAvatarBackground) {
        guard profile.avatarBackground != background else { return }
        profile.avatarBackground = background
        try? modelContext.save()
        Analytics.capture(
            "profile_avatar_background_changed",
            properties: ["background": background.rawValue]
        )

        if let userID = authService.currentUser?.uid {
            Task {
                try? await AccountDataSyncService.syncProfile(userID: userID, profile: profile)
            }
        }
    }

    private var welcomeLine: String {
        let name = profile.nickname.trimmingCharacters(in: .whitespacesAndNewlines)
        return name.isEmpty ? "Welcome back" : "Welcome back, \(name)"
    }

}
