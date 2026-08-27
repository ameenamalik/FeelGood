//
//  ExerciseDemoView.swift
//  FeelGood
//
//  A looping line-art animation for the step on screen, when one is bundled.
//  Renders nothing for the steps that don't have one yet — most don't.
//

import SwiftUI
import Lottie

struct ExerciseDemoView: View {
    let glossaryID: String?

    @State private var frames: [UIImage] = []
    @State private var frameIndex = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.self) private var environment

    private let frameInterval: Duration = .milliseconds(600)

    /// Resolved once per id, not decoded on every body evaluation — loading
    /// a `LottieAnimation` parses its JSON.
    private var lottieAnimation: LottieAnimation? {
        ExerciseDemo.lottieURL(for: glossaryID).flatMap { LottieAnimation.filepath($0.path) }
    }

    /// Whether a bundled demo exists, checked synchronously (a `Bundle` path
    /// lookup, not a decode) so the space it'll occupy is reserved from the
    /// very first render rather than popping in once the async load below
    /// finishes. A view that starts at zero size here and only grows once
    /// state changes has, in practice, sometimes never grown at all — so
    /// steps with a demo reserve it up front, and steps without one never
    /// reserve anything.
    private var hasDemo: Bool {
        ExerciseDemo.lottieURL(for: glossaryID) != nil || !ExerciseDemo.frameURLs(for: glossaryID).isEmpty
    }

    var body: some View {
        ZStack {
            if let lottieAnimation {
                // House-drawn art recolours dynamically to match the ink
                // token, the same job `.foregroundStyle` does for the PNG
                // path below — the JSON's own baked-in stroke colour is a
                // placeholder, not the source of truth for light/dark mode.
                LottieView(animation: lottieAnimation)
                    .resizable()
                    .playing(loopMode: reduceMotion ? .playOnce : .autoReverse)
                    .valueProvider(
                        ColorValueProvider(FGColor.skyDeep.resolve(in: environment).lottieColor),
                        for: AnimationKeypath(keys: ["**", "Color"])
                    )
                    .padding(FGSpace.m)
                    .accessibilityHidden(true)
            } else if frames.indices.contains(frameIndex) {
                // `.id` gives each frame its own view identity, so the old
                // frame fades out and the new one fades in at each one's own
                // size — a crossfade, not a resize. Animating the plain
                // `Image` in place (no `.id`) is what caused the old zoom
                // bug: SwiftUI morphed one frame's geometry into the next's.
                Image(uiImage: frames[frameIndex])
                    .renderingMode(.template)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .foregroundStyle(FGColor.skyDeep)
                    .padding(FGSpace.m)
                    .accessibilityHidden(true)
                    .id(frameIndex)
                    .transition(.opacity)
            }
        }
        .frame(maxWidth: hasDemo ? 220 : 0, maxHeight: hasDemo ? 220 : 0)
        .task(id: glossaryID) {
            // Lottie is preferred; only load the PNG flipbook when no
            // Lottie file exists for this id.
            guard lottieAnimation == nil else { return }
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
            // Animates the crossfade only (see `.id`/`.transition` above),
            // not the frame's geometry — frames vary in pixel dimensions,
            // and animating the plain image in place would interpolate the
            // `.aspectRatio(.fit)` sizing between them, reading as a zoom
            // rather than a clean pose change.
            withAnimation(FGMotion.gentle) { frameIndex += direction }
        }
    }
}

private extension Color.Resolved {
    var lottieColor: LottieColor {
        LottieColor(r: Double(red), g: Double(green), b: Double(blue), a: Double(opacity))
    }
}
