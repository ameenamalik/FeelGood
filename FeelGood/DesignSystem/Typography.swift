//
//  Typography.swift
//  FeelGood
//
//  Sora for headlines — confident and modern; DM Sans for body copy. Both fall
//  back to the system face until the files are added to the bundle, so the app
//  never ships a missing-font crash or an invisible label.
//

import SwiftUI

enum FGFont {
    /// Set once the .ttf files are in the bundle. Until then everything below
    /// resolves to the system face at the same sizes and weights.
    static let displayFamily = "Sora"
    static let textFamily = "DM Sans"

    static let display = custom(displayFamily, .largeTitle, weight: .bold)
    static let title = custom(displayFamily, .title2, weight: .bold)
    static let itemTitle = custom(displayFamily, .headline, weight: .semibold)

    static let body = custom(textFamily, .body, weight: .regular)
    static let reason = custom(textFamily, .subheadline, weight: .regular)
    static let caption = custom(textFamily, .footnote, weight: .regular)
    static let label = custom(textFamily, .caption, weight: .medium)

    /// Scales with Dynamic Type either way — a custom face is only used when it
    /// is actually installed.
    private static func custom(_ family: String, _ style: Font.TextStyle, weight: Font.Weight) -> Font {
        isAvailable(family)
            ? .custom(family, size: UIFont.preferredFont(forTextStyle: style.uiStyle).pointSize, relativeTo: style).weight(weight)
            : .system(style, design: .default).weight(weight)
    }

    private static func isAvailable(_ family: String) -> Bool {
        !UIFont.fontNames(forFamilyName: family).isEmpty
    }
}

private extension Font.TextStyle {
    var uiStyle: UIFont.TextStyle {
        switch self {
        case .largeTitle: .largeTitle
        case .title: .title1
        case .title2: .title2
        case .title3: .title3
        case .headline: .headline
        case .subheadline: .subheadline
        case .callout: .callout
        case .footnote: .footnote
        case .caption: .caption1
        case .caption2: .caption2
        default: .body
        }
    }
}
