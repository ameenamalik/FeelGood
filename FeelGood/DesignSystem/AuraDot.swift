//
//  AuraDot.swift
//  FeelGood
//
//  A small bloom of colour, lit from just above centre.
//
//  The menu leads every row with one in its course's colour, and the check-in
//  card with one in pink. It replaces nothing functional — the course is named
//  in the pill beside it — so it can be purely a bit of warmth on a page that
//  is otherwise cards and type.
//

import SwiftUI

struct AuraDot: View {
    let color: Color
    var size: CGFloat = 52

    var body: some View {
        Circle()
            .fill(
                RadialGradient(
                    gradient: Gradient(stops: [
                        // White rather than a token: this is a highlight on a
                        // colour, not type on a surface, so it should not flip
                        // to near-black at night and swallow the bloom.
                        .init(color: .white, location: 0),
                        .init(color: color.opacity(0.55), location: 0.24),
                        .init(color: color, location: 0.44),
                        .init(color: color.opacity(0.45), location: 0.66),
                        .init(color: color.opacity(0), location: 0.88),
                    ]),
                    center: UnitPoint(x: 0.5, y: 0.46),
                    startRadius: 0,
                    endRadius: size / 2
                )
            )
            .frame(width: size, height: size)
            .accessibilityHidden(true)
    }
}
