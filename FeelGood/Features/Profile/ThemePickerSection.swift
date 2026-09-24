//
//  ThemePickerSection.swift
//  FeelGood
//
//  "Your look". Shown only once a second look has been earned — until then it
//  does not exist on screen, so nothing says what the person has not done
//  (docs/PRD-themes.md §7). Choosing is instant and free; a look is never
//  taken back.
//

import SwiftUI

struct ThemePickerSection: View {
    let unlocked: [FGThemeID]
    @Environment(ThemeSettings.self) private var settings

    var body: some View {
        if unlocked.count > 1 {
            VStack(alignment: .leading, spacing: FGSpace.m) {
                VStack(alignment: .leading, spacing: FGSpace.xs) {
                    Text("Your look")
                        .font(FGFont.title)
                        .foregroundStyle(FGColor.ink)
                    Text("Pick the one that feels like you.")
                        .font(FGFont.reason)
                        .foregroundStyle(FGColor.inkMuted)
                }

                HStack(spacing: FGSpace.s) {
                    ForEach(unlocked, id: \.self) { id in
                        ThemeOption(
                            id: id,
                            isSelected: settings.effective(unlocked: unlocked) == id
                        ) {
                            settings.selected = id
                        }
                    }
                }
            }
        }
    }
}

private struct ThemeOption: View {
    let id: FGThemeID
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: FGSpace.xs) {
                ThemePreview()
                    // A subtree can override its parent, so this shows *that*
                    // look while the rest of the screen wears the current one.
                    .environment(\.fgTheme, id)
                    .frame(height: 132)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .strokeBorder(isSelected ? FGColor.ink : FGColor.lineStrong, lineWidth: isSelected ? 3 : 1.5)
                    )

                HStack(spacing: 6) {
                    // Selection is a mark as well as a heavier border, never
                    // colour alone.
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .accessibilityHidden(true)
                    }
                    Text(id.title)
                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                }
                .foregroundStyle(FGColor.ink)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.feelGoodPress)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(id.title) look")
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }
}

/// A miniature Today: page, hero, and two course cards. Built from the same
/// tokens as the real screen, so it cannot drift from it.
private struct ThemePreview: View {
    var body: some View {
        VStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(FGColor.bannerGradient)
                .frame(height: 34)
            ForEach([Course.appetizer, .main], id: \.self) { course in
                HStack {
                    Capsule().fill(course.chipFill).frame(width: 36, height: 9)
                    Spacer()
                    Circle().fill(course.plate).frame(width: 20, height: 20)
                }
                .padding(.horizontal, 8)
                .frame(height: 34)
                .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(course.fill))
                .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).strokeBorder(course.edge, lineWidth: 1))
            }
        }
        .padding(8)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(FGColor.bg)
    }
}
