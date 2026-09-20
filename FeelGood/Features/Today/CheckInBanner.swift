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
            ZStack(alignment: .topTrailing) {
                glow
                mascots
                content
            }
            .frame(maxWidth: .infinity, minHeight: 120, alignment: .topLeading)
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
        VStack(alignment: .leading, spacing: 8) {
            Text("How are you feeling today?")
                .font(.system(size: 22, weight: .semibold, design: .rounded))
                .tracking(-0.2)
                .foregroundStyle(Self.cream)
                .lineSpacing(0)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: 170, alignment: .leading)

            // Metadata, not a nested button: the whole card is the target.
            HStack(spacing: 4) {
                Text("30 sec · Tap to start")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .bold))
            }
            .foregroundStyle(Self.cream.opacity(0.85))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }

    /// A soft warm light behind the fruit so they lift off the clay.
    private var glow: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [Color(light: 0xFFE8CD, dark: 0xFFE8CD).opacity(0.42), .clear],
                    center: .center,
                    startRadius: 0,
                    endRadius: 60
                )
            )
            .frame(width: 170, height: 170)
            .offset(x: 30, y: -30)
            .accessibilityHidden(true)
    }

    /// Peach, pear and blueberry. Blueberry is the cool one on purpose: a red
    /// fruit disappears into the clay.
    private var mascots: some View {
        ZStack(alignment: .topTrailing) {
            mascot("IntentCalmPeach", size: 52, trailing: 76, top: 18)
            mascot("IntentMobilityPear", size: 56, trailing: 12, top: 14)
            mascot("IntentCalmBlueberryMascot", size: 48, trailing: 46, top: 62)
        }
        .accessibilityHidden(true)
    }

    private func mascot(_ name: String, size: CGFloat, trailing: CGFloat, top: CGFloat) -> some View {
        Image(name)
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
            .padding(.trailing, trailing)
            .padding(.top, top)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
    }
}

#Preview {
    CheckInBanner {}
        .padding(FGSpace.page)
        .background(FGColor.bg)
}
