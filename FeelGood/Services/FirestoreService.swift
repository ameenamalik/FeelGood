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
//  - Lifecycles managed with isolated deinit and .task(id:)
//

import FirebaseCore
import FirebaseFirestore
import Foundation
import SwiftUI

// MARK: - Firestore Models

public struct FirestoreCompletionRecord: Codable, Sendable, Identifiable {
    public var id: String
    public var userId: String
    public var sessionTitle: String
    public var startedAt: Date
    public var endedAt: Date
    public var feel: String?
    public var timestamp: Date

    public init(
        id: String = UUID().uuidString,
        userId: String,
        sessionTitle: String,
        startedAt: Date,
        endedAt: Date,
        feel: String? = nil,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.sessionTitle = sessionTitle
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.feel = feel
        self.timestamp = timestamp
    }
}

public struct FirestoreCustomWorkout: Codable, Sendable, Identifiable {
    public var id: String
    public var userId: String
    public var title: String
    public var durationMin: Int
    public var intensity: Int
    public var createdAt: Date

    public init(
        id: String = UUID().uuidString,
        userId: String,
        title: String,
        durationMin: Int,
        intensity: Int,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.title = title
        self.durationMin = durationMin
        self.intensity = intensity
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
        startedAt: Date,
        endedAt: Date,
        feel: String? = nil
    ) async throws {
        guard let db else { return }
        let record = FirestoreCompletionRecord(
            userId: userId,
            sessionTitle: sessionTitle,
            startedAt: startedAt,
            endedAt: endedAt,
            feel: feel
        )
        try db.collection("users")
            .document(userId)
            .collection("completions")
            .document(record.id)
            .setData(from: record)
    }

    // MARK: - Custom Workouts Persistence

    public func saveCustomWorkout(
        userId: String,
        title: String,
        durationMin: Int,
        intensity: Int
    ) async throws {
        guard let db else { return }
        let workout = FirestoreCustomWorkout(
            userId: userId,
            title: title,
            durationMin: durationMin,
            intensity: intensity
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

    // MARK: - User Preferences & Profile Sync

    public func saveUserPreferences(userId: String, data: [String: Any]) async throws {
        guard let db else { return }
        try await db.collection("users")
            .document(userId)
            .setData(data, merge: true)
    }

    isolated deinit {
        workoutsListener?.remove()
        completionsListener?.remove()
    }
}
