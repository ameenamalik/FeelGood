//
//  CheckInSheet.swift
//  FeelGood
//
//  Two taps, ten seconds. The third and fourth are optional and stay optional —
//  the app never blocks on input, and there is no way to answer this wrongly.
//
//  One page that grows. The first question is all there is until it is
//  answered, then the next arrives underneath it. That keeps the "one thing at
//  a time" feel without paging: nothing is hidden behind a Back button, every
//  answer stays on screen where it can be changed, and the page getting longer
//  is the only progress indicator the sheet needs.
//
//  Each answer is a soft wash rather than an icon on white. Which wash an
//  answer gets means nothing — see the note above `checkInAura` in Palette.
//

import SwiftUI
import PostHog

struct CheckInSheet: View {
    let current: PlanCheckIn?
    let currentCalendarOpening: CalendarOpening?
    let isProUser: Bool
    let preferredTime: TimeOfDay
    let realisticMinutes: Int
    private let calendarProvider: any CalendarAvailabilityProviding
    let onDone: (PlanCheckIn, CalendarOpening?, CalendarMovementPlan?) -> Void

    @State private var energy: Energy?
    @State private var time: TimeBudget?
    @State private var place: PlaceIntent?
    @State private var bodies: Set<BodyState>
    @State private var calendarOpening: CalendarOpening?
    @State private var selectedCalendarOpening: CalendarOpening?
    @State private var calendarConnectionState: CalendarConnectionState
    @State private var isLoadingCalendar = false
    @State private var calendarLoadFailed = false
    @State private var movementPlan: CalendarMovementPlan?
    @State private var confirmedMovementPlan: CalendarMovementPlan?
    @State private var isLoadingMovementPlans = false
    @State private var isShowingPaywall = false
    @AppStorage(CalendarMovementPreferences.recognitionEnabledKey)
    private var isMovementRecognitionEnabled = false
    /// How many questions are on screen. Only ever grows within a sitting —
    /// taking an answer back must not make a question you have already seen
    /// disappear out from under you.
    @State private var revealed: Int
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(PurchasesManager.self) private var purchasesManager

    init(
        current: PlanCheckIn?,
        currentCalendarOpening: CalendarOpening? = nil,
        isProUser: Bool = false,
        preferredTime: TimeOfDay = .varies,
        realisticMinutes: Int = 20,
        calendarProvider: any CalendarAvailabilityProviding = EventKitCalendarAvailabilityService.shared,
        onDone: @escaping (PlanCheckIn, CalendarOpening?, CalendarMovementPlan?) -> Void
    ) {
        self.current = current
        self.currentCalendarOpening = currentCalendarOpening
        self.isProUser = isProUser
        self.preferredTime = preferredTime
        self.realisticMinutes = realisticMinutes
        self.calendarProvider = calendarProvider
        self.onDone = onDone
        _energy = State(initialValue: current?.energy)
        _time = State(initialValue: current?.time)
        _place = State(initialValue: current?.place)
        _bodies = State(initialValue: current?.bodies ?? [])
        _calendarOpening = State(initialValue: currentCalendarOpening)
        _selectedCalendarOpening = State(initialValue: currentCalendarOpening)
        _calendarConnectionState = State(initialValue: calendarProvider.connectionState)
        _movementPlan = State(initialValue: nil)
        _confirmedMovementPlan = State(initialValue: nil)
        // Coming back to change one answer should not re-run the reveal — the
        // whole sheet is already yours at that point.
        _revealed = State(initialValue: current == nil ? 1 : CheckInFlow.stepCount)
    }

