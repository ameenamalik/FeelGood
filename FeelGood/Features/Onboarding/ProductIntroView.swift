//
//  ProductIntroView.swift
//  FeelGood
//
//  One welcome screen before onboarding: what FeelGood asks and why.
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
    enum Route { case onboarding, today, restoreProfile }

    static func route(requiresOnboarding: Bool, hasProfile: Bool) -> Route {
        if requiresOnboarding { return .onboarding }
        return hasProfile ? .today : .restoreProfile
    }

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
        FirstRunFlow.resetWelcomeFlow(defaults: defaults)
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
    @State private var isShowingPostOnboardingPaywall = false

    /// Reset the welcome screens for a fresh installation or a debug restart.
    /// Signing out preserves these flags so onboarding is not repeated.
    static func resetWelcomeFlow(defaults: UserDefaults = .standard) {
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
                SettingUpMenuView(answers: settingUp.answers, onEdit: {
                    Analytics.capture("onboarding_summary_edited", properties: ["flow_version": 2])
                    settingUpModel = nil
                }) {
                    if PurchasesManager.shared.isProUnlocked {
                        settingUpModel = nil
                        onFinish(settingUp)
                    } else {
                        isShowingPostOnboardingPaywall = true
                    }
                }
                .fullScreenCover(isPresented: $isShowingPostOnboardingPaywall, onDismiss: {
                    settingUpModel = nil
                    onFinish(settingUp)
                }) {
                    FeelGoodPaywallView(context: .onboarding)
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
    let onFinish: () -> Void

    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        ZStack {
            FGColor.bg.ignoresSafeArea()

            GeometryReader { geometry in
                ScrollView {
                    WelcomeScreenLayout(availableHeight: geometry.size.height) {
                        VStack(spacing: FGSpace.m) {
                            welcomeArtwork

                            VStack(spacing: FGSpace.s) {
                                Text("FeelGood")
                                    .font(FGFont.display)
                                    .foregroundStyle(FGColor.ink)
                                    .accessibilityAddTraits(.isHeader)

                                Text("A menu for the day you’re having.")
                                    .font(FGFont.body)
                                    .foregroundStyle(FGColor.inkMuted)
                            }
                            .fixedSize(horizontal: false, vertical: true)
                        }
                        .multilineTextAlignment(.center)

                        VStack(spacing: FGSpace.m) {
                            Text("Before we start, tell us a little about yourself.\nWe’ll suggest movement that fits you.")
                                .font(FGFont.reason)
                                .foregroundStyle(FGColor.inkMuted)
                                .multilineTextAlignment(.center)
                                .lineSpacing(3)
                                .fixedSize(horizontal: false, vertical: true)
                                .padding(.bottom, FGSpace.s)

                            FGPrimaryButton(title: "Let’s begin", action: onFinish)

                            Text("\(OnboardingModel.Card.allCases.count) quick steps · Change answers anytime")
                                .font(FGFont.caption)
                                .foregroundStyle(FGColor.inkMuted)
                                .multilineTextAlignment(.center)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .frame(maxWidth: 360)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, FGSpace.page)
                }
                .scrollBounceBehavior(.basedOnSize)
            }
            .fgReadableWidth()
        }
        .onAppear {
            Analytics.capture("product_intro_page_viewed", properties: [
                "page": 1,
                "page_count": 1,
                "flow_version": 2,
            ])
        }
    }

    /// One compact composition: the logo leads, with familiar characters around it.
    /// Scale the entire group together so the artwork never overlaps the copy.
    private var welcomeArtwork: some View {
        GeometryReader { geometry in
            let scale = min(1, geometry.size.width / 300, geometry.size.height / 220)

            ZStack {
                appIconMark
                    .modifier(WelcomeFloat(rise: 4, tilt: 0.8, duration: 3.2))

                mascot("IntentEnergyClementine", size: 60)
                    .modifier(WelcomeFloat(rise: 5, tilt: -2, duration: 2.6))
                    .offset(y: -84)
                mascot("IntentStrengthPlum", size: 66)
                    .modifier(WelcomeFloat(rise: -6, tilt: 2, duration: 3.0))
                    .offset(x: -108, y: -42)
                mascot("IntentCalmBlueberryMascot", size: 66)
                    .modifier(WelcomeFloat(rise: 5, tilt: 1.5, duration: 3.5))
                    .offset(x: 108, y: -42)
                mascot("IntentShowingUpBanana", size: 80)
                    .modifier(WelcomeFloat(rise: 6, tilt: -2, duration: 3.3))
                    .offset(x: -86, y: 65)
                mascot("IntentMobilityPear", size: 78)
                    .modifier(WelcomeFloat(rise: -5, tilt: 2, duration: 2.8))
                    .offset(x: 86, y: 65)
            }
            .frame(width: 300, height: 220)
            .scaleEffect(scale)
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .frame(height: typeSize.isAccessibilitySize ? 160 : 220)
        .accessibilityHidden(true)
    }

    private func mascot(_ name: String, size: CGFloat) -> some View {
        Image(name)
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
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

}

/// Keep the brand slightly above center and the setup copy attached to the button.
/// On short screens or at larger text sizes, keep minimum gaps and allow scrolling.
private struct WelcomeScreenLayout: Layout {
    let availableHeight: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 360
        let itemProposal = ProposedViewSize(width: width, height: nil)
        let brand = subviews[0].sizeThatFits(itemProposal)
        let actions = subviews[1].sizeThatFits(itemProposal)
        let minimumHeight = brand.height + actions.height + FGSpace.xl + FGSpace.l * 2
        return CGSize(width: width, height: max(availableHeight, minimumHeight))
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let itemProposal = ProposedViewSize(width: bounds.width, height: nil)
        let brand = subviews[0].sizeThatFits(itemProposal)
        let actions = subviews[1].sizeThatFits(itemProposal)
        let actionsTop = bounds.maxY - FGSpace.l - actions.height
        let brandCenter = max(
            bounds.minY + FGSpace.l + brand.height / 2,
            min(bounds.minY + bounds.height * 0.44, actionsTop - FGSpace.xl - brand.height / 2)
        )

        subviews[0].place(
            at: CGPoint(x: bounds.midX, y: brandCenter),
            anchor: .center,
            proposal: ProposedViewSize(width: bounds.width, height: brand.height)
        )
        subviews[1].place(
            at: CGPoint(x: bounds.midX, y: bounds.maxY - FGSpace.l),
            anchor: .bottom,
            proposal: ProposedViewSize(width: bounds.width, height: actions.height)
        )
    }
}

/// A slow bob and slight sway, confined to decorative welcome artwork.
/// PhaseAnimator owns the loop and cancels it when the view leaves the screen.
private struct WelcomeFloat: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase

    let rise: CGFloat
    let tilt: Double
    let duration: Double

    func body(content: Content) -> some View {
        if reduceMotion || scenePhase != .active {
            content
        } else {
            content.phaseAnimator([-1.0, 1.0]) { view, phase in
                view
                    .offset(y: rise * phase)
                    .rotationEffect(.degrees(tilt * phase))
            } animation: { _ in
                .easeInOut(duration: duration)
            }
        }
    }
}

#Preview("Product intro") {
    ProductIntroView {}
}
