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
    case sky

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .automatic: "Automatic"
        case .blush: "Blush"
        case .apricot: "Apricot"
        case .butter: "Butter"
        case .sage: "Sage"
        case .lilac: "Lilac"
        case .sky: "Sky"
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
        case .sky: .sky
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
    let littleWins: [LittleWinProgress]
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var hoppingAvatar: ProfileAvatar?
    @State private var hopID: UUID?
    @State private var lockedWin: LittleWin?

    private var unlockedWins: Set<LittleWin> {
        Set(littleWins.filter(\.isUnlocked).map(\.win))
    }

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

                        Text("Apple starts with you. Earn little-win badges to unlock more characters and colors.")
                            .font(FGFont.body)
                            .foregroundStyle(FGColor.inkMuted)
                    }

                    LazyVGrid(columns: columns, spacing: FGSpace.m) {
                        ForEach(ProfileAvatar.allCases) { avatar in
                            let isSelected = selection == avatar
                            let isUnlocked = isAvatarUnlocked(avatar)

                            Button {
                                if isUnlocked {
                                    selectAvatar(avatar)
                                } else {
                                    lockedWin = avatar.unlockingWin
                                }
                            } label: {
                                VStack(spacing: 5) {
                                    ProfileAvatarView(
                                        avatar: avatar,
                                        background: background,
                                        size: 68
                                    )
                                    .scaleEffect(hoppingAvatar == avatar ? 1.04 : 1)
                                    .rotationEffect(.degrees(hoppingAvatar == avatar ? -3 : 0))
                                    .offset(y: hoppingAvatar == avatar ? -6 : 0)
                                    .saturation(isUnlocked ? 1 : 0)
                                    .opacity(isUnlocked ? 1 : 0.55)
                                    .blur(radius: isUnlocked ? 0 : 8)

                                    Text(isUnlocked ? avatar.displayName : "Mystery friend")
                                        .font(FGFont.caption.weight(.semibold))
                                        .foregroundStyle(FGColor.ink)
                                        .lineLimit(1)

                                    Group {
                                        if !isUnlocked, let win = avatar.unlockingWin {
                                            HStack(spacing: 4) {
                                                Image(systemName: "lock.fill")
                                                Text(win.title)
                                            }
                                            .font(.caption2.weight(.semibold))
                                            .foregroundStyle(FGColor.inkMuted)
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.72)
                                        } else {
                                            Color.clear
                                                .accessibilityHidden(true)
                                        }
                                    }
                                    .frame(height: 14)
                                }
                                .padding(.horizontal, 6)
                                .padding(.vertical, 10)
                                .frame(maxWidth: .infinity, minHeight: 128)
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
                            .accessibilityLabel(isUnlocked ? avatar.displayName : "Locked mystery character")
                            .accessibilityHint(
                                isUnlocked
                                    ? "Selects this profile character"
                                    : "Unlocks with the \(avatar.unlockingWin?.title ?? "little win") badge"
                            )
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
        .alert(item: $lockedWin) { win in
            Alert(
                title: Text("Unlock with \(win.title)"),
                message: Text("\(win.detail) Then come back here to meet your new profile friend and color."),
                dismissButton: .default(Text("Got it"))
            )
        }
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
                    let isUnlocked = isBackgroundUnlocked(choice)

                    Button {
                        if isUnlocked {
                            selectBackground(choice)
                        } else {
                            lockedWin = choice.unlockingWin
                        }
                    } label: {
                        VStack(spacing: 5) {
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
                                .opacity(isUnlocked ? 1 : 0.5)
                                .blur(radius: isUnlocked ? 0 : 6)

                            Text(isUnlocked ? choice.displayName : "Mystery color")
                                .font(FGFont.caption.weight(.semibold))
                                .foregroundStyle(FGColor.ink)
                                .lineLimit(1)

                            Group {
                                if !isUnlocked, let win = choice.unlockingWin {
                                    HStack(spacing: 4) {
                                        Image(systemName: "lock.fill")
                                        Text(win.title)
                                    }
                                    .font(.caption2.weight(.semibold))
                                    .foregroundStyle(FGColor.inkMuted)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.72)
                                } else {
                                    Color.clear
                                        .accessibilityHidden(true)
                                }
                            }
                            .frame(height: 14)
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity, minHeight: 96)
                    }
                    .buttonStyle(.feelGoodPress)
                    .scaleEffect(isSelected ? 1.04 : 1)
                    .offset(y: isSelected ? -2 : 0)
                    .zIndex(isSelected ? 1 : 0)
                    .fgAnimation(FGMotion.settle, value: isSelected)
                    .accessibilityLabel(
                        isUnlocked ? "\(choice.displayName) background" : "Locked mystery background"
                    )
                    .accessibilityHint(
                        isUnlocked
                            ? "Selects this profile background"
                            : "Unlocks with the \(choice.unlockingWin?.title ?? "little win") badge"
                    )
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

    private func isAvatarUnlocked(_ avatar: ProfileAvatar) -> Bool {
        avatar == .defaultAvatar
            || avatar == selection
            || avatar.unlockingWin.map(unlockedWins.contains) == true
    }

    private func isBackgroundUnlocked(_ choice: ProfileAvatarBackground) -> Bool {
        choice == .automatic
            || choice == background
            || choice.unlockingWin.map(unlockedWins.contains) == true
    }
}
