//
//  DebugMenu.swift
//  FeelGood
//
//  Reachable by long-pressing the date above the menu. Debug builds only, so
//  there is nothing to hide in release and nothing a reviewer can stumble into.
//

#if DEBUG

import RevenueCat
import SwiftUI
import SwiftData

struct DebugMenu: View {
    let content: any ContentProviding
    /// Called after seeding so Today can rebuild against the new history.
    let onSeed: () -> Void

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Environment(PurchasesManager.self) private var purchasesManager
    @State private var lastApplied: DebugScenario?
    @State private var purchasingPackageID: String?

    private var seeder: DebugSeeder {
        DebugSeeder(context: context, content: content)
    }

    var body: some View {
        ZStack {
            FGColor.bg.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: FGSpace.l) {
                    VStack(alignment: .leading, spacing: FGSpace.xs) {
                        Text("Time travel")
                            .font(FGFont.title)
                            .foregroundStyle(FGColor.ink)
                        Text("Writes real history through the real store. The engine then reacts to it exactly as it would for a real person.")
                            .font(FGFont.reason)
                            .foregroundStyle(FGColor.inkMuted)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    FGCard {
                        VStack(alignment: .leading, spacing: FGSpace.xs) {
                            Text("Right now")
                                .font(FGFont.label)
                                .foregroundStyle(FGColor.goldDeep)
                            Text(seeder.summary())
                                .font(FGFont.body)
                                .foregroundStyle(FGColor.ink)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }

                    VStack(spacing: FGSpace.s) {
                        ForEach(DebugScenario.allCases) { scenario in
                            Button {
                                seeder.apply(scenario)
                                lastApplied = scenario
                                onSeed()
                            } label: {
                                FGCard(isHighlighted: lastApplied == scenario) {
                                    VStack(alignment: .leading, spacing: FGSpace.xs) {
                                        Text(scenario.title)
                                            .font(FGFont.itemTitle)
                                            .foregroundStyle(FGColor.ink)
                                        Text(scenario.detail)
                                            .font(FGFont.caption)
                                            .foregroundStyle(FGColor.inkMuted)
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    VStack(alignment: .leading, spacing: FGSpace.xs) {
                        Text("Entitlement")
                            .font(FGFont.title)
                            .foregroundStyle(FGColor.ink)
                        Text("Forces every Pro-gated flow — the copy upgrade, the paywall gate — on, without a sandbox purchase.")
                            .font(FGFont.reason)
                            .foregroundStyle(FGColor.inkMuted)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    FGCard {
                        Toggle(
                            "Force Pro unlocked",
                            isOn: Binding(
                                get: { purchasesManager.debugForceProUnlocked },
                                set: { purchasesManager.debugForceProUnlocked = $0 }
                            )
                        )
                            .font(FGFont.body)
                            .foregroundStyle(FGColor.ink)
                    }

                    VStack(alignment: .leading, spacing: FGSpace.xs) {
                        Text("Plans")
                            .font(FGFont.title)
                            .foregroundStyle(FGColor.ink)
                        Text("Real purchases against the RevenueCat Test Store — no sandbox account needed. Requires monthly/yearly packages configured on the current offering.")
                            .font(FGFont.reason)
                            .foregroundStyle(FGColor.inkMuted)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    VStack(spacing: FGSpace.s) {
                        if purchasesManager.isLoadingOfferings {
                            ProgressView()
                        } else {
                            planRow(title: "Monthly", package: purchasesManager.monthlyPackage)
                            planRow(title: "Yearly", package: purchasesManager.yearlyPackage)
                        }
                    }

                    VStack(alignment: .leading, spacing: FGSpace.xs) {
                        Text("Exercise Demos")
                            .font(FGFont.title)
                            .foregroundStyle(FGColor.ink)
                        Text("Newly animated exercise demo flipbooks.")
                            .font(FGFont.reason)
                            .foregroundStyle(FGColor.inkMuted)
                    }

                    VStack(spacing: FGSpace.m) {
                        let demos: [(String, String)] = [
                            ("Downward Dog", "downward-dog"),
                            ("Qigong: Lifting the Sky", "qigong-lifting-the-sky"),
                            ("Wall Angels", "wall-angels"),
                            ("Full Body Shakeout", "full-body-shake"),
                            ("Mindful Breathing", "deep-breath")
                        ]
                        ForEach(demos, id: \.1) { name, id in
                            FGCard {
                                VStack(alignment: .leading, spacing: FGSpace.s) {
                                    Text(name)
                                        .font(FGFont.body.weight(.semibold))
                                        .foregroundStyle(FGColor.ink)
                                    HStack {
                                        Spacer()
                                        ExerciseDemoView(glossaryID: id)
                                            .frame(width: 140, height: 140)
                                        Spacer()
                                    }
                                }
                            }
                        }
                    }

                    FGPrimaryButton(title: "Back to today") { dismiss() }
                }
                .padding(FGSpace.page)
            }
        }
        .task {
            if purchasesManager.offerings == nil {
                await purchasesManager.fetchOfferings()
            }
        }
        .presentationDragIndicator(.visible)
    }

    /// `package` is `nil` when this plan isn't configured on the current
    /// offering yet — shown disabled rather than hidden, so it's obvious
    /// from the debug menu itself which of the three PRD §10 tiers still
    /// need a RevenueCat dashboard entry.
    @ViewBuilder
    private func planRow(title: String, package: Package?) -> some View {
        Button {
            guard let package else { return }
            Task {
                purchasingPackageID = package.identifier
                _ = await purchasesManager.purchase(package: package)
                purchasingPackageID = nil
            }
        } label: {
            FGCard {
                HStack {
                    Text(title)
                        .font(FGFont.body)
                        .foregroundStyle(FGColor.ink)
                    Spacer()
                    if purchasingPackageID == package?.identifier {
                        ProgressView()
                    } else if let package {
                        Text(package.localizedPriceString)
                            .font(FGFont.caption)
                            .foregroundStyle(FGColor.inkMuted)
                    } else {
                        Text("Not configured")
                            .font(FGFont.caption)
                            .foregroundStyle(FGColor.inkMuted)
                    }
                }
            }
        }
        .buttonStyle(.plain)
        .disabled(package == nil || purchasingPackageID != nil)
    }
}

#endif
