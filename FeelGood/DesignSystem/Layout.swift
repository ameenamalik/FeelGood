//
//  Layout.swift
//  FeelGood
//
//  Generous whitespace, large touch targets, one idea per screen.
//

import SwiftUI

nonisolated enum FGSpace {
    static let xs: CGFloat = 4
    static let s: CGFloat = 8
    static let m: CGFloat = 16
    static let l: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 48
    /// Standard page inset.
    static let page: CGFloat = 24
}

nonisolated enum FGRadius {
    static let card: CGFloat = 20
    static let chip: CGFloat = 10
    static let button: CGFloat = 16
}

nonisolated enum FGSize {
    /// Never smaller than this, anywhere.
    static let minTouchTarget: CGFloat = 44
}
