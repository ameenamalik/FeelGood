//
//  Schema.swift
//  FeelGood
//
//  Every version of the store the app has ever had, and the plan for getting
//  from one to the next.
//
//  ─────────────────────────────────────────────────────────────────────────
//  HOW TO CHANGE A MODEL
//
//  Once a build with a given schema has reached anybody — TestFlight included —
//  that schema is frozen. Editing it in place is what loses somebody's history.
//  Instead:
//
//    1. Copy the current `FeelGoodSchemaVn` into a new `FeelGoodSchemaVn+1`,
//       bump its `versionIdentifier`, and make the change there.
//    2. Add a `MigrationStage` to `FeelGoodMigrationPlan.stages`. Adding an
//       optional property, or one with a default, is `.lightweight`; anything
//       that has to move data is `.custom`.
//    3. Point `FeelGoodSchema.Current` at the new version.
//    4. Add a case to `SchemaMigrationTests` that opens a store written by the
//       old version and asserts the data survived.
//
//  Before that first release, editing V1 in place is fine — nobody is carrying
//  a store yet. Afterwards it is not, and no amount of "it's only one field"
//  changes that. See PRD §11.
//  ─────────────────────────────────────────────────────────────────────────
//

import Foundation
import SwiftData

/// The shipped shape of the store. Nothing has been released yet, so this is
/// still editable in place — see the note above for when that stops being true.
enum FeelGoodSchemaV1: VersionedSchema {
    static var versionIdentifier: Schema.Version { Schema.Version(1, 0, 0) }

    static var models: [any PersistentModel.Type] {
        [
            UserProfile.self,
            CheckInRecord.self,
            PlanDay.self,
            PlanItem.self,
            SessionRecord.self,
            AffinityRecord.self,
            CustomSession.self,
            ContentVersionRecord.self,
            BanditStateRecord.self,
        ]
    }
}

/// How the store gets from any version it might be on to the one this build
/// expects. Empty of stages while there is only one version — the point of it
/// existing now is that the next change is a stage rather than a surprise.
enum FeelGoodMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] { [FeelGoodSchemaV1.self] }
    static var stages: [MigrationStage] { [] }
}

/// Everything the app persists. Passed to the container in one place.
enum FeelGoodSchema {
    /// The version this build is written against.
    typealias Current = FeelGoodSchemaV1

    static var models: [any PersistentModel.Type] { Current.models }
    static var schema: Schema { Schema(versionedSchema: Current.self) }
}
