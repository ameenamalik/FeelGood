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
                        isHighlighted ? FGColor.clayDeep : FGColor.lineStrong,
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
                .foregroundStyle(isEnabled ? FGColor.onActionFill : FGColor.inkMuted)
                .frame(maxWidth: .infinity, minHeight: 56)
                .contentShape(Capsule())
                .background(
                    Capsule()
                        .fill(isEnabled ? FGColor.actionFill : FGColor.line)
                )
        }
        .buttonStyle(.feelGoodPress)
        .disabled(!isEnabled)
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
            label
        }
        .buttonStyle(.plain)
    }

    private var label: some View {
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
        .padding(.horizontal, FGSpace.xs)
        .contentShape(Capsule())
        // Keep secondary actions intentionally quiet with no background.
        .modifier(FGQuietGlass())
    }
}

private struct FGQuietGlass: ViewModifier {
    func body(content: Content) -> some View {
        content
    }
}

/// A selectable answer in the check-in. Two taps, ten seconds.
///
/// The visual, detail, and accent are optional so each flow can keep its own
/// expression without changing the choice's typography or selection styling.
struct FGChoice: View {
    @Environment(\.colorScheme) private var colorScheme
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
                        .foregroundStyle(selectedForeground)
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
                            .fill(isSelected && colorScheme != .dark ? accent.fill.opacity(0.3) : .clear)
                    )
            )
            .overlay(
                // Selection is never signalled by colour alone: the border
                // gains weight too, while its hue connects it to the tint.
                RoundedRectangle(cornerRadius: hasVisual ? 20 : FGRadius.button, style: .continuous)
                    .strokeBorder(
                        selectionBorder,
                        lineWidth: isSelected ? 1.5 : 1
                    )
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel([title, detail].compactMap(\.self).joined(separator: ", "))
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }

    private var selectedForeground: Color {
        guard isSelected else { return FGColor.ink }
        return colorScheme == .dark ? FGColor.ink : accent.text
    }

    private var selectionBorder: Color {
        guard isSelected else { return FGColor.lineStrong }
        return colorScheme == .dark ? FGColor.ink : accent.text.opacity(0.95)
    }
}

