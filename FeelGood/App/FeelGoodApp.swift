//
//  FeelGoodApp.swift
//  FeelGood
//

import SwiftUI
import SwiftData
import os

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
                    OnboardingView { onboarding in
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
    private enum Destination: Hashable { case today, you }

    var body: some View {
        // Two tabs, and only two. The PRD's "no tab, no browse" (§6) is aimed
        // at the glossary — 873 browsable exercises is the overwhelm the app
        // exists to remove — not at the app's own shell. Today stays the
        // default and stays uncluttered; this is just how the peers to it
        // become reachable. Library and Settings land here too.
        TabView(selection: $tab) {
            Tab("Today", systemImage: "sun.max", value: Destination.today) {
                TodayView(model: model, requestedSessionID: $requestedSessionID)
            }
            Tab("You", systemImage: "person", value: Destination.you) {
                YouView(model: model, profile: profile) { answers in
                    profile.apply(answers, now: Date())
                }
            }
        }
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
