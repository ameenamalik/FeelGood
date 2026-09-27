//
//  DopamineMenuTourView.swift
//  FeelGood
//
//  A short first-run tour introducing the menu, swapping, and custom routines.
//

import SwiftUI

struct DopamineMenuTourView: View {
    var onComplete: () -> Void

    @State private var currentStep = 0
    @Environment(\.dismiss) private var dismiss

    private let totalSteps = 3

    var body: some View {
        ZStack {
            FGColor.bg.ignoresSafeArea()
            FGBrandWash(reach: 0.65).ignoresSafeArea()

            VStack(spacing: FGSpace.l) {
                topBar

                TabView(selection: $currentStep) {
                    stepOne
                        .tag(0)

                    stepTwo
                        .tag(1)

                    stepThree
                        .tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                footer
            }
            .padding(.horizontal, FGSpace.page)
            .padding(.vertical, FGSpace.m)
        }
    }

    private var topBar: some View {
        HStack {
            // Page indicator dots
            HStack(spacing: 6) {
                ForEach(0..<totalSteps, id: \.self) { index in
                    Capsule()
                        .fill(index == currentStep ? FGColor.ink : FGColor.lineStrong)
                        .frame(width: index == currentStep ? 20 : 6, height: 6)
                        .animation(FGMotion.gentle, value: currentStep)
                }
            }

            Spacer()

            Button("Skip") {
                finish()
            }
            .font(FGFont.label.weight(.medium))
            .foregroundStyle(FGColor.inkMuted)
        }
        .padding(.top, FGSpace.xs)
    }

    // MARK: - Slides

    private var stepOne: some View {
        VStack(spacing: FGSpace.xl) {
            Spacer()

            TourIntroDemo(isActive: currentStep == 0)
                .frame(height: 200)

            VStack(spacing: FGSpace.m) {
                Text("Your menu for today")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundStyle(FGColor.ink)
                    .multilineTextAlignment(.center)

                Text("Pick one. That counts.")
                    .font(FGFont.body)
                    .foregroundStyle(FGColor.inkMuted)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, FGSpace.s)
            }

            Spacer()
        }
    }

    private var stepTwo: some View {
        TourCoursesSwapDemo(isActive: currentStep == 1)
    }

    private var stepThree: some View {
        TourAddRoutineDemo(isActive: currentStep == 2)
    }

    // MARK: - Footer & Helpers

    private var footer: some View {
        Button {
            if currentStep < totalSteps - 1 {
                withAnimation(FGMotion.gentle) {
                    currentStep += 1
                }
            } else {
                finish()
            }
        } label: {
            Text(currentStep == totalSteps - 1 ? "Start" : "Next")
                .font(FGFont.itemTitle)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(FGColor.actionFill)
                .foregroundStyle(FGColor.onActionFill)
                .clipShape(RoundedRectangle(cornerRadius: FGRadius.tile, style: .continuous))
        }
        .buttonStyle(.feelGoodPress)
        .padding(.bottom, FGSpace.s)
    }

    private func finish() {
        dismiss()
        onComplete()
    }
}


// MARK: - Animated demos

/// Shared mock content for the tour demos. Purely illustrative, no real data.
private struct DemoItem: Equatable {
    let title: String
    let time: String
    let aura: FGAura

    static let samples: [DemoItem] = [
        DemoItem(title: "Desk shoulder rolls", time: "3 min", aura: .apricot),
        DemoItem(title: "Gentle mat flow", time: "12 min", aura: .lilac),
        DemoItem(title: "Slow stretch", time: "6 min", aura: .sage),
        DemoItem(title: "Box breathing", time: "5 min", aura: .butter),
    ]
}

private struct DemoCard: View {
    let item: DemoItem
    var isChosen = false

    var body: some View {
        HStack(spacing: FGSpace.m) {
            Circle()
                .fill(item.aura.core)
                .frame(width: 40, height: 40)
                .overlay(Circle().strokeBorder(item.aura.mid.opacity(0.7), lineWidth: 1))
                .overlay {
                    if isChosen {
                        Image(systemName: "checkmark")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(FGColor.ink)
                            .transition(.scale.combined(with: .opacity))
                    }
                }

            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(FGFont.itemTitle)
                    .foregroundStyle(FGColor.ink)
                Text(item.time)
                    .font(FGFont.label)
                    .foregroundStyle(FGColor.inkMuted)
            }
            Spacer()
        }
        .padding(FGSpace.m)
        .background(
            RoundedRectangle(cornerRadius: FGRadius.tile, style: .continuous)
                .fill(isChosen ? item.aura.core.opacity(0.45) : FGColor.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: FGRadius.tile, style: .continuous)
                .strokeBorder(isChosen ? item.aura.mid.opacity(0.7) : FGColor.line, lineWidth: 1)
        )
    }
}

private func pause(_ seconds: Double) async {
    try? await Task.sleep(for: .seconds(seconds))
}

