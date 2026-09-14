//
//  ScannableCueView.swift
//  FeelGood
//
//  Formats exercise cues into scannable mid-workout guidance:
//  a prominent setup/action lead, followed by concise bite-sized tips.
//

import SwiftUI

struct ScannableCueView: View {
    let cue: String
    var requiresSideSwitch: Bool = false

    private var parsed: CueBreakdown {
        CueBreakdown(raw: cue, requiresSideSwitch: requiresSideSwitch)
    }

    var body: some View {
        VStack(spacing: FGSpace.s) {
            if let lead = parsed.leadAction {
                Text(lead)
                    .font(FGFont.itemTitle)
                    .foregroundStyle(FGColor.ink)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if !parsed.tips.isEmpty {
                VStack(alignment: .leading, spacing: FGSpace.xs) {
                    ForEach(parsed.tips, id: \.self) { tip in
                        HStack(alignment: .top, spacing: FGSpace.s) {
                            Image(systemName: "circle.fill")
                                .font(.system(size: 5))
                                .foregroundStyle(FGColor.goldDeep)
                                .padding(.top, 6)
                            Text(tip)
                                .font(FGFont.caption)
                                .foregroundStyle(FGColor.inkMuted)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                .padding(.horizontal, FGSpace.s)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(cue)
    }
}

nonisolated struct CueBreakdown: Equatable, Sendable {
    let leadAction: String?
    let tips: [String]

    init(raw: String, requiresSideSwitch: Bool) {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            self.leadAction = nil
            self.tips = []
            return
        }

        // Split into sentences / major clauses
        let sentences = trimmed
            .components(separatedBy: CharacterSet(charactersIn: ".!?\n"))
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        guard !sentences.isEmpty else {
            self.leadAction = trimmed
            self.tips = []
            return
        }

        // Helper to detect if a sentence is an inline side-switch instruction
        func isSwitchSideSentence(_ s: String) -> Bool {
            let lower = s.lowercased()
            return lower.hasPrefix("switch side") ||
                lower.hasPrefix("switch to the other") ||
                lower.hasPrefix("repeat on the other") ||
                lower.contains("switch sides halfway") ||
                lower.contains("switch sides after") ||
                lower == "switch sides" ||
                lower == "switch legs"
        }

        // Filter out inline switch sentences if explicit side switch alert is active
        let candidateSentences: [String]
        if requiresSideSwitch {
            candidateSentences = sentences.filter { !isSwitchSideSentence($0) }
        } else {
            candidateSentences = sentences
        }

        if candidateSentences.isEmpty {
            self.leadAction = sentences.first
            self.tips = []
        } else if candidateSentences.count == 1 {
            self.leadAction = candidateSentences[0]
            self.tips = []
        } else {
            self.leadAction = candidateSentences[0]
            self.tips = Array(candidateSentences.dropFirst())
        }
    }
}
