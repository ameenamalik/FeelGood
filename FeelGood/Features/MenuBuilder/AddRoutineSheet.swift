//
//  AddRoutineSheet.swift
//  FeelGood
//
//  Sheet to write in and configure a custom routine for My Menu.
//

import SwiftUI
import PostHog

struct AddRoutineSheet: View {
    let model: TodayModel
    let initialCourse: Course
    let editingSession: Session?
    let onSaved: ((Session) -> Void)?

    @Environment(\.dismiss) private var dismiss
    @State private var title: String = ""
    @State private var sessionDescription: String = ""
    @State private var parts: [CustomRoutinePart] = []
    @State private var partTitle: String = ""
    @State private var partDurationMin: Int = 1
    @State private var course: Course
    @State private var activity: Activity = .yoga
    @State private var intensity: Int = 3
    @State private var addToToday: Bool = false
    @State private var isShowingCatalogPicker: Bool = false
    @FocusState private var isTitleFocused: Bool
    @FocusState private var isDescriptionFocused: Bool
    @FocusState private var isPartTitleFocused: Bool

    private static let partDurations = [1, 2, 3, 5, 10, 15, 20]
    private static let efforts: [(label: String, intensity: Int)] = [
        ("Easy", 2), ("Steady", 3), ("Hard", 4)
    ]

    init(
        model: TodayModel,
        initialCourse: Course = .main,
        editingSession: Session? = nil,
        onSaved: ((Session) -> Void)? = nil
    ) {
        self.model = model
        let startingCourse = editingSession?.course ?? initialCourse
        self.initialCourse = startingCourse
        self.editingSession = editingSession
        self.onSaved = onSaved
        _title = State(initialValue: editingSession?.title ?? "")
        _sessionDescription = State(initialValue: editingSession?.subtitle ?? "")
        if let editingSession {
            let savedParts = editingSession.customRoutineParts
            _parts = State(initialValue: savedParts.isEmpty
                ? [CustomRoutinePart(title: editingSession.title, durationMin: editingSession.durationMin)]
                : savedParts)
        } else {
            _parts = State(initialValue: [])
        }
        _course = State(initialValue: startingCourse)
        _activity = State(initialValue: editingSession?.activity ?? .yoga)
        _intensity = State(initialValue: editingSession?.intensity ?? 3)
        _addToToday = State(initialValue: editingSession.map { session in
            model.todayCustomOverrides.values.contains { $0.id == session.id }
        } ?? false)
    }

    private var isValid: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && parts.contains { !$0.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }

    private var totalDurationMin: Int { parts.reduce(0) { $0 + $1.durationMin } }