/// Slide 1: menu cards rise in one by one, then one gets picked.
private struct TourIntroDemo: View {
    let isActive: Bool

    @State private var visibleCount = 0
    @State private var chosenIndex: Int?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let items = Array(DemoItem.samples.prefix(3))

    var body: some View {
        VStack(spacing: FGSpace.s) {
            ForEach(items.indices, id: \.self) { i in
                DemoCard(item: items[i], isChosen: chosenIndex == i)
                    .opacity(i < visibleCount ? (chosenIndex == nil || chosenIndex == i ? 1 : 0.45) : 0)
                    .offset(y: i < visibleCount ? 0 : 24)
                    .scaleEffect(chosenIndex == i ? 1.03 : 1)
            }
        }
        .accessibilityHidden(true)
        .task(id: isActive) {
            guard isActive else { return }
            if reduceMotion {
                visibleCount = items.count
                return
            }
            while !Task.isCancelled {
                visibleCount = 0
                chosenIndex = nil
                await pause(0.3)
                for i in 1...items.count {
                    guard !Task.isCancelled else { return }
                    withAnimation(FGMotion.settle) { visibleCount = i }
                    await pause(0.35)
                }
                await pause(0.8)
                withAnimation(FGMotion.swap) { chosenIndex = 1 }
                await pause(2.4)
            }
        }
    }
}

/// Slide 2: the four courses appear, then a card is swiped away and the
/// next one slides in from the right.
private struct TourCoursesSwapDemo: View {
    let isActive: Bool

    private enum Phase { case courses, swap }

    private struct Course: Identifiable {
        let id: String
        let time: String
        let icon: String
        let aura: FGAura
    }

    private let courses = [
        Course(id: "Appetizers", time: "3–5 min", icon: "sun.max.fill", aura: .apricot),
        Course(id: "Mains", time: "10–25 min", icon: "figure.cross.training", aura: .lilac),
        Course(id: "Sides", time: "5–15 min", icon: "figure.flexibility", aura: .sage),
        Course(id: "Desserts", time: "5–10 min", icon: "sparkles", aura: .butter),
    ]

    @State private var phase: Phase = .courses
    @State private var visibleCourses = 0
    @State private var itemIndex = 0
    @State private var cardOffset: CGFloat = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: FGSpace.l) {
            Spacer()

            ZStack {
                if phase == .courses {
                    VStack(spacing: FGSpace.s) {
                        ForEach(courses.indices, id: \.self) { i in
                            courseRow(courses[i])
                                .opacity(i < visibleCourses ? 1 : 0)
                                .offset(y: i < visibleCourses ? 0 : 18)
                        }
                    }
                    .transition(.opacity)
                } else {
                    DemoCard(item: DemoItem.samples[itemIndex % DemoItem.samples.count])
                        .offset(x: cardOffset)
                        .rotationEffect(.degrees(Double(cardOffset) / 50))
                        .transition(.opacity)
                }
            }
            .frame(height: 260)
            .clipped()
            .accessibilityHidden(true)

            VStack(spacing: FGSpace.s) {
                Text(phase == .courses ? "Four kinds of movement" : "Swap anything")
                    .font(FGFont.display)
                    .foregroundStyle(FGColor.ink)
                    .multilineTextAlignment(.center)
                    .id("t-\(phase)")
                    .transition(.opacity)

                Text(phase == .courses
                     ? "Short starts, full sessions, resets, and rest."
                     : "Swipe left or tap Swap.")
                    .font(FGFont.body)
                    .foregroundStyle(FGColor.inkMuted)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .padding(.horizontal, FGSpace.s)
                    .id("s-\(phase)")
                    .transition(.opacity)
            }
            .animation(FGMotion.gentle, value: phase)

            Spacer()
        }
        .task(id: isActive) {
            guard isActive else { return }
            if reduceMotion {
                visibleCourses = courses.count
                return
            }
            await runLoop()
        }
    }

    private func courseRow(_ c: Course) -> some View {
        HStack(spacing: FGSpace.m) {
            Image(systemName: c.icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(c.aura.mid)
                .frame(width: 34, height: 34)
                .background(c.aura.core.opacity(0.4))
                .clipShape(Circle())
            Text(c.id)
                .font(FGFont.itemTitle)
                .foregroundStyle(FGColor.ink)
            Spacer()
            Text(c.time)
                .font(FGFont.label)
                .foregroundStyle(FGColor.inkMuted)
        }
        .padding(FGSpace.m)
        .background(
            RoundedRectangle(cornerRadius: FGRadius.tile, style: .continuous)
                .fill(FGColor.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: FGRadius.tile, style: .continuous)
                .strokeBorder(FGColor.line, lineWidth: 1)
        )
    }

    private func runLoop() async {
        while !Task.isCancelled {
            phase = .courses
            visibleCourses = 0
            itemIndex = 0
            cardOffset = 0
            await pause(0.3)

            for i in 1...courses.count {
                guard !Task.isCancelled else { return }
                withAnimation(FGMotion.settle) { visibleCourses = i }
                await pause(0.3)
            }
            await pause(1.6)
            guard !Task.isCancelled else { return }
            withAnimation(FGMotion.gentle) { phase = .swap }
            await pause(1.2)

            for _ in 0..<3 {
                guard !Task.isCancelled else { return }
                // Swipe out to the left.
                withAnimation(.easeIn(duration: 0.28)) { cardOffset = -460 }
                await pause(0.3)
                // Jump the next card to the right edge, then slide it in.
                itemIndex += 1
                var t = Transaction()
                t.disablesAnimations = true
                withTransaction(t) { cardOffset = 460 }
                await pause(0.05)
                withAnimation(FGMotion.swap) { cardOffset = 0 }
                await pause(1.3)
            }
        }
    }
}