/// A check-in or onboarding answer, resting as a neutral card and blooming
/// into colour when it is picked.
///
/// The counterpart to `FGChoice`, and the difference is only visible on
/// selection. `FGChoice` tints a white tile with a flat accent; this one swaps
/// the whole surface for a soft wash and puts an ink border round it, which is
/// what makes a picked answer read from across the screen.
///
/// The first attempt had every tile washed all the time. It looked like a wall
/// rather than a set of choices, and in a sixteen-tile grid there was no
/// resting state left to contrast the picked one against. Neutral-until-picked
/// also fixes the dark mode problem for free: an unpicked tile carries `ink`,
/// which flips, and only the picked one carries `inkOnAccent`, which must not.
///
/// The wash is two offset `RadialGradient`s over a `LinearGradient`, which is
/// what gives the corner-lit look. `MeshGradient` would do the same in fewer
/// lines and is available on iOS 18, but it interpolates its own way between
/// control points and would not land on the values these stops were chosen for.
struct FGAuraTile: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dynamicTypeSize) private var typeSize

    let title: String
    var detail: String? = nil
    var systemImage: String? = nil
    /// Optional decorative artwork that lives inside the card without adding
    /// another VoiceOver stop. Hidden when Dynamic Type needs the full tile.
    var artworkName: String? = nil
    var artworkSize: CGFloat = 92
    var artworkAlignment: Alignment = .top
    /// `.display` puts the title in the 40pt light numeral the artboard uses
    /// for the time question, with its unit small underneath. `.standard` is
    /// the headline every other answer gets.
    var titleStyle: TitleStyle = .standard
    var contentPlacement: ContentPlacement = .center
    var preferredHeight: CGFloat? = nil
    var showsAuraAtRest = false
    let aura: FGAura
    let isSelected: Bool
    let action: () -> Void

    private var tileHeight: CGFloat? {
        typeSize.isAccessibilitySize ? nil : (preferredHeight ?? FGSize.auraTile)
    }

    /// One line for a single word, two for a phrase.
    ///
    /// Not cosmetic. Given two lines to play with, SwiftUI would rather
    /// hyphenate a long word than shrink it — "Postpartum" came out as
    /// "Postpar-tum" and `minimumScaleFactor` never got a chance, because the
    /// text technically fit. Capping a single word at one line leaves scaling
    /// as the only way to make it fit, which is the one we want. A phrase still
    /// gets its second line and breaks at the space, where it should.
    private var titleLineLimit: Int? {
        guard !typeSize.isAccessibilitySize else { return nil }
        return title.contains(" ") ? 2 : 1
    }

    /// Ink that flips with the appearance when the tile is neutral; ink that
    /// does not when it is washed, because the wash does not either.
    private var foreground: Color {
        usesAuraSurface ? FGColor.inkOnAccent : FGColor.ink
    }

    var body: some View {
        Button(action: action) {
            ZStack(alignment: .bottomLeading) {
                if let artworkName, !typeSize.isAccessibilitySize {
                    Image(artworkName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: artworkSize, height: artworkSize)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: artworkAlignment)
                        .padding(.top, FGSpace.xs)
                        .accessibilityHidden(true)
                        .allowsHitTesting(false)
                }

                VStack(
                    alignment: contentPlacement == .bottomLeading ? .leading : .center,
                    spacing: FGSpace.xs
                ) {
                    if let systemImage {
                        Image(systemName: systemImage)
                            .font(.title2)
                            .symbolRenderingMode(.monochrome)
                            .frame(height: typeSize.isAccessibilitySize ? nil : 26)
                            .foregroundStyle(foreground)
                            .accessibilityHidden(true)
                            .padding(.bottom, FGSpace.xs)
                    }

                    Text(title)
                        .font(titleFont)
                        .tracking(titleStyle == .display ? -1.8 : 0)
                        .multilineTextAlignment(contentPlacement == .bottomLeading ? .leading : .center)
                        .lineLimit(titleLineLimit)
                        .minimumScaleFactor(typeSize.isAccessibilitySize ? 1 : 0.75)
                        .foregroundStyle(foreground)

                    if let detail {
                        Text(detail)
                            .font(FGFont.label)
                            .multilineTextAlignment(contentPlacement == .bottomLeading ? .leading : .center)
                            .foregroundStyle(foreground.opacity(0.7))
                    }
                }
                .padding(contentPlacement == .bottomLeading ? FGSpace.m : 12)
                .frame(
                    maxWidth: .infinity,
                    maxHeight: .infinity,
                    alignment: contentPlacement == .bottomLeading ? .bottomLeading : .center
                )
            }
            .frame(
                maxWidth: .infinity,
                minHeight: tileHeight ?? (FGSize.minTouchTarget + 8),
                maxHeight: hasFixedHeight ? tileHeight : nil,
                alignment: contentPlacement == .bottomLeading ? .bottomLeading : .center
            )
            .background(surface)
            .overlay(alignment: .topTrailing) {
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Color.black)
                        .frame(width: 24, height: 24)
                        .background(Circle().fill(Color.white))
                        .padding(10)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: FGRadius.tile, style: .continuous)
                    .strokeBorder(
                        isSelected ? selectedBorder : FGColor.line,
                        lineWidth: isSelected ? 3.5 : 1
                    )
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel([title, detail].compactMap(\.self).joined(separator: ", "))
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }

    /// Fixed at ordinary sizes so a two-line label does not leave its
    /// neighbours looking clipped; free to grow once the type is large.
    private var hasFixedHeight: Bool { !typeSize.isAccessibilitySize }

    enum TitleStyle { case standard, display }
    enum ContentPlacement { case center, bottomLeading }

    private var titleFont: Font {
        switch titleStyle {
        case .standard: FGFont.itemTitle
        // Light at rest, regular when picked — the weight shift is part of how
        // the artboard signals the choice, alongside the wash.
        case .display: .system(size: 40, weight: isSelected ? .regular : .light, design: .rounded)
        }
    }

    @ViewBuilder
    private var surface: some View {
        if isSelected {
            RoundedRectangle(cornerRadius: FGRadius.tile, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [aura.mid, aura.edge.opacity(0.9)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay {
                    washRadialOverlays
                }
        } else if showsAuraAtRest {
            wash.opacity(0.58)
        } else {
            RoundedRectangle(cornerRadius: FGRadius.tile, style: .continuous)
                .fill(FGAura.resting)
        }
    }

    private var usesAuraSurface: Bool {
        showsAuraAtRest || isSelected
    }

    private var selectedBorder: Color {
        colorScheme == .dark ? FGColor.ink : FGColor.inkOnAccent
    }

    private var washRadialOverlays: some View {
        ZStack {
            RoundedRectangle(cornerRadius: FGRadius.tile, style: .continuous)
                .fill(
                    RadialGradient(
                        colors: [aura.core, aura.core.opacity(0)],
                        center: UnitPoint(x: 0.28, y: 0.22),
                        startRadius: 0,
                        endRadius: 120
                    )
                )
            RoundedRectangle(cornerRadius: FGRadius.tile, style: .continuous)
                .fill(
                    RadialGradient(
                        colors: [aura.mid, aura.mid.opacity(0)],
                        center: UnitPoint(x: 0.78, y: 0.84),
                        startRadius: 0,
                        endRadius: 110
                    )
                )
        }
    }

    /// Bright core at the upper left, a second bloom at the upper right, both
    /// falling away to the edge colour.
    private var wash: some View {
        RoundedRectangle(cornerRadius: FGRadius.tile, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [aura.mid, aura.edge],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay {
                washRadialOverlays
            }
    }
}


/// A short answer as a capsule.
///
/// Deliberately plainer than `FGAuraTile`. Some questions are a quick list of
/// things to rule out, and a grid of colour fields makes ruling something out
/// feel weightier than it is.
struct FGPill: View {
    let title: String
    var selectedAura: FGAura? = nil
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(FGFont.body.weight(.medium))
                .foregroundStyle(pillForeground)
                .padding(.vertical, 11)
                .padding(.horizontal, 17)
                .frame(minHeight: FGSize.minTouchTarget)
                .background(Capsule().fill(pillFill))
                .overlay(
                    Capsule().strokeBorder(
                        pillBorder,
                        lineWidth: isSelected ? 1.5 : 1
                    )
                )
                .contentShape(Capsule())
        }
        .buttonStyle(.feelGoodPress)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }

    private var pillFill: AnyShapeStyle {
        if isSelected, let selectedAura {
            return AnyShapeStyle(
                LinearGradient(
                    colors: [selectedAura.core, selectedAura.mid, selectedAura.edge],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        }
        return AnyShapeStyle(isSelected ? FGColor.ink : FGColor.surface)
    }

    private var pillForeground: Color {
        guard isSelected else { return FGColor.ink }
        return selectedAura == nil ? FGColor.bg : FGColor.inkOnAccent
    }

    private var pillBorder: Color {
        guard isSelected else { return FGColor.lineStrong }
        return FGColor.inkOnAccent.opacity(0.72)
    }
}

// MARK: - Previews

/// The choice grid at the widths that actually decide its column count. A tile
/// pinned to a fixed width once collapsed this to two columns and an orphan on
/// every phone narrower than an iPhone 17, and nothing here rendered it at a
/// width small enough to show that — so these previews start at the narrow end.
private struct ChoiceGridPreview: View {
    @Environment(\.dynamicTypeSize) private var typeSize

    @State private var selected = "Medium"

    private let options = [
        ("Low", "cloud"),
        ("Medium", "cloud.sun"),
        ("High", "sun.max")
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

/// A code-level guarantee that a RevenueCat paywall always has a way out.
///
/// `PaywallView(displayCloseButton:)` only affects the legacy "original
/// template" paywalls — a V2 Paywall Builder template renders its own close
/// affordance per its dashboard config, and silently ignores the parameter.
/// If that template is ever edited to drop its close element, the paywall
/// becomes unskippable with no compile-time or code-review signal. This
/// overlay never depends on template content, so it can't regress that way.
extension View {
    func guaranteedPaywallCloseButton(action: @escaping () -> Void) -> some View {
        overlay(alignment: .topTrailing) {
            Button(action: action) {
                // The system close affordance: a small tinted disc with a
                // light glyph, sitting inside a full-size tap target.
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(FGColor.inkMuted)
                    .frame(width: 30, height: 30)
                    .background(FGColor.ink.opacity(0.08), in: Circle())
                    .frame(width: FGSize.minTouchTarget, height: FGSize.minTouchTarget)
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Close")
            .padding(.top, FGSpace.xs)
            .padding(.trailing, FGSpace.xs)
        }
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
