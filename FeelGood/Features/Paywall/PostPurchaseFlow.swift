//
//  PostPurchaseFlow.swift
//  FeelGood
//
//  What happens in the first minute after someone subscribes: confirm it,
//  promise a heads-up before any charge (trials only, and only while
//  notifications are still undecided), then hand them one small move.
//

import RevenueCat
import SwiftUI

struct PostPurchaseFlow: View {
    /// Called once, with the session to open when the person tapped "Start now".
    var onFinish: (String?) -> Void

    private enum Step {
        case welcome, reminder, firstMove
    }

    @State private var step = Step.welcome
    @State private var candidates: [Session] = []
    @State private var candidateIndex = 0
    @State private var isAskingForReminder = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var purchases: PurchasesManager { PurchasesManager.shared }
    private var firstMove: Session? {
        candidates.isEmpty ? nil : candidates[candidateIndex % candidates.count]
    }

    var body: some View {
        ZStack {
            FGColor.bg.ignoresSafeArea()
            FGBrandWash(reach: 0.6).ignoresSafeArea()

            switch step {
            case .welcome: welcome.transition(.opacity)
            case .reminder: reminder.transition(.opacity)
            case .firstMove: firstMoveScreen.transition(.opacity)
            }
        }
        .task {
            if let store = try? ContentStore.bundled() {
                candidates = FirstMove.candidates(from: store.sessions)
            }
            Analytics.capture("post_purchase_shown")
        }
    }

    private func go(to next: Step) {
        Analytics.capture("post_purchase_step", properties: ["step": "\(next)"])
        if reduceMotion {
            step = next
        } else {
            withAnimation(FGMotion.swap) { step = next }
        }
    }

    // MARK: - Welcome

