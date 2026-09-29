//
//  CheckInBanner.swift
//  FeelGood
//
//  The invitation to check in, shown on Today until someone has. A quiet caption
//  under the headline read as subtitle text and got scrolled past, so this is
//  a real card, tappable end to end. Once there is a check-in it collapses back
//  to the one-line summary (`TodayView.checkInSubtitle`) — no dismiss, no
//  nag state, nothing that counts.
//
//  Paper: "Today — Check-in banner (before check-in)", file "Jazzy tulip".
//

import SwiftUI

struct CheckInBanner: View {
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .center, spacing: 8) {
                content
                mascotCluster
            }
            .padding(.leading, 20)
            .padding(.trailing, 14)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(FGColor.bannerGradient)
            )
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .contentShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        }
        .buttonStyle(.feelGoodPress)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Check in for today. Takes about 30 seconds")
        .accessibilityAddTraits(.isButton)
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("How are you feeling today?")
                .font(.system(size: 20, weight: .semibold, design: .rounded))
                .tracking(-0.2)
                .foregroundStyle(FGColor.onBanner)
                .lineSpacing(0)
                .fixedSize(horizontal: false, vertical: true)

            // Metadata, not a nested button: the whole card is the target.
            HStack(spacing: 4) {
                Text("30 sec · Tap to start")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .bold))
            }
            .foregroundStyle(FGColor.onBanner.opacity(0.85))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// One fixed-size illustration block keeps the fruit vertically centered
    /// with the copy. None of its children ask for infinite height, so the
    /// artwork can no longer make the card grow and leave an empty lower half.
    private var mascotCluster: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [FGColor.bannerGlow.opacity(0.42), .clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 46
                    )
                )
                .frame(width: 98, height: 98)

            mascot("IntentCalmPeach", size: 32)
                .offset(x: -28, y: -11)
            mascot("IntentMobilityPear", size: 36)
                .offset(x: 25, y: -10)
            mascot("IntentCalmBlueberryMascot", size: 30)
                .offset(x: 2, y: 18)
        }
        .frame(width: 102, height: 68)
        .accessibilityHidden(true)
    }

    private func mascot(_ name: String, size: CGFloat) -> some View {
        Image(name)
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
    }
}

#Preview {
    CheckInBanner {}
        .padding(FGSpace.page)
        .background(FGColor.bg)
}
