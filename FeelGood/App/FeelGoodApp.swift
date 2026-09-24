//
//  FeelGoodApp.swift
//  FeelGood
//

import SwiftUI
import SwiftData
import os
import PostHog
import FirebaseCore
import GoogleSignIn

@main
struct FeelGoodApp: App {
    @State private var storage: Storage
    /// Set when somebody chose to carry on without a store. Only reachable
    /// from `StoreUnavailableView`, and only for the life of this launch.
    @State private var isContinuingWithoutStore = false
    @State private var themeSettings = ThemeSettings()
    /// Loaded once at launch and handed down; the catalog never changes while
    /// the app is running.
    private let content: ContentStore?

    init() {
        if AuthService.isFirebaseConfigured {
            FirebaseApp.configure()
        }

        if let projectToken = Bundle.main.object(forInfoDictionaryKey: "PostHogProjectToken") as? String,
           let host = Bundle.main.object(forInfoDictionaryKey: "PostHogHost") as? String,
           !projectToken.isEmpty,
           !host.isEmpty {
            let config = PostHogConfig(projectToken: projectToken, host: host)
            config.errorTrackingConfig.autoCapture = true
            #if DEBUG
            // Set `config.debug = true` to diagnose replay: the capture path
            // fails closed and silently (an unsettled `.postHogMask()` reporter,
            // a view-controller transition, a WebP encode failure) and every one
            // of those bails is a `hedgeLog` gated on that flag.
            config.logs.environment = "debug"
            #else
            config.logs.environment = "production"
            #endif
            // Session replay is a different risk surface than events/logs: it
            // captures whatever's rendered, not an allow-listed payload. Keep
            // it available for local diagnosis, but never enable screenshot
            // capture in a Release build that handles private wellness input.
            //
            // `screenshotMode` is not optional for us. Wireframe reconstruction
            // walks a UIKit view hierarchy, and this app has none: the root
            // controller is a `UIHostingController`, so `PostHogReplayIntegration`
            // bails out of every snapshot with "SwiftUI snapshot not supported,
            // enable screenshotMode" and no initial snapshot ever leaves the
            // device.
            //
            // Masking is what carries the privacy decision, not the render mode.
            // The global masks are off because they black out the whole screen:
            // `maskAllTextInputs` redacts every `SwiftUI.CGDrawingView`, which is
            // what all `Text` and `Button` draw into, and this UI is almost
            // entirely text. Sensitive regions are instead named one at a time
            // with `.postHogMask()`.
            //
            // That trade is only safe while the list of masked views is actually
            // complete. It is allow-by-default: any screen that renders a
            // work-around label, a check-in answer, or a kept session's title and
            // is not explicitly masked ships those pixels to PostHog. See the
            // reproductive-health rule in CLAUDE.md before adding a screen.
            #if DEBUG
            config.sessionReplay = true
            config.sessionReplayConfig.maskAllTextInputs = false
            config.sessionReplayConfig.maskAllImages = false
            config.sessionReplayConfig.screenshotMode = true
            #else
            config.sessionReplay = false
            #endif
            PostHogSDK.shared.setup(config)
        } else {
            #if DEBUG
            assertionFailure("POSTHOG_PROJECT_TOKEN variable required by PostHog is missing or un-configured, this causes events to be silently missed. This error stops appearing once POSTHOG_PROJECT_TOKEN is configured")
            #endif
        }

        _storage = State(initialValue: Storage.open())
        content = try? ContentStore.bundled()
        // Must run before any view reads PurchasesManager.shared.isProUnlocked / offerings.
        PurchasesManager.shared.configure()
        OneSignalManager.shared.initialize(appId: OneSignalConstants.appID)
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if storage.isEphemeral && !isContinuingWithoutStore {
                    StoreUnavailableView(
                        onRetry: { storage = Storage.open() },
                        onContinueAnyway: { isContinuingWithoutStore = true }
                    )
                } else {
                    RootView(content: content)
                }
            }
            .environment(themeSettings)
        }
        .modelContainer(storage.container)
        .environment(PurchasesManager.shared)
        .environment(AuthService.shared)
    }

}

/// Routing. No profile yet means onboarding; otherwise, today's menu.
struct RootView: View {
    let content: ContentStore?

    @Environment(\.modelContext) private var context
    @Environment(AuthService.self) private var authService
    @Query private var profiles: [UserProfile]
    @State private var pendingExistingAccount: AuthUser?
    @State private var accountReloadID = UUID()
    @State private var accountSyncError: String?
    @State private var isSyncingAccount = false

