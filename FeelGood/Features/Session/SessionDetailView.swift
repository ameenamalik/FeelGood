//
//  SessionDetailView.swift
//  FeelGood
//
//  What it is, what you need, one action. The title carries the screen; the
//  detail waits behind a disclosure for whoever actually wants it.
//
//  The "why" lives here now, not on the card that offered it — Today's menu
//  card and Chat's recommendation card both stay to a title and a mascot;
//  whoever wants the reasoning taps in for it instead of reading it twice.
//

import SwiftUI

struct SessionDetailView: View {
    @State private var session: Session
    let model: TodayModel
    let onCompleted: () -> Void
    /// The "why" that used to sit on the card that offered this session.
    /// `nil` from the Library, where nobody chose it and there's no reason to
    /// give.
    private let reasonText: String?

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var isPlaying = false
    @State private var startedAt = Date()
    @State private var explaining: ExerciseTerm?
    @State private var isShowingSteps = false
    @State private var isEditing = false
    @State private var isConfirmingRemoval = false
    @State private var isConfirmingHide = false
    @State private var littleWinCelebration: LittleWinCelebration?
    @State private var shouldCloseAfterPlayer = false
    @State private var completedPlayerSession = false

    /// From the menu, where something chose it.
    init(item: MenuItem, model: TodayModel, onCompleted: @escaping () -> Void = {}) {
        _session = State(initialValue: item.session)
        self.model = model
        self.onCompleted = onCompleted
        self.reasonText = item.reasonText
    }

    /// From the Library, where nobody chose it and somebody went looking — or
    /// from Chat, where a reason was already given in conversation.
    init(session: Session, model: TodayModel, reason: String? = nil, onCompleted: @escaping () -> Void = {}) {
        _session = State(initialValue: session)
        self.model = model
        self.onCompleted = onCompleted
        self.reasonText = reason
    }

