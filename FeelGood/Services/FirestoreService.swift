//
//  FirestoreService.swift
//  FeelGood
//
//  Cloud Firestore integration for syncing user preferences, completed workouts,
//  and custom dopamine menu items.
//
//  Follows firebase-firestore guidelines:
//  - Only import FirebaseFirestore (no FirebaseFirestoreSwift)
//  - Safe lazy initialization (never inline Firestore.firestore() before configure)
//  - Listener lifecycles are managed explicitly when auth state changes
//

import FirebaseCore
@preconcurrency import FirebaseFirestore
import Foundation
import SwiftUI

// MARK: - Firestore Models

public struct FirestoreCompletionRecord: Codable, Sendable, Identifiable {
    public var id: String
    public var userId: String
    public var sessionTitle: String
    public var sessionID: String?
    public var startedAt: Date
    public var endedAt: Date
    public var durationMin: Int?
    public var activity: String?
    public var qualities: [String]?
    public var intensity: Int?
    public var course: String?
    public var place: String?
    public var feel: String?
    public var timestamp: Date

    public init(
        id: String = UUID().uuidString,
        userId: String,
        sessionTitle: String,
        sessionID: String? = nil,
        startedAt: Date,
        endedAt: Date,
        durationMin: Int? = nil,
        activity: String? = nil,
        qualities: [String]? = nil,
        intensity: Int? = nil,
        course: String? = nil,
        place: String? = nil,
        feel: String? = nil,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.sessionTitle = sessionTitle
        self.sessionID = sessionID
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.durationMin = durationMin
        self.activity = activity
        self.qualities = qualities
        self.intensity = intensity
        self.course = course
        self.place = place
        self.feel = feel
        self.timestamp = timestamp
    }
}

public struct FirestoreCustomRoutinePart: Codable, Sendable, Identifiable {
    public var id: String
    public var title: String
    public var durationMin: Int
    public var cue: String?

    public init(id: String = UUID().uuidString, title: String, durationMin: Int, cue: String? = nil) {
        self.id = id
        self.title = title
        self.durationMin = durationMin
        self.cue = cue
    }

    init(_ part: CustomRoutinePart) {
        id = part.id
        title = part.title
        durationMin = part.durationMin
        cue = part.cue
    }

    var customRoutinePart: CustomRoutinePart {
        CustomRoutinePart(id: id, title: title, durationMin: durationMin, cue: cue)
    }
}

public struct FirestoreCustomWorkout: Codable, Sendable, Identifiable {
    public var id: String
    public var userId: String
    public var title: String
    public var description: String?
    public var parts: [FirestoreCustomRoutinePart]?
    public var durationMin: Int
    public var intensity: Int
    public var course: String?
    public var activity: String?
    public var createdAt: Date

    public init(
        id: String = UUID().uuidString,
        userId: String,
        title: String,
        description: String? = nil,
        parts: [FirestoreCustomRoutinePart]? = nil,
        durationMin: Int,
        intensity: Int,
        course: String? = nil,
        activity: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.title = title
        self.description = description
        self.parts = parts
        self.durationMin = durationMin
        self.intensity = intensity
        self.course = course
        self.activity = activity
        self.createdAt = createdAt
    }
}

// MARK: - Firestore Service

@Observable
@MainActor
public final class FirestoreService: Sendable {
    public static let shared = FirestoreService()

    public private(set) var customWorkouts: [FirestoreCustomWorkout] = []
    public private(set) var recentCompletions: [FirestoreCompletionRecord] = []

    private var workoutsListener: ListenerRegistration?
    private var completionsListener: ListenerRegistration?

    private var db: Firestore? {
        guard AuthService.isFirebaseConfigured && FirebaseApp.app() != nil else {
            return nil
        }
        return Firestore.firestore()
    }

    public init() {}

    // MARK: - Sync & Realtime Listeners

    public func startListening(for userId: String) {
        stopListening()

        guard let db else { return }

        // 1. Listen for custom kept workouts
        workoutsListener = db.collection("users")
            .document(userId)
            .collection("custom_workouts")
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let documents = snapshot?.documents, error == nil else { return }
                let items = documents.compactMap { doc -> FirestoreCustomWorkout? in
                    try? doc.data(as: FirestoreCustomWorkout.self)
                }
                Task { @MainActor [weak self] in
                    self?.customWorkouts = items
                }
            }

