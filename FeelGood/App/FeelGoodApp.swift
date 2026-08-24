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
    }

}

/// Routing. No profile yet means onboarding; otherwise, today's menu.
struct RootView: View {
    let content: ContentStore?

    @Environment(\.modelContext) private var context
    @Query private var profiles: [UserProfile]
    @Query(sort: \SessionRecord.startedAt, order: .reverse) private var records: [SessionRecord]
    @Query private var affinity: [AffinityRecord]
    @Query(sort: \CustomSession.createdAt) private var ownSessions: [CustomSession]
    @Query(sort: \PlanDay.dayStart, order: .reverse) private var days: [PlanDay]
    @Query(sort: \CheckInRecord.takenAt, order: .reverse) private var checkIns: [CheckInRecord]

    var body: some View {
        Group {
            if let content {
                if let profile = profiles.first {
                    // Deliberately not re-keyed on the profile: an edit is
                    // applied to the live model instead, so changing your mind
                    // never throws away today's check-in.
                    TodayScreen(
                        content: content,
                        profile: profile,
                        history: records.map(\.historyEntry),
                        affinity: Dictionary(affinity.map { ($0.sessionID, $0.score) }, uniquingKeysWith: { first, _ in first }),
                        ownSessions: ownSessions.map(\.session),
                        log: SwiftDataActivityLog(context: context),
                        storedDay: storedDay(content: content),
                        storedCheckIn: storedCheckIn
                    )
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

private extension RootView {
    var todayStart: Date { Calendar.current.startOfDay(for: Date()) }

    /// The menu already generated for today, if there is one. Sessions resolve
    /// through the bundled catalog first and somebody's own kept workouts
    /// second — the engine draws from both, so restoring has to as well.
    func storedDay(content: ContentStore) -> Menu? {
        guard let today = days.first, today.dayStart == todayStart else { return nil }
        let own = Dictionary(ownSessions.map { ($0.id, $0.session) }, uniquingKeysWith: { first, _ in first })
        return today.menu { content.session(id: $0) ?? own[$0] }
    }

    /// Today's most recent answers, so the app doesn't ask twice.
    var storedCheckIn: PlanCheckIn? {
        guard let latest = checkIns.first, latest.dayStart == todayStart else { return nil }
        return latest.planCheckIn
    }
}

/// Owns the day's model so a swap or a check-in survives a re-render.
private struct TodayScreen: View {
    private let profile: UserProfile
    @State private var model: TodayModel

    init(
        content: ContentStore,
        profile: UserProfile,
        history: [HistoryEntry],
        affinity: [String: Double],
        ownSessions: [Session],
        log: any ActivityLogging,
        storedDay: Menu?,
        storedCheckIn: PlanCheckIn?
    ) {
        self.profile = profile
        _model = State(initialValue: TodayModel(
            store: content,
            profile: profile.planProfile,
            checkIn: storedCheckIn,
            history: history,
            affinity: affinity,
            ownSessions: ownSessions,
            log: log,
            restoring: storedDay,
            now: Date()
        ))
    }

    var body: some View {
        TodayView(model: model, answers: profile.answers) { answers in
            profile.apply(answers, now: Date())
        }
    }
}

#Preview("Onboarding") {
    OnboardingView { _ in }
}
