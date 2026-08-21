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

    /// A store that cannot be opened must not be a crash on launch. Falling
    /// back to memory means she still gets a menu today; the failure is logged
    /// and the next launch tries the real store again.
    private static func makeContainer() -> ModelContainer {
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

/// Placeholder root. Onboarding and the Today menu land in week 2; this exists
/// so the target builds and runs while the engine and content go in.
struct RootView: View {
    var body: some View {
        ZStack {
            FGColor.cream.ignoresSafeArea()
            VStack(spacing: FGSpace.s) {
                Text("FeelGood")
                    .font(FGFont.display)
                    .foregroundStyle(FGColor.ink)
                Text("Here's today.")
                    .font(FGFont.reason)
                    .foregroundStyle(FGColor.inkMuted)
            }
        }
    }
}

#Preview {
    RootView()
}