        // 2. Listen for workout completions
        completionsListener = db.collection("users")
            .document(userId)
            .collection("completions")
            .order(by: "timestamp", descending: true)
            .limit(to: 50)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let documents = snapshot?.documents, error == nil else { return }
                let items = documents.compactMap { doc -> FirestoreCompletionRecord? in
                    try? doc.data(as: FirestoreCompletionRecord.self)
                }
                Task { @MainActor [weak self] in
                    self?.recentCompletions = items
                }
            }
    }

    public func stopListening() {
        workoutsListener?.remove()
        workoutsListener = nil
        completionsListener?.remove()
        completionsListener = nil
        customWorkouts = []
        recentCompletions = []
    }

    // MARK: - Workout Completion Recording

    public func recordCompletion(
        userId: String,
        sessionTitle: String,
        sessionID: String,
        startedAt: Date,
        endedAt: Date,
        durationMin: Int,
        activity: String,
        qualities: [String] = [],
        intensity: Int = 1,
        course: String? = nil,
        place: String? = nil,
        feel: String? = nil,
        recordID: String? = nil
    ) async throws {
        guard let db else { return }
        let record = FirestoreCompletionRecord(
            id: recordID ?? Self.completionID(sessionID: sessionID, startedAt: startedAt),
            userId: userId,
            sessionTitle: sessionTitle,
            sessionID: sessionID,
            startedAt: startedAt,
            endedAt: endedAt,
            durationMin: durationMin,
            activity: activity,
            qualities: qualities,
            intensity: intensity,
            course: course,
            place: place,
            feel: feel
        )
        try db.collection("users")
            .document(userId)
            .collection("completions")
            .document(record.id)
            .setData(from: record)
    }

    /// A stable document id makes guest-history claiming retry-safe. A failed
    /// upload can be run again without creating duplicate badge progress.
    nonisolated public static func completionID(sessionID: String, startedAt: Date) -> String {
        let safeSessionID = sessionID
            .replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: " ", with: "-")
        let milliseconds = Int64((startedAt.timeIntervalSince1970 * 1_000).rounded())
        return "\(safeSessionID)-\(milliseconds)"
    }

    public func fetchAllCompletions(userId: String) async throws -> [FirestoreCompletionRecord] {
        guard let db else { return [] }
        let snapshot = try await db.collection("users")
            .document(userId)
            .collection("completions")
            .getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: FirestoreCompletionRecord.self) }
    }

    // MARK: - Custom Workouts Persistence

    public func saveCustomWorkout(
        id: String? = nil,
        userId: String,
        title: String,
        description: String? = nil,
        parts: [FirestoreCustomRoutinePart]? = nil,
        durationMin: Int,
        intensity: Int,
        course: String? = nil,
        activity: String? = nil
    ) async throws {
        guard let db else { return }
        let workout = FirestoreCustomWorkout(
            id: id ?? UUID().uuidString,
            userId: userId,
            title: title,
            description: description,
            parts: parts,
            durationMin: durationMin,
            intensity: intensity,
            course: course,
            activity: activity
        )
        try db.collection("users")
            .document(userId)
            .collection("custom_workouts")
            .document(workout.id)
            .setData(from: workout)
    }

    public func deleteCustomWorkout(userId: String, workoutId: String) async throws {
        guard let db else { return }
        try await db.collection("users")
            .document(userId)
            .collection("custom_workouts")
            .document(workoutId)
            .delete()
    }

    public func fetchAllCustomWorkouts(userId: String) async throws -> [FirestoreCustomWorkout] {
        guard let db else { return [] }
        let snapshot = try await db.collection("users")
            .document(userId)
            .collection("custom_workouts")
            .getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: FirestoreCustomWorkout.self) }
    }

    // MARK: - User Preferences & Profile Sync

    public func saveUserPreferences(userId: String, data: sending [String: Any]) async throws {
        guard let db else { return }
        var data = data
        // Work-arounds are device-only. Clears the field an older build wrote.
        data["workArounds"] = FieldValue.delete()
        try await db.collection("users")
            .document(userId)
            .setData(data, merge: true)
    }

    public func fetchUserPreferences(userId: String) async throws -> [String: Any]? {
        guard let db else { return nil }
        let snapshot = try await db.collection("users").document(userId).getDocument()
        return snapshot.data()
    }

    // MARK: - Account Deletion

    /// Throws if any document could not be removed, so a caller never treats a
    /// failed or partial delete as a finished one. Account deletion relies on
    /// that: it must not go on to delete the auth user while data remains.
    public func deleteUserData(userId: String) async throws {
        stopListening()
        guard let db else { return }

        let userRef = db.collection("users").document(userId)

        // Delete subcollections fully before the root document. `limit(to:)` alone
        // would silently leave documents behind for any account with more than
        // one page of history — those become permanently orphaned once the
        // owning auth user is gone, since Firestore security rules key deletion
        // rights off `request.auth.uid == userId`. Loop each subcollection to
        // exhaustion instead of taking a single capped page.
        async let workoutsCleared: Void = deleteAllDocuments(in: userRef.collection("custom_workouts"))
        async let completionsCleared: Void = deleteAllDocuments(in: userRef.collection("completions"))
        _ = try await (workoutsCleared, completionsCleared)

        try await userRef.delete()
    }

    private func deleteAllDocuments(in collection: CollectionReference, pageSize: Int = 300) async throws {
        while true {
            let snapshot = try await collection.limit(to: pageSize).getDocuments()
            guard !snapshot.documents.isEmpty else { return }

            let batch = collection.firestore.batch()
            for doc in snapshot.documents {
                batch.deleteDocument(doc.reference)
            }
            try await batch.commit()

            if snapshot.documents.count < pageSize {
                return
            }
        }
    }
}
