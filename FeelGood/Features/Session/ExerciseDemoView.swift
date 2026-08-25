//
//  ExerciseDemoView.swift
//  FeelGood
//
//  A looping line-art animation for the step on screen, when one is bundled.
//  Renders nothing for the steps that don't have one yet — most don't.
//

import SwiftUI

struct ExerciseDemoView: View {
    let glossaryID: String?

    @State private var frames: [UIImage] = []
    @State private var frameIndex = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let frameInterval: Duration = .milliseconds(600)

    /// Whether bundled frames exist, checked synchronously (a `Bundle` path
    /// lookup, not a decode) so the space they'll occupy is reserved from the
    /// very first render rather than popping in once the async load below
    /// finishes. A view that starts at zero size here and only grows once
    /// state changes has, in practice, sometimes never grown at all — so
    /// steps with a demo reserve it up front, and steps without one never
    /// reserve anything.
    private var hasDemo: Bool { !ExerciseDemo.frameURLs(for: glossaryID).isEmpty }

    var body: some View {
        ZStack {
            if hasDemo {
                RoundedRectangle(cornerRadius: FGRadius.card, style: .continuous)
                    .fill(FGColor.sky.opacity(0.14))
            }
            if frames.indices.contains(frameIndex) {
                Image(uiImage: frames[frameIndex])
                    .renderingMode(.template)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .foregroundStyle(FGColor.skyDeep)
                    .padding(FGSpace.m)
                    .accessibilityHidden(true)
            }
        }
        .frame(maxWidth: hasDemo ? 220 : 0, maxHeight: hasDemo ? 220 : 0)
        .task(id: glossaryID) {
            // `UIImage(contentsOfFile:)`, not `UIImage(data:)` from a manually
            // read `Data`: Xcode's Copy Bundle Resources phase silently
            // recompresses some bundled PNGs into Apple's private CgBI format,
            // which only the file-path initialiser reliably decodes.
            frames = ExerciseDemo.frameURLs(for: glossaryID).compactMap { url in
                UIImage(contentsOfFile: url.path)
            }
            frameIndex = 0
            guard frames.count > 1, !reduceMotion else { return }
            await loop()
        }
    }

    /// Bounces back and forth across the frames rather than looping forward,
    /// so a two- or three-frame set reads as a held movement, not a slideshow.
    private func loop() async {
        var direction = 1
        while !Task.isCancelled {
            try? await Task.sleep(for: frameInterval)
            guard !Task.isCancelled else { return }
            let next = frameIndex + direction
            if next < 0 || next >= frames.count {
                direction = -direction
            }
            withAnimation(FGMotion.gentle) { frameIndex += direction }
        }
    }
}
