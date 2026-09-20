//
//  CheckInBanner.swift
//  FeelGood
//
//  The invitation to check in, shown on Today until someone has. A quiet caption
//  under the headline read as subtitle text and got scrolled past, so this is
//  a real card with a real button. Once there is a check-in it collapses back
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
    private static let pillText = Color(light: 0xA84A2C, dark: 0xA84A2C)
    private static let pillMuted = Color(light: 0x756B5E, dark: 0x756B5E)

    var body: some View {
        Button(action: onTap) {
            ZStack(alignment: .topTrailing) {
                glow
                mascots
                content
            }
            .frame(maxWidth: .infinity, minHeight: 158, alignment: .topLeading)
            .background(
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(Self.gradient)
            )
            .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
            .contentShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        }
        .buttonStyle(.feelGoodPress)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Check in for today. Takes about 30 seconds")
        .accessibilityAddTraits(.isButton)
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("How are you feeling today?")
                .font(.system(size: 24, weight: .semibold, design: .rounded))
                .tracking(-0.2)
                .foregroundStyle(Self.cream)
                .lineSpacing(0)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: 190, alignment: .leading)

            HStack(spacing: 8) {
                Text("Check in")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(Self.pillText)
                Circle()
                    .fill(Self.pillText.opacity(0.5))
                    .frame(width: 3, height: 3)
                Text("30 sec")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(Self.pillMuted)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 11)
            .background(Self.cream, in: Capsule())
        }
        .padding(.horizontal, 22)
        .padding(.top, 22)
        .padding(.bottom, 20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    /// A soft warm light behind the fruit so they lift off the clay.
    private var glow: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [Color(light: 0xFFE8CD, dark: 0xFFE8CD).opacity(0.42), .clear],
                    center: .center,
                    startRadius: 0,
                    endRadius: 75
                )
            )
            .frame(width: 220, height: 220)
            .offset(x: 40, y: -50)
            .accessibilityHidden(true)
    }

    /// Peach, pear and blueberry. Blueberry is the cool one on purpose: a red
    /// fruit disappears into the clay.
    private var mascots: some View {
        ZStack(alignment: .topTrailing) {
            mascot("IntentCalmPeach", size: 76, trailing: 82, top: 52)
            mascot("IntentMobilityPear", size: 84, trailing: 8, top: 14)
            mascot("IntentCalmBlueberryMascot", size: 76, trailing: 16, top: 74)
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
