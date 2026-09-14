//
//  AccountDataSyncService.swift
//  FeelGood
//
//  Bridges the app's local-first SwiftData store and an optional Firebase
//  account. Guest progress is never uploaded until authentication succeeds,
//  and retries are idempotent.
//

import Foundation
import SwiftData

@MainActor
enum AccountDataSyncService {
    static let localOwnerKey = "FeelGood.LocalDataOwnerUID.v1"

    private struct CompletionSnapshot {
        let sessionID: String
        let title: String
        let startedAt: Date
        let endedAt: Date
        let durationMin: Int
        let activity: String
        let qualities: [String]
        let intensity: Int
        let course: String
        let place: String?
        let feel: String?
    }

    static func hasGuestProgress(in context: ModelContext) -> Bool {
        let completions = (try? context.fetch(FetchDescriptor<SessionRecord>())) ?? []
        if completions.contains(where: \.wasCompleted) { return true }
        let routines = (try? context.fetch(FetchDescriptor<CustomSession>())) ?? []
        return !routines.isEmpty
    }

    static func localOwnerUID(defaults: UserDefaults = .standard) -> String? {
        defaults.string(forKey: localOwnerKey)
    }

    static func syncProfile(userID: String, profile: UserProfile) async throws {
        try await FirestoreService.shared.saveUserPreferences(
            userId: userID,
            data: preferenceData(from: profile)
        )
    }

    /// Used for a newly created account and for the explicit "add this device"
    /// choice. Local progress is uploaded first, then any already-remote data is
    /// imported so both sides converge without duplicate completions.
    static func mergeLocalProgress(
        into userID: String,
        context: ModelContext,
        catalog: [Session]
    ) async throws {
        try await uploadLocalData(userID: userID, context: context, catalog: catalog)
        try await importCloudData(userID: userID, context: context)
        UserDefaults.standard.set(userID, forKey: localOwnerKey)
    }

    /// Uses only the signed-in account's history. This is the safe choice when
    /// somebody signs into an existing account on a device holding guest data.
    static func replaceLocalWithAccount(
        userID: String,
        context: ModelContext
    ) async throws {
        clearActivityData(in: context, removeProfile: false)
        try await importCloudData(userID: userID, context: context)
        UserDefaults.standard.set(userID, forKey: localOwnerKey)
    }

