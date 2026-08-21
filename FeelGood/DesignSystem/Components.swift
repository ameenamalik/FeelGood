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
            .frame(minHeight: FGSize.minTouchTarget, alignment: .leading)
        }
        .buttonStyle(.plain)
    }
}

/// A selectable answer in the check-in. Two taps, ten seconds.
struct FGChoice: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(FGFont.body)
                .foregroundStyle(isSelected ? FGColor.bg : FGColor.ink)
                .frame(maxWidth: .infinity, minHeight: FGSize.minTouchTarget + 8)
                .background(
                    RoundedRectangle(cornerRadius: FGRadius.button, style: .continuous)
                        .fill(isSelected ? FGColor.ink : FGColor.surface)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: FGRadius.button, style: .continuous)
                        .strokeBorder(isSelected ? Color.clear : FGColor.line, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}
