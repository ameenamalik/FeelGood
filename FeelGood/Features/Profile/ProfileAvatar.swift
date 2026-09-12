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
                            Button {
                                selection = avatar
                            } label: {
                                VStack(spacing: FGSpace.xs) {
                                    ProfileAvatarView(
                                        avatar: avatar,
                                        background: background,
                                        size: 76
                                    )

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
                                            selection == avatar ? FGColor.ink : FGColor.lineStrong,
                                            lineWidth: selection == avatar ? 2 : 1
                                        )
                                }
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(avatar.displayName)
                            .accessibilityAddTraits(selection == avatar ? .isSelected : [])
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
    }

    private var backgroundPicker: some View {
        VStack(alignment: .leading, spacing: FGSpace.s) {
            Text("Background color")
                .font(FGFont.sectionTitle)
                .foregroundStyle(FGColor.ink)

            LazyVGrid(columns: columns, spacing: FGSpace.s) {
                ForEach(ProfileAvatarBackground.allCases) { choice in
                    Button {
                        background = choice
                    } label: {
                        VStack(spacing: FGSpace.xs) {
                            Circle()
                                .fill(choice.aura(for: selection).core)
                                .frame(width: 46, height: 46)
                                .overlay {
                                    Circle()
                                        .strokeBorder(
                                            background == choice ? FGColor.ink : FGColor.lineStrong,
                                            lineWidth: background == choice ? 3 : 1
                                        )
                                }
                                .overlay {
                                    if background == choice {
                                        Image(systemName: "checkmark")
                                            .font(.caption.weight(.bold))
                                            .foregroundStyle(FGColor.inkOnAccent)
                                    }
                                }

                            Text(choice.displayName)
                                .font(FGFont.caption.weight(.semibold))
                                .foregroundStyle(FGColor.ink)
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity, minHeight: 82)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(choice.displayName) background")
                    .accessibilityAddTraits(background == choice ? .isSelected : [])
                }
            }
        }
    }
}
