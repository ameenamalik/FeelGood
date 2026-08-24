//
//  BrandWash.swift
//  FeelGood
//
//  The one piece of decoration in the app: the cloud gradient with a fine
//  grain over it, so it reads as printed paper rather than as a UI surface.
//
//  It is never information. Nothing is ever encoded in it, nothing is ever
//  only legible because of it, and no text depends on it for contrast — the
//  gradient darkens in the dark appearance precisely so that ordinary `ink`
//  keeps working on top of it in both modes.
//

import CoreGraphics
import SwiftUI

/// A tile of monochrome noise, generated once and reused.
///
/// Core Graphics rather than `UIGraphicsImageRenderer`, and `nonisolated`,
/// because this is built lazily on whichever thread first draws a wash — the
/// same rule that governs the colour tokens next door.
nonisolated enum FGGrain {
    /// 128pt of noise, tiled. Small enough to be free, large enough that the
    /// repeat is invisible under a gradient. `nil` if the bitmap cannot be
    /// built, in which case the wash simply renders without grain.
    static let tile: Image? = {
        let side = 128
        var pixels = [UInt8](repeating: 0, count: side * side)
        var generator = SystemRandomNumberGenerator()
        for index in pixels.indices {
            // Centred on mid-grey: `.overlay` blending leaves mid-grey alone,
            // so the spread around it is exactly the strength of the grain.
            pixels[index] = 64 + generator.next(upperBound: UInt8(128))
        }

        // The pointer has to stay valid until `makeImage` has copied out of
        // it, so both calls live inside the same borrow.
        let bitmap: CGImage? = pixels.withUnsafeMutableBytes { buffer in
            guard let context = CGContext(
                data: buffer.baseAddress,
                width: side,
                height: side,
                bitsPerComponent: 8,
                bytesPerRow: side,
                space: CGColorSpaceCreateDeviceGray(),
                bitmapInfo: CGImageAlphaInfo.none.rawValue
            ) else { return nil }
            return context.makeImage()
        }

        return bitmap.map { Image(decorative: $0, scale: 2) }
    }()
}

/// The brand wash: a soft bloom rising from the bottom edge of whatever frame
/// it is given, fading out completely before it reaches the top.
///
/// Bottom-anchored on purpose. A band across the top competes with the status
/// bar and the screen's own title for the same few hundred points; rising from
/// the bottom it fills the space the content has already finished with.
struct FGBrandWash: View {
    /// How far the bloom reaches, as a fraction of the frame's longest edge.
    ///
    /// This — not a fixed height — is what controls the size of the wash. A
    /// short `.frame(height:)` gets aligned to the *safe area* bottom, which
    /// leaves the home-indicator strip showing the bare page colour underneath:
    /// a white band across the bottom of the screen. The view always fills, and
    /// the radius decides how much of that fill is coloured.
    var reach: CGFloat = 1.15

    var body: some View {
        GeometryReader { proxy in
            let extent = max(proxy.size.width, proxy.size.height) * reach

            ZStack {
                RadialGradient(
                    gradient: FGColor.washGradient,
                    center: .bottom,
                    startRadius: 0,
                    endRadius: extent
                )

                if let grain = FGGrain.tile {
                    grain
                        .resizable(resizingMode: .tile)
                        .blendMode(.overlay)
                        // 0.5, not more: the grain swings the background
                        // luminance under a glyph, and muted captions sit on
                        // this. Stronger than this and they drop under 4.5:1.
                        .opacity(0.5)
                }
            }
            // Gradient and grain fade together, so the noise never shows up as
            // a rectangle of static over the flat page colour.
            .mask {
                RadialGradient(
                    stops: [
                        .init(color: .black, location: 0),
                        .init(color: .black.opacity(0.9), location: 0.4),
                        .init(color: .clear, location: 1),
                    ],
                    center: .bottom,
                    startRadius: 0,
                    endRadius: extent * 0.9
                )
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

#Preview("Full bleed") {
    ZStack {
        FGColor.bg
        FGBrandWash()
        Text("Done.")
            .font(FGFont.display)
            .foregroundStyle(FGColor.ink)
    }
    .ignoresSafeArea()
}

#Preview("Under a menu") {
    ZStack {
        FGColor.bg
        FGBrandWash(reach: 0.62)
        Text("Good to see you.")
            .font(FGFont.display)
            .foregroundStyle(FGColor.ink)
            .frame(maxHeight: .infinity, alignment: .top)
            .padding(FGSpace.page)
    }
    .ignoresSafeArea()
}
