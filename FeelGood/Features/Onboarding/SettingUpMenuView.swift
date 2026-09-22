//
//  SettingUpMenuView.swift
//  FeelGood
//
//  A delightful ~2.3-second transition animation shown right after onboarding
//  completes, giving the user a warm sense of personal care before they
//  arrive at their fresh daily menu and the Dopamine Menu Tour.
//

import SwiftUI
import UIKit

struct SettingUpMenuView: View {
    var onComplete: () -> Void

    @State private var phase = 0
    @State private var progress: CGFloat = 0.28
    @State private var isPulsing = false
    @State private var isCompleted = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            FGColor.bg.ignoresSafeArea()
            FGBrandWash(reach: 0.82).ignoresSafeArea()

            VStack(spacing: FGSpace.xl) {
                Spacer()

                // Mascot nestled in a pulsing aura
                ZStack {
                    Circle()
                        .fill(FGAura.apricot.core.opacity(isPulsing ? 0.40 : 0.24))
                        .frame(width: 140, height: 140)
                        .scaleEffect(reduceMotion ? 1.0 : (isPulsing ? 1.08 : 0.94))

                    Image("IntentEnergyClementine")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 110, height: 110)
                        .offset(y: reduceMotion ? 0 : (isPulsing ? -5 : 5))
                }

                VStack(spacing: FGSpace.s) {
                    Text("Setting up your menu")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(FGColor.ink)

                    // Phase text
                    Text(currentPhaseText)
                        .font(FGFont.body)
                        .foregroundStyle(FGColor.inkMuted)
                        .multilineTextAlignment(.center)
                        .frame(height: 24)
                        .id("phase_\(phase)")
                        .transition(.opacity.combined(with: .scale(scale: 0.96)))
                }

                // Progress bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(FGColor.ink.opacity(0.08))
                            .frame(height: 6)

                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [FGColor.clayDeep, FGColor.controlAccent],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: max(16, geo.size.width * progress), height: 6)
                            .animation(.easeInOut(duration: 0.45), value: progress)
                    }
                }
                .frame(width: 200, height: 6)
                .padding(.top, FGSpace.xs)

                Spacer()
            }
            .padding(.horizontal, FGSpace.page)
            .contentShape(Rectangle())
            .onTapGesture {
                finish()
            }
        }
        .onAppear {
            startAnimationSequence()
        }
    }

    private var currentPhaseText: String {
        switch phase {
        case 0:
            return "Tuning into your energy..."
        case 1:
            return "Curating your 4 courses..."
        default:
            return "Your menu is ready!"
        }
    }

    private func startAnimationSequence() {
        withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
            isPulsing = true
        }

        if reduceMotion {
            progress = 1.0
            phase = 2
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                finish()
            }
            return
        }

        // Phase 1: Curating your 4 courses at 0.8s
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation(FGMotion.gentle) {
                phase = 1
                progress = 0.72
            }
        }

        // Phase 2: Ready at 1.6s
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
            withAnimation(FGMotion.gentle) {
                phase = 2
                progress = 1.0
            }
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }

        // Auto-complete at 2.3s
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.3) {
            finish()
        }
    }

    private func finish() {
        guard !isCompleted else { return }
        isCompleted = true
        onComplete()
    }
}
