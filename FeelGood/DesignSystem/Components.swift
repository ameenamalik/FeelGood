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
    /// Height only. Giving this to `maxWidth` as well is what welded the tile
    /// to 110pt and broke the grid on every phone narrower than an iPhone 17.
    private var visualTileHeight: CGFloat? {
        hasVisual && !typeSize.isAccessibilitySize ? FGSize.choiceTile : nil
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
            // Width fills whatever slot `FlowRow` hands over — the layout owns
            // the column arithmetic, the tile just occupies its share. Height
            // keeps the square-ish proportion at its floor and is free to grow,
            // so a two-line label doesn't leave its neighbours looking clipped.
            .frame(
                maxWidth: .infinity,
                minHeight: visualTileHeight ?? (FGSize.minTouchTarget + 8),
                maxHeight: hasVisual ? .infinity : nil
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

// MARK: - Previews

/// The choice grid at the widths that actually decide its column count. A tile
/// pinned to a fixed width once collapsed this to two columns and an orphan on
/// every phone narrower than an iPhone 17, and nothing here rendered it at a
/// width small enough to show that — so these previews start at the narrow end.
private struct ChoiceGridPreview: View {
    @Environment(\.dynamicTypeSize) private var typeSize

    @State private var selected = "Steady"

    private let options = [
        ("Empty", "cloud"),
        ("Steady", "cloud.sun"),
        ("Strong", "sun.max")
    ]

    var body: some View {
        FlowRow.choices(isAccessibilitySize: typeSize.isAccessibilitySize) {
            ForEach(options, id: \.0) { option in
                FGChoice(
                    title: option.0,
                    systemImage: option.1,
                    isSelected: selected == option.0
                ) {
                    selected = option.0
                }
            }
        }
        .padding(FGSpace.page)
    }
}

/// 327pt is what a 375pt screen leaves after `FGSpace.page` either side — the
/// narrowest phone still supported, and where the grid used to break.
#Preview("Choice grid — smallest phone") {
    ChoiceGridPreview()
        .frame(width: 375)
        .background(FGColor.bg)
}

#Preview("Choice grid — roomiest phone") {
    ChoiceGridPreview()
        .frame(width: 440)
        .background(FGColor.bg)
}

/// Three columns of accessibility type is three columns of broken words, so
/// `FlowRow.choices` drops to one. This is the preview that proves it.
#Preview("Choice grid — accessibility type") {
    ChoiceGridPreview()
        .frame(width: 375)
        .environment(\.dynamicTypeSize, .accessibility3)
        .background(FGColor.bg)
}
