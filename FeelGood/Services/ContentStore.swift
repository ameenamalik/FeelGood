//
//  ContentStore.swift
//  FeelGood
//
//  Content is data, not code: the catalog is bundled JSON today and can be
//  delivered remotely later without a rebuild. Protocol-backed so the whole
//  app runs offline in tests and previews. See PRD §6, §11.
//

import Foundation

nonisolated protocol ContentProviding: Sendable {
    var version: Int { get }
    var sessions: [Session] { get }
    var glossary: [ExerciseTerm] { get }
    func session(id: String) -> Session?
    /// Resolves a step's `glossaryID`. `nil` means the step simply shows no
    /// "what's this?" affordance — never an error state.
    func term(id: String?) -> ExerciseTerm?
}

nonisolated struct ContentStore: ContentProviding {
    let version: Int
    let sessions: [Session]
    let glossary: [ExerciseTerm]

    private let sessionsByID: [String: Session]
    private let termsByID: [String: ExerciseTerm]

    init(catalog: ContentCatalog) {
        version = catalog.version
        sessions = catalog.sessions
        glossary = catalog.glossary
        sessionsByID = Dictionary(catalog.sessions.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        termsByID = Dictionary(catalog.glossary.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
    }

    func session(id: String) -> Session? { sessionsByID[id] }

    func term(id: String?) -> ExerciseTerm? {
        guard let id else { return nil }
        return termsByID[id]
    }

    // MARK: - Loading

    enum LoadError: Error, LocalizedError {
        case catalogNotFound(name: String)

        var errorDescription: String? {
            switch self {
            case .catalogNotFound(let name): "Bundled content catalog \(name).json is missing."
            }
        }
    }

    static func bundled(named name: String = "catalog", in bundle: Bundle = .main) throws -> ContentStore {
        guard let url = bundle.url(forResource: name, withExtension: "json") else {
            throw LoadError.catalogNotFound(name: name)
        }
        let data = try Data(contentsOf: url)
        let catalog = try JSONDecoder().decode(ContentCatalog.self, from: data)
        return ContentStore(catalog: catalog)
    }

    // MARK: - Validation

    /// Invariants the catalog must hold. Asserted in tests so a bad content
    /// drop fails the build rather than the morning.
    enum CatalogIssue: Hashable, CustomStringConvertible {
        case duplicateSessionID(String)
        case duplicateTermID(String)
        case unresolvedGlossaryReference(sessionID: String, glossaryID: String)
        case noGuaranteedAppetizer
        case appetizerCannotBeDoneAtHome(sessionID: String)
        case intensityOutOfRange(sessionID: String, intensity: Int)
        case emptyEnergyFit(sessionID: String)
        case videoBehindPaywallRisk(sessionID: String)

        var description: String {
            switch self {
            case .duplicateSessionID(let id): "Duplicate session id: \(id)"
            case .duplicateTermID(let id): "Duplicate glossary term id: \(id)"
            case .unresolvedGlossaryReference(let s, let g): "Session \(s) references unknown glossary term \(g)"
            case .noGuaranteedAppetizer: "No no-equipment, contraindication-free appetizer exists"
            case .appetizerCannotBeDoneAtHome(let id): "Appetizer \(id) needs somewhere other than home"
            case .intensityOutOfRange(let id, let i): "Session \(id) has intensity \(i), expected 1...5"
            case .emptyEnergyFit(let id): "Session \(id) fits no energy level, so it can never be surfaced"
            case .videoBehindPaywallRisk(let id): "Video session \(id) must stay free — YouTube policy"
            }
        }
    }

    func validate() -> [CatalogIssue] {
        var issues: [CatalogIssue] = []

        var seenSessions: Set<String> = []
        for session in sessions where !seenSessions.insert(session.id).inserted {
            issues.append(.duplicateSessionID(session.id))
        }
        var seenTerms: Set<String> = []
        for term in glossary where !seenTerms.insert(term.id).inserted {
            issues.append(.duplicateTermID(term.id))
        }

        for session in sessions {
            if !(1...5).contains(session.intensity) {
                issues.append(.intensityOutOfRange(sessionID: session.id, intensity: session.intensity))
            }
            if session.energyFit.isEmpty {
                issues.append(.emptyEnergyFit(sessionID: session.id))
            }
            for step in session.source.steps {
                if let glossaryID = step.glossaryID, termsByID[glossaryID] == nil {
                    issues.append(.unresolvedGlossaryReference(sessionID: session.id, glossaryID: glossaryID))
                }
            }
        }

        // The two-minute option has to survive the worst possible day, which
        // includes not leaving the house.
        for session in sessions where session.course == .appetizer && !session.worksAtHome {
            issues.append(.appetizerCannotBeDoneAtHome(sessionID: session.id))
        }

        // The floor of the product: something to offer no matter what.
        let hasFallback = sessions.contains {
            $0.course == .appetizer
                && $0.needsNoEquipment
                && $0.worksAtHome
                && !$0.source.isVideo
                && $0.contraindications.isEmpty
        }
        if !hasFallback { issues.append(.noGuaranteedAppetizer) }

        return issues
    }
}
