//
//  ProductIntroView.swift
//  FeelGood
//
//  Three quiet promises before onboarding: what FeelGood is, what it asks,
//  and what it gives back. No account gate—the first real menu comes first.
//

import SwiftUI
import UIKit

struct FirstRunFlow: View {
    static let hasSeenIntroKey = "hasSeenProductIntro"

    let onFinish: (OnboardingModel) -> Void
    @AppStorage(Self.hasSeenIntroKey) private var hasSeenIntro = false

    var body: some View {
        Group {
            if hasSeenIntro {
                OnboardingView(onFinish: onFinish)
            } else {
                ProductIntroView {
                    Analytics.capture("product_intro_completed")
                    hasSeenIntro = true
                }
            }
        }
    }
}

struct ProductIntroView: View {
    private enum Page: Int, CaseIterable {
        case promise
        case checkIn
        case menu

        var buttonTitle: String {
            switch self {
            case .promise: "Next"
            case .checkIn: "Continue"
            case .menu: "Make it mine"
            }
        }
    }

    let onFinish: () -> Void

    @State private var page = Page.promise
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        ZStack {
            FGColor.bg.ignoresSafeArea()
            FGBrandWash(reach: 0.82).ignoresSafeArea()

            GeometryReader { geometry in
                ScrollView {
                    VStack(spacing: 0) {
                        topNavigation

                        Spacer(minLength: typeSize.isAccessibilitySize ? FGSpace.m : FGSpace.l)

                        pageContent
                            .id(page)
                            .transition(pageTransition)

                        Spacer(minLength: FGSpace.l)

                        carouselFooter
                            .padding(.bottom, typeSize.isAccessibilitySize ? FGSpace.m : FGSpace.xxl)
                    }
                    .frame(
                        minHeight: max(0, geometry.size.height - 1),
                        alignment: .center
                    )
                    .padding(.horizontal, FGSpace.page)
                    .padding(.top, FGSpace.xs)
                    .padding(.bottom, FGSpace.l)
                }
                .scrollBounceBehavior(.basedOnSize)
            }
        }
    }

    private var topNavigation: some View {
        HStack {
            if page == .promise {
                Color.clear
                    .frame(width: 52, height: FGSize.minTouchTarget)
            } else {
                Button(action: goBack) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(FGColor.ink)
                        .frame(width: FGSize.minTouchTarget, height: FGSize.minTouchTarget)
                        .background(Circle().fill(FGAura.lilac.core))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Back")
                .frame(width: 52, alignment: .leading)
            }

            Spacer()

            topProgress
                .frame(width: 112)

            Spacer()

            if page == .menu {
                Color.clear
                    .frame(width: 52, height: FGSize.minTouchTarget)
            } else {
                Button("Skip", action: onFinish)
                    .font(FGFont.reason.weight(.semibold))
                    .foregroundStyle(FGColor.ink)
                    .frame(minWidth: 52, minHeight: FGSize.minTouchTarget)
                    .buttonStyle(.plain)
            }
        }
    }

    private var topProgress: some View {
        HStack(spacing: FGSpace.s) {
            ForEach(Page.allCases, id: \.self) { item in
                Capsule()
                    .fill(item.rawValue <= page.rawValue ? FGColor.ink : FGColor.line)
                    .frame(maxWidth: .infinity)
                    .frame(height: 4)
            }
        }
        .accessibilityElement()
        .accessibilityLabel("Introduction \(page.rawValue + 1) of \(Page.allCases.count)")
    }

    @ViewBuilder
    private var pageContent: some View {
        switch page {
        case .promise:
            promisePage
        case .checkIn:
            checkInPage
        case .menu:
            menuPage
        }
    }

    private var promisePage: some View {
        VStack(spacing: FGSpace.m) {
            promiseHero

            introCopy(
                title: "FeelGood",
                detail: "A menu for the day you’re having.\nNo streaks. No scores. No guilt."
            )
        }
        .frame(maxWidth: .infinity)
    }

    private var checkInPage: some View {
        VStack(spacing: FGSpace.l) {
            checkInHero

            introCopy(
                title: "Tell us what today looks like.",
                detail: "Your energy, your time, your space. That’s enough."
            )

            HStack(spacing: FGSpace.s) {
                signalChip("Low energy", aura: .butter)
                signalChip("10 min", aura: .apricot)
                signalChip("Home", aura: .sage)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var menuPage: some View {
        VStack(spacing: FGSpace.l) {
            menuHero

            introCopy(
                title: "We’ll make the menu.",
                detail: "One Main, a few Sides, and always something small enough to start."
            )
        }
        .frame(maxWidth: .infinity)
    }

    private func introCopy(title: String, detail: String) -> some View {
        VStack(spacing: FGSpace.s) {
            Text(title)
                .font(FGFont.display)
                .tracking(-0.7)
                .foregroundStyle(FGColor.ink)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)

            Text(detail)
                .font(FGFont.body)
                .foregroundStyle(FGColor.inkMuted)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: 330)
        .accessibilityElement(children: .combine)
    }

    private var promiseHero: some View {
        appIconMark
            .frame(
                maxWidth: .infinity,
                minHeight: typeSize.isAccessibilitySize ? 104 : 112
            )
            .accessibilityHidden(true)
    }

    private var checkInHero: some View {
        ZStack {
            IntroFruitBackdrop()
                .fill(
                    LinearGradient(
                        colors: [FGAura.butter.core, FGAura.apricot.mid, FGAura.sage.core],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 296, height: 220)

            Image("IntentStrengthPlum")
                .resizable()
                .scaledToFit()
                .frame(width: 84, height: 84)
                .offset(x: -106, y: -62)

            Image("IntentCalmBlueberry")
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .offset(x: 108, y: -66)

            Image("IntentShowingUpBanana")
                .resizable()
                .scaledToFit()
                .frame(width: 114, height: 114)
                .offset(x: -82, y: 46)

            Image("IntentEnergyClementine")
                .resizable()
                .scaledToFit()
                .frame(width: 118, height: 118)
                .offset(x: 18, y: -34)

            Image("IntentMobilityPear")
                .resizable()
                .scaledToFit()
                .frame(width: 108, height: 108)
                .offset(x: 86, y: 56)
        }
        .frame(maxWidth: .infinity, minHeight: heroHeight)
        .accessibilityHidden(true)
    }

    private var menuHero: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 82, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [FGAura.butter.core, FGAura.blush.core, FGAura.apricot.mid],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 282, height: 220)
                .rotationEffect(.degrees(-4))

            VStack(spacing: 7) {
                miniMenuRow("Appetizer", color: FGColor.gold)
                miniMenuRow("Main", color: FGColor.clay, isMain: true)
                miniMenuRow("Side", color: FGColor.sage)
                miniMenuRow("Dessert", color: FGColor.rose)
            }
            .padding(12)
            .frame(width: 214)
            .background(
                RoundedRectangle(cornerRadius: FGRadius.card, style: .continuous)
                    .fill(FGColor.surface)
                    .shadow(color: FGColor.ink.opacity(0.1), radius: 18, y: 9)
            )

            Image("IntentEnergyClementine")
                .resizable()
                .scaledToFit()
                .frame(width: 72, height: 72)
                .offset(x: 118, y: 77)
        }
        .frame(maxWidth: .infinity, minHeight: heroHeight)
        .accessibilityHidden(true)
    }

    private var heroHeight: CGFloat {
        typeSize.isAccessibilitySize ? 228 : 250
    }

    @ViewBuilder
    private var appIconMark: some View {
        if let appIconImage {
            Image(uiImage: appIconImage)
                .resizable()
                .interpolation(.high)
                .scaledToFit()
                .frame(width: 92, height: 92)
                .clipShape(RoundedRectangle(cornerRadius: 21, style: .continuous))
                .shadow(color: FGColor.ink.opacity(0.12), radius: 14, y: 8)
                .accessibilityHidden(true)
        } else {
            RoundedRectangle(cornerRadius: 21, style: .continuous)
                .fill(Color(light: 0x0D0C15, dark: 0x0D0C15))
                .frame(width: 92, height: 92)
                .overlay {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 31, weight: .medium))
                        .foregroundStyle(FGColor.clay)
                }
                .accessibilityHidden(true)
        }
    }

    /// App icons are compiled into specially named bundle files rather than a
    /// normal image set. Reading the declared primary icon keeps this screen
    /// showing the exact shipping artwork instead of maintaining a duplicate.
    private var appIconImage: UIImage? {
        guard
            let icons = Bundle.main.object(forInfoDictionaryKey: "CFBundleIcons") as? [String: Any],
            let primary = icons["CFBundlePrimaryIcon"] as? [String: Any],
            let files = primary["CFBundleIconFiles"] as? [String]
        else { return nil }

        return files.reversed().lazy.compactMap(UIImage.init(named:)).first
    }

    private func signalChip(_ title: String, aura: FGAura) -> some View {
        Text(title)
            .font(FGFont.label)
            .foregroundStyle(FGColor.inkOnAccent)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .padding(.horizontal, 12)
            .frame(minHeight: 36)
        .background(
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [aura.core, aura.mid, aura.edge],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
    }

    private func miniMenuRow(
        _ title: String,
        color: Color,
        isMain: Bool = false
    ) -> some View {
        HStack(spacing: 8) {
            Circle()
                .fill(color)
                .frame(width: isMain ? 12 : 9, height: isMain ? 12 : 9)

            Text(title)
                .font(.system(size: isMain ? 13 : 11, weight: isMain ? .semibold : .medium, design: .rounded))
                .foregroundStyle(FGColor.ink)

            Spacer(minLength: 0)

            Capsule()
                .fill(FGColor.line)
                .frame(width: isMain ? 48 : 32, height: 5)
        }
        .padding(.horizontal, 10)
        .frame(height: isMain ? 40 : 31)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(isMain ? FGAura.apricot.core : FGColor.bg.opacity(0.78))
        )
    }

    private var carouselFooter: some View {
        FGPrimaryButton(title: page.buttonTitle, action: advance)
            .frame(maxWidth: 280)
            .frame(maxWidth: .infinity)
    }

    private var pageTransition: AnyTransition {
        reduceMotion
            ? .opacity
            : .opacity.combined(with: .offset(x: 22))
    }

    private func advance() {
        guard let next = Page(rawValue: page.rawValue + 1) else {
            onFinish()
            return
        }
        withAnimation(FGMotion.settle) { page = next }
    }

    private func goBack() {
        guard let previous = Page(rawValue: page.rawValue - 1) else { return }
        withAnimation(FGMotion.settle) { page = previous }
    }
}

