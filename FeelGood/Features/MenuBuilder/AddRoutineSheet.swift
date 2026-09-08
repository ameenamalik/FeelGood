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
    let onSaved: ((Session) -> Void)?

    @Environment(\.dismiss) private var dismiss
    @State private var title: String = ""
    @State private var course: Course
    @State private var durationMin: Int = 15
    @State private var activity: Activity = .yoga
    @State private var intensity: Int = 3
    @State private var addToToday: Bool = false
    @State private var isShowingCatalogPicker: Bool = false
    @FocusState private var isTitleFocused: Bool

    private static let commonDurations = [2, 5, 10, 15, 20, 30, 45, 60]
    private static let efforts: [(label: String, intensity: Int)] = [
        ("Easy", 2), ("Steady", 3), ("Hard", 4)
    ]

    init(
        model: TodayModel,
        initialCourse: Course = .main,
        onSaved: ((Session) -> Void)? = nil
    ) {
        self.model = model
        self.initialCourse = initialCourse
        self.onSaved = onSaved
        _course = State(initialValue: initialCourse)
        // Default sensible duration based on course
        let defaultDuration: Int
        switch initialCourse {
        case .appetizer: defaultDuration = 5
        case .main: defaultDuration = 20
        case .side: defaultDuration = 10
        case .dessert: defaultDuration = 10
        case .special: defaultDuration = 45
        }
        _durationMin = State(initialValue: defaultDuration)
    }

    private var isValid: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            ZStack {
                FGColor.bg.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: FGSpace.xl) {
                        Text("Create a routine")
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
                                            if c == .appetizer && durationMin > 10 { durationMin = 5 }
                                            if c == .main && durationMin < 15 { durationMin = 20 }
                                        }
                                    }
                                }
                            }
                        }

                        question("How much time?") {
                            WrapRow(spacing: FGSpace.s, lineSpacing: FGSpace.s) {
                                ForEach(Self.commonDurations, id: \.self) { minutes in
                                    FGPill(
                                        title: "\(minutes) min",
                                        selectedAura: aura(for: course),
                                        isSelected: durationMin == minutes
                                    ) {
                                        withAnimation(FGMotion.gentle) { durationMin = minutes }
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
                        .tint(FGColor.clayDeep)
                        .padding(FGSpace.m)
                        .background(FGColor.surface)
                        .clipShape(RoundedRectangle(cornerRadius: FGRadius.card, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: FGRadius.card, style: .continuous)
                                .strokeBorder(FGColor.lineStrong.opacity(0.45), lineWidth: 1)
                        )

                        FGQuietButton("Pick an existing session instead", systemImage: "sparkles") {
                            isShowingCatalogPicker = true
                        }
                        .frame(maxWidth: .infinity)

                        FGPrimaryButton(title: "Save routine", isEnabled: isValid) {
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
                    durationMin = pickedSession.durationMin
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

    private func saveRoutine() {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let session = model.addCustomRoutine(
            title: trimmed,
            activity: activity,
            durationMin: durationMin,
            intensity: intensity,
            course: course,
            addToToday: addToToday
        )

        Analytics.capture("custom_routine_created", properties: [
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