/// Slide 3: tap + Routine, type a custom movement, press Add, and it lands
/// on the menu.
private struct TourAddRoutineDemo: View {
    let isActive: Bool

    private let typedText = "Evening walk with the dog"

    @State private var isTappingPlus = false
    @State private var isShowingField = false
    @State private var typed = ""
    @State private var isShowingAdd = false
    @State private var isTappingAdd = false
    @State private var isAdded = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: FGSpace.l) {
            Spacer()

            stage
                .frame(height: 190)
                .accessibilityHidden(true)

            VStack(spacing: FGSpace.s) {
                Text("Add your own")
                    .font(FGFont.display)
                    .foregroundStyle(FGColor.ink)
                    .multilineTextAlignment(.center)

                Text("Tap + Routine.")
                    .font(FGFont.body)
                    .foregroundStyle(FGColor.inkMuted)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .padding(.horizontal, FGSpace.s)
            }

            Spacer()
        }
        .task(id: isActive) {
            guard isActive else { return }
            if reduceMotion {
                isAdded = true
                return
            }
            await runLoop()
        }
    }

    private var stage: some View {
        VStack(spacing: FGSpace.m) {
            ZStack(alignment: .bottomTrailing) {
                HStack(spacing: 4) {
                    Image(systemName: "plus")
                        .font(.system(size: 11, weight: .semibold))
                    Text("Routine")
                        .font(FGFont.label.weight(.medium))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .foregroundStyle(FGColor.ink)
                .background(FGColor.surface)
                .clipShape(Capsule())
                .overlay(Capsule().strokeBorder(FGColor.lineStrong, lineWidth: 1))
                .scaleEffect(isTappingPlus ? 0.92 : 1)

                Image(systemName: "hand.tap.fill")
                    .font(.system(size: 26))
                    .foregroundStyle(FGColor.ink.opacity(0.75))
                    .offset(x: 10, y: 22)
                    .opacity(isTappingPlus ? 1 : 0)
            }

            if isAdded {
                DemoCard(
                    item: DemoItem(title: typedText, time: "Yours", aura: .sage),
                    isChosen: true
                )
                .transition(.move(edge: .bottom).combined(with: .opacity))
            } else if isShowingField {
                HStack(spacing: FGSpace.s) {
                    HStack(spacing: 2) {
                        Text(typed.isEmpty ? " " : typed)
                            .font(FGFont.body)
                            .foregroundStyle(FGColor.ink)
                            .lineLimit(1)
                        Rectangle()
                            .fill(FGColor.ink)
                            .frame(width: 2, height: 20)
                        Spacer(minLength: 0)
                    }

                    if isShowingAdd {
                        Text("Add")
                            .font(FGFont.label.weight(.semibold))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 7)
                            .background(FGColor.actionFill)
                            .foregroundStyle(FGColor.onActionFill)
                            .clipShape(Capsule())
                            .scaleEffect(isTappingAdd ? 0.9 : 1)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                .padding(FGSpace.m)
                .background(
                    RoundedRectangle(cornerRadius: FGRadius.tile, style: .continuous)
                        .fill(FGColor.surface)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: FGRadius.tile, style: .continuous)
                        .strokeBorder(FGColor.lineStrong, lineWidth: 1)
                )
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }

    private func runLoop() async {
        while !Task.isCancelled {
            isTappingPlus = false
            isShowingField = false
            isShowingAdd = false
            isTappingAdd = false
            isAdded = false
            typed = ""

            await pause(0.9)
            withAnimation(.easeOut(duration: 0.18)) { isTappingPlus = true }
            await pause(0.35)
            withAnimation(.easeOut(duration: 0.18)) { isTappingPlus = false }
            withAnimation(FGMotion.gentle) { isShowingField = true }
            await pause(0.5)

            for ch in typedText {
                guard !Task.isCancelled else { return }
                typed.append(ch)
                await pause(0.06)
            }
            await pause(0.3)
            withAnimation(FGMotion.swap) { isShowingAdd = true }
            await pause(0.8)
            withAnimation(.easeOut(duration: 0.15)) { isTappingAdd = true }
            await pause(0.25)
            withAnimation(FGMotion.settle) { isAdded = true }
            await pause(2.4)
        }
    }
}