    /// Account data remains in Firebase; only the device cache is removed.
    /// Removing the profile returns RootView to the product intro/onboarding,
    /// which creates a genuinely separate guest rather than exposing the last
    /// account's preferences.
    static func clearAccountDataFromDevice(context: ModelContext) {
        clearActivityData(in: context, removeProfile: true)
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: localOwnerKey)
        defaults.removeObject(forKey: "sessionProgress.v1")
        defaults.removeObject(forKey: "FeelGood.ChatThreads.v1")
        defaults.removeObject(forKey: "FeelGood.ActiveThreadID.v1")
        defaults.removeObject(forKey: "FeelGood.ChatHistory.v2")
    }

    private static func uploadLocalData(
        userID: String,
        context: ModelContext,
        catalog: [Session]
    ) async throws {
        let sessionsByID = Dictionary(uniqueKeysWithValues: catalog.map { ($0.id, $0) })
        let records = (try? context.fetch(FetchDescriptor<SessionRecord>())) ?? []
        let completions: [CompletionSnapshot] = records.compactMap { record in
            guard record.wasCompleted else { return nil }
            let session = sessionsByID[record.sessionID]
            return CompletionSnapshot(
                sessionID: record.sessionID,
                title: session?.title ?? "Completed session",
                startedAt: record.startedAt,
                endedAt: record.endedAt ?? record.startedAt,
                durationMin: record.durationMin,
                activity: record.activityRaw,
                qualities: record.qualitiesRaw,
                intensity: record.intensity,
                course: record.courseRaw,
                place: record.placeRaw,
                feel: record.feelRaw
            )
        }

        for item in completions {
            try await FirestoreService.shared.recordCompletion(
                userId: userID,
                sessionTitle: item.title,
                sessionID: item.sessionID,
                startedAt: item.startedAt,
                endedAt: item.endedAt,
                durationMin: item.durationMin,
                activity: item.activity,
                qualities: item.qualities,
                intensity: item.intensity,
                course: item.course,
                place: item.place,
                feel: item.feel,
                recordID: FirestoreService.completionID(
                    sessionID: item.sessionID,
                    startedAt: item.startedAt
                )
            )
        }

        let routines = (try? context.fetch(FetchDescriptor<CustomSession>())) ?? []
        for routine in routines {
            try await FirestoreService.shared.saveCustomWorkout(
                id: routine.id,
                userId: userID,
                title: routine.title,
                description: routine.sessionDescription,
                parts: routine.parts.map(FirestoreCustomRoutinePart.init),
                durationMin: routine.durationMin,
                intensity: routine.intensity,
                course: routine.courseRaw,
                activity: routine.activityRaw
            )
        }

        if let profile = try? context.fetch(FetchDescriptor<UserProfile>()).first {
            try await syncProfile(userID: userID, profile: profile)
        }
    }

    private static func importCloudData(userID: String, context: ModelContext) async throws {
        let cloudCompletions = try await FirestoreService.shared.fetchAllCompletions(userId: userID)
        let cloudRoutines = try await FirestoreService.shared.fetchAllCustomWorkouts(userId: userID)
        let cloudPreferences = try await FirestoreService.shared.fetchUserPreferences(userId: userID)

        let localRecords = (try? context.fetch(FetchDescriptor<SessionRecord>())) ?? []
        var completionKeys = Set(localRecords.filter(\.wasCompleted).map {
            completionKey(sessionID: $0.sessionID, startedAt: $0.startedAt)
        })

        for remote in cloudCompletions {
            let key = completionKey(sessionID: remote.sessionID ?? remote.sessionTitle, startedAt: remote.startedAt)
            guard completionKeys.insert(key).inserted else { continue }

            let activity = remote.activity.flatMap(Activity.init(rawValue:)) ?? .stretching
            let course = remote.course.flatMap(Course.init(rawValue:))
                ?? inferredCourse(for: remote.durationMin ?? 10)
            let session = Session.own(
                id: remote.sessionID ?? "synced-\(remote.id)",
                title: remote.sessionTitle,
                activity: activity,
                durationMin: remote.durationMin ?? 10,
                intensity: remote.intensity ?? 1,
                course: course
            )
            let record = SessionRecord(
                session: session,
                startedAt: remote.startedAt,
                dayStart: Calendar.current.startOfDay(for: remote.endedAt),
                endedAt: remote.endedAt,
                outcome: .completed(feel: remote.feel.flatMap(Feel.init(rawValue:))),
                place: remote.place.flatMap(Place.init(rawValue:))
            )
            if let qualities = remote.qualities, !qualities.isEmpty {
                record.qualitiesRaw = qualities
            }
            context.insert(record)
        }

        let existingRoutineIDs = Set(((try? context.fetch(FetchDescriptor<CustomSession>())) ?? []).map(\.id))
        for remote in cloudRoutines where !existingRoutineIDs.contains(remote.id) {
            context.insert(CustomSession(
                id: remote.id,
                title: remote.title,
                description: remote.description,
                parts: remote.parts?.map(\.customRoutinePart) ?? [],
                activity: remote.activity.flatMap(Activity.init(rawValue:)) ?? .stretching,
                durationMin: remote.durationMin,
                intensity: remote.intensity,
                course: remote.course.flatMap(Course.init(rawValue:)),
                createdAt: remote.createdAt
            ))
        }

        if let cloudPreferences,
           let profile = try? context.fetch(FetchDescriptor<UserProfile>()).first {
            apply(cloudPreferences, to: profile)
        }
        try context.save()
    }

    private static func clearActivityData(in context: ModelContext, removeProfile: Bool) {
        try? context.delete(model: SessionRecord.self)
        try? context.delete(model: AffinityRecord.self)
        try? context.delete(model: CheckInRecord.self)
        try? context.delete(model: PlanDay.self)
        try? context.delete(model: CustomSession.self)
        if removeProfile {
            try? context.delete(model: UserProfile.self)
        }
        try? context.save()
    }

    private static func completionKey(sessionID: String, startedAt: Date) -> String {
        FirestoreService.completionID(sessionID: sessionID, startedAt: startedAt)
    }

    /// `pregnancy`, `postpartum`, and `pelvicFloor` are reproductive health
    /// data (see CLAUDE.md and `CopyPayload.swift`). `CopyPayload` and the
    /// PostHog mask already keep them off the LLM-copy and session-replay
    /// channels; Firestore account sync is a third channel that needs the
    /// same boundary, since it's what a linked identity and the privacy
    /// manifest actually see.
    private static let deviceOnlyWorkArounds: Set<WorkAround> = [.pregnancy, .postpartum, .pelvicFloor]

    private static func preferenceData(from profile: UserProfile) -> [String: Any] {
        let syncableWorkArounds = profile.answers.workArounds
            .subtracting(deviceOnlyWorkArounds)
            .map(\.rawValue)
            .sorted()
        var data: [String: Any] = [
            "activities": profile.activitiesRaw,
            "sports": profile.sportsRaw,
            "equipment": profile.equipmentRaw,
            "places": profile.placesRaw,
            "cadence": profile.cadenceRaw,
            "moments": profile.momentsRaw,
            "realisticMinutes": profile.realisticMinutes,
            "bestTimeOfDay": profile.bestTimeOfDayRaw,
            "intents": profile.intentsRaw,
            "workArounds": syncableWorkArounds,
            "hiddenSessionIDs": profile.hiddenSessionIDsRaw,
            "nickname": profile.nickname,
            "avatarID": profile.avatar.rawValue,
            "avatarBackgroundID": profile.avatarBackground.rawValue,
            "updatedAt": profile.updatedAt,
        ]
        if let reminderHour = profile.reminderHour {
            data["reminderHour"] = reminderHour
        }
        return data
    }

    private static func apply(_ data: [String: Any], to profile: UserProfile) {
        let current = profile.answers
        let answers = ProfileAnswers(
            activities: decodedSet(data["activities"], fallback: current.activities),
            sports: decodedSet(data["sports"], fallback: current.sports),
            equipment: decodedSet(data["equipment"], fallback: current.equipment),
            places: decodedSet(data["places"], fallback: current.places),
            cadence: (data["cadence"] as? String).flatMap(Cadence.init(rawValue:)) ?? current.cadence,
            moments: (data["moments"] as? String).flatMap(MovementMoments.init(rawValue:)) ?? current.moments,
            realisticMinutes: data["realisticMinutes"] as? Int ?? current.realisticMinutes,
            bestTimeOfDay: (data["bestTimeOfDay"] as? String).flatMap(TimeOfDay.init(rawValue:)) ?? current.bestTimeOfDay,
            intents: decodedSet(data["intents"], fallback: current.intents),
            // Subtracting here too, not just on upload, guards against a
            // document written before this boundary existed still carrying
            // one of the three values.
            workArounds: decodedSet(data["workArounds"], fallback: current.workArounds)
                .subtracting(deviceOnlyWorkArounds),
            hiddenSessionIDs: Set((data["hiddenSessionIDs"] as? [String]) ?? Array(current.hiddenSessionIDs))
        )
        profile.apply(answers, now: Date())
        if let nickname = data["nickname"] as? String { profile.nickname = nickname }
        if let avatarID = data["avatarID"] as? String,
           ProfileAvatar(rawValue: avatarID) != nil {
            profile.avatarRaw = avatarID
        }
        if let backgroundID = data["avatarBackgroundID"] as? String,
           ProfileAvatarBackground(rawValue: backgroundID) != nil {
            profile.avatarBackgroundRaw = backgroundID
        }
        if let reminder = data["reminderHour"] as? Int { profile.reminderHour = reminder }
    }

    private static func decodedSet<Value: RawRepresentable & Hashable>(
        _ value: Any?,
        fallback: Set<Value>
    ) -> Set<Value> where Value.RawValue == String {
        guard let raw = value as? [String] else { return fallback }
        return Set(raw.compactMap(Value.init(rawValue:)))
    }

    private static func inferredCourse(for durationMin: Int) -> Course {
        switch durationMin {
        case ...5: .appetizer
        case ...10: .side
        default: .main
        }
    }
}
