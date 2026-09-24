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
    @State private var isShowingLibrary = false
    @State private var isShowingPaywall = false
    @State private var libraryInitialSession: Session?
    @State private var libraryInitialActivity: Activity?
    @Environment(\.modelContext) private var modelContext
    @Environment(AuthService.self) private var authService
    #if DEBUG
    @State private var isDebugging = false
    #endif

    var body: some View {
        NavigationStack {
            page
                // Inside the NavigationStack, where the scroll view is; an inset
                // applied outside it does not reach this content.
                .fgTabBarInset()
                .toolbar(.hidden, for: .navigationBar)
        }
        .sheet(isPresented: $isShowingLibrary) {
            LibraryView(
                model: model,
                initialSession: libraryInitialSession,
                initialActivity: libraryInitialActivity
            )
        }
        .sheet(isPresented: $isShowingPaywall) {
            FeelGoodPaywallView()
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
                    profileHero

                    ActivityHistorySection(model: model)

                    LittleWinsSection(progress: model.littleWins)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, FGSpace.page)
                .padding(.top, FGSpace.s)
                .padding(.bottom, FGSpace.page)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
    }

    /// Preferences and account live behind one gear on the greeting's own row,
    /// instead of a row of pills under it — the greeting gets the room back.
    private var settingsMenu: some View {
        // Qualified: the engine's own `Menu` (today's menu) shadows SwiftUI's.
        SwiftUI.Menu {
            Button {
                isEditingProfile = true
            } label: {
                Label("My preferences", systemImage: "slider.horizontal.3")
            }
            Button {
                isShowingAccount = true
            } label: {
                Label("My account", systemImage: "person.crop.circle")
            }
        } label: {
            Image(systemName: "gearshape")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(FGColor.ink)
                .frame(width: FGSize.minTouchTarget, height: FGSize.minTouchTarget)
                .background(FGColor.surface.opacity(0.78), in: Circle())
                .overlay { Circle().strokeBorder(FGColor.lineStrong, lineWidth: 1) }
        }
        .accessibilityLabel("Settings")
        .accessibilityHint("Opens your preferences and account")
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
            .buttonStyle(.feelGoodPress)
            .accessibilityLabel("Profile mascot, \(profile.avatar.displayName)")
            .accessibilityHint("Choose a different mascot")

            Text(welcomeLine)
                .font(FGFont.sectionTitle)
                .foregroundStyle(FGColor.ink)
                .frame(maxWidth: .infinity, alignment: .leading)

            Button {
                if model.isProUser {
                    libraryInitialSession = nil
                    libraryInitialActivity = nil
                    isShowingLibrary = true
                } else {
                    isShowingPaywall = true
                }
            } label: {
                Image(systemName: "books.vertical")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(FGColor.ink)
                    .frame(width: FGSize.minTouchTarget, height: FGSize.minTouchTarget)
                    .background(FGColor.surface.opacity(0.78), in: Circle())
                    .overlay { Circle().strokeBorder(FGColor.lineStrong, lineWidth: 1) }
            }
            .accessibilityLabel("Library")
            .accessibilityHint("Browse all sessions")

            settingsMenu
        }
    }

    private func saveAvatar(_ avatar: ProfileAvatar) {
        guard profile.avatar != avatar else { return }
        profile.avatar = avatar
        try? modelContext.save()
        profile.publishWidgetAppearance()
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
        profile.publishWidgetAppearance()
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
        "You"
    }

}
