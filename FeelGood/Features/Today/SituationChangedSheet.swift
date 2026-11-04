//
//  SituationChangedSheet.swift
//  FeelGood
//
//  One short page for "my situation changed": what changed, the detail if it
//  needs one, and whether it is for now or for good. The menu follows the
//  moment it is saved.
//

import SwiftUI

struct SituationChangedSheet: View {
    /// Called with the change and whether it is temporary.
    let onSave: (SituationChange, Bool) -> Void

    private enum Kind: CaseIterable, Identifiable {
        case pain, lessCapacity, newGoal
        var id: Self { self }

        var title: String {
            switch self {
            case .pain: "Something hurts"
            case .lessCapacity: "Less time or energy"
            case .newGoal: "I want something different"
            }
        }

        var detail: String {
            switch self {
            case .pain: "We'll go easy on it."
            case .lessCapacity: "Shorter, gentler sessions."
            case .newGoal: "Change what you're moving toward."
            }
        }

        var symbol: String {
            switch self {
            case .pain: "bandage"
            case .lessCapacity: "battery.25percent"
            case .newGoal: "scope"
            }
        }
    }

    @State private var kind: Kind?
    @State private var areas: Set<WorkAround> = []
    @State private var goals: Set<Intent> = []
    @State private var isTemporary = true
    @Environment(\.dismiss) private var dismiss

    private var change: SituationChange? {
        guard let kind else { return nil }
        switch kind {
        case .pain: return .pain(areas)
        case .lessCapacity: return .lessCapacity
        case .newGoal: return .newGoal(goals)
        }
    }

    private var canSave: Bool { change?.isValid ?? false }

