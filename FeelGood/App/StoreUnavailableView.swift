//
//  StoreUnavailableView.swift
//  FeelGood
//
//  What somebody sees when the store won't open. Two things this screen must
//  never do: imply the history is gone (it isn't — it's on the device, unread),
//  and quietly route into onboarding as though this were a first launch.
//

import SwiftUI

struct StoreUnavailableView: View {
    let onRetry: () -> Void
    let onContinueAnyway: () -> Void

    var body: some View {
        ZStack {
            FGColor.bg.ignoresSafeArea()

            VStack(alignment: .leading, spacing: FGSpace.l) {
                Spacer()

                Text("Give it a moment.")
                    .font(FGFont.display)
                    .foregroundStyle(FGColor.ink)
                    .fixedSize(horizontal: false, vertical: true)

                Text("""
                    Everything you've done is still on this device — the app just \
                    couldn't open it this time. Closing it and opening it again \
                    usually sorts it out.
                    """)
                    .font(FGFont.body)
                    .foregroundStyle(FGColor.inkMuted)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer()

                VStack(spacing: FGSpace.s) {
                    FGPrimaryButton(title: "Try again", action: onRetry)

                    FGQuietButton("Just show me today", systemImage: "arrow.right", action: onContinueAnyway)

                    Text("Nothing from today would be kept.")
                        .font(FGFont.caption)
                        .foregroundStyle(FGColor.inkMuted)
                }
                .frame(maxWidth: .infinity)
            }
            .padding(FGSpace.page)
        }
        .accessibilityElement(children: .contain)
    }
}

#Preview {
    StoreUnavailableView(onRetry: {}, onContinueAnyway: {})
}
