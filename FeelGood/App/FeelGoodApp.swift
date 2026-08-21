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

    init() {
        container = Self.makeContainer()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
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
    /// back to memory means she still gets a menu today; the failure is logged
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

/// Root routing. Onboarding lands in week 2; until then the menu is built from
/// a stand-in profile so the real engine and the real catalog drive the screen.
struct RootView: View {
    var body: some View {
        if let store = try? ContentStore.bundled() {
            TodayView(model: TodayModel(store: store, profile: .standIn, now: Date()))
        } else {
            // The catalog is bundled, so this is a build problem, not a user
            // one — but it still must not be a blank screen.
            ContentUnavailableView(
                "Content didn't load",
                systemImage: "leaf",
                description: Text("Reinstalling the app should fix it.")
            )
        }
    }
}

extension PlanProfile {
    /// Stands in for onboarding: a mat, some weights, and the outdoors.
    static var standIn: PlanProfile {
        PlanProfile(
            availableActivities: [
                .pilates, .yoga, .stretching, .walking, .strength,
                .breathwork, .qigong, .dance, .carries
            ],
            equipment: [.none, .mat, .weights, .outdoor],
            cadence: .mostDays,
            realisticMinutes: 30,
            bestTimeOfDay: .morning,
            intent: .strengthen,
            workArounds: []
        )
    }
}

#Preview {
    RootView()
}
