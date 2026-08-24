//
//  EngineBoundaryTests.swift
//  FeelGoodTests
//
//  The engine's purity is currently held up by convention: `Engine/` is a
//  folder in the app target, not a module, so nothing at link time stops a
//  tired evening from adding `import SwiftData` to it. This test is the cheap
//  stand-in for that link error until the target split happens.
//
//  It is an allow-list rather than a ban-list on purpose. A ban-list only ever
//  closes the doors somebody already thought of — it would catch SwiftData and
//  wave through `Network`, `HealthKit`, or `os`. The rule being enforced is
//  "pure computation over Foundation values", and that is a statement about
//  what is *permitted*, so it is written that way.
//

import Testing
import Foundation

/// Everything the pure layer is allowed to see. Adding to this list is a real
/// architectural decision (PRD §11), not a build fix — if a new entry is
/// needed, that is the signal the logic belongs in `Services/` instead.
private let permittedModules: Set<String> = ["Foundation"]

/// `Engine/` consumes `Session` and the taxonomy enums from `Content/`, so a UI
/// or persistence import there leaks across the boundary just as surely —
/// transitively, and without touching a file in `Engine/`.
private let pureDirectories = ["Engine", "Content"]

@Suite("Engine boundary")
struct EngineBoundaryTests {

    @Test("Engine and Content import nothing but Foundation", arguments: pureDirectories)
    func onlyPermittedImports(directory: String) throws {
        let sources = try swiftFiles(in: directory)

        // A moved or renamed folder must fail loudly. A file scan that finds
        // nothing otherwise passes forever while enforcing nothing at all.
        #expect(!sources.isEmpty, "No Swift files found under \(directory)/ — has it moved?")

        for file in sources {
            let contents = try String(contentsOf: file, encoding: .utf8)
            for module in importedModules(in: contents) {
                #expect(
                    permittedModules.contains(module),
                    """
                    \(file.lastPathComponent) imports \(module).
                    \(directory)/ is a pure function of value types — no UI, no networking, \
                    no storage I/O, no clock. Move whatever needs \(module) into Services/.
                    """
                )
            }
        }
    }

    // MARK: Private

    /// Line-anchored so the prose in these files — several of which mention
    /// SwiftData in a header comment explaining that they don't use it — is
    /// read as prose. Handles attributes like `@preconcurrency import`.
    private func importedModules(in source: String) -> [String] {
        source.split(separator: "\n").compactMap { line in
            var rest = Substring(line).drop { $0 == " " || $0 == "\t" }
            while rest.first == "@" {
                rest = rest.drop { !$0.isWhitespace }.drop { $0 == " " || $0 == "\t" }
            }
            guard rest.hasPrefix("import ") else { return nil }
            // The submodule of `import os.log` is not the interesting part.
            return rest
                .dropFirst("import ".count)
                .drop { $0 == " " }
                .prefix { $0.isLetter || $0.isNumber || $0 == "_" }
                .description
                .nilIfEmpty
        }
    }

    /// Recursive: a subfolder added under `Engine/` later is still `Engine/`.
    private func swiftFiles(in directory: String) throws -> [URL] {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()  // FeelGoodTests
            .deletingLastPathComponent()  // repository root
            .appending(path: "FeelGood")
            .appending(path: directory)

        guard let walker = FileManager.default.enumerator(
            at: root,
            includingPropertiesForKeys: [.isRegularFileKey]
        ) else { return [] }

        return walker.compactMap { $0 as? URL }.filter { $0.pathExtension == "swift" }
    }
}

private extension String {
    var nilIfEmpty: String? { isEmpty ? nil : self }
}