    var body: some View {
        ZStack {
            FGColor.bg.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: FGSpace.l) {
                    heading

                    // Equipment, length, impact — not target area, which is
                    // already the title's own words. A pill that repeats the
                    // heading back isn't information, it's noise.
                    WrapRow(spacing: FGSpace.s, lineSpacing: FGSpace.s) {
                        ForEach(detailChips, id: \.self) { FGChip(text: $0) }
                    }

                    if !session.source.steps.isEmpty {
                        VStack(alignment: .leading, spacing: FGSpace.m) {
                            Divider()
                                .overlay(FGColor.line)

                            lineup

                            Divider()
                                .overlay(FGColor.line)

                            if let firstStep = session.source.steps.first {
                                firstUpSection(firstStep)
                            }
                        }
                    }

                    // Custom routines remain editable whether they are a
                    // simple after-the-fact log or a playable list of parts.
                    if session.isOwn {
                        VStack(spacing: FGSpace.s) {
                            if session.source.steps.isEmpty {
                                FGPrimaryButton(title: "I did this") {
                                    let completionStartedAt = Date()
                                    Analytics.capture("workout_completed", properties: workoutProperties)
                                    OneSignalManager.shared.trackSessionCompleted(
                                        sessionID: session.id,
                                        startedAt: completionStartedAt
                                    )
                                    model.complete(session, startedAt: completionStartedAt, feel: nil)
                                    presentLittleWinOrFinish()
                                }
                            } else {
                                FGPrimaryButton(title: savedProgress == nil ? "Start" : "Resume") {
                                    startOrResumeSession()
                                }
                            }
                            HStack(spacing: FGSpace.m) {
                                FGQuietButton("Edit", systemImage: "pencil") {
                                    isEditing = true
                                }
                                FGQuietButton("Remove", systemImage: "minus.circle") {
                                    isConfirmingRemoval = true
                                }
                            }
                        }
                        .padding(.top, FGSpace.s)
                    } else {
                        VStack(spacing: FGSpace.s) {
                            FGPrimaryButton(title: savedProgress == nil ? "Start" : "Resume") {
                                startOrResumeSession()
                            }
                            FGQuietButton("Don't suggest this again", systemImage: "eye.slash") {
                                isConfirmingHide = true
                            }
                        }
                        .padding(.top, FGSpace.s)
                    }
                }
                .padding(FGSpace.page)
            }
        }
        .fullScreenCover(isPresented: $isPlaying, onDismiss: handlePlayerDismiss) {
            PlayerView(
                session: session,
                progress: savedProgress,
                glossary: model.store.glossary,
                onFinish: { result in
                    switch result {
                    case .completed(let feel):
                        Analytics.capture("workout_completed", properties: workoutProperties)
                        OneSignalManager.shared.trackSessionCompleted(
                            sessionID: session.id,
                            startedAt: startedAt
                        )
                        model.complete(session, startedAt: startedAt, feel: feel)
                        completedPlayerSession = true
                    case .paused:
                        // PlayerView reports and persists the interruption at
                        // the moment Pause or Leave is tapped.
                        break
                    }
                    shouldCloseAfterPlayer = true
                    isPlaying = false
                },
                onPause: { progress in
                    model.pause(session, at: progress)
                    OneSignalManager.shared.trackSessionPaused(
                        sessionID: session.id,
                        startedAt: progress.startedAt
                    )
                },
                onResume: { progress in
                    OneSignalManager.shared.trackSessionResumed(
                        sessionID: session.id,
                        startedAt: progress.startedAt
                    )
                },
                startedAt: startedAt
            )
        }
        .sheet(item: $littleWinCelebration, onDismiss: finishCompletedSession) { celebration in
            LittleWinCelebrationView(celebration: celebration)
                .presentationDetents([.large])
                .presentationDragIndicator(.hidden)
        }
        .sheet(item: $explaining) { term in
            GlossarySheet(term: term)
        }
        .sheet(isPresented: $isEditing) {
            AddRoutineSheet(model: model, editingSession: session) { updated in
                session = updated
            }
        }
        .confirmationDialog(
            "Remove \(session.title)?",
            isPresented: $isConfirmingRemoval,
            titleVisibility: .visible
        ) {
            Button("Remove", role: .destructive) {
                trackDiscardIfNeeded()
                model.forget(session)
                dismiss()
            }
            Button("Keep it", role: .cancel) {}
        } message: {
            Text("It stops being offered. The times you did it still count.")
        }
        .confirmationDialog(
            "Don't suggest this again?",
            isPresented: $isConfirmingHide,
            titleVisibility: .visible
        ) {
            Button("Hide this exercise", role: .destructive) {
                Analytics.capture("session_hidden", properties: ["session_id": session.id, "title": session.title])
                trackDiscardIfNeeded()
                model.hide(session)
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("We won't suggest '\(session.title)' on your menu anymore. You can review or unhide it anytime from your Profile.")
        }
        .presentationDragIndicator(.visible)
    }

    private var savedProgress: SessionProgress? {
        model.progress(for: session)
    }

    private var course: Course { session.course }

    private func startOrResumeSession() {
        Analytics.capture("workout_started", properties: workoutProperties)
        if let progress = savedProgress {
            startedAt = progress.startedAt
            OneSignalManager.shared.trackSessionResumed(
                sessionID: session.id,
                startedAt: progress.startedAt
            )
        } else {
            startedAt = Date()
        }
        isPlaying = true
    }

    private func trackDiscardIfNeeded() {
        guard let progress = savedProgress else { return }
        OneSignalManager.shared.trackSessionDiscarded(
            sessionID: session.id,
            startedAt: progress.startedAt
        )
    }

    private func handlePlayerDismiss() {
        guard shouldCloseAfterPlayer else { return }
        shouldCloseAfterPlayer = false
        if completedPlayerSession {
            completedPlayerSession = false
            presentLittleWinOrFinish()
        } else {
            dismiss()
        }
    }

    private func presentLittleWinOrFinish() {
        guard let celebration = model.takePendingLittleWinCelebration() else {
            finishCompletedSession()
            return
        }

        // When the player has just closed, give its full-screen presentation
        // one run-loop turn to finish before asking SwiftUI to present the
        // celebration sheet. Presenting both in the same transaction can make
        // the badge silently fail to appear.
        Task { @MainActor in
            await Task.yield()
            littleWinCelebration = celebration
        }
    }

    private func finishCompletedSession() {
        OneSignalManager.shared.setInAppTrigger(
            key: "session_completed",
            value: "true"
        )
        onCompleted()
        dismiss()
    }

    /// `session.chips` minus target area, which is already spelled out in the
    /// title above — showing it twice is the "same thing" this screen used
    /// to repeat.
    private var detailChips: [String] {
        if session.isOwn {
            return [session.durationLabel]
        }
        var pills = session.equipment.compactMap(\.label)
        pills.append(session.durationLabel)
        pills.append(session.impactLabel)
        return pills
    }

    private var workoutProperties: [String: Any] {
        [
            "session_id": session.id,
            "activity": session.activity.rawValue,
            "course": course.rawValue,
            "duration_minutes": session.durationMin,
            "is_saved_workout": session.isOwn
        ]
    }

    /// The title is the screen — carried on the same gradient and mascot as
    /// the card that offered it, so opening a session doesn't drop the color
    /// story it walked in with. Whoever wants the "why" gets it here, since
    /// the card upstream stayed to a title.
    private var heading: some View {
        HStack(alignment: .top, spacing: FGSpace.m) {
            VStack(alignment: .leading, spacing: FGSpace.s) {
                Text(course.label.uppercased())
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(course.accentText)
                    .padding(.horizontal, 11)
                    .padding(.vertical, 5)
                    .background(Color.white.opacity(colorScheme == .dark ? 0.20 : 0.88))
                    .clipShape(Capsule())

                Text(session.title)
                    .font(FGFont.display)
                    .foregroundStyle(course.accentText)
                    .fixedSize(horizontal: false, vertical: true)

                if let explanation {
                    Text(explanation)
                        .font(FGFont.reason)
                        .foregroundStyle(course.accentText.opacity(0.78))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Image(course.menuMascotAsset)
                .resizable()
                .scaledToFit()
                .frame(width: 72, height: 72)
                .accessibilityHidden(true)
        }
        .padding(FGSpace.l)
        .background(course.accentGradient)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }

    /// The session's own blurb if it has one, otherwise the reason this was
    /// recommended — the same fallback the card upstream used to show.
    private var explanation: String? {
        if !session.subtitle.isEmpty { return session.subtitle }
        guard let reasonText, !reasonText.isEmpty else { return nil }
        return reasonText
    }

    /// Closed by default. Someone deciding whether to start needs the title and
    /// the length; the breakdown is for whoever wants to know before they say
    /// yes, and it should cost them one tap rather than everyone else a screen.
    private var lineup: some View {
        VStack(alignment: .leading, spacing: FGSpace.s) {
            Button {
                isShowingSteps.toggle()
            } label: {
                HStack(spacing: FGSpace.s) {
                    Text("What you'll do")
                        .font(FGFont.body.weight(.medium))
                        .foregroundStyle(FGColor.ink)
                    Spacer(minLength: FGSpace.s)
                    Text(partsLabel)
                        .font(FGFont.body)
                        .foregroundStyle(FGColor.inkMuted)
                    Image(systemName: "chevron.right")
                        .font(FGFont.body.weight(.semibold))
                        .foregroundStyle(FGColor.inkMuted)
                        .rotationEffect(.degrees(isShowingSteps ? 90 : 0))
                }
                .frame(minHeight: FGSize.minTouchTarget)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("What you'll do, \(partsLabel)")
            .accessibilityValue(isShowingSteps ? "Expanded" : "Collapsed")
            .accessibilityHint(isShowingSteps ? "Hides the steps" : "Shows the steps")

            if isShowingSteps {
                steps
                    .padding(.top, FGSpace.xs)
            }
        }
        .fgAnimation(FGMotion.gentle, value: isShowingSteps)
    }

    /// Tinted to the course's own accent, not a fixed colour — so this
    /// screen never argues with the tag it just walked in from.
    private func firstUpSection(_ firstStep: Step) -> some View {
        HStack(alignment: .center, spacing: FGSpace.m) {
            ZStack {
                Circle()
                    .fill(course.tagFill)
                    .frame(width: 40, height: 40)
                Image(systemName: "record.circle")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(course.tagText)
            }
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 3) {
                Text("FIRST UP")
                    .font(FGFont.label.weight(.bold))
                    .tracking(0.5)
                    .foregroundStyle(course.tagText)

                Text("\(stepCost(firstStep)) \(firstStep.name.lowercased())")
                    .font(FGFont.body)
                    .foregroundStyle(FGColor.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, FGSpace.xs)
    }

    private func stepCost(_ step: Step) -> String {
        if step.isCounted, let reps = step.reps {
            return step.setCount > 1 ? "\(step.setCount) × \(reps)" : "\(reps) reps"
        }
        return "\(max(1, step.seconds / 60)) min"
    }

    private var partsLabel: String {
        let count = session.source.steps.count
        return count == 1 ? "1 part" : "\(count) parts"
    }

    private var steps: some View {
        VStack(alignment: .leading, spacing: FGSpace.s) {
            ForEach(Array(session.source.steps.enumerated()), id: \.offset) { _, step in
                HStack(alignment: .firstTextBaseline, spacing: FGSpace.s) {
                    Text(step.name)
                        .font(FGFont.body)
                        .foregroundStyle(FGColor.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    // The only route into the glossary is a step already
                    // on screen. It is never browsable.
                    if let term = model.term(for: step) {
                        Button {
                            explaining = term
                        } label: {
                            Image(systemName: "questionmark.circle")
                                .foregroundStyle(FGColor.goldDeep)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("What is \(step.name)?")
                    }
                    Spacer(minLength: FGSpace.s)
                    // A counted step is measured in reps, not minutes — the
                    // number is what somebody is deciding about before they
                    // start, so it is what the preview shows.
                    Text(stepCost(step))
                        .font(FGFont.label)
                        .foregroundStyle(FGColor.inkMuted)
                }
            }
        }
    }
}

/// Plain steps, plain language. No gym taxonomy, no photography.
struct GlossarySheet: View {
    let term: ExerciseTerm

    var body: some View {
        ZStack {
            FGColor.bg.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: FGSpace.m) {
                    Text(term.name)
                        .font(FGFont.title)
                        .foregroundStyle(FGColor.ink)

                    VStack(alignment: .leading, spacing: FGSpace.s) {
                        ForEach(Array(term.instructions.enumerated()), id: \.offset) { _, line in
                            Text(line)
                                .font(FGFont.body)
                                .foregroundStyle(FGColor.ink)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }

                    if !term.muscles.isEmpty {
                        Text("Works: \(term.muscles.joined(separator: ", "))")
                            .font(FGFont.reason)
                            .foregroundStyle(FGColor.inkMuted)
                    }
                }
                .padding(FGSpace.page)
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}
