//
//  Storage.swift
//  FeelGood
//
//  Opening the store, and being honest when it can't be opened.
//
//  Two rules here, both about somebody's history:
//
//  1. **Nothing in this file ever deletes or replaces the store.** A store that
//     won't open today is not a store that is gone — a bad migration, a device
//     out of space, or a file still locked by a crashed process all look the
//     same from here, and all of them get better on their own. Deleting to
//     "recover" would turn a bad morning into a permanent loss.
//  2. **A fallback is never silent.** Running in memory is a visible state the
//     app tells the truth about, not a quiet reset that looks like a first
//     launch.
//

import Foundation
import OSLog
import SwiftData

struct Storage {
    let container: ModelContainer

    /// True when the real store could not be opened and this container is a
    /// stand-in that will not survive the app closing. Anything on disk is
    /// untouched and will be tried again next launch.
    let isEphemeral: Bool

    private static let logger = Logger(subsystem: "com.ameenamalik.FeelGood", category: "storage")

    /// Opens the store, migrating it if this build expects a newer shape.
    /// `url` is for tests; production passes `nil` for the default location.
    ///
    /// Call this once per store per launch. Two live containers on one store
    /// file is not a supported arrangement, and releasing one of them takes the
    /// process with it. The retry path is safe because a failed open leaves no
    /// container on that file at all — the stand-in is in memory.
    static func open(at url: URL? = nil) -> Storage {
        if url == nil { prepareStoreDirectory() }
        let schema = FeelGoodSchema.schema
        let configuration = url.map { ModelConfiguration(schema: schema, url: $0) }
            ?? ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return Storage(
                container: try ModelContainer(
                    for: schema,
                    migrationPlan: FeelGoodMigrationPlan.self,
                    configurations: [configuration]
                ),
                isEphemeral: false
            )
        } catch {
            // Left exactly where it is. See rule 1 above.
            logger.error("Store could not be opened, running in memory: \(error, privacy: .public)")
            return Storage(container: ephemeralContainer(schema), isEphemeral: true)
        }
    }

    private static func ephemeralContainer(_ schema: Schema) -> ModelContainer {
        do {
            return try ModelContainer(
                for: schema,
                configurations: [ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)]
            )
        } catch {
            // A container that needs no file and no migration cannot fail for
            // any reason the app could recover from.
            fatalError("In-memory store unavailable: \(error)")
        }
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
            logger.error("Could not prepare Application Support: \(error, privacy: .public)")
        }
    }
}