    var body: some View {
        ZStack {
            FGColor.bg.ignoresSafeArea()

            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: FGSpace.xl) {
                        title

                        energyQuestion(proxy)
                        if revealed > 1 { timeQuestion(proxy) }
                        if revealed > 2 { placeQuestion(proxy) }
                        if revealed > 3 { bodyQuestion }

                        footer
                    }
                    .padding(FGSpace.page)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .scrollBounceBehavior(.basedOnSize)
            }
        }
        .fgAnimation(FGMotion.settle, value: revealed)
        .sensoryFeedback(.selection, trigger: selection)
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .sheet(isPresented: $isShowingPaywall) {
            FeelGoodPaywallView()
        }
        .task { await loadCalendarContextIfConnected() }
        .onChange(of: isMovementRecognitionEnabled) { _, isEnabled in
            if isEnabled {
                Task { await loadMovementPlansIfEnabled() }
            } else {
                movementPlan = nil
                confirmedMovementPlan = nil
            }
        }
    }

    // MARK: Questions

    private var title: some View {
        Text("How's today?")
            .font(FGFont.title)
            .foregroundStyle(FGColor.ink)
            .accessibilityAddTraits(.isHeader)
    }

    private func energyQuestion(_ proxy: ScrollViewProxy) -> some View {
        question("How's your energy?", index: 0) {
            ForEach(Energy.allCases, id: \.self) { option in
                FGPill(
                    title: option.checkInLabel,
                    selectedAura: option.checkInAura,
                    isSelected: energy == option
                ) {
                    energy = option
                    reveal(after: 0, didAnswer: true, using: proxy)
                }
            }
        }
    }

    private func timeQuestion(_ proxy: ScrollViewProxy) -> some View {
        VStack(alignment: .leading, spacing: FGSpace.m) {
            Text("How much time, really?")
                .font(FGFont.itemTitle)
                .foregroundStyle(FGColor.ink)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)

            calendarContext(using: proxy)
                .postHogMask()

            TimeBudgetScale(selection: time) { option in
                time = option
                selectedCalendarOpening = nil
                reveal(after: 1, didAnswer: true, using: proxy)
            }
            .postHogMask()
        }
        .id(1)
        .transition(
            reduceMotion
                ? .opacity
                : .opacity.combined(with: .offset(y: 16))
        )
    }

    @ViewBuilder
    private func calendarContext(using proxy: ScrollViewProxy) -> some View {
        if hasProAccess {
            switch calendarConnectionState {
            case .notRequested:
                calendarCard(
                    title: "Work around your day",
                    detail: "Use today's event times on this device to find a realistic opening.",
                    buttonTitle: "Connect Calendar"
                ) {
                    Task { await connectCalendar() }
                }

            case .connected:
                movementRecognitionToggle
                movementPlanContext

                if isLoadingCalendar {
                    HStack(spacing: FGSpace.s) {
                        ProgressView()
                        Text("Looking for an opening in today…")
                            .font(FGFont.caption)
                            .foregroundStyle(FGColor.inkMuted)
                    }
                    .padding(.horizontal, FGSpace.s)
                } else if let calendarOpening {
                    let message = calendarMessage(for: calendarOpening)
                    calendarCard(
                        title: message.title,
                        detail: message.detail,
                        buttonTitle: "Choose \(calendarOpening.budget.maxMinutes) minutes",
                        isSelected: selectedCalendarOpening == calendarOpening
                    ) {
                        time = calendarOpening.budget
                        selectedCalendarOpening = calendarOpening
                        reveal(after: 1, didAnswer: true, using: proxy)
                    }
                } else if calendarLoadFailed {
                    calendarStatus("Calendar couldn't be checked. Choose a time below.")
                } else {
                    calendarStatus("No clear opening left today. Choose what feels realistic below.")
                }

            case .denied:
                calendarStatus("Calendar access is off. You can still choose a time below.")
            }
        } else {
            calendarCard(
                title: "Work around your day",
                detail: "FeelGood Pro can use today’s Calendar openings to suggest a realistic time.",
                buttonTitle: "See FeelGood Pro"
            ) {
                isShowingPaywall = true
            }
        }
    }

    private var movementRecognitionToggle: some View {
        Toggle(isOn: $isMovementRecognitionEnabled) {
            VStack(alignment: .leading, spacing: 3) {
                Text("Recognize movement plans")
                    .font(FGFont.body.weight(.semibold))
                    .foregroundStyle(FGColor.ink)
                Text("Uses event names only on this device to spot workouts and classes.")
                    .font(FGFont.caption)
                    .foregroundStyle(FGColor.inkMuted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .tint(FGColor.controlAccent)
        .padding(FGSpace.m)
        .background(
            RoundedRectangle(cornerRadius: FGRadius.card, style: .continuous)
                .fill(FGColor.surface)
        )
        .postHogMask()
    }

    @ViewBuilder
    private var movementPlanContext: some View {
        if isMovementRecognitionEnabled {
            if isLoadingMovementPlans {
                calendarStatus("Looking for movement already planned today…")
            } else if let movementPlan {
                movementPlanCard(movementPlan)
            }
        }
    }

    private func movementPlanCard(_ plan: CalendarMovementPlan) -> some View {
        let hasEnded = plan.end <= Date()
        let isHappeningNow = plan.start <= Date() && !hasEnded

        return VStack(alignment: .leading, spacing: FGSpace.s) {
            HStack(spacing: FGSpace.xs) {
                Image(systemName: "figure.mind.and.body")
                Text(movementPlanTitle(plan, hasEnded: hasEnded, isHappeningNow: isHappeningNow))
            }
            .font(FGFont.body.weight(.semibold))
            .foregroundStyle(FGColor.ink)

            Text(movementPlanDetail(plan, hasEnded: hasEnded))
                .font(FGFont.caption)
                .foregroundStyle(FGColor.inkMuted)
                .fixedSize(horizontal: false, vertical: true)

            if hasEnded {
                WrapRow(spacing: FGSpace.s, lineSpacing: FGSpace.s) {
                    FGPill(
                        title: "Yes, count it",
                        selectedAura: .sage,
                        isSelected: confirmedMovementPlan == plan
                    ) {
                        confirmedMovementPlan = confirmedMovementPlan == plan ? nil : plan
                    }
                    FGPill(title: "Didn't happen", isSelected: false) {
                        dismissMovementPlan(plan)
                    }
                    FGPill(title: "Not movement", isSelected: false) {
                        dismissMovementPlan(plan)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(FGSpace.m)
        .background(
            RoundedRectangle(cornerRadius: FGRadius.card, style: .continuous)
                .fill(FGColor.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: FGRadius.card, style: .continuous)
                .strokeBorder(confirmedMovementPlan == plan ? FGColor.ink : FGColor.lineStrong, lineWidth: 1)
        )
        .postHogMask()
        .accessibilityElement(children: .contain)
    }

    private func movementPlanTitle(
        _ plan: CalendarMovementPlan,
        hasEnded: Bool,
        isHappeningNow: Bool
    ) -> String {
        if hasEnded { return "Did your \(plan.activity.label.lowercased()) session happen?" }
        if isHappeningNow { return "Movement is on your calendar now" }
        return "Movement is already on your calendar"
    }

    private func movementPlanDetail(_ plan: CalendarMovementPlan, hasEnded: Bool) -> String {
        if hasEnded {
            return "Confirm it before FeelGood counts it. Calendar plans are never logged automatically."
        }
        return "A \(plan.activity.label.lowercased()) session is planned for \(plan.start.formatted(date: .omitted, time: .shortened)). Choose time below only if you want something extra."
    }

    private func dismissMovementPlan(_ plan: CalendarMovementPlan) {
        CalendarMovementPreferences.markHandled(plan.id)
        confirmedMovementPlan = nil
        movementPlan = nil
    }

    private func calendarCard(
        title: String,
        detail: String,
        buttonTitle: String,
        isSelected: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: FGSpace.s) {
            HStack(spacing: FGSpace.xs) {
                Image(systemName: "calendar")
                Text(title)
            }
            .font(FGFont.body.weight(.semibold))
            .foregroundStyle(FGColor.ink)

            Text(detail)
                .font(FGFont.caption)
                .foregroundStyle(FGColor.inkMuted)
                .fixedSize(horizontal: false, vertical: true)

            Button(buttonTitle, action: action)
                .font(FGFont.caption.weight(.semibold))
                .foregroundStyle(FGColor.inkOnAccent)
                .padding(.horizontal, FGSpace.m)
                .frame(minHeight: FGSize.minTouchTarget)
                .background(Capsule().fill(FGColor.gold))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(FGSpace.m)
        .background(
            RoundedRectangle(cornerRadius: FGRadius.card, style: .continuous)
                .fill(FGColor.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: FGRadius.card, style: .continuous)
                .strokeBorder(isSelected ? FGColor.ink : FGColor.lineStrong, lineWidth: isSelected ? 1.5 : 1)
        )
        .accessibilityElement(children: .contain)
    }

    private func calendarStatus(_ text: String) -> some View {
        HStack(alignment: .top, spacing: FGSpace.s) {
            Image(systemName: "calendar")
                .accessibilityHidden(true)
            Text(text)
                .font(FGFont.caption)
        }
        .foregroundStyle(FGColor.inkMuted)
        .padding(.horizontal, FGSpace.s)
    }

    private func placeQuestion(_ proxy: ScrollViewProxy) -> some View {
        question("Where are you today?", index: 2, isOptional: true) {
            ForEach(PlaceIntent.allCases, id: \.self) { option in
                FGPill(
                    title: option.checkInLabel,
                    selectedAura: option.checkInAura,
                    isSelected: place == option
                ) {
                    // Tapping the answer you already gave takes it back.
                    // Un-answering must not reveal the next question — see
                    // `CheckInFlow.next`.
                    let wasSelected = place == option
                    place = wasSelected ? nil : option
                    reveal(after: 2, didAnswer: !wasSelected, using: proxy)
                }
            }
        }
        .overlay(alignment: .topTrailing) {
            // The only question that needs a way past it: the last one is
            // already followed by the button that ends the sheet.
            if revealed == 3 {
                Button("Skip") { reveal(after: 2, didAnswer: true, using: proxy) }
                    .font(FGFont.caption)
                    .foregroundStyle(FGColor.inkMuted)
            }
        }
    }

    private var bodyQuestion: some View {
        question("Anything going on in your body?", index: 3, isOptional: true) {
            ForEach(BodyState.allCases, id: \.self) { option in
                FGPill(
                    title: option.checkInLabel,
                    selectedAura: option.checkInAura,
                    isSelected: bodies.contains(option)
                ) {
                    toggleBody(option)
                }
            }
        }
    }

    /// One question and its answers. `index` doubles as the scroll target, so
    /// a newly revealed question can be brought into view.
    private func question<Options: View>(
        _ text: String,
        index: Int,
        isOptional: Bool = false,
        @ViewBuilder options: () -> Options
    ) -> some View {
        VStack(alignment: .leading, spacing: FGSpace.m) {
            Text(text)
                .font(FGFont.itemTitle)
                .foregroundStyle(isOptional ? FGColor.inkMuted : FGColor.ink)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)

            WrapRow(spacing: FGSpace.s, lineSpacing: FGSpace.s) { options() }
                .postHogMask()
        }
        .id(index)
        .transition(
            reduceMotion
                ? .opacity
                : .opacity.combined(with: .offset(y: 16))
        )
    }

    // MARK: Footer

    @ViewBuilder
    private var footer: some View {
        VStack(spacing: FGSpace.s) {
            // Appears as soon as there is enough to build a menu from, rather
            // than waiting for the optional questions to be dealt with.
            if energy != nil, time != nil {
                FGPrimaryButton(title: "Show me today") { finish() }
            }

            FGQuietButton("Skip — just show me something") { finish() }
                .frame(maxWidth: .infinity)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: Behaviour

    /// Brings the next question onto the page and scrolls to it.
    ///
    /// `didAnswer` is false when the tap cleared an answer rather than giving
    /// one; nothing new appears in that case.
    private func reveal(after index: Int, didAnswer: Bool, using proxy: ScrollViewProxy) {
        guard let next = CheckInFlow.next(after: index, didAnswer: didAnswer) else { return }
        guard next >= revealed else { return }

        revealed = next + 1

        guard !reduceMotion else {
            proxy.scrollTo(next, anchor: .center)
            return
        }

        withAnimation(FGMotion.settle) {
            proxy.scrollTo(next, anchor: .center)
        }
    }

    /// Every answer as it actually stands, including the unanswered ones. The
    /// defaults in `plan` would swallow the first tap on "Steady" — nothing
    /// would appear to change — so haptics key off this instead.
    private var selection: [String?] {
        let selectedBodies = bodies.map(\.rawValue).sorted().joined(separator: ",")
        return [energy?.rawValue, time?.rawValue, place?.rawValue, selectedBodies.isEmpty ? nil : selectedBodies]
    }

    /// What gets handed back: the unanswered questions fall back to the middle,
    /// because skipping is always allowed to produce a menu.
    private var plan: PlanCheckIn {
        PlanCheckIn(energy: energy ?? .steady, time: time ?? .some, place: place, bodies: bodies)
    }

    private func finish() {
        // The body answers are handed over and dropped: `CheckInAnalytics` has nowhere to
        // put it. That is the whole point of the type — see its header.
        Analytics.capture(
            CheckInAnalytics(energy: energy, time: time, place: place, bodies: bodies)
        )
        onDone(plan, selectedCalendarOpening, confirmedMovementPlan)
    }

    private func toggleBody(_ option: BodyState) {
        if bodies.contains(option) {
            bodies.remove(option)
        } else if option == .good {
            bodies = [.good]
        } else {
            bodies.remove(.good)
            bodies.insert(option)
        }
    }

    private func connectCalendar() async {
        calendarConnectionState = await calendarProvider.requestAccess()
        await loadCalendarContextIfConnected()
    }

    private func loadCalendarContextIfConnected() async {
        await loadCalendarOpeningIfConnected()
        await loadMovementPlansIfEnabled()
    }

    private func loadMovementPlansIfEnabled() async {
        guard
            hasProAccess,
            calendarConnectionState == .connected,
            isMovementRecognitionEnabled
        else { return }

        isLoadingMovementPlans = true
        defer { isLoadingMovementPlans = false }

        do {
            let now = Date()
            let plans = try await calendarProvider.movementPlans(on: now, calendar: .current)
                .filter { !CalendarMovementPreferences.isHandled($0.id) }
            movementPlan = plans
                .filter { $0.end <= now }
                .max { $0.end < $1.end }
                ?? plans.filter { $0.end > now }.min { $0.start < $1.start }
        } catch {
            movementPlan = nil
        }
    }

    private func loadCalendarOpeningIfConnected() async {
        guard hasProAccess, calendarConnectionState == .connected else { return }
        isLoadingCalendar = true
        calendarLoadFailed = false
        defer { isLoadingCalendar = false }

        do {
            calendarOpening = try await calendarProvider.suggestedOpening(
                on: Date(),
                preferredTime: preferredTime,
                realisticMinutes: realisticMinutes,
                calendar: .current
            )
        } catch {
            calendarOpening = nil
            calendarLoadFailed = true
        }
    }

    private func openingPhrase(_ opening: CalendarOpening) -> String {
        let hour = Calendar.current.component(.hour, from: opening.start)
        if (11..<14).contains(hour) { return "around lunch" }
        return "around \(opening.start.formatted(date: .omitted, time: .shortened))"
    }

    private func calendarMessage(for opening: CalendarOpening) -> (title: String, detail: String) {
        let suggestion = "Plans change—would \(opening.budget.maxMinutes) minutes feel realistic?"
        switch opening.context {
        case .beforeNextEvent:
            return ("Some space before your next event", suggestion)
        case .openForRestOfDay:
            return ("Your calendar looks open for the rest of today", suggestion)
        case .openToday:
            return ("Your calendar looks open today", suggestion)
        case .uncertain:
            return ("A possible opening \(openingPhrase(opening))", suggestion)
        }
    }

    private var hasProAccess: Bool {
        isProUser || purchasesManager.isProUnlocked
    }
}

/// A clean time slider that maps its smooth visual track onto the durations
/// supported by the planning engine. It deliberately has no thumb until the
/// person chooses, so an unanswered check-in never looks prefilled.
private struct TimeBudgetScale: View {
    let selection: TimeBudget?
    let onSelect: (TimeBudget) -> Void

    private let options = TimeBudget.allCases
    @State private var previewSelection: TimeBudget?
    @State private var dragProgress: CGFloat?

    init(selection: TimeBudget?, onSelect: @escaping (TimeBudget) -> Void) {
        self.selection = selection
        self.onSelect = onSelect
        _previewSelection = State(initialValue: selection)
    }

    var body: some View {
        VStack(spacing: FGSpace.s) {
            if let activeSelection {
                Text(compactLabel(for: activeSelection))
                    .font(FGFont.body.weight(.semibold))
                    .foregroundStyle(FGColor.clayDeep)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            GeometryReader { geometry in
                let sideInset: CGFloat = 12
                let trackWidth = max(geometry.size.width - (sideInset * 2), 1)
                let thumbProgress = activeProgress ?? 0

                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(FGColor.lineStrong.opacity(0.35))
                        .frame(width: trackWidth, height: 5)
                        .offset(x: sideInset)

                    if let activeProgress {
                        Capsule()
                            .fill(FGColor.clayDeep)
                            .frame(width: trackWidth * activeProgress, height: 5)
                            .offset(x: sideInset)
                    }

                    Circle()
                        .fill(activeSelection == nil ? FGColor.surface : FGColor.clay)
                        .frame(width: 24, height: 24)
                        .overlay {
                            Circle()
                                .strokeBorder(
                                    activeSelection == nil ? FGColor.lineStrong : FGColor.clayDeep,
                                    lineWidth: 2
                                )
                        }
                        .shadow(color: FGColor.ink.opacity(0.12), radius: 3, y: 1)
                        .position(
                            x: sideInset + (trackWidth * thumbProgress),
                            y: geometry.size.height / 2
                        )
                }
                .contentShape(Rectangle())
                .simultaneousGesture(
                    SpatialTapGesture()
                        .onEnded { value in
                            select(at: value.location.x, width: geometry.size.width)
                        }
                )
                .simultaneousGesture(
                    DragGesture(minimumDistance: 8)
                        .onChanged { value in
                            let progress = progress(at: value.location.x, width: geometry.size.width)
                            dragProgress = progress
                            previewSelection = option(for: progress)
                        }
                        .onEnded { value in
                            select(at: value.location.x, width: geometry.size.width)
                        }
                )
            }
            .frame(height: FGSize.minTouchTarget)

            HStack {
                Text("Rest")
                Spacer()
                Text("1 hr")
            }
            .font(FGFont.caption)
            .foregroundStyle(FGColor.inkMuted)
        }
        .padding(.vertical, FGSpace.xs)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Available time")
        .accessibilityValue(selection?.checkInLabel ?? "Not selected")
        .accessibilityHint("Swipe up or down to change the number of minutes")
        .accessibilityAdjustableAction(adjustSelection)
        .onChange(of: selection) { _, newSelection in
            previewSelection = newSelection
            dragProgress = nil
        }
    }

    private var activeSelection: TimeBudget? {
        previewSelection ?? selection
    }

    private func compactLabel(for option: TimeBudget) -> String {
        if option.isZero {
            return "Rest day (0 min)"
        }
        return option.maxMinutes == 60 ? "1 hr" : "\(option.maxMinutes) min"
    }

    private var activeProgress: CGFloat? {
        if let dragProgress { return dragProgress }
        guard
            let activeSelection,
            let index = options.firstIndex(of: activeSelection),
            options.count > 1
        else { return nil }
        return CGFloat(index) / CGFloat(options.count - 1)
    }

    private func progress(at xPosition: CGFloat, width: CGFloat) -> CGFloat {
        let sideInset: CGFloat = 12
        let trackWidth = max(width - (sideInset * 2), 1)
        return min(max((xPosition - sideInset) / trackWidth, 0), 1)
    }

    private func option(for progress: CGFloat) -> TimeBudget {
        let index = Int((progress * CGFloat(options.count - 1)).rounded())
        return options[index]
    }

    private func select(at xPosition: CGFloat, width: CGFloat) {
        let option = option(for: progress(at: xPosition, width: width))
        previewSelection = option
        dragProgress = nil
        onSelect(option)
    }

    private func adjustSelection(_ direction: AccessibilityAdjustmentDirection) {
        let currentIndex = selection.flatMap { options.firstIndex(of: $0) }
        let nextIndex: Int

        switch direction {
        case .increment:
            nextIndex = min((currentIndex ?? -1) + 1, options.count - 1)
        case .decrement:
            nextIndex = max((currentIndex ?? options.count) - 1, 0)
        @unknown default:
            return
        }

        let option = options[nextIndex]
        previewSelection = option
        onSelect(option)
    }
}

#Preview("Empty") {
    CheckInSheet(current: nil) { _, _, _ in }
        .environment(PurchasesManager.shared)
}

#Preview("Answered") {
    CheckInSheet(
        current: PlanCheckIn(energy: .low, time: .aLittle, place: .stayingIn, body: .stiff)
    ) { _, _, _ in }
    .environment(PurchasesManager.shared)
}

#Preview("Aura tiles") {
    FlowRow.choices(isAccessibilitySize: false) {
        ForEach(Array(FGAura.allCases.enumerated()), id: \.offset) { _, aura in
            FGAuraTile(title: "Steady", detail: "20–30", aura: aura, isSelected: aura == .apricot) {}
        }
    }
    .padding(FGSpace.page)
    .background(FGColor.bg)
}
