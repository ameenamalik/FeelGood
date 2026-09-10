//
//  LittleWinsView.swift
//  FeelGood
//

import SwiftUI
import UIKit

struct LittleWinsSection: View {
    let progress: [LittleWinProgress]
    @State private var selected: LittleWinProgress?

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: FGSpace.m) {
            VStack(alignment: .leading, spacing: FGSpace.xs) {
                Text("Your little wins")
                    .font(FGFont.title)
                    .foregroundStyle(FGColor.ink)
                Text("Small things worth noticing. No streak required.")
                    .font(FGFont.reason)
                    .foregroundStyle(FGColor.inkMuted)
            }

            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(progress) { item in
                    Button { selected = item } label: {
                        LittleWinCard(progress: item)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .sheet(item: $selected) { item in
            NavigationStack {
                LittleWinDetailView(progress: item)
            }
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
    }
}

private struct LittleWinCard: View {
    let progress: LittleWinProgress

    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(alignment: .center, spacing: FGSpace.s) {
                Image(progress.win.mascotAsset)
                    .resizable()
                    .scaledToFit()
                    .saturation(progress.isUnlocked ? 1 : 0)
                    .opacity(progress.isUnlocked ? 1 : 0.48)
                    .frame(width: 64, height: 64)

                Text(progress.win.title)
                    .font(FGFont.itemTitle)
                    .foregroundStyle(FGColor.inkOnAccent)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)

                Text(progress.statusLine)
                    .font(FGFont.caption)
                    .foregroundStyle(FGColor.inkOnAccent.opacity(0.72))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, minHeight: 154, alignment: .center)

            if !progress.isUnlocked {
                Image(systemName: "lock.fill")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(FGColor.inkMuted)
                    .frame(width: 28, height: 28)
                    .background(FGColor.surface.opacity(0.78))
                    .clipShape(Circle())
            }
        }
        .padding(FGSpace.m)
        .background(
            progress.win.aura.badgeGradient,
            in: RoundedRectangle(cornerRadius: FGRadius.tile, style: .continuous)
        )
        .shadow(color: FGColor.ink.opacity(0.055), radius: 10, y: 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(progress.win.title), \(progress.statusLine)")
        .accessibilityHint("Opens badge details")
    }
}

struct LittleWinDetailView: View {
    let progress: LittleWinProgress
    @Environment(\.dismiss) private var dismiss
    @State private var shareItems: ShareItems?

    var body: some View {
        ZStack {
            FGColor.bg.ignoresSafeArea()
            FGBrandWash(reach: 0.32).ignoresSafeArea()

            VStack(spacing: FGSpace.m) {
                Image(progress.win.mascotAsset)
                    .resizable()
                    .scaledToFit()
                    .saturation(progress.isUnlocked ? 1 : 0)
                    .opacity(progress.isUnlocked ? 1 : 0.48)
                    .frame(width: 112, height: 112)

                VStack(spacing: FGSpace.s) {
                    Text(progress.win.title)
                        .font(FGFont.display)
                        .foregroundStyle(FGColor.ink)
                    Text(progress.isUnlocked ? progress.win.unlockedLine : progress.statusLine)
                        .font(FGFont.sectionTitle)
                        .foregroundStyle(FGColor.inkMuted)
                        .multilineTextAlignment(.center)
                    Text(progress.win.detail)
                        .font(FGFont.body)
                        .foregroundStyle(FGColor.inkMuted)
                        .multilineTextAlignment(.center)
                }

                if progress.isUnlocked {
                    Button {
                        shareItems = ShareItems(progress: progress)
                    } label: {
                        Label("Share badge", systemImage: "square.and.arrow.up")
                            .font(FGFont.body.weight(.semibold))
                            .foregroundStyle(FGColor.ink)
                            .frame(width: 220, height: 50)
                            .background(FGColor.surface)
                            .clipShape(Capsule())
                            .shadow(color: FGColor.ink.opacity(0.06), radius: 8, y: 3)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(FGSpace.page)
        }
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") { dismiss() }
            }
        }
        .sheet(item: $shareItems) { items in
            ActivityShareSheet(items: items.items)
                .presentationDetents([.medium, .large])
        }
    }
}

struct LittleWinCelebrationView: View {
    let celebration: LittleWinCelebration
    @Environment(\.dismiss) private var dismiss
    @State private var shareItems: ShareItems?

