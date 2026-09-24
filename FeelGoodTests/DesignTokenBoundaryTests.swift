//
//  DesignTokenBoundaryTests.swift
//  FeelGoodTests
//
//  Colour is resolved in one place. A view that spells a hex value, or builds
//  its own `Color(light:dark:)`, opts out of every theme — it will look right
//  until someone picks a different look and then stay the old one.
//
//  Scans the app's feature and service code for colour literals. `DesignSystem/`
//  is where they belong, so it is the one place not scanned.
//

import Testing
import Foundation

private let scannedDirectories = ["Features", "Services", "App", "Models"]

@Suite("Design token boundary")
struct DesignTokenBoundaryTests {

    @Test("No colour literals outside DesignSystem", arguments: scannedDirectories)
    func noColourLiterals(directory: String) throws {
        let sources = try swiftFiles(in: directory)
        #expect(!sources.isEmpty, "No Swift files found under \(directory)/ — has it moved?")

        for file in sources {
            let contents = try String(contentsOf: file, encoding: .utf8)
            for (index, line) in contents.split(separator: "\n", omittingEmptySubsequences: false).enumerated() {
                let text = String(line)
                // Prose that mentions a hex value is not a literal.
                if text.drop(while: { $0 == " " || $0 == "\t" }).hasPrefix("//") { continue }
                #expect(
                    !hasColourLiteral(text),
                    """
                    \(file.lastPathComponent):\(index + 1) spells a colour literal.
                    Add a named role to FGColor in DesignSystem/Palette.swift and use that, \
                    so a theme can restyle it.
                    """
                )
            }
        }
    }

    // MARK: Private

    /// `Color(light:dark:)`, `Color(hex:)`, `Color(red:…)`, `UIColor(red:…)`,
    /// or a bare `0xRRGGBB` number.
    private func hasColourLiteral(_ line: String) -> Bool {
        let patterns = [
            #"Color\(\s*(light|hex|red)\s*:"#,
            #"UIColor\(\s*(red|hex)\s*:"#,
            #"\b0x[0-9A-Fa-f]{6}\b"#,
        ]
        return patterns.contains { line.range(of: $0, options: .regularExpression) != nil }
    }

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