    var body: some View {
        ZStack {
            FGColor.bg.ignoresSafeArea()
            FGBrandWash(reach: 0.28).ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: FGSpace.l) {
                    VStack(alignment: .leading, spacing: FGSpace.s) {
                        Text("What changed?")
                            .font(.system(.largeTitle, design: .rounded).weight(.semibold))
                            .foregroundStyle(FGColor.ink)
                        Text("Today's menu follows right away.")
                            .font(FGFont.reason)
                            .foregroundStyle(FGColor.inkMuted)
                    }

                    VStack(spacing: FGSpace.s) {
                        ForEach(Kind.allCases) { option in
                            kindRow(option)
                        }
                    }

                    if kind == .pain {
                        detail("Where?") {
                            pills(SituationChange.painAreas, label: \.label, selection: $areas)
                        }
                    }

                    if kind == .newGoal {
                        detail("What are you moving toward?") {
                            pills(Array(Intent.allCases), label: \.label, selection: $goals)
                        }
                    }

                    if kind != nil {
                        detail("How long?") {
                            WrapRow(spacing: FGSpace.s, lineSpacing: FGSpace.s) {
                                FGPill(
                                    title: "For now · \(SituationChange.temporaryDays / 7) weeks",
                                    selectedAura: .sage,
                                    isSelected: isTemporary
                                ) { isTemporary = true }
                                FGPill(
                                    title: "Keep it",
                                    selectedAura: .apricot,
                                    isSelected: !isTemporary
                                ) { isTemporary = false }
                            }
                            if isTemporary {
                                Text("We'll ask before going back to how things were.")
                                    .font(FGFont.caption)
                                    .foregroundStyle(FGColor.inkMuted)
                            }
                        }
                    }
                }
                .padding(FGSpace.page)
                .padding(.bottom, FGSpace.xxl)
                .fgReadableWidth()
            }
            .scrollBounceBehavior(.basedOnSize)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            VStack(spacing: FGSpace.s) {
                FGPrimaryButton(title: "Update my menu", isEnabled: canSave) {
                    guard let change else { return }
                    onSave(change, isTemporary)
                    dismiss()
                }
                FGQuietButton("Never mind") { dismiss() }
            }
            .padding(.horizontal, FGSpace.page)
            .padding(.vertical, FGSpace.s)
            .background(FGColor.bg.opacity(0.94))
        }
        .presentationDetents([.large])
    }

    private func kindRow(_ option: Kind) -> some View {
        let isSelected = kind == option
        return Button {
            withAnimation(FGMotion.gentle) { kind = option }
        } label: {
            HStack(spacing: FGSpace.m) {
                Image(systemName: option.symbol)
                    .font(.system(size: 20, weight: .semibold))
                    .frame(width: 32)
                    .foregroundStyle(FGColor.ink)
                VStack(alignment: .leading, spacing: 2) {
                    Text(option.title)
                        .font(FGFont.itemTitle)
                        .foregroundStyle(FGColor.ink)
                    Text(option.detail)
                        .font(FGFont.caption)
                        .foregroundStyle(FGColor.inkMuted)
                }
                Spacer(minLength: 0)
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? FGColor.ink : FGColor.lineStrong)
            }
            .padding(FGSpace.m)
            .frame(maxWidth: .infinity, minHeight: FGSize.minTouchTarget + 14)
            .background(
                RoundedRectangle(cornerRadius: FGRadius.card, style: .continuous)
                    .fill(isSelected ? Course.side.fill : FGColor.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: FGRadius.card, style: .continuous)
                    .strokeBorder(isSelected ? Course.side.edge : FGColor.lineStrong, lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }

    private func detail<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: FGSpace.s) {
            Text(title)
                .font(FGFont.sectionTitle)
                .foregroundStyle(FGColor.ink)
            content()
        }
        .transition(.opacity)
    }

    private func pills<Item: Hashable>(
        _ items: [Item],
        label: KeyPath<Item, String>,
        selection: Binding<Set<Item>>
    ) -> some View {
        WrapRow(spacing: FGSpace.s, lineSpacing: FGSpace.s) {
            ForEach(Array(items.enumerated()), id: \.element) { index, item in
                let palette: [FGAura] = [.apricot, .lilac, .blush, .sage, .butter]
                FGPill(
                    title: item[keyPath: label],
                    selectedAura: palette[index % palette.count],
                    isSelected: selection.wrappedValue.contains(item)
                ) {
                    withAnimation(FGMotion.gentle) {
                        if selection.wrappedValue.contains(item) {
                            selection.wrappedValue.remove(item)
                        } else {
                            selection.wrappedValue.insert(item)
                        }
                    }
                }
            }
        }
    }
}

/// Shown on Today once a temporary change has run its course.
struct AdjustmentCheckInCard: View {
    let onRevert: () -> Void
    let onKeep: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: FGSpace.m) {
            VStack(alignment: .leading, spacing: FGSpace.xs) {
                Text("Your two weeks are up.")
                    .font(FGFont.itemTitle)
                    .foregroundStyle(FGColor.ink)
                Text("Go back to how things were, or keep today's setup?")
                    .font(FGFont.reason)
                    .foregroundStyle(FGColor.inkMuted)
            }
            HStack(spacing: FGSpace.s) {
                Button(action: onRevert) {
                    Text("Go back")
                        .font(FGFont.body.weight(.medium))
                        .foregroundStyle(FGColor.onActionFill)
                        .frame(maxWidth: .infinity, minHeight: FGSize.minTouchTarget)
                        .background(Capsule().fill(FGColor.actionFill))
                }
                Button(action: onKeep) {
                    Text("Keep it")
                        .font(FGFont.body.weight(.medium))
                        .foregroundStyle(FGColor.ink)
                        .frame(maxWidth: .infinity, minHeight: FGSize.minTouchTarget)
                        .background(Capsule().strokeBorder(FGColor.lineStrong, lineWidth: 1))
                }
            }
            .buttonStyle(.plain)
        }
        .padding(FGSpace.m)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: FGRadius.card, style: .continuous)
                .fill(FGColor.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: FGRadius.card, style: .continuous)
                .strokeBorder(FGColor.lineStrong, lineWidth: 1)
        )
    }
}