    var body: some View {
        NavigationStack {
            ZStack {
                FGColor.bg.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: FGSpace.xl) {
                        Text(editingSession == nil ? "Create a routine" : "Edit routine")
                            .font(FGFont.title)
                            .foregroundStyle(FGColor.ink)
                            .accessibilityAddTraits(.isHeader)

                        question("What should we call it?") {
                            TextField("e.g. Morning Sunlight Walk, 5-min Neck Release", text: $title)
                                .font(FGFont.body)
                                .foregroundStyle(FGColor.ink)
                                .textFieldStyle(.plain)
                                .textInputAutocapitalization(.sentences)
                                .focused($isTitleFocused)
                                .submitLabel(.done)
                                .padding(.horizontal, FGSpace.m)
                                .padding(.vertical, 12)
                                .background(FGColor.surface)
                                .clipShape(RoundedRectangle(cornerRadius: FGRadius.chip, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: FGRadius.chip, style: .continuous)
                                        .strokeBorder(isTitleFocused ? FGColor.clayDeep : FGColor.line, lineWidth: isTitleFocused ? 1.5 : 1)
                                )
                                .postHogMask()
                        }

                        question("Add a description (optional)") {
                            TextField("e.g. A gentle reset for tight shoulders", text: $sessionDescription, axis: .vertical)
                                .font(FGFont.body)
                                .foregroundStyle(FGColor.ink)
                                .textFieldStyle(.plain)
                                .textInputAutocapitalization(.sentences)
                                .lineLimit(2...4)
                                .focused($isDescriptionFocused)
                                .padding(.horizontal, FGSpace.m)
                                .padding(.vertical, 12)
                                .background(FGColor.surface)
                                .clipShape(RoundedRectangle(cornerRadius: FGRadius.chip, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: FGRadius.chip, style: .continuous)
                                        .strokeBorder(isDescriptionFocused ? FGColor.clayDeep : FGColor.line, lineWidth: isDescriptionFocused ? 1.5 : 1)
                                )
                                .postHogMask()
                        }

                        question("Add the parts") {
                            VStack(alignment: .leading, spacing: FGSpace.s) {
                                Text("Add one item at a time. You can stop whenever the routine feels complete.")
                                    .font(FGFont.caption)
                                    .foregroundStyle(FGColor.inkMuted)
                                    .fixedSize(horizontal: false, vertical: true)

                                ForEach($parts) { $part in
                                    HStack(spacing: FGSpace.s) {
                                        TextField("Part name", text: $part.title)
                                            .font(FGFont.body)
                                            .foregroundStyle(FGColor.ink)
                                            .textFieldStyle(.plain)
                                            .postHogMask()

                                        Picker("Duration", selection: $part.durationMin) {
                                            ForEach(Self.partDurations, id: \.self) { minutes in
                                                Text("\(minutes) min").tag(minutes)
                                            }
                                        }
                                        .pickerStyle(.menu)
                                        .tint(FGColor.inkMuted)

                                        Button {
                                            parts.removeAll { $0.id == part.id }
                                        } label: {
                                            Image(systemName: "minus.circle.fill")
                                                .foregroundStyle(FGColor.inkMuted)
                                                .frame(width: FGSize.minTouchTarget, height: FGSize.minTouchTarget)
                                        }
                                        .buttonStyle(.plain)
                                        .accessibilityLabel("Remove \(part.title)")
                                    }
                                    .padding(.leading, FGSpace.m)
                                    .background(FGColor.surface)
                                    .clipShape(RoundedRectangle(cornerRadius: FGRadius.chip, style: .continuous))
                                }

                                HStack(spacing: FGSpace.s) {
                                    TextField("Add a part", text: $partTitle)
                                        .font(FGFont.body)
                                        .foregroundStyle(FGColor.ink)
                                        .textFieldStyle(.plain)
                                        .textInputAutocapitalization(.sentences)
                                        .focused($isPartTitleFocused)
                                        .submitLabel(.done)
                                        .onSubmit(addPart)
                                        .postHogMask()

                                    Picker("Duration", selection: $partDurationMin) {
                                        ForEach(Self.partDurations, id: \.self) { minutes in
                                            Text("\(minutes) min").tag(minutes)
                                        }
                                    }
                                    .pickerStyle(.menu)
                                    .tint(FGColor.ink)

                                    Button(action: addPart) {
                                        Image(systemName: "plus.circle.fill")
                                            .font(.system(size: 24, weight: .semibold))
                                            .foregroundStyle(canAddPart ? FGColor.clayDeep : FGColor.inkMuted.opacity(0.45))
                                            .frame(width: FGSize.minTouchTarget, height: FGSize.minTouchTarget)
                                    }
                                    .buttonStyle(.plain)
                                    .disabled(!canAddPart)
                                    .accessibilityLabel("Add part")
                                }
                                .padding(.leading, FGSpace.m)
                                .background(FGColor.surface)
                                .clipShape(RoundedRectangle(cornerRadius: FGRadius.chip, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: FGRadius.chip, style: .continuous)
                                        .strokeBorder(isPartTitleFocused ? FGColor.clayDeep : FGColor.line, lineWidth: isPartTitleFocused ? 1.5 : 1)
                                )

                                if !parts.isEmpty {
                                    Text("\(parts.count) \(parts.count == 1 ? "part" : "parts") · \(totalDurationMin) min total")
                                        .font(FGFont.caption)
                                        .foregroundStyle(FGColor.inkMuted)
                                }
                            }
                        }

                        question("What kind of movement?") {
                            Picker("Movement", selection: $activity) {
                                ForEach(Activity.allCases, id: \.self) { option in
                                    Text(option.label).tag(option)
                                }
                            }
                            .pickerStyle(.menu)
                            .tint(FGColor.ink)
                            .font(FGFont.body.weight(.medium))
                            .frame(maxWidth: .infinity, minHeight: FGSize.minTouchTarget, alignment: .leading)
                            .padding(.horizontal, FGSpace.m)
                            .background(FGColor.surface)
                            .clipShape(RoundedRectangle(cornerRadius: FGRadius.chip, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: FGRadius.chip, style: .continuous)
                                    .strokeBorder(FGColor.line, lineWidth: 1)
                            )
                        }

                        question("Where does it belong?") {
                            WrapRow(spacing: FGSpace.s, lineSpacing: FGSpace.s) {
                                ForEach([Course.appetizer, Course.main, Course.side, Course.dessert], id: \.self) { c in
                                    FGPill(
                                        title: c.label,
                                        selectedAura: aura(for: c),
                                        isSelected: course == c
                                    ) {
                                        withAnimation(FGMotion.gentle) {
                                            course = c
                                        }
                                    }
                                }
                            }
                        }

                        question("How should it feel?") {
                            WrapRow(spacing: FGSpace.s, lineSpacing: FGSpace.s) {
                                ForEach(Self.efforts, id: \.intensity) { effort in
                                    FGPill(
                                        title: effort.label,
                                        selectedAura: effortAura(for: effort.intensity),
                                        isSelected: intensity == effort.intensity
                                    ) {
                                        withAnimation(FGMotion.gentle) { intensity = effort.intensity }
                                    }
                                }
                            }
                        }

                        Toggle(isOn: $addToToday) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Add to today’s menu")
                                    .font(FGFont.body.weight(.semibold))
                                    .foregroundStyle(FGColor.ink)
                                Text("Replaces today’s suggested \(course.label.lowercased()).")
                                    .font(FGFont.caption)
                                    .foregroundStyle(FGColor.inkMuted)
                            }
                        }
                        .tint(FGColor.controlAccent)
                        .padding(FGSpace.m)
                        .background(FGColor.surface)
                        .clipShape(RoundedRectangle(cornerRadius: FGRadius.card, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: FGRadius.card, style: .continuous)
                                .strokeBorder(FGColor.lineStrong.opacity(0.45), lineWidth: 1)
                        )

                        if editingSession == nil {
                            FGQuietButton("Pick an existing session instead", systemImage: "sparkles") {
                                isShowingCatalogPicker = true
                            }
                            .frame(maxWidth: .infinity)
                        }

                        FGPrimaryButton(title: editingSession == nil ? "Save routine" : "Save changes", isEnabled: isValid) {
                            saveRoutine()
                        }
                    }
                    .padding(FGSpace.page)
                }
                .scrollBounceBehavior(.basedOnSize)
                .scrollDismissesKeyboard(.interactively)
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(FGColor.ink)
                }
            }
            .sheet(isPresented: $isShowingCatalogPicker) {
                CatalogPickerSheet(model: model, preferredCourse: course) { pickedSession in
                    title = pickedSession.title
                    sessionDescription = pickedSession.subtitle
                    let pickedParts = pickedSession.source.steps.map {
                        CustomRoutinePart(title: $0.name, durationMin: max(1, Int(ceil(Double($0.seconds) / 60))))
                    }
                    parts = pickedParts.isEmpty
                        ? [CustomRoutinePart(title: pickedSession.title, durationMin: pickedSession.durationMin)]
                        : pickedParts
                    activity = pickedSession.activity
                    course = pickedSession.course
                    intensity = pickedSession.intensity
                }
            }
            .onAppear {
                if title.isEmpty {
                    isTitleFocused = true
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    private func question<Content: View>(
        _ prompt: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: FGSpace.m) {
            Text(prompt)
                .font(FGFont.itemTitle)
                .foregroundStyle(FGColor.ink)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)

            content()
        }
    }

    private func aura(for course: Course) -> FGAura {
        switch course {
        case .appetizer: .butter
        case .main: .apricot
        case .side: .sage
        case .dessert: .blush
        case .special: .lilac
        }
    }

    private func effortAura(for intensity: Int) -> FGAura {
        switch intensity {
        case ...2: .sage
        case 3: .apricot
        default: .blush
        }
    }

    private var canAddPart: Bool {
        !partTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func addPart() {
        let trimmed = partTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        withAnimation(FGMotion.gentle) {
            parts.append(CustomRoutinePart(title: trimmed, durationMin: partDurationMin))
        }
        partTitle = ""
        partDurationMin = 1
        isPartTitleFocused = true
    }

    private func saveRoutine() {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let trimmedDescription = sessionDescription.trimmingCharacters(in: .whitespacesAndNewlines)

        let description = trimmedDescription.isEmpty ? nil : trimmedDescription
        let cleanedParts = parts.compactMap { part -> CustomRoutinePart? in
            let partTitle = part.title.trimmingCharacters(in: .whitespacesAndNewlines)
            return partTitle.isEmpty ? nil : CustomRoutinePart(id: part.id, title: partTitle, durationMin: part.durationMin)
        }
        guard !cleanedParts.isEmpty else { return }
        let durationMin = cleanedParts.reduce(0) { $0 + $1.durationMin }
        let session: Session
        if let editingSession {
            guard let updated = model.updateCustomRoutine(
                editingSession,
                title: trimmed,
                description: description,
                parts: cleanedParts,
                activity: activity,
                durationMin: durationMin,
                intensity: intensity,
                course: course,
                addToToday: addToToday
            ) else { return }
            session = updated
        } else {
            session = model.addCustomRoutine(
                title: trimmed,
                description: description,
                parts: cleanedParts,
                activity: activity,
                durationMin: durationMin,
                intensity: intensity,
                course: course,
                addToToday: addToToday
            )
        }

        Analytics.capture(editingSession == nil ? "custom_routine_created" : "custom_routine_edited", properties: [
            "title": trimmed,
            "activity": activity.rawValue,
            "duration": durationMin,
            "course": course.rawValue,
            "added_to_today": addToToday
        ])

        onSaved?(session)
        dismiss()
    }
}
