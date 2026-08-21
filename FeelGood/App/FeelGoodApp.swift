//
//  FeelGoodApp.swift
//  FeelGood
//

import SwiftUI
import SwiftData
import os

@main
struct FeelGoodApp: App {
    private let container: ModelContainer
    /// Loaded once at launch and handed down; the catalog never changes while
    /// the app is running.
    private let content: ContentStore?

    init() {
        container = Self.makeContainer()
        content = try? ContentStore.bundled()
    }

    var body: some Scene {
        WindowGroup {
            RootView(content: content)
        }
        .modelContainer(container)
    }

    /// On a fresh install `Library/Application Support` does not exist yet.
    /// CoreData will get there eventually, but only after stat-ing every parent
    /// directory and logging several hundred lines of diagnostics first.
    /// Creating it up front keeps first launch quiet and the store path honest.
    private static func prepareStoreDirectory() {
        do {
            try FileManager.default.url(
                for: .applicationSupportDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            )
        } catch {
            // Not fatal: the container below still tries, and falls back to
            // memory if the store genuinely cannot be opened.
            Logger(subsystem: "com.ameenamalik.FeelGood", category: "storage")
                .error("Could not prepare Application Support: \(error, privacy: .public)")
        }
    }

    /// A store that cannot be opened must not be a crash on launch. Falling
    /// back to memory means there is still a menu today; the failure is logged
    /// and the next launch tries the real store again.
    private static func makeContainer() -> ModelContainer {
        prepareStoreDirectory()
        let schema = Schema(FeelGoodSchema.models)
        do {
            return try ModelContainer(
                for: schema,
                configurations: [ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)]
            )
        } catch {
            Logger(subsystem: "com.ameenamalik.FeelGood", category: "storage")
                .error("Persistent store unavailable, running in memory: \(error, privacy: .public)")
            return try! ModelContainer(
                for: schema,
                configurations: [ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)]
            )
        }
    }
}

/// Routing. No profile yet means onboarding; otherwise, today's menu.
struct RootView: View {
    let content: ContentStore?

    @Environment(\.modelContext) private var context
    @Query private var profiles: [UserProfile]
    @Query(sort: \SessionRecord.startedAt, order: .reverse) private var records: [SessionRecord]

    var body: some View {
        Group {
            if let content {
                if let profile = profiles.first {
                    TodayScreen(
                        content: content,
                        profile: profile.planProfile,
                        history: records.map(\.historyEntry)
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
    @State private var model: TodayModel

    init(content: ContentStore, profile: PlanProfile, history: [HistoryEntry]) {
        _model = State(initialValue: TodayModel(
            store: content,
            profile: profile,
            history: history,
            now: Date()
        ))
    }

    var body: some View {
        TodayView(model: model)
    }
}

#Preview("Onboarding") {
    OnboardingView { _ in }
}
