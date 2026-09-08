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
                    VStack(alignment: .leading, spacing: FGSpace.l) {
                        // Title Section
                        VStack(alignment: .leading, spacing: FGSpace.s) {
                            Text("Name your routine")
                                .font(FGFont.itemTitle)
                                .foregroundStyle(FGColor.ink)

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

                        // Section / Course Quadrant
                        VStack(alignment: .leading, spacing: FGSpace.s) {
                            Text("Menu Section")
                                .font(FGFont.itemTitle)
                                .foregroundStyle(FGColor.ink)

                            HStack(spacing: FGSpace.s) {
                                ForEach([Course.appetizer, Course.main, Course.side, Course.dessert], id: \.self) { c in
                                    Button {
                                        withAnimation(FGMotion.gentle) {
                                            course = c
                                            // Adjust sensible default duration if switching courses
                                            if c == .appetizer && durationMin > 10 { durationMin = 5 }
                                            if c == .main && durationMin < 15 { durationMin = 20 }
                                        }
                                    } label: {
                                        VStack(spacing: 4) {
                                            Text(c.label)
                                                .font(FGFont.label.weight(.semibold))
                                                .foregroundStyle(course == c ? c.tagText : FGColor.inkMuted)
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 10)
                                        .background(course == c ? c.tagFill : FGColor.surface)
                                        .clipShape(RoundedRectangle(cornerRadius: FGRadius.chip, style: .continuous))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: FGRadius.chip, style: .continuous)
                                                .strokeBorder(course == c ? c.tagText.opacity(0.4) : FGColor.line, lineWidth: 1)
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }

                        // Duration Picker
                        VStack(alignment: .leading, spacing: FGSpace.s) {
                            Text("Duration")
                                .font(FGFont.itemTitle)
                                .foregroundStyle(FGColor.ink)

                            FlowRow(spacing: FGSpace.s) {
                                ForEach(Self.commonDurations, id: \.self) { minutes in
                                    FGChoice(title: "\(minutes) min", isSelected: durationMin == minutes) {
                                        withAnimation(FGMotion.gentle) { durationMin = minutes }
                                    }
                                }
                            }
                        }

                        // Effort / Intensity
                        VStack(alignment: .leading, spacing: FGSpace.s) {
                            Text("Effort Level")
                                .font(FGFont.itemTitle)
                                .foregroundStyle(FGColor.ink)

                            HStack(spacing: FGSpace.s) {
                                ForEach(Self.efforts, id: \.intensity) { effort in
                                    FGChoice(title: effort.label, isSelected: intensity == effort.intensity) {
                                        withAnimation(FGMotion.gentle) { intensity = effort.intensity }
                                    }
                                }
                            }
                        }

                        // Add to Today Toggle
                        VStack(alignment: .leading, spacing: FGSpace.xs) {
                            Toggle(isOn: $addToToday) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Add to today's menu now")
                                        .font(FGFont.body.weight(.medium))
                                        .foregroundStyle(FGColor.ink)
                                    Text("Replaces today's suggested \(course.label.lowercased()) with this routine.")
                                        .font(FGFont.caption)
                                        .foregroundStyle(FGColor.inkMuted)
                                }
                            }
                            .tint(FGColor.clayDeep)
                            .padding(FGSpace.m)
                            .background(
                                RoundedRectangle(cornerRadius: FGRadius.card - 4, style: .continuous)
                                    .fill(FGColor.surface)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: FGRadius.card - 4, style: .continuous)
                                    .strokeBorder(FGColor.line, lineWidth: 1)
                            )
                        }

                        // Or Pick from Library button
                        FGQuietButton("Or pick an existing session from library", systemImage: "sparkles") {
                            isShowingCatalogPicker = true
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, FGSpace.xs)

                        // Action Button
                        FGPrimaryButton(title: "Save routine", isEnabled: isValid) {
                            saveRoutine()
                        }
                        .padding(.top, FGSpace.s)
                    }
                    .padding(FGSpace.page)
                }
                .scrollBounceBehavior(.basedOnSize)
                .scrollDismissesKeyboard(.interactively)
            }
            .navigationTitle("New Routine")
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