#Preview("Product intro") {
    ProductIntroView {}
}

private struct IntroFruitBackdrop: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX + rect.width * 0.06, y: rect.minY + rect.height * 0.44))
        path.addCurve(
            to: CGPoint(x: rect.minX + rect.width * 0.33, y: rect.minY + rect.height * 0.07),
            control1: CGPoint(x: rect.minX + rect.width * 0.07, y: rect.minY + rect.height * 0.20),
            control2: CGPoint(x: rect.minX + rect.width * 0.17, y: rect.minY + rect.height * 0.05)
        )
        path.addCurve(
            to: CGPoint(x: rect.minX + rect.width * 0.88, y: rect.minY + rect.height * 0.25),
            control1: CGPoint(x: rect.minX + rect.width * 0.53, y: rect.minY - rect.height * 0.02),
            control2: CGPoint(x: rect.minX + rect.width * 0.79, y: rect.minY + rect.height * 0.05)
        )
        path.addCurve(
            to: CGPoint(x: rect.minX + rect.width * 0.88, y: rect.minY + rect.height * 0.78),
            control1: CGPoint(x: rect.maxX + rect.width * 0.02, y: rect.minY + rect.height * 0.43),
            control2: CGPoint(x: rect.maxX - rect.width * 0.01, y: rect.minY + rect.height * 0.68)
        )
        path.addCurve(
            to: CGPoint(x: rect.minX + rect.width * 0.27, y: rect.minY + rect.height * 0.94),
            control1: CGPoint(x: rect.minX + rect.width * 0.69, y: rect.maxY + rect.height * 0.03),
            control2: CGPoint(x: rect.minX + rect.width * 0.43, y: rect.maxY + rect.height * 0.01)
        )
        path.addCurve(
            to: CGPoint(x: rect.minX + rect.width * 0.06, y: rect.minY + rect.height * 0.44),
            control1: CGPoint(x: rect.minX + rect.width * 0.10, y: rect.minY + rect.height * 0.88),
            control2: CGPoint(x: rect.minX - rect.width * 0.02, y: rect.minY + rect.height * 0.65)
        )
        path.closeSubpath()
        return path
    }
}
