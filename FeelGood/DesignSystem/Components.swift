//
//  Components.swift
//  FeelGood
//
//  Shared primitives. Large touch targets, generous padding, and no affordance
//  anywhere that scores, ranks, or counts.
//

import SwiftUI

/// A raised surface on the cream page.
struct FGCard<Content: View>: View {
    var isHighlighted = false
    @ViewBuilder var content: Content

    var body: some View {
        content
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(FGSpace.m)
            .background(
                RoundedRectangle(cornerRadius: FGRadius.card, style: .continuous)
                    .fill(FGColor.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: FGRadius.card, style: .continuous)
                    .strokeBorder(
                        isHighlighted ? FGColor.limeDeep : FGColor.lineStrong,
                        lineWidth: isHighlighted ? 2 : 1
                    )
            )
    }
}

/// A small factual label — duration, equipment. Never a score.
struct FGChip: View {
    let text: String

    var body: some View {
        Text(text)
            .font(FGFont.label)
            .foregroundStyle(FGColor.inkMuted)
            .padding(.horizontal, FGSpace.s)
            .padding(.vertical, FGSpace.xs)
            .background(
                RoundedRectangle(cornerRadius: FGRadius.chip, style: .continuous)
                    .fill(FGColor.bg)
            )
            .overlay(
                RoundedRectangle(cornerRadius: FGRadius.chip, style: .continuous)
                    .strokeBorder(FGColor.line, lineWidth: 1)
            )
    }
}

/// The one action on a screen.
struct FGPrimaryButton: View {
    let title: String
    var isEnabled = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(FGFont.body.weight(.medium))
                .foregroundStyle(isEnabled ? FGColor.bg : FGColor.inkMuted)
                .frame(maxWidth: .infinity, minHeight: 56)
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        // The fill sits *outside* the button on purpose. `.disabled` makes the
        // plain button style render its whole label at about half opacity, so a
        // fill drawn inside it lets the page through — over the brand wash that
        // came out muddy brown. Out here the fill stays opaque and only the
        // label dims, which is what a disabled control should do anyway.
        .background(
            Capsule()
                .fill(isEnabled ? FGColor.ink : FGColor.line)
        )
    }
}

/// A quiet secondary action, for things like "not today".
struct FGQuietButton: View {
    let title: String
    let systemImage: String?
    let action: () -> Void

    init(_ title: String, systemImage: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.systemImage = systemImage
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: FGSpace.xs) {
                if let systemImage { Image(systemName: systemImage) }
                Text(title)
            }
            .font(FGFont.caption.weight(.medium))
            .foregroundStyle(FGColor.inkMuted)
            // Short labels like "Skip" are only a few points wide. The height
            // was already 44; the width was not, and `FGSize.minTouchTarget`
            // says never smaller than this anywhere.
            .frame(minWidth: FGSize.minTouchTarget, minHeight: FGSize.minTouchTarget, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

/// A selectable answer in the check-in. Two taps, ten seconds.
///
/// The visual, detail, and accent are optional so each flow can keep its own
/// expression without changing the choice's typography or selection styling.
struct FGChoice: View {
    @Environment(\.dynamicTypeSize) private var typeSize

    let title: String
    var emoji: String? = nil
    var systemImage: String? = nil
    var detail: String? = nil
    var accent: FGAccent = .ink
    let isSelected: Bool
    let action: () -> Void

    private var hasVisual: Bool { emoji != nil || systemImage != nil }
    private var visualTileSize: CGFloat? {
        hasVisual && !typeSize.isAccessibilitySize ? 110 : nil
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: hasVisual ? FGSpace.s : FGSpace.xs) {
                if let emoji {
                    // A text style, so it grows with Dynamic Type instead of
                    // stranding a fixed-size glyph next to huge type. Hidden
                    // from VoiceOver, which would otherwise read "cloud".
                    Text(emoji)
                        .font(.title2)
                        .frame(height: typeSize.isAccessibilitySize ? nil : 24)
                        .foregroundStyle(FGColor.ink)
                        .accessibilityHidden(true)
                }

                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.title2)
                        .symbolRenderingMode(.monochrome)
                        .frame(width: 32, height: typeSize.isAccessibilitySize ? nil : 24)
                        .foregroundStyle(isSelected ? accent.text : FGColor.ink)
                        .accessibilityHidden(true)
                }

                VStack(spacing: 2) {
                    Text(title)
                        .font(FGFont.body)
                        .multilineTextAlignment(.center)
                        .lineLimit(typeSize.isAccessibilitySize ? nil : 2)
                        .minimumScaleFactor(typeSize.isAccessibilitySize ? 1 : 0.85)
                        .foregroundStyle(FGColor.ink)

                    if let detail {
                        Text(detail)
                            .font(FGFont.label)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(FGColor.inkMuted)
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(hasVisual ? 12 : 0)
            .padding(.horizontal, hasVisual ? 0 : FGSpace.xs)
            // Fill the height `FlowRow` offers, so a two-line label doesn't
            // leave its neighbours in the row looking clipped short. Only the
            // visual tiles do this; plain rows keep hugging.
            .frame(
                minWidth: visualTileSize,
                maxWidth: visualTileSize ?? .infinity,
                minHeight: visualTileSize ?? (FGSize.minTouchTarget + 8),
                maxHeight: visualTileSize ?? (hasVisual ? .infinity : nil)
            )
            .background(
                RoundedRectangle(cornerRadius: hasVisual ? 20 : FGRadius.button, style: .continuous)
                    .fill(FGColor.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: hasVisual ? 20 : FGRadius.button, style: .continuous)
                            .fill(isSelected ? accent.fill.opacity(0.3) : .clear)
                    )
            )
            .overlay(
                // Selection is never signalled by colour alone: the border
                // gains weight too, while its hue connects it to the tint.
                RoundedRectangle(cornerRadius: hasVisual ? 20 : FGRadius.button, style: .continuous)
                    .strokeBorder(
                        isSelected ? accent.text.opacity(0.95) : FGColor.lineStrong,
                        lineWidth: isSelected ? 1.5 : 1
                    )
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel([title, detail].compactMap(\.self).joined(separator: ", "))
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}
