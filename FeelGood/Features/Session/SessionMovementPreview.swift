//
//  SessionMovementPreview.swift
//  FeelGood
//
//  Quiet, anonymous demonstrations shown before somebody commits to Start.
//  The horizontal strip keeps a longer routine easy to scan without making
//  the detail screen several screens taller.
//

import SwiftUI

struct SessionMovementPreview: View {
    let steps: [Step]

    var body: some View {
        VStack(alignment: .leading, spacing: FGSpace.m) {
            HStack(alignment: .firstTextBaseline) {
                Text(steps.count == 1 ? "See the movement" : "See the movements")
                    .font(FGFont.itemTitle)
                    .foregroundStyle(FGColor.ink)
                Spacer()
                Text("\(steps.count) previews")
                    .font(FGFont.label)
                    .foregroundStyle(FGColor.inkMuted)
            }

            ScrollView(.horizontal) {
                LazyHStack(spacing: FGSpace.s) {
                    ForEach(Array(steps.enumerated()), id: \.offset) { _, step in
                        movementCard(step)
                    }
                }
                .scrollTargetLayout()
            }
            .scrollIndicators(.hidden)
            .scrollTargetBehavior(.viewAligned)
        }
        .padding(FGSpace.m)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: FGRadius.tile, style: .continuous)
                .fill(FGColor.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: FGRadius.tile, style: .continuous)
                .strokeBorder(FGColor.line, lineWidth: 1)
        )
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Movement previews")
    }

    private func movementCard(_ step: Step) -> some View {
        VStack(alignment: .leading, spacing: FGSpace.xs) {
            ExerciseDemoView(glossaryID: step.glossaryID)
                .frame(maxWidth: .infinity)
                .frame(height: 130)

            Text(step.name)
                .font(FGFont.label)
                .foregroundStyle(FGColor.ink)
                .lineLimit(2)
                .frame(maxWidth: .infinity, minHeight: 34, alignment: .topLeading)
        }
        .padding(FGSpace.s)
        // Five columns, two and a half cards wide: the third card is always
        // partly in view, so the strip reads as scrollable at first glance.
        .containerRelativeFrame(.horizontal, count: 5, span: 2, spacing: FGSpace.s)
        .background(
            RoundedRectangle(cornerRadius: FGRadius.card, style: .continuous)
                .fill(FGColor.bg)
        )
    }
}