    private var welcome: some View {
        screen(
            footer: "Manage or cancel any time in Settings.",
            primary: "Let's go",
            primaryAction: advanceFromWelcome
        ) {
            VStack(alignment: .leading, spacing: FGSpace.l) {
                HStack(alignment: .top, spacing: FGSpace.m) {
                    VStack(alignment: .leading, spacing: FGSpace.s) {
                        Text("You're in.\nLet's move.")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .tracking(-0.8)
                            .foregroundStyle(FGColor.ink)
                        Text("FeelGood Pro is on.")
                            .font(FGFont.reason)
                            .foregroundStyle(FGColor.inkMuted)
                    }
                    Spacer(minLength: 0)
                    Image(Course.appetizer.menuMascotAsset)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 120, height: 120)
                        .accessibilityHidden(true)
                }

                Text("What's on your menu now")
                    .font(FGFont.sectionTitle)
                    .foregroundStyle(FGColor.ink)

                VStack(spacing: FGSpace.s + 4) {
                    perkCard(tag: "Swaps", title: "Swap any session, any time", course: .appetizer, mascot: Course.main.menuMascotAsset)
                    perkCard(tag: "Chat", title: "Talk to your companion", course: .main, mascot: "IntentCalmBlueberryMascot")
                    perkCard(tag: "Calendar", title: "A menu around your day", course: .side, mascot: Course.side.menuMascotAsset)
                }
            }
        }
    }

    private func advanceFromWelcome() {
        Task {
            if await shouldAskForReminder() {
                go(to: .reminder)
            } else if firstMove != nil {
                go(to: .firstMove)
            } else {
                onFinish(nil)
            }
        }
    }

    // MARK: - Reminder

    /// Only on a trial that will convert, with a reminder moment still ahead,
    /// and only when iOS has never been asked. If notifications are already
    /// allowed the reminder is scheduled without a screen; if they were
    /// refused, asking again would only open Settings.
    private func shouldAskForReminder() async -> Bool {
        guard let status = purchases.proStatus,
              TrialReminderPlan.shouldRemind(status),
              let end = status.expirationDate,
              TrialReminderPlan.fireDate(trialEnd: end) != nil
        else { return false }
        return await TrialReminderScheduler.shared.authorizationIsUndecided()
    }

    private var trialDays: Int {
        max(2, purchases.proStatus?.daysRemaining() ?? 7)
    }

    /// "$34.99 a year" for the plan they bought, or nil if it cannot be told.
    private var purchasedPrice: String? {
        PurchasedPlan.priceLine(
            productID: purchases.customerInfo?.entitlements[RevenueCatConstants.proEntitlementID]?.productIdentifier,
            packages: [purchases.yearlyPackage, purchases.monthlyPackage].compactMap { $0 }
        )
    }

    private var reminder: some View {
        screen(
            footer: "Allow notifications so the reminder reaches you.",
            primary: "Remind me",
            primaryEnabled: !isAskingForReminder,
            primaryAction: allowReminder,
            secondary: "Not now",
            secondaryAction: skipReminder
        ) {
            VStack(alignment: .leading, spacing: FGSpace.l) {
                HStack(alignment: .top, spacing: FGSpace.m) {
                    VStack(alignment: .leading, spacing: FGSpace.s) {
                        Text("We'll tell you before anything is charged.")
                            .font(.system(size: 30, weight: .bold, design: .rounded))
                            .tracking(-0.6)
                            .foregroundStyle(FGColor.ink)
                        Text("Your free trial is yours. A heads-up arrives the day before it ends.")
                            .font(FGFont.reason)
                            .foregroundStyle(FGColor.inkMuted)
                    }
                    Spacer(minLength: 0)
                    Image(Course.dessert.menuMascotAsset)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 96, height: 96)
                        .accessibilityHidden(true)
                }

                VStack(spacing: FGSpace.s + 4) {
                    perkCard(tag: "Today", title: "Pro is on. Nothing is charged.", course: .side, mascot: Course.side.menuMascotAsset)
                    perkCard(tag: "Day \(trialDays - 1)", title: "We send you a reminder.", course: .main, mascot: Course.special.menuMascotAsset)
                    perkCard(
                        tag: "Day \(trialDays)",
                        title: purchasedPrice.map { "\($0), unless you cancel." } ?? "It renews, unless you cancel.",
                        course: .dessert,
                        mascot: Course.main.menuMascotAsset
                    )
                }
            }
        }
    }

    private func allowReminder() {
        guard !isAskingForReminder else { return }
        isAskingForReminder = true
        Analytics.capture("trial_reminder_asked")
        OneSignalManager.shared.setPushEnabled(true) { granted in
            Task { @MainActor in
                isAskingForReminder = false
                Analytics.capture("trial_reminder_answered", properties: ["granted": granted])
                if granted {
                    await TrialReminderScheduler.shared.sync(status: purchases.proStatus, price: purchasedPrice)
                }
                advanceFromReminder()
            }
        }
    }

    private func skipReminder() {
        Analytics.capture("trial_reminder_skipped")
        advanceFromReminder()
    }

    private func advanceFromReminder() {
        if firstMove != nil {
            go(to: .firstMove)
        } else {
            onFinish(nil)
        }
    }

    // MARK: - First move

    private var firstMoveScreen: some View {
        let session = firstMove
        return screen(
            footer: nil,
            primary: "Start now",
            primaryAction: {
                Analytics.capture("first_move_started", properties: ["session_id": session?.id ?? ""])
                onFinish(session?.id)
            },
            secondary: candidates.count > 1 ? "Show me something else" : "Not today",
            secondaryAction: {
                if candidates.count > 1 {
                    Analytics.capture("first_move_swapped")
                    candidateIndex += 1
                } else {
                    onFinish(nil)
                }
            }
        ) {
            VStack(alignment: .leading, spacing: FGSpace.l) {
                VStack(alignment: .leading, spacing: FGSpace.s) {
                    Text("YOUR FIRST MOVE")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .tracking(1)
                        .foregroundStyle(FGColor.sageDeep)
                    Text("Start with something small.")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .tracking(-0.8)
                        .foregroundStyle(FGColor.ink)
                    Text(FirstMove.subtitle(hour: Calendar.current.component(.hour, from: .now)))
                        .font(FGFont.reason)
                        .foregroundStyle(FGColor.inkMuted)
                }

                Image("LittleWinFirstMoveStrawberry")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                    .frame(height: 220)
                    .accessibilityHidden(true)

                if let session {
                    VStack(alignment: .leading, spacing: FGSpace.xs + 2) {
                        tag("Appetizer · \(session.durationMin) min")
                        Text(session.title)
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundStyle(FGColor.ink)
                        if !session.subtitle.isEmpty {
                            Text(session.subtitle)
                                .font(FGFont.reason)
                                .foregroundStyle(FGColor.ink)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(FGSpace.m)
                    .background(
                        RoundedRectangle(cornerRadius: FGRadius.card, style: .continuous)
                            .fill(session.course.fill)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: FGRadius.card, style: .continuous)
                            .strokeBorder(session.course.edge, lineWidth: 1)
                    )
                    .id(session.id)
                    .transition(.opacity)
                }
            }
        }
    }

    // MARK: - Pieces

    /// The shared page shape: scrolling content, with the actions fixed at
    /// the bottom so a large type size never pushes the button off screen.
    private func screen<Content: View>(
        footer: String?,
        primary: String,
        primaryEnabled: Bool = true,
        primaryAction: @escaping () -> Void,
        secondary: String? = nil,
        secondaryAction: (() -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) -> some View {
        ScrollView {
            content()
                .padding(.horizontal, FGSpace.page)
                .padding(.top, FGSpace.xl)
                .padding(.bottom, FGSpace.l)
                .fgReadableWidth()
        }
        .scrollBounceBehavior(.basedOnSize)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            VStack(spacing: FGSpace.s) {
                if let footer {
                    Text(footer)
                        .font(FGFont.caption)
                        .foregroundStyle(FGColor.inkMuted)
                        .multilineTextAlignment(.center)
                }
                FGPrimaryButton(title: primary, isEnabled: primaryEnabled, action: primaryAction)
                if let secondary, let secondaryAction {
                    Button(action: secondaryAction) {
                        Text(secondary)
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundStyle(FGColor.inkMuted)
                            .frame(maxWidth: .infinity, minHeight: FGSize.minTouchTarget)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, FGSpace.page)
            .padding(.top, FGSpace.s)
            .padding(.bottom, FGSpace.s)
            .background(FGColor.bg.opacity(0.94))
        }
    }

    private func tag(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.system(size: 11, weight: .bold, design: .rounded))
            .tracking(0.6)
            .foregroundStyle(FGColor.ink)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(Capsule().fill(FGColor.surface))
    }

    private func perkCard(tag label: String, title: String, course: Course, mascot: String) -> some View {
        HStack(spacing: FGSpace.m) {
            VStack(alignment: .leading, spacing: FGSpace.s) {
                tag(label)
                Text(title)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(FGColor.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
            Image(mascot)
                .resizable()
                .scaledToFit()
                .frame(width: 44, height: 44)
                .padding(8)
                .background(Circle().fill(FGColor.surface))
                .accessibilityHidden(true)
        }
        .padding(FGSpace.m)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: FGRadius.card, style: .continuous)
                .fill(course.fill)
        )
        .overlay(
            RoundedRectangle(cornerRadius: FGRadius.card, style: .continuous)
                .strokeBorder(course.edge, lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
    }
}

/// Which plan someone bought, as the line the reminder screen quotes.
enum PurchasedPlan {
    static func priceLine(productID: String?, packages: [Package]) -> String? {
        guard let productID,
              let package = packages.first(where: { $0.storeProduct.productIdentifier == productID })
        else { return nil }
        let unit: String
        switch package.packageType {
        case .annual: unit = "a year"
        case .monthly: unit = "a month"
        default: return package.storeProduct.localizedPriceString
        }
        return "\(package.storeProduct.localizedPriceString) \(unit)"
    }
}
