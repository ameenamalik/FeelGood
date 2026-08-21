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
                    .strokeBorder(isHighlighted ? FGColor.lime : FGColor.line, lineWidth: isHighlighted ? 2 : 1)
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
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(FGFont.body.weight(.medium))
                .foregroundStyle(FGColor.bg)
                .frame(maxWidth: .infinity, minHeight: FGSize.minTouchTarget)
                .background(
                    RoundedRectangle(cornerRadius: FGRadius.button, style: .continuous)
                        .fill(FGColor.ink)
                )
        }
        .buttonStyle(.plain)
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
/// The emoji, detail, and accent are all optional, so onboarding — which shares
/// this component — keeps the plain title-only tile it has always had.
struct FGChoice: View {
    let title: String
    var emoji: String? = nil
    var detail: String? = nil
    var accent: FGAccent = .ink
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: FGSpace.xs) {
                if let emoji {
                    // A text style, so it grows with Dynamic Type instead of
                    // stranding a fixed-size glyph next to huge type. Hidden
                    // from VoiceOver, which would otherwise read "cloud".
                    Text(emoji)
                        .font(.title)
                        .accessibilityHidden(true)
                }

                Text(title)
                    .font(FGFont.body)
                    .multilineTextAlignment(.center)

                if let detail {
                    Text(detail)
                        .font(FGFont.label)
                        .multilineTextAlignment(.center)
                        .opacity(0.7)
                }
            }
            .foregroundStyle(isSelected ? accent.text : FGColor.ink)
            .padding(.vertical, emoji == nil ? 0 : FGSpace.s)
            .padding(.horizontal, FGSpace.xs)
            // Fill the height `FlowRow` offers, so a two-line label doesn't
            // leave its neighbours in the row looking clipped short. Only the
            // emoji tiles do this; onboarding's plain rows keep hugging.
            .frame(
                maxWidth: .infinity,
                minHeight: FGSize.minTouchTarget + 8,
                maxHeight: emoji == nil ? nil : .infinity
            )
            .background(
                RoundedRectangle(cornerRadius: FGRadius.button, style: .continuous)
                    .fill(isSelected ? accent.fill : FGColor.surface)
            )
            .overlay(
                // Selection is never signalled by colour alone: the border
                // doubles in weight and darkens, which survives both a
                // greyscale screenshot and a colour-blind reader.
                RoundedRectangle(cornerRadius: FGRadius.button, style: .continuous)
                    .strokeBorder(isSelected ? FGColor.ink : FGColor.line, lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel([title, detail].compactMap(\.self).joined(separator: ", "))
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}
