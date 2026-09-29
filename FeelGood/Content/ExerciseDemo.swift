//
//  ExerciseDemo.swift
//  FeelGood
//
//  Bundled exercise demos, keyed by glossary id. Add reviewed demos by
//  dropping files into ExerciseDemos/. Known mismatched imports are blocked
//  below until corrected. Two formats coexist during the move to house-drawn art:
//
//  - `{id}.json`: a Lottie animation, our own art, checked in-house.
//  - `{id}-{n}.png`: the older numbered-frame flipbook. Frames are white
//    strokes on a transparent field so they render as template images and
//    pick up whatever ink colour the screen is using.
//
//  Lottie is preferred where both exist. See ExerciseDemoView.
//
//  PNG artwork: Bryl Lim (https://bryllim.com), building on Everkinetic
//  (https://github.com/everkinetic/data). CC BY-SA 4.0 — mostly unmodified;
//  a few sets are adaptations, under the same license.
//  See FeelGood/Content/ExerciseDemos/ATTRIBUTION.md for which is which.
//

import Foundation

nonisolated enum ExerciseDemo {
    /// These imported sets depict a different movement or mix incompatible
    /// poses. Keep the instructions available without showing a misleading
    /// flipbook. A corrected Lottie can still take precedence over the PNGs.
    /// See docs/EXERCISE_DEMO_REVIEW.md before removing an entry.
    static let unavailableFrameIDs: Set<String> = [
        "banded-frog-pump", "hiking", "lying-hamstring-walkout",
        "reverse-hyperextension", "seal-jack", "seated-knee-tuck",
        "skater-squat", "smith-machine-bulgarian-split-squat",
        "stability-ball-hamstring-curl", "towel-hamstring-curl", "towel-row",
    ]

    /// Whether anything is bundled for this id. A `Bundle` path lookup, not
    /// a decode, so callers can reserve layout for it synchronously.
    static func hasDemo(for glossaryID: String?) -> Bool {
        lottieURL(for: glossaryID) != nil || !frameURLs(for: glossaryID).isEmpty
    }

    /// A bundled Lottie animation for a glossary id, if one has been drawn.
    static func lottieURL(for glossaryID: String?) -> URL? {
        guard let glossaryID else { return nil }
        return Bundle.main.url(forResource: glossaryID, withExtension: "json")
    }

    /// Bundled frames for a glossary id, in order. Empty when none exist.
    static func frameURLs(for glossaryID: String?) -> [URL] {
        guard let glossaryID else { return [] }
        guard !unavailableFrameIDs.contains(glossaryID) else { return [] }
        var urls: [URL] = []
        var index = 1
        while let url = Bundle.main.url(forResource: "\(glossaryID)-\(index)", withExtension: "png") {
            urls.append(url)
            index += 1
        }
        return urls
    }
}
