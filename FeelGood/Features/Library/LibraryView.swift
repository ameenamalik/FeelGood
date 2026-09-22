//
//  LibraryView.swift
//  FeelGood
//
//  Everything there is, free forever. Deliberately not the home screen: the
//  app's job is to remove options, and this is the one place that hands them
//  all back for the times somebody wants to go looking. See PRD §8.
//

import SwiftUI

struct LibraryView: View {
    let model: TodayModel

    @Environment(\.dismiss) private var dismiss
    @State private var selected: Session?
    @State private var selectedActivity: Activity?

    init(
        model: TodayModel,
        initialSession: Session? = nil,
        initialActivity: Activity? = nil
    ) {
        self.model = model
        _selected = State(initialValue: initialSession)
        _selectedActivity = State(initialValue: initialActivity)
    }

    private var availableActivities: [Activity] {
        let set = Set(model.everything.map(\.activity))
        return Activity.allCases.filter { set.contains($0) }
    }

    private var courses: [(course: Course, sessions: [Session])] {
        Course.allCases.compactMap { course in
            let sessions = model.everything.filter { session in
                session.course == course
                    && (selectedActivity == nil || session.activity == selectedActivity)
            }
            return sessions.isEmpty ? nil : (course, sessions)
        }
    }

    var body: some View {
        ZStack {
            FGColor.bg.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: FGSpace.l) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: FGSpace.s) {
                            Text("Library")
                                .font(FGFont.title)
                                .foregroundStyle(FGColor.ink)
                            Text("Nothing here is chosen for you. That's the point of it.")
                                .font(FGFont.reason)
                                .foregroundStyle(FGColor.inkMuted)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        Spacer()
                        Button("Done") { dismiss() }
                            .font(FGFont.body.weight(.medium))
                            .foregroundStyle(FGColor.ink)
                    }

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: FGSpace.xs) {
                            filterChip(
                                title: "All",
                                isSelected: selectedActivity == nil
                            ) {
                                selectedActivity = nil
                            }

                            ForEach(availableActivities, id: \.self) { activity in
                                filterChip(
                                    title: activity.label,
                                    isSelected: selectedActivity == activity
                                ) {
                                    selectedActivity = selectedActivity == activity ? nil : activity
                                }
                            }
                        }
                    }

                    ForEach(courses, id: \.course) { group in
                        VStack(alignment: .leading, spacing: FGSpace.s) {
                            Text(group.course.label)
                                .font(FGFont.label)
                                .foregroundStyle(FGColor.inkMuted)
                                .textCase(.uppercase)
                                .tracking(1.1)

                            ForEach(group.sessions) { session in
                                row(session)
                            }
                        }
                    }
                }
                .padding(FGSpace.page)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
        .sheet(item: $selected) { session in
            SessionDetailView(session: session, model: model)
        }
        .presentationDragIndicator(.visible)
    }

    private func filterChip(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(FGFont.label.weight(isSelected ? .semibold : .regular))
                .foregroundStyle(isSelected ? FGColor.onActionFill : FGColor.ink)
                .padding(.horizontal, FGSpace.m)
                .padding(.vertical, FGSpace.s)
                .background(
                    Capsule()
                        .fill(isSelected ? FGColor.actionFill : FGColor.surface)
                )
                .overlay(
                    Capsule()
                        .strokeBorder(isSelected ? Color.clear : FGColor.line, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }

    private func row(_ session: Session) -> some View {
        FGCard {
            VStack(alignment: .leading, spacing: FGSpace.xs) {
                Text(session.title)
                    .font(FGFont.body.weight(.medium))
                    .foregroundStyle(FGColor.ink)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if session.isOwn && !session.subtitle.isEmpty {
                    Text(session.subtitle)
                        .font(FGFont.caption)
                        .foregroundStyle(FGColor.inkMuted)
                        .fixedSize(horizontal: false, vertical: true)
                }

                WrapRow(spacing: FGSpace.xs, lineSpacing: FGSpace.xs) {
                    ForEach(session.chips, id: \.self) { FGChip(text: $0) }
                }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { selected = session }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(
            ([session.title, session.subtitle] + session.chips)
                .filter { !$0.isEmpty }
                .joined(separator: ". ")
        )
        .accessibilityAddTraits(.isButton)
    }
}
