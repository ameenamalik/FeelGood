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
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isPulsing = false
    /// A few degrees either side of upright — a full spin would read as a
    /// loading state, not a celebration, so this only ever wiggles.
    @State private var mascotTilt = 0.0

    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(alignment: .center, spacing: FGSpace.s) {
                Image(progress.win.mascotAsset)
                    .resizable()
                    .scaledToFit()
                    .saturation(progress.isUnlocked ? 1 : 0)
                    .opacity(progress.isUnlocked ? 1 : 0.48)
                    .frame(width: 64, height: 64)
                    .rotationEffect(.degrees(mascotTilt))

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
        .overlay(
            RoundedRectangle(cornerRadius: FGRadius.tile, style: .continuous)
                .fill(Color.white.opacity(isPulsing ? 0.45 : 0))
                .allowsHitTesting(false)
        )
        .scaleEffect(isPulsing ? 1.07 : 1.0)
        .shadow(color: FGColor.ink.opacity(0.055), radius: 10, y: 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(progress.win.title), \(progress.statusLine)")
        .accessibilityHint("Opens badge details")
        .onChange(of: progress.isUnlocked) { wasUnlocked, isUnlocked in
            // Only the live flip earns the moment — a card that opens already
            // unlocked (a fresh load, a different day) gets no pop.
            guard !wasUnlocked, isUnlocked, !reduceMotion else { return }
            withAnimation(FGMotion.swap) { isPulsing = true }
            withAnimation(FGMotion.settle.delay(0.16)) { isPulsing = false }

            // A quick tilt-and-settle on the mascot itself, timed just under
            // the card's own pulse so the two moments read as one gesture
            // rather than two separate animations firing side by side.
            withAnimation(.interpolatingSpring(stiffness: 220, damping: 8)) {
                mascotTilt = -12
            }
            withAnimation(.interpolatingSpring(stiffness: 180, damping: 9).delay(0.12)) {
                mascotTilt = 0
            }
        }
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
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var shareItems: ShareItems?
    @State private var mascotScale = 0.72
    @State private var mascotRotation = -7.0
    @State private var mascotOpacity = 0.0
    @State private var didCelebrate = false

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
                        .scaleEffect(mascotScale)
                        .rotationEffect(.degrees(mascotRotation))
                        .opacity(mascotOpacity)
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
        .sensoryFeedback(.success, trigger: didCelebrate)
        .onAppear {
            didCelebrate = true

            guard !reduceMotion else {
                mascotScale = 1
                mascotRotation = 0
                mascotOpacity = 1
                return
            }

            // One spring supplies the pop and its natural settle. A second
            // bounce made the badge feel toy-like rather than warmly earned.
            withAnimation(.spring(response: 0.58, dampingFraction: 0.58)) {
                mascotScale = 1
                mascotRotation = 0
                mascotOpacity = 1
            }
        }
        .interactiveDismissDisabled()
        .sheet(item: $shareItems) { items in
            ActivityShareSheet(items: items.items)
                .presentationDetents([.medium, .large])
        }
    }
}

private struct LittleWinConfetti: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let pieces: [LittleWinConfettiPiece] = [
        .init(id: 0, x: 0.08, y: 0.12, rotation: -28, spin: -95, fall: 96, delay: 0.00, color: FGColor.rose),
        .init(id: 1, x: 0.21, y: 0.06, rotation: 32, spin: 120, fall: 82, delay: 0.03, color: FGColor.sage),
        .init(id: 2, x: 0.36, y: 0.10, rotation: -12, spin: -80, fall: 106, delay: 0.07, color: FGColor.gold),
        .init(id: 3, x: 0.64, y: 0.09, rotation: 18, spin: 85, fall: 92, delay: 0.05, color: FGColor.clay),
        .init(id: 4, x: 0.79, y: 0.06, rotation: -34, spin: -130, fall: 84, delay: 0.02, color: FGColor.rose),
        .init(id: 5, x: 0.92, y: 0.15, rotation: 24, spin: 105, fall: 102, delay: 0.08, color: FGColor.gold),
        .init(id: 6, x: 0.05, y: 0.35, rotation: 38, spin: 125, fall: 116, delay: 0.10, color: FGColor.gold),
        .init(id: 7, x: 0.95, y: 0.38, rotation: -30, spin: -110, fall: 112, delay: 0.12, color: FGColor.sage),
        .init(id: 8, x: 0.10, y: 0.63, rotation: 20, spin: 90, fall: 126, delay: 0.05, color: FGColor.clay),
        .init(id: 9, x: 0.90, y: 0.64, rotation: 35, spin: 140, fall: 122, delay: 0.09, color: FGColor.rose),
        .init(id: 10, x: 0.18, y: 0.79, rotation: -25, spin: -100, fall: 108, delay: 0.13, color: FGColor.sage),
        .init(id: 11, x: 0.82, y: 0.80, rotation: 28, spin: 115, fall: 104, delay: 0.15, color: FGColor.gold),
    ]

    var body: some View {
        GeometryReader { proxy in
            ForEach(pieces) { piece in
                LittleWinConfettiPieceView(
                    piece: piece,
                    canvasSize: proxy.size,
                    reduceMotion: reduceMotion
                )
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

private struct LittleWinConfettiPiece: Identifiable {
    let id: Int
    let x: CGFloat
    let y: CGFloat
    let rotation: Double
    let spin: Double
    let fall: CGFloat
    let delay: Double
    let color: Color
}

private struct LittleWinConfettiPieceView: View {
    let piece: LittleWinConfettiPiece
    let canvasSize: CGSize
    let reduceMotion: Bool

    @State private var didBurst = false
    @State private var didFall = false

    var body: some View {
        Capsule()
            .fill(piece.color)
            .frame(width: 9, height: 22)
            .scaleEffect(didBurst ? 1 : 0.18)
            .rotationEffect(
                .degrees((didBurst ? piece.rotation : 0) + (didFall ? piece.spin : 0))
            )
            .position(
                x: didBurst ? canvasSize.width * piece.x : canvasSize.width * 0.5,
                y: (didBurst ? canvasSize.height * piece.y : canvasSize.height * 0.42)
                    + (didFall ? piece.fall : 0)
            )
            .opacity(reduceMotion ? (didBurst ? 0.72 : 0) : (didFall ? 0 : didBurst ? 1 : 0))
            .task {
                guard !reduceMotion else {
                    didBurst = true
                    return
                }

                do {
                    try await Task.sleep(for: .seconds(piece.delay))
                } catch {
                    return
                }

                withAnimation(.spring(response: 0.52, dampingFraction: 0.72)) {
                    didBurst = true
                }

                do {
                    try await Task.sleep(for: .milliseconds(520))
                } catch {
                    return
                }

                withAnimation(.easeIn(duration: 0.92)) {
                    didFall = true
                }
            }
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
