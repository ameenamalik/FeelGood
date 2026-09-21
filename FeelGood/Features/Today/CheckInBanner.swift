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

    // The banner is the one saturated block on the page, so its colours are
    // fixed rather than adaptive: a warm clay card with cream type reads the
    // same in light and dark.
    private static let gradient = LinearGradient(
        colors: [
            Color(light: 0xCB6C46, dark: 0xCB6C46),
            Color(light: 0xB4532F, dark: 0xB4532F),
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    private static let cream = Color(light: 0xFFFDF9, dark: 0xFFFDF9)

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
                    .fill(Self.gradient)
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
                .foregroundStyle(Self.cream)
                .lineSpacing(0)
                .fixedSize(horizontal: false, vertical: true)

            // Metadata, not a nested button: the whole card is the target.
            HStack(spacing: 4) {
                Text("30 sec · Tap to start")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .bold))
            }
            .foregroundStyle(Self.cream.opacity(0.85))
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
                        colors: [Color(light: 0xFFE8CD, dark: 0xFFE8CD).opacity(0.42), .clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 58
                    )
                )
                .frame(width: 126, height: 126)

            mascot("IntentCalmPeach", size: 42)
                .offset(x: -38, y: -15)
            mascot("IntentMobilityPear", size: 46)
                .offset(x: 34, y: -14)
            mascot("IntentCalmBlueberryMascot", size: 40)
                .offset(x: 2, y: 24)
        }
        .frame(width: 132, height: 80)
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
