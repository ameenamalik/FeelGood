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
            // captures whatever's rendered, not an allow-listed payload.
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
            config.sessionReplay = true
            config.sessionReplayConfig.maskAllTextInputs = false
            config.sessionReplayConfig.maskAllImages = false
            config.sessionReplayConfig.screenshotMode = true
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
    }

    var body: some Scene {
        WindowGroup {
            if storage.isEphemeral && !isContinuingWithoutStore {
                StoreUnavailableView(
                    onRetry: { storage = Storage.open() },
                    onContinueAnyway: { isContinuingWithoutStore = true }
                )
            } else {
                RootView(content: content)
            }
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
    @Query private var profiles: [UserProfile]

    var body: some View {
        Group {
            if let content {
                if let profile = profiles.first {
                    TodayScreen(
                        content: content,
                        profile: profile,
                        log: SessionLog(context: context)
                    )
                    .id(profile.updatedAt)
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
        .onOpenURL { url in
            _ = GIDSignIn.sharedInstance.handle(url)
        }
    }
}

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
    /// A session the widget asked for. Cleared once Today has opened it.
    @State private var requestedSessionID: String?

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
        // instead. Only pre-26 needs that explicit material.
        tabView
            .toolbarBackground(.ultraThinMaterial, for: .tabBar)
            .toolbarBackground(.visible, for: .tabBar)
    }

    private var tabView: some View {
        TabView(selection: $tab) {
            Tab("Today", systemImage: "sun.max", value: Destination.today) {
                TodayView(model: model, requestedSessionID: $requestedSessionID)
            }
            Tab("Chat", systemImage: "bubble.left.and.bubble.right", value: Destination.explore) {
                ProGateView {
                    ExploreView(model: model)
                }
            }
            Tab("You", systemImage: "person", value: Destination.you) {
                YouView(model: model, profile: profile) { answers in
                    profile.apply(answers, now: Date())
                }
            }
        }
        .tint(FGColor.ink)
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
