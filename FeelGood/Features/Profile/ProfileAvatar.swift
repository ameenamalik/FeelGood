//
//  ProfileAvatar.swift
//  FeelGood
//
//  A small, closed set of private-by-design profile pictures. Stable raw
//  values are persisted instead of asset names so artwork can be renamed or
//  replaced without changing somebody's selection.
//

import SwiftUI

nonisolated enum ProfileAvatar: String, CaseIterable, Identifiable, Sendable {
    case apple
    case plum
    case banana
    case pear
    case blueberry
    case peach
    case clementine
    case lime

    static let defaultAvatar: ProfileAvatar = .apple

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .apple: "Apple"
        case .plum: "Plum"
        case .banana: "Banana"
        case .pear: "Pear"
        case .blueberry: "Blueberry"
        case .peach: "Peach"
        case .clementine: "Clementine"
        case .lime: "Lime"
        }
    }

    var assetName: String {
        switch self {
        case .apple: "IntentStrengthApple"
        case .plum: "IntentStrengthPlum"
        case .banana: "IntentShowingUpBanana"
        case .pear: "IntentMobilityPear"
        case .blueberry: "IntentCalmBlueberryMascot"
        case .peach: "IntentCalmPeach"
        case .clementine: "IntentEnergyClementine"
        case .lime: "IntentPlayLime"
        }
    }

    var aura: FGAura {
        switch self {
        case .apple, .clementine: .apricot
        case .plum, .blueberry: .lilac
        case .banana, .lime: .butter
        case .pear: .sage
        case .peach: .blush
        }
    }
}

/// The color behind a profile mascot. `automatic` preserves each fruit's
/// art-directed default while the named choices let somebody personalize it.
nonisolated enum ProfileAvatarBackground: String, CaseIterable, Identifiable, Sendable {
    case automatic
    case blush
    case apricot
    case butter
    case sage
    case lilac

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .automatic: "Automatic"
        case .blush: "Blush"
        case .apricot: "Apricot"
        case .butter: "Butter"
        case .sage: "Sage"
        case .lilac: "Lilac"
        }
    }

    func aura(for avatar: ProfileAvatar) -> FGAura {
        switch self {
        case .automatic: avatar.aura
        case .blush: .blush
        case .apricot: .apricot
        case .butter: .butter
        case .sage: .sage
        case .lilac: .lilac
        }
    }
}

struct ProfileAvatarView: View {
    let avatar: ProfileAvatar
    var background: ProfileAvatarBackground = .automatic
    var size: CGFloat = 44

    var body: some View {
        Image(avatar.assetName)
            .resizable()
            .scaledToFit()
            .padding(size * 0.08)
            .frame(width: size, height: size)
            .background(background.aura(for: avatar).core, in: Circle())
            .accessibilityHidden(true)
    }
}

struct ProfileAvatarPickerView: View {
    @Binding var selection: ProfileAvatar
    @Binding var background: ProfileAvatarBackground
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var hoppingAvatar: ProfileAvatar?
    @State private var hopID: UUID?

