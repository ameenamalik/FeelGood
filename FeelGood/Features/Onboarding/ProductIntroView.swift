//
//  ProductIntroView.swift
//  FeelGood
//
//  Two quiet promises before onboarding: what FeelGood is and what it asks.
//  `FirstRunFlow` below sequences intro → the onboarding quiz → the person's
//  first menu. The optional account prompt comes only after the first completed
//  session, when there is real progress worth saving; see PRD §7.0/§7.1.
//

import SwiftUI
import UIKit

/// The local installation boundary for the welcome flow.
///
/// Firebase keeps authentication in the Keychain, which can survive deleting
/// and reinstalling the app. A restored session must not be mistaken for proof
/// that onboarding happened in this installation. This flag lives in the app
/// container instead: deleting the app removes it, so the welcome flow wins
/// before account restoration or a recovered profile can route to Today.
@MainActor
enum InstallationFirstRun {
    static let completedKey = "FeelGood.InstallationOnboardingCompleted.v1"
    private static let startedKey = "FeelGood.InstallationOnboardingStarted.v1"

    /// Called once when `RootView` is created.
    ///
    /// `hasSeenProductIntro` migrates people who completed onboarding before
    /// this installation marker existed. A real reinstall has neither local
    /// key, even when Firebase restores its Keychain session.
    static func prepare(defaults: UserDefaults = .standard) -> Bool {
        if defaults.object(forKey: completedKey) != nil {
            return !defaults.bool(forKey: completedKey)
        }

        // SwiftUI can recreate RootView after the product intro but before the
        // quiz is finished. Once this installation has started onboarding,
        // `hasSeenProductIntro` belongs to this run and is not legacy evidence.
        if defaults.bool(forKey: startedKey) {
            return true
        }

        if defaults.bool(forKey: FirstRunFlow.hasSeenIntroKey) {
            defaults.set(true, forKey: completedKey)
            return false
        }

        defaults.set(true, forKey: startedKey)
        resetWelcomeState(defaults: defaults)
        return true
    }

    static func markCompleted(defaults: UserDefaults = .standard) {
        defaults.set(true, forKey: completedKey)
        defaults.removeObject(forKey: startedKey)
    }

    private static func resetWelcomeState(defaults: UserDefaults) {
        FirstRunFlow.resetForSignedOutUser(defaults: defaults)
        defaults.set(false, forKey: "hasShownFirstCompletionAuthPrompt")
        defaults.set(false, forKey: "hasShownFirstCompletionPaywall")
        defaults.set(false, forKey: "hasSeenDopamineMenuTour")
    }
}

struct FirstRunFlow: View {
    static let hasSeenIntroKey = "hasSeenProductIntro"
    static let hasSeenWelcomeSignUpKey = "hasSeenWelcomeSignUp"

    let onFinish: (OnboardingModel) -> Void
    @AppStorage(Self.hasSeenIntroKey) private var hasSeenIntro = false
    @State private var settingUpModel: OnboardingModel?

    /// A signed-out account becomes a fresh local guest. Replay the product
    /// promises and account choice before asking for new preferences.
    static func resetForSignedOutUser(defaults: UserDefaults = .standard) {
        defaults.set(false, forKey: hasSeenIntroKey)
        defaults.set(false, forKey: hasSeenWelcomeSignUpKey)
    }

    var body: some View {
        Group {
            if !hasSeenIntro {
                ProductIntroView {
                    Analytics.capture("product_intro_completed")
                    hasSeenIntro = true
                }
            } else if let settingUp = settingUpModel {
                SettingUpMenuView {
                    settingUpModel = nil
                    onFinish(settingUp)
                }
            } else {
                OnboardingView { onboarding in
                    settingUpModel = onboarding
                }
            }
        }
    }
}

struct ProductIntroView: View {
    private enum Page: Int, CaseIterable {
        case promise
        case checkIn

        var buttonTitle: String {
            switch self {
            case .promise: "Next"
            case .checkIn: "Start"
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
                            .contentShape(Rectangle())
                            .simultaneousGesture(
                                DragGesture(minimumDistance: 30)
                                    .onEnded { value in
                                        guard abs(value.translation.width) > abs(value.translation.height) * 1.5 else { return }
                                        if value.translation.width < -50, page == .promise {
                                            advance()
                                        } else if value.translation.width > 50 {
                                            goBack()
                                        }
                                    }
                            )

                        Spacer(minLength: FGSpace.l)

                        carouselFooter
                            .padding(.bottom, typeSize.isAccessibilitySize ? FGSpace.m : FGSpace.xxl)
                    }
                    .frame(
                        width: max(0, geometry.size.width - FGSpace.page * 2),
                        alignment: .center
                    )
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
                        .foregroundStyle(FGColor.inkOnAccent)
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

            if page == .checkIn {
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

            WrapRow(spacing: FGSpace.s, lineSpacing: FGSpace.s) {
                signalChip("Low energy", aura: .butter)
                signalChip("10 min", aura: .apricot)
                signalChip("Home", aura: .sage)
            }
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
        GeometryReader { geometry in
            // Scale the artwork and its offsets together within the available
            // width, leaving breathing room at both sides on smaller phones.
            let scale = max(0, min(1, (geometry.size.width - 16) / 296, geometry.size.height / 220))
            ZStack {
                IntroFruitBackdrop()
                    .fill(
                        LinearGradient(
                            colors: [FGAura.butter.core, FGAura.apricot.mid, FGAura.sage.core],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 296 * scale, height: 220 * scale)

                Image("IntentStrengthPlum")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 84 * scale, height: 84 * scale)
                    .offset(x: -106 * scale, y: -62 * scale)

                Image("IntentCalmBlueberryMascot")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80 * scale, height: 80 * scale)
                    .offset(x: 108 * scale, y: -66 * scale)

                Image("IntentShowingUpBanana")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 114 * scale, height: 114 * scale)
                    .offset(x: -82 * scale, y: 46 * scale)

                Image("IntentEnergyClementine")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 118 * scale, height: 118 * scale)
                    .offset(x: 18 * scale, y: -34 * scale)

                Image("IntentMobilityPear")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 108 * scale, height: 108 * scale)
                    .offset(x: 86 * scale, y: 56 * scale)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .frame(height: heroHeight)
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
                .fill(FGColor.appIconFallback)
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

    private var carouselFooter: some View {
        FGPrimaryButton(title: page.buttonTitle, action: advance)
            .frame(maxWidth: 280)
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

nonisolated private struct IntroFruitBackdrop: Shape {
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