    var body: some View {
        ZStack {
            FGColor.bg.ignoresSafeArea()
            FGBrandWash(reach: 0.38).ignoresSafeArea()
            LittleWinConfetti()

            VStack(spacing: FGSpace.l) {
                VStack(spacing: FGSpace.s) {
                    Text("New badge unlocked")
                        .font(FGFont.display)
                        .foregroundStyle(FGColor.ink)
                        .multilineTextAlignment(.center)

                    Text("You just added another little win.")
                        .font(FGFont.body)
                        .foregroundStyle(FGColor.inkMuted)
                        .multilineTextAlignment(.center)
                }

                ZStack {
                    Circle()
                        .fill(celebration.featured.win.aura.badgeGradient)
                        .frame(width: 164, height: 164)

                    Circle()
                        .fill(FGColor.surface.opacity(0.34))
                        .frame(width: 132, height: 132)

                    Image(celebration.featured.win.mascotAsset)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 118, height: 118)
                }

                VStack(spacing: FGSpace.s) {
                    Text(celebration.featured.win.title)
                        .font(FGFont.title)
                        .foregroundStyle(FGColor.ink)
                        .multilineTextAlignment(.center)
                    Text(celebration.featured.win.unlockedLine)
                        .font(FGFont.body)
                        .foregroundStyle(FGColor.inkMuted)
                        .multilineTextAlignment(.center)

                    if celebration.wins.count > 1 {
                        Text("And \(celebration.wins.count - 1) more little win\(celebration.wins.count == 2 ? "" : "s").")
                            .font(FGFont.caption.weight(.semibold))
                            .foregroundStyle(FGColor.inkMuted)
                    }
                }

                HStack(spacing: FGSpace.s) {
                    Button {
                        shareItems = ShareItems(progress: celebration.featured)
                    } label: {
                        Label("Share", systemImage: "square.and.arrow.up")
                            .font(FGFont.body.weight(.semibold))
                            .foregroundStyle(FGColor.ink)
                            .frame(maxWidth: .infinity, minHeight: 56)
                            .background(FGColor.line)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)

                    FGPrimaryButton(title: "Nice") { dismiss() }
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, FGSpace.l)
            .padding(.vertical, FGSpace.xl)
            .frame(maxWidth: 370)
            .background(
                FGColor.surface,
                in: RoundedRectangle(cornerRadius: FGRadius.tile, style: .continuous)
            )
            .shadow(color: FGColor.ink.opacity(0.11), radius: 24, y: 10)
            .padding(FGSpace.page)
        }
        .interactiveDismissDisabled()
        .sheet(item: $shareItems) { items in
            ActivityShareSheet(items: items.items)
                .presentationDetents([.medium, .large])
        }
    }
}

private struct LittleWinConfetti: View {
    private let pieces: [(x: CGFloat, y: CGFloat, rotation: Double, color: Color)] = [
        (0.08, 0.10, -18, FGColor.rose),
        (0.22, 0.05, 28, FGColor.sage),
        (0.78, 0.07, -32, FGColor.clay),
        (0.92, 0.14, 18, FGColor.gold),
        (0.06, 0.34, 36, FGColor.gold),
        (0.94, 0.39, -24, FGColor.sage),
        (0.08, 0.72, 16, FGColor.clay),
        (0.92, 0.68, 34, FGColor.rose),
        (0.18, 0.91, -28, FGColor.sage),
        (0.82, 0.92, 22, FGColor.gold),
    ]

    var body: some View {
        GeometryReader { proxy in
            ForEach(Array(pieces.enumerated()), id: \.offset) { _, piece in
                Capsule()
                    .fill(piece.color)
                    .frame(width: 9, height: 22)
                    .rotationEffect(.degrees(piece.rotation))
                    .position(
                        x: proxy.size.width * piece.x,
                        y: proxy.size.height * piece.y
                    )
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

private struct ShareItems: Identifiable {
    let id = UUID()
    let items: [Any]

    @MainActor
    init(progress: LittleWinProgress) {
        let card = LittleWinShareCard(progress: progress)
            .frame(width: 1080, height: 1080)
        let renderer = ImageRenderer(content: card)
        renderer.scale = 1
        var result: [Any] = ["\(progress.win.title) — a little win with FeelGood."]
        if let image = renderer.uiImage { result.insert(image, at: 0) }
        items = result
    }
}

private struct LittleWinShareCard: View {
    let progress: LittleWinProgress

    var body: some View {
        ZStack {
            progress.win.aura.badgeGradient

            VStack(spacing: 42) {
                Text("FEELGOOD · LITTLE WINS")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .tracking(3)
                    .foregroundStyle(FGColor.inkOnAccent.opacity(0.66))

                Image(progress.win.mascotAsset)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 430, height: 430)

                Text(progress.win.title)
                    .font(.system(size: 76, weight: .bold, design: .rounded))
                    .foregroundStyle(FGColor.inkOnAccent)

                Text(progress.win.unlockedLine)
                    .font(.system(size: 34, weight: .medium))
                    .foregroundStyle(FGColor.inkOnAccent.opacity(0.72))
            }
            .padding(80)
        }
        .clipShape(RoundedRectangle(cornerRadius: 72, style: .continuous))
    }
}

private struct ActivityShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

private extension LittleWin {
    var aura: FGAura {
        switch self {
        case .firstMove: .apricot
        case .homebody: .sage
        case .gymRegular: .lilac
        case .yogaEra: .blush
        case .tinyWins: .butter
        case .varietyPack: .apricot
        }
    }
}

private extension FGAura {
    var badgeGradient: LinearGradient {
        LinearGradient(
            colors: [core, mid],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}