    private let columns = [
        GridItem(.adaptive(minimum: 92), spacing: FGSpace.s)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: FGSpace.l) {
                    VStack(alignment: .leading, spacing: FGSpace.xs) {
                        Text("Choose your FeelGood friend")
                            .font(FGFont.title)
                            .foregroundStyle(FGColor.ink)

                        Text("Pick a fruit mascot, then make its background your own.")
                            .font(FGFont.body)
                            .foregroundStyle(FGColor.inkMuted)
                    }

                    LazyVGrid(columns: columns, spacing: FGSpace.m) {
                        ForEach(ProfileAvatar.allCases) { avatar in
                            let isSelected = selection == avatar

                            Button {
                                selectAvatar(avatar)
                            } label: {
                                VStack(spacing: FGSpace.xs) {
                                    ProfileAvatarView(
                                        avatar: avatar,
                                        background: background,
                                        size: 76
                                    )
                                    .scaleEffect(hoppingAvatar == avatar ? 1.04 : 1)
                                    .rotationEffect(.degrees(hoppingAvatar == avatar ? -3 : 0))
                                    .offset(y: hoppingAvatar == avatar ? -6 : 0)

                                    Text(avatar.displayName)
                                        .font(FGFont.caption.weight(.semibold))
                                        .foregroundStyle(FGColor.ink)
                                        .lineLimit(1)
                                }
                                .frame(maxWidth: .infinity, minHeight: 116)
                                .background(FGColor.surface)
                                .clipShape(RoundedRectangle(cornerRadius: FGRadius.card, style: .continuous))
                                .overlay {
                                    RoundedRectangle(cornerRadius: FGRadius.card, style: .continuous)
                                        .strokeBorder(
                                            isSelected ? FGColor.ink : FGColor.lineStrong,
                                            lineWidth: isSelected ? 2 : 1
                                        )
                                }
                                .overlay(alignment: .topTrailing) {
                                    selectionCheckmark
                                        .scaleEffect(isSelected ? 1 : 0.35)
                                        .opacity(isSelected ? 1 : 0)
                                        .padding(FGSpace.xs)
                                        .animation(
                                            reduceMotion
                                                ? .none
                                                : .spring(response: 0.34, dampingFraction: 0.56),
                                            value: isSelected
                                        )
                                }
                            }
                            .buttonStyle(.feelGoodPress)
                            .scaleEffect(isSelected ? 1.025 : 1)
                            .offset(y: isSelected ? -3 : 0)
                            .zIndex(isSelected ? 1 : 0)
                            .fgAnimation(FGMotion.settle, value: isSelected)
                            .fgAnimation(FGMotion.settle, value: hoppingAvatar)
                            .accessibilityLabel(avatar.displayName)
                            .accessibilityAddTraits(isSelected ? .isSelected : [])
                        }
                    }

                    backgroundPicker
                }
                .padding(FGSpace.page)
            }
            .background(FGColor.bg)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .sensoryFeedback(.selection, trigger: selection)
        .sensoryFeedback(.selection, trigger: background)
    }

    private var backgroundPicker: some View {
        VStack(alignment: .leading, spacing: FGSpace.s) {
            Text("Background color")
                .font(FGFont.sectionTitle)
                .foregroundStyle(FGColor.ink)

            LazyVGrid(columns: columns, spacing: FGSpace.s) {
                ForEach(ProfileAvatarBackground.allCases) { choice in
                    let isSelected = background == choice

                    Button {
                        selectBackground(choice)
                    } label: {
                        VStack(spacing: FGSpace.xs) {
                            Circle()
                                .fill(choice.aura(for: selection).core)
                                .frame(width: 46, height: 46)
                                .overlay {
                                    Circle()
                                        .strokeBorder(
                                            isSelected ? FGColor.ink : FGColor.lineStrong,
                                            lineWidth: isSelected ? 3 : 1
                                        )
                                }
                                .overlay {
                                    Image(systemName: "checkmark")
                                        .font(.caption.weight(.bold))
                                        .foregroundStyle(FGColor.inkOnAccent)
                                        .scaleEffect(isSelected ? 1 : 0.25)
                                        .opacity(isSelected ? 1 : 0)
                                        .animation(
                                            reduceMotion
                                                ? .none
                                                : .spring(response: 0.34, dampingFraction: 0.56),
                                            value: isSelected
                                        )
                                }
                                .fgAnimation(FGMotion.gentle, value: background)
                                .fgAnimation(FGMotion.gentle, value: selection)

                            Text(choice.displayName)
                                .font(FGFont.caption.weight(.semibold))
                                .foregroundStyle(FGColor.ink)
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity, minHeight: 82)
                    }
                    .buttonStyle(.feelGoodPress)
                    .scaleEffect(isSelected ? 1.04 : 1)
                    .offset(y: isSelected ? -2 : 0)
                    .zIndex(isSelected ? 1 : 0)
                    .fgAnimation(FGMotion.settle, value: isSelected)
                    .accessibilityLabel("\(choice.displayName) background")
                    .accessibilityAddTraits(isSelected ? .isSelected : [])
                }
            }
        }
    }

    private var selectionCheckmark: some View {
        Image(systemName: "checkmark")
            .font(.caption2.weight(.bold))
            .foregroundStyle(FGColor.bg)
            .frame(width: 24, height: 24)
            .background(FGColor.ink, in: Circle())
    }

    private func selectAvatar(_ avatar: ProfileAvatar) {
        guard selection != avatar else { return }

        withAnimation(reduceMotion ? nil : FGMotion.settle) {
            selection = avatar
        }

        guard !reduceMotion else { return }
        let id = UUID()
        hopID = id

        withAnimation(.spring(response: 0.22, dampingFraction: 0.62)) {
            hoppingAvatar = avatar
        }

        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(150))
            guard hopID == id else { return }
            withAnimation(.spring(response: 0.3, dampingFraction: 0.72)) {
                hoppingAvatar = nil
            }
        }
    }

    private func selectBackground(_ choice: ProfileAvatarBackground) {
        guard background != choice else { return }
        withAnimation(reduceMotion ? nil : FGMotion.gentle) {
            background = choice
        }
    }
}