    var body: some View {
        Group {
            #if DEBUG
            if ProcessInfo.processInfo.arguments.contains("-FGForceChatConsent") {
                DebugChatConsentHost()
            } else if ProcessInfo.processInfo.arguments.contains("-FGForcePaywall") {
                FeelGoodPaywallView()
            } else if ProcessInfo.processInfo.arguments.contains("-FGForceSettingUpMenu") {
                SettingUpMenuView(onComplete: {})
            } else {
                routedContent
            }
            #else
            routedContent
            #endif
        }
        .onChange(of: authService.currentUser?.uid, initial: true) { _, userID in
            guard let userID else {
                OneSignalManager.shared.logout()
                return
            }

            // Keep OneSignal's user identity aligned with Firebase so a person's
            // notification history and targeting follow their account, not a device.
            OneSignalManager.shared.login(externalId: userID)

            guard let user = authService.currentUser, let content else { return }
            Task {
                // Firebase's auth-state listener and the interactive method can
                // finish in either order. A brief debounce lets the method publish
                // whether this was account creation before deciding to prompt.
                try? await Task.sleep(for: .milliseconds(200))
                await handleAccountArrival(user: user, userID: userID, content: content)
            }
        }
        .onChange(of: profiles.count) { _, count in
            guard count > 0,
                  let userID = authService.currentUser?.uid,
                  let content else { return }
            runAccountSync {
                try await AccountDataSyncService.mergeLocalProgress(
                    into: userID,
                    context: context,
                    catalog: content.sessions
                )
            }
        }
        .confirmationDialog(
            "Choose your saved progress",
            isPresented: Binding(
                get: { pendingExistingAccount != nil },
                set: { if !$0 { pendingExistingAccount = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("Continue with both") {
                guard let user = pendingExistingAccount, let content else { return }
                pendingExistingAccount = nil
                runAccountSync {
                    try await AccountDataSyncService.mergeLocalProgress(
                        into: user.uid,
                        context: context,
                        catalog: content.sessions
                    )
                }
            }
            Button("Continue with account only", role: .destructive) {
                guard let user = pendingExistingAccount else { return }
                pendingExistingAccount = nil
                runAccountSync {
                    try await AccountDataSyncService.replaceLocalWithAccount(
                        userID: user.uid,
                        context: context
                    )
                }
            }
            Button("Continue as guest", role: .cancel) {
                pendingExistingAccount = nil
                try? authService.signOut()
            }
        } message: {
            Text("This phone has workouts or routines saved from before you signed in. Combine them with your account, or use the account's saved progress only. Using the account only removes the guest progress from this phone.")
        }
        .alert(
            "Progress couldn't sync",
            isPresented: Binding(
                get: { accountSyncError != nil },
                set: { if !$0 { accountSyncError = nil } }
            )
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(accountSyncError ?? "Your progress is still safe on this device.")
        }
        .onOpenURL { url in
            _ = GIDSignIn.sharedInstance.handle(url)
        }
        #if DEBUG
        .onAppear {
            if profiles.isEmpty {
                let initialProfile = UserProfile(
                    answers: ProfileAnswers(
                        activities: [.yoga, .strength, .walking],
                        places: [.home, .outdoors],
                        realisticMinutes: 30
                    ),
                    now: Date()
                )
                context.insert(initialProfile)
                try? context.save()
            }
        }
        #endif
    }

    @ViewBuilder
    private var routedContent: some View {
        if let content {
            if let profile = profiles.first {
                TodayScreen(
                    content: content,
                    profile: profile,
                    log: SessionLog(context: context)
                )
                .id("\(profile.updatedAt.timeIntervalSince1970)-\(accountReloadID.uuidString)")
            } else {
                FirstRunFlow { onboarding in
                    context.insert(onboarding.makeRecord(now: Date()))
                    try? context.save()
                }
            }
        } else {
            // The catalog ships in the bundle, so this is a build problem
            // rather than a user one — but it still must not be blank.
            ContentUnavailableView(
                "Content didn't load",
                systemImage: "leaf",
                description: Text("Reinstalling the app should fix it.")
            )
        }
    }

    @MainActor
    private func handleAccountArrival(user: AuthUser, userID: String, content: ContentStore) async {
        guard !isSyncingAccount else { return }
        let owner = AccountDataSyncService.localOwnerUID()

        if owner == userID || authService.lastAuthenticationCreatedAccount == nil {
            runAccountSync {
                try await AccountDataSyncService.mergeLocalProgress(
                    into: userID,
                    context: context,
                    catalog: content.sessions
                )
            }
        } else if authService.lastAuthenticationCreatedAccount == true {
            runAccountSync {
                try await AccountDataSyncService.mergeLocalProgress(
                    into: userID,
                    context: context,
                    catalog: content.sessions
                )
            }
        } else if AccountDataSyncService.hasGuestProgress(in: context) {
            pendingExistingAccount = user
        } else {
            runAccountSync {
                try await AccountDataSyncService.replaceLocalWithAccount(
                    userID: userID,
                    context: context
                )
            }
        }
    }

    @MainActor
    private func runAccountSync(_ operation: @escaping @MainActor () async throws -> Void) {
        guard !isSyncingAccount else { return }
        isSyncingAccount = true
        Task { @MainActor in
            do {
                try await operation()
                accountReloadID = UUID()
            } catch {
                accountSyncError = error.localizedDescription
            }
            isSyncingAccount = false
        }
    }
}

#if DEBUG
private struct DebugChatConsentHost: View {
    @State private var isPresented = false

    var body: some View {
        ZStack {
            FGColor.bg.ignoresSafeArea()
            FGBrandWash().ignoresSafeArea()
        }
        .task { isPresented = true }
        .sheet(isPresented: $isPresented) {
            ChatConsentSheet { _ in }
        }
    }
}
#endif

/// Owns the day's model so a swap or a check-in survives a re-render.
private struct TodayScreen: View {
    private let profile: UserProfile
    @State private var model: TodayModel

    init(content: ContentStore, profile: UserProfile, log: any SessionLogging) {
        self.profile = profile
        _model = State(initialValue: TodayModel(
            store: content,
            profile: profile.planProfile,
            log: log,
            copy: CopyService(),
            now: Date()
        ))
    }

    /// Which tab is showing, so a deep link can bring Today forward even if
    /// the app was last left on the reflection.
    @State private var tab = Destination.today
    @Environment(ThemeSettings.self) private var themeSettings
    /// A session the widget asked for. Cleared once Today has opened it.
    @State private var requestedSessionID: String?
    /// `model` is built once and lives for the process, so nothing else
    /// notices the calendar day rolling over while the app sat suspended in
    /// the background — a warm resume the next morning would otherwise keep
    /// showing yesterday's menu.
    @Environment(\.scenePhase) private var scenePhase

    /// Named `Destination` rather than `Tab`: a nested type called `Tab`
    /// shadows SwiftUI's `Tab` view and the TabView stops compiling.
    private enum Destination: Hashable { case today, explore, you }

    var body: some View {
        // Three tabs now, not two — a deliberate, explicit exception to the
        // PRD's "no tab, no browse" (§6). That rule is aimed at the glossary:
        // 873 browsable exercises is the overwhelm the app exists to remove.
        // Explore isn't a browsable list; it's the same redact-on-device →
        // Worker pipeline as the check-in sheet's "Describe Day" mode, given
        // its own persistent thread instead of a one-shot drawer. Today
        // stays the default and stays uncluttered; this is just how the
        // peers to it become reachable. Library and Settings land here too.
        // Keep the tab bar readable over the app's warm background wash.
        ZStack {
            // Keep one page surface alive while destinations switch. The tab
            // views are created lazily, so without this layer their first
            // rendered frame can briefly expose the system background.
            FGColor.bg.ignoresSafeArea()

            tabView
        }
        // The theme rides the trait bridge (Theme.swift), so every token under
        // here — and every sheet presented over it — resolves against it without
        // a view passing it along. Onboarding sits outside this and stays Kiln.
        .fgTheme(themeSettings.effective(unlocked: FGThemeID.unlocked(by: model.littleWins)))
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                model.refreshForNewDay()
            }
        }
    }

    private var tabView: some View {
        TabView(selection: $tab) {
            Tab("Today", systemImage: "sun.max", value: Destination.today) {
                TodayView(model: model, requestedSessionID: $requestedSessionID)
                    .fgTabBarInset()
                    .toolbarVisibility(.hidden, for: .tabBar)
            }
            Tab("Chat", systemImage: "bubble.left.and.bubble.right", value: Destination.explore) {
                ExploreView(model: model)
                    .toolbarVisibility(.hidden, for: .tabBar)
            }
            Tab("You", systemImage: "person", value: Destination.you) {
                YouView(model: model, profile: profile) { answers in
                    profile.apply(answers, now: Date())
                    if let userID = AuthService.shared.currentUser?.uid {
                        Task {
                            try? await AccountDataSyncService.syncProfile(
                                userID: userID,
                                profile: profile
                            )
                        }
                    }
                }
                .toolbarVisibility(.hidden, for: .tabBar)
            }
        }
        .tint(FGColor.ink)
        // The system bar is a see-through glass pill; ours is solid (TabBar.swift).
        .toolbarVisibility(.hidden, for: .tabBar)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            FGTabBar(
                items: [
                    FGTabBarItem(tag: Destination.today, title: "Today", systemImage: "sun.max"),
                    FGTabBarItem(tag: Destination.explore, title: "Chat", systemImage: "bubble.left.and.bubble.right"),
                    FGTabBarItem(tag: Destination.you, title: "You", systemImage: "person"),
                ],
                selection: $tab
            )
        }
        // Covers upgrades and restores: the widget learns the fruit on launch,
        // not only when it is next changed.
        .onAppear { profile.publishWidgetAppearance() }
        .onOpenURL { url in
            guard let id = DeepLink.sessionID(from: url) else { return }
            tab = .today
            requestedSessionID = id
        }
    }
}

#Preview("Onboarding") {
    OnboardingView { _ in }
}
