//
//  ExerciseDemo.swift
//  FeelGood
//
//  Bundled line-art animation frames, keyed by glossary id. Most exercises
//  don't have one yet — adding a demo is dropping numbered PNGs into
//  ExerciseDemos/, never a code change. Frames are white strokes on a
//  transparent field so they render as template images and pick up whatever
//  ink colour the screen is using.
//
//  Artwork: Bryl Lim (https://bryllim.com), building on Everkinetic
//  (https://github.com/everkinetic/data). CC BY-SA 4.0 — unmodified here.
//  See FeelGood/Content/ExerciseDemos/ATTRIBUTION.md.
//

import Foundation

nonisolated enum ExerciseDemo {
    /// Bundled frames for a glossary id, in order. Empty when none exist.
    static func frameURLs(for glossaryID: String?) -> [URL] {
        guard let glossaryID else { return [] }
        var urls: [URL] = []
        var index = 1
        while let url = Bundle.main.url(forResource: "\(glossaryID)-\(index)", withExtension: "png") {
            urls.append(url)
            index += 1
        }
        return urls
    }
}
